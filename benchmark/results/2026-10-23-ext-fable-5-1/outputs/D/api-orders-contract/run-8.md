## 1. Contract (read only)

| Item | Value |
| --- | --- |
| Contract | OpenAPI 3.0.3, title Orders API, version 2.1.0, supplied inline with this request. No URL or repository path given. Read 2026-10-25. |
| Deployed version under test | 2.1.0 on staging, as stated in the recording note dated 2026-10-15. Assumption: I did not confirm it against a deployment record or a version endpoint, because none was supplied. |
| Base URL and environment | Not given. Assumption: the staging host, with the paths exactly as declared. |
| Auth model | The document declares no `securitySchemes` and no `security`. Assumption: the endpoints are authenticated with a bearer token the document omits, since orders are customer data. If that is true, the omission is documentation drift. If the API is genuinely public, the "another user's order" row in the auth matrix becomes a P0 security finding. |
| Operations declared | Two: `GET /orders/{id}` and `POST /orders`. No list, update, delete, or status-transition operation. |
| What was run | Nothing. All three responses are recorded samples from 2026-10-15. Every claim about live behaviour below is dated to that recording. |

The absence of a delete operation is a test-environment constraint: anything a test creates on staging cannot be removed through the API. See the automation note at the end.

## 2. Conformance of the recorded responses

Each response was validated by hand against the schema the contract declares for that status. Rows are ordered by the sample they come from.

| # | Request and status | Declared schema location | Actual | Finding | Classification | Proposed owner |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | `GET /orders/1042` → 200 | `components.schemas.Order.properties.total`: `type: number` | `"total": "42.50"` (JSON string) | Wrong JSON type for a required field. A consumer that does arithmetic on `total` breaks. | **Software defect**, unless the team serialises money as a decimal string on purpose. In that case it is documentation drift and the schema must say `type: string` with a pattern, and all consumers must be told. | API team decides; defect by default. |
| M2 | same | `Order.properties.note`: `type: string`, no `nullable: true` | `"note": null` | `null` is not a string under OAS 3.0.3 without `nullable: true`. `note` is not required, so omitting the key would conform. | **Software defect** in the serialiser, or drift if the team wants `null` and adds `nullable: true`. Low severity, but it breaks strict validators. | API team. |
| M3 | `GET /orders/999999` → 404 | `components.schemas.Error`: `required: [code, message]` | `{"message": "Order not found"}` | Required field `code` missing. Consumers that branch on `code` cannot. | **Software defect**. The status is right, the body is not. | API team. |
| M4 | `POST /orders` with a 5,000-character `note` → 500 | `paths./orders.post.responses`: only 201 and 400 declared | HTTP 500 | Undocumented status. Input validation is absent for `note` length, so the request reaches the database and fails there. The contract's own "Invalid order" response (400) is what a too-long note should get. | **Software defect**, P1. | API team. |
| M5 | same | `Error` schema (the only error shape declared) | `{"error": "..."}` | Body matches no declared schema: wrong key, no `code`, no `message`. This is a third error shape in one API, alongside `Error` and the `{message}` shape in M3. | **Software defect** (unhandled-exception handler does not use the `Error` contract). Same ticket as M4 or a separate one for the handler. | API team. |
| M6 | same | security-qa rule: no internal details in error bodies | `value too long for type character varying(500)` | The body reveals the storage engine, the column type and its length. Information disclosure through an error message. | **Software defect**, security label. | API team, security review in copy. |
| M7 | same | `NewOrder.properties.note`: no `maxLength` | Real limit is 500 characters (from the DB column type) | The schema declares no boundary where the system has one. Clients cannot know the limit until they hit a 500. | **Documentation drift**: add `maxLength: 500`. The API must also enforce it (M4). | Document owner. |
| M8 | contract as a whole | no `securitySchemes` | unknown | Auth is either undocumented or absent. See Contract above. | **Documentation drift** if authenticated, **security defect** if not. | Document owner / security review. |

What conforms in the samples: both GET statuses are the declared ones, `id` is an integer, `status` is inside the enum.

What the samples cannot show: no 201 and no 400 were recorded, so the POST happy path and the declared 400 error body are unverified. Whether the 500-character limit counts characters or bytes is unknown. Whether `items` has similar undeclared limits is unknown.

