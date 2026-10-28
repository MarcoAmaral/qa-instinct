**Verdict:** all three recorded responses violate the 2.1.0 contract. Recording 3 is a server defect that also leaks database internals. Recordings 1 and 2 are schema violations that will break strictly typed clients and generated SDKs.

**Assumptions**
- The recordings omit headers, so Content-Type and other headers are unverified and assumed to be `application/json`.
- The contract is the source of truth. Where implementation and spec disagree, the implementation is wrong, unless the spec is clearly incomplete, which is called out as a gap.
- The error text in recording 3 names a Postgres `varchar(500)` column, so the intended note limit is taken to be 500 characters.
- No security scheme is declared, so the endpoints are assumed unauthenticated on staging.
- It is unknown whether the request in recording 3 persisted an order before failing. This is treated as open.

## Findings

| ID | Recording | Observed | Contract says | Severity |
|----|-----------|----------|---------------|----------|
| F1 | 1, `total` | `"42.50"` (string) | `type: number` | High |
| F2 | 1, `note` | `null` | `type: string`, not nullable | Medium |
| F3 | 2, body | `code` missing | `Error` requires `code` and `message` | Medium |
| F4 | 3, status | `500` | Only `201` and `400` are documented | High |
| F5 | 3, body | `{"error": ...}` with raw DB message | `Error` schema; no internal details | High |
| F6 | 3, cause | 5,000-char note reaches the database | `NewOrder.note` has no `maxLength` | Medium (spec gap) |

- **F1.** OpenAPI 3.0.3 `number` means a JSON number. A quoted decimal fails validation in any strict client and silently produces string arithmetic in loose ones. If the string was chosen to avoid float rounding, that is a legitimate design, but then the schema must change to `type: string` with a decimal pattern. Either the code or the spec is wrong today. Both cannot stand.
- **F2.** In 3.0.3 a property only accepts `null` when it carries `nullable: true`. The server must either omit `note` when there is none, or the spec must add `nullable: true`. Omitting is cleaner for clients.
- **F3.** The 404 body is missing a required field. Clients that branch on `code` cannot distinguish "not found" from other 4xx errors. The spec also never defines what codes exist, which is a related gap below.
- **F4.** An input that the server can reject deterministically must produce `400`, not `500`. Input length is validation, not a fault. This will also page on-call for every long note.
- **F5.** The body exposes the storage engine and column width. That is information disclosure and should be treated as a security finding. The body also uses a different shape (`error`) from every other error, so clients cannot parse it.
- **F6.** The bug exists because the contract never states a limit. Adding `maxLength: 500` to `note` is the fix on the spec side. The server must enforce it before the database does.

**Open question raised by recording 3.** If the insert failed after any side effect (reserved stock, emitted event, allocated id), the system is in an inconsistent state. Test P5 below checks this.

## Contract gaps to close regardless of the findings

- `GET /orders/{id}` documents no response for an id that fails the path schema (`0`, `-1`, `abc`, `1.5`). Decide on `400` or `404` and document it.
- `NewOrder.note` needs `maxLength: 500`. `NewOrder.items` needs `maxItems`, a per-item `maxLength`, and a decision on `uniqueItems`.
- Behaviour for an unknown SKU is undefined. Assumed `400`.
- `Error.code` has no enumerated values, so clients cannot program against it.
- `Order` has no `items` property, so the `201` response cannot echo what was ordered. Assumed intentional, but confirm.
- `Order.total` has no `minimum` and no precision rule. If string-decimal is intended, say so with `format`.
- No `405`, `415`, `401`, or `403` responses are documented. Assumed unauthenticated, but `405` and `415` still need defining.
- `additionalProperties` is unrestricted everywhere, so extra request fields are silently allowed. Decide whether that is wanted.

## Test plan

**Approach.** Every test runs through a response validator bound to the spec (for example `openapi-core`, `ajv` with the dereferenced schema, or Schemathesis), so status, Content-Type, and body schema are asserted on every call without repeating that in each row. Schemathesis fuzzing runs in CI as a separate job to catch any 5xx from schema-invalid input. The three recordings become explicit regression tests (G3, P4, P5, F1 via G1).

**GET /orders/{id}**

