---
feature: Shipping fee at checkout
feature_code: SHIP
tc_count: 14
tracker_issues: [SHIP-9]
risk_level: HIGH
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-24
---

# Test Cases — Shipping fee at checkout

| Field            | Value                                                        |
| ---------------- | ------------------------------------------------------------ |
| **Project**      | Storefront checkout (name not given in the ticket)           |
| **Author**       | Marco — Senior QA Analyst                                    |
| **Date Created** | 2026-10-24                                                   |
| **Last Updated** | 2026-10-24                                                   |
| **Methodology**  | ISTQB CTFL v4.0 — Decision Table, BVA, State Transition, EP, Error Guessing |

## Context and assumptions

The working directory holds no source code, so no precondition or expected result below is grounded in an implementation. Every case rests on the assumptions listed here; each one must be confirmed against the real checkout before execution.

- **A1 — Subtotal definition.** "Order subtotal" is the merchandise total before tax, shipping and order-level coupons. If coupons apply before the threshold check, TC-SHIP-002 and TC-SHIP-003 need their data revisited.
- **A2 — Threshold is inclusive.** "$50.00 or more" means a subtotal of exactly $50.00 earns free standard shipping.
- **A3 — Member.** A signed-in shopper with an active membership. Guests and signed-in shoppers without a membership are non-members.
- **A4 — Two methods only.** Checkout offers Standard and Express, Standard selected by default. No other method or carrier rule exists.
- **A5 — Display.** The fee row shows the amount in USD with two decimals, and shows the word `Free` when the fee is $0.00.
- **A6 — Recalculation.** The fee is recalculated whenever the cart contents, the selected method or the shopper's session changes, without a page reload.
- **A7 — Single region.** One shipping region; no tax, currency or destination variations are in scope.
- **A8 — Tracker.** `SHIP-9` has no base URL, so the ID is used as plain text.

Decision table used for TC-SHIP-001 to TC-SHIP-009 (conditions: member, subtotal ≥ $50.00, method):

| Column | Member | Subtotal ≥ $50.00 | Method   | Fee    |
| ------ | ------ | ----------------- | -------- | ------ |
| C1     | No     | No                | Standard | $5.99  |
| C2     | No     | Yes               | Standard | Free   |
| C3     | Yes    | No                | Standard | Free   |
| C4     | Yes    | Yes               | Standard | Free   |
| C5     | No     | No                | Express  | $12.99 |
| C6     | No     | Yes               | Express  | $12.99 |
| C7     | Yes    | No                | Express  | $7.99  |
| C8     | Yes    | Yes               | Express  | $7.99  |

Release gate: the five cases tagged `@gate` (TC-SHIP-001, 002, 004, 006, 008) cover one representative of each distinct fee outcome.

---

## TC-SHIP-001: Non-member pays $5.99 standard shipping just below the threshold

| Field                  | Value                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                               |
| **Issue**              | SHIP-9                                                                                                                                                 |
| **Automation Score**   | HIGH (63/67.5)                                                                                                                                         |
| **ISTQB Technique**    | Decision Table — C1; BVA — three-value, $49.99 (threshold − 0.01)                                                                                      |
| **Manual Env**         | Local, Staging                                                                                                                                         |
| **Precondition**       | Signed in as a non-member account (A3). Cart is empty. Catalogue has items that can total exactly $49.99.                                             |
| **Steps**              | 1. Add items so the cart subtotal is `$49.99` <br> 2. Proceed to checkout <br> 3. Confirm **Standard** is the selected shipping method                |
| **Expected**           | Subtotal row shows `$49.99`. Shipping fee row shows `$5.99`. Order total shows `$55.98`.                                                              |
| **data-testid needed** | `order-subtotal`, `shipping-option-standard`, `shipping-fee`, `order-total`                                                                            |
| **Source**             | AC-1                                                                                                                                                   |
| **Note**               | Uses $49.99 rather than an arbitrary low value so this case doubles as the lower boundary of the threshold.                                            |

