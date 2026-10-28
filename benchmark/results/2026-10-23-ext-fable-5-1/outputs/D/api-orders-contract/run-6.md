# Orders API 2.1.0: contract check, conformance findings and test design

Nothing in this report was run by me. The three responses were recorded by the requester on staging on 2026-10-15; every claim about live behaviour carries that date. The schema was read; the service was not called. No files were created.

## 1. Contract

| Item | Value |
| --- | --- |
| Contract | OpenAPI 3.0.3 document pasted with the request, `info.version` 2.1.0, read 2026-10-25 |
| Deployed version under test | 2.1.0 on staging, as stated with the recordings. Assumption: taken from the deployment record. Not confirmed by me through a version endpoint or deploy log. |
| Environment and base URL | Staging. Host not given. Assumption: one shared instance, so every write below is a unique, marked record. |
| Auth model | The document declares no `securitySchemes` and no `security`. Assumption: the recordings were made without credentials. If staging requires a token, the contract omits it (finding S-1 below). |
| Operations | `GET /orders/{id}` (200, 404) and `POST /orders` (201, 400). No list, update, delete or state-change operation. |
| Sample | Three responses. The documented 201 and 400 were never recorded, so the POST happy path and the documented validation path are both unverified. |

## 2. Conformance: recorded responses against the declared schemas

Each recorded body was checked against the schema declared for its status, the status against the documented list, and the response against what the schema leaves unsaid.

| # | Request (2026-10-15) | Declared | Actual | Classification | Owner |
| --- | --- | --- | --- | --- | --- |
| C-1 | `GET /orders/1042` → 200 | `Order.total: { type: number }` | `"total": "42.50"` is a JSON string | **Software defect** (provisional). A consumer coded to the contract does arithmetic on a string. If the team chose string decimals deliberately for money precision, reclassify as drift and change the schema to `type: string` with a pattern. Either way the two must agree. | API team, decision by the API owner |
| C-2 | same | `Order.note: { type: string }`, no `nullable: true` (OpenAPI 3.0.3 needs the keyword to allow null) | `"note": null` | **Documentation drift** (provisional). The API emits the key as null when no note was given. Fix in the document (`nullable: true`) or in the serializer (omit the key). | Document owner |
| C-3 | `GET /orders/999999` → 404 | `Error.required: [code, message]` | `{"message": "Order not found"}`, no `code` | **Software defect.** Clients cannot branch on the error kind. The status is right; the body is not. | API team |
| C-4 | `POST /orders`, note of 5,000 chars → 500 | Documented statuses: 201, 400 | 500 | **Software defect.** An over-long input is a validation failure, so the contract's 400 with an Error body applies. The database constraint is doing the validator's job. | API team, file with `/qa-defect` |
| C-5 | same | 400 → `Error` | `{"error": "value too long for type character varying(500)"}` matches no declared schema | **Software defect**, same root cause as C-4. One report, two observations. | API team |
| C-6 | same | `NewOrder.note` declares no `maxLength` | Real boundary is 500 characters, set by the column | **Documentation gap.** Add `maxLength: 500` once the API owner confirms 500 is the intended limit, not an accident of the column type. | Document owner and API owner |
| C-7 | same | No statement about error content | The message leaks a database type and column width | **Security finding**, information disclosure. The `security-qa` rule forbids stack traces in output; database internals fall under the same item. Include in the C-4 report. | API team |

Two observed error shapes, `{message}` and `{error}`, plus the declared `{code, message}` means three error shapes are in play. Nothing recorded conforms to the declared one.

Shared-environment note on C-4: a 500 from a column constraint normally rolls the insert back, but the API has no list endpoint and the response carries no id, so whether a partial order was left on staging cannot be checked through the API. The team should check the store directly.

What the schema does not say, found while checking:

- **S-1 Auth.** No security scheme. Either the API is open, which the owner must confirm, or the contract omits 401 and 403.
- **S-2 GET with an invalid id.** `minimum: 1` and `type: integer` are declared, but no 400 is documented for `0`, `-1`, `abc` or `1.5`.
- **S-3 Method and media type.** No 405 for `PUT /orders/1`, no 415 for a non-JSON body, no 429.
- **S-4 Item limits.** `items` has `minItems: 1` and no `maxItems`; each element is a string with no `maxLength` and no statement that it must be a known SKU.
- **S-5 Status lifecycle.** The enum names `placed`, `paid`, `shipped`, but no operation moves an order between them and nothing says which status a new order gets.
- **S-6 Money as number.** `total: number` permits floats. Whether this is the intended wire type ties into the C-1 decision.

## 3. Test design

Acceptance criteria are derived from the contract because no ticket was given. All five are assumptions until the owner confirms them.

- **AC1** GET of an existing id returns 200 with an `Order` body.
- **AC2** GET of an unknown id returns 404 with an `Error` body.
- **AC3** POST of a valid `NewOrder` returns 201 with an `Order` body whose status is `placed`.
- **AC4** POST of an invalid `NewOrder` returns 400 with an `Error` body and creates nothing.
- **AC5** No client input produces a 5xx, and every non-2xx body is an `Error`.

