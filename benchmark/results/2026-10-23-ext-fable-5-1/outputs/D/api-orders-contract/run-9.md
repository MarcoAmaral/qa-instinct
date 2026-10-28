# Orders API 2.1.0: conformance report and test design

Nothing was run in this session. All conformance claims below rest on the three responses recorded on staging on 2026-10-15. Every claim about live behaviour carries that date. The `api-tests/` files this skill normally writes were not created, by instruction.

## 1. Contract

| Item | Value | Source |
| --- | --- | --- |
| Contract | OpenAPI 3.0.3, Orders API 2.1.0, supplied inline with the request | Tier 1 (declared) |
| Path or URL of the document | Not given. Assumption: it is the version the team publishes for 2.1.0 | Assumption |
| Deployed version under test | 2.1.0 on staging, stated by whoever recorded the responses. Not confirmed by me from a version endpoint or deploy log | Assumption |
| Base URL | Not given. Staging environment, exact host unknown | Assumption |
| Auth model | The document declares no `securitySchemes` and no `security`. Assumption: no authentication on either endpoint | Tier 1, by omission |
| Date read | 2026-10-25 | |

The schema documents two endpoints and four responses in total. It declares no `maxLength` on `note`, no `maxItems` on `items`, no `nullable` on any field, no 401, 403, 405, 415 or 500, and no `securitySchemes`. Each gap is listed under "What the schema does not say".

## 2. Conformance of the recorded responses

Every recorded response mismatches the contract. Six mismatches across three responses.

| # | Request | Declared schema location | Actual response | Mismatch | Classification | Proposed owner |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | GET /orders/1042 | `Order.total`: `type: number` | `"total": "42.50"` (string) | Wrong JSON type for a required field | **Software defect** (provisional). The two-decimal string suggests a deliberate decimal serializer. If the API team confirms it is intentional, reclassify as documentation drift and change the schema to `type: string, format: decimal`. Either way a consumer coded to `number` breaks. | API team |
| M2 | GET /orders/1042 | `Order.note`: `type: string`, not nullable | `"note": null` | `null` is not a valid value for a non-nullable string in OpenAPI 3.0.3 | **Documentation drift**. An order without a note is a normal state. The schema should declare `nullable: true` or the API should omit the field. The owner decides which. | API team (schema) |
| M3 | GET /orders/999999 | 404 → `Error`, `required: [code, message]` | `{"message": "Order not found"}` | Required field `code` missing | **Software defect**. The contract promises a machine-readable code that consumers branch on. | API team |
| M4 | POST /orders, 5,000-character note | Responses: 201, 400 only | HTTP 500 | Undocumented status | **Software defect**. Over-long input is a client error, not a server fault. Expected: 400 with an `Error` body. | API team |
| M5 | POST /orders, 5,000-character note | Any error response → `Error` (`code`, `message`) | `{"error": "value too long for type character varying(500)"}` | Error body of a different shape; neither required field present | **Software defect**, same root cause as M4. | API team |
| M6 | POST /orders, 5,000-character note | `NewOrder.note`: `type: string`, no `maxLength` | Storage rejects above 500 characters | A real boundary the schema does not declare | **Documentation drift**. The schema should declare `maxLength: 500` so clients can validate before sending. | API team (schema) |

Two further findings from the same responses:

- **Information disclosure (M5).** The 500 body echoes the database column type and width. That is internal implementation detail in a client-facing response. Report it with M4 under the `security-qa` rule, as a sensitive-data item.
- **Unknown side effect (M4).** The recording does not show whether the order was partially persisted before the 500. There is no list endpoint to check. The defect report should ask the team to confirm, and the automated test should assert that no order is created on the failing path once a way to observe that exists.

Classification applies the `context-discovery` rule: the running service is ground truth for what the system does today, and the contract is ground truth for what it declares. The conflict is reported, not resolved here. M1, M3, M4 and M5 go to `/qa-defect` as three reports (M4 and M5 together). M2 and M6 go back to whoever owns the OpenAPI document. No test below is adjusted to match the observed behaviour until the owner decides.

Defect reports to open, with suggested priority:

| Report | Covers | Priority | Reason |
| --- | --- | --- | --- |
| DR-ORD-001 | M4, M5, information disclosure | P1 | Unhandled server error on valid-by-contract input, internal detail leaked. Workaround exists (shorter note) so not P0. |
| DR-ORD-002 | M1 | P1 | A required field has the wrong type on the main read path. Any consumer doing arithmetic on `total` fails. |
| DR-ORD-003 | M3 | P2 | Error is still readable by a human. Consumers that switch on `code` have no workaround. |

