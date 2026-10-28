# API Contract Mismatches

## Response 1: GET /orders/1042 → 200

**Mismatch:** `total` is returned as a string `"42.50"` but the schema defines it as `type: number`.

---

## Response 2: GET /orders/999999 → 404

**Mismatch:** Error response missing required `code` field. The schema requires both `code` and `message`; response contains only `message`.

---

## Response 3: POST /orders → 500

**Mismatches:**
1. Response code is `500`, but the contract only defines `201` and `400`.
2. Error body has an `error` field instead of the required `code` and `message` fields.

**Additional finding:** The error message reveals that `note` has a 500-character database limit not documented in the OpenAPI schema (NewOrder defines `note` as unbounded `type: string`).

---

# Recommended Test Coverage

## Contract Compliance Tests

| Test | Purpose |
| --- | --- |
| GET /orders/{id} returns Order with `total` as number | Catch the type mismatch in response 1 |
| GET /orders/{id} returns Error with both `code` and `message` fields | Catch missing `code` field on 404 |
| POST /orders succeeds with valid NewOrder | Establish baseline for 201 response |
| POST /orders returns Order with all required fields | Verify response schema compliance |
| POST /orders with empty `items` array returns 400 with Error schema | Test minItems validation |
| POST /orders with `items` omitted returns 400 with Error schema | Test required field validation |
| POST /orders with `note` = 501 characters returns 400, not 500 | Catch unhandled validation error |
| All Error responses include both `code` and `message` | Ensure consistent error format |

## Boundary & Input Validation Tests

| Test | Purpose |
| --- | --- |
| GET /orders/0 returns 400 or 404 (id minimum: 1) | Test parameter validation |
| GET /orders/abc returns 400 | Test non-integer id |
| GET /orders/{very-large-id} returns 404 | Test integer bounds |
| POST /orders with non-array `items` returns 400 | Test type validation |
| POST /orders with `items: [""]` succeeds or returns 400 | Clarify item format requirements |
| POST /orders with `note` = exactly 500 characters succeeds | Boundary test for note limit |
| POST /orders with `note` = 501 characters returns 400 | Boundary test just over limit |

## Response Validation Tests

| Test | Purpose |
| --- | --- |
| Order.status is one of: "placed", "paid", "shipped" | Validate enum compliance |
| Order.id is a positive integer | Type check |
| Order.total is a number (not string) | Catch the type mismatch in response 1 |
| Order.note can be null or a string, never missing | Test optional field handling |
| Error.code is non-empty string | Baseline error format |
| Error.message is non-empty string | Baseline error format |

## Assumptions

- **`note` max length:** Assumed 500 characters based on database error in response 3; should be documented in schema.
- **404 vs. 400 for invalid id:** Assumed 404 is correct for numeric id that exists nowhere; no test case for malformed id provided.
- **POST /orders success case:** No successful POST response recorded; tests assume a 201 response with an Order object including a generated `id`.
