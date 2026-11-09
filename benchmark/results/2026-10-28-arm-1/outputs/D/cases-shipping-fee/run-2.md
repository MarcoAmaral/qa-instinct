---
feature: Shipping fee at checkout
feature_code: SHIP
tc_count: 8
tracker_issues: [SHIP-9]
risk_level: HIGH
runbook: N/A — checkout flow is documented in app
implementation_pack: N/A — feature implemented
spec: tests/e2e/checkout.spec.ts
last_updated: 2026-10-28
---

# Test Cases — Shipping fee at checkout

| Field                | Value                                      |
| -------------------- | ------------------------------------------ |
| **Author**           | QA Engineer — Senior QA Engineer            |
| **Total TCs**        | 8                                          |
| **Date Created**     | 2026-10-28                                 |
| **Last Updated**     | 2026-10-28                                 |
| **Methodology**      | ISTQB CTFL v4.0 — EP, BVA, Decision Table  |

**Assumptions:** Order subtotal is calculated before shipping selection; member status is determined before checkout; prices are in USD; standard shipping is the default option; both standard and express shipping methods are available; checkout requires a shipping method selection.

---

## TC-SHIP-001: Non-member, standard shipping, subtotal below $50

| Field                  | Value                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                                   |
| **Issue**              | [SHIP-9](https://github.com/issues/SHIP-9)                                          |
| **Automation Score**   | HIGH (66/67.5)                                                                      |
| **ISTQB Technique**    | BVA — below boundary ($50); EP — non-member partition, standard shipping             |
| **Manual Env**         | Local, Staging                                                                     |
| **Precondition**       | User is not a member. Cart contains items with subtotal of $25.00. Checkout opened. |
| **Steps**              | 1. Select **Standard Shipping** <br> 2. Review shipping fee on order summary        |
| **Expected**           | Shipping fee displays as **$5.99**. Total = Subtotal + $5.99.                      |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-display`, `order-total`                   |
| **Source**             | AC-1                                                                                 |
| **Note**               | N/A — no caveats                                                                    |

---

## TC-SHIP-002: Non-member, standard shipping, subtotal exactly at $50 boundary

| Field                  | Value                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                                     |
| **Issue**              | [SHIP-9](https://github.com/issues/SHIP-9)                                            |
| **Automation Score**   | HIGH (66/67.5)                                                                        |
| **ISTQB Technique**    | BVA — at boundary ($50.00); EP — non-member partition, standard shipping              |
| **Manual Env**         | Local, Staging                                                                       |
| **Precondition**       | User is not a member. Cart contains items with subtotal of exactly $50.00. Checkout opened. |
| **Steps**              | 1. Select **Standard Shipping** <br> 2. Review shipping fee on order summary         |
| **Expected**           | Shipping fee displays as **Free** or **$0.00**. Total = Subtotal.                   |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-display`, `order-total`                    |
| **Source**             | AC-1                                                                                  |
| **Note**               | Boundary test — $50 threshold for free shipping                                      |

---

## TC-SHIP-003: Non-member, standard shipping, subtotal above $50

| Field                  | Value                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                                     |
| **Issue**              | [SHIP-9](https://github.com/issues/SHIP-9)                                            |
| **Automation Score**   | HIGH (66/67.5)                                                                        |
| **ISTQB Technique**    | BVA — above boundary ($50+); EP — non-member partition, standard shipping             |
| **Manual Env**         | Local, Staging                                                                       |
| **Precondition**       | User is not a member. Cart contains items with subtotal of $99.99. Checkout opened. |
| **Steps**              | 1. Select **Standard Shipping** <br> 2. Review shipping fee on order summary         |
| **Expected**           | Shipping fee displays as **Free** or **$0.00**. Total = Subtotal.                   |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-display`, `order-total`                    |
| **Source**             | AC-1                                                                                  |
| **Note**               | N/A — no caveats                                                                     |

---

## TC-SHIP-004: Member, standard shipping, any subtotal

| Field                  | Value                                                                              |
| ---------------------- | ---------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                                 |
| **Issue**              | [SHIP-9](https://github.com/issues/SHIP-9)                                         |
| **Automation Score**   | HIGH (66/67.5)                                                                     |
| **ISTQB Technique**    | EP — member partition, standard shipping (subtotal irrelevant)                      |
| **Manual Env**         | Local, Staging                                                                     |
| **Precondition**       | User is a member. Cart contains items with subtotal of $15.00 (below non-member threshold). Checkout opened. |
| **Steps**              | 1. Select **Standard Shipping** <br> 2. Review shipping fee on order summary       |
| **Expected**           | Shipping fee displays as **Free** or **$0.00**. Total = Subtotal.                 |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-display`, `order-total`                  |
| **Source**             | AC-2                                                                               |
| **Note**               | Member benefit: free standard shipping regardless of subtotal                      |

---

## TC-SHIP-005: Non-member, express shipping, any subtotal

| Field                  | Value                                                                              |
| ---------------------- | ---------------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p0 @e2e @ship @candidate`                                                |
| **Issue**              | [SHIP-9](https://github.com/issues/SHIP-9)                                         |
| **Automation Score**   | HIGH (66/67.5)                                                                     |
| **ISTQB Technique**    | EP — non-member partition, express shipping (subtotal irrelevant)                   |
| **Manual Env**         | Local, Staging                                                                     |
| **Precondition**       | User is not a member. Cart contains items with subtotal of $75.00. Checkout opened. |
| **Steps**              | 1. Select **Express Shipping** <br> 2. Review shipping fee on order summary       |
| **Expected**           | Shipping fee displays as **$12.99**. Total = Subtotal + $12.99.                   |
| **data-testid needed** | `shipping-method-express`, `shipping-fee-display`, `order-total`                   |
| **Source**             | AC-3                                                                               |
| **Note**               | N/A — no caveats                                                                   |

---

## TC-SHIP-006: Member, express shipping, any subtotal

| Field                  | Value                                                                              |
| ---------------------- | ---------------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p0 @e2e @ship @candidate`                                                |
| **Issue**              | [SHIP-9](https://github.com/issues/SHIP-9)                                         |
| **Automation Score**   | HIGH (66/67.5)                                                                     |
| **ISTQB Technique**    | EP — member partition, express shipping                                             |
| **Manual Env**         | Local, Staging                                                                     |
| **Precondition**       | User is a member. Cart contains items with subtotal of $30.00. Checkout opened.  |
| **Steps**              | 1. Select **Express Shipping** <br> 2. Review shipping fee on order summary       |
| **Expected**           | Shipping fee displays as **$7.99**. Total = Subtotal + $7.99.                    |
| **data-testid needed** | `shipping-method-express`, `shipping-fee-display`, `order-total`                   |
| **Source**             | AC-3                                                                               |
| **Note**               | Member receives express discount: $7.99 instead of $12.99                         |

---

## TC-SHIP-007: Non-member switches from standard to express shipping

| Field                  | Value                                                                              |
| ---------------------- | ---------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                            |
| **Issue**              | [SHIP-9](https://github.com/issues/SHIP-9)                                         |
| **Automation Score**   | HIGH (63/67.5)                                                                     |
| **ISTQB Technique**    | State Transition — standard → express; Error Guessing (stale fee display)          |
| **Manual Env**         | Local, Staging                                                                     |
| **Precondition**       | Non-member at checkout. Subtotal $45.00. Standard shipping selected, fee showing $5.99. |
| **Steps**              | 1. Select **Express Shipping** <br> 2. Wait for fee recalculation <br> 3. Review updated order summary |
| **Expected**           | Shipping fee updates to **$12.99** immediately. Total recalculates correctly. No stale fees displayed. |
| **data-testid needed** | `shipping-method-standard`, `shipping-method-express`, `shipping-fee-display`, `order-total` |
| **Source**             | Added by QA (verify fee updates when shipping method changes)                     |
| **Note**               | Regression risk: fee not recalculating when method changes                        |

---

## TC-SHIP-008: Member switches from express to standard shipping

| Field                  | Value                                                                              |
| ---------------------- | ---------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                            |
| **Issue**              | [SHIP-9](https://github.com/issues/SHIP-9)                                         |
| **Automation Score**   | HIGH (63/67.5)                                                                     |
| **ISTQB Technique**    | State Transition — express → standard; Error Guessing (stale fee display)          |
| **Manual Env**         | Local, Staging                                                                     |
| **Precondition**       | Member at checkout. Subtotal $20.00. Express shipping selected, fee showing $7.99. |
| **Steps**              | 1. Select **Standard Shipping** <br> 2. Wait for fee recalculation <br> 3. Review updated order summary |
| **Expected**           | Shipping fee updates to **Free** or **$0.00** immediately. Total recalculates to subtotal only. |
| **data-testid needed** | `shipping-method-standard`, `shipping-method-express`, `shipping-fee-display`, `order-total` |
| **Source**             | Added by QA (verify fee updates when shipping method changes)                     |
| **Note**               | Regression risk: fee not recalculating when method changes; member benefit not applied |
