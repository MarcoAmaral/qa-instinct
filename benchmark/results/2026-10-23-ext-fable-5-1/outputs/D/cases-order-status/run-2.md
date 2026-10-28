---
feature: Order status changes
feature_code: ORD
tc_count: 15
tracker_issues: [ORD-4]
risk_level: HIGH
runbook: N/A — no runbook requested for this story
implementation_pack: N/A — no implementation pack exists
spec: N/A — not automated yet
last_updated: 2026-10-23
---

# Test Cases — Order status changes

| Field            | Value                                                        |
| ---------------- | ------------------------------------------------------------ |
| **Project**      | Store orders (ORD)                                           |
| **Author**       | Claude — Senior QA Analyst                                   |
| **Date Created** | 2026-10-23                                                   |
| **Last Updated** | 2026-10-23                                                   |
| **Methodology**  | ISTQB CTFL v4.0 — State Transition, Error Guessing           |

## Context and assumptions

The working directory contains no code, so no `Precondition` or `Expected` below is verified against an implementation. Every case rests on the story text and the assumptions listed here.

- **State model.** States: Placed, Paid, Shipped, Delivered, Cancelled. Events: record payment, mark shipped, confirm delivery, cancel. Valid transitions are the five the ACs name. Delivered and Cancelled are assumed terminal.
- **Interface.** Orders are assumed to be driven through an operator-facing API or admin screen. No `data-testid` values are known, so that row is `N/A` throughout. If a UI exists, name its selectors when the cases are first run.
- **Invalid transitions the ticket does not mention** (for example paying a Paid order, shipping a Placed order) are assumed to be refused with the status unchanged. Only the AC-5 message text is quoted; other messages are not asserted until the ticket defines them.
- **Tracker.** `ORD-4` matches the Linear/Jira identifier format. No base URL was given, so the ID is left as plain text.
- **Initial state** ("An order is created with the status Placed") appears in the story text, not in a numbered AC, so cases that check it are labelled `Added by QA`.

## State table

| From \ Event   | Record payment | Mark shipped | Confirm delivery | Cancel        |
| -------------- | -------------- | ------------ | ---------------- | ------------- |
| **Placed**     | Paid (AC-1)    | —            | —                | Cancelled (AC-4) |
| **Paid**       | —              | Shipped (AC-2) | —              | Cancelled (AC-4) |
| **Shipped**    | —              | —            | Delivered (AC-3) | refused (AC-5) |
| **Delivered**  | —              | —            | —                | —             |
| **Cancelled**  | —              | —            | —                | —             |

Empty cells are invalid transitions. Every valid transition has its own case (0-switch coverage). Each invalid transition gets one case so that one defect cannot mask another.

---

## TC-ORD-001: New order starts in Placed

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate`                                                       |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (64/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — initial state (entry into Placed)                                    |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | Operator is signed in; no order exists for the test customer                            |
| **Steps**              | 1. Create an order with at least one line item <br> 2. Read the order back              |
| **Expected**           | The order exists and its status is exactly `Placed`                                     |
| **data-testid needed** | N/A — no UI selectors known; the interface is assumed to be an API                      |
| **Source**             | Added by QA (the story text says a new order starts as Placed; no AC states it)         |
| **Note**               | Every other case depends on this one; run it first                                      |

---

## TC-ORD-002: Recording a payment moves Placed to Paid

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                 |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (64/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — valid transition Placed → Paid on "record payment"                   |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Placed`                                                    |
| **Steps**              | 1. Record a payment on the order <br> 2. Read the order back                            |
| **Expected**           | The action succeeds and the status is exactly `Paid`                                    |
| **data-testid needed** | N/A — no UI selectors known; the interface is assumed to be an API                      |
| **Source**             | AC-1                                                                                    |
| **Note**               | Payment amount, method and partial payments are out of scope; the ticket is silent      |

---

