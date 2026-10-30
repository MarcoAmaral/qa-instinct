# API Specification Compliance Report and Test Strategy

## Recorded Responses vs. Specification

### Mismatch 1: Response 1 — GET /orders/1042 (Type Violation)

**Issue:** The `total` field is serialized as a string instead of a number.

| Field | Spec | Recorded | Status |
| --- | --- | --- | --- |
| `total` | `number` | `"42.50"` (string) | ❌ Type mismatch |

**Impact:** Clients expecting a number will fail deserialization or require type coercion.

---

### Mismatch 2: Response 2 — GET /orders/999999 (Incomplete Error Schema)

**Issue:** The Error schema requires two fields; the response omits one.

| Field | Spec | Recorded | Status |
| --- | --- | --- | --- |
| `code` | required string | (missing) | ❌ Missing required field |
| `message` | required string | `"Order not found"` | ✓ Present |

**Impact:** Clients that parse the `code` field will fail; no structured error classification available.

---

### Mismatch 3: Response 3 — POST /orders (Invalid Status Code & Schema)

**Issue:** Two violations in one response.

| Aspect | Spec | Recorded | Status |
| --- | --- | --- | --- |
| HTTP Status | 201 or 400 | 500 | ❌ Undefined status code |
| Response Schema | Error (code + message) | `{"error": "..."}` | ❌ Wrong schema and field name |

**Impact:** A 500 error suggests an internal server failure, not a validation error. The client cannot tell if the request was malformed or if the server crashed. The response structure does not match the documented Error schema.

**Hidden constraint:** The API enforces a 500-character limit on the `note` field, but the OpenAPI spec does not document a `maxLength` constraint on `NewOrder.note`. This limit should be added to the schema.

---

## Recommended Test Suite

### 1. Happy Path Tests

- ✓ **GET /orders/{id} with valid id** → 200 with complete Order (all required + optional fields, `total` as number)
- ✓ **POST /orders with valid NewOrder** → 201 with Order (verify `id` is assigned, `status` defaults to a valid enum value, `total` is a number)

### 2. Type Validation Tests

- ✓ **GET /orders/1042** → verify `total` is `number` type, not string (deserialize and check type)
- ✓ **POST /orders → 201** → verify `total` in response is a number

### 3. Error Response Compliance Tests

- ✓ **GET /orders/999999** → 404 with Error schema: must have both `code` and `message` fields (both strings, non-empty)
- ✓ **POST /orders with invalid body** → 400 with Error schema: must have both `code` and `message` fields

### 4. Input Validation Tests

- ✓ **POST /orders with empty items array** → 400 (violates `minItems: 1`)
- ✓ **POST /orders without items field** → 400 (violates required)
- ✓ **POST /orders with note > 500 characters** → 400 (not 500; document maxLength constraint in spec)
- ✓ **POST /orders with non-string item in items** → 400 (type validation)

### 5. Boundary & Edge Case Tests

- ✓ **GET /orders/0** → 400 (violates `minimum: 1`)
- ✓ **GET /orders/-1** → 400 (violates `minimum: 1`)
- ✓ **GET /orders/1** (minimum valid) → 200 or 404 (valid id range)
- ✓ **POST /orders with note: null** → 201 (optional field, null allowed)
- ✓ **POST /orders with note: "" (empty string)** → 201 (valid, optional)
- ✓ **POST /orders with items containing exactly 1 item** → 201 (boundary: minItems: 1)

### 6. Schema Constraint Tests

- ✓ **GET /orders/{id}** → verify status is one of [placed, paid, shipped] only
- ✓ **POST /orders** → verify created Order has status in [placed, paid, shipped]

---

## Assumptions

- The API's 500-character limit on `note` is a real constraint and should be added to the spec as `NewOrder.note.maxLength: 500`.
- A 400 status code (Invalid order) is the correct response for validation failures, and the 500 is a bug in the current implementation.
- The Error schema `code` field should be present in all error responses. Suggested `code` values might be: `"not_found"`, `"validation_error"`, `"internal_error"`.
- For POST /orders, the `status` field should default to `"placed"` (common pattern), though the spec does not define this.