---

## TC-SHIP-002: Non-member gets free standard shipping at exactly $50.00

| Field                  | Value                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                               |
| **Issue**              | SHIP-9                                                                                                                                                 |
| **Automation Score**   | HIGH (63/67.5)                                                                                                                                         |
| **ISTQB Technique**    | Decision Table — C2; BVA — three-value, $50.00 (threshold)                                                                                            |
| **Manual Env**         | Local, Staging                                                                                                                                         |
| **Precondition**       | Signed in as a non-member account. Cart is empty.                                                                                                      |
| **Steps**              | 1. Add items so the cart subtotal is `$50.00` <br> 2. Proceed to checkout <br> 3. Confirm **Standard** is selected                                     |
| **Expected**           | Shipping fee row shows `Free` (A5). Order total shows `$50.00`.                                                                                        |
| **data-testid needed** | `order-subtotal`, `shipping-option-standard`, `shipping-fee`, `order-total`                                                                            |
| **Source**             | AC-1                                                                                                                                                   |
| **Note**               | Relies on assumption A2 (inclusive threshold). A `$5.99` result here is a defect against AC-1 wording "or more".                                       |

---

## TC-SHIP-003: Non-member gets free standard shipping just above the threshold

| Field                  | Value                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                |
| **Issue**              | SHIP-9                                                                                                                                                 |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                                         |
| **ISTQB Technique**    | BVA — three-value, $50.01 (threshold + 0.01)                                                                                                           |
| **Manual Env**         | Local, Staging                                                                                                                                         |
| **Precondition**       | Signed in as a non-member account. Cart is empty.                                                                                                      |
| **Steps**              | 1. Add items so the cart subtotal is `$50.01` <br> 2. Proceed to checkout <br> 3. Confirm **Standard** is selected                                     |
| **Expected**           | Shipping fee row shows `Free`. Order total shows `$50.01`.                                                                                             |
| **data-testid needed** | `order-subtotal`, `shipping-fee`, `order-total`                                                                                                        |
| **Source**             | AC-1                                                                                                                                                   |
| **Note**               | Catches a `>` versus `>=` mix-up combined with floating-point rounding of cents.                                                                       |

---

## TC-SHIP-004: Member gets free standard shipping below the threshold

| Field                  | Value                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                               |
| **Issue**              | SHIP-9                                                                                                                                                 |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                                         |
| **ISTQB Technique**    | Decision Table — C3                                                                                                                                    |
| **Manual Env**         | Local, Staging                                                                                                                                         |
| **Precondition**       | Signed in as an account with an active membership (A3). Cart is empty.                                                                                 |
| **Steps**              | 1. Add items so the cart subtotal is `$49.99` <br> 2. Proceed to checkout <br> 3. Confirm **Standard** is selected                                     |
| **Expected**           | Shipping fee row shows `Free`. Order total shows `$49.99`.                                                                                             |
| **data-testid needed** | `membership-badge`, `shipping-option-standard`, `shipping-fee`, `order-total`                                                                          |
| **Source**             | AC-2                                                                                                                                                   |
| **Note**               | Same subtotal as TC-SHIP-001 so the only variable is membership.                                                                                       |

---

## TC-SHIP-005: Member gets free standard shipping at or above the threshold

| Field                  | Value                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                |
| **Issue**              | SHIP-9                                                                                                                                                 |
| **Automation Score**   | HIGH (59/67.5)                                                                                                                                         |
| **ISTQB Technique**    | Decision Table — C4                                                                                                                                    |
| **Manual Env**         | Local, Staging                                                                                                                                         |
| **Precondition**       | Signed in as an account with an active membership. Cart is empty.                                                                                      |
| **Steps**              | 1. Add items so the cart subtotal is `$50.00` <br> 2. Proceed to checkout <br> 3. Confirm **Standard** is selected                                     |
| **Expected**           | Shipping fee row shows `Free`. Order total shows `$50.00`.                                                                                             |
| **data-testid needed** | `shipping-option-standard`, `shipping-fee`, `order-total`                                                                                              |
| **Source**             | AC-1, AC-2                                                                                                                                             |
| **Note**               | Both rules grant free shipping here; the case confirms they do not conflict (for example, no negative fee or double discount).                         |

