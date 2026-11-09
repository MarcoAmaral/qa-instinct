# API Contract Mismatches

## Response 1: GET /orders/1042 → 200

**Mismatches:**
- `total` is a string `"42.50"` but schema requires `type: number`
- `note` is `null` but schema specifies `type: string` (when present, must be a string; alternatively, schema should allow null via `nullable: true` or `type: [string, null]`)

## Response 2: GET /orders/999999 → 404

**Mismatches:**
- Missing required field `code` in Error schema (has only `message`)
- Error schema requires both `code` and `message`; response provides only `message`

## Response 3: POST /orders → 500

**Mismatches:**
- HTTP status `500` is not defined in OpenAPI spec (only `201` and `400` are valid responses)
- Response body field `error` does not match Error schema (which requires `code` and `message`)
- Error message is a database implementation detail, not an API-level error code/message

**Schema Gap:**
- OpenAPI schema does not declare `note` field has a maximum length, but implementation enforces `character varying(500)` (500 chars max). POST should fail with 400 and proper Error schema, not 500.

---

# Test Suite Design

## Happy Path

1. **GET /orders/{id} returns valid Order**
   - Assert status code is 200
   - Assert `id` is integer
   - Assert `status` is one of: placed, paid, shipped
   - Assert `total` is a number (not string)
   - Assert `note` (if present) is a string (not null)

2. **POST /orders creates Order with required fields only**
   - Request: `{"items": ["sku-1"]}`
   - Assert status code is 201
   - Assert response contains `id` (integer), `status` (string enum), `total` (number)
   - Assert response `note` is absent or a string (never null)

3. **POST /orders creates Order with optional note**
   - Request: `{"items": ["sku-1", "sku-2"], "note": "rush order"}`
   - Assert status code is 201
   - Assert all Order fields present with correct types

## Error Cases

4. **GET /orders/{nonexistent} returns 404 with Error schema**
   - Assert status code is 404
   - Assert response has `code` (string, required)
   - Assert response has `message` (string, required)
   - Assert no extra fields or malformed response

5. **POST /orders with empty items array returns 400**
   - Request: `{"items": []}`
   - Assert status code is 400
   - Assert Error schema with `code` and `message` fields

6. **POST /orders with missing items field returns 400**
   - Request: `{"note": "test"}`
   - Assert status code is 400
   - Assert Error schema compliance

7. **POST /orders with note exceeding 500 characters returns 400 (not 500)**
   - Request: `{"items": ["sku-1"], "note": "<5001 character string>"}`
   - Assert status code is 400 (not 500)
   - Assert Error schema with `code` and `message` (not database error)

8. **POST /orders with non-string items elements returns 400**
   - Request: `{"items": [123, true]}`
   - Assert status code is 400
   - Assert Error schema compliance

## Edge Cases

9. **GET /orders with non-integer path parameter returns 400 or 404**
   - Path: `/orders/abc`
   - Assert error response (400 or 404 per implementation)
   - Assert Error schema compliance

10. **All error responses use consistent Error schema**
    - Every 4xx/5xx response must include `code` and `message` fields
    - No database error strings exposed to client
    - All error responses have `Content-Type: application/json`

11. **Type validation for Order response fields**
    - Verify `total` is always numeric (test with various decimal values)
    - Verify `note` is never null when returned (either string or field omitted)
    - Verify `id` is always positive integer
