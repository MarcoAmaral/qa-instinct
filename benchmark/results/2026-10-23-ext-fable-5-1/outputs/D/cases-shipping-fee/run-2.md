---
feature: Shipping fee at checkout
feature_code: SHIP
tc_count: 13
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
| **Project**      | Storefront checkout                                          |
| **Author**       | Marco — Senior QA Analyst                                    |
| **Date Created** | 2026-10-24                                                   |
| **Last Updated** | 2026-10-24                                                   |
| **Methodology**  | ISTQB CTFL v4.0 — Decision Table, BVA, EP, Error Guessing    |

## Scope and assumptions

The working repository is empty, so no `Precondition` or `Expected` below could be verified against code. The `context-discovery` rule could not be applied; every value comes from the story text and the assumptions listed here. Confirm each assumption with the product owner before execution.

- **A1 — Subtotal definition.** "Order subtotal" is the sum of line items after item-level discounts and promo codes, before tax and before shipping. If promo codes apply after the fee is computed, TC-SHIP-010 changes.
- **A2 — Member definition.** A member is a signed-in shopper whose account carries an active membership. Guests and signed-in non-members are both "non-members".
- **A3 — Currency and rounding.** Prices are USD with two decimals; comparison is on the exact cent value, so $49.99 is below the threshold and $50.00 is at it.
- **A4 — Free display.** A free fee is shown as `$0.00` (or the word `Free`); either is acceptable, but the order total must include the fee as zero.
- **A5 — Default method.** Standard shipping is preselected when the checkout page opens. Express is chosen by selecting a radio or option on the same page.
- **A6 — Live recalculation.** The fee updates on the checkout page without a full reload whenever the method, the subtotal or the membership state changes.
- **A7 — Environments.** Local and Staging exist; Staging has a test member account and a test non-member account.
- **A8 — Tracker.** `SHIP-9` is used as plain text; the tracker base URL is unknown.

## Decision table (basis for TC-SHIP-001 to TC-SHIP-008)

| Rule | Member | Subtotal ≥ $50.00 | Method   | Fee    |
| ---- | ------ | ----------------- | -------- | ------ |
| R1   | No     | No                | Standard | $5.99  |
| R2   | No     | Yes               | Standard | $0.00  |
| R3   | Yes    | No                | Standard | $0.00  |
| R4   | Yes    | Yes               | Standard | $0.00  |
| R5   | No     | No                | Express  | $12.99 |
| R6   | No     | Yes               | Express  | $12.99 |
| R7   | Yes    | No                | Express  | $7.99  |
| R8   | Yes    | Yes               | Express  | $7.99  |

---

## TC-SHIP-001: Non-member below threshold pays $5.99 standard shipping

| Field                  | Value                                                                                                                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                                                                    |
| **Issue**              | SHIP-9                                                                                                                                                                                      |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                                                                              |
| **ISTQB Technique**    | Decision Table — R1 (non-member, subtotal < $50.00, Standard)                                                                                                                               |
| **Manual Env**         | Local, Staging                                                                                                                                                                              |
| **Precondition**       | Shopper is a guest (not signed in). Cart contains items with subtotal $30.00. No promo code applied.                                                                                         |
| **Steps**              | 1. Open checkout <br> 2. Confirm **Standard** is the selected shipping method <br> 3. Read the shipping fee and the order total                                                              |
| **Expected**           | Shipping fee shows `$5.99`. Order total equals `$35.99` plus any tax. No free-shipping message is shown.                                                                                     |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee`, `order-subtotal`, `order-total`                                                                                                                 |
| **Source**             | AC-1                                                                                                                                                                                        |
| **Note**               | Relies on A1, A5. Pair with TC-SHIP-002 for the threshold pass.                                                                                                                             |

---

## TC-SHIP-002: Non-member at or above threshold gets free standard shipping

| Field                  | Value                                                                                                                                         |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                      |
| **Issue**              | SHIP-9                                                                                                                                        |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                                |
| **ISTQB Technique**    | Decision Table — R2 (non-member, subtotal ≥ $50.00, Standard)                                                                                 |
| **Manual Env**         | Local, Staging                                                                                                                                |
| **Precondition**       | Shopper is a guest. Cart subtotal is $75.00. No promo code applied.                                                                            |
| **Steps**              | 1. Open checkout <br> 2. Confirm **Standard** is selected <br> 3. Read the shipping fee and the order total                                    |
| **Expected**           | Shipping fee shows `$0.00` or `Free`. Order total equals `$75.00` plus any tax; no shipping amount is added.                                   |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee`, `order-total`                                                                                     |
| **Source**             | AC-1                                                                                                                                          |
| **Note**               | Relies on A4 for the display form.                                                                                                            |

---

## TC-SHIP-003: Member below threshold gets free standard shipping

