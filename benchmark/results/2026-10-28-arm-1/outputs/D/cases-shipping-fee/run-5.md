---
feature: Shipping Fee Calculation at Checkout
feature_code: SHIP
tc_count: 8
tracker_issues: [SHIP-9]
risk_level: MEDIUM
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-28
---

# Test Cases — Shipping Fee Calculation at Checkout

| Field                | Value                                              |
| -------------------- | -------------------------------------------------- |
| **Project**          | Shipping & Checkout                                |
| **Author**           | Senior QA Engineer — ISTQB CTFL v4.0               |
| **Date Created**     | 2026-10-28                                         |
| **Last Updated**     | 2026-10-28                                         |
| **Methodology**      | ISTQB CTFL v4.0 — EP, BVA, Decision Table          |

---

## TC-SHIP-001: Standard shipping — non-member, subtotal below threshold ($49.99)

| Field                  | Value                                                                                           |
| ---------------------- | ----------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                                              |
| **Issue**              | SHIP-9                                                                                          |
| **Automation Score**   | HIGH (56/67.5)                                                                                  |
| **ISTQB Technique**    | BVA — boundary value just below threshold (min-1 at $49.99)                                     |
| **Manual Env**         | Local, Staging                                                                                  |
| **Precondition**       | User is not a member, cart contains items with subtotal $49.99, checkout page displayed         |
| **Steps**              | 1. Select Standard Shipping <br> 2. Observe the fee displayed on checkout page                  |
| **Expected**           | Standard Shipping fee displays as $5.99 in the order summary                                    |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-amount`                                               |
| **Source**             | AC-1                                                                                            |
| **Note**               | Assumption: subtotal does not include shipping fees when determining threshold                  |

---

## TC-SHIP-002: Standard shipping — non-member, subtotal at threshold ($50.00)

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                                         |
| **Issue**              | SHIP-9                                                                                     |
| **Automation Score**   | HIGH (58/67.5)                                                                             |
| **ISTQB Technique**    | BVA — boundary value at threshold (min at $50.00)                                          |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | User is not a member, cart contains items with subtotal exactly $50.00, checkout displayed |
| **Steps**              | 1. Select Standard Shipping <br> 2. Observe the fee displayed on checkout page             |
| **Expected**           | Standard Shipping fee displays as FREE (no charge) in the order summary                    |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-amount`                                          |
| **Source**             | AC-1                                                                                       |
| **Note**               | Boundary equality: >= $50.00 qualifies for free shipping                                   |

---

## TC-SHIP-003: Standard shipping — non-member, subtotal above threshold ($75.00)

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                                         |
| **Issue**              | SHIP-9                                                                                     |
| **Automation Score**   | HIGH (58/67.5)                                                                             |
| **ISTQB Technique**    | EP — valid partition (high subtotal, standard shipping)                                    |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | User is not a member, cart contains items with subtotal $75.00, checkout displayed         |
| **Steps**              | 1. Select Standard Shipping <br> 2. Observe the fee displayed on checkout page             |
| **Expected**           | Standard Shipping fee displays as FREE (no charge) in the order summary                    |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-amount`                                          |
| **Source**             | AC-1                                                                                       |
| **Note**               | Validates upper partition behavior                                                         |

---

## TC-SHIP-004: Standard shipping — member, subtotal below threshold ($25.00)

| Field                  | Value                                                                                    |
| ---------------------- | ---------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                                       |
| **Issue**              | SHIP-9                                                                                   |
| **Automation Score**   | HIGH (56/67.5)                                                                           |
| **ISTQB Technique**    | Decision Table — member status + shipping type (row: member=true, method=standard)       |
| **Manual Env**         | Local, Staging                                                                           |
| **Precondition**       | User is a member (verified in session/account), cart subtotal $25.00, checkout displayed |
| **Steps**              | 1. Select Standard Shipping <br> 2. Observe the fee displayed on checkout page           |
| **Expected**           | Standard Shipping fee displays as FREE (no charge) in the order summary                  |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-amount`, `user-membership-badge`                |
| **Source**             | AC-2                                                                                     |
| **Note**               | AC-2 overrides AC-1: members always get free standard shipping regardless of subtotal    |

