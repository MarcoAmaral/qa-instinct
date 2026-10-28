# Test cases: ORD-4 Order status changes

Each test starts with a new order unless the preconditions say otherwise. A new order shows the status **Placed**.

## Assumptions

The story does not describe the interface or the behaviour outside the 5 acceptance criteria. These tests assume the following. Correct any that do not match the product before running the tests.

- Staff open an order from **Orders** and see its status in a field labelled **Status**.
- The actions are buttons on the order page labelled **Record payment**, **Mark as shipped**, **Confirm delivery** and **Cancel order**.
- An action that is not allowed for the current status is refused, the status does not change, and a message explains why. Only the message for AC-5 is given in the story. Other refusal messages are not checked for exact wording.
- **Delivered** and **Cancelled** are final. No action changes an order out of these statuses.
- Customers see the same status as staff on their order page.
- Payments, shipments and deliveries are recorded by a staff member using the buttons above. Automatic updates from payment or shipping providers are out of scope.

## Status flow under test

| From | Action | To |
| --- | --- | --- |
| (new order) | Create order | Placed |
| Placed | Record payment | Paid |
| Paid | Mark as shipped | Shipped |
| Shipped | Confirm delivery | Delivered |
| Placed | Cancel order | Cancelled |
| Paid | Cancel order | Cancelled |
| Shipped | Cancel order | Refused |

## Happy path

### TC-01: A new order starts as Placed

Covers: the opening statement of the story.

1. Create an order in the test store.
2. Open the order from **Orders**.

Expected: **Status** shows **Placed**.

### TC-02: Recording a payment moves a Placed order to Paid

Covers: AC-1.

Preconditions: an order with the status **Placed**.

1. Open the order.
2. Select **Record payment** and complete the form.

Expected: **Status** shows **Paid**.

### TC-03: Marking a Paid order as shipped moves it to Shipped

Covers: AC-2.

Preconditions: an order with the status **Paid**.

1. Open the order.
2. Select **Mark as shipped**.

Expected: **Status** shows **Shipped**.

### TC-04: Confirming delivery moves a Shipped order to Delivered

Covers: AC-3.

Preconditions: an order with the status **Shipped**.

1. Open the order.
2. Select **Confirm delivery**.

Expected: **Status** shows **Delivered**.

### TC-05: The full flow from Placed to Delivered

Covers: AC-1, AC-2, AC-3 in sequence on one order.

1. Create an order. Check that **Status** shows **Placed**.
2. Select **Record payment**. Check that **Status** shows **Paid**.
3. Select **Mark as shipped**. Check that **Status** shows **Shipped**.
4. Select **Confirm delivery**. Check that **Status** shows **Delivered**.

Expected: each step shows the status named in that step, with no step skipped.

## Cancelling

### TC-06: A Placed order can be cancelled

Covers: AC-4.

Preconditions: an order with the status **Placed**.

1. Open the order.
2. Select **Cancel order** and confirm.

Expected: **Status** shows **Cancelled**.

### TC-07: A Paid order can be cancelled

Covers: AC-4.

Preconditions: an order with the status **Paid**.

1. Open the order.
2. Select **Cancel order** and confirm.

Expected: **Status** shows **Cancelled**.

### TC-08: Cancelling a Shipped order is refused

Covers: AC-5.

Preconditions: an order with the status **Shipped**.

1. Open the order.
2. Select **Cancel order** and confirm.

Expected: the message "Shipped orders cannot be cancelled." appears. **Status** still shows **Shipped**.

### TC-09: Cancelling a Delivered order is refused

Covers: assumption that **Delivered** is final.

Preconditions: an order with the status **Delivered**.

1. Open the order.
2. Select **Cancel order**, if the button is available, and confirm.

Expected: the order is not cancelled. **Status** still shows **Delivered**. Note the message shown, if any, for the product owner to confirm.

## Actions out of order

Each of these tests checks that an action is refused when the order is not in the right status, and that the status does not change.

### TC-10: Marking a Placed order as shipped is refused

Preconditions: an order with the status **Placed**.

1. Open the order.
2. Select **Mark as shipped**, if the button is available.

Expected: the action is refused. **Status** still shows **Placed**.

### TC-11: Confirming delivery of a Placed order is refused

Preconditions: an order with the status **Placed**.

1. Open the order.
2. Select **Confirm delivery**, if the button is available.

Expected: the action is refused. **Status** still shows **Placed**.

### TC-12: Confirming delivery of a Paid order is refused

Preconditions: an order with the status **Paid**.

1. Open the order.
2. Select **Confirm delivery**, if the button is available.

Expected: the action is refused. **Status** still shows **Paid**.

### TC-13: Recording a payment on a Paid order does not change its status

Preconditions: an order with the status **Paid**.

1. Open the order.
2. Select **Record payment**, if the button is available, and complete the form.

Expected: **Status** still shows **Paid**. Note whether the second payment is accepted or refused, for the product owner to confirm.

### TC-14: No action changes a Cancelled order

Covers: assumption that **Cancelled** is final.

Preconditions: an order with the status **Cancelled**.

1. Open the order.
2. Try each of **Record payment**, **Mark as shipped** and **Confirm delivery**, if the buttons are available.

Expected: every action is refused. **Status** still shows **Cancelled**.

### TC-15: No action changes a Delivered order

Covers: assumption that **Delivered** is final.

Preconditions: an order with the status **Delivered**.

1. Open the order.
2. Try each of **Record payment**, **Mark as shipped** and **Confirm delivery**, if the buttons are available.

Expected: every action is refused. **Status** still shows **Delivered**.

## Status shown to customers

### TC-16: The customer sees the same status as staff

Covers: the story goal that customers and staff see where an order is.

Preconditions: an order placed by a test customer account.

1. As staff, select **Record payment** on the order.
2. As the customer, open the order from the customer account.
3. Repeat for **Mark as shipped**, **Confirm delivery**, and, on a second order, **Cancel order**.

Expected: after each action, the customer view shows the same status as **Status** on the staff page.

## Coverage

| Criterion | Test cases |
| --- | --- |
| Order created as Placed | TC-01, TC-05 |
| AC-1 | TC-02, TC-05 |
| AC-2 | TC-03, TC-05 |
| AC-3 | TC-04, TC-05 |
| AC-4 | TC-06, TC-07 |
| AC-5 | TC-08 |
| Assumed final statuses | TC-09, TC-14, TC-15 |
| Assumed refused actions | TC-10 to TC-13 |
| Story goal | TC-16 |

## Open questions for the product owner

These do not block the tests above, but the expected results marked "note" depend on them.

- What message, if any, is shown when an action other than cancelling is refused?
- Can a payment be recorded twice on the same order, for example a partial payment?
- Does a cancelled Paid order need a refund step, and does that affect the status?
- Are **Delivered** and **Cancelled** final, or can staff reopen an order?
