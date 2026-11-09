# API Contract Compliance Report: Orders API v2.1.0

## Mismatches Found

### Response 1: GET /orders/1042 (200)
**Type mismatch in `total` field:**
- Contract specifies: `type: number`
- Response contains: `"42.50"` (string)
- Should be: `42.50` (numeric value, not quoted)

### Response 2: GET /orders/999999 (404)
**Missing required field:**
- Contract Error schema requires both `code` and `message` fields
- Response missing: `code` field
- Response body: `{"message": "Order not found"}` 
- Should include: `{"code": "...", "message": "Order not found"}`

### Response 3: POST /orders (500)
**Multiple mismatches:**
1. **Undefined status code:** Returns 500, but contract only defines 201 and 400
2. **Response format violation:** Body is `{"error": "..."}` but Error schema requires `{"code": "...", "message": "..."}`
3. **Undocumented constraint discovered:** `note` field has a max length of 500 characters (PostgreSQL `character varying(500)`), not defined in OpenAPI schema

---

## Assumptions

- The `note` field is implicitly nullable in responses (null values are valid even though not marked as nullable in schema)
- HTTP 500 indicates a server implementation bug, not an API contract issue
- The `note` field's 500-character limit applies to both POST and GET operations

---

## Recommended Test Coverage

### Happy Path
- GET existing order with all fields populated
- GET existing order with optional `note` field null
- POST valid order with required `items` only
- POST valid order with `items` and `note`

### Error Cases (Define in Contract)
- GET with non-existent ID → 404 with proper Error schema
- GET with invalid ID format (non-integer, negative, 0) → 400 with Error schema
- POST with missing `items` field → 400
- POST with empty `items` array → 400 (minItems: 1)
- POST with `items` containing non-string values → 400
- POST with `note` exceeding 500 characters → 400 (update schema to add `maxLength: 500`)

### Type Validation
- Verify `total` is numeric, not stringified
- Verify `id` is integer in all responses
- Verify `status` enum values only ([placed, paid, shipped])

### Schema Compliance
- Verify all 404 responses include required `code` field
- Verify all error responses match Error schema exactly
- Verify all order responses match Order schema exactly

### Edge Cases
- Large valid `note` values (500 characters exactly)
- Order IDs at boundaries (1, very large integers)
- Empty vs. null fields in optional properties
- Concurrent requests to same order
