# Test Cases — ORD-4: Order status changes

## Assumptions

- A1: Orders are created via an API or UI action; the exact mechanism is not specified, so tests refer to "create an order" generically.
- A2: Each transition is triggered by a distinct action: Record Payment, Mark Shipped, Confirm Delivery, Cancel.
- A3: Transitions not listed in the acceptance criteria (e.g. shipping a Placed order, paying a Shipped order, any change to a Delivered or Cancelled order) are invalid and should be refused without changing status. The story does not specify the error message for these, so tests assert only that the action is refused and the status is unchanged.
- A4: Cancelling a Delivered or Cancelled order is refused. The story only specifies the message for Shipped orders, so the message for other refused cancellations is not asserted.
- A5: The valid statuses are exactly: Placed, Paid, Shipped, Delivered, Cancelled.
- A6: Refused transitions do not create a status-change record or side effects.
- A7: Status is visible to both customers and staff through some view; tests refer to "the order's status" as the value returned/displayed to both.

## Priority legend

P1 = core acceptance criteria, P2 = negative/invalid transitions, P3 = edge cases and robustness.

---

## Section 1 — Initial status

### TC-01 New order has status Placed (P1)
**Precondition:** None.
**Steps:**
1. Create a new order.
2. Read the order's status.

**Expected:** Status is `Placed`.

### TC-02 New order status is Placed regardless of order content (P3)
**Precondition:** None.
**Steps:**
1. Create an order with a single line item.
2. Create an order with multiple line items.
3. Read each order's status.

**Expected:** Both orders have status `Placed`.

---

## Section 2 — AC-1: Placed → Paid

### TC-03 Recording payment on a Placed order sets status to Paid (P1)
**Precondition:** An order in status `Placed`.
**Steps:**
1. Record a payment on the order.
2. Read the order's status.

**Expected:** Status is `Paid`.

### TC-04 Recording payment on a Paid order is refused (P2)
**Precondition:** An order in status `Paid`.
**Steps:**
1. Record a payment on the order.
2. Read the order's status.

**Expected:** The action is refused. Status remains `Paid`. (Assumption A3.)

### TC-05 Recording payment on a Shipped order is refused (P2)
**Precondition:** An order in status `Shipped`.
**Steps:**
1. Record a payment on the order.
2. Read the order's status.

**Expected:** Action refused. Status remains `Shipped`.

### TC-06 Recording payment on a Delivered order is refused (P2)
**Precondition:** An order in status `Delivered`.
**Steps:**
1. Record a payment on the order.
2. Read the order's status.

**Expected:** Action refused. Status remains `Delivered`.

### TC-07 Recording payment on a Cancelled order is refused (P2)
**Precondition:** An order in status `Cancelled`.
**Steps:**
1. Record a payment on the order.
2. Read the order's status.

**Expected:** Action refused. Status remains `Cancelled`.

---

## Section 3 — AC-2: Paid → Shipped

### TC-08 Marking a Paid order as shipped sets status to Shipped (P1)
**Precondition:** An order in status `Paid`.
**Steps:**
1. Mark the order as shipped.
2. Read the order's status.

**Expected:** Status is `Shipped`.

### TC-09 Marking a Placed order as shipped is refused (P2)
**Precondition:** An order in status `Placed` (no payment recorded).
**Steps:**
1. Mark the order as shipped.
2. Read the order's status.

**Expected:** Action refused. Status remains `Placed`. An unpaid order must not ship.

### TC-10 Marking a Shipped order as shipped again is refused (P2)
**Precondition:** An order in status `Shipped`.
**Steps:**
1. Mark the order as shipped.
2. Read the order's status.

**Expected:** Action refused. Status remains `Shipped`.

### TC-11 Marking a Delivered order as shipped is refused (P2)
**Precondition:** An order in status `Delivered`.
**Steps:**
1. Mark the order as shipped.
2. Read the order's status.

**Expected:** Action refused. Status remains `Delivered`.

### TC-12 Marking a Cancelled order as shipped is refused (P2)
**Precondition:** An order in status `Cancelled`.
**Steps:**
1. Mark the order as shipped.
2. Read the order's status.

**Expected:** Action refused. Status remains `Cancelled`.

---

## Section 4 — AC-3: Shipped → Delivered

### TC-13 Confirming delivery of a Shipped order sets status to Delivered (P1)
**Precondition:** An order in status `Shipped`.
**Steps:**
1. Confirm delivery of the order.
2. Read the order's status.

**Expected:** Status is `Delivered`.

### TC-14 Confirming delivery of a Placed order is refused (P2)
**Precondition:** An order in status `Placed`.
**Steps:**
1. Confirm delivery of the order.
2. Read the order's status.

