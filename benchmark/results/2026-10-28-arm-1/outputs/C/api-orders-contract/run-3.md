# API Contract Validation Report

## Mismatches Found

### 1. Response 1: GET /orders/1042 → 200
**Field `total` type mismatch**
- Spec defines: `total` as type `number`
- Actual response: `"total": "42.50"` (string)
- Impact: Numeric calculations require parsing; violates JSON Schema contract

### 2. Response 2: GET /orders/999999 → 404
**Error schema incomplete**
- Spec requires: both `code` and `message` fields in Error object
- Actual response: `{"message": "Order not found"}` (missing `code`)
- Impact: Clients cannot programmatically distinguish error types; violates required fields

### 3. Response 3: POST /orders (with 5,000-char note) → 500
**Multiple violations:**
- Status code not documented: spec defines only 201 and 400, not 500
- Response schema mismatch: `{"error": "..."}` does not match Error schema (`code` + `message`)
- Constraint not declared: `note` field accepted in spec but database enforces 500-char limit (not documented)
- Assumption: The `note` field should declare `maxLength: 500` in NewOrder schema

---

## Test Suite Design

### Contract Compliance Tests

| Test | Purpose | Request | Expected Result |
|------|---------|---------|-----------------|
| **GET /orders/{id}** – Happy path | Verify 200 response structure | `GET /orders/1` | Status 200; Order with `total` as number (not string); all required fields present |
| **GET /orders/{id}** – 404 structure | Verify error format | `GET /orders/999999` | Status 404; Error object with both `code` and `message` (not empty/null) |
| **GET /orders/{id}** – Invalid ID | Reject id below minimum | `GET /orders/0` or `GET /orders/-1` | Status 400 or similar; Error response |
| **GET /orders/{id}** – Non-integer ID | Reject non-numeric path param | `GET /orders/abc` | Status 400 (or 404 per routing); Error response |
| **POST /orders** – Valid creation | Create with required field only | Body: `{"items": ["sku-1"]}` | Status 201; Order with required fields; `id` is integer; `status` in enum; `total` is number |
| **POST /orders** – With optional note | Create with max-length note | Body: `{"items": ["sku-1"], "note": "<500 chars>"}` | Status 201; Order created; note preserved |
| **POST /orders** – Note exceeds limit | Reject oversized note | Body: `{"items": ["sku-1"], "note": "<5,001 chars>"}` | Status 400 (not 500); Error with `code` and `message`; message describes constraint |
| **POST /orders** – Missing items | Reject request without items | Body: `{"note": "..."}` | Status 400; Error response |
| **POST /orders** – Empty items array | Reject array below minItems | Body: `{"items": []}` | Status 400; Error response |
| **POST /orders** – Status values | Verify status field only contains valid enum | Any 201 response | `status` is one of: "placed", "paid", "shipped" |
| **Error response schema** – All errors | Verify consistent error format across all error codes | Any 400/404/500 | All error responses include `code` and `message`; no `error` field |

### Data Validation Tests

- **Total field numeric**: Multiply returned `total` × 2 without string parsing; confirm result is valid number
- **Note length boundary**: POST with exactly 500 chars → expect 201; POST with 501 chars → expect 400
- **Items array validation**: POST with non-string items (numbers, objects) → expect 400

---

## Recommendations

1. **Immediate**: Fix Response 1 (cast `total` to number in JSON), Response 2 (add `code` field to 404), and Response 3 (add `maxLength: 500` to NewOrder.note schema and return 400 instead of 500)
2. **Documentation**: Add 400 response to POST /orders for validation errors (note length, etc.) and document the `maxLength` constraint
3. **Error handling**: Standardize all error responses to Error schema; add `code` field mapping (e.g., "NOT_FOUND", "INVALID_REQUEST")
