---
feature: Order Status Management
feature_code: ORD
tc_count: 8
tracker_issues: ORD-4
risk_level: HIGH
runbook: N/A — feature behavior is straightforward state transitions
implementation_pack: N/A — no implementation pack provided
spec: N/A — automation spec not specified
last_updated: 2026-10-28
---

# Test Cases — Order Status Changes

| Field                | Value                                                      |
| -------------------- | ---------------------------------------------------------- |
| **Project**          | Order Management                                           |
| **Author**           | QA Engineer — Senior QA Engineer                           |
| **Date Created**     | 2026-10-28                                                 |
| **Last Updated**     | 2026-10-28                                                 |
| **Methodology**      | ISTQB CTFL v4.0 — State Transition, Equivalence Partition  |

---

## TC-ORD-001: New order is created with Placed status

| Field                  | Value                                                                      |
| ---------------------- | -------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                          |
| **Issue**              | ORD-4                                                                      |
| **Automation Score**   | HIGH (64.5/67.5)                                                           |
| **ISTQB Technique**    | EP — valid partition (order creation)                                     |
| **Manual Env**         | Local, Staging                                                             |
| **Precondition**       | Store operator is logged in, order management interface is loaded         |
| **Steps**              | 1. Create a new order <br> 2. View the order details                       |
| **Expected**           | Order status displays as "Placed"                                          |
| **data-testid needed** | `order-status-display`, `order-create-btn`                                 |
| **Source**             | Added by QA (story context: initial order state)                           |
| **Note**               | Assumption: order creation action triggers immediately and shows status   |

---

## TC-ORD-002: Recording payment on Placed order changes status to Paid

| Field                  | Value                                                                      |
| ---------------------- | -------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                          |
| **Issue**              | ORD-4                                                                      |
| **Automation Score**   | HIGH (64.5/67.5)                                                           |
| **ISTQB Technique**    | State Transition — Placed→Paid (valid transition)                         |
| **Manual Env**         | Local, Staging                                                             |
| **Precondition**       | An order exists with status "Placed"                                       |
| **Steps**              | 1. Open the order <br> 2. Click "Record Payment" <br> 3. Confirm payment  |
| **Expected**           | Order status changes to "Paid". Confirmation message is displayed.        |
| **data-testid needed** | `order-status-display`, `record-payment-btn`, `payment-confirm-btn`        |
| **Source**             | AC-1                                                                       |
| **Note**               | N/A — no caveats                                                           |

---

## TC-ORD-003: Marking Paid order as shipped changes status to Shipped

| Field                  | Value                                                                      |
| ---------------------- | -------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                          |
| **Issue**              | ORD-4                                                                      |
| **Automation Score**   | HIGH (64.5/67.5)                                                           |
| **ISTQB Technique**    | State Transition — Paid→Shipped (valid transition)                        |
| **Manual Env**         | Local, Staging                                                             |
| **Precondition**       | An order exists with status "Paid"                                         |
| **Steps**              | 1. Open the order <br> 2. Click "Mark as Shipped" <br> 3. Confirm action |
| **Expected**           | Order status changes to "Shipped". Confirmation message is displayed.     |
| **data-testid needed** | `order-status-display`, `mark-shipped-btn`, `action-confirm-btn`           |
| **Source**             | AC-2                                                                       |
| **Note**               | N/A — no caveats                                                           |

---

## TC-ORD-004: Confirming delivery of Shipped order changes status to Delivered

| Field                  | Value                                                                      |
| ---------------------- | -------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                          |
| **Issue**              | ORD-4                                                                      |
| **Automation Score**   | HIGH (64.5/67.5)                                                           |
| **ISTQB Technique**    | State Transition — Shipped→Delivered (valid transition)                   |
| **Manual Env**         | Local, Staging                                                             |
| **Precondition**       | An order exists with status "Shipped"                                      |
| **Steps**              | 1. Open the order <br> 2. Click "Confirm Delivery" <br> 3. Confirm action |
| **Expected**           | Order status changes to "Delivered". Confirmation message is displayed.   |
| **data-testid needed** | `order-status-display`, `confirm-delivery-btn`, `action-confirm-btn`       |
| **Source**             | AC-3                                                                       |
| **Note**               | N/A — no caveats                                                           |

