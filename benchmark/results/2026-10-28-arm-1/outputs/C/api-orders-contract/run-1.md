# API Contract Mismatches

## Response 1: GET /orders/1042

**Mismatch:** `total` field type

- **Contract specifies:** `total` as `number` type
- **Response returns:** `"42.50"` as a string
- **Impact:** Clients expecting a numeric type will fail type validation or encounter parsing errors

## Response 2: GET /orders/999999

**Mismatch:** Error schema incomplete

- **Contract specifies:** Error requires `code` (string) and `message` (string)
- **Response returns:** Only `message` field; `code` is missing
- **Impact:** Consumers relying on `code` for error handling (retries, user messaging by error type) cannot parse the response

## Response 3: POST /orders

**Mismatch:** Undocumented response status and schema

- **Contract specifies:** 400 response for invalid orders, Error schema with `code` and `message`
- **Response returns:** 500 status with `{"error": "..."}` (neither 201 nor 400; wrong schema)
- **Impact:** Client error-handling branches for 400 are not exercised; the note length validation should return 400, not 500

**Additional finding:** The OpenAPI schema does not document an upper limit on the `note` field, but the implementation enforces a 500-character varchar limit. This limit should be added to the schema (`maxLength: 500`).

---

# Recommended Test Suite

Organize by endpoint and scenario:

## GET /orders/{id}

| Test case | Input | Expected | Currently missing |
|-----------|-------|----------|-------------------|
| Valid order | id=1042 | 200, Order with numeric `total` | Numeric type validation |
| Not found | id=999999 | 404, Error with `code` and `message` | `code` field validation |
| Invalid ID (below minimum) | id=0 | 400 or 404 | Boundary test |
| Invalid ID (non-integer) | id=abc | 400 | Input validation test |
| Large valid ID | id=2147483647 | 200 or 404 | Boundary test |

## POST /orders

| Test case | Body | Expected | Currently missing |
|-----------|------|----------|-------------------|
| Valid, minimal | `{"items":["sku-1"]}` | 201, Order with all required fields | Happy path validation |
| Valid with note | `{"items":["sku-1"], "note":"test"}` | 201, Order with note | Happy path with optional field |
| Note at limit | `{"items":["sku-1"], "note":"<500-char string>"}` | 201 | Boundary test |
| Note exceeds limit | `{"items":["sku-1"], "note":"<501-char string>"}` | 400, Error with `code` and `message` | Returns 500; should return 400 |
| Empty items | `{"items":[]}` | 400, Error with `code` and `message` | minItems validation test |
| Missing items | `{"note":"test"}` | 400, Error with `code` and `message` | Required field validation |
| Multiple items | `{"items":["sku-1","sku-2","sku-3"]}` | 201, Order | Array handling test |
| Invalid item type | `{"items":[123]}` | 400, Error with `code` and `message` | Type validation test |
| Response fields present | (valid request) | Response includes `id`, `status`, `total`, `note` | Schema compliance |
| Response status enum | (valid request) | `status` is one of `["placed","paid","shipped"]` | Enum validation |

## Cross-cutting

- All error responses validate presence and type of `code` and `message` fields
- All 200/201 responses validate that `total` is numeric (not string)
- Validate Content-Type is `application/json` in both requests and responses
