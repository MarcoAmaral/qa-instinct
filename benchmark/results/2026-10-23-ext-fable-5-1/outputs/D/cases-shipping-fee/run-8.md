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

| Field            | Value                                                    |
| ---------------- | -------------------------------------------------------- |
| **Project**      | Checkout (SHIP-9)                                        |
| **Author**       | Marco — Senior QA Analyst                                |
| **Date Created** | 2026-10-24                                               |
| **Last Updated** | 2026-10-24                                               |
| **Methodology**  | ISTQB CTFL v4.0 — EP, BVA (three-value), Decision Table, Error Guessing |

## Context and assumptions

The working directory holds no source code, so no precondition or expected value below was verified against an implementation. Every case rests on the story text plus the assumptions listed here. Each assumption is tagged in the **Note** row of the cases that depend on it.

- **A1 — Subtotal definition.** "Order subtotal" is the sum of line items before shipping, tax and discounts. If discounts apply before the threshold check, TC-SHIP-012 must be re-read.
- **A2 — Threshold comparison.** "$50.00 or more" means `subtotal >= 50.00`. The three-value BVA cases use $49.99, $50.00 and $50.01.
- **A3 — Member status.** "Member" is a flag on the signed-in account. A guest or a signed-in non-member shopper is a non-member. The story says nothing about how membership is bought or expires.
- **A4 — Fee display.** The checkout page shows a shipping method selector with the fee next to each method, and the order summary shows a shipping line. Free shipping displays as `$0.00` (or "Free"); the case asserts the amount, not the wording.
- **A5 — Default method.** Standard shipping is selected by default when checkout loads.
- **A6 — Currency and tracker.** Amounts are US dollars. The tracker is Jira-style (`SHIP-9`); no base URL was given, so the ID is plain text.
- **A7 — Express threshold.** AC-3 gives express no subtotal threshold. Express costs the same at $49.99 and $50.00 for both shopper types.

**Decision table used for AC-1 to AC-3** (conditions: member?, method, subtotal ≥ $50.00):

| Rule | Member | Method   | Subtotal ≥ 50 | Fee    | Case        |
| ---- | ------ | -------- | ------------- | ------ | ----------- |
| R1   | No     | Standard | No            | $5.99  | TC-SHIP-001 |
| R2   | No     | Standard | Yes           | $0.00  | TC-SHIP-002 |
| R3   | Yes    | Standard | No            | $0.00  | TC-SHIP-005 |
| R4   | Yes    | Standard | Yes           | $0.00  | TC-SHIP-006 |
| R5   | No     | Express  | No            | $12.99 | TC-SHIP-007 |
| R6   | No     | Express  | Yes           | $12.99 | TC-SHIP-008 |
| R7   | Yes    | Express  | No            | $7.99  | TC-SHIP-009 |
| R8   | Yes    | Express  | Yes           | $7.99  | TC-SHIP-010 |

**Release gate (`@gate`):** TC-SHIP-001, 002, 003, 005, 007, 009. These six cover every distinct fee value and the threshold boundary. The remaining cases stay in the document as regression and error-guessing coverage.

---

## TC-SHIP-001: Non-member pays $5.99 standard shipping below the threshold

| Field                  | Value                                                                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                |
| **Issue**              | SHIP-9                                                                                                                                  |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                          |
| **ISTQB Technique**    | Decision Table — R1 (non-member, standard, subtotal < $50.00)                                                                           |
| **Manual Env**         | Local, Staging                                                                                                                          |
| **Precondition**       | Signed in as a non-member account (or guest). Cart contains items with a subtotal of $25.00. Standard shipping is the selected method. |
| **Steps**              | 1. Open the checkout page <br> 2. Read the fee shown next to **Standard** shipping <br> 3. Read the **Shipping** line in the order summary |
| **Expected**           | Standard shipping shows `$5.99`. The order summary **Shipping** line shows `$5.99`. Order total equals subtotal + $5.99 (+ tax if any).  |
| **data-testid needed** | `shipping-option-standard-fee`, `order-summary-shipping`, `order-summary-total`                                                        |
| **Source**             | AC-1                                                                                                                                    |
| **Note**               | Depends on A1, A3, A4, A5.                                                                                                              |

---

## TC-SHIP-002: Non-member gets free standard shipping at $50.00 (lower boundary)

