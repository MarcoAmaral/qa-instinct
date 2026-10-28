All three recorded responses violate the contract. Six mismatches found. One is a server fault on valid input that also leaks database internals.

## Contract mismatches

| # | Sample | Aspect | Contract | Observed | Severity |
|---|--------|--------|----------|----------|----------|
| M1 | 1 | `Order.total` | `type: number` | JSON string `"42.50"` | High |
| M2 | 1 | `Order.note` | `type: string`, not nullable | `null` | Medium |
| M3 | 2 | `Error.code` | required | absent | Medium |
| M4 | 3 | Status for valid request | only 201 or 400 defined | 500 | High |
| M5 | 3 | Error body shape | `Error {code, message}` | `{"error": "..."}` | Medium |
| M6 | 3 | Error content | n/a | raw PostgreSQL message exposing column type and length | Medium, security |

**M1, total is a string.** Typed clients generated from the contract will fail to deserialize every successful order. The contract is the published 2.1.0 promise, so the fix belongs in the API unless product deliberately wants decimal strings for money. If that is the decision, the contract must change to a string with a decimal pattern and that is a breaking change needing a version bump. Also check GET and POST emit the same representation.

**M2, note is null.** OpenAPI 3.0.3 rejects `null` for a `string` property unless `nullable: true` is set. Either omit the field when the order has no note, which is non-breaking, or add `nullable: true` to the contract.

**M3, 404 body lacks code.** Clients that branch on `code` cannot distinguish "not found" from other errors. Emit a stable code such as `ORDER_NOT_FOUND`. Check all other error paths for the same omission.

**M4 and M5, 500 on a valid request.** The request satisfies `NewOrder` because `note` has no `maxLength`. The server forwards the value to a `varchar(500)` column with no application-level validation, and the database raises. Validation is missing at the API boundary. Fix both sides: add `maxLength: 500` to `NewOrder.note`, reject over-length input with 400 and an `Error` body, and add a generic 500 response to the contract that uses the `Error` schema. Also confirm the failed insert rolled back and no partial order row exists.

**M6, information disclosure.** The message reveals the database vendor, column type, and limit. Error responses must never carry database or stack text. This points to a global exception handler that passes exception messages straight through, so every unguarded constraint will leak the same way.

## Contract gaps and assumptions

Gaps in the spec that the tests below exercise, with the behavior assumed until product confirms:

- `GET /orders/{id}` defines no 400 even though `id` has `minimum: 1`. Assumed: `0`, negatives, and non-integers return 400 with an `Error` body.
- `NewOrder.note` has no `maxLength`. Assumed: 500 characters, per the database error.
- `NewOrder.items[]` strings have no length or format constraint, and `items` has no `maxItems`. Assumed: same class of unguarded database limit exists and must return 400, not 500.
- No 405, 406, 413, or 415 responses are defined. Assumed: all return an `Error` body, never a 500.
- No 500 response is defined. Assumed: one should be, using the `Error` schema with a sanitized message.
- `Order.status` after creation is not stated. Assumed: `placed`.
- No `additionalProperties: false` on any schema, so extra fields are permitted. Tests report them as informational.
- No authentication is defined. Assumed: none required.
- Recorded samples omit headers. Assumed: `Content-Type: application/json` on all three.
- The 5,000-character note was ASCII. Multibyte handling is tested separately because `varchar(500)` counts characters, not bytes.

## Test plan

Automate schema validation once rather than per test. Every response in the suite is validated against the spec by a validator such as openapi-core or a Schemathesis run in CI, so M1, M2, M3, and M5 fail automatically on regression. Each test below lists the expected result after the fixes above.

GET /orders/{id}

| ID | Case | Expected |
|----|------|----------|
| G01 | Existing order, regression for sample 1 | 200, `total` is a JSON number, `status` in enum, `note` is a string or omitted |
| G02 | Order with a note | `note` present as string, matching what was posted |
| G03 | Order without a note | `note` omitted, or `null` only if contract gains `nullable: true` |
| G04 | One order per enum value `placed`, `paid`, `shipped` | 200 each; no undocumented status such as `cancelled` ever appears |
| G05 | Non-existent id, regression for sample 2 | 404, body has both `code` and `message` |
| G06 | `id` = 0 | 400 with `Error` body |
| G07 | `id` negative | 400 with `Error` body |
| G08 | `id` non-integer: `abc`, `1.5`, `1e3`, ` 1`, `%00` | 400 with `Error` body, never 500 |
| G09 | `id` beyond 64-bit range | 400 or 404 with `Error` body, never 500 |
| G10 | Response `Content-Type` header | `application/json` on 200 and 404 |
| G11 | `Accept: application/xml` | 406 with `Error` body, or JSON regardless; must be consistent |
| G12 | Unsupported method, e.g. `DELETE /orders/1` | 405 with `Error` body |