| ID | Request | Expected |
|----|---------|----------|
| G1 | Existing id with a note | `200`; `id` integer, `status` in enum, `total` is a JSON number, `note` is a string. Regression for F1. |
| G2 | Existing id with no note | `200`; `note` absent (or `null` only once spec says `nullable: true`). Regression for F2. |
| G3 | Non-existent id | `404`; `Error` with both `code` and `message`. Regression for F3. |
| G4 | `id = 0` | Documented 4xx, never `500` |
| G5 | `id = -1` | Same as G4 |
| G6 | `id = abc` | Same as G4 |
| G7 | `id = 1.5` | Same as G4 |
| G8 | `id = 99999999999999999999` (overflows int64) | Documented 4xx, never `500` |
| G9 | `id = 0042`, `id = %31` (URL-encoded), trailing whitespace | Consistent, documented handling |
| G10 | One fixture per enum value: `placed`, `paid`, `shipped` | Each returned verbatim; any internal status such as `cancelled` must not leak |
| G11 | Orders with totals `0`, `0.1`, `1234567.89` | Numeric, correct precision, no float drift |
| G12 | Wrong method: `PUT`, `DELETE`, `POST /orders/1` | `405`, never `500` |

**POST /orders**

| ID | Request body | Expected |
|----|--------------|----------|
| P1 | `{"items":["sku-1"]}` | `201`; `Order` with `id >= 1`, `status` is `placed` (assumed initial state), `note` absent. A following `GET` returns the same order. |
| P2 | Note of 1 character | `201`, note echoed verbatim |
| P3 | Note of exactly 500 characters | `201`. Boundary. |
| P4 | Note of 501 characters | `400`; `Error` body. Regression for F4 and F5. |
| P5 | Note of 5,000 characters | `400`; then verify no order row, no event, no id consumed. Regression for recording 3 and the side-effect question. |
| P6 | Note of 500 multibyte characters (CJK, emoji) | `201`. Verifies the limit is characters, not bytes. |
| P7 | Note `""` | Documented behaviour, either `201` with empty note or `400`. Pin it. |
| P8 | Note `null` | `400` or treated as absent. Pin it and document. |
| P9 | Note of type number, object, array | `400` |
| P10 | Note containing control characters, `'; DROP TABLE`, `<script>` | Stored and returned verbatim, correctly JSON-escaped, never `500` |
| P11 | `items` missing | `400` |
| P12 | `items: []` | `400` |
| P13 | `items: "sku-1"` (not an array) | `400` |
| P14 | `items: [1]` (non-string element) | `400` |
| P15 | `items: [""]` | `400` (assumed) |
| P16 | `items: ["does-not-exist"]` | `400` with a distinguishable `code` (assumed) |
| P17 | `items: ["sku-1","sku-1"]` | Documented behaviour, either merged or two lines. Pin it. |
| P18 | 1,000 items | `201` or documented `400`, never `500` |
| P19 | One item string of 5,000 characters | `400`, never `500`. Same bug class as recording 3. |
| P20 | Extra unknown field `{"items":["sku-1"],"foo":1}` | Consistent: ignored or `400`. Pin it. |
| P21 | Empty body | `400` |
| P22 | Malformed JSON `{"items":[` | `400`; `Error` body, never `500` |
| P23 | Body is a JSON array `[]` | `400` |
| P24 | `Content-Type: text/plain` with a JSON body | `415` or `400`, never `500` |
| P25 | `total` correctness against a price fixture | `total` equals the sum of item prices |
| P26 | Same valid body sent twice | Two distinct orders (assumed, no idempotency key defined). Document. |
| P27 | 50 concurrent valid posts | 50 unique ids, all retrievable |

**Cross-cutting**

| ID | Check | Expected |
|----|-------|----------|
| X1 | Every non-2xx body across all tests | Matches `Error`; never contains `character varying`, `SQLSTATE`, `Traceback`, `Exception`, or a stack frame |
| X2 | Every response, including errors | `Content-Type: application/json` |
| X3 | Schemathesis run with all checks against the spec | Zero 5xx, zero schema violations |
| X4 | Response time with a 500-char note and 1,000 items | Within the service's baseline, no timeout |
| X5 | Spec lint (Spectral or equivalent) in CI | Fails the build if `maxLength`, `nullable`, and the 4xx responses above are missing |

**Suggested fix order**
1. F4 and F5 together: validate `note` length before the database and return the `Error` shape. Add a global handler so no raw exception text ever reaches a response.
2. F1: decide number versus decimal string, then align code and spec.
3. F3: add `code` to every error path and enumerate the codes in the spec.
4. F2 and the contract gaps: update the spec, then run X3 and X5 to confirm the implementation matches.

**Exit criteria.** All tests above pass against staging. Schemathesis reports no 5xx and no schema violations. The three original recordings, replayed, now return `200` with a numeric total, `404` with a `code`, and `400` with an `Error` body respectively.
