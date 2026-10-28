---
feature: Shipping fee at checkout
feature_code: SHIP
tc_count: 12
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
| **Author**       | QA — Senior QA Analyst                                       |
| **Date Created** | 2026-10-24                                                   |
| **Last Updated** | 2026-10-24                                                   |
| **Methodology**  | ISTQB CTFL v4.0 — Decision Table, BVA (three-value), EP, Error Guessing |

## Assumptions

The working directory holds no source code, so nothing below is grounded in an implementation. Every `Precondition`, `Expected` and `data-testid needed` row is a proposal to confirm against the real checkout.

- **A1 — Subtotal definition.** "Order subtotal" is the merchandise total after item-level discounts and before tax, shipping and gift cards. If promo codes apply after the subtotal, the shipping rule uses the pre-promo figure.
- **A2 — Member.** A "member" is a signed-in shopper whose account has an active membership. Guests and signed-in non-members are "non-members".
- **A3 — Methods.** Checkout offers exactly two methods, Standard and Express, chosen by a radio group. Standard is selected by default.
- **A4 — Display.** A zero fee is rendered as `Free`; other fees as `$X.XX` in USD. The order total equals subtotal + shipping fee (tax out of scope).
- **A5 — Boundary.** "$50.00 or more" is inclusive, so $50.00 is free and $49.99 is $5.99. Amounts are compared in cents, not floating-point dollars.
- **A6 — Tracker.** `SHIP-9` is a Jira-style key with no base URL given, so it is written as plain text.

## Decision Table (AC-1 to AC-3)

| Condition / Action      | R1    | R2    | R3    | R4     | R5    |
| ----------------------- | ----- | ----- | ----- | ------ | ----- |
| Method = Standard       | Y     | Y     | Y     | N      | N     |
| Member                  | N     | N     | Y     | N      | Y     |
| Subtotal ≥ $50.00       | N     | Y     | —     | —      | —     |
| **Fee**                 | $5.99 | Free  | Free  | $12.99 | $7.99 |

Columns collapsed where the subtotal is irrelevant (R3, R4, R5); each collapsed column is exercised once below $50 and the subtotal-independence is confirmed in TC-SHIP-007 and TC-SHIP-009.

---

## TC-SHIP-001: Non-member standard shipping below $50 costs $5.99

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                |
| **Issue**              | SHIP-9                                                                                                  |
| **Automation Score**   | HIGH (62/67.5)                                                                                          |
| **ISTQB Technique**    | Decision Table — R1 (Standard, non-member, subtotal < $50.00)                                           |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Guest session; cart subtotal $30.00; checkout page open with Standard selected (A3)                     |
| **Steps**              | 1. Open the checkout summary <br> 2. Read the shipping line and the order total                         |
| **Expected**           | Shipping line shows `$5.99`. Order total shows `$35.99`.                                                |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee`, `order-total`                                               |
| **Source**             | AC-1                                                                                                    |
| **Note**               | N/A — no caveats                                                                                        |

---

## TC-SHIP-002: Non-member standard shipping at $50.00 is free

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                |
| **Issue**              | SHIP-9                                                                                                  |
| **Automation Score**   | HIGH (62/67.5)                                                                                          |
| **ISTQB Technique**    | BVA (three-value) — boundary value $50.00 (min of the free partition); also Decision Table R2           |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Guest session; cart subtotal exactly $50.00; checkout page open with Standard selected                  |
| **Steps**              | 1. Open the checkout summary <br> 2. Read the shipping line and the order total                         |
| **Expected**           | Shipping line shows `Free`. Order total shows `$50.00`.                                                 |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee`, `order-total`                                               |
| **Source**             | AC-1                                                                                                    |
| **Note**               | Inclusive boundary per A5. If the product owner intended "more than $50", this case and TC-SHIP-003 swap outcomes. |

---