Every case asserts the status **and** validates the body against the schema declared for that status. Every case carries `@api` and `@orders`, plus the suite, priority and automation tags shown. Level: system testing against the staging instance.

**GET /orders/{id}: partitions and boundaries for `id`** (integer, minimum 1)

| Case | Input | Expected | Technique | AC | Tags |
| --- | --- | --- | --- | --- | --- |
| G-01 | id of an order the test created | 200; `Order` schema; `id` equals; `status` in enum; `total` is a number | EP, valid | AC1 | @smoke @p0 @candidate |
| G-02 | id above any existing order | 404; `Error` with `code` and `message` | EP, invalid | AC2 | @smoke @p1 @candidate |
| G-03 | id = 1 | 200 or 404, never 400 or 500 | BVA, min | AC1, AC2 | @regression @p2 @candidate |
| G-04 | id = 0 | Undocumented. Proposed: 400 `Error`. Record what staging does. | BVA, min-1 | AC5 | @regression @p2 @candidate |
| G-05 | id = -1 | As G-04 | EP, invalid | AC5 | @regression @p3 @candidate |
| G-06 | id = `abc` | As G-04 | EP, wrong type | AC5 | @regression @p2 @candidate |
| G-07 | id = `1.5` | As G-04 | EP, wrong type | AC5 | @regression @p3 @candidate |
| G-08 | id = 9223372036854775808 | 400 or 404, never 500 | BVA, overflow | AC5 | @regression @p2 @candidate |
| G-09 | id = `1 OR 1=1` | 400, never 500, no data | Error guessing | AC5 | @regression @p1 @candidate |
| G-10 | id of a fixture order in each of `paid` and `shipped` (read only, never mutated) | 200; `status` is the expected enum value | EP per state | AC1 | @regression @p2 @candidate |
| G-11 | id of an order created without a note | 200; `note` absent or null per the C-2 decision | EP, optional field | AC1 | @regression @p2 @deferred until C-2 is decided |

**POST /orders: partitions and boundaries per field.** `items`: array of string, `minItems: 1`, required. `note`: string, optional, observed limit 500.

| Case | Body | Expected | Technique | AC | Tags |
| --- | --- | --- | --- | --- | --- |
| P-01 | `{"items": ["sku-1"]}` | 201; `Order` schema; `status` = `placed`; `total` is a number | EP, valid (positive half) | AC3 | @smoke @p0 @candidate |
| P-02 | items `["sku-1"]`, note `"qa-<runId>"` | 201; `note` echoed exactly | EP, valid optional | AC3 | @smoke @p1 @candidate |
| P-03 | items `["sku-1", "sku-2"]` | 201; total reflects both | EP, valid | AC3 | @regression @p1 @candidate |
| P-04 | items `[]` | 400 `Error`; GET of any returned id is 404 | BVA, minItems-1 | AC4 | @smoke @p1 @candidate |
| P-05 | `items` missing | 400 `Error` | EP, missing required | AC4 | @regression @p1 @candidate |
| P-06 | items `null` | 400 `Error` | EP, null | AC4 | @regression @p2 @candidate |
| P-07 | items `"sku-1"` | 400 `Error` | EP, wrong type | AC4 | @regression @p2 @candidate |
| P-08 | items `[1]` | 400 `Error` | EP, wrong element type | AC4 | @regression @p2 @candidate |
| P-09 | items `[""]` | Undocumented. Proposed 400. Record. | BVA, empty element | AC4 | @regression @p2 @candidate |
| P-10 | items `["no-such-sku"]` | Undocumented: the schema allows any string. Record whether business validation exists and with which shape. | Error guessing | AC4 | @regression @p1 @candidate |
| P-11 | items with 100, then 1,000 elements | Undocumented maximum. Bounded probe; never 500. Record the real limit for the document. | BVA, undeclared max | AC5 | @regression @p2 @candidate |
| P-12 | note of 499 chars | 201 | BVA, max-1 | AC3 | @regression @p1 @candidate |
| P-13 | note of 500 chars | 201 | BVA, max | AC3 | @regression @p1 @candidate |
| P-14 | note of 501 chars | 400 `Error` (today: 500, defect C-4) | BVA, max+1 | AC4, AC5 | @regression @p1 @candidate |
| P-15 | note `""` | Undocumented. Record. | BVA, empty | AC3 | @regression @p3 @candidate |
| P-16 | note `null` | 400 per the schema as written. Record; depends on C-2. | EP, null | AC4 | @regression @p2 @deferred until C-2 is decided |
| P-17 | note `123` | 400 `Error` | EP, wrong type | AC4 | @regression @p2 @candidate |
| P-18 | note of 500 four-byte characters | 201. A byte-counting validator would wrongly reject at 2,000 bytes. | Error guessing | AC3 | @regression @p2 @candidate |
| P-19 | valid body plus `"total": 0`, `"id": 1`, `"status": "shipped"` | 201; returned `total`, `id` and `status` ignore the input (mass assignment) | Error guessing, security | AC3 | @regression @p1 @candidate |
| P-20 | empty body | 400 `Error` | EP, missing body | AC4 | @regression @p2 @candidate |
| P-21 | malformed JSON | 400 `Error`, never 500 | Error guessing | AC5 | @regression @p1 @candidate |
| P-22 | `Content-Type: text/plain` with a valid JSON string | Undocumented. Proposed 415 `Error`. Record. | Error guessing | AC5 | @regression @p3 @candidate |
| P-23 | note with the XSS payload from the `qa-reference` skill's security checks | 201; stored as sent; JSON-escaped on read. Rendering safety is the consumer's test. | Checklist, security | AC3 | @regression @p2 @candidate |
| P-24 | same valid body sent twice | Two orders with different ids. The contract promises no idempotency; record the behaviour and recommend an `Idempotency-Key` header if clients retry. | Error guessing, idempotency | AC3 | @regression @p2 @candidate |

