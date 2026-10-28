---
title: Orders API contract check and test plan
slug: orders-api-contract-check-and-test-plan
article_type: reference
product_area: Orders API
audience: API developer, QA engineer
plan_availability: None: internal engineering document
reading_time: 6 min
related_articles: None: no related articles yet
last_updated: 2026-10-25
---

# Orders API contract check and test plan

All 3 recorded responses break the contract, and the tests below are designed to catch each break and the gaps around it.

**Assumptions.** The OpenAPI document is the source of truth. The staging build and the contract both say version 2.1.0, so each difference is a defect, not version skew. The database limit of 500 characters is the intended limit for `note`. Inputs the contract does not describe should get a 400 with an `Error` body. No authentication is defined, so the tests send none.

## Mismatches in the recorded responses

| # | Recorded | Contract says | Mismatch | Severity |
|---|---|---|---|---|
| 1a | `"total": "42.50"` | `total` is `number` | String instead of number. Clients that parse `total` as a number fail or do arithmetic on text. | High |
| 1b | `"note": null` | `note` is `string`, not nullable | OpenAPI 3.0.3 needs `nullable: true` to allow null. An optional field with no value should be omitted. | Medium |
| 2 | `{"message": "Order not found"}` | `Error` requires `code` and `message` | Required `code` is missing. Clients that branch on `code` cannot. | High |
| 3a | Status `500` | Only `201` and `400` are defined | Undocumented status. The contract sets no `maxLength` on `note`, so a 5,000 character note is valid input. Either the server accepts it or the contract gains the limit and the server returns 400. | Critical |
| 3b | `{"error": "..."}` | `Error` requires `code` and `message` | Body does not match the `Error` schema. Neither required field is present. | High |
| 3c | `value too long for type character varying(500)` | Nothing | The body leaks a raw database error, the column type and the column width to any caller. | High |

Response 1 passes on `id` and `status`. Response 2 has the right status code. Response 3 fails on status, body shape and content.

**Suggested fixes, in order.**

1. Validate `note` length before the insert and return 400 with an `Error` body. Add `maxLength: 500` to `note` in both `NewOrder` and `Order`. Add a catch-all handler so no 500 ever carries database text. Assumed code value: `note_too_long`.
2. Return `total` as a JSON number. If the team wants decimal precision, change the contract to a string with a pattern instead. Decide in the contract first, then change the server.
3. Add `code` to the 404 body. Assumed value: `order_not_found`.
4. Omit `note` when the order has none, or add `nullable: true` to `Order.note`.

## Gaps in the contract

These are not mismatches. They are places where behaviour is undefined, so the tests need an agreed expectation.

- `GET /orders/{id}` has no response for an id that fails `integer, minimum: 1`, such as `0`, `-1`, `abc` or `1.5`. Assumed: 400 with `Error`.
- `POST /orders` has no response for malformed JSON or a wrong `Content-Type`. Assumed: 400 with `Error`.
- `NewOrder.items` has no `maxItems`, and item strings have no `minLength` or `maxLength`. An empty string or a 10,000 item array is valid today.
- `Error.code` has no enum, so clients cannot know which values to handle.
- No `500` is documented, so there is no agreed body for unexpected failures. Assumed: `Error` body with a stable code and no internal detail.
- Nothing says which `status` a new order gets. Assumed: `placed`.

## Tests the API needs

Run every test through a response validator that checks 2 things on every call. The status code must be listed in the contract for that operation, and the body must validate against the referenced schema. Each test below adds its own checks.

**GET /orders/{id}**

| ID | Request | Expect | Catches |
|---|---|---|---|
| G1 | Existing order with a note | 200, `Order`, `total` is a JSON number, `note` is a string | 1a |
| G2 | Existing order without a note | 200, `note` absent, or null only if the contract gains `nullable` | 1b |
| G3 | One order per `status` value: placed, paid, shipped | 200, `status` in the enum | Enum drift |
| G4 | Unknown id, for example 999999 | 404, `Error` with `code` and `message` | 2 |
| G5 | `0` and `-1` | 400, `Error` | Gap, `minimum: 1` |
| G6 | `abc`, `1.5`, `1e3`, empty id | 400 or 404 as agreed, with `Error`, never 500 | Gap, type |
| G7 | `9223372036854775808`, past int64 | 400 or 404, never 500 | Overflow |

**POST /orders**

| ID | Request | Expect | Catches |
|---|---|---|---|
| P1 | `{"items": ["sku-1"]}` | 201, `Order`, `status` is `placed`, `total` a number | Happy path |
| P2 | Items plus a 1 character note | 201, `note` echoed unchanged | Note round trip |
| P3 | Note of exactly 500 characters | 201 | Upper boundary |
| P4 | Note of 501 characters | 400, `Error`, no database text | 3a, 3b, boundary |
| P5 | Note of 5,000 characters | 400, `Error` | 3a, regression |
| P6 | Note of 500 multi-byte characters, such as emoji or CJK | 201, note stored whole | Bytes versus characters |
| P7 | `{"items": []}` | 400 | `minItems: 1` |
| P8 | `{}` and `{"note": "x"}` | 400 | Required `items` |
| P9 | `{"items": [1, 2]}`, `{"items": "sku-1"}`, `{"items": null}` | 400 | Item type |
| P10 | `{"items": ["sku-1"], "note": null}` | 400, or 201 if the contract gains `nullable` | 1b, input side |
| P11 | `{"items": ["sku-1"], "note": 42}` | 400 | Note type |
| P12 | Empty body, `{` malformed, `Content-Type: text/plain` | 400, `Error`, never 500 | Gap |
| P13 | `{"items": ["sku-1"], "extra": true}` | Agreed behaviour, assumed 201 with the field ignored | `additionalProperties` |
| P14 | `{"items": [""]}` and 10,000 items | Agreed behaviour, never 500 | Gap, size |

**Cross-cutting**

| ID | Check | Catches |
|---|---|---|
| X1 | After P1, `GET /orders/{new id}` returns the same `id`, `status`, `total` and `note` | Persistence |
| X2 | After P5, no order was created: the order count is unchanged and the next id returns 404 | Partial writes on failure |
| X3 | Every non-2xx body matches `Error` and `code` is a documented value | 2, 3b |
| X4 | No response body matches `/character varying\|relation \|syntax error\|psycopg\|SQLSTATE\|stack trace/i` | 3c |
| X5 | Every response has `Content-Type: application/json` | Content negotiation |
| X6 | `PUT`, `DELETE` and `PATCH` on both paths return 405 with `Error`, never 500 | Undocumented methods |

**How to run them.** Make P4, P5, X2 and X4 blocking in CI, because they cover the 500 and the leak. Store the 3 recorded responses as fixtures and assert that each fails validation today, so the suite proves it would have caught them. Re-record the fixtures after the fixes land and keep both sets.
