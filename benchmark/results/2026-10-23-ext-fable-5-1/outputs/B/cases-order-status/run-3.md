# Test Cases — ORD-4: Order status changes

## Assumptions

- A1: The valid transitions are exactly those listed; any other transition (e.g. shipping a Placed order, paying a Paid order) is refused and leaves the status unchanged. The story does not specify error messages for these, so tests check only that the status is unchanged and that an error is returned.
- A2: Delivered and Cancelled are terminal: no further transition is accepted.
- A3: Refused operations return an error to the caller and do not persist any change.
- A4: Status is the only attribute changed by a transition; the test harness can read an order's status after each action (via API or UI).
- A5: Operations on a non-existent order are refused with a not-found error.
- A6: Where a status check is referenced, "customers and staff see" means the same status value is returned from both the customer order view and the staff/admin view.

## Positive paths (acceptance criteria)

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-01 | New order starts as Placed | None | 1. Create an order. 2. Read its status. | Status is `Placed`. | Intro |
| TC-02 | Payment moves Placed to Paid | Order in `Placed` | 1. Record a payment on the order. 2. Read status. | Status is `Paid`. | AC-1 |
| TC-03 | Shipping moves Paid to Shipped | Order in `Paid` | 1. Mark order as shipped. 2. Read status. | Status is `Shipped`. | AC-2 |
| TC-04 | Delivery moves Shipped to Delivered | Order in `Shipped` | 1. Confirm delivery. 2. Read status. | Status is `Delivered`. | AC-3 |
| TC-05 | Cancel a Placed order | Order in `Placed` | 1. Cancel the order. 2. Read status. | Status is `Cancelled`. | AC-4 |
| TC-06 | Cancel a Paid order | Order in `Paid` | 1. Cancel the order. 2. Read status. | Status is `Cancelled`. | AC-4 |
| TC-07 | Full happy path end to end | None | 1. Create order. 2. Record payment. 3. Mark shipped. 4. Confirm delivery. Read status after each step. | Statuses in order: `Placed`, `Paid`, `Shipped`, `Delivered`. | AC-1–3 |
| TC-08 | Cancelling a Shipped order is refused | Order in `Shipped` | 1. Attempt to cancel. 2. Read status. | Operation is refused with message exactly `Shipped orders cannot be cancelled.` Status remains `Shipped`. | AC-5 |

## Negative paths — invalid transitions (A1, A2)

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-09 | Record payment on Paid order | Order in `Paid` | Record a payment. | Refused; status remains `Paid`. |
| TC-10 | Record payment on Shipped order | Order in `Shipped` | Record a payment. | Refused; status remains `Shipped`. |
| TC-11 | Record payment on Delivered order | Order in `Delivered` | Record a payment. | Refused; status remains `Delivered`. |
| TC-12 | Record payment on Cancelled order | Order in `Cancelled` | Record a payment. | Refused; status remains `Cancelled`. |
| TC-13 | Ship a Placed (unpaid) order | Order in `Placed` | Mark as shipped. | Refused; status remains `Placed`. |
| TC-14 | Ship a Shipped order | Order in `Shipped` | Mark as shipped. | Refused; status remains `Shipped`. |
| TC-15 | Ship a Delivered order | Order in `Delivered` | Mark as shipped. | Refused; status remains `Delivered`. |
| TC-16 | Ship a Cancelled order | Order in `Cancelled` | Mark as shipped. | Refused; status remains `Cancelled`. |
| TC-17 | Confirm delivery on Placed order | Order in `Placed` | Confirm delivery. | Refused; status remains `Placed`. |
| TC-18 | Confirm delivery on Paid order | Order in `Paid` | Confirm delivery. | Refused; status remains `Paid`. |
| TC-19 | Confirm delivery on Delivered order | Order in `Delivered` | Confirm delivery. | Refused; status remains `Delivered`. |
| TC-20 | Confirm delivery on Cancelled order | Order in `Cancelled` | Confirm delivery. | Refused; status remains `Cancelled`. |
| TC-21 | Cancel a Delivered order | Order in `Delivered` | Cancel. | Refused; status remains `Delivered`. |
| TC-22 | Cancel a Cancelled order | Order in `Cancelled` | Cancel. | Refused (or no-op with no change); status remains `Cancelled`. |
| TC-23 | Refused cancellation message is not reused for other statuses | Order in `Delivered` | Cancel. | Error is returned, but the message is not `Shipped orders cannot be cancelled.` (message must describe the actual state). |

## Robustness and consistency

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-24 | Refused transition persists nothing | Order in `Shipped` | 1. Attempt cancel. 2. Reload order from storage/API in a fresh session. | Status is still `Shipped`; no partial update, no stray status-history entry for `Cancelled`. |
| TC-25 | Transition on non-existent order | No order with the given ID | Record payment / ship / deliver / cancel using an unknown order ID. | Each is refused with a not-found error; no order is created. |
| TC-26 | Customer and staff views agree after each transition | Order in `Placed` | After each of: payment, ship, deliver, read status from the customer view and the staff view. | Both views show the same status at every step. |
| TC-27 | Customer and staff views agree after cancellation | Order in `Paid` | Cancel; read both views. | Both views show `Cancelled`. |
| TC-28 | Concurrent conflicting transitions | Order in `Paid` | Submit "mark shipped" and "cancel" at the same time. | Exactly one succeeds; final status is either `Shipped` or `Cancelled`, never both applied and never an undefined/mixed state. The losing request is refused. |
| TC-29 | Duplicate payment submission (retry) | Order in `Placed` | Submit the same payment request twice in quick succession. | Status is `Paid`; second request is refused or treated as idempotent. Status never regresses. |
| TC-30 | Status set is closed | Any order | Attempt to set the status directly to a value outside {Placed, Paid, Shipped, Delivered, Cancelled} (e.g. `Refunded`, empty string, lowercase `paid`), if any such endpoint/field exists. | Refused; status unchanged. |
| TC-31 | Status is stable across reload | Order in `Shipped` | Restart the application / clear caches; read the order. | Status is `Shipped`. |
| TC-32 | Independent orders do not affect each other | Two orders A (`Placed`) and B (`Paid`) | Cancel A; read B. Ship B; read A. | A is `Cancelled`, B is `Shipped`; neither action changes the other order. |

## Traceability

| AC | Test cases |
|---|---|
| Order created as Placed | TC-01, TC-07 |
| AC-1 | TC-02, TC-07, TC-09–TC-12, TC-29 |
| AC-2 | TC-03, TC-07, TC-13–TC-16 |
| AC-3 | TC-04, TC-07, TC-17–TC-20 |
| AC-4 | TC-05, TC-06, TC-21, TC-22, TC-27, TC-28 |
| AC-5 | TC-08, TC-23, TC-24 |
| General (visibility, robustness) | TC-25, TC-26, TC-30–TC-32 |

## Open points for the product owner

- Error messages and HTTP/status codes for refused transitions other than AC-5 are unspecified; TC-09–TC-23 only assert refusal and unchanged status.
- Whether re-cancelling an already Cancelled order is an error or a silent no-op (TC-22) should be confirmed.
- Whether a Shipped order has any alternative path (e.g. return/refund) is out of scope for ORD-4 and not tested here.
