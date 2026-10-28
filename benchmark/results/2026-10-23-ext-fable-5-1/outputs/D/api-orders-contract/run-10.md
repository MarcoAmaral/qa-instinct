**Orders API 2.1.0, staging, recordings of 2026-10-15.** Nothing in this report was run by me. The three recorded responses are the conformance sample; everything else is read from the contract. Every claim about live behaviour is dated 2026-10-15 and may have changed since.

**Assumptions (information missing from the request)**

- A1. "Deployed version 2.1.0" comes from the recording note and is treated as the deployment record. I did not re-confirm it from a version endpoint or deploy log.
- A2. Base URL is the staging host; the host name was not given.
- A3. The document declares no `securitySchemes`, so the API is treated as unauthenticated until the owner says otherwise. The auth matrix is designed but tagged `@deferred`.
- A4. A newly created order starts in status `placed`, and `total` is computed server-side (NewOrder carries no prices). Neither is stated in the contract.
- A5. No acceptance criteria were supplied. The criteria below (AC-1 to AC-6) are derived from the contract, one per documented response plus one for the error shape.
- A6. Whether recording 3 left a partial order row behind is unknown.

## 1. Contract and conformance

**Contract record (step 1).** OpenAPI 3.0.3, title Orders API, document version 2.1.0, pasted inline with the request on 2026-10-25. Two operations: `GET /orders/{id}` (documents 200, 404) and `POST /orders` (documents 201, 400). Three schemas: NewOrder, Order, Error. Auth model: none declared (A3). Environment: staging (A2). Deployed build: 2.1.0 per A1. The document declares no `maxLength`, `maxItems`, `pattern`, `nullable` or `additionalProperties` anywhere, so most real limits are undeclared and have to be observed.

**Derived acceptance criteria (A5)**

| AC | Statement |
| --- | --- |
| AC-1 | `GET /orders/{id}` for an existing id returns 200 with a body valid against Order. |
| AC-2 | `GET /orders/{id}` for a non-existent id returns 404 with a body valid against Error. |
| AC-3 | `POST /orders` with a valid NewOrder returns 201 with a body valid against Order. |
| AC-4 | `POST /orders` with an invalid NewOrder returns 400 with a body valid against Error. |
| AC-5 | Every error response, documented or not, has the Error shape (`code` and `message`, both strings). |
| AC-6 | `id` below 1 or not an integer is rejected (schema `minimum: 1`, `type: integer`); the response is undocumented. |

**Conformance results (step 3).** Zero of the three recorded responses conform fully. Eight findings follow.

| # | Request (2026-10-15) | Declared (schema location) | Actual | Mismatch | Classification | Proposed owner |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | GET /orders/1042 → 200 | `Order.properties.total`: `type: number` | `"total": "42.50"` (string) | Wrong JSON type on a required field | **Software defect** (provisional). If money-as-string is a deliberate decision, it becomes documentation drift and the schema must say `type: string` with a decimal `pattern`. Either way, consumers generated from this document fail to parse today's response. | Orders API team; API doc owner if deliberate |
| M2 | GET /orders/1042 → 200 | `Order.properties.note`: `type: string`, no `nullable: true` | `"note": null` | `null` is not a string in OpenAPI 3.0.3 | **Documentation drift**. Recommend `nullable: true`, or omit the field when absent and say so. | API doc owner |
| M3 | GET /orders/999999 → 404 | `Error.required: [code, message]` | `{"message": "Order not found"}` | Required `code` missing | **Software defect**. A client that switches on `code` cannot distinguish this 404 from any other. | Orders API team |
| M4 | POST /orders, note of 5,000 chars → 500 | `paths./orders.post.responses`: only 201 and 400 | HTTP 500 | Undocumented status; an over-long input is a validation failure and belongs to 400 | **Software defect** (missing input validation; the database enforces the limit instead of the API) | Orders API team |
| M5 | same → 500 | `Error` schema | `{"error": "value too long..."}` | Body matches no declared schema; `code` and `message` absent | **Software defect**. The unhandled-exception path has its own shape, so every 500 the service ever emits is off-contract, not only this one. | Orders API team |
| M6 | same → 500 | security-qa rule: no stack traces or internals in responses | Message names the column type `character varying(500)` | Information disclosure of storage internals | **Software defect** (security). Replace with a generic message; keep the detail in server logs. | Orders API team |
| M7 | same | `NewOrder.properties.note`: no `maxLength` | Real limit is 500 characters, enforced by the database | The schema declares no boundary; the observed one is 500 | **Documentation drift**. Declare `maxLength: 500` so clients can validate before sending. Pair with M4 so the API enforces it too. | API doc owner and Orders API team |
| M8 | same | n/a | Unknown whether an order row was created before the insert failed | Side effect of a 500 unverified | Open check, not a mismatch. Needs a `GET` on the next expected id, or a count, right after reproducing. | Tester, next run |

