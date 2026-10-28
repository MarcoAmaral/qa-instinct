# Orders API 2.1.0: conformance report and test design

**Scope and sources.** Contract: the OpenAPI 3.0.3 document pasted in the request (title Orders API, version 2.1.0). Deployed build: 2.1.0 on staging, as stated in the recording of 2026-10-15. I did not confirm it from a deployment record or version endpoint, and I sent no requests. Every claim about live behaviour below rests on the three recorded responses, so each is dated 2026-10-15. Auth model: the contract declares no `securitySchemes`, so the assumption is no authentication, flagged wherever it matters. Base URL: not given. Rules applied: context-discovery, testing-guidelines, code-style-qa, security-qa, test-tools, test-evidence (all found in `.claude/rules`). The evidence checker was not run because no specs exist yet.

## 1. Conformance of the recorded responses

| # | Request | Declared (schema location) | Actual (2026-10-15) | Mismatch | Classification | Proposed owner |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | GET /orders/1042 → 200 | `Order.total: number` | `"total": "42.50"` (string) | Wrong JSON type | **Software defect** (provisional). If decimal-as-string is a deliberate money choice, reclassify as documentation drift and change the schema to `type: string` with a pattern. The API owner decides; the test is not relaxed until then. | API team |
| M2 | GET /orders/1042 → 200 | `Order.note: string`, not nullable (OpenAPI 3.0.3 needs `nullable: true`) | `"note": null` | `null` is not a valid string | **Documentation drift** (likely): either add `nullable: true` or omit the field when empty. Confirm with the API team which one was intended. | Doc owner |
| M3 | GET /orders/999999 → 404 | `Error` requires `code` and `message` | `{"message": "Order not found"}` | Required `code` missing | **Software defect**: the documented error contract is not met, so clients cannot branch on an error code. | API team |
| M4 | POST /orders, note of 5,000 chars → 500 | Only `201` and `400` documented; `400` body is `Error` | `500`, body `{"error": "value too long for type character varying(500)"}` | Undocumented status; body matches no schema; database internals leaked to the client | **Software defect**: input exceeding the storage limit must be rejected with `400` and an `Error` body. The leaked column type is also a security-hygiene finding (information disclosure, per the security-qa rule). | API team |
| M5 | Same as M4 | `NewOrder.note` declares no `maxLength` | The database limit is 500 characters | Undeclared boundary | **Documentation drift**: add `maxLength: 500` to `NewOrder.note` and to `Order.note`. The limit is inferred from the error text, not probed; the 500/501 boundary pair has not been run. | Doc owner |

Open question from M4, not a mismatch yet: whether an order row was created before the failure. The contract has no list or delete endpoint, so this cannot be checked through the API. Assumption: the write was rolled back. Test TC-ORD-027 below records what actually happens.

**Two error shapes were observed** (`{message}` and `{error}`) and neither is the declared one. Clients coded to the contract will fail on both.

**What the schema does not say, and the recording confirms or leaves open:**

- No `securitySchemes`, no `401` or `403`. Either the API is public or auth is undocumented.
- No status for an invalid path parameter (`/orders/0`, `/orders/abc`). The `minimum: 1` constraint has no documented failure response.
- No `405`, `415`, `422` or `429`, and no `500`, although one was observed.
- No `maxLength` on `note`, no `maxItems` on `items`, no `minLength` or `pattern` on the SKU strings.
- `Order` has no `items` property, so a created order's response cannot echo what was ordered. Possibly intended, worth a question to the owner.
- `additionalProperties` is unset on every schema, so extra response fields pass validation by default. The 200 body had none.
- `total` is a number with no `minimum` and no statement of how it is derived from SKU strings. Assumption: the server prices items from a catalogue.
- The `status` enum (placed, paid, shipped) has no transitions in this contract. Assumption: payment and fulfilment systems move orders forward.

## 2. Test design

Acceptance criteria are derived from the contract because none were supplied:

