## Contract

**Where the contract lives.** The OpenAPI 3.0.3 document pasted in the request, title Orders API, version 2.1.0. No path, URL or repository location was given, so it was read inline on 2026-10-25. The deployed build is stated by the requester as 2.1.0 on staging, recorded 2026-10-15. I did not confirm that from a deployment record or version endpoint. Assumption: the requester's statement is the deployment record. Base URL unknown. Auth model: the document declares no security scheme. Assumption: either staging is unauthenticated or auth is undocumented, and the design below treats both as possibilities to test.

**What the contract declares.** Two operations, GET `/orders/{id}` with 200 and 404, and POST `/orders` with 201 and 400. Three schemas: NewOrder, Order and Error. Nothing else: no list, update or delete, no security schemes, no `maxLength` on `note` or on items, no `maximum` on `id`, no `nullable` anywhere, no 400 for a malformed id, no 401, 403, 405, 415, 429 or 500.

**Acceptance criteria used below.** No ticket was supplied, so these are derived from the contract and marked as an assumption.

| AC | Statement |
| :-- | :-- |
| AC-1 | GET with an existing id returns 200 and a body that validates against Order. |
| AC-2 | GET with an unknown id returns 404 and a body that validates against Error. |
| AC-3 | POST with a valid NewOrder returns 201, a body that validates against Order, and the order is readable by GET afterwards. |
| AC-4 | POST with an invalid NewOrder returns 400 and a body that validates against Error. |
| AC-5 (proposed) | Every error response, documented or not, uses the Error shape and exposes no internal detail. The contract does not say this today. It is proposed because findings M3 to M6 show the gap. |

## Conformance of the recorded responses

**What was run.** Nothing. This section validates the three recordings supplied, dated 2026-10-15 on staging, against the schema for each status. No request was sent in this session, so every claim is about those three bodies only. Zero of the three bodies conform.

| # | Request and status | Declared schema location | Actual | Mismatch | Classification | Owner |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| M1 | GET `/orders/1042`, 200 | `components.schemas.Order.properties.total`, `type: number` | `"total": "42.50"` | Declared number, returned as a JSON string. A consumer generated from the contract fails to parse, and arithmetic on the raw value concatenates. | Software defect, provisional. Contract and build carry the same version, so the contract describes this build. If the owner confirms the string is deliberate for decimal precision, reclassify as documentation drift and change the schema to a string with a pattern. | API team, confirm with consumers |
| M2 | GET `/orders/1042`, 200 | `components.schemas.Order.properties.note`, `type: string`, not nullable | `"note": null` | OpenAPI 3.0.3 rejects `null` for a string unless `nullable: true`. The field is optional, so omitting the key was the documented way to express "no note". | Documentation drift, provisional. Cheapest fix is `nullable: true` in the schema. A strict generated client breaks today, so if consumers already use one, treat as a defect. | API document owner |
| M3 | GET `/orders/999999`, 404 | `components.schemas.Error.required: [code, message]` | `{"message": "Order not found"}` | Required `code` missing. The status is correct. Consumers that switch on `code` cannot. | Software defect | API team |
| M4 | POST `/orders`, note of 5,000 characters, 500 | `paths./orders.post.responses` documents 201 and 400 only. NewOrder declares no `maxLength` on `note`. | HTTP 500 | By the contract this request is valid and should return 201. The implementation has a 500-character storage limit the contract does not declare. A valid-by-contract request produces a server error. | Software defect and documentation drift together. Product decides the real limit. Then the schema declares `maxLength` and the server returns 400 with an Error body beyond it. | Product owner for the limit, API team for the handling |
| M5 | Same as M4 | Error schema, by AC-5 and by the shape of every other documented error | `{"error": "..."}` | Third error shape in three recordings. Not Error: no `code`, no `message`. | Software defect | API team |
| M6 | Same as M4 | None. Security finding, not a schema mismatch. | `value too long for type character varying(500)` | The body leaks the database engine's error text and column type. Information disclosure, medium severity. | Software defect, security. File through `/qa-defect` with the security label. | API team |
| M7 | Same as M4 | AC-3, atomicity of creation | Unknown | The recording does not show whether an order row or any side effect was persisted before the failure. | Open question, not classifiable. Verify by GET after reproducing. | QA to verify |

**What the schema does not say, found while reading.** Not mismatches, but gaps the design must probe. GET with an id of 0, a negative number or a non-integer has no documented status. Unknown SKUs, duplicate items and unknown body fields have no documented outcome. No response declares `additionalProperties: false`, so extra fields pass validation and must be recorded rather than failed. The `status` enum has no cancelled or failed value; if the business has cancellation, the enum has drifted. There is no delete operation, which constrains test data cleanup on staging.

**What this report cannot show.** The 201 path and the 400 path were never recorded, so AC-3 and AC-4 are unverified in both directions. A conforming Error body has never been observed. Whether 1042 was returned to a caller allowed to see it is unknown.

## Test design

