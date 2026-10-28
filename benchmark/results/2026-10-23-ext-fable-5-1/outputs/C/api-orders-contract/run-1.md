All 3 recorded responses break the contract. Recording 1 has 2 field mismatches, recording 2 is missing a required field, and recording 3 returns a status and body the contract does not define.

Assumptions made where the contract or recordings are silent:

- Order 1042 exists on staging and 999999 does not. The tests below do not rely on this. They create their own orders through POST.
- The failed POST in recording 3 did not store an order. A test checks this rather than trusting it.
- The 500-character limit on `note` is the intended business limit, so the contract should declare it. Widening the database column is the alternative if product wants longer notes.
- A newly created order has the status `placed`.
- Unknown request fields are ignored.
- No authentication is in scope. The contract defines none.

## Mismatches

| # | Recording | What | Contract says | API returned | Impact | Fix |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1, GET existing order | `total` | number | the string `"42.50"` | High. Typed clients fail to parse or silently treat money as text. | Return a JSON number. If decimal precision is the reason for the string, change the contract to a string with a decimal format and bump the major version, because that is a breaking change. |
| 2 | 1, GET existing order | `note` | string, not nullable in OpenAPI 3.0.3 | `null` | Medium. Strict validators reject the response. | Omit `note` when the order has none, or add `nullable: true` to `Order.note`. |
| 3 | 2, GET missing order | `code` | required string | absent | Medium. Clients that branch on `code` get nothing to branch on. | Add a stable code such as `order_not_found`. |
| 4 | 3, POST with a 5,000-character note | status | `201` or `400` only | `500` | High. A valid request under the contract crashes the server. | Validate the note length before writing to the database and return `400`. |
| 5 | 3, POST with a 5,000-character note | body | `Error` object with `code` and `message` | `{"error": "..."}` | High. Error handling written to the contract cannot read this body. | Send every error, including unexpected ones, in the `Error` shape. |
| 6 | 3, POST with a 5,000-character note | message text | not covered | the raw database error | Medium. The text reveals the column type and the database product. | Never pass database errors to clients. Log them and return a generic message. |
| 7 | 3, POST with a 5,000-character note | `note` length | no limit | fails above 500 characters | Medium. The contract promises something the API cannot store. | Add `maxLength: 500` to `NewOrder.note`. |

Recording 1 is correct for `id` and `status`. Recording 2 has a correct `message`. No recording is fully compliant.

The recordings also expose places where the contract is silent, so the API can pass and still surprise clients:

- GET `/orders/{id}` sets `minimum: 1` but documents no response for an invalid id. The API needs a defined `400` for `0`, negative numbers and non-integers.
- Item strings have no `maxLength`. The same database limit that broke `note` may break a long item value.
- The status of a newly created order is not documented.
- No `default` response exists, so unexpected errors have no promised shape.
- Nothing says whether unknown request fields are ignored or rejected.

## Tests this API needs

Run 3 checks on every response in every test below, so each test covers the contract as well as the case:

1. The status code is listed in the contract for that path and method. Any other status fails the test, including `500`.
2. The body validates against the schema the contract names for that status, with nullable off.
3. The body contains none of the strings `character varying`, `SQL`, `Traceback` or `Exception`.

Each test creates the orders it needs through POST and reads back the returned id. No test depends on seeded data.

GET `/orders/{id}`:

| ID | Request | Expected status | Checks |
| --- | --- | --- | --- |
| G1 | id of an order created in setup | 200 | `total` is a JSON number. `status` is one of `placed`, `paid`, `shipped`. `note` is a string or absent. Regression for mismatches 1 and 2. |
| G2 | id that was never created | 404 | `code` and `message` present. Regression for mismatch 3. |
| G3 | id `0` | 400, assumed | `Error` body. |
| G4 | id `-1` | 400, assumed | `Error` body. |
| G5 | id `abc` | 400, assumed | `Error` body. |
| G6 | id `1.5` | 400, assumed | `Error` body. |
| G7 | id `9223372036854775808` | 400 or 404 | Never 500. |
| G8 | id returned by a POST in the same test | 200 | `id`, `status`, `total` and `note` equal the 201 body. |

POST `/orders`:

| ID | Request body | Expected status | Checks |
| --- | --- | --- | --- |
| P1 | 1 item, no `note` | 201 | `id` is an integer of 1 or more. `status` is `placed`. `note` is absent. |
| P2 | 3 items and a 1-character `note` | 201 | `note` is returned unchanged. |
| P3 | `note` of exactly 500 characters | 201 | A GET on the new id returns all 500 characters. |
| P4 | `note` of 501 characters | 400 | `Error` body. No order was created. |
| P5 | `note` of 5,000 characters | 400 | `Error` body with a code. No database text. A GET on any id in the response, if present, returns 404. Regression for mismatches 4 to 7. |
| P6 | `items` is `[]` | 400 | `Error` body. |
| P7 | `items` missing | 400 | `Error` body. |
| P8 | `items` is the string `sku-1` | 400 | `Error` body. |
| P9 | `items` is `[1]` and, separately, `[null]` | 400 | `Error` body. |
| P10 | `note` is `123` | 400 | `Error` body. |
| P11 | `note` is `null` | 400, assumed | Decide with product. If `null` should be allowed, expect 201 with `note` absent and update the contract. |
| P12 | empty body | 400 | `Error` body. |
| P13 | malformed JSON | 400 | `Error` body, not a framework error page. |
| P14 | valid JSON sent as `text/plain` | 400 or 415 | `Error` body. Never 500. |
| P15 | valid order plus an unknown field | 201, assumed | The unknown field is not echoed back. |
| P16 | 1 item of 5,000 characters | 201 or 400 | Never 500. Probes the same storage limit as `note`. |
| P17 | the same item listed twice | 201, assumed | Both items accepted. Decide with product if duplicates should fail. |

Two further tests apply across both endpoints:

- Every response, including every error, carries `Content-Type: application/json`.
- A property-based run generates requests from the contract and fails on any undocumented status. A tool such as Schemathesis does this from the spec file with no extra test code.

## Recommended contract changes

Make these in the same change as the code fixes, so the tests above have a stable target:

- `NewOrder.note`: add `maxLength: 500`.
- `NewOrder.items.items`: add a `maxLength` that matches storage.
- `Order.note`: add `nullable: true`, or state in the description that the field is absent when empty.
- `Order.total`: keep `number`, or move to a decimal string in a new major version.
- `Error.code`: list the codes as an enum, such as `invalid_order`, `note_too_long` and `order_not_found`.
- GET `/orders/{id}`: add a `400` response using `Error`.
- Both operations: add a `default` response using `Error`, so unexpected failures have a documented shape.
- `NewOrder`: add `additionalProperties: false` if unknown fields should be rejected instead of ignored.
- POST `/orders` description: state that a new order starts as `placed`.
