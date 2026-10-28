**Result: all three recorded responses violate the contract.** Six distinct mismatches, two of which point at the contract itself being incomplete rather than only the server being wrong.

Assumptions: the recordings show the full response bodies, every response was served as `application/json`, the database column behind `note` is `varchar(500)`, and the contract is the intended source of truth where it is explicit.

## Mismatches

| # | Recording | Field or aspect | Contract says | Observed | Severity |
|---|-----------|-----------------|---------------|----------|----------|
| 1 | GET /orders/1042 | `total` | `type: number` | `"42.50"`, a string | High. Any typed client deserialising `Order` will fail or silently coerce. |
| 2 | GET /orders/1042 | `note` | `type: string`, not nullable | `null` | Medium. OpenAPI 3.0 forbids null unless `nullable: true`. Either omit the key or mark it nullable. |
| 3 | GET /orders/999999 | `Error.code` | required | absent | High. Clients that branch on `code` cannot handle the 404. |
| 4 | POST /orders, long note | status code | only 201 and 400 defined | 500 | High. A contract-valid request produced an undocumented server error. |
| 5 | POST /orders, long note | error body shape | `Error` with `code` and `message` | `{"error": ...}`, neither required field present | High. Third distinct error envelope in three recordings. |
| 6 | POST /orders, long note | `NewOrder.note` length | no `maxLength`, so 5,000 chars is valid input | rejected by a 500-char database column | Medium. Contract and storage disagree. Add `maxLength: 500` and return 400, or widen the column. |

Two further problems sit outside a strict schema check but need fixing alongside the above:

- **Internal detail leaks.** The 500 body echoes a Postgres error including the column type. That exposes schema details to any caller and should never reach the response.
- **Contract gaps the recordings expose.** GET /orders/{id} declares `minimum: 1` on `id` but documents no response for an invalid id such as `0` or `abc`. The `Error` schema has no documented `code` values, so the one field clients should branch on has no vocabulary. Neither `items` entries nor `total` carry any constraint, so the contract cannot distinguish a valid SKU from an empty string or a negative total.

## Test design

Run two layers: a generated contract suite that validates every response against the schema for its status code, plus hand-written cases for behaviour the generator cannot infer. Each case below names the expected status and the schema the body must satisfy. Cases marked **R** are regressions for the recordings above and should fail today.

### GET /orders/{id}

| Case | Input | Expect |
|------|-------|--------|
| Existing order **R** | id of a seeded order | 200, body validates as `Order`, `total` is a JSON number, `note` either absent or a string |
| Order with no note **R** | seeded order with empty note | 200, `note` key absent or string, never `null` |
| Order in each status | one seeded order per enum value | 200, `status` is exactly one of `placed`, `paid`, `shipped` |
| Unknown id **R** | `999999` | 404, body validates as `Error`, `code` present and documented |
| Below minimum | `0`, `-1` | Same status for both, body validates as `Error`. Assumed 404 until the contract documents 400 for this endpoint. |
| Non-integer id | `abc`, `1.5`, `1e3`, empty segment | Same assumption as above. Never 500. |
| Overflow id | `99999999999999999999` | Non-5xx, `Error` body |
| Other methods | DELETE, PUT on the path | 405 or 404, `Error` body, never 500 |

### POST /orders

| Case | Input | Expect |
|------|-------|--------|
| Minimal valid | `{"items": ["sku-1"]}` | 201, body validates as `Order`, `status` is `placed`, `note` absent |
| With note | note of 1 char and of 500 chars | 201, `note` echoed back verbatim |
| Note at boundary **R** | note of 501 chars and of 5,000 chars | 400 with `Error` body once `maxLength` is added, or 201 if the column is widened. Never 500 and never a database message. |
| Multi-byte note | 500 characters that exceed 500 bytes | Same result as the 500-char ASCII case. Catches byte-versus-character limit bugs. |
| Missing items | `{}` and `{"note": "x"}` | 400, `Error` body |
| Empty items | `{"items": []}` | 400, violates `minItems: 1` |
| Wrong item types | `[1]`, `[null]`, `[{}]`, `[""]` | 400 for the first three. Empty string is contract-valid today, so record the current behaviour and raise it as a contract gap. |
| Unknown field | `{"items": ["sku-1"], "foo": 1}` | Record whether rejected or ignored, then pin it. Contract is silent. |
| Malformed body | invalid JSON, empty body, wrong content type | 400 or 415, `Error` body, never 500 |
| Round trip | POST then GET the returned `id` | GET body equals POST body field for field, `total` numeric in both |
| Large items array | 1,000 items | Non-5xx. Flags the missing `maxItems`. |

### Cross-cutting

- **Error envelope invariant.** Every non-2xx response from any endpoint validates as `Error`. One assertion run over the whole suite, so a fourth envelope shape cannot sneak in.
- **No leakage invariant.** No response body matches patterns such as `character varying`, `SQLSTATE`, `Traceback`, or `at .*\.java:`.
- **No 5xx invariant.** Fuzz both endpoints with a schema-driven generator such as Schemathesis using the contract above. Any 5xx fails the run. This would have caught recording 3 without a hand-written case.
- **Version pin.** Assert the served spec reports `2.1.0` so the suite fails loudly when run against a mismatched deployment.

### Contract changes to make before the suite can go green

1. Add `nullable: true` to `Order.note`, or stop emitting `null`.
2. Add `maxLength: 500` to `NewOrder.note` and `Order.note`.
3. Document a response for invalid `id` on GET, and enumerate `Error.code` values.
4. Add `minLength: 1` to `items` entries and `minimum: 0` to `total` so the generator stops producing degenerate inputs that are technically valid.
