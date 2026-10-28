# API Contract Compliance Report & Test Design

## Mismatches Found

### 1. Response 1: GET /orders/1042 → 200
**Type mismatch in `total` field:**
- Schema declares `total: number`
- Recorded value: `"42.50"` (string)
- **Impact:** Consumer code expecting numeric operations (comparison, arithmetic) will fail

**Invalid null value for `note` field:**
- Schema declares `note: string` (required array does not include it, so it's optional, but when present must be a string)
- Recorded value: `null`
- **Impact:** null violates the string type constraint; if optional, should be omitted entirely

---

### 2. Response 2: GET /orders/999999 → 404
**Missing required `code` field:**
- Schema requires Error object with fields: `[code, message]`
- Recorded response: only has `message`
- **Impact:** Clients expecting to parse error codes cannot function

---

### 3. Response 3: POST /orders → 500
**Status code not in contract:**
- Schema defines only 201 (success) and 400 (validation error)
- Recorded: 500 Internal Server Error
- **Impact:** API is failing to validate request constraints before processing

**Error response structure mismatch:**
- Schema requires Error object: `{code: string, message: string}`
- Recorded: `{error: "..."}` (different key name, single field)
- **Impact:** Clients cannot parse error response

**Implementation detail leaked in error message:**
- Message exposes postgres type name `character varying(500)` instead of user-facing validation error
- **Impact:** Reveals backend schema; the `note` field lacks validation at request boundary

---

## Test Design Recommendations

### Happy Path Tests
1. **GET /orders/{id} success (200)**
   - Assert `total` is numeric type, not string
   - Assert `note` is omitted OR is a string (not null)
   - Assert all required Order fields (`id`, `status`, `total`) are present
   - Assert `status` enum value is one of: `[placed, paid, shipped]`

2. **POST /orders success (201)**
   - Send valid NewOrder with `items` array and optional `note`
   - Assert response is Order schema with all required fields
   - Assert `id` is a positive integer
   - Assert `status` is one of enum values

### Error Handling Tests
3. **GET /orders/{id} not found (404)**
   - Assert response matches Error schema
   - Assert both `code` and `message` fields are present and strings
   - Assert `message` is descriptive (e.g., "Order not found")

4. **POST /orders validation failures (400, not 500)**
   - **Empty items array:** `{items: []}` → 400 with Error schema (violates minItems: 1)
   - **Missing items field:** `{note: "..."}` → 400 with Error schema (items required)
   - **Note field length:** `{items: [...], note: "<5000 chars>"}` → 400 with Error schema (not 500)
   - Assert error response structure matches Error schema in all cases

5. **GET /orders/{id} input validation (4xx)**
   - Invalid id (non-integer): `/orders/abc` → 4xx
   - Out-of-range id (< 1): `/orders/0` or `/orders/-1` → 4xx
   - Assert proper error response per schema

### Contract Compliance Tests
6. **Response structure validation**
   - Verify all responses use correct schema references (no extra fields that violate type constraints)
   - Verify null is never used for non-nullable string fields
   - Verify numeric fields are actually numbers, not string-encoded numbers

7. **Content-type validation**
   - All responses declare `application/json` and deliver it
   - All error responses use Error schema, never generic error objects

---

## Assumptions Made
- The `note` field should either be omitted when null, or present as a string; null values indicate a schema violation, not intended optionality.
- The 500 error in response 3 represents a data validation bug in the API (missing constraint check on note field length) rather than a legitimate API behavior to test.
- The `minimum: 1` constraint on `id` parameter should be enforced by the server (e.g., reject /orders/0).
