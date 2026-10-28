**Summary:** all 3 recorded responses break the contract. The GET success body returns the wrong type for `total` and a null `note`. The 404 body is missing a required field. The POST returns an undocumented 500 with an undocumented body and leaks a database error. Five fixes are needed, and the test plan below covers them plus the gaps the recordings did not reach.

Assumptions, because the recordings do not say:

- Responses were sent with `Content-Type: application/json`.
- The 5,000-character note was plain ASCII, so characters equal bytes.
- The database column behind `note` is `varchar(500)` on a PostgreSQL database. The error text is PostgreSQL's wording.
- The API has no authentication, since the spec defines none.
- Staging runs the same code as the version 2.1.0 the spec describes.

## Mismatches

| # | Request | What the contract says | What the server did | Severity |
| --- | --- | --- | --- | --- |
| 1a | GET /orders/1042 | `Order.total` is `number` | Returned the string `"42.50"` | High. Typed clients fail to parse the response. |
| 1b | GET /orders/1042 | `Order.note` is `string`, not nullable | Returned `null`. OpenAPI 3.0.3 needs `nullable: true` to allow this. | Medium. Strict validators reject the body. |
| 2 | GET /orders/999999 | 404 body is `Error`, which requires `code` and `message` | Returned only `message` | Medium. Clients that branch on `code` cannot. |
| 3a | POST /orders, valid body | Only 201 and 400 are defined | Returned 500 | High. A request that passes the schema must never produce a server error. |
| 3b | POST /orders, valid body | Error bodies have `code` and `message` | Body used an `error` key and neither required field | Medium. Same client breakage as #2. |
| 3c | POST /orders, valid body | `NewOrder.note` has no length limit | Storage allows 500 characters | High. The spec promises more than the system accepts. |
| 3d | POST /orders, valid body | No rule, but a quality issue | Response text reveals the database type and column size | Medium. Internal details leak to callers. |

Two gaps in the contract itself showed up while checking:

- GET /orders/{id} declares `minimum: 1` and `type: integer` for the id, but defines no 400 response. Requests like `/orders/0` or `/orders/abc` have no documented outcome.
- No operation documents a 500. A generic server error response using the `Error` schema is missing.

## Fixes to agree before testing

Each mismatch has two possible owners. The tests below assume the choices marked as recommended.

1. **`total` type.** Recommended: keep `number` in the spec and fix the server. Note the risk: binary floating point is a poor fit for money. If the team prefers decimal strings, change the spec to `type: string` with a decimal pattern instead, and update test G2.
2. **`note` null.** Recommended: the server omits the key when there is no note. The alternative is adding `nullable: true` to `Order.note` in the spec.
3. **404 body.** Server adds a stable `code`, for example `order_not_found`.
4. **Note length.** Spec adds `maxLength: 500` to `NewOrder.note`. Server validates before writing and returns 400 with an `Error` body. The code should be something like `note_too_long`.
5. **Error handling.** Spec adds a documented 500 with the `Error` schema. Server maps every unhandled exception to that shape and never echoes database messages.
6. **Invalid path id.** Spec adds a 400 response to GET /orders/{id}.

## Test design

Run every test against the spec with a schema validator in the test harness. Two checks apply to every response of every test and are not repeated below:

- The status code is one the spec defines for that operation.
- The body validates against the schema the spec assigns to that status code, and the content type is `application/json`.

**GET /orders/{id}**

| ID | Request | Expected |
| --- | --- | --- |
| G1 | Known id | 200. `id` is an integer and equals the path id. |
| G2 | Known id | `total` is a JSON number, not a string. Regression for mismatch 1a. |
| G3 | Known id with no note | The `note` key is absent, not null. Regression for 1b. |
| G4 | Known id with a note | `note` is a string equal to what was stored. |
| G5 | One order in each status | `status` is one of `placed`, `paid`, `shipped`. Fail on any other value. |
| G6 | Unknown id | 404. Body has `code` and `message`. Regression for mismatch 2. |
| G7 | `/orders/0` and `/orders/-1` | 400 with an `Error` body. Depends on fix 6. |
| G8 | `/orders/abc` and `/orders/1.5` | 400 with an `Error` body. |
| G9 | An id above the 64-bit integer range | 400, never 500. |

**POST /orders**

| ID | Request | Expected |
| --- | --- | --- |
| P1 | `{"items": ["sku-1"]}` | 201. Body is an `Order`. `status` is `placed`. |
| P2 | Items plus a short note | 201. `note` is returned unchanged. |
| P3 | Note of exactly 500 characters | 201. Upper boundary. |
| P4 | Note of 501 characters | 400 with `Error`. Lower boundary of the failure. |
| P5 | Note of 5,000 characters | 400 with `Error`. Exact regression for mismatch 3a to 3d. |
| P6 | Note of 500 multi-byte characters, for example emoji | 201. Proves the limit counts characters, not bytes. If it fails, the column limit and the spec disagree on units. |
| P7 | `{"items": []}` | 400. `minItems` enforced. |
| P8 | `{}` and `{"note": "x"}` | 400. `items` required. |
| P9 | `{"items": [1, 2]}` and `{"items": "sku-1"}` | 400. Item type enforced. |
| P10 | `{"items": ["sku-1"], "note": 42}` | 400. Note type enforced. |
| P11 | Empty body | 400. Request body is required. |
| P12 | Malformed JSON | 400 with `Error`, never 500. |
| P13 | Body sent as `text/plain` | 400 or 415. Pick one and add it to the spec. |
| P14 | Extra unknown field | Assumption: ignored, 201. Confirm with the team. |

**Cross-cutting**

| ID | Check | Expected |
| --- | --- | --- |
| X1 | POST then GET the returned id | The GET body equals the POST body, including `total` and `note`. |
| X2 | Every 4xx and 5xx body in the suite | Validates against `Error`. Same shape everywhere. |
| X3 | Every error `message` in the suite | Contains none of `character varying`, `varchar`, `SQL`, `pg_`, or a stack trace. Regression for 3d. |
| X4 | Property test: generate 500 random bodies that pass `NewOrder` | No response is 5xx. |
| X5 | Property test: generate 500 random bodies that fail `NewOrder` | Every response is 400 with `Error`. |
| X6 | Spec lint | Every response the server can produce is documented. Fails until fixes 5 and 6 land. |

Run G1 to G9 and P1 to P14 on every deploy to staging. Run X4 and X5 nightly, since they take longer. P5 and X3 are the two tests that would have caught the recorded failure, so add them first.
