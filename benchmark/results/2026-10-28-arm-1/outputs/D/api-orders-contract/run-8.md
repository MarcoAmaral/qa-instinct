# Contract Analysis and Test Design Report

## Contract Document

**Contract Source:** OpenAPI 3.0.3  
**Version:** 2.1.0  
**Recorded:** 2026-10-15 (staging environment)  
**Deployed Version Confirmed:** 2.1.0  
**Auth Model:** None  
**Base URL:** Staging (assumed; not provided)  

### Endpoints
- `GET /orders/{id}` – retrieve order by integer ID ≥ 1
- `POST /orders` – create new order from NewOrder payload

### Schemas
- **Order** (required fields: id, status, total): id: integer | status: enum [placed, paid, shipped] | total: number | note: optional string
- **NewOrder** (required field: items): items: array of strings, minItems=1 | note: optional string  
- **Error** (required fields: code, message): code: string | message: string

---

## Conformance Report

| # | Request | Endpoint | Status | Finding | Classification | Notes |
|---|---------|----------|--------|---------|-----------------|-------|
| 1 | GET /orders/1042 | GET /orders/{id} | 200 | `total` field: schema declares `type: number`, response is string `"42.50"` | Software defect | Serialization mismatch; all numeric fields should be typed consistently |
| 2 | GET /orders/999999 | GET /orders/{id} | 404 | Error body missing required `code` field; has only `message` | Software defect | Error schema requires both `code` and `message`; response violates contract |
| 3 | POST /orders (5,000-char note) | POST /orders | 500 | (a) Undocumented status code 500; schema declares 201, 400 only. (b) Error body shape `{"error": "..."}` does not match Error schema `{code, message}`. (c) `note` field has enforced maxLength ~500, not declared in NewOrder schema | Software defects | (a) No 5xx in contract. (b) Error body shape mismatch. (c) Constraint not documented; request should return 400 per contract, not 500 |

---

## Test Design

### GET /orders/{id}

**Tags:** `@api` | suite: contract | priority: critical | automation: required

#### Partitions & Boundaries
- **id parameter (path, required, integer, minimum: 1)**
  - Valid: 1, 2, 1042, 999999 (normal range)
  - Boundary: id = 1 (minimum), large integers (e.g., 2147483647)
  - Invalid: 0 (below minimum), negative, non-integer (string "abc", float 1.5, null, missing)
  - Wrong type: JSON string in path segment

#### State Transitions & Resource Lifecycle
- Existing order: returns 200 with Order body (any valid status)
- Non-existent order: returns 404 with Error body
- Invalid state assumption: order immutability (no update or delete tested here)

#### Error Contract
- **200 OK:** Order schema with id, status (enum), total (number), optional note
- **404 Not Found:** Error schema with code and message
- **Undocumented 5xx:** treat as defect; not in contract

#### Acceptance Criteria
1. Status 200 responses include a valid Order body: id, status in [placed, paid, shipped], total as number (not string), optional note
2. Status 404 responses include Error body: both code and message fields (not message only)
3. Request with id < 1 or non-integer returns appropriate error (400 or 422; contract silent; observe and record)

---

### POST /orders

**Tags:** `@api` | suite: contract | priority: critical | automation: required

#### Partitions & Boundaries
- **items field (array, required, minItems: 1, string items)**
  - Valid: ["sku-1"], ["sku-1", "sku-2"], ["item with spaces"], ["item-123"]
  - Boundary: array with 1 item (minItems=1)
  - Invalid: empty array [], missing field, null, non-array (object, string, number), null in array
  - Wrong type: array of integers, array of objects

- **note field (optional, string)**
  - Valid: absent, "", "short note", "123 characters"
  - Boundary: undeclared maxLength; contract silent; observed constraint ~500 chars (defect: 500-char note returned 500 error, not 400)
  - Invalid: null (not declared; assume omitted instead), number, object, oversized (5000+ chars)

#### Error Scenarios
- **400 Bad Request:** missing items, empty items array, wrong type for items
- **500 Internal Server Error** (undocumented): occurs on oversized note; contract says this should be 400; defect

#### Response Contract
- **201 Created:** Order schema (id, status, total as number, optional note); status typically "placed" for new orders
- **400 Bad Request:** Error schema with code and message
- **500 Internal Server Error:** undocumented; currently returns `{"error": "..."}` (not Error schema shape)

#### Acceptance Criteria
1. POST with valid items array and no note returns 201 with Order body (id set, status="placed", total computed, note absent or null)
2. POST with valid items and short note returns 201 with Order body (note included)
3. POST with items oversized or note oversized returns 400 (not 500) with Error body: code and message fields
4. POST missing items, empty items, or wrong type returns 400 with Error body
5. Error responses always use {code, message} shape (never {error: ...})

---

## Test Cases: Partitioning & Priorities

### GET /orders/{id}

| Case | Input (id) | Expected Status | Expected Fields | Priority | Automation |
|------|-----------|-----------------|-----------------|----------|-----------|
| Valid: exists | 1042 | 200 | Order with status=paid, total as number | critical | required |
| Valid: boundary minimum | 1 | 200 or 404 | Order (if exists) or Error | high | required |
| Invalid: does not exist | 999999 | 404 | Error: code, message | critical | required |
| Invalid: below minimum | 0 | 400 or 422 | Error or parse error | high | required |
| Invalid: negative | -1 | 400 or 422 | Error or parse error | high | required |
| Invalid: non-integer | "abc" | 400 | Error or parse error | high | required |
| Invalid: null | (omitted in path) | N/A | 404 or 400 | medium | required |
| Boundary: large integer | 2147483647 | 200 or 404 | Order or Error | medium | required |

### POST /orders

| Case | Payload | Expected Status | Expected Fields | Priority | Automation |
|------|---------|-----------------|-----------------|----------|-----------|
| Valid: minimal | {"items": ["sku-1"]} | 201 | Order: id, status="placed", total (number), no note | critical | required |
| Valid: with note | {"items": ["sku-1"], "note": "test"} | 201 | Order with note field | critical | required |
| Invalid: missing items | {"note": "test"} | 400 | Error: code, message | critical | required |
| Invalid: empty items | {"items": []} | 400 | Error: code, message | critical | required |
| Invalid: wrong type (items is string) | {"items": "sku-1"} | 400 | Error: code, message | high | required |
| Invalid: oversized note (5000 chars) | {"items": ["sku-1"], "note": "<5000 chars>"} | 400 | Error: code, message (NOT 500) | high | required |
| Invalid: note is number | {"items": ["sku-1"], "note": 123} | 400 | Error: code, message | medium | required |
| Boundary: note at limit (assume ~500) | {"items": ["sku-1"], "note": "<500 chars>"} | 201 | Order with note | high | required |
| Boundary: large items array | {"items": ["sku-1", ..., "sku-100"]} | 201 or 400 | Order or Error (contract silent; observe) | medium | required |

---

## Contract Strategy Recommendation

**Schema conformance checks are justified and sufficient at this stage.** The API is single-provider with no indication of multiple independent consumers; there is no evidence that breaking changes have reached external clients. Conformance checks against the OpenAPI schema (step 3, automated in CI) will catch: undocumented status codes, missing or mistyped fields, and error body shape drift. This is the lower-cost first activity and aligns with the contract-first principle. Consumer-driven contracts are not warranted unless the API becomes a dependency for independently released services outside the team's visibility. Before automating, three software defects must be resolved: (1) `total` must be a number, not a string, (2) Error responses must include both `code` and `message` fields, (3) validation errors (oversized note) must return 400, not 500, with a correct Error body.
