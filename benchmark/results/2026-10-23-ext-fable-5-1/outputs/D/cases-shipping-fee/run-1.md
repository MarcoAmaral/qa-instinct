---
feature: Shipping fee at checkout
feature_code: SHIP
tc_count: 15
tracker_issues: [SHIP-9]
risk_level: MEDIUM
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-24
---

# Test Cases — Shipping fee at checkout

| Field            | Value                                                                                        |
| ---------------- | -------------------------------------------------------------------------------------------- |
| **Project**      | Checkout (SHIP)                                                                              |
| **Author**       | Marco — Senior QA Analyst                                                                    |
| **Date Created** | 2026-10-24                                                                                   |
| **Last Updated** | 2026-10-24                                                                                   |
| **Methodology**  | ISTQB CTFL v4.0 — Decision Table, BVA (three-value), EP, State Transition, Error Guessing   |

## Assumptions

The working repository is empty, so none of the preconditions or expected results below could be checked against code. Every item here is an assumption until a developer confirms it.

- **A1 Subtotal definition.** "Order subtotal" is the merchandise total after any item or promo discounts, before tax and before shipping. The $50.00 threshold compares against this value.
- **A2 Member definition.** A member is a signed-in account with an active membership. Guests and signed-in accounts without an active membership are non-members. A lapsed membership counts as non-member.
- **A3 Display format.** A zero fee is shown as the word `Free`. Non-zero fees are shown in USD with two decimals, for example `$5.99`.
- **A4 Checkout layout.** The shipping step offers two selectable options, Standard and Express, with Standard preselected. A shipping fee line and an order total line are visible on the same step.
- **A5 Recalculation.** The fee and order total update without a page reload when the shopper changes the shipping option or the cart contents.
- **A6 Currency.** USD only. No other currency or region is in scope.
- **A7 Test data.** A guest session, a non-member account, a member account and an expired-membership account are available, plus products priced to reach the exact subtotals used below and a promo code worth $10.00 off.
- **A8 Selectors.** The `data-testid` values are proposals; the UI has none yet that QA could verify.

## Decision table (AC-1, AC-2, AC-3)

| Rule | Member | Option   | Subtotal | Fee    | Case       |
| ---- | ------ | -------- | -------- | ------ | ---------- |
| R1   | No     | Standard | < $50.00 | $5.99  | TC-SHIP-001, 003 |
| R2   | No     | Standard | ≥ $50.00 | Free   | TC-SHIP-002, 004, 005 |
| R3   | Yes    | Standard | < $50.00 | Free   | TC-SHIP-006 |
| R4   | Yes    | Standard | ≥ $50.00 | Free   | TC-SHIP-007 |
| R5   | No     | Express  | < $50.00 | $12.99 | TC-SHIP-008 |
| R6   | No     | Express  | ≥ $50.00 | $12.99 | TC-SHIP-009 |
| R7   | Yes    | Express  | < $50.00 | $7.99  | TC-SHIP-010 |
| R8   | Yes    | Express  | ≥ $50.00 | $7.99  | TC-SHIP-011 |

---

## TC-SHIP-001: Non-member pays $5.99 standard shipping below the threshold