Defects to raise through `/qa-defect`: one for M4 + M5 + M6 (over-long note returns 500 with leaked internals, P1), one for M3 (404 body missing `code`), one for M1 (`total` serialised as string, pending the team's decision), one for M2 (`note` emitted as `null`). M7 and M8 go to whoever owns the document.

## 3. Test design

**Acceptance criteria.** None were supplied, so they are derived from the contract. Each case below names the one it checks.

- AC1: `GET /orders/{id}` for an existing order returns 200 with a body valid against `Order`.
- AC2: `GET /orders/{id}` for an unknown id returns 404 with a body valid against `Error`.
- AC3: `GET /orders/{id}` with an id that violates `integer, minimum: 1` is rejected. The contract documents no status for this. Assumption: 400 with `Error`; the observed status is recorded either way, and 500 or 200 is a failure.
- AC4: `POST /orders` with a valid `NewOrder` returns 201 with a body valid against `Order`, and a following GET returns the same order.
- AC5: `POST /orders` with an invalid `NewOrder` returns 400 with a body valid against `Error`. Never 500.
- AC6: every error response, documented or not, has the `Error` body shape.

**Partitions and boundaries, `GET /orders/{id}`** (EP §4.2.1, BVA §4.2.2). Path parameter `id`: `integer, minimum: 1`.

| Partition | Values | Expected | AC |
| --- | --- | --- | --- |
| Valid, existing | fixture order id (1042 on staging, read-only) | 200, `Order` | AC1 |
| Valid, not existing | 999999 | 404, `Error` with `code` | AC2 |
| Lower boundary | 1 (exists or not, record), 0, -1 | 1: 200 or 404 per data; 0 and -1: 400 `Error` (assumption) | AC3 |
| Not an integer | `abc`, `1.5`, `1042abc`, `01042`, `1e3` | 400 `Error` (assumption); `01042` and `1e3` recorded, since parsers differ | AC3 |
| Overflow | 2147483648, 9223372036854775808, a 400-digit number | 400 or 404, never 500 | AC3, AC6 |
| Injection | `1042 OR 1=1`, `1042;DROP TABLE orders`, `../orders` | 400 or 404, body `Error`, never 200 with data, never 500 | AC6, security |
| Empty | `GET /orders/` | Routes to the collection; GET is undeclared there, so 404 or 405 with `Error` | AC6 |

**Partitions and boundaries, `POST /orders`.** `items`: `array, minItems: 1, items: string`. `note`: `string`, no declared length, 500 observed.

| Field | Partition | Values | Expected | AC |
| --- | --- | --- | --- | --- |
| items | missing, null | `{}`, `{"items": null}` | 400 `Error` | AC5 |
| items | wrong type | `"sku-1"`, `{}`, `42` | 400 `Error` | AC5 |
| items | empty (min − 1) | `[]` | 400 `Error` | AC5 |
| items | min | `["sku-1"]` | 201 `Order`, `total` a number | AC4 |
| items | min + 1 | `["sku-1","sku-2"]` | 201 `Order` | AC4 |
| items | non-string element | `[1]`, `[null]`, `[{}]` | 400 `Error` | AC5 |
| items | empty string element | `[""]` | Undeclared. Assumption: 400. Record. | AC5 |
| items | unknown SKU | `["no-such-sku"]` | Undeclared. Assumption: 400 with a business `code`. Record. | AC5 |
| items | duplicate | `["sku-1","sku-1"]` | Undeclared. Record whether it is two lines or one. | AC4 |
| items | many | 1,000 elements; one element of 10,000 characters | Undeclared. 201 or 400, never 500. Record the real limits. | AC6 |
| note | absent | no key | 201; response omits `note` or has a string, never `null` (M2) | AC4 |
| note | empty | `""` | Undeclared. Record. | AC4 |
| note | max | 500 characters | 201 (BVA on the observed limit) | AC4 |
| note | max + 1 | 501 characters | 400 `Error` (fails today, M4) | AC5 |
| note | far over | 5,000 characters | 400 `Error` (fails today, M4) | AC5 |
| note | multibyte at the limit | 500 × `é`; 250 × a 4-byte emoji | Record whether the limit is characters or bytes; never 500 | AC6 |
| note | wrong type | `123`, `true`, `{}`, `[]` | 400 `Error` | AC5 |
| note | null | `null` | Undeclared. 400, or treated as absent. Record. | AC5 |
| note | hostile content | `<script>alert(1)</script>`, `'; DROP TABLE orders;--` | 201, stored and returned verbatim as a string, no 500. A consumer renders it escaped. | AC4, security |
| body | empty, malformed JSON | ``, `{"items": [` | 400 `Error`, not 500 | AC5, AC6 |
| body | wrong content type | `text/plain` with a JSON string | Undeclared. 415 with `Error` (assumption). Record. | AC6 |
| body | mass assignment | `{"items":["sku-1"], "total": 0, "status": "shipped", "id": 1}` | 201; response `total` is server-computed, `status` is the initial state, `id` is server-assigned | AC4, security |

**Resource state model** (§4.2.4). States from the `status` enum: `placed`, `paid`, `shipped`, plus the implicit state *absent*. The contract exposes only two events: create, which moves *absent* to `placed` (assumption: `placed` is the initial status; the contract does not say), and read, which changes nothing. Pay and ship are not operations of this contract, so their valid and invalid transitions (pay twice, ship before paying, ship after shipping) cannot be driven through this API. That gap goes to whoever owns the transition service.

Coverage criterion chosen: *all states*, the weakest, because only one transition is reachable. It needs one read-only fixture order in each of the three statuses. Order 1042 covers `paid`; `placed` and `shipped` fixtures are an assumption to confirm with the team.

| Case | Sequence | Expected |
| --- | --- | --- |
| Create then read | POST valid → GET returned id | 201 then 200; same `id`, `status: placed`, same `total`, same `note` |
| Read absent | GET id that never existed | 404 `Error` |
| Read each state | GET placed fixture, paid fixture, shipped fixture | 200; `status` equals the fixture's; `total` is a number in all three |
| Read a non-existent id after creating a neighbour | POST → GET returned id + 1 | 404, or 200 for an order not created by this test. Never the test's own order. Guards against id guessing in the client. |

**Auth matrix.** Expectations assume the API is authenticated (assumption in Contract). Every row asserts the body is `Error`-shaped, which is an undocumented status today and so also a drift finding.

| Case | GET /orders/{id} | POST /orders |
| --- | --- | --- |
| No token | 401 `Error` | 401 `Error` |
| Expired token | 401 `Error` | 401 `Error` |
| Valid token, another customer's order id | 404 or 403 `Error`. Never 200 with that customer's data (BOLA). | n/a |
| Valid token, wrong role (read-only or support) | 200 if the role may read | 403 `Error` |
| Valid token, own order | 200 `Order` | 201 `Order` |

If no auth exists, the "another customer's order" row is the finding: any caller reads any order by incrementing an integer id.

**Error contract.**

| Status | GET /orders/{id} | POST /orders | Shape declared | Shape observed |
| --- | --- | --- | --- | --- |
| 400 | not declared | declared | `Error` | none recorded |
| 401, 403 | not declared | not declared | none | unknown |
| 404 | declared | not declared (wrong path) | `Error` | `{message}` only (M3) |
| 405 (`PUT`, `DELETE /orders/1042`; `GET /orders`) | not declared | not declared | none | unknown |
| 413, 415, 429 | not declared | not declared | none | unknown |
| 500 | not declared | not declared | none | `{error}` (M5) |

Three shapes exist for one API. Every case above asserts the `Error` schema on every non-2xx status, so each path that returns another shape fails until the shape is unified or the document is widened.

**Idempotency and retries.** There is no `PUT` or `DELETE` to repeat. The contract promises nothing about a retried `POST` and declares no `Idempotency-Key` header. Tests therefore record behaviour rather than enforce it:

- Same valid body sent twice in succession: record whether two orders with different ids are created. Assumption: they are, and the client must guard its own retries. Recommend the document say so.
- Same body sent twice with an identical `Idempotency-Key` header: record whether the second call returns the first order. Not a defect either way until the API promises it.

**Test cases.** Technique and tags per case. Every case asserts status and body against the contract schema for that status. Feature tag `@orders`.

| ID | Case | Technique | Tags | AC |
| --- | --- | --- | --- | --- |
| TC-ORD-001 | GET existing order returns `Order` with numeric `total` | EP | `@api @smoke @p0 @candidate` | AC1 |
| TC-ORD-002 | GET unknown id returns 404 `Error` with `code` | EP | `@api @smoke @p1 @candidate` | AC2 |
| TC-ORD-003 | GET id 0 and −1 return 400 `Error` | BVA | `@api @regression @p2 @candidate` | AC3 |
| TC-ORD-004 | GET non-integer ids return 400 `Error` | EP | `@api @regression @p2 @candidate` | AC3 |
| TC-ORD-005 | GET overflow and injection ids never return 500 or foreign data | Error guessing | `@api @regression @p1 @candidate` | AC3, AC6 |
| TC-ORD-006 | GET one fixture order per status; `status` matches | State transition, all states | `@api @regression @p2 @candidate` | AC1 |
| TC-ORD-007 | POST minimal valid order returns 201 `Order`; GET round trip matches | EP, state transition | `@api @smoke @p0 @candidate` | AC4 |
| TC-ORD-008 | POST without `note` returns `Order` with no `null` note | EP | `@api @regression @p2 @candidate` | AC4 |
| TC-ORD-009 | POST with `items` missing, null, wrong type or `[]` returns 400 `Error` | EP, BVA | `@api @smoke @p1 @candidate` | AC5 |
| TC-ORD-010 | POST with non-string `items` elements returns 400 `Error` | EP | `@api @regression @p2 @candidate` | AC5 |
| TC-ORD-011 | POST with unknown SKU, empty-string SKU, duplicate SKU: recorded behaviour, never 500 | EP, error guessing | `@api @regression @p2 @candidate` | AC5 |
| TC-ORD-012 | POST with `note` of 500 characters returns 201 | BVA | `@api @regression @p1 @candidate` | AC4 |
| TC-ORD-013 | POST with `note` of 501 and 5,000 characters returns 400 `Error` | BVA | `@api @smoke @p1 @candidate` | AC5 |
| TC-ORD-014 | POST with multibyte `note` at the limit: record characters versus bytes, never 500 | BVA, error guessing | `@api @regression @p2 @candidate` | AC6 |
| TC-ORD-015 | POST with `note` of wrong type returns 400 `Error` | EP | `@api @regression @p2 @candidate` | AC5 |
| TC-ORD-016 | POST with hostile `note` content is stored and returned verbatim | Error guessing | `@api @regression @p1 @candidate` | AC4 |
| TC-ORD-017 | POST with empty or malformed body returns 400 `Error` | EP | `@api @regression @p1 @candidate` | AC5, AC6 |
| TC-ORD-018 | POST with wrong content type: recorded status, `Error` body | Error guessing | `@api @regression @p3 @candidate` | AC6 |
| TC-ORD-019 | POST with client-supplied `total`, `status`, `id` ignores them | Error guessing | `@api @regression @p1 @candidate` | AC4 |
| TC-ORD-020 | No token and expired token on both endpoints return 401 `Error` | Checklist (auth) | `@api @smoke @p0 @candidate` | AC6 |
| TC-ORD-021 | Another customer's order id never returns 200 with their data | Checklist (BOLA) | `@api @smoke @p0 @candidate` | AC6 |
| TC-ORD-022 | Wrong role on POST returns 403 `Error` | Checklist (auth) | `@api @regression @p1 @candidate` | AC6 |
| TC-ORD-023 | `PUT` and `DELETE /orders/{id}`, `GET /orders` return 405 or 404 with `Error` | Error guessing | `@api @regression @p3 @candidate` | AC6 |
| TC-ORD-024 | POST same body twice, with and without `Idempotency-Key`: recorded behaviour | Error guessing | `@api @regression @p2 @candidate` | AC4 |
| TC-ORD-025 | Every non-2xx body in the suite validates against `Error` (shared assertion) | Checklist | `@api @smoke @p1 @candidate` | AC6 |

Expected failures against build 2.1.0 as recorded on 2026-10-15: TC-ORD-001 (M1, M2), TC-ORD-002 (M3), TC-ORD-013 (M4 to M6), TC-ORD-025 (M3, M5). Those are findings, not tests to soften.

**Contract strategy.** Schema conformance checks are enough. The activity to make cheaper is test execution with response validation, which is a test execution and coverage tool in CTFL §6.1 terms; the tool is the test runner's HTTP client plus a JSON Schema validator that loads the OpenAPI document once and resolves its `$ref`s, run in CI on every deployment to staging. Consumer-driven contract tests are not justified on the evidence here: nothing shows several independently released consumers, a provider team that cannot see them, or a breaking change that has already reached a consumer. What the samples show is a provider that does not honour its own schema, and schema checks in CI catch exactly that at a fraction of the cost of a broker, a provider verification step and a second team's process. Revisit if a second consumer team ships on its own cadence.

**Automation plan, not written here.** The request forbade creating files, so no specs exist and the evidence checker was not run. The shape the specs should take:

- One helper, an orders client with `getOrder(id)` and `createOrder(body)` plus raw-request variants for malformed bodies and headers. Actions only, no assertions.
- Specs use the Playwright `request` fixture. Assumption: the repository uses Playwright; no repository was supplied. Otherwise the framework's own client.
- The OpenAPI document is loaded once; a validator built for the OAS 3.0 dialect validates every body against the schema for its status. The suite and the contract cannot drift apart silently.
- Red-green proof before any assertion counts: in a throwaway copy change `Order.total` to `type: string` and watch TC-ORD-001 fail with a type error, then revert.
- Cleanup is the blocker. There is no `DELETE`, so orders created by TC-ORD-007 to 024 stay on staging. Until an agreed cleanup path exists, such as an admin endpoint or a scheduled purge keyed on a `note` marker like `qa-<run-id>`, run the creating cases only against an ephemeral environment. The read-only and 400-path cases, which create nothing, can run on staging now.

**What this work cannot show.** Nothing was executed; all conformance claims rest on three samples from 2026-10-15. No 201, 400, 401, 403, 405 or 415 response has been observed. Status transitions beyond create are outside the contract. Load and fuzzing volumes are other activities.

**Rules.** The `qa-rules` skill is not installed, so the `context-discovery`, `testing-guidelines`, `test-tools`, `security-qa` and `test-evidence` rules were read from the project's own `.claude/rules` folder and applied. The `code-style-qa` rule was not applied because no test code was written. The evidence checker `check-test-evidence.sh` was not run because there is no spec directory.
