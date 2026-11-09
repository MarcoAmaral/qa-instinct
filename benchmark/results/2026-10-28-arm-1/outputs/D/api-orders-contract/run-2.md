# Contract

**Location:** Provided as OpenAPI 3.0.3 document  
**Version:** 2.1.0  
**Recorded:** 2026-10-15 against deployed version 2.1.0 on staging environment  
**Base URL:** `https://staging-api.example.com` (assumed from "staging environment"; not provided)  
**Auth:** None declared; assumed unauthenticated access  

**Endpoints:**
- `GET /orders/{id}` — retrieve order by ID
- `POST /orders` — create new order

---

# Conformance

| # | Request | Expected Schema | Actual Response | Status | Classification | Owner |
|---|---------|-----------------|-----------------|--------|-----------------|-------|
| 1 | `GET /orders/1042` | `Order.total: number` | `"total": "42.50"` (string) | 200 | **Software defect** — type mismatch: string where number declared | API backend |
| 2 | `GET /orders/999999` | `Error`: {code, message} both required | `{"message": "Order not found"}` — missing `code` | 404 | **Software defect** — required field `code` missing from Error response | API backend |
| 3 | `POST /orders` with 5000-char note | Documented responses: 201, 400 | 500 with `{"error": "…"}` | 500 | **Software defect** — undocumented status code; wrong error shape | API backend |
| 4 | `POST /orders` with 5000-char note | `Error`: {code, message} on 400 errors | `{"error": "value too long…"}` — wrong shape | 500 | **Software defect** — error body uses `error` instead of `code`/`message` schema | API backend |

**Assumptions:**  
- Recorded responses from 2026-10-15 represent deployed version 2.1.0 behavior at that time.
- Staging base URL inferred from "staging environment" context; no explicit endpoint provided.
- Auth model "none" assumed because no security scheme is declared in the OpenAPI document.

---

# Design

## Endpoint: GET /orders/{id}

### Field Partitions & Boundaries

**Path Parameter `id`:**
- **Valid partition:** integers in range [1, max-int], order exists in system
- **Invalid partition:** 0, negative integers, non-existent positive integers
- **Boundary:** minimum valid id = 1 (schema declares `minimum: 1`); no maximum declared; probe for integer overflow or type coercion

**Expected Response (200):**
- `id`: integer, present ✓
- `status`: enum string [placed, paid, shipped], present ✓
- `total`: number, present — **currently fails: API returns string** ✗
- `note`: optional string, can be null ✓

**Error Response (404):**
- `code`: string, required — **currently fails: not present** ✗
- `message`: string, required ✓

### State Model

| State | Trigger | Expected Status | Expected Body |
|-------|---------|-----------------|----------------|
| Order exists | `GET /orders/{valid_id}` | 200 | Order with id, status, total |
| Order not found | `GET /orders/{invalid_id}` | 404 | Error {code, message} |

### Invalid Transitions & Edge Cases

- Query non-existent ID (e.g., 999999)
- Query with id=0 (below minimum)
- Query with negative id
- Query with non-integer id (type mismatch in URL parsing)

### Error Contract

| Status | Schema Required | Schema Fields | Current Behavior |
|--------|---|---|---|
| 200 | Order | {id, status, total, note?} | ✓ structure OK, but `total` is string not number |
| 404 | Error | {code, message} | ✗ missing `code` field |

### Idempotency

GET is idempotent; repeating the same request must return identical responses (or 404 consistently if deleted between calls).

### Tags

`@api` `@rest` `@suite:orders` `@priority:p1` `@automation:required`

---

## Endpoint: POST /orders

### Field Partitions & Boundaries

**Request Body `NewOrder`:**

**Field `items` (required array of strings):**
- **Valid partition:** array with 1+ non-empty strings (schema declares `minItems: 1`)
- **Invalid partitions:**
  - Empty array `[]`
  - Missing field
  - Null
  - Non-array type (object, string, number)
  - Array with non-string items
- **Boundary:** minItems = 1; no maxItems declared; probe for max array length and per-item string length
- **Type mismatch:** string where array expected, or number items instead of strings