| Field                  | Value                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @e2e @ship @candidate`                                                                                |
| **Issue**              | SHIP-9                                                                                                                 |
| **Automation Score**   | HIGH (64/67.5)                                                                                                         |
| **ISTQB Technique**    | Decision Table — R1 (non-member, Standard, subtotal < $50.00); EP representative $25.00                                |
| **Manual Env**         | Local, Staging                                                                                                         |
| **Precondition**       | Guest session (not signed in). Cart subtotal is exactly $25.00. Checkout is open at the shipping step (A4).             |
| **Steps**              | 1. Confirm the subtotal line reads `$25.00` <br> 2. Confirm **Standard** is selected <br> 3. Read the shipping fee line <br> 4. Read the order total line |
| **Expected**           | Shipping fee line reads `$5.99`. Order total equals $25.00 plus $5.99 plus any tax shown, i.e. `$30.99` before tax.     |
| **data-testid needed** | `shipping-option-standard`, `shipping-fee`, `order-subtotal`, `order-total`                                            |
| **Source**             | AC-1                                                                                                                   |
| **Note**               | Relies on A1 and A3.                                                                                                   |

---

## TC-SHIP-002: Non-member gets free standard shipping above the threshold

| Field                  | Value                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @e2e @ship @candidate`                                                                                |
| **Issue**              | SHIP-9                                                                                                                 |
| **Automation Score**   | HIGH (64/67.5)                                                                                                         |
| **ISTQB Technique**    | Decision Table — R2 (non-member, Standard, subtotal ≥ $50.00); EP representative $120.00                               |
| **Manual Env**         | Local, Staging                                                                                                         |
| **Precondition**       | Guest session. Cart subtotal is exactly $120.00. Checkout is open at the shipping step with **Standard** selected.     |
| **Steps**              | 1. Confirm the subtotal line reads `$120.00` <br> 2. Read the shipping fee line <br> 3. Read the order total line        |
| **Expected**           | Shipping fee line reads `Free`. Order total equals $120.00 plus any tax shown; no shipping amount is added.             |
| **data-testid needed** | `shipping-option-standard`, `shipping-fee`, `order-subtotal`, `order-total`                                            |
| **Source**             | AC-1                                                                                                                   |
| **Note**               | Relies on A3 for the `Free` label.                                                                                     |

---

## TC-SHIP-003: Subtotal of $49.99 charges $5.99 standard shipping

| Field                  | Value                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                |
| **Issue**              | SHIP-9                                                                                                                 |
| **Automation Score**   | HIGH (64/67.5)                                                                                                         |
| **ISTQB Technique**    | BVA — three-value, threshold − 0.01 ($49.99) on the Standard non-member partition                                      |
| **Manual Env**         | Local, Staging                                                                                                         |
| **Precondition**       | Guest session. Cart subtotal is exactly $49.99. Checkout is open at the shipping step with **Standard** selected.      |
| **Steps**              | 1. Confirm the subtotal line reads `$49.99` <br> 2. Read the shipping fee line                                          |
| **Expected**           | Shipping fee line reads `$5.99`.                                                                                       |
| **data-testid needed** | `shipping-fee`, `order-subtotal`                                                                                       |
| **Source**             | AC-1                                                                                                                   |
| **Note**               | Catches a `>` written where `>=` was meant, and any rounding that lifts $49.99 to $50.00.                              |

---

## TC-SHIP-004: Subtotal of exactly $50.00 gives free standard shipping

| Field                  | Value                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                |
| **Issue**              | SHIP-9                                                                                                                 |
| **Automation Score**   | HIGH (64/67.5)                                                                                                         |
| **ISTQB Technique**    | BVA — three-value, threshold ($50.00) on the Standard non-member partition                                             |
| **Manual Env**         | Local, Staging                                                                                                         |
| **Precondition**       | Guest session. Cart subtotal is exactly $50.00. Checkout is open at the shipping step with **Standard** selected.      |
| **Steps**              | 1. Confirm the subtotal line reads `$50.00` <br> 2. Read the shipping fee line                                          |
| **Expected**           | Shipping fee line reads `Free`.                                                                                        |
| **data-testid needed** | `shipping-fee`, `order-subtotal`                                                                                       |
| **Source**             | AC-1                                                                                                                   |
| **Note**               | The AC says "$50.00 or more", so the boundary itself must be free.                                                     |

---

## TC-SHIP-005: Subtotal of $50.01 gives free standard shipping

| Field                  | Value                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                |
| **Issue**              | SHIP-9                                                                                                                 |
| **Automation Score**   | HIGH (64/67.5)                                                                                                         |
| **ISTQB Technique**    | BVA — three-value, threshold + 0.01 ($50.01) on the Standard non-member partition                                      |
| **Manual Env**         | Local, Staging                                                                                                         |
| **Precondition**       | Guest session. Cart subtotal is exactly $50.01. Checkout is open at the shipping step with **Standard** selected.      |
| **Steps**              | 1. Confirm the subtotal line reads `$50.01` <br> 2. Read the shipping fee line                                          |
| **Expected**           | Shipping fee line reads `Free`.                                                                                        |
| **data-testid needed** | `shipping-fee`, `order-subtotal`                                                                                       |
| **Source**             | AC-1                                                                                                                   |
| **Note**               | Guards against a comparison done on integer dollars or cents that drops the fractional cent.                           |

