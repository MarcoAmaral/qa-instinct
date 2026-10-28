---
feature: Shipping fee at checkout
feature_code: SHIP
tc_count: 12
tracker_issues: [SHIP-9]
risk_level: MEDIUM
runbook: N/A — no runbook requested for this story
implementation_pack: N/A — no implementation pack exists
spec: N/A — not automated yet
last_updated: 2026-10-24
---

# Test Cases — Shipping fee at checkout

| Field            | Value                                                   |
| ---------------- | ------------------------------------------------------- |
| **Project**      | [Project name] — not stated in the story                |
| **Author**       | Marco — Senior QA Analyst                               |
| **Date Created** | 2026-10-24                                              |
| **Last Updated** | 2026-10-24                                              |
| **Methodology**  | ISTQB CTFL v4.0 — Decision Table, BVA, EP, Error Guessing |

## Scope and assumptions

The working repository is empty, so no `Precondition` or `Expected` below is grounded in code. Every assumption is listed here and repeated in the case it affects.

- **A1 — Tracker.** `SHIP-9` matches the Linear and Jira formats; the base URL is unknown, so the ID is plain text.
- **A2 — Subtotal.** "Order subtotal" is the sum of line items after item-level discounts and after any order-level coupon, before shipping and tax, and equals the **Subtotal** line shown at checkout. The story does not say whether a coupon counts; TC-SHIP-011 tests this assumption and must be re-checked with the Product Owner.
- **A3 — Member.** A member is a signed-in account with an active membership. Guests and signed-in non-members are non-members. A lapsed membership counts as non-member (TC-SHIP-010).
- **A4 — Display.** The fee appears as a **Shipping** line in the order summary. A zero fee is shown as `Free`. Paid fees are shown as `$5.99`, `$7.99`, `$12.99`. The **Total** line equals subtotal plus shipping (tax ignored in these cases).
- **A5 — Methods.** Exactly two methods exist, Standard and Express, chosen by a radio control at checkout; Standard is pre-selected.
- **A6 — Boundary.** "$50.00 or more" is inclusive: $50.00 is free, $49.99 is paid. Prices carry two decimals, so the two-value BVA pair is $49.99 and $50.00.

### Decision table (AC-1, AC-2, AC-3)

| Condition                 | R1  | R2  | R3  | R4  | R5  |
| ------------------------- | --- | --- | --- | --- | --- |
| member                    | F   | F   | T   | F   | T   |
| method = Express          | F   | F   | F   | T   | T   |
| subtotal ≥ $50.00         | F   | T   | –   | –   | –   |
| **Actions**               |     |     |     |     |     |
| Fee $5.99                 | X   |     |     |     |     |
| Fee Free                  |     | X   | X   |     |     |
| Fee $12.99                |     |     |     | X   |     |
| Fee $7.99                 |     |     |     |     | X   |

Release gate: TC-SHIP-001, 002, 004, 005, 006 (one case per decision-table column, tagged `@gate`).

---

## TC-SHIP-001: Non-member pays $5.99 for Standard at $49.99

| Field                  | Value                                                                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                           |
| **Issue**              | SHIP-9                                                                                                                                             |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                                     |
| **ISTQB Technique**    | Decision Table — R1; BVA — $49.99 (max of the paid partition)                                                                                      |
| **Manual Env**         | Local, Staging                                                                                                                                     |
| **Precondition**       | Signed in as a non-member (A3). Cart contains items whose subtotal is exactly $49.99. No coupon applied.                                           |
| **Steps**              | 1. Open checkout <br> 2. Confirm **Standard** is selected <br> 3. Read the **Subtotal**, **Shipping** and **Total** lines                            |
| **Expected**           | Subtotal shows `$49.99`. Shipping shows `$5.99`. Total shows `$55.98`.                                                                             |
| **data-testid needed** | `shipping-option-standard`, `order-subtotal`, `shipping-fee`, `order-total`                                                                        |
| **Source**             | AC-1                                                                                                                                               |
| **Note**               | Assumption A6: threshold is inclusive at $50.00, so $49.99 is the last paid value.                                                                 |

---

## TC-SHIP-002: Non-member gets free Standard at exactly $50.00

