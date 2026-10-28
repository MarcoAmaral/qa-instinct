---
feature: Order status changes
feature_code: ORD
tc_count: 13
tracker_issues: [ORD-4]
risk_level: HIGH
runbook: N/A — no runbook exists for this feature
implementation_pack: N/A — no implementation pack exists
spec: N/A — not automated yet
last_updated: 2026-10-23
---

# Test Cases — Order status changes

| Field            | Value                                                     |
| ---------------- | --------------------------------------------------------- |
| **Project**      | N/A — the ticket does not name the project                |
| **Author**       | Marco — Senior QA Analyst                                 |
| **Date Created** | 2026-10-23                                                |
| **Last Updated** | 2026-10-23                                                |
| **Methodology**  | ISTQB CTFL v4.0 — State Transition, EP, Error Guessing    |

## Assumptions and context

The working directory holds no code, so no precondition or expected result below is verified against an implementation. Every case rests on the ticket text and the assumptions listed here. The `context-discovery` and `testing-guidelines` rules were not loaded and no `qa-rules` skill is installed, so neither rule could be applied; the tag taxonomy used is the one in this command's own text.

- **A1 — Interface.** The ticket does not say whether operators act through a UI or an API. Steps are written as operator actions ("record a payment on the order"); each should be mapped to the real endpoint or screen before execution. `data-testid needed` is `N/A` throughout for this reason.
- **A2 — Terminal states.** Delivered and Cancelled are assumed terminal: no action moves an order out of them. The ticket is silent on this.
- **A3 — Other refused transitions.** Only AC-5 gives an exact message. For every other invalid transition the expected result is "refused, status unchanged"; the exact message is to be confirmed with the developer and recorded in the case's Note.
- **A4 — Tracker.** `ORD-4` matches both the Linear and Jira key formats and no base URL was given, so the ID is left as plain text.
- **A5 — Idempotency.** Repeating an action already applied (paying a Paid order, cancelling a Cancelled order) is assumed to be refused rather than silently accepted.

State model used for coverage: Placed → Paid → Shipped → Delivered, plus Placed → Cancelled and Paid → Cancelled. Five valid transitions (0-switch coverage in TC-001 to TC-006) and seven invalid events (TC-007 to TC-013).

---

## TC-ORD-001: New order starts in Placed

| Field                  | Value                                                                                         |
| ---------------------- | --------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                                                       |
| **Issue**              | ORD-4                                                                                         |
| **Automation Score**   | HIGH (62/67.5)                                                                                |
| **ISTQB Technique**    | State Transition — initial state Placed                                                       |
| **Manual Env**         | Local, Staging                                                                                |
| **Precondition**       | Operator is signed in; a valid customer and at least one purchasable item exist               |
| **Steps**              | 1. Create a new order for the customer <br> 2. Read the order's status                        |
| **Expected**           | The order exists and its status is exactly `Placed`. No other status is shown or stored.      |
| **data-testid needed** | N/A — interface not specified (A1)                                                            |
| **Source**             | Added by QA (the story text says an order is created with the status Placed; no AC states it) |
| **Note**               | Precondition for every other case in this file                                                |

---

## TC-ORD-002: Recording a payment moves Placed to Paid

| Field                  | Value                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                                               |
| **Issue**              | ORD-4                                                                                 |
| **Automation Score**   | HIGH (62/67.5)                                                                        |
| **ISTQB Technique**    | State Transition — valid transition Placed → Paid (event: record payment)            |
| **Manual Env**         | Local, Staging                                                                        |
| **Precondition**       | An order exists with status `Placed` (TC-ORD-001)                                     |
| **Steps**              | 1. Record a payment on the order <br> 2. Read the order's status                      |
| **Expected**           | The action is accepted and the status is exactly `Paid`.                              |
| **data-testid needed** | N/A — interface not specified (A1)                                                    |
| **Source**             | AC-1                                                                                  |
| **Note**               | N/A — no caveats                                                                      |

---

## TC-ORD-003: Marking as shipped moves Paid to Shipped

| Field                  | Value                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                                                |
| **Issue**              | ORD-4                                                                                  |
| **Automation Score**   | HIGH (60/67.5)                                                                         |
| **ISTQB Technique**    | State Transition — valid transition Paid → Shipped (event: mark as shipped)           |
| **Manual Env**         | Local, Staging                                                                         |
| **Precondition**       | An order exists with status `Paid` (TC-ORD-002)                                        |
| **Steps**              | 1. Mark the order as shipped <br> 2. Read the order's status                           |
| **Expected**           | The action is accepted and the status is exactly `Shipped`.                            |
| **data-testid needed** | N/A — interface not specified (A1)                                                     |
| **Source**             | AC-2                                                                                   |
| **Note**               | N/A — no caveats                                                                       |

---

## TC-ORD-004: Confirming delivery moves Shipped to Delivered

