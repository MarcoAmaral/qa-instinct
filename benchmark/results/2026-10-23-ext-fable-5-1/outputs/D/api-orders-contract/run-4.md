## Contract

| Item | Value |
| --- | --- |
| Contract | OpenAPI 3.0.3, Orders API 2.1.0, pasted in the request. No URL or repository path given, so there is no fetched date and no provenance beyond the request. |
| Deployed version under test | 2.1.0 on staging, as stated by the requester for 2026-10-15. Assumption: that figure comes from the staging deployment record or version endpoint. I did not confirm it. |
| Auth model | None declared. The document has no `securitySchemes` and no `security` block. Assumption: the recordings were made without credentials. If staging does require a token, every 401 or 403 below is an undocumented status. |
| Base URL and environment | Not given. Staging, shared instance. |
| What was run | Nothing. The three responses were recorded by the requester on 2026-10-15. I validated those bodies against the schema by reading. Every "conforms" or "mismatch" below is about those recordings, not about staging today. |

Operations the contract declares: GET `/orders/{id}` (200, 404) and POST `/orders` (201, 400). There is no list, update, delete or status-transition endpoint, so the contract declares a lifecycle it gives no way to drive.

## Conformance of the recorded responses

Every recorded response has at least one mismatch. Six findings in total.

| # | Request | Declared schema location | Actual | Mismatch | Classification | Proposed owner |
| --- | --- | --- | --- | --- | --- | --- |
| C1 | GET /orders/1042 → 200 | `Order.total: number` | `"total": "42.50"` (string) | Wrong JSON type. A client doing arithmetic on `total` gets string concatenation. | Probable documentation drift: serialising money as a decimal string is a deliberate pattern, and the value is well formed. If the team meant `number`, it is a software defect. Owner decides; either fix is acceptable, silence is not. | API owner (schema) |
| C2 | GET /orders/1042 → 200 | `Order.note: string`, no `nullable: true` | `"note": null` | `null` is not a string in OAS 3.0.3 without `nullable: true`. | Documentation drift. Either declare `nullable: true` or omit the key when the order has no note. | API owner (schema) |
| C3 | GET /orders/999999 → 404 | `Error.required: [code, message]` | `{"message": "Order not found"}` | Required field `code` missing. Consumers cannot branch on an error code. | Software defect: the contract promises a machine-readable code and the service omits it. If `code` was never implemented anywhere, reclassify as drift. | API team, via `/qa-defect` |
| C4 | POST /orders, note of 5,000 chars → 500 | Operation declares only 201 and 400 | Status 500 | Undocumented status. An unhandled database constraint reaches the client. Expected per contract: 400 with an `Error` body. | Software defect. | API team, via `/qa-defect` |
| C5 | Same request as C4 | `Error` schema | `{"error": "value too long for type character varying(500)"}` | Error body of a third shape: neither `code` nor `message`. The text leaks the database column type, which the `security-qa` rule forbids in responses. | Software defect, with a security-hygiene note. Same report as C4. | API team |
| C6 | Same request as C4 | `NewOrder.note: string`, no `maxLength` | Real limit is 500 characters | The schema declares no boundary; the service has one. | Documentation gap. Declare `maxLength: 500` once the 400 handling exists. | API owner (schema) |

What the recordings cannot tell us: whether the failed POST in C4 left a row behind. Assumption: the database rejected the insert and nothing was created, but with no list endpoint this cannot be checked through the API. Only three of the four documented status and operation pairs were exercised. POST → 201 and POST → 400 were never observed, so their conformance is unknown.

Error shapes seen so far: `{"message"}` for 404 and `{"error"}` for 500. Neither matches `Error`. Document each real shape or fix the service, but do not adjust tests to accept them (principle 2).

## Test design

Acceptance criteria are not supplied, so each case checks a criterion derived from the contract: AC-1 an existing id returns an `Order`; AC-2 an unknown id returns 404 with an `Error`; AC-3 a valid `NewOrder` returns 201 with an `Order`; AC-4 an invalid `NewOrder` returns 400 with an `Error`; AC-5 no response carries an undocumented status or body shape. Every case asserts status and body against the schema for that status. Tags follow the `testing-guidelines` rule, all with `@api @orders`.

**GET /orders/{id}: partitions and boundaries** (EP §4.2.1, BVA §4.2.2)

| ID | Input | Expected per contract | Note | Tags |
| --- | --- | --- | --- | --- |
| TC-ORD-001 | Existing id (fixture, e.g. 1042) | 200, `Order`; `total` is a number, `status` in enum, `note` string or absent | AC-1. Currently fails on C1 and C2. | @smoke @p0 @candidate |
| TC-ORD-002 | Unknown id 999999 | 404, `Error` with `code` and `message` | AC-2. Currently fails on C3. | @smoke @p1 @candidate |
| TC-ORD-003 | id = 1 (minimum) | 200 or 404, both with a conforming body; never 400 | AC-1 / AC-2 boundary | @regression @p2 @candidate |
| TC-ORD-004 | id = 0 (min − 1) | Undeclared. Propose 400, `Error`. Record observed. | AC-5. Schema says `minimum: 1` but declares no 400 for GET. | @regression @p2 @candidate |
| TC-ORD-005 | id = −1, `abc`, `10.5`, 2^63 | Undeclared. Propose 400, `Error`, never 500 | AC-5 | @regression @p2 @candidate |
| TC-ORD-006 | Response has an extra, undeclared field | Record. Schema lacks `additionalProperties: false`, so this is a drift finding, not a failure. | AC-5 | @regression @p3 @candidate |
| TC-ORD-007 | One order per declared status: placed, paid, shipped | 200 each; `status` exactly one of the three | AC-1. Needs fixtures per state; a fourth value is a mismatch. | @regression @p1 @candidate |

