# API Testing Report: Orders API v2.1.0

## Contract Discovery

| Aspect | Details |
|--------|---------|
| Location | OpenAPI 3.0.3, provided in-line |
| Version | 2.1.0 |
| Deployed version tested | 2.1.0 (staging, 2026-10-15) |
| Authentication | None declared |
| Base URL | Assumed `https://staging.example.com` |

---

## Conformance Findings

All recorded responses run against the declared schema for their status code.

| # | Request | Status | Finding | Classification | Severity |
|---|---------|--------|---------|-----------------|----------|
| 1 | GET /orders/1042 | 200 | `total` field is string `"42.50"` but schema declares `type: number` | **Software defect** | High |
| 2 | GET /orders/999999 | 404 | Error response missing required `code` field; only `message` present. Schema requires both. | **Software defect** | High |
| 3 | POST /orders (note: 5000 chars) | 500 | Undocumented status. Schema declares only 201 and 400. | **Software defect** | High |
| 4 | POST /orders (note: 5000 chars) | 500 | Error body shape is `{"error": "..."}` but schema requires `Error` with required fields `code` and `message` | **Software defect** | High |

---

## Test Design

### Endpoint: GET /orders/{id}

**Parameters & Boundaries**
- `id` (path, required, integer, minimum: 1)
  - Valid partition: id ≥ 1 (e.g., 1, 100, 1042)
  - Invalid partition: id < 1 (e.g., 0, -1)
  - Boundary: id = 1, id = 2147483647
  - Type mismatch: id as string, float

**Resource States**
- Order exists → 200, `Order` body with `id`, `status` (enum), `total`, optional `note`
- Order does not exist → 404, `Error` body (currently broken: missing `code`)

**Authorization**
- Assumed: no authentication required (no auth model in schema; confirm if this is an internal-only API)

**Error Contract**
- Schema documents: 404 with `Error` shape
- Observed error shape: incomplete (missing `code`)
- Expected body: `{"code": "<code>", "message": "Order not found"}`

**Idempotency**
- GET is idempotent; safe to retry.

**Test Cases (by technique)**

| Case | Input | Expected Status | Expected Body | Tags |
|------|-------|-----------------|----------------|------|
| TC-1: Retrieve existing order | GET /orders/1042 | 200 | Order with id, status enum, total (number not string), optional note | @api, @positive, @smoke |
| TC-2: Order not found | GET /orders/999999 | 404 | Error with code and message | @api, @negative, @boundary |
| TC-3: Invalid id = 0 | GET /orders/0 | 400 or 404 | Error (response TBD by service) | @api, @negative, @boundary |
| TC-4: Invalid id = -1 | GET /orders/-1 | 400 or 404 | Error (response TBD by service) | @api, @negative, @boundary |
| TC-5: Invalid id type (string) | GET /orders/abc | 400 | Error (response TBD by service) | @api, @negative, @type-mismatch |

---

### Endpoint: POST /orders

**Request Body & Boundaries**

- `items` (required, array of strings, minItems: 1)
  - Valid partition: 1 string, 2+ strings
  - Invalid partition: 0 items, null, missing, non-array type
  - Boundary: items minItems=1 (valid: ["sku-1"]; invalid: [])
  - Item type: string vs non-string (number, object, null)

- `note` (optional, string)
  - Valid partition: absent, short string, within db limit (~500 chars observed)
  - Invalid partition: over ~500 chars (db constraint observed)
  - Type mismatch: null, number, array

**Resource States**
- Valid order created → 201, `Order` body with id, status, total, optional note
- Invalid input → 400, `Error` body (currently broken: missing `code`, using wrong field name `error`)
- Input exceeding db constraints → Currently returns 500 (undocumented); expected 400

**Authorization**
- Assumed: no authentication required

**Error Contract**
- Schema documents: 400 with `Error` shape
- Observed on constraint violation (note > 500 chars): 500 with malformed error body
- Expected on 400: `{"code": "<code>", "message": "<message>"}`

**Idempotency**
- POST is not idempotent. Calling twice creates two orders. Test: POST same body twice, expect two distinct order ids.

**Test Cases (by technique)**

| Case | Input | Expected Status | Expected Body | Tags |
|------|-------|-----------------|----------------|------|
| TC-6: Create order, minimal | POST /orders with `{"items": ["sku-1"]}` | 201 | Order with id (≥1), status ∈ [placed, paid, shipped], total ≥ 0, no note | @api, @positive, @smoke |
| TC-7: Create order with note | POST /orders with `{"items": ["sku-1"], "note": "rush"}` | 201 | Order + note field present in response | @api, @positive |
| TC-8: Multiple items | POST /orders with `{"items": ["sku-1", "sku-2"]}` | 201 | Order created | @api, @positive |
| TC-9: Missing items | POST /orders with `{"note": "test"}` | 400 | Error with code and message | @api, @negative, @required-field |
| TC-10: Empty items array | POST /orders with `{"items": []}` | 400 | Error with code and message | @api, @negative, @boundary |
| TC-11: Items not array | POST /orders with `{"items": "sku-1"}` | 400 | Error with code and message | @api, @negative, @type-mismatch |
| TC-12: Note too long (>500 chars) | POST /orders with items + 5000-char note | 400 | Error with code and message (currently returns 500) | @api, @negative, @boundary, @defect-regression |
| TC-13: Idempotent POST | Send TC-6 twice | 201 each time | Two different order ids | @api, @idempotency |
| TC-14: Item type mismatch | POST /orders with `{"items": [123]}` | 400 | Error with code and message | @api, @negative, @type-mismatch |

---

## Contract Strategy Recommendation

**Schema conformance checks are sufficient.** The Orders API has a single provider (staging service) and no indication of multiple independent consumers. Conformance checks against the provided OpenAPI schema will:

- Validate every endpoint and documented status code against the contract
- Catch type mismatches (total as string), missing required fields (code in Error), and undocumented responses (500)
- Detect future regressions automatically

Consumer-driven contracts are not justified until: (1) multiple independently released consumers depend on this API, (2) the provider team cannot observe or test those consumers, and (3) breaking changes have already escaped to production. Run conformance checks in CI after each deploy to catch drift early.

---

## Defects to File

Three software defects block test automation:

1. **GET /orders/{id}: 200 response returns `total` as string, not number** → `/qa-defect`
2. **GET /orders/{id}: 404 response missing required `code` field** → `/qa-defect`
3. **POST /orders: Input validation error (note > 500 chars) returns 500 with wrong error shape** → `/qa-defect`

Resolve defects before automation. Tests will assert the corrected behaviour once fixes land.
