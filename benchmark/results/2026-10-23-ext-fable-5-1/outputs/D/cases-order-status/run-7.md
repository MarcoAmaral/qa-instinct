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
| **Project**      | N/A — project name not stated in the ticket                  |
| **Author**       | Marco — Senior QA Analyst                                    |
| **Date Created** | 2026-10-23                                                   |
| **Last Updated** | 2026-10-23                                                   |
| **Methodology**  | ISTQB CTFL v4.0 — State Transition, EP, Error Guessing       |

## Assumptions

The workspace is empty, so none of the following could be verified against code. Each is stated here and repeated in the **Note** of the case it affects.

- **A1 — Status set.** The complete status set is Placed, Paid, Shipped, Delivered, Cancelled. No other status exists.
- **A2 — Operator actions.** The four operator actions are named Record payment, Mark shipped, Confirm delivery and Cancel. They are exposed through an operator API or admin UI; the cases are written at the API level and refer to the action by name, not by endpoint or button.
- **A3 — Refused transitions.** Any transition the ticket does not list is refused, the order keeps its current status, and a message is shown. The ticket only states the message for cancelling a Shipped order (AC-5); for every other refusal the exact wording is unknown and the case asserts only that the status is unchanged and an error is returned.
- **A4 — Terminal states.** Delivered and Cancelled are terminal; no action moves an order out of them.
- **A5 — Tracker.** `ORD-4` matches both Linear and Jira identifier formats and no base URL was given, so the ID is shown as plain text.
- **A6 — Order creation.** An order can be created in test setup with the operator's store and reaches Placed without any further action.

## State Transition Table

| Current \ Event | Record payment | Mark shipped  | Confirm delivery | Cancel          |
| --------------- | -------------- | ------------- | ---------------- | --------------- |
| **Placed**      | Paid (AC-1)    | refused (A3)  | refused (A3)     | Cancelled (AC-4)|
| **Paid**        | refused (A3)   | Shipped (AC-2)| refused (A3)     | Cancelled (AC-4)|
| **Shipped**     | refused (A3)   | refused (A3)  | Delivered (AC-3) | refused (AC-5)  |
| **Delivered**   | refused (A4)   | refused (A4)  | refused (A4)     | refused (A4)    |
| **Cancelled**   | refused (A4)   | refused (A4)  | refused (A4)     | refused (A4)    |

Five valid transitions and one ticket-specified invalid transition. TC-ORD-001 to TC-ORD-009 give 0-switch coverage of every valid transition; TC-ORD-010 to TC-ORD-014 cover invalid transitions, one per case.

---

## TC-ORD-001: New order starts in Placed

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate`                                                                       |
| **Issue**              | ORD-4                                                                                                   |
| **Automation Score**   | HIGH (64/67.5)                                                                                          |
| **ISTQB Technique**    | State Transition — initial state (Placed)                                                               |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Operator is authenticated. No order exists for the test customer.                                       |
| **Steps**              | 1. Create an order for the test customer <br> 2. Read the order back                                    |
| **Expected**           | The order exists and its status is exactly `Placed`. No other status appears in its status history.     |
| **data-testid needed** | N/A — API level, no UI element is asserted                                                              |
| **Source**             | Added by QA (the story text says a new order starts as Placed; no AC states it)                         |
| **Note**               | Depends on A6. Every later case uses this as its setup step.                                            |

---

## TC-ORD-002: Record payment moves Placed to Paid

| Field                  | Value                                                                                                                 |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate`                                                                                     |
| **Issue**              | ORD-4                                                                                                                 |
| **Automation Score**   | HIGH (64/67.5)                                                                                                        |
| **ISTQB Technique**    | State Transition — valid transition Placed → Paid on Record payment                                                   |
| **Manual Env**         | Local, Staging                                                                                                        |
| **Precondition**       | Operator is authenticated. An order exists with status `Placed`.                                                      |
| **Steps**              | 1. Record payment on the order <br> 2. Read the order back                                                            |
| **Expected**           | The action succeeds. The status is exactly `Paid`. Reading the order again returns `Paid` (the change is persisted).  |
| **data-testid needed** | N/A — API level, no UI element is asserted                                                                            |
| **Source**             | AC-1                                                                                                                  |
| **Note**               | Depends on A2 for the action name.                                                                                    |

