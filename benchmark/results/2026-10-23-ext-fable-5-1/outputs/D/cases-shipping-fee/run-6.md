---
feature: Shipping fee at checkout
feature_code: SHIP
tc_count: 15
tracker_issues: [SHIP-9]
risk_level: HIGH
runbook: N/A — no runbook requested
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-24
---

# Test Cases — Shipping fee at checkout

| Field            | Value                                                                  |
| ---------------- | ---------------------------------------------------------------------- |
| **Project**      | Checkout                                                               |
| **Author**       | Marco — Senior QA Analyst                                              |
| **Date Created** | 2026-10-24                                                             |
| **Last Updated** | 2026-10-24                                                             |
| **Methodology**  | ISTQB CTFL v4.0 — Decision Table, BVA, EP, State Transition, Error Guessing |

## Assumptions

The working repository is empty, so none of the preconditions or expected results below could be grounded in code. Each is an assumption to confirm with the team before execution.

- **A1 — Subtotal definition.** "Order subtotal" is the merchandise total shown in the order summary after promo or coupon discounts, before tax and before shipping. If the product applies the threshold before discounts, TC-SHIP-013 inverts.
- **A2 — Member definition.** A "member" is a signed-in account whose membership is active at checkout time. An expired or cancelled membership counts as a non-member.
- **A3 — Boundary.** "$50.00 or more" is inclusive: $50.00 is free, $49.99 is $5.99.
- **A4 — Display.** The checkout order summary shows a shipping-method selector with the options **Standard** and **Express**, a shipping line that reads `Free`, `$5.99`, `$7.99` or `$12.99`, and an order total that includes the fee.
- **A5 — Tracker.** SHIP-9 follows the Linear or Jira identifier pattern. No base URL was given, so the ID is left as plain text.
- **A6 — Currency.** All prices are USD with two decimals and no rounding issues at the threshold.

## Decision table (basis for the DT cases)

| Condition             | R1  | R2  | R3  | R4  | R5  |
| --------------------- | --- | --- | --- | --- | --- |
| is_member             | F   | F   | T   | F   | T   |
| method = Express      | F   | F   | F   | T   | T   |
| subtotal ≥ $50.00     | F   | T   | –   | –   | –   |
| **Actions**           |     |     |     |     |     |
| Shipping = Free       |     | X   | X   |     |     |
| Shipping = $5.99      | X   |     |     |     |     |
| Shipping = $12.99     |     |     |     | X   |     |
| Shipping = $7.99      |     |     |     |     | X   |

No column is infeasible. Each of the five columns is covered by at least one case below.

---

## TC-SHIP-001: Non-member standard shipping costs $5.99 just below the threshold

| Field                  | Value                                                                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                               |
| **Issue**              | SHIP-9                                                                                                                                 |
| **Automation Score**   | HIGH (60/67.5)                                                                                                                         |
| **ISTQB Technique**    | BVA — two-value, $49.99 (max of the below-threshold partition); Decision Table R1                                                       |
| **Manual Env**         | Local, Staging                                                                                                                         |
| **Precondition**       | Shopper is signed out or signed in without a membership (A2). Cart subtotal is exactly $49.99 (A1). No coupon applied.                |
| **Steps**              | 1. Open checkout <br> 2. Select **Standard** shipping <br> 3. Read the shipping line and the order total                                 |
| **Expected**           | Shipping line reads `$5.99`. Order total equals $49.99 + tax + $5.99. No "free shipping" message is shown.                              |
| **data-testid needed** | `shipping-method-standard`, `summary-shipping-fee`, `summary-order-total`                                                              |
| **Source**             | AC-1                                                                                                                                   |
| **Note**               | Release gate: this is the paid-standard path most non-member orders hit.                                                               |

---

## TC-SHIP-002: Non-member standard shipping is free at exactly $50.00