**Expected:** Action refused. Status remains `Placed`.

### TC-15 Confirming delivery of a Paid order is refused (P2)
**Precondition:** An order in status `Paid`.
**Steps:**
1. Confirm delivery of the order.
2. Read the order's status.

**Expected:** Action refused. Status remains `Paid`.

### TC-16 Confirming delivery of a Delivered order again is refused (P2)
**Precondition:** An order in status `Delivered`.
**Steps:**
1. Confirm delivery of the order.
2. Read the order's status.

**Expected:** Action refused. Status remains `Delivered`.

### TC-17 Confirming delivery of a Cancelled order is refused (P2)
**Precondition:** An order in status `Cancelled`.
**Steps:**
1. Confirm delivery of the order.
2. Read the order's status.

**Expected:** Action refused. Status remains `Cancelled`.

---

## Section 5 — AC-4: Cancellation of Placed or Paid orders

### TC-18 Cancelling a Placed order sets status to Cancelled (P1)
**Precondition:** An order in status `Placed`.
**Steps:**
1. Cancel the order.
2. Read the order's status.

**Expected:** Status is `Cancelled`.

### TC-19 Cancelling a Paid order sets status to Cancelled (P1)
**Precondition:** An order in status `Paid`.
**Steps:**
1. Cancel the order.
2. Read the order's status.

**Expected:** Status is `Cancelled`.

### TC-20 Cancelling a Delivered order is refused (P2)
**Precondition:** An order in status `Delivered`.
**Steps:**
1. Cancel the order.
2. Read the order's status.

**Expected:** Action refused. Status remains `Delivered`. (Assumption A4; message not asserted.)

### TC-21 Cancelling an already Cancelled order is refused (P2)
**Precondition:** An order in status `Cancelled`.
**Steps:**
1. Cancel the order.
2. Read the order's status.

**Expected:** Action refused. Status remains `Cancelled`. (Assumption A4.)

---

## Section 6 — AC-5: Cancellation of Shipped orders

### TC-22 Cancelling a Shipped order is refused with the specified message (P1)
**Precondition:** An order in status `Shipped`.
**Steps:**
1. Cancel the order.
2. Capture the response/error shown.
3. Read the order's status.

**Expected:**
- The action is refused.
- The message is exactly `Shipped orders cannot be cancelled.` (including trailing full stop, case as written).
- Status remains `Shipped`.

### TC-23 Refused cancellation leaves the Shipped order fully usable (P2)
**Precondition:** An order in status `Shipped`.
**Steps:**
1. Attempt to cancel the order (expect refusal).
2. Confirm delivery of the order.
3. Read the order's status.

**Expected:** Step 2 succeeds. Status is `Delivered`. The refused cancellation did not block or corrupt the order.

### TC-24 Repeated cancellation attempts on a Shipped order are each refused (P3)
**Precondition:** An order in status `Shipped`.
**Steps:**
1. Attempt to cancel the order three times in succession.
2. Read the order's status after each attempt.

**Expected:** Each attempt returns `Shipped orders cannot be cancelled.` Status remains `Shipped` every time.

---

## Section 7 — End-to-end flows

### TC-25 Full happy path: Placed → Paid → Shipped → Delivered (P1)
**Precondition:** None.
**Steps:**
1. Create an order; verify status `Placed`.
2. Record payment; verify status `Paid`.
3. Mark as shipped; verify status `Shipped`.
4. Confirm delivery; verify status `Delivered`.

**Expected:** Each status matches as listed, in order, with no intermediate or skipped states.

### TC-26 Early cancellation path: Placed → Cancelled (P1)
**Precondition:** None.
**Steps:**
1. Create an order; verify `Placed`.
2. Cancel; verify `Cancelled`.
3. Attempt Record Payment, Mark Shipped, Confirm Delivery.

**Expected:** Step 2 yields `Cancelled`. Every action in step 3 is refused and status stays `Cancelled`.

### TC-27 Post-payment cancellation path: Placed → Paid → Cancelled (P1)
**Precondition:** None.
**Steps:**
1. Create an order; verify `Placed`.
2. Record payment; verify `Paid`.
3. Cancel; verify `Cancelled`.
4. Attempt Mark Shipped and Confirm Delivery.

**Expected:** Step 3 yields `Cancelled`. Each action in step 4 is refused and status stays `Cancelled`.

### TC-28 Delivered is terminal (P2)
**Precondition:** An order in status `Delivered`.
**Steps:**
1. Attempt Record Payment, Mark Shipped, Confirm Delivery, and Cancel.
2. Read the order's status after each.

**Expected:** Every action is refused. Status remains `Delivered` throughout.

