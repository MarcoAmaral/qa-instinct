## Contract mismatches

Every recorded response deviates from the 2.1.0 contract. Seven distinct mismatches, two of them severe enough to break typed clients.

| # | Response | Where | Contract says | Observed | Impact |
|---|---|---|---|---|---|
| M1 | 1 (200) | `total` | `number` | string `"42.50"` | High. Typed clients and schema validators reject the body. Likely a decimal column serialised as text. |
| M2 | 1 (200) | `note` | `string`, not nullable | `null` | Medium. OpenAPI 3.0.3 needs `nullable: true` for null to be valid. Server should omit the key or contract must change. |
| M3 | 2 (404) | `code` | required | absent | Medium. Clients that branch on `code` cannot. |
| M4 | 3 | status | only `201` and `400` are documented | `500` | High. A contract-valid request produced an undocumented status. |
| M5 | 3 | body shape | `Error` with `code` and `message` | `{"error": "..."}` | High. Wrong property name, both required fields missing. |
| M6 | 3 | `note` length | no `maxLength`, so a 5,000-char note is valid | rejected by a database column limit | High. Either the contract is missing `maxLength: 500` or the storage is too small. The server lets the database do input validation that the request layer should do. |
| M7 | 3 | error text | not specified | leaks database column type and driver message | Medium, security. Internal implementation detail exposed to callers. |

What did conform: the status codes on responses 1 and 2, `id` as integer, `status` within the enum, and no unexpected extra properties on response 1.

Contract gaps surfaced by the review, not mismatches but things the spec does not cover and the tests will need an answer for:

- **Invalid path ids.** `id` has `minimum: 1` but GET documents no `400`. Behaviour for `0`, negatives, and non-integers is undefined.
- **No bounds on `items`.** No `maxItems`, no `maxLength` or pattern on each SKU string. Same failure class as M6 waiting to happen.
- **`Order` omits `items`.** A created order cannot be read back with what was ordered. Possibly intentional, worth confirming.
- **No `code` vocabulary.** `Error.code` is a free string, so clients cannot branch on it reliably.
- **Initial `status` after POST** is not stated.

Assumptions used throughout: the contract is the source of truth and server deviations are bugs. The 500-character limit is the intended business limit, so the fix is `maxLength: 500` in the contract plus a `400` from the request layer. Responses were served with `Content-Type: application/json`, since headers were not recorded. Invalid path ids should return `400` with an `Error` body. A new order starts as `placed`. Pricing is out of scope, so `total` is only asserted to be a non-negative number.

## Test design

Approach: a pytest suite with a single response-validation fixture that loads the spec and asserts, for every call, that the status code is documented for that operation, the content type is JSON, and the body validates against the schema for that status. Null in a non-nullable field and string-typed numbers fail here automatically, which catches M1, M2, M3, M4 and M5 without per-test assertions. Complemented by a Schemathesis run over the spec for generated inputs. Test data is created through POST in setup rather than relying on a pre-seeded id like 1042, so the suite is deterministic across environments.

**Regression tests for the three recordings.** Each pinned to the exact request that was recorded, so the fix is verifiable and the defect cannot return.

| ID | Request | Expected | Currently |
|---|---|---|---|
| R1 | GET existing order | `200`, `total` is a JSON number, `note` absent or string | Fails M1, M2 |
| R2 | GET unknown id | `404`, body has `code` and `message` | Fails M3 |
| R3 | POST note of 5,000 chars | `400`, `Error` body, message contains no database or driver text | Fails M4 to M7 |

**GET /orders/{id}**

| ID | Case | Expected |
|---|---|---|
| G1 | Order created in setup, fetched by id | `200`, `Order` schema, `id` matches, `status` in enum |
| G2 | Order created without a note | `note` key omitted, never `null` |
| G3 | Order created with a note | `note` round-trips byte-for-byte |
| G4 | Unknown id | `404`, `Error` schema |
| G5 | id `0` | `400`, `Error` schema, never `404` or `500` |
| G6 | Negative id | `400` |
| G7 | Non-integer id such as `abc`, `1.5`, `1e3` | `400` |
| G8 | id above 64-bit range | `400`, never `500` |
| G9 | Wrong method such as DELETE | `405` or `404`, never `500`, body is `Error` |

**POST /orders**

| ID | Case | Expected |
|---|---|---|
| P1 | Minimal valid body, one item | `201`, `Order` schema, `status` is `placed`, `total` is number ≥ 0 |
| P2 | Created order fetched by returned id | `200`, identical `Order` |
| P3 | Note of exactly 500 chars | `201`, note round-trips |
| P4 | Note of 501 chars | `400`, `Error` schema |
| P5 | Note of 500 multi-byte chars such as emoji | `201`. Verifies the limit counts characters, not bytes |
| P6 | Note that is empty string | `201`, stored as empty or omitted, documented either way |
| P7 | `items` missing | `400` |
| P8 | `items` is `[]` | `400`, exercises `minItems` |
| P9 | `items` contains a number, `null`, or an object | `400` |
| P10 | `items` is a string rather than an array | `400` |
| P11 | `note` is a number or object | `400` |
| P12 | Body is malformed JSON | `400`, `Error` schema, no parser stack trace |
| P13 | Empty body | `400` |
| P14 | `Content-Type: text/plain` with a JSON body | `400` or `415`, contract decision needed, never `500` |
| P15 | Unknown extra property | `201`, since `additionalProperties` is not false. Documents current tolerance |
| P16 | Items array with 10,000 entries | `400` or `201`, never `500`. Forces the `maxItems` decision |
| P17 | Single SKU string of 10,000 chars | `400` or `201`, never `500`. Same as P16 for `maxLength` |
| P18 | Every `4xx` body | `message` contains no database, SQL, or stack text |

**Generated and cross-cutting**

| ID | Case | Expected |
|---|---|---|
| X1 | Schemathesis over both operations, negative and positive data | No `5xx`, every response conforms to the spec |
| X2 | Every error response across the suite | `code` is from a fixed, documented set once one exists |
| X3 | Spec lint in CI | Spec validates, and every status the server can emit is documented |

**Decisions the suite is blocked on.** Everything else runs now under the stated assumptions.

1. **`total` type.** Keep `number` and fix the serialiser, or move to a decimal string. A string is safer for money but is a breaking change for current clients and needs a major version bump.
2. **`note` absence.** Omit the key, matching the contract as written, or add `nullable: true`. Recommend omitting.
3. **Length limits.** Confirm 500 for `note`, and choose values for `maxItems` and per-item `maxLength` so P16 and P17 have a definite answer.
4. **Invalid path ids.** Add a documented `400` to GET so G5 to G8 have a contractual expectation.
