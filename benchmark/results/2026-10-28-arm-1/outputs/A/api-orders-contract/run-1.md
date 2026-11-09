# API Contract Mismatches

## Response 1: GET /orders/1042 → 200
**Mismatch: `total` field type**
- Expected: `number`
- Actual: `string` ("42.50")

**Mismatch: `note` field nullability**
- Schema specifies `type: string` with no `nullable: true`
- Actual: `null`
- Expected: either absent from response or a string value

## Response 2: GET /orders/999999 → 404
**Mismatch: Error schema incomplete**
- Required fields: `code`, `message`
- Actual: only `message` present
- Missing: `code` field

## Response 3: POST /orders (with 5000-char note) → 500
**Mismatch: Incorrect status code**
- Expected: `400` (Invalid order) or `201` (Created)
- Actual: `500`
- The note field exceeds database limit; should be validated and return 400

**Mismatch: Error response schema**
- Expected: `{ code: string, message: string }`
- Actual: `{ error: string }`

---

# Recommended Test Suite

## Happy Path Tests
- **GET /orders/{id} with valid id** → 200, Order with all required fields (id as integer, status in enum, total as number)
- **GET /orders/{id} with all optional fields** → Order includes optional `note` as string (not null)
- **POST /orders with minimal body** → 201, Order with id, status, total
- **POST /orders with note field** → 201, Order includes note as string

## Validation Tests
- **GET /orders/0** → 404 (id minimum is 1)
- **GET /orders/-1** → 404 or 400 (negative id violates minimum: 1)
- **GET /orders/abc** → 400 (non-integer id)
- **POST /orders with empty items** → 400 (minItems: 1)
- **POST /orders without items field** → 400 (required)
- **POST /orders with note > 500 chars** → 400 (validate max length before processing)

## Response Schema Compliance Tests
- **GET /orders/{id} return type** → verify `total` is number, not string
- **GET /orders/{id} null handling** → verify `note` is never null; either omitted or string
- **404 Error response** → verify both `code` and `message` fields present
- **400 Error response** → verify both `code` and `message` fields present

## Status Enum Tests
- **Retrieve orders** → verify `status` is one of: `placed`, `paid`, `shipped`
- **Created order default status** → verify newly created orders have valid status value

## Edge Cases
- **POST /orders with very long item SKU** → 201 or 400 depending on field limits
- **GET /orders/{id} with max integer** → 404 (order doesn't exist) or 200
- **POST /orders with unicode/special chars in note** → 201 (should be accepted)
- **POST /orders with note exactly 500 chars** → 201 (boundary test)
- **POST /orders with note at 501 chars** → 400 (just over boundary)