**Field `note` (optional string):**
- **Valid partition:** absent, empty string, normal text
- **Invalid partitions:** null, non-string (number, boolean, object)
- **Boundary:** no maxLength declared; schema allows any string, but **API validates at DB level** (5000 char test triggered 500, column limit is 500 chars) — this is **undocumented validation**; probe for the real limit
- **Database constraint mismatch:** schema declares `type: string` with no maxLength, but DB rejects strings > 500 chars

**Expected Response (201):**
- `id`: integer, present
- `status`: enum string [placed, paid, shipped], present
- `total`: number, present — **currently fails: API returns string** ✗
- `note`: optional string or null

**Error Response (400):**
- `code`: string, required — **currently fails: not present** ✗
- `message`: string, required ✓

### State Model

| Trigger | Expected Status | Expected Body | Current Behavior |
|---------|---|---|---|
| Valid items, no note | POST with {"items": ["sku-1"]} | 201 | Order created (untested; assume OK based on schema) |
| Valid items, short note | POST with {"items": ["sku-1"], "note": "short"} | 201 | Order created (untested; assume OK) |
| Valid items, 5000-char note | POST with {"items": ["sku-1"], "note": "<5000 chars>"} | 400 or 500 | **Currently 500 with wrong error shape** ✗ |
| Empty items | POST with {"items": []} | 400 | Not tested; schema violation |
| Missing items | POST with {"note": "text"} | 400 | Not tested; required field missing |

### Invalid Transitions & Edge Cases

- Omit `items` field entirely
- Send `items: null`
- Send `items: []` (violates minItems: 1)
- Send `items: [""]` (empty string item)
- Send `items: [123]` (non-string type)
- Send `note: null`
- Send `note: 5000+` character string (triggers DB validation error, currently 500)
- Send extra undeclared fields in request

### Error Contract

| Status | Schema Required | Schema Fields | Current Behavior |
|--------|---|---|---|
| 201 | Order | {id, status, total, note?} | ✗ `total` is string not number |
| 400 | Error | {code, message} | Not tested; schema declares it, API may return 500 instead |

**Undocumented:** API returns 500 with `{"error": "…"}` when note > 500 chars (DB column limit); neither 400 nor 500 is documented in OpenAPI spec.

### Idempotency

POST is not idempotent by default. **Not tested whether:** retrying the same create request duplicates the order or returns the same order ID. If the API supports idempotency keys, test with and without them.

### Tags

`@api` `@rest` `@suite:orders` `@priority:p1` `@automation:required`

---

## Test Coverage Summary

### Happy Path (Positive Cases)
- [ ] GET existing order (id=1042 or similar valid ID) → 200, Order with all required fields
- [ ] POST valid order with items only → 201, Order created
- [ ] POST valid order with items and short note → 201, Order created

### Boundary & Invalid Input (Negative Cases)
- [ ] GET with id=0 → 404 or 400
- [ ] GET with id=-1 → 404 or 400
- [ ] GET with non-existent id → 404, Error {code, message}
- [ ] POST with empty items array → 400, Error {code, message}
- [ ] POST with missing items field → 400, Error {code, message}
- [ ] POST with items=null → 400, Error {code, message}
- [ ] POST with items containing non-strings → 400, Error {code, message}
- [ ] POST with note > 500 characters → **Currently 500, should be 400**; test current behavior and conformance
- [ ] POST with note=null → 201 (optional field) or 400 if null is rejected

### Type & Schema Validation
- [ ] Verify `Order.total` is number (currently fails: string)
- [ ] Verify `Order.status` is one of [placed, paid, shipped]
- [ ] Verify 404 Error has both `code` and `message` (currently fails: missing code)

### Undocumented Behavior
- [ ] Confirm POST with 5000-char note returns 500 (not documented)
- [ ] Determine DB constraint on `note` field (currently inferred as 500 chars)

---

## Contract Strategy

**Schema conformance checks are the justified first step.** The API has four confirmed mismatches (wrong types, missing fields, undocumented status). These are fast to catch in CI: load the OpenAPI spec once, validate every response body against the declared schema for its status code, and fail the suite if any response shape or type differs from the contract. 

Consumer-driven contracts are not justified here: there is no evidence of multiple independent consumers. The defects are in the provider's conformance to its own declared schema, not in a gap between consumer expectations and provider promises. Once the provider fixes the four mismatches (string→number for `total`, add `code` to Error responses, document and shape the 500 error, respect the undeclared note maxLength), schema conformance checks are sufficient to prevent regression.
