# Orders API 2.1.0: conformance of recorded responses and test design

## Contract and build under test

| Item | Value |
| --- | --- |
| Contract | OpenAPI 3.0.3, `Orders API` 2.1.0, supplied inline in the request. No URL or repository path given, so the inline document is treated as the authoritative copy (assumption). |
| Deployed version | 2.1.0 on staging, as stated by whoever recorded the responses. Not confirmed from a deployment record or version endpoint. |
| Recordings | Three responses dated 2026-10-15, ten days before this review. Nothing was run for this report. Every claim below about live behaviour is a claim about that date. |
| Auth model | The document declares no `securitySchemes`. Assumption: none is enforced. If a token is in fact required, the recordings omitted it, and the auth matrix below still applies. |
| Base URL | Not given. Staging environment, shared instance (assumption). |
| Deletion | The contract has no `DELETE /orders/{id}`, so test data created by `POST` cannot be removed through the API. This shapes the automation section. |

## Conformance of the recorded responses

Each recorded body was validated by hand against the schema the contract declares for that status. All three responses fail. Classification follows the rule that the contract is the declared truth: where the API departs from it, it is a software defect unless the owner confirms the contract is what is wrong, in which case it becomes documentation drift.

| # | Request and status | Declared (schema location) | Actual | Classification | Proposed owner |
| --- | --- | --- | --- | --- | --- |
| 1a | `GET /orders/1042` → 200 | `Order.total`: `type: number` | `"42.50"`, a string | **Software defect.** Generated and typed clients will fail to parse the field. Re-classify as drift only if the owner confirms money is deliberately a decimal string, in which case the schema needs `type: string` with a `pattern`. | API team |
| 1b | `GET /orders/1042` → 200 | `Order.note`: `type: string`, no `nullable: true`. OpenAPI 3.0.3 forbids `null` unless declared. | `null` | **Documentation drift.** `note` is optional and the API uses `null` for "not set". Either add `nullable: true` or omit the key when unset. | API document owner |
| 2 | `GET /orders/999999` → 404 | `Error` requires `code` and `message` | `{"message": "Order not found"}`, no `code` | **Software defect.** The declared machine-readable `code` is missing, so a client can only branch on message text. | API team |
| 3a | `POST /orders`, `items: ["sku-1"]`, `note` of 5,000 characters → 500 | `post /orders` declares 201 and 400 only. `NewOrder.note` declares no `maxLength`, so this request is **valid under the contract**. | 500 | **Software defect, high severity.** An unhandled database constraint turns a contract-valid request into a server error. The correct outcome is 201, or 400 with an `Error` body once a limit is declared. | API team |
| 3b | same | No schema for 500. Every declared error body is `{code, message}`. | `{"error": "..."}` | **Software defect.** An error body of an undeclared shape. Together with row 2, the API has at least two error shapes, neither matching the contract. | API team |
| 3c | same | No declared body exposes storage details. | `value too long for type character varying(500)`, a raw PostgreSQL message naming the column type and size | **Software defect, security.** Information disclosure: it fingerprints the database and the column definition. Belongs with 3a in the same defect report. | API team, security reviewer |
| 3d | same | `NewOrder.note` declares no boundary | Observed limit: 500 characters, from the `varchar(500)` column | **Documentation drift.** The real boundary exists and is undeclared. The product owner decides the limit; the document then declares `maxLength` and the 400 that enforces it. | Product owner, then API document owner |

**Open question from row 3a.** The recording does not show whether the 500 left a half-written order behind. Test P-20 below checks this, because a request that fails after an insert is a data defect on top of the status defect.

**What the contract does not say**, found by reading it alongside the recordings:

- No status for a path id outside its own schema: `/orders/0`, `/orders/-1`, `/orders/abc`, `/orders/1.5`. The document declares `minimum: 1` and `integer` and then documents only 200 and 404.
- No 401 or 403, consistent with no security scheme. If orders belong to customers, sequential integer ids with no auth make every order enumerable.
- No 405 (`PUT`, `DELETE` on `/orders/1`), no 415 (non-JSON content type), no 413, no 429, no status for malformed JSON.
- No `additionalProperties: false` on `NewOrder`, so unknown fields are silently allowed or silently dropped. Undeclared either way.
- No `minimum` on `total`, no `maxItems`, `uniqueItems` or item `pattern` on `items`, no `minLength` on an item string, so `[""]` is contract-valid.
- `status` enumerates `placed`, `paid`, `shipped` and the API exposes no operation that moves between them. Which status a new order gets is undeclared. Assumption used below: `placed`.
- No idempotency mechanism on `POST`. A retried create is allowed to duplicate.

