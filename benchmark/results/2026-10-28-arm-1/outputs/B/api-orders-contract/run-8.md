# API Contract Compliance Report & Test Design

## Contract Violations Found

### Response 1: GET /orders/1042 → 200

| Issue | Details |
|-------|---------|
| **Type field mismatch** | `total: "42.50"` is a string; contract requires `type: number` |
| **Nullable field violation** | `note: null` returned; schema defines `note: { type: string }` (not explicitly nullable) |

### Response 2: GET /orders/999999 → 404

| Issue | Details |
|-------|---------|
| **Missing required field** | Response lacks `code` field; Error schema requires `[code, message]` |
| **Incomplete schema** | Only `message` present; `code` is required |

### Response 3: POST /orders → 500

| Issue | Details |
|-------|---------|
| **Wrong status code** | Returns 500; contract specifies 400 for invalid input |
| **Wrong response schema** | Returns `{"error": "..."}` instead of Error schema `{code, message}` |
| **Undocumented constraint** | `note` field has 500-char limit not specified in OpenAPI schema |
| **Invalid error format** | Does not conform to Error schema structure |

---

## Recommended Test Suite

### GET /orders/{id} Tests

**Valid cases:**
- ✓ GET /orders/1 with valid order returns 200 + Order schema
- ✓ Order.total is numeric (not string)
- ✓ Order.status is one of [placed, paid, shipped]
- ✓ Order.note is either omitted or a string (not null)

**Invalid cases:**
- ✓ GET /orders/999999 returns 404 + Error schema with both `code` and `message`
- ✓ GET /orders/0 returns 404 (id minimum is 1)
- ✓ GET /orders/-1 returns 404
- ✓ GET /orders/abc returns 400 or 404 (non-integer id)

**Edge cases:**
- ✓ GET /orders/9223372036854775807 (max int64)

---

### POST /orders Tests

**Valid cases:**
- ✓ POST with `{"items": ["sku-1"]}` returns 201 + Order schema
- ✓ POST with `{"items": ["sku-1", "sku-2", ...]}` (multiple items)
- ✓ POST with `{"items": ["sku-1"], "note": ""}` (empty note allowed)
- ✓ POST with `{"items": ["sku-1"], "note": "<string up to 499 chars>"}` returns 201

**Invalid cases:**
- ✓ POST with `{"items": []}` returns 400 + Error (minItems: 1 violated)
- ✓ POST with `{"note": "text"}` (missing items) returns 400 + Error
- ✓ POST with `{"items": "sku-1"}` (items not array) returns 400 + Error
- ✓ POST with `{"items": [123]}` (items should be strings) returns 400 + Error
- ✓ POST with `{"items": ["sku-1"], "note": "<5001 chars>"}` returns **400** (not 500) + Error schema
- ✓ POST with empty body returns 400 + Error
- ✓ POST with invalid JSON returns 400

**Schema compliance:**
- ✓ 201 response Order schema has integer `id`, enum `status`, numeric `total`, optional `note`
- ✓ 400 response Error schema has string `code` and string `message` (both required)

---

## Assumptions

- Nullable fields should be explicitly marked `nullable: true` in OpenAPI for null to be valid; unmarked fields should not return null
- Note field has undocumented 500-character limit (inferred from error message)
- Status code 500 in response 3 is a bug; should be 400
- Response body format errors in responses 2 and 3 indicate implementation issues with error handling