---

## TC-ORD-003: Mark shipped moves Paid to Shipped

| Field                  | Value                                                                                           |
| ---------------------- | ----------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate`                                                               |
| **Issue**              | ORD-4                                                                                           |
| **Automation Score**   | HIGH (62.5/67.5)                                                                                |
| **ISTQB Technique**    | State Transition — valid transition Paid → Shipped on Mark shipped                              |
| **Manual Env**         | Local, Staging                                                                                  |
| **Precondition**       | Operator is authenticated. An order exists with status `Paid` (created, then payment recorded). |
| **Steps**              | 1. Mark the order as shipped <br> 2. Read the order back                                        |
| **Expected**           | The action succeeds. The status is exactly `Shipped` and stays `Shipped` on re-read.            |
| **data-testid needed** | N/A — API level, no UI element is asserted                                                      |
| **Source**             | AC-2                                                                                            |
| **Note**               | Depends on A2 for the action name.                                                              |

---

## TC-ORD-004: Confirm delivery moves Shipped to Delivered

| Field                  | Value                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate`                                                                                      |
| **Issue**              | ORD-4                                                                                                                  |
| **Automation Score**   | HIGH (61/67.5)                                                                                                         |
| **ISTQB Technique**    | State Transition — valid transition Shipped → Delivered on Confirm delivery                                            |
| **Manual Env**         | Local, Staging                                                                                                         |
| **Precondition**       | Operator is authenticated. An order exists with status `Shipped` (created, payment recorded, marked shipped).          |
| **Steps**              | 1. Confirm delivery of the order <br> 2. Read the order back                                                           |
| **Expected**           | The action succeeds. The status is exactly `Delivered` and stays `Delivered` on re-read.                               |
| **data-testid needed** | N/A — API level, no UI element is asserted                                                                             |
| **Source**             | AC-3                                                                                                                   |
| **Note**               | Depends on A2 for the action name.                                                                                     |

---

## TC-ORD-005: Full lifecycle Placed → Paid → Shipped → Delivered

| Field                  | Value                                                                                                                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                                                                                                                    |
| **Issue**              | ORD-4                                                                                                                                                                                      |
| **Automation Score**   | HIGH (62.5/67.5)                                                                                                                                                                           |
| **ISTQB Technique**    | State Transition — 1-switch sequence covering all three forward transitions in one run                                                                                                     |
| **Manual Env**         | Local, Staging                                                                                                                                                                             |
| **Precondition**       | Operator is authenticated. No order exists for the test customer.                                                                                                                          |
| **Steps**              | 1. Create an order and read its status <br> 2. Record payment and read its status <br> 3. Mark shipped and read its status <br> 4. Confirm delivery and read its status                     |
| **Expected**           | The statuses read after each step are, in order: `Placed`, `Paid`, `Shipped`, `Delivered`. No step is refused. If a status history is exposed, it lists exactly these four in this order. |
| **data-testid needed** | N/A — API level, no UI element is asserted                                                                                                                                                 |
| **Source**             | AC-1, AC-2, AC-3 (the full path)                                                                                                                                                           |
| **Note**               | Release-gate case: proves the forward path works end to end. Does not replace TC-ORD-002 to TC-ORD-004, which isolate the failing step.                                                     |

---

