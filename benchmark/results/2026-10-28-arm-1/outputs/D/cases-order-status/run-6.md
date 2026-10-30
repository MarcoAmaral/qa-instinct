---
feature: Order Status Transitions
feature_code: ORD
tc_count: 12
tracker_issues: [ORD-4]
risk_level: HIGH
runbook: N/A — standard CRUD operations
implementation_pack: N/A
spec: tests/api/orders.spec.ts
last_updated: 2026-10-28
---

# Test Cases — Order Status Transitions

| Field                | Value                                      |
| -------------------- | ------------------------------------------ |
| **Project**          | E-Commerce Platform                        |
| **Author**           | Senior QA Engineer — ISTQB CTFL v4.0       |
| **Date Created**     | 2026-10-28                                 |
| **Last Updated**     | 2026-10-28                                 |
| **Methodology**      | ISTQB CTFL v4.0 — State Transition, EP     |

---

## TC-ORD-001: New order is created with Placed status

| Field                  | Value                                                    |
| ---------------------- | -------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate`                        |
| **Issue**              | ORD-4                                                    |
| **Automation Score**   | HIGH (65/67.5)                                           |
| **ISTQB Technique**    | State Transition — Initial state entry point             |
| **Manual Env**         | Local, Staging                                           |
| **Precondition**       | Order creation endpoint is available; no prior state     |
| **Steps**              | 1. Call POST /orders with valid order data               |
| **Expected**           | Order created successfully. Status field equals "Placed" |
| **data-testid needed** | N/A — API response assertion only                        |
| **Source**             | Story requirement (order is created with Placed status)  |
| **Note**               | Assumption: Order creation is triggered via API endpoint |

---

## TC-ORD-002: Recording payment on Placed order transitions to Paid

| Field                  | Value                                                          |
| ---------------------- | -------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate`                              |
| **Issue**              | ORD-4                                                          |
| **Automation Score**   | HIGH (63/67.5)                                                 |
| **ISTQB Technique**    | State Transition — Placed→Paid valid transition               |
| **Manual Env**         | Local, Staging                                                 |
| **Precondition**       | Order exists with status "Placed"                              |
| **Steps**              | 1. Call PUT /orders/{id}/payment with payment details <br> 2. Retrieve order status |
| **Expected**           | Status changes to "Paid". Payment details are recorded.        |
| **data-testid needed** | N/A — API response assertion only                              |
| **Source**             | AC-1                                                           |
| **Note**               | Assumption: Payment is recorded atomically with status change |

---

## TC-ORD-003: Recording payment on non-Placed order is rejected

| Field                  | Value                                                                     |
| ---------------------- | ------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                    |
| **Issue**              | ORD-4                                                                     |
| **Automation Score**   | MEDIUM (44/67.5)                                                          |
| **ISTQB Technique**    | State Transition — invalid transition (Paid/Shipped/Delivered/Cancelled)  |
| **Manual Env**         | Local, Staging                                                            |
| **Precondition**       | Order exists with status "Paid" (or Shipped/Delivered/Cancelled)          |
| **Steps**              | 1. Call PUT /orders/{id}/payment with payment details <br> 2. Check response |
| **Expected**           | Request rejected with HTTP 409 Conflict. Status unchanged. Error message indicates invalid state transition |
| **data-testid needed** | N/A — API response assertion only                                         |
| **Source**             | Added by QA (state machine rejects invalid transitions)                   |
| **Note**               | Assumption: System enforces strict state machine; one test covers all non-Placed states |

---

## TC-ORD-004: Marking Paid order as shipped transitions to Shipped

| Field                  | Value                                                          |
| ---------------------- | -------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate`                              |
| **Issue**              | ORD-4                                                          |
| **Automation Score**   | HIGH (63/67.5)                                                 |
| **ISTQB Technique**    | State Transition — Paid→Shipped valid transition              |
| **Manual Env**         | Local, Staging                                                 |
| **Precondition**       | Order exists with status "Paid"                                |
| **Steps**              | 1. Call PUT /orders/{id}/ship with shipment details <br> 2. Retrieve order status |
| **Expected**           | Status changes to "Shipped". Shipment timestamp recorded.      |
| **data-testid needed** | N/A — API response assertion only                              |
| **Source**             | AC-2                                                           |
| **Note**               | Assumption: Shipment action records timestamp and transitions status |

---

## TC-ORD-005: Marking non-Paid order as shipped is rejected

| Field                  | Value                                                                    |
| ---------------------- | ---------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                  |
| **Issue**              | ORD-4                                                                   |
| **Automation Score**   | MEDIUM (44/67.5)                                                        |
| **ISTQB Technique**    | State Transition — invalid transition (Placed/Shipped/Delivered/Cancelled) |
| **Manual Env**         | Local, Staging                                                          |
| **Precondition**       | Order exists with status "Placed" (or Shipped/Delivered/Cancelled)      |
| **Steps**              | 1. Call PUT /orders/{id}/ship with shipment details <br> 2. Check response |
| **Expected**           | Request rejected with HTTP 409 Conflict. Status unchanged.              |
| **data-testid needed** | N/A — API response assertion only                                       |
| **Source**             | Added by QA (state machine rejects invalid transitions)                 |
| **Note**               | Assumption: Payment must be recorded before shipping is allowed         |

---

## TC-ORD-006: Confirming delivery of Shipped order transitions to Delivered

| Field                  | Value                                                          |
| ---------------------- | -------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate`                              |
| **Issue**              | ORD-4                                                          |
| **Automation Score**   | HIGH (63/67.5)                                                 |
| **ISTQB Technique**    | State Transition — Shipped→Delivered valid transition          |
| **Manual Env**         | Local, Staging                                                 |
| **Precondition**       | Order exists with status "Shipped"                             |
| **Steps**              | 1. Call PUT /orders/{id}/deliver <br> 2. Retrieve order status |
| **Expected**           | Status changes to "Delivered". Delivery timestamp recorded.    |
| **data-testid needed** | N/A — API response assertion only                              |
| **Source**             | AC-3                                                           |
| **Note**               | Assumption: Delivery confirmation marks order as terminal      |