| Field                  | Value                                                                                                                 |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                              |
| **Issue**              | SHIP-9                                                                                                                |
| **Automation Score**   | HIGH (60/67.5)                                                                                                        |
| **ISTQB Technique**    | BVA — two-value, $50.00 (min of the free partition, inclusive per A3); Decision Table R2                               |
| **Manual Env**         | Local, Staging                                                                                                        |
| **Precondition**       | Shopper is a non-member. Cart subtotal is exactly $50.00. No coupon applied.                                           |
| **Steps**              | 1. Open checkout <br> 2. Select **Standard** shipping <br> 3. Read the shipping line and the order total                |
| **Expected**           | Shipping line reads `Free`. Order total equals $50.00 + tax with no shipping added.                                   |
| **data-testid needed** | `shipping-method-standard`, `summary-shipping-fee`, `summary-order-total`                                             |
| **Source**             | AC-1                                                                                                                  |
| **Note**               | Release gate. An off-by-one here ("more than $50") would charge $5.99 and fail this case.                              |

---

## TC-SHIP-003: Non-member standard shipping stays free one cent above the threshold

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                 |
| **Issue**              | SHIP-9                                                                                                  |
| **Automation Score**   | HIGH (55/67.5)                                                                                          |
| **ISTQB Technique**    | BVA — three-value, $50.01 (min+1 of the free partition)                                                 |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Shopper is a non-member. Cart subtotal is exactly $50.01. No coupon applied.                             |
| **Steps**              | 1. Open checkout <br> 2. Select **Standard** shipping <br> 3. Read the shipping line                     |
| **Expected**           | Shipping line reads `Free`.                                                                             |
| **data-testid needed** | `shipping-method-standard`, `summary-shipping-fee`                                                      |
| **Source**             | AC-1                                                                                                    |
| **Note**               | Guards against a strict-equality check on $50.00 that misses larger values.                             |

---

## TC-SHIP-004: Non-member standard shipping costs $5.99 for a small order

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                 |
| **Issue**              | SHIP-9                                                                                                  |
| **Automation Score**   | HIGH (55/67.5)                                                                                          |
| **ISTQB Technique**    | EP — EP1 (valid: subtotal between $0.01 and $49.99), representative $12.50                              |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Shopper is a non-member. Cart subtotal is $12.50. No coupon applied.                                     |
| **Steps**              | 1. Open checkout <br> 2. Select **Standard** shipping <br> 3. Read the shipping line and the order total  |
| **Expected**           | Shipping line reads `$5.99`. Order total equals $12.50 + tax + $5.99.                                    |
| **data-testid needed** | `shipping-method-standard`, `summary-shipping-fee`, `summary-order-total`                               |
| **Source**             | AC-1                                                                                                    |
| **Note**               | N/A — no caveats                                                                                        |

---

## TC-SHIP-005: Member standard shipping is free below the threshold

| Field                  | Value                                                                                                                       |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                    |
| **Issue**              | SHIP-9                                                                                                                      |
| **Automation Score**   | HIGH (58/67.5)                                                                                                              |
| **ISTQB Technique**    | Decision Table — R3 (member, standard, subtotal irrelevant), tested with subtotal below threshold                             |
| **Manual Env**         | Local, Staging                                                                                                              |
| **Precondition**       | Shopper is signed in with an active membership (A2). Cart subtotal is $10.00. No coupon applied.                            |
| **Steps**              | 1. Open checkout <br> 2. Select **Standard** shipping <br> 3. Read the shipping line and the order total                      |
| **Expected**           | Shipping line reads `Free`. Order total equals $10.00 + tax with no shipping added.                                          |
| **data-testid needed** | `shipping-method-standard`, `summary-shipping-fee`, `summary-order-total`                                                   |
| **Source**             | AC-2                                                                                                                        |
| **Note**               | Release gate: the member benefit must override the AC-1 threshold.                                                          |

---

## TC-SHIP-006: Member standard shipping is free at and above the threshold

