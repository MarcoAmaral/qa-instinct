---
feature: Order Status Changes
feature_code: ORD
tc_count: 7
tracker_issues: [ORD-4]
risk_level: HIGH
runbook: N/A — status transitions are straightforward operations
implementation_pack: N/A — no implementation pack referenced
spec: N/A — spec location not provided
last_updated: 2026-10-28
---

# Test Cases — Order Status Changes

| Field                | Value                                                                |
| -------------------- | -------------------------------------------------------------------- |
| **Project**          | Order Management System                                              |
| **Author**           | Senior QA Engineer                                                   |
| **Date Created**     | 2026-10-28                                                           |
| **Last Updated**     | 2026-10-28                                                           |
| **Methodology**      | ISTQB CTFL v4.0 — State Transition, Equivalence Partitioning         |

---

## TC-ORD-001: New order is created with Placed status

| Field                  | Value                                                                                    |
| ---------------------- | ---------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                                        |
| **Issue**              | ORD-4                                                                                    |
| **Automation Score**   | HIGH (62/67.5)                                                                           |
| **ISTQB Technique**    | State Transition — Initial state (Placed is the entry point)                             |
| **Manual Env**         | Local, Staging                                                                           |
| **Precondition**       | Order creation form is accessible with valid customer and item data                     |
| **Steps**              | 1. Fill order form with customer name, email, and order items <br> 2. Click Create order |
| **Expected**           | Order is created and its status field displays "Placed"                                  |
| **data-testid needed** | `order-status-display`, `order-create-button`                                            |
| **Source**             | Added by QA (story states "An order is created with the status Placed")                  |
| **Note**               | N/A — no caveats                                                                         |

---

## TC-ORD-002: Record payment on Placed order transitions to Paid status

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                                          |
| **Issue**              | ORD-4                                                                                      |
| **Automation Score**   | HIGH (61/67.5)                                                                             |
| **ISTQB Technique**    | State Transition — valid transition (Placed → Paid)                                        |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | An order exists with status Placed; payment recording form or action is accessible         |
| **Steps**              | 1. Navigate to the Placed order <br> 2. Click Record Payment or equivalent action          |
| **Expected**           | Order status changes to "Paid" immediately; status field reflects the change              |
| **data-testid needed** | `order-status-display`, `record-payment-button`, `payment-confirmation-toast`              |
| **Source**             | AC-1                                                                                       |
| **Note**               | N/A — no caveats                                                                           |

---

## TC-ORD-003: Mark Paid order as shipped transitions to Shipped status

| Field                  | Value                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                                      |
| **Issue**              | ORD-4                                                                                  |
| **Automation Score**   | HIGH (61/67.5)                                                                         |
| **ISTQB Technique**    | State Transition — valid transition (Paid → Shipped)                                   |
| **Manual Env**         | Local, Staging                                                                         |
| **Precondition**       | An order exists with status Paid; ship action is accessible                            |
| **Steps**              | 1. Navigate to the Paid order <br> 2. Click Mark as Shipped or equivalent action       |
| **Expected**           | Order status changes to "Shipped" immediately; status field reflects the change         |
| **data-testid needed** | `order-status-display`, `mark-shipped-button`, `shipped-confirmation-toast`             |
| **Source**             | AC-2                                                                                   |
| **Note**               | N/A — no caveats                                                                       |

---

## TC-ORD-004: Confirm delivery of Shipped order transitions to Delivered status

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                                         |
| **Issue**              | ORD-4                                                                                     |
| **Automation Score**   | HIGH (61/67.5)                                                                            |
| **ISTQB Technique**    | State Transition — valid transition (Shipped → Delivered)                                 |
| **Manual Env**         | Local, Staging                                                                            |
| **Precondition**       | An order exists with status Shipped; delivery confirmation action is accessible           |
| **Steps**              | 1. Navigate to the Shipped order <br> 2. Click Confirm Delivery or equivalent action     |
| **Expected**           | Order status changes to "Delivered" immediately; status field reflects the change        |
| **data-testid needed** | `order-status-display`, `confirm-delivery-button`, `delivered-confirmation-toast`         |
| **Source**             | AC-3                                                                                      |
| **Note**               | N/A — no caveats                                                                          |

---

## TC-ORD-005: Cancel Placed order transitions to Cancelled status

| Field                  | Value                                                                                 |
| ---------------------- | --------------------------------------------------------------------------------------|
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                                |
| **Issue**              | ORD-4                                                                                 |
| **Automation Score**   | HIGH (59/67.5)                                                                        |
| **ISTQB Technique**    | State Transition — valid transition (Placed → Cancelled)                              |
| **Manual Env**         | Local, Staging                                                                        |
| **Precondition**       | An order exists with status Placed; cancel action is accessible                      |
| **Steps**              | 1. Navigate to the Placed order <br> 2. Click Cancel Order or equivalent action      |
| **Expected**           | Order status changes to "Cancelled" immediately; status field reflects the change    |
| **data-testid needed** | `order-status-display`, `cancel-order-button`, `cancel-confirmation-toast`            |
| **Source**             | AC-4                                                                                  |
| **Note**               | N/A — no caveats                                                                      |

---

## TC-ORD-006: Cancel Paid order transitions to Cancelled status

| Field                  | Value                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------|
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                               |
| **Issue**              | ORD-4                                                                                |
| **Automation Score**   | HIGH (59/67.5)                                                                       |
| **ISTQB Technique**    | State Transition — valid transition (Paid → Cancelled)                               |
| **Manual Env**         | Local, Staging                                                                       |
| **Precondition**       | An order exists with status Paid; cancel action is accessible                       |
| **Steps**              | 1. Navigate to the Paid order <br> 2. Click Cancel Order or equivalent action       |
| **Expected**           | Order status changes to "Cancelled" immediately; status field reflects the change   |
| **data-testid needed** | `order-status-display`, `cancel-order-button`, `cancel-confirmation-toast`           |
| **Source**             | AC-4                                                                                 |
| **Note**               | N/A — no caveats                                                                     |

---

## TC-ORD-007: Cancel Shipped order is refused with error message

| Field                  | Value                                                                                           |
| ---------------------- | ----------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                                          |
| **Issue**              | ORD-4                                                                                           |
| **Automation Score**   | HIGH (55/67.5)                                                                                  |
| **ISTQB Technique**    | State Transition — invalid transition attempt (Shipped → Cancelled is disallowed)                |
| **Manual Env**         | Local, Staging                                                                                  |
| **Precondition**       | An order exists with status Shipped; cancel action is available in the UI                       |
| **Steps**              | 1. Navigate to the Shipped order <br> 2. Click Cancel Order or equivalent action                |
| **Expected**           | Cancel action is refused. Error message displays: "Shipped orders cannot be cancelled." Status remains "Shipped" |
| **data-testid needed** | `order-status-display`, `cancel-order-button`, `error-message-text`                              |
| **Source**             | AC-5                                                                                            |
| **Note**               | This test verifies business rule enforcement — shipped orders are locked from cancellation      |

---

## Assumptions

- Order management system is web-based with operator-facing UI
- Status transitions are atomic operations (change completes or fails entirely)
- The error message text "Shipped orders cannot be cancelled" is exact
- Each status change produces a confirmation indicator (toast, message, or UI update)
- Delivery confirmation is a manual operator action, not automatic based on tracking events
- No automatic status progression; all transitions require explicit operator action
- Cancelled status is terminal (no further transitions from Cancelled)
- Order lookup/navigation to existing orders is already implemented
