# API Compliance Report & Test Design

## Recorded Response Mismatches

### Mismatch 1: Response 1 — Incorrect `total` type
**Location:** GET /orders/1042 → 200  
**Issue:** `total` returned as string `"42.50"` but schema requires type `number`  
**Contract violation:** Type mismatch on required field  
**Severity:** High — Clients expecting JSON number will break on string

### Mismatch 2: Response 2 — Missing required `code` field
**Location:** GET /orders/999999 → 404  
**Issue:** Error schema requires fields `[code, message]` (both required); response only includes `message`  
**Contract violation:** Missing required field in Error schema  
**Severity:** High — Clients expecting `code` will fail to parse

### Mismatch 3: Response 1 — Undeclared null in `note`
**Location:** GET /orders/1042 → 200  
**Issue:** `note` field is `null`, but schema defines it as `type: string` without nullable indicator  
**Contract violation:** Type mismatch (null ≠ string) or schema omission (should declare optional/nullable)  
**Severity:** Medium — Depends on schema interpretation; typically optional fields should be omitted or schema should allow null  
**Assumption:** `note` is optional but when present should be a string; null violates this

### Mismatch 4: Response 3 — Undocumented HTTP status
**Location:** POST /orders → 500  
**Issue:** Contract specifies only 201 (success) and 400 (invalid order); no 500 documented  
**Contract violation:** Response not in OpenAPI spec  
**Severity:** Critical — Unhandled error case

### Mismatch 5: Response 3 — Invalid Error schema format
**Location:** POST /orders → 500  
**Issue:** Error response `{"error": "value too long..."}` doesn't match Error schema `{code, message}`  
**Contract violation:** Response body doesn't conform to documented Error schema  
**Severity:** High — Response structure incorrect even if status were expected

### Mismatch 6: Response 3 — Missing validation constraint
**Location:** POST /orders with 5,000-character `note`  
**Issue:** `note` field has no specified length limit in NewOrder schema, but database rejects strings >500 chars with 500 error  
**Contract violation:** Undocumented constraint; should either be in schema or return 400  
**Severity:** High — Clients cannot predict rejection; schema doesn't document the constraint

---

## Recommended Test Suite

### 1. Type Compliance Tests
- [ ] GET /orders/{id} returns `total` as JSON number (not string)
- [ ] GET /orders/{id} returns `id` as integer
- [ ] POST /orders returns Order with all numeric and enum fields correctly typed
- [ ] Error responses contain only documented string fields

### 2. Required Field Tests
- [ ] GET /orders/{id} → 404 includes both `code` and `message` in Error response
- [ ] GET /orders/{id} → 200 includes all required Order fields: `id`, `status`, `total`
- [ ] POST /orders → 400 includes both `code` and `message` in Error response
- [ ] POST /orders → 201 includes all required Order fields

### 3. Enum Validation Tests
- [ ] GET /orders/{id} → 200 status is one of: placed, paid, shipped (no other values)

### 4. Request Validation Tests
- [ ] POST /orders with empty items array → 400 with Error schema
- [ ] POST /orders with missing items → 400 with Error schema
- [ ] POST /orders with items=null → 400 with Error schema
- [ ] POST /orders with items not array → 400 with Error schema

### 5. Note Field Tests
- [ ] POST /orders with note omitted → 201 (note should be omitted or null, document behavior)
- [ ] POST /orders with note as valid string → 201
- [ ] POST /orders with note exceeding max length (>500 chars) → 400 (not 500) with proper Error schema
- [ ] POST /orders with note=null → clarify if allowed

### 6. Path Parameter Tests
- [ ] GET /orders/0 → 400 (minimum: 1 constraint)
- [ ] GET /orders/-1 → 400 (minimum: 1 constraint)
- [ ] GET /orders/abc → 400 (not integer)
- [ ] GET /orders/1.5 → 400 (not integer)

### 7. HTTP Status Code Tests
- [ ] GET /orders/valid-id → 200 (not 201)
- [ ] POST /orders with valid body → 201 (not 200)
- [ ] POST /orders with invalid body → 400 (not 500)
- [ ] No unspecified 5xx errors in normal operation

### 8. Error Response Format Tests
- [ ] All 4xx/5xx responses match Error schema: `{code: string, message: string}`
- [ ] All error codes are machine-parseable identifiers (e.g., "NOT_FOUND", "INVALID_ORDER")
- [ ] Error messages are user-friendly descriptions

### 9. Content-Type Tests
- [ ] All responses include `Content-Type: application/json` header
- [ ] Responses are valid JSON

### 10. Nullable/Optional Field Tests
- [ ] Document which Order fields are optional (note appears optional in schema but null in response is ambiguous)
- [ ] Document whether note can be null or must be omitted

---

## Assumptions Made

- **`note` field semantics**: Treated as optional (not in `required` array) but when returned, should be a string or omitted; null is a schema violation.
- **Error constraint documentation**: The 500 error reveals an undocumented `note` max length (500 chars); this should be in the schema.
- **Error codes**: Assumed error `code` field should contain machine-readable identifiers (e.g., "NOT_FOUND", "INVALID_ORDER") rather than descriptive messages.
