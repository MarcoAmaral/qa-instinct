Checked three staging recordings (2026-10-15, v2.1.0) against the Orders API 2.1.0 contract. All three responses violate the contract. The most serious are the money field returned as a string and an unhandled 500 that leaks a database error.

## Contract mismatches

| ID | Recording | Aspect | Contract says | Observed | Severity |
|----|-----------|--------|---------------|----------|----------|
| F1 | 1, GET /orders/1042 | `total` | `type: number` | JSON string `"42.50"` | High |
| F2 | 1, GET /orders/1042 | `note` | `type: string`, optional, not nullable | `null` | Medium |
| F3 | 2, GET /orders/999999 | Error body | `code` and `message` both required | `code` missing | Medium |
| F4 | 3, POST /orders | Status code | Only `201` and `400` documented | `500` | High |
| F5 | 3, POST /orders | Error body | Error schema with `code` and `message` | `{"error": "..."}`, neither field present | Medium |
| F6 | 3, POST /orders | `note` length | No `maxLength`, so a 5,000-character note is a valid request | Server storage caps it at 500 characters | High |
| F7 | 3, POST /orders | Information disclosure | Not covered | Raw PostgreSQL error text with column type exposed to the client | Medium |

Detail on each:

- **F1, total as string.** Clients typed against the spec will fail to parse or will silently coerce. Either the API must emit a JSON number, or the contract must change `total` to a string with a decimal pattern. The second option is common for money, but it is a breaking change and must be decided explicitly. Every other numeric field should be checked for the same serializer behavior.
- **F2, null note.** OpenAPI 3.0.3 treats `null` as invalid for `type: string` unless `nullable: true` is set. The server should omit the key when there is no note, or the contract should add `nullable: true`. The choice must match what POST accepts for `note: null`, which is untested.
- **F3, missing error code.** The 404 body breaks the shared Error schema. Clients that branch on `code` cannot distinguish error kinds. A stable code such as `order_not_found` should be added.
- **F4 and F6, the 500.** The request was contract-valid, so the only compliant answer is `201`. Since the storage column is varchar(500), a 500-character limit clearly exists and the contract hides it. The fix needs two halves: add `maxLength: 500` to `NewOrder.note` and validate it with a `400`, and make the handler never let a database constraint error surface as a 500. Whether the limit is 500 characters or 500 bytes also needs confirming. PostgreSQL varchar counts characters, but any intermediate layer may not.
- **F5 and F7, the 500 body.** The body uses a different shape from every documented error and echoes driver text. This leaks schema details and should be replaced by a generic Error body with a correlation id. Also unknown: whether the failed insert left a partial row or consumed a sequence value. The tests below check that.

Contract gaps that are not yet mismatches but will produce undocumented behavior:

- GET `/orders/{id}` declares `minimum: 1` on `id` but defines no `400` response. What `/orders/0`, `/orders/-1`, or `/orders/abc` return is unspecified.
- No `500`, `415`, or `405` responses are documented anywhere. A spec lint rule should require every status the server can return to be listed.
- `NewOrder.items` has no `maxItems` and item strings have no `maxLength` or pattern, so the same overflow class as F6 likely exists for SKUs.
- `Order.total` has no `minimum`, and the status an order starts in after POST is not stated.
- No `Content-Type` was recorded for any response. The contract requires `application/json`.

## Test design

Tests are grouped by endpoint, then cross-cutting. Each is tagged with the finding it guards. "Strict schema" means validation with `additionalProperties` treated as reported, no type coercion, and null rejected unless the contract says nullable.

GET /orders/{id}

| ID | Case | Expected | Guards |
|----|------|----------|--------|
| G01 | Existing order with a note | 200, strict Order schema, `total` is a JSON number, `id` equals the path id, `Content-Type: application/json` | F1 |
| G02 | Existing order with no note | 200, `note` key absent, never `null` | F2 |
| G03 | Nonexistent id (999999) | 404, strict Error schema, `code` present and stable | F3 |
| G04 | Id at minimum boundary, 1 | 200 or 404, body matches the documented schema for that status | gap |
| G05 | Id 0 and negative id | Documented status only, never 500. Assumed 404 until the spec adds 400 | gap |
| G06 | Non-integer ids: `abc`, `1.5`, `1e3`, empty, URL-encoded, 20-digit overflow | Never 500, never a stack trace or driver text | F7 |
| G07 | One order in each status: placed, paid, shipped | `status` always within the enum | schema |
| G08 | Totals with zero, large, and fractional values | Number in JSON, no precision loss versus the stored value | F1 |

