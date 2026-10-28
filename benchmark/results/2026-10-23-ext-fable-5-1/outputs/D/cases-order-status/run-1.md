---
feature: Order status changes
feature_code: ORD
tc_count: 14
tracker_issues: [ORD-4]
risk_level: HIGH
runbook: N/A — no runbook exists for this feature
implementation_pack: N/A — no implementation pack exists
spec: N/A — not automated yet
last_updated: 2026-10-23
---

# Test Cases — Order status changes

| Field            | Value                                              |
| ---------------- | -------------------------------------------------- |
| **Project**      | N/A — not stated in the story                      |
| **Author**       | QA — Senior QA Analyst                             |
| **Date Created** | 2026-10-23                                         |
| **Last Updated** | 2026-10-23                                         |
| **Methodology**  | ISTQB CTFL v4.0 — State Transition, Error Guessing |

## Scope and assumptions

The working directory contains no source code, so the `context-discovery` rule could not be applied: no precondition or expected result below is verified against an implementation. Each is derived from the story text only.

- **A1 — Tracker.** `ORD-4` is a Jira-style key. No base URL was given, so the ID is written as plain text.
- **A2 — Interface.** The story names no UI. Cases are written at the service or API level (`@api`); each action (record payment, mark shipped, confirm delivery, cancel) is assumed to be a single operation on one order. `data-testid needed` is therefore `N/A` throughout.
- **A3 — Refusal leaves state unchanged.** A refused transition is assumed to leave the order in its current status and to persist nothing.
- **A4 — Unlisted transitions are invalid.** The story calls the status set "fixed". Any transition it does not list (ship a Placed order, cancel a Delivered order, pay twice, act on a Cancelled order) is assumed to be refused. The story gives a message only for AC-5, so the other refusals assert on status and on "a refusal" without quoting text.
- **A5 — Status model.** Five statuses: Placed, Paid, Shipped, Delivered, Cancelled. Delivered and Cancelled are terminal.

## State transition table

| From \ Event  | record payment | mark shipped  | confirm delivery | cancel                         |
| ------------- | -------------- | ------------- | ---------------- | ------------------------------ |
| **Placed**    | Paid (AC-1)    | refused (A4)  | refused (A4)     | Cancelled (AC-4)               |
| **Paid**      | refused (A4)   | Shipped (AC-2)| refused (A4)     | Cancelled (AC-4)               |
| **Shipped**   | refused (A4)   | refused (A4)  | Delivered (AC-3) | refused with message (AC-5)    |
| **Delivered** | refused (A4)   | refused (A4)  | refused (A4)     | refused (A4)                   |
| **Cancelled** | refused (A4)   | refused (A4)  | refused (A4)     | refused (A4)                   |

Valid transitions: 5. All five are covered once (0-switch coverage) by TC-ORD-002 to TC-ORD-006, and chained by TC-ORD-008. Invalid transitions: 15; the one the story specifies (AC-5) and six representative others are covered. The remaining eight are the same partition (action on a terminal or out-of-sequence state) and are noted in TC-ORD-014.

---

## TC-ORD-001: New order is created with status Placed

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                    |
| **Issue**              | ORD-4                                                                                      |
| **Automation Score**   | HIGH (62/67.5)                                                                             |
| **ISTQB Technique**    | State Transition — initial state                                                           |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | Store operator is authenticated; no order exists for the test customer                     |
| **Steps**              | 1. Create a new order <br> 2. Read the order back                                          |
| **Expected**           | The order exists and its status is exactly `Placed`.                                       |
| **data-testid needed** | N/A — no UI is specified (A2)                                                              |
| **Source**             | Added by QA (the story text says an order is created with the status Placed; no AC states it) |
| **Note**               | Every other case depends on this initial state.                                            |

---

## TC-ORD-002: Recording a payment moves a Placed order to Paid

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                    |
| **Issue**              | ORD-4                                                                                      |
| **Automation Score**   | HIGH (62/67.5)                                                                             |
| **ISTQB Technique**    | State Transition — Placed → Paid on "record payment"                                       |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | An order exists with status `Placed`                                                       |
| **Steps**              | 1. Record a payment on the order <br> 2. Read the order back                               |
| **Expected**           | The operation succeeds. Status is exactly `Paid`.                                          |
| **data-testid needed** | N/A — no UI is specified (A2)                                                              |
| **Source**             | AC-1                                                                                       |
| **Note**               | N/A — no caveats                                                                           |

---

## TC-ORD-003: Marking shipped moves a Paid order to Shipped

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                    |
| **Issue**              | ORD-4                                                                                      |
| **Automation Score**   | HIGH (60/67.5)                                                                             |
| **ISTQB Technique**    | State Transition — Paid → Shipped on "mark shipped"                                        |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | An order exists with status `Paid` (created via TC-ORD-002)                                |
| **Steps**              | 1. Mark the order as shipped <br> 2. Read the order back                                   |
| **Expected**           | The operation succeeds. Status is exactly `Shipped`.                                       |
| **data-testid needed** | N/A — no UI is specified (A2)                                                              |
| **Source**             | AC-2                                                                                       |
| **Note**               | N/A — no caveats                                                                           |