- **AC-1** GET an existing order returns `200` with an `Order` body.
- **AC-2** GET an unknown order returns `404` with an `Error` body.
- **AC-3** POST a valid `NewOrder` returns `201` with an `Order` body for the new order.
- **AC-4** POST an invalid `NewOrder` returns `400` with an `Error` body.
- **AC-5** (implied) No request produces an undocumented status or a body outside the declared schemas.

Every case asserts the status **and** validates the body against the schema declared for that status. Tags follow the testing-guidelines taxonomy; all cases are `@api`.

### 2.1 GET /orders/{id}

**Partitions and boundaries for `id`** (EP §4.2.1, BVA 2-value §4.2.2; the only declared boundary is `minimum: 1`):

| Partition | Values | Expected |
| --- | --- | --- |
| Valid, exists | a seeded id such as 1042; an id created in the same test | `200`, `Order` |
| Valid, does not exist | 999999 | `404`, `Error` |
| Below minimum | 0 (min-1), -1 | Undocumented. A `4xx` with an `Error` body; record which |
| Minimum | 1 | `200` or `404`, each with its declared body |
| Not an integer | `abc`, `1.5`, `1e3`, `0042`, empty segment | Undocumented. `4xx` with `Error`, never `500` |
| Overflow | 2147483648, 9223372036854775808 | Undocumented. `4xx` with `Error`, never `500` |

| ID | Case | AC | Technique | Tags |
| --- | --- | --- | --- | --- |
| TC-ORD-001 | Existing id → `200`; body validates as `Order`; `id` equals the requested id; `status` in enum; `total` is a JSON number | AC-1 | EP | `@smoke @api @p0 @candidate` |
| TC-ORD-002 | Unknown id → `404`; body validates as `Error` with `code` and `message` | AC-2 | EP | `@smoke @api @p1 @candidate` |
| TC-ORD-003 | id = 0 → `4xx` with `Error`; status recorded as observed | AC-5 | BVA | `@regression @api @p2 @candidate` |
| TC-ORD-004 | id = 1 → `200` or `404`, body matches the status | AC-1/2 | BVA | `@regression @api @p2 @candidate` |
| TC-ORD-005 | Each non-integer id → `4xx` with `Error`, never `500` | AC-5 | EP, error guessing | `@regression @api @p2 @candidate` |
| TC-ORD-006 | Overflow ids → `4xx` with `Error`, never `500` | AC-5 | BVA | `@regression @api @p2 @candidate` |
| TC-ORD-007 | Order created with a note → GET echoes `note` as a string (positive half of M2) | AC-1 | EP | `@regression @api @p2 @candidate` |
| TC-ORD-008 | Order created without a note → `note` absent or null, per the owner's decision on M2 | AC-1 | EP | `@regression @api @p3 @deferred` until M2 is decided |
| TC-ORD-009 | One seeded order per enum value (placed, paid, shipped) → each validates | AC-1 | EP on `status` | `@regression @api @p2 @candidate`; needs seeded fixtures for paid and shipped |
| TC-ORD-010 | Response `Content-Type` is `application/json` on `200` and `404` | AC-5 | Checklist | `@regression @api @p3 @candidate` |

TC-ORD-001 **will fail on staging today** because of M1 and M2. It stays red until the owner decides; it is not loosened.

### 2.2 POST /orders

**Partitions and boundaries per field:**

| Field | Partition | Values | Expected |
| --- | --- | --- | --- |
| `items` | Valid | `["sku-1"]`; 2 items; 50 items | `201`, `Order` |
| `items` | Below `minItems` | `[]` | `400`, `Error` |
| `items` | Missing, null | key absent; `null` | `400`, `Error` |
| `items` | Wrong type | `"sku-1"`, `{}`, `1` | `400`, `Error` |
| `items` | Element not a string | `[1]`, `[null]`, `[{}]` | `400`, `Error` |
| `items` | Undeclared limits | `[""]`; 1,000 items; duplicate SKUs; unknown SKU `"no-such-sku"` | Undocumented. Record `201` or `400`; never `500` |
| `note` | Valid | absent; `""`; 1 char; 499; **500** (max) | `201` |
| `note` | Over the undeclared limit | **501** (max+1); 5,000 | `400`, `Error` (observed `500`, M4) |
| `note` | Wrong type | `1`, `{}`, `[]`, `null` | `400`, `Error` (`null` is undocumented; record) |
| Body | Malformed | invalid JSON; empty body; a JSON array; `Content-Type: text/plain` | `400` with `Error`; `415` for the wrong media type is undocumented, record |
| Body | Extra field | `{"items":["sku-1"],"foo":1}` | Undocumented. `additionalProperties` unset, so expect `201` with the field ignored; record |

