**Assumptions.** The recordings are complete and accurate, including status codes. No response headers were captured, so Content-Type is assumed to be application/json. The spec is OpenAPI 3.0.3, where `null` is only valid if a property declares `nullable: true`. Whether the failed POST in recording 3 left a row behind is unknown and treated as an open risk. Where the server and spec disagree, the spec is treated as the intended behavior unless noted.

## Mismatches

Every recorded response violates the contract. Four violations are server bugs, one is a spec gap that the server surfaced badly.

| # | Recording | Contract says | Server did | Severity |
|---|---|---|---|---|
| M1 | 1, `total` | `number` | String `"42.50"` | High. Clients doing arithmetic on `total` will break or silently concatenate. |
| M2 | 1, `note` | `string`, not nullable | `null` | Medium. Either the server should omit the key, or the spec needs `nullable: true`. |
| M3 | 2, 404 body | `Error` requires `code` and `message` | Only `message` | Medium. Clients branching on `code` get undefined. |
| M4 | 3, status | Only 201 and 400 documented | 500 | High. A valid-per-contract request crashed the service. |
| M5 | 3, body | Any error body must be `Error` | `{"error": ...}` with raw Postgres text | High. Wrong shape, and it leaks the storage column type and length. |

**Root cause of M4 and M5.** The spec puts no `maxLength` on `NewOrder.note`, but the database column holds 500 characters. The server validates nothing and lets the database throw. The fix has two parts. Add `maxLength: 500` to `note` in the spec, and validate it in the handler so the response is a 400 with an `Error` body. The spec change is the smaller of the two options; raising the column width would still leave an unbounded field.

**Side effect risk from recording 3.** If the handler inserted the order before the note, or wrote to any other table first without a transaction, the 500 may have persisted a partial order. This needs checking in the staging database before the fix ships.

## Contract gaps found alongside

These are not violated by the recordings but will produce the same class of surprise.

- **GET has no 400.** The `id` parameter declares `minimum: 1` but the only documented failure is 404. Requests for `/orders/0`, `/orders/-1` and `/orders/abc` have no defined outcome. Recommend documenting 400 with an `Error` body.
- **No 5xx anywhere.** Document a `default` response using `Error` so clients can always parse failures the same way.
- **`note` has no `maxLength` in either schema.** Covered above for `NewOrder`. `Order.note` should match.
- **`NewOrder.items` strings are unbounded.** A 5,000-character SKU will likely hit the same database failure as the note.
- **`Error.code` has no enum.** Clients cannot know which codes to expect, so the field is unusable for branching even once the server sends it.

## Test plan

Tests are grouped by endpoint, then cross-cutting checks. "Now" shows the expected result against the current staging build, based on the recordings. Tests marked "spec first" depend on the spec decisions above and should be written after those land.

**GET /orders/{id}**

| ID | Request | Expected | Now |
|---|---|---|---|
| G1 | Known id | 200. Body validates against `Order`. `total` is a JSON number. `id` equals the path id. `status` is in the enum. | Fails (M1) |
| G2 | Known id with no note | 200. `note` key absent, or null only if spec adds `nullable`. | Fails (M2) |
| G3 | Known id with a note | 200. `note` is a string, at most 500 characters. | Unknown |
| G4 | Unknown id | 404. Body validates against `Error` with both `code` and `message`. | Fails (M3) |
| G5 | id of 0, negative, non-integer, leading zeros, 2^63 | 400 with `Error`. Never 500. Spec first. | Unknown |

**POST /orders**

| ID | Request | Expected | Now |
|---|---|---|---|
| P1 | `{"items": ["sku-1"]}` | 201. Body validates against `Order`. `status` is `placed`. `total` is a number. | Unknown |
| P2 | P1 plus a short note | 201. `note` echoed unchanged. | Unknown |
| P3 | Note of exactly 500 characters | 201. Boundary passes. Spec first. | Unknown |
| P4 | Note of 501 characters | 400 with `Error`. Spec first. | Fails (M4, M5) |
| P5 | Note of 5,000 characters | 400 with `Error`. No order row created. Response contains no database text. | Fails (M4, M5) |
| P6 | Missing `items` | 400 with `Error`. | Unknown |
| P7 | `items` is `[]` | 400 with `Error`. `minItems` enforced. | Unknown |
| P8 | `items` contains a number or null | 400 with `Error`. | Unknown |
| P9 | `note` is a number | 400 with `Error`. | Unknown |
| P10 | Malformed JSON, empty body, wrong Content-Type | 400 with `Error`. Never 500. | Unknown |
| P11 | Item string of 5,000 characters | 400 with `Error`, not 500. Probes the same unbounded-field bug. | Likely fails |
| P12 | Round trip | POST returns id, then GET on that id returns an identical body. | Unknown |

**Cross-cutting**

- **X1, every error is an Error.** Every non-2xx response from any test above validates against `Error`. Enforce this as a shared assertion rather than per test.
- **X2, no leakage.** No response body contains strings such as `character varying`, `relation`, `syntax error`, or a stack trace. Run this against every response in the suite.
- **X3, schema fuzzing in CI.** Run a property-based contract tool such as Schemathesis against staging with any 5xx and any schema violation counted as failure. This would have caught all five mismatches without hand-written cases.
- **X4, spec lint.** Fail the build if any operation lacks a 400 or `default` response, or if any string property in a request schema lacks `maxLength`.
- **X5, atomicity.** For P5, assert via a database count or a test-only hook that a rejected order leaves no rows in the orders or order-items tables.

**Order of work.** Decide the spec changes first since G5, P3 and P4 cannot be asserted until they land. Then fix the serializer for `total` and `note`, add `code` to the 404 handler, and add request validation for `note` length. Land X3 at the same time so regressions are caught by the fuzzer rather than only by the hand-written cases.
