## Contract mismatches

Every recorded response violates the contract. Three of the seven findings are server bugs, two are contract gaps, and two need a product decision.

| # | Recording | Field or aspect | Contract says | Observed | Severity | Likely fix |
|---|---|---|---|---|---|---|
| 1a | GET /orders/1042 → 200 | `total` | `type: number` | String `"42.50"` | High. Numeric clients will fail to parse or silently coerce. | Decision needed. Either the server serializes the decimal as a JSON number, or the contract changes to `type: string` with a decimal pattern if money-as-string is intentional. Pick one and apply it everywhere `total` appears. |
| 1b | GET /orders/1042 → 200 | `note` | `type: string`, optional, not nullable | `null` | Medium. In OpenAPI 3.0.3 `null` is invalid for a string unless `nullable: true` is set. | Server should omit the key when there is no note. Alternatively add `nullable: true` to `Order.note` if null is the intended "no note" signal. |
| 2a | GET /orders/999999 → 404 | `code` | Required by `Error` | Missing | High. Clients that branch on `code` cannot distinguish error kinds. | Server bug. Return something like `{"code": "ORDER_NOT_FOUND", "message": "Order not found"}`. |
| 3a | POST /orders → 500 | Status code | Only 201 and 400 are documented | 500 | High. Undocumented status for a request that is valid per the contract. | Server bug. Validate `note` length before the database write and return 400. |
| 3b | POST /orders → 500 | Response body | `Error` with `code` and `message` | `{"error": "..."}` with neither field | High. The error envelope is inconsistent across endpoints. | Server bug. Route all unhandled exceptions through the standard `Error` envelope. |
| 3c | POST /orders → 500 | Message content | Not specified | Raw PostgreSQL text: `value too long for type character varying(500)` | Medium. Leaks schema and database vendor to callers. | Server bug. Never echo database or driver messages to clients. |
| 3d | POST /orders → 500 | `NewOrder.note` and `Order.note` | No `maxLength` | The storage column is 500 characters | Medium. The contract advertises an unbounded field the server cannot store. | Contract gap. Add `maxLength: 500` to both `note` properties so clients can validate up front and the 400 response is justified by the spec. |

One further observation from recording 1. The contract does not allow `null` anywhere, yet the server clearly stores nullable notes. Whichever way 1b is resolved, `NewOrder.note` and `Order.note` must agree, since a client that sends no note and then reads the order back should see consistent shape.

## Assumptions and contract gaps

Assumptions made where the recordings are silent:

- All three responses carried `Content-Type: application/json`. Headers were not recorded, so a header check is included in the tests rather than reported as a finding.
- The recorded bodies are complete, not truncated excerpts.
- Order ids 1042 and 999999 are both valid path values. Both satisfy `integer, minimum: 1`, so the 404 in recording 2 is the correct status and only its body is wrong.
- A newly created order has `status: "placed"`. The contract does not say which enum value a POST produces.
- The API has no authentication. The contract defines no security scheme, so no 401 or 403 tests are included. Add them if staging actually requires a token.
- The contract is the source of truth for the test oracle, except for the two "decision needed" items above, where tests are written against the current contract and will fail until the decision is made.

Gaps the recordings expose but do not directly violate:

- GET /orders/{id} declares no response for an invalid id such as `0`, `-1`, `abc`, or `1.5`. Most frameworks return 400 or 404 here. The contract should document one.
- No 405, 406, 415, or 422 responses are documented. Wrong method, unsupported Accept, non-JSON body, and malformed JSON all need a defined outcome.
- `NewOrder.items` entries are bare strings with no `minLength`, `pattern`, or `maxItems`. An empty string or a thousand items is contract-valid.
- No `additionalProperties: false` on any schema, so unknown fields must be accepted and ignored. That is fine, but it should be a deliberate choice and tested.
- No 201 `Location` header is declared. Add it if the server sends one.

## Test design

Organize the suite in four layers. Layer 1 catches every mismatch above automatically. Layers 2 and 3 pin down behavior the schema alone cannot express. Layer 4 is the regression gate for the specific bugs found.

**Layer 1: contract conformance, automated from the spec.**

