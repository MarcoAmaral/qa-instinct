---
feature: Shipping Fee at Checkout
feature_code: SHIP
tc_count: 8
tracker_issues: SHIP-9
risk_level: HIGH
runbook: N/A — no runbook defined
implementation_pack: N/A — no implementation pack defined
spec: N/A — not specified
last_updated: 2026-10-28
---

# Test Cases — Shipping Fee at Checkout

| Field            | Value                                             |
| ---------------- | ------------------------------------------------- |
| **Project**      | Shipping Checkout                                 |
| **Author**       | QA Engineer — Senior QA Engineer                  |
| **Date Created** | 2026-10-28                                        |
| **Last Updated** | 2026-10-28                                        |
| **Methodology**  | ISTQB CTFL v4.0 — Equivalence Partitioning, BVA  |

---

## TC-SHIP-001: Non-member, standard shipping, subtotal below threshold

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                                      |
| **Issue**              | SHIP-9                                                                                  |
| **Automation Score**   | HIGH (56/67.5)                                                                          |
| **ISTQB Technique**    | EP + BVA — subtotal below $50 (min-1: $49.99); non-member partition                     |
| **Manual Env**         | Staging                                                                                 |
| **Precondition**       | User is not logged in or is non-member. Checkout page with order subtotal $49.99. Standard shipping option is selected. |
| **Steps**              | 1. Navigate to checkout page <br> 2. Confirm Standard shipping is selected <br> 3. Observe shipping fee displayed |
| **Expected**           | Shipping fee displays as $5.99. Total price = Subtotal + $5.99. Fee is not struck through or marked as free. |
| **data-testid needed** | `shipping-fee`, `shipping-option-standard`, `checkout-total`                            |
| **Source**             | AC-1                                                                                    |
| **Note**               | Assumption: subtotal $49.99 is representative of < $50.00 threshold; non-member is the default user state when not authenticated. |

---

## TC-SHIP-002: Non-member, standard shipping, subtotal at threshold

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                                      |
| **Issue**              | SHIP-9                                                                                  |
| **Automation Score**   | HIGH (57/67.5)                                                                          |
| **ISTQB Technique**    | BVA — boundary value (min: $50.00); non-member partition                                |
| **Manual Env**         | Staging                                                                                 |
| **Precondition**       | User is not logged in or is non-member. Checkout page with order subtotal exactly $50.00. Standard shipping option is selected. |
| **Steps**              | 1. Navigate to checkout page <br> 2. Confirm Standard shipping is selected <br> 3. Observe shipping fee displayed |
| **Expected**           | Shipping fee displays as FREE or $0.00. Total price = Subtotal ($50.00). Fee label shows "Free Shipping" or equivalent. |
| **data-testid needed** | `shipping-fee`, `shipping-option-standard`, `checkout-total`                            |
| **Source**             | AC-1                                                                                    |
| **Note**               | Assumption: >= $50.00 qualifies for free shipping; exact boundary ($50.00) is included in free tier. |

---

## TC-SHIP-003: Non-member, standard shipping, subtotal above threshold

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                                      |
| **Issue**              | SHIP-9                                                                                  |
| **Automation Score**   | HIGH (56/67.5)                                                                          |
| **ISTQB Technique**    | EP + BVA — subtotal above $50 (max+1: $50.01); non-member partition                     |
| **Manual Env**         | Staging                                                                                 |
| **Precondition**       | User is not logged in or is non-member. Checkout page with order subtotal $50.01 or higher. Standard shipping option is selected. |
| **Steps**              | 1. Navigate to checkout page <br> 2. Confirm Standard shipping is selected <br> 3. Observe shipping fee displayed |
| **Expected**           | Shipping fee displays as FREE or $0.00. Total price = Subtotal. Fee label shows "Free Shipping" or equivalent. |
| **data-testid needed** | `shipping-fee`, `shipping-option-standard`, `checkout-total`                            |
| **Source**             | AC-1                                                                                    |
| **Note**               | Assumption: any subtotal >= $50.00 qualifies for free standard shipping. |

---

## TC-SHIP-004: Member, standard shipping, any subtotal

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                                      |
| **Issue**              | SHIP-9                                                                                  |
| **Automation Score**   | HIGH (58/67.5)                                                                          |
| **ISTQB Technique**    | EP — member partition; subtotal below threshold ($25.00) as representative             |
| **Manual Env**         | Staging                                                                                 |
| **Precondition**       | User is authenticated and is a member (membership status confirmed). Checkout page with order subtotal $25.00. Standard shipping option is selected. |
| **Steps**              | 1. Confirm user is logged in as member <br> 2. Navigate to checkout page <br> 3. Confirm Standard shipping is selected <br> 4. Observe shipping fee displayed |
| **Expected**           | Shipping fee displays as FREE or $0.00 regardless of subtotal amount. Total price = Subtotal. Fee label shows "Free Shipping" or equivalent. |
| **data-testid needed** | `shipping-fee`, `shipping-option-standard`, `checkout-total`, `user-membership-badge`  |
| **Source**             | AC-2                                                                                    |
| **Note**               | Assumption: members always receive free standard shipping regardless of subtotal; membership status is visible or queryable on checkout page. |

