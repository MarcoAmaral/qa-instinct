---
feature: Checkout Shipping Fees
feature_code: SHIP
tc_count: 8
tracker_issues: SHIP-9
risk_level: HIGH
runbook: N/A — standard checkout feature
implementation_pack: N/A — see checkout specs
spec: N/A — not yet automated
last_updated: 2026-10-28
---

# Test Cases — Shipping Fees at Checkout

| Field                | Value                                                |
| -------------------- | ---------------------------------------------------- |
| **Project**          | [Project Name]                                       |
| **Author**           | QA Engineer — Senior QA Engineer                     |
| **Date Created**     | 2026-10-28                                           |
| **Last Updated**     | 2026-10-28                                           |
| **Methodology**      | ISTQB CTFL v4.0 — EP, BVA, Decision Table            |

---

## TC-SHIP-001: Standard shipping — non-member, subtotal under $50 costs $5.99

| Field                  | Value                                                                                             |
| ---------------------- | ------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                                               |
| **Issue**              | SHIP-9                                                                                            |
| **Automation Score**   | HIGH (58/67.5)                                                                                    |
| **ISTQB Technique**    | EP — valid partition (non-member, standard, subtotal in <$50 range)                              |
| **Manual Env**         | Local, Staging                                                                                   |
| **Precondition**       | Non-member user logged in; cart contains items totaling $30.00 subtotal; checkout page displays |
| **Steps**              | 1. View cart subtotal <br> 2. Select "Standard Shipping" <br> 3. Observe shipping fee in order summary |
| **Expected**           | Shipping fee shows "$5.99" for standard shipping. Order total = subtotal ($30.00) + standard shipping ($5.99). |
| **data-testid needed** | `shipping-option-standard`, `shipping-fee`, `order-total`                                        |
| **Source**             | AC-1                                                                                              |
| **Note**               | N/A — no caveats                                                                                  |

---

## TC-SHIP-002: Standard shipping — non-member, subtotal exactly $50.00 is free

| Field                  | Value                                                                                          |
| ---------------------- | ---------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                                             |
| **Issue**              | SHIP-9                                                                                         |
| **Automation Score**   | HIGH (60/67.5)                                                                                 |
| **ISTQB Technique**    | BVA — boundary value (min = $50.00 for free threshold)                                         |
| **Manual Env**         | Local, Staging                                                                                 |
| **Precondition**       | Non-member user logged in; cart contains items totaling exactly $50.00 subtotal; checkout page |
| **Steps**              | 1. View cart subtotal ($50.00) <br> 2. Select "Standard Shipping" <br> 3. Check shipping fee   |
| **Expected**           | Shipping fee shows "$0.00" (free). Order total = $50.00 (no shipping charge added).             |
| **data-testid needed** | `shipping-option-standard`, `shipping-fee`, `order-total`                                      |
| **Source**             | AC-1                                                                                            |
| **Note**               | Boundary condition: confirms >= $50.00 triggers free shipping                                   |

---

## TC-SHIP-003: Standard shipping — non-member, subtotal over $50 is free

| Field                  | Value                                                                                          |
| ---------------------- | ---------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @e2e @ship @candidate`                                                        |
| **Issue**              | SHIP-9                                                                                         |
| **Automation Score**   | HIGH (57/67.5)                                                                                 |
| **ISTQB Technique**    | EP — valid partition (non-member, standard, subtotal >$50)                                     |
| **Manual Env**         | Local, Staging                                                                                 |
| **Precondition**       | Non-member user logged in; cart contains items totaling $75.00 subtotal; checkout page         |
| **Steps**              | 1. View cart subtotal ($75.00) <br> 2. Select "Standard Shipping" <br> 3. Check shipping fee   |
| **Expected**           | Shipping fee shows "$0.00" (free). Order total = $75.00 (no shipping charge added).             |
| **data-testid needed** | `shipping-option-standard`, `shipping-fee`, `order-total`                                      |
| **Source**             | AC-1                                                                                            |
| **Note**               | N/A — no caveats                                                                                |

---

## TC-SHIP-004: Standard shipping — member, any subtotal is free

| Field                  | Value                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                                                    |
| **Issue**              | SHIP-9                                                                                                 |
| **Automation Score**   | HIGH (59/67.5)                                                                                         |
| **ISTQB Technique**    | EP — valid partition (member, standard, any subtotal); tests subtotal < $50 with member status       |
| **Manual Env**         | Local, Staging                                                                                        |
| **Precondition**       | Member user logged in; cart contains items totaling $20.00 subtotal (below non-member threshold)      |
| **Steps**              | 1. Confirm user is a member (check account badge or profile) <br> 2. View cart subtotal ($20.00) <br> 3. Select "Standard Shipping" <br> 4. Check shipping fee |
| **Expected**           | Shipping fee shows "$0.00" (free). Order total = $20.00. Member gets free shipping regardless of subtotal. |
| **data-testid needed** | `user-member-badge`, `shipping-option-standard`, `shipping-fee`, `order-total`                        |
| **Source**             | AC-2                                                                                                   |
| **Note**               | AC-2 overrides AC-1: members always get free standard shipping, even under $50.00                     |

---

## TC-SHIP-005: Express shipping — non-member costs $12.99

| Field                  | Value                                                                                          |
| ---------------------- | ---------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @e2e @ship @candidate`                                                        |
| **Issue**              | SHIP-9                                                                                         |
| **Automation Score**   | HIGH (56/67.5)                                                                                 |
| **ISTQB Technique**    | EP — valid partition (non-member, express, any subtotal)                                       |
| **Manual Env**         | Local, Staging                                                                                 |
| **Precondition**       | Non-member user logged in; cart contains items totaling $30.00 subtotal; checkout page         |
| **Steps**              | 1. View cart subtotal ($30.00) <br> 2. Select "Express Shipping" <br> 3. Check shipping fee   |
| **Expected**           | Shipping fee shows "$12.99" for express shipping. Order total = $30.00 + $12.99 = $42.99.      |
| **data-testid needed** | `shipping-option-express`, `shipping-fee`, `order-total`                                       |
| **Source**             | AC-3                                                                                            |
| **Note**               | Express fee is flat $12.99 for non-members, regardless of subtotal                             |