---

## TC-SHIP-006: Member gets free standard shipping below the threshold

| Field                  | Value                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                |
| **Issue**              | SHIP-9                                                                                                                 |
| **Automation Score**   | HIGH (62.5/67.5)                                                                                                       |
| **ISTQB Technique**    | Decision Table — R3 (member, Standard, subtotal < $50.00); value $49.99 doubles as a BVA check that the threshold is ignored for members |
| **Manual Env**         | Local, Staging                                                                                                         |
| **Precondition**       | Signed in as an account with an active membership (A2). Cart subtotal is exactly $49.99. Checkout is open at the shipping step with **Standard** selected. |
| **Steps**              | 1. Confirm the subtotal line reads `$49.99` <br> 2. Read the shipping fee line <br> 3. Read the order total line         |
| **Expected**           | Shipping fee line reads `Free`. Order total equals $49.99 plus any tax shown.                                           |
| **data-testid needed** | `shipping-fee`, `order-subtotal`, `order-total`                                                                        |
| **Source**             | AC-2                                                                                                                   |
| **Note**               | N/A — no caveats                                                                                                       |

---

## TC-SHIP-007: Member gets free standard shipping above the threshold

| Field                  | Value                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                |
| **Issue**              | SHIP-9                                                                                                                 |
| **Automation Score**   | HIGH (62.5/67.5)                                                                                                       |
| **ISTQB Technique**    | Decision Table — R4 (member, Standard, subtotal ≥ $50.00); EP representative $120.00                                   |
| **Manual Env**         | Local, Staging                                                                                                         |
| **Precondition**       | Signed in as a member. Cart subtotal is exactly $120.00. Checkout is open at the shipping step with **Standard** selected. |
| **Steps**              | 1. Confirm the subtotal line reads `$120.00` <br> 2. Read the shipping fee line                                         |
| **Expected**           | Shipping fee line reads `Free`.                                                                                        |
| **data-testid needed** | `shipping-fee`, `order-subtotal`                                                                                       |
| **Source**             | AC-1, AC-2                                                                                                             |
| **Note**               | Both rules give the same result here; the case confirms neither path double-applies or errors.                        |

---

## TC-SHIP-008: Non-member pays $12.99 express shipping below the threshold

| Field                  | Value                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                |
| **Issue**              | SHIP-9                                                                                                                 |
| **Automation Score**   | HIGH (64/67.5)                                                                                                         |
| **ISTQB Technique**    | Decision Table — R5 (non-member, Express, subtotal < $50.00); EP representative $25.00                                 |
| **Manual Env**         | Local, Staging                                                                                                         |
| **Precondition**       | Guest session. Cart subtotal is exactly $25.00. Checkout is open at the shipping step with **Standard** selected.      |
| **Steps**              | 1. Select **Express** <br> 2. Read the shipping fee line <br> 3. Read the order total line                              |
| **Expected**           | Shipping fee line reads `$12.99`. Order total equals $25.00 plus $12.99 plus any tax shown, i.e. `$37.99` before tax.  |
| **data-testid needed** | `shipping-option-express`, `shipping-fee`, `order-total`                                                               |
| **Source**             | AC-3                                                                                                                   |
| **Note**               | N/A — no caveats                                                                                                       |

---

## TC-SHIP-009: Non-member still pays $12.99 express shipping above the threshold

