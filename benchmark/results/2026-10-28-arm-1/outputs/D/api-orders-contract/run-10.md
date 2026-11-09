# API Test Report: Orders API v2.1.0

## Step 1: Contract

**Source:** OpenAPI 3.0.3 schema (provided)  
**Version:** 2.1.0  
**Deployed version under test:** 2.1.0 (staging environment, 2026-10-15)  
**Auth model:** None (no authentication declared)  
**Base URL:** `https://staging.api.example.com` (assumption; not provided)  
**Environment:** Shared staging instance; data created 2026-10-15

---

## Step 2: Conformance Findings

| # | Request | Declared Schema | Actual Response | Classification | Issue | Proposed Owner |
|---|---------|-----------------|-----------------|-----------------|-------|-----------------|
| 1 | `GET /orders/1042` | Order.total: `number` | `"total": "42.50"` (string) | Software defect | Type mismatch: schema declares `number`, API returns string. Serialization layer bug or JSON parsing issue. | API Team |
| 2 | `GET /orders/999999` | Error requires: `{code, message}` | `{"message": "Order not found"}` | Software defect | Missing required field: `code` is required by schema but absent. Error schema not followed. | API Team |
| 3 | `POST /orders` (note field 5,000 chars) | Documented responses: 201, 400 | Status 500 | Software defect | Undocumented status code. No schema maps HTTP 500. | API Team |
| 3 | `POST /orders` error body | Error requires: `{code, message}` | `{"error": "value too long for type character varying(500)"}` | Software defect | Wrong error shape: `error` field instead of required `{code, message}`. Payload validation error; `note` field apparently has a 500-char limit undeclared in the schema. | API Team |

**Additional observations:**  
- NewOrder schema declares no `maxLength` for the `note` field, but the API enforces a 500-character limit and rejects longer input. This is a schema documentation gap (missing constraint).
- No `minimum` declared for numeric boundaries on `total` (e.g., must be ≥ 0?); boundary probing needed.

---

## Step 3: Test Design

### GET /orders/{id}

**Purpose:** Retrieve an order by ID  
**Tag:** `@api` | suite: order-retrieval | priority: critical | automation: required

| Case | Partition | Input | Expected Status | Expected Body | Acceptance Criterion |
|------|-----------|-------|-----------------|----------------|----------------------|
| 1 | Valid order, exists | `id = 1042` | 200 | Order with all fields populated; `status` ∈ {placed, paid, shipped}; `total` is number ≥ 0 | Retrieve placed order returns correct schema |
| 2 | Valid order, no note | `id = 1043` (create one with no note) | 200 | Order with `note` absent or `null` (schema allows both) | Optional field handling |
| 3 | Order not found | `id = 999999` | 404 | Error with `{code, message}` both present and non-empty | 404 returns valid error schema |
| 4 | ID boundary: minimum | `id = 1` (if exists) | 200 or 404 | Conforms to schema for that status | Minimum declared (1) is enforced |
| 5 | ID boundary: below minimum | `id = 0` | 400 or 404 | Error body conforms | Schema minimum = 1; API rejects or treats as not found |
| 6 | ID boundary: maximum integer | `id = 2147483647` | 404 (assumed not found) | Error body conforms | Large valid integer handled |
| 7 | ID type mismatch | `id = "abc"` (in path) | 400 or 404 | Error body conforms | Non-integer rejected by path validation |
| 8 | Negative ID | `id = -1` | 400 or 404 | Error body conforms | Below minimum; rejected or not found |

**Resource state:** Order is immutable from retrieval perspective (GET only); status enum is `{placed, paid, shipped}`.

---

### POST /orders

**Purpose:** Create a new order  
**Tag:** `@api` | suite: order-creation | priority: critical | automation: required

