---
feature: Shipping Fee at Checkout
feature_code: SHIP
tc_count: 8
tracker_issues: [SHIP-9]
risk_level: HIGH
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-28
---

# Test Cases — Shipping Fee at Checkout

| Field                | Value                                                                    |
| -------------------- | ----------------------------------------------------------------------- |
| **Project**          | Shipping & Checkout                                                     |
| **Author**           | Senior QA Engineer — ISTQB CTFL v4.0                                   |
| **Date Created**     | 2026-10-28                                                              |
| **Last Updated**     | 2026-10-28                                                              |
| **Methodology**      | ISTQB CTFL v4.0 — Equivalence Partitioning, Boundary Value Analysis, Decision Table |

---

## TC-SHIP-001: Standard shipping is free for non-members when subtotal ≥ $50.00

| Field                  | Value                                                                    |
| ---------------------- | ------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                       |
| **Issue**              | SHIP-9                                                                   |
| **Automation Score**   | HIGH (60/67.5)                                                           |
| **ISTQB Technique**    | BVA — subtotal $50.00 (boundary: free threshold)                         |
| **Manual Env**         | Local, Staging                                                           |
| **Precondition**       | Non-member user at checkout with order subtotal $50.00, standard shipping selected |
| **Steps**              | 1. Navigate to shipping method selection <br> 2. Verify standard shipping option is displayed <br> 3. Review shipping fee <br> 4. Proceed to order review |
| **Expected**           | Standard shipping fee displays as $0.00. No surcharge is added to the order total. |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-display`, `order-total`        |
| **Source**             | AC-1                                                                     |
| **Note**               | Assumption: non-member = guest/unauthenticated user; subtotal = product total before tax/shipping |

---

## TC-SHIP-002: Standard shipping costs $5.99 for non-members when subtotal < $50.00

| Field                  | Value                                                                    |
| ---------------------- | ------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                       |
| **Issue**              | SHIP-9                                                                   |
| **Automation Score**   | HIGH (60/67.5)                                                           |
| **ISTQB Technique**    | BVA — subtotal $49.99 (just below boundary)                              |
| **Manual Env**         | Local, Staging                                                           |
| **Precondition**       | Non-member user at checkout with order subtotal $49.99, standard shipping selected |
| **Steps**              | 1. Navigate to shipping method selection <br> 2. Verify standard shipping option is displayed <br> 3. Review shipping fee <br> 4. Proceed to order review |
| **Expected**           | Standard shipping fee displays as $5.99. The order total increases by $5.99. |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-display`, `order-total`        |
| **Source**             | AC-1                                                                     |
| **Note**               | Boundary value just below the $50.00 free threshold                      |

---

## TC-SHIP-003: Standard shipping is free for members at any subtotal (below $50.00)

| Field                  | Value                                                                    |
| ---------------------- | ------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                       |
| **Issue**              | SHIP-9                                                                   |
| **Automation Score**   | HIGH (62/67.5)                                                           |
| **ISTQB Technique**    | EP — valid partition (member user state, low subtotal)                   |
| **Manual Env**         | Local, Staging                                                           |
| **Precondition**       | Authenticated member user at checkout with order subtotal $30.00, standard shipping selected |
| **Steps**              | 1. Verify user is logged in as member <br> 2. Navigate to shipping method selection <br> 3. Verify standard shipping option is displayed <br> 4. Review shipping fee |
| **Expected**           | Standard shipping fee displays as $0.00. No surcharge is added. Member badge or indicator visible. |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-display`, `member-indicator`   |
| **Source**             | AC-2                                                                     |
| **Note**               | Assumption: member = authenticated user with membership status; free regardless of subtotal amount |

---

## TC-SHIP-004: Standard shipping is free for members at any subtotal (above $50.00)

| Field                  | Value                                                                    |
| ---------------------- | ------------------------------------------------------------------------ |
| **Tags**               | `@regression @p0 @e2e @ship @candidate`                                  |
| **Issue**              | SHIP-9                                                                   |
| **Automation Score**   | HIGH (62/67.5)                                                           |
| **ISTQB Technique**    | EP — valid partition (member user state, high subtotal)                  |
| **Manual Env**         | Local, Staging                                                           |
| **Precondition**       | Authenticated member user at checkout with order subtotal $75.00, standard shipping selected |
| **Steps**              | 1. Verify user is logged in as member <br> 2. Navigate to shipping method selection <br> 3. Verify standard shipping option is displayed <br> 4. Review shipping fee |
| **Expected**           | Standard shipping fee displays as $0.00. Member status grants free shipping regardless of subtotal. |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-display`, `member-indicator`   |
| **Source**             | AC-2                                                                     |
| **Note**               | Confirms AC-2 applies at all subtotal levels                             |