**Partitions and boundaries, GET `/orders/{id}`.** Technique: EP and BVA on the path parameter, schema validation on the body. Expected statuses for undocumented partitions are an assumption and are written as "record"; the expected body in every case is the Error shape, per AC-5.

| ID | Input | Technique | Expected | AC | Tags |
| :-- | :-- | :-- | :-- | :-- | :-- |
| G-01 | Existing id | EP valid | 200, body validates against Order, `total` is a JSON number, `status` in enum, `note` absent or string | AC-1 | @api @smoke @p0 @candidate @orders |
| G-02 | Existing id with no note | EP valid | 200, `note` key absent or declared nullable, per the owner's decision on M2 | AC-1 | @api @regression @p2 @candidate @orders |
| G-03 | Unknown id, 999999 | EP valid, not found | 404, body validates against Error with `code` and `message` | AC-2 | @api @smoke @p0 @candidate @orders |
| G-04 | id 1 | BVA min | 200 or 404, body conforms to the status | AC-1, AC-2 | @api @regression @p1 @candidate @orders |
| G-05 | id 0 | BVA min minus 1 | Record. Assumption 400 with Error. A 404 is acceptable only if its body is Error. A 500 is a defect. | AC-5 | @api @regression @p1 @candidate @orders |
| G-06 | id -1 | EP invalid | Record, same rule as G-05 | AC-5 | @api @regression @p2 @candidate @orders |
| G-07 | id `abc`, `1.5`, `1e3`, `0001`, `%201` | EP invalid type and encoding | Record each. Never 500. `0001` must not alias 1 silently; record whether it does. | AC-5 | @api @regression @p2 @candidate @orders |
| G-08 | id 2147483647, 2147483648, 9007199254740993, 9223372036854775808 | BVA at undeclared maximum | 404 with Error for parseable values. Any 500 on overflow is a defect and the schema then needs a `maximum`. | AC-2, AC-5 | @api @regression @p2 @candidate @orders |
| G-09 | Existing id read twice | Idempotency | Both bodies equal | AC-1 | @api @regression @p3 @candidate @orders |
| G-10 | Existing id, `Accept: text/plain` | Error guessing | 200 JSON or 406 with Error. Record. | AC-5 | @api @regression @p3 @deferred @orders |

**Partitions and boundaries, POST `/orders`.** Technique: EP and BVA per field, plus body-level partitions. The 500-character limit comes from M4 and is observed, not declared. All created orders carry a note beginning with a unique run marker, see cleanup below.

| ID | Input | Technique | Expected | AC | Tags |
| :-- | :-- | :-- | :-- | :-- | :-- |
| P-01 | `items: ["sku-1"]`, no note | EP valid, BVA minItems | 201, body validates against Order, `status` is `placed` (assumption), `total` is a number, then GET returns the same order | AC-3 | @api @smoke @p0 @candidate @orders |
| P-02 | Two distinct valid SKUs, short note | EP valid | 201, note echoed verbatim, total reflects both items | AC-3 | @api @smoke @p0 @candidate @orders |
| P-03 | `items: []` | BVA minItems minus 1 | 400, Error body | AC-4 | @api @smoke @p0 @candidate @orders |
| P-04 | `items` missing | EP invalid, required | 400, Error body | AC-4 | @api @regression @p1 @candidate @orders |
| P-05 | `items: null`, `items: "sku-1"`, `items: [1]`, `items: [null]`, `items: [""]` | EP invalid type, one case each | 400, Error body, message names the field | AC-4 | @api @regression @p1 @candidate @orders |
| P-06 | Unknown SKU, duplicate SKU | EP, business rule undeclared | Record. Assumption 400 with Error for unknown; duplicates either accepted or 400. Raise as a contract gap either way. | AC-4 | @api @regression @p1 @candidate @orders |
| P-07 | 100 items, then 1,000 items | BVA at undeclared maxItems, bounded | 201 or 400 with Error. Never 500. Record the real limit. | AC-5 | @api @regression @p2 @candidate @orders |
| P-08 | SKU strings of 64, 255 and 256 characters | BVA at undeclared item length | Same rule as P-07 | AC-5 | @api @regression @p2 @candidate @orders |
| P-09 | note of 0, 1, 499, 500 characters | BVA at observed limit, valid side | 201, note echoed exactly, including the empty string unless the owner decides empty means absent | AC-3 | @api @regression @p1 @candidate @orders |
| P-10 | note of 501 and 5,000 characters | BVA at observed limit, invalid side | 400 with Error after the fix for M4. Until then this reproduces M4. Then GET any id returned or the newest order to answer M7. | AC-4, AC-5 | @api @regression @p0 @candidate @orders |
| P-11 | note of 500 four-byte characters | BVA, characters versus bytes | 201. A varchar(500) in PostgreSQL counts characters, so this is valid. A 400 or 500 shows a byte-based check somewhere. | AC-3 | @api @regression @p2 @candidate @orders |
| P-12 | note `null`, note `123`, note `{}` | EP invalid type | 400, Error body. If `null` is accepted, the owner's decision on M2 applies. | AC-4 | @api @regression @p2 @candidate @orders |
| P-13 | note containing `<script>`, SQL fragments, newlines and control characters | Security, stored input | 201, value stored and returned byte for byte as a JSON string, no truncation, no execution evidence, no 500 | AC-3 | @api @regression @p1 @candidate @orders @security |
| P-14 | Unknown top-level field `coupon: "X"` | EP, additional properties undeclared | Record. Either ignored with 201 or 400 with Error. | AC-5 | @api @regression @p3 @candidate @orders |
| P-15 | Empty body, malformed JSON, JSON array, `Content-Type: text/plain` | Error guessing, body level | 400 or 415 with Error body. Never 500. | AC-5 | @api @regression @p1 @candidate @orders |
| P-16 | Same valid body sent twice | Idempotency | Two orders with distinct ids. The contract promises no idempotency key, so duplication is the documented behaviour. Record it and raise whether clients retry on timeout. | AC-3 | @api @regression @p2 @candidate @orders |
| P-17 | Valid body, then GET the returned id | Round trip | GET body equals the POST body field for field | AC-3 | @api @smoke @p0 @candidate @orders |

