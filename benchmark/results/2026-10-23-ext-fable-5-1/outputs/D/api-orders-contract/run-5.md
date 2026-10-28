## Contract

**Source.** OpenAPI 3.0.3, Orders API 2.1.0, supplied inline in the request. No URL, path or `servers` block was given. Fetched 2026-10-25 from the request text. Assumption: this is the published contract for 2.1.0, with no newer revision on the API's docs site.

**Deployed build under test.** Staging, version 2.1.0, as stated in the recording of 2026-10-15. I did not confirm it from a deploy record or version endpoint, and I sent no requests. Every statement below about live behaviour comes from the three recorded responses and is dated 2026-10-15. Ten days have passed on a shared environment, so re-run the three requests before filing anything.

**Auth model.** The document declares no `securitySchemes` and no `security` block. Assumption: the contract intends no authentication. That is itself a finding for the design below, because order ids are sequential integers and the GET has no owner check to document.

**Base URL.** Not given. Assumption: the staging base URL in the team's environment config.

**Testability gaps in the contract.** There is no list endpoint and no DELETE. Every order a test creates stays on staging, and the suite has no API-level way to prove that a failed POST left nothing behind. The Order schema does not return `items`, so a create cannot be checked for round-trip of what was ordered. Both are design findings for the contract owner, not test cases.

## Conformance

Nothing was run. I validated each recorded body by reading it against the schema declared for that status.

**What conforms.** Response 1 returned the documented 200. Its `id` is an integer and `status` is in the enum. Response 2 returned the documented 404 for an unknown id.

**Mismatches.** One row per deviation. Classification follows principle 2: the schema and the service carry the same version, so the conflict is reported and neither side is changed until the owner decides.

| # | Request | Declared schema location | Actual | Classification | Proposed owner |
| --- | --- | --- | --- | --- | --- |
| M1 | GET /orders/1042 → 200 | `Order.properties.total`: `type: number` | `"total": "42.50"`, a string | Software defect, provisional. Clients generated from the contract parse a number. If the string is a deliberate decimal-precision choice, it becomes documentation drift and the schema must say `type: string` with a pattern. One side must change either way. | API team; contract owner copied. Route to `/qa-defect`. |
| M2 | GET /orders/1042 → 200 | `Order.properties.note`: `type: string`, no `nullable: true` | `"note": null` | Documentation drift, provisional. Null for "no note" is a common deliberate choice. Fix is `nullable: true`, or the service omits the key. The field is optional, so omission already conforms. | Contract owner. |
| M3 | GET /orders/999999 → 404 | `Error.required: [code, message]` | `{"message": "Order not found"}`, no `code` | Software defect. A client that branches on `code` cannot tell this error from any other. | API team. Route to `/qa-defect`. |
| M4 | POST /orders, note of 5,000 chars → 500 | `paths./orders.post.responses` documents only 201 and 400 | HTTP 500 | Software defect, high severity. The request violates no declared constraint, so the API must answer 201 or a 400 with an Error body. An unhandled storage error is neither, and any client can trigger it at will. | API team. Route to `/qa-defect`. |
| M5 | Same request | `Error` schema | `{"error": "..."}`, no `code`, no `message` | Software defect. The generic error handler emits a third error shape. Assert in the same defect report as M4. | API team. |
| M6 | Same request | Not a schema item. The `security-qa` rule: no stack traces or internals in responses | Message discloses the column type `character varying(500)` | Software defect, security hygiene. Information disclosure of storage implementation. Same report as M4, separate line. | API team. |
| M7 | Same request | `NewOrder.properties.note` declares no `maxLength` | Real limit is 500 characters at the storage layer, inferred from the error text, not probed | Documentation drift. An undeclared boundary. Add `maxLength: 500` once M4's validation is in place. | Contract owner. |

**What the schema does not say, and the recording cannot answer.**

