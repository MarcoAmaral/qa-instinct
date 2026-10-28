## Contract check: Orders API 2.1.0, staging, 2026-10-15

All 3 recorded responses break the contract. The deployed version matches the contract version, so these are implementation defects, not version drift.

### Mismatches

| # | Request | Where | Contract says | Response has | Severity |
| --- | --- | --- | --- | --- | --- |
| 1a | GET /orders/1042 | `Order.total` | `number` | `"42.50"`, a string | High. Clients that do arithmetic on `total` fail or silently concatenate. |
| 1b | GET /orders/1042 | `Order.note` | `string`, not nullable | `null` | Medium. OpenAPI 3.0.3 needs `nullable: true` for null to be valid. An optional field with no value should be omitted. |
| 2a | GET /orders/999999 | `Error.code` | required | missing | Medium. Clients that branch on `code` cannot handle this error. |
| 3a | POST /orders, 5,000-char note | status | 201 or 400 only | 500 | High. 500 is undocumented for this operation. The request is valid under the contract, since `NewOrder.note` has no `maxLength`. |
| 3b | POST /orders, 5,000-char note | body | `Error` with `code` and `message` | `{"error": ...}`, neither field | Medium. Wrong shape and wrong key. |
| 3c | POST /orders, 5,000-char note | message text | an API-level message | raw database error naming a `character varying(500)` column | Medium. Leaks storage details to callers. |
| 3d | Contract vs. storage | `NewOrder.note` | no length limit | database stores 500 characters | Design gap. The contract promises more than the implementation can hold. |

### Contract gaps the recordings expose

These are not mismatches in the 3 recordings, but the contract leaves them undefined and the tests below need an answer.

- **Invalid path id.** `id` has `minimum: 1` and `type: integer`, but GET declares no 400. `/orders/0`, `/orders/-1` and `/orders/abc` have no documented outcome.
- **Status of a new order.** The contract does not say which `status` a POST returns. The enum suggests `placed`.
- **Unknown fields in the request.** `additionalProperties` is unset, so `{"items": ["sku-1"], "foo": 1}` is accepted by default. The contract should say so explicitly.
- **Unknown item strings.** `items` are free strings. Nothing says what happens when a string is not a known SKU.
- **Side effects on failure.** Nothing says whether a failed POST may leave a partial order behind.

### Assumptions

- `total` is a currency amount. The contract's `number` type wins until someone decides to change it. If the team prefers strings for exact decimals, the contract must change to `type: string` with a pattern, and clients must be told.
- The database column for `note` is `varchar(500)` and will not be widened. The fix is `maxLength: 500` on `NewOrder.note` and a 400 response. Either choice is acceptable, but 500 is not.
- Invalid path ids should return 400 with an `Error` body. The contract needs that response added.
- A new order starts as `placed`.
- `Error.code` values are stable, machine-readable strings such as `order_not_found` and `invalid_order`. The actual values are unknown.
- A failed POST creates nothing.

### Recommended contract changes

1. Add `maxLength: 500` to `NewOrder.note`.
2. Add `nullable: true` to `Order.note`, or make the server omit the field. Omitting is cleaner.
3. Add a 400 response to GET /orders/{id} for an invalid id.
4. Document the initial `status` of a new order.
5. Set `additionalProperties: false` on `NewOrder`, or state that unknown fields are ignored.
6. List the allowed `Error.code` values as an enum.

## Test design

### Layer 1: Contract validation on every response

Run one validator against every response in every test below. This layer alone would have caught all 7 findings.

- The status code is declared for that operation in the spec.
- The `Content-Type` is `application/json`.
- The body validates against the schema for that status, including types, required fields and enums.
- Every 4xx and 5xx body validates against `Error`.
- No error message contains database or framework text. Use a deny-list: `character varying`, `constraint`, `SQL`, `exception`, `stack`, `at line`.

### Layer 2: GET /orders/{id}

| Test | Request | Expect |
| --- | --- | --- |
| Existing order | GET /orders/1042 | 200. `id` is an integer, `total` is a JSON number, `status` is one of the 3 enum values. |
| Note omitted or string | an order with no note | 200. `note` is absent, or a string if the contract adopts `nullable`. Never `null` under the current contract. |
| Every status value | one order each in `placed`, `paid`, `shipped` | 200 with the matching `status`. |
| Unknown id | GET /orders/999999 | 404. Body has `code` and `message`. |
| Zero id | GET /orders/0 | 400 with `Error`. Not 404, not 500. |
| Negative id | GET /orders/-1 | 400 with `Error`. |
| Non-integer id | GET /orders/abc, GET /orders/1.5 | 400 with `Error`. |
| Oversized id | GET /orders/99999999999999999999 | 400 or 404 with `Error`. Not 500. |
| Round trip | POST then GET the returned `id` | The GET body equals the POST body. |

### Layer 3: POST /orders

Valid requests:

| Test | Body | Expect |
| --- | --- | --- |
| Minimal order | `{"items": ["sku-1"]}` | 201. `Order` body, `status` is `placed`, `total` is a number, `note` absent. |
| Order with note | `{"items": ["sku-1"], "note": "gift"}` | 201. `note` echoed back exactly. |
| Several items | `{"items": ["sku-1", "sku-2", "sku-1"]}` | 201. Duplicates accepted, since the contract does not forbid them. |
| Note at the limit | 500-character note | 201. Regression test for finding 3. |
| Multibyte note at the limit | 500 characters of 4-byte emoji | 201. Proves the limit counts characters, not bytes. |
| Unknown field | `{"items": ["sku-1"], "foo": 1}` | 201 or 400, whichever the contract decides. Never 500. |

Invalid requests. Each expects 400 with an `Error` body and no order created:

| Test | Body |
| --- | --- |
| Note over the limit | 501-character note. Regression test for finding 3. |
| Note far over the limit | 5,000-character note, the recorded case. |
| Empty items | `{"items": []}` |
| Missing items | `{"note": "x"}` |
| Items not an array | `{"items": "sku-1"}` |
| Item not a string | `{"items": [1]}`, `{"items": [null]}` |
| Note not a string | `{"items": ["sku-1"], "note": 5}` |
| Empty body | no body at all |
| Malformed JSON | `{"items": [` |
| Wrong content type | valid body sent as `text/plain` |
| Null body | `null` |

Side-effect check: after each invalid request, count orders or GET the most recent id. Nothing new may exist.

### Layer 4: Robustness

- **Fuzz the request body.** Generate random JSON against `NewOrder` with a property-based tool. Any 5xx is a failure.
- **Fuzz the path id.** Random strings, unicode, encoded slashes, very long values. Any 5xx is a failure.
- **Large valid payload.** 10,000 items of normal length. Expect 201 or a documented 413, not 500.

### Layer 5: Pin the contract in CI

- Lint the spec on every change, and fail if any operation lacks a 400 or 404 where parameters or lookups exist.
- Run Layers 1 to 3 against staging on every deploy.
- Record every response in those runs and diff them against the spec, so a future `"42.50"` is caught before release.
- Generate client types from the spec and compile the test suite against them. A string `total` then fails at build time.

### Regression tests for the 3 recorded findings

1. GET an order and assert `typeof total === "number"` and `"note" in body` is false when the note is empty.
2. GET an unknown id and assert `code` is present and non-empty.
3. POST a 5,000-character note and assert status 400, an `Error` body, no database text, and no new order.
