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

| Field            | Value                                                    |
| ---------------- | -------------------------------------------------------- |
| **Project**      | Store orders (ORD)                                       |
| **Author**       | Marco — Senior QA Analyst                                |
| **Date Created** | 2026-10-23                                               |
| **Last Updated** | 2026-10-23                                               |
| **Methodology**  | ISTQB CTFL v4.0 — State Transition, EP, Error Guessing   |

## Assumptions

The working directory contains no source code, so `Precondition` and `Expected` could not be grounded in an implementation. Every case below rests on the story text and these stated assumptions:

- **A1 — State model.** The order has exactly five statuses: Placed, Paid, Shipped, Delivered, Cancelled. Delivered and Cancelled are terminal; no AC describes leaving them.
- **A2 — Operations.** Four operations exist: record payment, mark shipped, confirm delivery, cancel. Each is exposed to the store operator (UI or API; the cases are written operation-first so they apply to either).
- **A3 — Refusals.** A refused operation leaves the status unchanged and returns an error. Only AC-5 quotes an exact message; other refusals are asserted on "refused, status unchanged" and the message text is a QA finding to be recorded.
- **A4 — Tracker.** `ORD-4` is used as plain text; no base URL was given.
- **A5 — Environments.** Local and Staging are assumed available.
- **A6 — Selectors.** No UI exists to inspect; `data-testid needed` lists the selectors the cases would require if the operations are UI-driven.

State-transition table (A1, A2):

| From \ Event | record payment | mark shipped | confirm delivery | cancel |
| ------------ | -------------- | ------------ | ---------------- | ------ |
| Placed       | Paid (AC-1)    | refused      | refused          | Cancelled (AC-4) |
| Paid         | refused        | Shipped (AC-2) | refused        | Cancelled (AC-4) |
| Shipped      | refused        | refused      | Delivered (AC-3) | refused, AC-5 message |
| Delivered    | refused        | refused      | refused          | refused |
| Cancelled    | refused        | refused      | refused          | refused |

Release gate: cases tagged `@gate` (TC-ORD-001 to 005, 007).

---

