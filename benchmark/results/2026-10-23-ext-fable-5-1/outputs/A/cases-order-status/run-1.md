## Test Cases: ORD-4 Order status changes

### Assumptions

- A1: A newly created order always has status Placed and no other initial status is possible.
- A2: Each transition is a distinct operation (record payment, mark shipped, confirm delivery, cancel) exposed on the order.
- A3: Transitions not listed in the acceptance criteria (for example shipping a Placed order, paying a Shipped order, or any change to a Delivered or Cancelled order) are refused and leave the status unchanged. The story does not specify messages for these cases, so tests assert only that the operation is refused and the status is unchanged.
- A4: A refused transition is surfaced as an error to the caller and produces no side effects.
- A5: Repeating a transition already applied (for example paying a Paid order) is treated as an invalid transition per A3, not as an idempotent no-op.
- A6: The cancellation refusal message is matched exactly, including the trailing period.

### Happy path

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-01 | New order starts as Placed | None | 1. Create an order. 2. Read its status. | Status is Placed. | Story preamble, A1 |
| TC-02 | Payment moves Placed to Paid | Order in status Placed | 1. Record a payment on the order. 2. Read its status. | Operation succeeds. Status is Paid. | AC-1 |
| TC-03 | Shipping moves Paid to Shipped | Order in status Paid | 1. Mark the order as shipped. 2. Read its status. | Operation succeeds. Status is Shipped. | AC-2 |
| TC-04 | Delivery moves Shipped to Delivered | Order in status Shipped | 1. Confirm delivery of the order. 2. Read its status. | Operation succeeds. Status is Delivered. | AC-3 |
| TC-05 | Full lifecycle Placed to Delivered | None | 1. Create an order. 2. Record a payment. 3. Mark shipped. 4. Confirm delivery. Read status after each step. | Statuses observed in order: Placed, Paid, Shipped, Delivered. | AC-1, AC-2, AC-3 |
| TC-06 | Cancel a Placed order | Order in status Placed | 1. Cancel the order. 2. Read its status. | Operation succeeds. Status is Cancelled. | AC-4 |
| TC-07 | Cancel a Paid order | Order in status Paid | 1. Cancel the order. 2. Read its status. | Operation succeeds. Status is Cancelled. | AC-4 |

### Refused cancellation

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-08 | Cancel a Shipped order is refused | Order in status Shipped | 1. Cancel the order. 2. Read its status. | Operation is refused with the message `Shipped orders cannot be cancelled.` Status remains Shipped. | AC-5, A6 |
| TC-09 | Refused cancellation leaves order usable | Order in status Shipped | 1. Attempt to cancel the order. 2. Confirm delivery of the order. | Step 1 is refused per TC-08. Step 2 succeeds and status is Delivered. | AC-5, AC-3, A4 |

### Invalid transitions from Placed

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-10 | Ship a Placed order | Order in status Placed | 1. Mark the order as shipped. | Operation is refused. Status remains Placed. | A3 |
| TC-11 | Deliver a Placed order | Order in status Placed | 1. Confirm delivery of the order. | Operation is refused. Status remains Placed. | A3 |

### Invalid transitions from Paid

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-12 | Pay a Paid order again | Order in status Paid | 1. Record a payment on the order. | Operation is refused. Status remains Paid. | A3, A5 |
| TC-13 | Deliver a Paid order | Order in status Paid | 1. Confirm delivery of the order. | Operation is refused. Status remains Paid. | A3 |

### Invalid transitions from Shipped

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-14 | Pay a Shipped order | Order in status Shipped | 1. Record a payment on the order. | Operation is refused. Status remains Shipped. | A3 |
| TC-15 | Ship a Shipped order again | Order in status Shipped | 1. Mark the order as shipped. | Operation is refused. Status remains Shipped. | A3, A5 |

### Terminal state: Delivered

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-16 | Pay a Delivered order | Order in status Delivered | 1. Record a payment on the order. | Operation is refused. Status remains Delivered. | A3 |
| TC-17 | Ship a Delivered order | Order in status Delivered | 1. Mark the order as shipped. | Operation is refused. Status remains Delivered. | A3 |
| TC-18 | Deliver a Delivered order again | Order in status Delivered | 1. Confirm delivery of the order. | Operation is refused. Status remains Delivered. | A3, A5 |
| TC-19 | Cancel a Delivered order | Order in status Delivered | 1. Cancel the order. | Operation is refused. Status remains Delivered. The message is not asserted because the story only specifies one for Shipped orders. | A3 |

### Terminal state: Cancelled

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-20 | Pay a Cancelled order | Order in status Cancelled | 1. Record a payment on the order. | Operation is refused. Status remains Cancelled. | A3 |
| TC-21 | Ship a Cancelled order | Order in status Cancelled | 1. Mark the order as shipped. | Operation is refused. Status remains Cancelled. | A3 |
| TC-22 | Deliver a Cancelled order | Order in status Cancelled | 1. Confirm delivery of the order. | Operation is refused. Status remains Cancelled. | A3 |
| TC-23 | Cancel a Cancelled order again | Order in status Cancelled | 1. Cancel the order. | Operation is refused. Status remains Cancelled. | A3, A5 |

### Isolation

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-24 | Transitions affect only the target order | Two orders, both in status Placed | 1. Record a payment on order A. 2. Read the status of both orders. | Order A is Paid. Order B remains Placed. | AC-1 |
| TC-25 | Refused transition on one order does not affect another | Order A in status Shipped, order B in status Paid | 1. Attempt to cancel order A. 2. Cancel order B. | Step 1 is refused per TC-08. Step 2 succeeds and order B is Cancelled. Order A remains Shipped. | AC-4, AC-5 |

### Coverage matrix

| Criterion | Test cases |
|---|---|
| Initial status Placed | TC-01, TC-05 |
| AC-1 | TC-02, TC-05, TC-24 |
| AC-2 | TC-03, TC-05 |
| AC-3 | TC-04, TC-05, TC-09 |
| AC-4 | TC-06, TC-07, TC-25 |
| AC-5 | TC-08, TC-09, TC-25 |
| Unspecified transitions (A3) | TC-10 to TC-23 |

### Open points for the product owner

- Whether repeated transitions such as paying a Paid order should be refused or silently accepted. Tests TC-12, TC-15, TC-18, and TC-23 assume refusal and will need updating if idempotency is wanted.
- Whether a Delivered order can be cancelled, for example for a return flow. TC-19 assumes it cannot.
- The expected error messages for all refused transitions other than cancelling a Shipped order.