| Field                  | Value                                                                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                              |
| **Issue**              | SHIP-9                                                                                                                                |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                        |
| **ISTQB Technique**    | BVA — three-value, boundary $50.00 (min of the free partition); also Decision Table R2                                                |
| **Manual Env**         | Local, Staging                                                                                                                        |
| **Precondition**       | Signed in as a non-member account. Cart subtotal is exactly $50.00. Standard shipping is the selected method.                         |
| **Steps**              | 1. Open the checkout page <br> 2. Read the fee shown next to **Standard** shipping <br> 3. Read the **Shipping** line in the order summary |
| **Expected**           | Standard shipping shows `$0.00` (or "Free"). The **Shipping** line shows `$0.00`. Order total equals subtotal (+ tax if any).          |
| **data-testid needed** | `shipping-option-standard-fee`, `order-summary-shipping`, `order-summary-total`                                                      |
| **Source**             | AC-1                                                                                                                                  |
| **Note**               | Depends on A2 ("or more" means `>=`). If the implementation uses `>`, this case fails and AC-1 is misread by the code, not by QA.      |

---

## TC-SHIP-003: Non-member pays $5.99 standard shipping at $49.99 (boundary minus one cent)

| Field                  | Value                                                                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                              |
| **Issue**              | SHIP-9                                                                                                                                |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                        |
| **ISTQB Technique**    | BVA — three-value, $49.99 (max of the paid partition)                                                                                 |
| **Manual Env**         | Local, Staging                                                                                                                        |
| **Precondition**       | Signed in as a non-member account. Cart subtotal is exactly $49.99. Standard shipping is the selected method.                         |
| **Steps**              | 1. Open the checkout page <br> 2. Read the fee shown next to **Standard** shipping <br> 3. Read the **Shipping** line in the order summary |
| **Expected**           | Standard shipping shows `$5.99`. The **Shipping** line shows `$5.99`.                                                                 |
| **data-testid needed** | `shipping-option-standard-fee`, `order-summary-shipping`                                                                              |
| **Source**             | AC-1                                                                                                                                  |
| **Note**               | Depends on A2. Catches a floating-point threshold bug where 49.99 rounds up to 50.                                                    |

---

## TC-SHIP-004: Non-member gets free standard shipping at $50.01 (boundary plus one cent)

| Field                  | Value                                                                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                               |
| **Issue**              | SHIP-9                                                                                                                                |
| **Automation Score**   | HIGH (58/67.5)                                                                                                                        |
| **ISTQB Technique**    | BVA — three-value, $50.01 (min + 1 of the free partition)                                                                             |
| **Manual Env**         | Local, Staging                                                                                                                        |
| **Precondition**       | Signed in as a non-member account. Cart subtotal is exactly $50.01. Standard shipping is the selected method.                         |
| **Steps**              | 1. Open the checkout page <br> 2. Read the fee shown next to **Standard** shipping <br> 3. Read the **Shipping** line in the order summary |
| **Expected**           | Standard shipping shows `$0.00` (or "Free"). The **Shipping** line shows `$0.00`.                                                     |
| **data-testid needed** | `shipping-option-standard-fee`, `order-summary-shipping`                                                                              |
| **Source**             | AC-1                                                                                                                                  |
| **Note**               | Depends on A2. Completes the three-value boundary set with TC-SHIP-002 and TC-SHIP-003.                                               |

---

## TC-SHIP-005: Member gets free standard shipping below the threshold

| Field                  | Value                                                                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                              |
| **Issue**              | SHIP-9                                                                                                                                |
| **Automation Score**   | HIGH (59/67.5)                                                                                                                        |
| **ISTQB Technique**    | Decision Table — R3 (member, standard, subtotal < $50.00)                                                                             |
| **Manual Env**         | Local, Staging                                                                                                                        |
| **Precondition**       | Signed in as a member account. Cart subtotal is $25.00. Standard shipping is the selected method.                                     |
| **Steps**              | 1. Open the checkout page <br> 2. Read the fee shown next to **Standard** shipping <br> 3. Read the **Shipping** line in the order summary |
| **Expected**           | Standard shipping shows `$0.00` (or "Free"). The **Shipping** line shows `$0.00`. Order total equals subtotal (+ tax if any).          |
| **data-testid needed** | `shipping-option-standard-fee`, `order-summary-shipping`, `order-summary-total`                                                      |
| **Source**             | AC-2                                                                                                                                  |
| **Note**               | Depends on A3. This is the case that proves membership overrides the AC-1 threshold.                                                  |

---

## TC-SHIP-006: Member gets free standard shipping at or above the threshold

| Field                  | Value                                                                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                               |
| **Issue**              | SHIP-9                                                                                                                                |
| **Automation Score**   | HIGH (56/67.5)                                                                                                                        |
| **ISTQB Technique**    | Decision Table — R4 (member, standard, subtotal ≥ $50.00)                                                                             |
| **Manual Env**         | Local, Staging                                                                                                                        |
| **Precondition**       | Signed in as a member account. Cart subtotal is $120.00. Standard shipping is the selected method.                                    |
| **Steps**              | 1. Open the checkout page <br> 2. Read the fee shown next to **Standard** shipping <br> 3. Read the **Shipping** line in the order summary |
| **Expected**           | Standard shipping shows `$0.00` (or "Free"). The **Shipping** line shows `$0.00`.                                                     |
| **data-testid needed** | `shipping-option-standard-fee`, `order-summary-shipping`                                                                              |
| **Source**             | AC-1, AC-2                                                                                                                            |
| **Note**               | Both rules yield free shipping here; the case guards against a double-discount or negative fee when both apply.                        |

