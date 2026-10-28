# API Contract Mismatches and Test Design

## Recorded Response Mismatches

### Response 1: GET /orders/1042 → 200

**Mismatch: Type violation**
- Field `total` is returned as string `"42.50"` but schema requires type `number`.

**Mismatch: Null handling**
- Field `note` is returned as `null`. The schema lists `note` as optional (not in `required`) but does not explicitly allow null. Assume the contract intends `nullable: true` for optional fields; if not, this is a violation.

---

### Response 2: GET /orders/999999 → 404

**Mismatch: Missing required field**
- Response `{"message": "Order not found"}` is missing the required `code` field. Error schema requires both `code` and `message`.

---

### Response 3: POST /orders with 5,000-character note → 500

**Mismatch: Wrong status code**
- Returns `500` but contract specifies only `201` (success) or `400` (invalid order). A 500 indicates an unhandled server error.

**Mismatch: Response does not match Error schema**
- Response uses `{"error": "..."}` but the `400` error response schema requires `{"code": "...", "message": "..."}`.

**Mismatch: Missing validation**
- The `note` field exceeds 500 characters (inferred from the error message). The contract does not declare a length limit on `note` in the NewOrder schema, but the API enforces one. Either the contract is incomplete or the API is over-validating.

---

## Test Design

### Happy-Path Tests

1. **GET existing order** — retrieve an order with a valid ID; verify 200, all required fields present, `total` is numeric.
2. **POST valid order** — create an order with required `items` array; verify 201, Order schema returned with auto-assigned `id`, `status`, `total`.

### Validation Tests

3. **GET with invalid ID format** — path parameter `id="abc"` or `id=0`; expect 400 or validation error (not 200).
4. **GET with ID below minimum** — `id=0`; expect error (schema says `minimum: 1`).
5. **POST missing items** — body `{"note": "..."}` without `items`; expect 400.
6. **POST empty items array** — body `{"items": []}` (violates `minItems: 1`); expect 400.
7. **POST note exceeds 500 chars** — add note validation limit (currently missing from schema); expect 400, not 500.
8. **POST with unknown fields** — body `{"items": [...], "unknown_field": "...}`; verify graceful handling (strip or reject).

### Error-Response Tests

9. **404 Error schema compliance** — GET non-existent order; verify 404 includes both `code` and `message` fields.
10. **400 Error schema compliance** — POST invalid order; verify 400 includes both `code` and `message` fields.

### Type and Schema Tests

11. **Response type correctness** — verify `total` is always numeric (not string).
12. **Null handling** — if `note` is optional, verify it is `null` or absent consistently; update contract to mark nullable if needed.
13. **Status enum values** — GET an order and verify `status` is one of `placed`, `paid`, `shipped`.

### Edge Cases

14. **Minimum valid ID** — `id=1`; expect success.
15. **Large ID** — `id=2147483647`; expect 404 or success depending on data.
16. **Single item in array** — POST with `items: ["single-sku"]`; expect 201.
17. **Large items array** — no limit in contract; POST with 1,000 items and verify handling.

### Contract Updates Recommended

- Declare `note` as nullable in Order schema or mark it with `maxLength: 500`.
- Specify error response `code` values (e.g., `NOT_FOUND`, `INVALID_REQUEST`) so tests can verify them.
- Clarify whether 400 or 422 is used for validation errors.