| Field                  | Value                                                                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                             |
| **Issue**              | SHIP-9                                                                                                                               |
| **Automation Score**   | HIGH (58/67.5)                                                                                                                       |
| **ISTQB Technique**    | Decision Table — R3 (member, subtotal < $50.00, Standard)                                                                            |
| **Manual Env**         | Local, Staging                                                                                                                       |
| **Precondition**       | Shopper is signed in with an active membership. Cart subtotal is $10.00.                                                             |
| **Steps**              | 1. Open checkout <br> 2. Confirm **Standard** is selected <br> 3. Read the shipping fee and the order total                           |
| **Expected**           | Shipping fee shows `$0.00` or `Free`. Order total equals `$10.00` plus any tax. The `$5.99` non-member fee does not appear anywhere. |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee`, `order-total`                                                                            |
| **Source**             | AC-2                                                                                                                                 |
| **Note**               | Relies on A2. This is the rule that overrides AC-1; it belongs in the gate.                                                          |

---

## TC-SHIP-004: Member at or above threshold still gets free standard shipping

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                 |
| **Issue**              | SHIP-9                                                                                                  |
| **Automation Score**   | HIGH (55/67.5)                                                                                          |
| **ISTQB Technique**    | Decision Table — R4 (member, subtotal ≥ $50.00, Standard)                                               |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Shopper is signed in with an active membership. Cart subtotal is $120.00.                               |
| **Steps**              | 1. Open checkout <br> 2. Confirm **Standard** is selected <br> 3. Read the shipping fee                 |
| **Expected**           | Shipping fee shows `$0.00` or `Free`. Order total equals `$120.00` plus any tax.                        |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee`, `order-total`                                               |
| **Source**             | AC-1, AC-2                                                                                              |
| **Note**               | Guards against a bug where the member rule and the threshold rule conflict and one of them adds a fee. |

---

## TC-SHIP-005: Non-member below threshold pays $12.99 express

| Field                  | Value                                                                                                                               |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                            |
| **Issue**              | SHIP-9                                                                                                                              |
| **Automation Score**   | HIGH (59/67.5)                                                                                                                      |
| **ISTQB Technique**    | Decision Table — R5 (non-member, subtotal < $50.00, Express)                                                                        |
| **Manual Env**         | Local, Staging                                                                                                                      |
| **Precondition**       | Shopper is a guest. Cart subtotal is $30.00.                                                                                        |
| **Steps**              | 1. Open checkout <br> 2. Select **Express** shipping <br> 3. Read the shipping fee and the order total                               |
| **Expected**           | Shipping fee changes from `$5.99` to `$12.99`. Order total equals `$42.99` plus any tax.                                             |
| **data-testid needed** | `shipping-method-express`, `shipping-fee`, `order-total`                                                                            |
| **Source**             | AC-3                                                                                                                                |
| **Note**               | N/A — no caveats                                                                                                                    |

---

## TC-SHIP-006: Non-member above threshold still pays $12.99 express

| Field                  | Value                                                                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                 |
| **Issue**              | SHIP-9                                                                                                                                                  |
| **Automation Score**   | HIGH (57/67.5)                                                                                                                                          |
| **ISTQB Technique**    | Decision Table — R6 (non-member, subtotal ≥ $50.00, Express)                                                                                            |
| **Manual Env**         | Local, Staging                                                                                                                                          |
| **Precondition**       | Shopper is a guest. Cart subtotal is $75.00.                                                                                                            |
| **Steps**              | 1. Open checkout <br> 2. Confirm Standard shows `$0.00` or `Free` <br> 3. Select **Express** shipping <br> 4. Read the shipping fee and the order total  |
| **Expected**           | Shipping fee shows `$12.99`. Order total equals `$87.99` plus any tax. The free-shipping threshold does not reduce the express fee.                      |
| **data-testid needed** | `shipping-method-express`, `shipping-fee`, `order-total`                                                                                                |
| **Source**             | AC-3                                                                                                                                                    |
| **Note**               | AC-3 says "at any subtotal" only for members; QA reads AC-1's threshold as applying to standard only. Confirm with PO.                                  |

---

## TC-SHIP-007: Member below threshold pays $7.99 express

| Field                  | Value                                                                                                             |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                          |
| **Issue**              | SHIP-9                                                                                                            |
| **Automation Score**   | HIGH (57/67.5)                                                                                                    |
| **ISTQB Technique**    | Decision Table — R7 (member, subtotal < $50.00, Express)                                                          |
| **Manual Env**         | Local, Staging                                                                                                    |
| **Precondition**       | Shopper is signed in with an active membership. Cart subtotal is $10.00.                                          |
| **Steps**              | 1. Open checkout <br> 2. Select **Express** shipping <br> 3. Read the shipping fee and the order total             |
| **Expected**           | Shipping fee shows `$7.99`. Order total equals `$17.99` plus any tax. `$12.99` does not appear.                    |
| **data-testid needed** | `shipping-method-express`, `shipping-fee`, `order-total`                                                          |
| **Source**             | AC-3                                                                                                              |
| **Note**               | N/A — no caveats                                                                                                  |

