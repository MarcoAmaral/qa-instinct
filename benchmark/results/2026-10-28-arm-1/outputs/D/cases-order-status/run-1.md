---
feature: Order Status Changes
feature_code: ORD
tc_count: 9
tracker_issues: [ORD-4]
risk_level: HIGH
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — no spec provided
last_updated: 2026-10-28
---

# Test Cases — Order Status Changes

| Field            | Value                                           |
| ---------------- | ----------------------------------------------- |
| **Project**      | Order Management System                         |
| **Author**       | QA Engineer — Senior QA                         |
| **Date Created** | 2026-10-28                                      |
| **Last Updated** | 2026-10-28                                      |
| **Methodology**  | ISTQB CTFL v4.0 — State Transition, EP, Error Guessing |

---

## TC-ORD-001: New order is created with Placed status

| Field                  | Value                                                                |
| ---------------------- | -------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate`                                    |
| **Issue**              | ORD-4                                                                |
| **Automation Score**   | HIGH (66/67.5)                                                       |
| **ISTQB Technique**    | State Transition — initial state                                     |
| **Manual Env**         | Local, Staging                                                       |
| **Precondition**       | System is running, order creation API is available                   |
| **Steps**              | 1. Call order creation endpoint with valid order details             |
| **Expected**           | Order is created with status `Placed`                                |
| **data-testid needed** | N/A — API response validation                                        |
| **Source**             | Added by QA (the story text states: "An order is created with the status Placed") |
| **Note**               | N/A — no caveats                                                     |

---

## TC-ORD-002: Recording payment on Placed order changes status to Paid

| Field                  | Value                                                                |
| ---------------------- | -------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate`                                    |
| **Issue**              | ORD-4                                                                |
| **Automation Score**   | HIGH (60/67.5)                                                       |
| **ISTQB Technique**    | State Transition — Placed → Paid (valid transition)                  |
| **Manual Env**         | Local, Staging                                                       |
| **Precondition**       | An order exists with status `Placed`                                 |
| **Steps**              | 1. Call record-payment endpoint for the Placed order                 |
| **Expected**           | Order status changes to `Paid`                                       |
| **data-testid needed** | N/A — API response validation                                        |
| **Source**             | AC-1                                                                 |
| **Note**               | N/A — no caveats                                                     |

---

## TC-ORD-003: Marking Paid order as shipped changes status to Shipped

| Field                  | Value                                                                |
| ---------------------- | -------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate`                                    |
| **Issue**              | ORD-4                                                                |
| **Automation Score**   | HIGH (60/67.5)                                                       |
| **ISTQB Technique**    | State Transition — Paid → Shipped (valid transition)                 |
| **Manual Env**         | Local, Staging                                                       |
| **Precondition**       | An order exists with status `Paid`                                   |
| **Steps**              | 1. Call mark-shipped endpoint for the Paid order                     |
| **Expected**           | Order status changes to `Shipped`                                    |
| **data-testid needed** | N/A — API response validation                                        |
| **Source**             | AC-2                                                                 |
| **Note**               | N/A — no caveats                                                     |

---

## TC-ORD-004: Confirming delivery of Shipped order changes status to Delivered

| Field                  | Value                                                                |
| ---------------------- | -------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate`                                    |
| **Issue**              | ORD-4                                                                |
| **Automation Score**   | HIGH (60/67.5)                                                       |
| **ISTQB Technique**    | State Transition — Shipped → Delivered (valid transition)            |
| **Manual Env**         | Local, Staging                                                       |
| **Precondition**       | An order exists with status `Shipped`                                |
| **Steps**              | 1. Call confirm-delivery endpoint for the Shipped order              |
| **Expected**           | Order status changes to `Delivered`                                  |
| **data-testid needed** | N/A — API response validation                                        |
| **Source**             | AC-3                                                                 |
| **Note**               | N/A — no caveats                                                     |

---

## TC-ORD-005: Cancelling Placed order changes status to Cancelled

