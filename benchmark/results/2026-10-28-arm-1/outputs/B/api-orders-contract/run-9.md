# API QA Report: Orders API v2.1.0

## Recorded Response Mismatches

| Response | Issue | Severity | Details |
|----------|-------|----------|---------|
| 1. GET /orders/1042 | Type mismatch: `total` field | High | Returned as string `"42.50"` but OpenAPI schema specifies `type: number`. Should be numeric (e.g., `42.50` without quotes). |
| 1. GET /orders/1042 | Optional field `note` | Medium | Returned as `null` instead of string or omitted. Schema specifies `type: string`; `null` violates the type contract (though some clients tolerate this). |
| 2. GET /orders/999999 | Missing required field | High | Error response missing `code` field. OpenAPI Error schema requires both `code` and `message`; response only contains `message`. |
| 3. POST /orders | Undocumented response code | Critical | HTTP 500 returned but OpenAPI spec only defines 201 and 400 responses. Spec does not account for server errors. |
| 3. POST /orders | Invalid error schema | High | Response has `{"error": "..."}` structure; does not match Error schema (missing `code`, wrong field name for message). |
| 3. POST /orders | Information disclosure | Medium | Database constraint error exposed (`character varying(500)`) rather than user-friendly message. |

---

## Test Suite Design

### 1. GET /orders/{id} — Success Path

- **Test 1.1**: Retrieve valid order (id: 1) → expect 200, Order schema with all required fields (id, status, total) as correct types
- **Test 1.2**: Verify `status` enum enforcement (only "placed", "paid", "shipped" allowed)
- **Test 1.3**: Verify `total` is a number type, not string
- **Test 1.4**: Verify optional `note` field: either omitted or string type (not null)
- **Test 1.5**: Response Content-Type header is `application/json`

### 2. GET /orders/{id} — Error Cases

- **Test 2.1**: Retrieve non-existent order (id: 999999) → expect 404 with Error schema containing both `code` and `message` fields as strings
- **Test 2.2**: Invalid id parameter: negative integer → expect 4xx with appropriate error
- **Test 2.3**: Invalid id parameter: zero → expect 4xx (schema specifies minimum: 1)
- **Test 2.4**: Invalid id parameter: non-integer (e.g., "abc", "1.5") → expect 4xx
- **Test 2.5**: Invalid id parameter: too large (beyond integer range) → expect 4xx
- **Test 2.6**: Missing id parameter → expect 4xx or 5xx

### 3. GET /orders/{id} — Boundary & Edge Cases

- **Test 3.1**: Minimum valid id (1) → expect 200
- **Test 3.2**: Large valid id (e.g., 2147483647) → expect 200 or 404 (depends on data)
- **Test 3.3**: Response time and payload size within acceptable limits

### 4. POST /orders — Success Path

- **Test 4.1**: Create order with items array only → expect 201, Order schema with all required fields, correct types
- **Test 4.2**: Create order with items and note → expect 201, Order schema includes note as string
- **Test 4.3**: Verify returned `status` is set to a valid enum value (assumption: initial status is "placed")
- **Test 4.4**: Verify returned `id` is a positive integer
- **Test 4.5**: Response Content-Type header is `application/json`
- **Test 4.6**: Verify `total` in response is a number type (not string)

### 5. POST /orders — Invalid Input

- **Test 5.1**: Missing `items` field → expect 400 with Error schema (code + message)
- **Test 5.2**: Empty `items` array → expect 400 (schema: minItems: 1)
- **Test 5.3**: `items` not an array (e.g., object, string, number) → expect 400
- **Test 5.4**: `items` array with non-string elements (e.g., [1, null, {}]) → expect 400
- **Test 5.5**: Extra/unknown fields in request → expect 200/201 (behavior: reject or ignore, assumption: ignore)
- **Test 5.6**: `note` field is not a string (e.g., number, array) → expect 400
- **Test 5.7**: `note` field exceeds maximum length (test 500 chars boundary, 501 chars, 5000 chars) → expect 400 with proper Error schema (currently returns 500 with wrong schema)

### 6. POST /orders — Error Response Format

- **Test 6.1**: All 400 responses include both `code` and `message` fields as strings
- **Test 6.2**: Error `code` values are consistent and meaningful (e.g., "INVALID_ORDER", "MISSING_ITEMS")
- **Test 6.3**: Error messages are user-friendly and do not expose internal database details
- **Test 6.4**: No undocumented 5xx responses returned for client input errors

### 7. General Contract Compliance

- **Test 7.1**: All responses include correct HTTP status codes as defined in spec
- **Test 7.2**: All error responses follow Error schema (code + message required)
- **Test 7.3**: All Order responses include id, status (valid enum), total (number type)
- **Test 7.4**: No null values for fields with explicit string type (use omission or provide valid string)
- **Test 7.5**: Content-Type headers are consistently `application/json`

---

## Assumptions Made

- Initial order status upon creation is "placed" (not defined in spec)
- Maximum note length is 500 characters (inferred from database error)
- Additional/unknown request fields are silently ignored
- A 500 error for request validation is a server bug, not a documented feature; tests should verify proper 400 responses instead