POST /orders

| ID | Case | Expected | Guards |
|----|------|----------|--------|
| P01 | Minimal valid body `{"items":["sku-1"]}` | 201, strict Order schema, `total` numeric, then GET returns the same resource | F1 |
| P02 | Note of exactly 500 characters | 201, note round-trips unchanged through GET | F6 |
| P03 | Note of 501 characters | 400, strict Error schema, no row created | F4, F6 |
| P04 | Note of 5,000 characters, the recorded case | 400 not 500, Error schema, no row created, next created id is contiguous | F4, F5, F6 |
| P05 | Note of 500 four-byte characters such as emoji | 201. Proves the limit is characters, not bytes. If 400, the contract must state bytes | F6 |
| P06 | `note: null` | Consistent with the F2 decision: either 400 or treated as absent, and GET then omits it | F2 |
| P07 | `note` as a number or object | 400, Error schema | schema |
| P08 | `items` missing | 400, Error schema | schema |
| P09 | `items: []` | 400, minItems enforced | schema |
| P10 | `items` with non-string entries, nulls, or nested arrays | 400 | schema |
| P11 | Item string very long, 5,000 characters | 400 not 500. Same defect class as F6 | F6 |
| P12 | Very large `items` array, 10,000 entries | 400 or 201 by policy, never 500 or timeout | gap |
| P13 | Empty body, malformed JSON, body is an array or string | 400, Error schema | schema |
| P14 | Unknown extra property | 201 and the property ignored. Assumed until the spec sets `additionalProperties: false` | gap |
| P15 | `Content-Type: text/plain` or missing | 400 or 415, documented, never 500 | gap |
| P16 | Duplicate SKU in `items` | Documented behavior, never 500. Assumed accepted | gap |
| P17 | Every error body from this endpoint | Matches Error schema exactly and contains no SQL, column, or driver text | F5, F7 |

Cross-cutting and automation

- **Contract conformance in CI.** Run a schema-driven tool such as Schemathesis against staging on every deploy, with strict response validation. It would have caught F1, F2, F3, and F5 automatically. Add a rule that any status not in the spec fails the run, which catches F4.
- **Spec lint.** Add Spectral rules requiring `maxLength` on every string property that is persisted, a defined `500` response, and `nullable` to be explicit. This turns F6 into a design-time failure.
- **Serializer unit test.** One test at the JSON encoding layer asserting decimal money fields encode as numbers, since F1 is almost certainly a global serializer setting rather than a per-field bug.
- **Error handling unit test.** Any database constraint violation inside the POST handler must map to a 400 with a generic Error body. Assert the raw exception message is logged server-side but never returned.
- **Data integrity check.** After P03 and P04, query the order count and the next sequence value. A gap proves the insert ran before validation.
- **Regression gate.** G01, G02, G03, P03, and P04 are the minimum set to mark the four findings fixed, and should be required to pass before the contract or code change ships.

## Assumptions and decisions needed

- The 5,000-character note request carried `Content-Type: application/json` and was otherwise well-formed. The recording omits headers.
- Order 999999 did not exist, and 1042 was a normal order rather than a special test fixture.
- The varchar(500) column is the `note` column. The error message does not name it, but nothing else in the request is near 500 characters.
- Database transactions roll back on the 500, so no partial row exists. P04 verifies this rather than trusting it.
- The recorded responses are complete bodies, not truncated excerpts.

Three decisions block finalizing the tests and must be made by the API owner, not inferred:

1. Is `total` a JSON number or a decimal string? This changes F1 from a server bug to a contract change, and it is breaking either way.
2. Is `note` nullable, or omitted when absent? This decides F2 and P06.
3. Is the note limit 500 characters, 500 bytes, or should the column grow? This decides P02, P03, and P05.

Until those are answered, the tests above assume the contract as written is the source of truth: number, not nullable, and a 500-character limit added as `maxLength`.