**What conformed.** In recording 1, `id` is an integer and `status` is in the enum. In recording 2, the status is 404 and `message` is a string. Nothing else could be confirmed.

**What the schema does not say (error contract gaps).** These are undocumented statuses that the design below forces, so each will produce a finding on first run.

| Situation | Documented? | Expectation under AC-5 |
| --- | --- | --- |
| `GET /orders/0`, `/orders/-1`, `/orders/abc`, `/orders/1.5` | No. GET documents only 200 and 404 although `id` declares `minimum: 1` and `type: integer` | 400 with Error body. Record whatever is returned; a 404 here would be acceptable only if documented. |
| Malformed JSON, missing body, `Content-Type: text/plain` on POST | No (400 is documented for "Invalid order", not for unparseable requests; 415 is absent) | 400 or 415 with Error body |
| Unknown property in NewOrder, for example `"price": 1` | No (`additionalProperties` not set) | Observe: silently ignored or 400. Record. |
| 401 / 403 | No `securitySchemes` | See auth matrix |
| 405 on `PUT /orders/1042`, `DELETE /orders/1042` | No | Observe and record |
| 500 | No | Should never be reached by input alone; when reached, Error body (M5) |

## 2. Test design (step 2)

Techniques: equivalence partitioning and 2-value boundary value analysis per field (CTFL v4.0 §4.2.1, §4.2.2), state transition for the order lifecycle (§4.2.4), error guessing for the storage and encoding probes (§4.4.1). Every case asserts status **and** body against the schema for that status. Tags follow the taxonomy: `@api` plus suite, priority, automation status and feature tag `@orders`.

**GET /orders/{id}: partitions and boundaries of `id`**

| Case | Input | Partition / boundary | Expected status, body | AC | Tags |
| --- | --- | --- | --- | --- | --- |
| TC-ORD-001 | 1042 (seeded, read-only) | Valid, existing | 200, Order schema; `total` is a number; `status` in enum; `note` string or absent | AC-1 | @smoke @api @p0 @candidate |
| TC-ORD-002 | Id returned by a POST in the same test | Valid, existing, own data | 200, body equals the 201 body field by field | AC-1 | @regression @api @p1 @candidate |
| TC-ORD-003 | 999999 | Valid integer, not existing | 404, Error schema with `code` | AC-2 | @smoke @api @p1 @candidate |
| TC-ORD-004 | 1 | Boundary min | 200 or 404, body per status | AC-1/2 | @regression @api @p2 @candidate |
| TC-ORD-005 | 0 | Boundary min−1, invalid | Undocumented; assert Error body under AC-5 and record status | AC-6 | @regression @api @p1 @candidate |
| TC-ORD-006 | −1 | Invalid partition, negative | Same as 005 | AC-6 | @regression @api @p2 @candidate |
| TC-ORD-007 | `abc` | Wrong type, non-numeric | Same as 005 | AC-6 | @regression @api @p1 @candidate |
| TC-ORD-008 | `1.5` | Wrong type, decimal | Same as 005 | AC-6 | @regression @api @p2 @candidate |
| TC-ORD-009 | `0001042` | Leading zeros | Observe: 200 for 1042, or 404/400. Record. | AC-6 | @regression @api @p3 @candidate |
| TC-ORD-010 | 2147483647, 2147483648, 9223372036854775808 | Undeclared max: 32-bit edge, 64-bit overflow | 404 or 400 with Error body, never 500 | AC-2/5 | @regression @api @p2 @candidate |
| TC-ORD-011 | 1042 with `Accept: text/plain` | Content negotiation | Observe: 406 or JSON anyway. Record. | AC-5 | @regression @api @p3 @deferred |

**POST /orders: partitions and boundaries per field**

