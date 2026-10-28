# Orders API 2.1.0: contract check and test design

Staging on 2026-10-15 ran the same version the contract describes, so every difference below is drift between the contract and the code, not version skew.

**Assumptions:** responses were `application/json` (the recordings omit headers). The contract has no authentication, so tests run unauthenticated. The contract is the source of truth unless a row below says a decision is needed.

## Mismatches in the recorded responses

| # | Request | What the contract says | What staging returned | Severity |
| --- | --- | --- | --- | --- |
| 1a | `GET /orders/1042` | `Order.total` is a `number` | `"42.50"`, a string | High. Typed clients fail to parse the field. |
| 1b | `GET /orders/1042` | `Order.note` is a `string` and is not nullable | `null` | Medium. OpenAPI 3.0.3 rejects `null` unless the property has `nullable: true`. |
| 2 | `GET /orders/999999` | 404 body is `Error`, which requires `code` and `message` | `code` is missing | Medium. Clients that branch on `code` cannot handle this error. |
| 3a | `POST /orders` with a 5,000-character `note` | Only 201 and 400 are documented | 500 | High. Client input causes a server error, and the response is undocumented. |
| 3b | `POST /orders` with a 5,000-character `note` | Any error body is `Error` with `code` and `message` | `{"error": ...}` with neither field | Medium. The error shape differs from every other endpoint. |
| 3c | `POST /orders` with a 5,000-character `note` | No internal detail in responses | Body quotes the database column type `character varying(500)` | Medium. Leaks the storage engine and schema. |

Two of these need a product decision rather than a straight fix:

- **Total as string or number.** The code returns a decimal string, which avoids floating-point rounding on money. Either the code changes to return a number, or the contract changes `total` to a string with a decimal pattern. The second option is safer for money, but it is a breaking change for clients that already parse a number.
- **Note length.** The database allows 500 characters. Either the contract adds `maxLength: 500` to `NewOrder.note` and the code returns 400, or the column widens. Adding the limit is the smaller change.

## Gaps in the contract itself

These are not drift. They are places where the contract does not say what should happen, so staging cannot be wrong or right.

- **No 400 on `GET /orders/{id}`.** The path parameter requires an integer of at least 1, but the operation lists no 400 response. Requests such as `/orders/0` and `/orders/abc` have no documented outcome.
- **No `maxLength` on `note`** and no `maxItems` or per-item length on `items`. Every unbounded string is a path to the 500 seen in recording 3.
- **`note` is absent from `Order.required`** but the code sends it as `null`. The contract should say whether an order without a note omits the field or sends `null`.
- **No `additionalProperties: false`** on any schema. The stray `error` field in recording 3 passes schema validation, which hides exactly this kind of bug.
- **No 405, 415 or 422** responses. Wrong method, wrong content type and malformed JSON have no documented outcome.

## Test design

The suite has 4 layers. Layer 1 runs on every response in every other layer.

**Layer 1: schema conformance on every response.** Validate status code, content type and body against the contract with an OpenAPI validator in the test client. This single check would have caught all 6 mismatches above. Add a rule that any 5xx is a failure regardless of body.

**Layer 2: `GET /orders/{id}`.**

| ID | Request | Expected per contract |
| --- | --- | --- |
| G1 | Existing id | 200, `Order`, `total` is a JSON number, `id` equals the path id |
| G2 | One order per `status` value: `placed`, `paid`, `shipped` | 200, `status` matches the enum exactly |
| G3 | Order with a note | 200, `note` is a string |
| G4 | Order without a note | 200, `note` absent or `null`, whichever the contract decides |
| G5 | Unknown id (999999) | 404, `Error` with `code` and `message` |
| G6 | `id` = 0, `id` = -1 | 400 once documented, never 500 |
| G7 | `id` = `abc`, `id` = `1.5`, `id` = `1e3` | 400 once documented, never 500 |
| G8 | `id` above 64-bit range | 400 or 404, never 500 |

**Layer 3: `POST /orders`.**

| ID | Request | Expected per contract |
| --- | --- | --- |
| P1 | `{"items": ["sku-1"]}` | 201, `Order`, `status` is `placed`, `total` is a number |
| P2 | `{"items": ["sku-1"], "note": "x"}` | 201, `note` echoed back as a string |
| P3 | Round trip: `GET` the id from P1 | 200, body equals the 201 body |
| P4 | `{}` and `{"items": null}` | 400, `Error` |
| P5 | `{"items": []}` | 400, `Error` |
| P6 | `{"items": [1, 2]}` and `{"items": "sku-1"}` | 400, `Error` |
| P7 | `note` of 500, 501, 5,000 and 1,000,000 characters | 201 at 500; 400 with `Error` above 500 once `maxLength` is added. Never 500. Regression test for recording 3. |
| P8 | `note` of non-string type | 400, `Error` |
| P9 | Unknown top-level field | 400 if `additionalProperties: false` is adopted, otherwise 201 and the field is ignored |
| P10 | Empty body, malformed JSON, `Content-Type: text/plain` | 400 or 415, never 500 |
| P11 | 1 item with 10,000 characters, 10,000 items | 400 or 201, never 500 |
| P12 | Non-string item types mixed into a valid array | 400, `Error` |

**Layer 4: cross-cutting.**

- **Error shape.** For every non-2xx response in the suite, assert `code` and `message` exist, no other top-level keys, and the message contains none of the strings `character varying`, `syntax error`, `null value`, `relation` or a stack trace.
- **Property-based fuzzing.** Run Schemathesis or an equivalent against the contract nightly with the rule "no 5xx and every response matches the schema". This covers inputs the fixed cases miss.
- **Contract lint.** Fail the build if a string property has no `maxLength`, a nullable field lacks `nullable: true`, or an operation with constrained parameters lacks a 400 response.
- **Regression pins.** G1, G5 and P7 pin the three recorded failures. They should fail today and pass after the fixes land.

**Order of work:** fix 3a and 3c first, since they turn user input into server errors and leak schema details. Then settle the `total` and `note` decisions, update the contract, and fix 1a, 1b and 2 to match.
