# Orders API 2.1.0: contract check and test design

**Result:** all 3 recorded responses break the contract. Two are response-shape bugs in the service. One is a server error that the contract does not allow and that leaks database internals. The contract itself has 4 gaps that the tests below also cover.

Assumptions, because the recording does not say:

- The recorded bodies are complete and were sent with `Content-Type: application/json`.
- The 5,000-character note was plain ASCII.
- The staging build is the same code as version 2.1.0 of the contract.
- A new order starts with status `placed`. The contract does not say.
- Unknown request fields are ignored. The contract does not say.
- The failed POST in recording 3 did not create an order. This is unverified and test P18 checks it.

## Mismatches

| # | Recording | What the contract says | What the server did | Severity |
| --- | --- | --- | --- | --- |
| 1 | GET /orders/1042, field `total` | `total` is a `number` | Sent the string `"42.50"` | High. Clients that do arithmetic on `total` or validate against the schema fail. |
| 2 | GET /orders/1042, field `note` | `note` is a `string` and is not marked `nullable` | Sent `null` | Medium. In OpenAPI 3.0.3 a property without `nullable: true` rejects `null`. Either omit the field or mark it nullable. |
| 3 | GET /orders/999999, 404 body | `Error` requires `code` and `message` | Sent only `message` | High. Clients that branch on `code` cannot handle the error. |
| 4 | POST /orders, status | Only `201` and `400` are documented | Returned `500` | High. An oversized note is a client mistake and must be a `400`. |
| 5 | POST /orders, 500 body | Every error body is an `Error` with `code` and `message` | Sent `{"error": "..."}` | High. The body matches no schema in the contract. |
| 6 | POST /orders, 500 body text | Nothing about the storage layer | Exposed the PostgreSQL column type `character varying(500)` | Medium, security. Internal error text tells attackers about the database and schema. |
| 7 | POST /orders, note length | `note` has no `maxLength` | The database rejects anything over 500 characters | Medium, contract gap. The limit is real but undocumented, so clients cannot validate before sending. |

Contract gaps that no recording hit but the tests cover:

- `GET /orders/{id}` documents no response for an `id` that fails `minimum: 1` or is not an integer. Assumed: `400` with an `Error` body.
- `POST /orders` documents no response for an unknown SKU in `items`. Assumed: `400` with an `Error` body.
- Neither operation documents a generic `5xx`. The tests treat any `5xx` as a failure.
- The contract does not say whether the database limit of 500 counts characters or bytes. Test P7 settles it.

Recommended contract fixes, in priority order:

1. Make the server send `total` as a JSON number. Do not change the contract to `string`. If decimal precision matters, add `format: decimal` and document the number of decimal places.
2. Add `maxLength: 500` to `note` in `NewOrder` and in `Order`.
3. Decide on `note`: either add `nullable: true` or make the server omit the field when there is no note. Omitting is simpler for clients.
4. Add a `400` response to `GET /orders/{id}` for invalid ids.
5. Make every error path, including unexpected failures, return an `Error` body with a stable `code` and a message that contains no database or stack text.

## Test design

All tests run against the OpenAPI document with a schema validator in the test harness, so every response is checked for status, `Content-Type`, and body shape without a hand-written assertion per field. Three assertions apply to every test and are not repeated in the tables:

- The status code is one the contract lists for that operation. Any `5xx` fails the test.
- Every non-`2xx` body validates against `Error`. The body never contains `character varying`, `SQL`, `pg_`, `Exception`, or a stack trace.
- `Content-Type` is `application/json`.

**GET /orders/{id}**

| ID | Request | Expected | Catches |
| --- | --- | --- | --- |
| G1 | id of an existing paid order | `200`, body validates against `Order`, `total` is a JSON number, `status` is in the enum | Mismatch 1 |
| G2 | id of an order with no note | `200`, `note` is absent or, if the contract adopts `nullable`, is `null` | Mismatch 2 |
| G3 | id of an order with a note | `200`, `note` is the stored string | Note round-trip |
| G4 | one order per `status` value: `placed`, `paid`, `shipped` | `200`, `status` matches the fixture | Enum drift between database and contract |
| G5 | id that does not exist | `404`, body has `code` and `message` | Mismatch 3 |
| G6 | id `0` | `400`, `Error` body | Gap: `minimum: 1` not enforced or not documented |
| G7 | id `-1` | `400`, `Error` body | Same as G6 |
| G8 | id `abc` | `400`, `Error` body | Non-integer path parameter |
| G9 | id `1.5` | `400`, `Error` body | Non-integer path parameter |
| G10 | id `9223372036854775808`, one above a signed 64-bit integer | `400` or `404`, never `500` | Integer overflow in the id parser or database |
| G11 | orders with total `0`, `0.1`, `1234567.89` | `200`, `total` is a number equal to the fixture value | Rounding and float conversion once mismatch 1 is fixed |

