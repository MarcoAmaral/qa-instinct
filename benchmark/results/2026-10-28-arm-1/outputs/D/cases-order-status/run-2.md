---
feature: Order Status Changes
feature_code: ORD
tc_count: 9
tracker_issues: [ORD-4]
risk_level: MEDIUM
runbook: N/A — status transitions are state machine logic, no manual runbook needed
implementation_pack: N/A — not yet assigned
spec: N/A — not yet assigned
last_updated: 2026-10-28
---

# Test Cases — Order Status Changes

| Field                | Value                                                       |
| -------------------- | ----------------------------------------------------------- |
| **Project**          | Order Management System                                     |
| **Author**           | QA Engineer — Senior QA Engineer, ISTQB CTFL v4.0          |
| **Date Created**     | 2026-10-28                                                  |
| **Last Updated**     | 2026-10-28                                                  |
| **Methodology**      | ISTQB CTFL v4.0 — State Transition, Equivalence Partitioning, Error Guessing |

---

## TC-ORD-001: Order created with "Placed" status

| Field                  | Value                                                           |
| ---------------------- | --------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @integration @ord @candidate`                       |
| **Issue**              | ORD-4                                                           |
| **Automation Score**   | HIGH (64/67.5)                                                  |
| **ISTQB Technique**    | State Transition — initial state (Placed is the entry point)    |
| **Manual Env**         | Local, Staging                                                  |
| **Precondition**       | Order management system is available                            |
| **Steps**              | 1. Create a new order via API or UI                             |
| **Expected**           | Order is created with status "Placed"                           |
| **data-testid needed** | `order-status-display`                                          |
| **Source**             | Added by QA (the story text states initial state; no AC given)   |
| **Note**               | N/A — baseline for all subsequent transitions                   |

---

## TC-ORD-002: Recording payment on Placed order changes status to Paid

| Field                  | Value                                                           |
| ---------------------- | --------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @integration @ord @candidate`                       |
| **Issue**              | ORD-4                                                           |
| **Automation Score**   | HIGH (64/67.5)                                                  |
| **ISTQB Technique**    | State Transition — valid transition (Placed → Paid)             |
| **Manual Env**         | Local, Staging                                                  |
| **Precondition**       | An order exists with status "Placed"                            |
| **Steps**              | 1. Record a payment against the order <br> 2. Fetch the order   |
| **Expected**           | Order status changes to "Paid"                                  |
| **data-testid needed** | `order-status-display`                                          |
| **Source**             | AC-1                                                            |
| **Note**               | N/A — no caveats                                                |

---

## TC-ORD-003: Marking Paid order as shipped changes status to Shipped

| Field                  | Value                                                           |
| ---------------------- | --------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @integration @ord @candidate`                       |
| **Issue**              | ORD-4                                                           |
| **Automation Score**   | HIGH (64/67.5)                                                  |
| **ISTQB Technique**    | State Transition — valid transition (Paid → Shipped)            |
| **Manual Env**         | Local, Staging                                                  |
| **Precondition**       | An order exists with status "Paid"                              |
| **Steps**              | 1. Mark the order as shipped <br> 2. Fetch the order            |
| **Expected**           | Order status changes to "Shipped"                               |
| **data-testid needed** | `order-status-display`                                          |
| **Source**             | AC-2                                                            |
| **Note**               | N/A — no caveats                                                |

---

## TC-ORD-004: Confirming delivery of Shipped order changes status to Delivered

| Field                  | Value                                                           |
| ---------------------- | --------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @integration @ord @candidate`                       |
| **Issue**              | ORD-4                                                           |
| **Automation Score**   | HIGH (64/67.5)                                                  |
| **ISTQB Technique**    | State Transition — valid transition (Shipped → Delivered)       |
| **Manual Env**         | Local, Staging                                                  |
| **Precondition**       | An order exists with status "Shipped"                           |
| **Steps**              | 1. Confirm delivery of the order <br> 2. Fetch the order        |
| **Expected**           | Order status changes to "Delivered"                             |
| **data-testid needed** | `order-status-display`                                          |
| **Source**             | AC-3                                                            |
| **Note**               | N/A — no caveats                                                |

