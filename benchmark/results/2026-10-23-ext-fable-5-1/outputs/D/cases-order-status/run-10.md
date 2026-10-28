---
feature: Order Status Changes
feature_code: ORD
tc_count: 13
tracker_issues: [ORD-4]
risk_level: HIGH
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-23
---

# Test Cases — Order Status Changes

| Field            | Value                                                        |
| ---------------- | ------------------------------------------------------------ |
| **Project**      | Store Orders                                                 |
| **Author**       | Marco — Senior QA Analyst                                    |
| **Date Created** | 2026-10-23                                                   |
| **Last Updated** | 2026-10-23                                                   |
| **Methodology**  | ISTQB CTFL v4.0 — State Transition, EP, Error Guessing       |

## Context and assumptions

The working directory is empty, so no code, API or UI could be inspected. Every `Precondition` and `Expected` below is derived from the ticket text alone and must be re-checked against the implementation when it exists. The `context-discovery` rule itself could not be loaded (no `qa-rules` skill installed), so it was applied from the summary in the command only.

Assumptions made to keep going:

- **A1 — Operations.** Four operations exist: Record payment, Mark shipped, Confirm delivery, Cancel. The ticket does not name endpoints or buttons; steps describe the action, not the control.
- **A2 — Refusal shape.** A refused transition leaves the status unchanged and surfaces a message. The ticket quotes a message only for AC-5; other refusals are expected to be rejected without a specified message.
- **A3 — Terminal states.** Delivered and Cancelled are terminal: no operation moves an order out of them. The ticket calls the set "fixed" but does not say so explicitly, so these cases are marked Added by QA.
- **A4 — Delivered cannot be cancelled.** AC-5 covers Shipped only. Cancelling a Delivered order is assumed refused, with no message specified.
- **A5 — Identifiers.** `data-testid` values are proposals; none exist yet.

State model used (0-switch coverage, CTFL §4.2.4):

| From \ Event | Record payment | Mark shipped | Confirm delivery | Cancel        |
| ------------ | -------------- | ------------ | ---------------- | ------------- |
| Placed       | Paid (AC-1)    | refused      | refused          | Cancelled (AC-4) |
| Paid         | refused        | Shipped (AC-2) | refused        | Cancelled (AC-4) |
| Shipped      | refused        | refused      | Delivered (AC-3) | refused (AC-5) |
| Delivered    | refused        | refused      | refused          | refused       |
| Cancelled    | refused        | refused      | refused          | refused       |

---

## TC-ORD-001: New order starts in Placed

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                                                    |
| **Issue**              | ORD-4                                                                                      |
| **Automation Score**   | HIGH (62/67.5)                                                                             |
| **ISTQB Technique**    | State Transition — initial state                                                           |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | Operator signed in; at least one product available to order                                |
| **Steps**              | 1. Create a new order <br> 2. Open the order detail                                        |
| **Expected**           | Order status reads exactly `Placed`. No other status is shown anywhere in the detail view. |
| **data-testid needed** | `order-status`                                                                             |
| **Source**             | Added by QA (the story text says a new order starts as Placed; no AC states it)            |
| **Note**               | Every other case depends on this one; run first.                                           |

---

## TC-ORD-002: Recording payment moves Placed to Paid

| Field                  | Value                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                                                                |
| **Issue**              | ORD-4                                                                                                  |
| **Automation Score**   | HIGH (62/67.5)                                                                                         |
| **ISTQB Technique**    | State Transition — valid transition Placed → Paid                                                      |
| **Manual Env**         | Local, Staging                                                                                         |
| **Precondition**       | An order in status `Placed` exists (TC-ORD-001)                                                        |
| **Steps**              | 1. Open the order <br> 2. Record a payment <br> 3. Reload the order detail                             |
| **Expected**           | Status reads `Paid` immediately and after reload. No error is shown.                                   |
| **data-testid needed** | `order-status`, `order-record-payment-btn`                                                             |
| **Source**             | AC-1                                                                                                   |
| **Note**               | Reload step checks persistence, not only the in-page update.                                           |

---

## TC-ORD-003: Marking shipped moves Paid to Shipped

