# Orders API 2.1.0 QA report

**Scope.** Three responses recorded on staging on 2026-10-15 against the 2.1.0 contract. Deployed version and contract version match, so none of the gaps can be explained by version skew.

**Assumptions.** The contract is the source of truth and the server is what must change, except where a product decision is explicitly called out. Response headers were not recorded, so I assume every response carried `Content-Type: application/json`. The spec declares no security scheme, so I assume the API is unauthenticated or that auth sits in front of it and is out of scope. Whether the failed POST in recording 3 left a row behind is unknown. The initial status of a newly created order is assumed to be `placed`.

## Findings

Every recorded response violates the contract. Six distinct mismatches:

| ID | Recording | Observed | Contract says | Severity | Likely cause and fix |
|---|---|---|---|---|---|
| F1 | 1, GET 200 | `total` is the JSON string `"42.50"` | `Order.total` is `type: number` | High. Typed clients fail deserialization or silently coerce. | Serializer emits the decimal column as a string. Either fix the serializer or change the contract to a documented decimal string with a pattern. Needs a decision, see D1. |
| F2 | 1, GET 200 | `note` is `null` | `Order.note` is `type: string` with no `nullable: true`. In OpenAPI 3.0.3 `null` fails validation. | Medium | Serializer writes every column. Omit absent optional fields, or add `nullable: true` to the contract. See D4. |
| F3 | 2, GET 404 | Body is `{"message": ...}` only | `Error` requires both `code` and `message` | High. Clients that branch on `code` cannot distinguish error kinds. | Not-found handler bypasses the standard error envelope. Add a stable code such as `ORDER_NOT_FOUND`. |
| F4 | 3, POST | HTTP 500 for a request that is valid under the contract | Only 201 and 400 are documented; `NewOrder.note` has no `maxLength` | High. A contract-valid input crashes the endpoint. | DB column is `varchar(500)` while the API accepts unbounded text. Either add `maxLength: 500` to the contract and validate with a 400, or widen the column. Both layers must agree. See D2. |
| F5 | 3, POST 500 | Body is `{"error": ...}` | Any error body must be the `Error` object | Medium | Unhandled-exception path uses a different envelope than handled errors. Route all errors through one envelope. |
| F6 | 3, POST 500 | Raw PostgreSQL error text returned to the caller | Not specified, but a security defect regardless | Medium | Information disclosure of DB engine, column type and length. Return a generic message and log the detail server-side with a request id. |

**Additional risk from recording 3.** A 500 after validation may mean the order row was partially written or an id was consumed. Test P22 below covers this. Treat as a possible data-integrity bug until proven otherwise.

**Contract defects and gaps.** These are problems in the spec itself rather than mismatches, and several of them directly caused the failures above:

- No bound on any input. `note` and each `items` element have no `maxLength`, and `items` has no `maxItems`. F4 is the predictable result.
- GET has no 400 response. Behaviour for ids that violate `minimum: 1` or are not integers is undefined.
- No 500 or `default` response and no 415 or 405. The contract cannot be used to assert "no undocumented status codes" until these are decided.
- `Error.code` has no enum, so clients have nothing stable to switch on.
- `Order` does not include `items`, so a client cannot verify what it ordered from the create response.
- `total` has no `format`, `minimum` or precision rule. Money as a bare float is a rounding risk and is the root of D1.

**Decisions required from the API owner.** The test expectations marked "per D-n" depend on these:

- D1. `total` as a number or as a decimal string. Recommendation: decimal string with pattern `^-?\d+\.\d{2}$`, because it is lossless and matches current behaviour. Either way, update spec and server together.
- D2. Max length for `note`. Recommendation: `maxLength: 500` in the contract, enforced with 400 and code `NOTE_TOO_LONG`.
- D3. Invalid path id such as `0`, `-1`, `abc`. Recommendation: 400 with the `Error` envelope, documented in the spec.
- D4. Absent optional fields omitted, or `nullable: true`. Recommendation: omit.

**Release recommendation.** Block on F1, F3 and F4. F2, F5 and F6 can ship behind a fix-forward if the error envelope work is scheduled.

## Test design

**Approach.** Three layers. First, a response validator in the test client that checks every response against the schema for its status code and fails on any undocumented status. Second, property-based generation from the spec with a tool such as Schemathesis, where any 5xx or schema violation is a failure. Third, the explicit cases below, which encode the business rules and the regressions for F1 to F6. Spec linting with Spectral runs in CI so the gaps listed above cannot regress.

**Cross-cutting contract tests, run against every response in every suite:**

| ID | Check | Covers |
|---|---|---|
| C1 | Status code is one documented for the operation | F4 |
| C2 | Body validates against the schema for that status; types match exactly, numbers are not strings, no `null` for non-nullable fields | F1, F2 |
| C3 | Every 4xx and 5xx body is the `Error` object with non-empty `code` and `message` | F3, F5 |
| C4 | No error message matches internal-detail patterns such as `character varying`, `SQLSTATE`, `Traceback`, `psycopg`, `at .*\.java` | F6 |
| C5 | `Content-Type` is `application/json; charset=utf-8` on every response | assumption check |

**GET /orders/{id}:**

