---
feature: Order status changes
feature_code: ORD
tc_count: 17
tracker_issues: [ORD-4]
risk_level: HIGH
runbook: N/A — no runbook requested for this story
implementation_pack: N/A — no implementation pack exists
spec: N/A — not automated yet
last_updated: 2026-10-23
---

# Test Cases — Order status changes

| Field            | Value                                                              |
| ---------------- | ------------------------------------------------------------------ |
| **Project**      | N/A — project name not given in the story                          |
| **Author**       | Marco — Senior QA Analyst                                          |
| **Date Created** | 2026-10-23                                                         |
| **Last Updated** | 2026-10-23                                                         |
| **Methodology**  | ISTQB CTFL v4.0 — State Transition, Equivalence Partitioning, Error Guessing |

## Context and assumptions

The working directory holds no source code, so no `Precondition` or `Expected` below could be grounded in an implementation. Every case is derived from the story text only. Assumptions, each to be confirmed against the build before the first run:

- **A1 — Interface.** The operator acts through a web UI showing an order detail page with a status label and one button per action (Record payment, Mark as shipped, Confirm delivery, Cancel). The `data-testid` names below are proposals, not existing selectors.
- **A2 — Refusals the story does not describe.** Any action not listed as a valid transition is refused and the status does not change. The story gives an exact message only for cancelling a Shipped order (AC-5). For every other refusal the cases assert "refused, status unchanged" and leave the message text open.
- **A3 — Terminal states.** Delivered and Cancelled are terminal; no action moves an order out of them.
- **A4 — Visibility.** "Customers and staff always see where an order is" is read as: the new status is persisted and shown on reload, not only in the operator's current page.
- **A5 — Tracker.** `ORD-4` matches both Linear and Jira identifier formats and no base URL was given, so the ID is used as plain text.
- **A6 — Environments.** Local and Staging are assumed to exist.

### State model (CTFL §4.2.4)

Events across the top, states down the side. A cell holds the resulting state for a valid transition; `refused` marks an invalid one. AC-5 is the only refusal the story specifies.

| State ↓ / Event → | Record payment     | Mark as shipped    | Confirm delivery   | Cancel                     |
| ----------------- | ------------------ | ------------------ | ------------------ | -------------------------- |
| **Placed**        | Paid (AC-1)        | refused (TC-011)   | refused (not covered, see below) | Cancelled (AC-4)  |
| **Paid**          | refused (TC-010)   | Shipped (AC-2)     | refused (TC-012)   | Cancelled (AC-4)           |
| **Shipped**       | refused (not covered) | refused (not covered) | Delivered (AC-3) | refused, AC-5 message (TC-007) |
| **Delivered**     | refused (not covered) | refused (not covered) | refused (not covered) | refused (TC-008)     |
| **Cancelled**     | refused (TC-014)   | refused (TC-013)   | refused (not covered) | refused (TC-009)        |

Coverage: all 5 valid transitions (0-switch, 100%). Of the 15 invalid transitions, 8 have a case; the 7 marked "not covered" are low-likelihood (they require skipping two or more steps, or acting on a terminal state through a path the UI should not offer) and are listed in the Note of TC-ORD-013 as `@deferred` follow-ups.

### Release gate

Cases tagged `@gate` form the release gate: TC-ORD-001 to TC-ORD-005 and TC-ORD-007. They prove the lifecycle works end to end and that the one refusal the story specifies holds.

---

## TC-ORD-001: New order is created with status Placed

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                               |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (62/67.5)                                                        |
| **ISTQB Technique**    | State Transition — initial state (entry into Placed)                  |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | Operator is signed in; no order exists yet for the test customer      |
| **Steps**              | 1. Create a new order for the test customer <br> 2. Open the order detail page |
| **Expected**           | The status label reads exactly `Placed`. No other status is shown or implied. |
| **data-testid needed** | `order-status`                                                        |
| **Source**             | Added by QA (the story text says a new order starts as Placed; no AC states it) |
| **Note**               | Precondition for every other case in this file                        |

---