| Field                  | Value                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                                                   |
| **Issue**              | ORD-4                                                                                     |
| **Automation Score**   | HIGH (58/67.5)                                                                            |
| **ISTQB Technique**    | State Transition — valid transition Shipped → Delivered (event: confirm delivery)        |
| **Manual Env**         | Local, Staging                                                                            |
| **Precondition**       | An order exists with status `Shipped` (TC-ORD-003)                                        |
| **Steps**              | 1. Confirm delivery of the order <br> 2. Read the order's status                          |
| **Expected**           | The action is accepted and the status is exactly `Delivered`.                             |
| **data-testid needed** | N/A — interface not specified (A1)                                                        |
| **Source**             | AC-3                                                                                      |
| **Note**               | Together with TC-002 and TC-003 this covers the full happy path Placed → Delivered        |

---

## TC-ORD-005: Cancelling a Placed order moves it to Cancelled

| Field                  | Value                                                                              |
| ---------------------- | ---------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                                            |
| **Issue**              | ORD-4                                                                              |
| **Automation Score**   | HIGH (62/67.5)                                                                     |
| **ISTQB Technique**    | State Transition — valid transition Placed → Cancelled (event: cancel)             |
| **Manual Env**         | Local, Staging                                                                     |
| **Precondition**       | An order exists with status `Placed` (TC-ORD-001)                                  |
| **Steps**              | 1. Cancel the order <br> 2. Read the order's status                                |
| **Expected**           | The action is accepted and the status is exactly `Cancelled`.                      |
| **data-testid needed** | N/A — interface not specified (A1)                                                 |
| **Source**             | AC-4                                                                               |
| **Note**               | N/A — no caveats                                                                   |

---

## TC-ORD-006: Cancelling a Paid order moves it to Cancelled

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                                                                 |
| **Issue**              | ORD-4                                                                                                   |
| **Automation Score**   | HIGH (60/67.5)                                                                                          |
| **ISTQB Technique**    | State Transition — valid transition Paid → Cancelled (event: cancel)                                    |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | An order exists with status `Paid` (TC-ORD-002)                                                         |
| **Steps**              | 1. Cancel the order <br> 2. Read the order's status                                                     |
| **Expected**           | The action is accepted and the status is exactly `Cancelled`.                                           |
| **data-testid needed** | N/A — interface not specified (A1)                                                                      |
| **Source**             | AC-4                                                                                                    |
| **Note**               | The ticket says nothing about refunding the recorded payment on cancel; raise with the PO as a question |

---

## TC-ORD-007: Cancelling a Shipped order is refused with the exact message

| Field                  | Value                                                                                                                                         |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ord @candidate @gate`                                                                                                       |
| **Issue**              | ORD-4                                                                                                                                         |
| **Automation Score**   | HIGH (60/67.5)                                                                                                                                |
| **ISTQB Technique**    | State Transition — invalid event: cancel in state Shipped                                                                                     |
| **Manual Env**         | Local, Staging                                                                                                                                |
| **Precondition**       | An order exists with status `Shipped` (TC-ORD-003)                                                                                            |
| **Steps**              | 1. Cancel the order <br> 2. Read the returned message <br> 3. Read the order's status                                                          |
| **Expected**           | The action is refused. The message is exactly `Shipped orders cannot be cancelled.` (full stop included). The status is still `Shipped`.      |
| **data-testid needed** | N/A — interface not specified (A1)                                                                                                            |
| **Source**             | AC-5                                                                                                                                          |
| **Note**               | The only invalid transition with a message given by the ticket; compare the string byte for byte                                              |

---

## TC-ORD-008: Cancelling a Delivered order is refused

| Field                  | Value                                                                                                        |
| ---------------------- | ------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                                                       |
| **Issue**              | ORD-4                                                                                                        |
| **Automation Score**   | HIGH (54/67.5)                                                                                               |
| **ISTQB Technique**    | State Transition — invalid event: cancel in state Delivered                                                  |
| **Manual Env**         | Local, Staging                                                                                               |
| **Precondition**       | An order exists with status `Delivered` (TC-ORD-004)                                                         |
| **Steps**              | 1. Cancel the order <br> 2. Read the order's status                                                          |
| **Expected**           | The action is refused and the status is still `Delivered`.                                                   |
| **data-testid needed** | N/A — interface not specified (A1)                                                                           |
| **Source**             | Added by QA (AC-4 lists only Placed and Paid as cancellable and AC-5 covers only Shipped; Delivered is unaddressed) |
| **Note**               | Message not specified (A3); confirm with the developer whether the AC-5 text is reused or a distinct one     |

---

## TC-ORD-009: Cancelling an already Cancelled order is refused

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @ord @candidate`                                                     |
| **Issue**              | ORD-4                                                                                      |
| **Automation Score**   | HIGH (54/67.5)                                                                             |
| **ISTQB Technique**    | State Transition — invalid event: cancel in state Cancelled                                |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | An order exists with status `Cancelled` (TC-ORD-005)                                       |
| **Steps**              | 1. Cancel the order again <br> 2. Read the order's status                                  |
| **Expected**           | The action is refused and the status is still `Cancelled`. No second cancellation is recorded. |
| **data-testid needed** | N/A — interface not specified (A1)                                                         |
| **Source**             | Added by QA (the ticket is silent on repeating an action; assumption A5)                   |
| **Note**               | Message not specified (A3)                                                                 |

