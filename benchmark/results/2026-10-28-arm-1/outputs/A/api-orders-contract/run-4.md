# API Contract Compliance Report

## Mismatches Found

### Response 1: GET /orders/1042 (Status: 200)
| Field | Expected | Actual | Issue |
|-------|----------|--------|-------|
| `total` | `number` | `"42.50"` (string) | Type mismatch: string instead of number |
| `note` | `string` (optional) | `null` | Null value not explicitly allowed by schema |

### Response 2: GET /orders/999999 (Status: 404)
| Issue | Details |
|-------|---------|
| Missing required field | `code` field is required by Error schema but absent |
| Schema mismatch | Response has only `message`; Error schema requires `{code, message}` |

### Response 3: POST /orders (Status: 500)
| Issue | Details |
|-------|---------|
| Unexpected status code | 500 not defined in OpenAPI spec (only 201, 400 allowed) |
| Response schema violation | Body has `error` field; Error schema requires `{code, message}` |
| Unvalidated constraint | Note field lacks `maxLength` in NewOrder schema but API enforces 500-char DB limit |

---

## Test Suite Design

### 1. Happy Path Tests
- **GET /orders/{id} with valid ID** → Verify 200 response with complete Order schema, total as number
- **POST /orders with valid items** → Verify 201 response with Order schema, auto-assigned id, status in [placed, paid, shipped]
- **POST /orders with items and note** → Verify both fields present in response

### 2. Required Field Validation Tests
- **GET /orders/{id}** → Response must include id, status, total
- **POST /orders** → Request body must require items; response must include id, status, total
- **404 Error responses** → Must include both code and message fields

### 3. Type Validation Tests
- **Order.total** → Assert type is number, not string
- **Order.id** → Assert type is integer
- **Order.status** → Assert value is one of [placed, paid, shipped]
- **All string fields** → Assert no unexpected null values or use explicit nullable schema

### 4. Request Validation Tests
- **POST /orders with missing items** → Expect 400 with Error schema
- **POST /orders with empty items array** → Expect 400 (minItems: 1 violation)
- **POST /orders with non-string item** → Expect 400 if schema enforces string type
- **GET /orders/{id} with id < 1** → Expect 400 (minimum: 1 violation)
- **GET /orders/{id} with non-integer id** → Expect 400

### 5. Error Response Schema Tests
- **All 4xx/5xx responses** → Must match Error schema: `{code: string, message: string}`
- **404 responses** → Verify code and message fields populated appropriately

### 6. Edge Case & Constraint Tests
- **POST /orders with note > 500 characters** → Should return 400 (schema violation), not 500; Error schema expected
- **POST /orders with very long note (5000 chars)** → Verify graceful rejection, not database error leak
- **POST /orders with special characters in items/note** → Verify handling of XML, SQL, unicode
- **GET /orders with boundary ID values** → Test id=1 (minimum), large integers

### 7. Content-Type Tests
- All responses must declare `application/json` content type
- POST request must send `application/json` content type

### 8. Assumptions Made
- `note` field should explicitly allow `null` in Order schema if API returns it, or API should omit the field
- A database constraint (500-char limit on note) should be declared in OpenAPI schema as `maxLength: 500`
- Error responses with code 500 suggest unhandled exceptions; all errors should map to documented status codes with proper Error schema
