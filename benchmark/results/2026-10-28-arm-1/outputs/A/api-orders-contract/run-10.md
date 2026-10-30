# API Contract Mismatches

## Response 1: GET /orders/1042 → 200

**Mismatch 1: `total` field type**
- Expected: `number` (per schema)
- Received: `"42.50"` (string)
- Severity: Type violation

**Mismatch 2: `note` field value**
- Expected: `string` type (optional, but if present must be string) or omitted entirely
- Received: `null`
- Severity: Type violation — null is not of type string

## Response 2: GET /orders/999999 → 404

**Mismatch 1: Missing required `code` field**
- Expected: `Error` schema requires `{code: string, message: string}`
- Received: `{message: "Order not found"}` (missing `code`)
- Severity: Schema violation — required field absent

## Response 3: POST /orders with oversized note → 500

**Mismatch 1: Undocumented status code**
- Expected: 201 (Created) or 400 (Invalid order) per OpenAPI spec
- Received: 500 (not in spec)
- Severity: Contract violation

**Mismatch 2: Error response schema mismatch**
- Expected: `Error` schema `{code: string, message: string}`
- Received: `{error: "..."}` (wrong field name, no `code`)
- Severity: Response structure violation

---

# Test Suite Design

## Validation Tests

1. **GET /orders/{id} returns total as number**
   - Call GET /orders/1042
   - Assert response.total is typeof number, not string
   - Assert response.total equals 42.50

2. **GET /orders/{id} returns note as string or omits it**
   - Call GET /orders/1042 (or any order with note)
   - Assert response.note is either a string OR the field is absent
   - Assert response.note is never null

3. **404 Error response includes required code field**
   - Call GET /orders/999999
   - Assert response.code exists and is a string
   - Assert response.message exists and is a string
   - Verify both required fields per Error schema

4. **POST /orders with oversized note returns 400, not 500**
   - POST /orders with {"items": ["sku-1"], "note": "<5000+ chars>"}
   - Assert status code is 400 (not 500)
   - Assert response matches Error schema {code, message}

5. **POST /orders returns proper Error schema on validation failure**
   - POST /orders with {"items": []}  (violates minItems: 1)
   - Assert status is 400
   - Assert response has both code and message fields
   - Assert no "error" field (wrong structure)

## Happy Path Tests

6. **POST /orders creates order with all required fields**
   - POST /orders with {"items": ["sku-1"]}
   - Assert status is 201
   - Assert response.id is integer
   - Assert response.status is enum value (placed, paid, or shipped)
   - Assert response.total is number
   - Assert response has required fields only

7. **POST /orders creates order with optional note**
   - POST /orders with {"items": ["sku-1"], "note": "urgent"}
   - Assert status is 201
   - Assert response.note equals "urgent" (string, not null)

8. **GET /orders/{id} retrieves created order**
   - POST /orders to create order
   - GET /orders/{created_id}
   - Assert status is 200
   - Assert all fields match Order schema (total as number, not string)

## Edge Cases

9. **POST /orders rejects empty items array**
   - POST /orders with {"items": []}
   - Assert status is 400

10. **POST /orders rejects missing items field**
    - POST /orders with {"note": "test"}
    - Assert status is 400
    - Assert error code/message indicate missing required field

11. **GET /orders with invalid id format returns 400 or 404**
    - GET /orders/abc (non-integer)
    - Assert status is 400 (invalid format per schema minimum: 1)

12. **GET /orders with id < 1 returns 400**
    - GET /orders/0 or GET /orders/-1
    - Assert status is 400 (violates schema minimum: 1)
