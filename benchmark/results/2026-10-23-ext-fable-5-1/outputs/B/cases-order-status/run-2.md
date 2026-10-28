# Test Cases — ORD-4: Order status changes

## Assumptions

1. The status set is exactly: Placed, Paid, Shipped, Delivered, Cancelled. No other statuses exist.
2. Delivered and Cancelled are terminal. No transition out of either is permitted; such attempts are refused with an error and the status is unchanged.
3. Any transition not listed in AC-1 to AC-4 (for example, shipping a Placed order, delivering a Paid order, paying a Paid order) is refused with an error and the status is unchanged. The exact wording of those errors is not specified, so tests assert only that the operation fails and the status does not change.
4. Error messages are matched exactly where specified (AC-5), including the trailing period.
5. Transitions are exposed through an API or UI action per transition: record payment, mark shipped, confirm delivery, cancel. Tests are written against behaviour, not a specific interface.
6. Each successful transition is persisted and visible on re-read, and the system records a transition timestamp (the audit trail itself is out of scope here).
7. Only one status is stored per order; transitions are atomic.

## Test case format

Each case lists Preconditions, Steps, and Expected result. Priority: P1 = core acceptance, P2 = guard rail / negative, P3 = edge.

---

## A. Order creation

**TC-01 New order is created as Placed** (P1, covers story statement)
- Preconditions: Operator can create an order.
- Steps: Create a new order with valid data. Read the order back.
- Expected: Status is `Placed`. No other status value is shown anywhere for the order.

**TC-02 Status cannot be set directly at creation** (P2, assumption 1)
- Preconditions: Create endpoint or form accepts an order payload.
- Steps: Attempt to create an order supplying a status of `Paid`, `Shipped`, `Delivered`, and `Cancelled` in turn.
- Expected: Either the supplied status is ignored and the order is `Placed`, or the request is rejected. The order is never created in a non-Placed status.

---

## B. AC-1: Placed → Paid

**TC-03 Record payment on Placed order** (P1)
- Preconditions: Order in `Placed`.
- Steps: Record a payment. Read the order back.
- Expected: Status is `Paid`. The change is persisted after refresh.

**TC-04 Record payment on Paid order is refused** (P2, assumption 3)
- Preconditions: Order in `Paid`.
- Steps: Record a payment again.
- Expected: Operation is refused with an error. Status remains `Paid`. No duplicate payment is recorded.

**TC-05 Record payment on Shipped, Delivered, Cancelled orders is refused** (P2)
- Preconditions: Three orders, one each in `Shipped`, `Delivered`, `Cancelled`.
- Steps: Record a payment on each.
- Expected: Each is refused with an error. Each status is unchanged.

---

## C. AC-2: Paid → Shipped

**TC-06 Mark Paid order as shipped** (P1)
- Preconditions: Order in `Paid`.
- Steps: Mark as shipped. Read the order back.
- Expected: Status is `Shipped`. The change is persisted.

**TC-07 Mark Placed order as shipped is refused** (P2)
- Preconditions: Order in `Placed` (unpaid).
- Steps: Mark as shipped.
- Expected: Refused with an error. Status remains `Placed`. Payment step cannot be skipped.

**TC-08 Mark Shipped, Delivered, Cancelled orders as shipped is refused** (P2)
- Preconditions: Three orders in `Shipped`, `Delivered`, `Cancelled`.
- Steps: Mark each as shipped.
- Expected: Each refused. Statuses unchanged.

---

## D. AC-3: Shipped → Delivered

**TC-09 Confirm delivery of Shipped order** (P1)
- Preconditions: Order in `Shipped`.
- Steps: Confirm delivery. Read the order back.
- Expected: Status is `Delivered`. The change is persisted.

**TC-10 Confirm delivery of Placed or Paid order is refused** (P2)
- Preconditions: Two orders, one in `Placed`, one in `Paid`.
- Steps: Confirm delivery on each.
- Expected: Each refused. Statuses unchanged. Shipping step cannot be skipped.

**TC-11 Confirm delivery twice on same order is refused** (P2)
- Preconditions: Order in `Delivered`.
- Steps: Confirm delivery again.
- Expected: Refused. Status remains `Delivered`.

**TC-12 Confirm delivery of Cancelled order is refused** (P2)
- Preconditions: Order in `Cancelled`.
- Steps: Confirm delivery.
- Expected: Refused. Status remains `Cancelled`.

---

## E. AC-4: Cancel Placed or Paid

**TC-13 Cancel a Placed order** (P1)
- Preconditions: Order in `Placed`.
- Steps: Cancel the order. Read it back.
- Expected: Status is `Cancelled`. The change is persisted.

**TC-14 Cancel a Paid order** (P1)
- Preconditions: Order in `Paid`.
- Steps: Cancel the order. Read it back.
- Expected: Status is `Cancelled`. The change is persisted. (Refund handling is out of scope for this story; note any refund side effect for a separate story.)

**TC-15 Cancel an already Cancelled order is refused** (P2)
- Preconditions: Order in `Cancelled`.
- Steps: Cancel again.
- Expected: Refused with an error. Status remains `Cancelled`. The error is not the AC-5 message.

**TC-16 Cancel a Delivered order is refused** (P2, assumption 2)
- Preconditions: Order in `Delivered`.
- Steps: Cancel the order.
- Expected: Refused with an error. Status remains `Delivered`. The error is not the AC-5 "Shipped orders" message.

