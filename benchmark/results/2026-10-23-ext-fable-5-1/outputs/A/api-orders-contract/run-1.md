# Orders API 2.1.0 — contract conformance report and test design

**Verdict:** none of the three recorded responses conforms to the contract. Seven mismatches found, three of them in one response. The POST failure is the most serious because a request that is valid under the contract produces an undocumented 500 that leaks database internals.

## Mismatches

| # | Recording | What the contract says | What was observed | Severity | Recommended fix |
|---|---|---|---|---|---|
| M1 | 1, GET /orders/1042 | `Order.total` is `type: number` | `"total": "42.50"` is a JSON string | High. Clients doing arithmetic or strict deserialisation break. | Decide once: serialise as a number, or change the contract to a decimal string with a `pattern`. The contract must change if the string is intentional. |
| M2 | 1, GET /orders/1042 | `Order.note` is `type: string`, no `nullable: true` | `"note": null` | Medium. Null is invalid in OpenAPI 3.0.3 without `nullable`. | Omit the key when no note exists, or add `nullable: true`. |
| M3 | 2, GET /orders/999999 | `Error` requires `code` and `message` | Only `message` present | Medium. Clients cannot branch on a machine-readable code. | Return `code`, for example `order_not_found`. |
| M4 | 3, POST /orders | Documented responses are 201 and 400 only | 500 | High. The request is valid per the contract, so 201 was expected. | Validate input before the database write and return 400. |
| M5 | 3, POST /orders | Error bodies use the `Error` schema | `{"error": "..."}`, no `code`, no `message` | Medium. | Route all error paths through one `Error` serialiser, including the unhandled-exception handler. |
| M6 | 3, POST /orders | No contract statement, but general hygiene | Body echoes a PostgreSQL message naming a column type | High. Information disclosure of schema internals. | Never return raw exception text. Log it, return a generic `Error`. |
| M7 | 3, POST /orders | `NewOrder.note` has no `maxLength` | Storage enforces 500 characters | Medium. Contract and implementation disagree on the valid input space. | Add `maxLength: 500` to `NewOrder.note` and `Order.note`, or widen the column. |

**Contract gaps found while checking.** These are not mismatches with the recordings but will produce unverifiable behaviour.

- GET /orders/{id} documents no 400 even though `id` has `minimum: 1` and `type: integer`. Behaviour for `/orders/0`, `/orders/-1`, `/orders/abc` is undefined.
- POST /orders documents no 415 for a non-JSON content type and no response for malformed JSON.
- `Error.code` has no `enum`, so tests cannot assert a specific code without an out-of-band list.
- `Order` has no `items` property, so a client cannot read back what was ordered.
- Neither schema sets `additionalProperties: false`, so undocumented fields pass validation silently.

**Assumptions used throughout.**

- The contract is the source of truth. Where implementation and contract disagree, the implementation is wrong unless product decides otherwise. The one open product decision is M1, money as number versus string.
- The 500-character note limit is the intended business rule, so the fix is `maxLength: 500` plus a 400, not a wider column.
- Error codes will be `order_not_found` and `validation_error`. Adjust the assertions once the real vocabulary is fixed.
- A newly created order has status `placed`. `total` is computed server-side from item prices in a fixture catalogue.
- Unknown extra request properties are ignored, not rejected.
- Staging behaves as production will for 2.1.0, and all responses carry `Content-Type: application/json`. The recordings do not show headers, so this is unverified.
- Authentication is out of scope because the contract does not define it.

## Test design

**Layer 1, contract enforcement on every call.** Wrap the test HTTP client in a validator that fails any test whose response has a status not listed for that operation, a body that does not validate against the schema for that status, or a non-JSON content type. This single mechanism would have caught M1 through M5 and M7. Treat `null` as invalid for non-nullable fields. Enable a strict mode that fails on undocumented properties and review the report before deciding whether to add `additionalProperties: false`.

**Layer 2, GET /orders/{id}.**

| ID | Scenario | Expected | Covers |
|---|---|---|---|
| G1 | Existing order with a note | 200. `id` equals the path id, `status` in enum, `total` is a JSON number, `note` is a string. | Recording 1, M1 |
| G2 | Existing order without a note | 200. `note` key absent, never `null`. | Recording 1, M2 |
| G3 | One fixture per status: placed, paid, shipped | 200 with the matching status. | enum coverage |
| G4 | Unknown id 999999 | 404. `Error` with `code` and `message`. | Recording 2, M3 |
| G5 | id = 0, id = -1 | 400 or 404 once the contract decides. Never 500. | contract gap |
| G6 | id = abc, id = 1.5, id = 9223372036854775808, id = 1e3 | Same documented status as G5. Never 500. | contract gap |
| G7 | Round-trip after P1 | GET returns exactly what POST returned. | consistency |

**Layer 3, POST /orders.**

| ID | Scenario | Expected | Covers |
|---|---|---|---|
| P1 | `{"items": ["sku-1"]}` | 201. `Order` with integer id of at least 1, status `placed`, numeric `total`, no `note`. | happy path |
| P2 | Note of exactly 500 characters | 201 with the note echoed unchanged. | M7 boundary |
| P3 | Note of 501 characters | 400 `Error`, code `validation_error`. | M4, M7 boundary |
| P4 | Note of 5,000 characters | 400 `Error`. Regression for the recorded failure. | Recording 3, M4, M5 |
| P5 | Note of 500 multibyte characters, for example emoji, so over 500 bytes | 201. Fails if the limit is bytes rather than characters. Decide and document. | M7 ambiguity |
| P6 | `items` missing | 400 `Error`. | required |
| P7 | `items: []` | 400 `Error`. | minItems |
| P8 | `items: [1]` and `items: "sku-1"` | 400 `Error`. | item type, array type |
| P9 | `note: 123` and `note: null` | 400 `Error`. | note type |
| P10 | Malformed JSON body | 400 `Error`. Never 500. | contract gap |
| P11 | Empty body, and `Content-Type: text/plain` | 400 or 415 once documented. Never 500. | contract gap |
| P12 | Extra property `{"items": ["sku-1"], "foo": 1}` | 201 under the ignore assumption. | assumption |
| P13 | Unknown SKU `does-not-exist` | 400 `Error`. | business rule |
| P14 | 10,000 items | 201 or 400 once a `maxItems` is chosen. Never 500. | robustness |
| P15 | Two items with known prices | `total` equals the fixture sum as a number. | M1, correctness |

**Layer 4, cross-cutting.**

- **No internals in any error body.** Every 4xx and 5xx body is scanned for `character varying`, `SQL`, `pg`, `Traceback`, `at .*\(.*\.java`, and similar. Covers M6.
- **Property-based fuzz.** Generate bodies from the `NewOrder` schema, then mutate types, lengths, nesting, and encoding. Assert the status is always in the documented set and the body validates. Covers M4 and M5 broadly.
- **Spec lint.** Run an OpenAPI linter in CI and fail on missing `nullable`, missing `maxLength` on bounded fields, and undocumented 400 on operations with constrained parameters.
- **Recording replay.** Turn the three recordings into fixtures asserted against the corrected contract so the exact failures reported here stay fixed.

**Fix order.** M4, M5, and M6 together, since one error handler change resolves all three. Then M3 and M7, which are small. Then M1 and M2, which need a product decision on the contract wording before the code change.
