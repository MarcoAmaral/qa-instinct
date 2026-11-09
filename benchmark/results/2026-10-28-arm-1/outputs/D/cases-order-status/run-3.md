---
feature: Order Status Management
feature_code: ORD
tc_count: 8
tracker_issues: [ORD-4]
risk_level: MEDIUM
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack provided
spec: N/A — implementation details unknown
last_updated: 2026-10-28
---

# Test Cases — Order Status Changes

| Field                | Value                                              |
| -------------------- | -------------------------------------------------- |
| **Project**          | Order Management System                            |
| **Author**           | Senior QA Engineer                                 |
| **Date Created**     | 2026-10-28                                         |
| **Last Updated**     | 2026-10-28                                         |
| **Methodology**      | ISTQB CTFL v4.0 — State Transition, EP, Decision Table |

---

## TC-ORD-001: New order is created with Placed status

| Field                  | Value                                             |
| ---------------------- | ------------------------------------------------- |
| **Tags**               | `@smoke @p0 @integration @ord @candidate`         |
| **Issue**              | [ORD-4](https://tracker.example.com/ORD-4)        |
| **Automation Score**   | HIGH (60/67.5)                                    |
| **ISTQB Technique**    | State Transition — initial state validation       |
| **Manual Env**         | Local, Staging                                    |
| **Precondition**       | System is ready to accept new orders              |
| **Steps**              | 1. Create a new order with order details          |
| **Expected**           | Order is created successfully. Status field equals "Placed". |
| **data-testid needed** | `order-status-display`, `order-created-response`  |
| **Source**             | Story requirement (order created as Placed; no AC explicitly states it) |
| **Note**               | Assumption: "order is created" refers to any order-creation API or UI action that persists the order. |

---

## TC-ORD-002: Payment on Placed order changes status to Paid

| Field                  | Value                                             |
| ---------------------- | ------------------------------------------------- |
| **Tags**               | `@smoke @p0 @integration @ord @candidate`         |
| **Issue**              | [ORD-4](https://tracker.example.com/ORD-4)        |
| **Automation Score**   | HIGH (62/67.5)                                    |
| **ISTQB Technique**    | State Transition — Placed → Paid (valid)         |
| **Manual Env**         | Local, Staging                                    |
| **Precondition**       | Order exists with status Placed                   |
| **Steps**              | 1. Record a payment on the order <br> 2. Retrieve order status |
| **Expected**           | Payment is recorded. Order status changes to "Paid". |
| **data-testid needed** | `record-payment-button`, `order-status-display`, `payment-success-message` |
| **Source**             | AC-1                                              |
| **Note**               | Assumption: "recording a payment" is an action (button click or API call) that marks the payment as received. |

---

## TC-ORD-003: Marking Paid order as shipped changes status to Shipped

| Field                  | Value                                             |
| ---------------------- | ------------------------------------------------- |
| **Tags**               | `@smoke @p0 @integration @ord @candidate`         |
| **Issue**              | [ORD-4](https://tracker.example.com/ORD-4)        |
| **Automation Score**   | HIGH (62/67.5)                                    |
| **ISTQB Technique**    | State Transition — Paid → Shipped (valid)        |
| **Manual Env**         | Local, Staging                                    |
| **Precondition**       | Order exists with status Paid                     |
| **Steps**              | 1. Mark the order as shipped <br> 2. Retrieve order status |
| **Expected**           | Order status changes to "Shipped".                |
| **data-testid needed** | `mark-shipped-button`, `order-status-display`     |
| **Source**             | AC-2                                              |
| **Note**               | Assumption: "marking as shipped" is a user action (button or API call) initiated by store operator. |

---

## TC-ORD-004: Confirming delivery of Shipped order changes status to Delivered

| Field                  | Value                                             |
| ---------------------- | ------------------------------------------------- |
| **Tags**               | `@smoke @p0 @integration @ord @candidate`         |
| **Issue**              | [ORD-4](https://tracker.example.com/ORD-4)        |
| **Automation Score**   | HIGH (62/67.5)                                    |
| **ISTQB Technique**    | State Transition — Shipped → Delivered (valid)   |
| **Manual Env**         | Local, Staging                                    |
| **Precondition**       | Order exists with status Shipped                  |
| **Steps**              | 1. Confirm delivery of the order <br> 2. Retrieve order status |
| **Expected**           | Order status changes to "Delivered".              |
| **data-testid needed** | `confirm-delivery-button`, `order-status-display` |
| **Source**             | AC-3                                              |
| **Note**               | Assumption: "confirming delivery" is a user action that marks the order as received by customer. |

---

## TC-ORD-005: Cancelling a Placed order changes status to Cancelled

| Field                  | Value                                             |
| ---------------------- | ------------------------------------------------- |
| **Tags**               | `@regression @p1 @integration @ord @candidate`    |
| **Issue**              | [ORD-4](https://tracker.example.com/ORD-4)        |
| **Automation Score**   | HIGH (60/67.5)                                    |
| **ISTQB Technique**    | State Transition — Placed → Cancelled (valid)    |
| **Manual Env**         | Local, Staging                                    |
| **Precondition**       | Order exists with status Placed                   |
| **Steps**              | 1. Cancel the order <br> 2. Retrieve order status |
| **Expected**           | Order status changes to "Cancelled".              |
| **data-testid needed** | `cancel-order-button`, `order-status-display`     |
| **Source**             | AC-4                                              |
| **Note**               | Assumption: Cancel is available to operators at Placed stage. |

---

## TC-ORD-006: Cancelling a Paid order changes status to Cancelled

| Field                  | Value                                             |
| ---------------------- | ------------------------------------------------- |
| **Tags**               | `@regression @p1 @integration @ord @candidate`    |
| **Issue**              | [ORD-4](https://tracker.example.com/ORD-4)        |
| **Automation Score**   | HIGH (60/67.5)                                    |
| **ISTQB Technique**    | State Transition — Paid → Cancelled (valid)      |
| **Manual Env**         | Local, Staging                                    |
| **Precondition**       | Order exists with status Paid                     |
| **Steps**              | 1. Cancel the order <br> 2. Retrieve order status |
| **Expected**           | Order status changes to "Cancelled".              |
| **data-testid needed** | `cancel-order-button`, `order-status-display`     |
| **Source**             | AC-4                                              |
| **Note**               | Assumption: Cancel is available at Paid stage (refund may be required but is out of scope for this TC). |

---

## TC-ORD-007: Cancelling a Shipped order is refused with error message

| Field                  | Value                                                                       |
| ---------------------- | --------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @integration @ord @candidate`                                   |
| **Issue**              | [ORD-4](https://tracker.example.com/ORD-4)                                  |
| **Automation Score**   | HIGH (64/67.5)                                                              |
| **ISTQB Technique**    | State Transition — Shipped → Cancelled (invalid transition)                |
| **Manual Env**         | Local, Staging                                                              |
| **Precondition**       | Order exists with status Shipped                                            |
| **Steps**              | 1. Attempt to cancel the order <br> 2. Inspect response                     |
| **Expected**           | Cancel action is rejected. Error message displays exactly: "Shipped orders cannot be cancelled." Order status remains "Shipped". |
| **data-testid needed** | `cancel-order-button`, `error-message-display`, `order-status-display`      |
| **Source**             | AC-5                                                                        |
| **Note**               | Assumption: Error message is exact text shown to user; case and punctuation must match. |

---

## TC-ORD-008: Attempting to transition from Delivered to any other state is refused

| Field                  | Value                                                                       |
| ---------------------- | --------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @integration @ord @candidate`                              |
| **Issue**              | [ORD-4](https://tracker.example.com/ORD-4)                                  |
| **Automation Score**   | MEDIUM (48/67.5)                                                            |
| **ISTQB Technique**    | State Transition — Delivered is terminal state (no valid outbound transitions) |
| **Manual Env**         | Local, Staging                                                              |
| **Precondition**       | Order exists with status Delivered                                          |
| **Steps**              | 1. Attempt to ship the order <br> 2. Attempt to cancel the order <br> 3. Attempt to record payment |
| **Expected**           | All state-change actions are unavailable or rejected. Order remains in Delivered state. No error thrown. |
| **data-testid needed** | `mark-shipped-button`, `cancel-order-button`, `record-payment-button`       |
| **Source**             | Added by QA (story is silent on Delivered being terminal; this validates the state machine is complete) |
| **Note**               | Assumption: Delivered is the final state and no further transitions are allowed. Buttons may be disabled or requests rejected. |
