# Test cases: ORD-4 Order status changes

## Assumptions

- **Status values** are exactly Placed, Paid, Shipped, Delivered and Cancelled. No other status exists.
- **Any change the story does not list is refused**, and the order keeps its current status. The story gives a message only for AC-5, so these cases check the refusal and the unchanged status, not the message text.
- **Delivered and Cancelled are final.** No action changes an order out of either status.
- **The current status is visible** on the order's detail page to both staff and customers.
- **Assumed labels**, to be corrected by an editor who can see the product: **Record payment**, **Mark as shipped**, **Confirm delivery**, **Cancel order**, and a **Status** field on the order.
- **Each test starts with a fresh order** created by the store operator, unless the preconditions say otherwise.

## Test cases

### TC-01: A new order starts as Placed

Covers: story statement "An order is created with the status Placed."

1. Create a new order.
2. Open the order.

Expected: **Status** shows Placed.

### TC-02: Recording a payment on a Placed order sets it to Paid

Covers: AC-1

Preconditions: an order with status Placed.

1. Open the order.
2. Select **Record payment** and complete the action.

Expected: **Status** shows Paid.

### TC-03: Marking a Paid order as shipped sets it to Shipped

Covers: AC-2

Preconditions: an order with status Paid.

1. Open the order.
2. Select **Mark as shipped**.

Expected: **Status** shows Shipped.

### TC-04: Confirming delivery of a Shipped order sets it to Delivered

Covers: AC-3

Preconditions: an order with status Shipped.

1. Open the order.
2. Select **Confirm delivery**.

Expected: **Status** shows Delivered.

### TC-05: Cancelling a Placed order sets it to Cancelled

Covers: AC-4

Preconditions: an order with status Placed.

1. Open the order.
2. Select **Cancel order**.

Expected: **Status** shows Cancelled.

### TC-06: Cancelling a Paid order sets it to Cancelled

Covers: AC-4

Preconditions: an order with status Paid.

1. Open the order.
2. Select **Cancel order**.

Expected: **Status** shows Cancelled.

### TC-07: Cancelling a Shipped order is refused with the exact message

Covers: AC-5

Preconditions: an order with status Shipped.

1. Open the order.
2. Select **Cancel order**.

Expected:

- The action is refused.
- The message shown is exactly: `Shipped orders cannot be cancelled.`
- **Status** still shows Shipped.

### TC-08: Full path from Placed to Delivered

Covers: AC-1, AC-2, AC-3 in sequence.

1. Create a new order. **Status** shows Placed.
2. Select **Record payment**. **Status** shows Paid.
3. Select **Mark as shipped**. **Status** shows Shipped.
4. Select **Confirm delivery**. **Status** shows Delivered.

Expected: each step shows the status listed, in that order, with no skipped or extra status.

### TC-09: Marking a Placed order as shipped is refused

Covers: assumption that unlisted changes are refused (AC-2 only allows Paid orders).

Preconditions: an order with status Placed.

1. Open the order.
2. Select **Mark as shipped**.

Expected: the action is refused and **Status** still shows Placed.

### TC-10: Confirming delivery of a Paid order is refused

Covers: assumption that unlisted changes are refused (AC-3 only allows Shipped orders).

Preconditions: an order with status Paid.

1. Open the order.
2. Select **Confirm delivery**.

Expected: the action is refused and **Status** still shows Paid.

### TC-11: Recording a second payment on a Paid order is refused

Covers: assumption that unlisted changes are refused (AC-1 only allows Placed orders).

Preconditions: an order with status Paid.

1. Open the order.
2. Select **Record payment**.

Expected: the action is refused and **Status** still shows Paid.

### TC-12: Cancelling a Delivered order is refused

Covers: assumption that Delivered is final. AC-4 lists only Placed and Paid.

Preconditions: an order with status Delivered.

1. Open the order.
2. Select **Cancel order**.

Expected: the action is refused and **Status** still shows Delivered.

### TC-13: No action changes a Cancelled order

Covers: assumption that Cancelled is final.

Preconditions: an order with status Cancelled.

1. Open the order.
2. Select **Record payment**.
3. Select **Mark as shipped**.
4. Select **Confirm delivery**.
5. Select **Cancel order**.

Expected: every action is refused and **Status** still shows Cancelled after each one.

### TC-14: A status change is visible to staff and customers

Covers: story goal "customers and staff always see where an order is."

Preconditions: an order with status Placed, and a customer account that owns it.

1. As the store operator, select **Record payment** on the order.
2. As the store operator, open the order. **Status** shows Paid.
3. As the customer, open the same order.

Expected: the customer also sees Paid, with no further action needed.

## Coverage

| Criterion | Test cases |
| --- | --- |
| Created as Placed | TC-01, TC-08 |
| AC-1 | TC-02, TC-08, TC-11 |
| AC-2 | TC-03, TC-08, TC-09 |
| AC-3 | TC-04, TC-08, TC-10 |
| AC-4 | TC-05, TC-06, TC-12 |
| AC-5 | TC-07 |
| Final statuses (assumed) | TC-12, TC-13 |
| Visibility to staff and customers | TC-14 |

## Open points for the product owner

- Confirm the message text, if any, for refused actions other than AC-5.
- Confirm whether Delivered and Cancelled are final, as assumed in TC-12 and TC-13.
- Confirm the interface labels listed under Assumptions.
