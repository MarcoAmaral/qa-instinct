# OpenAPI Contract Mismatches

## Response 1: GET /orders/1042 → 200
**Issue: Type mismatch in `total` field**
- Spec requires: `total` as `type: number`
- Recorded response: `"total": "42.50"` (string)
- Impact: Response violates the schema contract

**Issue: Invalid `note` value**
- Spec requires: `note` as `type: string` (when present)
- Recorded response: `"note": null`
- Impact: Null is not a valid string value; should either be a string or the property should be omitted

## Response 2: GET /orders/999999 → 404
**Issue: Missing required field**
- Spec requires Error schema with: `code` (required) and `message` (required)
- Recorded response: `{"message": "Order not found"}` (missing `code`)
- Impact: Response violates the Error schema contract; cannot be validated against `$ref: "#/components/schemas/Error"`

## Response 3: POST /orders → 500
**Issue: Undocumented response code**
- Spec defines responses: `201` and `400` only
- Recorded response: HTTP 500 (not in spec)
- Impact: Response code not part of the API contract

**Issue: Invalid error response format**
- Spec requires Error schema with: `code` and `message` (both required)
- Recorded response: `{"error": "value too long for type character varying(500)"}`
- Impact: Uses `error` field instead of `code`/`message`; violates Error schema

**Issue: Undocumented constraint on `note` field**
- Database error references `character varying(500)`, implying max length of 500 characters
- Spec does not document this constraint in NewOrder schema
- Impact: Request validation cannot be properly implemented by clients

---

# Test Design

## Test Categories

### 1. GET /orders/{id} - Happy Path
- **Valid order retrieval**: GET /orders/{existing_id} returns 200 with complete Order object
  - Assert: status in [placed, paid, shipped]
  - Assert: total is a number
  - Assert: id matches request
  - Assert: id is integer type
  - Assert: status is string enum value
  - Assert: total is number type

### 2. GET /orders/{id} - Error Handling
- **Order not found**: GET /orders/999999 returns 404 with Error schema
  - Assert: response has both `code` and `message` fields
  - Assert: both fields are strings
  - Assert: Content-Type is application/json

- **Invalid id parameter**: GET /orders/0, /orders/-1, /orders/abc
  - Assert: returns 400 (or documents expected behavior)

### 3. POST /orders - Happy Path
- **Minimal order**: POST with `{"items": ["sku-1"]}` returns 201
  - Assert: response is Order schema with all required fields
  - Assert: total is number type, not string
  - Assert: id is present and integer

- **Order with note**: POST with `{"items": ["sku-1"], "note": "customer note"}`
  - Assert: note field in response matches request (or is properly transformed)
  - Assert: note is string type, not null

### 4. POST /orders - Validation
- **Missing items**: POST with `{"note": "test"}` returns 400 with Error schema
  - Assert: error has `code` and `message`

- **Empty items array**: POST with `{"items": []}` returns 400
  - Assert: error indicates minItems violation

- **Non-array items**: POST with `{"items": "sku-1"}` returns 400

- **Note length boundary**: POST with note containing exactly 500 and 501 characters
  - Assert: behavior is consistent and documented (currently returns 500 on overflow; should return 400 per spec)

### 5. Schema Compliance
- **All response fields match declared types**
  - For Order: id (int), status (string enum), total (number, not string)
  - For Error: code (string), message (string)

- **Optional fields handling**
  - note should be omitted or be a valid string, never null

### 6. Content-Type Validation
- All responses should have Content-Type: application/json

---

# Recommended Fixes

1. **Fix `total` serialization**: Return as number, not string (42.50 not "42.50")
2. **Fix `note` null handling**: Return omitted property or valid string, never null
3. **Add `code` to 404 errors**: Include both required fields in Error schema
4. **Document note length limit**: Add `maxLength: 500` to NewOrder schema or reject with 400
5. **Add validation error responses**: Ensure 400 responses use proper Error schema with code/message
6. **Validate request schema**: Reject requests violating NewOrder constraints with 400, not 500