---

## TC-SHIP-006: Non-member pays $12.99 express shipping below the threshold

| Field                  | Value                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                               |
| **Issue**              | SHIP-9                                                                                                                                                 |
| **Automation Score**   | HIGH (63/67.5)                                                                                                                                         |
| **ISTQB Technique**    | Decision Table — C5                                                                                                                                    |
| **Manual Env**         | Local, Staging                                                                                                                                         |
| **Precondition**       | Signed in as a non-member account. Cart is empty.                                                                                                      |
| **Steps**              | 1. Add items so the cart subtotal is `$49.99` <br> 2. Proceed to checkout <br> 3. Select **Express**                                                  |
| **Expected**           | Express option becomes selected. Shipping fee row shows `$12.99`. Order total shows `$62.98`.                                                          |
| **data-testid needed** | `shipping-option-express`, `shipping-fee`, `order-total`                                                                                               |
| **Source**             | AC-3                                                                                                                                                   |
| **Note**               | N/A — no caveats                                                                                                                                       |

---

## TC-SHIP-007: Non-member still pays $12.99 express at or above the threshold

| Field                  | Value                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                |
| **Issue**              | SHIP-9                                                                                                                                                 |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                                         |
| **ISTQB Technique**    | Decision Table — C6                                                                                                                                    |
| **Manual Env**         | Local, Staging                                                                                                                                         |
| **Precondition**       | Signed in as a non-member account. Cart is empty.                                                                                                      |
| **Steps**              | 1. Add items so the cart subtotal is `$50.00` <br> 2. Proceed to checkout <br> 3. Select **Express**                                                  |
| **Expected**           | Shipping fee row shows `$12.99`. Order total shows `$62.99`.                                                                                           |
| **data-testid needed** | `shipping-option-express`, `shipping-fee`, `order-total`                                                                                               |
| **Source**             | AC-1, AC-3                                                                                                                                             |
| **Note**               | Guards against the free-shipping threshold leaking from Standard into Express.                                                                         |

---

## TC-SHIP-008: Member pays $7.99 express shipping below the threshold

| Field                  | Value                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                               |
| **Issue**              | SHIP-9                                                                                                                                                 |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                                         |
| **ISTQB Technique**    | Decision Table — C7                                                                                                                                    |
| **Manual Env**         | Local, Staging                                                                                                                                         |
| **Precondition**       | Signed in as an account with an active membership. Cart is empty.                                                                                      |
| **Steps**              | 1. Add items so the cart subtotal is `$49.99` <br> 2. Proceed to checkout <br> 3. Select **Express**                                                  |
| **Expected**           | Shipping fee row shows `$7.99`. Order total shows `$57.98`.                                                                                            |
| **data-testid needed** | `membership-badge`, `shipping-option-express`, `shipping-fee`, `order-total`                                                                           |
| **Source**             | AC-3                                                                                                                                                   |
| **Note**               | N/A — no caveats                                                                                                                                       |

---

## TC-SHIP-009: Member still pays $7.99 express at or above the threshold