- Whether the 500 in M4 created a partial order. Assumption: the insert failed atomically. Unverifiable through this contract, see the testability gap above.
- Which status GET returns for an id below the declared minimum, or a non-integer id. The GET documents only 200 and 404.
- Whether 401, 403, 405, 413 or 415 exist. None is documented.
- Whether the 500-character limit counts characters or bytes. The error names a varchar, so multibyte input is a separate boundary.
- Whether the 404 shape in M3 and the 500 shape in M5 are the only undocumented error shapes. The 400 was never recorded, so the documented Error shape has not been observed at all.

## Test design

Acceptance criteria are derived from the contract because no ticket was supplied. AC-6 is an assumption: the contract never states a new order's initial status.

- AC-1: GET with an existing id returns 200 and an Order body.
- AC-2: GET with an unknown id returns 404 and an Error body.
- AC-3: POST with a valid NewOrder returns 201 and the created Order.
- AC-4: POST with an invalid NewOrder returns 400 and an Error body.
- AC-5: every error body has `code` and `message`.
- AC-6, assumed: a new order is created in status `placed`.

Every case below carries `@api`. Every case asserts status and body against the schema for that status. Suite, priority and automation tags are per row. All are `@candidate` because no spec exists yet.

**GET /orders/{id}.** Partitions of `id`: valid existing, valid unknown, below minimum, non-integer, beyond the integer range the schema leaves undeclared.

| ID | Case | Technique | Expected | Tags | AC |
| --- | --- | --- | --- | --- | --- |
| TC-ORD-001 | Existing id, created by the test | EP, valid | 200; body validates as Order; `id` equals path; `total` is a JSON number; `note` string or absent | @smoke @p0 | AC-1 |
| TC-ORD-002 | Unknown id, e.g. 999999 | EP, valid partition, 404 | 404; body validates as Error with `code` and `message` | @smoke @p1 | AC-2, AC-5 |
| TC-ORD-003 | id = 1 | BVA, minimum | 200 or 404, body per status. Must not be 400 | @regression @p2 | AC-1 |
| TC-ORD-004 | id = 0 | BVA, minimum minus one | Undocumented. Record observed. Expected by REST convention: 400 with Error body; 404 acceptable if the owner says so | @regression @p1 | AC-5 |
| TC-ORD-005 | id = -1 | EP, invalid | Same as TC-ORD-004 | @regression @p2 | AC-5 |
| TC-ORD-006 | id = "abc" | EP, invalid type | Undocumented. Record observed. Expected 400 with Error body | @regression @p1 | AC-5 |
| TC-ORD-007 | id = "1.5" | EP, invalid type | Same as TC-ORD-006 | @regression @p2 | AC-5 |
| TC-ORD-008 | id = 2147483648, then 9223372036854775808 | BVA, undeclared upper bound | Undocumented. Record observed. Must not be 500 | @regression @p1 | AC-5 |
| TC-ORD-009 | id = "0042" | Error guessing, leading zeros | Record whether it resolves to 42 or is rejected | @regression @p3 | AC-1 |
| TC-ORD-010 | GET twice on the same id | Idempotency | Both bodies identical | @regression @p2 | AC-1 |
| TC-ORD-011 | Response has no field outside the Order schema | Schema conformance | No undeclared properties. If any appear, record as drift | @regression @p2 | AC-1 |

**POST /orders.** Partitions per field. `items`: missing, null, wrong type, empty, one element, several, non-string element, empty string element, duplicate skus, unknown sku, large count. `note`: absent, empty, 1, 500, 501, 5,000, non-string, multibyte. Body: absent, not JSON, wrong content type, unknown extra property.

