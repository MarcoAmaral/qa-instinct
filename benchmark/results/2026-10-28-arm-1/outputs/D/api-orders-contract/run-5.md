# API Testing Report: Orders API v2.1.0

## Conformance Checklist

| Request | Expected Schema | Actual Response | Classification | Owner |
|---------|-----------------|-----------------|-----------------|-------|
| GET /orders/1042 | Order (total: number) | `{"id": 1042, "status": "paid", "total": "42.50", "note": null}` | **Defect**: `total` is string, schema declares `type: number` | Backend |
| GET /orders/999999 | Error (required: [code, message]) | `{"message": "Order not found"}` | **Defect**: missing required field `code` | Backend |
| POST /orders with 5000-char note | 201 with Order schema OR 400 with Error schema | 500 `{"error": "value too long for type character varying(500)"}` | **Defect**: undocumented HTTP 500; response shape neither 400 Error nor 201 Order | Backend |

## Contract Summary

| | |
|---|---|
| **Location & Version** | OpenAPI 3.0.3, version 2.1.0 (provided) |
| **Deployed Version Confirmed** | 2.1.0 on staging, tested 2026-10-15 |
| **Base URL** | Not specified; assumed staging instance |
| **Auth** | None declared |
| **Environments Tested** | Staging (recorded responses only) |

---

## Test Design by Endpoint

### GET /orders/{id}

**Partitions per field:**
- `id` (path): positive integer ≥1 (valid); 0, negative, non-integer, >2^31 (invalid); boundary cases: id=1, id=999999 (not found)

**State Model:**
- Order exists in `placed`, `paid`, or `shipped` state → 200, Order body
- Order does not exist → 404, Error body
- Authorization (if added): own order vs another user's

**Error Contract:**
- 404 (documented): Error schema with `code` and `message`
- Other statuses: not documented; probe for 500, 403, 401 if auth added

**Test Cases:**

| Case | Input | Expected (per schema) | Assertion | Tag |
|------|-------|----------------------|-----------|-----|
| Happy path: existing order | GET /orders/1042 | 200, Order with id, status ∈ [placed, paid, shipped], total (number), optional note | Status=200; body conforms Order schema; id, status, total present; total is numeric | `@api` L1 priority:1 |
| Not found | GET /orders/999999 | 404, Error with code and message | Status=404; body has code (string) and message (string) | `@api` L1 priority:1 |
| Invalid ID: boundary | GET /orders/0 | 404 or client error (400 or 422) | Status 4xx or 5xx; if documented as 400, Error schema | `@api` L2 priority:2 |
| Invalid ID: non-integer | GET /orders/abc | 400 or 404 | Handled gracefully; if 400, Error schema | `@api` L2 priority:2 |
| Very large ID | GET /orders/9999999999 | 404 (not found) or overflow error | State intent (record if 500) | `@api` L2 priority:3 |

---

### POST /orders

**Partitions per field:**
- `items` (array): 1 item (valid); 0 items (invalid, minItems=1); null, non-array, array of non-strings (invalid)
- `note` (optional string): absent (valid); empty string (valid); string; ≤500 chars (assumed); >500 chars (currently returns 500, not documented 400)

**Resource State Model:**
- POST with valid body → 201, Order created with id, status='placed', total, optional note
- POST with missing items → 400, Error
- POST with items=[] → 400, Error (schema violation)
- POST with overlong note → currently 500 (undocumented defect; should be 400 per intent)

**Error Contract:**
- 400 (documented): Error schema with `code` and `message`
- 201 (documented): Order schema with required id, status, total
- 500 (not documented): currently returns `{"error": "..."}`, not Error schema

**Test Cases:**

| Case | Input | Expected (per schema) | Assertion | Tag |
|------|-------|----------------------|-----------|-----|
| Happy path: minimal order | POST with `{"items": ["sku-1"]}` | 201, Order (id, status='placed', total, no note OR note=null) | Status=201; body conforms Order schema; id > 0; status in enum | `@api` L1 priority:1 |
| Happy path: with note | POST with `{"items": ["sku-1"], "note": "test"}` | 201, Order (id, status, total, note="test") | Status=201; Order body conforms; note field present and matches input | `@api` L1 priority:1 |
| Multiple items | POST with `{"items": ["sku-1", "sku-2"]}` | 201, Order | Status=201; Order conforms | `@api` L1 priority:1 |
| Missing items field | POST with `{"note": "test"}` | 400, Error with code and message | Status=400; Error body conforms; message indicates items required | `@api` L1 priority:1 |
| Empty items array | POST with `{"items": []}` | 400, Error (minItems=1 violated) | Status=400; Error conforms; message indicates minimum 1 item | `@api` L1 priority:2 |
| Items: non-array | POST with `{"items": "sku-1"}` | 400, Error | Status=400; Error conforms | `@api` L1 priority:2 |
| Note boundary: 500 chars | POST with `{"items": ["sku-1"], "note": "<500-char string>"}` | 201, Order with full note | Status=201; note field matches (or truncated if that's the spec) | `@api` L2 priority:2 |
| Note boundary: 5000 chars | POST with `{"items": ["sku-1"], "note": "<5000-char string>"}` | 400, Error (per schema intent) | **Currently fails: returns 500 with malformed body** | `@api` L2 priority:2 defect |
| Items: array of non-strings | POST with `{"items": [1, 2]}` | 400, Error | Status=400; Error conforms | `@api` L2 priority:3 |
| Null items | POST with `{"items": null}` | 400, Error | Status=400; Error conforms | `@api` L2 priority:3 |

---

## Contract Strategy Recommendation

**Schema conformance checks are sufficient** for this API. The service has a single provider (backend team) and one known consumer (frontend). A consumer-driven contract is not justified because:
- The provider controls both the schema and the service, so feedback loops are fast.
- A single internal consumer can validate responses against the published schema in its test suite.
- No independently released external consumers depend on this API yet.

Conformance testing (step 3 above) catches:
- Type mismatches (`total` as string).
- Missing required fields in error responses.
- Undocumented status codes and malformed bodies.

These findings should be reported as defects (step 4 → `/qa-defect`) and fixed before the suite runs in CI.

---

## Automation Recommendation

Automate in **Playwright + TypeScript** (if Playwright is in the stack) or **Vitest + native fetch** (if a heavier client is not available). Load the OpenAPI schema once at suite start, validate each response body through it (use a JSON Schema validator library), and never assert status codes alone.

Each test creates order records with unique note values to isolate state, then deletes them via the API after the assertion (DELETE not documented; confirm if supported or test cleanup via timestamp-based queries).
