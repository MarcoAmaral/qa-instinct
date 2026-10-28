---
feature: Order status changes
feature_code: ORD
tc_count: 14
tracker_issues: [ORD-4]
risk_level: HIGH
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-23
---

# Test Cases — Order status changes

| Field            | Value                                                              |
| ---------------- | ------------------------------------------------------------------ |
| **Project**      | Store orders (project name not given in the ticket)                |
| **Author**       | Bem-te-vi — Senior QA Analyst                                      |
| **Date Created** | 2026-10-23                                                         |
| **Last Updated** | 2026-10-23                                                         |
| **Methodology**  | ISTQB CTFL v4.0 — State Transition, Equivalence Partitioning, Error Guessing |

## Assumptions

The working directory contains no code, so none of the preconditions or expected results below could be checked against an implementation. Every case is written from the ticket alone.

- **A1.** Status changes are triggered by three operations named in the ticket: record payment, mark shipped, confirm delivery, plus cancel. Cases call them by those names regardless of whether the real interface is an API, a service method or a UI action.
- **A2.** The five statuses in the ticket (Placed, Paid, Shipped, Delivered, Cancelled) are the complete, fixed set. Delivered and Cancelled are terminal: the ticket lists no transition out of them.
- **A3.** A transition the ticket does not list is refused and leaves the status unchanged. The ticket specifies the refusal message only for AC-5; for the other refusals the message wording is unknown and the case asks the tester to record it.
- **A4.** `ORD-4` is a tracker ID with no base URL given, so it appears as plain text. No UI selectors are known, so every `data-testid needed` row is `N/A`.
- **A5.** The story text says an order starts as Placed, but no AC states it, so that case is `Added by QA`.

## State Transition Model

| From \ Event | Record payment | Mark shipped | Confirm delivery | Cancel |
| ------------ | -------------- | ------------ | ---------------- | ------ |
| Placed       | → Paid (AC-1)  | refused (QA) | refused (QA)     | → Cancelled (AC-4) |
| Paid         | refused (QA)   | → Shipped (AC-2) | refused (QA) | → Cancelled (AC-4) |
| Shipped      | refused (QA)   | refused (QA) | → Delivered (AC-3) | refused, "Shipped orders cannot be cancelled." (AC-5) |
| Delivered    | refused (QA)   | refused (QA) | refused (QA)     | refused (QA) |
| Cancelled    | refused (QA)   | refused (QA) | refused (QA)     | refused (QA) |

Valid transitions: 5. All five are covered individually (0-switch coverage) and once as a sequence (TC-ORD-008). Invalid transitions: 15; AC-5 covers one, and TC-ORD-009 to TC-ORD-013 cover the rest grouped by source state.

---

## TC-ORD-001: New order is created with status Placed

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (62/67.5)                                                        |
| **ISTQB Technique**    | State Transition — initial state (Placed)                             |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | Operator can create an order; no order exists for the test customer   |
| **Steps**              | 1. Create a new order <br> 2. Read the order's status                 |
| **Expected**           | Status is `Placed`. No other status is reported for the new order.    |
| **data-testid needed** | N/A — no UI element is known (assumption A4)                          |
| **Source**             | Added by QA (the story text says a new order starts as Placed; no AC states it) |
| **Note**               | Every later case depends on this initial state.                       |

---

## TC-ORD-002: Recording a payment moves a Placed order to Paid

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (62/67.5)                                                        |
| **ISTQB Technique**    | State Transition — Placed → Paid on record payment                    |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Placed`                                  |
| **Steps**              | 1. Record a payment on the order <br> 2. Read the order's status      |
| **Expected**           | The operation succeeds. Status is `Paid`.                             |
| **data-testid needed** | N/A — no UI element is known (assumption A4)                          |
| **Source**             | AC-1                                                                  |
| **Note**               | N/A — no caveats                                                      |

---

## TC-ORD-003: Marking a Paid order as shipped moves it to Shipped

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (60/67.5)                                                        |
| **ISTQB Technique**    | State Transition — Paid → Shipped on mark shipped                     |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Paid`                                    |
| **Steps**              | 1. Mark the order as shipped <br> 2. Read the order's status          |
| **Expected**           | The operation succeeds. Status is `Shipped`.                          |
| **data-testid needed** | N/A — no UI element is known (assumption A4)                          |
| **Source**             | AC-2                                                                  |
| **Note**               | N/A — no caveats                                                      |

---