| Case | Partition | Input Body | Expected Status | Expected Body | Acceptance Criterion |
|------|-----------|------------|-----------------|----------------|----------------------|
| 1 | Valid, minimal | `{"items": ["sku-1"]}` | 201 | Order with `id`, `status` (default?), `total`, no `note` field or `null` | Create order with required fields only |
| 2 | Valid, with note | `{"items": ["sku-1"], "note": "rush"}` | 201 | Order with `note: "rush"` | Optional note field passed through |
| 3 | Multiple items | `{"items": ["sku-1", "sku-2", "sku-3"]}` | 201 | Order reflecting all items | Array with > 1 item accepted |
| 4 | Empty items array | `{"items": []}` | 400 | Error with `{code, message}` | minItems: 1 enforced; empty rejected |
| 5 | Missing items | `{"note": "test"}` | 400 | Error with `{code, message}` | Required field validation |
| 6 | Items is null | `{"items": null}` | 400 | Error with `{code, message}` | Type violation (null instead of array) |
| 7 | Items is string | `{"items": "sku-1"}` | 400 | Error with `{code, message}` | Type violation (string instead of array) |
| 8 | Array item is not string | `{"items": [123]}` | 400 | Error with `{code, message}` | Item type validation (number instead of string) |
| 9 | Note field boundary: max length | `{"items": ["sku-1"], "note": "<string, 500 chars>"}` | 201 | Order created | Note at declared limit (if added to schema) |
| 10 | Note field: over limit | `{"items": ["sku-1"], "note": "<string, 5000+ chars>"}` | 400 | Error with `{code, message}` (not 500) | Validation error, not server crash |
| 11 | Note is null | `{"items": ["sku-1"], "note": null}` | 201 | Order with `note: null` or field absent | Null is valid for optional field |
| 12 | Extra field in request | `{"items": ["sku-1"], "unknown": "value"}` | 201 | Order (extra fields ignored) or 400 if strict | Schema additionalProperties behavior |
| 13 | Malformed JSON | Invalid JSON body | 400 | Error with `{code, message}` | JSON parse error |
| 14 | Empty body | `{}` | 400 | Error with `{code, message}` | Missing required `items` |

**Resource state & transitions:**  
- Create → Order enters lifecycle (status: placed, paid, or shipped; unclear from schema what the default is—probe this).  
- No idempotency declared; assume repeating POST creates multiple orders (typical REST).

**Error contract:**  
- 201: Order (all required fields present and types correct).  
- 400: `{code, message}` (both required; currently defective per response 3).  
- 500: Undocumented; currently returned for payload validation (note field too long). Should be 400 or documented.

---

## Step 4: Automation Strategy (Placeholder)

Tests will be written once conformance findings are resolved. Test approach:  
- Helper class with `getOrder(id)` and `createOrder(body)` methods; no assertions in helper.  
- Each spec validates response status **and** body against the schema using a JSON schema validator.  
- Data isolation: create orders with unique item SKUs; verify cleanup via GET afterwards.  
- Red-Green Proof: run with expected and actual values swapped to confirm assertion sensitivity.

---

## Step 5: Contract Strategy Recommendation

**Schema conformance checks are sufficient.**  

**Reasoning:**  
- Single provider, single consumer (assumed from staging-only mention). Consumer-driven contracts are justified only when multiple independently released consumers exist and cannot be tested by the provider; that is not the case here.  
- Conformance testing (validate all responses against the schema, run in CI, re-run on each deployment) will catch regressions in status codes, error shapes, and field types. The three mismatches above (type mismatch on `total`, missing `code` in error, undocumented 500) would all be caught by schema validation in the test suite.  
- Automation: use a test runner's HTTP client (Playwright `request`, `fetch`, or axios) with a JSON schema library (ajv, Hypothesis, or language-native validation); load the schema once per suite, reuse it across all tests.  
- Do not add consumer-driven contracts unless the provider ships to multiple external teams who have breaking changes reach production before the provider team sees them.

---

## Findings Summary

**Defects to file (3 software defects, 1 documentation gap):**

1. **Response type mismatch** (response 1): `Order.total` returned as string instead of number.  
2. **Error schema violation** (response 2, 3): `Error` body missing required `code` field; includes undeclared `error` field instead.  
3. **Undocumented status code** (response 3): HTTP 500 not in schema; payload validation should return 400.  
4. **Schema constraint missing** (response 3, observation): `NewOrder.note` has a 500-character limit enforced by the API but not declared in the schema.

**Tests to write: 30+ cases** (see design matrix above) covering:  
- Happy path (retrieve, create).  
- Boundary conditions on `id` (minimum 1, type integer), `items` (minItems 1, type array of string), `note` (optional, 500-char limit).  
- Error body schema conformance (all error responses checked for `{code, message}`).  
- Type violations (null, wrong JSON type).  
- Undocumented fields and missing required fields.
