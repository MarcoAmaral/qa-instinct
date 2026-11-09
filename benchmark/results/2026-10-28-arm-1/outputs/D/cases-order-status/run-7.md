---
feature: Order Status Management
feature_code: ORD
tc_count: 8
tracker_issues: [ORD-4]
risk_level: MEDIUM
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-28
---

# Test Cases — Order Status Management

| Field            | Value                                       |
| ---------------- | ------------------------------------------- |
| **Project**      | Order Management System                     |
| **Author**       | Senior QA Engineer                          |
| **Date Created** | 2026-10-28                                  |
| **Last Updated** | 2026-10-28                                  |
| **Methodology**  | ISTQB CTFL v4.0 — State Transition, EP     |

---

## TC-ORD-001: New order is created with Placed status

| Field                  | Value                                                                |
| ---------------------- | -------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                    |
| **Issue**              | [ORD-4]                                                              |
| **Automation Score**   | HIGH (61/67.5)                                                       |
| **ISTQB Technique**    | State Transition — initial state (Placed)                            |
| **Manual Env**         | Local, Staging                                                       |
| **Precondition**       | Order creation endpoint is accessible; no prior orders exist         |
| **Steps**              | 1. Create a new order via order creation API or UI                   |
| **Expected**           | Order is created with status `Placed`                                |
| **data-testid needed** | `order-status-display`                                               |
| **Source**             | Added by QA (the story text states initial status; no AC numbered it) |
| **Note**               | N/A — no caveats                                                     |

---

## TC-ORD-002: Recording payment on Placed order changes status to Paid

| Field                  | Value                                                               |
| ---------------------- | ------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                   |
| **Issue**              | [ORD-4]                                                             |
| **Automation Score**   | HIGH (61/67.5)                                                      |
| **ISTQB Technique**    | State Transition — Placed → Paid (valid transition)                 |
| **Manual Env**         | Local, Staging                                                      |
| **Precondition**       | An order exists with status `Placed`                                |
| **Steps**              | 1. Invoke record-payment action on the Placed order <br> 2. Verify order state |
| **Expected**           | Order status changes to `Paid`                                       |
| **data-testid needed** | `order-status-display`, `record-payment-btn`                        |
| **Source**             | AC-1                                                                 |
| **Note**               | N/A — no caveats                                                    |

---

## TC-ORD-003: Marking Paid order as shipped changes status to Shipped

| Field                  | Value                                                               |
| ---------------------- | ------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                   |
| **Issue**              | [ORD-4]                                                             |
| **Automation Score**   | HIGH (61/67.5)                                                      |
| **ISTQB Technique**    | State Transition — Paid → Shipped (valid transition)                |
| **Manual Env**         | Local, Staging                                                      |
| **Precondition**       | An order exists with status `Paid`                                  |
| **Steps**              | 1. Invoke mark-shipped action on the Paid order <br> 2. Verify order state |
| **Expected**           | Order status changes to `Shipped`                                    |
| **data-testid needed** | `order-status-display`, `mark-shipped-btn`                          |
| **Source**             | AC-2                                                                 |
| **Note**               | N/A — no caveats                                                    |

---

## TC-ORD-004: Confirming delivery on Shipped order changes status to Delivered

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                     |
| **Issue**              | [ORD-4]                                                               |
| **Automation Score**   | HIGH (61/67.5)                                                        |
| **ISTQB Technique**    | State Transition — Shipped → Delivered (valid transition)             |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Shipped`                                 |
| **Steps**              | 1. Invoke confirm-delivery action on the Shipped order <br> 2. Verify order state |
| **Expected**           | Order status changes to `Delivered`                                   |
| **data-testid needed** | `order-status-display`, `confirm-delivery-btn`                        |
| **Source**             | AC-3                                                                  |
| **Note**               | N/A — no caveats                                                     |

---

## TC-ORD-005: Cancelling a Placed order changes status to Cancelled

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                |
| **Issue**              | [ORD-4]                                                               |
| **Automation Score**   | HIGH (60/67.5)                                                        |
| **ISTQB Technique**    | State Transition — Placed → Cancelled (valid transition)              |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Placed`                                  |
| **Steps**              | 1. Invoke cancel action on the Placed order <br> 2. Verify order state |
| **Expected**           | Order status changes to `Cancelled`                                   |
| **data-testid needed** | `order-status-display`, `cancel-order-btn`                            |
| **Source**             | AC-4                                                                  |
| **Note**               | N/A — no caveats                                                     |

---

## TC-ORD-006: Cancelling a Paid order changes status to Cancelled

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                |
| **Issue**              | [ORD-4]                                                               |
| **Automation Score**   | HIGH (60/67.5)                                                        |
| **ISTQB Technique**    | State Transition — Paid → Cancelled (valid transition)                |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Paid`                                    |
| **Steps**              | 1. Invoke cancel action on the Paid order <br> 2. Verify order state  |
| **Expected**           | Order status changes to `Cancelled`                                   |
| **data-testid needed** | `order-status-display`, `cancel-order-btn`                            |
| **Source**             | AC-4                                                                  |
| **Note**               | N/A — no caveats                                                     |

---

## TC-ORD-007: Attempting to cancel a Shipped order shows error message

| Field                  | Value                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                               |
| **Issue**              | [ORD-4]                                                                              |
| **Automation Score**   | HIGH (59/67.5)                                                                      |
| **ISTQB Technique**    | State Transition — Shipped (invalid event: cancel attempted; rejection); Error Guessing |
| **Manual Env**         | Local, Staging                                                                      |
| **Precondition**       | An order exists with status `Shipped`                                                |
| **Steps**              | 1. Invoke cancel action on the Shipped order <br> 2. Observe response and order state |
| **Expected**           | Cancel action is refused. Error message reads: "Shipped orders cannot be cancelled." Order status remains `Shipped`. |
| **data-testid needed** | `order-status-display`, `cancel-order-btn`, `error-message`                          |
| **Source**             | AC-5                                                                                 |
| **Note**               | N/A — no caveats                                                                    |

---

## TC-ORD-008: Full order lifecycle: Placed → Paid → Shipped → Delivered

| Field                  | Value                                                                                                                                                          |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                                                                                                             |
| **Issue**              | [ORD-4]                                                                                                                                                        |
| **Automation Score**   | HIGH (62/67.5)                                                                                                                                               |
| **ISTQB Technique**    | State Transition — full valid path (0-switch coverage)                                                                                                       |
| **Manual Env**         | Local, Staging                                                                                                                                               |
| **Precondition**       | Order creation endpoint is accessible                                                                                                                        |
| **Steps**              | 1. Create a new order <br> 2. Record payment <br> 3. Mark as shipped <br> 4. Confirm delivery <br> 5. Verify final state                                    |
| **Expected**           | Order progresses through all states in sequence: `Placed` → `Paid` → `Shipped` → `Delivered`. Final status is `Delivered`.                                   |
| **data-testid needed** | `order-status-display`, `record-payment-btn`, `mark-shipped-btn`, `confirm-delivery-btn`                                                                     |
| **Source**             | AC-1, AC-2, AC-3                                                                                                                                             |
| **Note**               | N/A — no caveats                                                                                                                                            |