## TC-ORD-001: New order starts in Placed

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                 |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (63/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — initial state (Placed)                                               |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | Operator is signed in; a product is in stock                                            |
| **Steps**              | 1. Create a new order <br> 2. Read the order's status                                   |
| **Expected**           | Status is exactly `Placed`. No other status is shown or returned.                       |
| **data-testid needed** | `order-status-badge`                                                                    |
| **Source**             | Added by QA (the story text says a new order starts as Placed; no AC states it)         |
| **Note**               | Every later case depends on this initial state.                                         |

---

## TC-ORD-002: Recording payment moves Placed to Paid

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                 |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (63/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — valid transition Placed → Paid                                       |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Placed`                                                    |
| **Steps**              | 1. Record a payment on the order <br> 2. Read the order's status                        |
| **Expected**           | Operation succeeds. Status is `Paid`.                                                   |
| **data-testid needed** | `order-record-payment-btn`, `order-status-badge`                                        |
| **Source**             | AC-1                                                                                    |
| **Note**               | N/A — no caveats                                                                        |

---

## TC-ORD-003: Marking shipped moves Paid to Shipped

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                 |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (61/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — valid transition Paid → Shipped                                      |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Paid`                                                      |
| **Steps**              | 1. Mark the order as shipped <br> 2. Read the order's status                            |
| **Expected**           | Operation succeeds. Status is `Shipped`.                                                |
| **data-testid needed** | `order-mark-shipped-btn`, `order-status-badge`                                          |
| **Source**             | AC-2                                                                                    |
| **Note**               | N/A — no caveats                                                                        |

---

## TC-ORD-004: Confirming delivery moves Shipped to Delivered

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                 |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (61/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — valid transition Shipped → Delivered                                 |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Shipped`                                                   |
| **Steps**              | 1. Confirm delivery of the order <br> 2. Read the order's status                        |
| **Expected**           | Operation succeeds. Status is `Delivered`.                                              |
| **data-testid needed** | `order-confirm-delivery-btn`, `order-status-badge`                                      |
| **Source**             | AC-3                                                                                    |
| **Note**               | N/A — no caveats                                                                        |

---

## TC-ORD-005: Cancelling a Placed order moves it to Cancelled

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                 |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (63/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — valid transition Placed → Cancelled                                  |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Placed`                                                    |
| **Steps**              | 1. Cancel the order <br> 2. Read the order's status                                     |
| **Expected**           | Operation succeeds. Status is `Cancelled`.                                              |
| **data-testid needed** | `order-cancel-btn`, `order-status-badge`                                                |
| **Source**             | AC-4                                                                                    |
| **Note**               | N/A — no caveats                                                                        |

---

## TC-ORD-006: Cancelling a Paid order moves it to Cancelled

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @api @ord @candidate`                                                  |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (61/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — valid transition Paid → Cancelled                                    |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Paid`                                                      |
| **Steps**              | 1. Cancel the order <br> 2. Read the order's status                                     |
| **Expected**           | Operation succeeds. Status is `Cancelled`.                                              |
| **data-testid needed** | `order-cancel-btn`, `order-status-badge`                                                |
| **Source**             | AC-4                                                                                    |
| **Note**               | The story does not mention a refund for a cancelled Paid order. Record what the system does as a finding; it is out of this story's scope. |

---

## TC-ORD-007: Cancelling a Shipped order is refused with the exact message

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @api @ord @candidate @gate`                                                 |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (61/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — invalid transition Shipped → cancel                                  |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Shipped`                                                   |
| **Steps**              | 1. Cancel the order <br> 2. Read the error returned <br> 3. Read the order's status     |
| **Expected**           | Operation is refused. Error message is exactly "Shipped orders cannot be cancelled." Status remains `Shipped`. |
| **data-testid needed** | `order-cancel-btn`, `order-error-message`, `order-status-badge`                         |
| **Source**             | AC-5                                                                                    |
| **Note**               | Assert the full string including the trailing period.                                  |

---

## TC-ORD-008: Cancelling a Delivered order is refused

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                  |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (56/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — invalid transition Delivered → cancel                                |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Delivered`                                                 |
| **Steps**              | 1. Cancel the order <br> 2. Read the order's status                                     |
| **Expected**           | Operation is refused with an error. Status remains `Delivered`.                         |
| **data-testid needed** | `order-cancel-btn`, `order-error-message`, `order-status-badge`                         |
| **Source**             | Added by QA (AC-4 lists only Placed and Paid as cancellable; the ticket is silent on Delivered) |
| **Note**               | Message text is unspecified (A3). Record the actual text as a finding and ask the PO whether it should match AC-5's wording. |

---

## TC-ORD-009: Cancelling an already Cancelled order is refused

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @api @ord @candidate`                                                  |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (54/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — invalid transition Cancelled → cancel (terminal state)               |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Cancelled`                                                 |
| **Steps**              | 1. Cancel the order again <br> 2. Read the order's status                               |
| **Expected**           | Operation is refused with an error, or is a no-op; either way status remains `Cancelled` and no second cancellation event is recorded. |
| **data-testid needed** | `order-cancel-btn`, `order-status-badge`                                                |
| **Source**             | Added by QA (the ticket is silent on repeating an operation on a terminal state)        |
| **Note**               | Idempotency is a design question for the PO; this case records the behaviour.           |

---

## TC-ORD-010: Marking a Placed order as shipped is refused

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                  |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (58/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — invalid transition Placed → mark shipped (skips Paid)                |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Placed`; no payment recorded                               |
| **Steps**              | 1. Mark the order as shipped <br> 2. Read the order's status                            |
| **Expected**           | Operation is refused with an error. Status remains `Placed`.                            |
| **data-testid needed** | `order-mark-shipped-btn`, `order-error-message`, `order-status-badge`                   |
| **Source**             | Added by QA (AC-2 allows shipping only from Paid; shipping an unpaid order is a revenue risk) |
| **Note**               | Highest-value negative case: an unpaid shipment is a direct financial loss.             |

---

## TC-ORD-011: Confirming delivery of a Paid order is refused

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                  |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (56/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — invalid transition Paid → confirm delivery (skips Shipped)           |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | An order exists with status `Paid`                                                      |
| **Steps**              | 1. Confirm delivery of the order <br> 2. Read the order's status                        |
| **Expected**           | Operation is refused with an error. Status remains `Paid`.                              |
| **data-testid needed** | `order-confirm-delivery-btn`, `order-error-message`, `order-status-badge`               |
| **Source**             | Added by QA (AC-3 allows delivery confirmation only from Shipped)                       |
| **Note**               | Also run from `Placed` as a variant; expected result is the same with status `Placed`.  |

---

## TC-ORD-012: Recording a second payment on a Paid order is refused

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @api @ord @candidate`                                                  |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | HIGH (56/67.5)                                                                          |
| **ISTQB Technique**    | EP — invalid partition (payment on a non-Placed order); covers Paid, Shipped, Delivered, Cancelled |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | One order in each of `Paid`, `Shipped`, `Delivered`, `Cancelled`                        |
| **Steps**              | 1. Record a payment on each order <br> 2. Read each order's status                      |
| **Expected**           | Every operation is refused with an error. Each status is unchanged. No duplicate payment is recorded. |
| **data-testid needed** | `order-record-payment-btn`, `order-error-message`, `order-status-badge`                 |
| **Source**             | Added by QA (AC-1 allows payment only from Placed; the ticket is silent on double payment) |
| **Note**               | Payment on a Cancelled order is the customer-facing risk here: money taken for an order that will never ship. |

---

## TC-ORD-013: Concurrent cancel and mark-shipped on a Paid order leaves one consistent status

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @integration @ord @candidate`                                          |
| **Issue**              | ORD-4                                                                                   |
| **Automation Score**   | MEDIUM (41/67.5)                                                                        |
| **ISTQB Technique**    | Error Guessing — race condition between two operators on the same order                 |
| **Manual Env**         | Local                                                                                   |
| **Precondition**       | An order exists with status `Paid`; two operator sessions open on it                    |
| **Steps**              | 1. From session A, cancel the order <br> 2. At the same moment, from session B, mark it shipped <br> 3. Read the order's status and the result each session received |
| **Expected**           | Exactly one operation succeeds. Status is either `Cancelled` or `Shipped`, never both and never a stale value. The losing session receives a refusal, not a success. |
| **data-testid needed** | `order-cancel-btn`, `order-mark-shipped-btn`, `order-status-badge`                      |
| **Source**             | Added by QA (the ticket is silent on concurrent status changes; a Shipped order that also reads Cancelled breaks the story's goal of a single visible status) |
| **Note**               | Automate at integration level with two parallel requests; UI-level timing is flaky. Lower score reflects setup effort and determinism risk. |

---

## Coverage summary

| AC / rule                    | Cases                       |
| ---------------------------- | --------------------------- |
| Initial state Placed (story) | TC-ORD-001                  |
| AC-1                         | TC-ORD-002                  |
| AC-2                         | TC-ORD-003                  |
| AC-3                         | TC-ORD-004                  |
| AC-4                         | TC-ORD-005, TC-ORD-006      |
| AC-5                         | TC-ORD-007                  |
| Invalid transitions (QA)     | TC-ORD-008 to TC-ORD-012    |
| Concurrency (QA)             | TC-ORD-013                  |

All five valid transitions are covered once (0-switch coverage). Every invalid cell of the transition table is covered by at least one case.

## Rules not applied

The `context-discovery` and `testing-guidelines` rules and the `qa-reference` skill were not in context and no `qa-rules` skill is installed in this session. The repository is empty, so context discovery had nothing to read; the assumptions section above stands in for it.