| Field                  | Value                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @e2e @ship @candidate`                                                                                |
| **Issue**              | SHIP-9                                                                                                                 |
| **Automation Score**   | HIGH (64/67.5)                                                                                                         |
| **ISTQB Technique**    | Decision Table — R6 (non-member, Express, subtotal ≥ $50.00); value $50.00 doubles as a BVA check that the free-shipping threshold does not leak into Express |
| **Manual Env**         | Local, Staging                                                                                                         |
| **Precondition**       | Guest session. Cart subtotal is exactly $50.00. Checkout is open at the shipping step with **Standard** selected.      |
| **Steps**              | 1. Confirm the shipping fee line reads `Free` for Standard <br> 2. Select **Express** <br> 3. Read the shipping fee line |
| **Expected**           | Shipping fee line reads `$12.99`. The threshold discount from AC-1 is not applied to Express.                           |
| **data-testid needed** | `shipping-option-express`, `shipping-fee`                                                                              |
| **Source**             | AC-3                                                                                                                   |
| **Note**               | The most likely defect: the $50.00 free rule applied regardless of option.                                             |

---

## TC-SHIP-010: Member pays $7.99 express shipping below the threshold

| Field                  | Value                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                |
| **Issue**              | SHIP-9                                                                                                                 |
| **Automation Score**   | HIGH (62.5/67.5)                                                                                                       |
| **ISTQB Technique**    | Decision Table — R7 (member, Express, subtotal < $50.00); value $49.99                                                 |
| **Manual Env**         | Local, Staging                                                                                                         |
| **Precondition**       | Signed in as a member. Cart subtotal is exactly $49.99. Checkout is open at the shipping step with **Standard** selected. |
| **Steps**              | 1. Select **Express** <br> 2. Read the shipping fee line <br> 3. Read the order total line                              |
| **Expected**           | Shipping fee line reads `$7.99`. Order total equals $49.99 plus $7.99 plus any tax shown, i.e. `$57.98` before tax.    |
| **data-testid needed** | `shipping-option-express`, `shipping-fee`, `order-total`                                                               |
| **Source**             | AC-3                                                                                                                   |
| **Note**               | Confirms the member Express rate is $7.99 and not `Free` (AC-2 applies to Standard only).                               |

---

## TC-SHIP-011: Member pays $7.99 express shipping above the threshold

| Field                  | Value                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                |
| **Issue**              | SHIP-9                                                                                                                 |
| **Automation Score**   | HIGH (62.5/67.5)                                                                                                       |
| **ISTQB Technique**    | Decision Table — R8 (member, Express, subtotal ≥ $50.00); value $50.00                                                 |
| **Manual Env**         | Local, Staging                                                                                                         |
| **Precondition**       | Signed in as a member. Cart subtotal is exactly $50.00. Checkout is open at the shipping step with **Standard** selected. |
| **Steps**              | 1. Select **Express** <br> 2. Read the shipping fee line                                                                |
| **Expected**           | Shipping fee line reads `$7.99`.                                                                                       |
| **data-testid needed** | `shipping-option-express`, `shipping-fee`                                                                              |
| **Source**             | AC-3                                                                                                                   |
| **Note**               | N/A — no caveats                                                                                                       |

---

## TC-SHIP-012: Switching shipping option updates fee and order total without reload

| Field                  | Value                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                |
| **Issue**              | SHIP-9                                                                                                                 |
| **Automation Score**   | HIGH (62.5/67.5)                                                                                                       |
| **ISTQB Technique**    | State Transition — Standard → Express → Standard (0-switch coverage of both valid transitions)                         |
| **Manual Env**         | Local, Staging                                                                                                         |
| **Precondition**       | Guest session. Cart subtotal is exactly $25.00. Checkout is open at the shipping step with **Standard** selected.      |
| **Steps**              | 1. Note fee and order total <br> 2. Select **Express** <br> 3. Note fee and order total <br> 4. Select **Standard** <br> 5. Note fee and order total |
| **Expected**           | Step 1: fee `$5.99`, total `$30.99` before tax. Step 3: fee `$12.99`, total `$37.99` before tax. Step 5: fee `$5.99`, total `$30.99` before tax. No page reload occurs and the previously selected option is no longer marked selected. |
| **data-testid needed** | `shipping-option-standard`, `shipping-option-express`, `shipping-fee`, `order-total`                                   |
| **Source**             | Added by QA (the story asks to "see the right shipping fee" but no AC covers changing the option after it is first shown) |
| **Note**               | Relies on A5. A stale fee after a switch is a common display bug.                                                      |

---

## TC-SHIP-013: Removing an item that drops the subtotal below $50.00 reinstates the standard fee

| Field                  | Value                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                |
| **Issue**              | SHIP-9                                                                                                                 |
| **Automation Score**   | HIGH (60.5/67.5)                                                                                                       |
| **ISTQB Technique**    | State Transition — subtotal crosses the threshold downward while the shipping step is open                             |
| **Manual Env**         | Local, Staging                                                                                                         |
| **Precondition**       | Guest session. Cart holds two items: $40.00 and $15.00 (subtotal $55.00). Checkout is open at the shipping step with **Standard** selected and the fee showing `Free`. Items can be removed from checkout or from a cart drawer reachable from checkout. |
| **Steps**              | 1. Confirm fee reads `Free` <br> 2. Remove the $15.00 item <br> 3. Return to or stay on the shipping step <br> 4. Read subtotal, fee and order total |
| **Expected**           | Subtotal reads `$40.00`. Shipping fee reads `$5.99`. Order total equals $40.00 plus $5.99 plus any tax shown. The earlier `Free` value is not cached.  |
| **data-testid needed** | `cart-item-remove`, `order-subtotal`, `shipping-fee`, `order-total`                                                    |
| **Source**             | Added by QA (the ticket is silent on the subtotal changing after the fee is shown)                                     |
| **Note**               | Relies on A5. If items cannot be edited from checkout, perform step 2 in the cart page and re-enter checkout.           |

---

## TC-SHIP-014: Promo code that lowers the subtotal below $50.00 removes free standard shipping

| Field                  | Value                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                |
| **Issue**              | SHIP-9                                                                                                                 |
| **Automation Score**   | HIGH (55.5/67.5)                                                                                                       |
| **ISTQB Technique**    | Error Guessing — threshold evaluated against the pre-discount amount instead of the discounted subtotal                |
| **Manual Env**         | Local, Staging                                                                                                         |
| **Precondition**       | Guest session. Cart subtotal is exactly $55.00. A valid promo code worth $10.00 off the order exists (A7). Checkout is open at the shipping step with **Standard** selected and the fee showing `Free`. |
| **Steps**              | 1. Enter the promo code and apply it <br> 2. Read subtotal, fee and order total                                         |
| **Expected**           | Subtotal reads `$45.00`. Shipping fee reads `$5.99`. Order total equals $45.00 plus $5.99 plus any tax shown.           |
| **data-testid needed** | `promo-code-input`, `promo-code-apply`, `order-subtotal`, `shipping-fee`, `order-total`                                |
| **Source**             | Added by QA (the ticket does not define whether "subtotal" is before or after discounts)                              |
| **Note**               | Depends entirely on A1. If the product owner decides the threshold uses the pre-discount amount, correct the Expected in place with a dated note rather than deleting this case. |

---

## TC-SHIP-015: Account with an expired membership is charged as a non-member

| Field                  | Value                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @ship @candidate`                                                                                |
| **Issue**              | SHIP-9                                                                                                                 |
| **Automation Score**   | MEDIUM (43.5/67.5)                                                                                                     |
| **ISTQB Technique**    | EP — invalid partition of "member" (membership exists but is not active)                                               |
| **Manual Env**         | Staging                                                                                                                |
| **Precondition**       | Signed in as an account whose membership end date is in the past (A2, A7). Cart subtotal is exactly $25.00. Checkout is open at the shipping step with **Standard** selected. |
| **Steps**              | 1. Read the shipping fee line <br> 2. Select **Express** <br> 3. Read the shipping fee line                              |
| **Expected**           | Step 1: fee reads `$5.99`. Step 3: fee reads `$12.99`. Member rates are not applied.                                    |
| **data-testid needed** | `shipping-option-express`, `shipping-fee`                                                                              |
| **Source**             | Added by QA (the ticket does not say what "member" means when a membership has lapsed)                                 |
| **Note**               | Depends on A2. Marked Staging only because creating an expired membership locally may need a database edit; revise once the setup path is known. |

---

## Notes on rules not applied

The `context-discovery` rule could not be applied as written: the `qa-rules` skill is not installed and the working repository contains no files, so no precondition, label or selector above was verified against code. Treat A1 to A8 as open questions for the developer and product owner.
