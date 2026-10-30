# API Response Contract Mismatches & Test Specification

## Mismatches Found

### Response 1: GET /orders/1042 → 200

| Issue | Recorded | Spec requires | Severity |
|-------|----------|---|---|
| `total` type | String `"42.50"` | Number `42.50` | High |
| `note` value | `null` | String or absent (schema undefined for null) | Medium |

### Response 2: GET /orders/999999 → 404

| Issue | Recorded | Spec requires | Severity |
|-------|----------|---|---|
| Missing `code` field | Not present | Required string field | High |
| Response body | `{"message": "..."}` | `{"code": "...", "message": "..."}` | High |

### Response 3: POST /orders → 500

| Issue | Recorded | Spec requires | Severity |
|-------|----------|---|---|
| HTTP status | `500` | `201` or `400` (500 not defined) | High |
| Response schema | `{"error": "..."}` | Error schema: `{"code": "...", "message": "..."}` | High |
| Missing constraint | `note` silently limited to ~500 chars in DB | Spec defines no `maxLength` | High |
| Missing validation | 5000-char note causes 500, not 400 | Should return 400 for invalid input | High |

---

## Assumptions

- `null` values in optional fields are not allowed by the spec (schema shows type without `nullable: true`); Error schema treats `note` as required in response, though not in request.
- The 500 error is a data validation bug, not an intended response type.
- The `note` field has an undocumented 500-character database limit.

---

## Test Specification

### Unit Tests: Schema Compliance

1. **GET /orders/{id} — success (200)**
   - Assert response matches Order schema exactly
   - Assert `total` is type number, not string
   - Assert `note` is string when present; clarify spec re: null values
   - Test with valid id (e.g., 1042)

2. **GET /orders/{id} — not found (404)**
   - Assert response has both `code` and `message` fields
   - Assert both fields are non-empty strings
   - Test with non-existent id (e.g., 999999)

3. **GET /orders/{id} — invalid input**
   - Assert 400 response for non-integer id
   - Assert 400 response for id < 1
   - Assert error response has `code` and `message`

4. **POST /orders — success (201)**
   - Assert response matches Order schema
   - Assert `total` is type number
   - Assert `id` is present
   - Assert `status` is one of: placed, paid, shipped
   - Test with valid NewOrder (items array with 1+ items)

5. **POST /orders — invalid input (400)**
   - Assert 400 for empty items array
   - Assert 400 for missing items field
   - Assert 400 for note exceeding documented max length (currently 500 chars; spec should define it)
   - Assert response has `code` and `message` fields

6. **POST /orders — type validation**
   - Assert 400 for non-array items
   - Assert 400 for non-string array items
   - Assert 400 for non-string note

### Integration Tests

7. **Happy path:** Create order, retrieve it, verify all fields match
8. **Boundary: note field**
   - Test note at max allowed length → 201
   - Test note over max length → 400 (not 500)
9. **Boundary: items array**
   - Test minItems: 1 (zero items → 400)
   - Test multiple items in one order

### Contract Tests

10. **Response headers:** Assert `Content-Type: application/json`
11. **Status codes:** Assert only 200, 201, 400, 404 are returned (no 500 in happy/error paths)
12. **Error format consistency:** All 4xx responses use Error schema with `code` and `message`

---

## Fix Priority

1. **Critical:** Return 400 (not 500) when `note` exceeds length limit; include `code` field in error
2. **High:** Fix total field to serialize as number, not string
3. **High:** Add `code` field to 404 error responses
4. **Medium:** Clarify in spec whether `note` allows `null` in GET responses, and define max length
5. **Medium:** Add constraint validation tests to CI/CD pipeline
