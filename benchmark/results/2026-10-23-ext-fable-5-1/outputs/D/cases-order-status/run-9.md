---
feature: Order status changes
feature_code: ORD
tc_count: 15
tracker_issues: [ORD-4]
risk_level: HIGH
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-23
---

# Test Cases — Order status changes

| Field            | Value                                                        |
| ---------------- | ------------------------------------------------------------ |
| **Project**      | Order management (project name not given in the story)       |
| **Author**       | Marco — Senior QA Analyst                                    |
| **Date Created** | 2026-10-23                                                   |
| **Last Updated** | 2026-10-23                                                   |
| **Methodology**  | ISTQB CTFL v4.0 — State Transition (0-switch and 1-switch), EP, Error Guessing |

## Scope and assumptions

The story defines a state machine with five states (Placed, Paid, Shipped, Delivered, Cancelled) and four events (record payment, mark shipped, confirm delivery, cancel). The cases below cover every valid transition (0-switch coverage), the full happy-path chain (1-switch), the one refused transition the story names, and one case per refused transition the story does not name.

Assumptions made because the information is missing:

- **No codebase was available.** The working directory is empty, so no precondition or expected result could be verified against code. Every `Precondition` and `Expected` comes from the story text alone.
- **Interface.** The four events are exposed as operations an operator can trigger (API or UI is unknown). Steps name the action, not an endpoint or button. Cases are tagged `@api` on the assumption the transitions are enforced server-side; retag if the system under test is UI-only.
- **Unlisted transitions are refused.** The story says the set of statuses is fixed. Any transition it does not list (for example shipping a Placed order) is assumed to be refused and to leave the status unchanged. No message is specified for those refusals, so only "refused, status unchanged" is asserted.
- **Delivered and Cancelled are terminal.** No event moves an order out of either state.
- **Refusal message.** AC-5 is the only transition with a quoted message; it is asserted verbatim, including the final full stop.
- **Tracker.** `ORD-4` matches the Linear and Jira ID formats and no base URL was given, so the ID is used as plain text.
- **Test data.** "A Paid order" is produced by creating an order and recording a payment on it (AC-1); "a Shipped order" by then marking it shipped (AC-2). Each case creates its own order so cases do not share state.

---

## TC-ORD-001: New order is created with status Placed

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate`                                     |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (64/67.5)                                                        |
| **ISTQB Technique**    | State Transition — initial state (entry into Placed)                  |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | Operator is signed in; a product that can be ordered exists           |
| **Steps**              | 1. Create a new order <br> 2. Read the order's status                 |
| **Expected**           | The order exists and its status is exactly `Placed`                   |
| **data-testid needed** | N/A — asserted through the order record, no UI element known          |
| **Source**             | Added by QA (the story text says a new order starts as Placed; no AC states it) |
| **Note**               | Every other case depends on this one; run it first                    |

---

## TC-ORD-002: Recording a payment moves a Placed order to Paid

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                               |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (64/67.5)                                                        |
| **ISTQB Technique**    | State Transition — valid transition Placed → Paid on "record payment" |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Placed`                                  |
| **Steps**              | 1. Record a payment on the order <br> 2. Read the order's status      |
| **Expected**           | The operation succeeds and the status is exactly `Paid`               |
| **data-testid needed** | N/A — asserted through the order record, no UI element known          |
| **Source**             | AC-1                                                                  |
| **Note**               | N/A — no caveats                                                      |

---

## TC-ORD-003: Marking as shipped moves a Paid order to Shipped

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                               |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (62.5/67.5)                                                      |
| **ISTQB Technique**    | State Transition — valid transition Paid → Shipped on "mark shipped"  |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Paid` (created, then payment recorded)   |
| **Steps**              | 1. Mark the order as shipped <br> 2. Read the order's status          |
| **Expected**           | The operation succeeds and the status is exactly `Shipped`            |
| **data-testid needed** | N/A — asserted through the order record, no UI element known          |
| **Source**             | AC-2                                                                  |
| **Note**               | N/A — no caveats                                                      |

---

## TC-ORD-004: Confirming delivery moves a Shipped order to Delivered

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                               |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (61/67.5)                                                        |
| **ISTQB Technique**    | State Transition — valid transition Shipped → Delivered on "confirm delivery" |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Shipped` (created, paid, then marked shipped) |
| **Steps**              | 1. Confirm delivery of the order <br> 2. Read the order's status      |
| **Expected**           | The operation succeeds and the status is exactly `Delivered`          |
| **data-testid needed** | N/A — asserted through the order record, no UI element known          |
| **Source**             | AC-3                                                                  |
| **Note**               | N/A — no caveats                                                      |

---