## TC-ORD-004: Confirming delivery moves a Shipped order to Delivered

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (60/67.5)                                                        |
| **ISTQB Technique**    | State Transition — Shipped → Delivered on confirm delivery            |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Shipped`                                 |
| **Steps**              | 1. Confirm delivery of the order <br> 2. Read the order's status      |
| **Expected**           | The operation succeeds. Status is `Delivered`.                        |
| **data-testid needed** | N/A — no UI element is known (assumption A4)                          |
| **Source**             | AC-3                                                                  |
| **Note**               | N/A — no caveats                                                      |

---

## TC-ORD-005: Cancelling a Placed order moves it to Cancelled

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (62/67.5)                                                        |
| **ISTQB Technique**    | State Transition — Placed → Cancelled on cancel                       |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Placed`                                  |
| **Steps**              | 1. Cancel the order <br> 2. Read the order's status                   |
| **Expected**           | The operation succeeds. Status is `Cancelled`.                        |
| **data-testid needed** | N/A — no UI element is known (assumption A4)                          |
| **Source**             | AC-4                                                                  |
| **Note**               | N/A — no caveats                                                      |

---

## TC-ORD-006: Cancelling a Paid order moves it to Cancelled

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (60/67.5)                                                        |
| **ISTQB Technique**    | State Transition — Paid → Cancelled on cancel                         |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Paid`                                    |
| **Steps**              | 1. Cancel the order <br> 2. Read the order's status                   |
| **Expected**           | The operation succeeds. Status is `Cancelled`.                        |
| **data-testid needed** | N/A — no UI element is known (assumption A4)                          |
| **Source**             | AC-4                                                                  |
| **Note**               | The ticket says nothing about refunding the recorded payment. Record what happens to it; raise with the PO if a refund is expected. |

---

## TC-ORD-007: Cancelling a Shipped order is refused with the exact message

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (60/67.5)                                                        |
| **ISTQB Technique**    | State Transition — invalid transition Shipped → Cancelled             |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Shipped`                                 |
| **Steps**              | 1. Cancel the order <br> 2. Read the order's status                   |
| **Expected**           | The operation is refused with the message `Shipped orders cannot be cancelled.` (exact text, including the full stop). Status remains `Shipped`. |
| **data-testid needed** | N/A — no UI element is known (assumption A4)                          |
| **Source**             | AC-5                                                                  |
| **Note**               | N/A — no caveats                                                      |

---

## TC-ORD-008: Order follows the full path Placed → Paid → Shipped → Delivered

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@sanity @p1 @api @ord @candidate`                                     |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (56/67.5)                                                        |
| **ISTQB Technique**    | State Transition — valid transition sequence (1-switch coverage of the happy path) |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | Operator can create an order                                          |
| **Steps**              | 1. Create a new order and read its status <br> 2. Record a payment and read the status <br> 3. Mark the order as shipped and read the status <br> 4. Confirm delivery and read the status |
| **Expected**           | Statuses read `Placed`, then `Paid`, then `Shipped`, then `Delivered`, in that order. Every operation succeeds. |
| **data-testid needed** | N/A — no UI element is known (assumption A4)                          |
| **Source**             | AC-1, AC-2, AC-3 (the full path on one order)                         |
| **Note**               | Proves the transitions chain on a single order, which TC-ORD-002 to TC-ORD-004 do not. |

---

## TC-ORD-009: Cancelling a Delivered order is refused

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                 |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (54/67.5)                                                        |
| **ISTQB Technique**    | State Transition — invalid transition Delivered → Cancelled           |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Delivered`                               |
| **Steps**              | 1. Cancel the order <br> 2. Read the order's status                   |
| **Expected**           | The operation is refused with an error. Status remains `Delivered`. Record the message returned; the ticket does not specify it. |
| **data-testid needed** | N/A — no UI element is known (assumption A4)                          |
| **Source**             | Added by QA (the ticket only refuses cancellation of Shipped orders; it is silent on Delivered, which has no outgoing transition) |
| **Note**               | Assumption A2 and A3. If the product allows this, the state model in the ticket needs a sixth transition. |

---

