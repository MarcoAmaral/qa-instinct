# Test cases: ORD-4 Order status changes

Each test checks one status change from the story. The tests use the order page in the store back office and the order page a customer sees.

## Assumptions

The story does not show the interface, so the tests assume these labels. Correct them before running the tests.

- The order page shows the current status in a field labelled **Status**.
- The actions are buttons on the order page labelled **Record payment**, **Mark as shipped**, **Confirm delivery** and **Cancel order**.
- A refused action shows its message on the order page and leaves the status unchanged.
- An action that is not listed for a status (for example **Mark as shipped** on a Placed order) is refused. The story does not give these messages, so the tests only check that the status does not change.
- Delivered and Cancelled are final. No action changes an order out of either status.
- The customer sees the same status as staff on their own order page.

## Setup for every test

- You are signed in as a store operator.
- You can create a test order from a demo customer account.
- Unless a test says otherwise, create a fresh order before each test.

## Test cases

### TC-01: A new order starts as Placed

Covers: the opening line of the story.

1. Create a new order.
2. Open the order page.

Expected: **Status** shows **Placed**.

### TC-02: Record a payment on a Placed order

Covers: AC-1.

1. Open a Placed order.
2. Select **Record payment**.

Expected: **Status** shows **Paid**.

### TC-03: Mark a Paid order as shipped

Covers: AC-2.

1. Open a Paid order.
2. Select **Mark as shipped**.

Expected: **Status** shows **Shipped**.

### TC-04: Confirm delivery of a Shipped order

Covers: AC-3.

1. Open a Shipped order.
2. Select **Confirm delivery**.

Expected: **Status** shows **Delivered**.

### TC-05: Cancel a Placed order

Covers: AC-4.

1. Open a Placed order.
2. Select **Cancel order**.

Expected: **Status** shows **Cancelled**.

### TC-06: Cancel a Paid order

Covers: AC-4.

1. Open a Paid order.
2. Select **Cancel order**.

Expected: **Status** shows **Cancelled**.

### TC-07: Cancelling a Shipped order is refused

Covers: AC-5.

1. Open a Shipped order.
2. Select **Cancel order**.

Expected: the page shows the message `Shipped orders cannot be cancelled.` with that exact wording. **Status** still shows **Shipped**.

### TC-08: An order moves through every status in order

Covers: AC-1, AC-2 and AC-3 together.

1. Create a new order and confirm **Status** shows **Placed**.
2. Select **Record payment** and confirm **Status** shows **Paid**.
3. Select **Mark as shipped** and confirm **Status** shows **Shipped**.
4. Select **Confirm delivery** and confirm **Status** shows **Delivered**.

Expected: each step shows the status named in that step, and no step is refused.

### TC-09: Marking a Placed order as shipped is refused

Covers: assumption that steps cannot be skipped.

1. Open a Placed order.
2. Select **Mark as shipped**.

Expected: the action is refused. **Status** still shows **Placed**.

### TC-10: Confirming delivery of a Paid order is refused

Covers: assumption that steps cannot be skipped.

1. Open a Paid order.
2. Select **Confirm delivery**.

Expected: the action is refused. **Status** still shows **Paid**.

### TC-11: Recording a second payment on a Paid order does not change the status

Covers: assumption that an action cannot be repeated.

1. Open a Paid order.
2. Select **Record payment**.

Expected: the action is refused or ignored. **Status** still shows **Paid**.

### TC-12: Cancelling a Delivered order is refused

Covers: assumption that Delivered is final.

1. Open a Delivered order.
2. Select **Cancel order**.

Expected: the action is refused. **Status** still shows **Delivered**.

### TC-13: No action changes a Cancelled order

Covers: assumption that Cancelled is final.

1. Open a Cancelled order.
2. Select **Record payment**.
3. Select **Mark as shipped**.
4. Select **Confirm delivery**.
5. Select **Cancel order**.

Expected: every action is refused or ignored. **Status** still shows **Cancelled** after each step.

### TC-14: The customer sees the new status

Covers: the story goal that customers see where an order is.

1. As the store operator, open a Placed order and select **Record payment**.
2. Sign in as the customer who placed the order.
3. Open the same order.

Expected: the customer's order page shows **Paid**.

## Traceability

| Requirement | Test cases |
| --- | --- |
| Order is created as Placed | TC-01, TC-08 |
| AC-1 | TC-02, TC-08, TC-11 |
| AC-2 | TC-03, TC-08, TC-09 |
| AC-3 | TC-04, TC-08, TC-10 |
| AC-4 | TC-05, TC-06 |
| AC-5 | TC-07 |
| Final statuses (assumed) | TC-12, TC-13 |
| Customers see the status | TC-14 |

## Open questions for the story owner

- What message appears when an action is refused for a reason other than AC-5?
- Is **Record payment** allowed more than once on an order, for example for partial payments?
- Can a Delivered or Cancelled order ever change status, for example after a return?