---

## TC-ORD-004: Confirming delivery moves a Shipped order to Delivered

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                    |
| **Issue**              | ORD-4                                                                                      |
| **Automation Score**   | HIGH (58/67.5)                                                                             |
| **ISTQB Technique**    | State Transition — Shipped → Delivered on "confirm delivery"                               |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | An order exists with status `Shipped` (created via TC-ORD-003)                             |
| **Steps**              | 1. Confirm delivery of the order <br> 2. Read the order back                               |
| **Expected**           | The operation succeeds. Status is exactly `Delivered`.                                     |
| **data-testid needed** | N/A — no UI is specified (A2)                                                              |
| **Source**             | AC-3                                                                                       |
| **Note**               | N/A — no caveats                                                                           |

---

## TC-ORD-005: Cancelling a Placed order moves it to Cancelled

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                    |
| **Issue**              | ORD-4                                                                                      |
| **Automation Score**   | HIGH (62/67.5)                                                                             |
| **ISTQB Technique**    | State Transition — Placed → Cancelled on "cancel"                                          |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | An order exists with status `Placed`; no payment has been recorded                         |
| **Steps**              | 1. Cancel the order <br> 2. Read the order back                                            |
| **Expected**           | The operation succeeds. Status is exactly `Cancelled`.                                     |
| **data-testid needed** | N/A — no UI is specified (A2)                                                              |
| **Source**             | AC-4                                                                                       |
| **Note**               | N/A — no caveats                                                                           |

---

## TC-ORD-006: Cancelling a Paid order moves it to Cancelled

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                    |
| **Issue**              | ORD-4                                                                                      |
| **Automation Score**   | HIGH (60/67.5)                                                                             |
| **ISTQB Technique**    | State Transition — Paid → Cancelled on "cancel"                                            |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | An order exists with status `Paid` (created via TC-ORD-002)                                |
| **Steps**              | 1. Cancel the order <br> 2. Read the order back                                            |
| **Expected**           | The operation succeeds. Status is exactly `Cancelled`.                                     |
| **data-testid needed** | N/A — no UI is specified (A2)                                                              |
| **Source**             | AC-4                                                                                       |
| **Note**               | The story says nothing about refunding the recorded payment; this case asserts status only. Raise with the PO. |

---

## TC-ORD-007: Cancelling a Shipped order is refused with the exact message

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                    |
| **Issue**              | ORD-4                                                                                      |
| **Automation Score**   | HIGH (60/67.5)                                                                             |
| **ISTQB Technique**    | State Transition — invalid transition Shipped → Cancelled                                  |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | An order exists with status `Shipped` (created via TC-ORD-003)                             |
| **Steps**              | 1. Cancel the order <br> 2. Read the order back                                            |
| **Expected**           | The operation is refused. The response carries the message `Shipped orders cannot be cancelled.` character for character, including the trailing full stop. Status is still `Shipped`. |
| **data-testid needed** | N/A — no UI is specified (A2)                                                              |
| **Source**             | AC-5                                                                                       |
| **Note**               | The only refusal whose message the story specifies.                                        |

---

