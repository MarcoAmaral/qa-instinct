---
feature: Shipping fee at checkout
feature_code: SHIP
tc_count: 14
tracker_issues: [SHIP-9]
risk_level: MEDIUM
runbook: N/A — no runbook requested
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-24
---

# Test Cases — Shipping fee at checkout

| Field            | Value                                              |
| ---------------- | -------------------------------------------------- |
| **Project**      | N/A — not stated in the ticket                     |
| **Author**       | Marco — Senior QA Analyst                          |
| **Date Created** | 2026-10-24                                         |
| **Last Updated** | 2026-10-24                                         |
| **Methodology**  | ISTQB CTFL v4.0 — Decision Table, BVA, EP, State Transition, Error Guessing |

## Context and assumptions

Context discovery found no code in the working directory, so no precondition or expected result below is grounded in an implementation. Every case rests on the ticket text plus these assumptions, each marked so a reviewer can overturn it:

- **A1 — Subtotal definition.** "Order subtotal" is the merchandise total after any coupon or promotion, before tax and before shipping. The ticket does not say; TC-SHIP-014 tests this reading and must be confirmed with the product owner.
- **A2 — Boundary precision.** Subtotals are compared in cents, so $49.99 is below the threshold and $50.00 is at it.
- **A3 — Member.** A "member" is a signed-in account with an active membership. Guests and signed-in accounts without membership are non-members.
- **A4 — Free display.** A free fee renders as the label `Free` and adds $0.00 to the order total. If the project renders `$0.00` instead, substitute that string in the Expected column.
- **A5 — Default method.** Standard shipping is preselected when checkout opens; express is a selectable option.
- **A6 — Tracker.** `SHIP-9` is a Linear or Jira key; the base URL is unknown, so the ID is left as plain text.

Decision table used for the rule cases (one case per column):

| Condition               | R1  | R2  | R3  | R4  | R5  |
| ----------------------- | --- | --- | --- | --- | --- |
| member                  | F   | F   | T   | F   | T   |
| method = express        | F   | F   | F   | T   | T   |
| subtotal ≥ $50.00       | T   | F   | –   | –   | –   |
| **Actions**             |     |     |     |     |     |
| Fee = Free              | X   |     | X   |     |     |
| Fee = $5.99             |     | X   |     |     |     |
| Fee = $12.99            |     |     |     | X   |     |
| Fee = $7.99             |     |     |     |     | X   |

Release gate: cases tagged `@gate` (TC-SHIP-001, 002, 005, 007, 009) cover every decision-table column plus both sides of the $50.00 boundary.

---

## TC-SHIP-001: Standard shipping is free at a subtotal of exactly $50.00 for a non-member

| Field                  | Value                                                                                                                                            |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                         |
| **Issue**              | SHIP-9                                                                                                                                           |
| **Automation Score**   | HIGH (60/67.5)                                                                                                                                   |
| **ISTQB Technique**    | BVA — three-value, $50.00 (min of the free partition); Decision Table — R1                                                                       |
| **Manual Env**         | Local, Staging                                                                                                                                   |
| **Precondition**       | Signed in as a non-member (A3). Cart contains items whose subtotal is exactly $50.00 with no coupon applied (A1, A2). Standard shipping preselected (A5). |
| **Steps**              | 1. Open the checkout page <br> 2. Read the subtotal line <br> 3. Read the shipping fee line for Standard <br> 4. Read the order total               |
| **Expected**           | Subtotal shows `$50.00`. Standard shipping fee shows `Free` (A4). Order total equals subtotal plus tax with no shipping amount added.               |
| **data-testid needed** | `checkout-subtotal`, `shipping-option-standard`, `shipping-fee`, `checkout-total`                                                                 |
| **Source**             | AC-1                                                                                                                                             |
| **Note**               | The most likely off-by-one: a `>` instead of `>=` would charge $5.99 here.                                                                       |

---

## TC-SHIP-002: Standard shipping costs $5.99 at a subtotal of $49.99 for a non-member

