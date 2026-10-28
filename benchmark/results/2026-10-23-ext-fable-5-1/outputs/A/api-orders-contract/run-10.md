**Verdict:** all three recorded responses violate the contract. There are six distinct mismatches, plus one security finding and several contract gaps that the recordings expose. The spec is version 2.1.0 and so is the deployment, so none of this is version skew.

**Assumptions**

- The spec is the source of truth. Where the server disagrees, the server is wrong unless noted otherwise below.
- The recorded bodies are complete and were served with `Content-Type: application/json`. Headers were not captured, so content type is unverified.
- The 5,000-character note was plain ASCII. The database column is `varchar(500)`, which counts characters, so multibyte input needs its own test.
- Newly created orders start in status `placed`. The spec does not say.
- Unknown request properties are ignored, since no schema sets `additionalProperties: false`.
- Authentication is out of scope. The spec defines none.

## Mismatches

| # | Recording | Field or aspect | Contract says | Server did | Severity |
|---|---|---|---|---|---|
| 1 | GET /orders/1042 | `total` | `type: number` | Returned the string `"42.50"` | High. Any typed client deserialising `total` as a number breaks. |
| 2 | GET /orders/1042 | `note` | `type: string`, not nullable | Returned `null` | Medium. In OpenAPI 3.0.3 `null` is only valid with `nullable: true`. Omitting the key would have been valid because `note` is optional. |
| 3 | GET /orders/999999 | Error body | `code` and `message` both required | Only `message` present | Medium. Clients branching on `code` cannot. |
| 4 | POST /orders, long note | Status code | Only 201 and 400 are defined | Returned 500 | High. A request that is fully valid under `NewOrder` produced a server error. |
| 5 | POST /orders, long note | Error body | `Error` schema with `code` and `message` | `{"error": "..."}` matches no schema | Medium. Error handling is not funnelled through one shape. |
| 6 | POST /orders, long note | `NewOrder.note` | No `maxLength` | Server enforces 500 via the database | High. The constraint is real but undeclared. Either the spec gains `maxLength: 500` and the server validates it as a 400, or the column is widened. The former is the sensible fix. |

**Security finding, not a schema mismatch.** Recording 3 leaks a raw PostgreSQL error, including the column type. Error bodies must never carry database or stack text.

**Contract gaps the recordings expose.** These need a decision before the tests below can be pinned.

- GET /orders/{id} declares `minimum: 1` on `id` but defines no 400. The behaviour for `0`, negatives and non-integers is unspecified. Recommend adding a 400 response.
- `Order.note` must gain `nullable: true` or the server must omit the key. Omitting is cleaner.
- `Order.total` is `number`. If money is deliberately serialised as a string for precision, change the spec to `type: string` with a decimal pattern. Either choice is fine, but the two sides must agree. Tests below assert the spec as written.
- `Error.code` should be an enum of stable values, for example `ORDER_NOT_FOUND` and `VALIDATION_ERROR`, so clients can branch on it.
- Consider documenting 500 with the `Error` schema so even failures are contract-shaped and the schema validator can assert that.
- POST /orders has no `Location` header documented. Optional, but cheap to add.

## Test design

**Approach.** Two layers. First, a schema-conformance layer that runs every response from every test through an OpenAPI response validator, so status code, content type and body shape are checked automatically on each call. Second, explicit functional and boundary cases listed below. A property-based fuzzer driven from the spec, such as Schemathesis, should run alongside to find further undeclared 500s. Fixtures required: one order with a note, one without, one per `status` enum value, and a known-missing id.

**A. Conformance, applied to every response**

| ID | Assertion |
|---|---|
| A1 | Status code is one the spec lists for that operation. |
| A2 | Body validates against the schema declared for that status code. |
| A3 | `Content-Type` is `application/json`. |
| A4 | Every 4xx and 5xx body validates against `Error`, with non-empty `code` and `message`. |
| A5 | No body, at any status, matches a leak pattern such as `character varying`, `relation`, `syntax error`, `Traceback`, or `at .*\.java:`. |

