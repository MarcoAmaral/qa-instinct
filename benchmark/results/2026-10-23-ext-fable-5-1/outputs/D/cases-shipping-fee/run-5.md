---
feature: Shipping fee at checkout
feature_code: SHIP
tc_count: 17
tracker_issues: [SHIP-9]
risk_level: HIGH
runbook: N/A — no runbook exists for this feature yet
implementation_pack: N/A — no implementation pack; the repository is empty
spec: N/A — not automated yet
last_updated: 2026-10-24
---

# Test Cases — Shipping fee at checkout

| Field            | Value                                                        |
| ---------------- | ------------------------------------------------------------ |
| **Project**      | N/A — project name not provided in the request               |
| **Author**       | Marco — Senior QA Analyst                                    |
| **Date Created** | 2026-10-24                                                   |
| **Last Updated** | 2026-10-24                                                   |
| **Methodology**  | ISTQB CTFL v4.0 — Decision Table, BVA, EP, State Transition, Error Guessing |

## Context and assumptions

The working directory contains no source code, so `Precondition` and `Expected` could not be grounded in an implementation. Every case below is written from the ticket text alone. Assumptions, each flagged in the case that depends on it:

- **A1 — Subtotal definition.** "Order subtotal" is the sum of line-item prices after any discount code, before tax and before shipping. The ticket does not define it. TC-SHIP-013 checks this reading and must be re-pointed if the product owner decides otherwise.
- **A2 — Member definition.** "Member" is a signed-in shopper whose membership is active at the time the fee is shown. A lapsed membership is treated as non-member (TC-SHIP-017).
- **A3 — Display format.** A free fee is shown as `Free` and a charged fee as a dollar amount with two decimals, for example `$5.99`. If the UI uses `$0.00` instead of `Free`, read `Free` below as `$0.00`.
- **A4 — Threshold boundary.** "$50.00 or more" means the boundary is inclusive: $50.00 is free, $49.99 is charged.
- **A5 — Checkout state.** Checkout is reachable only with a non-empty cart, so a $0.00 subtotal is not tested as a boundary.
- **A6 — Tracker.** `SHIP-9` is used as a plain identifier; no base URL was given, so no link is invented.
- **A7 — Selectors.** `data-testid` names are proposed, not existing; the implementing developer should adopt or map them.

## Decision table (basis for TC-SHIP-001 to TC-SHIP-010)

| Rule | Member | Subtotal ≥ $50.00 | Method   | Fee    | Source | Case             |
| ---- | ------ | ----------------- | -------- | ------ | ------ | ---------------- |
| R1   | No     | No                | Standard | $5.99  | AC-1   | TC-SHIP-001, 003 |
| R2   | No     | Yes               | Standard | Free   | AC-1   | TC-SHIP-002, 004, 005 |
| R3   | Yes    | No                | Standard | Free   | AC-2   | TC-SHIP-006      |
| R4   | Yes    | Yes               | Standard | Free   | AC-2   | TC-SHIP-007      |
| R5   | No     | No                | Express  | $12.99 | AC-3   | TC-SHIP-008      |
| R6   | No     | Yes               | Express  | $12.99 | AC-3   | TC-SHIP-009      |
| R7   | Yes    | No                | Express  | $7.99  | AC-3   | TC-SHIP-010      |
| R8   | Yes    | Yes               | Express  | $7.99  | AC-3   | TC-SHIP-010 (step 5) |

All eight columns are feasible; all eight are covered.

## Release gate

Cases tagged `@gate` form the release gate: TC-SHIP-001, 002, 004, 006, 008, 010. They cover every fee value the ticket names plus the inclusive $50.00 boundary. Everything else is regression depth.

---

## TC-SHIP-001: Charge $5.99 standard shipping to a guest below the threshold

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                  |
| **Issue**              | SHIP-9                                                                                    |
| **Automation Score**   | HIGH (63/67.5)                                                                            |
| **ISTQB Technique**    | Decision Table — R1 (non-member, below threshold, standard); EP — subtotal partition below $50.00 |
| **Manual Env**         | Local, Staging                                                                            |
| **Precondition**       | Shopper is not signed in (no session). Cart contains items whose subtotal is $35.00. No discount code applied. |
| **Steps**              | 1. Open the cart and proceed to checkout <br> 2. Select **Standard** shipping <br> 3. Read the shipping fee line |
| **Expected**           | Shipping fee reads `$5.99`. Subtotal reads `$35.00`. Order total includes the $5.99.      |
| **data-testid needed** | `checkout-subtotal`, `shipping-option-standard`, `shipping-fee`, `order-total`             |
| **Source**             | AC-1                                                                                      |
| **Note**               | Assumption A3 (display format), A5 (non-empty cart).                                      |

