All 3 recorded responses break the contract. There are 6 mismatches, 1 security finding, and 6 places where the contract is silent and a decision is needed before tests can assert a result. The staging build reports the same version as the contract, so none of this is a version skew.

Assumptions made where the recordings are silent:

- The contract is the source of truth. Where server and contract disagree, the server is wrong unless the fix column says otherwise.
- The `note` column is a 500-character database column, as the error text says, and that limit is intended.
- A new order starts with status `placed`.
- Response headers were not recorded. Tests below assert `Content-Type: application/json` anyway.
- Recording 3 does not say whether the failed POST wrote a row. Tests treat "no row" as the required behaviour.

## Mismatches

| # | Recording | Contract | What is wrong | Severity | Fix |
| --- | --- | --- | --- | --- | --- |
| 1 | GET /orders/1042 returns `"total": "42.50"` | `Order.total` is `number` | Value is a JSON string | High. Typed clients fail to parse or do string maths. | Server: send `42.5` as a number. If 2 decimal places must survive, change the contract instead to `type: string, pattern: ^\d+\.\d{2}$` and bump the version. Choose one; do not leave both. |
| 2 | GET /orders/1042 returns `"note": null` | `Order.note` is `string` with no `nullable: true` | OpenAPI 3.0 does not allow null for a string | Medium | Server: omit the key when there is no note. Or contract: add `nullable: true` to both `Order.note` and `NewOrder.note`. |
| 3 | GET /orders/999999 returns `{"message": "Order not found"}` | `Error` requires `code` and `message` | `code` is missing | Medium. Clients that branch on `code` get undefined. | Server: add `"code": "order_not_found"`. |
| 4 | POST /orders returns 500 | Only 201 and 400 are documented | Undocumented status | High | Server: validate `note` length before the database and return 400. |
| 5 | POST /orders returns `{"error": "..."}` | `Error` requires `code` and `message` | Body matches no schema in the contract | High | Server: return `{"code": "note_too_long", "message": "note must be 500 characters or fewer"}`. |
| 6 | POST /orders rejects a 5,000-character note | `NewOrder.note` has no `maxLength`, so the request is valid | Contract allows what the server cannot store | High | Contract: add `maxLength: 500` to `NewOrder.note` and `Order.note`. Server: enforce it. |

Security finding: the 500 body repeats the database error text. It reveals the column type and that the store is SQL. Strip internal messages from every error body. This is a separate fix from #4, because a future 500 from another cause must not leak either.

## Gaps in the contract

These are not mismatches, because the contract says nothing. Each needs a decision, written into the contract, before the tests marked "gap" below can assert.

1. GET with an id that fails `minimum: 1` or is not an integer, such as `/orders/0` or `/orders/abc`. No response is documented. Recommend 400 with an `Error` body.
2. Unknown fields in the POST body. `additionalProperties` is unset, so the default allows them. Recommend documenting that they are ignored, or rejecting with 400.
3. `"note": null` in a POST body. The schema forbids it. Recommend 400, or make both schemas nullable as part of mismatch #2.
4. `Order` has no `items` field, but `NewOrder` requires one. A client cannot read back what it sent. Recommend adding `items` to `Order`.
5. No `maxItems` on `items` and no `maxLength` on each sku. Any size-limited column behind them will produce the same 500 as mismatch #4. Recommend limits.
6. POST with a non-JSON `Content-Type`. Recommend 415, or document 400.

## Tests

Three layers. Run them against every pull request on a local server and nightly against staging.

**Layer 1: automatic contract validation.** Every response from layers 2 and 3 passes through an OpenAPI response validator, for example Schemathesis, openapi-core or express-openapi-validator in test mode. A test fails if the status code is not listed for the operation or the body does not match the schema for that status. This layer alone catches mismatches 1 to 5. Add a property-based Schemathesis run that generates requests from the spec. That run would have found mismatch 6 before the recording did.

**Layer 2: GET /orders/{id}**