## TC-SHIP-003: Non-member standard shipping at $49.99 costs $5.99

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @e2e @ship @candidate @gate`                                                           |
| **Issue**              | SHIP-9                                                                                                  |
| **Automation Score**   | HIGH (60/67.5)                                                                                          |
| **ISTQB Technique**    | BVA (three-value) — boundary value $49.99 (min − 1 cent)                                                |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Guest session; cart subtotal exactly $49.99; checkout page open with Standard selected                  |
| **Steps**              | 1. Open the checkout summary <br> 2. Read the shipping line and the order total                         |
| **Expected**           | Shipping line shows `$5.99`. Order total shows `$55.98`.                                                |
| **data-testid needed** | `shipping-fee`, `order-total`                                                                           |
| **Source**             | AC-1                                                                                                    |
| **Note**               | Pairs with TC-SHIP-002 to prove the threshold is inclusive at $50.00.                                   |

---

## TC-SHIP-004: Non-member standard shipping at $50.01 is free

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                 |
| **Issue**              | SHIP-9                                                                                                  |
| **Automation Score**   | HIGH (57/67.5)                                                                                          |
| **ISTQB Technique**    | BVA (three-value) — boundary value $50.01 (min + 1 cent)                                                |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Guest session; cart subtotal exactly $50.01; checkout page open with Standard selected                  |
| **Steps**              | 1. Open the checkout summary <br> 2. Read the shipping line and the order total                         |
| **Expected**           | Shipping line shows `Free`. Order total shows `$50.01`.                                                 |
| **data-testid needed** | `shipping-fee`, `order-total`                                                                           |
| **Source**             | AC-1                                                                                                    |
| **Note**               | Guards against a `>` versus `>=` slip and against float rounding of 50.01 (A5).                         |

---

## TC-SHIP-005: Non-member standard shipping well above $50 is free

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                 |
| **Issue**              | SHIP-9                                                                                                  |
| **Automation Score**   | HIGH (57/67.5)                                                                                          |
| **ISTQB Technique**    | EP — valid partition (subtotal ≥ $50.00, interior value); Decision Table R2                             |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Guest session; cart subtotal $120.00; checkout page open with Standard selected                         |
| **Steps**              | 1. Open the checkout summary <br> 2. Read the shipping line and the order total                         |
| **Expected**           | Shipping line shows `Free`. Order total shows `$120.00`.                                                |
| **data-testid needed** | `shipping-fee`, `order-total`                                                                           |
| **Source**             | AC-1                                                                                                    |
| **Note**               | N/A — no caveats                                                                                        |

---

## TC-SHIP-006: Member standard shipping below $50 is free

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                |
| **Issue**              | SHIP-9                                                                                                  |
| **Automation Score**   | HIGH (58/67.5)                                                                                          |
| **ISTQB Technique**    | Decision Table — R3 (Standard, member, subtotal < $50.00)                                               |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Signed in as an account with an active membership (A2); cart subtotal $10.00; Standard selected         |
| **Steps**              | 1. Open the checkout summary <br> 2. Read the shipping line and the order total                         |
| **Expected**           | Shipping line shows `Free`. Order total shows `$10.00`.                                                 |
| **data-testid needed** | `shipping-fee`, `order-total`, `member-badge`                                                           |
| **Source**             | AC-2                                                                                                    |
| **Note**               | Member fixture setup is the main automation cost.                                                       |

---

## TC-SHIP-007: Member standard shipping at $49.99 and $50.00 is free in both cases

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                 |
| **Issue**              | SHIP-9                                                                                                  |
| **Automation Score**   | HIGH (54/67.5)                                                                                          |
| **ISTQB Technique**    | BVA (two-value) applied to the member partition — $49.99 and $50.00 both free                           |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Signed in as a member; cart subtotal $49.99; Standard selected                                          |
| **Steps**              | 1. Read the shipping line <br> 2. Add a $0.01 item so the subtotal becomes $50.00 <br> 3. Read the shipping line again |
| **Expected**           | Shipping line shows `Free` after step 1 and after step 3. No `$5.99` appears at any point.              |
| **data-testid needed** | `shipping-fee`, `cart-subtotal`                                                                         |
| **Source**             | AC-2                                                                                                    |
| **Note**               | Proves the $50 threshold has no effect on members ("at any subtotal").                                  |

---

## TC-SHIP-008: Non-member express shipping costs $12.99 below $50

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                |
| **Issue**              | SHIP-9                                                                                                  |
| **Automation Score**   | HIGH (60/67.5)                                                                                          |
| **ISTQB Technique**    | Decision Table — R4 (Express, non-member)                                                               |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Guest session; cart subtotal $30.00; checkout page open with Standard selected                          |
| **Steps**              | 1. Select **Express** <br> 2. Read the shipping line and the order total                                |
| **Expected**           | Shipping line shows `$12.99`. Order total shows `$42.99`.                                               |
| **data-testid needed** | `shipping-method-express`, `shipping-fee`, `order-total`                                                |
| **Source**             | AC-3                                                                                                    |
| **Note**               | N/A — no caveats                                                                                        |

---

## TC-SHIP-009: Non-member express shipping still costs $12.99 at $50.00 or more

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                 |
| **Issue**              | SHIP-9                                                                                                  |
| **Automation Score**   | HIGH (57/67.5)                                                                                          |
| **ISTQB Technique**    | Decision Table — R4 with subtotal ≥ $50.00, confirming the free-shipping threshold does not leak into Express |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Guest session; cart subtotal $50.00; checkout page open                                                 |
| **Steps**              | 1. Select **Express** <br> 2. Read the shipping line and the order total                                |
| **Expected**           | Shipping line shows `$12.99`. Order total shows `$62.99`. Nothing says `Free`.                          |
| **data-testid needed** | `shipping-method-express`, `shipping-fee`, `order-total`                                                |
| **Source**             | AC-1, AC-3                                                                                              |
| **Note**               | AC-1's free threshold is explicitly scoped to Standard; this case checks that scoping.                   |

---

## TC-SHIP-010: Member express shipping costs $7.99 at any subtotal

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                |
| **Issue**              | SHIP-9                                                                                                  |
| **Automation Score**   | HIGH (56/67.5)                                                                                          |
| **ISTQB Technique**    | Decision Table — R5 (Express, member), exercised below and above $50.00                                 |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Signed in as a member; cart subtotal $30.00; checkout page open                                         |
| **Steps**              | 1. Select **Express** <br> 2. Read the shipping line and the order total <br> 3. Add items so the subtotal is $80.00 <br> 4. Read the shipping line and the order total again |
| **Expected**           | After step 2: shipping `$7.99`, total `$37.99`. After step 4: shipping `$7.99`, total `$87.99`. Express never shows `Free` or `$12.99` for a member. |
| **data-testid needed** | `shipping-method-express`, `shipping-fee`, `order-total`, `cart-subtotal`                               |
| **Source**             | AC-3                                                                                                    |
| **Note**               | N/A — no caveats                                                                                        |

---

## TC-SHIP-011: Fee recalculates when the cart crosses the $50 threshold during checkout

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                 |
| **Issue**              | SHIP-9                                                                                                  |
| **Automation Score**   | MEDIUM (49/67.5)                                                                                        |
| **ISTQB Technique**    | State Transition — subtotal partition < $50 → ≥ $50 → < $50 with Standard selected (0-switch coverage of both transitions) |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Guest session; cart holds one item at $45.00 and one at $10.00 (subtotal $55.00); Standard selected     |
| **Steps**              | 1. Read the shipping line <br> 2. Remove the $10.00 item from the checkout page <br> 3. Read the shipping line and total <br> 4. Re-add the $10.00 item <br> 5. Read the shipping line and total |
| **Expected**           | Step 1: `Free`. Step 3: shipping `$5.99`, total `$50.99`. Step 5: shipping `Free`, total `$55.00`. No page reload is needed for the fee to update. |
| **data-testid needed** | `cart-item-remove`, `shipping-fee`, `order-total`, `cart-subtotal`                                      |
| **Source**             | Added by QA (the ticket is silent on recalculation after cart edits; a stale fee contradicts "know what I will pay") |
| **Note**               | Error-guessing target: stale fee cached from the first render.                                          |

---

## TC-SHIP-012: Switching shipping method updates the fee and total without stale values

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                 |
| **Issue**              | SHIP-9                                                                                                  |
| **Automation Score**   | HIGH (55/67.5)                                                                                          |
| **ISTQB Technique**    | State Transition — Standard → Express → Standard for a non-member below $50; Error Guessing (stale closure on rapid toggling) |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Guest session; cart subtotal $30.00; checkout page open with Standard selected                          |
| **Steps**              | 1. Read the shipping line <br> 2. Select **Express** <br> 3. Select **Standard** <br> 4. Toggle Express and Standard five times quickly, ending on Express <br> 5. Read the shipping line and total |
| **Expected**           | Step 1: `$5.99`. After step 2: `$12.99`. After step 3: `$5.99`. After step 5: shipping `$12.99`, total `$42.99`, matching the finally selected method. |
| **data-testid needed** | `shipping-method-standard`, `shipping-method-express`, `shipping-fee`, `order-total`                    |
| **Source**             | Added by QA (the ticket describes each fee but not the transition between methods)                      |
| **Note**               | If the fee comes from an API call, confirm the last response wins, not the last to arrive.               |

---

## Release gate

Cases tagged `@gate`: TC-SHIP-001, 002, 003, 006, 008, 010. They cover every decision-table column plus the inclusive boundary; all are `@p0` and must pass before release.

## Open points for the product owner

- Confirm A1 (what "subtotal" includes) and A5 (inclusive $50.00). Both change expected values if wrong.
- The story does not say what the subtotal rule does for an empty cart or for a member whose membership lapsed mid-session. No cases were written for these; add them once the behaviour is defined.

## Rules not applied

The repository at the working directory is empty, so the `context-discovery` rule could not be grounded in code. The `context-discovery` and `testing-guidelines` rules were not in context and no `qa-rules` skill is installed, so the tag taxonomy follows the summary in this command's own instructions.