---

## TC-SHIP-002: Give a guest free standard shipping well above the threshold

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                  |
| **Issue**              | SHIP-9                                                                                    |
| **Automation Score**   | HIGH (63/67.5)                                                                            |
| **ISTQB Technique**    | Decision Table — R2 (non-member, at or above threshold, standard); EP — subtotal partition ≥ $50.00 |
| **Manual Env**         | Local, Staging                                                                            |
| **Precondition**       | Shopper is not signed in. Cart subtotal is $120.00. No discount code applied.             |
| **Steps**              | 1. Proceed to checkout <br> 2. Select **Standard** shipping <br> 3. Read the shipping fee line |
| **Expected**           | Shipping fee reads `Free`. Order total equals subtotal plus tax with no shipping component. |
| **data-testid needed** | `checkout-subtotal`, `shipping-option-standard`, `shipping-fee`, `order-total`             |
| **Source**             | AC-1                                                                                      |
| **Note**               | Assumption A3.                                                                            |

---

## TC-SHIP-003: Charge $5.99 at $49.99, one cent below the threshold

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                   |
| **Issue**              | SHIP-9                                                                                    |
| **Automation Score**   | HIGH (59/67.5)                                                                            |
| **ISTQB Technique**    | BVA — three-value, min−1 of the free partition ($49.99)                                   |
| **Manual Env**         | Local, Staging                                                                            |
| **Precondition**       | Shopper is not signed in. Cart subtotal is exactly $49.99 (for example one item priced $49.99). |
| **Steps**              | 1. Proceed to checkout <br> 2. Select **Standard** shipping <br> 3. Read the shipping fee line |
| **Expected**           | Shipping fee reads `$5.99`.                                                               |
| **data-testid needed** | `checkout-subtotal`, `shipping-fee`                                                       |
| **Source**             | AC-1                                                                                      |
| **Note**               | Assumption A4 (inclusive boundary). The most likely off-by-one defect is `>` instead of `>=`; TC-SHIP-004 catches it. |

---

## TC-SHIP-004: Give free standard shipping at exactly $50.00

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                  |
| **Issue**              | SHIP-9                                                                                    |
| **Automation Score**   | HIGH (61/67.5)                                                                            |
| **ISTQB Technique**    | BVA — three-value, min of the free partition ($50.00)                                     |
| **Manual Env**         | Local, Staging                                                                            |
| **Precondition**       | Shopper is not signed in. Cart subtotal is exactly $50.00 (for example one item priced $50.00). |
| **Steps**              | 1. Proceed to checkout <br> 2. Select **Standard** shipping <br> 3. Read the shipping fee line |
| **Expected**           | Shipping fee reads `Free`.                                                                |
| **data-testid needed** | `checkout-subtotal`, `shipping-fee`                                                       |
| **Source**             | AC-1                                                                                      |
| **Note**               | Assumption A4. This is the single highest-value boundary in the story.                   |

---

## TC-SHIP-005: Give free standard shipping at $50.01

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                   |
| **Issue**              | SHIP-9                                                                                    |
| **Automation Score**   | HIGH (59/67.5)                                                                            |
| **ISTQB Technique**    | BVA — three-value, min+1 of the free partition ($50.01)                                   |
| **Manual Env**         | Local, Staging                                                                            |
| **Precondition**       | Shopper is not signed in. Cart subtotal is exactly $50.01.                                |
| **Steps**              | 1. Proceed to checkout <br> 2. Select **Standard** shipping <br> 3. Read the shipping fee line |
| **Expected**           | Shipping fee reads `Free`.                                                                |
| **data-testid needed** | `checkout-subtotal`, `shipping-fee`                                                       |
| **Source**             | AC-1                                                                                      |
| **Note**               | N/A — no caveats                                                                          |

---