| ID | Request | Expected | Today |
| --- | --- | --- | --- |
| G1 | id of a known order | 200. `Order` schema. `id` equals the path id. `total` is a JSON number. `status` is in the enum. | Fails: #1, #2 |
| G2 | known order with no note | 200. `note` key absent, or null if the contract adopts nullable. | Fails: #2 |
| G3 | known order with a note | 200. `note` equals the stored string exactly. | Unknown |
| G4 | one order in each status: placed, paid, shipped | `status` matches. The test fails if any other string ever appears. | Unknown |
| G5 | orders with totals 0, 0.1, 999999.99 | JSON number, equal within 0.001. | Fails: #1 |
| G6 | unknown id, such as 999999 | 404. `Error` with `code` and `message`. | Fails: #3 |
| G7 | id = 0 | 400 `Error` (gap 1). Never 500. | Unknown |
| G8 | id = -1 | Same as G7. | Unknown |
| G9 | id = abc, 1.5, 1e3, 00042 | 400 `Error` (gap 1). Never 500. `00042` must not resolve to order 42 unless decided. | Unknown |
| G10 | id = 99999999999999999999 | 400 or 404, never 500. | Unknown |
| G11 | every response above | `Content-Type: application/json` on success and error alike. | Unknown |

**Layer 3: POST /orders**

| ID | Request | Expected | Today |
| --- | --- | --- | --- |
| P1 | `{"items": ["sku-1"]}` | 201. `Order` schema. `id` is an integer of 1 or more. `status` is `placed`. `total` is a number. `note` absent. | Unknown |
| P2 | items plus `"note": "hello"` | 201. `note` echoed exactly. | Unknown |
| P3 | note of exactly 500 characters | 201. Boundary. | Unknown |
| P4 | note of 501 characters | 400. `Error` with `code: note_too_long`. | Fails: #4, #5, #6 |
| P5 | note of 5,000 characters | Same as P4. Regression test for recording 3. | Fails |
| P6 | note of 500 four-byte characters, such as emoji | 201. Returned intact. Proves the limit counts characters, not bytes. | Unknown |
| P7 | `"note": ""` | Decide: 201 with `""`, or treated as absent. Assert the decision. | Unknown |
| P8 | `"note": null` | 400 (gap 3), or 201 if nullable is adopted. | Unknown |
| P9 | `"items": []` | 400 `Error`. | Unknown |
| P10 | `items` missing | 400 `Error`. | Unknown |
| P11 | `"items": "sku-1"` | 400 `Error`. | Unknown |
| P12 | `"items": [1]`, `[null]`, `[""]` | 400 for 1 and null. Decide for `""`. | Unknown |
| P13 | 10,000 items | 201 or 400 (gap 5). Never 500. | Unknown |
| P14 | one sku of 10,000 characters | 400 (gap 5). Never 500. | Unknown |
| P15 | empty body | 400 `Error`. | Unknown |
| P16 | malformed JSON such as `{"items": [` | 400 `Error` body. Not HTML, not plain text. | Unknown |
| P17 | valid JSON with `Content-Type: text/plain` | 415 or 400 (gap 6). | Unknown |
| P18 | `{"items": ["sku-1"], "foo": 1}` | Ignored or 400 (gap 2). | Unknown |
| P19 | after P1, GET /orders/{new id} | 200. Same `id`, `status`, `total`, `note`. | Unknown |
| P20 | after P4 and P5, check the store | No new order was written. Count unchanged. | Unknown |
| P21 | every 4xx and 5xx body in this suite | No SQL keywords, column names, stack traces or file paths. Regex check. | Fails: leak |
| P22 | `{"items": ["sku-1", "sku-1"]}` | Decide: 201 with both, or 400. Assert the decision. | Unknown |

**Method and route checks.** GET /orders without an id, and DELETE /orders/1, return 404 or 405 with an `Error` body. Never 500.

**Order of fixes.** First mismatches 4, 5 and 6 together with the leak, because any client can trigger them. Then 1 and 3, because they change how clients parse. Then 2. Each fix lands with its row above turned from "Fails" to passing, and the contract edits for gaps 1 to 6 land before the "gap" rows are enabled.
