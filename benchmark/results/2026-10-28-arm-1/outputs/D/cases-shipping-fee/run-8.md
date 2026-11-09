---
feature: Shipping Fee Calculation
feature_code: SHIP
tc_count: 8
tracker_issues: [SHIP-9]
risk_level: MEDIUM
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-28
---

# Test Cases — Shipping Fee Calculation

| Field            | Value                                                      |
| ---------------- | ---------------------------------------------------------- |
| **Project**      | E-commerce Checkout                                        |
| **Author**       | Senior QA Engineer                                         |
| **Date Created** | 2026-10-28                                                 |
| **Last Updated** | 2026-10-28                                                 |
| **Methodology**  | ISTQB CTFL v4.0 — Equivalence Partitioning, Boundary Value Analysis, Decision Table |

---

## TC-SHIP-001: Non-member, standard shipping, subtotal below threshold

| Field                  | Value                                                                  |
| ---------------------- | ---------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                     |
| **Issue**              | [SHIP-9](https://tracker.example.com/SHIP-9)                           |
| **Automation Score**   | HIGH (64/67.5)                                                         |
| **ISTQB Technique**    | EP — non-member, standard shipping, subtotal < $50                     |
| **Manual Env**         | Local, Staging                                                         |
| **Precondition**       | User is not a member, cart subtotal is $40.00, checkout page displays shipping options |
| **Steps**              | 1. Navigate to checkout <br> 2. Select "Standard Shipping" <br> 3. Observe shipping fee display |
| **Expected**           | Shipping fee displays as "$5.99" and is added to order total           |
| **data-testid needed** | `shipping-fee-display`, `order-total`, `shipping-method-standard`      |
| **Source**             | AC-1                                                                   |
| **Note**               | Assumption: Non-member status is inferred from "not logged in as member" or explicit account type |

---

## TC-SHIP-002: Non-member, standard shipping, subtotal at threshold

| Field                  | Value                                                                  |
| ---------------------- | ---------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                     |
| **Issue**              | [SHIP-9](https://tracker.example.com/SHIP-9)                           |
| **Automation Score**   | HIGH (64/67.5)                                                         |
| **ISTQB Technique**    | BVA — boundary at $50.00 (minimum for free shipping)                   |
| **Manual Env**         | Local, Staging                                                         |
| **Precondition**       | User is not a member, cart subtotal is exactly $50.00, checkout page displays shipping options |
| **Steps**              | 1. Navigate to checkout <br> 2. Select "Standard Shipping" <br> 3. Observe shipping fee display |
| **Expected**           | Shipping fee displays as "$0.00" (free); order total includes no shipping charge |
| **data-testid needed** | `shipping-fee-display`, `order-total`, `shipping-method-standard`      |
| **Source**             | AC-1                                                                   |
| **Note**               | Assumption: $50.00 is inclusive (≥ $50.00 is free, not > $50.00)       |

---

## TC-SHIP-003: Non-member, standard shipping, subtotal above threshold

| Field                  | Value                                                                  |
| ---------------------- | ---------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                     |
| **Issue**              | [SHIP-9](https://tracker.example.com/SHIP-9)                           |
| **Automation Score**   | HIGH (64/67.5)                                                         |
| **ISTQB Technique**    | EP — non-member, standard shipping, subtotal ≥ $50                     |
| **Manual Env**         | Local, Staging                                                         |
| **Precondition**       | User is not a member, cart subtotal is $75.00, checkout page displays shipping options |
| **Steps**              | 1. Navigate to checkout <br> 2. Select "Standard Shipping" <br> 3. Observe shipping fee display |
| **Expected**           | Shipping fee displays as "$0.00" (free); order total includes no shipping charge |
| **data-testid needed** | `shipping-fee-display`, `order-total`, `shipping-method-standard`      |
| **Source**             | AC-1                                                                   |
| **Note**               | N/A — no caveats                                                       |

---

## TC-SHIP-004: Non-member, standard shipping, subtotal just below threshold

| Field                  | Value                                                                  |
| ---------------------- | ---------------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @e2e @ship @candidate`                                |
| **Issue**              | [SHIP-9](https://tracker.example.com/SHIP-9)                           |
| **Automation Score**   | HIGH (64/67.5)                                                         |
| **ISTQB Technique**    | BVA — boundary at $49.99 (one cent below threshold)                    |
| **Manual Env**         | Local, Staging                                                         |
| **Precondition**       | User is not a member, cart subtotal is $49.99, checkout page displays shipping options |
| **Steps**              | 1. Navigate to checkout <br> 2. Select "Standard Shipping" <br> 3. Observe shipping fee display |
| **Expected**           | Shipping fee displays as "$5.99" and is added to order total           |
| **data-testid needed** | `shipping-fee-display`, `order-total`, `shipping-method-standard`      |
| **Source**             | AC-1                                                                   |
| **Note**               | Assumption: Subtotal is calculated to 2 decimal places (cents)         |

---

## TC-SHIP-005: Member, standard shipping, any subtotal

| Field                  | Value                                                                  |
| ---------------------- | ---------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                     |
| **Issue**              | [SHIP-9](https://tracker.example.com/SHIP-9)                           |
| **Automation Score**   | HIGH (64/67.5)                                                         |
| **ISTQB Technique**    | EP — member, standard shipping (subtotal irrelevant per AC-2)           |
| **Manual Env**         | Local, Staging                                                         |
| **Precondition**       | User is a member (logged in), cart subtotal is $25.00, checkout page displays shipping options |
| **Steps**              | 1. Navigate to checkout while logged in as a member <br> 2. Select "Standard Shipping" <br> 3. Observe shipping fee display |
| **Expected**           | Shipping fee displays as "$0.00" (free) regardless of subtotal amount  |
| **data-testid needed** | `shipping-fee-display`, `order-total`, `shipping-method-standard`, `user-member-badge` |
| **Source**             | AC-2                                                                   |
| **Note**               | Assumption: Member status is verified and visible in checkout context  |

---

## TC-SHIP-006: Non-member, express shipping

| Field                  | Value                                                                  |
| ---------------------- | ---------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                     |
| **Issue**              | [SHIP-9](https://tracker.example.com/SHIP-9)                           |
| **Automation Score**   | HIGH (64/67.5)                                                         |
| **ISTQB Technique**    | EP — non-member, express shipping (subtotal irrelevant per AC-3)        |
| **Manual Env**         | Local, Staging                                                         |
| **Precondition**       | User is not a member, cart has any subtotal, checkout page displays shipping options |
| **Steps**              | 1. Navigate to checkout <br> 2. Select "Express Shipping" <br> 3. Observe shipping fee display |
| **Expected**           | Shipping fee displays as "$12.99" and is added to order total          |
| **data-testid needed** | `shipping-fee-display`, `order-total`, `shipping-method-express`       |
| **Source**             | AC-3                                                                   |
| **Note**               | Assumption: Express shipping cost is flat-rate, independent of subtotal |

---

## TC-SHIP-007: Member, express shipping

| Field                  | Value                                                                  |
| ---------------------- | ---------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                     |
| **Issue**              | [SHIP-9](https://tracker.example.com/SHIP-9)                           |
| **Automation Score**   | HIGH (64/67.5)                                                         |
| **ISTQB Technique**    | EP — member, express shipping (member discount applies per AC-3)        |
| **Manual Env**         | Local, Staging                                                         |
| **Precondition**       | User is a member (logged in), cart has any subtotal, checkout page displays shipping options |
| **Steps**              | 1. Navigate to checkout while logged in as a member <br> 2. Select "Express Shipping" <br> 3. Observe shipping fee display |
| **Expected**           | Shipping fee displays as "$7.99" (member rate) and is added to order total |
| **data-testid needed** | `shipping-fee-display`, `order-total`, `shipping-method-express`, `user-member-badge` |
| **Source**             | AC-3                                                                   |
| **Note**               | Assumption: Member receives express discount regardless of subtotal    |

---

## TC-SHIP-008: Switching shipping method recalculates fee

| Field                  | Value                                                                  |
| ---------------------- | ---------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                |
| **Issue**              | [SHIP-9](https://tracker.example.com/SHIP-9)                           |
| **Automation Score**   | MEDIUM (52/67.5)                                                       |
| **ISTQB Technique**    | State Transition — from Standard to Express, non-member, subtotal ≥ $50 |
| **Manual Env**         | Local, Staging                                                         |
| **Precondition**       | User is not a member, cart subtotal is $60.00, "Standard Shipping" ($0.00) is selected and displayed |
| **Steps**              | 1. On checkout page, switch selection to "Express Shipping" <br> 2. Observe shipping fee update <br> 3. Observe order total recalculation |
| **Expected**           | Shipping fee updates from "$0.00" to "$12.99"; order total increases by $12.99 immediately |
| **data-testid needed** | `shipping-fee-display`, `order-total`, `shipping-method-standard`, `shipping-method-express` |
| **Source**             | Added by QA (the story is silent on the interaction behavior when switching methods; this validates correct recalculation) |
| **Note**               | Assumption: Fee updates in real-time without page reload; used to catch state management bugs |
