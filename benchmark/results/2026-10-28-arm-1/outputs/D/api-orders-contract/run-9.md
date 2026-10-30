## Contract

**Source:** OpenAPI 3.0.3 document provided in-line  
**Version:** 2.1.0  
**Deployed version confirmed:** 2.1.0 (staging environment, tested 2026-10-15)  
**Base URL:** Assumed to be staging instance; exact endpoint base not provided  
**Authentication:** None documented; assume no auth required  

---

## Conformance

| # | Request | Schema location | Actual response | Classification | Owner |
|---|---------|-----------------|-----------------|-----------------|-------|
| 1 | GET /orders/1042 | Order.total: `{ type: number }` | `"total": "42.50"` (string type) | Software defect | API service team |
| 2 | GET /orders/999999 | Error: required [code, message] | Missing `code` field; only `message` present | Software defect | API service team |
| 3 | POST /orders {"items": ["sku-1"], "note": "5000-char string"} | Documented responses: 201, 400 only | HTTP 500 returned (undocumented) | Software defect | API service team |
| 3a | POST /orders error response | Error: required [code, message] schema | `{"error": "value too long for type character varying(500)"}` (wrong shape) | Software defect | API service team |

**Assumptions:**  
- Response 1: `null` for optional `note` field is valid per JSON Schema.  
- Response 3: The 500 status indicates a server error; a 400 with proper Error schema was expected for validation failure.  
- Response 3 body shape conflict: the documented Error schema requires `code` and `message`, but the actual response uses `error` as a single string field.

---

## Design

### GET /orders/{id}

**Partitions and boundaries:**
- **id parameter:**
  - Valid: integer ≥ 1 (schema minimum: 1)
  - Invalid: 0, negative integers (violate minimum)
  - Invalid: non-integer (wrong JSON type)
  - Invalid: string that looks like number ("123")
  - Boundary: id=1 (minimum), id=999999 (non-existent record tested)

**Resource state model:**
- Retrieve existing order → 200 + Order schema
- Retrieve deleted/non-existent order → 404 + Error schema
- Retrieve with invalid id format → likely 400, not tested

**Error contract:**
- 404: documented, Error schema required  
  - **Finding:** Error schema requires [code, message], but id=999999 returns only message field (defect)
- Undocumented statuses: 400 (bad id format), 500 (internal error)

**Idempotency:** Not applicable (read-only operation).

**Tags:** `@api` `@rest` `@priority:critical` `@smoke` | Suite: contract-conformance | Automation: immediate

---

### POST /orders

**Partitions and boundaries:**
- **items (required array):**
  - Valid: array with 1+ string elements ("items": ["sku-1"])
  - Invalid: empty array (violates minItems: 1)
  - Invalid: array with non-string elements (violates items schema)
  - Invalid: missing (required field)
  - Boundary: minItems=1 (test with 1 item, 0 items)

- **note (optional string):**
  - Valid: absent
  - Valid: empty string ""
  - Valid: short string < 500 chars
  - Invalid: string > 500 chars (discovered via response 3)
  - Boundary: 500 chars (max observed); 501 chars; 5000 chars (tested, returns 500 error)

**Resource state model:**
- Create order with valid items → 201 + Order schema (id assigned, status="placed")
- Create order with invalid items (empty array) → 400 + Error schema
- Create order with missing items field → 400 + Error schema
- Create order with note > 500 chars → **500 undocumented** (should be 400); Error schema mismatch

**Error contract:**
- 400: documented, Error schema required  
  - **Assumption:** 400 is for all validation failures (empty items, missing items, note too long)
  - **Finding:** note > 500 chars returns 500 instead of 400 (defect)
- 500: undocumented; actual response shape is `{"error": "..."}`, not Error schema
- Undocumented statuses: 422 (semantic validation), 413 (payload too large)

**Idempotency:** Not guaranteed; POST creates resource. If retried, will create duplicate (not idempotent per contract silence).

**Tags:** `@api` `@rest` `@priority:critical` `@smoke` | Suite: contract-conformance | Automation: immediate

---

## Contract Strategy

**Recommendation:** Schema conformance checks are sufficient as the primary contract verification strategy.

**Rationale:** The Orders API is a single provider with a stable OpenAPI 3.0.3 contract and no multiple independent consumers mentioned. Conformance checks (validating every endpoint response body against the declared schema, including error shapes) will catch the defects already observed (type mismatches, missing required fields, undocumented statuses, wrong error shapes). These checks run fast in CI/CD, require only the provider's schema and a staging instance, and scale to cover all endpoints and status codes without adding process overhead. Consumer-driven contracts are not justified without evidence of multiple released consumers depending on this API and unable to see or test updates before breaking changes reach them.

**Automatable conformance tests:** All three endpoints (GET /orders/{id} happy path + 404 path, POST /orders happy path + 400 path); validate response bodies against schema for each status; run with a schema validator (e.g., `jsonschema` library or Playwright's `expect(response).toMatchSchema()`).
