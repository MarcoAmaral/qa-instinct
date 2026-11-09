# API Contract Mismatches

## Response 1: GET /orders/1042 → 200
**Mismatch**: `total` field is a string `"42.50"` but schema requires `type: number`
- Expected: `{"id": 1042, "status": "paid", "total": 42.50, "note": null}`
- Actual: `{"id": 1042, "status": "paid", "total": "42.50", "note": null}`

## Response 2: GET /orders/999999 → 404
**Mismatch**: Missing required `code` field in Error schema
- Expected: `{"code": "...", "message": "Order not found"}`
- Actual: `{"message": "Order not found"}`
- The Error schema requires both `code` and `message` (both in `required` array)

## Response 3: POST /orders → 500
**Multiple mismatches**:
1. **Undocumented status code**: 500 is not in the OpenAPI spec (only 201 and 400 defined)
2. **Wrong response schema**: Response body has `{"error": "..."}` but should use Error schema with `code` and `message` fields
3. **Undocumented constraint**: The `note` field has an unspecified maximum length of 500 characters in the database; this is not documented in the schema
4. **Wrong HTTP status**: Should return 400 Bad Request (documented) with Error schema, not 500 with a custom error format

---

# Required Test Suite

## Type Correctness Tests
- [ ] **test_order_total_is_number**: GET /orders/{id} returns `total` as a JSON number, not string
- [ ] **test_order_id_is_integer**: GET /orders/{id} returns `id` as JSON integer
- [ ] **test_all_order_status_values**: Verify returned `status` is one of: "placed", "paid", "shipped"

## GET /orders/{id} - 404 Response
- [ ] **test_404_error_has_code_field**: GET /orders/{nonexistent} returns Error with both `code` and `message` fields
- [ ] **test_404_error_required_fields**: Error response contains required fields per schema

## POST /orders - Request Validation
- [ ] **test_post_empty_items_returns_400**: POST with `{"items": []}` returns 400 Bad Request with Error schema
- [ ] **test_post_missing_items_returns_400**: POST with `{"note": "text"}` (no items) returns 400 with Error schema
- [ ] **test_post_null_items_returns_400**: POST with `{"items": null}` returns 400
- [ ] **test_post_note_max_length_boundary**: POST with note of exactly 500 characters succeeds (201); 501 characters returns 400 (not 500)
- [ ] **test_post_note_length_error_format**: When note exceeds limit, response is 400 with Error schema (`code` and `message`), not 500
- [ ] **test_post_missing_note_is_valid**: POST with only `{"items": ["sku"]}` succeeds (note is optional)

## POST /orders - Success Response (201)
- [ ] **test_post_returns_order_schema**: Response contains `id`, `status`, `total` (as number, not string)
- [ ] **test_post_returns_correct_status_codes**: Only 201 (Created) and 400 (Bad Request); no 500
- [ ] **test_post_status_enum_values**: Returned order has `status` in ["placed", "paid", "shipped"]
- [ ] **test_post_response_has_note_field**: If note was provided in request, it's returned in response
- [ ] **test_post_response_note_nullable**: If note omitted from request, response includes note field (null or string)

## GET /orders/{id} - Path Validation
- [ ] **test_get_invalid_id_zero**: GET /orders/0 returns 400 or 404 (schema requires minimum: 1)
- [ ] **test_get_negative_id**: GET /orders/-1 returns 400 or 404
- [ ] **test_get_non_integer_id**: GET /orders/abc returns 400 (path parameter must be integer)

## Response Schema Compliance
- [ ] **test_error_schema_always_has_code_and_message**: All 400/404 responses include both required Error fields
- [ ] **test_no_undocumented_fields_in_order**: Order response contains only documented fields (id, status, total, note)
- [ ] **test_no_undocumented_fields_in_error**: Error response contains only documented fields (code, message)

---

# Assumptions Made
- The `note` field maximum length of 500 characters is a business constraint that should be enforced at the API layer, not the database layer
- 500-character error responses indicate a missing input validation layer; the API should validate before database operations
- Field `note` in Error responses should be optional/nullable when omitted from the request
- The `code` field in Error responses should be a machine-readable string (e.g., "order_not_found", "invalid_input")
