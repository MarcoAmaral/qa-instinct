# Test cases: ORD-4 Order status changes

## Assumptions

The story does not describe the interface or the transitions it leaves out. These test cases assume the following; correct them before running.

- The order page shows a **Status** field and the actions **Record payment**, **Mark as shipped**, **Confirm delivery** and **Cancel order**.
- A refused action shows the message on the order page and leaves the status unchanged.
- Any transition the story does not list is refused (for example, shipping a Placed order). TC-09 to TC-13 cover these and are marked as assumed. If the product allows them, drop those cases.
- Delivered and Cancelled are end states. No action changes them.
- Test data: a store operator account and a way to create a fresh order for each case.

## Transition matrix

| From | Record payment | Mark as shipped | Confirm delivery | Cancel order |
| --- | --- | --- | --- | --- |
| Placed | Paid (AC-1) | Refused (assumed) | Refused (assumed) | Cancelled (AC-4) |
| Paid | Refused (assumed) | Shipped (AC-2) | Refused (assumed) | Cancelled (AC-4) |
| Shipped | Refused (assumed) | Refused (assumed) | Delivered (AC-3) | Refused, message (AC-5) |
| Delivered | Refused (assumed) | Refused (assumed) | Refused (assumed) | Refused (assumed) |
| Cancelled | Refused (assumed) | Refused (assumed) | Refused (assumed) | Refused (assumed) |

## Test cases

### TC-01: A new order starts as Placed

Covers: story precondition.

1. Create a new order.
2. Open the order.

Expected: **Status** shows **Placed**.

### TC-02: Record a payment on a Placed order

Covers: AC-1.

Before you start: an order with status **Placed**.

1. Open the order.
2. Select **Record payment**.

Expected: **Status** changes to **Paid**.

### TC-03: Mark a Paid order as shipped

Covers: AC-2.

Before you start: an order with status **Paid**.

1. Open the order.
2. Select **Mark as shipped**.

Expected: **Status** changes to **Shipped**.

### TC-04: Confirm delivery of a Shipped order

Covers: AC-3.

Before you start: an order with status **Shipped**.

1. Open the order.
2. Select **Confirm delivery**.

Expected: **Status** changes to **Delivered**.

### TC-05: Cancel a Placed order

Covers: AC-4.

Before you start: an order with status **Placed**.

1. Open the order.
2. Select **Cancel order**.

Expected: **Status** changes to **Cancelled**.

### TC-06: Cancel a Paid order

Covers: AC-4.

Before you start: an order with status **Paid**.

1. Open the order.
2. Select **Cancel order**.

Expected: **Status** changes to **Cancelled**.

### TC-07: Cancelling a Shipped order is refused

Covers: AC-5.

Before you start: an order with status **Shipped**.

1. Open the order.
2. Select **Cancel order**.

Expected: the message "Shipped orders cannot be cancelled." is shown, exactly as written. **Status** still shows **Shipped**.

### TC-08: Full path from Placed to Delivered

Covers: AC-1, AC-2, AC-3 together.

1. Create a new order. **Status** shows **Placed**.
2. Select **Record payment**. **Status** shows **Paid**.
3. Select **Mark as shipped**. **Status** shows **Shipped**.
4. Select **Confirm delivery**. **Status** shows **Delivered**.

Expected: each status appears in that order, and no step is refused.

### TC-09: Shipping a Placed order is refused (assumed)

Before you start: an order with status **Placed**.

1. Open the order.
2. Select **Mark as shipped**.

Expected: the action is refused. **Status** still shows **Placed**.

### TC-10: Confirming delivery of a Paid order is refused (assumed)

Before you start: an order with status **Paid**.

1. Open the order.
2. Select **Confirm delivery**.

Expected: the action is refused. **Status** still shows **Paid**.

### TC-11: Recording a second payment is refused (assumed)

Before you start: an order with status **Paid**.

1. Open the order.
2. Select **Record payment**.

Expected: the action is refused. **Status** still shows **Paid**.

### TC-12: Cancelling a Delivered order is refused (assumed)

Before you start: an order with status **Delivered**.

1. Open the order.
2. Select **Cancel order**.

Expected: the action is refused. **Status** still shows **Delivered**. Note the message shown, since the story does not define one.

### TC-13: No action changes a Cancelled order (assumed)

Before you start: an order with status **Cancelled**.

1. Open the order.
2. Select **Record payment**, then **Mark as shipped**, then **Confirm delivery**, then **Cancel order**, one at a time.

Expected: every action is refused. **Status** still shows **Cancelled** after each one.

### TC-14: Customer sees the current status

Covers: the story goal that customers see where an order is.

Before you start: an order with status **Placed**, and the customer account that placed it.

1. As the operator, select **Record payment**.
2. As the customer, open the order.

Expected: the customer sees **Paid**. Repeat for **Shipped**, **Delivered** and **Cancelled**.

## Traceability

| Criterion | Test cases |
| --- | --- |
| Precondition (new order is Placed) | TC-01, TC-08 |
| AC-1 | TC-02, TC-08 |
| AC-2 | TC-03, TC-08 |
| AC-3 | TC-04, TC-08 |
| AC-4 | TC-05, TC-06 |
| AC-5 | TC-07 |
| Not in story (assumed) | TC-09 to TC-13 |
| Story goal (visibility) | TC-14 |

## Open points for the product owner

- Which transitions outside the list are refused, and what message each shows.
- Whether the refusal in AC-5 is a message on the page, a disabled **Cancel order** action, or both.
- Whether customers and staff see the same status names.
