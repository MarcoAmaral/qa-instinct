---
feature: Shipping Fee Calculation at Checkout
feature_code: SHIP
tc_count: 9
tracker_issues: [SHIP-9]
risk_level: MEDIUM
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — test cases only
last_updated: 2026-10-28
---

# Test Cases — Shipping Fee Calculation at Checkout

| Field                | Value                                     |
| -------------------- | ----------------------------------------- |
| **Project**          | E-Commerce Checkout                       |
| **Author**           | QA Engineer — ISTQB CTFL v4.0             |
| **Date Created**     | 2026-10-28                                |
| **Last Updated**     | 2026-10-28                                |
| **Methodology**      | ISTQB CTFL v4.0 — BVA, EP, Decision Table |

**Assumptions made:**
- User authentication status (member/non-member) is determined by login and account type
- Subtotal is calculated from product prices only, before tax and shipping fees
- Shipping fee is displayed as a line item in the order summary before payment
- The system supports USD with two decimal places ($X.XX)
- Member status is stable during the checkout session
- "Standard shipping" and "Express shipping" are the only shipping methods offered

---

## TC-SHIP-001: Standard shipping free for non-member with subtotal ≥ $50.00

| Field                  | Value                                                                      |
| ---------------------- | -------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                         |
| **Issue**              | SHIP-9                                                                     |
| **Automation Score**   | HIGH (58/67.5)                                                             |
| **ISTQB Technique**    | EP — valid partition (non-member, standard, subtotal ≥ $50)                |
| **Manual Env**         | Local, Staging                                                             |
| **Precondition**       | User is logged out (non-member), cart contains items totaling $75.00       |
| **Steps**              | 1. Navigate to checkout <br> 2. Select "Standard shipping" <br> 3. Observe order summary |
| **Expected**           | Shipping line shows "$0.00" or "FREE". Total order amount is subtotal + $0.00 tax. |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-amount`, `order-total`           |
| **Source**             | AC-1                                                                       |
| **Note**               | Core revenue-affecting rule; must pass before release                      |

---

## TC-SHIP-002: Standard shipping $5.99 for non-member with subtotal < $50.00

| Field                  | Value                                                                      |
| ---------------------- | -------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                         |
| **Issue**              | SHIP-9                                                                     |
| **Automation Score**   | HIGH (57/67.5)                                                             |
| **ISTQB Technique**    | EP — valid partition (non-member, standard, subtotal < $50)                |
| **Manual Env**         | Local, Staging                                                             |
| **Precondition**       | User is logged out (non-member), cart contains items totaling $35.00       |
| **Steps**              | 1. Navigate to checkout <br> 2. Select "Standard shipping" <br> 3. Observe order summary |
| **Expected**           | Shipping line shows "$5.99". Total order amount is $35.00 + $5.99 + tax.   |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-amount`, `order-total`           |
| **Source**             | AC-1                                                                       |
| **Note**               | Core revenue-affecting rule; must pass before release                      |

---

## TC-SHIP-003: Standard shipping free for member at any subtotal above zero

| Field                  | Value                                                                      |
| ---------------------- | -------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                         |
| **Issue**              | SHIP-9                                                                     |
| **Automation Score**   | HIGH (56/67.5)                                                             |
| **ISTQB Technique**    | EP — valid partition (member, standard, low subtotal)                      |
| **Manual Env**         | Local, Staging                                                             |
| **Precondition**       | User is logged in with member account, cart contains items totaling $15.00 |
| **Steps**              | 1. Navigate to checkout <br> 2. Select "Standard shipping" <br> 3. Observe order summary |
| **Expected**           | Shipping line shows "$0.00" or "FREE" (member benefit). Total is $15.00 + tax only. |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-amount`, `member-badge`          |
| **Source**             | AC-2                                                                       |
| **Note**               | Member benefit; critical for retention and value proposition               |

---

## TC-SHIP-004: Express shipping $12.99 for non-member

| Field                  | Value                                                                      |
| ---------------------- | -------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                    |
| **Issue**              | SHIP-9                                                                     |
| **Automation Score**   | HIGH (55/67.5)                                                             |
| **ISTQB Technique**    | EP — valid partition (non-member, express)                                 |
| **Manual Env**         | Local, Staging                                                             |
| **Precondition**       | User is logged out (non-member), cart contains items totaling $60.00       |
| **Steps**              | 1. Navigate to checkout <br> 2. Select "Express shipping" <br> 3. Observe order summary |
| **Expected**           | Shipping line shows "$12.99". Total order amount is $60.00 + $12.99 + tax. |
| **data-testid needed** | `shipping-method-express`, `shipping-fee-amount`, `order-total`            |
| **Source**             | AC-3                                                                       |
| **Note**               | Upsell opportunity; non-member express pricing                             |

---

## TC-SHIP-005: Express shipping $7.99 for member

| Field                  | Value                                                                      |
| ---------------------- | -------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                    |
| **Issue**              | SHIP-9                                                                     |
| **Automation Score**   | HIGH (54/67.5)                                                             |
| **ISTQB Technique**    | EP — valid partition (member, express)                                     |
| **Manual Env**         | Local, Staging                                                             |
| **Precondition**       | User is logged in with member account, cart contains items totaling $60.00 |
| **Steps**              | 1. Navigate to checkout <br> 2. Select "Express shipping" <br> 3. Observe order summary |
| **Expected**           | Shipping line shows "$7.99" (member discount from $12.99). Total is $60.00 + $7.99 + tax. |
| **data-testid needed** | `shipping-method-express`, `shipping-fee-amount`, `member-discount-tag`    |
| **Source**             | AC-3                                                                       |
| **Note**               | Member benefit on express option; price differential validates AC-3        |

---

## TC-SHIP-006: Boundary — exactly $50.00 subtotal, non-member, standard → free

| Field                  | Value                                                                      |
| ---------------------- | -------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p0 @e2e @ship @candidate`                                        |
| **Issue**              | SHIP-9                                                                     |
| **Automation Score**   | HIGH (56/67.5)                                                             |
| **ISTQB Technique**    | BVA — boundary value at $50.00 (min inclusive)                             |
| **Manual Env**         | Local, Staging                                                             |
| **Precondition**       | User is logged out (non-member), cart contains items totaling exactly $50.00 |
| **Steps**              | 1. Navigate to checkout <br> 2. Select "Standard shipping" <br> 3. Observe order summary |
| **Expected**           | Shipping line shows "$0.00" or "FREE". Total is $50.00 + tax (no $5.99 fee). |
| **data-testid needed** | `shipping-fee-amount`, `order-subtotal`                                    |
| **Source**             | AC-1                                                                       |
| **Note**               | Boundary condition; off-by-one bugs common here; the ≥ threshold is critical |