---

## TC-ORD-007: Confirming delivery of non-Shipped order is rejected

| Field                  | Value                                                                  |
| ---------------------- | ---------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                 |
| **Issue**              | ORD-4                                                                  |
| **Automation Score**   | MEDIUM (44/67.5)                                                       |
| **ISTQB Technique**    | State Transition — invalid transition (Placed/Paid/Delivered/Cancelled) |
| **Manual Env**         | Local, Staging                                                         |
| **Precondition**       | Order exists with status "Placed" (or Paid/Delivered/Cancelled)        |
| **Steps**              | 1. Call PUT /orders/{id}/deliver <br> 2. Check response                |
| **Expected**           | Request rejected with HTTP 409 Conflict. Status unchanged.             |
| **data-testid needed** | N/A — API response assertion only                                      |
| **Source**             | Added by QA (state machine rejects invalid transitions)                |
| **Note**               | Assumption: Order must be shipped before delivery can be confirmed     |

---

## TC-ORD-008: Cancelling Placed order transitions to Cancelled

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate`                                     |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (64/67.5)                                                        |
| **ISTQB Technique**    | State Transition — Placed→Cancelled valid transition                  |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | Order exists with status "Placed"                                     |
| **Steps**              | 1. Call DELETE /orders/{id} or PUT /orders/{id}/cancel <br> 2. Retrieve order status |
| **Expected**           | Status changes to "Cancelled". Cancellation timestamp recorded.       |
| **data-testid needed** | N/A — API response assertion only                                     |
| **Source**             | AC-4                                                                  |
| **Note**               | Assumption: Placed orders can be cancelled at any time before payment |

---

## TC-ORD-009: Cancelling Paid order transitions to Cancelled

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate`                                     |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (62/67.5)                                                        |
| **ISTQB Technique**    | State Transition — Paid→Cancelled valid transition                    |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | Order exists with status "Paid"                                       |
| **Steps**              | 1. Call DELETE /orders/{id} or PUT /orders/{id}/cancel <br> 2. Retrieve order status |
| **Expected**           | Status changes to "Cancelled". Cancellation timestamp and refund initiation recorded. |
| **data-testid needed** | N/A — API response assertion only                                     |
| **Source**             | AC-4                                                                  |
| **Note**               | Assumption: Paid orders can be cancelled; refund process is initiated |

---

## TC-ORD-010: Cancelling Shipped order is refused with specific error message

| Field                  | Value                                                                       |
| ---------------------- | --------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate`                                           |
| **Issue**              | ORD-4                                                                       |
| **Automation Score**   | HIGH (66/67.5)                                                              |
| **ISTQB Technique**    | State Transition — invalid transition (Shipped); error message validation   |
| **Manual Env**         | Local, Staging                                                              |
| **Precondition**       | Order exists with status "Shipped"                                          |
| **Steps**              | 1. Call DELETE /orders/{id} or PUT /orders/{id}/cancel <br> 2. Check response and error message |
| **Expected**           | Request rejected with HTTP 409 Conflict. Response body contains exactly: "Shipped orders cannot be cancelled." Status remains "Shipped". |
| **data-testid needed** | N/A — API response assertion only                                           |
| **Source**             | AC-5                                                                        |
| **Note**               | Assumption: Error message is exact string match; test validates both status code and message text |

---

## TC-ORD-011: Cancelling Delivered order is rejected

| Field                  | Value                                                                       |
| ---------------------- | --------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                      |
| **Issue**              | ORD-4                                                                       |
| **Automation Score**   | MEDIUM (48/67.5)                                                            |
| **ISTQB Technique**    | State Transition — invalid transition (Delivered is terminal)               |
| **Manual Env**         | Local, Staging                                                              |
| **Precondition**       | Order exists with status "Delivered"                                        |
| **Steps**              | 1. Call DELETE /orders/{id} or PUT /orders/{id}/cancel <br> 2. Check response |
| **Expected**           | Request rejected with HTTP 409 Conflict. Status remains "Delivered".        |
| **data-testid needed** | N/A — API response assertion only                                           |
| **Source**             | Added by QA (Delivered is a terminal state; no transitions allowed)         |
| **Note**               | Assumption: Delivered orders are immutable and cannot be cancelled          |

---

## TC-ORD-012: Cancelled order state is terminal — no transitions allowed

| Field                  | Value                                                                       |
| ---------------------- | --------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @api @ord @candidate`                                      |
| **Issue**              | ORD-4                                                                       |
| **Automation Score**   | MEDIUM (40/67.5)                                                            |
| **ISTQB Technique**    | State Transition — error guessing (attempting all transitions from terminal state) |
| **Manual Env**         | Local, Staging                                                              |
| **Precondition**       | Order exists with status "Cancelled"                                        |
| **Steps**              | 1. Attempt to record payment: Call PUT /orders/{id}/payment <br> 2. Attempt to ship: Call PUT /orders/{id}/ship <br> 3. Attempt to deliver: Call PUT /orders/{id}/deliver |
| **Expected**           | All three requests rejected with HTTP 409 Conflict. Status remains "Cancelled" after each attempt. |
| **data-testid needed** | N/A — API response assertion only                                           |
| **Source**             | Added by QA (error guessing — cancelled orders must not transition to any state) |
| **Note**               | Assumption: Cancelled is a terminal state; combines three invalid transitions to maximize coverage |
