# API Contract Mismatches

## Response 1: GET /orders/1042 → 200
| Field | Issue | Expected | Actual |
|-------|-------|----------|--------|
| `total` | Type mismatch | `number` (e.g., `42.50`) | `string` (`"42.50"`) |
| `note` | Invalid null | Must be `string` or omitted when null | `null` |

## Response 2: GET /orders/999999 → 404
| Field | Issue | Expected | Actual |
|-------|-------|----------|--------|
| (missing) | **Required field absent** | Error schema requires `code` and `message` | Only `message` provided |

## Response 3: POST /orders → 500
| Aspect | Issue | Expected | Actual |
|--------|-------|----------|--------|
| Status code | **Undocumented** | Only 201 or 400 specified | `500` returned |
| Response body | **Schema mismatch** | Error schema: `{code, message}` | `{error: "..."}` |
| Input validation | **Missing constraint** | Schema doesn't specify `note` limit | API enforces 500-char max (unspecified) |

**Assumptions:** 
- `null` values should be omitted from response (strict schema compliance), not sent as `null`
- The 5,000-char note *should* return 400 with a proper Error schema response, not 500
- All status codes not explicitly listed are contract violations

---

# Test Suite Design

## 1. GET /orders/{id} Tests

### 1.1 Happy Path
- **GET /orders/1 with existing order** → 200, Order schema valid (id: integer, status: enum, total: number ≥ 0, note: string or omitted)
- **GET /orders/999 with non-existent id** → 404, Error schema with both `code` and `message` fields (not null)

### 1.2 Boundary & Invalid Input
- **GET /orders/0** → 400 or 404 (id minimum: 1)
- **GET /orders/-1** → 400 or 404 (id minimum: 1)
- **GET /orders/abc** → 400 (not an integer)
- **GET /orders/1.5** → 400 (not an integer)
- **GET /orders/999999999999999999999** → 400 or 404 (integer overflow)

### 1.3 Schema Compliance
- **Verify `total` is always a number, never a string**
- **Verify `note` field either is a string or absent, never null**
- **Verify `status` is only one of: `placed`, `paid`, `shipped`**
- **Verify no additional undocumented properties**

---

## 2. POST /orders Tests

### 2.1 Happy Path
- **POST with minimal valid order** `{items: ["sku-1"]}` → 201, Order schema valid
- **POST with items and note** `{items: ["sku-1", "sku-2"], note: "rush"}` → 201, Order schema valid

### 2.2 Invalid Input (400 Errors)
- **Missing `items` field** `{note: "test"}` → 400, Error with `code` and `message`
- **Empty items array** `{items: []}` → 400 (minItems: 1 violated)
- **Items is not an array** `{items: "sku-1"}` → 400
- **Item is not a string** `{items: [123, "sku-2"]}` → 400
- **Note exceeds 500 characters** `{items: ["sku-1"], note: "<5001 chars>"}` → 400, Error schema (not 500), with documented `code`

### 2.3 Boundary Tests
- **Note exactly 500 characters** → 201 (validate true boundary)
- **Note exactly 501 characters** → 400 (validate constraint)
- **Empty string note** `{items: ["sku-1"], note: ""}` → 201
- **Very large items array** `{items: [100 SKUs]}` → 201 or 400 if limit exists

---

## 3. Response Schema Validation Tests

### 3.1 All Responses
- **Verify content-type is `application/json`**
- **Verify no unexpected properties beyond schema**
- **Verify enum fields only use declared values**

### 3.2 Order Responses (200, 201)
- **`id`: integer, present, > 0**
- **`status`: one of `["placed", "paid", "shipped"]`**
- **`total`: number (not string), ≥ 0**
- **`note`: string if present, absent if null (not `null` literal)**

### 3.3 Error Responses (400, 404)
- **`code`: string, present, not null**
- **`message`: string, present, not null**
- **No `error` field (Response 2 violates schema by using `error` instead of `code`)**

---

## 4. HTTP Status & Headers
- **All 2xx responses include valid JSON body**
- **All 4xx responses include valid Error schema**
- **No 5xx errors for known invalid input** (Response 3 with long note should be 400)
- **Content-Type header is `application/json` for all**
