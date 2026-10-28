# Assumptions

- The recordings are complete and exact. Response headers were not captured, so I assume every response carried `Content-Type: application/json`. Header checks are included in the tests below because this is unverified.
- Staging ran version 2.1.0, which matches the contract's `info.version`, so the contract is the correct baseline for every recording.
- The 5,000-character note in recording 3 was plain ASCII. Whether the 500 limit is characters or bytes is therefore still unknown.
- Behaviour the contract does not define is treated as a contract gap, not a defect. For each gap I state the expected behaviour I tested against and flag it as a product decision.
- Business rules not in the contract: a new order starts in status `placed`, `total` is computed server-side from the item SKUs, and unknown SKUs are rejected with 400. No authentication is in scope.

# Contract mismatches

Every recording violates the contract. Six defects, ordered by severity.

| # | Recording | Observed | Contract requires | Severity |
|---|---|---|---|---|
| D1 | 3 | `500` on a request that is valid per `NewOrder` | Only `201` or `400` are defined. A valid request must never produce 5xx. | Critical |
| D2 | 3 | Body leaks `value too long for type character varying(500)` | Nothing in the contract permits exposing database column types. This is CWE-209 information disclosure. | High |
| D3 | 1 | `"total": "42.50"` is a JSON string | `Order.total` is `type: number`. Typed clients will fail to deserialise or will silently concatenate instead of add. | High |
| D4 | 2 | 404 body is `{"message": ...}` with no `code` | `Error` requires both `code` and `message`. Clients that branch on `code` cannot distinguish error kinds. | Medium |
| D5 | 3 | 500 body is `{"error": ...}` | Even undocumented errors should use the `Error` envelope. Neither `code` nor `message` is present. | Medium |
| D6 | 1 | `"note": null` | `Order.note` is `type: string` with no `nullable: true`. In OpenAPI 3.0.3 null is a type violation. Omit the key or mark it nullable. | Medium |

**Root cause of D1, D2, D5.** The `note` column is `varchar(500)` but neither the API layer nor the contract enforces a length. Input reaches the database unvalidated and the raw driver exception is serialised to the client. The same pattern almost certainly applies to item SKU strings and to any other string column, so the fix should be a general input-length policy plus a global exception handler, not a one-off check on `note`.

**Open question on D1.** It is also unknown whether the failed POST left a partially written order behind. Test P3 below checks this.

**Contract gaps the recordings expose.** These need a product decision, then a contract edit, before the test suite can be made strict.

- `NewOrder.note` and `Order.note` need `maxLength`. The pragmatic choice is 500 to match the column, with a 400 on violation. Widening the column is the alternative but an upper bound is still required.
- Decide whether `total` is a JSON number or a decimal string. If money precision is the reason for the string, change the contract to `type: string, format: decimal` and say so. As published, the server is wrong.
- `Order.note` must be either `nullable: true` or omitted when empty. Pick one and apply it consistently.
- GET `/orders/{id}` defines no 400. Requests with `id` of 0, negative, or non-integer have no documented outcome.
- No `default` or `500` response is defined for either operation. Add one that references `Error` so the envelope is contractually required everywhere.
- `Error.code` has no enum. Document the codes so clients can branch on them and tests can assert them.
- `items` has no `maxItems` and its strings have no `maxLength`. Unknown SKU handling is undocumented.
- `Order.id` has no `minimum: 1` although the path parameter does. Align them.
- 405 and 415 are not documented. If the server emits them they must use the `Error` schema.

# Test design

**Approach.** Two layers. First, a schema-driven contract suite generated from the OpenAPI file and run in CI on every build. A tool such as Schemathesis or Dredd would have caught D3, D4, D5 and D6 automatically, and property-based string generation would have found D1 within minutes. Second, the hand-written cases below, which cover business rules, boundaries and robustness that generated tests cannot infer. Every case asserts three things in addition to its specific expectation: the status code is one the contract lists for that operation, `Content-Type` is `application/json`, and the body validates against the referenced schema.

**Priority.** P0 cases are regressions for the six defects and must pass before 2.1.x ships. P1 is the core contract suite. P2 is boundaries. P3 is robustness and security hardening.

**GET /orders/{id}**

