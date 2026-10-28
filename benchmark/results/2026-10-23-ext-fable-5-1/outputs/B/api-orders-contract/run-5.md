## Contract mismatches in the recorded responses

| # | Recording | Finding | Severity |
|---|-----------|---------|----------|
| 1 | GET /orders/1042 → 200 | `total` is the string `"42.50"`. Schema says `type: number`. | High |
| 1 | GET /orders/1042 → 200 | `note` is `null`. Schema says `type: string` with no `nullable: true`, so null is invalid under OpenAPI 3.0.3. | Medium |
| 2 | GET /orders/999999 → 404 | Body lacks the required `code` field of the Error schema. Only `message` is present. | High |
| 3 | POST /orders (5,000-char note) → 500 | Status 500 is not documented for this operation. The contract allows only 201 and 400. | High |
| 3 | POST /orders (5,000-char note) → 500 | Body `{"error": ...}` does not match the Error schema. Both required fields `code` and `message` are missing. | High |
| 3 | POST /orders (5,000-char note) → 500 | The body leaks a database error string, revealing the column type and length. Internal details should not reach clients. | Medium (security) |
| 3 | POST /orders (5,000-char note) → 500 | Root cause is a contract gap. `note` has no `maxLength` in the spec, yet storage caps it at 500 characters. Either the spec should declare `maxLength: 500` and the server should return 400, or storage should accept arbitrary length. | High |

Recording 1 passes on status code and the presence of `id`, `status`, and `total`. Recording 2 passes on status code. Everything else above is a defect.

## Gaps in the contract itself

- **No response for an invalid path id.** The spec constrains `id` to an integer of at least 1 but documents no 400 for `/orders/0`, `/orders/-1`, or `/orders/abc`.
- **No 5xx documented** anywhere. Clients cannot know what shape to expect on server failure.
- **No `maxLength` on `note`** in NewOrder or Order, and no `maxLength` or pattern on `items[]` entries.
- **No `maxItems` on `items`**, so the upper bound on an order is undefined.
- **No `additionalProperties: false`** on any schema, so unknown fields silently pass. This is probably intended but should be explicit.
- **No 415 or 405 documented** for wrong content type or unsupported method.
- **`Order.note` is not nullable** yet the server returns null for it. The spec should say `nullable: true` or the server should omit the field.
- **No `total` precision or minimum.** A negative or non-finite total would be contract-valid.
- **No authentication scheme** is declared. Assumed public or out of scope for this document.

## Assumptions

- The database column for `note` is `varchar(500)`, as the leaked error states, and 500 is the intended business limit.
- Order ids are 64-bit integers server side. Boundary tests below use 2^31 and 2^63 to probe that.
- Error `code` is meant to be a stable machine-readable string such as `ORDER_NOT_FOUND` or `VALIDATION_ERROR`. Exact values are not specified, so tests assert presence and type only.
- The recorded `total` string is a serialization bug, not a deliberate decimal-as-string policy. If it is deliberate, the spec must change to `type: string` with a pattern.
- Staging is representative of production for behavior under test.

## Test design

### A. Schema validation (automated, every response)

Run every response through a JSON Schema validator against the resolved OpenAPI schema. This single harness would have caught every defect above. Each test below asserts status code plus schema conformance unless stated otherwise.

### B. GET /orders/{id}

| ID | Case | Input | Expected |
|----|------|-------|----------|
| G1 | Happy path | Existing id | 200, Order schema, `total` is a JSON number, `status` in enum |
| G2 | Order with no note | Existing id whose note is unset | 200, `note` absent or spec updated to nullable. Fails today. |
| G3 | Order with a note | Existing id with note | 200, `note` is a string |
| G4 | Each status value | Orders in placed, paid, shipped | 200, `status` matches |
| G5 | Not found | Unused large id such as 999999 | 404, Error schema with `code` and `message`. Fails today. |
| G6 | Zero id | `/orders/0` | 400 or 404, Error schema. Behavior must be documented. |
| G7 | Negative id | `/orders/-1` | Same as G6 |
| G8 | Non-integer id | `/orders/abc`, `/orders/1.5`, `/orders/1e3` | 400, Error schema |
| G9 | Leading zeros and plus sign | `/orders/0042`, `/orders/+42` | Deterministic, documented. Should not resolve to order 42 silently. |
| G10 | Overflow | `/orders/2147483648`, `/orders/9223372036854775808` | 400 or 404 with Error schema, never 500 |
| G11 | Very long id string | 10,000 digits | 400 or 414, never 500 |
| G12 | Injection payloads in id | `1 OR 1=1`, `1;DROP TABLE orders` URL-encoded | 400, no leaked SQL text |
| G13 | Content-Type header | Any success or error | `application/json` with charset |
| G14 | Response does not expose other orders | Request id A, assert no fields from id B | Passes trivially but guards against joins leaking |