| Field                  | Value                                                                |
| ---------------------- | -------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                |
| **Issue**              | ORD-4                                                                |
| **Automation Score**   | HIGH (58/67.5)                                                       |
| **ISTQB Technique**    | State Transition — Placed → Cancelled (valid transition)             |
| **Manual Env**         | Local, Staging                                                       |
| **Precondition**       | An order exists with status `Placed`                                 |
| **Steps**              | 1. Call cancel-order endpoint for the Placed order                   |
| **Expected**           | Order status changes to `Cancelled`                                  |
| **data-testid needed** | N/A — API response validation                                        |
| **Source**             | AC-4                                                                 |
| **Note**               | N/A — no caveats                                                     |

---

## TC-ORD-006: Cancelling Paid order changes status to Cancelled

| Field                  | Value                                                                |
| ---------------------- | -------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                |
| **Issue**              | ORD-4                                                                |
| **Automation Score**   | HIGH (58/67.5)                                                       |
| **ISTQB Technique**    | State Transition — Paid → Cancelled (valid transition)               |
| **Manual Env**         | Local, Staging                                                       |
| **Precondition**       | An order exists with status `Paid`                                   |
| **Steps**              | 1. Call cancel-order endpoint for the Paid order                     |
| **Expected**           | Order status changes to `Cancelled`                                  |
| **data-testid needed** | N/A — API response validation                                        |
| **Source**             | AC-4                                                                 |
| **Note**               | N/A — no caveats                                                     |

---

## TC-ORD-007: Attempting to cancel Shipped order returns error

| Field                  | Value                                                                |
| ---------------------- | -------------------------------------------------------------------- |
| **Tags**               | `@sanity @p0 @api @ord @candidate`                                   |
| **Issue**              | ORD-4                                                                |
| **Automation Score**   | HIGH (56/67.5)                                                       |
| **ISTQB Technique**    | State Transition — Shipped → Cancelled (invalid transition)          |
| **Manual Env**         | Local, Staging                                                       |
| **Precondition**       | An order exists with status `Shipped`                                |
| **Steps**              | 1. Call cancel-order endpoint for the Shipped order                  |
| **Expected**           | Request fails. Error message returned: "Shipped orders cannot be cancelled." Order status remains `Shipped`. |
| **data-testid needed** | N/A — API response validation                                        |
| **Source**             | AC-5                                                                 |
| **Note**               | N/A — no caveats                                                     |

---

## TC-ORD-008: Cannot record payment on already Paid order

| Field                  | Value                                                                |
| ---------------------- | -------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                |
| **Issue**              | ORD-4                                                                |
| **Automation Score**   | MEDIUM (48/67.5)                                                     |
| **ISTQB Technique**    | State Transition — Paid → Paid (invalid transition)                  |
| **Manual Env**         | Local, Staging                                                       |
| **Precondition**       | An order exists with status `Paid`                                   |
| **Steps**              | 1. Call record-payment endpoint for the already Paid order           |
| **Expected**           | Request fails or is idempotent (order remains `Paid`, no error or idempotent success) |
| **data-testid needed** | N/A — API response validation                                        |
| **Source**             | Added by QA (the story is silent on attempted duplicate transitions) |
| **Note**               | Implementation assumption: error returned. If idempotent, update expected result. |

---

## TC-ORD-009: Cannot mark Placed order as Shipped without payment

| Field                  | Value                                                                |
| ---------------------- | -------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @api @ord @candidate`                                |
| **Issue**              | ORD-4                                                                |
| **Automation Score**   | MEDIUM (44/67.5)                                                     |
| **ISTQB Technique**    | Error Guessing — invalid state sequence                              |
| **Manual Env**         | Local, Staging                                                       |
| **Precondition**       | An order exists with status `Placed` (not yet `Paid`)                 |
| **Steps**              | 1. Call mark-shipped endpoint for the Placed order                   |
| **Expected**           | Request fails. Order status remains `Placed`. Error message indicates payment is required. |
| **data-testid needed** | N/A — API response validation                                        |
| **Source**             | Added by QA (the story implies payment must precede shipment; no explicit AC covers invalid sequences) |
| **Note**               | Implementation assumption: payment is a prerequisite for shipping. Verify with product. |
