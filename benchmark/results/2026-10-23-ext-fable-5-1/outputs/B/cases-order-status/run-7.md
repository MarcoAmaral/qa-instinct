# Test Cases: ORD-4 Order Status Changes

## Assumptions

1. **Statuses are exactly five:** Placed, Paid, Shipped, Delivered, Cancelled. No other statuses exist.
2. **Transitions are strictly linear.** Paid -> Shipped -> Delivered is the only forward path. Skipping a step (e.g. shipping a Placed order) is rejected. The story doesn't say this, but "fixed set of statuses" implies it.
3. **Delivered and Cancelled are terminal.** No action changes an order out of either state.
4. **Rejected transitions leave the status unchanged** and return an error. For transitions other than AC-5 the exact wording is unspecified, so tests only check that an error is returned and the status is untouched.
5. **A rejected transition is not persisted.** Refreshing or reloading the order shows the original status.
6. **"Recording a payment" is a single action.** Partial payments and payment failures are out of scope for this story.
7. **Cancelling a Paid order does not test refunds.** Any refund behaviour belongs to a separate story.
8. **Actor:** a store operator with permission to perform all actions. Role-based restrictions are out of scope.
9. **Each transition is exposed through an interface** (API or UI) that accepts an order ID and returns the resulting status or an error. Tests are written at that level.

## Preconditions

- A store operator account exists and is authenticated.
- A fresh order can be created on demand. Each test creates its own order so tests are independent.

---

## Positive tests: happy path

### TC-01 New order starts as Placed
**Covers:** story preamble
**Steps:**
1. Create a new order.
2. Read the order's status.

**Expected:** Status is `Placed`.

### TC-02 Record payment on a Placed order
**Covers:** AC-1
**Steps:**
1. Create a new order (status Placed).
2. Record a payment on it.
3. Read the order's status.

**Expected:** Action succeeds. Status is `Paid`.

### TC-03 Mark a Paid order as shipped
**Covers:** AC-2
**Steps:**
1. Create an order and record a payment (status Paid).
2. Mark the order as shipped.
3. Read the order's status.

**Expected:** Action succeeds. Status is `Shipped`.

### TC-04 Confirm delivery of a Shipped order
**Covers:** AC-3
**Steps:**
1. Create an order, record payment, mark as shipped (status Shipped).
2. Confirm delivery.
3. Read the order's status.

**Expected:** Action succeeds. Status is `Delivered`.

### TC-05 Full lifecycle end to end
**Covers:** AC-1, AC-2, AC-3
**Steps:**
1. Create an order. Verify `Placed`.
2. Record payment. Verify `Paid`.
3. Mark shipped. Verify `Shipped`.
4. Confirm delivery. Verify `Delivered`.

**Expected:** Each step succeeds and the status after each step matches.

### TC-06 Cancel a Placed order
**Covers:** AC-4
**Steps:**
1. Create a new order (status Placed).
2. Cancel the order.
3. Read the order's status.

**Expected:** Action succeeds. Status is `Cancelled`.

### TC-07 Cancel a Paid order
**Covers:** AC-4
**Steps:**
1. Create an order and record a payment (status Paid).
2. Cancel the order.
3. Read the order's status.

**Expected:** Action succeeds. Status is `Cancelled`.

---

## Negative tests: explicitly specified

### TC-08 Cancel a Shipped order is refused
**Covers:** AC-5
**Steps:**
1. Create an order, record payment, mark as shipped (status Shipped).
2. Attempt to cancel the order.
3. Read the order's status.

**Expected:** Action is refused. Error message is exactly:
```
Shipped orders cannot be cancelled.
```
Status remains `Shipped`.

### TC-09 Cancel a Shipped order: message text is exact
**Covers:** AC-5
**Steps:**
1. Same as TC-08, step 1 and 2.
2. Compare the error text character by character, including the trailing full stop and capitalisation.

**Expected:** The message matches the spec string exactly, with no extra prefix, suffix, or wrapping.

---

## Negative tests: invalid transitions (assumption 2 and 3)

Each case follows the same pattern: set up the order in the given state, attempt the action, check that an error is returned and the status is unchanged.

