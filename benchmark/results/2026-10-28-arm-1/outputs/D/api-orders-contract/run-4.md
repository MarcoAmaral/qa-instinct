# Contract and Conformance Report: Orders API v2.1.0

## Contract Summary

**Location:** Provided OpenAPI 3.0.3 document  
**Version:** 2.1.0  
**Deployed Build:** Staging, 2026-10-15  
**Confirmation:** Version in OpenAPI title matches recorded responses metadata  
**Auth Model:** None (no security schemes declared)  
**Base URL:** Assumed `https://staging-api.example.com` (not specified; required for automation)

---

## Conformance Findings

| Request | Declared Schema | Actual Response | Classification | Proposed Owner |
|---------|-----------------|-----------------|-----------------|----------------|
| GET /orders/1042 | `Order.total` must be `type: number` | `"42.50"` (string) | **Software defect**: API serializes `total` as string instead of number | API provider |
| GET /orders/999999 | `Error` requires `[code, message]` | `{"message": "Order not found"}` — `code` missing | **Software defect**: `code` field is required by schema but absent from response | API provider |
| POST /orders (5,000-char note) | Only 201 and 400 documented | HTTP 500 returned | **Software defect**: Undocumented status code | API provider |
| POST /orders (5,000-char note) | `Error` requires `[code, message]` | `{"error": "value too long for..."}` — wrong shape | **Software defect**: Error body does not conform to Error schema | API provider |
| POST /orders with `note` field | Schema declares no `maxLength` on `note` (optional field) | Request rejected; message indicates 500-char limit | **Documentation drift**: The `note` field has an undeclared server-side limit of 500 characters | Schema owner |

---

## Test Design

### GET /orders/{id}

**Partitions and Boundaries (per field):**
- `id` parameter: valid (1–2147483647), boundary (id=1, id=999999), invalid (id=0, id=-1, id=non-integer)

**Resource State Model:**
- Happy path: order exists → 200 with Order body
- Error path: order does not exist → 404 with Error body (both `code` and `message` required)

**Response Body Contract:**
- **200**: Order schema (`id` integer, `status` one of [placed, paid, shipped], `total` number ← **currently broken**, `note` string|null)
- **404**: Error schema (`code` and `message` required ← **currently broken**)

**Cases:**
- `GET /orders/1` → 200, Order with `total` as number (type-check)
- `GET /orders/999999` → 404, Error with both `code` and `message`
- `GET /orders/0` → likely 400 or 404; clarify boundary
- `GET /orders/{non-integer}` → 400 or 404; clarify format validation

**Tags:** `@api` `@get` `@orders-read` `priority:high` `automation:required`

---

### POST /orders

**Partitions and Boundaries (per field):**
- `items` (required array):
  - Valid: 1–N string SKUs
  - Boundary: minItems=1 (one item), 100+ items
  - Invalid: empty array, null, non-array, non-string items
  
- `note` (optional string):
  - Valid: empty string, 1–500 chars (observed limit)
  - Boundary: exactly 500 chars, 501 chars
  - Invalid: null, non-string, 5000+ chars ← **currently returns 500 instead of 400**

**Resource State Model:**
- Happy path: POST valid NewOrder → 201, Order with auto-assigned `id`, `status` (assume "placed"), calculated `total`
- Validation error: POST with empty items or malformed body → 400, Error with `code` and `message`
- Boundary error: POST with note > 500 chars → 400 (not 500), Error with `code` and `message`

**Response Body Contract:**
- **201**: Order schema (`total` as number, not string ← **currently broken**)
- **400**: Error schema (both `code` and `message` required ← **currently broken**)
- **500**: Not documented; currently observed but should not occur

**Cases:**
- `POST /orders` with valid items and no note → 201, Order with `status="placed"`, `total` as number
- `POST /orders` with items and note (50 chars) → 201, Order with `note` echoed back
- `POST /orders` with empty items array → 400, Error
- `POST /orders` with note = 500 chars → 201 (boundary valid)
- `POST /orders` with note = 501 chars → 400, Error (boundary invalid) — **requires fix from 500 status**
- `POST /orders` with no body → 400, Error
- `POST /orders` with non-JSON body → 400 or 415, Error

**Tags:** `@api` `@post` `@orders-create` `priority:high` `automation:required` `boundary:note-length`

---

## Contract Strategy Recommendation

**Schema conformance checks are sufficient** for this API at its current maturity. No consumer-driven contracts are justified: this is a single-provider, single-contract model with synchronous black-box testing. Three conformance findings (total type mismatch, missing error `code` field, and undocumented 500 + maxLength on note) must be resolved before schema checks can pass; run conformance in CI after fixes to prevent regression. Test suite should validate body against the declared schema for every status, not only HTTP status codes.
