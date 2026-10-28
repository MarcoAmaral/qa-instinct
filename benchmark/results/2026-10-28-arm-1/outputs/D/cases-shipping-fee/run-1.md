---
feature: Shipping Fee Calculation at Checkout
feature_code: SHIP
tc_count: 8
tracker_issues: SHIP-9
risk_level: HIGH
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — no spec provided
last_updated: 2026-10-28
---

# Test Cases — Shipping Fee Calculation at Checkout

| Field                | Value                                                      |
| -------------------- | ---------------------------------------------------------- |
| **Project**          | Shipping & Checkout                                        |
| **Author**           | Senior QA Engineer                                         |
| **Date Created**     | 2026-10-28                                                 |
| **Last Updated**     | 2026-10-28                                                 |
| **Methodology**      | ISTQB CTFL v4.0 — Boundary Value Analysis, Decision Table |

---

## TC-SHIP-001: Standard shipping free for non-member at $50.00 boundary

| Field                  | Value                                                           |
| ---------------------- | --------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                              |
| **Issue**              | SHIP-9                                                          |
| **Automation Score**   | HIGH (56/67.5)                                                  |
| **ISTQB Technique**    | BVA — boundary value ($50.00 minimum for free shipping)         |
| **Manual Env**         | Local, Staging                                                  |
| **Precondition**       | Non-member user logged in; checkout page with cart subtotal of $50.00 (after discounts, before shipping) |
| **Steps**              | 1. Navigate to checkout <br> 2. Select Standard shipping <br> 3. Review shipping fee display |
| **Expected**           | Shipping fee displays as $0.00 or "Free" for Standard shipping. Total adjusts accordingly. |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-amount`, `order-total` |
| **Source**             | AC-1                                                            |
| **Note**               | Assumption: subtotal is calculated before tax and does not include express fees. |

---

## TC-SHIP-002: Standard shipping charged $5.99 for non-member below $50.00

| Field                  | Value                                                           |
| ---------------------- | --------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                              |
| **Issue**              | SHIP-9                                                          |
| **Automation Score**   | HIGH (54/67.5)                                                  |
| **ISTQB Technique**    | BVA — below boundary ($49.99)                                   |
| **Manual Env**         | Local, Staging                                                  |
| **Precondition**       | Non-member user logged in; checkout page with cart subtotal of $49.99 |
| **Steps**              | 1. Navigate to checkout <br> 2. Select Standard shipping <br> 3. Review shipping fee display |
| **Expected**           | Shipping fee displays as $5.99 for Standard shipping. Order total increases by $5.99. |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-amount`, `order-total` |
| **Source**             | AC-1                                                            |
| **Note**               | N/A — no caveats                                                |

---

## TC-SHIP-003: Standard shipping free for non-member above $50.00

| Field                  | Value                                                           |
| ---------------------- | --------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                         |
| **Issue**              | SHIP-9                                                          |
| **Automation Score**   | HIGH (52/67.5)                                                  |
| **ISTQB Technique**    | BVA — above boundary ($50.01)                                   |
| **Manual Env**         | Local, Staging                                                  |
| **Precondition**       | Non-member user logged in; checkout page with cart subtotal of $50.01 |
| **Steps**              | 1. Navigate to checkout <br> 2. Select Standard shipping <br> 3. Review shipping fee display |
| **Expected**           | Shipping fee displays as $0.00 or "Free" for Standard shipping. Order total does not increase. |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-amount`, `order-total` |
| **Source**             | AC-1                                                            |
| **Note**               | N/A — no caveats                                                |

---

## TC-SHIP-004: Member receives free Standard shipping regardless of subtotal

| Field                  | Value                                                           |
| ---------------------- | --------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                              |
| **Issue**              | SHIP-9                                                          |
| **Automation Score**   | HIGH (55/67.5)                                                  |
| **ISTQB Technique**    | Decision Table — member status (true) × shipping type (standard) |
| **Manual Env**         | Local, Staging                                                  |
| **Precondition**       | Member user logged in with active membership; checkout page with cart subtotal of $25.00 |
| **Steps**              | 1. Navigate to checkout <br> 2. Select Standard shipping <br> 3. Review shipping fee display |
| **Expected**           | Shipping fee displays as $0.00 or "Free" for Standard shipping, regardless of subtotal being below $50. Membership badge is visible. |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-amount`, `membership-badge` |
| **Source**             | AC-2                                                            |
| **Note**               | Assumption: member status is derived from user account; a valid membership is active at test time. |