| Field                  | Value                                                                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                           |
| **Issue**              | SHIP-9                                                                                                                                             |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                                     |
| **ISTQB Technique**    | Decision Table — R2; BVA — $50.00 (min of the free partition)                                                                                      |
| **Manual Env**         | Local, Staging                                                                                                                                     |
| **Precondition**       | Signed in as a non-member (A3). Cart subtotal is exactly $50.00. No coupon applied.                                                                |
| **Steps**              | 1. Open checkout <br> 2. Confirm **Standard** is selected <br> 3. Read the **Shipping** and **Total** lines                                         |
| **Expected**           | Shipping shows `Free`. Total shows `$50.00`.                                                                                                       |
| **data-testid needed** | `shipping-option-standard`, `shipping-fee`, `order-total`                                                                                          |
| **Source**             | AC-1                                                                                                                                               |
| **Note**               | A `>` instead of `>=` in the threshold check fails exactly here. Assumption A4: zero fee renders as `Free`.                                         |

---

## TC-SHIP-003: Standard fee is correct one cent either side of the threshold

| Field                  | Value                                                                                                                                                                |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                              |
| **Issue**              | SHIP-9                                                                                                                                                               |
| **Automation Score**   | HIGH (57/67.5)                                                                                                                                                       |
| **ISTQB Technique**    | BVA — three-value neighbours $49.98 (max-1) and $50.01 (min+1)                                                                                                       |
| **Manual Env**         | Local, Staging                                                                                                                                                       |
| **Precondition**       | Signed in as a non-member (A3). Standard selected. Two carts prepared: subtotal $49.98 and subtotal $50.01.                                                          |
| **Steps**              | 1. Open checkout with the $49.98 cart and read **Shipping** <br> 2. Open checkout with the $50.01 cart and read **Shipping**                                          |
| **Expected**           | Step 1: Shipping shows `$5.99`. Step 2: Shipping shows `Free`.                                                                                                       |
| **data-testid needed** | `shipping-fee`                                                                                                                                                       |
| **Source**             | AC-1                                                                                                                                                                 |
| **Note**               | Catches a comparison done on a rounded or integer dollar value (for example `Math.round(subtotal) >= 50`, which would make $49.98 free).                             |

---

## TC-SHIP-004: Member gets free Standard below the threshold

| Field                  | Value                                                                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                           |
| **Issue**              | SHIP-9                                                                                                                                             |
| **Automation Score**   | HIGH (59/67.5)                                                                                                                                     |
| **ISTQB Technique**    | Decision Table — R3; EP — valid partition (member, subtotal below $50.00)                                                                          |
| **Manual Env**         | Local, Staging                                                                                                                                     |
| **Precondition**       | Signed in as a member with an active membership (A3). Cart subtotal is $10.00. No coupon applied.                                                  |
| **Steps**              | 1. Open checkout <br> 2. Confirm **Standard** is selected <br> 3. Read the **Shipping** and **Total** lines                                         |
| **Expected**           | Shipping shows `Free`. Total shows `$10.00`.                                                                                                       |
| **data-testid needed** | `shipping-option-standard`, `shipping-fee`, `order-total`                                                                                          |
| **Source**             | AC-2                                                                                                                                               |
| **Note**               | The member rule must win over the AC-1 threshold; this is the case that proves it.                                                                 |

---

## TC-SHIP-005: Member pays $7.99 for Express

| Field                  | Value                                                                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                           |
| **Issue**              | SHIP-9                                                                                                                                             |
| **Automation Score**   | HIGH (59/67.5)                                                                                                                                     |
| **ISTQB Technique**    | Decision Table — R5                                                                                                                                |
| **Manual Env**         | Local, Staging                                                                                                                                     |
| **Precondition**       | Signed in as a member (A3). Cart subtotal is $10.00.                                                                                               |
| **Steps**              | 1. Open checkout <br> 2. Select **Express** <br> 3. Read the **Shipping** and **Total** lines                                                       |
| **Expected**           | Shipping shows `$7.99`. Total shows `$17.99`.                                                                                                      |
| **data-testid needed** | `shipping-option-express`, `shipping-fee`, `order-total`                                                                                           |
| **Source**             | AC-3                                                                                                                                               |
| **Note**               | Guards against the member free-shipping rule (AC-2) leaking into Express and making it `Free`.                                                     |

---

## TC-SHIP-006: Non-member pays $12.99 for Express

| Field                  | Value                                                                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                           |
| **Issue**              | SHIP-9                                                                                                                                             |
| **Automation Score**   | HIGH (59/67.5)                                                                                                                                     |
| **ISTQB Technique**    | Decision Table — R4                                                                                                                                |
| **Manual Env**         | Local, Staging                                                                                                                                     |
| **Precondition**       | Signed in as a non-member (A3). Cart subtotal is $10.00.                                                                                           |
| **Steps**              | 1. Open checkout <br> 2. Select **Express** <br> 3. Read the **Shipping** and **Total** lines                                                       |
| **Expected**           | Shipping shows `$12.99`. Total shows `$22.99`.                                                                                                     |
| **data-testid needed** | `shipping-option-express`, `shipping-fee`, `order-total`                                                                                           |
| **Source**             | AC-3                                                                                                                                               |
| **Note**               | N/A — no caveats                                                                                                                                   |