| Field                  | Value                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                |
| **Issue**              | SHIP-9                                                                                                                                                 |
| **Automation Score**   | HIGH (59/67.5)                                                                                                                                         |
| **ISTQB Technique**    | Decision Table — C8                                                                                                                                    |
| **Manual Env**         | Local, Staging                                                                                                                                         |
| **Precondition**       | Signed in as an account with an active membership. Cart is empty.                                                                                      |
| **Steps**              | 1. Add items so the cart subtotal is `$50.00` <br> 2. Proceed to checkout <br> 3. Select **Express**                                                  |
| **Expected**           | Shipping fee row shows `$7.99`, not `Free`. Order total shows `$57.99`.                                                                                |
| **data-testid needed** | `shipping-option-express`, `shipping-fee`, `order-total`                                                                                               |
| **Source**             | AC-2, AC-3                                                                                                                                             |
| **Note**               | Confirms the member free-standard rule (AC-2) does not override the member express price (AC-3).                                                       |

---

## TC-SHIP-010: Switching shipping method updates the fee in place

| Field                  | Value                                                                                                                                                                                    |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                                                  |
| **Issue**              | SHIP-9                                                                                                                                                                                   |
| **Automation Score**   | HIGH (56/67.5)                                                                                                                                                                           |
| **ISTQB Technique**    | State Transition — Standard → Express → Standard (0-switch coverage of both valid transitions)                                                                                            |
| **Manual Env**         | Local, Staging                                                                                                                                                                           |
| **Precondition**       | Signed in as a non-member account. Cart subtotal is `$30.00`. Checkout page open with **Standard** selected and fee row showing `$5.99`.                                                 |
| **Steps**              | 1. Select **Express** <br> 2. Observe the fee and total rows <br> 3. Select **Standard** <br> 4. Observe the fee and total rows                                                            |
| **Expected**           | After step 1: fee `$12.99`, total `$42.99`, no page reload. After step 3: fee `$5.99`, total `$35.99`. No stale value is shown at any point.                                            |
| **data-testid needed** | `shipping-option-standard`, `shipping-option-express`, `shipping-fee`, `order-total`                                                                                                     |
| **Source**             | Added by QA (the ticket is silent on changing method after the fee is first shown)                                                                                                       |
| **Note**               | Relies on assumption A6. If the real checkout reloads on method change, keep the expected amounts and drop the "no page reload" clause with a dated correction.                            |

---

## TC-SHIP-011: Removing an item drops the subtotal below the threshold and reinstates the fee

| Field                  | Value                                                                                                                                                                                    |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                                                  |
| **Issue**              | SHIP-9                                                                                                                                                                                   |
| **Automation Score**   | MEDIUM (49/67.5)                                                                                                                                                                         |
| **ISTQB Technique**    | Error Guessing — stale fee after cart mutation crossing the threshold                                                                                                                    |
| **Manual Env**         | Local, Staging                                                                                                                                                                           |
| **Precondition**       | Signed in as a non-member account. Cart holds two items: one at `$45.00` and one at `$10.00` (subtotal `$55.00`). Checkout page open, **Standard** selected, fee row shows `Free`.         |
| **Steps**              | 1. Remove the `$10.00` item from the checkout (or return to cart, remove it, and return to checkout) <br> 2. Observe subtotal, fee and total rows                                           |
| **Expected**           | Subtotal shows `$45.00`. Fee row shows `$5.99`. Total shows `$50.99`. The `Free` label is gone.                                                                                           |
| **data-testid needed** | `cart-item-remove`, `order-subtotal`, `shipping-fee`, `order-total`                                                                                                                      |
| **Source**             | Added by QA (the ticket is silent on recalculation after the cart changes)                                                                                                                |
| **Note**               | Run the mirror direction too (add an item to cross upward) if time allows; it is lower risk because a fee dropping to Free never overcharges the shopper.                                  |

---

## TC-SHIP-012: Placed order persists the displayed shipping fee and total