## TC-SHIP-006: Give a member free standard shipping below the threshold

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                  |
| **Issue**              | SHIP-9                                                                                    |
| **Automation Score**   | HIGH (58/67.5)                                                                            |
| **ISTQB Technique**    | Decision Table — R3 (member, below threshold, standard)                                   |
| **Manual Env**         | Local, Staging                                                                            |
| **Precondition**       | Shopper is signed in with an active membership. Cart subtotal is $12.00.                  |
| **Steps**              | 1. Proceed to checkout <br> 2. Select **Standard** shipping <br> 3. Read the shipping fee line |
| **Expected**           | Shipping fee reads `Free`. No $5.99 charge appears anywhere in the order summary.          |
| **data-testid needed** | `member-badge`, `shipping-option-standard`, `shipping-fee`, `order-total`                  |
| **Source**             | AC-2                                                                                      |
| **Note**               | Assumption A2 (member definition). A low subtotal is chosen so the free result can only come from membership, not the threshold. |

---

## TC-SHIP-007: Give a member free standard shipping above the threshold

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                   |
| **Issue**              | SHIP-9                                                                                    |
| **Automation Score**   | HIGH (56/67.5)                                                                            |
| **ISTQB Technique**    | Decision Table — R4 (member, at or above threshold, standard)                             |
| **Manual Env**         | Local, Staging                                                                            |
| **Precondition**       | Shopper is signed in with an active membership. Cart subtotal is $80.00.                  |
| **Steps**              | 1. Proceed to checkout <br> 2. Select **Standard** shipping <br> 3. Read the shipping fee line |
| **Expected**           | Shipping fee reads `Free`.                                                                |
| **data-testid needed** | `member-badge`, `shipping-fee`                                                            |
| **Source**             | AC-2                                                                                      |
| **Note**               | Confirms the two free rules do not conflict when both apply.                             |

---

## TC-SHIP-008: Charge a guest $12.99 for express below the threshold

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                  |
| **Issue**              | SHIP-9                                                                                    |
| **Automation Score**   | HIGH (61/67.5)                                                                            |
| **ISTQB Technique**    | Decision Table — R5 (non-member, below threshold, express)                                |
| **Manual Env**         | Local, Staging                                                                            |
| **Precondition**       | Shopper is not signed in. Cart subtotal is $35.00.                                        |
| **Steps**              | 1. Proceed to checkout <br> 2. Select **Express** shipping <br> 3. Read the shipping fee line |
| **Expected**           | Shipping fee reads `$12.99`. Order total includes the $12.99.                             |
| **data-testid needed** | `shipping-option-express`, `shipping-fee`, `order-total`                                  |
| **Source**             | AC-3                                                                                      |
| **Note**               | N/A — no caveats                                                                          |

---

## TC-SHIP-009: Still charge a guest $12.99 for express above the threshold

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                   |
| **Issue**              | SHIP-9                                                                                    |
| **Automation Score**   | HIGH (59/67.5)                                                                            |
| **ISTQB Technique**    | Decision Table — R6 (non-member, at or above threshold, express)                          |
| **Manual Env**         | Local, Staging                                                                            |
| **Precondition**       | Shopper is not signed in. Cart subtotal is $120.00.                                       |
| **Steps**              | 1. Proceed to checkout <br> 2. Select **Express** shipping <br> 3. Read the shipping fee line |
| **Expected**           | Shipping fee reads `$12.99`. The $50.00 free-shipping threshold does not apply to express. |
| **data-testid needed** | `shipping-option-express`, `shipping-fee`                                                 |
| **Source**             | AC-3                                                                                      |
| **Note**               | Guards against the threshold being applied to every method instead of standard only.     |

---

## TC-SHIP-010: Charge a member $7.99 for express at any subtotal

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                  |
| **Issue**              | SHIP-9                                                                                    |
| **Automation Score**   | HIGH (57/67.5)                                                                            |
| **ISTQB Technique**    | Decision Table — R7 and R8 (member, express, both subtotal partitions)                    |
| **Manual Env**         | Local, Staging                                                                            |
| **Precondition**       | Shopper is signed in with an active membership. Cart subtotal is $12.00.                  |
| **Steps**              | 1. Proceed to checkout <br> 2. Select **Express** shipping <br> 3. Read the shipping fee line <br> 4. Return to cart and add items so the subtotal is $120.00 <br> 5. Return to checkout with **Express** still selected and read the fee |
| **Expected**           | Step 3: fee reads `$7.99`. Step 5: fee still reads `$7.99`. Membership does not make express free. |
| **data-testid needed** | `member-badge`, `shipping-option-express`, `shipping-fee`                                 |
| **Source**             | AC-3                                                                                      |
| **Note**               | Assumption A2. Also guards against AC-2 being over-applied so that members get express free. |

---