---

## TC-ORD-005: Cancelling Placed order changes status to Cancelled

| Field                  | Value                                                           |
| ---------------------- | --------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @integration @ord @candidate`                  |
| **Issue**              | ORD-4                                                           |
| **Automation Score**   | HIGH (64/67.5)                                                  |
| **ISTQB Technique**    | State Transition — valid transition (Placed → Cancelled)        |
| **Manual Env**         | Local, Staging                                                  |
| **Precondition**       | An order exists with status "Placed"                            |
| **Steps**              | 1. Cancel the order <br> 2. Fetch the order                     |
| **Expected**           | Order status changes to "Cancelled"                             |
| **data-testid needed** | `order-status-display`                                          |
| **Source**             | AC-4                                                            |
| **Note**               | N/A — no caveats                                                |

---

## TC-ORD-006: Cancelling Paid order changes status to Cancelled

| Field                  | Value                                                           |
| ---------------------- | --------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @integration @ord @candidate`                  |
| **Issue**              | ORD-4                                                           |
| **Automation Score**   | HIGH (64/67.5)                                                  |
| **ISTQB Technique**    | State Transition — valid transition (Paid → Cancelled)          |
| **Manual Env**         | Local, Staging                                                  |
| **Precondition**       | An order exists with status "Paid"                              |
| **Steps**              | 1. Cancel the order <br> 2. Fetch the order                     |
| **Expected**           | Order status changes to "Cancelled"                             |
| **data-testid needed** | `order-status-display`                                          |
| **Source**             | AC-4                                                            |
| **Note**               | N/A — no caveats                                                |

---

## TC-ORD-007: Cancelling Shipped order is refused with error message

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @integration @ord @candidate`                                          |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (64/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — invalid transition (Shipped ↛ Cancelled) + Error Guessing             |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status "Shipped"                                                   |
| **Steps**              | 1. Attempt to cancel the order <br> 2. Observe the response                             |
| **Expected**           | Request is refused. Error message "Shipped orders cannot be cancelled." is returned. Order status remains "Shipped" |
| **data-testid needed** | `error-message`                                                                         |
| **Source**             | AC-5                                                                                    |
| **Note**               | N/A — no caveats                                                                        |

---

## TC-ORD-008: Cannot transition directly from Placed to Shipped

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @integration @ord @candidate`                                          |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (60/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — invalid transition (Placed ↛ Shipped) + Error Guessing                |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status "Placed"                                                    |
| **Steps**              | 1. Attempt to mark the order as "Shipped" without recording payment first <br> 2. Observe the response |
| **Expected**           | Request is refused. Order status remains "Placed"                                       |
| **data-testid needed** | N/A — no UI elements asserted, error handling verified                                  |
| **Source**             | Added by QA (the ticket specifies a fixed sequence; no state may be skipped)             |
| **Note**               | N/A — enforces the Placed → Paid → Shipped sequence                                     |

---

## TC-ORD-009: Cannot transition directly from Placed to Delivered

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @integration @ord @candidate`                                          |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (60/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — invalid transition (Placed ↛ Delivered) + Error Guessing              |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status "Placed"                                                    |
| **Steps**              | 1. Attempt to mark the order as "Delivered" <br> 2. Observe the response                |
| **Expected**           | Request is refused. Order status remains "Placed"                                       |
| **data-testid needed** | N/A — no UI elements asserted, error handling verified                                  |
| **Source**             | Added by QA (the ticket specifies a fixed sequence; no state may be skipped)             |
| **Note**               | N/A — enforces the Placed → Paid → Shipped → Delivered sequence                        |
