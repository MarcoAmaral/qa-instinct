## Test Cases: ORD-4 Order Status Changes

### Assumptions

- A newly created order always starts in status Placed with no way to specify a different initial status.
- The status set is exactly: Placed, Paid, Shipped, Delivered, Cancelled. No other statuses exist.
- Transitions not listed in the acceptance criteria are refused and leave the status unchanged. The exact refusal message for those cases is unspecified, so tests only assert that the operation is refused and the status is unchanged.
- A refused operation does not create a partial change, side effect, or new status history entry.
- Delivered and Cancelled are terminal. No transition out of them is allowed.
- Each operation is applied to one order at a time by an authorised store operator. Permissions are out of scope for this story.

### Acceptance criteria coverage

| ID | Title | Precondition | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-01 | New order starts as Placed | None | Create a new order. | Order status is Placed. | Preamble |
| TC-02 | Record payment on Placed order | Order in status Placed | Record a payment on the order. | Status becomes Paid. | AC-1 |
| TC-03 | Mark Paid order as shipped | Order in status Paid | Mark the order as shipped. | Status becomes Shipped. | AC-2 |
| TC-04 | Confirm delivery of Shipped order | Order in status Shipped | Confirm delivery. | Status becomes Delivered. | AC-3 |
| TC-05 | Cancel Placed order | Order in status Placed | Cancel the order. | Status becomes Cancelled. | AC-4 |
| TC-06 | Cancel Paid order | Order in status Paid | Cancel the order. | Status becomes Cancelled. | AC-4 |
| TC-07 | Cancel Shipped order is refused | Order in status Shipped | Cancel the order. | Operation is refused with the message "Shipped orders cannot be cancelled." Status remains Shipped. | AC-5 |
| TC-08 | Full happy path end to end | None | Create order, record payment, mark shipped, confirm delivery. | Status moves Placed → Paid → Shipped → Delivered, in that order, with no intermediate state skipped. | AC-1 to AC-3 |

### Invalid transitions (negative cases)

Each of these expects the operation to be refused and the status to remain unchanged.

| ID | Title | Precondition | Steps | Expected result |
|---|---|---|---|---|
| TC-09 | Ship a Placed order | Order in status Placed | Mark the order as shipped. | Refused. Status remains Placed. |
| TC-10 | Confirm delivery of a Placed order | Order in status Placed | Confirm delivery. | Refused. Status remains Placed. |
| TC-11 | Confirm delivery of a Paid order | Order in status Paid | Confirm delivery. | Refused. Status remains Paid. |
| TC-12 | Record payment on a Paid order | Order in status Paid | Record a payment. | Refused. Status remains Paid. |
| TC-13 | Record payment on a Shipped order | Order in status Shipped | Record a payment. | Refused. Status remains Shipped. |
| TC-14 | Ship a Shipped order | Order in status Shipped | Mark the order as shipped. | Refused. Status remains Shipped. |
| TC-15 | Cancel a Delivered order | Order in status Delivered | Cancel the order. | Refused. Status remains Delivered. |
| TC-16 | Record payment on a Delivered order | Order in status Delivered | Record a payment. | Refused. Status remains Delivered. |
| TC-17 | Ship a Delivered order | Order in status Delivered | Mark the order as shipped. | Refused. Status remains Delivered. |
| TC-18 | Confirm delivery of a Delivered order | Order in status Delivered | Confirm delivery. | Refused. Status remains Delivered. |
| TC-19 | Record payment on a Cancelled order | Order in status Cancelled | Record a payment. | Refused. Status remains Cancelled. |
| TC-20 | Ship a Cancelled order | Order in status Cancelled | Mark the order as shipped. | Refused. Status remains Cancelled. |
| TC-21 | Confirm delivery of a Cancelled order | Order in status Cancelled | Confirm delivery. | Refused. Status remains Cancelled. |
| TC-22 | Cancel a Cancelled order | Order in status Cancelled | Cancel the order. | Refused. Status remains Cancelled. |

### Edge and robustness cases

| ID | Title | Precondition | Steps | Expected result |
|---|---|---|---|---|
| TC-23 | Refused cancel leaves no side effects | Order in status Shipped | Cancel the order, then read the order back. | Status is Shipped. No cancellation timestamp, reason, or history entry was recorded. |
| TC-24 | Refusal message is exact | Order in status Shipped | Cancel the order and capture the error message. | Message equals "Shipped orders cannot be cancelled." exactly, including the trailing period and capitalisation. |
| TC-25 | Shipped order can still be delivered after a refused cancel | Order in status Shipped | Attempt to cancel, then confirm delivery. | Cancel is refused. Delivery succeeds and status becomes Delivered. |
| TC-26 | Status change persists across reload | Order in status Placed | Record a payment, then fetch the order fresh from storage. | Fetched order shows status Paid. |
| TC-27 | Operations on one order do not affect another | Two orders A and B, both Placed | Record a payment on order A. | Order A is Paid. Order B remains Placed. |
| TC-28 | Operation on a non-existent order | No order with the given id | Record a payment, ship, deliver, or cancel using an unknown order id. | Operation is refused with a not-found style error. No order is created. |
| TC-29 | Concurrent cancel and ship on a Paid order | Order in status Paid | Submit a cancel and a ship request at the same time. | Exactly one succeeds. The final status is either Cancelled or Shipped, never both, and the losing request is refused. |
| TC-30 | Concurrent duplicate payment on a Placed order | Order in status Placed | Submit two record-payment requests at the same time. | Status is Paid. The second request is refused as a duplicate rather than silently succeeding. |

### Traceability

| Acceptance criterion | Test cases |
|---|---|
| Created as Placed | TC-01, TC-08 |
| AC-1 | TC-02, TC-08, TC-12, TC-13, TC-16, TC-19, TC-26, TC-27, TC-30 |
| AC-2 | TC-03, TC-08, TC-09, TC-14, TC-17, TC-20 |
| AC-3 | TC-04, TC-08, TC-10, TC-11, TC-18, TC-21, TC-25 |
| AC-4 | TC-05, TC-06, TC-15, TC-22, TC-29 |
| AC-5 | TC-07, TC-23, TC-24, TC-25 |
