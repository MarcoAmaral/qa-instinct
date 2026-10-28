---
title: Orders API contract check and test plan
slug: orders-api-contract-check-and-test-plan
article_type: reference
product_area: Orders API
audience: API developer, QA engineer
plan_availability: None: internal engineering document, not tied to a plan
reading_time: 6 min
related_articles: None: no related articles yet
last_updated: 2026-10-25
---

# Orders API contract check and test plan

All 3 recorded responses from staging on 2026-10-15 break the version 2.1.0 contract, and the API has no tests that would have caught them.

## Assumptions

- The OpenAPI document is the source of truth. Where the server differs, the server is wrong, unless the team decides to change the contract instead. One case where that choice is open is marked below.
- The recordings omit response headers. The checks below assume `Content-Type: application/json` on every response.
- The database column behind `note` holds 500 characters. The contract does not mention this limit.
- The 5,000-character note was plain ASCII text.
- The contract declares no authentication, so the tests send none.
- An order created through `POST /orders` starts with status `placed`.

## Mismatches found

| # | Recording | What the contract says | What the server did | Severity |
| --- | --- | --- | --- | --- |
| M1 | 1, `GET /orders/1042` | `total` is a `number` | `total` is the string `"42.50"` | High. Typed clients fail to parse the order. |
| M2 | 1, `GET /orders/1042` | `note` is a `string`; OpenAPI 3.0 needs `nullable: true` to allow null | `note` is `null` | Medium. Strict validators reject the body. |
| M3 | 2, `GET /orders/999999` | 404 body is an `Error` with required `code` and `message` | Body has `message` only; `code` is missing | Medium. Clients cannot branch on an error code. |
| M4 | 3, `POST /orders` | Only 201 and 400 are defined | Returned 500 | High. Undocumented status. |
| M5 | 3, `POST /orders` | `note` is a `string` with no `maxLength`, so the request is valid | Request rejected | High. A valid request must not fail. |
| M6 | 3, `POST /orders` | Every error body is an `Error` object | Body is `{"error": ...}` with no `code` or `message`, and the text exposes a database column type | High. Wrong shape and an information leak. |

Items that did match: status 200 and the `id` and `status` fields in recording 1, and status 404 in recording 2. The request in recording 3 is valid under the contract.

## Fixes to decide before writing the tests

Each mismatch needs one owner: server or contract. The recommendation is below.

- **M1, `total`.** This is the one open choice. If the API sends money as a decimal string on purpose, change the contract to `type: string` with a pattern such as `^\d+\.\d{2}$`. Otherwise fix the server to send a JSON number. Pick one; the tests assert whichever you choose.
- **M2, `note`.** Fix the server to omit `note` when it is empty. `note` is not required, so omitting it is already valid.
- **M3, 404 body.** Fix the server to add `code`, for example `order_not_found`.
- **M4, M5, M6, long notes.** Add `maxLength: 500` to `note` in both `NewOrder` and `Order`, and make the server return 400 with an `Error` body when the limit is exceeded. Never let a database error reach the client.
- **Contract gap, invalid path id.** `GET /orders/{id}` declares `minimum: 1` and `type: integer` but defines no response for `0`, negative or non-numeric ids. Add a 400 response that uses `Error`.
- **Contract gap, unexpected failures.** Add a `default` response that uses `Error`, so a 500 body still has a known shape.

## Test design

Every test asserts 3 things: the status code, the `Content-Type` header, and that the body validates against the schema the contract names for that status. Load the schemas from the OpenAPI file at test time, so a contract change breaks the right test. Any tool that validates JSON against an OpenAPI document works, for example Schemathesis, Dredd or openapi-core.

### GET /orders/{id}

| ID | Request | Expected status | Body check | Covers |
| --- | --- | --- | --- | --- |
| G1 | Existing order | 200 | Validates `Order`; `id` equals the path id; `total` has the agreed type; `note` is absent or a string, never null | M1, M2 |
| G2 | One order for each status: `placed`, `paid`, `shipped` | 200 | `status` is in the enum | Enum drift |
| G3 | Unknown id, for example 999999 | 404 | Validates `Error`; `code` and `message` are non-empty strings | M3 |
| G4 | Id `0` | 400 | Validates `Error` | Contract gap |
| G5 | Id `-1`, `abc`, `1.5` | 400 | Validates `Error` | Contract gap |
| G6 | Id `9223372036854775808` | 400 or 404, never 5xx | Validates `Error` | Overflow |

### POST /orders

| ID | Request body | Expected status | Body check | Covers |
| --- | --- | --- | --- | --- |
| P1 | `{"items": ["sku-1"]}` | 201 | Validates `Order`; `status` is `placed`; `note` absent | Happy path |
| P2 | Valid items, `note` of exactly 500 characters | 201 | `note` returned unchanged | Boundary |
| P3 | Valid items, `note` of 501 characters | 400 | Validates `Error` | M4, M5, M6 |
| P4 | Valid items, `note` of 5,000 characters | 400 | Validates `Error`; body text contains no database terms | Regression of recording 3 |
| P5 | Valid items, `note` of 500 four-byte characters, such as emoji | 201 | `note` returned unchanged | Character versus byte limit |
| P6 | `items` missing | 400 | Validates `Error` | Required field |
| P7 | `items` is `[]` | 400 | Validates `Error` | `minItems` |
| P8 | `items` is `["sku-1", 42]` | 400 | Validates `Error` | Item type |
| P9 | `items` is a string | 400 | Validates `Error` | Field type |
| P10 | `note` is a number, an object or `null` | 400 | Validates `Error` | Field type |
| P11 | Empty body, or text that is not JSON | 400 | Validates `Error` | Parse errors |
| P12 | Valid JSON sent as `text/plain` | 400 or 415 | Validates `Error` | Content type |
| P13 | Valid body plus an unknown field | 201 | Unknown field ignored | `additionalProperties` not restricted |
| P14 | P1, then `GET` the returned id | 200 | Same `status` and `note` as the `POST` response | Round trip |

### Cross-cutting tests

- **E1, error shape.** For every non-2xx response in the suite, the body validates `Error`. This single rule would have caught recordings 2 and 3.
- **E2, no 5xx from input.** Run a property-based fuzz of both endpoints from the OpenAPI file for at least 1,000 cases each. Any 5xx fails the run.
- **E3, no internal detail in errors.** No error `message` contains the words `varying`, `column`, `constraint`, `SQL` or a stack trace line.
- **E4, contract and server version.** The test run records the deployed version and fails if it differs from `info.version` in the contract.

## When to run

Run G1 to G6 and P1 to P14 in CI on every change to the API. Run E2 nightly against staging, since it takes longer. Tag P3, P4, G1 and G3 as regressions of the 2026-10-15 recordings, so a future reader knows why they exist.

## Updates

- 2026-10-25: first version, based on the recordings of 2026-10-15.
