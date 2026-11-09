---
feature: Order Status Changes
feature_code: ORD
tc_count: 8
tracker_issues: [ORD-4]
risk_level: HIGH
runbook: N/A — no runbook defined
implementation_pack: N/A — no implementation pack defined
spec: N/A — no spec provided
last_updated: 2026-10-28
---

# Test Cases — Order Status Changes

| Field            | Value                                          |
| ---------------- | ---------------------------------------------- |
| **Project**      | Orders                                         |
| **Author**       | QA Engineer — ISTQB CTFL v4.0                  |
| **Date Created** | 2026-10-28                                     |
| **Last Updated** | 2026-10-28                                     |
| **Methodology**  | ISTQB CTFL v4.0 — State Transition, EP         |

---

## TC-ORD-001: Order created with initial status Placed

| Field                  | Value                                                                         |
| ---------------------- | ----------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                             |
| **Issue**              | ORD-4                                                                         |
| **Automation Score**   | HIGH (61/67.5)                                                                |
| **ISTQB Technique**    | State Transition — valid initial state                                        |
| **Manual Env**         | Local, Staging                                                                |
| **Precondition**       | Order system is operational; no orders exist for test                         |
| **Steps**              | 1. Create a new order via API or UI <br> 2. Retrieve order details            |
| **Expected**           | Order is created successfully. Order status field shows `Placed`.             |
| **data-testid needed** | `order-status-display`, `order-create-btn`                                    |
| **Source**             | Story text (initial state: "An order is created with the status Placed")     |
| **Note**               | Assumption: order creation is available via API/UI; status is queryable       |

---

## TC-ORD-002: Record payment on Placed order changes status to Paid

| Field                  | Value                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                                    |
| **Issue**              | ORD-4                                                                                 |
| **Automation Score**   | HIGH (60/67.5)                                                                        |
| **ISTQB Technique**    | State Transition — Placed → Paid (valid transition)                                   |
| **Manual Env**         | Local, Staging                                                                        |
| **Precondition**       | Order exists with status `Placed`                                                     |
| **Steps**              | 1. Open order details <br> 2. Record a payment <br> 3. Confirm payment submission     |
| **Expected**           | Payment is recorded. Order status transitions to `Paid`. No error is displayed.       |
| **data-testid needed** | `order-status-display`, `record-payment-btn`, `payment-confirm-btn`                   |
| **Source**             | AC-1                                                                                  |
| **Note**               | Assumption: payment recording is a single action; status update is synchronous        |

---

## TC-ORD-003: Mark Paid order as shipped changes status to Shipped

| Field                  | Value                                                                             |
| ---------------------- | --------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                                |
| **Issue**              | ORD-4                                                                             |
| **Automation Score**   | HIGH (60/67.5)                                                                    |
| **ISTQB Technique**    | State Transition — Paid → Shipped (valid transition)                              |
| **Manual Env**         | Local, Staging                                                                    |
| **Precondition**       | Order exists with status `Paid`                                                   |
| **Steps**              | 1. Open order details <br> 2. Mark as shipped <br> 3. Confirm shipment action     |
| **Expected**           | Shipment is marked. Order status transitions to `Shipped`. No error is displayed. |
| **data-testid needed** | `order-status-display`, `mark-shipped-btn`, `shipment-confirm-btn`                |
| **Source**             | AC-2                                                                              |
| **Note**               | Assumption: mark-shipped is a single action; status update is synchronous         |

---

## TC-ORD-004: Confirm delivery of Shipped order changes status to Delivered

