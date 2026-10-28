# Orders API 2.1.0: conformance report and test design

## 1. Contract, build and scope of this check

- **Contract:** the OpenAPI 3.0.3 document in the request (Orders API, version 2.1.0). No path or URL was given, so the assumption is that this is the published document for 2.1.0. Read on 2026-10-25.
- **Build under test:** staging, version 2.1.0, as stated in the recording note of 2026-10-15. This was not confirmed from a deployment record or version endpoint. Assumption: the note is accurate. Staging may have changed in the ten days since, so every claim about live behaviour below is dated 2026-10-15.
- **Auth model:** the document declares no `securitySchemes`. Assumption: staging requires a bearer token and the recordings carried one. If the API is really open, that is finding F-8.
- **Base URL and environment:** not given. Assumption: staging, shared.
- **What was run:** nothing. The three responses were recorded by someone else and only read here. The evidence checker was not run because no specs exist yet. "Conforms" below means the recorded body conforms. It says nothing about statuses never recorded (201, 400, auth errors).

## 2. Conformance: recorded responses against the declared schema

| # | Request (2026-10-15) | Declared | Actual | Classification | Proposed owner |
| --- | --- | --- | --- | --- | --- |
| F-1 | GET /orders/1042, 200 | `Order.total` is `number` | `"total": "42.50"` (string) | **Software defect**, provisional. If the string is a deliberate decimal-safe choice, reclassify as documentation drift, but then the contract change is breaking and needs a version bump | API team; docs owner if drift |
| F-2 | GET /orders/1042, 200 | `Order.note` is `string`, not nullable (OpenAPI 3.0 has no `nullable: true` here) | `"note": null` | **Documentation drift**, likely. Fix is either `nullable: true` or omitting the key when empty. Owner decides which | Docs owner, with API team |
| F-3 | GET /orders/999999, 404 | `Error` requires `code` and `message` | `{"message": "Order not found"}`; `code` missing | **Software defect.** If no endpoint anywhere emits `code`, it becomes drift and the contract should drop the field | API team |
| F-4 | POST /orders, 5,000-char note | Documented statuses: 201, 400 | 500 | **Software defect.** An over-long note is invalid input and must be a 400 with an `Error` body | API team |
| F-5 | Same request | Error body shape `{code, message}` | `{"error": "..."}`, a third shape | **Software defect.** The unhandled-error path has its own body shape, so clients cannot parse errors uniformly | API team |
| F-6 | Same request | Nothing about internals in any body | Raw PostgreSQL message naming the DBMS and the column type `character varying(500)` | **Security defect** (sensitive data exposure, the `security-qa` rule). Stack-level detail reaches the client | API team, security |
| F-7 | Same request | `NewOrder.note` has no `maxLength` | Storage limit is 500 characters | **Documentation gap** plus missing validation. Declare `maxLength: 500` and validate before the write | Docs owner and API team |
| F-8 | All | No `securitySchemes`, no 401 or 403 | Unknown; not recorded | **Documentation gap** at minimum. If the API is open, a security defect: anyone can read any order by id | Docs owner; security if open |

**What conforms in the recordings.** Response 1 carries all three required keys, `id` is an integer, `status` is in the enum. Response 2 returns 404 for a well-formed id that does not exist, which is the documented status. Response 3 returns a status the contract does not allow, so nothing in it conforms.

**What the schema does not say, found by reading it.** No 400 is documented for GET with an id below the minimum or a non-integer. No `maximum` on `id`, no `maxLength` on `note` or on `items[]`, no `maxItems` on `items`, no `minimum` on `total`. No 405, 413 or 415. The `Order` schema does not return `items`, so a client cannot verify what it ordered from the 201 body. That last point is a static-review observation for `/qa-static`, not a mismatch.

**Side effect of F-4 not yet known.** Whether the failed insert left a partial order on staging is unknown. A single-table insert rolls back, but a two-step write (order row, then note) could leave a row. Check with the team before deciding the severity of F-4.