| Field                  | Value                                                                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                   |
| **Issue**              | SHIP-9                                                                                                                                     |
| **Automation Score**   | HIGH (60/67.5)                                                                                                                             |
| **ISTQB Technique**    | BVA — three-value, $49.99 (max of the paid partition); Decision Table — R2                                                                 |
| **Manual Env**         | Local, Staging                                                                                                                             |
| **Precondition**       | Signed in as a non-member (A3). Cart subtotal is exactly $49.99 with no coupon applied (A1, A2). Standard shipping preselected (A5).        |
| **Steps**              | 1. Open the checkout page <br> 2. Read the subtotal line <br> 3. Read the shipping fee line for Standard <br> 4. Read the order total         |
| **Expected**           | Subtotal shows `$49.99`. Standard shipping fee shows `$5.99`. Order total equals subtotal plus tax plus $5.99.                              |
| **data-testid needed** | `checkout-subtotal`, `shipping-option-standard`, `shipping-fee`, `checkout-total`                                                           |
| **Source**             | AC-1                                                                                                                                       |
| **Note**               | Catches rounding to whole dollars before comparing ($49.99 rounded up to $50 would wrongly be free).                                       |

---

## TC-SHIP-003: Standard shipping is free at a subtotal of $50.01 for a non-member

| Field                  | Value                                                                                                                               |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                             |
| **Issue**              | SHIP-9                                                                                                                              |
| **Automation Score**   | HIGH (56/67.5)                                                                                                                      |
| **ISTQB Technique**    | BVA — three-value, $50.01 (min+1 of the free partition)                                                                             |
| **Manual Env**         | Local, Staging                                                                                                                      |
| **Precondition**       | Signed in as a non-member (A3). Cart subtotal is exactly $50.01 with no coupon applied (A1, A2). Standard shipping preselected (A5). |
| **Steps**              | 1. Open the checkout page <br> 2. Read the shipping fee line for Standard <br> 3. Read the order total                               |
| **Expected**           | Standard shipping fee shows `Free` (A4). Order total has no shipping amount added.                                                  |
| **data-testid needed** | `checkout-subtotal`, `shipping-fee`, `checkout-total`                                                                               |
| **Source**             | AC-1                                                                                                                                |
| **Note**               | Guards against an equality-only check (`== 50.00`) that frees exactly $50.00 but charges anything above it.                         |

---

## TC-SHIP-004: Standard shipping costs $5.99 for a typical low subtotal for a non-member

| Field                  | Value                                                                                                                      |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                    |
| **Issue**              | SHIP-9                                                                                                                     |
| **Automation Score**   | HIGH (56/67.5)                                                                                                             |
| **ISTQB Technique**    | EP — paid partition ($0.01–$49.99), representative value $25.00                                                            |
| **Manual Env**         | Local, Staging                                                                                                             |
| **Precondition**       | Guest checkout, not signed in (A3). Cart subtotal is $25.00 with no coupon applied (A1). Standard shipping preselected (A5). |
| **Steps**              | 1. Open the checkout page as a guest <br> 2. Read the shipping fee line for Standard <br> 3. Read the order total           |
| **Expected**           | Standard shipping fee shows `$5.99`. Order total equals subtotal plus tax plus $5.99.                                       |
| **data-testid needed** | `checkout-subtotal`, `shipping-fee`, `checkout-total`                                                                      |
| **Source**             | AC-1                                                                                                                       |
| **Note**               | Uses a guest rather than a signed-in non-member so both non-member paths (A3) are covered across TC-SHIP-002 and this case. |

---

## TC-SHIP-005: Member gets free standard shipping below the $50.00 threshold

| Field                  | Value                                                                                                                          |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                       |
| **Issue**              | SHIP-9                                                                                                                         |
| **Automation Score**   | HIGH (58/67.5)                                                                                                                 |
| **ISTQB Technique**    | Decision Table — R3 (member, standard, subtotal irrelevant), exercised with subtotal $10.00                                     |
| **Manual Env**         | Local, Staging                                                                                                                 |
| **Precondition**       | Signed in as a member with active membership (A3). Cart subtotal is $10.00 with no coupon applied (A1). Standard preselected (A5). |
| **Steps**              | 1. Open the checkout page <br> 2. Read the shipping fee line for Standard <br> 3. Read the order total                          |
| **Expected**           | Standard shipping fee shows `Free` (A4). Order total has no shipping amount added.                                             |
| **data-testid needed** | `checkout-subtotal`, `shipping-option-standard`, `shipping-fee`, `checkout-total`                                               |
| **Source**             | AC-2                                                                                                                           |
| **Note**               | N/A — no caveats                                                                                                               |

