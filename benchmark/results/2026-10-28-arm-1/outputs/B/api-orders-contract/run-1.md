# API Response Compliance Report & Test Design

## Recorded Response Mismatches

### Mismatch 1: GET /orders/1042 Response Format
**Severity:** High

| Aspect | Spec | Actual | Issue |
|--------|------|--------|-------|
| `total` field type | `number` | `"42.50"` (string) | Type mismatch: response uses string instead of JSON number |

The `total` field is serialized as a string rather than a numeric type, breaking JSON schema validation.

---

### Mismatch 2: GET /orders/999999 Error Response Format
**Severity:** High

| Aspect | Spec | Actual | Issue |
|--------|------|--------|-------|
| Required fields | `code`, `message` | Only `message` | Missing required `code` field per Error schema |

The Error schema mandates both `code` and `message`. Response omits `code` entirely.

---

### Mismatch 3: POST /orders with Long Note Field
**Severity:** Critical

| Aspect | Spec | Actual | Issue |
|--------|------|--------|-------|
| HTTP Status | 201 or 400 | 500 | Unspecified status; indicates server error not validation error |
| Response schema | Error (`code`, `message`) | `{"error": "..."}` | Wrong schema: has `error` key instead of required `code`/`message` |
| Schema documentation | No `maxLength` on `note` | 500-char limit enforced | Constraint exists in implementation but absent in OpenAPI spec |

The API crashes on oversized input instead of validating at the boundary. Error response violates Error schema.

**Assumption:** The `note` field should document a `maxLength: 500` constraint in the OpenAPI schema.

---

## Test Design for Full API Coverage

### Group 1: GET /orders/{id} - Happy Path
- ✓ Retrieve valid order with all fields present (`id`, `status`, `total`, `note`)
- ✓ Verify `total` is returned as JSON number, not string
- ✓ Verify `status` matches one of enum values
- ✓ Verify `note` can be null or a string

### Group 2: GET /orders/{id} - Error Cases
- ✓ Retrieve non-existent order (404) with valid Error schema (`code` + `message`)
- ✓ Invalid path parameter: negative integer (e.g., /orders/-1) → verify 4xx rejection
- ✓ Invalid path parameter: zero (violates `minimum: 1`) → verify 4xx rejection
- ✓ Invalid path parameter: non-integer (e.g., /orders/abc) → verify 4xx rejection
- ✓ Invalid path parameter: float (e.g., /orders/1.5) → verify 4xx rejection
- ✓ Verify 404 responses always include `code` field

### Group 3: POST /orders - Happy Path
- ✓ Create order with required `items` array (single item)
- ✓ Create order with required `items` array (multiple items)
- ✓ Create order with `items` + optional `note` (short string)
- ✓ Verify 201 response contains valid Order schema with all required fields
- ✓ Verify `id` is integer, `status` is enum value, `total` is number
- ✓ Verify response `note` matches input `note`

### Group 4: POST /orders - Validation Errors (400)
- ✓ Missing required `items` field → 400 with Error schema
- ✓ Empty `items` array (violates `minItems: 1`) → 400 with Error schema
- ✓ `items` not an array → 400 with Error schema
- ✓ `items` contains non-string values → 400 with Error schema
- ✓ `note` field at max boundary (500 chars) → 201 success
- ✓ `note` field exceeds max (501+ chars) → 400 with Error schema (not 500)
- ✓ Extra unknown fields in request body → verify spec behavior (allow/reject)
- ✓ Invalid Content-Type header → verify rejection
- ✓ Malformed JSON body → 400 with Error schema

### Group 5: Response Format Compliance
- ✓ All error responses conform to Error schema (`code` always present)
- ✓ All Order responses have `total` as JSON number, never string
- ✓ All responses use `application/json` Content-Type
- ✓ No unexpected HTTP status codes (only 200, 201, 400, 404 per spec)

### Group 6: Edge Cases & Data Integrity
- ✓ Create order, immediately retrieve by id, verify data integrity
- ✓ Order `status` transitions (verify immutability per spec if applicable)
- ✓ Very long valid `note` (just under 500 char limit)
- ✓ Unicode/special characters in `note` field
- ✓ Large order `total` values (e.g., 999999.99)
- ✓ Order `total` precision (e.g., 42.50 vs 42.5 representation)

### Group 7: Integration & State
- ✓ Newly created order has `status: "placed"` (verify initial state)
- ✓ Multiple orders can be created independently
- ✓ Order IDs are unique and sequential/consistent

---

## Recommended Fixes

1. **Serialize `total` as JSON number:** Ensure `total` field is output as numeric type, not string.
2. **Add `code` to all Error responses:** Implement `code` field in error handling (e.g., `"code": "ORDER_NOT_FOUND"`).
3. **Validate `note` length at API boundary:** Return 400 with Error schema for `note` > 500 chars, not 500.
4. **Update OpenAPI spec:** Add `maxLength: 500` to `NewOrder.properties.note` schema.
5. **Standardize error response:** Never use `{"error": "..."}` format; always use `{"code": "...", "message": "..."}`.