**Suggested severity for `/qa-defect`.** F-4 to F-6 together as one P1 report (unhandled error plus information leak). F-1 as P1 (a client doing arithmetic on `total` breaks silently). F-3 as P2. F-2 as P3 until the owner decides direction. F-8 as a question to the owner before filing.

## 3. Test design

The contract is the only acceptance criterion available, so cases cite it as AC-G200 (GET returns `Order`), AC-G404 (GET returns `Error` for an unknown id), AC-P201 (POST returns `Order`), AC-P400 (POST returns `Error` for an invalid order) and AC-X (behaviour the contract leaves undocumented; the expected value is an assumption and the observed value is recorded as a finding). Every case asserts status and validates the body against the schema for that status, loaded once from the OpenAPI document. Every case carries `@api @orders` plus the tags shown.

**GET /orders/{id}: partitions and boundaries of `id`.** Valid: integer at or above 1 that exists; integer at or above 1 that does not exist. Invalid: 0, negative, non-integer text, decimal, above the undeclared maximum, injection text. Two-value BVA at the declared minimum: 0 and 1. The upper boundary is undeclared, so it is probed and recorded, not asserted.

| ID | Input | Technique | Expected | AC | Tags |
| --- | --- | --- | --- | --- | --- |
| TC-ORD-001 | id of a fixture order (1042) | EP valid | 200; `Order` schema; `total` is a number; `note` string or absent. Fails today on F-1 and F-2 | AC-G200 | @smoke @p0 @candidate |
| TC-ORD-002 | 999999 | EP valid, not found | 404; `Error` with `code` and `message`. Fails today on F-3 | AC-G404 | @smoke @p1 @candidate |
| TC-ORD-003 | 1 | BVA at minimum | 200 or 404 by data; body matches that status; never 400 | AC-G200 | @regression @p2 @candidate |
| TC-ORD-004 | 0 | BVA below minimum | 400 `Error` (assumption); record actual | AC-X | @regression @p2 @candidate |
| TC-ORD-005 | -1 | EP invalid | As TC-ORD-004 | AC-X | @regression @p3 @candidate |
| TC-ORD-006 | `abc` | EP wrong type | 400 `Error` (assumption); never 500 | AC-X | @regression @p2 @candidate |
| TC-ORD-007 | `1.5` | EP wrong type | As TC-ORD-006 | AC-X | @regression @p3 @candidate |
| TC-ORD-008 | 2147483648, then 9223372036854775808 (one per test) | BVA at undeclared maximum | 404 or 400 with `Error`; never 500; record the real limit | AC-X | @regression @p2 @candidate |
| TC-ORD-009 | `1 OR 1=1`, `1;--`, `../` (one per test) | Error guessing, security | 400 `Error`; no 500; no DBMS text in the body | AC-X | @regression @p1 @candidate |
| TC-ORD-010 | One fixture id per status: placed, paid, shipped | State coverage (all states) | 200; `status` equals the fixture's state. Assumption: read-only fixtures exist per status | AC-G200 | @regression @p2 @candidate |
| TC-ORD-011 | Same GET twice | Idempotency of a safe method | Identical bodies | AC-G200 | @regression @p3 @candidate |
| TC-ORD-012 | Fixture order with no note | EP optional field | `note` absent or a string; `null` fails until the contract says nullable (F-2) | AC-G200 | @regression @p2 @candidate |

**POST /orders: partitions and boundaries per field.** `items`: missing, null, wrong type (string, object), empty array, one element, two elements, element of wrong type, empty-string element, unknown SKU, many elements. `note`: absent, empty, normal, 500 characters, 501 characters, 5,000 characters, 500 multibyte characters, null, number, hostile text. Body: empty, malformed JSON, wrong content type, extra property, JSON array. Each test creates its order with a note marker `qa-<runId>` so it can be found later.

