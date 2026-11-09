---
feature: Order Status Management
feature_code: ORD
tc_count: 8
tracker_issues: [ORD-4]
risk_level: MEDIUM
runbook: N/A — standard order operations workflow
implementation_pack: N/A — not provided
spec: N/A — not provided
last_updated: 2026-10-28
---

# Test Cases — Order Status Management

| Field                | Value                           |
| -------------------- | ------------------------------- |
| **Project**          | Order Management System         |
| **Author**           | QA Engineer — ISTQB CTFL v4.0   |
| **Date Created**     | 2026-10-28                      |
| **Last Updated**     | 2026-10-28                      |
| **Methodology**      | ISTQB CTFL v4.0 — State Transition, Error Guessing |

---

## TC-ORD-001: Order is created with Placed status

| Field                  | Value                                                           |
| ---------------------- | --------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @orders @candidate`                            |
| **Issue**              | ORD-4                                                           |
| **Automation Score**   | HIGH (64/67.5)                                                  |
| **ISTQB Technique**    | State Transition — Initial state validation                     |
| **Manual Env**         | Local, Staging                                                  |
| **Precondition**       | No order exists in the system                                   |
| **Steps**              | 1. Create a new order via API or order creation form <br> 2. Retrieve the order <br> 3. Inspect the status field |
| **Expected**           | Order is created and status field equals "Placed"               |
| **data-testid needed** | `order-status-display`, `order-details-panel`                   |
| **Source**             | Added by QA (the story text states initial state; no AC numbers it) |
| **Note**               | N/A — no caveats                                                |

---

## TC-ORD-002: Payment recording on Placed order changes status to Paid

| Field                  | Value                                                                   |
| ---------------------- | ----------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @orders @candidate`                                    |
| **Issue**              | ORD-4                                                                   |
| **Automation Score**   | HIGH (62/67.5)                                                          |
| **ISTQB Technique**    | State Transition — Placed → Paid transition                             |
| **Manual Env**         | Local, Staging                                                          |
| **Precondition**       | An order exists in Placed status                                        |
| **Steps**              | 1. Open the order details <br> 2. Click "Record Payment" button <br> 3. Confirm payment amount and submit <br> 4. Observe status field |
| **Expected**           | Status changes to "Paid". Payment timestamp is recorded. Order remains editable. |
| **data-testid needed** | `order-record-payment-btn`, `order-status-display`, `payment-confirmation-msg` |
| **Source**             | AC-1                                                                    |
| **Note**               | N/A — no caveats                                                        |

---

## TC-ORD-003: Marking Paid order as shipped changes status to Shipped

| Field                  | Value                                                              |
| ---------------------- | ------------------------------------------------------------------ |
| **Tags**               | `@regression @p0 @e2e @orders @candidate`                          |
| **Issue**              | ORD-4                                                              |
| **Automation Score**   | HIGH (62/67.5)                                                     |
| **ISTQB Technique**    | State Transition — Paid → Shipped transition                       |
| **Manual Env**         | Local, Staging                                                     |
| **Precondition**       | An order exists in Paid status                                     |
| **Steps**              | 1. Open the order details <br> 2. Click "Mark as Shipped" button <br> 3. Enter or confirm shipment details <br> 4. Observe status field |
| **Expected**           | Status changes to "Shipped". Shipment timestamp is recorded. Customer notification is sent. |
| **data-testid needed** | `order-mark-shipped-btn`, `order-status-display`, `shipment-notification-msg` |
| **Source**             | AC-2                                                               |
| **Note**               | N/A — no caveats                                                   |

---

## TC-ORD-004: Confirming delivery of Shipped order changes status to Delivered