**B. GET /orders/{id}**

| ID | Request | Expected | Currently |
|---|---|---|---|
| B1 | Existing id | 200. `id` equals the path. `status` in enum. `total` is a JSON number. | Fails on `total` |
| B2 | Existing order without a note | 200. `note` key absent, not `null`. | Fails |
| B3 | Existing order with a note | 200. `note` is a string. | Untested |
| B4 | One fixture per status `placed`, `paid`, `shipped` | 200 each, status echoed. | Untested |
| B5 | Unknown id, e.g. 999999 | 404. Body has `code` and `message`. | Fails on `code` |
| B6 | `id` = 0 | 400 with `Error`. Never 500. | Unspecified |
| B7 | `id` = -1 | 400 with `Error`. | Unspecified |
| B8 | `id` = `abc`, `1.5`, `1e3`, `  1` | 400 with `Error`. Never 500. | Unspecified |
| B9 | `id` = 9223372036854775808, beyond int64 | 400 or 404, never 500. | Unspecified |
| B10 | Unsupported method, e.g. DELETE /orders/1 | 405 with `Error`. | Unspecified |

**C. POST /orders, success paths**

| ID | Request body | Expected | Currently |
|---|---|---|---|
| C1 | `{"items":["sku-1"]}` | 201. Full `Order`. `status` is `placed`. `total` is a number. `note` absent. | Untested |
| C2 | Items plus a short note | 201. Note echoed verbatim. | Untested |
| C3 | Round trip: POST then GET the returned id | GET body equals POST body. | Untested |
| C4 | Several items, e.g. 50 skus | 201. | Untested |
| C5 | Note of exactly 500 characters | 201. | Untested |
| C6 | Note of 500 characters where each is a 4-byte emoji | 201. Proves the limit counts characters, not bytes. | Untested |
| C7 | Note of 5,000 characters | 400 with `Error`. Regression for recording 3. | Fails with 500 |
| C8 | Note of 501 characters | 400 with `Error`. Pins the boundary. | Fails with 500 |
| C9 | Empty string note | 201. Assumed accepted. | Untested |
| C10 | Unknown extra property, e.g. `"gift": true` | 201. Property ignored and not echoed. | Untested |
| C11 | Client supplies `id`, `status`, `total` in the body | 201. Server-assigned values win. | Untested |

**D. POST /orders, validation paths. All expect 400 with `Error`, never 500.**

| ID | Request |
|---|---|
| D1 | No body |
| D2 | Malformed JSON, e.g. `{"items":` |
| D3 | JSON that is not an object, e.g. `[]` or `"x"` |
| D4 | Missing `items` |
| D5 | `items` is `[]` |
| D6 | `items` is `null` |
| D7 | `items` is a string, number, or object |
| D8 | `items` contains a non-string: `[1]`, `[null]`, `[{}]`, `[""]` |
| D9 | `note` is `null` |
| D10 | `note` is a number, array, or object |
| D11 | `Content-Type: text/plain` with a valid JSON body. 400 or 415 is acceptable. Spec should pick one. |
| D12 | 10,000 items. 201 or 400 is acceptable, 500 is not. |
| D13 | A single item string of 100,000 characters. 201 or 400 is acceptable, 500 is not. |
| D14 | Body of several megabytes. 400 or 413, never 500 or a hang. |

**E. Regression pins for the three recordings**

| ID | Reproduces | Passes when |
|---|---|---|
| E1 | Recording 1 | `total` is a number and `note` is absent or a string. |
| E2 | Recording 2 | 404 body contains `code`. |
| E3 | Recording 3 | 400 with `Error`, and the body contains no database text. |

**Ordering of fixes so the suite can go green.** Add `maxLength: 500` to `NewOrder.note` and `Order.note`, add a 400 to GET /orders/{id}, enumerate `Error.code`, and decide the `total` type. Then fix the server to validate note length before the database, serialise `total` per the decision, omit `note` when null, and route every error through one `Error` serialiser.