---

## TC-ORD-005: Cancelling a Placed order changes status to Cancelled

| Field                  | Value                                                                      |
| ---------------------- | -------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p0 @e2e @ord @candidate`                                         |
| **Issue**              | ORD-4                                                                      |
| **Automation Score**   | HIGH (64.5/67.5)                                                           |
| **ISTQB Technique**    | State Transition — Placed→Cancelled (valid transition)                    |
| **Manual Env**         | Local, Staging                                                             |
| **Precondition**       | An order exists with status "Placed"                                       |
| **Steps**              | 1. Open the order <br> 2. Click "Cancel Order" <br> 3. Confirm cancellation |
| **Expected**           | Order status changes to "Cancelled". Confirmation message is displayed.   |
| **data-testid needed** | `order-status-display`, `cancel-order-btn`, `cancel-confirm-btn`           |
| **Source**             | AC-4                                                                       |
| **Note**               | N/A — no caveats                                                           |

---

## TC-ORD-006: Cancelling a Paid order changes status to Cancelled

| Field                  | Value                                                                      |
| ---------------------- | -------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p0 @e2e @ord @candidate`                                         |
| **Issue**              | ORD-4                                                                      |
| **Automation Score**   | HIGH (64.5/67.5)                                                           |
| **ISTQB Technique**    | State Transition — Paid→Cancelled (valid transition)                      |
| **Manual Env**         | Local, Staging                                                             |
| **Precondition**       | An order exists with status "Paid"                                         |
| **Steps**              | 1. Open the order <br> 2. Click "Cancel Order" <br> 3. Confirm cancellation |
| **Expected**           | Order status changes to "Cancelled". Confirmation message is displayed.   |
| **data-testid needed** | `order-status-display`, `cancel-order-btn`, `cancel-confirm-btn`           |
| **Source**             | AC-4                                                                       |
| **Note**               | N/A — no caveats                                                           |

---

## TC-ORD-007: Cancelling a Shipped order is refused with error message

| Field                  | Value                                                                      |
| ---------------------- | -------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p1 @e2e @ord @candidate`                                         |
| **Issue**              | ORD-4                                                                      |
| **Automation Score**   | HIGH (64.5/67.5)                                                           |
| **ISTQB Technique**    | State Transition — Shipped→Cancelled (invalid transition)                 |
| **Manual Env**         | Local, Staging                                                             |
| **Precondition**       | An order exists with status "Shipped"                                      |
| **Steps**              | 1. Open the order <br> 2. Click "Cancel Order" <br> 3. Attempt to confirm |
| **Expected**           | Cancel operation is blocked. Error message displays: "Shipped orders cannot be cancelled." Order status remains "Shipped". |
| **data-testid needed** | `order-status-display`, `cancel-order-btn`, `error-message`                |
| **Source**             | AC-5                                                                       |
| **Note**               | N/A — no caveats                                                           |

---

## TC-ORD-008: Invalid state transitions are prevented (Delivered order cannot transition)

| Field                  | Value                                                                      |
| ---------------------- | -------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                     |
| **Issue**              | ORD-4                                                                      |
| **Automation Score**   | HIGH (64.5/67.5)                                                           |
| **ISTQB Technique**    | State Transition — Delivered is terminal state (error guessing)            |
| **Manual Env**         | Local, Staging                                                             |
| **Precondition**       | An order exists with status "Delivered"                                    |
| **Steps**              | 1. Open the order <br> 2. Attempt to click "Cancel Order" or other state-change buttons |
| **Expected**           | No state-change actions are available. Order status remains "Delivered". UI reflects terminal state. |
| **data-testid needed** | `order-status-display`, `cancel-order-btn`                                 |
| **Source**             | Added by QA (delivered is a terminal state; the story implies no further transitions) |
| **Note**               | Assumption: Delivered is a terminal state with no further transitions allowed |
