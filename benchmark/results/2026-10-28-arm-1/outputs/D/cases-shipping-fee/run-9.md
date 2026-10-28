---
feature: Shipping Fee Calculation at Checkout
feature_code: SHIP
tc_count: 10
tracker_issues: [SHIP-9]
risk_level: MEDIUM
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-28
---

# Test Cases — Shipping Fee Calculation at Checkout

| Field                | Value                                      |
| -------------------- | ------------------------------------------ |
| **Project**          | Shipping & Checkout                        |
| **Author**           | Senior QA Engineer                         |
| **Date Created**     | 2026-10-28                                 |
| **Last Updated**     | 2026-10-28                                 |
| **Methodology**      | ISTQB CTFL v4.0 — EP, BVA, Decision Table |

---

## TC-SHIP-001: Standard shipping free for non-member with subtotal ≥ $50.00

| Field                  | Value                                                                     |
| ---------------------- | ------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                        |
| **Issue**              | SHIP-9                                                                    |
| **Automation Score**   | HIGH (60/67.5)                                                            |
| **ISTQB Technique**    | BVA — boundary value at $50.00 (min free threshold)                       |
| **Manual Env**         | Local, Staging                                                            |
| **Precondition**       | Not logged in (non-member); cart contains items totaling exactly $50.00   |
| **Steps**              | 1. Navigate to checkout <br> 2. Select "Standard Shipping" <br> 3. Observe shipping fee display |
| **Expected**           | Shipping fee displays as "$0.00" or "Free"; total reflects no shipping charge. |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-display`, `checkout-total`      |
| **Source**             | AC-1                                                                      |
| **Note**               | Assumption: Standard shipping is the default selection; non-members are users not logged in |

---

## TC-SHIP-002: Standard shipping charged $5.99 for non-member with subtotal < $50.00

| Field                  | Value                                                                     |
| ---------------------- | ------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                        |
| **Issue**              | SHIP-9                                                                    |
| **Automation Score**   | HIGH (60/67.5)                                                            |
| **ISTQB Technique**    | EP — valid partition (non-member, below threshold)                        |
| **Manual Env**         | Local, Staging                                                            |
| **Precondition**       | Not logged in (non-member); cart contains items totaling $25.00           |
| **Steps**              | 1. Navigate to checkout <br> 2. Select "Standard Shipping" <br> 3. Observe shipping fee display |
| **Expected**           | Shipping fee displays as "$5.99"; checkout total = subtotal + $5.99.      |
| **data-testid needed** | `shipping-method-standard`, `shipping-fee-display`, `checkout-total`      |
| **Source**             | AC-1                                                                      |
| **Note**               | N/A — no caveats                                                          |

---

## TC-SHIP-003: Standard shipping boundary at $49.99 (just below threshold)

| Field                  | Value                                                                     |
| ---------------------- | ------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                   |
| **Issue**              | SHIP-9                                                                    |
| **Automation Score**   | HIGH (58/67.5)                                                            |
| **ISTQB Technique**    | BVA — boundary value at $49.99 (max charged threshold)                    |
| **Manual Env**         | Local, Staging                                                            |
| **Precondition**       | Not logged in (non-member); cart contains items totaling $49.99           |
| **Steps**              | 1. Navigate to checkout <br> 2. Select "Standard Shipping" <br> 3. Confirm shipping fee |
| **Expected**           | Shipping fee displays as "$5.99"; total = $49.99 + $5.99 = $55.98.        |
| **data-testid needed** | `shipping-fee-display`, `checkout-total`                                  |
| **Source**             | AC-1                                                                      |
| **Note**               | N/A — no caveats                                                          |

---

## TC-SHIP-004: Standard shipping boundary at $50.01 (just above threshold)

| Field                  | Value                                                                     |
| ---------------------- | ------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                   |
| **Issue**              | SHIP-9                                                                    |
| **Automation Score**   | HIGH (58/67.5)                                                            |
| **ISTQB Technique**    | BVA — boundary value at $50.01 (min free threshold + 1¢)                  |
| **Manual Env**         | Local, Staging                                                            |
| **Precondition**       | Not logged in (non-member); cart contains items totaling $50.01           |
| **Steps**              | 1. Navigate to checkout <br> 2. Select "Standard Shipping" <br> 3. Confirm shipping fee |
| **Expected**           | Shipping fee displays as "$0.00" or "Free"; total = $50.01.               |
| **data-testid needed** | `shipping-fee-display`, `checkout-total`                                  |
| **Source**             | AC-1                                                                      |
| **Note**               | N/A — no caveats                                                          |

---

## TC-SHIP-005: Standard shipping free for member at any subtotal (low subtotal)

| Field                  | Value                                                                     |
| ---------------------- | ------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                        |
| **Issue**              | SHIP-9                                                                    |
| **Automation Score**   | HIGH (62/67.5)                                                            |
| **ISTQB Technique**    | EP — member partition (any subtotal); low value test                       |
| **Manual Env**         | Local, Staging                                                            |
| **Precondition**       | Logged in as member; cart contains items totaling $5.00                   |
| **Steps**              | 1. Navigate to checkout <br> 2. Verify membership status displays <br> 3. Select "Standard Shipping" |
| **Expected**           | Shipping fee displays as "$0.00" or "Free"; total = $5.00 (no charge).    |
| **data-testid needed** | `membership-badge`, `shipping-fee-display`, `checkout-total`              |
| **Source**             | AC-2                                                                      |
| **Note**               | Assumption: membership is indicated visually at checkout; member status persists across session |

---

## TC-SHIP-006: Standard shipping free for member at any subtotal (high subtotal)

| Field                  | Value                                                                     |
| ---------------------- | ------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                   |
| **Issue**              | SHIP-9                                                                    |
| **Automation Score**   | HIGH (62/67.5)                                                            |
| **ISTQB Technique**    | EP — member partition (any subtotal); high value test                      |
| **Manual Env**         | Local, Staging                                                            |
| **Precondition**       | Logged in as member; cart contains items totaling $500.00                 |
| **Steps**              | 1. Navigate to checkout <br> 2. Select "Standard Shipping"                |
| **Expected**           | Shipping fee displays as "$0.00" or "Free"; total = $500.00 (no charge).  |
| **data-testid needed** | `shipping-fee-display`, `checkout-total`                                  |
| **Source**             | AC-2                                                                      |
| **Note**               | N/A — no caveats                                                          |

---

## TC-SHIP-007: Express shipping costs $12.99 for non-member

| Field                  | Value                                                                     |
| ---------------------- | ------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                        |
| **Issue**              | SHIP-9                                                                    |
| **Automation Score**   | HIGH (60/67.5)                                                            |
| **ISTQB Technique**    | EP — valid partition (non-member, express method)                         |
| **Manual Env**         | Local, Staging                                                            |
| **Precondition**       | Not logged in (non-member); cart contains items totaling $30.00; checkout page loaded |
| **Steps**              | 1. Navigate to checkout <br> 2. Select "Express Shipping" <br> 3. Observe shipping fee |
| **Expected**           | Shipping fee displays as "$12.99"; checkout total = $30.00 + $12.99 = $42.99. |
| **data-testid needed** | `shipping-method-express`, `shipping-fee-display`, `checkout-total`       |
| **Source**             | AC-3                                                                      |
| **Note**               | N/A — no caveats                                                          |

---

## TC-SHIP-008: Express shipping costs $7.99 for member

| Field                  | Value                                                                     |
| ---------------------- | ------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate`                                        |
| **Issue**              | SHIP-9                                                                    |
| **Automation Score**   | HIGH (62/67.5)                                                            |
| **ISTQB Technique**    | EP — valid partition (member, express method)                             |
| **Manual Env**         | Local, Staging                                                            |
| **Precondition**       | Logged in as member; cart contains items totaling $30.00; checkout page loaded |
| **Steps**              | 1. Navigate to checkout <br> 2. Verify membership status <br> 3. Select "Express Shipping" |
| **Expected**           | Shipping fee displays as "$7.99"; checkout total = $30.00 + $7.99 = $37.99. |
| **data-testid needed** | `membership-badge`, `shipping-method-express`, `shipping-fee-display`, `checkout-total` |
| **Source**             | AC-3                                                                      |
| **Note**               | N/A — no caveats                                                          |