### What the schema does not say

| Gap | Why it matters | What the tests do |
| --- | --- | --- |
| No 500 documented | Observed on 2026-10-15 | Assert 500 never occurs for any designed input |
| No 401 or 403, no `securitySchemes` | Either the API is open, or auth exists and is undocumented | Probe without credentials; any 401 or 403 is drift |
| No 405 for GET /orders, PUT or DELETE /orders/{id} | Error shape for unsupported methods unknown | Probe, record the status and body shape as observed |
| No 415 for a non-JSON content type | Error shape unknown | Probe, record as observed |
| No response for a non-integer or sub-minimum path id | `minimum: 1` declares a boundary with no response for breaching it | Probe 0, -1, `abc`, `1.5`; expect 400 with `Error` and record |
| `Order` has no `items` field | Created order cannot be read back for its contents | Note as a design gap for the owner |
| No `maxItems` on `items`, no `maxLength` on `items[]` strings | Real limits unknown; `note` already proved storage limits exist | Probe with bounded sizes, record observed limits |
| `status` on creation unspecified | Assumption: a new order is `placed` | Assert `placed` on 201 and mark the assumption |
| No endpoint moves `status` to `paid` or `shipped` | The lifecycle is driven elsewhere | State model covers create and read only; transitions observed, never driven |
| No idempotency key on POST | Retry behaviour undefined | Test what happens and record it |

## 3. Test design

Acceptance criteria are the contract's declared responses and schemas. Each case names the one it checks. Level tag is `@api` on every case (system testing, CTFL v4.0 §2.2.1), so a shared staging instance is a constraint. Feature tag `@orders`. Every case asserts status **and** validates the body against the schema for that status; a status-only assertion is not a case.

### 3.1 GET /orders/{id}

**Partitions and boundaries for `id`** (EP §4.2.1, BVA 2-value §4.2.2). Declared: integer, minimum 1. Boundary at 0 / 1.

| ID | Input | Partition | Expected (per contract) | AC | Tags |
| --- | --- | --- | --- | --- | --- |
| TC-ORD-001 | id of an order created by the test | Valid, exists | 200, body valid against `Order`: `id` integer equal to the one created, `status` in enum, `total` is a JSON number, `note` string or absent | 200 → `Order` | @smoke @api @p0 @candidate |
| TC-ORD-002 | 999999 (or any id proven absent) | Valid, not found | 404, body valid against `Error` with `code` and `message` both strings | 404 → `Error` | @smoke @api @p1 @candidate |
| TC-ORD-003 | 1 | Boundary: minimum | 200 if it exists, else 404 with `Error` body. Either way, never 400 | `minimum: 1` | @regression @api @p2 @candidate |
| TC-ORD-004 | 0 | Boundary: minimum minus 1 | Undocumented. Expected 400 with `Error` body. Record observed | `minimum: 1` | @regression @api @p2 @candidate |
| TC-ORD-005 | -1 | Invalid: negative | Same as TC-ORD-004 | `minimum: 1` | @regression @api @p3 @candidate |
| TC-ORD-006 | `abc` | Invalid: not an integer | Undocumented. Expected 400 with `Error` body, never 500 | `type: integer` | @regression @api @p2 @candidate |
| TC-ORD-007 | `1.5` | Invalid: non-integer number | Same as TC-ORD-006 | `type: integer` | @regression @api @p3 @candidate |
| TC-ORD-008 | 9223372036854775808 (2^63) | Boundary: above 64-bit signed | Undocumented. Expected 400 or 404 with `Error` body, never 500 | `type: integer` | @regression @api @p3 @candidate |
| TC-ORD-009 | id of an order whose `note` was never set | Valid, optional field absent | 200, `note` absent or, if the owner accepts drift M2, `null`. The expectation is pinned once M2 is decided | 200 → `Order` | @regression @api @p2 @deferred |
| TC-ORD-010 | id of an order created with a 500-character note | Valid, note at maximum | 200, `note` returned intact at 500 characters | 200 → `Order` | @regression @api @p2 @candidate |

TC-ORD-001 currently fails on staging because of M1. TC-ORD-002 currently fails because of M3. TC-ORD-009 is deferred until M2 is decided, so the test does not encode a guess.