## TC-ORD-006: Cancel a Placed order

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate`                                                                       |
| **Issue**              | ORD-4                                                                                                   |
| **Automation Score**   | HIGH (64/67.5)                                                                                          |
| **ISTQB Technique**    | State Transition — valid transition Placed → Cancelled on Cancel                                        |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Operator is authenticated. An order exists with status `Placed`.                                        |
| **Steps**              | 1. Cancel the order <br> 2. Read the order back                                                         |
| **Expected**           | The action succeeds. The status is exactly `Cancelled` and stays `Cancelled` on re-read.                |
| **data-testid needed** | N/A — API level, no UI element is asserted                                                              |
| **Source**             | AC-4                                                                                                    |
| **Note**               | N/A — no caveats                                                                                        |

---

## TC-ORD-007: Cancel a Paid order

| Field                  | Value                                                                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                                                                                 |
| **Issue**              | ORD-4                                                                                                                                                   |
| **Automation Score**   | HIGH (62.5/67.5)                                                                                                                                        |
| **ISTQB Technique**    | State Transition — valid transition Paid → Cancelled on Cancel                                                                                          |
| **Manual Env**         | Local, Staging                                                                                                                                          |
| **Precondition**       | Operator is authenticated. An order exists with status `Paid`.                                                                                          |
| **Steps**              | 1. Cancel the order <br> 2. Read the order back                                                                                                         |
| **Expected**           | The action succeeds. The status is exactly `Cancelled` and stays `Cancelled` on re-read.                                                                |
| **data-testid needed** | N/A — API level, no UI element is asserted                                                                                                              |
| **Source**             | AC-4                                                                                                                                                    |
| **Note**               | Release-gate case: Paid is the last state where cancellation is allowed, so this is the boundary of the cancel rule. The ticket is silent on refunds; this case asserts status only. |

---

## TC-ORD-008: Cancelling a Shipped order is refused with the exact message

| Field                  | Value                                                                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                                                                                                                                |
| **Issue**              | ORD-4                                                                                                                                                                                                  |
| **Automation Score**   | HIGH (62.5/67.5)                                                                                                                                                                                       |
| **ISTQB Technique**    | State Transition — invalid transition Shipped → Cancelled on Cancel                                                                                                                                    |
| **Manual Env**         | Local, Staging                                                                                                                                                                                         |
| **Precondition**       | Operator is authenticated. An order exists with status `Shipped`.                                                                                                                                      |
| **Steps**              | 1. Cancel the order <br> 2. Read the order back                                                                                                                                                        |
| **Expected**           | The action is refused. The response carries the message `Shipped orders cannot be cancelled.` exactly, including the trailing full stop. The status is still `Shipped`. No `Cancelled` entry is added to any status history. |
| **data-testid needed** | N/A — API level, no UI element is asserted                                                                                                                                                             |
| **Source**             | AC-5                                                                                                                                                                                                   |
| **Note**               | Release-gate case: the only refusal the ticket specifies word for word. Compare the message by exact string, not by substring.                                                                          |

---

## TC-ORD-009: Cancelled order can still be read with status Cancelled

| Field                  | Value                                                                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                                                                |
| **Issue**              | ORD-4                                                                                                                                 |
| **Automation Score**   | HIGH (59/67.5)                                                                                                                        |
| **ISTQB Technique**    | EP — valid partition (terminal state is readable, not deleted)                                                                        |
| **Manual Env**         | Local, Staging                                                                                                                        |
| **Precondition**       | Operator is authenticated. An order was cancelled from `Placed` in a previous step.                                                   |
| **Steps**              | 1. Read the order by its ID <br> 2. List the customer's orders                                                                        |
| **Expected**           | The order is returned in both reads with status `Cancelled`. It is not deleted and does not disappear from the customer's order list. |
| **data-testid needed** | N/A — API level, no UI element is asserted                                                                                            |
| **Source**             | Added by QA (the story says staff and customers always see where an order is; a cancelled order must remain visible)                  |
| **Note**               | Depends on A4.                                                                                                                        |

---

## TC-ORD-010: Cancelling a Delivered order is refused

| Field                  | Value                                                                                                                                                                 |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                                                                                                |
| **Issue**              | ORD-4                                                                                                                                                                 |
| **Automation Score**   | HIGH (59/67.5)                                                                                                                                                        |
| **ISTQB Technique**    | State Transition — invalid transition Delivered → Cancelled on Cancel                                                                                                 |
| **Manual Env**         | Local, Staging                                                                                                                                                        |
| **Precondition**       | Operator is authenticated. An order exists with status `Delivered`.                                                                                                   |
| **Steps**              | 1. Cancel the order <br> 2. Read the order back                                                                                                                       |
| **Expected**           | The action is refused with an error. The status is still `Delivered`.                                                                                                 |
| **data-testid needed** | N/A — API level, no UI element is asserted                                                                                                                            |
| **Source**             | Added by QA (AC-4 lists only Placed and Paid as cancellable and AC-5 covers Shipped; the ticket is silent on Delivered)                                                |
| **Note**               | Depends on A3 and A4. The message wording is not specified; do not assert `Shipped orders cannot be cancelled.` here. Record the actual message in the run result for the PO to confirm. |

---

## TC-ORD-011: Cancelling an already Cancelled order is refused

| Field                  | Value                                                                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @api @ord @candidate`                                                                                                 |
| **Issue**              | ORD-4                                                                                                                                  |
| **Automation Score**   | HIGH (56/67.5)                                                                                                                         |
| **ISTQB Technique**    | State Transition — invalid transition Cancelled → Cancelled on Cancel (repeat event)                                                   |
| **Manual Env**         | Local, Staging                                                                                                                         |
| **Precondition**       | Operator is authenticated. An order exists with status `Cancelled`.                                                                    |
| **Steps**              | 1. Cancel the order a second time <br> 2. Read the order back                                                                          |
| **Expected**           | The second cancel is refused with an error (or, if the product chooses idempotency, succeeds with no change). Either way the status is `Cancelled` and no second cancellation is recorded. |
| **data-testid needed** | N/A — API level, no UI element is asserted                                                                                             |
| **Source**             | Added by QA (the ticket is silent on repeating an action on a terminal order)                                                          |
| **Note**               | Depends on A4. Refused versus idempotent is a product decision; the case fails only if the status changes or a duplicate record appears. |