---

## TC-SHIP-006: Member gets free standard shipping at $49.99 and at $50.00

| Field                  | Value                                                                                                                                                         |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                       |
| **Issue**              | SHIP-9                                                                                                                                                        |
| **Automation Score**   | HIGH (54/67.5)                                                                                                                                                |
| **ISTQB Technique**    | BVA — two-value at $50.00 ($49.99, $50.00) applied to the member partition, to show the threshold has no effect on members                                    |
| **Manual Env**         | Local, Staging                                                                                                                                                |
| **Precondition**       | Signed in as a member (A3). Cart subtotal is $49.99 with no coupon applied (A1, A2). Standard preselected (A5).                                                |
| **Steps**              | 1. Open the checkout page <br> 2. Read the shipping fee line for Standard <br> 3. Return to the cart and add a $0.01 item so the subtotal is $50.00 <br> 4. Open the checkout page again <br> 5. Read the shipping fee line for Standard |
| **Expected**           | Step 2: fee shows `Free`. Step 5: fee still shows `Free` (A4). At no point is `$5.99` shown.                                                                   |
| **data-testid needed** | `checkout-subtotal`, `shipping-fee`                                                                                                                           |
| **Source**             | AC-2                                                                                                                                                          |
| **Note**               | A $0.01 test SKU is needed in the test catalogue; if none exists, use any two subtotals straddling $50.00.                                                     |

---

## TC-SHIP-007: Express shipping costs $12.99 for a non-member below the threshold

| Field                  | Value                                                                                                                                                |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                             |
| **Issue**              | SHIP-9                                                                                                                                               |
| **Automation Score**   | HIGH (58/67.5)                                                                                                                                       |
| **ISTQB Technique**    | Decision Table — R4 (non-member, express, subtotal irrelevant), exercised with subtotal $30.00                                                        |
| **Manual Env**         | Local, Staging                                                                                                                                       |
| **Precondition**       | Signed in as a non-member (A3). Cart subtotal is $30.00 with no coupon applied (A1). Checkout open with Standard preselected (A5).                     |
| **Steps**              | 1. Select the Express shipping option <br> 2. Read the shipping fee line <br> 3. Read the order total                                                 |
| **Expected**           | Express is shown as selected. Shipping fee shows `$12.99`. Order total equals subtotal plus tax plus $12.99.                                          |
| **data-testid needed** | `shipping-option-express`, `shipping-fee`, `checkout-total`                                                                                          |
| **Source**             | AC-3                                                                                                                                                 |
| **Note**               | N/A — no caveats                                                                                                                                     |

---

## TC-SHIP-008: Express shipping still costs $12.99 for a non-member at or above $50.00

| Field                  | Value                                                                                                                            |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                          |
| **Issue**              | SHIP-9                                                                                                                           |
| **Automation Score**   | HIGH (56/67.5)                                                                                                                   |
| **ISTQB Technique**    | Decision Table — R4 with subtotal ≥ $50.00 ($75.00), confirming the free-standard rule does not leak into express                 |
| **Manual Env**         | Local, Staging                                                                                                                   |
| **Precondition**       | Signed in as a non-member (A3). Cart subtotal is $75.00 with no coupon applied (A1). Checkout open with Standard preselected (A5). |
| **Steps**              | 1. Confirm the Standard fee shows `Free` <br> 2. Select the Express shipping option <br> 3. Read the shipping fee line <br> 4. Read the order total |
| **Expected**           | After step 2 the shipping fee shows `$12.99`, not `Free`. Order total equals subtotal plus tax plus $12.99.                       |
| **data-testid needed** | `shipping-option-standard`, `shipping-option-express`, `shipping-fee`, `checkout-total`                                          |
| **Source**             | AC-1, AC-3                                                                                                                       |
| **Note**               | Likely defect shape: a single "free shipping" flag computed from the subtotal and applied to whichever method is selected.        |

---

## TC-SHIP-009: Member pays $7.99 for express below the threshold