---

## TC-SHIP-007: Express stays paid at and above the $50.00 threshold

| Field                  | Value                                                                                                                                                                      |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                                    |
| **Issue**              | SHIP-9                                                                                                                                                                     |
| **Automation Score**   | HIGH (55/67.5)                                                                                                                                                             |
| **ISTQB Technique**    | Decision Table — R4 and R5 with subtotal ≥ $50.00 (the `–` condition); BVA — $50.00                                                                                         |
| **Manual Env**         | Local, Staging                                                                                                                                                             |
| **Precondition**       | Two accounts: one non-member, one member (A3). Each has a cart with subtotal exactly $50.00.                                                                                |
| **Steps**              | 1. As the non-member, open checkout, select **Express**, read **Shipping** <br> 2. As the member, open checkout, select **Express**, read **Shipping**                       |
| **Expected**           | Step 1: Shipping shows `$12.99`. Step 2: Shipping shows `$7.99`. Neither shows `Free`.                                                                                     |
| **data-testid needed** | `shipping-option-express`, `shipping-fee`                                                                                                                                  |
| **Source**             | AC-3                                                                                                                                                                       |
| **Note**               | The AC-1 free threshold applies to Standard only. A shared "free over $50" flag applied before the method check would fail here.                                            |

---

## TC-SHIP-008: Switching method updates the fee and total without reload

| Field                  | Value                                                                                                                                                                                                 |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                                                               |
| **Issue**              | SHIP-9                                                                                                                                                                                                |
| **Automation Score**   | HIGH (54/67.5)                                                                                                                                                                                        |
| **ISTQB Technique**    | State Transition — Standard → Express → Standard (0-switch coverage of both valid transitions)                                                                                                         |
| **Manual Env**         | Local, Staging                                                                                                                                                                                        |
| **Precondition**       | Signed in as a non-member (A3). Cart subtotal is $30.00. Checkout open with **Standard** selected and Shipping showing `$5.99`.                                                                        |
| **Steps**              | 1. Select **Express** <br> 2. Read **Shipping** and **Total** <br> 3. Select **Standard** <br> 4. Read **Shipping** and **Total**                                                                        |
| **Expected**           | Step 2: Shipping `$12.99`, Total `$42.99`. Step 4: Shipping `$5.99`, Total `$35.99`. The page does not reload and no stale value is shown between selections.                                          |
| **data-testid needed** | `shipping-option-standard`, `shipping-option-express`, `shipping-fee`, `order-total`                                                                                                                  |
| **Source**             | Added by QA (the story says the shopper should "see the right fee" but no AC covers changing the method at checkout)                                                                                   |
| **Note**               | Assumption A5: method is chosen by a radio control at checkout.                                                                                                                                       |

---

## TC-SHIP-009: Changing cart quantity across the threshold recalculates Standard fee

| Field                  | Value                                                                                                                                                                                                            |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                                                                          |
| **Issue**              | SHIP-9                                                                                                                                                                                                           |
| **Automation Score**   | MEDIUM (49/67.5)                                                                                                                                                                                                 |
| **ISTQB Technique**    | Error Guessing — stale fee after subtotal changes (crosses the boundary in both directions)                                                                                                                       |
| **Manual Env**         | Local, Staging                                                                                                                                                                                                   |
| **Precondition**       | Signed in as a non-member (A3). Cart holds one item priced $30.00. Checkout open, **Standard** selected, Shipping shows `$5.99`.                                                                                  |
| **Steps**              | 1. Increase the item quantity to 2 (subtotal $60.00) from the checkout or cart and return to checkout <br> 2. Read **Shipping** <br> 3. Decrease the quantity back to 1 <br> 4. Read **Shipping**                   |
| **Expected**           | Step 2: Shipping shows `Free`, Total `$60.00`. Step 4: Shipping shows `$5.99`, Total `$35.99`.                                                                                                                    |
| **data-testid needed** | `cart-item-quantity`, `shipping-fee`, `order-total`                                                                                                                                                              |
| **Source**             | Added by QA (the ticket is silent on the subtotal changing after the fee was first shown)                                                                                                                         |
| **Note**               | If quantity cannot be edited from checkout, perform steps 1 and 3 in the cart and re-open checkout; record which path was used.                                                                                   |

---

## TC-SHIP-010: Guest and lapsed-membership shoppers are charged as non-members