### 3.2 POST /orders

**Partitions and boundaries for the body** (EP §4.2.1, BVA §4.2.2). Declared: `items` required, array of string, minItems 1. `note` optional string, no declared maximum. Observed maximum on 2026-10-15: 500 characters.

| ID | Body | Partition | Expected (per contract) | AC | Tags |
| --- | --- | --- | --- | --- | --- |
| TC-ORD-020 | `{"items": ["sku-1"]}` | Valid, items at minimum | 201, body valid against `Order`, `status` is `placed` (assumption), `total` is a JSON number, `Location` header if present names the new id. Order deleted in teardown | 201 → `Order` | @smoke @api @p0 @candidate |
| TC-ORD-021 | `{"items": ["sku-1","sku-2","sku-3"]}` | Valid, several items | 201, body valid against `Order` | 201 → `Order` | @regression @api @p1 @candidate |
| TC-ORD-022 | `{"items": ["sku-1"], "note": "ok"}` | Valid, note present | 201, `note` echoed | 201 → `Order` | @regression @api @p1 @candidate |
| TC-ORD-023 | `{"items": []}` | Boundary: minItems minus 1 | 400, body valid against `Error` | 400 → `Error`, `minItems: 1` | @smoke @api @p1 @candidate |
| TC-ORD-024 | `{}` | Invalid: items missing | 400, `Error` body | `required: [items]` | @regression @api @p1 @candidate |
| TC-ORD-025 | `{"items": null}` | Invalid: items null | 400, `Error` body | `type: array` | @regression @api @p2 @candidate |
| TC-ORD-026 | `{"items": "sku-1"}` | Invalid: wrong JSON type (string, not array) | 400, `Error` body | `type: array` | @regression @api @p2 @candidate |
| TC-ORD-027 | `{"items": [42]}` | Invalid: item is a number | 400, `Error` body | `items: {type: string}` | @regression @api @p2 @candidate |
| TC-ORD-028 | `{"items": [null]}` | Invalid: item is null | 400, `Error` body | `items: {type: string}` | @regression @api @p2 @candidate |
| TC-ORD-029 | `{"items": [""]}` | Invalid by error guessing: empty string | Undocumented. Expected 400, `Error` body. Record observed | `items: {type: string}` | @regression @api @p2 @candidate |
| TC-ORD-030 | `{"items": ["no-such-sku"]}` | Valid by schema, invalid by business rule | Undocumented. Expected 400 with `Error` body or 201 if the API does not validate SKUs. Record observed. Delete if created | 400 → `Error` | @regression @api @p1 @candidate |
| TC-ORD-031 | `{"items": ["sku-1","sku-1"]}` | Error guessing: duplicate items | Undocumented. Record whether it creates one order with two lines, or rejects | 201 → `Order` | @regression @api @p3 @candidate |
| TC-ORD-032 | 1 item string of 5,000 characters | Over-long item | Undocumented. Expected 400 with `Error` body, never 500 | `items: {type: string}` | @regression @api @p2 @candidate |
| TC-ORD-033 | 1,000 items | Many items, bounded probe | Undocumented. Expected 201 or 400 with `Error` body, never 500. Record observed limit | `type: array` | @regression @api @p3 @candidate |
| TC-ORD-034 | `note: ""` | Boundary: empty note | 201, `note` echoed as empty string or omitted. Record | 201 → `Order` | @regression @api @p3 @candidate |
| TC-ORD-035 | `note` of 500 characters | Boundary: observed maximum | 201, `note` echoed intact | 201 → `Order` | @regression @api @p1 @candidate |
| TC-ORD-036 | `note` of 501 characters | Boundary: observed maximum plus 1 | 400, `Error` body. Never 500. No order persisted | 400 → `Error` | @smoke @api @p1 @candidate |
| TC-ORD-037 | `note` of 5,000 characters | Over-long, the recorded case | Same as TC-ORD-036. Regression spec for DR-ORD-001: must fail until the fix lands | 400 → `Error` | @regression @api @p1 @candidate |
| TC-ORD-038 | `note` of 500 multibyte characters (e.g. "é" or CJK) | Boundary in characters, not bytes | 201 if the limit is characters, 400 with `Error` if bytes. Never 500. Record which | 201 → `Order` | @regression @api @p2 @candidate |
| TC-ORD-039 | `note: null` | Invalid: null for non-nullable string | 400, `Error` body, or 201 if the owner accepts M2. Pinned after M2 is decided | `note: {type: string}` | @regression @api @p2 @deferred |
| TC-ORD-040 | `note: 123` | Invalid: wrong JSON type | 400, `Error` body | `note: {type: string}` | @regression @api @p2 @candidate |
| TC-ORD-041 | `{"items": ["sku-1"], "extra": true}` | Unknown property | Undocumented. Expected 201 with the property ignored, or 400. Record | `NewOrder` | @regression @api @p3 @candidate |
| TC-ORD-042 | No body | `requestBody.required: true` | 400, `Error` body | 400 → `Error` | @regression @api @p1 @candidate |
| TC-ORD-043 | Body `not json` | Malformed JSON | 400, `Error` body. Never 500 | 400 → `Error` | @regression @api @p1 @candidate |
| TC-ORD-044 | Valid body, `Content-Type: text/plain` | Wrong media type | Undocumented. Expected 415. Record status and body shape | Error contract gap | @regression @api @p3 @candidate |
| TC-ORD-045 | `note` containing `<script>alert(1)</script>` | Security: stored input echoed | 201, `note` echoed verbatim and unaltered in GET. Response `Content-Type` is `application/json`. Not a rendering test; it proves the API does not transform input | `security-qa`: injection | @regression @api @p2 @candidate |