---

## TC-SHIP-007: Boundary — $49.99 subtotal, non-member, standard → $5.99

| Field                  | Value                                                                      |
| ---------------------- | -------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p0 @e2e @ship @candidate`                                        |
| **Issue**              | SHIP-9                                                                     |
| **Automation Score**   | HIGH (56/67.5)                                                             |
| **ISTQB Technique**    | BVA — boundary value at $49.99 (max exclusive)                             |
| **Manual Env**         | Local, Staging                                                             |
| **Precondition**       | User is logged out (non-member), cart contains items totaling $49.99       |
| **Steps**              | 1. Navigate to checkout <br> 2. Select "Standard shipping" <br> 3. Observe order summary |
| **Expected**           | Shipping line shows "$5.99". Total is $49.99 + $5.99 + tax.                |
| **data-testid needed** | `shipping-fee-amount`, `order-subtotal`                                    |
| **Source**             | AC-1                                                                       |
| **Note**               | Boundary condition; validates the < $50 rule; one cent below threshold triggers fee |

---

## TC-SHIP-008: Member status overrides subtotal rule for standard shipping

| Field                  | Value                                                                      |
| ---------------------- | -------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                    |
| **Issue**              | SHIP-9                                                                     |
| **Automation Score**   | MEDIUM (44/67.5)                                                           |
| **ISTQB Technique**    | Decision Table — member status AND subtotal interaction                    |
| **Manual Env**         | Local, Staging                                                             |
| **Precondition**       | User is logged in with member account, cart contains items totaling $20.00 (below $50 threshold) |
| **Steps**              | 1. Navigate to checkout <br> 2. Select "Standard shipping" <br> 3. Observe order summary |
| **Expected**           | Shipping line shows "$0.00" or "FREE" (member benefit applies, overriding the <$50 rule). Total is $20.00 + tax. |
| **data-testid needed** | `shipping-fee-amount`, `member-status-indicator`                           |
| **Source**             | AC-1, AC-2                                                                 |
| **Note**               | Validates AC-2 hierarchy: member free standard shipping at ANY subtotal, even below $50 |

---

## TC-SHIP-009: Shipping fee updates when shipping method switched mid-checkout

| Field                  | Value                                                                      |
| ---------------------- | -------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @ship @candidate`                                    |
| **Issue**              | SHIP-9                                                                     |
| **Automation Score**   | MEDIUM (42/67.5)                                                           |
| **ISTQB Technique**    | EP — state change (switching between standard and express)                 |
| **Manual Env**         | Local, Staging                                                             |
| **Precondition**       | User is logged out (non-member), cart contains items totaling $60.00, "Standard shipping" is selected ($0.00) |
| **Steps**              | 1. Verify shipping line shows "$0.00" <br> 2. Switch to "Express shipping" <br> 3. Observe shipping fee updates immediately |
| **Expected**           | Shipping line updates from "$0.00" to "$12.99". Order total updates to $60.00 + $12.99 + tax. No reload required. |
| **data-testid needed** | `shipping-method-standard`, `shipping-method-express`, `shipping-fee-amount` |
| **Source**             | Added by QA (AC does not specify real-time updates; validates UX responsiveness) |
| **Note**               | Error Guessing: stale fee display is a common defect in async checkout flows |