### TC-29 Cancelled is terminal (P2)
**Precondition:** An order in status `Cancelled`.
**Steps:**
1. Attempt Record Payment, Mark Shipped, Confirm Delivery, and Cancel.
2. Read the order's status after each.

**Expected:** Every action is refused. Status remains `Cancelled` throughout.

### TC-30 Skipping a step is not allowed (P2)
**Precondition:** An order in status `Placed`.
**Steps:**
1. Attempt Confirm Delivery directly.
2. Attempt Mark Shipped directly.
3. Read the order's status.

**Expected:** Both actions refused. Status remains `Placed`. Orders cannot jump ahead in the sequence.

---

## Section 8 — Visibility and consistency

### TC-31 Customer and staff views show the same status after each transition (P2)
**Precondition:** An order in status `Placed`; customer and staff views available.
**Steps:**
1. After each transition in the happy path (TC-25), read the status from the customer view and the staff view.

**Expected:** Both views show the identical status at every step, with no stale value.

### TC-32 Status persists after reload / re-fetch (P2)
**Precondition:** An order in status `Paid`.
**Steps:**
1. Mark the order as shipped.
2. Re-fetch the order from storage (reload page or new API call).

**Expected:** Status is `Shipped` on re-fetch. The change was persisted, not only held in memory.

### TC-33 Status value is one of exactly the five defined statuses (P3)
**Precondition:** Orders in each of the five statuses.
**Steps:**
1. Read the status of each order.

**Expected:** Each value is exactly one of `Placed`, `Paid`, `Shipped`, `Delivered`, `Cancelled`. No other values, casing variants, or blank values appear. (Assumption A5.)

---

## Section 9 — Robustness and edge cases

### TC-34 Concurrent conflicting transitions on the same order (P3)
**Precondition:** An order in status `Paid`.
**Steps:**
1. Simultaneously issue Mark Shipped and Cancel for the same order.
2. Read the final status.

**Expected:** Exactly one action succeeds. Final status is either `Shipped` or `Cancelled`, never both applied, never an intermediate or invalid state. The losing action is refused. If the Cancel loses to Mark Shipped, the refusal message is `Shipped orders cannot be cancelled.`

### TC-35 Duplicate submission of the same transition (P3)
**Precondition:** An order in status `Placed`.
**Steps:**
1. Submit Record Payment twice in rapid succession (e.g. double-click or retried request).
2. Read the order's status.

**Expected:** Status is `Paid`. The second submission is refused or ignored; the order is not left in an inconsistent state.

### TC-36 Transition on a non-existent order is refused (P3)
**Precondition:** An order ID that does not exist.
**Steps:**
1. Attempt each of the four actions against the non-existent ID.

**Expected:** Each action is refused with a not-found style error. No order is created as a side effect.

### TC-37 Transitions on one order do not affect another (P3)
**Precondition:** Two orders A and B, both in status `Placed`.
**Steps:**
1. Record payment on order A.
2. Read the status of order B.

**Expected:** Order A is `Paid`. Order B remains `Placed`.

### TC-38 Refused transition produces no status-change record (P3)
**Precondition:** An order in status `Shipped`; status history is available.
**Steps:**
1. Attempt to cancel the order (refused).
2. Inspect the order's status history.

**Expected:** No new history entry is created for the refused attempt. (Assumption A6; skip if no history exists.)

---

## Traceability matrix

| Acceptance criterion | Test cases |
|---|---|
| Initial status is Placed | TC-01, TC-02, TC-25 |
| AC-1 Placed → Paid | TC-03, TC-04, TC-05, TC-06, TC-07, TC-25, TC-35 |
| AC-2 Paid → Shipped | TC-08, TC-09, TC-10, TC-11, TC-12, TC-25 |
| AC-3 Shipped → Delivered | TC-13, TC-14, TC-15, TC-16, TC-17, TC-25, TC-30 |
| AC-4 Cancel Placed/Paid | TC-18, TC-19, TC-20, TC-21, TC-26, TC-27 |
| AC-5 Cancel Shipped refused | TC-22, TC-23, TC-24, TC-34 |
| Terminal states (derived) | TC-28, TC-29 |
| Visibility / persistence | TC-31, TC-32, TC-33 |
| Robustness | TC-34, TC-35, TC-36, TC-37, TC-38 |

## Open questions for the product owner (not blocking)

1. What message should be returned for refused transitions other than cancelling a Shipped order (e.g. shipping a Placed order)?
2. Should a Cancelled order that was Paid trigger a refund, and does that affect status?
3. Is any transition out of Delivered (e.g. returns) planned? If so, Delivered-is-terminal tests will need revisiting.