| ID | Case | Technique | Expected | Tags | AC |
| --- | --- | --- | --- | --- | --- |
| TC-ORD-020 | `{"items": ["sku-1"]}`, no note | EP valid, BVA minItems | 201; body validates as Order; `id` integer ≥ 1; `status` = `placed` under AC-6; `total` number | @smoke @p0 | AC-3, AC-6 |
| TC-ORD-021 | Two items, note "hello" | EP valid | 201; `note` echoes input | @smoke @p1 | AC-3 |
| TC-ORD-022 | Created order is readable by GET with the returned id | State transition, create → read | 200; same `id`, `status`, `note` | @smoke @p0 | AC-1, AC-3 |
| TC-ORD-023 | `{"items": []}` | BVA, minItems minus one | 400; Error body | @smoke @p1 | AC-4, AC-5 |
| TC-ORD-024 | `{}` | EP, required missing | 400; Error body | @regression @p1 | AC-4, AC-5 |
| TC-ORD-025 | `{"items": null}` | EP, null | 400; Error body | @regression @p1 | AC-4 |
| TC-ORD-026 | `items` as string, number, object | EP, wrong JSON type, one case each | 400; Error body | @regression @p1 | AC-4 |
| TC-ORD-027 | `{"items": [42]}`, `[null]`, `[{}]` | EP, wrong element type | 400; Error body | @regression @p1 | AC-4 |
| TC-ORD-028 | `{"items": [""]}` | Error guessing, undeclared | Record observed. Expected 400 | @regression @p2 | AC-4 |
| TC-ORD-029 | `{"items": ["sku-1", "sku-1"]}` | Error guessing, undeclared | Record observed. Is `total` doubled or deduplicated? | @regression @p2 | AC-3 |
| TC-ORD-030 | `{"items": ["sku-does-not-exist"]}` | Error guessing, undeclared business rule | Record observed. Expected 400 with Error; 201 means pricing accepts unknown skus | @regression @p1 | AC-4 |
| TC-ORD-031 | 100 items, then 1,000 items, bounded | BVA, undeclared maxItems | Record observed limit. Must not be 500 | @regression @p2 | AC-3 |
| TC-ORD-032 | note of 500 characters | BVA, observed max | 201; `note` echoed intact | @regression @p1 | AC-3 |
| TC-ORD-033 | note of 501 characters | BVA, observed max plus one | 400; Error body. Today returns 500, see M4 | @regression @p1 | AC-4, AC-5 |
| TC-ORD-034 | note of 5,000 characters, the recorded case | Confirmation of M4 | 400; Error body; no storage detail in `message` | @regression @p1 | AC-4, AC-5 |
| TC-ORD-035 | note of 500 four-byte characters | Error guessing, bytes versus characters | Record observed. 201 or 400, never 500 | @regression @p2 | AC-3 |
| TC-ORD-036 | note "" | BVA, empty string | Record observed. Expected 201 with `note` "" or absent | @regression @p3 | AC-3 |
| TC-ORD-037 | note as number, object, array, null | EP, wrong type, one case each | 400; Error body | @regression @p2 | AC-4 |
| TC-ORD-038 | Empty body with `Content-Type: application/json` | EP, required body missing | 400; Error body | @regression @p1 | AC-4 |
| TC-ORD-039 | Malformed JSON | Error guessing | 400; Error body, not a parser stack trace | @regression @p1 | AC-5 |
| TC-ORD-040 | `Content-Type: text/plain` with a valid JSON string | Error guessing | Undocumented. Record observed. Expected 415 or 400 with Error body | @regression @p2 | AC-5 |
| TC-ORD-041 | Valid body plus `"foo": "bar"` | Error guessing, additionalProperties undeclared | Record observed: ignored or 400 | @regression @p3 | AC-3 |
| TC-ORD-042 | Same valid POST sent twice | Idempotency | Contract promises nothing. Expected two orders with distinct ids. Record it, and raise whether an idempotency key is wanted | @regression @p2 | AC-3 |
| TC-ORD-043 | Body of 1 MB, bounded | Error guessing, undeclared payload limit | Record observed. Expected 413 or 400, never 500 | @regression @p2 | AC-5 |
| TC-ORD-044 | 400 response has no field outside Error | Schema conformance | No undeclared properties | @regression @p2 | AC-5 |