| Case | Body | Partition / boundary | Expected status, body | AC | Tags |
| --- | --- | --- | --- | --- | --- |
| TC-ORD-020 | `{"items":["sku-1"]}` | Valid, 1 item (minItems boundary), note absent | 201, Order schema; `status` is `placed` (A4); `total` number; `note` absent or null per M2 decision | AC-3 | @smoke @api @p0 @candidate |
| TC-ORD-021 | `{"items":["sku-1","sku-2"],"note":"ok"}` | Valid, several items, note present | 201; `note` echoed exactly | AC-3 | @regression @api @p1 @candidate |
| TC-ORD-022 | `{"items":[]}` | minItems−1 | 400, Error schema | AC-4 | @smoke @api @p1 @candidate |
| TC-ORD-023 | `{}` | `items` missing (required) | 400, Error | AC-4 | @regression @api @p1 @candidate |
| TC-ORD-024 | `{"items":null}` | `items` null | 400, Error | AC-4 | @regression @api @p1 @candidate |
| TC-ORD-025 | `{"items":"sku-1"}` | Wrong type, string not array | 400, Error | AC-4 | @regression @api @p1 @candidate |
| TC-ORD-026 | `{"items":[1]}` | Element wrong type | 400, Error | AC-4 | @regression @api @p2 @candidate |
| TC-ORD-027 | `{"items":[""]}` | Empty string element (schema allows it) | Observe: 201 or 400. Record; the schema declares no `minLength`. | AC-3/4 | @regression @api @p2 @candidate |
| TC-ORD-028 | `{"items":["sku-1","sku-1"]}` | Duplicate elements | Observe: 201 with total doubled, or 400. Undocumented. | AC-3 | @regression @api @p2 @candidate |
| TC-ORD-029 | `{"items":["no-such-sku"]}` | Unknown SKU | Observe: 201 or 400. Business rule undocumented. | AC-3/4 | @regression @api @p1 @candidate |
| TC-ORD-030 | 100 items, then 1,000 items | Undeclared `maxItems`, bounded probe | 201 or 400, never 500. Record the real limit. | AC-5 | @regression @api @p2 @candidate |
| TC-ORD-031 | `note` of 500 chars | Observed max (M7) | 201, note echoed intact | AC-3 | @regression @api @p1 @candidate |
| TC-ORD-032 | `note` of 501 chars | Observed max+1 | 400, Error. Today: 500 (M4). | AC-4 | @regression @api @p1 @candidate |
| TC-ORD-033 | `note` of 5,000 chars | Recorded failing input | 400, Error. Regression for M4, M5, M6: body must not name a column type. Then check no order was created (M8). | AC-4/5 | @regression @api @p1 @candidate |
| TC-ORD-034 | `note` of 500 four-byte characters (emoji) | Byte versus character limit | 201 if the limit is in characters; a 500 here means the limit is in bytes. Record. | AC-3 | @regression @api @p2 @candidate |
| TC-ORD-035 | `"note": ""` | Empty string, allowed by schema | 201; note is `""` on GET | AC-3 | @regression @api @p3 @candidate |
| TC-ORD-036 | `"note": null` | Null, not nullable in schema | 400 by the schema; but GET returns null (M2), so observe and record the inconsistency | AC-4 | @regression @api @p2 @candidate |
| TC-ORD-037 | `"note": 42` | Wrong type | 400, Error | AC-4 | @regression @api @p2 @candidate |
| TC-ORD-038 | `note` containing `<script>alert(1)</script>` | Stored payload | 201; GET returns it byte-for-byte, neither executed nor silently altered. Escaping is the consumer's job; stripping or 500 here is a finding. | AC-3 | @regression @api @p2 @candidate |
| TC-ORD-039 | `{"items":["sku-1"],"price":0}` | Unknown property | Observe: ignored or 400. Record. | AC-4 | @regression @api @p2 @candidate |
| TC-ORD-040 | Body `{"items":["sku-1"` (malformed) | Unparseable JSON | 400, Error | AC-5 | @regression @api @p1 @candidate |
| TC-ORD-041 | No body | `requestBody.required: true` | 400, Error | AC-4 | @regression @api @p1 @candidate |
| TC-ORD-042 | Valid body, `Content-Type: text/plain` | Unsupported media type | 415 or 400, Error body | AC-5 | @regression @api @p2 @candidate |
| TC-ORD-043 | `[{"items":["sku-1"]}]` | Array as root | 400, Error | AC-4 | @regression @api @p2 @candidate |

**Resource state model (§4.2.4).** States: `(absent)`, `placed`, `paid`, `shipped`. Events this contract exposes: create (`absent → placed`, A4) and read (no change). The transitions `placed → paid` and `paid → shipped` have no endpoint in this document, so they happen outside the contract and cannot be driven or attempted invalidly here. Coverage criterion reachable: **all states**, by reading seeded orders in each status. **Valid transitions** and **all transitions** are not reachable through this API.

| Case | Sequence | Expected | AC | Tags |
| --- | --- | --- | --- | --- |
| TC-ORD-050 | POST valid, then GET the new id | 201 then 200; `status` `placed`; same `id`, `total`, `note` | AC-1/3 | @smoke @api @p0 @candidate |
| TC-ORD-051 | GET seeded orders in `placed`, `paid`, `shipped` | 200 each; `status` exactly the seeded value | AC-1 | @regression @api @p1 @candidate |
| TC-ORD-052 | GET an id for an order deleted or cancelled by another system | 404, Error, or a status outside the enum (which would be a conformance failure) | AC-2 | @regression @api @p2 @deferred |
| TC-ORD-053 | PUT / PATCH / DELETE on `/orders/1042` | 405 with Error body; must not change the record (read-only fixture) | AC-5 | @regression @api @p2 @candidate |