## TC-SHIP-011: Update the fee when switching between standard and express

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                   |
| **Issue**              | SHIP-9                                                                                    |
| **Automation Score**   | HIGH (55/67.5)                                                                            |
| **ISTQB Technique**    | State Transition — Standard→Express→Standard with a fixed subtotal (0-switch coverage)    |
| **Manual Env**         | Local, Staging                                                                            |
| **Precondition**       | Shopper is not signed in. Cart subtotal is $35.00. Checkout page is open with **Standard** selected. |
| **Steps**              | 1. Read the fee <br> 2. Select **Express** and read the fee and order total <br> 3. Select **Standard** again and read the fee and order total |
| **Expected**           | Step 1: `$5.99`. Step 2: `$12.99`, order total rises by $7.00. Step 3: `$5.99`, order total returns to its step 1 value. No stale fee remains after either switch. |
| **data-testid needed** | `shipping-option-standard`, `shipping-option-express`, `shipping-fee`, `order-total`       |
| **Source**             | Added by QA (the ticket is silent on changing method after the fee is first shown)       |
| **Note**               | Targets stale-state bugs where the fee is computed once on page load.                   |

---

## TC-SHIP-012: Recalculate the fee when a cart edit crosses the threshold

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                   |
| **Issue**              | SHIP-9                                                                                    |
| **Automation Score**   | MEDIUM (50/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — subtotal crosses $50.00 downward then upward; Error Guessing — stale fee |
| **Manual Env**         | Local, Staging                                                                            |
| **Precondition**       | Shopper is not signed in. Cart holds two items: $30.00 and $25.00 (subtotal $55.00). Checkout is open with **Standard** selected and fee showing `Free`. |
| **Steps**              | 1. Remove the $25.00 item from checkout (or return to cart, remove it, return to checkout) <br> 2. Read subtotal and fee <br> 3. Add the $25.00 item back <br> 4. Read subtotal and fee |
| **Expected**           | Step 2: subtotal `$30.00`, fee `$5.99`. Step 4: subtotal `$55.00`, fee `Free`. Order total is consistent with each fee. |
| **data-testid needed** | `checkout-subtotal`, `shipping-fee`, `order-total`, `cart-remove-item`                    |
| **Source**             | Added by QA (the ticket is silent on cart changes after checkout is opened)               |
| **Note**               | If the checkout page cannot edit the cart, run via the cart page; the assertion is the same. |

---

## TC-SHIP-013: Evaluate the threshold on the subtotal after a discount code

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                   |
| **Issue**              | SHIP-9                                                                                    |
| **Automation Score**   | MEDIUM (46/67.5)                                                                          |
| **ISTQB Technique**    | Error Guessing — which amount the threshold is compared against                           |
| **Manual Env**         | Local, Staging                                                                            |
| **Precondition**       | Shopper is not signed in. Cart item subtotal is $55.00. A valid discount code worth $10.00 off exists. |
| **Steps**              | 1. Proceed to checkout with **Standard** selected and read the fee <br> 2. Apply the $10.00 discount code <br> 3. Read subtotal and fee |
| **Expected**           | Step 1: `Free`. Step 3: subtotal `$45.00`, fee `$5.99` (per assumption A1, the post-discount amount is the subtotal). |
| **data-testid needed** | `discount-code-input`, `discount-apply`, `checkout-subtotal`, `shipping-fee`              |
| **Source**             | Added by QA (the ticket does not define "order subtotal")                                 |
| **Note**               | **Assumption A1 is unverified and business-critical.** If the product owner rules that the pre-discount amount counts, the step 3 expectation becomes `Free`. Confirm before marking a failure as a defect. If no discount feature exists, record this case as blocked, not dropped. |

---

## TC-SHIP-014: Exclude tax from the threshold comparison

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                   |
| **Issue**              | SHIP-9                                                                                    |
| **Automation Score**   | MEDIUM (46/67.5)                                                                          |
| **ISTQB Technique**    | Error Guessing — total used in place of subtotal                                          |
| **Manual Env**         | Staging (needs a taxable address)                                                         |
| **Precondition**       | Shopper is not signed in. Cart subtotal is $47.00. A shipping address in a taxed region is entered so that subtotal plus tax exceeds $50.00. |
| **Steps**              | 1. Proceed to checkout <br> 2. Enter the taxable address <br> 3. Select **Standard** and read subtotal, tax and fee |
| **Expected**           | Subtotal `$47.00`. Fee `$5.99`. Tax is shown separately and does not push the order into free shipping. |
| **data-testid needed** | `checkout-subtotal`, `checkout-tax`, `shipping-fee`                                       |
| **Source**             | Added by QA (the ticket does not define "order subtotal")                                 |
| **Note**               | Assumption A1. If tax is not computed at checkout in this product, record as not applicable with that reason. |

---

## TC-SHIP-015: Sum cent-priced items to exactly $50.00 without rounding error

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @ship @candidate`                                                   |
| **Issue**              | SHIP-9                                                                                    |
| **Automation Score**   | HIGH (54/67.5)                                                                            |
| **ISTQB Technique**    | Error Guessing — floating-point accumulation at the boundary                              |
| **Manual Env**         | Local, Staging                                                                            |
| **Precondition**       | Shopper is not signed in. Cart holds three items priced $10.10, $20.20 and $19.70 (sum $50.00). |
| **Steps**              | 1. Proceed to checkout <br> 2. Select **Standard** <br> 3. Read subtotal and fee           |
| **Expected**           | Subtotal reads `$50.00`. Fee reads `Free`. A float sum of 49.999999… must not produce `$5.99`. |
| **data-testid needed** | `checkout-subtotal`, `shipping-fee`                                                       |
| **Source**             | Added by QA (the ticket is silent on how money is summed)                                 |
| **Note**               | Strong unit-test candidate as well; recommend the fee calculator takes integer cents.    |

---

## TC-SHIP-016: Apply member rates when the shopper signs in during checkout

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @ship @candidate`                                                   |
| **Issue**              | SHIP-9                                                                                    |
| **Automation Score**   | MEDIUM (44/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — Guest→Member while checkout is open                                    |
| **Manual Env**         | Local, Staging                                                                            |
| **Precondition**       | Shopper is not signed in. Cart subtotal is $35.00. Checkout is open with **Express** selected showing `$12.99`. Credentials for an active member exist. |
| **Steps**              | 1. Sign in from the checkout page (or header) as the member <br> 2. Return to checkout with the same cart <br> 3. Read the express fee <br> 4. Select **Standard** and read the fee |
| **Expected**           | Step 3: `$7.99`. Step 4: `Free`. The cart is preserved across sign-in.                    |
| **data-testid needed** | `sign-in-submit`, `member-badge`, `shipping-fee`, `shipping-option-standard`               |
| **Source**             | Added by QA (the ticket is silent on membership changing mid-checkout)                    |
| **Note**               | If sign-in resets the cart, that is a separate defect; still record the fee result for the re-added cart. |

---

## TC-SHIP-017: Treat a lapsed membership as non-member

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @ship @manual-only`                                                 |
| **Issue**              | SHIP-9                                                                                    |
| **Automation Score**   | LOW (33/67.5)                                                                             |
| **ISTQB Technique**    | EP — invalid partition of "member" (signed in, membership expired)                        |
| **Manual Env**         | Staging (needs an account with an expired membership)                                     |
| **Precondition**       | Shopper is signed in to an account whose membership expired before today. Cart subtotal is $35.00. |
| **Steps**              | 1. Proceed to checkout <br> 2. Select **Standard** and read the fee <br> 3. Select **Express** and read the fee |
| **Expected**           | Step 2: `$5.99`. Step 3: `$12.99`. No member pricing is applied.                           |
| **data-testid needed** | `shipping-fee`, `shipping-option-standard`, `shipping-option-express`                     |
| **Source**             | Added by QA (the ticket does not say whether "member" means an active membership)         |
| **Note**               | Assumption A2. Kept manual because seeding an expired membership depends on account tooling not yet known; promote to `@candidate` once a fixture exists. |

---

## Coverage summary

| Source | Cases |
| ------ | ----- |
| AC-1   | TC-SHIP-001, 002, 003, 004, 005 |
| AC-2   | TC-SHIP-006, 007 |
| AC-3   | TC-SHIP-008, 009, 010 |
| Added by QA | TC-SHIP-011 to 017 |

Decision table coverage: 8 of 8 rules. BVA coverage on the $50.00 threshold: $49.99, $50.00, $50.01.

## Rules not applied

The `context-discovery` and `testing-guidelines` rules were not in context and no `qa-rules` skill is installed, so they were applied from the summary in this command only. The repository is empty, so no `Precondition` or `Expected` could be verified against code; assumptions A1 to A7 above record what needs confirmation.