| Field                  | Value                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                    |
| **Issue**              | SHIP-9                                                                                                     |
| **Automation Score**   | HIGH (55/67.5)                                                                                             |
| **ISTQB Technique**    | Decision Table — R3 (member, standard), tested with subtotal $50.00 to confirm the condition is irrelevant   |
| **Manual Env**         | Local, Staging                                                                                             |
| **Precondition**       | Shopper is a member. Cart subtotal is exactly $50.00. No coupon applied.                                    |
| **Steps**              | 1. Open checkout <br> 2. Select **Standard** shipping <br> 3. Read the shipping line                        |
| **Expected**           | Shipping line reads `Free`.                                                                                |
| **data-testid needed** | `shipping-method-standard`, `summary-shipping-fee`                                                         |
| **Source**             | AC-1, AC-2                                                                                                 |
| **Note**               | Both rules agree here; the case confirms there is no double-discount or negative fee.                       |

---

## TC-SHIP-007: Non-member express shipping costs $12.99 below the threshold

| Field                  | Value                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                   |
| **Issue**              | SHIP-9                                                                                                     |
| **Automation Score**   | HIGH (58/67.5)                                                                                             |
| **ISTQB Technique**    | Decision Table — R4 (non-member, express, subtotal irrelevant), tested with subtotal below threshold         |
| **Manual Env**         | Local, Staging                                                                                             |
| **Precondition**       | Shopper is a non-member. Cart subtotal is $25.00. No coupon applied.                                        |
| **Steps**              | 1. Open checkout <br> 2. Select **Express** shipping <br> 3. Read the shipping line and the order total      |
| **Expected**           | Shipping line reads `$12.99`. Order total equals $25.00 + tax + $12.99.                                     |
| **data-testid needed** | `shipping-method-express`, `summary-shipping-fee`, `summary-order-total`                                   |
| **Source**             | AC-3                                                                                                       |
| **Note**               | Release gate.                                                                                              |

---

## TC-SHIP-008: Non-member express shipping is not free above the threshold

| Field                  | Value                                                                                                              |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                            |
| **Issue**              | SHIP-9                                                                                                             |
| **Automation Score**   | HIGH (55/67.5)                                                                                                     |
| **ISTQB Technique**    | Decision Table — R4 (non-member, express), tested with subtotal $120.00 to confirm the free-threshold does not leak |
| **Manual Env**         | Local, Staging                                                                                                     |
| **Precondition**       | Shopper is a non-member. Cart subtotal is $120.00. No coupon applied.                                               |
| **Steps**              | 1. Open checkout <br> 2. Select **Express** shipping <br> 3. Read the shipping line                                 |
| **Expected**           | Shipping line reads `$12.99`. No "free shipping" message is shown for express.                                      |
| **data-testid needed** | `shipping-method-express`, `summary-shipping-fee`                                                                  |
| **Source**             | AC-1, AC-3                                                                                                         |
| **Note**               | Likely defect: applying the AC-1 threshold to every method instead of standard only.                                |

---

## TC-SHIP-009: Member express shipping costs $7.99 below the threshold

| Field                  | Value                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                   |
| **Issue**              | SHIP-9                                                                                                     |
| **Automation Score**   | HIGH (58/67.5)                                                                                             |
| **ISTQB Technique**    | Decision Table — R5 (member, express, subtotal irrelevant), tested with subtotal below threshold             |
| **Manual Env**         | Local, Staging                                                                                             |
| **Precondition**       | Shopper is a member. Cart subtotal is $25.00. No coupon applied.                                            |
| **Steps**              | 1. Open checkout <br> 2. Select **Express** shipping <br> 3. Read the shipping line and the order total      |
| **Expected**           | Shipping line reads `$7.99`. Order total equals $25.00 + tax + $7.99.                                       |
| **data-testid needed** | `shipping-method-express`, `summary-shipping-fee`, `summary-order-total`                                   |
| **Source**             | AC-3                                                                                                       |
| **Note**               | Release gate.                                                                                              |

---

## TC-SHIP-010: Member express shipping stays $7.99 above the threshold, not free

