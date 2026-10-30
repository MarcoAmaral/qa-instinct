# API Contract Mismatches and Test Design

## Recorded Response Mismatches

### Response 1: GET /orders/1042 → 200
**Mismatch:** `total` field type violation
- Contract specifies: `total: { type: number }`
- Recorded response: `"total": "42.50"` (string, not number)
- **Impact:** Consumers expecting a number will fail JSON parsing or arithmetic operations

### Response 2: GET /orders/999999 → 404
**Mismatch:** Missing required field in Error schema
- Contract specifies: Error requires `[code, message]`
- Recorded response: `{"message": "Order not found"}` (missing `code` field)
- **Impact:** Clients that expect and use the `code` field will receive null/undefined

### Response 3: POST /orders (with 5,000-char note) → 500
**Mismatch #1:** Undocumented status code
- Contract defines: 201 (Created) or 400 (Invalid order)
- Recorded response: 500 (Internal Server Error)
- **Impact:** API behavior outside contract; unclear if this is a bug or undocumented constraint

**Mismatch #2:** Undocumented constraint on `note` field
- Contract specifies: `note: { type: string }` (no maxLength)
- Actual behavior: Rejects strings over 500 characters with database error
- **Impact:** Clients sending valid requests per the contract receive 500 errors
- **Assumption:** The `note` field has a `maxLength: 500` constraint in the database that should be documented in the schema

**Mismatch #3:** Error response format
- Contract specifies Error schema: `{code, message}` both strings
- Recorded response: `{"error": "value too long for type character varying(500)"}` (database error message, not Error schema)
- **Impact:** Response does not conform to documented Error schema

---

## Test Coverage Gaps

### Schema Validation Tests
- [ ] GET /orders/{id} returns `total` as a number, not a string
- [ ] GET /orders/{id} with 404 response includes both `code` and `message` fields
- [ ] All Order responses include required fields: `id`, `status`, `total`
- [ ] All Error responses include required fields: `code`, `message`
- [ ] `status` enum values are only: placed, paid, shipped

### Input Validation Tests
- [ ] POST /orders accepts `items` array with 1+ items
- [ ] POST /orders rejects empty `items` array (minItems: 1)
- [ ] POST /orders accepts `note` field under 500 characters (**assumption**)
- [ ] POST /orders rejects `note` over 500 characters with 400 (not 500) (**assumption**)
- [ ] POST /orders rejects missing `items` field with 400

### Status Code Tests
- [ ] GET /orders/{id} with valid id returns 200
- [ ] GET /orders/{id} with non-existent id returns 404 (not 500)
- [ ] POST /orders with valid body returns 201
- [ ] POST /orders with invalid body returns 400 (not 500)
- [ ] POST /orders with oversized `note` returns 400 (not 500) (**assumption**)

### Path Parameter Validation Tests
- [ ] GET /orders/{id} accepts integer id ≥ 1
- [ ] GET /orders/{id} with id < 1 returns 400 (or behavior is defined)
- [ ] GET /orders/{id} with non-integer id returns 400

### Contract Compliance Tests
- [ ] Error responses always follow `{code: string, message: string}` schema
- [ ] No 5xx responses documented in contract are returned for client errors
- [ ] Response Content-Type is application/json for all responses

---

## Recommendations

1. **Fix Response 1:** Serialize `total` as a number in the GET /orders/{id} endpoint
2. **Fix Response 2:** Add `code` field to all 404 Error responses; define consistent error codes (e.g., "ORDER_NOT_FOUND")
3. **Update Contract or Fix Response 3:** Either:
   - Add `maxLength: 500` to the `note` property in NewOrder schema and update POST to return 400 on constraint violation, OR
   - Remove the database constraint and allow longer notes
4. **Add Integration Tests:** Validate all responses against their declared schemas in CI/CD
5. **Document Error Codes:** Define the set of valid `code` values (e.g., "ORDER_NOT_FOUND", "INVALID_REQUEST", "NOTE_TOO_LONG")
