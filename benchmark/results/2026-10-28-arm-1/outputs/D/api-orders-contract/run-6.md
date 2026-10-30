## Contract

**Location:** Provided inline; OpenAPI 3.0.3

**Version:** 2.1.0

**Deployed version under test:** 2.1.0, confirmed by user (recorded 2026-10-15 on staging)

**Authentication:** None declared; assumed public/unauthenticated

**Base URL:** Staging (2026-10-15)

**Endpoints:**
- `GET /orders/{id}` — retrieve an order
- `POST /orders` — create an order

---

## Conformance Findings

| # | Request | Declared Schema | Actual Response | Classification | Owner |
|---|---------|-----------------|-----------------|---|---|
| 1 | GET /orders/1042 | Order: `total` is number | `{"id": 1042, "status": "paid", "total": "42.50", "note": null}` | **Software defect**: `total` returned as string, schema declares `type: number` | API team |
| 2 | GET /orders/999999 | Error: requires `code` and `message` | `{"message": "Order not found"}` | **Software defect**: missing required `code` field; Error schema declares both as required | API team |
| 3 | POST /orders (5,000-char note) | 201 or 400 only | Status 500, body: `{"error": "value too long for type character varying(500)"}` | **Software defect**: undocumented HTTP 500 status; response body does not conform to Error schema (has `error` key, not `code` + `message`). **Documentation drift**: schema omits `maxLength` constraint on `note` field | API team / Docs team |

---

## Design

### Endpoints and Test Cases

#### GET /orders/{id}

**Partitions and Boundaries:**
- `id` parameter: integer, minimum 1 (per schema)
  - Valid: 1, 999999, large integers
  - Invalid: 0, negative, non-integer, string, null

**Resource State:**
- Existing order (id=1042) → 200 with Order body
- Non-existent order (id=999999) → 404 with Error body

**Error Contract:**
- 404: Error schema (requires `code` + `message`); actual response missing `code` (defect found)
- Undocumented statuses: 500, 401, 403 (test for presence/absence)

**Test Cases:**
- `@api suite:orders priority:p1`: GET valid id → 200, body conforms to Order schema, all required fields present, `status` in enum, `total` is number type
- `@api suite:orders priority:p1`: GET non-existent id → 404, body conforms to Error schema (both `code` and `message` required)
- `@api suite:orders priority:p2`: GET id = 0 → 400 or 404 (boundary below minimum)
- `@api suite:orders priority:p2`: GET id = negative → 400 or 404
- `@api suite:orders priority:p2`: GET invalid id types (string, null, float) → 400
- `@api suite:orders priority:p2`: GET with very large id → 404 or 200 (boundary behavior)

---

#### POST /orders

**Partitions and Boundaries:**
- `items` (required): array of strings, minItems: 1
  - Valid: `["sku-1"]`, `["sku-1", "sku-2"]`, single item array
  - Invalid: empty array `[]`, null, missing, non-array, non-string items
- `note` (optional): string
  - Valid: absent, null, empty string `""`, normal text
  - Invalid: non-string, exceeds schema limit (5,000-char test → 500 error; defect found)

**Resource State / Idempotency:**
- POST creates a new order; assume no idempotency key (test if repeating POST duplicates or returns 400/409)

**Error Contract:**
- 201: Order schema (requires `id`, `status`, `total`)
- 400: Error schema (requires `code` + `message`) for validation failures
- 500: undocumented; defect found (database constraint on `note` field not declared)

**Test Cases:**
- `@api suite:orders priority:p1`: POST valid request `{"items": ["sku-1"]}` → 201, body conforms to Order schema, `id` assigned, `status` in enum, `total` is number
- `@api suite:orders priority:p1`: POST with optional `note` → 201, `note` carried through (or omitted if not required in response)
- `@api suite:orders priority:p2`: POST with empty items array `[]` → 400, Error body has `code` + `message`
- `@api suite:orders priority:p2`: POST with missing `items` → 400, Error body conforms
- `@api suite:orders priority:p2`: POST with non-string items `[123]` → 400, Error body conforms
- `@api suite:orders priority:p2`: POST with `note` = null → 201 or 400 (clarify schema intent)
- `@api suite:orders priority:p2`: POST with `note` exceeding 500 chars → 400 (with correct Error shape) or 500 (current defect)
- `@api suite:orders priority:p2`: POST with `note` = 500 chars exactly → 201 (boundary, schema silent)
- `@api suite:orders priority:p2`: POST repeated (same request twice) → clarify idempotency (201 both times, 409 on second, or 400)

---

### Contract Strategy

**Recommendation: Schema conformance checks are sufficient.**

**Reasoning:** The Orders API has a single provider and no evidence of multiple independent consumers. The mismatches found (type errors, missing required fields, undocumented status codes, response body shape violations) are caught by validating every response body against the OpenAPI schema in CI. No consumer-driven contracts are needed unless separate, independently released client teams emerge. The schema itself must be updated to document the `maxLength: 500` constraint on `note` and to include the HTTP 500 error type and its body shape; these are documentation drifts, not justifications for a separate contract layer.
