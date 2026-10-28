# QA Report: Orders API 2.1.0 (staging, recorded 2026-10-15)

## Summary

All three recorded responses violate the contract. Response 1 breaks two field types. Response 2 omits a required error field. Response 3 is an undocumented 500 that leaks database internals on input the contract declares valid. Severity is ordered below from highest to lowest.

| # | Request | Finding | Severity |
|---|---------|---------|----------|
| 3 | POST /orders, 5,000-char note | Undocumented 500, non-conforming body, DB error leaked | High |
| 1 | GET /orders/1042 | `total` returned as string, contract says number | High |
| 2 | GET /orders/999999 | Error body missing required `code` | Medium |
| 1 | GET /orders/1042 | `note` is null, contract does not allow null | Medium |

## Assumptions

- All three responses were served with `Content-Type: application/json`. The recordings did not capture headers.
- The recordings are verbatim and the deployed build truly reports version 2.1.0.
- The 500 message originates from PostgreSQL and the `note` column is `varchar(500)`. The contract defines no `maxLength` for `note`, so the field is unbounded by spec.
- The OpenAPI document is the agreed source of truth. Where server and spec disagree, I report the server as wrong and separately flag where the spec itself should change.

## Mismatches in detail

### Response 1: GET /orders/1042 -> 200

Status code and `id` and `status` conform. Two fields do not.

- **`total` is a JSON string, not a number.** The schema declares `total: { type: number }`. The server returned `"42.50"`. Any typed client generated from this spec will fail to deserialize this response. Likely cause is a decimal column serialized without conversion.
- **`note` is `null`, which the schema forbids.** OpenAPI 3.0.3 only permits null when the property carries `nullable: true`, and `Order.note` does not. The server should either omit `note` when absent or the spec should mark it nullable. This is a decision for the API owner. My recommendation is to omit the key, which keeps the contract unchanged.

### Response 2: GET /orders/999999 -> 404

Status code conforms. The body does not.

- **Required field `code` is missing.** The `Error` schema requires both `code` and `message`. Only `message` was returned. Clients branching on `code` will receive undefined. The spec also never enumerates valid codes, which should be fixed so this field is testable.

### Response 3: POST /orders with a 5,000-character note -> 500

This is the most serious finding and contains four distinct defects.

- **The input is valid under the contract.** `NewOrder.note` is `type: string` with no `maxLength`. A 5,000-character note is therefore a legal request. A server that fails on legal input is defective regardless of status code.
- **500 is not a documented response.** The POST operation defines only 201 and 400. If the server intends to reject long notes, it must return 400 with an `Error` body, and the spec must add `maxLength: 500` to `NewOrder.note` so clients can validate ahead of time.
- **The body does not match the `Error` schema.** It uses a single `error` key instead of the required `code` and `message`.
- **Internal details are leaked.** The message exposes the database engine, the column type, and its length limit. This is an information disclosure issue and should be caught by a global exception handler that returns a generic message.

Two follow-up questions this recording cannot answer. First, whether the failed insert left a partial order or an orphaned row, which a subsequent GET could reveal. Second, whether `items` has a similar hidden limit, since the spec gives it no `maxItems` or per-item `maxLength` either.

## Spec defects to fix alongside the server

- Add `maxLength` to `NewOrder.note` and `Order.note`, and `maxItems` plus per-item `maxLength` to `NewOrder.items`. The 500 proves undocumented limits exist.
- Either add `nullable: true` to `Order.note` or document that absent notes are omitted.
- Enumerate `Error.code` values so error tests can assert exact codes.
- GET /orders/{id} declares `minimum: 1` on `id` but defines no 400 or 422 response. Requests for `/orders/0`, `/orders/-1`, and `/orders/abc` currently have no specified outcome.
- Consider documenting 500 with the `Error` schema so clients have a known shape even on failure.
- `total` as a floating-point `number` risks rounding for currency. Decide now whether to keep `number`, switch to integer minor units, or switch to a decimal string and update the spec. The current string response may be the implementer's intent leaking through, and the team should settle this deliberately rather than by accident.

## Test design

Tests are grouped by type. Each test states its target, inputs, and expected result. Items marked **R** are direct regression tests for the defects above and should be written first.

### Contract tests (automated schema validation on every response)

Run every response below through a JSON Schema validator against the referenced component. Recommended tooling is a schema-fuzzing tool such as Schemathesis in CI, plus a validating mock such as Prism for consumer builds.

1. **R** GET existing order: 200 body validates against `Order`. `total` must be a JSON number. `note` must be absent or a string.
2. **R** GET unknown order: 404 body validates against `Error` with both `code` and `message` present and non-empty.
3. **R** POST valid order: 201 body validates against `Order`.
4. **R** POST invalid order: 400 body validates against `Error`.
5. Every response has `Content-Type: application/json` with optional charset.
6. No response on any path returns a status code not listed for that operation.

### GET /orders/{id}: functional and boundary