---

## TC-SHIP-008: Member above threshold pays $7.99 express

| Field                  | Value                                                                                                          |
| ---------------------- | -------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                        |
| **Issue**              | SHIP-9                                                                                                         |
| **Automation Score**   | HIGH (55/67.5)                                                                                                 |
| **ISTQB Technique**    | Decision Table — R8 (member, subtotal ≥ $50.00, Express)                                                       |
| **Manual Env**         | Local, Staging                                                                                                 |
| **Precondition**       | Shopper is signed in with an active membership. Cart subtotal is $120.00.                                      |
| **Steps**              | 1. Open checkout <br> 2. Select **Express** shipping <br> 3. Read the shipping fee and the order total          |
| **Expected**           | Shipping fee shows `$7.99`. Order total equals `$127.99` plus any tax. Express is not made free by the threshold. |
| **data-testid needed** | `shipping-method-express`, `shipping-fee`, `order-total`                                                       |
| **Source**             | AC-2, AC-3                                                                                                     |
| **Note**               | Guards against the member standard-free rule leaking into express.                                             |

---

## TC-SHIP-009: Standard fee flips exactly at the $50.00 boundary for a non-member

| Field                  | Value                                                                                                                                                                                                                                                                 |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @e2e @ship @candidate @gate`                                                                                                                                                                                                                         |
| **Issue**              | SHIP-9                                                                                                                                                                                                                                                                |
| **Automation Score**   | HIGH (59/67.5)                                                                                                                                                                                                                                                        |
| **ISTQB Technique**    | BVA — three-value on the $50.00 threshold: $49.99 (max-1 of the paid partition), $50.00 (min of free), $50.01 (min+1 of free)                                                                                                                                         |
| **Manual Env**         | Local, Staging                                                                                                                                                                                                                                                        |
| **Precondition**       | Shopper is a guest. Standard shipping selected. Test products exist that allow the cart to reach exactly $49.99, $50.00 and $50.01.                                                                                                                                   |
| **Steps**              | 1. Set the cart subtotal to $49.99 and open checkout; read the fee <br> 2. Adjust the cart to a subtotal of $50.00; read the fee <br> 3. Adjust the cart to a subtotal of $50.01; read the fee                                                                          |
| **Expected**           | Step 1: fee is `$5.99`. Step 2: fee is `$0.00` or `Free`. Step 3: fee is `$0.00` or `Free`. The order total matches subtotal plus fee in each step.                                                                                                                   |
| **data-testid needed** | `order-subtotal`, `shipping-fee`, `order-total`                                                                                                                                                                                                                       |
| **Source**             | AC-1                                                                                                                                                                                                                                                                  |
| **Note**               | Relies on A3. If an API or unit layer exposes the fee calculator, add a unit test for the same three values; it will be cheaper and more precise than the e2e version.                                                                                                 |

---

## TC-SHIP-010: Promo code that drops subtotal below $50.00 restores the $5.99 fee

| Field                  | Value                                                                                                                                                                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                                                                                                   |
| **Issue**              | SHIP-9                                                                                                                                                                                                                                    |
| **Automation Score**   | MEDIUM (47/67.5)                                                                                                                                                                                                                          |
| **ISTQB Technique**    | Error Guessing — subtotal crosses the threshold after the fee was first computed                                                                                                                                                          |
| **Manual Env**         | Staging                                                                                                                                                                                                                                   |
| **Precondition**       | Shopper is a guest. Cart subtotal is $55.00. A valid promo code worth $10.00 off exists. Standard selected; fee currently shows free.                                                                                                      |
| **Steps**              | 1. Open checkout and confirm the fee is `$0.00` or `Free` <br> 2. Apply the $10.00 promo code <br> 3. Read the subtotal, the shipping fee and the order total <br> 4. Remove the promo code <br> 5. Read the fee again                       |
| **Expected**           | Step 3: subtotal shows `$45.00`, fee shows `$5.99`, total is `$50.99` plus any tax, without a page reload. Step 5: fee returns to `$0.00` or `Free`.                                                                                       |
| **data-testid needed** | `promo-code-input`, `promo-code-apply`, `order-subtotal`, `shipping-fee`, `order-total`                                                                                                                                                   |
| **Source**             | Added by QA (the ticket is silent on whether "subtotal" is before or after discounts; this case fixes assumption A1 so a disagreement surfaces as a failure)                                                                               |
| **Note**               | If the PO decides shipping is computed on the pre-discount subtotal, invert the Expected in step 3 and keep the case.                                                                                                                      |

---

## TC-SHIP-011: Fee updates when switching between Standard and Express

| Field                  | Value                                                                                                                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                                                                                  |
| **Issue**              | SHIP-9                                                                                                                                                                                                                   |
| **Automation Score**   | HIGH (56/67.5)                                                                                                                                                                                                           |
| **ISTQB Technique**    | State Transition — Standard → Express → Standard; 0-switch coverage of the method selector                                                                                                                               |
| **Manual Env**         | Local, Staging                                                                                                                                                                                                           |
| **Precondition**       | Shopper is a guest. Cart subtotal is $30.00. Checkout open with Standard selected and fee `$5.99`.                                                                                                                        |
| **Steps**              | 1. Select **Express** <br> 2. Read the fee and total <br> 3. Select **Standard** <br> 4. Read the fee and total <br> 5. Select **Express** twice quickly                                                                  |
| **Expected**           | Step 2: fee `$12.99`, total `$42.99` plus tax. Step 4: fee `$5.99`, total `$35.99` plus tax. Step 5: fee settles at `$12.99`; no stale value or doubled fee is shown.                                                     |
| **data-testid needed** | `shipping-method-standard`, `shipping-method-express`, `shipping-fee`, `order-total`                                                                                                                                     |
| **Source**             | Added by QA (the ticket describes fees per method but not what happens when the shopper changes method on the page)                                                                                                       |
| **Note**               | Step 5 targets a race where two fee requests resolve out of order.                                                                                                                                                       |

---

## TC-SHIP-012: Signing in as a member mid-checkout removes the standard fee

| Field                  | Value                                                                                                                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                                                                                                                    |
| **Issue**              | SHIP-9                                                                                                                                                                                                                                                     |
| **Automation Score**   | MEDIUM (44/67.5)                                                                                                                                                                                                                                           |
| **ISTQB Technique**    | State Transition — guest → signed-in member while the checkout page is open                                                                                                                                                                                |
| **Manual Env**         | Staging                                                                                                                                                                                                                                                    |
| **Precondition**       | Shopper starts as a guest with cart subtotal $30.00. A member test account exists. Checkout open with Standard selected and fee `$5.99`.                                                                                                                    |
| **Steps**              | 1. Use the checkout sign-in link and sign in with the member account <br> 2. Return to or remain on checkout <br> 3. Read the shipping fee and total <br> 4. Select **Express** and read the fee                                                             |
| **Expected**           | Step 3: fee shows `$0.00` or `Free`; total is `$30.00` plus tax. Step 4: fee shows `$7.99`. The cart contents are preserved across sign-in.                                                                                                                 |
| **data-testid needed** | `checkout-sign-in-link`, `shipping-fee`, `order-total`, `shipping-method-express`                                                                                                                                                                          |
| **Source**             | Added by QA (the ticket is silent on membership state changing after checkout has loaded)                                                                                                                                                                  |
| **Note**               | Relies on A2 and A6. Also run the reverse: a member whose membership is expired in the admin tool while checkout is open should see `$5.99`; log the result in this case's Note if there is no separate case.                                                |

---

## TC-SHIP-013: Signed-in non-member is charged like a guest

| Field                  | Value                                                                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                            |
| **Issue**              | SHIP-9                                                                                                                                             |
| **Automation Score**   | HIGH (54/67.5)                                                                                                                                     |
| **ISTQB Technique**    | EP — invalid partition for the member rule: signed-in account without membership (and expired membership as a second representative)              |
| **Manual Env**         | Local, Staging                                                                                                                                     |
| **Precondition**       | Two test accounts: one signed-in with no membership, one with a membership that expired yesterday. Cart subtotal is $30.00 for each.               |
| **Steps**              | 1. Sign in with the non-member account and open checkout <br> 2. Read the Standard fee, then select Express and read the fee <br> 3. Repeat steps 1 and 2 with the expired-membership account |
| **Expected**           | Both accounts: Standard fee `$5.99`, Express fee `$12.99`. No member pricing is applied on the basis of being signed in alone.                      |
| **data-testid needed** | `shipping-fee`, `shipping-method-express`                                                                                                          |
| **Source**             | Added by QA (the ticket does not define "member"; this case pins assumption A2 so that "signed in" is not treated as "member")                      |
| **Note**               | Highest-value negative case: a bug here gives free shipping to every account holder.                                                               |

---

## Release gate

Cases tagged `@gate`: TC-SHIP-001, 002, 003, 005, 007, 009. They cover all three ACs, the member override and the exact threshold, and should run in under 10 minutes.

## Rules not applied

- `context-discovery`: the repository has no source files, so nothing could be verified against code. All preconditions and expected values rest on assumptions A1 to A8.
- `testing-guidelines` tag taxonomy and the `qa-reference` worked examples were not loaded in this session; tags follow the four required categories stated in the command.