**Resource state model.** The Order enum names three states, placed, paid and shipped. This API exposes one event, create, and one query, read. No transition to paid or shipped is reachable through it. Assumption: payment and fulfilment services move the state. What is testable here is the entry state after create, covered by P-01, and that read never returns a value outside the enum, covered by G-01 for every id read in the suite. Invalid transitions cannot be attempted through this contract. If the business has cancel or refund, the enum is incomplete and that is a documentation gap to raise now, before a consumer hard-codes three values.

**Auth matrix.** The contract declares no security. Each row runs against both operations and records what happens.

| Caller | Expected if auth exists | Expected if the API is public | Tags |
| :-- | :-- | :-- | :-- |
| No token | 401 with Error body | Documented behaviour | @api @smoke @p0 @candidate @security |
| Expired token | 401 with Error body | Not applicable | @api @regression @p1 @candidate @security |
| Valid token, another customer's order id | 404 or 403 with Error body, never the order | Finding: sequential integer ids plus unauthenticated read is an enumeration path. Raise as a security risk regardless of whether the data is sensitive. | @api @smoke @p0 @candidate @security |
| Wrong role on POST | 403 with Error body | Not applicable | @api @regression @p1 @candidate @security |

CSRF does not apply unless the API accepts cookie sessions. Assumption: it does not. If a session cookie is observed, the CSRF checks in the security reference apply to POST.

**Error contract.** Documented: 404 on GET, 400 on POST, both with the Error shape. Undocumented and reachable: 400 on GET for a malformed id, 405 on PUT or DELETE, 415, 401 and 403 if auth exists, 429 if a rate limit exists, and 500 as recorded. Three error shapes have been seen and none is the declared one: a message-only object, an error-only object, and the declared code-plus-message shape that has never been observed. Every case above asserts the Error shape on every non-2xx response, so the suite fails on each of M3, M5 and M6 until the owner fixes the shape or the document.

**Cleanup on shared staging.** The contract has no delete operation, so the rule that each test deletes what it creates cannot be met through the API. Assumption: an out-of-band purge exists or can be requested. Every POST in the suite carries a note starting with a unique run marker so the owner can purge those rows, each run caps its creations, and a final step lists the ids it created. If the team marks staging orders read-only, the POST cases run only against a dedicated test tenant or a local dry run, whose results are an oracle and never a sign-off.

**Automation shape.** One helper class with two action methods, get by id and create, and no assertions. The OpenAPI document is loaded once, and each spec validates status and body through its schemas, so a schema edit changes the tests without anyone touching them. Each new assertion is proven to fail first by altering the expected schema in a throwaway copy, and that failing output is kept. Assumption: the repository uses Playwright, so the request fixture is the client. The `check-test-evidence.sh` checker was not run, because no specs were written in this session.

**Contract strategy.** Schema conformance checks are enough, and they should run in CI against staging on every deploy. The activity is test execution with a validation oracle, category test execution and coverage tools. Within that category a JSON Schema validator driven from the OpenAPI document covers every case above, and a generative conformance tool can add the undeclared-boundary probes in G-05 to G-08 and P-07 to P-08 cheaply. Consumer-driven contracts are not justified on the evidence here. Nothing in the request shows several independently released consumers that the provider team cannot see, and the breakages found are all provider-side drift that schema checks catch directly. If a second consumer team with its own release cadence appears, revisit, because M1 is exactly the class of change that a consumer-written contract would have caught before deploy.

**Rules applied and limits.** The context-discovery, testing-guidelines, test-tools and security-qa rules and the test design reference were read from the project's rules folder. The code-style-qa and test-evidence rules were not applied in full, because no specs were written. No files were created, as instructed, so the five step outputs above stand in for `api-tests/contract.md`, `design.md` and `conformance.md`. Next actions: file M1, M3, M4, M5 and M6 through `/qa-defect`, send M2 and the undeclared limits to the document owner, and confirm the staging build from its deployment record before the first live run.