TC-ORD-036 and TC-ORD-037 currently fail on staging because of M4 and M5.

### 3.3 Resource state model (§4.2.4)

States declared by `status`: `placed`, `paid`, `shipped`. Events the contract exposes: **create** (POST) and **read** (GET). No update, delete, pay, ship or cancel endpoint exists. Assumption: payment and shipping move the status from another system.

| ID | Sequence | Expected | Tags |
| --- | --- | --- | --- |
| TC-ORD-050 | create, then read by returned id | GET body equals POST body field for field, `status` is `placed` | @smoke @api @p0 @candidate |
| TC-ORD-051 | create, read, read again | Both reads identical. GET is safe and idempotent | @regression @api @p2 @candidate |
| TC-ORD-052 | read an order known to be `paid` (fixture 1042, read-only) | 200, `status: paid`, body valid against `Order`. Observes a transition it cannot drive | @regression @api @p2 @candidate |
| TC-ORD-053 | read an order known to be `shipped` (fixture needed, none known) | As above. Blocked until a shipped fixture exists | @regression @api @p2 @deferred |
| TC-ORD-054 | PUT /orders/{id}, DELETE /orders/{id} | Invalid transitions by method: undocumented. Expected 405. Record status and body shape | @regression @api @p3 @candidate |
| TC-ORD-055 | GET /orders (collection) | Undocumented. Expected 405 or 404 with `Error` body. Record | @regression @api @p3 @candidate |

Coverage criterion: valid transitions over the exposed events, plus one invalid transition per case so that defects do not mask each other. All transitions coverage is impossible here because the contract exposes no event for `paid` or `shipped`. That is a design gap for the owner, not a test gap.

Fixture 1042 is read-only: the tests never write to it. Every created order is deleted in teardown. There is no DELETE endpoint, so teardown cannot run through the API. Assumption: the team provides a cleanup route or a database job. Until then, every created order carries a unique marker in `note` (for example `qa-<run id>-<case id>`) so leftovers can be found and purged, and the suite reports the ids it created.

### 3.4 Auth matrix

The contract declares no security. Assumption: both endpoints are open.

| Endpoint | No token | Expired token | Another user's resource | Wrong role |
| --- | --- | --- | --- | --- |
| GET /orders/{id} | Expected 200 or 404 per contract. A 401 or 403 is drift | Not applicable while no scheme is declared | Not testable: no ownership model declared | Not applicable |
| POST /orders | Expected 201 or 400 per contract. A 401 or 403 is drift | Not applicable | Not applicable | Not applicable |

**Security finding, not a test.** If the API really is open, an order with a sequential integer id is readable by anyone who guesses the id. That is a broken object-level authorization (BOLA) exposure by design. Raise it to the owner before the suite is finalised. If an auth scheme exists and the document omits it, that is documentation drift and the matrix above becomes four real rows per endpoint. CSRF does not apply as long as no cookie session exists (assumption).

### 3.5 Error contract

