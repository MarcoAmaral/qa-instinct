## 1. Contract mismatches in the recorded responses

Contract version and deployed version both read 2.1.0, so every finding below is real drift, not version skew. Assumption: the contract is the source of truth, and the recordings captured full bodies but not headers, so Content-Type cannot be checked.

| # | Recording | Finding | Contract rule violated | Severity |
|---|---|---|---|---|
| M1 | 1, GET /orders/1042 | `total` is the string `"42.50"` | `Order.total` is `type: number` | High. Clients doing arithmetic on `total` get type errors or string concatenation. |
| M2 | 1, GET /orders/1042 | `note` is `null` | `Order.note` is `type: string` with no `nullable: true`. In OpenAPI 3.0.3 null is invalid unless `nullable` is declared. | Medium. Optional field should be omitted, or the contract must declare it nullable. |
| M3 | 2, GET /orders/999999 | Error body has no `code` | `Error` requires `[code, message]` | Medium. Clients branching on `code` cannot distinguish error kinds. |
| M4 | 3, POST /orders | Status 500 | Only 201 and 400 are documented. An oversized optional field is a client-input problem and must map to 400. | High. Unhandled input crashes the request path. |
| M5 | 3, POST /orders | Body is `{"error": ...}` | Not an `Error` object: wrong key, no `code`, no `message` | Medium. Even undocumented statuses should use the shared error shape. |
| M6 | 3, POST /orders | Message is a raw PostgreSQL error naming the column type | Not a contract rule, but an information-disclosure defect | High. Leaks schema internals to any unauthenticated caller. |
| M7 | 3, POST /orders | Unknown whether a partial order row or side effects (totals, inventory) were committed before the failure | Not visible in the recording | Needs verification. Treat as High until a follow-up GET proves nothing was persisted. |

Root-cause notes:

- **M1** is almost certainly a DECIMAL column serialised as a string. That is a defensible money-handling choice, but then the contract must change to `type: string` with a pattern. Either fix the serializer or the spec, not neither.
- **M4 through M6** share one root cause. The `note` column is `varchar(500)` and the handler does no length validation before the insert. The contract also has no `maxLength` on `NewOrder.note`, so the spec cannot be satisfied as written.
- **M3** suggests the 404 path uses a different error serializer than the rest of the API, or `code` was never implemented. Check whether 400 responses also lack it.

## 2. Contract gaps found while reviewing

These are not mismatches in the recordings, but the contract is silent where the API must behave somehow. Each becomes a test with an assumed expected result.

- **`note` has no `maxLength`.** Assumed intended limit is 500 characters to match the database. Spec should state it.
- **`Order` has no `items` property.** A created order drops the one thing the client sent. Assumed to be an oversight. Flag for the API owner, tests below only assert what the spec declares.
- **No response is documented for invalid `id`** such as `0`, `-1`, `abc`, `1.5`, or a value beyond int64. Assumed expected result is 400 with an `Error` body.
- **No 405, 415, 401, or 403 documented.** Assumed: no authentication on this API, unsupported methods return 405, non-JSON content types return 415.
- **`Error.code` has no enum.** Tests can only assert it is a non-empty string. Recommend enumerating codes.
- **`items` entries have no pattern or `maxLength`.** Empty strings and 10,000-character strings are currently valid per the spec. Recommend a SKU pattern.
- **`total` has no `minimum`.** Negative totals are valid per the spec.
- **No `additionalProperties: false`.** Extra fields will never be caught by contract validation. Decide deliberately.

## 3. Test design

All tests run against staging with the deployed version header or `/version` checked first, so a future drift is attributed correctly. Every response in every test is validated against the contract schema automatically, in addition to the specific assertions listed. Tests marked **FAILS NOW** are expected to fail until the matching defect is fixed, and must be tracked as known failures rather than skipped.

**Group A. Contract conformance, run on every response**

| ID | Check | Guards |
|---|---|---|
| A1 | Status code is one listed for the operation. | M4 |
| A2 | `Content-Type` is `application/json`. | Unverified in recordings |
| A3 | Body validates against the schema for that status. Type checks are strict: a numeric string is not a number. | M1, M2, M3, M5 |
| A4 | No field is `null` unless the schema declares `nullable: true`. | M2 |
| A5 | Any 4xx or 5xx body validates against `Error`, even for undocumented statuses. | M5 |
| A6 | Error `message` never contains `character varying`, `relation`, `column`, `syntax error`, stack-trace markers, or file paths. | M6 |

**Group B. GET /orders/{id}**

| ID | Input | Expected | Notes |
|---|---|---|---|
| B1 | Existing id, note set | 200, all required fields, `total` is a JSON number, `note` is a string | **FAILS NOW** on M1 |
| B2 | Existing id, note never set | 200, `note` key absent | **FAILS NOW** on M2 |
| B3 | Each status `placed`, `paid`, `shipped` | 200, `status` matches enum | Seed one order per status |
| B4 | Non-existent id, e.g. 999999 | 404, `Error` with non-empty `code` and `message` | **FAILS NOW** on M3 |
| B5 | `id` = 0 | 400 (assumed), `Error` body | Minimum is 1 |
| B6 | `id` = -1 | 400 (assumed) | |
| B7 | `id` = `abc`, `1.5`, `1e3`, ` 1`, `1;` | 400 (assumed), never 500 | |
| B8 | `id` = 9223372036854775808 (int64 + 1) | 400 or 404, never 500 | Overflow handling |
| B9 | `id` = `1 OR 1=1`, `../1`, `%00` | 400 or 404, never 500, no DB text in body | Injection and parsing |
| B10 | Deleted or soft-deleted order id | 404 | Assumption: soft-deletes exist. Remove if not. |
| B11 | Order belonging to another tenant or user | 404, not the record | Only if the API has ownership. Assumed none, so parked. |
| B12 | `total` with many decimals, e.g. 0.1 + 0.2 seeded | Exact value, no float drift | Supports the M1 decision |

