# API Contract Validation Report & Test Design

## Mismatches Between Contract and Recorded Responses

### Response 1: GET /orders/1042 → 200
**Type mismatch:** The `total` field is returned as a string `"42.50"` but the schema defines `type: number`. Should be `42.50` (numeric, not quoted).

### Response 2: GET /orders/999999 → 404
**Missing required field:** The Error schema requires both `code` and `message`, but the response contains only `message`. The `code` field is missing.

**Implied structure:** This response should be `{"code": "NOT_FOUND", "message": "Order not found"}` (or similar code value).

### Response 3: POST /orders → 500
**Status code mismatch:** The schema defines only `201` (Created) and `400` (Invalid order) responses. A `500` response is not in the contract.

**Error structure mismatch:** The response uses `{"error": "..."}` format, but the Error schema requires `{"code": "...", "message": "..."}`.

**Undocumented constraint:** The note field accepts max 500 characters (database column limit), but the OpenAPI schema does not document this limit. The request body was valid per the schema (a string is allowed for `note`), yet the API rejected it.

---

## Test Design

### Critical Tests (Validation Gaps)

1. **Response Type Validation**
   - GET /orders/{id} with valid order: verify `total` is a number, not a string
   - Verify `status` enum values are exactly `placed`, `paid`, or `shipped`

2. **Error Response Structure**
   - GET /orders/999999: verify response has both `code` and `message` fields, both required
   - POST /orders with invalid body: verify response matches Error schema

3. **Undocumented Constraints**
   - POST /orders with 5,000-character note: verify it returns 400 (not 500) with proper Error structure
   - Assumption: note field has max length 500 characters; encode this as a boundary test

### Happy Path Tests

4. **Valid GET requests**
   - GET /orders/1: order exists → 200, all Order fields present and correctly typed
   - GET /orders/{large-valid-id}: verify any integer ≥1 is accepted

5. **Valid POST requests**
   - POST with only `items` array → 201, returns Order with auto-assigned `id`, status (assume `placed`), and `total`
   - POST with `items` and valid `note` (≤500 chars) → 201
   - POST with empty/whitespace note → 201 (or verify it's treated as null)

### Error Cases

6. **Request validation**
   - POST with no body → 400
   - POST with missing `items` field → 400
   - POST with empty `items` array → 400
   - POST with `items` containing non-strings → 400 (if enforced)
   - POST with note > 500 characters → 400

7. **Path parameter validation**
   - GET /orders/0 → 400 (violates `minimum: 1`)
   - GET /orders/-1 → 400
   - GET /orders/1.5 → 400 (not an integer)
   - GET /orders/abc → 400

8. **Not Found**
   - GET /orders/999999 → 404 with Error structure containing `code` and `message`

### Quality Assertions (All Responses)

- Every response matches its declared schema
- Error responses always contain both `code` and `message`
- No 5xx responses for client errors (4xx when request is invalid)
