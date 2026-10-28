## Mismatches

Every row below is a contract violation, checked field by field against the 2.1.0 spec.

| Recording | Field | Contract says | Response has | Severity |
|---|---|---|---|---|
| 1. GET /orders/1042, 200 | `total` | `number` | string `"42.50"` | High. Clients doing arithmetic break or silently coerce. |
| 1. GET /orders/1042, 200 | `note` | `string`, not nullable | `null` | Medium. OpenAPI 3.0.3 only permits null with `nullable: true`. Server should omit the key or the contract should allow null. |
| 2. GET /orders/999999, 404 | `code` | required `string` | absent | Medium. Error schema fails validation. Clients cannot branch on an error code. |
| 3. POST /orders, long note | status | `201` or `400` only | `500` | High. Undocumented status from an unhandled database error. |
| 3. POST /orders, long note | body | `Error` with `code` and `message` | `{"error": ...}` | Medium. Wrong shape, no code, no message. |
| 3. POST /orders, long note | body text | nothing internal | leaks Postgres column type and length | Medium. Information disclosure about storage schema. |

**Recording 3 has a deeper problem than the shape.** The contract puts no `maxLength` on `note`, so a 5,000-character note is a valid request under the published spec. The server must either accept it or the contract must declare a limit and the server must reject with 400. Today neither holds. The root cause is that the server performs no input validation before the insert and relies on the database to fail.

**On `total`, pick one side.** The lowest-risk fix is making the server emit a JSON number, since clients were built against the published 2.1.0 contract. If the team deliberately wants decimal strings for money precision, that is a breaking change and needs a new major version, not a silent drift on staging.

Contract gaps the review surfaced. These are not violated by the recordings, but they will produce more violations under test:

- GET /orders/{id} declares `minimum: 1` on `id` but no 400 response. Any rejection of `0`, negatives, or non-integers is automatically undocumented.
- No `default` or 500 response is declared on any operation, so every server error is a contract break.
- `note` has no `maxLength` even though storage holds 500 characters.
- `Error.code` has no enum, so clients cannot rely on specific values. Recommend `order_not_found`, `validation_failed`, `internal_error`.
- POST 201 declares no `Location` header. Not a violation, but worth adding.

## Assumptions

- All three responses carried `Content-Type: application/json`. Headers were not recorded.
- Recorded bodies are complete and untruncated.
- The 500-character column limit in the leaked error is the intended business limit for `note`, so the tests use 500 as the boundary.
- Staging at 2.1.0 is the same build as production, so these are live bugs, not staging drift.
- The contract declares no authentication, so the tests omit it. If the real API requires it, add a 401 and 403 layer.
- Order 1042 is not a stable fixture. Tests create their own orders through POST and never depend on pre-existing ids.
- Pricing of SKUs is outside this contract, so tests assert `total` is a non-negative number rather than a specific value.

## Tests this API needs

Three layers, in priority order.

**Layer 1: automated contract conformance in CI.** Every response from every test below is validated against the spec by an OpenAPI validator such as schemathesis, openapi-core, or Prism in proxy mode. This single addition would have caught all six mismatches above. Run it on every pull request against an ephemeral environment.

**Layer 2: spec-driven fuzzing.** Run schemathesis against the spec for both operations with a few thousand generated cases. Any 500, any non-JSON body, and any body failing the declared schema fails the build. This finds the next undocumented 500 before a user does.

**Layer 3: explicit scenario tests.** The table lists each test, the expected result under the corrected contract, and whether the recordings already show it failing.

GET /orders/{id}

| ID | Request | Expected | Status today |
|---|---|---|---|
| G1 | Existing order | 200, `Order` schema, `total` is a JSON number, `status` in enum | Fails, recording 1 |
| G2 | Existing order with no note | 200, `note` key absent or a string, never null | Fails, recording 1 |
| G3 | Unknown id | 404, `Error` with both `code` and `message` | Fails, recording 2 |
| G4 | `id` of `0` | 400, `Error`, once the contract declares it | Unknown, contract gap |
| G5 | Negative `id` | 400, `Error` | Unknown, contract gap |
| G6 | Non-integer `id` such as `abc` or `1.5` | 400, `Error`, never 500 | Unknown |
| G7 | `id` beyond 64-bit range | 400 or 404, never 500 | Unknown |
| G8 | Round trip: POST then GET by returned id | Same `id`, `status`, `note` as the POST response | Unknown |

POST /orders

| ID | Request body | Expected | Status today |
|---|---|---|---|
| P1 | `{"items": ["sku-1"]}` | 201, `Order` schema, `status` is `placed`, `note` absent | Unknown |
| P2 | Valid items, one-character note | 201, note echoed exactly | Unknown |
| P3 | Valid items, note of exactly 500 characters | 201, note echoed intact | Unknown, boundary |
| P4 | Valid items, note of 501 characters | 400, `Error`, `code` is `validation_failed` | Fails by inference |
| P5 | Valid items, note of 5,000 characters | 400, `Error` | Fails, recording 3 |
| P6 | Note of 500 multi-byte characters such as emoji | 201 or 400, never 500. Postgres counts characters, other layers may count bytes | Unknown |
| P7 | `items` missing | 400, `Error` | Unknown |
| P8 | `items` is `[]` | 400, `Error` | Unknown |
| P9 | `items` is `[1]` or `[null]` | 400, `Error` | Unknown |
| P10 | `items` is `null` or a string | 400, `Error` | Unknown |
| P11 | `note` is a number or object | 400, `Error` | Unknown |
| P12 | Empty body, or malformed JSON | 400, `Error` | Unknown |
| P13 | Body is a JSON array, not an object | 400, `Error` | Unknown |
| P14 | `Content-Type: text/plain` with JSON text | 400, or 415 once documented | Unknown |
| P15 | Unknown extra field | 201. The schema does not set `additionalProperties: false`, so extras are allowed. Decide and document. | Unknown |
| P16 | Valid request | Returned `id` is an integer of at least 1 and the order is fetchable with GET | Unknown |
| P17 | Two valid requests | Distinct ids | Unknown |

Cross-cutting error hygiene, applied to every response in every test

- No body ever contains `character varying`, `SQL`, `psql`, a stack trace, a file path, or a class name. Assert with a denylist regex on all 4xx and 5xx bodies.
- Every 4xx and 5xx body validates against `Error`, and `code` is one of the enum values.
- Every response has `Content-Type: application/json`.
- No test ever observes a 500. A 500 is a test failure regardless of the scenario.

**Regression pins.** G1, G2, G3, and P5 reproduce the three recordings exactly and should be added first, before any fix, so the fixes are proven by a red-to-green transition.

**Recommended order of work.**

1. Amend the contract: add `maxLength: 500` to `note`, add a 400 response to GET /orders/{id}, add an enum to `Error.code`, add a `default` error response, and either mark `note` nullable or commit the server to omitting it. Keep `total` as `number`. Ship as 2.1.1 since nothing valid under 2.1.0 becomes invalid.
2. Fix the server: validate the request body before touching the database, serialise `total` as a number, include `code` in every error, and replace the generic database error handler with one that returns the `Error` shape and logs the detail server-side only.
3. Wire layers 1 and 2 into CI so drift of this kind cannot reach staging again.