---

## TC-SHIP-006: Express shipping — member costs $7.99

| Field                  | Value                                                                                          |
| ---------------------- | ---------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @e2e @ship @candidate`                                                        |
| **Issue**              | SHIP-9                                                                                         |
| **Automation Score**   | HIGH (57/67.5)                                                                                 |
| **ISTQB Technique**    | EP — valid partition (member, express, any subtotal)                                           |
| **Manual Env**         | Local, Staging                                                                                 |
| **Precondition**       | Member user logged in; cart contains items totaling $45.00 subtotal; checkout page             |
| **Steps**              | 1. Confirm user is a member <br> 2. View cart subtotal ($45.00) <br> 3. Select "Express Shipping" <br> 4. Check shipping fee |
| **Expected**           | Shipping fee shows "$7.99" for express shipping. Order total = $45.00 + $7.99 = $52.99.        |
| **data-testid needed** | `user-member-badge`, `shipping-option-express`, `shipping-fee`, `order-total`                  |
| **Source**             | AC-3                                                                                            |
| **Note**               | Member discount on express: $7.99 vs. non-member $12.99                                       |

---

## TC-SHIP-007: Shipping fee updates when subtotal crosses $50 threshold

| Field                  | Value                                                                                                                              |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                            |
| **Issue**              | SHIP-9                                                                                                                             |
| **Automation Score**   | MEDIUM (44/67.5)                                                                                                                   |
| **ISTQB Technique**    | State Transition — cart state changes trigger fee recalculation                                                                    |
| **Manual Env**         | Local, Staging                                                                                                                     |
| **Precondition**       | Non-member user logged in; checkout page displayed; cart initially contains $45.00 subtotal; Standard Shipping selected          |
| **Steps**              | 1. Observe shipping fee ($5.99 for subtotal $45.00) <br> 2. Add item costing $5.00 to cart (subtotal now $50.00) <br> 3. Observe updated shipping fee |
| **Expected**           | Shipping fee updates from "$5.99" to "$0.00" (free) when subtotal reaches $50.00. Order total recalculates automatically.         |
| **data-testid needed** | `cart-subtotal`, `shipping-fee`, `order-total`, `add-to-cart-button`                                                              |
| **Source**             | AC-1                                                                                                                               |
| **Note**               | Tests dynamic recalculation; confirms system re-evaluates AC-1 rule on cart change                                                |

---

## TC-SHIP-008: Member discount applies regardless of subtotal and shipping type

| Field                  | Value                                                                                                                       |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                     |
| **Issue**              | SHIP-9                                                                                                                      |
| **Automation Score**   | HIGH (54/67.5)                                                                                                              |
| **ISTQB Technique**    | Decision Table — all valid combinations of (member status) × (shipping type) × (subtotal range)                             |
| **Manual Env**         | Local, Staging                                                                                                              |
| **Precondition**       | Member user logged in; cart contains $15.00 subtotal (below non-member standard threshold); checkout page                   |
| **Steps**              | 1. Confirm user is a member <br> 2. Select "Standard Shipping" and note fee <br> 3. Switch to "Express Shipping" and note fee <br> 4. Verify both show member-only pricing |
| **Expected**           | Standard Shipping: $0.00 (free). Express Shipping: $7.99 (member rate). Both fees are lower than non-member equivalent costs. |
| **data-testid needed** | `user-member-badge`, `shipping-option-standard`, `shipping-option-express`, `shipping-fee`                                 |
| **Source**             | AC-2, AC-3                                                                                                                  |
| **Note**               | AC-2 and AC-3 combined: members get the best rate on both shipping options; AC-2 overrides AC-1 ($50 rule) for members     |