---

## F. AC-5: Cancelling Shipped is refused

**TC-17 Cancel a Shipped order returns exact error** (P1)
- Preconditions: Order in `Shipped`.
- Steps: Cancel the order.
- Expected: Refused. Error message is exactly `Shipped orders cannot be cancelled.` including capitalisation and trailing period. Status remains `Shipped`.

**TC-18 Shipped order remains deliverable after failed cancel** (P2)
- Preconditions: TC-17 just executed on an order.
- Steps: Confirm delivery on that order.
- Expected: Status becomes `Delivered`. The refused cancel left no partial state.

**TC-19 Repeated cancel attempts on Shipped order** (P3)
- Preconditions: Order in `Shipped`.
- Steps: Attempt cancel three times in a row.
- Expected: Each attempt returns the same AC-5 message. Status remains `Shipped` throughout.

---

## G. Full lifecycle and terminal states

**TC-20 Happy path end to end** (P1)
- Preconditions: None.
- Steps: Create order. Record payment. Mark shipped. Confirm delivery. Read status after each step.
- Expected: Status sequence observed is `Placed` → `Paid` → `Shipped` → `Delivered`.

**TC-21 Delivered is terminal** (P2)
- Preconditions: Order in `Delivered`.
- Steps: Attempt each of: record payment, mark shipped, confirm delivery, cancel.
- Expected: All four refused. Status remains `Delivered`.

**TC-22 Cancelled is terminal** (P2)
- Preconditions: Order in `Cancelled` (one cancelled from Placed, one from Paid).
- Steps: On each, attempt: record payment, mark shipped, confirm delivery, cancel.
- Expected: All refused on both orders. Status remains `Cancelled`.

**TC-23 Transition matrix check** (P2)
- Preconditions: One order in each of the five statuses.
- Steps: Apply each of the four operations to each order (20 combinations).
- Expected: Exactly these five succeed, and all others are refused with status unchanged:

| From | Operation | Result |
|---|---|---|
| Placed | Record payment | Paid |
| Paid | Mark shipped | Shipped |
| Shipped | Confirm delivery | Delivered |
| Placed | Cancel | Cancelled |
| Paid | Cancel | Cancelled |

---

## H. Concurrency, persistence, and robustness

**TC-24 Concurrent conflicting transitions** (P2)
- Preconditions: Order in `Paid`.
- Steps: Submit "mark shipped" and "cancel" at the same moment from two sessions.
- Expected: Exactly one succeeds. Final status is either `Shipped` or `Cancelled`, never both or a mixed state. The losing request receives a refusal consistent with the new status (if shipped first, the cancel returns the AC-5 message).

**TC-25 Duplicate concurrent payment** (P3)
- Preconditions: Order in `Placed`.
- Steps: Submit two "record payment" requests simultaneously.
- Expected: Status is `Paid`. At most one payment is recorded. The second request is refused or idempotently absorbed, per assumption 3.

**TC-26 Transition on a non-existent order** (P2)
- Preconditions: An order ID that does not exist.
- Steps: Attempt each of the four operations against that ID.
- Expected: Each is refused with a not-found error. No order is created as a side effect.

**TC-27 Status survives restart / re-read** (P2)
- Preconditions: Order moved to `Shipped`.
- Steps: Restart the service or clear client cache. Read the order.
- Expected: Status is still `Shipped`.

**TC-28 Failed transition leaves no partial write** (P2)
- Preconditions: Order in `Placed`.
- Steps: Mark as shipped (invalid). Read order record directly from storage.
- Expected: Status is `Placed`, no updated timestamp for a shipped event, no orphaned transition record.

---

## I. Visibility to customers and staff

**TC-29 Customer view reflects each status** (P1, story goal)
- Preconditions: An order visible to its customer.
- Steps: Walk the order through Placed, Paid, Shipped, Delivered. After each step, view as the customer.
- Expected: Customer sees the current status each time with no stale value.

**TC-30 Staff and customer see the same status** (P2)
- Preconditions: Order in `Cancelled`.
- Steps: View as store operator and as customer.
- Expected: Both views show `Cancelled`.

**TC-31 Status labels use the exact fixed names** (P3)
- Preconditions: Orders in each status.
- Steps: Inspect displayed and API status values.
- Expected: Values are exactly `Placed`, `Paid`, `Shipped`, `Delivered`, `Cancelled`. No synonyms (for example "Complete", "Canceled", "In transit").

---

## Traceability

| AC | Test cases |
|---|---|
| Story: created as Placed | TC-01, TC-02, TC-20 |
| AC-1 | TC-03, TC-04, TC-05, TC-23 |
| AC-2 | TC-06, TC-07, TC-08, TC-23 |
| AC-3 | TC-09, TC-10, TC-11, TC-12, TC-23 |
| AC-4 | TC-13, TC-14, TC-15, TC-16, TC-23 |
| AC-5 | TC-17, TC-18, TC-19, TC-24 |
| Terminal states (assumption 2) | TC-21, TC-22 |
| Robustness | TC-24 to TC-28 |
| Visibility (story goal) | TC-29, TC-30, TC-31 |

## Open questions for the product owner (not blocking)

- Should Delivered and Cancelled be strictly terminal, or is a return / reopen flow planned?
- What error messages should invalid transitions other than AC-5 return?
- Should cancelling a Paid order trigger a refund, and is that part of this story?
- Is a status change history (who, when) required for customers or staff?