| ID | Case | AC | Technique | Tags |
| --- | --- | --- | --- | --- |
| TC-ORD-020 | One item, no note → `201`; body validates as `Order`; `id` integer ≥ 1; `status` is `placed` (assumption); `total` is a number; a GET on the new id returns the same body | AC-3 | EP | `@smoke @api @p0 @candidate` |
| TC-ORD-021 | Note of exactly 500 characters → `201`; GET echoes it unchanged | AC-3 | BVA max | `@regression @api @p1 @candidate` |
| TC-ORD-022 | Note of 501 characters → `400` with `Error`, not `500` | AC-4 | BVA max+1 | `@regression @api @p1 @candidate`; regression for M4 |
| TC-ORD-023 | Note of 5,000 characters → `400` with `Error`; body contains no database or stack text | AC-4 | EP, security checklist | `@regression @api @p1 @candidate`; reproduces M4 |
| TC-ORD-024 | `items: []` → `400` with `Error` | AC-4 | BVA minItems-1 | `@smoke @api @p1 @candidate` |
| TC-ORD-025 | `items` missing, null, wrong type, element not a string (one case each) → `400` with `Error` | AC-4 | EP | `@regression @api @p1 @candidate` |
| TC-ORD-026 | `note` of each wrong type → `400` with `Error`; `null` recorded | AC-4 | EP | `@regression @api @p2 @candidate` |
| TC-ORD-027 | After a rejected POST (TC-ORD-022 or 023), no order was created. Oracle: the next successful POST's id is the previous max + 1, or a count from a database query the team grants. Mark the oracle as an assumption | AC-4 | Error guessing | `@regression @api @p2 @candidate` |
| TC-ORD-028 | Malformed JSON, empty body, JSON array → `400` with `Error` | AC-4 | EP | `@regression @api @p2 @candidate` |
| TC-ORD-029 | Wrong `Content-Type` → status recorded; body is `Error` if `4xx` | AC-5 | Error guessing | `@regression @api @p3 @candidate` |
| TC-ORD-030 | Extra field, unknown SKU, duplicate SKUs, empty-string SKU, 1,000 items (one case each) → status recorded, never `500`, body matches the status | AC-5 | Error guessing | `@regression @api @p2 @candidate` |
| TC-ORD-031 | Identical body sent twice → two distinct ids (the contract promises no idempotency); if an `Idempotency-Key` header is honoured, the second call returns the first order | AC-3 | Idempotency | `@regression @api @p2 @candidate` |

### 2.3 Resource state model (§4.2.4, all-transitions criterion)

States: **Absent**, **placed**, **paid**, **shipped**. Events in this contract: `create` (POST) and `read` (GET). The `paid` and `shipped` transitions are not reachable through this contract; the assumption is that other systems drive them, so those states are covered by seeded fixtures only.

| From | Event | To | Expected | Case |
| --- | --- | --- | --- | --- |
| Absent | create, valid body | placed | `201`, `Order` with `status: placed` | TC-ORD-020 |
| Absent | create, empty items | Absent | `400`, `Error`; nothing created | TC-ORD-024, 027 |
| Absent | read | Absent | `404`, `Error` | TC-ORD-002 |
| placed / paid / shipped | read | same | `200`, `Order` with that status | TC-ORD-009 |
| any | delete, update | n/a | No endpoint; `405` expected and undocumented; record | TC-ORD-032 `@regression @api @p3 @candidate` |