**Resource state model.** The `status` enum implies placed → paid → shipped, but the contract exposes only one event, create. Assumption: the transitions exist in other systems or endpoints not in this document. Valid-transitions coverage of this contract is TC-ORD-022 alone. Invalid transitions that the contract lets a test attempt: read before create, covered by TC-ORD-002, and read of an impossible id, covered by TC-ORD-004 to TC-ORD-008. Paid and shipped orders cannot be produced through this API, so the suite can validate those enum values only on pre-existing records such as order 1042, which it must treat as read-only.

**Auth matrix.** The contract declares no security scheme. Run each endpoint with no token, an expired token, a token for a different customer against order 1042, and a token with a read-only role against POST. Record the observed status and body for each. Expected under the `security-qa` rule: 401 for no or expired token, 403 or 404 for another customer's order, 403 for the wrong role, all with an Error body. If staging answers 200 to all of them, the finding is that order ids are sequential integers readable by anyone, which is an object-level authorization exposure. Whether that is acceptable is the owner's call, and the contract must then say the API is public. CSRF does not apply to a JSON API without cookie sessions; confirm the session model before dropping the check.

**Error contract.** Documented: GET 200 and 404, POST 201 and 400, all errors as `Error`. Observed shapes as of 2026-10-15: `Error` never seen, `{message}` on 404, `{error}` on 500. Undocumented statuses to settle with the owner: 400 on GET for an invalid id, 401, 403, 405, 413, 415, 500. The owner should either document each or declare that a 500 is always a defect. Each shape needs its own assertion. One `Error` validator does not cover a response that is not `Error`.

**Idempotency and retries.** GET is idempotent and TC-ORD-010 checks it. POST declares no idempotency key, so a client retry on a timeout will duplicate an order. TC-ORD-042 records the behaviour. There is no PUT or DELETE to test.

**Contract strategy.** Schema conformance checks are enough. The activity is contract conformance of a single provider, and the tool category is test execution and assertion support, a JSON Schema validator loaded with the OpenAPI components and called from the API specs. Every mismatch found above, M1 to M7, would fail a validator that checks each body against the schema for its status, so this activity catches the known failure class at the lowest cost. Consumer-driven contracts are not justified on the evidence: the request names one provider, no independently released consumers, no broker, and no breaking change that has reached a consumer. If those conditions appear, revisit. Any stub of this API used in a consumer's tests is testware and proves the consumer only.

**Automation plan.** Assumption: the team's repository uses Playwright, so the specs use the `request` fixture. The workspace supplied here is empty, so no existing convention was found. Structure:

- One helper class with two action methods, one per endpoint, returning the raw response and never asserting.
- The OpenAPI document loaded once, its component schemas compiled with a JSON Schema validator, and one assertion helper that reports the first validation error verbatim.
- Each spec asserts status, then validates the body against the schema for that status, then asserts the field-level expectations in its row.
- Order 1042 is read-only. Every other GET case reads an order the same test created.
- Cleanup cannot be done through the API. Assumption: staging has a periodic purge. Until then, every created order carries a unique marker in `note`, and the plan lists the testability gap for the owner.
- Red-green proof before the suite counts: flip `total` to `type: string` in a throwaway copy of the schema and watch TC-ORD-001 fail on `total`, then restore. Repeat for `Error.required` and TC-ORD-002.

**What this deliverable cannot show.** I ran nothing. The seven mismatches rest on three recorded responses from 2026-10-15. No 400 has ever been observed, so AC-4 and the documented Error shape are unverified. Statuses paid and shipped were never produced. Auth behaviour is unknown. The evidence checker was not run, because no spec exists yet. All rules this skill names were loaded from the plugin's rules folder and applied.