## TC-ORD-005: Cancelling a Placed order moves it to Cancelled

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                               |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (64/67.5)                                                        |
| **ISTQB Technique**    | State Transition — valid transition Placed → Cancelled on "cancel"    |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Placed`                                  |
| **Steps**              | 1. Cancel the order <br> 2. Read the order's status                   |
| **Expected**           | The operation succeeds and the status is exactly `Cancelled`          |
| **data-testid needed** | N/A — asserted through the order record, no UI element known          |
| **Source**             | AC-4                                                                  |
| **Note**               | AC-4 names two source states; TC-ORD-006 covers the other             |

---

## TC-ORD-006: Cancelling a Paid order moves it to Cancelled

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                               |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (62.5/67.5)                                                      |
| **ISTQB Technique**    | State Transition — valid transition Paid → Cancelled on "cancel"      |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Paid` (created, then payment recorded)   |
| **Steps**              | 1. Cancel the order <br> 2. Read the order's status                   |
| **Expected**           | The operation succeeds and the status is exactly `Cancelled`          |
| **data-testid needed** | N/A — asserted through the order record, no UI element known          |
| **Source**             | AC-4                                                                  |
| **Note**               | The story does not say whether a refund is triggered; not asserted here. Raise with the PO. |

---

## TC-ORD-007: Cancelling a Shipped order is refused with the exact message

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                               |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (61/67.5)                                                        |
| **ISTQB Technique**    | State Transition — invalid transition Shipped → Cancelled on "cancel" |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Shipped` (created, paid, then marked shipped) |
| **Steps**              | 1. Cancel the order <br> 2. Read the refusal message <br> 3. Read the order's status |
| **Expected**           | The operation is refused. The message is exactly `Shipped orders cannot be cancelled.` The status is still `Shipped`. |
| **data-testid needed** | N/A — asserted through the response and order record, no UI element known |
| **Source**             | AC-5                                                                  |
| **Note**               | The only refusal with a message specified in the story                |

---

## TC-ORD-008: Full happy path from Placed to Delivered in sequence

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@sanity @p1 @api @ord @candidate`                                    |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (58/67.5)                                                        |
| **ISTQB Technique**    | State Transition — 1-switch sequence Placed → Paid → Shipped → Delivered |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | Operator is signed in; a product that can be ordered exists           |
| **Steps**              | 1. Create an order and confirm status `Placed` <br> 2. Record a payment and confirm status `Paid` <br> 3. Mark as shipped and confirm status `Shipped` <br> 4. Confirm delivery and confirm status `Delivered` |
| **Expected**           | Each step succeeds and the status after each step is the one named; no step is skipped or repeated |
| **data-testid needed** | N/A — asserted through the order record, no UI element known          |
| **Source**             | AC-1, AC-2, AC-3 (the full path on one order)                         |
| **Note**               | Checks that each transition leaves the order in a state the next transition accepts; TC-ORD-002 to 004 each start from a fresh fixture and cannot catch that |

---

## TC-ORD-009: Marking a Placed order as shipped is refused

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (59.5/67.5)                                                      |
| **ISTQB Technique**    | State Transition — invalid transition Placed → Shipped (payment skipped) |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Placed`; no payment has been recorded    |
| **Steps**              | 1. Mark the order as shipped <br> 2. Read the order's status          |
| **Expected**           | The operation is refused and the status is still `Placed`             |
| **data-testid needed** | N/A — asserted through the response and order record, no UI element known |
| **Source**             | Added by QA (the story says statuses are a fixed sequence but names no rule for shipping before payment) |
| **Note**               | Refusal message not specified; assert only that the call fails and status is unchanged |

---

## TC-ORD-010: Confirming delivery of a Paid order is refused

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (58/67.5)                                                        |
| **ISTQB Technique**    | State Transition — invalid transition Paid → Delivered (shipping skipped) |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Paid` (created, then payment recorded)   |
| **Steps**              | 1. Confirm delivery of the order <br> 2. Read the order's status      |
| **Expected**           | The operation is refused and the status is still `Paid`               |
| **data-testid needed** | N/A — asserted through the response and order record, no UI element known |
| **Source**             | Added by QA (the story is silent on delivery before shipment)         |
| **Note**               | Refusal message not specified; assert only that the call fails and status is unchanged |

---

