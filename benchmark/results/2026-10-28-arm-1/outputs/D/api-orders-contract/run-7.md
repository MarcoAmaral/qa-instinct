# api-tests/contract.md

**Contract location:** Provided inline in command  
**Format:** OpenAPI 3.0.3  
**Version:** 2.1.0  
**Deployed version under test:** 2.1.0 (staging, recorded 2026-10-15)  
**Authentication:** None (assumption: unauthenticated access)  
**Base URL:** Not specified (assumption: requests use platform default)  
**Environment:** Staging

**Endpoints:**
- `GET /orders/{id}` — Retrieve an order by ID
- `POST /orders` — Create a new order

**Schemas:**
- `Order`: required [id, status, total]; properties: id (integer), status (enum: placed|paid|shipped), total (number), note (string, optional)
- `NewOrder`: required [items]; properties: items (array of strings, minItems: 1), note (string, optional)
- `Error`: required [code, message]; properties: code (string), message (string)

---

# api-tests/conformance.md

| # | Request | Endpoint | Status | Declared Schema | Actual Response | Mismatch | Classification | Owner |
|---|---------|----------|--------|-----------------|-----------------|----------|-----------------|-------|
| 1 | GET /orders/1042 | GET /orders/{id} → 200 | 200 | Order: {id, status, total} required | `{"id": 1042, "status": "paid", "total": "42.50", "note": null}` | `total` is string `"42.50"`, schema declares `type: number` | Software defect | API team |
| 2 | GET /orders/999999 | GET /orders/{id} → 404 | 404 | Error: {code, message} required | `{"message": "Order not found"}` | Missing required field `code`; only `message` present | Software defect | API team |
| 3 | POST /orders with `{"items": ["sku-1"], "note": "<5000 chars>"}` | POST /orders → 201/400 | 500 | Status 500 not documented; Error schema requires {code, message} | `{"error": "value too long for type character varying(500)"}` | (1) Undocumented status 500; (2) Error body has `error` field, not `code` and `message`; (3) Database constraint on `note` length not expressed in schema | Software defect | API team |

**Summary of findings:**

- **Type mismatch:** Response 1 violates schema type (string vs. number for `total`).
- **Missing required field:** Response 2 lacks `code` field mandated by Error schema.
- **Undocumented error and wrong body shape:** Response 3 returns HTTP 500 (not in schema) with non-conformant error body; reveals undocumented constraint: `note` has a max length of ~500 characters not declared in `NewOrder.note`.

---

# api-tests/design.md

## GET /orders/{id}

**Tags:** @api, suite:orders, priority:critical, automation:required

**Partitions and boundaries:**
- **id parameter:**
  - Valid: integer ≥ 1 (minimum per schema)
  - Invalid: integer < 1 (boundary violation), string, null, missing, float, negative

**Cases:**

| Case | Input | Expected Status | Expected Body | Acceptance Criterion |
|------|-------|-----------------|----------------|---------------------|
| P1: Existing order | id=1042 | 200 | Order {id, status ∈ [placed, paid, shipped], total ∈ ℝ, note optional} | Retrieve order within constraints |
| P2: Non-existent order | id=999999 | 404 | Error {code, message} ✓ *conformance defect: code missing* | 404 must have required fields |
| N1: Boundary—id = 0 | id=0 | 400 or 404 | Error {code, message} | Minimum constraint enforced |
| N2: Boundary—id = 1 | id=1 | 200 or 404 | Order or Error | Minimum boundary valid |
| N3: Type—string id | id="abc" | 400 | Error {code, message} | Parameter type validation |
| N4: Type—null id | id=null | 400 | Error {code, message} | Null rejected |

**Resource state:** Read-only; no state transitions tested.

**Error contract:** Schema documents 404 (Error shape). Defect: actual 404 response omits required `code` field.

---

## POST /orders

**Tags:** @api, suite:orders, priority:critical, automation:required

**Partitions and boundaries:**
- **items (array of strings):**
  - Valid: [1..n] strings (minItems: 1 satisfied)
  - Invalid: empty array, null, non-array, contains non-string, missing
- **note (optional string):**
  - Valid: omitted, empty string, short strings
  - Invalid: over 500 characters (observed constraint via 500 error), non-string type

**Cases:**

| Case | Input | Expected Status | Expected Body | Acceptance Criterion |
|------|-------|-----------------|----------------|---------------------|
| P1: Create order, no note | `{"items": ["sku-1"]}` | 201 | Order {id ∈ ℤ⁺, status="placed", total ∈ ℝ, note absent or null} | Order created in initial state |
| P2: Create order, with note | `{"items": ["sku-1"], "note": "rush"}` | 201 | Order {id ∈ ℤ⁺, status="placed", total ∈ ℝ, note="rush"} | Optional note included |
| P3: Multiple items | `{"items": ["sku-1", "sku-2", "sku-3"]}` | 201 | Order with all SKUs processed | Array cardinality ≥ 1 accepted |
| N1: Missing items | `{"note": "rush"}` | 400 | Error {code, message} | Required field enforced |
| N2: Empty items | `{"items": []}` | 400 | Error {code, message} | minItems: 1 enforced |
| N3: Non-string in items | `{"items": [1, "sku"]}` | 400 | Error {code, message} | Item type validation |
| N4: Note exceeds 500 chars | `{"items": ["sku-1"], "note": "<5001 chars>"}` | 400 | Error {code, message} ✓ *actual: 500 with wrong body shape* | Validation boundary enforced; currently unhandled (500) |
| N5: items not array | `{"items": "sku-1"}` | 400 | Error {code, message} | Type validation |

**Resource state:** Create transition. New order enters "placed" status (assumption from schema enum and typical flow).

**Error contract:** Schema documents 400 (validation failure). Defect: constraint on `note` length (≤500 chars) not declared in schema, and violation returns 500 with `{"error": "…"}` (wrong shape; should be Error {code, message}).

**Undocumented behavior:** Database column constraint (varchar(500) on note) not expressed in OpenAPI schema.

---

## Contract testing strategy

**Recommendation: Schema conformance checks are sufficient; consumer-driven contracts are not justified.**

**Rationale:**
- No indication of multiple independently released consumers.
- Schema conformance (step 3) is the cost-effective first activity: it requires only the OpenAPI document and request capability.
- Three conformance defects (type mismatch on `total`, missing `code` in 404, undocumented 500 error) must be fixed before automation proceeds; conformance checks will verify the fix.
- Consumer-driven contracts add process overhead (contract broker, provider verification step, dual-team coordination) only when providers cannot see their consumers; here, this is a single team's API and test suite.

**Next step:** Fix the three defects, re-run conformance checks, then automate per the design cases above.