---

## TC-SHIP-005: Standard shipping — member, high subtotal ($100.00)

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                   |
| **Issue**              | SHIP-9                                                                                    |
| **Automation Score**   | MEDIUM (42/67.5)                                                                          |
| **ISTQB Technique**    | EP — valid partition (high subtotal, member, standard shipping)                           |
| **Manual Env**         | Local, Staging                                                                            |
| **Precondition**       | User is a member, cart subtotal $100.00, checkout displayed                              |
| **Steps**              | 1. Select Standard Shipping <br> 2. Observe the fee displayed on checkout page           |
| **Expected**           | Standard Shipping fee displays as FREE (no charge) in the order summary                  |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-amount`                                         |
| **Source**             | AC-2                                                                                     |
| **Note**               | Confirms member benefit applies at all subtotals, including high values                   |

---

## TC-SHIP-006: Express shipping — non-member, any subtotal ($30.00)

| Field                  | Value                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                                     |
| **Issue**              | SHIP-9                                                                                 |
| **Automation Score**   | HIGH (57/67.5)                                                                         |
| **ISTQB Technique**    | Decision Table — non-member + express shipping (row: member=false, method=express)     |
| **Manual Env**         | Local, Staging                                                                         |
| **Precondition**       | User is not a member, cart subtotal $30.00, checkout displayed                         |
| **Steps**              | 1. Select Express Shipping <br> 2. Observe the fee displayed on checkout page          |
| **Expected**           | Express Shipping fee displays as $12.99 in the order summary                           |
| **data-testid needed** | `shipping-method-express`, `shipping-fee-amount`                                        |
| **Source**             | AC-3                                                                                   |
| **Note**               | Express pricing is fixed and does not depend on subtotal                                |

---

## TC-SHIP-007: Express shipping — member, any subtotal ($30.00)

| Field                  | Value                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                                    |
| **Issue**              | SHIP-9                                                                                |
| **Automation Score**   | HIGH (57/67.5)                                                                        |
| **ISTQB Technique**    | Decision Table — member + express shipping (row: member=true, method=express)         |
| **Manual Env**         | Local, Staging                                                                        |
| **Precondition**       | User is a member (verified in session/account), cart subtotal $30.00, checkout shown  |
| **Steps**              | 1. Select Express Shipping <br> 2. Observe the fee displayed on checkout page         |
| **Expected**           | Express Shipping fee displays as $7.99 in the order summary                           |
| **data-testid needed** | `shipping-method-express`, `shipping-fee-amount`, `user-membership-badge`             |
| **Source**             | AC-3                                                                                  |
| **Note**               | Member express discount: $12.99 → $7.99 (savings $5.00), independent of subtotal     |

---

## TC-SHIP-008: Express shipping — member, high subtotal ($100.00)

| Field                  | Value                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                               |
| **Issue**              | SHIP-9                                                                                |
| **Automation Score**   | MEDIUM (40/67.5)                                                                      |
| **ISTQB Technique**    | EP — valid partition (high subtotal, member, express shipping)                        |
| **Manual Env**         | Local, Staging                                                                        |
| **Precondition**       | User is a member, cart subtotal $100.00, checkout displayed                           |
| **Steps**              | 1. Select Express Shipping <br> 2. Observe the fee displayed on checkout page         |
| **Expected**           | Express Shipping fee displays as $7.99 in the order summary                           |
| **data-testid needed** | `shipping-method-express`, `shipping-fee-amount`                                      |
| **Source**             | AC-3                                                                                  |
| **Note**               | Confirms member express pricing applies consistently across subtotal ranges            |