| Field                  | Value                                                                                                                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                                                                 |
| **Issue**              | SHIP-9                                                                                                                                                                                                  |
| **Automation Score**   | MEDIUM (46/67.5)                                                                                                                                                                                        |
| **ISTQB Technique**    | EP — invalid partitions of "member": guest (no account) and expired membership                                                                                                                          |
| **Manual Env**         | Local, Staging                                                                                                                                                                                          |
| **Precondition**       | Two sessions: a guest with no sign-in, and an account whose membership expired yesterday (A3). Each cart subtotal is $10.00.                                                                            |
| **Steps**              | 1. As guest, open checkout with **Standard** and read **Shipping** <br> 2. As guest, select **Express** and read **Shipping** <br> 3. Repeat steps 1 and 2 as the lapsed member                           |
| **Expected**           | Every Standard reading shows `$5.99`. Every Express reading shows `$12.99`. No member price appears.                                                                                                     |
| **data-testid needed** | `shipping-option-standard`, `shipping-option-express`, `shipping-fee`                                                                                                                                   |
| **Source**             | Added by QA (the ticket defines member pricing but not who counts as a member)                                                                                                                           |
| **Note**               | Assumption A3. If guest checkout does not exist, mark the guest steps `N/A — guest checkout not offered` and run only the lapsed-member steps.                                                           |

---

## TC-SHIP-011: Coupon that drops the subtotal below $50.00 removes free Standard

| Field                  | Value                                                                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @ship @manual-only`                                                                                                                                                              |
| **Issue**              | SHIP-9                                                                                                                                                                                                 |
| **Automation Score**   | LOW (33/67.5)                                                                                                                                                                                          |
| **ISTQB Technique**    | Error Guessing — threshold evaluated against the wrong subtotal (pre-discount vs post-discount)                                                                                                        |
| **Manual Env**         | Staging                                                                                                                                                                                                |
| **Precondition**       | Signed in as a non-member (A3). Cart subtotal is $55.00. A valid $10.00 order-level coupon exists. Checkout open, **Standard** selected, Shipping shows `Free`.                                         |
| **Steps**              | 1. Apply the $10.00 coupon <br> 2. Read **Subtotal**, **Shipping** and **Total**                                                                                                                         |
| **Expected**           | Subtotal shows `$45.00`. Shipping shows `$5.99`. Total shows `$50.99`.                                                                                                                                 |
| **data-testid needed** | `coupon-input`, `coupon-apply`, `order-subtotal`, `shipping-fee`, `order-total`                                                                                                                        |
| **Source**             | Added by QA (the ticket does not say whether "subtotal" is before or after an order-level coupon)                                                                                                        |
| **Note**               | Expected follows assumption A2. If the Product Owner rules that the threshold uses the pre-coupon subtotal, correct this case in place with a dated note; do not delete it. Kept manual until decided.    |

---

## TC-SHIP-012: Fee shown at checkout matches the fee charged on the placed order

| Field                  | Value                                                                                                                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p1 @e2e @ship @candidate`                                                                                                                                                                |
| **Issue**              | SHIP-9                                                                                                                                                                                             |
| **Automation Score**   | MEDIUM (44/67.5)                                                                                                                                                                                   |
| **ISTQB Technique**    | Error Guessing — client-displayed fee diverging from the server-calculated fee                                                                                                                     |
| **Manual Env**         | Staging                                                                                                                                                                                            |
| **Precondition**       | Signed in as a member (A3). Cart subtotal is $20.00. A test payment method is available.                                                                                                           |
| **Steps**              | 1. Open checkout and select **Express** <br> 2. Note **Shipping** (`$7.99`) and **Total** (`$27.99`) <br> 3. Place the order <br> 4. Open the order confirmation page and the order in the account's order history |
| **Expected**           | Both the confirmation page and the order history show Shipping `$7.99` and Total `$27.99`, identical to step 2.                                                                                    |
| **data-testid needed** | `shipping-fee`, `order-total`, `place-order`, `order-confirmation-shipping`, `order-confirmation-total`                                                                                            |
| **Source**             | Added by QA (the story's goal is "so that I know what I will pay"; no AC checks that the shown fee is the fee charged)                                                                              |
| **Note**               | If the fee is computed only in the browser, this is the case that exposes it. Requires a sandbox payment; not suitable for the smoke suite.                                                        |

---

## Rules not applied

The `context-discovery` and `testing-guidelines` rules are not loaded in this session and no `qa-rules` skill is installed, so they could not be read. In their place: the repository was searched and is empty, so no case is grounded in code, and the tag taxonomy used is the one restated in the `qa-cases` command.