**Defects to file through `/qa-defect`:** one report for rows 3a, 3b and 3c together (one failure, three symptoms), one for row 2, one for row 1a. Rows 1b and 3d go to the document owner as drift, not as defects.

## Test design

Test basis: the contract. The acceptance criteria below are derived from it, since none were supplied (assumption), and every case names the one it checks. All cases carry `@api`. Technique column uses CTFL v4.0 section numbers; schema conformance itself is good practice, not syllabus content.

| AC | Criterion |
| --- | --- |
| AC-1 | `GET /orders/{id}` with an existing id returns 200 and a body valid against `Order`. |
| AC-2 | `GET /orders/{id}` with a well-formed id that matches no order returns 404 and a body valid against `Error`. |
| AC-3 | `GET /orders/{id}` with an id outside the declared schema returns a 4xx with an `Error` body, never a 5xx. Status to be declared; 400 proposed. |
| AC-4 | `POST /orders` with a body valid against `NewOrder` returns 201, an `Order` body, and the order is then readable by `GET`. |
| AC-5 | `POST /orders` with a body invalid against `NewOrder` returns 400 and an `Error` body. |
| AC-6 | No request documented here produces a 5xx or a body outside the schema declared for its status. |
| AC-7 | No error body names internal components: database, column, table, stack frame. |

**GET /orders/{id}: partitions and boundaries**

| ID | Input for `id` | Technique | AC | Expected | Tags |
| --- | --- | --- | --- | --- | --- |
| G-01 | An order created by the test in the same run | EP valid (§4.2.1) | AC-1 | 200; body validates against `Order`; `total` is a JSON number; `note` is a string or absent, not `null`; `status` is in the enum | `@smoke @p0 @automated` |
| G-02 | `1` (declared minimum) | BVA (§4.2.2) | AC-1 or AC-2 | 200 with `Order` if it exists, else 404 with `Error`; never 5xx | `@regression @p1 @automated` |
| G-03 | `0` (minimum minus 1) | BVA | AC-3 | 4xx with `Error` body; record the status observed | `@regression @p1 @automated` |
| G-04 | `-1` | EP invalid | AC-3 | As G-03 | `@regression @p2 @automated` |
| G-05 | `999999` and an id one above the highest existing id | EP valid, non-existent | AC-2 | 404; body has `code` and `message` (currently fails, row 2) | `@smoke @p0 @automated` |
| G-06 | `abc`, `1.5`, `1e3`, `01042`, `1042 ` (trailing space, URL-encoded) | EP invalid, wrong type | AC-3 | 4xx with `Error`; `01042` must not resolve to 1042 silently, record what it does | `@regression @p2 @automated` |
| G-07 | `2147483648` and `9223372036854775808` (32-bit and 64-bit overflow) | BVA, undeclared upper bound | AC-3, AC-6 | 4xx or 404 with `Error`, never 500 | `@regression @p2 @automated` |
| G-08 | `1042;DROP TABLE orders`, `1042' OR '1'='1` | Error guessing (§4.4.1), injection | AC-3, AC-7 | 4xx with `Error`; no database text in the body | `@regression @p1 @automated` |
| G-09 | Same id twice | Idempotency of a safe method | AC-1 | Both bodies identical | `@regression @p3 @automated` |

**POST /orders: partitions and boundaries**