| ID | Input | Technique | Expected | AC | Tags |
| --- | --- | --- | --- | --- | --- |
| TC-ORD-020 | `{"items":["sku-1"]}` | EP valid; BVA `minItems` | 201; `Order` schema; `status` is `placed` (assumption: initial state); `total` a number; then GET by the new id returns the same body | AC-P201 | @smoke @p0 @candidate |
| TC-ORD-021 | items plus a short note | EP valid | 201; `note` echoed verbatim | AC-P201 | @smoke @p1 @candidate |
| TC-ORD-022 | `{}` (no `items`) | EP missing required | 400 `Error` with `code` and `message` | AC-P400 | @smoke @p1 @candidate |
| TC-ORD-023 | `{"items":[]}` | BVA `minItems` minus one | 400 `Error` | AC-P400 | @regression @p1 @candidate |
| TC-ORD-024 | two items | BVA `minItems` plus one | 201 | AC-P201 | @regression @p2 @candidate |
| TC-ORD-025 | `"items": null` | EP null | 400 `Error` | AC-P400 | @regression @p2 @candidate |
| TC-ORD-026 | `"items": "sku-1"` and `"items": {}` (one per test) | EP wrong type | 400 `Error` | AC-P400 | @regression @p2 @candidate |
| TC-ORD-027 | `[1]`, `[null]`, `[{}]` (one per test) | EP wrong element type | 400 `Error` | AC-P400 | @regression @p2 @candidate |
| TC-ORD-028 | `[""]` | Positive half of an undeclared rule | Contract says 201; if 400, record as an undeclared business rule | AC-X | @regression @p2 @candidate |
| TC-ORD-029 | `["no-such-sku"]` | Error guessing, undeclared rule | Contract says 201; a 400 is a documentation gap; record | AC-X | @regression @p2 @candidate |
| TC-ORD-030 | 100 items, then 1,000 items (one per test) | BVA at undeclared `maxItems` | 201, or 400 `Error`; never 500; record the limit | AC-X | @regression @p2 @candidate |
| TC-ORD-031 | `"note": ""` | EP empty string | 201 per contract; record | AC-P201 | @regression @p3 @candidate |
| TC-ORD-032 | note of exactly 500 characters | BVA at the observed storage limit, positive half | 201; note returned in full | AC-P201 | @regression @p1 @candidate |
| TC-ORD-033 | note of 501 characters | BVA limit plus one | 400 `Error`; today a 500 (F-4) | AC-P400 | @regression @p1 @candidate |
| TC-ORD-034 | note of 5,000 characters | Regression of the recorded failure | 400 `Error`; no DBMS text | AC-P400 | @smoke @p1 @candidate |
| TC-ORD-035 | 500 four-byte characters (emoji) | Error guessing: characters versus bytes | 201; detects a validator counting bytes while the column counts characters | AC-P201 | @regression @p2 @candidate |
| TC-ORD-036 | `"note": null` | EP null | 400 `Error` per contract; record actual (ties to F-2) | AC-P400 | @regression @p2 @candidate |
| TC-ORD-037 | `"note": 123` | EP wrong type | 400 `Error` | AC-P400 | @regression @p2 @candidate |
| TC-ORD-038 | note with `<script>` and `' OR 1=1` payloads (one per test) | Security, injection | 201; stored and returned verbatim as a string; never 500 | AC-P201 | @regression @p1 @candidate |
| TC-ORD-039 | empty body | EP invalid body | 400 `Error` | AC-P400 | @regression @p2 @candidate |
| TC-ORD-040 | malformed JSON | EP invalid body | 400 `Error`, not 500 | AC-P400 | @regression @p1 @candidate |
| TC-ORD-041 | `Content-Type: text/plain` with a JSON body | Error guessing | 415 or 400 with `Error`; undocumented; record | AC-X | @regression @p3 @candidate |
| TC-ORD-042 | valid body plus `"foo": 1` | EP unknown property | 201 ignoring it, or 400; undocumented; record | AC-X | @regression @p3 @candidate |
| TC-ORD-043 | body is a JSON array | EP wrong root type | 400 `Error` | AC-P400 | @regression @p3 @candidate |
| TC-ORD-044 | identical valid POST sent twice | Idempotency | Two distinct ids. The contract promises no deduplication, so this records behaviour and supports a request for an `Idempotency-Key` header | AC-X | @regression @p2 @candidate |
| TC-ORD-045 | after TC-ORD-033, confirm no order was persisted | Side effect of a failed write | No row; needs DB access or a list endpoint, neither of which the contract offers | AC-X | @regression @p1 @manual-only |
| TC-ORD-046 | 201 response headers | Error guessing | `Location` header present or not; undocumented; record | AC-X | @regression @p3 @candidate |

