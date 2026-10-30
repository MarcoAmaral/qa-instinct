---
feature: Order Status Changes
feature_code: ORD
tc_count: 7
tracker_issues: [ORD-4]
risk_level: HIGH
runbook: N/A — no runbook
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-28
---

# Test Cases — Order Status Changes

| Field                | Value                                    |
| -------------------- | ---------------------------------------- |
| **Project**          | Store Order Management                   |
| **Author**           | QA Engineer — Senior QA Engineer         |
| **Date Created**     | 2026-10-28                               |
| **Last Updated**     | 2026-10-28                               |
| **Methodology**      | ISTQB CTFL v4.0 — State Transition       |

---

## TC-ORD-001: Order is created with status Placed

| Field                  | Value                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                                     |
| **Issue**              | ORD-4                                                                                 |
| **Automation Score**   | HIGH (58.5/67.5)                                                                      |
| **ISTQB Technique**    | State Transition — Initial state verification                                        |
| **Manual Env**         | Local, Staging                                                                        |
| **Precondition**       | System is ready to create a new order; no orders exist yet                            |
| **Steps**              | 1. Create a new order through the order creation interface                            |
| **Expected**           | Order is created and its status is "Placed"                                          |
| **data-testid needed** | `order-status`, `order-id`                                                            |
| **Source**             | Story requirement (order starts as Placed; no numbered AC)                            |
| **Note**               | Added as TC to verify initial state before transitions                                |

---

## TC-ORD-002: Recording payment on Placed order changes status to Paid

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                     |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (58.5/67.5)                                                      |
| **ISTQB Technique**    | State Transition — Placed → Paid (valid transition)                   |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status "Placed"                                  |
| **Steps**              | 1. Locate the order <br> 2. Click or select "Record Payment" <br> 3. Confirm payment action |
| **Expected**           | Order status changes to "Paid"                                        |
| **data-testid needed** | `order-status`, `record-payment-btn`                                  |
| **Source**             | AC-1                                                                  |
| **Note**               | N/A — no caveats                                                      |

---

## TC-ORD-003: Marking Paid order as shipped changes status to Shipped

| Field                  | Value                                                              |
| ---------------------- | ------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                  |
| **Issue**              | ORD-4                                                              |
| **Automation Score**   | HIGH (58.5/67.5)                                                   |
| **ISTQB Technique**    | State Transition — Paid → Shipped (valid transition)               |
| **Manual Env**         | Local, Staging                                                     |
| **Precondition**       | An order exists with status "Paid"                                 |
| **Steps**              | 1. Locate the order <br> 2. Click or select "Mark as Shipped" <br> 3. Confirm shipment action |
| **Expected**           | Order status changes to "Shipped"                                  |
| **data-testid needed** | `order-status`, `mark-shipped-btn`                                 |
| **Source**             | AC-2                                                               |
| **Note**               | N/A — no caveats                                                   |

---

## TC-ORD-004: Confirming delivery of Shipped order changes status to Delivered

| Field                  | Value                                                               |
| ---------------------- | ------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                   |
| **Issue**              | ORD-4                                                               |
| **Automation Score**   | HIGH (58.5/67.5)                                                    |
| **ISTQB Technique**    | State Transition — Shipped → Delivered (valid transition)           |
| **Manual Env**         | Local, Staging                                                      |
| **Precondition**       | An order exists with status "Shipped"                               |
| **Steps**              | 1. Locate the order <br> 2. Click or select "Confirm Delivery" <br> 3. Confirm delivery action |
| **Expected**           | Order status changes to "Delivered"                                 |
| **data-testid needed** | `order-status`, `confirm-delivery-btn`                              |
| **Source**             | AC-3                                                                |
| **Note**               | N/A — no caveats                                                    |

---

## TC-ORD-005: Cancelling Placed order changes status to Cancelled

| Field                  | Value                                                            |
| ---------------------- | ---------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @e2e @ord @candidate`                            |
| **Issue**              | ORD-4                                                            |
| **Automation Score**   | HIGH (58.5/67.5)                                                  |
| **ISTQB Technique**    | State Transition — Placed → Cancelled (valid transition)          |
| **Manual Env**         | Local, Staging                                                    |
| **Precondition**       | An order exists with status "Placed"                              |
| **Steps**              | 1. Locate the order <br> 2. Click or select "Cancel Order" <br> 3. Confirm cancellation |
| **Expected**           | Order status changes to "Cancelled"                               |
| **data-testid needed** | `order-status`, `cancel-order-btn`                                |
| **Source**             | AC-4                                                              |
| **Note**               | N/A — no caveats                                                  |

---

## TC-ORD-006: Cancelling Paid order changes status to Cancelled

| Field                  | Value                                                            |
| ---------------------- | ---------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @e2e @ord @candidate`                            |
| **Issue**              | ORD-4                                                            |
| **Automation Score**   | HIGH (58.5/67.5)                                                  |
| **ISTQB Technique**    | State Transition — Paid → Cancelled (valid transition)            |
| **Manual Env**         | Local, Staging                                                    |
| **Precondition**       | An order exists with status "Paid"                                |
| **Steps**              | 1. Locate the order <br> 2. Click or select "Cancel Order" <br> 3. Confirm cancellation |
| **Expected**           | Order status changes to "Cancelled"                               |
| **data-testid needed** | `order-status`, `cancel-order-btn`                                |
| **Source**             | AC-4                                                              |
| **Note**               | N/A — no caveats                                                  |

---

## TC-ORD-007: Cancelling Shipped order is refused with error message

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                                          |
| **Issue**              | ORD-4                                                                                      |
| **Automation Score**   | HIGH (58.5/67.5)                                                                           |
| **ISTQB Technique**    | State Transition — Shipped state; cancel is invalid transition                             |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | An order exists with status "Shipped"                                                      |
| **Steps**              | 1. Locate the order <br> 2. Attempt to click or select "Cancel Order"                      |
| **Expected**           | Cancellation is blocked. Error message "Shipped orders cannot be cancelled." is displayed. Order status remains "Shipped". |
| **data-testid needed** | `order-status`, `cancel-order-btn`, `error-message`                                        |
| **Source**             | AC-5                                                                                       |
| **Note**               | N/A — no caveats                                                                           |