| Field                  | Value                                                                                                                   |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                 |
| **Issue**              | SHIP-9                                                                                                                  |
| **Automation Score**   | HIGH (55/67.5)                                                                                                          |
| **ISTQB Technique**    | Decision Table — R5 (member, express), tested with subtotal $120.00 to confirm the member free-standard rule does not leak |
| **Manual Env**         | Local, Staging                                                                                                          |
| **Precondition**       | Shopper is a member. Cart subtotal is $120.00. No coupon applied.                                                        |
| **Steps**              | 1. Open checkout <br> 2. Select **Express** shipping <br> 3. Read the shipping line                                      |
| **Expected**           | Shipping line reads `$7.99`.                                                                                            |
| **data-testid needed** | `shipping-method-express`, `summary-shipping-fee`                                                                       |
| **Source**             | AC-2, AC-3                                                                                                              |
| **Note**               | Likely defect: treating "members get free shipping" as method-agnostic.                                                  |

---

## TC-SHIP-011: Switching shipping method recalculates the fee and order total

| Field                  | Value                                                                                                                                                                      |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p1 @e2e @ship @candidate`                                                                                                                                        |
| **Issue**              | SHIP-9                                                                                                                                                                     |
| **Automation Score**   | HIGH (54/67.5)                                                                                                                                                             |
| **ISTQB Technique**    | State Transition — Standard → Express → Standard (0-switch coverage of both valid transitions)                                                                              |
| **Manual Env**         | Local, Staging                                                                                                                                                             |
| **Precondition**       | Shopper is a non-member. Cart subtotal is $25.00. Checkout is open with **Standard** selected and the shipping line showing `$5.99`.                                        |
| **Steps**              | 1. Select **Express** <br> 2. Read the shipping line and the order total <br> 3. Select **Standard** again <br> 4. Read the shipping line and the order total                 |
| **Expected**           | After step 1 the shipping line reads `$12.99` and the total rises by $7.00. After step 3 the shipping line reads `$5.99` and the total returns to its original value. No page reload is required. |
| **data-testid needed** | `shipping-method-standard`, `shipping-method-express`, `summary-shipping-fee`, `summary-order-total`                                                                       |
| **Source**             | Added by QA (the ticket is silent on changing method after the fee is first shown)                                                                                          |
| **Note**               | N/A — no caveats                                                                                                                                                           |

---

## TC-SHIP-012: Cart change that crosses the threshold updates the standard fee

| Field                  | Value                                                                                                                                                    |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                  |
| **Issue**              | SHIP-9                                                                                                                                                   |
| **Automation Score**   | MEDIUM (49/67.5)                                                                                                                                         |
| **ISTQB Technique**    | Error Guessing — stale fee after subtotal changes (cached value, no recalculation)                                                                         |
| **Manual Env**         | Local, Staging                                                                                                                                           |
| **Precondition**       | Shopper is a non-member. Cart contains one item priced $30.00. Checkout is open with **Standard** selected and the shipping line showing `$5.99`.          |
| **Steps**              | 1. Increase the item quantity to 2 (subtotal $60.00) from the checkout or cart <br> 2. Return to or refresh the checkout summary <br> 3. Read the shipping line <br> 4. Reduce quantity back to 1 <br> 5. Read the shipping line |
| **Expected**           | After step 2 the shipping line reads `Free`. After step 4 the shipping line reads `$5.99`. The order total reflects each change.                           |
| **data-testid needed** | `cart-item-quantity`, `summary-subtotal`, `summary-shipping-fee`, `summary-order-total`                                                                   |
| **Source**             | Added by QA (the ticket is silent on recalculation after the cart changes)                                                                                |
| **Note**               | Where quantity cannot be edited from checkout, perform steps 1 and 4 in the cart page.                                                                     |

---

## TC-SHIP-013: Coupon that drops the subtotal below $50.00 removes free standard shipping

| Field                  | Value                                                                                                                                                       |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @ship @candidate`                                                                                                                     |
| **Issue**              | SHIP-9                                                                                                                                                      |
| **Automation Score**   | MEDIUM (44/67.5)                                                                                                                                            |
| **ISTQB Technique**    | Error Guessing — threshold evaluated on the wrong amount (pre- vs post-discount)                                                                              |
| **Manual Env**         | Local, Staging                                                                                                                                              |
| **Precondition**       | Shopper is a non-member. Cart subtotal is $55.00. A valid $10.00-off coupon exists. **Standard** is selected and the shipping line shows `Free`.               |
| **Steps**              | 1. Apply the coupon <br> 2. Read the subtotal, the shipping line and the order total                                                                         |
| **Expected**           | Subtotal reads `$45.00`. Shipping line reads `$5.99` (per assumption A1: the threshold uses the post-discount subtotal). Order total equals $45.00 + tax + $5.99. |
| **data-testid needed** | `coupon-input`, `coupon-apply`, `summary-subtotal`, `summary-shipping-fee`, `summary-order-total`                                                           |
| **Source**             | Added by QA (the ticket does not define whether "subtotal" is before or after discounts)                                                                     |
| **Note**               | If the product owner decides the threshold uses the pre-discount subtotal, the expected shipping line becomes `Free`. Confirm before running.                 |

