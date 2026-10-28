# Orders API 2.1.0: contract check and test plan

The 3 recorded responses contain 7 mismatches against the contract, and the contract itself has 4 gaps that the tests below must settle before they can be written.

## Assumptions

- The staging build is the same code as version 2.1.0 in the spec, so every mismatch is a bug in either the server or the spec, not a version skew.
- The database column `note varchar(500)` reflects the intended limit. The fix is to enforce 500 characters at the API, not to widen the column.
- Money values should stay `number` as the contract says. If the team prefers a decimal string, that is a breaking contract change and needs a new major version.
- A new order starts with status `placed`, and the server computes `total` from the items. The contract does not say either.
- Order 999999 did not exist when recorded, so the 404 status itself is correct.

## Mismatches in the recorded responses

| # | Recorded response | Contract says | Response shows | Impact | Fix |
| --- | --- | --- | --- | --- | --- |
| 1 | GET /orders/1042 | `total` is `number` | `"42.50"`, a string | Typed clients fail to parse or silently treat money as text | Server: return `42.5` as a JSON number |
| 2 | GET /orders/1042 | `note` is `string`, not nullable | `null` | Strict validators reject the body; OpenAPI 3.0.3 needs `nullable: true` for null | Server: omit `note` when unset. Alternative: add `nullable: true` to the spec |
| 3 | GET /orders/999999 | Error requires `code` and `message` | Only `message` | Clients that branch on `code` cannot tell this 404 from any other | Server: add `code`, for example `order_not_found` |
| 4 | POST /orders (5,000-char note) | Only 201 and 400 are documented | 500 | Undocumented status; clients have no defined handling | Server: validate note length and return 400 |
| 5 | POST /orders (5,000-char note) | Error body has `code` and `message` | `{"error": "..."}`, a different shape | Error parsing fails for every client | Server: use the Error schema for every error, including 5xx |
| 6 | POST /orders (5,000-char note) | `note` has no `maxLength`, so the request is valid | Server rejects it | Contract and server disagree on what a valid order is | Spec: add `maxLength: 500` to `NewOrder.note` and `Order.note` |
| 7 | POST /orders (5,000-char note) | Nothing about internals | Raw PostgreSQL error text `character varying(500)` | Leaks database engine and column type to callers | Server: never pass database messages through; log them, return a generic Error |

Mismatches 4 to 7 come from one root cause: no input validation on `note` before the insert. One fix closes all four.

## Contract gaps found while checking

These are not mismatches, but the tests cannot assert a result until they are decided.

| Gap | Where | Decision needed |
| --- | --- | --- |
| No response for an invalid `id` such as `/orders/0`, `/orders/-1` or `/orders/abc` | GET /orders/{id} | Document a 400 with the Error schema. Assumed below. |
| No 5xx response documented anywhere | Both paths | Add a `default` response using the Error schema so clients know every error has `code` and `message` |
| `Order` has no `items` field, so a created order does not show what was ordered | Order schema | Decide whether `items` belongs in `Order`. Tests below do not assume it |
| No 415 or malformed-JSON response for POST | POST /orders | Document a 400 with the Error schema. Assumed below |

## Tests this API needs

### 1. Schema conformance on every response

One rule, applied to every test below: the status code must appear in the contract for that operation, and the body must validate against the schema for that status. This single check would have caught all 7 mismatches.

### 2. GET /orders/{id}

| Test | Request | Expected |
| --- | --- | --- |
| Existing order | GET /orders/1042 | 200, body validates against Order, `total` is a JSON number, `status` is one of `placed`, `paid`, `shipped` |
| Order with no note | GET on an order created without a note | 200, `note` absent (or `null` only if the spec adds `nullable`) |
| Order with a note | GET on an order created with a note | 200, `note` echoed as a string |
| One order per status | GET on an order in each of the 3 states | 200, `status` matches the enum spelling exactly |
| Unknown id | GET /orders/999999 | 404, body validates against Error with `code` and `message` |
| Id below minimum | GET /orders/0 | 400, Error schema (assumed) |
| Negative id | GET /orders/-1 | 400, Error schema (assumed) |
| Non-integer id | GET /orders/abc, GET /orders/1.5 | 400, Error schema (assumed), never 500 |
| Very large id | GET /orders/99999999999999999999 | 400 or 404, Error schema, never 500 |

### 3. POST /orders

| Test | Request body | Expected |
| --- | --- | --- |
| Minimal valid order | `{"items": ["sku-1"]}` | 201, Order schema, `status` is `placed`, `total` is a number, `note` absent |
| Order with note | `{"items": ["sku-1"], "note": "gift"}` | 201, `note` is `"gift"` |
| Round trip | POST then GET /orders/{id} from the response | GET returns the same `id`, `status`, `total` and `note` |
| Missing items | `{}` | 400, Error schema |
| Empty items | `{"items": []}` | 400, Error schema (`minItems: 1`) |
| Wrong item type | `{"items": [1, 2]}` | 400, Error schema |
| Wrong note type | `{"items": ["sku-1"], "note": 42}` | 400, Error schema |
| Note at the limit | note of exactly 500 characters | 201 |
| Note one over the limit | note of 501 characters | 400, Error schema, never 500 |
| Note far over the limit | note of 5,000 characters | 400, Error schema. Regression test for mismatches 4 to 7 |
| Note with multibyte characters | 500 characters that are 4 bytes each | 201. Confirms the limit counts characters, not bytes |
| Unknown field | `{"items": ["sku-1"], "extra": true}` | 201 and the field is ignored, since the spec does not set `additionalProperties: false`. Document whichever the team picks |
| No body | empty request | 400, Error schema |
| Malformed JSON | `{"items": [` | 400, Error schema, never 500 |
| Wrong content type | `text/plain` body | 400 or 415, Error schema (assumed 400) |

### 4. Error shape and information leakage

| Test | How | Expected |
| --- | --- | --- |
| Every error uses the Error schema | Run every 4xx and 5xx case above | `code` and `message` present, no other top-level keys such as `error` |
| No internal detail in messages | Assert on every error body | Message does not contain `varying`, `relation`, `column`, `SQL`, a stack trace or a file path |
| Error codes are stable | Collect `code` from every error case | Each distinct error has one documented code, and the codes are listed in the spec |

### 5. Contract hygiene

Run these on the spec file itself, in CI, before any server test.

- Lint the spec with Spectral or an equivalent. Fail on an unused schema, a missing `default` error response, or a `string` property returned as `null` without `nullable`.
- Diff the spec against the previous tag. Any change to a response schema requires a version bump in `info.version`.
- Generate the client from the spec and compile it against the recorded responses. Mismatches 1 and 2 break generated clients at parse time.

### 6. Automation

- Run property-based contract tests with Schemathesis against staging on every deploy. It generates requests from the spec, including long strings, and flags any undocumented status. Mismatch 4 would have been found on the first run.
- Record one response per documented status per operation and store it next to the spec. Validate the recordings against the schemas in CI so the recordings cannot drift the way these 3 did.
- Treat any 5xx in the test run as a failure, regardless of what the test expected.

## Order of work

1. Fix `note` validation and the error handler on the server. This closes mismatches 4, 5, 6 and 7 and the leak.
2. Fix `total` and `note` in the GET response, and add `code` to the 404. This closes mismatches 1, 2 and 3.
3. Update the spec: `maxLength: 500`, a 400 on GET, and a `default` Error response. Release as 2.1.1.
4. Add the schema conformance check and the Schemathesis run to CI so the next regression fails before staging.