| Field                  | Value                                                                       |
| ---------------------- | --------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                                     |
| **Issue**              | ORD-4                                                                       |
| **Automation Score**   | HIGH (62/67.5)                                                              |
| **ISTQB Technique**    | State Transition — valid transition Paid → Shipped                          |
| **Manual Env**         | Local, Staging                                                              |
| **Precondition**       | An order in status `Paid` exists (TC-ORD-002)                               |
| **Steps**              | 1. Open the order <br> 2. Mark the order as shipped <br> 3. Reload          |
| **Expected**           | Status reads `Shipped` immediately and after reload. No error is shown.     |
| **data-testid needed** | `order-status`, `order-mark-shipped-btn`                                    |
| **Source**             | AC-2                                                                        |
| **Note**               | N/A — no caveats                                                            |

---

## TC-ORD-004: Confirming delivery moves Shipped to Delivered

| Field                  | Value                                                                        |
| ---------------------- | ---------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                                      |
| **Issue**              | ORD-4                                                                        |
| **Automation Score**   | HIGH (62/67.5)                                                               |
| **ISTQB Technique**    | State Transition — valid transition Shipped → Delivered                      |
| **Manual Env**         | Local, Staging                                                               |
| **Precondition**       | An order in status `Shipped` exists (TC-ORD-003)                             |
| **Steps**              | 1. Open the order <br> 2. Confirm delivery <br> 3. Reload                    |
| **Expected**           | Status reads `Delivered` immediately and after reload. No error is shown.    |
| **data-testid needed** | `order-status`, `order-confirm-delivery-btn`                                 |
| **Source**             | AC-3                                                                         |
| **Note**               | TC-ORD-002 to TC-ORD-004 together give the full happy path Placed → Delivered. |

---

## TC-ORD-005: Cancelling a Placed order moves it to Cancelled

| Field                  | Value                                                                     |
| ---------------------- | ------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                                   |
| **Issue**              | ORD-4                                                                     |
| **Automation Score**   | HIGH (60/67.5)                                                            |
| **ISTQB Technique**    | State Transition — valid transition Placed → Cancelled                    |
| **Manual Env**         | Local, Staging                                                            |
| **Precondition**       | An order in status `Placed` exists                                        |
| **Steps**              | 1. Open the order <br> 2. Cancel the order <br> 3. Reload                 |
| **Expected**           | Status reads `Cancelled` immediately and after reload. No error is shown. |
| **data-testid needed** | `order-status`, `order-cancel-btn`                                        |
| **Source**             | AC-4                                                                      |
| **Note**               | N/A — no caveats                                                          |

---

## TC-ORD-006: Cancelling a Paid order moves it to Cancelled

| Field                  | Value                                                                              |
| ---------------------- | ---------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                                            |
| **Issue**              | ORD-4                                                                              |
| **Automation Score**   | HIGH (60/67.5)                                                                     |
| **ISTQB Technique**    | State Transition — valid transition Paid → Cancelled                               |
| **Manual Env**         | Local, Staging                                                                     |
| **Precondition**       | An order in status `Paid` exists                                                   |
| **Steps**              | 1. Open the order <br> 2. Cancel the order <br> 3. Reload                          |
| **Expected**           | Status reads `Cancelled` immediately and after reload. No error is shown.          |
| **data-testid needed** | `order-status`, `order-cancel-btn`                                                 |
| **Source**             | AC-4                                                                               |
| **Note**               | The ticket says nothing about refunding the recorded payment; out of scope here.   |

---

## TC-ORD-007: Cancelling a Shipped order is refused with the exact message

| Field                  | Value                                                                                                                              |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                                                                                            |
| **Issue**              | ORD-4                                                                                                                              |
| **Automation Score**   | HIGH (60/67.5)                                                                                                                     |
| **ISTQB Technique**    | State Transition — invalid transition Shipped → Cancelled                                                                          |
| **Manual Env**         | Local, Staging                                                                                                                     |
| **Precondition**       | An order in status `Shipped` exists                                                                                                |
| **Steps**              | 1. Open the order <br> 2. Attempt to cancel the order <br> 3. Reload                                                               |
| **Expected**           | Message shown reads exactly `Shipped orders cannot be cancelled.` (with the final full stop). Status still reads `Shipped` after reload. |
| **data-testid needed** | `order-status`, `order-cancel-btn`, `order-error-message`                                                                          |
| **Source**             | AC-5                                                                                                                               |
| **Note**               | Compare the message character for character; a near match is a fail.                                                              |

