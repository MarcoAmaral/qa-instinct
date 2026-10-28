All three recorded responses violate the 2.1.0 contract, and the third also leaks database internals. Findings, assumptions, and the test design follow.

Assumptions made where the recordings are silent:
- The contract is the source of truth because the deployed version matches it, so each mismatch is an API defect unless the team explicitly decides to change the spec.
- Requests were sent with `Content-Type: application/json`, no authentication, and the long note was plain ASCII.
- The database column limit of 500 characters is the intended business limit for `note`.
- A newly created order has status `placed`.
- The recordings are ten days old. Each finding should be re-reproduced on current staging before filing.

## Contract mismatches

| # | Recording | Contract says | Mismatch | Severity | Recommended fix |
|---|---|---|---|---|---|
| 1a | GET /orders/1042 returns `"total": "42.50"` | `Order.total` is `type: number` | Value is a JSON string, not a number. Typed clients will fail to deserialize or silently coerce money values. | High | Serialize `total` as a JSON number. If the team wants string decimals for precision, that is a breaking change and needs a new major contract version with `type: string` and a pattern. |
| 1b | GET /orders/1042 returns `"note": null` | `Order.note` is `type: string`, optional, not `nullable` | OpenAPI 3.0.3 rejects null for a non-nullable string. Strict deserializers will reject the payload. | Medium | Omit `note` when the order has none. Alternatively add `nullable: true` to the contract, which is non-breaking. |
| 2 | GET /orders/999999 returns `{"message": "Order not found"}` | `Error` requires both `code` and `message` | Required `code` field is missing. Clients that branch on the error code cannot. | High | Return a stable machine-readable code such as `order_not_found` alongside the message. |
| 3a | POST /orders with 5,000-char note returns 500 | Only 201 and 400 are documented; `note` has no `maxLength` | A contractually valid request produces an undocumented 5xx. The server never validated input before hitting the database. | High | Validate `note` length before persistence and return 400 with an `Error` body. Add `maxLength: 500` to `NewOrder.note` so the limit is public. |
| 3b | Body is `{"error": "value too long for type character varying(500)"}` | 4xx bodies must match `Error`; no 5xx body is defined | Body uses an undocumented `error` key and lacks `code` and `message`. | Medium | Route all error paths through one `Error` serializer, including unhandled exceptions. |
| 3c | The 500 body echoes a raw PostgreSQL message | Not covered by the contract, but a security defect | Reveals the database engine, column type, and length. This is information disclosure and suggests other DB errors leak the same way. | High, security | Never forward database or stack messages to clients. Log them server-side with a correlation id and return a generic `Error`. |

Contract gaps surfaced by the same evidence, independent of the three defects:
- `GET /orders/{id}` defines no 400 response, yet the path parameter has `minimum: 1` and `type: integer`. Behaviour for `0`, negatives, and non-numeric ids is unspecified.
- No `default` or 500 response is defined anywhere, so there is no agreed shape for unhandled failures.
- `Error.code` has no enum or documented value list, so clients cannot know which codes to handle.
- `NewOrder` does not set `additionalProperties: false`, so unknown fields are silently accepted. That may be intended, but it should be a conscious choice.
- Nothing states whether a 500-character limit on `note` counts characters or bytes. PostgreSQL `varchar(n)` counts characters, which must be verified for multibyte input.

## Test design

Every test below validates the full response, status code, `Content-Type`, and body, against the OpenAPI schema with a JSON Schema validator in the assertion step. A single generic assertion also applies to every test: no response may ever be 5xx, and no body may contain the strings `character varying`, `psql`, `postgres`, `SQL`, `Traceback`, or `Exception`.

GET /orders/{id}

| ID | Purpose | Input | Expected | Covers |
|---|---|---|---|---|
| G01 | Happy path, schema conformance | Existing paid order | 200, `Order` schema valid, `total` is a JSON number, `status` in enum | 1a |
| G02 | Note absent versus present | One order without a note, one with | Without: `note` key omitted or valid string, never null. With: exact string returned | 1b |
| G03 | Every status value | Seeded orders in `placed`, `paid`, `shipped` | 200 with the matching enum value; no other status ever appears | enum |
| G04 | Money precision | Orders with totals 0, 0.1, 42.5, 1234567.89, 1e9 | Numeric value equals stored total to the cent; no float drift like 42.49999 | 1a |
| G05 | Unknown id | 999999 and the largest id plus one | 404, `Error` with `code` and `message` | 2 |
| G06 | Below minimum | `0`, `-1` | A documented 4xx, never 500. Recommend 400. Flag that the contract must choose | gap |
| G07 | Non-integer ids | `abc`, `1.5`, `1e3`, `01`, `%20`, `9223372036854775808`, empty segment | 400 or 404 per the agreed contract; never 500 | gap |
| G08 | Headers | Any valid id | `Content-Type: application/json`; `charset` if present is UTF-8 | hygiene |
| G09 | Unsupported methods | PUT, DELETE, PATCH on `/orders/1042` | 405 with `Allow` header, or a documented 4xx | hygiene |
| G10 | Deleted or hidden order | Id of a soft-deleted order, if the domain has them | 404 with the same `Error` shape as G05 | 2 |