| ID | Body | Technique | AC | Expected | Tags |
| --- | --- | --- | --- | --- | --- |
| P-01 | `{"items": ["sku-1"]}`, no `note` | EP valid, `minItems` boundary | AC-4 | 201; `Order` body; `id` integer; `status` `placed` (assumption, record what is returned); `total` number; then `GET` of that id returns the same order | `@smoke @p0 @automated` |
| P-02 | Two items; then 100 items | EP valid; probe for undeclared `maxItems` | AC-4 | 201, or a 400 with `Error` at the real limit; record the limit as observed | `@regression @p2 @automated` |
| P-03 | `{"items": ["sku-1"], "note": "x"}` and `note` of 499 characters | BVA on the observed limit, valid side | AC-4 | 201; `note` echoed verbatim as a string | `@regression @p1 @automated` |
| P-04 | `note` of exactly 500 characters | BVA, boundary | AC-4 | 201; `note` echoed in full, no truncation | `@regression @p1 @automated` |
| P-05 | `note` of 501 characters | BVA, max plus 1 | AC-5, AC-6 | 400 with `Error` once the limit is declared; today's 500 is the defect of row 3a | `@regression @p0 @automated` |
| P-06 | `note` of 5,000 characters (the recorded case) | EP invalid, over-long | AC-5, AC-6, AC-7 | 400 with `Error`; no database text; no order persisted (see P-20) | `@regression @p0 @automated` |
| P-07 | `note` of 500 multi-byte characters (accented letters, then emoji) | BVA, character versus byte count | AC-4 | 201 if the limit is characters; record if it is bytes, since the contract says neither | `@regression @p2 @automated` |
| P-08 | `note: ""` | EP valid (no `minLength` declared) | AC-4 | 201; record whether `note` comes back as `""`, absent or `null` | `@regression @p3 @automated` |
| P-09 | `note: null`, `note: 123`, `note: {}` | EP invalid, wrong type | AC-5 | 400 with `Error` | `@regression @p1 @automated` |
| P-10 | `items` missing | EP invalid, required field | AC-5 | 400 with `Error` | `@smoke @p0 @automated` |
| P-11 | `items: []` | BVA, `minItems` minus 1 | AC-5 | 400 with `Error` | `@smoke @p0 @automated` |
| P-12 | `items: null`, `items: "sku-1"`, `items: [1]`, `items: [null]` | EP invalid, wrong type | AC-5 | 400 with `Error` | `@regression @p1 @automated` |
| P-13 | `items: [""]` and an item of 5,000 characters | Undeclared `minLength` and `maxLength` on items | AC-5, AC-6 | Contract-valid, so 201 or a declared 400; never 500. Record the real limits | `@regression @p1 @automated` |
| P-14 | `items: ["sku-1", "sku-1"]` | Undeclared `uniqueItems` | AC-4 | Record: two lines or one; `total` consistent with the choice | `@regression @p3 @manual` |
| P-15 | `items: ["sku-does-not-exist"]` | Business rule, undeclared | AC-5 | Record: 400 with `Error`, or 201 and a `total` of 0. A question for the owner either way | `@regression @p1 @manual` |
| P-16 | Empty body; malformed JSON `{"items": [`; a JSON array `[]`; `Content-Type: text/plain` | Error guessing on the envelope | AC-5, AC-6 | 400 (or 415 for the content type) with `Error`; never 500 | `@regression @p1 @automated` |
| P-17 | Valid body plus `"id": 1`, `"status": "shipped"`, `"total": 0` | Error guessing, mass assignment | AC-4 | 201; returned `id`, `status` and `total` are server-assigned and ignore the client values | `@regression @p0 @automated` |
| P-18 | Valid body plus an unknown field `"x": 1` | Undeclared `additionalProperties` | AC-4 | Record: 201 with the field dropped, or 400 | `@regression @p3 @automated` |
| P-19 | Same valid body sent twice | Idempotency and retries | AC-4 | No idempotency key is declared, so two orders with different ids is the expected observation. Record it and raise the duplicate-on-retry risk with the owner | `@regression @p1 @automated` |
| P-20 | After P-05 and P-06, count orders carrying the run's unique note prefix | Side effect of a failed create | AC-6 | Zero orders persisted by the failed requests | `@regression @p0 @automated` |

**Response-body assertions common to every case.** Status and body together: the body is validated against the schema the contract declares for that exact status, including 400 and 404. Any status the contract does not declare for the operation fails the test on its own, before the body is inspected.

**Resource state model** (§4.2.4). States: `placed`, `paid`, `shipped`, from the enum. Events this API exposes: create (`POST`) and read (`GET`). No event in the contract moves an order between states and none deletes it, so the only transitions reachable here are "no order → placed" and "placed → read". Assumption: payment and fulfilment systems change `status` out of band.