**POST /orders: partitions and boundaries**

| ID | Input | Expected per contract | Note | Tags |
| --- | --- | --- | --- | --- |
| TC-ORD-010 | `items: ["sku-1"]`, no note | 201, `Order`; `id` integer ≥ 1; GET of that id returns the same body | AC-3, positive half. Assumption: new orders start as `placed`. | @smoke @p0 @candidate |
| TC-ORD-011 | `items` missing, `null`, a string, `[]` (minItems − 1) | 400, `Error` each | AC-4, one case per partition | @smoke @p1 @candidate |
| TC-ORD-012 | `items: [1]`, `[""]`, `["sku-1","sku-1"]`, `["no-such-sku"]` | Wrong type → 400. The other three are undeclared: record whether unknown, empty or duplicate SKUs are accepted. | AC-4 / AC-5. Schema declares no `minLength`, `pattern` or `uniqueItems`. | @regression @p2 @candidate |
| TC-ORD-013 | `items` with 2, then 100 elements | 201 each, or a documented 400 | Undeclared `maxItems`; probe bounded, not load. | @regression @p3 @candidate |
| TC-ORD-014 | `note` of 500 chars (observed max) | 201, `note` echoed intact | AC-3 boundary | @regression @p1 @candidate |
| TC-ORD-015 | `note` of 501 chars (max + 1) | 400, `Error`; never 500 | AC-4. Currently fails per C4, C5. | @regression @p1 @candidate |
| TC-ORD-016 | `note: 123`, `note: null`, `note: ""` | Number → 400. `null` and `""` undeclared: record. | AC-4 / AC-5 | @regression @p2 @candidate |
| TC-ORD-017 | Empty body, malformed JSON, `Content-Type: text/plain`, unknown extra field | 400 `Error` for the first two. 415 and the extra field are undeclared: record. | AC-5 | @regression @p2 @candidate |

**Resource state model** (state transition §4.2.4). States: none → `placed` (POST) → `paid` → `shipped`. The contract exposes only the create event and the read. The `paid` and `shipped` transitions happen out of band, so valid-transitions coverage through this API is one transition, and no invalid transition (pay twice, ship an unpaid order) can be attempted here. TC-ORD-007 gives all-states coverage via fixtures. Say this plainly in the suite report: the lifecycle is observed, not driven. Anything that transitions orders is out of contract and needs its own schema before it is tested.

**Auth matrix.** The contract declares no auth, so the expected result of every row is "same as with credentials". Any 401 or 403 is an undocumented status to report as drift. If GET returns any order to an anonymous caller, that is a BOLA finding under the `security-qa` rule for the owner to rule on, not a pass.

| Case | GET /orders/{id} | POST /orders |
| --- | --- | --- |
| No token | Record status and shape | Record |
| Expired token | Record | Record |
| Another user's order id | Record; flag if returned | n/a |
| Wrong role | Record | Record |

**Error contract.** Documented: 404 and 400 as `Error`. Undocumented but reachable: 400 on GET, 401/403, 405 (GET /orders, DELETE /orders/{id}), 415, 429, 500. One case per undocumented status: trigger it, record the body shape, assert it never 500s. Two non-conforming shapes already exist (C3, C5).

**Idempotency and retries.** The contract promises nothing. POST twice with the same body: expect two orders with different ids, record it. No `Idempotency-Key` header is declared; recommend one, but do not test for it until it is in the schema. There is no PUT or DELETE to check.

**Shared-environment constraint.** The contract has no DELETE, so orders created by TC-ORD-010 to 017 cannot be cleaned up through the API. Mark every test order with `note: "qa-auto-<run-id>"` and agree a cleanup job with the owner before the suite runs on a schedule. Until then, run POST cases by hand and in small numbers. Date every observation.

**Automation (step 4, not done).** Specs were not written and no files were created, as requested. When they are: one helper with one method per endpoint and no assertions; the schema loaded once and validated with a JSON Schema validator; red-green proof for each assertion; `check-test-evidence.sh` run on the spec directory. Note that the suite will stay red on TC-ORD-001, 002 and 015 until the owners decide on C1 to C5. Do not loosen the schema to make them pass.

**Contract strategy (step 5).** Schema conformance checks are enough. The activity is result checking at execution time, a test execution tool category (CTFL §6.1); a JSON Schema validator such as Ajv inside the runner's HTTP client fits, with the OpenAPI document as the single source. Consumer-driven contracts are not justified on the evidence: there is one provider, no named independently released consumers, and no record of a breaking change reaching them. The recorded drift (C1, C2, C6) is exactly what a schema check in CI catches. Revisit if several consumer teams appear that the provider team cannot see.

**Defects to file** via `/qa-defect`: DR for C4 plus C5 (500 and database type leak on long note, P1), DR for C3 (404 body missing `code`, P2). Drift to the schema owner: C1, C2, C6, and the undocumented statuses.

**Rules not applied.** All rules named by the skill were found in `.claude/rules` and read, except `code-style-qa`, which applies only at step 4 and was not needed. The evidence checker was not run because no specs exist.