## TC-ORD-002: Recording a payment moves a Placed order to Paid

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                               |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (64/67.5)                                                        |
| **ISTQB Technique**    | State Transition — valid transition Placed → Paid (event: Record payment) |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order with status `Placed` exists (TC-ORD-001) and is open         |
| **Steps**              | 1. Click **Record payment** <br> 2. Complete any payment details the form requires <br> 3. Submit |
| **Expected**           | The status label changes to `Paid`. No error is shown.               |
| **data-testid needed** | `order-pay-btn`, `order-status`                                       |
| **Source**             | AC-1                                                                  |
| **Note**               | Assumption A1: payment details form is unspecified; record what the build asks for |

---

## TC-ORD-003: Marking a Paid order as shipped moves it to Shipped

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                               |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (64/67.5)                                                        |
| **ISTQB Technique**    | State Transition — valid transition Paid → Shipped (event: Mark as shipped) |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order with status `Paid` exists (TC-ORD-002) and is open           |
| **Steps**              | 1. Click **Mark as shipped** <br> 2. Confirm if a confirmation is asked |
| **Expected**           | The status label changes to `Shipped`. No error is shown.            |
| **data-testid needed** | `order-ship-btn`, `order-status`                                      |
| **Source**             | AC-2                                                                  |
| **Note**               | N/A — no caveats                                                      |

---

## TC-ORD-004: Confirming delivery moves a Shipped order to Delivered

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                               |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (64/67.5)                                                        |
| **ISTQB Technique**    | State Transition — valid transition Shipped → Delivered (event: Confirm delivery) |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order with status `Shipped` exists (TC-ORD-003) and is open        |
| **Steps**              | 1. Click **Confirm delivery** <br> 2. Confirm if a confirmation is asked |
| **Expected**           | The status label changes to `Delivered`. No error is shown.          |
| **data-testid needed** | `order-deliver-btn`, `order-status`                                   |
| **Source**             | AC-3                                                                  |
| **Note**               | N/A — no caveats                                                      |

---

## TC-ORD-005: Cancelling a Placed order moves it to Cancelled

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                               |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (62/67.5)                                                        |
| **ISTQB Technique**    | State Transition — valid transition Placed → Cancelled (event: Cancel) |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order with status `Placed` exists (TC-ORD-001) and is open         |
| **Steps**              | 1. Click **Cancel** <br> 2. Confirm if a confirmation is asked        |
| **Expected**           | The status label changes to `Cancelled`. No error is shown.          |
| **data-testid needed** | `order-cancel-btn`, `order-status`                                    |
| **Source**             | AC-4                                                                  |
| **Note**               | N/A — no caveats                                                      |

---