| ID | Pri | Request | Expected | Covers |
|---|---|---|---|---|
| G1 | P0 | Existing order with a note | 200. `total` is a JSON number. `note` is a string. | D3 |
| G2 | P0 | Existing order with no note | 200. `note` key absent, or null only once the contract says nullable. | D6 |
| G3 | P0 | Non-existent id, e.g. 999999 | 404. Body has `code` and `message`. | D4 |
| G4 | P1 | One fixture per status: placed, paid, shipped | 200. `status` is within the enum. | Enum coverage |
| G5 | P1 | Read-after-write: GET the id returned by P1 | 200. Fields equal the POST response. | Consistency |
| G6 | P2 | `id` = 0 | 400 with `Error`. Never 500, never a 404 that hides a validation failure. | Gap |
| G7 | P2 | `id` = -1 | 400 with `Error`. | Gap |
| G8 | P2 | `id` = `abc`, `1.5`, `1e3`, empty | 400 with `Error`. Never 500. | Gap |
| G9 | P2 | `id` = 99999999999999999999 | 400 or 404 with `Error`. Integer overflow at the DB layer is a classic 500. | Robustness |
| G10 | P2 | `id` = `0001042`, `+1042` | Documented and consistent behaviour. Either both resolve to 1042 or both are 400. | Gap |
| G11 | P3 | PUT, DELETE, PATCH on the path | 405 with `Error` and an `Allow` header. | Gap |
| G12 | P3 | `Accept: application/xml` | 406 with `Error`, or JSON regardless. Never a non-JSON body. | Gap |

**POST /orders**

| ID | Pri | Request | Expected | Covers |
|---|---|---|---|---|
| P1 | P1 | `{"items":["sku-1"]}` | 201. `id` integer ≥ 1, `status` = placed, `total` number, `note` absent. | Happy path |
| P2 | P1 | Notes of length 1, 499, 500 | 201. Note round-trips byte-for-byte on the following GET. | Upper boundary |
| P3 | P0 | Note of length 501 and of length 5,000 | 400 with `Error`. Afterwards no new order exists, verified by id sequence or a count. | D1, D5, atomicity |
| P4 | P0 | Any induced server failure, e.g. DB connection refused in staging or a fault-injection flag | 500 with `Error` envelope. Body contains no SQL, column, type, stack or driver text. | D2, D5 |
| P5 | P2 | Note of 500 four-byte emoji characters | 201 if the limit is characters, 400 if bytes. Result must match what the contract ends up saying. | Char vs byte |
| P6 | P2 | `note` = `""` | 201 and the empty string is preserved, or 400 if a `minLength` is added. | Gap |
| P7 | P2 | `note` = null | 400 under the current contract. Document if nulls are to be accepted. | Gap |
| P8 | P1 | `note` as number, object, array | 400 with `Error`. | Type validation |
| P9 | P1 | `items` missing | 400 with `Error`. | `required` |
| P10 | P1 | `items` = `[]` | 400 with `Error`. | `minItems` |
| P11 | P1 | `items` = string, null, `[1]`, `[null]`, `[""]` | 400 with `Error`. | Type validation |
| P12 | P1 | `items` = `["no-such-sku"]` | 400 with `Error` and a distinct `code`. | Business rule, gap |
| P13 | P1 | `items` = `["sku-1","sku-1"]` | Document: either 201 with doubled total or 400. | Gap |
| P14 | P2 | `items` with 10,000 entries | 400 once `maxItems` exists. Until then 201 within the response-time budget, never 500. | Gap |
| P15 | P0 | One item string of 5,000 characters | 400 with `Error`. Same defect class as D1 on a different column. | D1 generalised |
| P16 | P2 | Note containing `\u0000` | 400 with `Error`. PostgreSQL rejects null bytes in text and this commonly surfaces as a 500. | Robustness |
| P17 | P1 | Empty body, truncated JSON, trailing comma, non-UTF-8 bytes | 400 with `Error`. | Parser handling |
| P18 | P1 | Body is a JSON array or a bare string | 400 with `Error`. | Type validation |
| P19 | P2 | Valid JSON body with `Content-Type: text/plain` or no content type | 415 or 400 with `Error`. Document which. | Gap |
| P20 | P2 | `{"items":["sku-1"],"unexpected":1}` | Document: ignored or 400. Assert whichever the contract chooses. | Gap |
| P21 | P1 | Items with known prices | `total` equals the expected sum to two decimal places and is a number. | D3, correctness |
| P22 | P2 | Same valid body sent twice | Two orders with distinct ids. Document if idempotency keys are ever introduced. | Gap |
| P23 | P3 | Note containing SQL, HTML and template payloads | 201. Stored and returned verbatim, no 500, no interpretation. | Injection |
| P24 | P3 | Body larger than 1 MB | 413 with `Error`, not 500 and not a connection reset. | Robustness |
| P25 | P3 | 50 concurrent valid POSTs | All 201, all ids unique, all retrievable. | Concurrency |

**Cross-cutting checks**

- Every error response from every case above, including 404, 405, 413, 415 and 500, validates against `Error` and carries a documented `code`. Build the `Error.code` enum from the values observed and add it to the contract.
- A response-body scanner runs on every test and fails on strings such as `character varying`, `relation`, `syntax error`, `Exception`, `at line`, and file paths. This turns D2 into a permanent guard.
- The generated contract suite runs against staging on every deploy and against a local instance in CI. The generated suite must be configured to treat any undocumented status code as a failure, not a warning.
- Once the contract gaps above are resolved, promote the P2 "document which" cases to strict assertions. Until then they run in reporting mode so the gaps stay visible without blocking the build.
