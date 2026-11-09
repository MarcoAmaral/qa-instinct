# API Compliance Report & Test Design

## Recorded Response Analysis

### Response 1: GET /orders/1042 → 200
**MISMATCH FOUND**
- `total` field: Returned as string `"42.50"` but schema requires `type: number` ❌
- `note` field: Returned as `null` but schema defines `type: string` — null is not a valid string value ❌

### Response 2: GET /orders/999999 → 404
**MISMATCH FOUND**
- Error response missing required `code` field (schema requires `[code, message]`) ❌
- Response body `{"message": "Order not found"}` is incomplete per the Error schema

### Response 3: POST /orders → 500
**CRITICAL MISMATCHES FOUND**
- HTTP 500 status is not documented in the OpenAPI contract (only 201 and 400 defined) ❌
- Error response format `{"error": "..."}` does not conform to the Error schema ❌
- Missing required `code` field ❌
- Undocumented constraint: `note` field has a 500-character database limit not specified in the schema ❌
- Request is valid per schema but server rejects it — indicates server-side validation mismatch

**Assumption:** The actual request body exceeded the undocumented character limit, causing database constraint violation to bubble up as 500.

---

## Recommended Test Suite

### GET /orders/{id} Tests

| Test | Input | Expected | Check |
|------|-------|----------|-------|
| Valid order retrieval | id=1042 | 200, Order schema | id (integer), status (enum), total (number—not string), note (string or absent) |
| Non-existent order | id=999999 | 404, Error schema | Both `code` and `message` required; validate field types |
| Invalid id: zero | id=0 | 400 or 422 | Reject id < 1 per schema minimum |
| Invalid id: negative | id=-1 | 400 or 422 | Reject per schema minimum |
| Invalid id: string | id=abc | 400 or 422 | Reject non-integer |
| Invalid id: float | id=1.5 | 400 or 422 | Reject decimal |
| Response Content-Type | Any valid GET | application/json | Verify header |
| Status enum values | Valid order | status ∈ {placed, paid, shipped} | Test all three values if possible |

### POST /orders Tests

| Test | Payload | Expected | Check |
|-------|---------|----------|-------|
| Valid: required fields only | `{"items": ["sku-1"]}` | 201, Order schema | All required Order fields present with correct types |
| Valid: with optional note | `{"items": ["sku-1"], "note": "text"}` | 201, Order schema | note field preserved as string |
| Missing items array | `{"note": "text"}` | 400, Error schema | Reject; both `code` and `message` fields present |
| Empty items array | `{"items": []}` | 400, Error schema | Reject minItems: 1 constraint |
| Non-string item | `{"items": [123]}` | 400, Error schema | Reject type violation |
| Multiple items | `{"items": ["sku-1", "sku-2", "sku-3"]}` | 201, Order schema | Accept valid array |
| Note at boundary | `{"items": ["sku-1"], "note": "<500 chars>"}` | 201, Order schema | Accept at limit |
| Note exceeding limit | `{"items": ["sku-1"], "note": "<501 chars>"}` | 400, Error schema | Reject with proper Error structure (not 500), or document 500-char max in schema |
| Null note field | `{"items": ["sku-1"], "note": null}` | 400 or auto-exclude? | Clarify null handling; schema says `type: string`, not nullable |
| Response Content-Type | Valid request | application/json | Verify header |
| Response id field | Valid request | id is integer ≥ 1 | Type and value validation |
| Response status field | Valid request | status ∈ {placed, paid, shipped} | Enum validation |
| Response total field | Valid request | total is number (not string) | Enforce correct type |
| Extra fields in request | `{"items": [...], "unknown": "x"}` | 201 or 400? | Clarify strict vs. lenient validation |

### Cross-Cutting Tests

| Test | Purpose |
|------|---------|
| Malformed JSON | Both endpoints | Expect 400 |
| Missing Content-Type | POST | Expect 400 or infer application/json |
| Charset in Content-Type | POST | Verify e.g. `application/json; charset=utf-8` accepted |
| Unicode in note | POST | Test emoji, multi-byte chars |
| SQL injection in note | POST | Verify parameterized queries; should reject or escape safely |
| Very large item count | POST | Test practical upper bound on array size |

---

## Summary of Contract Violations

1. **Type coercion bug:** `total` serialized as string instead of number
2. **Null handling bug:** `note` field allows null in response but schema forbids it  
3. **Incomplete error responses:** Missing `code` field in 404 responses
4. **Unhandled constraint:** 500-character limit on `note` causes 500 error instead of documented 400 with Error schema
5. **Undocumented status codes:** Server returns 500; contract doesn't account for it

**Recommendation:** Update API responses to match schema contracts, document the 500-character `note` limit in OpenAPI, and always return proper Error schema for client errors (400) rather than generic server errors (500).