| Field                  | Value                                                                                                                       |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                    |
| **Issue**              | SHIP-9                                                                                                                      |
| **Automation Score**   | HIGH (58/67.5)                                                                                                              |
| **ISTQB Technique**    | Decision Table — R5 (member, express, subtotal irrelevant), exercised with subtotal $15.00                                   |
| **Manual Env**         | Local, Staging                                                                                                              |
| **Precondition**       | Signed in as a member (A3). Cart subtotal is $15.00 with no coupon applied (A1). Checkout open with Standard preselected (A5). |
| **Steps**              | 1. Select the Express shipping option <br> 2. Read the shipping fee line <br> 3. Read the order total                        |
| **Expected**           | Shipping fee shows `$7.99`. Order total equals subtotal plus tax plus $7.99.                                                 |
| **data-testid needed** | `shipping-option-express`, `shipping-fee`, `checkout-total`                                                                 |
| **Source**             | AC-3                                                                                                                        |
| **Note**               | N/A — no caveats                                                                                                            |

---

## TC-SHIP-010: Member pays $7.99 for express at or above $50.00, never free

| Field                  | Value                                                                                                                         |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                       |
| **Issue**              | SHIP-9                                                                                                                        |
| **Automation Score**   | HIGH (56/67.5)                                                                                                                |
| **ISTQB Technique**    | Decision Table — R5 with subtotal $50.00 (the boundary), confirming the member free-standard rule does not make express free   |
| **Manual Env**         | Local, Staging                                                                                                                |
| **Precondition**       | Signed in as a member (A3). Cart subtotal is exactly $50.00 with no coupon applied (A1, A2). Checkout open with Standard preselected (A5). |
| **Steps**              | 1. Confirm the Standard fee shows `Free` <br> 2. Select the Express shipping option <br> 3. Read the shipping fee line <br> 4. Read the order total |
| **Expected**           | After step 2 the shipping fee shows `$7.99`, not `Free` and not `$12.99`. Order total equals subtotal plus tax plus $7.99.     |
| **data-testid needed** | `shipping-option-standard`, `shipping-option-express`, `shipping-fee`, `checkout-total`                                       |
| **Source**             | AC-2, AC-3                                                                                                                    |
| **Note**               | Likely defect shape: member discount implemented as "members ship free" rather than per-method pricing.                       |

---

## TC-SHIP-011: Switching between Standard and Express updates the fee and total without reload

| Field                  | Value                                                                                                                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                                                |
| **Issue**              | SHIP-9                                                                                                                                                                                 |
| **Automation Score**   | HIGH (54/67.5)                                                                                                                                                                         |
| **ISTQB Technique**    | State Transition — Standard → Express → Standard (0-switch coverage of both valid transitions)                                                                                          |
| **Manual Env**         | Local, Staging                                                                                                                                                                         |
| **Precondition**       | Signed in as a non-member (A3). Cart subtotal is $30.00 with no coupon applied (A1). Checkout open with Standard preselected (A5).                                                       |
| **Steps**              | 1. Read the fee and total <br> 2. Select Express <br> 3. Read the fee and total <br> 4. Select Standard <br> 5. Read the fee and total                                                   |
| **Expected**           | Step 1: fee `$5.99`. Step 3: fee `$12.99` and the total rises by $7.00. Step 5: fee `$5.99` and the total returns to the step 1 value. Each change is visible without a page reload.    |
| **data-testid needed** | `shipping-option-standard`, `shipping-option-express`, `shipping-fee`, `checkout-total`                                                                                                |
| **Source**             | Added by QA (the story goal is to "see the right shipping fee" but no AC covers changing the method once at checkout)                                                                  |
| **Note**               | N/A — no caveats                                                                                                                                                                       |

---

## TC-SHIP-012: Removing an item that drops the subtotal below $50.00 recalculates the standard fee

