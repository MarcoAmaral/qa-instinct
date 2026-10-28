All 3 recorded responses break the contract. There are 7 mismatches, 2 of which are the same bug seen from the server side and from the spec side. The 500 on a 5,000-character note is the only one that fails a valid request outright. The other 6 are shape errors that break any client that validates responses against the spec.

## Mismatches

| # | Recorded response | Contract says | Mismatch | Fix on |
| --- | --- | --- | --- | --- |
| M1 | GET /orders/1042: `"total": "42.50"` | `Order.total` is `number` | Value is a JSON string, not a number. A typed client fails to parse it. | Server, or spec (see note below) |
| M2 | GET /orders/1042: `"note": null` | `Order.note` is `string` with no `nullable: true` | In OpenAPI 3.0.3, `null` is not a valid string unless the property is marked nullable. | Server should omit the key, or spec should add `nullable: true` |
| M3 | GET /orders/999999: `{"message": "Order not found"}` | `Error` requires `code` and `message` | Required field `code` is missing. | Server |
| M4 | POST /orders: status 500 | Only 201 and 400 are documented | Undocumented status code for a request that is valid under `NewOrder`. | Server (return 400 after M6) |
| M5 | POST /orders: `{"error": "..."}` | 400 and 404 bodies use `Error` | Body uses an `error` key instead of `code` and `message`. The 500 body does not match any documented schema. | Server |
| M6 | POST /orders: note of 5,000 characters rejected by storage | `NewOrder.note` has no `maxLength` | The spec promises to accept notes of any length. Storage accepts 500. The contract and the server disagree on what a valid order is. | Spec (`maxLength: 500`) and server (validate before the write) |
| M7 | POST /orders: `"value too long for type character varying(500)"` | Error bodies carry a `code` and a human-readable `message` | The message is a raw database error. It reveals the storage engine and column size to any caller. | Server |

**On M1.** Returning money as a string is often deliberate, because JSON numbers lose decimal precision in some clients. If that is the intent, the spec is wrong, not the server. Change `total` to `type: string` with a pattern such as `^\d+\.\d{2}$`, or to an integer of minor units. Either way, pick one and make both sides agree.

**Gaps found while checking.** These are not mismatches, because the recordings do not exercise them, but the tests below need an answer for each.

- The spec documents no response for an `id` that is not an integer or is below 1. A request such as `GET /orders/abc` or `GET /orders/0` has no defined outcome.
- The spec documents no response for a missing or wrong `Content-Type`, or for malformed JSON.
- `NewOrder.items` has no `maxItems`, and each item string has no `maxLength`. Anything with a storage limit behind it will fail the same way M4 did.
- `Error.code` has no enum or documented values, so clients cannot branch on it.

## Test plan

Run every test in 2 layers. The first layer asserts the status code and the business outcome. The second layer validates the response body against the schema the spec assigns to that status code, and fails on any status code the spec does not list. A spec-driven validator such as Schemathesis or openapi-core gives the second layer for free and also fuzzes every field.

**GET /orders/{id}**

| ID | Request | Expect | Guards against |
| --- | --- | --- | --- |
| G1 | Existing id | 200. Body validates as `Order`. `id` equals the path id. `total` is a JSON number. `status` is one of the 3 enum values. | M1, M2 |
| G2 | Existing order with no note | 200. `note` is absent, not `null`. | M2 |
| G3 | Existing order with a note | 200. `note` is the stored string. | Regression for M2 fix |
| G4 | Unknown id, such as 999999 | 404. Body validates as `Error` with non-empty `code` and `message`. | M3 |
| G5 | id = 1 | 200 or 404. Never 5xx. | Boundary at `minimum: 1` |
| G6 | id = 0, id = -1 | 400 with `Error` body. | Gap: undefined response |
| G7 | id = `abc`, id = `1.5`, id = `1e3` | 400 with `Error` body. | Gap: undefined response |
| G8 | id = 9223372036854775808 (above 64-bit) | 400 or 404 with `Error` body. Never 5xx. | Integer overflow in path parsing |
| G9 | One order per status value: placed, paid, shipped | 200. `status` matches exactly, lowercase. | Enum drift, such as `Paid` or `cancelled` leaking |
| G10 | Any of the above | `Content-Type: application/json` on every response. | Missing header |

