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

| Field            | Value                                                       |
| ---------------- | ----------------------------------------------------------- |
| **Project**      | Store orders                                                |
| **Author**       | Marco — Senior QA Analyst                                   |
| **Date Created** | 2026-10-23                                                  |
| **Last Updated** | 2026-10-23                                                  |
| **Methodology**  | ISTQB CTFL v4.0 — State Transition, EP, Error Guessing      |

## Context and assumptions

The working directory holds no source code, so none of the preconditions or expected results below could be checked against an implementation. Every case rests on the story text alone. Assumptions made where the ticket is silent:

- **A1 — Interface.** The transitions are exposed as operations an operator can call (API or staff UI). Cases are written at API level; the data-testid row is N/A until the UI is known.
- **A2 — Status set.** The fixed set is exactly Placed, Paid, Shipped, Delivered, Cancelled. Delivered and Cancelled are terminal: no transition leaves them.
- **A3 — Refused transitions other than AC-5.** Any transition the story does not list (for example shipping a Placed order) is refused, the status does not change, and an error is returned. The story gives an exact message only for AC-5; other messages are not asserted word for word.
- **A4 — Tracker.** ORD-4 is the ticket ID; the base URL is unknown, so the ID is used as plain text.
- **A5 — Visibility.** "Customers and staff always see where an order is" is read as: after each transition, reading the order back returns the new status. The story has no AC for it, so it is checked inside each case's Expected rather than as its own case.

Release gate: cases tagged `@gate` (TC-ORD-002 to TC-ORD-008) answer "do the five ACs work?". The remaining cases are where invalid-transition findings come from.

---

## TC-ORD-001: New order is created with status Placed