---

## TC-ORD-012: Mark shipped on a Placed order is refused

| Field                  | Value                                                                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                                                                  |
| **Issue**              | ORD-4                                                                                                                                   |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                          |
| **ISTQB Technique**    | State Transition — invalid transition Placed → Shipped on Mark shipped (skips payment)                                                  |
| **Manual Env**         | Local, Staging                                                                                                                          |
| **Precondition**       | Operator is authenticated. An order exists with status `Placed`; no payment has been recorded.                                          |
| **Steps**              | 1. Mark the order as shipped <br> 2. Read the order back                                                                                |
| **Expected**           | The action is refused with an error. The status is still `Placed`.                                                                      |
| **data-testid needed** | N/A — API level, no UI element is asserted                                                                                              |
| **Source**             | Added by QA (AC-2 allows shipping only from Paid; shipping an unpaid order is the highest-cost skip and the ticket does not state the refusal) |
| **Note**               | Depends on A3. Message wording not specified.                                                                                           |

---

## TC-ORD-013: Confirm delivery on a Paid order is refused

| Field                  | Value                                                                                                              |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                                             |
| **Issue**              | ORD-4                                                                                                              |
| **Automation Score**   | HIGH (59/67.5)                                                                                                     |
| **ISTQB Technique**    | State Transition — invalid transition Paid → Delivered on Confirm delivery (skips shipping)                        |
| **Manual Env**         | Local, Staging                                                                                                     |
| **Precondition**       | Operator is authenticated. An order exists with status `Paid`; it has not been marked shipped.                     |
| **Steps**              | 1. Confirm delivery of the order <br> 2. Read the order back                                                       |
| **Expected**           | The action is refused with an error. The status is still `Paid`.                                                   |
| **data-testid needed** | N/A — API level, no UI element is asserted                                                                         |
| **Source**             | Added by QA (AC-3 allows delivery only from Shipped; the ticket does not state the refusal)                         |
| **Source**             | AC-3                                                                                                               |
| **Note**               | Depends on A3. Message wording not specified. Also run the same step from `Placed` as a variant and record both.    |

