# Orders API QA Report

## Findings: Contract Violations

| # | Endpoint | Status | Issue | Severity |
|---|----------|--------|-------|----------|
| 1 | GET /orders/1042 | 200 | `total` field is string `"42.50"` but schema requires `type: number` | HIGH |
| 2 | GET /orders/1042 | 200 | `note` field is `null` but schema defines `type: string` (not nullable) | HIGH |
| 3 | GET /orders/999999 | 404 | Missing required `code` field in Error schema (only has `message`) | HIGH |
| 4 | POST /orders | 500 | Status code 500 not defined in OpenAPI contract (only 201, 400 allowed) | HIGH |
| 5 | POST /orders | 500 | Error response `{"error": "..."}` doesn't match Error schema structure | HIGH |
| 6 | POST /orders | 500 | Schema missing `maxLength` constraint on `note` field (server enforces 500 chars) | MEDIUM |

---

## Test Suite Design

### 1. GET /orders/{id} - Happy Path
- **GET /orders/1** (assuming valid ID exists)
  - Assert: Status 200
  - Assert: Response matches Order schema exactly (id: integer, status: enum, total: number)
  - Assert: All required fields present (id, status, total)
  - Assert: If note present, it is string type (not null)

### 2. GET /orders/{id} - Not Found
- **GET /orders/999999999**
  - Assert: Status 404
  - Assert: Response has required Error fields: `code` (string) and `message` (string)
  - Assert: No extra fields not in schema

### 3. GET /orders/{id} - Invalid Input
- **GET /orders/0** (id < minimum 1)
  - Assert: Status 400
  - Assert: Error schema returned

- **GET /orders/abc** (id not integer)
  - Assert: Status 400
  - Assert: Error schema returned

### 4. POST /orders - Minimal Valid Request
- **POST /orders with body `{"items": ["item-1"]}`**
  - Assert: Status 201
  - Assert: Response matches Order schema (id: integer, status: enum, total: number)
  - Assert: Returned status is one of: placed, paid, shipped

### 5. POST /orders - With Optional Note
- **POST /orders with body `{"items": ["item-1"], "note": "test note"}`**
  - Assert: Status 201
  - Assert: Response note field is string type (not null)

### 6. POST /orders - Invalid Requests
- **POST /orders with body `{"items": []}`** (empty items array)
  - Assert: Status 400
  - Assert: Error schema returned with code and message

- **POST /orders with body `{"note": "test"}`** (missing items)
  - Assert: Status 400
  - Assert: Error schema returned with code and message

- **POST /orders with body `{"items": ["item-1"], "note": "<string of 501 characters>"}`**
  - Assert: Status 400 (not 500)
  - Assert: Error schema returned with code and message

- **POST /orders with body `{"items": ["item-1"], "note": "<string of 5000 characters>"}`**
  - Assert: Status 400 (not 500)
  - Assert: Error schema returned with code and message
  - Assert: Response matches Error schema structure

### 7. POST /orders - Multiple Items
- **POST /orders with body `{"items": ["sku-1", "sku-2", "sku-3"]}`**
  - Assert: Status 201
  - Assert: Order created successfully

### 8. Type Validation Tests
- **Verify total field is always numeric** (not string) in all 200 responses
- **Verify null values** are never returned for non-nullable fields (status, id, total in Order; code, message in Error)
- **Verify enum values** for status are strictly: placed, paid, or shipped

### 9. Schema Completeness Tests
- **GET 200 response** contains no extra fields beyond Order schema
- **GET 404 response** contains exactly required Error fields
- **POST 201 response** contains no extra fields beyond Order schema
- **POST 400 response** contains exactly required Error fields

### 10. Documentation Gap Tests
- **Add to OpenAPI schema:** `note: { type: string, maxLength: 500 }` in NewOrder
- **Add to OpenAPI schema:** Nullable note support or remove null from recorded response 1
- **Add to OpenAPI schema:** Error response must include `code` field in all error cases
- **Document or fix:** POST /orders should not return 500 for request validation errors

---

## Recommended Fixes (Priority Order)

1. **Cast `total` to number** in GET /orders/{id} response (currently string)
2. **Add `code` field** to all 404 Error responses
3. **Change POST /orders validation error handling** from 500 to 400 with proper Error schema
4. **Update OpenAPI schema** to include `note: { maxLength: 500 }` and clarify nullable fields
5. **Standardize Error responses** to always include required `code` and `message` fields
