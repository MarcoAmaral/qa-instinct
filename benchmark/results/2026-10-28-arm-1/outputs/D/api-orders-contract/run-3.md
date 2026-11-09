# Conformance Report: Orders API v2.1.0

## Contract
- **Source**: OpenAPI 3.0.3 document provided
- **Version**: 2.1.0
- **Deployed version confirmed**: 2.1.0 (staging, 2026-10-15)
- **Auth model**: None
- **Base URL**: Not specified (assumption: requests sent to staging environment)

---

## Conformance Mismatches

### Finding 1: Type mismatch in `Order.total`
| Aspect | Detail |
|--------|--------|
| **Request** | GET /orders/1042 |
| **Response status** | 200 |
| **Schema location** | `#/components/schemas/Order.total` |
| **Declared type** | `number` |
| **Actual value** | `"42.50"` (string) |
| **Full response** | `{"id": 1042, "status": "paid", "total": "42.50", "note": null}` |
| **Classification** | Software defect |
| **Proposed owner** | Backend (serialization layer) |

### Finding 2: Null value for typed optional field
| Aspect | Detail |
|--------|--------|
| **Request** | GET /orders/1042 |
| **Response status** | 200 |
| **Schema location** | `#/components/schemas/Order.note` |
| **Declared type** | `string` (optional) |
| **Actual value** | `null` |
| **Full response** | `{"id": 1042, "status": "paid", "total": "42.50", "note": null}` |
| **Classification** | Software defect |
| **Proposed owner** | Backend (field serialization inconsistency) |
| **Note** | Schema allows omission but specifies `type: string` if present; `null` violates this contract. |

### Finding 3: Missing required field in Error response
| Aspect | Detail |
|--------|--------|
| **Request** | GET /orders/999999 |
| **Response status** | 404 |
| **Schema location** | `#/components/schemas/Error` (required: `code`, `message`) |
| **Declared schema** | `{code: string, message: string}` |
| **Actual value** | `{"message": "Order not found"}` |
| **Missing field** | `code` |
| **Classification** | Software defect |
| **Proposed owner** | Backend (error response builder) |

### Finding 4: Undocumented HTTP status and malformed error body
| Aspect | Detail |
|--------|--------|
| **Request** | POST /orders with body `{"items": ["sku-1"], "note": "<5000-char string>"}` |
| **Response status** | 500 (Undocumented) |
| **Declared statuses** | 201 (Created), 400 (Invalid order) |
| **Declared error schema** | `#/components/schemas/Error` (requires: `code`, `message`) |
| **Actual response** | `{"error": "value too long for type character varying(500)"}` |
| **Violations** | (1) Status 500 not in schema; (2) Error body has `error` field instead of `code`+`message`; (3) Validation error (note field length) should return 400, not 500 |
| **Classification** | Software defect |
| **Proposed owner** | Backend (validation layer, error handling) |
| **Note** | Indicates missing schema constraint: `NewOrder.note` has no declared `maxLength`. The actual limit (500 chars) should be documented. |

---

## Test Design: Orders API

### Endpoint: `GET /orders/{id}`

#### Test Cases by Field Partition

**id parameter (path):**
- Valid partitions: `1` (minimum), `1042` (typical), large valid integer
- Invalid partitions: `0` (below minimum), `-1`, `abc` (non-integer), `1.5` (float), missing
- Boundaries: minimum `1` per schema; probe for upper bound (integer max or API-specific limit)

**Response body (status 200):**
- Happy path: all required fields (`id`, `status`, `total`) present and correctly typed
- `id`: matches request parameter
- `status`: one of `[placed, paid, shipped]`; test each value
- `total`: positive number; test zero and negative (if API allows)
- `note`: optional; test present (string), absent, null (currently fails; is a defect)

**Error responses (status 404):**
- Non-existent id (e.g., 999999): verify Error schema with `code` and `message` (currently fails; missing `code`)
- Probe for other error statuses not documented (e.g., 400 for invalid id format if type coercion fails)

#### Acceptance Criteria
1. GET /orders/1042 returns 200 with Order schema fully conforming to declared types and required fields
2. GET /orders/999999 returns 404 with Error schema containing both `code` and `message` fields
3. GET /orders/{id} rejects id values below 1 (if client-side type checking) or returns documented error status
4. No undocumented response statuses

---

### Endpoint: `POST /orders`

#### Test Cases by Field Partition

**Request body: items (array, required, minItems: 1):**
- Valid partitions: `["sku-1"]` (single item), `["sku-1", "sku-2"]` (multiple)
- Invalid partitions: `[]` (empty, violates minItems), `null`, missing, not an array, non-string items (e.g., numbers)
- Boundaries: test boundary at minItems=1

**Request body: note (string, optional):**
- Valid partitions: omitted, `""` (empty string), normal string, (string under 500 chars if checking)
- Invalid partitions: `null`, non-string type (number, object)
- Boundaries: schema declares no maxLength, but API fails at 5000 chars with 500-char limit and status 500 (defect). Test with 500 and 501 char strings once schema is corrected.

**Response body (status 201):**
- Happy path: Order schema fully conforming (id assigned, status='placed' or default, total calculated, note optional)
- Verify `id` is unique and increments or follows server logic
- Verify `status` is a valid enum value
- Verify `total` is calculated correctly from items

**Error responses:**
- Invalid request (status 400): missing items, empty items, invalid types; verify Error schema with `code` and `message`
- Oversized note (status 400, not 500): once schema constraint is documented and backend corrected, verify error message

#### Acceptance Criteria
1. POST /orders with valid NewOrder returns 201 with complete Order schema
2. POST /orders with empty items array returns 400 with Error schema
3. POST /orders with missing items field returns 400 with Error schema
4. POST /orders with note string ≥501 chars returns 400 with Error schema (currently returns 500; is defect)
5. All error responses contain `code` and `message` fields

---

## Schema Gaps and Assumptions

| Gap | Assumption | Impact |
|-----|-----------|--------|
| `Order.id` type and generation logic | Auto-assigned by server, positive integer | Tests assume id is returned and stable |
| `Order.status` initial value | 'placed' on creation | Happy-path design assumes this; verify with team |
| `Order.total` calculation | Computed from items (not documented) | Cannot test calculation accuracy without domain knowledge |
| `NewOrder.note` maxLength | No schema constraint; API enforces ~500 chars | Constraint should be added to schema; currently causes unhandled 500 error |
| 404 vs 400 boundary | Path parameter validation strategy unclear | Assumption: invalid format returns 400; non-existent id returns 404 |
| Pagination/listing | GET /orders not documented | Scope: only documented endpoints tested |

---

## Contract Strategy Recommendation

**Schema conformance checks (step 3) are sufficient for this API.** The schema is simple, covers two endpoints, and no consumer-driven contract is justified. The API is controlled by one team and tested in a shared staging environment. Adopt schema validation in CI to catch type mismatches (like total as string) before they reach clients. Run the schema validator on every response in the test suite (using a JSON Schema validator library) and fail fast on violations. This is cheaper than consumer-driven contracts and catches the defects found here automatically.

Once the four defects are resolved (type corrections, error schema compliance, status code 500→400, schema constraint on note), schema conformance tests will be stable and sufficient.