## TC-ORD-003: Marking as shipped moves Paid to Shipped

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                 |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (62/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — valid transition Paid → Shipped on "mark shipped"                    |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Paid`                                                      |
| **Steps**              | 1. Mark the order as shipped <br> 2. Read the order back                                |
| **Expected**           | The action succeeds and the status is exactly `Shipped`                                 |
| **data-testid needed** | N/A — no UI selectors known; the interface is assumed to be an API                      |
| **Source**             | AC-2                                                                                    |
| **Note**               | N/A — no caveats                                                                        |

---

## TC-ORD-004: Confirming delivery moves Shipped to Delivered

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                 |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (60/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — valid transition Shipped → Delivered on "confirm delivery"           |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Shipped`                                                   |
| **Steps**              | 1. Confirm delivery of the order <br> 2. Read the order back                            |
| **Expected**           | The action succeeds and the status is exactly `Delivered`                               |
| **data-testid needed** | N/A — no UI selectors known; the interface is assumed to be an API                      |
| **Source**             | AC-3                                                                                    |
| **Note**               | Precondition needs two prior transitions; reuse the setup from TC-ORD-002 and TC-ORD-003 |

---

## TC-ORD-005: Cancelling a Placed order moves it to Cancelled

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                 |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (64/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — valid transition Placed → Cancelled on "cancel"                      |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Placed`                                                    |
| **Steps**              | 1. Cancel the order <br> 2. Read the order back                                         |
| **Expected**           | The action succeeds and the status is exactly `Cancelled`                               |
| **data-testid needed** | N/A — no UI selectors known; the interface is assumed to be an API                      |
| **Source**             | AC-4                                                                                    |
| **Note**               | N/A — no caveats                                                                        |

---

## TC-ORD-006: Cancelling a Paid order moves it to Cancelled

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                 |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (62/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — valid transition Paid → Cancelled on "cancel"                        |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Paid`                                                      |
| **Steps**              | 1. Cancel the order <br> 2. Read the order back                                         |
| **Expected**           | The action succeeds and the status is exactly `Cancelled`                               |
| **data-testid needed** | N/A — no UI selectors known; the interface is assumed to be an API                      |
| **Source**             | AC-4                                                                                    |
| **Note**               | Whether a refund is triggered is out of scope; the ticket is silent on refunds          |

---

## TC-ORD-007: Cancelling a Shipped order is refused with the exact message

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                 |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (62/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — invalid transition Shipped → Cancelled on "cancel"                   |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Shipped`                                                   |
| **Steps**              | 1. Attempt to cancel the order <br> 2. Read the order back                              |
| **Expected**           | The action is refused with the message "Shipped orders cannot be cancelled." and the status is still `Shipped` |
| **data-testid needed** | N/A — no UI selectors known; the interface is assumed to be an API                      |
| **Source**             | AC-5                                                                                    |
| **Note**               | Assert the message verbatim, including the trailing full stop                           |

---

## TC-ORD-008: Full lifecycle Placed → Paid → Shipped → Delivered

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p0 @api @ord @candidate @gate`                                                |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (60/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — the full valid path in sequence (covers the three forward transitions in one run) |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | Operator is signed in; no order exists for the test customer                            |
| **Steps**              | 1. Create an order and confirm status `Placed` <br> 2. Record a payment and confirm `Paid` <br> 3. Mark as shipped and confirm `Shipped` <br> 4. Confirm delivery and confirm `Delivered` |
| **Expected**           | Each read-back shows the status named in that step; no step is refused                  |
| **data-testid needed** | N/A — no UI selectors known; the interface is assumed to be an API                      |
| **Source**             | AC-1, AC-2, AC-3 (the full path)                                                        |
| **Note**               | Post-deploy check; a failure here is localised with TC-ORD-002 to TC-ORD-004            |

---

## TC-ORD-009: Cancelling a Delivered order is refused

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                  |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (56/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — invalid transition Delivered → Cancelled on "cancel"                 |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Delivered`                                                 |
| **Steps**              | 1. Attempt to cancel the order <br> 2. Read the order back                              |
| **Expected**           | The action is refused and the status is still `Delivered`                               |
| **data-testid needed** | N/A — no UI selectors known; the interface is assumed to be an API                      |
| **Source**             | Added by QA (the ticket is silent on cancelling a Delivered order; AC-4 lists only Placed and Paid as cancellable) |
| **Note**               | Message text is not asserted; the ticket defines a message only for Shipped. Raise with the PO |

---

## TC-ORD-010: Cancelling an already Cancelled order is refused

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @api @ord @candidate`                                                  |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (54/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — invalid transition Cancelled → Cancelled on "cancel"                 |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Cancelled`                                                 |
| **Steps**              | 1. Attempt to cancel the order again <br> 2. Read the order back                        |
| **Expected**           | The second cancel is refused (or is a no-op that reports the order is already cancelled) and the status is still `Cancelled`; no second cancellation record is created |
| **data-testid needed** | N/A — no UI selectors known; the interface is assumed to be an API                      |
| **Source**             | Added by QA (the ticket is silent on repeating an action on a terminal state)           |
| **Note**               | Whether a repeat cancel is an error or an idempotent no-op needs a PO decision; either way the status must not change |

---

## TC-ORD-011: Marking a Placed (unpaid) order as shipped is refused

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                  |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (58/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — invalid transition Placed → Shipped on "mark shipped" (skips Paid)   |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Placed`                                                    |
| **Steps**              | 1. Attempt to mark the order as shipped <br> 2. Read the order back                     |
| **Expected**           | The action is refused and the status is still `Placed`                                  |
| **data-testid needed** | N/A — no UI selectors known; the interface is assumed to be an API                      |
| **Source**             | Added by QA (the story requires a fixed sequence; AC-2 allows shipping only from Paid)  |
| **Note**               | Shipping unpaid goods is a revenue risk, hence `@p1`                                    |

---

## TC-ORD-012: Recording a second payment on a Paid order is refused

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                  |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (58/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — invalid transition Paid → Paid on "record payment"                   |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Paid`                                                      |
| **Steps**              | 1. Attempt to record another payment on the order <br> 2. Read the order back           |
| **Expected**           | The action is refused and the status is still `Paid`; no duplicate payment is recorded  |
| **data-testid needed** | N/A — no UI selectors known; the interface is assumed to be an API                      |
| **Source**             | Added by QA (AC-1 allows payment only from Placed; the ticket is silent on double payment) |
| **Note**               | Double charging a customer is a `@p1` risk even if the status happens to stay `Paid`    |

---

## TC-ORD-013: Confirming delivery of a Paid (unshipped) order is refused

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                  |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (56/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — invalid transition Paid → Delivered on "confirm delivery" (skips Shipped) |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Paid`                                                      |
| **Steps**              | 1. Attempt to confirm delivery of the order <br> 2. Read the order back                 |
| **Expected**           | The action is refused and the status is still `Paid`                                    |
| **data-testid needed** | N/A — no UI selectors known; the interface is assumed to be an API                      |
| **Source**             | Added by QA (AC-3 allows delivery only from Shipped; the ticket is silent on skipping Shipped) |
| **Note**               | Also covers Placed → Delivered by analogy; run from Placed as well if time allows        |

---

## TC-ORD-014: Forward actions on a Cancelled order are refused

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                  |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (54/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — invalid transitions out of the terminal state Cancelled on "record payment", "mark shipped" and "confirm delivery" |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | Three orders exist, each with status `Cancelled`                                        |
| **Steps**              | 1. On the first order, attempt to record a payment <br> 2. On the second, attempt to mark as shipped <br> 3. On the third, attempt to confirm delivery <br> 4. Read each order back |
| **Expected**           | Every attempt is refused and all three orders still show `Cancelled`                    |
| **data-testid needed** | N/A — no UI selectors known; the interface is assumed to be an API                      |
| **Source**             | Added by QA (the ticket is silent on actions after cancellation; Cancelled is assumed terminal) |
| **Note**               | Uses a separate order per event so one failure does not hide another                    |

---

## TC-ORD-015: Simultaneous cancel and ship on the same Paid order

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @integration @ord @candidate`                                          |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | MEDIUM (44/67.5)                                                                        |
| **ISTQB Technique**    | Error Guessing — race condition between two operators acting on one order              |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Paid`; two operator sessions are open on it                |
| **Steps**              | 1. From session A, send "cancel" and from session B send "mark shipped" at the same moment <br> 2. Read the order back <br> 3. Read the order's status history or audit log if one exists |
| **Expected**           | Exactly one action succeeds. The final status is either `Cancelled` or `Shipped`, never both recorded, and the losing action is refused with the status unchanged by it |
| **data-testid needed** | N/A — no UI selectors known; the interface is assumed to be an API                      |
| **Source**             | Added by QA (the ticket is silent on concurrent updates; two staff acting on one order is a realistic store scenario) |
| **Note**               | Score lowered for determinism; automate with parallel requests and repeat several times. A Shipped-then-Cancelled outcome would violate AC-5 |

---

## Coverage summary

| Source                         | Cases                                                      |
| ------------------------------ | ---------------------------------------------------------- |
| AC-1                           | TC-ORD-002, TC-ORD-008                                     |
| AC-2                           | TC-ORD-003, TC-ORD-008                                     |
| AC-3                           | TC-ORD-004, TC-ORD-008                                     |
| AC-4                           | TC-ORD-005, TC-ORD-006                                     |
| AC-5                           | TC-ORD-007                                                 |
| Added by QA                    | TC-ORD-001, TC-ORD-009 to TC-ORD-015                       |
| Release gate (`@gate`)         | TC-ORD-002 to TC-ORD-008                                   |

Open questions for the PO, none of which block running the cases: the message text for refused transitions other than Shipped → Cancelled, whether a repeat cancel is an error or a no-op, and whether cancelling a Paid order triggers a refund.

Rules not applied: `context-discovery` and `testing-guidelines` were not loaded and no `qa-rules` skill is installed, so the cases follow the format in this command and the `qa-reference` technique examples only.