| Field                  | Value                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate`                                                           |
| **Issue**              | ORD-4                                                                                       |
| **Automation Score**   | HIGH (64/67.5)                                                                              |
| **ISTQB Technique**    | State Transition — initial state (entry into Placed)                                        |
| **Manual Env**         | Local, Staging                                                                              |
| **Precondition**       | Operator is authenticated; no order exists for the test customer                            |
| **Steps**              | 1. Create a new order <br> 2. Read the order back                                           |
| **Expected**           | Order is created. Its status is exactly `Placed`. No other status value is ever shown.      |
| **data-testid needed** | N/A — tested at API level (assumption A1)                                                   |
| **Source**             | Added by QA (the story text says an order is created with the status Placed; no AC states it) |
| **Note**               | Precondition for every other case in this file                                              |

---

## TC-ORD-002: Recording a payment moves a Placed order to Paid

| Field                  | Value                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                     |
| **Issue**              | ORD-4                                                                                       |
| **Automation Score**   | HIGH (64/67.5)                                                                              |
| **ISTQB Technique**    | State Transition — valid transition Placed → Paid (event: payment recorded)                 |
| **Manual Env**         | Local, Staging                                                                              |
| **Precondition**       | An order exists with status `Placed` (TC-ORD-001)                                           |
| **Steps**              | 1. Record a payment on the order <br> 2. Read the order back                                |
| **Expected**           | Operation succeeds. Status is `Paid`. Reading the order again returns `Paid`.               |
| **data-testid needed** | N/A — tested at API level (assumption A1)                                                   |
| **Source**             | AC-1                                                                                        |
| **Note**               | N/A — no caveats                                                                            |

---

## TC-ORD-003: Marking a Paid order as shipped moves it to Shipped

| Field                  | Value                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                     |
| **Issue**              | ORD-4                                                                                       |
| **Automation Score**   | HIGH (64/67.5)                                                                              |
| **ISTQB Technique**    | State Transition — valid transition Paid → Shipped (event: mark shipped)                    |
| **Manual Env**         | Local, Staging                                                                              |
| **Precondition**       | An order exists with status `Paid` (TC-ORD-002)                                             |
| **Steps**              | 1. Mark the order as shipped <br> 2. Read the order back                                    |
| **Expected**           | Operation succeeds. Status is `Shipped`. Reading the order again returns `Shipped`.         |
| **data-testid needed** | N/A — tested at API level (assumption A1)                                                   |
| **Source**             | AC-2                                                                                        |
| **Note**               | N/A — no caveats                                                                            |

---

## TC-ORD-004: Confirming delivery moves a Shipped order to Delivered

| Field                  | Value                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                     |
| **Issue**              | ORD-4                                                                                       |
| **Automation Score**   | HIGH (64/67.5)                                                                              |
| **ISTQB Technique**    | State Transition — valid transition Shipped → Delivered (event: confirm delivery)           |
| **Manual Env**         | Local, Staging                                                                              |
| **Precondition**       | An order exists with status `Shipped` (TC-ORD-003)                                          |
| **Steps**              | 1. Confirm delivery of the order <br> 2. Read the order back                                |
| **Expected**           | Operation succeeds. Status is `Delivered`. Reading the order again returns `Delivered`.     |
| **data-testid needed** | N/A — tested at API level (assumption A1)                                                   |
| **Source**             | AC-3                                                                                        |
| **Note**               | N/A — no caveats                                                                            |

---

## TC-ORD-005: Full lifecycle Placed → Paid → Shipped → Delivered in one run

| Field                  | Value                                                                                                                                                       |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                                                                                     |
| **Issue**              | ORD-4                                                                                                                                                       |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                                              |
| **ISTQB Technique**    | State Transition — 1-switch sequence covering all three forward transitions on a single order                                                               |
| **Manual Env**         | Local, Staging                                                                                                                                              |
| **Precondition**       | Operator is authenticated; no order exists for the test customer                                                                                            |
| **Steps**              | 1. Create an order <br> 2. Record a payment <br> 3. Mark as shipped <br> 4. Confirm delivery <br> 5. Read the order back after each step                    |
| **Expected**           | Status after each step is, in order: `Placed`, `Paid`, `Shipped`, `Delivered`. No step is refused. No intermediate status is skipped or repeated.          |
| **data-testid needed** | N/A — tested at API level (assumption A1)                                                                                                                   |
| **Source**             | AC-1, AC-2, AC-3 (the full path)                                                                                                                            |
| **Note**               | Complements TC-ORD-002 to TC-ORD-004, which isolate each transition for diagnosis                                                                           |

---

## TC-ORD-006: Cancelling a Placed order moves it to Cancelled

| Field                  | Value                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                     |
| **Issue**              | ORD-4                                                                                       |
| **Automation Score**   | HIGH (64/67.5)                                                                              |
| **ISTQB Technique**    | State Transition — valid transition Placed → Cancelled (event: cancel)                      |
| **Manual Env**         | Local, Staging                                                                              |
| **Precondition**       | An order exists with status `Placed` (TC-ORD-001)                                           |
| **Steps**              | 1. Cancel the order <br> 2. Read the order back                                             |
| **Expected**           | Operation succeeds. Status is `Cancelled`. Reading the order again returns `Cancelled`.     |
| **data-testid needed** | N/A — tested at API level (assumption A1)                                                   |
| **Source**             | AC-4                                                                                        |
| **Note**               | N/A — no caveats                                                                            |

---

## TC-ORD-007: Cancelling a Paid order moves it to Cancelled

| Field                  | Value                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                     |
| **Issue**              | ORD-4                                                                                       |
| **Automation Score**   | HIGH (64/67.5)                                                                              |
| **ISTQB Technique**    | State Transition — valid transition Paid → Cancelled (event: cancel)                        |
| **Manual Env**         | Local, Staging                                                                              |
| **Precondition**       | An order exists with status `Paid` (TC-ORD-002)                                             |
| **Steps**              | 1. Cancel the order <br> 2. Read the order back                                             |
| **Expected**           | Operation succeeds. Status is `Cancelled`. Reading the order again returns `Cancelled`.     |
| **data-testid needed** | N/A — tested at API level (assumption A1)                                                   |
| **Source**             | AC-4                                                                                        |
| **Note**               | The story does not say whether a refund is triggered; out of scope for this case            |

---

## TC-ORD-008: Cancelling a Shipped order is refused with the exact message

| Field                  | Value                                                                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                                                                |
| **Issue**              | ORD-4                                                                                                                                  |
| **Automation Score**   | HIGH (64/67.5)                                                                                                                         |
| **ISTQB Technique**    | State Transition — invalid transition Shipped → Cancelled (event: cancel)                                                              |
| **Manual Env**         | Local, Staging                                                                                                                         |
| **Precondition**       | An order exists with status `Shipped` (TC-ORD-003)                                                                                     |
| **Steps**              | 1. Cancel the order <br> 2. Read the order back                                                                                        |
| **Expected**           | Operation is refused. Error message is exactly `Shipped orders cannot be cancelled.` (including the final full stop). Status is still `Shipped`. |
| **data-testid needed** | N/A — tested at API level (assumption A1)                                                                                              |
| **Source**             | AC-5                                                                                                                                   |
| **Note**               | The only refused transition with a message given by the ticket; assert it verbatim                                                     |

---

## TC-ORD-009: Cancelling a Delivered order is refused

| Field                  | Value                                                                                                                     |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                                                    |
| **Issue**              | ORD-4                                                                                                                     |
| **Automation Score**   | HIGH (58/67.5)                                                                                                            |
| **ISTQB Technique**    | State Transition — invalid transition Delivered → Cancelled (event: cancel)                                                |
| **Manual Env**         | Local, Staging                                                                                                            |
| **Precondition**       | An order exists with status `Delivered` (TC-ORD-004)                                                                      |
| **Steps**              | 1. Cancel the order <br> 2. Read the order back                                                                           |
| **Expected**           | Operation is refused with an error. Status is still `Delivered`.                                                          |
| **data-testid needed** | N/A — tested at API level (assumption A1)                                                                                 |
| **Source**             | Added by QA (AC-4 lists only Placed and Paid as cancellable; the ticket is silent on Delivered)                            |
| **Note**               | Assumption A2/A3: Delivered is terminal. The message text is not specified; confirm with the PO whether AC-5's wording or a different one applies |

---

## TC-ORD-010: Marking a Placed (unpaid) order as shipped is refused

| Field                  | Value                                                                                                                     |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                                                    |
| **Issue**              | ORD-4                                                                                                                     |
| **Automation Score**   | HIGH (58/67.5)                                                                                                            |
| **ISTQB Technique**    | State Transition — invalid transition Placed → Shipped (event: mark shipped)                                               |
| **Manual Env**         | Local, Staging                                                                                                            |
| **Precondition**       | An order exists with status `Placed` (TC-ORD-001)                                                                         |
| **Steps**              | 1. Mark the order as shipped <br> 2. Read the order back                                                                  |
| **Expected**           | Operation is refused with an error. Status is still `Placed`.                                                             |
| **data-testid needed** | N/A — tested at API level (assumption A1)                                                                                 |
| **Source**             | Added by QA (AC-2 allows shipping only from Paid; shipping an unpaid order would be a revenue loss)                        |
| **Note**               | Assumption A3                                                                                                             |

---

## TC-ORD-011: Confirming delivery of a Paid (unshipped) order is refused

| Field                  | Value                                                                                                                     |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                                                    |
| **Issue**              | ORD-4                                                                                                                     |
| **Automation Score**   | HIGH (58/67.5)                                                                                                            |
| **ISTQB Technique**    | State Transition — invalid transition Paid → Delivered (event: confirm delivery)                                           |
| **Manual Env**         | Local, Staging                                                                                                            |
| **Precondition**       | An order exists with status `Paid` (TC-ORD-002)                                                                           |
| **Steps**              | 1. Confirm delivery of the order <br> 2. Read the order back                                                              |
| **Expected**           | Operation is refused with an error. Status is still `Paid`.                                                               |
| **data-testid needed** | N/A — tested at API level (assumption A1)                                                                                 |
| **Source**             | Added by QA (AC-3 allows delivery only from Shipped; the ticket is silent on skipping a status)                            |
| **Note**               | Also run the same step from `Placed`; expected is the same with status still `Placed`                                     |

---

## TC-ORD-012: Recording a payment on an already Paid order is refused and status stays Paid

| Field                  | Value                                                                                                                     |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                                                    |
| **Issue**              | ORD-4                                                                                                                     |
| **Automation Score**   | HIGH (58/67.5)                                                                                                            |
| **ISTQB Technique**    | State Transition — invalid self-transition Paid → Paid (event: payment recorded twice)                                     |
| **Manual Env**         | Local, Staging                                                                                                            |
| **Precondition**       | An order exists with status `Paid` (TC-ORD-002)                                                                           |
| **Steps**              | 1. Record a payment on the order a second time <br> 2. Read the order back                                                |
| **Expected**           | Second payment is refused with an error. Status is still `Paid`. No second payment is recorded against the order.         |
| **data-testid needed** | N/A — tested at API level (assumption A1)                                                                                 |
| **Source**             | Added by QA (AC-1 applies only to a Placed order; a duplicate payment would double-charge the customer)                    |
| **Note**               | Assumption A3. If the product decides the second call should be idempotent (accepted, no change), update Expected with a dated note rather than deleting the case |

---

## TC-ORD-013: No transition leaves a Cancelled order

| Field                  | Value                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                                                                                 |
| **Issue**              | ORD-4                                                                                                                                                  |
| **Automation Score**   | HIGH (56/67.5)                                                                                                                                         |
| **ISTQB Technique**    | State Transition — invalid transitions out of terminal state Cancelled (events: payment, ship, deliver, cancel)                                         |
| **Manual Env**         | Local, Staging                                                                                                                                         |
| **Precondition**       | An order exists with status `Cancelled` (TC-ORD-006)                                                                                                   |
| **Steps**              | 1. Record a payment on the order <br> 2. Mark the order as shipped <br> 3. Confirm delivery of the order <br> 4. Cancel the order again <br> 5. Read the order back after each step |
| **Expected**           | Every operation is refused with an error. Status is `Cancelled` after each step.                                                                       |
| **data-testid needed** | N/A — tested at API level (assumption A1)                                                                                                              |
| **Source**             | Added by QA (the story says the status set is fixed; the ticket is silent on what happens after cancellation)                                          |
| **Note**               | Assumption A2: Cancelled is terminal. Four invalid events are grouped here because the precondition is the same and the result is identical; split if any step fails |

---

## TC-ORD-014: No forward transition leaves a Delivered order

| Field                  | Value                                                                                                                     |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                                                    |
| **Issue**              | ORD-4                                                                                                                     |
| **Automation Score**   | HIGH (56/67.5)                                                                                                            |
| **ISTQB Technique**    | State Transition — invalid transitions out of terminal state Delivered (events: payment, ship, deliver again)              |
| **Manual Env**         | Local, Staging                                                                                                            |
| **Precondition**       | An order exists with status `Delivered` (TC-ORD-004)                                                                      |
| **Steps**              | 1. Record a payment on the order <br> 2. Mark the order as shipped <br> 3. Confirm delivery again <br> 4. Read the order back after each step |
| **Expected**           | Every operation is refused with an error. Status is `Delivered` after each step.                                          |
| **data-testid needed** | N/A — tested at API level (assumption A1)                                                                                 |
| **Source**             | Added by QA (the story says the status set is fixed; the ticket is silent on events after delivery)                       |
| **Note**               | Cancel from Delivered is TC-ORD-009                                                                                       |

---

## TC-ORD-015: Concurrent ship and cancel on the same Paid order yield one winner

| Field                  | Value                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @api @ord @manual-only`                                                                                                               |
| **Issue**              | ORD-4                                                                                                                                                  |
| **Automation Score**   | LOW (34/67.5)                                                                                                                                          |
| **ISTQB Technique**    | Error Guessing — race condition between two valid events from the same state                                                                           |
| **Manual Env**         | Local, Staging                                                                                                                                         |
| **Precondition**       | An order exists with status `Paid` (TC-ORD-002); two operator sessions open on it                                                                      |
| **Steps**              | 1. From session A, mark the order as shipped <br> 2. At the same moment, from session B, cancel the order <br> 3. Read the order back <br> 4. Repeat 10 times on fresh Paid orders |
| **Expected**           | Exactly one of the two operations succeeds per order. The final status is either `Shipped` or `Cancelled`, never both outcomes recorded and never an unlisted status. If ship won, the cancel is refused with `Shipped orders cannot be cancelled.` |
| **data-testid needed** | N/A — tested at API level (assumption A1)                                                                                                              |
| **Source**             | Added by QA (the ticket is silent on concurrent operators; a ship-then-cancel race could cancel goods already dispatched)                               |
| **Note**               | Kept manual because the race cannot be made deterministic without a test hook in the implementation; revisit once the code is available                |