## TC-ORD-008: Full lifecycle Placed → Paid → Shipped → Delivered

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@sanity @p0 @api @ord @candidate`                                                         |
| **Issue**              | ORD-4                                                                                      |
| **Automation Score**   | HIGH (57/67.5)                                                                             |
| **ISTQB Technique**    | State Transition — 2-switch sequence through the happy path                                |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | Store operator is authenticated                                                            |
| **Steps**              | 1. Create an order and confirm status `Placed` <br> 2. Record a payment <br> 3. Mark as shipped <br> 4. Confirm delivery <br> 5. Read the order back after each step |
| **Expected**           | After each step the status is, in order: `Placed`, `Paid`, `Shipped`, `Delivered`. No step is refused. |
| **data-testid needed** | N/A — no UI is specified (A2)                                                              |
| **Source**             | AC-1, AC-2, AC-3 (the full path)                                                           |
| **Note**               | Overlaps TC-ORD-002 to 004 by design; this is the one that proves the chain on a single order. |

---

## TC-ORD-009: Cancelling a Delivered order is refused

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                     |
| **Issue**              | ORD-4                                                                                      |
| **Automation Score**   | HIGH (55/67.5)                                                                             |
| **ISTQB Technique**    | State Transition — invalid transition Delivered → Cancelled                                |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | An order exists with status `Delivered` (created via TC-ORD-004)                           |
| **Steps**              | 1. Cancel the order <br> 2. Read the order back                                            |
| **Expected**           | The operation is refused. Status is still `Delivered`.                                     |
| **data-testid needed** | N/A — no UI is specified (A2)                                                              |
| **Source**             | Added by QA (the ticket lists cancel only for Placed, Paid and Shipped; it is silent on Delivered) |
| **Note**               | Message text is unspecified. Do not assert on the AC-5 message here; record what is returned and raise with the PO. |

---

## TC-ORD-010: Cancelling an already Cancelled order is refused

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                     |
| **Issue**              | ORD-4                                                                                      |
| **Automation Score**   | HIGH (55/67.5)                                                                             |
| **ISTQB Technique**    | State Transition — invalid transition Cancelled → Cancelled (idempotency)                  |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | An order exists with status `Cancelled` (created via TC-ORD-005)                           |
| **Steps**              | 1. Cancel the order a second time <br> 2. Read the order back                              |
| **Expected**           | The operation is refused or treated as a no-op. Status is still `Cancelled`. No second cancellation record or event is produced. |
| **data-testid needed** | N/A — no UI is specified (A2)                                                              |
| **Source**             | Added by QA (the ticket is silent on repeating an action on a terminal state)             |
| **Note**               | Whether a repeat cancel is refused or silently accepted is a PO decision; either way the status must not change. |

---

## TC-ORD-011: Marking a Placed order shipped without payment is refused

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                     |
| **Issue**              | ORD-4                                                                                      |
| **Automation Score**   | HIGH (57/67.5)                                                                             |
| **ISTQB Technique**    | State Transition — invalid transition Placed → Shipped (skipped state)                     |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | An order exists with status `Placed`; no payment has been recorded                         |
| **Steps**              | 1. Mark the order as shipped <br> 2. Read the order back                                   |
| **Expected**           | The operation is refused. Status is still `Placed`.                                        |
| **data-testid needed** | N/A — no UI is specified (A2)                                                              |
| **Source**             | Added by QA (AC-2 allows shipping only from Paid; the ticket does not say what happens from Placed) |
| **Note**               | Highest business risk of the invalid set: shipping unpaid goods.                           |

---

## TC-ORD-012: Confirming delivery of a Paid order that was never shipped is refused

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                     |
| **Issue**              | ORD-4                                                                                      |
| **Automation Score**   | HIGH (55/67.5)                                                                             |
| **ISTQB Technique**    | State Transition — invalid transition Paid → Delivered (skipped state)                     |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | An order exists with status `Paid` (created via TC-ORD-002)                                |
| **Steps**              | 1. Confirm delivery of the order <br> 2. Read the order back                               |
| **Expected**           | The operation is refused. Status is still `Paid`.                                          |
| **data-testid needed** | N/A — no UI is specified (A2)                                                              |
| **Source**             | Added by QA (AC-3 allows delivery only from Shipped; the ticket does not say what happens from Paid) |
| **Note**               | N/A — no caveats                                                                           |

---

## TC-ORD-013: Recording a second payment on a Paid order is refused

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                     |
| **Issue**              | ORD-4                                                                                      |
| **Automation Score**   | HIGH (55/67.5)                                                                             |
| **ISTQB Technique**    | State Transition — invalid transition Paid → Paid (repeated event)                         |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | An order exists with status `Paid` (created via TC-ORD-002)                                |
| **Steps**              | 1. Record a payment on the order again <br> 2. Read the order back                         |
| **Expected**           | The operation is refused or treated as a no-op. Status is still `Paid`. Only one payment is recorded against the order. |
| **data-testid needed** | N/A — no UI is specified (A2)                                                              |
| **Source**             | Added by QA (AC-1 covers payment on Placed only; the ticket is silent on double payment)  |
| **Note**               | Double-charge risk; verify no second payment record exists, not only the status.          |

---

## TC-ORD-014: Concurrent cancel and ship on the same Paid order resolve to one status

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @integration @ord @deferred`                                              |
| **Issue**              | ORD-4                                                                                      |
| **Automation Score**   | LOW (33/67.5)                                                                              |
| **ISTQB Technique**    | Error Guessing — race between two valid events from the same state                         |
| **Manual Env**         | Local                                                                                      |
| **Precondition**       | An order exists with status `Paid`; two operator sessions are open on it                   |
| **Steps**              | 1. From session A, cancel the order <br> 2. From session B, mark the order shipped at the same moment (fire both requests within the same tick, or step through with a breakpoint after the status read in one of them) <br> 3. Read the order back |
| **Expected**           | Exactly one request succeeds and the other is refused. The final status is either `Cancelled` or `Shipped`, never both and never a stale intermediate. The refused request reports the status it found, so an operator is not told their action succeeded when it did not. |
| **data-testid needed** | N/A — no UI is specified (A2)                                                              |
| **Source**             | Added by QA (the ticket is silent on concurrent operators acting on one order)            |
| **Note**               | Deferred: needs the implementation to know whether optimistic locking, a DB constraint or a queue serialises status writes. The remaining eight invalid transitions from the table (pay/ship/deliver on Delivered or Cancelled, deliver on Placed, ship on Shipped) belong to the same partition as TC-ORD-009 to 013; add them as cases when the refusal behaviour is confirmed. |

---

## Release gate

The gate is the seven cases tagged `@gate` (TC-ORD-001 to 007): the initial state, the five valid transitions, and the one refusal the story specifies. Sizing, entry and exit criteria follow the `qa-plan` skill. TC-ORD-008 to 014 stay in the full suite and are where findings against the unstated transitions will come from.

## Rules not applied

- **context-discovery** — the repository is empty, so no precondition or expected result could be verified against code. Assumptions A2 to A5 above replace that grounding and should be re-checked once an implementation exists.