### C. POST /orders

| ID | Case | Body | Expected |
|----|------|------|----------|
| P1 | Minimal valid | `{"items":["sku-1"]}` | 201, Order schema, `status` is `placed`, `total` is a number |
| P2 | With note | `{"items":["sku-1"],"note":"hello"}` | 201, `note` echoed |
| P3 | Note at limit | note of exactly 500 chars | 201 |
| P4 | Note one over limit | note of 501 chars | 400, Error schema. Returns 500 today. |
| P5 | Note far over limit | note of 5,000 and 1,000,000 chars | 400 or 413, Error schema, no DB text leaked |
| P6 | Multibyte note at limit | 500 four-byte emoji, 500 CJK characters | 201. Probes whether the limit is bytes or characters. |
| P7 | Note is null | `"note": null` | 400 or treated as absent. Must be documented. |
| P8 | Note wrong type | `"note": 123`, `"note": ["x"]` | 400 |
| P9 | Missing items | `{}` and `{"note":"x"}` | 400 |
| P10 | Empty items | `{"items":[]}` | 400 (minItems 1) |
| P11 | Items wrong type | `"items":"sku-1"`, `"items":[1]`, `"items":[null]`, `"items":[{}]` | 400 |
| P12 | Empty string item | `"items":[""]` | 400 or 201, documented |
| P13 | Unknown SKU | `"items":["does-not-exist"]` | 400 or 201, documented. Assumed 400. |
| P14 | Duplicate SKUs | `"items":["sku-1","sku-1"]` | Documented quantity semantics |
| P15 | Very many items | 10,000 and 1,000,000 entries | 400 or 413, never 500 or timeout |
| P16 | Very long SKU | 100,000-char string | 400, no DB error |
| P17 | Unknown top-level field | `{"items":["sku-1"],"foo":1}` | 201 and field ignored, or 400. Documented. |
| P18 | Client-supplied id, status, total | `{"items":["sku-1"],"id":1,"status":"shipped","total":0}` | 201 with server-assigned values, client values ignored |
| P19 | Malformed JSON | `{"items":[` | 400, Error schema |
| P20 | Empty body | no bytes | 400 |
| P21 | Wrong content type | `text/plain`, `application/xml`, missing header | 415 or 400, documented |
| P22 | Oversized body | 50 MB payload | 413, connection not hung |
| P23 | Created resource is readable | POST then GET returned id | 200, same `id`, `status`, `total`, `note` |
| P24 | Location header | Any 201 | Present and points to `/orders/{id}` if the API chooses to emit it. Document either way. |
| P25 | Idempotency | Same body twice | Two distinct orders, or documented idempotency key behavior |
| P26 | Injection in note and items | SQL, HTML, script tags, null bytes | 201 stored verbatim and GET returns escaped-safe JSON, or 400. No 500. |

### D. Cross-cutting

- **Error envelope consistency.** For every 4xx and 5xx produced by B and C, assert the body is exactly the Error schema. Fail on `{"error": ...}` or missing `code`.
- **Error codes are stable.** Capture `code` values across runs and fail on drift.
- **No stack traces or SQL in any response body**, asserted by regex on `varying`, `syntax error`, `Exception`, `at ` traces.
- **Numeric serialization.** Assert `total` and `id` are JSON numbers, not strings, across many orders including totals with two decimals and zero.
- **Method coverage.** PUT, PATCH, DELETE on both paths return 405 with an Allow header, or are documented.
- **HEAD and OPTIONS** on both paths behave consistently.
- **Spec lint.** Run the OpenAPI document through a linter in CI and fail on the gaps listed above once fixed.
- **Contract-as-mock.** Generate a mock from the spec and run the client test suite against it, then against staging. Divergence surfaces contract drift early.

### E. Recommended fixes ordered by priority

1. Return 400 with Error schema for notes over 500 characters, and add `maxLength: 500` to `NewOrder.note` and `Order.note`.
2. Stop leaking database errors. Add a global handler that maps unexpected exceptions to a documented 500 with the Error schema.
3. Serialize `total` as a number.
4. Add `code` to all error responses, starting with the 404.
5. Either omit `note` when unset or mark it `nullable: true` in the spec.
6. Document 400 for invalid path ids, 500 for server errors, and any 405, 413, 415 the gateway emits.
7. Add `maxItems` to `items` and `maxLength` to item strings.