---

## TC-SHIP-009: Switching between shipping methods updates fee dynamically

| Field                  | Value                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                    |
| **Issue**              | SHIP-9                                                                                                     |
| **Automation Score**   | HIGH (56/67.5)                                                                                             |
| **ISTQB Technique**    | State Transition — valid transition between standard and express states                                    |
| **Manual Env**         | Local, Staging                                                                                             |
| **Precondition**       | Not logged in; cart contains items totaling $25.00; checkout page open with "Standard Shipping" selected  |
| **Steps**              | 1. Confirm shipping fee displays "$5.99" <br> 2. Click "Express Shipping" <br> 3. Confirm new fee displays |
| **Expected**           | Fee updates from "$5.99" to "$12.99"; total recalculated to $37.99. No delay or inconsistency.             |
| **data-testid needed** | `shipping-method-standard`, `shipping-method-express`, `shipping-fee-display`, `checkout-total`            |
| **Source**             | Added by QA (the ticket is silent on dynamic fee updates when switching methods)                           |
| **Note**               | Assumption: fee updates occur on method selection without requiring a page reload or API call confirmation |

---

## TC-SHIP-010: Membership status correctly determines shipping discount when login occurs during checkout

| Field                  | Value                                                                                                                            |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @ship @candidate`                                                                                          |
| **Issue**              | SHIP-9                                                                                                                           |
| **Automation Score**   | MEDIUM (42/67.5)                                                                                                                |
| **ISTQB Technique**    | State Transition — unauthenticated → authenticated; verify fee recalculation                                                     |
| **Manual Env**         | Local, Staging                                                                                                                   |
| **Precondition**       | Cart contains items totaling $30.00; checkout page shows non-member standard shipping fee "$5.99"                              |
| **Steps**              | 1. Click "Sign In" on checkout page <br> 2. Complete member login <br> 3. Return to checkout <br> 4. Observe shipping fee      |
| **Expected**           | After login, standard shipping fee updates to "$0.00" or "Free"; membership badge appears; total updates to $30.00 (no charge). |
| **data-testid needed** | `checkout-sign-in-btn`, `membership-badge`, `shipping-fee-display`, `checkout-total`                                            |
| **Source**             | Added by QA (the ticket is silent on fee recalculation after sign-in during checkout)                                           |
| **Note**               | Assumption: checkout page supports in-place authentication without full page reload; membership is verified server-side        |
