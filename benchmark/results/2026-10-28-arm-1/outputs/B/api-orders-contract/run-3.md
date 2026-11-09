# QA Report: Orders API Compliance Issues

## Contract Mismatches Found

### Response 1: GET /orders/1042 → 200
**Issues:**
- **Type violation**: `total` field is string `"42.50"` but schema requires `type: number` (integer or float)
- **Null violation**: `note` field is `null` but schema defines it as `type: string` without nullable specification. Per OpenAPI 3.0.3 strict interpretation, non-nullable types cannot be null.

**Assumption:** `total` should be numeric type `42.50` (not quoted), and `note` should either be omitted (if optional) or be a string value.

---

### Response 2: GET /orders/999999 → 404
**Issues:**
- **Missing required field**: Response missing `code` field. Schema requires both `code` (string) and `message` (string) as required fields.
- **Incomplete error object**: Only `message` is present; `code` is absent, violating the required fields constraint.

**Assumption:** Error response should include both fields, e.g., `{"code": "NOT_FOUND", "message": "Order not found"}`.

---

### Response 3: POST /orders with large note → 500
**Issues:**
- **Wrong status code**: Returns 500 (server error) instead of 400 (bad request). The schema defines only 201 and 400 as valid responses.
- **Wrong response schema**: Response body `{"error": "..."}` does not match Error schema which requires `code` and `message` fields.
- **Unhandled business rule**: The 5,000 character note exceeds an apparent 500 character database limit, but this validation is not documented in the schema.

**Assumption:** API should validate note length before processing and return 400 with proper Error schema. The `note` field may have an undocumented max length constraint that should be added to the OpenAPI spec.

---

## Test Suite Design

### 1. Happy Path Tests
- **GET /orders/{id} with valid id** → 200 with complete Order object (all required fields as correct types)
- **POST /orders with valid items array** → 201 with Order object including generated id and default status
- **POST /orders with optional note** → 201 respecting the note value

### 2. Parameter Validation Tests
- **GET /orders/{id} with id < 1** → 400 (violates `minimum: 1` constraint)
- **GET /orders/{id} with non-integer id** → 400 or 404
- **GET /orders/{id} with very large id** → 404 (order not found)
- **GET /orders/{id} with string id** → 400 (schema type violation)

### 3. Request Body Validation Tests
- **POST /orders with missing items** → 400 (required field)
- **POST /orders with empty items array** → 400 (violates `minItems: 1`)
- **POST /orders with non-array items** → 400 (type violation)
- **POST /orders with non-string item** → 400 (type violation)
- **POST /orders with note exceeding 500 chars** → 400 with Error schema (not 500)
- **POST /orders with note as non-string** → 400 (type violation)
- **POST /orders with extra unknown fields** → 201 (allowed per spec) or 400 (if strict validation)

### 4. Response Schema Compliance Tests
- **All 200/201 responses** → Validate `id` (integer), `status` (enum: placed|paid|shipped), `total` (number, not string), required fields present, no null values for non-nullable fields
- **All 400/404 responses** → Validate Error schema has both `code` (string) and `message` (string) fields, both non-empty

### 5. Status Field Enum Tests
- **Order status values** → Test that only "placed", "paid", "shipped" appear (not arbitrary strings)

### 6. Edge Cases
- **POST with maximum valid note length** → 500 characters, should succeed with 201
- **POST with 501 character note** → Should return 400, not 500
- **GET order that exists but has null/missing optional fields** → Verify only required fields are present or schema allows nullable
- **Concurrent POST requests** → Verify id uniqueness in responses

### 7. HTTP Semantics Tests
- **All 5xx responses logged as server errors** → Should not occur for invalid input; return 4xx instead
- **Content-Type on all responses** → Should be `application/json`