| ID | Request | Expected | Notes |
|---|---|---|---|
| G1 | Existing order | 200, `id` equals path id, `status` in enum, `total` per D1 | Regression F1 |
| G2 | Existing order with no note | 200, `note` absent, not `null` | Regression F2, per D4 |
| G3 | Existing order with a note | 200, `note` byte-for-byte equal to stored value | |
| G4 | Nonexistent id such as 999999 | 404, `code` present, e.g. `ORDER_NOT_FOUND` | Regression F3 |
| G5 | Deleted or soft-deleted order, if the model has one | 404, same envelope as G4 | No leakage of deleted state |
| G6 | `0`, `-1` | 400 per D3, never 500 | |
| G7 | `abc`, `1.5`, `1e3`, `0x10`, ` 1042` with encoded whitespace | 400 per D3, never 500 | |
| G8 | `00001042` with leading zeros | Decide: 200 for 1042 or 400. Must be deterministic | |
| G9 | `9223372036854775808` and a 40-digit number | 400 or 404, never 500 | Integer overflow |
| G10 | `1%20OR%201=1`, `1;DROP TABLE orders` | 400, no data effect | Injection |
| G11 | One order per enum status `placed`, `paid`, `shipped` | 200 with the matching status | Data-driven |
| G12 | Any DB status not in the enum, e.g. `cancelled`, `refunded` | Reconcile DB status set with the enum; any extra value is a contract break | Check the DB enum directly |
| G13 | Totals of `0`, `0.1`, `19.99`, `1000000.00`, negative if refunds exist | Exact representation, no float drift, per D1 | |
| G14 | `DELETE`, `PUT`, `PATCH` on `/orders/1` | 405 with `Allow` header, `Error` envelope | Undocumented today |
| G15 | `HEAD` and `OPTIONS` | Consistent with GET, no body on HEAD | |

**POST /orders:**

| ID | Request | Expected | Notes |
|---|---|---|---|
| P1 | `{"items":["sku-1"]}` | 201, `Order` validates, `status` is `placed`, `total` per D1; subsequent GET by returned id returns an equal body | Round trip |
| P2 | Valid items plus `"note":"hello"` | 201, `note` echoed exactly | |
| P3 | Note of exactly 500 chars | 201 | Boundary, per D2 |
| P4 | Note of 501 chars | 400, `code` `NOTE_TOO_LONG` per D2; never 500 | Regression F4 |
| P5 | Note of 5,000 chars and of 1 MB | Same as P4 | Regression F4 |
| P6 | Note of 500 four-byte emoji, 500 CJK chars, combining sequences, RTL text | 201 and exact round trip. Confirms the limit counts characters, not bytes, at every layer | Encoding |
| P7 | Note containing `\u0000` and other control chars | 400, never 500 | PostgreSQL rejects NUL in text |
| P8 | Note `""` | 201, empty string stored and returned | Schema allows it |
| P9 | Note `null`, `123`, `{}`, `[]` | 400 | `note` is a non-nullable string |
| P10 | Missing `items` | 400 with a code such as `VALIDATION_ERROR` naming the field | |
| P11 | `"items": []` | 400 | `minItems: 1` |
| P12 | `"items": "sku-1"`, `"items": null`, `"items": {}` | 400 | |
| P13 | `"items": [1]`, `[null]`, `[{}]`, `["sku-1", 2]` | 400 | |
| P14 | `"items": [""]`, `["   "]` | Decide, document, never 500 | Spec allows it today |
| P15 | One item of 10,000 chars; 10,000 items | 400 after `maxLength` and `maxItems` are added; never 500 | Follows from gaps list |
| P16 | `["sku-1","sku-1"]` | Decide: two lines or a 400. Document | |
| P17 | Unknown SKU `"does-not-exist"` | Decide: 400 with `UNKNOWN_SKU` or 201. Never 500 | Business rule |
| P18 | Extra field `"foo": 1` alongside valid body | 201 and the field is ignored, not echoed | No `additionalProperties: false` |
| P19 | No body; body `{}` | 400 | `requestBody.required: true` |
| P20 | Malformed JSON `{"items": [` | 400, never 500 | |
| P21 | `Content-Type: text/plain` and `application/x-www-form-urlencoded` with a JSON string | 415, documented | Undocumented today |
| P22 | After every 4xx and 5xx from this table | Order count unchanged, no new row, no gap in ids attributable to the failure | Atomicity, follows F4 |
| P23 | Same valid body sent twice | Two distinct ids, unless an idempotency key is introduced; document | |
| P24 | Known SKUs with known prices | `total` equals the sum to two decimals | Pricing correctness |
| P25 | Note with `<script>`, `' OR 1=1 --`, `${jndi:ldap://x}` | 201, stored verbatim, returned JSON-escaped, no interpretation anywhere | Injection |
| P26 | Body of 10 MB | 413 before parsing, never 500 or timeout | Resource limit |

**Non-functional and robustness:**

| ID | Check | Pass criteria |
|---|---|---|
| N1 | Property-based fuzz of both operations, 1,000 cases each | Zero 5xx, zero schema violations |
| N2 | 50 concurrent valid POSTs | All 201, all ids unique, all retrievable |
| N3 | 50 concurrent POSTs with 501-char notes | All 400, zero rows written |
| N4 | Latency under nominal load | p95 within the service SLO. Assumption: 300 ms for GET, 500 ms for POST until the owner states otherwise |
| N5 | Server logs for every 5xx | Contain stack detail and a request id that is also returned in a response header |
| N6 | Auth | Confirm that unauthenticated access is intended. If a gateway enforces auth, add 401 and 403 cases and document them |
| N7 | Spec lint in CI | Fails on any property without `maxLength` or `maxItems`, any non-nullable field the server can return as null, and any operation without a `default` error response |

**Order of execution for the current build.** Run C1 to C4 plus G1, G2, G4, P1, P4, P5 and P22 first. Those nine cases reproduce every recorded defect and establish whether recording 3 corrupted data. The rest follows once D1 to D4 are decided, since roughly a third of the expectations depend on them.
