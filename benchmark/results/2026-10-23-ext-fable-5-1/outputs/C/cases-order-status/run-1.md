# Test cases: ORD-4 Order status changes

## Assumptions

- **Labels.** The actions are called **Record payment**, **Mark as shipped**, **Confirm delivery** and **Cancel order**. Correct these if the product uses other names.
- **Delivered and Cancelled are final.** The story does not say what happens to a Delivered or Cancelled order. These tests assume no further action is allowed on either, and that the refusal reason is shown to the operator. See TC-10 to TC-13.
- **Out-of-order actions are refused.** The story does not say what happens when an action is used on the wrong status, for example **Mark as shipped** on a Placed order. These tests assume the action is refused and the status does not change. The wording of the refusal is not specified, so those tests check only that the status stays the same. See TC-07 to TC-09.
- **Refusal wording.** The message in AC-5 is checked word for word, including the full stop.
- **Setup.** Each test starts with a new order unless the preconditions say otherwise. The tester can create an order and move it through statuses with the actions above.

## Status flow under test

| From | Action | To |
| --- | --- | --- |
| (new order) | Create order | Placed |
| Placed | Record payment | Paid |
| Paid | Mark as shipped | Shipped |
| Shipped | Confirm delivery | Delivered |
| Placed | Cancel order | Cancelled |
| Paid | Cancel order | Cancelled |
| Shipped | Cancel order | Refused, stays Shipped |

## Test cases

### TC-01: A new order starts as Placed

Covers: story statement "An order is created with the status Placed."

1. Create a new order.
2. Open the order.

Expected: the order status is **Placed**.

### TC-02: Recording a payment moves a Placed order to Paid

Covers: AC-1

Preconditions: an order with status **Placed**.

1. Open the order.
2. Select **Record payment**.

Expected: the order status is **Paid**.

### TC-03: Marking a Paid order as shipped moves it to Shipped

Covers: AC-2

Preconditions: an order with status **Paid**.

1. Open the order.
2. Select **Mark as shipped**.

Expected: the order status is **Shipped**.

### TC-04: Confirming delivery moves a Shipped order to Delivered

Covers: AC-3

Preconditions: an order with status **Shipped**.

1. Open the order.
2. Select **Confirm delivery**.

Expected: the order status is **Delivered**.

### TC-05: Cancelling a Placed order moves it to Cancelled

Covers: AC-4

Preconditions: an order with status **Placed**.

1. Open the order.
2. Select **Cancel order**.

Expected: the order status is **Cancelled**.

### TC-06: Cancelling a Paid order moves it to Cancelled

Covers: AC-4

Preconditions: an order with status **Paid**.

1. Open the order.
2. Select **Cancel order**.

Expected: the order status is **Cancelled**.

### TC-07: Cancelling a Shipped order is refused with the exact message

Covers: AC-5

Preconditions: an order with status **Shipped**.

1. Open the order.
2. Select **Cancel order**.

Expected:
- The message "Shipped orders cannot be cancelled." is shown, with that exact wording.
- The order status is still **Shipped**.

### TC-08: Full happy path from Placed to Delivered

Covers: AC-1, AC-2, AC-3 in sequence

1. Create a new order. Check the status is **Placed**.
2. Select **Record payment**. Check the status is **Paid**.
3. Select **Mark as shipped**. Check the status is **Shipped**.
4. Select **Confirm delivery**. Check the status is **Delivered**.

Expected: each status matches the step, in that order, with no steps skipped.

### TC-09: Marking a Placed order as shipped is refused

Covers: assumption that out-of-order actions are refused. Confirm with the product owner.

Preconditions: an order with status **Placed**.

1. Open the order.
2. Select **Mark as shipped**.

Expected: the order status is still **Placed**.

### TC-10: Confirming delivery of a Paid order is refused

Covers: assumption that out-of-order actions are refused. Confirm with the product owner.

Preconditions: an order with status **Paid**.

1. Open the order.
2. Select **Confirm delivery**.

Expected: the order status is still **Paid**.

### TC-11: Recording a payment on a Paid order does not change the status

Covers: assumption that repeating an action is refused or ignored. Confirm with the product owner.

Preconditions: an order with status **Paid**.

1. Open the order.
2. Select **Record payment**.

Expected: the order status is still **Paid**.

### TC-12: Cancelling a Delivered order is refused

Covers: assumption that Delivered is final. Confirm with the product owner.

Preconditions: an order with status **Delivered**.

1. Open the order.
2. Select **Cancel order**.

Expected: the order status is still **Delivered**.

### TC-13: Recording a payment on a Cancelled order is refused

Covers: assumption that Cancelled is final. Confirm with the product owner.

Preconditions: an order with status **Cancelled**.

1. Open the order.
2. Select **Record payment**.

Expected: the order status is still **Cancelled**.

### TC-14: Cancelling a Cancelled order does not change the status

Covers: assumption that Cancelled is final. Confirm with the product owner.

Preconditions: an order with status **Cancelled**.

1. Open the order.
2. Select **Cancel order**.

Expected: the order status is still **Cancelled**.

### TC-15: A refused cancellation leaves the order usable

Covers: AC-5 together with AC-3

Preconditions: an order with status **Shipped**.

1. Open the order.
2. Select **Cancel order**. Check the message "Shipped orders cannot be cancelled." is shown.
3. Select **Confirm delivery**.

Expected: the order status is **Delivered**. The refused cancellation did not block the next step.

### TC-16: Status changes are visible to staff and customers

Covers: story goal "customers and staff always see where an order is."

Preconditions: an order with status **Placed**. A staff view and a customer view of the same order.

1. In the staff view, select **Record payment**.
2. Refresh the customer view of the order.
3. Refresh the staff order list.

Expected: both views show **Paid**. The order list shows the same status as the order page.

## Coverage

| Requirement | Test cases |
| --- | --- |
| New order is Placed | TC-01, TC-08 |
| AC-1 | TC-02, TC-08, TC-16 |
| AC-2 | TC-03, TC-08 |
| AC-3 | TC-04, TC-08, TC-15 |
| AC-4 | TC-05, TC-06 |
| AC-5 | TC-07, TC-15 |
| Assumed rules (not in story) | TC-09 to TC-14 |

## Open questions for the product owner

- What happens when an action is used on the wrong status, and what message is shown? TC-09 to TC-11 depend on the answer.
- Can a Delivered or Cancelled order change status at all? TC-12 to TC-14 depend on the answer.
- Can a Placed order be marked as shipped without a payment, for example for free orders? If yes, TC-09 is wrong.