**Resource state model.** From the enum: `placed` → `paid` → `shipped`. The only event this API exposes is create, which should land in `placed` (AC3, assumption). The `paid` and `shipped` transitions are driven elsewhere, presumably by payment and fulfilment systems, so invalid transitions such as ship-before-pay cannot be attempted through this contract and are out of this suite's scope. What the suite can check: T-01, create then read gives `placed` (P-01 plus G-01); T-02, a fixture order in each state reads back with that enum value (G-10); T-03, any status outside the enum is a conformance failure. Coverage criterion: all states, which is the weakest, because the API offers no transitions to exercise.

**Auth matrix.** The contract declares nothing, so every row records behaviour rather than asserting a documented status.

| Row | Both endpoints | Expected if auth exists | If the API is open |
| --- | --- | --- | --- |
| A-01 | No token | 401 `Error` | 200 or 201: raise S-1 to the owner |
| A-02 | Expired token | 401 `Error` | As above |
| A-03 | Valid token, another user's order id | 404 or 403 `Error`, never the other user's body | Any client reads any order: an authorization finding, not a test failure |
| A-04 | Wrong role on POST | 403 `Error` | As A-01 |

**Error contract.** Documented: 404 on GET and 400 on POST, both `Error`. Not documented: 400 on GET, 401, 403, 405, 415, 429 and 500. Case E-01 validates every non-2xx body in the suite against `Error`, so the undocumented statuses surface as failures the owner then documents or fixes. Case E-02 sends `PUT /orders/1` and `DELETE /orders/1` and expects 405 with an `Error` body.

**Idempotency and retries.** GET repeated returns the same body (I-01, @regression @p2). POST retried duplicates, per P-24. No PUT or DELETE exists, so there is nothing to test for repeat-same-state.

## 4. Automation plan, contract strategy and limits

**Automation scope.** Only what sections 2 and 3 justify: the G, P, A, E and I cases above in one Playwright project tagged `@api`, using the `request` fixture. Assumption: the repository uses Playwright. If it does not, the framework's own HTTP client takes its place. Structure per the `code-style-qa` rule:

- An `OrdersApi` helper with one action per endpoint, `getOrder` and `createOrder`, and no assertions.
- The OpenAPI document loaded once and compiled with a JSON Schema validator. Each test resolves the schema for its status from the document, so the contract and the tests cannot drift apart silently.
- Each test creates its own order with a unique marker in `note`. The API has no DELETE, so tests cannot remove what they create. This is a shared-environment constraint to raise now: either a cleanup job owned by the team keyed on the marker, or a delete endpoint. Until one exists, writes on staging accumulate.
- The suite will be red on C-1, C-3, C-4 and C-5 from the first run. That is the correct state. Each failing case links to its defect report and is not adjusted to pass.
- Red-green proof per case before it counts: in a throwaway copy, change `total` to `type: string` and watch G-01 flip, change `required` in `Error` and watch G-02 flip. Keep the output.
- The package's `check-test-evidence.sh` exists in `.claude/hooks/` but was not run, because no specs were written in this session.

**Contract strategy.** Schema conformance checks are enough. The activity is test execution with automatic result checking, CTFL §6.1 category: test execution tools. The tool is the runner's HTTP client plus a JSON Schema validator fed by the OpenAPI document, kept running in CI against staging. Consumer-driven contracts are not justified: the request names one provider and no consumers, there is no evidence of several independently released consumers, and no evidence that a breaking change has reached one. All seven findings are the provider disagreeing with its own document, which schema checks catch at the lowest cost. Revisit if a second consumer team starts shipping on its own cadence.

**What this report cannot show.**

- No request was sent. "Conforms" appears nowhere above for that reason.
- The 201 and 400 responses were never observed, so AC3 and AC4 are untested.
- Staging may have changed since 2026-10-15, and the 2.1.0 version is as reported, not confirmed by me.
- Whether C-4 left a partial record on staging cannot be checked through this API.
- All rules named by the skill were loaded and applied. The `code-style-qa` and `test-evidence` rules apply to step 4, which was planned but not executed.