---

## TC-ORD-008: Cancelling a Delivered order is refused

| Field                  | Value                                                                                                            |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                                                           |
| **Issue**              | ORD-4                                                                                                            |
| **Automation Score**   | HIGH (55/67.5)                                                                                                   |
| **ISTQB Technique**    | State Transition — invalid transition Delivered → Cancelled                                                      |
| **Manual Env**         | Local, Staging                                                                                                   |
| **Precondition**       | An order in status `Delivered` exists                                                                            |
| **Steps**              | 1. Open the order <br> 2. Attempt to cancel the order <br> 3. Reload                                             |
| **Expected**           | Cancellation is rejected. Status still reads `Delivered` after reload. Record the message shown, if any.          |
| **data-testid needed** | `order-status`, `order-cancel-btn`, `order-error-message`                                                        |
| **Source**             | Added by QA (AC-5 covers Shipped only; the ticket is silent on cancelling Delivered orders)                       |
| **Note**               | Assumption A4. If the product decides Delivered may be cancelled, this case must be rewritten, not deleted.       |

---

## TC-ORD-009: Shipping an order that has not been paid is refused

| Field                  | Value                                                                                                     |
| ---------------------- | --------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                                                    |
| **Issue**              | ORD-4                                                                                                     |
| **Automation Score**   | HIGH (55/67.5)                                                                                            |
| **ISTQB Technique**    | State Transition — invalid transition Placed → Shipped                                                    |
| **Manual Env**         | Local, Staging                                                                                            |
| **Precondition**       | An order in status `Placed` exists                                                                        |
| **Steps**              | 1. Open the order <br> 2. Attempt to mark the order as shipped <br> 3. Reload                             |
| **Expected**           | Operation is rejected. Status still reads `Placed` after reload.                                          |
| **data-testid needed** | `order-status`, `order-mark-shipped-btn`                                                                  |
| **Source**             | Added by QA (AC-2 only allows shipping from Paid; the ticket does not say what happens from Placed)       |
| **Note**               | Highest-value skip check: shipping unpaid goods is a revenue leak.                                        |

---

## TC-ORD-010: Confirming delivery of an unshipped order is refused

| Field                  | Value                                                                                                                   |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                                                                  |
| **Issue**              | ORD-4                                                                                                                   |
| **Automation Score**   | HIGH (55/67.5)                                                                                                          |
| **ISTQB Technique**    | State Transition — invalid transitions Placed → Delivered and Paid → Delivered                                          |
| **Manual Env**         | Local, Staging                                                                                                          |
| **Precondition**       | One order in status `Placed` and one in status `Paid` exist                                                             |
| **Steps**              | 1. Open the Placed order <br> 2. Attempt to confirm delivery <br> 3. Reload <br> 4. Repeat steps 1 to 3 on the Paid order |
| **Expected**           | Both attempts are rejected. The first order still reads `Placed`; the second still reads `Paid`.                        |
| **data-testid needed** | `order-status`, `order-confirm-delivery-btn`                                                                            |
| **Source**             | Added by QA (AC-3 only allows delivery from Shipped; the ticket is silent on earlier states)                             |
| **Note**               | Two invalid transitions in one case because they share the same event and expected outcome.                            |

---

## TC-ORD-011: Recording a second payment on a non-Placed order is refused

| Field                  | Value                                                                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                                                                                |
| **Issue**              | ORD-4                                                                                                                                 |
| **Automation Score**   | MEDIUM (50/67.5)                                                                                                                      |
| **ISTQB Technique**    | State Transition — invalid transitions Paid → Paid, Shipped → Paid, Delivered → Paid, Cancelled → Paid                                |
| **Manual Env**         | Local, Staging                                                                                                                        |
| **Precondition**       | One order in each status `Paid`, `Shipped`, `Delivered`, `Cancelled` exists                                                           |
| **Steps**              | 1. Open the Paid order <br> 2. Attempt to record a payment <br> 3. Reload <br> 4. Repeat for the Shipped, Delivered and Cancelled orders |
| **Expected**           | Every attempt is rejected. Each order keeps its starting status after reload. No duplicate payment is recorded.                        |
| **data-testid needed** | `order-status`, `order-record-payment-btn`                                                                                            |
| **Source**             | Added by QA (AC-1 only allows payment from Placed; double payment is a customer-facing money risk)                                     |
| **Note**               | If payment history is visible, assert it still shows one entry for the Paid order.                                                    |

