# API Contract Mismatches

## GET /orders/1042 (Response 1)

| Field | Contract | Recorded | Issue |
|-------|----------|----------|-------|
| `total` | `number` | `"42.50"` (string) | Type mismatch: returned string instead of number |
| `note` | `string` (optional) | `null` | Null value not allowed; should be absent or a string |

## GET /orders/999999 (Response 2)

| Field | Contract | Recorded | Issue |
|-------|----------|----------|-------|
| `code` | required | missing | Error schema requires `code` field; response omits it |
| Response structure | Error schema with `{code, message}` | `{message}` only | Incomplete Error object |

## POST /orders (Response 3)

| Issue | Details |
|-------|---------|
| Status code | Contract defines 201 and 400; received 500 |
| Response schema | Contract requires Error `{code, message}`; received `{error: "..."}` |
| Undocumented constraint | `note` field enforced at 500 characters max server-side; not in OpenAPI schema |
| Error handling | Validation error (5,000-char string) treated as 500 server error instead of 400 client error |

---

# Tests Required

## Schema Compliance Tests

- **GET /orders/{id} success case:** Verify `total` is a number (not string)
- **GET /orders/{id} success case:** Verify `note` is either absent or a string (never `null`)
- **GET /orders/{id} 404 case:** Verify Error response includes both `code` and `message` fields
- **POST /orders 201 case:** Verify Order response matches schema (number `total`, string or absent `note`)
- **POST /orders 400 case:** Verify Error response includes both `code` and `message` fields

## Constraint Tests

- **GET /orders with id < 1:** Should reject with 400 or 404 (validate minimum constraint)
- **POST /orders with empty items array:** Should return 400 (validate minItems: 1)
- **POST /orders with note > 500 characters:** Should return 400 with Error schema, not 500 with generic error
- **POST /orders with note exactly 500 characters:** Should succeed (boundary test)
- **POST /orders missing items field:** Should return 400 (validate required field)

## Type Validation Tests

- **POST /orders with items as non-array:** Should return 400
- **POST /orders with items containing non-strings:** Should return 400
- **GET /orders/{id} with non-integer id:** Should reject before processing

## Error Response Consistency Tests

- All 400 responses must return Error schema: `{code: string, message: string}`
- All 404 responses must return Error schema: `{code: string, message: string}`
- No 5xx responses for documented validation errors; wrap constraint violations as 400

## Integration Tests

- **Create and retrieve:** POST an order, then GET it by id; verify all fields match
- **Note field round-trip:** POST with note < 500 chars; retrieve; verify it persists as string
- **Empty note:** POST with no note field; verify response has note absent or null (per fix)

---

# Assumptions

- The `note` field should allow `null` in optional fields (common JSON API pattern), or responses should omit it entirely; schema update needed for clarity
- Server-side constraint on `note` (500 chars) should be documented in OpenAPI `schema.maxLength: 500`
- Status 500 on response 3 indicates a server bug; this validation should return 400
- `total` in response 1 represents monetary amount and should be number type (e.g., `42.50` not `"42.50"`)
