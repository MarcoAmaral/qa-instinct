---
feature: Cart — no duplicate product
feature_code: CART
tc_count: 9
tracker_issues: [ISSUE-ID]
risk_level: MEDIUM
runbook: N/A — no runbook requested for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-25
---

# Test Cases — Cart: no duplicate product

| Field            | Value                                                        |
| ---------------- | ------------------------------------------------------------ |
| **Project**      | ServeRest API (https://serverest.dev)                        |
| **Author**       | Claude — Senior QA Analyst                                   |
| **Date Created** | 2026-10-25                                                   |
| **Last Updated** | 2026-10-25                                                   |
| **Methodology**  | ISTQB CTFL v4.0 — EP, BVA, State Transition, Error Guessing  |

## Introduction and context discovery

- **Story:** `story.md`. Its acceptance criteria are already numbered AC-1 to AC-3, so the numbers are kept.
- **Context found:** the repository holds only the story and the QA tooling. There is no test suite, OpenAPI schema, fixture or application code to ground the cases in (Tier 1 and 2 sources are absent). Nothing here was confirmed against the running API.
- **Assumptions (not verified), used in several cases:**
  - A-1: `POST /carrinhos` needs a logged-in user; the token comes from `POST /login` and is sent in the `Authorization` header.
  - A-2: Products are created through `POST /produtos`, which may need an administrator token, with enough stock for the quantities used.
  - A-3: A cart body has the shape `{"produtos": [{"idProduto": "<id>", "quantidade": <n>}]}`.
  - A-4: Error responses carry a `message` field. The exact text is not stated in the story, so no case quotes it.
  - A-5: A cart can be removed with `DELETE /carrinhos/cancelar-compra` or `DELETE /carrinhos/concluir-compra`.
- **Isolation:** every case creates its own user (and its own products where needed) in its setup, so no case depends on another.
- **Gate:** `@gate` marks TC-CART-001 to TC-CART-003, the three acceptance criteria. The gate is defined and sized in the `qa-plan` skill; this marking is a proposal to be confirmed there.
- **Tracker:** none was named, so `[ISSUE-ID]` is a placeholder.

---

## TC-CART-001: Create a cart with distinct products

| Field                  | Value                                                                                                                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @cart @candidate @gate`                                                                                                                                               |
| **Issue**              | [ISSUE-ID]                                                                                                                                                                             |
| **Automation Score**   | HIGH (62.5/67.5)                                                                                                                                                                       |
| **ISTQB Technique**    | EP — valid partition (every `idProduto` distinct)                                                                                                                                      |
| **Manual Env**         | Local, Staging                                                                                                                                                                         |
| **Precondition**       | A registered, logged-in user with no cart. Two existing products, A and B, each with stock of at least 1 (assumptions A-1, A-2).                                                       |
| **Steps**              | 1. Send `POST /carrinhos` with the user's token and body `produtos: [{idProduto: A, quantidade: 1}, {idProduto: B, quantidade: 1}]` <br> 2. Send `GET /carrinhos` and look for the cart |
| **Expected**           | Step 1 returns status 201. Step 2 returns the new cart, which lists product A once and product B once.                                                                                  |
| **data-testid needed** | N/A — API test, no UI element is asserted                                                                                                                                              |
| **Source**             | AC-2                                                                                                                                                                                   |
| **Note**               | Assumptions A-1 to A-3 apply. Step 2 goes beyond the story: AC-2 only names the status code, and the cart content check guards against a 201 that stores something else.              |

---

## TC-CART-002: Reject a cart that lists the same product twice

| Field                  | Value                                                                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @api @cart @candidate @gate`                                                                                                                                 |
| **Issue**              | [ISSUE-ID]                                                                                                                                                               |
| **Automation Score**   | HIGH (62.5/67.5)                                                                                                                                                         |
| **ISTQB Technique**    | EP — invalid partition (the same `idProduto` appears twice)                                                                                                              |
| **Manual Env**         | Local, Staging                                                                                                                                                           |
| **Precondition**       | A registered, logged-in user with no cart. One existing product A with stock of at least 2 (assumptions A-1, A-2).                                                        |
| **Steps**              | 1. Send `POST /carrinhos` with the user's token and body `produtos: [{idProduto: A, quantidade: 1}, {idProduto: A, quantidade: 1}]`                                        |
| **Expected**           | Status 400. No cart is created for the user.                                                                                                                             |
| **data-testid needed** | N/A — API test, no UI element is asserted                                                                                                                                |
| **Source**             | AC-1                                                                                                                                                                     |
| **Note**               | "No cart is created" is checked with `GET /carrinhos` filtered on the user; the story does not state it, but a 400 that still stores a cart would defeat the rule. A-4 applies: the message text is not asserted. |

---

## TC-CART-003: Reject a second cart for a user who already has one

| Field                  | Value                                                                                                                                                                              |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @cart @candidate @gate`                                                                                                                                           |
| **Issue**              | [ISSUE-ID]                                                                                                                                                                         |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                                                                     |
| **ISTQB Technique**    | State Transition — invalid transition: HasCart state, event "create cart"                                                                                                          |
| **Manual Env**         | Local, Staging                                                                                                                                                                     |
| **Precondition**       | A registered, logged-in user who already has a cart created by a 201 response. Product A in that cart; a second existing product B with stock (assumptions A-1, A-2).              |
| **Steps**              | 1. Send `POST /carrinhos` with the user's token and body `produtos: [{idProduto: B, quantidade: 1}]` <br> 2. Send `GET /carrinhos` for the user                                      |
| **Expected**           | Step 1 returns status 400. Step 2 shows the original cart unchanged: product A only, no product B.                                                                                 |
| **data-testid needed** | N/A — API test, no UI element is asserted                                                                                                                                          |
| **Source**             | AC-3                                                                                                                                                                               |
| **Note**               | The second request uses a different, valid product on purpose, so the 400 can only come from the one-cart rule and not from the duplicate-product rule of AC-1. A-4 applies.      |

---

## TC-CART-004: Reject a duplicate product that is not adjacent in the list

| Field                  | Value                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @cart @candidate`                                                                                                                    |
| **Issue**              | [ISSUE-ID]                                                                                                                                                 |
| **Automation Score**   | HIGH (54.5/67.5)                                                                                                                                           |
| **ISTQB Technique**    | Error Guessing — duplicate detection that compares only neighbouring items; EP — invalid partition (duplicate among three items)                           |
| **Manual Env**         | Local, Staging                                                                                                                                             |
| **Precondition**       | A registered, logged-in user with no cart. Three existing products A, B, C with stock of at least 2 each (assumptions A-1, A-2).                            |
| **Steps**              | 1. Send `POST /carrinhos` with body `produtos: [{idProduto: A, quantidade: 1}, {idProduto: B, quantidade: 1}, {idProduto: A, quantidade: 1}]`              |
| **Expected**           | Status 400. No cart is created for the user.                                                                                                               |
| **data-testid needed** | N/A — API test, no UI element is asserted                                                                                                                  |
| **Source**             | Added by QA (AC-1 gives a two-item example; a list of three with the repeat in first and last place is a likely gap)                                       |
| **Note**               | A-4 applies. Not covered by the story's examples.                                                                                                          |

---

## TC-CART-005: Reject a duplicate product when the quantities differ

| Field                  | Value                                                                                                                                                            |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @api @cart @candidate`                                                                                                                          |
| **Issue**              | [ISSUE-ID]                                                                                                                                                       |
| **Automation Score**   | MEDIUM (50.5/67.5)                                                                                                                                               |
| **ISTQB Technique**    | Error Guessing — duplicate defined by `idProduto` alone, not by the whole line item                                                                              |
| **Manual Env**         | Local, Staging                                                                                                                                                   |
| **Precondition**       | A registered, logged-in user with no cart. One existing product A with stock of at least 3 (assumptions A-1, A-2).                                               |
| **Steps**              | 1. Send `POST /carrinhos` with body `produtos: [{idProduto: A, quantidade: 1}, {idProduto: A, quantidade: 2}]`                                                   |
| **Expected**           | Status 400. No cart is created for the user.                                                                                                                     |
| **data-testid needed** | N/A — API test, no UI element is asserted                                                                                                                        |
| **Source**             | Added by QA (the story says "same product", and does not say whether two lines with different quantities count as a duplicate)                                    |
| **Note**               | The expected 400 is QA's reading of "can't add the same product twice". If the product owner intends such lines to be merged, this case needs a ruling before it runs. A-4 applies. |

---

## TC-CART-006: A rejected duplicate request does not block a valid cart

| Field                  | Value                                                                                                                                                                     |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @cart @candidate`                                                                                                                                   |
| **Issue**              | [ISSUE-ID]                                                                                                                                                                |
| **Automation Score**   | HIGH (53/67.5)                                                                                                                                                            |
| **ISTQB Technique**    | State Transition — NoCart state stays NoCart after the rejected event, then the valid transition to HasCart                                                              |
| **Manual Env**         | Local, Staging                                                                                                                                                            |
| **Precondition**       | A registered, logged-in user with no cart. Two existing products A and B with stock of at least 2 (assumptions A-1, A-2).                                                  |
| **Steps**              | 1. Send `POST /carrinhos` with body `produtos: [{idProduto: A, quantidade: 1}, {idProduto: A, quantidade: 1}]` <br> 2. Send `POST /carrinhos` with body `produtos: [{idProduto: A, quantidade: 1}, {idProduto: B, quantidade: 1}]` |
| **Expected**           | Step 1 returns status 400. Step 2 returns status 201: the failed request left no cart behind, so the one-cart rule of AC-3 does not fire.                                 |
| **data-testid needed** | N/A — API test, no UI element is asserted                                                                                                                                 |
| **Source**             | Added by QA (the story is silent on what state a rejected request leaves; the business purpose is that the customer can still shop)                                       |
| **Note**               | Guards the interaction of AC-1 and AC-3. A-4 applies.                                                                                                                     |

---

## TC-CART-007: The one-cart rule applies per user, not across users

| Field                  | Value                                                                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @api @cart @candidate`                                                                                                                                  |
| **Issue**              | [ISSUE-ID]                                                                                                                                                               |
| **Automation Score**   | MEDIUM (49.5/67.5)                                                                                                                                                       |
| **ISTQB Technique**    | EP — valid partition (user without a cart, while another user holds a cart with the same product)                                                                        |
| **Manual Env**         | Local, Staging                                                                                                                                                           |
| **Precondition**       | Two registered, logged-in users, U1 and U2. U1 already has a cart containing product A. U2 has no cart (assumptions A-1, A-2).                                             |
| **Steps**              | 1. As U2, send `POST /carrinhos` with body `produtos: [{idProduto: A, quantidade: 1}]` <br> 2. As U1, send `GET /carrinhos` for U1's cart                                 |
| **Expected**           | Step 1 returns status 201: U2 may hold product A while U1's cart contains it. Step 2 shows U1's cart unchanged.                                                          |
| **data-testid needed** | N/A — API test, no UI element is asserted                                                                                                                                |
| **Source**             | Added by QA (AC-1 and AC-3 are phrased per user; the story does not say the rule is not global)                                                                          |
| **Note**               | Stock handling is not in the story. Product A needs stock for both carts; if the API reserves stock in the cart, give it a stock of at least 2.                           |

---

## TC-CART-008: Reject cart creation without authentication

| Field                  | Value                                                                                                                                                                        |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @cart @candidate`                                                                                                                                      |
| **Issue**              | [ISSUE-ID]                                                                                                                                                                   |
| **Automation Score**   | HIGH (59.5/67.5)                                                                                                                                                             |
| **ISTQB Technique**    | EP — invalid partition (no token)                                                                                                                                            |
| **Manual Env**         | Local, Staging                                                                                                                                                               |
| **Precondition**       | One existing product A. No token is sent (assumption A-1).                                                                                                                   |
| **Steps**              | 1. Send `POST /carrinhos` with no `Authorization` header and body `produtos: [{idProduto: A, quantidade: 1}]`                                                                |
| **Expected**           | The request is rejected as unauthenticated (status 401) and no cart is created.                                                                                              |
| **data-testid needed** | N/A — API test, no UI element is asserted                                                                                                                                    |
| **Source**             | Added by QA (the story says "as a customer" but gives no criterion for requests without a login)                                                                             |
| **Note**               | The status 401 is an assumption: the story does not state it. If the API answers with another 4xx code, record it as a documentation gap, not a failure, until the owner decides. |

---

## TC-CART-009: A user can create a new cart after finishing the previous one

| Field                  | Value                                                                                                                                                                              |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @api @cart @candidate`                                                                                                                                            |
| **Issue**              | [ISSUE-ID]                                                                                                                                                                         |
| **Automation Score**   | MEDIUM (39.5/67.5)                                                                                                                                                                 |
| **ISTQB Technique**    | State Transition — HasCart to NoCart (cart removed), then NoCart to HasCart                                                                                                        |
| **Manual Env**         | Local, Staging                                                                                                                                                                     |
| **Precondition**       | A registered, logged-in user who has a cart created by a 201 response. One existing product A (assumptions A-1, A-2, A-5).                                                         |
| **Steps**              | 1. Remove the cart with `DELETE /carrinhos/cancelar-compra` <br> 2. Send `POST /carrinhos` with body `produtos: [{idProduto: A, quantidade: 1}]`                                    |
| **Expected**           | Step 1 succeeds. Step 2 returns status 201: AC-3 limits the user to one cart at a time, so a removed cart must not block a new one.                                                 |
| **data-testid needed** | N/A — API test, no UI element is asserted                                                                                                                                          |
| **Source**             | Added by QA (AC-3 says "a user who has a cart" but does not say when a cart stops existing)                                                                                        |
| **Note**               | Rests on A-5, which is unverified: the delete endpoint, its success status and any stock effect are not in the story. Confirm against the API documentation before running.        |
