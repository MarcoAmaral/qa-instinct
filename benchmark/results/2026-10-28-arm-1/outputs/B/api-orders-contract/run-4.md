# QA Report: Orders API v2.1.0

## Contract Violations Found

### Violation 1: Invalid Data Type for `total` (Recording 1)
**Severity:** High | **Status:** Fail
- **Expected:** `total` field must be type `number`
- **Observed:** `"total": "42.50"` returned as string
- **Response:** 200 OK (correctly matched), but schema mismatch within response body
- **Impact:** API clients expecting numeric operations on `total` will fail or coerce incorrectly

### Violation 2: Missing Required Field in Error Response (Recording 2)
**Severity:** High | **Status:** Fail
- **Expected:** Error schema requires both `code` and `message` fields
- **Observed:** Response only contains `{"message": "Order not found"}`, missing `code` field
- **Response:** 404 OK (correctly matched status), but schema mismatch within response body
- **Impact:** API clients expecting `code` field for error classification will fail

### Violation 3: Undocumented 500 Response & Invalid Error Format (Recording 3)
**Severity:** Critical | **Status:** Fail
- **Expected:** POST /orders should return only 201 (success) or 400 (Invalid order)
- **Observed:** Returns 500 with error response body
- **Response Body Mismatch:** Returns `{"error": "..."}` instead of Error schema `{"code": "...", "message": "..."}`
- **Impact:** API contract does not account for server errors; clients cannot handle unexpected 500s

### Violation 4: Undocumented Constraint on `note` Field (Recording 3)
**Severity:** High | **Status:** Fail
- **Expected:** NewOrder.note is type string with no stated maximum length
- **Observed:** API rejects strings ≥ 5,000 characters with database error (VARCHAR(500) limit)
- **Assumed Constraint:** `note` field should have `maxLength: 500` in NewOrder schema
- **Impact:** API contract is incomplete; client cannot validate before submission

---

## Test Suite Design

### 1. Response Schema Compliance Tests

| Test Case | Method | Path | Input | Expected | Priority |
|-----------|--------|------|-------|----------|----------|
| Total field is numeric | GET | /orders/1042 | N/A | Response.total ∈ number, not string | Critical |
| Error includes code field | GET | /orders/999999 | N/A | Response includes `code` (string) | Critical |
| Error includes message field | GET | /orders/999999 | N/A | Response includes `message` (string) | Critical |
| Order id is integer | GET | /orders/1 | N/A | Response.id ∈ integer | High |
| Order status is enum | GET | /orders/1 | N/A | Response.status ∈ [placed, paid, shipped] | High |
| Create order returns integer id | POST | /orders | valid NewOrder | Response.id ∈ integer | High |
| Create order returns status enum | POST | /orders | valid NewOrder | Response.status ∈ [placed, paid, shipped] | High |

### 2. Request Validation Tests

| Test Case | Method | Path | Input | Expected Status | Priority |
|-----------|--------|------|-------|-----------------|----------|
| Missing items field | POST | /orders | {"note": "test"} | 400 | High |
| Empty items array | POST | /orders | {"items": []} | 400 | High |
| Note with 500 chars | POST | /orders | {"items": ["x"], "note": "500-char string"} | 201 | High |
| Note with 501 chars | POST | /orders | {"items": ["x"], "note": "501-char string"} | 400 | High |
| Single valid item | POST | /orders | {"items": ["sku-1"]} | 201 | High |
| Multiple valid items | POST | /orders | {"items": ["sku-1", "sku-2", "sku-3"]} | 201 | High |
| Note omitted entirely | POST | /orders | {"items": ["sku-1"]} | 201 | High |
| Note as null | POST | /orders | {"items": ["sku-1"], "note": null} | 201 (or 400) | Medium |
| Extra fields in body | POST | /orders | {"items": ["x"], "extra": "field"} | 201 (or 400) | Low |

### 3. Path Parameter Validation Tests

| Test Case | Method | Path | Expected Status | Priority |
|-----------|--------|------|-----------------|----------|
| Valid id = 1 | GET | /orders/1 | 200 or 404 | High |
| Valid id = 999999 | GET | /orders/999999 | 404 | High |
| Zero id | GET | /orders/0 | 400 (violates minimum: 1) | High |
| Negative id | GET | /orders/-1 | 400 | High |
| Non-integer id | GET | /orders/abc | 400 | High |
| Float id | GET | /orders/1.5 | 400 | High |
| Very large id | GET | /orders/9223372036854775807 | 200 or 404 | Medium |

### 4. HTTP-Level Contract Tests

| Test Case | Method | Path | Input | Expected | Priority |
|-----------|--------|------|-------|----------|----------|
| GET returns 200 for found resource | GET | /orders/1 | N/A | Status 200 | High |
| GET returns 404 for missing resource | GET | /orders/999999 | N/A | Status 404 | High |
| POST returns 201 on create | POST | /orders | valid | Status 201 | High |
| POST returns 400 on bad request | POST | /orders | invalid | Status 400 | High |
| Response Content-Type is application/json | GET/POST | /orders* | N/A | `Content-Type: application/json` | Medium |
| POST requires Content-Type application/json | POST | /orders | valid body, wrong CT | 400 or 415 | Medium |

### 5. Regression Tests (Fix Verification)

| Test Case | Current Behavior | Desired Behavior | Priority |
|-----------|------------------|------------------|----------|
| Verify total is always number in Order | "42.50" (string) | 42.50 (number) | Critical |
| Verify Error.code always present | Missing | Present and non-empty | Critical |
| Verify Error.message always present | Present but code absent | Present alongside code | Critical |
| Note field has maxLength: 500 in spec | No constraint documented | OpenAPI includes `maxLength: 500` | High |
| POST note > 500 chars returns 400 | Returns 500 with DB error | Returns 400 with proper Error schema | Critical |

---

## Assumptions

1. **Note field constraint:** `maxLength: 500` should be added to `NewOrder.note` and `Order.note` schemas based on database VARCHAR(500) limit.
2. **Null handling:** `note: null` is assumed to be valid since `note` is optional; if not intended, add `nullable: false`.
3. **404 behavior:** Assumed GET /orders/{id} with valid syntax but no matching record returns 404; not tested for id=1.
4. **Create behavior:** POST /orders is assumed to auto-generate id and set initial status; exact default status unknown.
5. **Extra fields:** POST with extra JSON fields assumed to be either accepted (stripped) or rejected; behavior unspecified.
6. **Error code values:** Error.code field values (e.g., "NOT_FOUND", "INVALID_REQUEST") are not defined in spec; test should validate against backend documentation.
