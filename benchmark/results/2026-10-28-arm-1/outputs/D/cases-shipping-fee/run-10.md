---
feature: Shipping Fee Calculation at Checkout
feature_code: SHIP
tc_count: 9
tracker_issues: [SHIP-9]
risk_level: MEDIUM
runbook: N/A — no runbook required
implementation_pack: N/A — scope not defined in ticket
spec: N/A — not automated yet
last_updated: 2026-10-28
---

# Test Cases — Shipping Fee Calculation at Checkout

| Field                | Value                                                      |
| -------------------- | ---------------------------------------------------------- |
| **Project**          | Shipping & Checkout                                        |
| **Author**           | Senior QA Engineer                                         |
| **Date Created**     | 2026-10-28                                                 |
| **Last Updated**     | 2026-10-28                                                 |
| **Methodology**      | ISTQB CTFL v4.0 — Equivalence Partitioning, Boundary Value Analysis, Decision Table |

**Assumptions:**
- Subtotal excludes shipping and tax; shipping fee is calculated _after_ order qualification.
- Member status is determined at checkout time from the active user's account profile.
- Express and standard shipping methods are both available to all customers (member and non-member).
- Boundary case $50.00 subtotal is inclusive (free standard shipping applies at exactly $50.00).
- All values are USD; currency conversion is out of scope.
- Low orders under $0.01 are rejected by order validation, so not tested here.

---

## TC-SHIP-001: Non-member, standard shipping, subtotal below $50 threshold

| Field                  | Value                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p1 @e2e @ship @candidate`                                                   |
| **Issue**              | SHIP-9                                                                               |
| **Automation Score**   | HIGH (56/67.5)                                                                      |
| **ISTQB Technique**    | EP — valid partition (non-member, subtotal < $50, standard method)                   |
| **Manual Env**         | Local, Staging                                                                       |
| **Precondition**       | Non-member user logged in; shopping cart contains items totaling $49.99 subtotal    |
| **Steps**              | 1. Navigate to checkout <br> 2. Select **Standard Shipping** <br> 3. View order summary |
| **Expected**           | Shipping fee displays as **$5.99**. Order total = Subtotal + $5.99. No discount applied. |
| **data-testid needed** | `shipping-method-select`, `shipping-fee-display`, `order-total`                     |
| **Source**             | AC-1                                                                                 |
| **Note**               | N/A — core happy path                                                                |

---

## TC-SHIP-002: Non-member, standard shipping, subtotal at $50.00 boundary

| Field                  | Value                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p1 @e2e @ship @candidate`                                                   |
| **Issue**              | SHIP-9                                                                               |
| **Automation Score**   | HIGH (58/67.5)                                                                      |
| **ISTQB Technique**    | BVA — boundary value (exactly at $50.00 threshold)                                   |
| **Manual Env**         | Local, Staging                                                                       |
| **Precondition**       | Non-member user logged in; shopping cart contains items totaling exactly $50.00     |
| **Steps**              | 1. Navigate to checkout <br> 2. Select **Standard Shipping** <br> 3. View order summary |
| **Expected**           | Shipping fee displays as **FREE**. Order total = $50.00 (no shipping charge).        |
| **data-testid needed** | `shipping-method-select`, `shipping-fee-display`, `order-total`                     |
| **Source**             | AC-1                                                                                 |
| **Note**               | Verifies the boundary condition is inclusive (≥ $50.00 qualifies for free shipping). |

---

## TC-SHIP-003: Non-member, standard shipping, subtotal above $50.00 threshold

| Field                  | Value                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p1 @e2e @ship @candidate`                                                   |
| **Issue**              | SHIP-9                                                                               |
| **Automation Score**   | HIGH (56/67.5)                                                                      |
| **ISTQB Technique**    | EP — valid partition (non-member, subtotal ≥ $50, standard method)                   |
| **Manual Env**         | Local, Staging                                                                       |
| **Precondition**       | Non-member user logged in; shopping cart contains items totaling $150.00 subtotal   |
| **Steps**              | 1. Navigate to checkout <br> 2. Select **Standard Shipping** <br> 3. View order summary |
| **Expected**           | Shipping fee displays as **FREE**. Order total = $150.00 (no shipping charge).       |
| **data-testid needed** | `shipping-method-select`, `shipping-fee-display`, `order-total`                     |
| **Source**             | AC-1                                                                                 |
| **Note**               | N/A — core happy path                                                                |

---

## TC-SHIP-004: Member, standard shipping, any subtotal (low)

| Field                  | Value                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p1 @e2e @ship @candidate`                                                   |
| **Issue**              | SHIP-9                                                                               |
| **Automation Score**   | HIGH (58/67.5)                                                                      |
| **ISTQB Technique**    | EP — valid partition (member, any subtotal, standard method)                         |
| **Manual Env**         | Local, Staging                                                                       |
| **Precondition**       | Member user logged in; shopping cart contains items totaling $15.00 subtotal        |
| **Steps**              | 1. Navigate to checkout <br> 2. Select **Standard Shipping** <br> 3. View order summary |
| **Expected**           | Shipping fee displays as **FREE**. Order total = $15.00 (member benefit applied).    |
| **data-testid needed** | `shipping-method-select`, `shipping-fee-display`, `order-total`, `member-badge`     |
| **Source**             | AC-2                                                                                 |
| **Note**               | Member status overrides the $50.00 subtotal threshold for standard shipping.         |