| Field                  | Value                                                                      |
| ---------------------- | -------------------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @e2e @orders @candidate`                                 |
| **Issue**              | ORD-4                                                                      |
| **Automation Score**   | HIGH (60/67.5)                                                             |
| **ISTQB Technique**    | State Transition — Shipped → Delivered transition                          |
| **Manual Env**         | Local, Staging                                                             |
| **Precondition**       | An order exists in Shipped status                                          |
| **Steps**              | 1. Open the order details <br> 2. Click "Confirm Delivery" button <br> 3. Confirm delivery timestamp <br> 4. Observe status field |
| **Expected**           | Status changes to "Delivered". Delivery timestamp is recorded. Order is marked as completed. |
| **data-testid needed** | `order-confirm-delivery-btn`, `order-status-display`, `delivery-confirmation-msg` |
| **Source**             | AC-3                                                                       |
| **Note**               | N/A — no caveats                                                           |

---

## TC-ORD-005: Cancelling Placed order changes status to Cancelled

| Field                  | Value                                                           |
| ---------------------- | --------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @orders @candidate`                       |
| **Issue**              | ORD-4                                                           |
| **Automation Score**   | HIGH (58/67.5)                                                  |
| **ISTQB Technique**    | State Transition — Placed → Cancelled transition                |
| **Manual Env**         | Local, Staging                                                  |
| **Precondition**       | An order exists in Placed status with no payment recorded       |
| **Steps**              | 1. Open the order details <br> 2. Click "Cancel Order" button <br> 3. Confirm cancellation <br> 4. Observe status field |
| **Expected**           | Status changes to "Cancelled". Cancellation timestamp is recorded. Order no longer appears in active orders. |
| **data-testid needed** | `order-cancel-btn`, `order-status-display`, `cancel-confirmation-msg` |
| **Source**             | AC-4                                                            |
| **Note**               | N/A — no caveats                                                |

---

## TC-ORD-006: Cancelling Paid order changes status to Cancelled

| Field                  | Value                                                                        |
| ---------------------- | ---------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @orders @candidate`                                   |
| **Issue**              | ORD-4                                                                        |
| **Automation Score**   | MEDIUM (45/67.5)                                                             |
| **ISTQB Technique**    | State Transition — Paid → Cancelled transition                               |
| **Manual Env**         | Local, Staging                                                               |
| **Precondition**       | An order exists in Paid status; payment has been recorded but not yet shipped |
| **Steps**              | 1. Open the order details <br> 2. Click "Cancel Order" button <br> 3. Confirm cancellation and refund <br> 4. Observe status field |
| **Expected**           | Status changes to "Cancelled". Refund is initiated (or marked pending). Cancellation timestamp is recorded. |
| **data-testid needed** | `order-cancel-btn`, `order-status-display`, `refund-initiated-msg`           |
| **Source**             | AC-4                                                                         |
| **Note**               | Assumption: Paid order cancellation initiates a refund. Refund mechanics (synchronous vs. asynchronous) not specified by ticket. |

---

## TC-ORD-007: Cancelling Shipped order is refused with error message

| Field                  | Value                                                                           |
| ---------------------- | ------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @orders @candidate`                                      |
| **Issue**              | ORD-4                                                                           |
| **Automation Score**   | HIGH (60/67.5)                                                                  |
| **ISTQB Technique**    | State Transition — Invalid transition (Shipped → Cancelled refused)             |
| **Manual Env**         | Local, Staging                                                                  |
| **Precondition**       | An order exists in Shipped status                                               |
| **Steps**              | 1. Open the order details <br> 2. Click "Cancel Order" button <br> 3. Attempt to confirm cancellation |
| **Expected**           | Cancel button is disabled OR cancellation is rejected with error message: "Shipped orders cannot be cancelled." Order status remains Shipped. |
| **data-testid needed** | `order-cancel-btn`, `order-status-display`, `error-message-shipped-cancel`      |
| **Source**             | AC-5                                                                            |
| **Note**               | Assumption: Error message is exact text quoted in AC-5; button may be disabled (preventive) or error shown on submit (reactive). Both satisfy the requirement. |

---

## TC-ORD-008: Invalid direct state transition is rejected

| Field                  | Value                                                                           |
| ---------------------- | ------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @orders @candidate`                                      |
| **Issue**              | ORD-4                                                                           |
| **Automation Score**   | MEDIUM (42/67.5)                                                                |
| **ISTQB Technique**    | Error Guessing — attempting direct transition outside the defined sequence      |
| **Manual Env**         | Local, Staging                                                                  |
| **Precondition**       | An order exists in Placed status; API request capability (direct API call or developer tools) |
| **Steps**              | 1. Attempt to transition order directly from Placed to Delivered via API or form manipulation <br> 2. Observe response |
| **Expected**           | Transition is rejected. Error message or validation failure is returned. Order remains in Placed status. |
| **data-testid needed** | N/A — API-level test or internal validation                                     |
| **Source**             | Added by QA (the ticket is silent on invalid intermediate skips; error guessing for state machine integrity) |
| **Note**               | Assumption: Only sequential state transitions are allowed (Placed → Paid → Shipped → Delivered, or → Cancelled from Placed/Paid). This test confirms the state machine enforces the sequence. |