---

## TC-ORD-010: Marking an unpaid Placed order as shipped is refused

| Field                  | Value                                                                                             |
| ---------------------- | ------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                                            |
| **Issue**              | ORD-4                                                                                             |
| **Automation Score**   | HIGH (56/67.5)                                                                                    |
| **ISTQB Technique**    | State Transition — invalid event: mark as shipped in state Placed                                 |
| **Manual Env**         | Local, Staging                                                                                    |
| **Precondition**       | An order exists with status `Placed` (TC-ORD-001)                                                 |
| **Steps**              | 1. Mark the order as shipped <br> 2. Read the order's status                                      |
| **Expected**           | The action is refused and the status is still `Placed`. The Paid step cannot be skipped.          |
| **data-testid needed** | N/A — interface not specified (A1)                                                                |
| **Source**             | Added by QA (AC-2 allows shipping only from Paid; the ticket does not say what happens from Placed) |
| **Note**               | Highest-risk skip: shipping goods that were never paid for. Message not specified (A3)            |

---

## TC-ORD-011: Confirming delivery of an unshipped order is refused

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                                                  |
| **Issue**              | ORD-4                                                                                                   |
| **Automation Score**   | HIGH (54/67.5)                                                                                          |
| **ISTQB Technique**    | State Transition — invalid event: confirm delivery in state Paid                                        |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | An order exists with status `Paid` (TC-ORD-002)                                                         |
| **Steps**              | 1. Confirm delivery of the order <br> 2. Read the order's status                                        |
| **Expected**           | The action is refused and the status is still `Paid`.                                                   |
| **data-testid needed** | N/A — interface not specified (A1)                                                                      |
| **Source**             | Added by QA (AC-3 allows delivery only from Shipped; the ticket does not say what happens from Paid)    |
| **Note**               | Run once more from `Placed` if time allows; same expected result. Message not specified (A3)            |

---

## TC-ORD-012: Recording a payment on a non-Placed order is refused

| Field                  | Value                                                                                                                                        |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ord @candidate`                                                                                                       |
| **Issue**              | ORD-4                                                                                                                                        |
| **Automation Score**   | HIGH (54/67.5)                                                                                                                               |
| **ISTQB Technique**    | EP — invalid partition "status is not Placed" for the record-payment event (representatives: Paid, Cancelled)                                |
| **Manual Env**         | Local, Staging                                                                                                                               |
| **Precondition**       | One order with status `Paid` (TC-ORD-002) and one with status `Cancelled` (TC-ORD-005)                                                       |
| **Steps**              | 1. Record a payment on the `Paid` order <br> 2. Read its status <br> 3. Record a payment on the `Cancelled` order <br> 4. Read its status     |
| **Expected**           | Both actions are refused. The first order is still `Paid`; the second is still `Cancelled`. No duplicate payment is recorded on either.      |
| **data-testid needed** | N/A — interface not specified (A1)                                                                                                           |
| **Source**             | Added by QA (AC-1 allows payment only from Placed; the ticket is silent on double payment and on paying a cancelled order)                   |
| **Note**               | Double payment is a money-handling risk; if the system accepts it, file as a defect even if status stays `Paid`. Message not specified (A3)  |

---

## TC-ORD-013: Two conflicting actions on the same order leave one consistent status

| Field                  | Value                                                                                                                                                                       |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @integration @ord @deferred`                                                                                                                               |
| **Issue**              | ORD-4                                                                                                                                                                       |
| **Automation Score**   | LOW (32/67.5)                                                                                                                                                               |
| **ISTQB Technique**    | Error Guessing — race between "mark as shipped" and "cancel" on a Paid order                                                                                                |
| **Manual Env**         | Local                                                                                                                                                                       |
| **Precondition**       | An order exists with status `Paid` (TC-ORD-002); two operator sessions or two concurrent requests can target it                                                              |
| **Steps**              | 1. From session A, mark the order as shipped <br> 2. At the same moment, from session B, cancel the order <br> 3. Read the order's status <br> 4. Read each session's result |
| **Expected**           | Exactly one action succeeds. The final status is either `Shipped` or `Cancelled`, never both and never an intermediate value. The losing session receives a refusal.        |
| **data-testid needed** | N/A — interface not specified (A1)                                                                                                                                          |
| **Source**             | Added by QA (the ticket is silent on concurrent actions; lost-update risk on a status field)                                                                                |
| **Note**               | Deferred because timing is non-deterministic in end-to-end form; best covered by a unit or integration test on the transition guard. Message not specified (A3)             |