---

## TC-SHIP-005: Express shipping costs $12.99 for non-members

| Field                  | Value                                                                    |
| ---------------------- | ------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                  |
| **Issue**              | SHIP-9                                                                   |
| **Automation Score**   | HIGH (58/67.5)                                                           |
| **ISTQB Technique**    | EP — valid partition (non-member, express shipping)                      |
| **Manual Env**         | Local, Staging                                                           |
| **Precondition**       | Non-member user at checkout with any subtotal, express shipping option available |
| **Steps**              | 1. Navigate to shipping method selection <br> 2. Select express shipping <br> 3. Review shipping fee displayed <br> 4. Proceed to order review |
| **Expected**           | Express shipping fee displays as $12.99. Order total increases by $12.99. Express option label clearly distinguishes from standard. |
| **data-testid needed** | `shipping-method-express`, `shipping-fee-display`, `order-total`         |
| **Source**             | AC-3                                                                     |
| **Note**               | Assumption: express shipping is always available; fee is flat regardless of subtotal |

---

## TC-SHIP-006: Express shipping costs $7.99 for members

| Field                  | Value                                                                    |
| ---------------------- | ------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                  |
| **Issue**              | SHIP-9                                                                   |
| **Automation Score**   | HIGH (60/67.5)                                                           |
| **ISTQB Technique**    | EP — valid partition (member, express shipping)                          |
| **Manual Env**         | Local, Staging                                                           |
| **Precondition**       | Authenticated member user at checkout with any subtotal, express shipping option available |
| **Steps**              | 1. Verify user is logged in as member <br> 2. Navigate to shipping method selection <br> 3. Select express shipping <br> 4. Review shipping fee displayed |
| **Expected**           | Express shipping fee displays as $7.99 (not $12.99). Order total increases by $7.99. Member discount is applied to express shipping. |
| **data-testid needed** | `shipping-method-express`, `shipping-fee-display`, `order-total`, `member-indicator` |
| **Source**             | AC-3                                                                     |
| **Note**               | Member receives a $5.00 discount on express ($12.99 → $7.99)             |

---

## TC-SHIP-007: Shipping fee updates when switching between standard and express as non-member

| Field                  | Value                                                                    |
| ---------------------- | ------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @ship @candidate`                                  |
| **Issue**              | SHIP-9                                                                   |
| **Automation Score**   | MEDIUM (42/67.5)                                                         |
| **ISTQB Technique**    | State Transition — shipping method change                                |
| **Manual Env**         | Local, Staging                                                           |
| **Precondition**       | Non-member at checkout with subtotal $40.00, standard shipping ($5.99) currently selected |
| **Steps**              | 1. Verify shipping fee shows $5.99 <br> 2. Select express shipping <br> 3. Observe fee update <br> 4. Select standard shipping again <br> 5. Observe fee update |
| **Expected**           | Fee updates to $12.99 when express is selected. Fee reverts to $5.99 when standard is reselected. Order total reflects each change immediately. |
| **data-testid needed** | `shipping-method-standard`, `shipping-method-express`, `shipping-fee-display` |
| **Source**             | Added by QA (the ticket is silent on fee recalculation during method selection)  |
| **Note**               | Validates real-time fee updates and state consistency                    |

---

## TC-SHIP-008: Shipping fee updates when switching between standard and express as member

| Field                  | Value                                                                    |
| ---------------------- | ------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @ship @candidate`                                  |
| **Issue**              | SHIP-9                                                                   |
| **Automation Score**   | MEDIUM (44/67.5)                                                         |
| **ISTQB Technique**    | State Transition — shipping method change with member benefits           |
| **Manual Env**         | Local, Staging                                                           |
| **Precondition**       | Authenticated member at checkout with any subtotal, standard shipping ($0.00) currently selected |
| **Steps**              | 1. Verify shipping fee shows $0.00 <br> 2. Select express shipping <br> 3. Observe fee update <br> 4. Select standard shipping again <br> 5. Observe fee update |
| **Expected**           | Fee updates to $7.99 when express is selected. Fee reverts to $0.00 when standard is reselected. Order total reflects each change immediately. |
| **data-testid needed** | `shipping-method-standard`, `shipping-method-express`, `shipping-fee-display`, `member-indicator` |
| **Source**             | Added by QA (the ticket is silent on fee recalculation during method selection)  |
| **Note**               | Validates member discount persists across method switches                |
