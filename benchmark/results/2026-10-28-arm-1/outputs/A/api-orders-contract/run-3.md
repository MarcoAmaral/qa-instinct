## API Contract Mismatches

| # | Response | Mismatch |
|---|----------|----------|
| 1 | GET /orders/1042 → 200 | `total` field is string `"42.50"` but spec requires `type: number` |
| 2 | GET /orders/1042 → 200 | `note` field is `null` but spec defines it as optional string (should be omitted or a string value, not null) |
| 3 | GET /orders/999999 → 404 | Missing required `code` field; only `message` is present (Error schema requires both) |
| 4 | POST /orders → 500 | Undocumented status code; spec defines only 201 and 400 as valid responses |
| 5 | POST /orders → 500 | Response body uses `error` field instead of required `code` and `message` fields |

## Test Strategy

### Happy Path Tests

**GET /orders/{id} - Valid Order**
- Assert status code is 200
- Assert `id` is an integer
- Assert `status` is one of [placed, paid, shipped]
- Assert `total` is a number (not string)
- Assert `note` field is either absent or a string (never null)
- Assert no extra fields beyond spec

**POST /orders - Create Order**
- Assert status code is 201
- Assert response matches Order schema with all required fields: id (integer), status (string enum), total (number)
- Test with minimal payload: `{"items": ["sku-1"]}`
- Test with optional note: `{"items": ["item1", "item2"], "note": "special instructions"}`
- Assert created order has predictable initial status (likely "placed")

### Error Path Tests

**GET /orders/{id} - Not Found**
- Assert status code is 404
- Assert response contains both `code` and `message` fields (Error schema)
- Test with non-existent id: 999999, negative values, zero, max-int

**POST /orders - Invalid Request (400)**
- Empty items array: `{"items": []}`
- Missing items field: `{"note": "test"}`
- Invalid item type: `{"items": [123]}`
- Oversized note field: `{"items": ["sku-1"], "note": "<5000+ character string>"}` → Assert 400 (not 500), with Error schema

**POST /orders - Boundary Tests**
- Maximum note length (assume 500 chars based on error): `{"items": ["sku-1"], "note": "<500 char string>"}` → Should succeed
- Just over limit (501 chars): Should return 400 with proper Error schema

### Schema Validation Tests

- All Order responses must have required fields: id, status, total
- All Error responses must have required fields: code, message
- Numeric fields (`id`, `total`) must be JSON numbers, not strings
- Optional fields (`note` in Order) should be present as their defined type or absent—never null
- Invalid enum values for `status` should be rejected