| Field                  | Value                                                                                                                                                                      |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                                    |
| **Issue**              | SHIP-9                                                                                                                                                                     |
| **Automation Score**   | MEDIUM (50/67.5)                                                                                                                                                           |
| **ISTQB Technique**    | Error Guessing — stale fee after a cart change crossing the threshold                                                                                                       |
| **Manual Env**         | Local, Staging                                                                                                                                                             |
| **Precondition**       | Signed in as a non-member (A3). Cart holds a $45.00 item and a $10.00 item (subtotal $55.00), no coupon (A1). Checkout open with Standard preselected and the fee showing `Free`. |
| **Steps**              | 1. Remove the $10.00 item from the order (via the checkout's edit-cart control or by returning to the cart) <br> 2. Return to or refresh the checkout page <br> 3. Read the subtotal, fee and total |
| **Expected**           | Subtotal shows `$45.00`. Standard shipping fee shows `$5.99`. Order total includes $5.99. The earlier `Free` value is not retained.                                          |
| **data-testid needed** | `cart-remove-item`, `checkout-subtotal`, `shipping-fee`, `checkout-total`                                                                                                   |
| **Source**             | Added by QA (the ticket is silent on cart changes made after the fee was first calculated)                                                                                  |
| **Note**               | If the checkout caches the shipping quote per session, this is where it shows.                                                                                             |

---

## TC-SHIP-013: Signing in as a member mid-checkout switches the fee to the member price

| Field                  | Value                                                                                                                                                       |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @ship @candidate`                                                                                                                     |
| **Issue**              | SHIP-9                                                                                                                                                      |
| **Automation Score**   | MEDIUM (44/67.5)                                                                                                                                            |
| **ISTQB Technique**    | State Transition — Guest (non-member) → Member within one checkout session; Error Guessing — membership read once and cached                                 |
| **Manual Env**         | Local, Staging                                                                                                                                              |
| **Precondition**       | Not signed in (guest). Cart subtotal is $30.00, no coupon (A1). Checkout open, Express selected, fee showing `$12.99`. A member account's credentials available (A3). |
| **Steps**              | 1. Use the checkout's sign-in control and sign in as the member <br> 2. Confirm the cart is preserved and Express is still selected <br> 3. Read the fee and total |
| **Expected**           | Shipping fee shows `$7.99` and the total drops by $5.00. Selecting Standard then shows `Free`.                                                               |
| **data-testid needed** | `checkout-sign-in`, `shipping-option-express`, `shipping-option-standard`, `shipping-fee`, `checkout-total`                                                  |
| **Source**             | Added by QA (the ticket is silent on a shopper's member status changing during checkout)                                                                    |
| **Note**               | Assumes checkout offers sign-in and preserves the guest cart on sign-in; if it does not, mark BLOCKED and note the actual flow.                              |

---

## TC-SHIP-014: A coupon that pulls the subtotal below $50.00 removes free standard shipping

| Field                  | Value                                                                                                                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @ship @candidate`                                                                                                                                                    |
| **Issue**              | SHIP-9                                                                                                                                                                                     |
| **Automation Score**   | MEDIUM (42/67.5)                                                                                                                                                                           |
| **ISTQB Technique**    | EP — ambiguous partition "subtotal after discount"; Error Guessing — threshold evaluated against the pre-discount amount                                                                   |
| **Manual Env**         | Local, Staging                                                                                                                                                                             |
| **Precondition**       | Signed in as a non-member (A3). Cart subtotal is $55.00 before discounts. A valid $10.00-off coupon exists. Checkout open with Standard preselected and the fee showing `Free`.             |
| **Steps**              | 1. Apply the coupon <br> 2. Read the subtotal, discount, fee and total                                                                                                                     |
| **Expected**           | Under assumption A1 the discounted subtotal is `$45.00` and the Standard fee changes to `$5.99`. If the product owner rules that the threshold uses the pre-discount amount, the fee stays `Free`; record which outcome was observed either way. |
| **data-testid needed** | `coupon-input`, `checkout-subtotal`, `shipping-fee`, `checkout-total`                                                                                                                      |
| **Source**             | Added by QA (the ticket does not define whether "subtotal" is before or after discounts)                                                                                                   |
| **Note**               | Expected result depends on A1, which is unverified. Do not log a defect from this case until the product owner confirms the definition; log a ticket question instead.                      |

---

Rules not applied: `context-discovery` and `testing-guidelines` are not loaded and no `qa-rules` skill is installed, so their text was not consulted. In place of context discovery, the working directory was checked and found empty, which is why every precondition above is an assumption.