---

## TC-SHIP-005: Member, standard shipping, high subtotal

| Field                  | Value                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                              |
| **Issue**              | SHIP-9                                                                               |
| **Automation Score**   | HIGH (55/67.5)                                                                      |
| **ISTQB Technique**    | EP — valid partition (member, high subtotal, standard method); confirms consistency  |
| **Manual Env**         | Local, Staging                                                                       |
| **Precondition**       | Member user logged in; shopping cart contains items totaling $500.00 subtotal       |
| **Steps**              | 1. Navigate to checkout <br> 2. Select **Standard Shipping** <br> 3. View order summary |
| **Expected**           | Shipping fee displays as **FREE**. Order total = $500.00 (member benefit applied).   |
| **data-testid needed** | `shipping-method-select`, `shipping-fee-display`, `order-total`, `member-badge`     |
| **Source**             | AC-2                                                                                 |
| **Note**               | Confirms free standard shipping is consistent across all member subtotals.           |

---

## TC-SHIP-006: Non-member, express shipping

| Field                  | Value                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p1 @e2e @ship @candidate`                                                   |
| **Issue**              | SHIP-9                                                                               |
| **Automation Score**   | HIGH (54/67.5)                                                                      |
| **ISTQB Technique**    | EP — valid partition (non-member, express method, any subtotal)                      |
| **Manual Env**         | Local, Staging                                                                       |
| **Precondition**       | Non-member user logged in; shopping cart contains items totaling $75.00 subtotal    |
| **Steps**              | 1. Navigate to checkout <br> 2. Select **Express Shipping** <br> 3. View order summary |
| **Expected**           | Shipping fee displays as **$12.99**. Order total = Subtotal + $12.99.                |
| **data-testid needed** | `shipping-method-select`, `shipping-fee-display`, `order-total`                     |
| **Source**             | AC-3                                                                                 |
| **Note**               | Express shipping fee applies to non-members regardless of subtotal.                  |

---

## TC-SHIP-007: Member, express shipping

| Field                  | Value                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p1 @e2e @ship @candidate`                                                   |
| **Issue**              | SHIP-9                                                                               |
| **Automation Score**   | HIGH (56/67.5)                                                                      |
| **ISTQB Technique**    | EP — valid partition (member, express method, any subtotal)                          |
| **Manual Env**         | Local, Staging                                                                       |
| **Precondition**       | Member user logged in; shopping cart contains items totaling $100.00 subtotal       |
| **Steps**              | 1. Navigate to checkout <br> 2. Select **Express Shipping** <br> 3. View order summary |
| **Expected**           | Shipping fee displays as **$7.99**. Order total = Subtotal + $7.99.                  |
| **data-testid needed** | `shipping-method-select`, `shipping-fee-display`, `order-total`, `member-badge`     |
| **Source**             | AC-3                                                                                 |
| **Note**               | Member express shipping discount applied (non-member pays $12.99; member pays $7.99).|

---

## TC-SHIP-008: Switching shipping methods updates fee immediately

| Field                  | Value                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @ship @candidate`                                              |
| **Issue**              | SHIP-9                                                                               |
| **Automation Score**   | MEDIUM (42/67.5)                                                                    |
| **ISTQB Technique**    | State Transition — valid transition from standard to express and back                |
| **Manual Env**         | Local, Staging                                                                       |
| **Precondition**       | Non-member user at checkout; cart subtotal $75.00; standard shipping initially selected |
| **Steps**              | 1. Observe shipping fee (should show **FREE** or **$5.99** based on subtotal) <br> 2. Select **Express Shipping** <br> 3. Observe updated fee <br> 4. Select **Standard Shipping** <br> 5. Observe final fee |
| **Expected**           | Fee updates to **$12.99** when express is selected. Fee reverts when standard is selected. Order total updates in real-time. |
| **data-testid needed** | `shipping-method-standard`, `shipping-method-express`, `shipping-fee-display`, `order-total` |
| **Source**             | Added by QA (the ticket is silent on method-switching behavior)                       |
| **Note**               | Verifies the UI responds immediately to shipping method changes.                     |

---

## TC-SHIP-009: Non-member with low subtotal; express shipping cost exceeds order

| Field                  | Value                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @ship @candidate`                                              |
| **Issue**              | SHIP-9                                                                               |
| **Automation Score**   | MEDIUM (38/67.5)                                                                    |
| **ISTQB Technique**    | Error Guessing — edge case (shipping fee > subtotal; tests fee calculation under stress) |
| **Manual Env**         | Local, Staging                                                                       |
| **Precondition**       | Non-member user logged in; shopping cart contains items totaling $10.00 subtotal    |
| **Steps**              | 1. Navigate to checkout <br> 2. Select **Express Shipping** <br> 3. View order summary |
| **Expected**           | Order total = $22.99 ($10.00 subtotal + $12.99 express fee). No discount or rejection. System allows high-fee-to-subtotal ratio. |
| **data-testid needed** | `shipping-method-select`, `shipping-fee-display`, `order-total`, `order-summary-breakdown` |
| **Source**             | Added by QA (ticket does not specify behavior when shipping fee exceeds subtotal)    |
| **Note**               | Confirms system does not reject or cap express shipping based on order size.         |