7. Existing order with each `status` value in turn (placed, paid, shipped). Assert the enum is respected and nothing outside it appears.
8. Order with no note. Assert `note` key is absent, or null only if the spec is amended.
9. Order with a note. Assert the note is returned unchanged, including Unicode and whitespace.
10. Lowest valid id `1`. Expect 200 or 404 with conforming body, never 5xx.
11. Boundary id `0`. Expect a 4xx with `Error` body once the spec defines one. Currently assert "not 5xx" and log the result.
12. Negative id `-1`. Same expectation as above.
13. Non-integer ids `abc`, `1.5`, `1e3`, empty, and a 20-digit integer beyond int64. Expect consistent 4xx, never 500.
14. Very large valid-looking id such as `2147483648`. Confirms no integer overflow to 500.
15. Path traversal and encoding: `/orders/%31042`, `/orders/1042/`, `/orders/1042%00`. Expect 404 or 400, never 200 for a different order and never 500.
16. Unsupported methods PUT, PATCH, DELETE on `/orders/{id}`. Expect 405 with an `Allow` header.

### POST /orders: functional

17. Minimal valid body `{"items": ["sku-1"]}`. Expect 201, `status` is `placed`, `total` is a number, `id` is a positive integer, `note` absent.
18. Valid body with note. Expect 201 and the note echoed exactly.
19. Round trip: POST then GET the returned id. Both bodies validate against `Order` and agree on every field.
20. Multiple items. Expect 201 and a `total` consistent with the items. Assumption: totals derive from a price catalog not in the spec, so assert type and non-negativity until pricing rules are supplied.
21. Duplicate item strings in `items`. Document observed behavior, since the spec does not say whether duplicates are allowed.

### POST /orders: validation and negative

22. Missing `items`. Expect 400 with `Error`.
23. Empty `items` array. Expect 400, enforcing `minItems: 1`.
24. `items` is not an array (string, object, number, null). Expect 400.
25. `items` contains a non-string element. Expect 400.
26. `items` contains an empty string or whitespace-only string. Document behavior and push for a spec decision.
27. `note` is not a string (number, array, object). Expect 400.
28. Unknown top-level property such as `"price": 0` or `"status": "shipped"`. Expect either 400 or silent ignore. Must never allow a client to set `status`, `total`, or `id`. This is a mass-assignment check.
29. Empty body, malformed JSON, and body of `null`. Expect 400, never 500.
30. Missing or wrong `Content-Type` such as `text/plain` with a JSON body. Expect 415 or 400.
31. Body size far above any reasonable order, such as 10 MB. Expect 413 or 400, never 500 or a timeout.

### POST /orders: length boundaries (regression for the 500)

Assumes the column limit of 500 characters and that the spec will adopt `maxLength: 500`.

32. **R** `note` of exactly 500 characters. Expect 201 and the note returned intact.
33. **R** `note` of 501 characters. Expect 400 with `Error`, not 500.
34. **R** `note` of 5,000 characters. Expect 400 with `Error`. The body must not contain the words `character varying`, `varchar`, or any SQL fragment.
35. **R** After test 34, confirm no order was created. Query for the most recent order id and verify it did not advance, or GET the id if one was returned.
36. `note` of 500 multi-byte characters such as emoji or CJK text. Confirms whether the limit is in characters or bytes. Expect 201 if characters, and the spec should state which.
37. Each item string at the hidden column limit and one past it. Expect 201 and 400 respectively, never 500.
38. Large `items` count such as 1,000 and 10,000 elements. Expect 201 or 400, never 500 or timeout.

### Security

39. **R** Trigger each known error path and assert no response body contains database, stack trace, file path, or framework identifiers.
40. SQL injection strings in `note` and `items` such as `'; DROP TABLE orders;--`. Expect 201 with the string stored literally, or 400. Then GET and confirm the literal value.
41. Script and HTML payloads in `note`. Expect the value stored and returned unescaped as JSON, with no reflection into any HTML context.
42. Authorization: the spec declares no security scheme. Confirm with the owner whether this is intentional. If auth exists, test unauthenticated and cross-tenant access to `/orders/{id}`.
43. Order id enumeration: sequential ids like 1042 make every order guessable. Flag as a design risk if orders belong to distinct customers.

### Robustness and non-functional

44. Concurrency: 50 parallel POSTs. Expect 50 distinct ids and 50 successful GETs.
45. Idempotency: identical POST twice creates two orders. Document this, and recommend an `Idempotency-Key` header if retries are expected.
46. Response time budget for GET and POST under light load. Thresholds to be agreed with the owner.
47. Version check: whatever mechanism reports the deployed version must say 2.1.0 and match the spec `info.version`.

## Recommended fix order

1. Add a global exception handler that maps unexpected errors to a generic `Error` body. This closes the information leak immediately even before validation is fixed.
2. Enforce `note` length at the API layer and return 400. Update the spec with `maxLength`.
3. Serialize `total` as a JSON number, or decide on a different representation and change the spec in the same release.
4. Add `code` to every error response and enumerate the codes in the spec.
5. Omit `note` when absent, or mark it nullable.
6. Wire tests 1 through 6 and the **R** tests into CI so these regressions cannot recur.