## TC-ORD-011: Recording a second payment on a Paid order is refused

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (58/67.5)                                                        |
| **ISTQB Technique**    | State Transition — invalid self-transition Paid → Paid on "record payment" |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Paid` (created, then payment recorded)   |
| **Steps**              | 1. Record a payment on the order again <br> 2. Read the order's status |
| **Expected**           | The operation is refused and the status is still `Paid`; the customer is not charged twice |
| **data-testid needed** | N/A — asserted through the response and order record, no UI element known |
| **Source**             | Added by QA (the story is silent on a repeated payment; double charging is a money risk) |
| **Note**               | If the system treats a repeated payment as idempotent success, record that as the actual behaviour and confirm with the PO |

---

## TC-ORD-012: Recording a payment on a Cancelled order is refused

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (58/67.5)                                                        |
| **ISTQB Technique**    | State Transition — invalid transition out of terminal state Cancelled → Paid |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Cancelled` (created, then cancelled)     |
| **Steps**              | 1. Record a payment on the order <br> 2. Read the order's status      |
| **Expected**           | The operation is refused and the status is still `Cancelled`          |
| **data-testid needed** | N/A — asserted through the response and order record, no UI element known |
| **Source**             | Added by QA (the story is silent on events after cancellation; Cancelled is assumed terminal) |
| **Note**               | Represents all events on a Cancelled order; extend to ship and deliver if the first run finds the state is not terminal |

---

## TC-ORD-013: Cancelling a Delivered order is refused

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (56.5/67.5)                                                      |
| **ISTQB Technique**    | State Transition — invalid transition out of terminal state Delivered → Cancelled |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Delivered` (created, paid, shipped, delivery confirmed) |
| **Steps**              | 1. Cancel the order <br> 2. Read the order's status                   |
| **Expected**           | The operation is refused and the status is still `Delivered`          |
| **data-testid needed** | N/A — asserted through the response and order record, no UI element known |
| **Source**             | Added by QA (AC-5 names only Shipped; the story is silent on cancelling a Delivered order) |
| **Note**               | Whether the AC-5 message is reused here is unspecified; record the actual message in the run result |

---

## TC-ORD-014: Cancelling an already Cancelled order is refused

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @api @ord @candidate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (56.5/67.5)                                                      |
| **ISTQB Technique**    | State Transition — invalid self-transition Cancelled → Cancelled      |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Cancelled` (created, then cancelled)     |
| **Steps**              | 1. Cancel the order again <br> 2. Read the order's status             |
| **Expected**           | The operation is refused and the status is still `Cancelled`; no second cancellation is recorded |
| **data-testid needed** | N/A — asserted through the response and order record, no UI element known |
| **Source**             | Added by QA (the story is silent on repeating a cancellation)         |
| **Note**               | If the system treats a repeat as idempotent success, record that as the actual behaviour and confirm with the PO |

---

## TC-ORD-015: Simultaneous cancel and ship on a Paid order leaves one consistent status

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @integration @ord @candidate`                        |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | MEDIUM (44/67.5)                                                      |
| **ISTQB Technique**    | Error Guessing — race condition on two conflicting events from the same state |
| **Manual Env**         | Local                                                                 |
| **Precondition**       | An order exists with status `Paid`; two operator sessions (or two parallel requests) can act on it |
| **Steps**              | 1. From session A, cancel the order <br> 2. From session B, mark the same order as shipped, sent at the same moment as step 1 <br> 3. Read the order's status <br> 4. Read both responses |
| **Expected**           | Exactly one operation succeeds and the other is refused. The final status is either `Cancelled` or `Shipped`, matching the one that succeeded. The order is never both, and never left in `Paid` with one success reported. |
| **data-testid needed** | N/A — asserted through the responses and order record, no UI element known |
| **Source**             | Added by QA (the story is silent on concurrent actions; a Paid order is the only state with two conflicting valid events) |
| **Note**               | Needs a harness that fires both requests concurrently; run on Local where timing can be controlled. Scored MEDIUM for determinism risk. |

---

## Traceability

| Source                        | Cases                                    |
| ----------------------------- | ---------------------------------------- |
| Story text (initial state)    | TC-ORD-001                               |
| AC-1                          | TC-ORD-002, TC-ORD-008                   |
| AC-2                          | TC-ORD-003, TC-ORD-008                   |
| AC-3                          | TC-ORD-004, TC-ORD-008                   |
| AC-4                          | TC-ORD-005, TC-ORD-006                   |
| AC-5                          | TC-ORD-007                               |
| Added by QA                   | TC-ORD-009 to TC-ORD-015                 |

Release gate (`@gate`): TC-ORD-002 to TC-ORD-007, one per acceptance criterion plus the second AC-4 source state. TC-ORD-001 is a prerequisite and runs first in the smoke suite.

## Open questions for the product owner

- Does cancelling a Paid order trigger a refund (TC-ORD-006)?
- Is the AC-5 message reused for other refused cancellations, or is there a generic message (TC-ORD-009, 010, 013)?
- Are repeated payments and repeated cancellations refused or treated as idempotent (TC-ORD-011, 014)?
- Are Delivered and Cancelled terminal states (TC-ORD-012, 013)?

## Rule not applied

The `context-discovery` rule could not be applied: no `qa-rules` skill is installed and the working directory contains no code. Preconditions and expected results are grounded in the story text only and are marked as assumptions above.