| Field                  | Value                                                                                                                                                                                    |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p0 @e2e @ship @candidate`                                                                                                                                                      |
| **Issue**              | SHIP-9                                                                                                                                                                                   |
| **Automation Score**   | HIGH (54/67.5)                                                                                                                                                                           |
| **ISTQB Technique**    | EP — valid partition (non-member, below threshold, Standard) checked end to end                                                                                                           |
| **Manual Env**         | Staging                                                                                                                                                                                  |
| **Precondition**       | Signed in as a non-member account with a valid test payment method. Cart subtotal is `$20.00`. Checkout page open, **Standard** selected, fee row shows `$5.99`.                          |
| **Steps**              | 1. Place the order <br> 2. Open the order confirmation page <br> 3. Open the same order in the account's order history (or fetch it from the orders API)                                   |
| **Expected**           | Confirmation shows shipping `$5.99` and total `$25.99`. The stored order carries the same shipping fee and total. The charge submitted to the payment provider is `$25.99`.               |
| **data-testid needed** | `place-order-btn`, `confirmation-shipping-fee`, `confirmation-order-total`                                                                                                               |
| **Source**             | Added by QA (the story's goal is "know what I will pay", so the shown fee must be the charged fee; no AC states it)                                                                       |
| **Note**               | The story is about display, but a display-only check cannot prove the fee is applied. This case is the one that proves it.                                                               |

---

## TC-SHIP-013: Guest shopper is treated as a non-member

| Field                  | Value                                                                                                                                                                                    |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                                                  |
| **Issue**              | SHIP-9                                                                                                                                                                                   |
| **Automation Score**   | HIGH (58/67.5)                                                                                                                                                                           |
| **ISTQB Technique**    | EP — invalid partition for the member rule (no session)                                                                                                                                 |
| **Manual Env**         | Local, Staging                                                                                                                                                                           |
| **Precondition**       | Not signed in (cookies and storage cleared). Guest checkout is enabled. Cart is empty.                                                                                                   |
| **Steps**              | 1. Add items so the cart subtotal is `$49.99` <br> 2. Proceed to guest checkout <br> 3. Note the fee with **Standard** selected <br> 4. Select **Express** and note the fee                |
| **Expected**           | Step 3: fee `$5.99`. Step 4: fee `$12.99`. No member pricing is applied.                                                                                                                |
| **data-testid needed** | `shipping-option-standard`, `shipping-option-express`, `shipping-fee`                                                                                                                    |
| **Source**             | Added by QA (the ticket does not define who counts as a member; guests are assumed non-members per A3)                                                                                   |
| **Note**               | If guest checkout does not exist, mark this case `N/A — guest checkout unavailable` with a dated note rather than deleting it.                                                            |

---

## TC-SHIP-014: Shopper with an expired membership is charged non-member rates

| Field                  | Value                                                                                                                                                                                    |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @ship @candidate`                                                                                                                                                  |
| **Issue**              | SHIP-9                                                                                                                                                                                   |
| **Automation Score**   | MEDIUM (44/67.5)                                                                                                                                                                         |
| **ISTQB Technique**    | Error Guessing — membership flag read without checking expiry                                                                                                                             |
| **Manual Env**         | Staging                                                                                                                                                                                  |
| **Precondition**       | Signed in as an account whose membership end date is in the past. Cart is empty.                                                                                                         |
| **Steps**              | 1. Add items so the cart subtotal is `$49.99` <br> 2. Proceed to checkout <br> 3. Note the fee with **Standard** selected <br> 4. Select **Express** and note the fee                      |
| **Expected**           | Step 3: fee `$5.99`. Step 4: fee `$12.99`. No membership badge is shown at checkout.                                                                                                      |
| **data-testid needed** | `membership-badge`, `shipping-fee`                                                                                                                                                       |
| **Source**             | Added by QA (the ticket is silent on lapsed memberships)                                                                                                                                 |
| **Note**               | Needs a test fixture with a backdated membership; score is MEDIUM because of that data setup effort. If memberships never expire in this product, record `N/A` with a dated note.          |

---

## Rules not applied

The `context-discovery` and `testing-guidelines` rules were not loaded in this session and no `qa-rules` skill is installed, so they could not be read. Context discovery was attempted directly: the working directory contains no source files, which is why every expected result above is marked as resting on the assumptions A1 to A8.