POST /orders

| ID | Purpose | Input | Expected | Covers |
|---|---|---|---|---|
| P01 | Minimal valid | `{"items":["sku-1"]}` | 201, `Order` schema valid, integer `id` at or above 1, status `placed`, `note` absent | baseline |
| P02 | With note | Valid items plus a 20-char note | 201, note echoed verbatim | baseline |
| P03 | Note at the limit | Note of exactly 500 ASCII chars | 201 | 3a boundary |
| P04 | Note one over the limit | 501 ASCII chars | 400, `Error` with a stable code such as `note_too_long` | 3a |
| P05 | Note far over the limit | 5,000 chars, the recorded case | 400, same body shape as P04 | 3a, 3b, 3c |
| P06 | Multibyte at the boundary | 500 four-byte emoji; 500 two-byte characters; 501 of each | 201 for 500, 400 for 501, confirming the limit counts characters not bytes | 3a |
| P07 | Hostile note content | SQL quotes, `<script>`, NUL byte `\u0000`, lone surrogate, control chars, RTL marks | 201 or 400 with `Error`; never 500. The NUL byte is a known PostgreSQL rejection path and is the highest-risk case | 3c |
| P08 | Note wrong type | `note` as number, boolean, array, object | 400 with `Error` | validation |
| P09 | Note null | `"note": null` | 400, or treated as absent. Must match the decision taken for 1b and be documented | 1b |
| P10 | Note empty string | `"note": ""` | 201 and the read-back of G02 returns `""` or omits the key, consistently | 1b |
| P11 | Items missing | `{}` and `{"note":"x"}` | 400 with `Error` | required |
| P12 | Items empty | `{"items":[]}` | 400, enforcing `minItems: 1` | minItems |
| P13 | Items wrong type | `"items": null`, `"items": "sku-1"`, `"items": [1]`, `"items": [null]`, `"items": [{}]` | 400 with `Error` for each | validation |
| P14 | Items edge values | `[""]`, `["sku-1","sku-1"]`, 10,000 items, a 10,000-char item string | 201 or a documented 400; never 500 or timeout. Flag whatever the API does so the contract can state it | gap |
| P15 | Unknown SKU | `["does-not-exist"]` | Contract is silent. Expect 400 with a distinct `code`. Flag for contract update | gap |
| P16 | Unknown extra property | `{"items":["sku-1"],"foo":1}` | 201 with the field ignored, unless the team chooses `additionalProperties: false` | gap |
| P17 | Malformed body | Empty body, truncated JSON, `[]`, a bare string, trailing comma | 400 with `Error`, never 500 | 3b |
| P18 | Wrong or missing content type | `text/plain`, `application/x-www-form-urlencoded`, no header | 400 or 415, body still `Error`; never 500 | 3b |
| P19 | Oversized payload | 10 MB body | 413 or 400 within a bounded time; never 500 or hang | robustness |
| P20 | Round trip | POST then GET the returned id | GET body equals POST body field for field, including `total` type | 1a, consistency |
| P21 | Duplicate submission | Same body sent twice | Two distinct ids, or a documented idempotency behaviour. Flag whichever is observed | gap |
| P22 | Error body shape | Every 400 from P04 through P18 | Each `code` is a non-empty string from one documented set; `message` is human-readable and contains no internals | 3b, 3c |

Cross-cutting and automation:
- Run schema-driven fuzzing, for example Schemathesis, against staging in CI with the 5xx and leak assertions above. It would have found all three defects without hand-written cases.
- Lint the spec, for example with Spectral, and add custom rules requiring a 400 on every operation with parameters, a `default` error response, and an enum on `Error.code`.
- Gate contract changes. Any diff to the OpenAPI file must be reviewed with the matching API change, and the version must bump correctly, major for 1a if the string-money option is chosen.
- Add server-side error-handler unit tests that assert every uncaught exception becomes a generic `Error` body with a correlation id and that the original message is only written to logs.
- Record these recordings as regression fixtures. Tests G01, G05, and P05 fail today and should be the first three to go green.