- Load the OpenAPI document and validate every response the suite receives against the schema for that path, method, and status. Treat any status not declared for the operation as a failure. This single assertion catches 1a, 1b, 2a, 3a, and 3b.
- Assert `Content-Type` is `application/json` on every response, success or error.
- Run a property-based fuzzer such as Schemathesis against the spec for both operations. Configure it to fail on any 5xx and any undeclared status. Give it a fixture that seeds a known order so GET has a real target.
- Lint the spec itself in CI with a rule set that flags `type: string` fields without `maxLength`, nullable fields without `nullable`, and operations lacking a 4xx for bad input. This catches 3d and the gaps above before they ship.

**Layer 2: GET /orders/{id} behavioral tests.**

- Existing order returns 200 with `id` as an integer equal to the path value, `status` in the enum, `total` as a JSON number, and either no `note` key or a string. Pin the 1a and 1b expectations here explicitly, not just via the generic validator, so the failure message names the field.
- Unknown id returns 404 with both `code` and `message` as non-empty strings.
- Boundary ids: `1` and the largest id in the seed data return 200 or a well-formed 404. Never a 500.
- Invalid ids: `0`, `-1`, `abc`, `1.5`, `01`, an id beyond 64-bit range, and a URL-encoded value. Each must return the documented 4xx once the gap is closed, and must never return 500 or a body outside the `Error` schema.
- Unsupported method, for example DELETE on `/orders/{id}`, returns 405 with the `Error` envelope.
- Accept header set to `text/xml` returns 406 or ignores the header and returns JSON. Either is acceptable once documented. A 500 is not.

**Layer 3: POST /orders behavioral tests.**

- Happy path with items only. Expect 201, integer `id`, `status` equals `placed`, numeric `total`, no `note` key or a null-free value, and if present a `Location` header pointing to `/orders/{id}`.
- Happy path with items and a note. Expect the same note back unchanged.
- Round trip. POST, then GET the returned id, and assert both bodies are identical for every `Order` field. This is where the `null` versus missing `note` inconsistency would surface if POST and GET serialize differently.
- Note length boundaries: 0, 1, 499, 500, 501, and 5000 characters. Expect 201 up to 500 and 400 above it with `code` identifying the field. The 501 case is the smallest input that reproduces recording 3.
- Note with multi-byte content: 500 characters of CJK or emoji. Postgres `varchar(500)` counts characters, so this should be 201. A byte-counting validation layer in front of it would wrongly reject. Test it both ways to be sure the two layers agree.
- Required field validation: body missing `items`, `items` empty array, `items` as a string, `items` containing a number, `items` containing `null`, `items` containing an empty string, `note` as a number, `note` as an array. Each returns 400 with the `Error` envelope and never 500.
- Unknown top-level field such as `"priority": "high"` is accepted and ignored, returning 201 without echoing the field.
- Malformed input: empty body, invalid JSON, `Content-Type: text/plain` with a JSON body, no `Content-Type` at all. Each returns 400 or 415 with the `Error` envelope.
- Oversized request body, for example 10 MB of items. Expect 413 or 400, never a timeout or 500.
- Unknown SKU in `items`. The contract is silent, so assert only that the response is a documented status with a valid body. Flag the chosen behavior for documentation.

**Layer 4: error envelope and leak guard, run across every negative test above.**

- Every non-2xx response validates against `Error`, with `code` drawn from a documented list once one exists.
- No response body, at any status, contains the substrings `character varying`, `psycopg`, `pg_`, `SQLSTATE`, `Traceback`, `at java.`, `at .*\.js:\d+`, or an absolute file path. This is the test that fails on recording 3 today and keeps 3c from regressing.
- No 5xx is ever produced by any request in the suite. If one is, the test prints the request so the input is reproducible.

**Regression pins for the three recordings.** Add three named tests that reproduce the exact recorded requests and assert the contract-correct outcome. All three fail against the current 2.1.0 build and define done for the fix:

| Test | Request | Expected after fix |
|---|---|---|
| `get_order_total_is_number_and_note_not_null` | GET /orders/1042 | 200, `total` is a JSON number, `note` absent or string |
| `get_missing_order_returns_error_code` | GET /orders/999999 | 404, `code` and `message` present |
| `post_long_note_returns_400_not_500` | POST /orders with a 5000-character note | 400, `Error` envelope, no database text |

Seed data needed: one order with id 1042, status `paid`, total 42.50, and no note, plus a guarantee that id 999999 does not exist. If the seed cannot be pinned, create the order in a fixture and substitute its id into the first regression test.