---

## TC-SHIP-014: Expired membership is charged non-member rates

| Field                  | Value                                                                                                                                         |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                       |
| **Issue**              | SHIP-9                                                                                                                                        |
| **Automation Score**   | MEDIUM (46/67.5)                                                                                                                              |
| **ISTQB Technique**    | EP — invalid partition of "member" (account with an expired membership)                                                                       |
| **Manual Env**         | Local, Staging                                                                                                                                |
| **Precondition**       | Shopper is signed in with an account whose membership expired before today (A2). Cart subtotal is $25.00. No coupon applied.                  |
| **Steps**              | 1. Open checkout <br> 2. Select **Standard** and read the shipping line <br> 3. Select **Express** and read the shipping line                   |
| **Expected**           | After step 2 the shipping line reads `$5.99`. After step 3 it reads `$12.99`. No member pricing is applied.                                   |
| **data-testid needed** | `shipping-method-standard`, `shipping-method-express`, `summary-shipping-fee`                                                                 |
| **Source**             | Added by QA (the ticket does not define what counts as a member)                                                                              |
| **Note**               | Requires a test account fixture with an expired membership; the setup effort lowers the automation score.                                      |

---

## TC-SHIP-015: Signing in as a member during checkout applies member rates

| Field                  | Value                                                                                                                                                                 |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @ship @candidate`                                                                                                                               |
| **Issue**              | SHIP-9                                                                                                                                                                |
| **Automation Score**   | MEDIUM (42/67.5)                                                                                                                                                      |
| **ISTQB Technique**    | State Transition — Guest checkout → Signed-in member (fee must follow the membership state change)                                                                     |
| **Manual Env**         | Local, Staging                                                                                                                                                        |
| **Precondition**       | Shopper is signed out. Cart subtotal is $25.00. Checkout is open with **Express** selected and the shipping line showing `$12.99`. A member account is available.       |
| **Steps**              | 1. Sign in from the checkout page with the member account <br> 2. Read the shipping line with **Express** still selected <br> 3. Select **Standard** and read the shipping line |
| **Expected**           | After step 2 the shipping line reads `$7.99`. After step 3 it reads `Free`. The selected method and cart contents survive the sign-in.                                 |
| **data-testid needed** | `checkout-sign-in`, `shipping-method-standard`, `shipping-method-express`, `summary-shipping-fee`                                                                     |
| **Source**             | Added by QA (the ticket is silent on membership state changing mid-checkout)                                                                                           |
| **Note**               | If guest checkout does not exist, mark this case `N/A — no guest checkout` and keep TC-SHIP-005 and TC-SHIP-009 as the member coverage.                                |

---

## Rules not applied

- **context-discovery**: the repository at the working directory contains no files, so preconditions and expected results could not be checked against the code. Every value above comes from the ticket text and the assumptions A1 to A6.
- **testing-guidelines**: not loaded and no `qa-rules` skill is installed. The tag taxonomy was taken from the command's own tagging rules.