---

## TC-SHIP-007: Non-member pays $12.99 express shipping below the threshold

| Field                  | Value                                                                                                                                                              |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                                           |
| **Issue**              | SHIP-9                                                                                                                                                             |
| **Automation Score**   | HIGH (59/67.5)                                                                                                                                                     |
| **ISTQB Technique**    | Decision Table — R5 (non-member, express, subtotal < $50.00)                                                                                                       |
| **Manual Env**         | Local, Staging                                                                                                                                                     |
| **Precondition**       | Signed in as a non-member account. Cart subtotal is $25.00. Checkout page is open with Standard selected.                                                          |
| **Steps**              | 1. Read the fee shown next to **Express** shipping <br> 2. Select **Express** <br> 3. Read the **Shipping** line in the order summary <br> 4. Read the order total |
| **Expected**           | Express shows `$12.99` before and after selection. The **Shipping** line changes from `$5.99` to `$12.99`. Order total increases by $7.00.                          |
| **data-testid needed** | `shipping-option-express`, `shipping-option-express-fee`, `order-summary-shipping`, `order-summary-total`                                                        |
| **Source**             | AC-3                                                                                                                                                               |
| **Note**               | Depends on A4, A5.                                                                                                                                                 |

---

## TC-SHIP-008: Non-member pays $12.99 express shipping at or above the threshold

| Field                  | Value                                                                                                                                        |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                      |
| **Issue**              | SHIP-9                                                                                                                                       |
| **Automation Score**   | HIGH (56/67.5)                                                                                                                               |
| **ISTQB Technique**    | Decision Table — R6 (non-member, express, subtotal ≥ $50.00)                                                                                 |
| **Manual Env**         | Local, Staging                                                                                                                               |
| **Precondition**       | Signed in as a non-member account. Cart subtotal is $50.00. Checkout page is open.                                                           |
| **Steps**              | 1. Select **Express** shipping <br> 2. Read the fee next to **Express** <br> 3. Read the **Shipping** line in the order summary                |
| **Expected**           | Express shows `$12.99`. The **Shipping** line shows `$12.99`. The free-standard threshold does not reduce the express fee.                    |
| **data-testid needed** | `shipping-option-express`, `shipping-option-express-fee`, `order-summary-shipping`                                                         |
| **Source**             | AC-3                                                                                                                                         |
| **Note**               | Depends on A7. Guards against the AC-1 threshold leaking into express pricing.                                                               |

---

## TC-SHIP-009: Member pays $7.99 express shipping below the threshold

| Field                  | Value                                                                                                                                        |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                     |
| **Issue**              | SHIP-9                                                                                                                                       |
| **Automation Score**   | HIGH (59/67.5)                                                                                                                               |
| **ISTQB Technique**    | Decision Table — R7 (member, express, subtotal < $50.00)                                                                                     |
| **Manual Env**         | Local, Staging                                                                                                                               |
| **Precondition**       | Signed in as a member account. Cart subtotal is $25.00. Checkout page is open with Standard selected.                                        |
| **Steps**              | 1. Read the fee next to **Express** <br> 2. Select **Express** <br> 3. Read the **Shipping** line in the order summary <br> 4. Read the order total |
| **Expected**           | Express shows `$7.99` before and after selection. The **Shipping** line changes from `$0.00` to `$7.99`. Order total increases by $7.99.      |
| **data-testid needed** | `shipping-option-express`, `shipping-option-express-fee`, `order-summary-shipping`, `order-summary-total`                                  |
| **Source**             | AC-2, AC-3                                                                                                                                   |
| **Note**               | Depends on A3, A5. Proves the member express rate is $7.99, not $0.00: AC-2's free shipping is standard only.                                 |

---

## TC-SHIP-010: Member pays $7.99 express shipping at or above the threshold

| Field                  | Value                                                                                                                                        |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                      |
| **Issue**              | SHIP-9                                                                                                                                       |
| **Automation Score**   | HIGH (56/67.5)                                                                                                                               |
| **ISTQB Technique**    | Decision Table — R8 (member, express, subtotal ≥ $50.00)                                                                                     |
| **Manual Env**         | Local, Staging                                                                                                                               |
| **Precondition**       | Signed in as a member account. Cart subtotal is $120.00. Checkout page is open.                                                              |
| **Steps**              | 1. Select **Express** shipping <br> 2. Read the fee next to **Express** <br> 3. Read the **Shipping** line in the order summary                |
| **Expected**           | Express shows `$7.99`. The **Shipping** line shows `$7.99`.                                                                                  |
| **data-testid needed** | `shipping-option-express`, `shipping-option-express-fee`, `order-summary-shipping`                                                         |
| **Source**             | AC-3                                                                                                                                         |
| **Note**               | Depends on A7. Completes the decision table.                                                                                                 |