| Field                  | Value                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate`                                                    |
| **Issue**              | ORD-4                                                                                 |
| **Automation Score**   | HIGH (60/67.5)                                                                        |
| **ISTQB Technique**    | State Transition — Shipped → Delivered (valid transition)                             |
| **Manual Env**         | Local, Staging                                                                        |
| **Precondition**       | Order exists with status `Shipped`                                                    |
| **Steps**              | 1. Open order details <br> 2. Confirm delivery <br> 3. Submit delivery confirmation   |
| **Expected**           | Delivery is confirmed. Order status transitions to `Delivered`. No error is displayed. |
| **data-testid needed** | `order-status-display`, `confirm-delivery-btn`, `delivery-confirm-btn`                |
| **Source**             | AC-3                                                                                  |
| **Note**               | Assumption: confirm-delivery is a single action; status update is synchronous         |

---

## TC-ORD-005: Cancel Placed order changes status to Cancelled

| Field                  | Value                                                                            |
| ---------------------- | -------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @e2e @ord @candidate`                                           |
| **Issue**              | ORD-4                                                                            |
| **Automation Score**   | HIGH (59/67.5)                                                                   |
| **ISTQB Technique**    | State Transition — Placed → Cancelled (valid transition)                         |
| **Manual Env**         | Local, Staging                                                                   |
| **Precondition**       | Order exists with status `Placed`                                                |
| **Steps**              | 1. Open order details <br> 2. Click Cancel order <br> 3. Confirm cancellation    |
| **Expected**           | Order cancellation succeeds. Order status transitions to `Cancelled`.            |
| **data-testid needed** | `order-status-display`, `cancel-order-btn`, `cancel-confirm-btn`                 |
| **Source**             | AC-4                                                                             |
| **Note**               | Assumption: cancellation confirmation is required for UX safety                  |

---

## TC-ORD-006: Cancel Paid order changes status to Cancelled

| Field                  | Value                                                                            |
| ---------------------- | -------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @e2e @ord @candidate`                                           |
| **Issue**              | ORD-4                                                                            |
| **Automation Score**   | HIGH (59/67.5)                                                                   |
| **ISTQB Technique**    | State Transition — Paid → Cancelled (valid transition)                           |
| **Manual Env**         | Local, Staging                                                                   |
| **Precondition**       | Order exists with status `Paid`                                                  |
| **Steps**              | 1. Open order details <br> 2. Click Cancel order <br> 3. Confirm cancellation    |
| **Expected**           | Order cancellation succeeds. Order status transitions to `Cancelled`.            |
| **data-testid needed** | `order-status-display`, `cancel-order-btn`, `cancel-confirm-btn`                 |
| **Source**             | AC-4                                                                             |
| **Note**               | Assumption: Paid orders can still be cancelled; refund handling is out of scope  |

---

## TC-ORD-007: Attempt to cancel Shipped order is refused with error

| Field                  | Value                                                                                                                                     |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                                                                          |
| **Issue**              | ORD-4                                                                                                                             |
| **Automation Score**   | HIGH (58/67.5)                                                                                                                   |
| **ISTQB Technique**    | State Transition — Shipped → Cancelled (invalid transition); error path                                                         |
| **Manual Env**         | Local, Staging                                                                                                                   |
| **Precondition**       | Order exists with status `Shipped`                                                                                                |
| **Steps**              | 1. Open order details <br> 2. Click Cancel order <br> 3. Attempt to confirm cancellation                                         |
| **Expected**           | Cancellation action is blocked. Error message displays exactly: `"Shipped orders cannot be cancelled."` Order status remains `Shipped`. |
| **data-testid needed** | `order-status-display`, `cancel-order-btn`, `error-message-text`                                                                  |
| **Source**             | AC-5                                                                                                                              |
| **Note**               | Assumption: error message is exact and case-sensitive as specified in AC-5; UI prevents or rejects the action                   |

---

## TC-ORD-008: Delivered order status is terminal and cannot transition

| Field                  | Value                                                                                                    |
| ---------------------- | -------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @ord @manual-only`                                                                 |
| **Issue**              | ORD-4                                                                                                    |
| **Automation Score**   | MEDIUM (36/67.5)                                                                                         |
| **ISTQB Technique**    | State Transition — Delivered is a terminal state; no valid outbound transitions                          |
| **Manual Env**         | Local, Staging                                                                                           |
| **Precondition**       | Order exists with status `Delivered`                                                                     |
| **Steps**              | 1. Open order details <br> 2. Verify Cancel button is hidden or disabled <br> 3. Attempt to modify order |
| **Expected**           | Cancel button is not available. Order details are read-only or modification controls are disabled. Status remains `Delivered`. |
| **data-testid needed** | `order-status-display`, `cancel-order-btn`                                                               |
| **Source**             | Added by QA (the story is silent on final state behavior; implied by AC-5 logic)                         |
| **Note**               | Assumption: `Delivered` is a terminal state where no further status transitions are allowed              |