- S-01: create, then read: `status` is `placed`, `total` equals the sum for the items (AC-4). `@regression @p1 @automated`
- S-02: read an order in each enum state (`paid`, `shipped`): body validates, `status` is exactly the enum value (AC-1). Needs fixture orders in those states, provided by the owning team, read-only. `@regression @p2 @manual`
- S-03: invalid transitions through this API: `PUT /orders/{id}`, `PATCH`, `DELETE` with an existing id. Expected 405 with an `Error` body, never 500 and never a silent state change (AC-6). One invalid transition per case. `@regression @p1 @automated`
- Not coverable here: paid → placed, shipped → paid, cancel, and any terminal state. The enum has no cancelled or refunded value, which is a question for the owner, not a test.

**Auth matrix.** The contract declares no security scheme, so the first result of this matrix is a finding either way.

| Case | `GET /orders/{id}` | `POST /orders` |
| --- | --- | --- |
| No token | If 200 and 201: the API is open. Pair with G-05 and the sequential ids: any client can enumerate every order. High-severity security finding, to the owner. If 401 with `Error`: the contract omits the scheme, drift. | Same |
| Expired token | 401 with `Error` | 401 with `Error` |
| Another user's order id | 403 or 404 with `Error`, no body of the other user's order (BOLA check per the security reference) | n/a |
| Wrong role, e.g. read-only service account | 200 if read is allowed to that role | 403 with `Error` |

All `@regression @p0 @automated` once the auth model is known. Until then they run as `@manual` to discover it. CSRF does not apply to a bearer-token JSON API; if the service uses cookies, the `POST` cases need the anti-CSRF check from the same reference.

**Error contract.** Declared: 400 and 404, both `{code, message}`. Observed shapes on 2026-10-15: `{message}` on 404 and `{error}` on 500, so no observed error matched the contract. Undeclared and to be observed: the 4xx for bad path ids (G-03 to G-08), 401 and 403, 405 (S-03), 415 and the malformed-JSON status (P-16), 413 for a multi-megabyte body, 429 if rate limiting exists. For every one of them the assertion is the same: the body validates against `Error`, and no body contains database, column, table or stack-frame text (AC-7). Where business-rule errors (P-15) and validation errors (P-11) turn out to use different shapes, each shape gets its own documented schema and its own test.

**Automation outline** (no specs written here, by request). Runner's HTTP client: the Playwright `request` fixture if the repository uses Playwright, otherwise the framework's own client. One helper, `OrdersApi`, with `getOrder(id)` and `createOrder(body)` returning the raw response, no assertions. The OpenAPI document is loaded and dereferenced once per worker; a `validate(status, operation, body)` helper compiles the component schema for that status with a JSON Schema validator, so the contract and the tests cannot drift apart silently. Each spec follows arrange, act, assert, with no sleeps. Data isolation on the shared staging instance: every created order carries a `note` prefixed with a unique run id, and the run ends by listing what it created. Because the contract has no delete, created orders cannot be removed through the API. This is a constraint to raise now: either an internal cleanup route, a scheduled purge of the prefix, or a dedicated test tenant. Each new assertion gets a red-green proof: alter the expected type in a throwaway copy of the schema, watch the test fail for that reason, keep the output. The evidence checker was not run, since no specs exist yet.

**Contract strategy.** Schema conformance checks are enough. The activity is provider-side conformance, kept running in CI on every build of the provider: the operation's declared schema per status, validated against real responses, which would have caught all seven rows above. The tool category is a JSON Schema validator inside the existing API test runner, so no new process or broker is needed. Consumer-driven contracts are not justified on what is known: nothing in the request shows several independently released consumers, a provider team that cannot see them, or a breaking change that has already reached one. Revisit if a second consumer team ships on its own cadence. Any stub of this API used by a consumer's tests is testware and proves only that consumer, never this provider.

**What this report cannot show.** Nothing was executed for it. The three recordings are ten days old on a shared instance that may have changed. No 201 and no 400 was ever observed, so the positive create path and the declared validation error are both unverified. The auth model, whether the 500 persisted an order, the real limits on `items`, and the status of a new order are all unknown until the cases above run.

**Rules not applied.** The `qa-rules` skill is not installed, so the `context-discovery`, `testing-guidelines`, `code-style-qa`, `security-qa`, `test-tools` and `test-evidence` rules were not loaded. Their detail files in `qa-reference` (`testing-design.md`, `security-checks.md`) were read and used for techniques, the auth checks and the field heuristics. The `check-test-evidence.sh` hook was not run.