---

## TC-ORD-014: Record payment on a Cancelled order is refused

| Field                  | Value                                                                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                                                                  |
| **Issue**              | ORD-4                                                                                                                                   |
| **Automation Score**   | HIGH (59/67.5)                                                                                                                          |
| **ISTQB Technique**    | State Transition — invalid transition Cancelled → Paid on Record payment (leaving a terminal state)                                     |
| **Manual Env**         | Local, Staging                                                                                                                          |
| **Precondition**       | Operator is authenticated. An order exists with status `Cancelled` (cancelled from Placed).                                             |
| **Steps**              | 1. Record payment on the order <br> 2. Read the order back                                                                              |
| **Expected**           | The action is refused with an error. The status is still `Cancelled`. No payment is recorded against the order.                         |
| **data-testid needed** | N/A — API level, no UI element is asserted                                                                                              |
| **Source**             | Added by QA (AC-1 allows payment only from Placed; reviving a cancelled order by paying it is a money-handling risk the ticket does not cover) |
| **Note**               | Depends on A3 and A4. Also run Mark shipped and Confirm delivery against the same Cancelled order as variants and record each.           |

---

## TC-ORD-015: Concurrent Cancel and Mark shipped on the same Paid order

| Field                  | Value                                                                                                                                                                                                 |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                                                                                                                                |
| **Issue**              | ORD-4                                                                                                                                                                                                 |
| **Automation Score**   | MEDIUM (40.5/67.5)                                                                                                                                                                                    |
| **ISTQB Technique**    | Error Guessing — race between two valid events from the same state                                                                                                                                    |
| **Manual Env**         | Local, Staging                                                                                                                                                                                        |
| **Precondition**       | Operator is authenticated. An order exists with status `Paid`. Two clients can send requests at the same time.                                                                                        |
| **Steps**              | 1. Send Cancel and Mark shipped for the same order at the same moment (parallel requests) <br> 2. Read the order back <br> 3. Repeat 10 times on fresh Paid orders                                      |
| **Expected**           | In every run exactly one request succeeds and the other is refused. The final status is either `Shipped` or `Cancelled`, never both, and matches the request that succeeded. No run ends with a status history showing both transitions. |
| **data-testid needed** | N/A — API level, no UI element is asserted                                                                                                                                                            |
| **Source**             | Added by QA (the ticket is silent on concurrent operators; a lost update here ships a cancelled order)                                                                                                 |
| **Note**               | Scored MEDIUM for determinism risk. If the second request is refused with `Shipped orders cannot be cancelled.` after Mark shipped won, that satisfies AC-5 and should be recorded as such.             |

---

## Coverage Summary

| Source | Cases |
| ------ | ----- |
| AC-1 | TC-ORD-002, TC-ORD-005 |
| AC-2 | TC-ORD-003, TC-ORD-005 |
| AC-3 | TC-ORD-004, TC-ORD-005 |
| AC-4 | TC-ORD-006, TC-ORD-007 |
| AC-5 | TC-ORD-008 |
| Added by QA | TC-ORD-001, TC-ORD-009 to TC-ORD-015 |
| Release gate (`@gate`) | TC-ORD-005, TC-ORD-007, TC-ORD-008 |

Rules not applied: `context-discovery` and `testing-guidelines` were not loaded and no `qa-rules` skill is installed, so preconditions and expected results are grounded in the ticket and the assumptions above rather than in code.
