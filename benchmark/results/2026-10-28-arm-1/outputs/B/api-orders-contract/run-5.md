# QA Report: Orders API 2.1.0 Contract Verification

## Mismatch Findings

### Response 1: GET /orders/1042 (Status: 200)
| Issue | Severity | Details |
|-------|----------|---------|
| Type mismatch: `total` field | **High** | Contract specifies `type: number`; recorded response has string `"42.50"`. JSON numbers should not be quoted. |
| Null value for `note` | **Medium** | Contract does not specify `note` as nullable. Field should either be omitted if null, or schema should allow `null` type explicitly. |

### Response 2: GET /orders/999999 (Status: 404)
| Issue | Severity | Details |
|-------|----------|---------|
| Missing required field `code` | **High** | Error schema requires `[code, message]` per contract. Recorded response only includes `message`. |

### Response 3: POST /orders (Status: 500)
| Issue | Severity | Details |
|-------|----------|---------|
| Unexpected HTTP status | **High** | Contract specifies only 201 or 400; API returned 500. Indicates unhandled server error. |
| Invalid error response structure | **High** | Response contains `error` field; Error schema requires `[code, message]`. |
| Missing validation constraint in contract | **High** | Database rejects note >500 chars with server error instead of 400 Bad Request. Contract does not document `note` maxLength; suggests specification gap. |
| Assumption: Database constraint not enforced at API layer | **Medium** | 5,000 char string should be rejected at request validation (400) before database, not causing 500. |

---

## Recommended Test Suite

### Core Contract Compliance Tests

**GET /orders/{id} - Valid Order**
- Fetch existing order by valid integer ID
- Assertions:
  - Status code: 200
  - Response body matches Order schema exactly
  - `total` field is JSON number (not string)
  - `status` value is one of [placed, paid, shipped]
  - If `note` is present, it is non-null string
  - All required fields [id, status, total] present

**GET /orders/{id} - Not Found**
- Fetch non-existent order (e.g., id=999999)
- Assertions:
  - Status code: 404
  - Response matches Error schema
  - Both required fields `code` and `message` present
  - `message` content is meaningful (e.g., "Order not found")

**GET /orders/{id} - Invalid Input**
- Test with non-integer, negative, or zero ID
- Assertions:
  - Status code: 400 (per contract's path parameter `minimum: 1`)
  - Response matches Error schema with both `code` and `message`

**POST /orders - Valid Creation**
- Create order with valid items array (≥1 item) and optional note
- Assertions:
  - Status code: 201
  - Response matches Order schema
  - Returned `id` is integer
  - `status` defaults to valid enum value
  - `total` is JSON number

**POST /orders - Valid with Note**
- Create order with items + note field
- Assertions:
  - Status code: 201
  - Note field echoed in response
  - Note length constraint not violated (test boundary: if max is undocumented, test both 100 and 500 char strings, and >500)

**POST /orders - Missing Items**
- POST with no `items` or `items: []`
- Assertions:
  - Status code: 400
  - Error schema [code, message] present
  - Error message indicates `items` required or minItems violation

**POST /orders - Invalid Items Type**
- POST with `items: "not-an-array"` or `items: null`
- Assertions:
  - Status code: 400
  - Error schema present

**POST /orders - Note Length Boundary (Critical)**
- POST with note lengths: 0, 1, 499, 500, 501, 1000, 5000
- Assertions:
  - Lengths ≤500: Status 201 with Order schema
  - Lengths >500: Status **400** with Error schema (not 500)
  - Error code and message clearly indicate length violation

**POST /orders - Malformed Request**
- POST with invalid JSON, missing body, wrong Content-Type
- Assertions:
  - Status code: 400
  - Error schema [code, message] present

### Edge Cases & Robustness

**Field Type Coercion**
- POST with `items: [123, true, null]` (non-strings in items array)
- Verify API rejects or coerces consistently, returning 400 with Error schema

**Unicode & Special Characters**
- Order note with emoji, control characters, HTML/SQL injection attempts
- Verify handling is consistent with contract and no 500 errors

**Concurrent Requests**
- Verify no race conditions on order creation, consistent ID generation

**Response Content-Type Validation**
- All responses must include `Content-Type: application/json`

---

## Specification Amendments Required

1. **Clarify `note` nullability**: Schema should be `note: { type: string, nullable: true }` or remove null possibility  
2. **Document `note` max length**: Add `maxLength: 500` to NewOrder schema's note property  
3. **Fix Error schema in 404**: Ensure `code` field is always populated  
4. **Add input validation**: API should validate request bodies and return 400 before database operations, preventing 500 errors
