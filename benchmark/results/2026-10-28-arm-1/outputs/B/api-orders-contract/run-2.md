# QA Report: Orders API v2.1.0 Contract Compliance

## Recorded Response Mismatches

### Response 1: GET /orders/1042
**Status:** ❌ **CONTRACT VIOLATION**
- **Issue:** `total` field is string `"42.50"` but contract specifies `type: number`
- **Severity:** High — serialization defect causing type mismatch
- **Impact:** API clients expecting numeric type may parse incorrectly

**Secondary issue:** `note: null` — field is present with null value, but schema specifies `type: string`. Should either omit the field or provide a string value.
- **Severity:** Medium — inconsistent nullability handling

---

### Response 2: GET /orders/999999
**Status:** ❌ **CONTRACT VIOLATION**
- **Issue:** `code` field is missing but marked required in Error schema
- **Severity:** High — response fails schema validation
- **Missing field:** `code` (required, type string)
- **Impact:** Clients relying on error codes for programmatic error handling will fail

---

### Response 3: POST /orders (5000-char note)
**Status:** ❌ **MULTIPLE CONTRACT VIOLATIONS**

1. **HTTP Status 500** — Not in contract (expected: 201 or 400)
   - Severity: Critical — unhandled exception should not surface to client

2. **Response body format** — `{"error": "..."}` does not match Error schema
   - Expected: `{"code": string, "message": string}`
   - Severity: High — schema mismatch

3. **Validation layer failure** — 5000-char note accepted by OpenAPI schema (no maxLength) but rejected at DB layer
   - Expected: 400 + Error response with validation detail
   - Assumption: `note` field has undocumented max length of ~500 chars (inferred from error message)
   - Severity: High — schema incompleteness

---

## Test Suite Design

### 1. **Response Schema Validation Tests**

```
✓ GET /orders/{id} 200: Verify Order response includes all required fields
  - id: integer
  - status: one of [placed, paid, shipped]
  - total: number (NOT string)
  - note: string or omitted (NOT null)

✓ GET /orders/{id} 404: Verify Error response includes both required fields
  - code: string, non-empty
  - message: string, non-empty

✓ POST /orders 201: Verify Order response matches schema
  (as above, plus verify assigned id and initial status value)

✓ POST /orders 400: Verify Error response matches schema
```

### 2. **Path Parameter Validation Tests**

```
✓ GET /orders/1: Minimum valid id (spec: minimum 1)
✓ GET /orders/2147483647: Maximum 32-bit int
✓ GET /orders/0: Reject (violates minimum: 1)
✓ GET /orders/-1: Reject (violates minimum: 1)
✓ GET /orders/abc: Reject non-integer
✓ GET /orders/1.5: Reject non-integer
```

### 3. **Request Body Validation Tests**

```
✓ POST /orders with valid {"items": ["sku-1"]}: Return 201
✓ POST /orders with {"items": ["sku-1", "sku-2"]}: Return 201
✓ POST /orders with {"items": ["sku-1"], "note": "valid string"}: Return 201

✗ POST /orders with {}: Missing required items → 400
✗ POST /orders with {"items": []}: Empty array violates minItems: 1 → 400
✗ POST /orders with {"items": ["sku-1"], "note": null}: note must be string or omitted → 400
✗ POST /orders with {"items": [123, "sku-1"]}: item must be string → 400
✗ POST /orders with {"items": ["sku-1"], "note": "<5000 char string>"}: Exceeds undocumented maxLength → 400 (currently returns 500)
```

### 4. **Note Field Boundary Tests**

```
✓ note with 1 character
✓ note with 500 characters (documented limit inferred from error)
✗ note with 501 characters → 400 Error response (not 500)
✓ note with special characters: emoji, unicode, quotes, newlines
✓ note omitted entirely
✗ note: null → Should either fail 400 or omit from response
```

### 5. **Enum Validation Tests**

```
✓ Verify status values only returned as: "placed", "paid", "shipped"
✗ Any status outside enum → Should never be returned or input
```

### 6. **Error Response Consistency**

```
✓ All 400 responses use Error schema (code + message)
✓ All 404 responses use Error schema (code + message)
✓ error.code should categorize failure (e.g., "VALIDATION_ERROR", "NOT_FOUND")
✓ error.message should be human-readable
✗ 500 errors should never occur; all client errors → 4xx
```

### 7. **Numeric Type Precision Tests**

```
✓ GET /orders/{id} total returns as number, not string
✓ totals with cents (e.g., 42.50) render as numbers: 42.5
✓ totals with no cents (e.g., 50) render as numbers: 50
✓ Negative or zero totals handled correctly
```

---

## Root Causes & Recommendations

| Issue | Root Cause | Fix |
|-------|-----------|-----|
| `total` as string | JSON serialization layer not using number type | Add numeric field serializer |
| Missing `code` in 404 | Error response builder incomplete | Update all error responses to include code field |
| 500 on long note | Validation not pre-flight checked before DB insert | Add JSON schema validator; reject 400 at handler layer with max length constraint |
| `note: null` | Optional field serializer includes null explicitly | Omit null fields or document nullability |

**Critical: Update OpenAPI spec** to document the actual `note` field constraints (inferred `maxLength: 500`).