| Status | Documented | Body shape declared | Body shape observed (2026-10-15) |
| --- | --- | --- | --- |
| 400 | Yes, POST only | `Error` | Never observed. The 5,000-character note returned 500 instead |
| 404 | Yes, GET only | `Error` | `{"message"}` only. `code` missing (M3) |
| 500 | No | None | `{"error": "<database message>"}` (M4, M5) |
| 401, 403, 405, 415 | No | None | Never observed |
| 400 on invalid path id | No | None | Never observed |

Two error shapes exist on staging today, neither matching the contract. Every error case above asserts the `Error` shape. Any other shape fails the test, by principle.

### 3.6 Idempotency and retries

| ID | Scenario | Expected | Tags |
| --- | --- | --- | --- |
| TC-ORD-060 | POST the same valid body twice | The API promises nothing. Expected: two orders with different ids. Record. If the second returns the first id or a 409, record that instead and raise a documentation gap | @regression @api @p2 @candidate |
| TC-ORD-061 | POST with an `Idempotency-Key` header, twice | Undocumented. Expected: header ignored, two orders. Record. Both deleted | @regression @api @p3 @candidate |
| TC-ORD-062 | GET the same id ten times in sequence | Identical bodies, no state change | @regression @api @p3 @candidate |

### 3.7 Smoke set

Five cases make the post-deploy gate, all under ten minutes: TC-ORD-001, TC-ORD-002, TC-ORD-020, TC-ORD-023, TC-ORD-036, TC-ORD-050. Three of them fail on staging today (M1, M3, M4), which is the correct outcome: the gate is red until the defects are fixed or the contract is corrected.

## 4. Automation plan

No spec was written, by instruction, so the evidence checker was not run and no red-green proof exists yet. The plan when writing begins:

- **Runner and client.** Playwright's `request` fixture if the repository uses Playwright, otherwise the project's own HTTP client. Activity: test execution. Category: test execution and coverage tools (CTFL v4.0 §6.1).
- **Schema validation.** Load the OpenAPI document once, resolve `#/components/schemas`, and validate every response body with a JSON Schema validator (Ajv in OpenAPI 3.0 mode, which understands `nullable`). The contract file is the single source of expected shapes, so a schema change and the tests cannot drift apart silently.
- **Helper.** One `OrdersApi` class with `getOrder(id)` and `createOrder(body)` returning the raw response. No assertions in the helper.
- **Specs.** AAA in every test. Status asserted, then body validated against the schema for that status, then field-level assertions for values the schema cannot express (the created id, the echoed note). No sleeps, no conditional assertions.
- **Data.** Each test creates its own order with a unique marker and removes it in `afterEach`, including on failure. Fixture 1042 is read-only.
- **Red-green proof.** Before an assertion counts, change the expected type in a throwaway copy of the schema (for example `total` to string), watch TC-ORD-001 fail for that reason, and keep the output. Repeat for the `Error` shape.
- **Evidence.** Run `check-test-evidence.sh api-tests/` from `.claude/hooks/` on the specs once they exist.

## 5. Contract strategy

**Schema conformance checks are enough for now.** The activity that needs to become cheaper is detecting a provider response that no longer matches its declared shape. The category is test execution tooling with schema validation, not a contract broker. The contract above has one provider and no evidence of several independently released consumers, no sign that the provider team cannot see its consumers, and no history of breaking changes reaching them. Consumer-driven contracts would add a process for both teams, a provider-side verification stage and a broker owner, with nothing today to justify that cost. The three recorded mismatches are all provider-side drift that a conformance suite in CI catches directly. Revisit the decision if a second consumer team ships on its own cadence or a breaking change reaches a consumer unannounced. If a simulated Orders API is ever used in a consumer's tests, that simulator is testware (CTFL v4.0 §1.4.3): it proves the consumer and never the provider.

## 6. What this work cannot show

- Nothing was executed. Conformance rests on three responses recorded by someone else on 2026-10-15.
- The deployed version was not confirmed from a deployment record or version endpoint.
- No 400 response was ever observed, so the `Error` shape on a validation failure is unknown until a run happens.
- No `shipped` order and no order without a note is known, so TC-ORD-009 and TC-ORD-053 have no fixture.
- Whether the failing POST persisted a partial order is unknown.
- Nothing was written, so no red-green proof and no evidence-checker output exist.

Rules applied: `context-discovery`, `testing-guidelines`, `code-style-qa`, `security-qa`, `test-tools`, `test-evidence`. None were missing.