---

## Coverage summary

| State transition (event)        | Valid?  | Case(s)                  | Source       |
| ------------------------------- | ------- | ------------------------ | ------------ |
| — → Placed (create)             | Valid   | TC-ORD-001               | Added by QA  |
| Placed → Paid (payment)         | Valid   | TC-ORD-002, TC-ORD-005   | AC-1         |
| Paid → Shipped (ship)           | Valid   | TC-ORD-003, TC-ORD-005   | AC-2         |
| Shipped → Delivered (deliver)   | Valid   | TC-ORD-004, TC-ORD-005   | AC-3         |
| Placed → Cancelled (cancel)     | Valid   | TC-ORD-006               | AC-4         |
| Paid → Cancelled (cancel)       | Valid   | TC-ORD-007               | AC-4         |
| Shipped → Cancelled (cancel)    | Invalid | TC-ORD-008               | AC-5         |
| Delivered → Cancelled (cancel)  | Invalid | TC-ORD-009               | Added by QA  |
| Placed → Shipped (ship)         | Invalid | TC-ORD-010               | Added by QA  |
| Placed/Paid → Delivered         | Invalid | TC-ORD-011               | Added by QA  |
| Paid → Paid (payment again)     | Invalid | TC-ORD-012               | Added by QA  |
| Cancelled → any                 | Invalid | TC-ORD-013               | Added by QA  |
| Delivered → Paid/Shipped/Deliv. | Invalid | TC-ORD-014               | Added by QA  |
| Paid: ship ∥ cancel (race)      | Mixed   | TC-ORD-015               | Added by QA  |

All five valid transitions are covered (0-switch coverage), plus every invalid event from each of the five states.

Rules not applied: `context-discovery` and `testing-guidelines` are not loaded in this session and no `qa-rules` skill is installed, so the cases were grounded in the story text only (see "Context and assumptions") and the tag taxonomy was taken from the command's own summary.