---

## TC-SHIP-011: Fee recalculates when the subtotal crosses the threshold during checkout

| Field                  | Value                                                                                                                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                                                                 |
| **Issue**              | SHIP-9                                                                                                                                                                                                  |
| **Automation Score**   | MEDIUM (48/67.5)                                                                                                                                                                                        |
| **ISTQB Technique**    | Error Guessing — stale fee after cart change (state not refreshed)                                                                                                                                      |
| **Manual Env**         | Local, Staging                                                                                                                                                                                          |
| **Precondition**       | Signed in as a non-member account. Cart contains one item at $45.00 (quantity 1) and one at $10.00 (quantity 1). Subtotal $55.00. Checkout page is open with Standard selected and showing `$0.00`. |
| **Steps**              | 1. Remove the $10.00 item (or reduce its quantity to 0) from the checkout page <br> 2. Read the **Shipping** line <br> 3. Add the $10.00 item back <br> 4. Read the **Shipping** line                   |
| **Expected**           | After step 1 the **Shipping** line shows `$5.99` (subtotal $45.00). After step 3 it shows `$0.00` (subtotal $55.00). The order total updates each time without a page reload.                            |
| **data-testid needed** | `checkout-item-remove`, `checkout-item-qty`, `order-summary-subtotal`, `order-summary-shipping`, `order-summary-total`                                                                                 |
| **Source**             | Added by QA (the ticket is silent on cart edits made after checkout loads; the fee must follow the current subtotal)                                                                                     |
| **Note**               | Depends on A1. If the checkout page does not allow cart edits, run it from the cart page and re-open checkout; mark the case as adapted with a dated note.                                               |

---

## TC-SHIP-012: Threshold uses the pre-discount subtotal, and the fee is not shown as negative

| Field                  | Value                                                                                                                                                                                            |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @ship @manual-only`                                                                                                                                                        |
| **Issue**              | SHIP-9                                                                                                                                                                                           |
| **Automation Score**   | LOW (33/67.5)                                                                                                                                                                                    |
| **ISTQB Technique**    | EP — subtotal partition where a discount moves the amount across the threshold; Error Guessing — negative or double-applied fee                                                                  |
| **Manual Env**         | Staging                                                                                                                                                                                          |
| **Precondition**       | Signed in as a non-member account. Cart subtotal is $55.00 before discounts. A $10.00 promo code is available. Standard shipping is selected.                                                     |
| **Steps**              | 1. Open the checkout page and read the **Shipping** line <br> 2. Apply the $10.00 promo code <br> 3. Read the **Subtotal**, **Discount** and **Shipping** lines <br> 4. Read the order total      |
| **Expected**           | Step 1 shows `$0.00`. After step 2, under assumption A1 the **Shipping** line stays `$0.00` because the pre-discount subtotal is $55.00. The fee is never negative. Total = $55.00 − $10.00 + $0.00 (+ tax). |
| **data-testid needed** | `promo-code-input`, `promo-code-apply`, `order-summary-subtotal`, `order-summary-discount`, `order-summary-shipping`, `order-summary-total`                                                     |
| **Source**             | Added by QA (the ticket does not define whether "subtotal" is before or after discounts)                                                                                                         |
| **Note**               | Depends on A1 and on a promo-code feature existing. If the product owner decides the threshold applies after discounts, change the expected fee to `$5.99` with a dated correction; do not delete the case. Kept manual until the rule is confirmed. |

---

## Coverage summary

| Source                        | Cases                                         |
| ----------------------------- | --------------------------------------------- |
| AC-1                          | TC-SHIP-001, 002, 003, 004, 006               |
| AC-2                          | TC-SHIP-005, 006, 009                         |
| AC-3                          | TC-SHIP-007, 008, 009, 010                    |
| Added by QA                   | TC-SHIP-011, 012                              |
| Release gate (`@gate`)        | TC-SHIP-001, 002, 003, 005, 007, 009          |

Open questions for the product owner, recorded here rather than asked: whether "subtotal" is pre- or post-discount (A1), and whether a guest shopper can be a member (A3). Rules not applied: the `context-discovery` rule could not be grounded in code because the repository is empty; `qa-rules` and `qa-reference` skills were not loaded, so the automation scores are from the matrix in this command alone.