**POST /orders**

| ID | Request | Expect | Guards against |
| --- | --- | --- | --- |
| P1 | `{"items": ["sku-1"]}` | 201. Body validates as `Order`. `status` is `placed`. `note` absent. | Happy path |
| P2 | Valid items, note of 1 character | 201. `note` echoed back. | Happy path with note |
| P3 | Valid items, note of exactly 500 characters | 201. | Boundary at `maxLength` |
| P4 | Valid items, note of 501 characters | 400 with `Error`. | Boundary at `maxLength` |
| P5 | Valid items, note of 5,000 characters | 400 with `Error`. Never 500. | Regression for M4, M5, M6 |
| P6 | Valid items, note of 500 multi-byte characters, such as emoji | 201. | Character count versus byte count |
| P7 | Body with no `items` key | 400 with `Error`. | `required` |
| P8 | `{"items": []}` | 400 with `Error`. | `minItems: 1` |
| P9 | `{"items": "sku-1"}` | 400 with `Error`. | `type: array` |
| P10 | `{"items": [1, null, {}]}` | 400 with `Error`. | `items.type: string` |
| P11 | `{"items": ["sku-1"], "note": 42}` and `"note": null` | 400 with `Error`. | `note.type: string` |
| P12 | Empty body | 400 with `Error`. | `requestBody.required` |
| P13 | Malformed JSON, such as `{"items": [` | 400 with `Error`. Never 5xx. | Gap: undefined response |
| P14 | Valid body sent as `text/plain` | 400 or 415 with `Error`. | Gap: undefined response |
| P15 | Valid body plus an unknown key, such as `{"items": ["sku-1"], "foo": 1}` | Either 201 with the key ignored, or 400. Pin whichever the team chooses. | Undocumented `additionalProperties` behaviour |
| P16 | 10,000 items | A documented status. Never 5xx. | Gap: no `maxItems` |
| P17 | One item string of 10,000 characters | A documented status. Never 5xx. | Gap: no item `maxLength` |
| P18 | POST then GET the returned id | GET returns 200 with the same `id`, `status`, `total` and `note`. | Round trip and persistence |
| P19 | Any 400 or 404 | `message` does not match `/character varying|sql|constraint|exception|stack/i`. | M7, internal error leakage |

**Cross-cutting**

| ID | Check | Guards against |
| --- | --- | --- |
| X1 | Every response, in every test, validates against the schema for its status code. Any status code not in the spec fails. | M1 to M5 as a class |
| X2 | Property-based fuzz of both endpoints from the spec. Assert no 5xx and no undocumented status. | Unknown inputs that reach storage unvalidated |
| X3 | Lint the spec itself: every optional property that can be null has `nullable: true`, every string that hits a column has `maxLength`, every array has `maxItems`. | M2, M6 recurring in future fields |
| X4 | Compare `info.version` in the served spec with the deployed version. | Testing against a stale contract |

Tests P3, P4 and P5 need M6 decided first. Tests G6, G7, P13 and P14 need the gaps decided first. Until then, assert only that the response is not 5xx and carries an `Error` body.

## Assumptions and open decisions

- **The deliverable is an engineering report.** The help-center article template with frontmatter does not fit a contract review, so I used the plain-language rules only.
- **The 500-character limit is the intended product limit.** The fix is to declare it in the spec and reject longer notes with 400, not to widen the column. If the product wants longer notes, swap P3 to P5 to the new limit.
- **A new order starts as `placed`.** The spec does not say. P1 pins it so a change is noticed.
- **Optional fields are omitted rather than sent as `null`.** If the team prefers `nullable: true` in the spec, invert G2 and P11's null case.
- **Invalid path ids and malformed bodies return 400 with an `Error` body.** The spec is silent. Add these responses to the spec at the same time as the tests.
- **Content-Type headers were not recorded.** G10 assumes the server sends `application/json`.
- **Staging at version 2.1.0 matches what production serves.** X4 checks this on each run.