**Group C. POST /orders, happy path**

| ID | Input | Expected |
|---|---|---|
| C1 | `{"items": ["sku-1"]}` | 201, `Order` with `id` integer, `status` = `placed` (assumed initial), `total` number, no `note` key |
| C2 | `{"items": ["sku-1"], "note": "hello"}` | 201, `note` = `"hello"` echoed exactly |
| C3 | `{"items": ["sku-1", "sku-2", "sku-1"]}` | 201. Duplicates allowed per spec. Assert `total` reflects three items if pricing is observable. |
| C4 | Create, then GET by returned `id` | GET body equals POST body |
| C5 | Note containing Unicode, emoji, RTL text, quotes, backslashes | 201, round-trips byte-exact through C4 |
| C6 | Note of exactly 500 characters | 201 |
| C7 | Note of 500 multi-byte characters (e.g. `é` or `日`) | 201. PostgreSQL `varchar(n)` counts characters, not bytes, so this must pass. |

**Group D. POST /orders, validation**

| ID | Input | Expected | Notes |
|---|---|---|---|
| D1 | Note of 501 characters | 400, `Error` body, no DB text | **FAILS NOW** on M4, M5, M6 |
| D2 | Note of 5,000 characters (the recorded case) | 400 | **FAILS NOW**. Then GET the newest order id and confirm nothing was created. Guards M7. |
| D3 | Note of 1 MB | 400 or 413, not 500, response under 2 s | Payload limit |
| D4 | `{}` | 400 | `items` required |
| D5 | `{"items": []}` | 400 | `minItems: 1` |
| D6 | `{"items": null}` | 400 | |
| D7 | `{"items": "sku-1"}` | 400 | Array required |
| D8 | `{"items": [1]}`, `[null]`, `[{}]`, `[""]` | 400 for the first three. `[""]` is currently valid per spec, so expected 201 and flagged as a spec gap. | |
| D9 | `{"items": ["sku-1"], "note": 42}`, `note: null`, `note: {}` | 400 | |
| D10 | `{"items": ["sku-1"], "extra": "x"}` | 201 per current spec. Document the decision. | |
| D11 | Empty body, `null`, `[]`, `"string"` | 400 | |
| D12 | Malformed JSON `{"items": [` | 400, not 500 | |
| D13 | `Content-Type: text/plain` with valid JSON | 415 (assumed) | |
| D14 | No `Content-Type` header | 400 or 415, not 500 | |
| D15 | Note containing `'; DROP TABLE orders; --` | 201, stored literally, C4 round-trip | Parameterised queries |
| D16 | 10,000 items of 1 character each | 201 or 400, not 500 or timeout | No `maxItems` in spec, flag as gap |
| D17 | Unknown SKU in `items` | Spec is silent. Assumed 400 with a distinct `code`. | |

**Group E. Method and protocol**

| ID | Input | Expected |
|---|---|---|
| E1 | PUT, PATCH, DELETE on `/orders/1042` | 405 with `Allow: GET` |
| E2 | GET `/orders` | 405 |
| E3 | POST `/orders/1042` | 405 |
| E4 | GET `/orders/1042` with `Accept: text/xml` | 406 or JSON anyway, never 500 |
| E5 | Trailing slash `/orders/1042/` | Consistent with the no-slash form, documented either way |

**Group F. Non-functional and regression safety**

- **F1, no 5xx under fuzzing.** Run a schema-driven fuzzer (Schemathesis or equivalent) against the contract for 30 minutes. Any 5xx is a failure. This alone would have caught recording 3.
- **F2, error-body uniformity.** Collect every 4xx and 5xx produced in groups B through E and assert each has `code` and `message` and nothing else leaked. Catches M3 and M5 across all paths at once.
- **F3, concurrency.** 50 parallel valid POSTs return 50 unique ids and 50 retrievable orders.
- **F4, latency baseline.** p95 for GET under 200 ms and POST under 500 ms on staging. Assumed thresholds, adjust to the team's SLO.
- **F5, idempotency.** Replaying the same POST twice creates two orders, since the spec has no idempotency key. Document this as intended or add a key.

**Recommended fixes before the failing tests can go green**

1. Add `maxLength: 500` to `NewOrder.note` and validate it in the handler before the insert. Return 400 with a code such as `note_too_long`.
2. Wrap the database layer so any unexpected exception becomes a 500 with a generic `Error` body and the real message goes only to logs.
3. Return `total` as a JSON number, or change the contract to a decimal string. Pick one and version it.
4. Omit `note` when unset, or add `nullable: true` to `Order.note`.
5. Add `code` to the 404 serializer and define an enum of error codes in the contract.
6. Add response-schema validation to the CI pipeline so every one of these mismatches blocks a merge rather than being found in a recording.
