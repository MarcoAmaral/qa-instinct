## Contract mismatches

Every recorded response violates the contract. Six distinct findings, plus two gaps in the contract itself that the recordings expose.

| # | Response | Field / aspect | Contract says | Observed | Severity |
|---|----------|----------------|---------------|----------|----------|
| M1 | 1: GET /orders/1042 | `total` | `type: number` | `"42.50"` is a string | High. Numeric clients will fail to parse or silently coerce. |
| M2 | 1: GET /orders/1042 | `note` | `type: string`, not nullable | `null` | Medium. OAS 3.0.3 requires `nullable: true` for null to be valid. Either the server must omit the key or the schema must allow null. |
| M3 | 2: GET /orders/999999 | `Error.code` | required | Absent. Body has only `message` | High. Clients that branch on `code` cannot handle this error. |
| M4 | 3: POST /orders (long note) | Status code | Only `201` and `400` are documented | `500` | High. An oversized client input is a validation failure and must be a `400`. |
| M5 | 3: POST /orders (long note) | Error body | `Error` schema with `code` and `message` | `{"error": "..."}`. Neither required field present, unknown key `error` | High. Error shape is inconsistent across endpoints (compare M3). |
| M6 | 3: POST /orders (long note) | `NewOrder.note` | No `maxLength` | Server rejects at 500 characters via a database constraint | Medium. The limit is real but undocumented. The contract should declare `maxLength: 500` and the server should enforce it before the database does. |

Two additional observations from response 3 that are not strictly schema violations:

- **Information leak.** The `500` body echoes a PostgreSQL error string, revealing the column type and length. Error bodies should never surface storage internals.
- **Possible partial write.** If the insert is not wrapped in a transaction, the failed request may have consumed an order id or left orphaned rows. This needs verification on staging.

Contract gaps the recordings expose:

- **No `400` on GET /orders/{id}.** The path parameter has `minimum: 1` and `type: integer`, but there is no documented response for `/orders/0`, `/orders/-5`, or `/orders/abc`. The server will return something. The contract must say what.
- **No `nullable` anywhere.** If `note` is intended to be optional on read, the schema needs either `nullable: true` or a guarantee that the key is omitted.

Recommended resolution per finding:

- M1: Fix the server to serialize `total` as a JSON number. Do not loosen the contract to string. If currency precision is the concern, document the number of decimal places instead.
- M2: Decide once. Either omit absent `note` from the response, or add `nullable: true`. Recommend omitting, which keeps the schema strict.
- M3 and M5: Fix the server so every error path produces `{code, message}`. Introduce a stable set of codes such as `ORDER_NOT_FOUND`, `VALIDATION_FAILED`.
- M4 and M6: Add `maxLength: 500` to `NewOrder.note`. Validate in the handler and return `400` with the `Error` schema.

## Tests this API needs

The suite has three layers. Contract tests validate every response against the spec automatically. Behavior tests cover the business rules the spec encodes. Regression tests pin each mismatch above so it cannot return.

**Layer 1: automatic contract validation**

Run a schema-driven tool such as Schemathesis or Dredd against staging on every deploy, loading this OpenAPI document. It should assert for every request it generates:

- The status code is one listed for that operation.
- The `Content-Type` is `application/json`.
- The body validates against the schema for that status code.
- No `5xx` is ever returned for any input the spec permits.

This layer alone would have caught M1 through M5.

**Layer 2: behavior tests per endpoint**

GET /orders/{id}:

1. Existing order returns `200`, body validates as `Order`, `id` equals the path parameter, `total` is a JSON number, `status` is one of the three enum values.
2. Existing order with no note omits `note` entirely, or returns a string if present. No null.
3. Non-existent id returns `404` with `code` and `message` both present and non-empty.
4. Boundary: `id` of `1` is accepted. `id` of `0` and a negative id are rejected with a documented `4xx`. Assumed `400` until the contract is updated.
5. Type violation: `/orders/abc`, `/orders/1.5`, `/orders/1e3` are rejected with the same documented `4xx`.
6. Overflow: an id larger than 64-bit integer range does not produce a `500`.
7. Authorization: if orders belong to accounts, a valid id belonging to another account returns `404` not `200`. Assumed out of scope since the spec has no security scheme, but flagged.

POST /orders:

1. Minimal valid body `{"items": ["sku-1"]}` returns `201`, body validates as `Order`, `status` is `placed`, `id` is a positive integer, `total` is a number.
2. Round trip: the returned `id` can be fetched with GET and the two bodies are equal.
3. Note is persisted: a body with `note: "hello"` returns `201` and the subsequent GET returns the same string.
4. Boundary on `note`: exactly 500 characters is accepted with `201`. Exactly 501 characters is rejected with `400` and an `Error` body. Include a multi-byte test, such as 500 emoji, to confirm the limit is counted in characters not bytes, or document which it is.
5. Boundary on `items`: empty array is `400`. One item is `201`. A large array, such as 1,000 items, is either `201` or a documented `400`, never `500`.
6. Missing required field: body without `items` is `400`.
7. Wrong types: `items` as a string, `items` containing an integer, `note` as a number, each `400`.
8. Unknown properties: body with an extra key such as `status: "shipped"` is either ignored or rejected with `400`. It must never set the status. Assumed ignored.
9. Malformed input: empty body, invalid JSON, wrong `Content-Type`, each returns `400` or `415`, never `500`.
10. Error body consistency: every `400` from this endpoint has the same `{code, message}` shape as the `404` from GET.
11. Atomicity: after a rejected request, no order was created. Verify by counting orders or by confirming the next successful order's id has no gap, depending on id strategy.
12. Idempotency: two identical POSTs create two orders unless an idempotency key is introduced. Pin whichever behavior is intended.

**Layer 3: regression tests pinning the recorded failures**

One test per finding, named after it, so the fix is verified and the bug cannot silently return:

- `test_total_is_json_number` for M1.
- `test_absent_note_is_omitted_not_null` for M2.
- `test_404_error_has_code` for M3.
- `test_oversized_note_returns_400_not_500` for M4.
- `test_oversized_note_error_matches_error_schema` for M5.
- `test_oversized_note_error_does_not_leak_db_details` for the information leak. Assert the message does not contain `character varying` or any SQL fragment.
- `test_contract_declares_note_maxlength` for M6. A lint test that parses the spec and asserts `maxLength: 500` is present, so the contract and server cannot drift apart again.

**Cross-cutting tests**

- Property-based fuzzing of both endpoints with random bodies and ids, asserting only that the status is documented and the body validates. This is cheap and catches the next undocumented `500`.
- A spec lint step in CI that fails the build if any operation lacks a `4xx` response, or if any response schema uses a non-nullable type for a field the server can return as null.
- Version check: assert the deployed build reports `2.1.0` before running the suite, so results are attributed to the right contract.

## Assumptions

- The recorded responses were served with `Content-Type: application/json`. Headers were not captured.
- Staging on 2026-10-15 was running the code that the version 2.1.0 contract describes, so none of the mismatches are explained by version drift.
- The 500-character limit on `note` is the intended business limit, not an accident of the column type. If the limit should be larger, the column changes and the tests above take the new number.
- There is no authentication or multi-tenancy in scope, since the contract defines no security scheme. If there is, the authorization test under GET becomes mandatory.
- Invalid path ids such as `/orders/0` should return `400`. The contract does not say, so this is the value the tests assume until it is documented.
- Unknown request properties are ignored rather than rejected. The contract sets no `additionalProperties`, so either reading is defensible.