---

## TC-SHIP-005: Express shipping charged $12.99 for non-member

| Field                  | Value                                                           |
| ---------------------- | --------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                         |
| **Issue**              | SHIP-9                                                          |
| **Automation Score**   | HIGH (52/67.5)                                                  |
| **ISTQB Technique**    | EP — valid partition (express shipping for non-member)          |
| **Manual Env**         | Local, Staging                                                  |
| **Precondition**       | Non-member user logged in; checkout page with cart subtotal of any amount |
| **Steps**              | 1. Navigate to checkout <br> 2. Select Express shipping <br> 3. Review shipping fee display |
| **Expected**           | Shipping fee displays as $12.99 for Express shipping. Order total increases by $12.99. |
| **data-testid needed** | `shipping-method-express`, `shipping-fee-amount`, `order-total` |
| **Source**             | AC-3                                                            |
| **Note**               | N/A — no caveats                                                |

---

## TC-SHIP-006: Express shipping charged $7.99 for member

| Field                  | Value                                                           |
| ---------------------- | --------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                              |
| **Issue**              | SHIP-9                                                          |
| **Automation Score**   | HIGH (55/67.5)                                                  |
| **ISTQB Technique**    | Decision Table — member status (true) × shipping type (express) |
| **Manual Env**         | Local, Staging                                                  |
| **Precondition**       | Member user logged in with active membership; checkout page with cart subtotal of any amount |
| **Steps**              | 1. Navigate to checkout <br> 2. Select Express shipping <br> 3. Review shipping fee display |
| **Expected**           | Shipping fee displays as $7.99 for Express shipping (not $12.99). Order total increases by $7.99. Membership badge visible. |
| **data-testid needed** | `shipping-method-express`, `shipping-fee-amount`, `order-total`, `membership-badge` |
| **Source**             | AC-3                                                            |
| **Note**               | N/A — no caveats                                                |

---

## TC-SHIP-007: Member Express discount is correctly applied vs. non-member

| Field                  | Value                                                           |
| ---------------------- | --------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @ship @candidate`                         |
| **Issue**              | SHIP-9                                                          |
| **Automation Score**   | MEDIUM (44/67.5)                                                |
| **ISTQB Technique**    | Decision Table — member (true vs. false) × express shipping     |
| **Manual Env**         | Local, Staging                                                  |
| **Precondition**       | Two browsers open: one with non-member user, one with member user; same cart contents; both at checkout |
| **Steps**              | 1. Non-member: select Express shipping, note fee <br> 2. Member: select Express shipping, note fee <br> 3. Compare displayed fees |
| **Expected**           | Non-member sees $12.99; Member sees $7.99. Difference is $5.00 in member's favor. Both can proceed to payment. |
| **data-testid needed** | `shipping-fee-amount`, `membership-badge`                       |
| **Source**             | AC-3                                                            |
| **Note**               | Assumption: member and non-member accounts exist in staging and can be logged in simultaneously. |

---

## TC-SHIP-008: Shipping method selection persists and recalculates fees on quantity change

| Field                  | Value                                                           |
| ---------------------- | --------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @ship @candidate`                         |
| **Issue**              | SHIP-9                                                          |
| **Automation Score**   | MEDIUM (38/67.5)                                                |
| **ISTQB Technique**    | Error Guessing — state change triggering fee recalculation      |
| **Manual Env**         | Local, Staging                                                  |
| **Precondition**       | Non-member user at checkout; cart subtotal $40.00; Standard shipping selected, fee shows $5.99 |
| **Steps**              | 1. Add item to cart (subtotal now $55.00) <br> 2. Return to shipping section <br> 3. Verify fee display and selection state |
| **Expected**           | Shipping method (Standard) remains selected. Fee updates to $0.00 (free, since subtotal now ≥ $50). Order total recalculates correctly. |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-amount`, `order-total`, `cart-subtotal` |
| **Source**             | Added by QA (the ticket is silent on fee recalculation on cart edits, but it's critical at checkout) |
| **Note**               | Assumption: cart can be edited from within the checkout page; subtotal updates instantly. |