| ID | Starting status | Action | Expected status after | Covers |
|---|---|---|---|---|
| TC-10 | Placed | Mark shipped | Placed | AC-2 (skip Paid) |
| TC-11 | Placed | Confirm delivery | Placed | AC-3 (skip Paid, Shipped) |
| TC-12 | Paid | Confirm delivery | Paid | AC-3 (skip Shipped) |
| TC-13 | Paid | Record payment | Paid | AC-1 (double payment) |
| TC-14 | Shipped | Record payment | Shipped | AC-1 |
| TC-15 | Shipped | Mark shipped | Shipped | AC-2 (double ship) |
| TC-16 | Delivered | Record payment | Delivered | AC-1 (terminal) |
| TC-17 | Delivered | Mark shipped | Delivered | AC-2 (terminal) |
| TC-18 | Delivered | Confirm delivery | Delivered | AC-3 (double delivery) |
| TC-19 | Delivered | Cancel | Delivered | AC-4/AC-5 (terminal) |
| TC-20 | Cancelled | Record payment | Cancelled | AC-1 (terminal) |
| TC-21 | Cancelled | Mark shipped | Cancelled | AC-2 (terminal) |
| TC-22 | Cancelled | Confirm delivery | Cancelled | AC-3 (terminal) |
| TC-23 | Cancelled | Cancel | Cancelled | AC-4 (double cancel) |

**Expected for all:** The action is rejected with an error. Status is unchanged. For TC-19, the spec gives no message, so only check for a rejection; do not assert the AC-5 wording unless the implementation chooses to reuse it.

---

## Persistence and consistency

### TC-24 Status survives reload
**Covers:** all ACs
**Steps:**
1. Create an order and record a payment.
2. Reload the order from storage (new request, new session, or re-fetch by ID).

**Expected:** Status is `Paid`. Repeat for Shipped, Delivered, and Cancelled.

### TC-25 Rejected transition is not persisted
**Covers:** AC-5
**Steps:**
1. Create an order, record payment, mark shipped.
2. Attempt to cancel (refused).
3. Reload the order by ID.

**Expected:** Status is `Shipped`. No partial or intermediate state was saved.

### TC-26 Status is visible to both staff and customer views
**Covers:** story goal ("customers and staff always see where an order is")
**Steps:**
1. Create an order and move it to Shipped.
2. View the order as a store operator.
3. View the same order as the customer who placed it.

**Expected:** Both views show `Shipped`. Repeat after Delivered and after Cancelled.

### TC-27 Transitions on one order do not affect another
**Covers:** all ACs
**Steps:**
1. Create orders A and B.
2. Record payment on A only.
3. Read status of B.

**Expected:** A is `Paid`. B is still `Placed`.

---

## Concurrency and edge cases

### TC-28 Concurrent cancel and ship on a Paid order
**Covers:** AC-2, AC-4, AC-5
**Steps:**
1. Create an order and record payment (status Paid).
2. Simultaneously send "cancel" and "mark shipped" requests.
3. Read the final status.

**Expected:** Exactly one request succeeds. Final status is either `Shipped` or `Cancelled`, never both and never an inconsistent state. The losing request receives a rejection. If cancel lost, the error is "Shipped orders cannot be cancelled."

### TC-29 Duplicate identical requests
**Covers:** AC-1
**Steps:**
1. Create an order.
2. Send two "record payment" requests simultaneously.

**Expected:** Final status is `Paid`. At most one request is reported as the transition; the other is rejected or treated as idempotent. No crash or data corruption.

### TC-30 Action on a non-existent order
**Covers:** all ACs
**Steps:**
1. Attempt to record payment, ship, deliver, and cancel using an order ID that does not exist.

**Expected:** Each action returns a "not found" style error. No order is created as a side effect.

### TC-31 Action with a malformed order ID
**Covers:** all ACs
**Steps:**
1. Attempt each transition with an empty ID, a null ID, and an ID of the wrong type or format.

**Expected:** Each action returns a validation error. No status is changed on any order.

### TC-32 Status value is from the fixed set only
**Covers:** story goal ("fixed set of statuses")
**Steps:**
1. Attempt to set an order's status directly to an arbitrary value (e.g. `Refunded`, `placed` in lower case, empty string) through any available write path.

**Expected:** Rejected. Only Placed, Paid, Shipped, Delivered, Cancelled are ever stored or displayed. If no direct write path exists, record this as not applicable.

---

## Traceability

| AC | Test cases |
|---|---|
| Preamble (created as Placed) | TC-01, TC-05, TC-27 |
| AC-1 | TC-02, TC-05, TC-13, TC-14, TC-16, TC-20, TC-24, TC-29 |
| AC-2 | TC-03, TC-05, TC-10, TC-15, TC-17, TC-21, TC-28 |
| AC-3 | TC-04, TC-05, TC-11, TC-12, TC-18, TC-22 |
| AC-4 | TC-06, TC-07, TC-19, TC-23, TC-28 |
| AC-5 | TC-08, TC-09, TC-25, TC-28 |
| Fixed status set | TC-32 |
| Visibility to customers and staff | TC-26 |

## Out of scope

- Refund handling when a Paid order is cancelled.
- Partial payments, failed payments, or payment provider errors.
- Role-based access control for who may perform each transition.
- Audit history or timestamps for status changes.
- Notifications to customers on status change.