**Resource state model.** The enum gives three states: placed, paid, shipped. The only event in this contract is create, which should land in placed (assumption, since no state is documented as initial). Pay, ship, cancel and delete are not exposed, so invalid transitions such as delete twice or update after delete cannot be attempted through this API. Transition events happen outside the contract, and GET must reflect them, which TC-ORD-010 covers with fixtures. Coverage criterion: all states. Valid-transition and all-transition coverage are out of reach until the contract exposes the events.

**Auth matrix.** The contract declares no scheme, so every expected value here is an assumption and every observed value is a finding.

| ID | Endpoint | Condition | Expected | Tags |
| --- | --- | --- | --- | --- |
| TC-ORD-050 | GET, POST (one per test) | no token | 401 with an `Error` body | @smoke @p0 @candidate |
| TC-ORD-051 | GET, POST | expired token | 401 with an `Error` body | @regression @p1 @candidate |
| TC-ORD-052 | GET | another user's order id | 404 or 403, never the order body (BOLA) | @smoke @p0 @candidate |
| TC-ORD-053 | POST | read-only role | 403 with an `Error` body | @regression @p1 @candidate |
| TC-ORD-054 | POST | cookie session without an anti-CSRF token, if sessions are cookie-based | 403; not applicable with bearer-only auth; record which | @regression @p1 @candidate |

**Error contract.** Documented: 404 `Error` on GET, 400 `Error` on POST. Observed: a `{message}` shape on 404 and an `{error}` shape on 500, so three shapes are in play against one declared. Not documented at all: 400 on GET, 401, 403, 405, 413, 415, 500. Each test of an undocumented status asserts the `Error` shape anyway, so that the moment the contract adds the status the test is already right.

**Automation notes.** Use the runner's HTTP client with a helper that has one action per endpoint and no assertions. Validate every body through the schema loaded once from the OpenAPI document, so the contract and the suite cannot drift apart silently. Prove each new assertion sensitive by breaking the expected schema in a throwaway copy and keeping the failing output. Cleanup is a real constraint: the contract has no DELETE, so orders created by the POST suite cannot be removed through the API. Until the team provides a cleanup route or job, every created order carries the `qa-<runId>` note marker, and the POST suite runs only where residual orders are tolerated. Run the package's evidence checker on the spec directory once specs exist.

**Contract strategy.** Schema conformance checks are enough for now. The activity that is slow and error-prone by hand is validating bodies against the schema on every run; that is a test execution and coverage tool, driven by a JSON Schema validator fed from the OpenAPI document and kept in CI. Consumer-driven contracts need several independently released consumers that the provider team cannot see, and evidence that breaking changes have already reached them. Neither condition is established here. F-1 is the one warning sign: if `total` became a string without a version change and consumers were hurt, that is exactly the trigger, and the recommendation should be revisited with that evidence.

**What this report cannot show.** No request was sent in this session. The 201 and 400 paths of POST, every GET with an invalid id, every auth case and the side effect of the 500 were never observed. The three recordings are from 2026-10-15 and staging may differ today. The contract's own gaps (no security scheme, no limits, no `items` in `Order`) are findings for `/qa-static`, and the defects F-1 to F-7 go to `/qa-defect` with the severities proposed above.