There is no delete, so the invalid transitions "delete twice" and "update after delete" cannot be attempted. TC-ORD-032 sends `DELETE` and `PUT` once each to `/orders/{id}` to record the status and body.

### 2.4 Auth matrix

The contract declares no security scheme. Assumption: the API is public on staging. Every row below records what the service does and, if a `401` or `403` appears, that is an undocumented status to report as drift.

| Endpoint | No token | Expired token | Another user's order | Wrong role |
| --- | --- | --- | --- | --- |
| GET /orders/{id} | TC-ORD-040 | TC-ORD-041 | TC-ORD-042 (BOLA: must not return another user's data if ownership exists) | TC-ORD-043 |
| POST /orders | TC-ORD-044 | TC-ORD-045 | n/a | TC-ORD-046 |

All `@regression @api @p1 @deferred` until the owner states whether orders are owned by a user. CSRF does not apply unless a cookie session exists; record if one does.

### 2.5 Error contract

| Status | Documented | Declared body | Observed 2026-10-15 |
| --- | --- | --- | --- |
| 404 on GET | Yes | `Error` | `{message}` only (M3) |
| 400 on POST | Yes | `Error` | Not observed; the over-long note went to `500` |
| 400 on GET (bad id) | No | none | Not observed |
| 500 | No | none | `{error}` with database text (M4) |
| 401, 403, 405, 415, 422, 429 | No | none | Not observed |

### 2.6 Shared-environment constraints

Every test creates its own order with a unique note prefix such as `qa-auto-<run-id>` so it can be identified. **The contract has no delete, so created orders cannot be removed through the API.** This breaks the rule that each test deletes its data. Options, for the owner: a staging cleanup job keyed on the note prefix, or a delete endpoint. Until one exists, say so in the suite's README and keep the smoke run to one created order per run.

## 3. Automation shape (no files written)

- Runner and client: the Playwright `request` fixture if the repository uses Playwright (assumption; otherwise the framework's own client).
- An `OrdersApi` helper with `get(id)` and `create(body)` returning the raw response. No assertions in the helper.
- The `components.schemas` block is loaded once and compiled with a JSON Schema validator (Ajv with the OpenAPI 3.0 `nullable` keyword enabled). Each spec asserts the status, then `validate(schemaFor(status), body)`. The contract and tests then cannot drift apart silently.
- Red-green proof before any assertion counts: in a throwaway copy, change `Order.total` to `type: string` and watch TC-ORD-001 flip; change `Error.required` and watch TC-ORD-002 flip. Keep the failing output.
- Run `check-test-evidence.sh` on the spec directory once specs exist.

## 4. Contract strategy

**Schema conformance checks are enough for now.** The activity is conformance checking of a provider against its own published contract; the category is test execution with a schema validator, and only then the tool (Playwright request plus Ajv, run in CI on every deploy to staging). Consumer-driven contracts would need several independently released consumers, a provider team that cannot see them, and breaking changes that already reached them. Nothing in the request shows that: the consumer set is unknown, so the assumption is one or few in-house consumers. If a second team ships a consumer on its own cadence, revisit, because the three mismatches found here are exactly the kind a consumer-written contract would have caught before release. Any stub of this API used in consumer tests is testware and proves the consumer only (CTFL v4.0 §1.4.3).

## 5. Defects to file through /qa-defect, and what this report cannot show

Defects: M4 (`500` with leaked database detail on a long note, severity high), M3 (`404` body missing `code`), M1 (`total` serialised as a string, pending the owner's decision). M2 and M5 go to the document owner as drift.

Not shown by this report: no request was sent by me, so nothing is confirmed as conforming. The `400` on POST was never observed, so the declared `Error` body on the documented happy-path rejection is untested. The 500/501 boundary is inferred from an error message. Whether M4 left a partial row is unknown. No auth behaviour, no `paid` or `shipped` creation, and no cleanup path exist in the contract.