## TC-ORD-010: Marking a Placed order as shipped is refused

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                 |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (56/67.5)                                                        |
| **ISTQB Technique**    | State Transition — invalid transition Placed → Shipped (skips Paid)   |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Placed`; no payment has been recorded    |
| **Steps**              | 1. Mark the order as shipped <br> 2. Read the order's status          |
| **Expected**           | The operation is refused with an error. Status remains `Placed`. Record the message returned. |
| **data-testid needed** | N/A — no UI element is known (assumption A4)                          |
| **Source**             | Added by QA (AC-2 only allows shipping from Paid; the ticket is silent on shipping an unpaid order) |
| **Note**               | Shipping unpaid goods is a revenue risk, hence `@p1`.                 |

---

## TC-ORD-011: Confirming delivery of an order that is not Shipped is refused

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                 |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (54/67.5)                                                        |
| **ISTQB Technique**    | State Transition — invalid transitions Placed → Delivered and Paid → Delivered |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | Two orders exist: order A with status `Placed`, order B with status `Paid` |
| **Steps**              | 1. Confirm delivery of order A <br> 2. Read order A's status <br> 3. Confirm delivery of order B <br> 4. Read order B's status |
| **Expected**           | Both operations are refused with an error. Order A remains `Placed`; order B remains `Paid`. Record the messages returned. |
| **data-testid needed** | N/A — no UI element is known (assumption A4)                          |
| **Source**             | Added by QA (AC-3 only allows delivery confirmation from Shipped; the ticket is silent on other source states) |
| **Note**               | N/A — no caveats                                                      |

---

## TC-ORD-012: No operation changes a Cancelled order

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                 |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (54/67.5)                                                        |
| **ISTQB Technique**    | State Transition — invalid transitions out of the terminal state Cancelled |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order exists with status `Cancelled`                               |
| **Steps**              | 1. Record a payment on the order <br> 2. Mark the order as shipped <br> 3. Confirm delivery of the order <br> 4. Cancel the order again <br> 5. Read the order's status |
| **Expected**           | All four operations are refused with an error. Status remains `Cancelled` after each. Record the messages returned. |
| **data-testid needed** | N/A — no UI element is known (assumption A4)                          |
| **Source**             | Added by QA (the ticket lists no transition out of Cancelled; it is silent on what happens if one is attempted) |
| **Note**               | Step 4 also checks that cancelling twice does not succeed silently or raise a different error from the other refusals. |

---

## TC-ORD-013: Repeating an already-applied transition is refused

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @api @ord @candidate`                                 |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | MEDIUM (50/67.5)                                                      |
| **ISTQB Technique**    | Error Guessing — duplicate event on the same state (Paid + record payment, Shipped + mark shipped, Delivered + confirm delivery) |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | Three orders exist: order A `Paid`, order B `Shipped`, order C `Delivered` |
| **Steps**              | 1. Record a second payment on order A <br> 2. Mark order B as shipped again <br> 3. Confirm delivery of order C again <br> 4. Read the status of each order |
| **Expected**           | Each repeated operation is refused with an error. Statuses remain `Paid`, `Shipped` and `Delivered` respectively. No second payment is recorded against order A. |
| **data-testid needed** | N/A — no UI element is known (assumption A4)                          |
| **Source**             | Added by QA (the ticket is silent on repeating an operation; a double payment or double-ship retry is a common defect) |
| **Note**               | If the product treats repeats as idempotent successes instead of refusals, record that and ask the PO which is intended. |

---

## TC-ORD-014: Simultaneous cancel and ship on a Paid order leave one consistent status

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @integration @ord @deferred`                          |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | LOW (33/67.5)                                                         |
| **ISTQB Technique**    | Error Guessing — race condition between two valid events from the same state |
| **Manual Env**         | Local                                                                 |
| **Precondition**       | An order exists with status `Paid`; two operator sessions can act on it at the same time |
| **Steps**              | 1. From session 1, cancel the order and, within the same instant, from session 2 mark it as shipped <br> 2. Read the order's status <br> 3. Read the result each session received |
| **Expected**           | Exactly one operation succeeds and the other is refused. Status is either `Cancelled` or `Shipped`, never a mix, and never `Shipped` after the cancel was reported as successful (or the reverse). |
| **data-testid needed** | N/A — no UI element is known (assumption A4)                          |
| **Source**             | Added by QA (the ticket is silent on concurrent operators; both events are valid from Paid, so the last writer could overwrite the first) |
| **Note**               | Deferred: needs a harness that fires two requests concurrently. Run by hand once the implementation shows how status writes are locked. |

---

## Rules not applied

The `context-discovery` rule and the `testing-guidelines` rule were not loaded, and no `qa-rules` skill is installed. Context discovery was attempted directly: the working directory holds no files, so no precondition or expected result in this document is verified against code. Tag categories follow the four-category scheme in this skill's own text.