**Auth matrix.** No security scheme is declared (A3). If the API is truly open, order ids are small sequential integers, so any client can enumerate every order and its note. That is a BOLA finding under the security-qa rule and must be raised whether or not it is "by design".

| Case | Condition | GET /orders/{id} | POST /orders | Tags |
| --- | --- | --- | --- | --- |
| TC-ORD-060 | No credentials | If auth exists: 401 with Error body. If not: 200 and finding "unauthenticated read of any order". | 401, or 201 and finding | @smoke @api @p0 @candidate |
| TC-ORD-061 | Expired or invalid token | 401, Error | 401, Error | @regression @api @p1 @deferred |
| TC-ORD-062 | Valid token, another user's order id (1041, 1043, adjacent to the known 1042) | 403 or 404 with Error, never the other user's body | n/a | @regression @api @p0 @candidate |
| TC-ORD-063 | Wrong role (read-only role on POST) | n/a | 403, Error | @regression @api @p1 @deferred |
| TC-ORD-064 | Cookie-based session, no anti-CSRF token on POST | n/a | Rejected, or finding if sessions are cookie-based | @regression @api @p1 @deferred |

Cases 061, 063 and 064 stay `@deferred` until the auth model is confirmed; 060 and 062 run now because an open API is itself the result.

**Idempotency and retries.** GET is safe and repeatable: TC-ORD-001 run twice must return identical bodies. POST declares no `Idempotency-Key` header or equivalent, so the API promises nothing. TC-ORD-070 (@regression @api @p1 @candidate): send the same valid POST twice and record whether two orders with different ids result. Expected under today's contract: two orders. Report that as a documented risk for retrying clients, not as a defect, and recommend an idempotency key if consumers retry on timeout. TC-ORD-071: PUT and DELETE are not in the contract, covered by TC-ORD-053.

**Shared-environment rules for the run.** Only `GET` on the seeded ids 1042 and 999999; every `POST` uses a note prefixed with a unique run id so the orders can be found and removed afterwards. The contract has no `DELETE`, so cleanup needs a database or admin route the owner provides; without one, created orders stay in staging and the run must say so. After the run, list orders by the run-id note and confirm the count matches what was created.

## 3. Automation outline, strategy and limits

**Automation (step 4), not written here.** The request was conformance and design, and no files were to be created. When the specs are written: a helper with one method per endpoint (`getOrder`, `createOrder`) and no assertions; the OpenAPI document loaded once and compiled into validators per operation and status, so a test asserts `validate("GET /orders/{id}", 200, body)` instead of hand-written field checks; each test creates its own order and removes it in a `finally` block once a cleanup route exists. Each new assertion gets a red-green proof by changing the expected status or a schema type in a throwaway copy and keeping the failing output. The package's `check-test-evidence.sh` was not run because no specs exist yet.

**Contract strategy (step 5).** Activity: provider-side conformance checking, category test execution and comparison (CTFL v4.0 §6.1). Recommendation: **schema conformance checks are enough, kept running in CI against staging on every deploy.** The cheap first step already found eight findings from three responses without any consumer involvement. Consumer-driven contracts would be justified only if several independently released consumers depend on this API, the provider team cannot see or test them, and breaking changes have already reached them. Nothing in the request establishes that, so the extra process, provider verification step and broker owner are not warranted today. Tool choice for the validator comes after this decision and after the repository's runner is known.

**Defects to file through `/qa-defect`**

1. M1: `total` serialised as a string on `GET /orders/{id}` 200 (confirm with the owner whether deliberate before filing).
2. M3: 404 error body omits required `code`.
3. M4 and M5 together: over-long `note` returns 500 with a non-contract body instead of 400 with Error.
4. M6: 500 message discloses database column type (security).
5. If TC-ORD-060 or 062 return another user's order: unauthenticated or cross-user read of orders (security, p0).

**Drift to return to the document owner.** M2 (`note` nullability), M7 (`note` `maxLength: 500`), the undocumented 400 for invalid `id`, and the absence of any `securitySchemes` if auth does in fact exist.

**What this report cannot show.** No request was sent in this session, so "conforms" was not claimed for anything beyond the three recordings. Never triggered: a documented 400 on POST, a 201 at all, any GET for an id below 1 or non-integer, any auth response, idempotent-retry behaviour, and the side effect of recording 3 (M8). The order lifecycle beyond `placed` cannot be exercised through this contract. Staging has changed since 2026-10-15 for all anyone knows; the first automated run re-establishes every row above.

**Rules.** The `testing-guidelines`, `context-discovery`, `security-qa` and `test-tools` rules were read and applied. The `code-style-qa` and `test-evidence` rules were not applied because no test code or evidence was produced.
