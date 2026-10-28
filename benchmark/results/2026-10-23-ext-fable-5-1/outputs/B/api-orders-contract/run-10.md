# Contract mismatches

**Severity key:** P1 = breaks clients or leaks data, P2 = schema violation clients can tolerate, P3 = spec hygiene.

| # | Recording | Field / aspect | Contract says | Observed | Severity |
|---|---|---|---|---|---|
| 1a | GET /orders/1042 | `total` | `type: number` | JSON string `"42.50"` | P1 |
| 1b | GET /orders/1042 | `note` | `type: string`, not nullable | `null` | P2 |
| 2a | GET /orders/999999 | `code` | required in `Error` | absent | P2 |
| 3a | POST /orders | status code | only 201 and 400 documented | 500 | P1 |
| 3b | POST /orders | body shape | `Error` with `code` + `message` | `{"error": "..."}`, neither field present | P2 |
| 3c | POST /orders | body content | opaque error message | raw PostgreSQL error naming column type `character varying(500)` | P1 (information disclosure) |
| 3d | POST /orders | `note` length | no `maxLength`, so a 5,000-char note is a valid request | rejected by the database, not by validation | P1 (spec and implementation disagree) |

**Detail on each finding**

- **1a, total as string.** Typed clients generated from this spec will fail to deserialise or silently coerce. Likely cause is a decimal column serialised without casting. Either change the serialiser to emit a JSON number or change the spec to `type: string` with a decimal `pattern`. The second option is defensible for money, but it must be a deliberate decision, not an accident.
- **1b, note is null.** OpenAPI 3.0.3 does not allow `null` unless the property declares `nullable: true`. Fix one side: omit the key when there is no note, or add `nullable: true` to `Order.note`.
- **2a, missing error code.** The 404 body carries only `message`. Clients that branch on `code` cannot distinguish "not found" from other errors. Add a stable code such as `ORDER_NOT_FOUND`.
- **3a to 3d, oversized note.** The request is valid under the published contract, so the only contract-conforming outcomes are 201 or a 400 with a documented reason. The handler lets the input reach the database, the database rejects it, and the unhandled exception becomes a 500 that exposes schema internals. Three things must change: add `maxLength: 500` to `NewOrder.note`, validate it in the handler and return a 400 `Error`, and add a global exception handler that never echoes driver messages.

# Assumptions and spec gaps

- **Assumed** every recorded response was `Content-Type: application/json`. The recordings do not include headers, so header checks are listed in the test plan but could not be verified.
- **Assumed** the 500 did not persist a partial order. This is unverified and is called out as a test below, because a half-written order would be a data-integrity bug on top of the contract bug.
- **Assumed** no authentication. The spec declares no `securitySchemes`. If staging actually requires a token, the spec is missing it and that is another mismatch.
- **Gap:** GET /orders/{id} documents no 400 even though `id` has `minimum: 1`. Requests like `/orders/0` or `/orders/abc` have no contracted outcome.
- **Gap:** POST /orders documents no 415 for a wrong `Content-Type` and no 405 for unsupported methods.
- **Gap:** `NewOrder.items` has `minItems: 1` but no `maxItems`, no `minLength` on each SKU, and no uniqueness rule, so the same unbounded-input class of bug as 3d is possible on `items`.
- **Gap:** `Order` carries no `items` property, so a client cannot read back what it ordered. Probably an omission in the spec rather than a bug.

# Test plan

Each test names the expected result under the corrected contract described above. Tests marked **currently failing** reproduce a finding from the recordings.

**Contract conformance, run on every response**
- Validate every response body against the referenced schema with a strict validator that rejects unknown types and `null` on non-nullable fields. Covers 1a, 1b, 2a, 3b. **Currently failing.**
- Assert `Content-Type: application/json` on all responses.
- Assert that no response uses a status code absent from the spec for that operation. Covers 3a. **Currently failing.**

**GET /orders/{id}**
- Existing order returns 200. `id` is an integer, `status` is one of the three enum values, `total` is a JSON number. **Currently failing on total.**
- Order with no note omits the key or returns a declared-nullable null, per whichever fix is chosen. **Currently failing.**
- Order with a note returns it as a string, round-tripping the value given at creation.
- One order per status value, confirming no undocumented status such as `cancelled` leaks through.
- Unknown id returns 404 with both `code` and `message`. **Currently failing on code.**
- Boundary ids: `0`, `-1`, `abc`, `1.5`, `1e3`, a 20-digit value above int64, and an empty segment. Expected 400 with an `Error` body once the spec documents it. Record the actual behaviour now as a baseline.
- Id with a trailing path segment or query string, to confirm routing is strict.

**POST /orders, happy path**
- Minimal body with one item returns 201. Response validates as `Order`, `status` is `placed`, `id` is a positive integer, and a follow-up GET returns the same resource.
- Body with a note at exactly 500 characters returns 201 and the note is stored unmodified.
- Multi-byte note near the limit, since `character varying(500)` counts characters and the validator must count the same way, not bytes.
- Several items, confirming `total` reflects all of them.

**POST /orders, validation**
- Note of 501 characters returns 400 with an `Error` body, not 500. **Currently failing.**
- Note of 5,000 characters returns 400, and the response never contains the strings `character varying`, `psql`, `SQL`, or a stack trace. **Currently failing.**
- After the oversized-note rejection, no new order row exists. Checks the partial-write assumption.
- Missing `items`, empty `items`, `items` that is not an array, item that is not a string, item that is an empty string. All 400.
- Unknown SKU in `items`. Record actual behaviour. The spec is silent, so this is a product question to raise.
- Missing body, empty body, malformed JSON, `note` that is a number. All 400.
- Wrong `Content-Type`, such as `text/plain` with a JSON body. Expected 415 once documented.
- Duplicate SKUs in `items`, to pin down whether they are merged or rejected.
- Unknown extra top-level property, to pin down whether the API is strict or lenient.

**Robustness and security**
- Very large `items` array, such as 10,000 entries, to confirm there is a bound and it fails with 400 or 413, never 500.
- Note containing SQL metacharacters, HTML, and control characters. Expect 201 and an unmodified round-trip, confirming parameterised queries and no stripping.
- Fuzz the two endpoints with random JSON for a fixed budget, asserting that no response is a 5xx and no body contains database vocabulary.
- Sequential ids are exposed, so test that `/orders/1041` and `/orders/1043` do not reveal another tenant's data if the API is multi-tenant. If it is single-tenant, document that assumption.

**Regression gate**
- Add the three recorded requests as fixed regression cases with the corrected expected responses. They should block deployment until 1a, 1b, 2a, 3a, 3b, 3c and 3d are fixed.
