## Assumptions

- The spec is the source of truth. Where the server and spec disagree, the server is wrong unless noted. Where the spec is silent, I state what the spec should say and test for that.
- OpenAPI 3.0.3 semantics apply, so `null` is invalid for a `type: string` property unless `nullable: true` is declared.
- The recordings omit headers. Content-Type is assumed to be `application/json` on all three and is not checked here.
- The 5,000-character note is plain ASCII. The storage column is `varchar(500)`, which in PostgreSQL counts characters, not bytes.
- The missing `note` maxLength will be resolved by adding `maxLength: 500` to the spec and returning 400 from the server, rather than widening the column.
- A newly created order has status `placed`.

## Mismatches

| ID | Recording | What the contract says | What was observed | Verdict |
|---|---|---|---|---|
| M1 | 1, GET /orders/1042 | `Order.total` is `number` | `"42.50"`, a JSON string | Server bug. If money-as-string is intentional, the spec must change to `type: string` with a decimal pattern, and every client is currently parsing it wrong. |
| M2 | 1, GET /orders/1042 | `Order.note` is `string`, not nullable | `null` | Server bug under the spec as written. Server should omit the key when no note exists. Alternative fix is `nullable: true` in the spec. |
| M3 | 2, GET /orders/999999 | `Error` requires `code` and `message` | Only `message` present | Server bug. Clients that branch on `code` get `undefined`. |
| M4 | 3, POST /orders | Only 201 and 400 are documented | 500 | Server bug. A request that satisfies `NewOrder` must never produce a 5xx. |
| M5 | 3, POST /orders | Error bodies use the `Error` schema | `{"error": "..."}`, no `code`, no `message` | Server bug. The 500 handler bypasses the error envelope entirely. |
| M6 | 3, POST /orders | `NewOrder.note` has no `maxLength` | Server rejects anything over 500 characters | Contract gap. The spec promises unbounded notes; the implementation cannot keep that promise. Add `maxLength: 500` and validate before the database call. |
| M7 | 3, POST /orders | Nothing | Raw database error text returned to the caller | Information disclosure. Column names and types must not leak to clients. Not a schema mismatch, but it fails any reasonable contract on error content. |

Things the recordings do not cover and therefore could not be checked: the 201 path, the documented 400 path, the `id` path parameter `minimum: 1` constraint, and the behaviour for non-integer ids. The spec also documents no response for an invalid id such as `0` or `abc`, which is a second contract gap. A 400 response with the `Error` schema should be added for that case.

## Test design

**Layer 1: automated contract validation.** Every test below runs its response through a schema validator wired to the spec, using the response schema for the returned status code. Two global rules apply to every request: an undocumented status code fails the test, and a body that does not validate fails the test. This layer alone would have caught M1 through M5.

**Layer 2: cross-cutting invariants.** These are asserted on every response in the suite, not written as individual cases.

- No response is 5xx for any input the suite sends, valid or invalid.
- Every non-2xx body validates against `Error`, with `code` a non-empty string and `message` non-empty.
- No error `message` contains the strings `character varying`, `varchar`, `relation`, `column`, `syntax error`, or a stack trace marker. This is the guard for M7.
- Content-Type on every response is `application/json`.
- `total` is a JSON number everywhere it appears. This is the guard for M1.
- `note`, when the key is present, is a string. This is the guard for M2.

**Layer 3: GET /orders/{id}.**

| Test | Request | Expected |
|---|---|---|
| G1 happy path | id of a seeded order with a note | 200, validates as `Order`, `id` equals the path id |
| G2 no note | id of a seeded order with no note | 200, `note` key absent. Flip to `note: null` if M2 is resolved by making the spec nullable. |
| G3 status coverage | one seeded order per enum value | 200 with `status` equal to `placed`, `paid`, `shipped` respectively |
| G4 not found | id with no order, e.g. 999999 | 404, validates as `Error`, `code` present and stable across runs. Regression for M3. |
| G5 below minimum | id = 0 | 400 with `Error`, not 404 and not 500. Requires the spec gap above to be closed. |
| G6 negative | id = -1 | Same as G5 |
| G7 non-integer | id = `abc`, id = `1.5`, id = `1e3` | Same as G5 |
| G8 overflow | id = 9223372036854775808 | 400 or 404, never 500 |
| G9 total precision | seeded order with total 42.50 | `total` is numeric and equals 42.5 within float tolerance. Regression for M1. |

**Layer 4: POST /orders.**

| Test | Body | Expected |
|---|---|---|
| P1 minimal valid | `{"items": ["sku-1"]}` | 201, validates as `Order`, `status` is `placed`, `total` is a number, `note` absent |
| P2 with note | `{"items": ["sku-1"], "note": "hello"}` | 201, `note` echoed back as `"hello"` |
| P3 round trip | P1 then GET the returned id | GET body equals the POST body field for field |
| P4 empty items | `{"items": []}` | 400 with `Error` |
| P5 items missing | `{"note": "x"}` | 400 with `Error` |
| P6 items wrong element type | `{"items": [1, 2]}` | 400 with `Error` |
| P7 items wrong type | `{"items": "sku-1"}` | 400 with `Error` |
| P8 note wrong type | `{"items": ["sku-1"], "note": 42}` | 400 with `Error` |
| P9 note explicit null | `{"items": ["sku-1"], "note": null}` | 400 with `Error` under the current spec. Flip to 201 if M2 is resolved with `nullable: true`. |
| P10 no body | empty request body | 400 with `Error` |
| P11 malformed JSON | `{"items": [` | 400 with `Error` |
| P12 wrong content type | valid body sent as `text/plain` | 400 or 415 with `Error`, and 415 must be added to the spec if chosen |
| P13 unknown field | `{"items": ["sku-1"], "colour": "red"}` | 201 and the field is ignored, or 400. Either is acceptable, but the choice must be documented in the spec with `additionalProperties`. |
| P14 note at limit | note of exactly 500 characters | 201 |
| P15 note one over | note of 501 characters | 400 with `Error`, never 500. Primary regression for M4, M5, M6. |
| P16 note far over | note of 5,000 characters, the recorded case | 400 with `Error`. Direct replay of recording 3. |
| P17 note multibyte at limit | 500 characters of a 4-byte emoji, 2,000 bytes | 201. Confirms the limit is counted in characters at both the validator and the column. |
| P18 note multibyte over | 501 characters of a 4-byte emoji | 400 with `Error` |
| P19 very large items array | 10,000 one-character skus | 201 or 400, never 500. Exposes any undocumented limit on `items`, which the spec should then declare with `maxItems`. |
| P20 sku length | a single sku of 5,000 characters | 201 or 400, never 500. Same reasoning as P19 for the item string length. |

**Layer 5: regression pins for the recorded failures.** Each mismatch gets one named test that replays the exact recorded request and asserts the corrected behaviour, so the suite reads as a changelog of what broke on 2026-10-15.

- M1 is pinned by G9.
- M2 is pinned by G2.
- M3 is pinned by G4.
- M4, M5 and M6 are pinned by P16.
- M7 is pinned by the global error-content invariant in Layer 2, exercised by P15 and P16.

**Ordering of fixes before the suite can go green.** P15 through P18 and G5 through G7 will fail until the spec gains `maxLength: 500` on `note` and a documented 400 for the path parameter. Those two spec edits should land in the same change as the server fixes, otherwise the contract validator will flag the corrected server responses as undocumented.