## TC-ORD-006: Cancelling a Paid order moves it to Cancelled

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@sanity @p1 @e2e @ord @candidate`                                    |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (60/67.5)                                                        |
| **ISTQB Technique**    | State Transition — valid transition Paid → Cancelled (event: Cancel)  |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order with status `Paid` exists (TC-ORD-002) and is open           |
| **Steps**              | 1. Click **Cancel** <br> 2. Confirm if a confirmation is asked        |
| **Expected**           | The status label changes to `Cancelled`. No error is shown.          |
| **data-testid needed** | `order-cancel-btn`, `order-status`                                    |
| **Source**             | AC-4                                                                  |
| **Note**               | The story says nothing about refunding the recorded payment; that is out of scope here and worth raising in refinement |

---

## TC-ORD-007: Cancelling a Shipped order is refused with the specified message

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                               |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (62/67.5)                                                        |
| **ISTQB Technique**    | State Transition — invalid transition Shipped → Cancelled (event: Cancel) |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order with status `Shipped` exists (TC-ORD-003) and is open        |
| **Steps**              | 1. Click **Cancel** (or trigger the cancel action by its API if the button is hidden) <br> 2. Reload the order detail page |
| **Expected**           | The action is refused and the message `Shipped orders cannot be cancelled.` is shown, exact text and trailing full stop included. The status label still reads `Shipped` before and after reload. |
| **data-testid needed** | `order-cancel-btn`, `order-error-message`, `order-status`             |
| **Source**             | AC-5                                                                  |
| **Note**               | If the build hides the Cancel button on Shipped orders, the API path still has to return the refusal; record which path was exercised |

---

## TC-ORD-008: Cancelling a Delivered order is refused

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (56/67.5)                                                        |
| **ISTQB Technique**    | State Transition — invalid transition Delivered → Cancelled (event: Cancel) |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order with status `Delivered` exists (TC-ORD-004) and is open      |
| **Steps**              | 1. Attempt **Cancel** (button or API) <br> 2. Reload the order detail page |
| **Expected**           | The action is refused. The status label still reads `Delivered` after reload. |
| **data-testid needed** | `order-cancel-btn`, `order-status`                                    |
| **Source**             | Added by QA (the ticket is silent on cancelling a Delivered order)    |
| **Note**               | Assumption A2: message text is not specified; record the actual text and raise it in refinement |

---

## TC-ORD-009: Cancelling an already Cancelled order is refused

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @ord @candidate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (54/67.5)                                                        |
| **ISTQB Technique**    | State Transition — invalid transition Cancelled → Cancelled (event: Cancel) |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order with status `Cancelled` exists (TC-ORD-005) and is open      |
| **Steps**              | 1. Attempt **Cancel** (button or API) <br> 2. Reload the order detail page |
| **Expected**           | The action is refused or has no effect. The status label still reads `Cancelled`; no duplicate cancellation record or second notification is produced. |
| **data-testid needed** | `order-cancel-btn`, `order-status`                                    |
| **Source**             | Added by QA (the ticket is silent on repeating an action on a terminal state) |
| **Note**               | Assumption A3                                                         |

---

## TC-ORD-010: Recording a second payment on a Paid order is refused

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (56/67.5)                                                        |
| **ISTQB Technique**    | State Transition — invalid transition Paid → Paid (event: Record payment); Error Guessing — double submit |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order with status `Paid` exists (TC-ORD-002) and is open           |
| **Steps**              | 1. Attempt **Record payment** again (button or API) <br> 2. Reload the order detail page |
| **Expected**           | The action is refused. The status label still reads `Paid`. Only one payment is recorded against the order. |
| **data-testid needed** | `order-pay-btn`, `order-status`                                       |
| **Source**             | Added by QA (the ticket is silent on a payment recorded on a non-Placed order; a double charge is the likely real-world defect) |
| **Note**               | Also try a rapid double-click on **Record payment** from `Placed`: exactly one payment must be recorded |

---

## TC-ORD-011: Marking a Placed order as shipped is refused

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (56/67.5)                                                        |
| **ISTQB Technique**    | State Transition — invalid transition Placed → Shipped (event: Mark as shipped) |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order with status `Placed` exists (TC-ORD-001) and is open         |
| **Steps**              | 1. Attempt **Mark as shipped** (button or API) <br> 2. Reload the order detail page |
| **Expected**           | The action is refused. The status label still reads `Placed`.        |
| **data-testid needed** | `order-ship-btn`, `order-status`                                      |
| **Source**             | Added by QA (the ticket is silent on shipping an unpaid order)        |
| **Note**               | Shipping goods that were never paid for is the highest-impact invalid transition in the table |

---

## TC-ORD-012: Confirming delivery of a Paid order is refused

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @ord @candidate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (54/67.5)                                                        |
| **ISTQB Technique**    | State Transition — invalid transition Paid → Delivered (event: Confirm delivery) |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order with status `Paid` exists (TC-ORD-002) and is open           |
| **Steps**              | 1. Attempt **Confirm delivery** (button or API) <br> 2. Reload the order detail page |
| **Expected**           | The action is refused. The status label still reads `Paid`.          |
| **data-testid needed** | `order-deliver-btn`, `order-status`                                   |
| **Source**             | Added by QA (the ticket is silent on skipping the Shipped step)       |
| **Note**               | N/A — no caveats                                                      |

---

## TC-ORD-013: Marking a Cancelled order as shipped is refused

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (56/67.5)                                                        |
| **ISTQB Technique**    | State Transition — invalid transition Cancelled → Shipped (event: Mark as shipped) |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order with status `Cancelled` exists (TC-ORD-006, cancelled after payment) and is open |
| **Steps**              | 1. Attempt **Mark as shipped** (button or API) <br> 2. Reload the order detail page |
| **Expected**           | The action is refused. The status label still reads `Cancelled`.     |
| **data-testid needed** | `order-ship-btn`, `order-status`                                      |
| **Source**             | Added by QA (the ticket is silent on acting on a Cancelled order; a warehouse shipping a cancelled order is a likely defect) |
| **Note**               | Invalid transitions not given their own case, to be added as `@deferred @p3` if the team wants all-transitions coverage: Placed → Confirm delivery; Shipped → Record payment; Shipped → Mark as shipped; Delivered → Record payment; Delivered → Mark as shipped; Delivered → Confirm delivery; Cancelled → Confirm delivery |

---

## TC-ORD-014: Recording a payment on a Cancelled order is refused

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (56/67.5)                                                        |
| **ISTQB Technique**    | State Transition — invalid transition Cancelled → Paid (event: Record payment) |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order with status `Cancelled` exists (TC-ORD-005, cancelled before payment) and is open |
| **Steps**              | 1. Attempt **Record payment** (button or API) <br> 2. Reload the order detail page |
| **Expected**           | The action is refused. The status label still reads `Cancelled`. No payment is recorded. |
| **data-testid needed** | `order-pay-btn`, `order-status`                                       |
| **Source**             | Added by QA (the ticket is silent on acting on a Cancelled order; charging for a cancelled order is a likely defect) |
| **Note**               | Assumption A3                                                         |

---

## TC-ORD-015: Full lifecycle Placed → Paid → Shipped → Delivered on one order

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | HIGH (60/67.5)                                                        |
| **ISTQB Technique**    | State Transition — valid path Placed → Paid → Shipped → Delivered (1-switch sequences on a single order) |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | Operator is signed in; a fresh order is created (TC-ORD-001)          |
| **Steps**              | 1. Click **Record payment** and submit <br> 2. Click **Mark as shipped** <br> 3. Click **Confirm delivery** <br> 4. Reload the order detail page |
| **Expected**           | After each step the status label reads `Paid`, `Shipped`, `Delivered` in that order. After reload it reads `Delivered`. The Cancel action is unavailable or refused at the end. |
| **data-testid needed** | `order-pay-btn`, `order-ship-btn`, `order-deliver-btn`, `order-status` |
| **Source**             | AC-1, AC-2, AC-3 (the full path on one order)                         |
| **Note**               | TC-ORD-002 to TC-ORD-004 each start from a seeded state; this case checks the transitions chain on the same record |

---

## TC-ORD-016: Status change is visible to another user without further action

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | MEDIUM (48/67.5)                                                      |
| **ISTQB Technique**    | EP — valid partition (persisted status read by a second session); Error Guessing — stale cached status |
| **Manual Env**         | Local, Staging                                                        |
| **Precondition**       | An order with status `Placed` exists; operator A has it open; a second session (operator B, or the customer's order view if one exists) has the same order open |
| **Steps**              | 1. As operator A, click **Record payment** and submit <br> 2. In the second session, reload the order view |
| **Expected**           | The second session shows `Paid`. No session shows a status other than `Paid` for this order. |
| **data-testid needed** | `order-status`                                                        |
| **Source**             | Added by QA (the story goal says customers and staff always see where an order is; no AC covers a second viewer) |
| **Note**               | Assumption A4. If a customer-facing order view does not exist in this build, run with two operator sessions and say so in the result |

---

## TC-ORD-017: Concurrent cancel and ship on the same Paid order

| Field                  | Value                                                                 |
| ---------------------- | --------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @manual @ord @manual-only`                           |
| **Issue**              | ORD-4                                                                 |
| **Automation Score**   | LOW (32/67.5)                                                         |
| **ISTQB Technique**    | Error Guessing — race between two valid events from the same state    |
| **Manual Env**         | Staging                                                               |
| **Precondition**       | An order with status `Paid` exists; two operator sessions have it open at the same time |
| **Steps**              | 1. In session A, click **Cancel** and, within the same second, in session B click **Mark as shipped** (or fire both requests concurrently against the API) <br> 2. Reload the order in both sessions |
| **Expected**           | Exactly one action succeeds. The order ends in either `Cancelled` or `Shipped`, never both, and the losing session is shown a refusal. If the order is `Shipped`, the later cancel is refused with `Shipped orders cannot be cancelled.` |
| **data-testid needed** | `order-cancel-btn`, `order-ship-btn`, `order-status`, `order-error-message` |
| **Source**             | Added by QA (the ticket is silent on two operators acting on one order at once) |
| **Note**               | Timing-dependent, so kept manual; automate at the API level only if the build exposes a way to serialise the two requests deterministically |

---

## Rules not applied

The `context-discovery` and `testing-guidelines` rules were not loaded in this session and the `qa-rules` skill is not installed, so they could not be read. Their intent was followed as far as `/qa-cases` describes it: the repository was searched for implementation and found empty, which is why every Precondition and Expected rests on the assumptions listed at the top.