---

## TC-SHIP-005: Member, standard shipping, high subtotal

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                 |
| **Issue**              | SHIP-9                                                                                  |
| **Automation Score**   | MEDIUM (48/67.5)                                                                        |
| **ISTQB Technique**    | EP — member partition; subtotal above threshold ($100.00) as representative             |
| **Manual Env**         | Staging                                                                                 |
| **Precondition**       | User is authenticated and is a member. Checkout page with order subtotal $100.00. Standard shipping option is selected. |
| **Steps**              | 1. Confirm user is logged in as member <br> 2. Navigate to checkout page <br> 3. Observe shipping fee displayed |
| **Expected**           | Shipping fee displays as FREE or $0.00. Total price = Subtotal ($100.00). Member benefit applies consistently. |
| **data-testid needed** | `shipping-fee`, `shipping-option-standard`, `checkout-total`                            |
| **Source**             | AC-2                                                                                    |
| **Note**               | Added by QA (confirms member benefit is not affected by high subtotals; prevents false positive if discount logic only applies below/above thresholds). |

---

## TC-SHIP-006: Non-member, express shipping

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                                      |
| **Issue**              | SHIP-9                                                                                  |
| **Automation Score**   | HIGH (55/67.5)                                                                          |
| **ISTQB Technique**    | EP — non-member partition; express shipping partition; any subtotal                    |
| **Manual Env**         | Staging                                                                                 |
| **Precondition**       | User is not logged in or is non-member. Checkout page with order subtotal $30.00. Express shipping option is available. |
| **Steps**              | 1. Navigate to checkout page <br> 2. Select Express shipping option <br> 3. Observe shipping fee displayed |
| **Expected**           | Shipping fee displays as $12.99. Total price = Subtotal + $12.99. Express fee is charged regardless of subtotal amount. |
| **data-testid needed** | `shipping-fee`, `shipping-option-express`, `checkout-total`                            |
| **Source**             | AC-3                                                                                    |
| **Note**               | Assumption: express shipping has a flat rate of $12.99 for all non-members, independent of subtotal. |

---

## TC-SHIP-007: Member, express shipping

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                                      |
| **Issue**              | SHIP-9                                                                                  |
| **Automation Score**   | HIGH (56/67.5)                                                                          |
| **ISTQB Technique**    | EP — member partition; express shipping partition; any subtotal                        |
| **Manual Env**         | Staging                                                                                 |
| **Precondition**       | User is authenticated and is a member. Checkout page with order subtotal $75.00. Express shipping option is available. |
| **Steps**              | 1. Confirm user is logged in as member <br> 2. Navigate to checkout page <br> 3. Select Express shipping option <br> 4. Observe shipping fee displayed |
| **Expected**           | Shipping fee displays as $7.99. Total price = Subtotal + $7.99. Member discount on express shipping is applied. |
| **data-testid needed** | `shipping-fee`, `shipping-option-express`, `checkout-total`, `user-membership-badge`  |
| **Source**             | AC-3                                                                                    |
| **Note**               | Assumption: express shipping for members is discounted to $7.99 flat rate, independent of subtotal. |

---

## TC-SHIP-008: Shipping fee updates when switching from standard to express

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                 |
| **Issue**              | SHIP-9                                                                                                  |
| **Automation Score**   | HIGH (54/67.5)                                                                                          |
| **ISTQB Technique**    | State Transition — standard → express state change; non-member partition                                |
| **Manual Env**         | Staging                                                                                                 |
| **Precondition**       | User is not logged in or is non-member. Checkout page with order subtotal $60.00. Standard shipping is initially selected (free). |
| **Steps**              | 1. Navigate to checkout page <br> 2. Observe Standard shipping fee (FREE) <br> 3. Click Express shipping option <br> 4. Observe shipping fee update |
| **Expected**           | Shipping fee changes from FREE (or $0.00) to $12.99. Total price updates immediately: Subtotal + $12.99. No page reload required. |
| **data-testid needed** | `shipping-fee`, `shipping-option-standard`, `shipping-option-express`, `checkout-total`                |
| **Source**             | Added by QA (the ticket is silent on fee recalculation on option change; critical for UX and prevents double-charging or stale fees). |
| **Note**               | Assumption: UI recalculates totals in real-time as shipping option changes. This guards against off-by-one and state reconciliation bugs. |
