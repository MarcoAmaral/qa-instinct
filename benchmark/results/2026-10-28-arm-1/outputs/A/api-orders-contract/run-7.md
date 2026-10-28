# API Contract Mismatches

## 1. Response 1: GET /orders/1042 → 200

**Mismatch: Field Type**
- `total` is returned as string `"42.50"` but schema requires `number` type

**Mismatch: Null Handling**
- `note` is returned as `null`, but the schema does not declare the field as `nullable`. Behavior unclear: should omit the field, or must declare nullable in schema.

---

## 2. Response 2: GET /orders/999999 → 404

**Mismatch: Missing Required Field**
- Response missing required `code` field from Error schema
- Response has only `{"message": "Order not found"}`, but Error requires both `code` and `message`

---

## 3. Response 3: POST /orders with long note → 500

**Mismatch: Unexpected Status Code**
- Response is 500, but contract only defines 201 (success) or 400 (invalid). 500 is outside the contract.

**Mismatch: Wrong Error Format**
- Response uses `{"error": "..."}` but Error schema requires `code` and `message` fields
- This appears to be an unhandled database constraint error leaking to the client

**Missing Input Validation**
- The API does not validate that `note` fits within limits before attempting to insert. Assumption: `note` should be validated client-side to reject strings longer than the database column limit (appears to be 500 characters).

---

# Test Plan

## Schema Compliance Tests

### GET /orders/{id} - Success Case
- [ ] Status is 200
- [ ] Response matches Order schema: all required fields present (`id`, `status`, `total`)
- [ ] `id` is integer
- [ ] `status` is one of: "placed", "paid", "shipped"
- [ ] `total` is number type, not string (fix: parse or return as `42.50` not `"42.50"`)
- [ ] `note` field either omitted (preferred) or explicitly nullable in schema

### GET /orders/{id} - Not Found
- [ ] Status is 404
- [ ] Response matches Error schema: both `code` and `message` present and non-null
- [ ] `code` and `message` are both strings
- [ ] Add required `code` field to error response

### POST /orders - Success Case
- [ ] Status is 201
- [ ] Response matches Order schema (same checks as GET success)
- [ ] Returned `id` is integer and unique
- [ ] Returned `status` is one of enum values

### POST /orders - Validation Failures
- [ ] Missing `items` field → 400 with Error schema (both `code` and `message`)
- [ ] Empty `items` array → 400 (minItems: 1 violation)
- [ ] Non-string items in array → 400
- [ ] `note` field exceeding 500 characters → 400 with Error schema, not 500 with database error message
- [ ] All error responses use `code` and `message` fields (not `error`)

## Input Boundary Tests

- [ ] `note` with 500 characters → accepted
- [ ] `note` with 501 characters → rejected with 400
- [ ] `items` with exactly 1 item → accepted
- [ ] `items` with 0 items → rejected with 400
- [ ] `items` array with 100+ items → accepted (or rejected if there's an upper limit)

## Type Correctness Tests

- [ ] `id` in response is always integer, never string
- [ ] `total` in response is always number, never string
- [ ] `status` in response is string and matches enum

---

# Assumptions

1. **Null handling**: Assumed `note` should be omitted from response rather than included as `null`, or schema should be updated to declare `nullable: true`.
2. **Note length limit**: Assumed the database column limit of 500 characters should be enforced at the API validation layer, with a 400 response, not exposed as a 500 error.
3. **Error code values**: Assumed `code` field in Error responses should contain machine-readable identifiers (e.g., "ORDER_NOT_FOUND", "INVALID_REQUEST", "REQUEST_TOO_LARGE"), though specific values are not defined in the contract.