---

## TC-ORD-012: Cancelled order accepts no further transitions

| Field                  | Value                                                                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                                                                                  |
| **Issue**              | ORD-4                                                                                                                                   |
| **Automation Score**   | MEDIUM (50/67.5)                                                                                                                        |
| **ISTQB Technique**    | State Transition — terminal state Cancelled; events Mark shipped, Confirm delivery and Cancel are invalid                               |
| **Manual Env**         | Local, Staging                                                                                                                          |
| **Precondition**       | An order in status `Cancelled` exists (TC-ORD-005)                                                                                      |
| **Steps**              | 1. Open the order <br> 2. Attempt to mark shipped <br> 3. Attempt to confirm delivery <br> 4. Attempt to cancel again <br> 5. Reload   |
| **Expected**           | All three attempts are rejected. Status still reads `Cancelled` after reload.                                                           |
| **data-testid needed** | `order-status`, `order-mark-shipped-btn`, `order-confirm-delivery-btn`, `order-cancel-btn`                                              |
| **Source**             | Added by QA (the story calls the status set "fixed" but no AC says Cancelled is terminal)                                                |
| **Note**               | Assumption A3. Record payment on Cancelled is covered in TC-ORD-011.                                                                    |

---

## TC-ORD-013: Delivered order accepts no further transitions

| Field                  | Value                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                                                                   |
| **Issue**              | ORD-4                                                                                                                    |
| **Automation Score**   | MEDIUM (50/67.5)                                                                                                         |
| **ISTQB Technique**    | State Transition — terminal state Delivered; events Mark shipped and Confirm delivery are invalid                        |
| **Manual Env**         | Local, Staging                                                                                                           |
| **Precondition**       | An order in status `Delivered` exists (TC-ORD-004)                                                                       |
| **Steps**              | 1. Open the order <br> 2. Attempt to mark shipped <br> 3. Attempt to confirm delivery again <br> 4. Reload               |
| **Expected**           | Both attempts are rejected. Status still reads `Delivered` after reload.                                                 |
| **data-testid needed** | `order-status`, `order-mark-shipped-btn`, `order-confirm-delivery-btn`                                                   |
| **Source**             | Added by QA (the story calls the status set "fixed" but no AC says Delivered is terminal)                                 |
| **Note**               | Assumption A3. Cancel on Delivered is TC-ORD-008; Record payment on Delivered is TC-ORD-011.                             |

---

## Coverage summary

| Source                                   | Cases                                              |
| ---------------------------------------- | -------------------------------------------------- |
| AC-1                                     | TC-ORD-002                                         |
| AC-2                                     | TC-ORD-003                                         |
| AC-3                                     | TC-ORD-004                                         |
| AC-4                                     | TC-ORD-005, TC-ORD-006                             |
| AC-5                                     | TC-ORD-007                                         |
| Story text (initial state)               | TC-ORD-001                                         |
| Added by QA (invalid transitions)        | TC-ORD-008 to TC-ORD-013                           |

Every valid transition in the state table is exercised once (0-switch coverage). Every invalid cell is exercised at least once. Release gate: TC-ORD-001 to TC-ORD-007, tagged `@gate`.

## Open points for the product owner

- **Refusal messages.** Only AC-5 specifies wording. Decide whether the other refusals need a fixed message so TC-ORD-008 to TC-ORD-013 can assert exact text.
- **Delivered and Cancelled as terminal.** Confirm assumption A3 and A4, or the six Added-by-QA cases change.
- **Concurrency.** Two operators acting on one order at once (for example Cancel and Mark shipped submitted together on a Paid order) is not specified. No case covers it yet; add one once the expected winner is defined.

Rule not applied in full: `context-discovery` could not be loaded because no `qa-rules` skill is installed, and the working directory contains no code to ground the cases in.