POST /orders

| ID | Case | Expected |
|----|------|----------|
| P01 | Minimal valid body `{"items": ["sku-1"]}` | 201, `Order` with integer `id`, numeric `total`, `status` = `placed` |
| P02 | Valid body with short note | 201, `note` echoed unchanged |
| P03 | Note of exactly 500 characters | 201 |
| P04 | Note of 501 characters | 400 with `Error`, code such as `VALIDATION_ERROR` |
| P05 | Note of 5,000 characters, regression for sample 3 | 400, body matches `Error`, message contains no database text |
| P06 | Note of 500 multibyte characters, e.g. 500 × `é` and 500 × an emoji | 201; confirms character versus byte semantics match the contract |
| P07 | Note of 499 multibyte characters plus one combining sequence | 201 or 400, but deterministic and documented |
| P08 | Note is empty string `""` | 201 |
| P09 | Note is `null` | 400, since `NewOrder.note` is not nullable |
| P10 | Note is a non-string: `123`, `{}`, `[]`, `true` | 400 |
| P11 | Note contains a NUL byte `\u0000` | 400, never 500; PostgreSQL text columns reject NUL |
| P12 | Note contains SQL and HTML metacharacters | 201, stored and returned byte-for-byte; no 500 |
| P13 | `items` missing | 400 |
| P14 | `items` empty `[]` | 400 |
| P15 | `items` not an array: string, object, number | 400 |
| P16 | `items` contains a non-string element | 400 |
| P17 | `items` element of 5,000 characters | 400 with `Error`, never 500; same bug class as sample 3 |
| P18 | `items` element empty string `""` | 400 assumed; contract silent |
| P19 | `items` with unknown SKU | 400 assumed; contract silent |
| P20 | `items` with duplicate SKUs | 201 assumed; total reflects quantity |
| P21 | `items` with 10,000 elements | 201 or 400 with `Error`, never 500 or timeout |
| P22 | Malformed JSON | 400 with `Error` |
| P23 | Empty body | 400 with `Error` |
| P24 | `Content-Type: text/plain` with valid JSON | 415 or 400 with `Error` |
| P25 | Body over 1 MB | 413 with `Error`, never 500 |
| P26 | Unknown extra property | 201 with property ignored, or 400; must be consistent and documented |
| P27 | Created order is retrievable | `GET /orders/{id}` returns identical `id`, `status`, `total`, `note` |
| P28 | `total` correctness | Equals priced sum of items from the pricing source for the staging catalog |
| P29 | No partial write on failure | After P04, P05, P11, P17: no new order row exists and the next created id is contiguous or at least not reserved for the failed request |
| P30 | Concurrent creates, 50 in parallel | All 201, all ids unique |
| P31 | Response `Content-Type` and `Location` header | `application/json`; `Location` header noted as informational since the contract does not define it |

Cross-cutting

| ID | Case | Expected |
|----|------|----------|
| X01 | Schema conformance of every response | Validator passes on every test; catches M1, M2, M3, M5 |
| X02 | Fuzzing with Schemathesis negative and positive strategies on both operations | Zero 5xx responses |
| X03 | Error hygiene scan | No error body or header matches `character varying`, `psycopg`, `SQLSTATE`, `Traceback`, `at line`, or a file path |
| X04 | Error code catalogue | Every 4xx and 5xx carries a documented `code`; the set is enumerated in the spec |
| X05 | Spec linting in CI | Spectral passes; spec declares `maxLength` on `note`, 400 on GET, and a 500 response |
| X06 | Spec drift gate | Contract tests run against each staging deploy and block promotion when any response fails validation |
| X07 | Version check | Deployed version header or build metadata equals the spec `info.version` |

Run order and priority: P05, P17, P11, X03 first because they reproduce or widen the live server fault. G01 and P27 next because the `total` type breaks every consumer. The remaining cases are regression coverage once the fixes land.