**POST /orders**

| ID | Request body | Expected | Catches |
| --- | --- | --- | --- |
| P1 | `{"items": ["sku-1"]}` | `201`, body validates against `Order`, `id` is at least 1, `status` is `placed`, `total` is a number | Happy path and the default status assumption |
| P2 | `{"items": ["sku-1"], "note": "hello"}` | `201`, `note` is `"hello"` | Note is stored |
| P3 | `{"items": ["sku-1", "sku-2", "sku-1"]}` | `201`, `total` reflects all 3 lines | Duplicate SKUs are allowed and counted |
| P4 | note of exactly 500 characters | `201` | Upper boundary accepted |
| P5 | note of 501 characters | `400`, `Error` body | Mismatches 4, 5, 6 at the boundary |
| P6 | note of 5,000 characters | `400`, `Error` body | The recorded failure, as a regression test |
| P7 | note of 500 four-byte characters, for example 500 emoji | `201` | Whether the limit counts characters or bytes. If this returns `400`, the contract must state the byte limit. |
| P8 | `{"items": []}` | `400`, `Error` body | `minItems: 1` |
| P9 | `{}` | `400`, `Error` body | `items` is required |
| P10 | `{"items": "sku-1"}` | `400`, `Error` body | `items` must be an array |
| P11 | `{"items": [1, null]}` | `400`, `Error` body | Array elements must be strings |
| P12 | `{"items": ["sku-1"], "note": null}` | `400`, or `201` with `note` absent. Pick one and document it. | Null handling matches the `note` decision |
| P13 | `{"items": ["sku-1"], "extra": true}` | `201`, `extra` is not echoed | Unknown fields are ignored, per the assumption |
| P14 | `{"items": ["no-such-sku"]}` | `400`, `Error` body | Gap: unknown SKU behaviour is undocumented |
| P15 | empty body | `400`, `Error` body | `requestBody` is required |
| P16 | `{"items": ["sku-1"]` with a missing brace | `400`, `Error` body | Malformed JSON does not reach the database |
| P17 | valid body with `Content-Type: text/plain` | `400` or `415`, `Error` body | Content negotiation. The contract should document which. |
| P18 | run P6, then count orders or GET the next id | No new order exists | The failed insert did not leave a partial row |
| P19 | run P2, then GET the returned id | `200`, the same `id`, `status`, `total`, and `note` as the `201` body | POST and GET agree on one order |

**Security and robustness**

| ID | Check | Expected |
| --- | --- | --- |
| S1 | For every `4xx` and `5xx` across all tests, scan the body | No database, driver, framework, or file-path text. Covers mismatch 6. |
| S2 | note containing `'; DROP TABLE orders; --` | `201`, note stored verbatim, table still present |
| S3 | note containing `<script>alert(1)</script>` | `201`, note returned verbatim as a JSON string, not altered or stripped |
| S4 | body of 1 MB with a valid shape | `400` or `413`, never `500`, response within the normal timeout |
| S5 | 200 concurrent valid POSTs | All return `201` with distinct ids |

**How to run them**

- Put the contract-validation tests in CI on every pull request. A tool that generates cases from the OpenAPI file, such as Schemathesis, covers G6 to G10 and P8 to P16 with little hand-written code and keeps them in step when the contract changes.
- Keep G1 to G5, P1 to P7, P18, P19, and S1 to S5 as explicit tests with fixtures, because they encode business rules the schema cannot express.
- Run the full set against staging after each deploy and compare with the contract version in the deployed build's `info.version`.

**Why mismatch 1 is the first fix.** A string `total` passes casual inspection and breaks silently in any client that sums or compares totals. The other mismatches produce visible errors. This one produces wrong numbers.
