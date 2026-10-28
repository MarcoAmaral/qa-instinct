# Test cases: ORD-4 Order status changes

## Assumptions

The story does not cover these points. Each test that relies on one names it.

- **A1:** Transitions not listed in the story are refused and the order keeps its current status. The story gives a message only for cancelling a Shipped order, so other refusals check the status and that an error is shown, not the exact wording.
- **A2:** Delivered and Cancelled are end states. No action changes them.
- **A3:** The 5 statuses are shown exactly as **Placed**, **Paid**, **Shipped**, **Delivered** and **Cancelled**.
- **A4:** "Recording a payment", "marking as shipped", "confirming delivery" and "cancelling" are 4 separate actions available to a store operator. Tests name them as actions, not as interface labels, until the labels are known.
- **A5:** Any order visible to staff is also visible to the customer who placed it, with the same status.

## Traceability

| AC | Test cases |
| --- | --- |
| Creation | TC-01 |
| AC-1 | TC-02, TC-07, TC-08 |
| AC-2 | TC-03, TC-09, TC-10 |
| AC-3 | TC-04, TC-11, TC-12 |
| AC-4 | TC-05, TC-06 |
| AC-5 | TC-13 |
| A2 | TC-14, TC-15 |
| Full path | TC-16, TC-17 |

## Test cases

### TC-01: A new order starts as Placed

- **Covers:** Order creation
- **Preconditions:** None.
- **Steps:**
  1. Create a new order.
  2. Open the order.
- **Expected result:** The order status is **Placed**.

### TC-02: Recording a payment moves a Placed order to Paid

- **Covers:** AC-1
- **Preconditions:** An order with status **Placed**.
- **Steps:**
  1. Record a payment on the order.
  2. Open the order.
- **Expected result:** The order status is **Paid**.

### TC-03: Marking as shipped moves a Paid order to Shipped

- **Covers:** AC-2
- **Preconditions:** An order with status **Paid**.
- **Steps:**
  1. Mark the order as shipped.
  2. Open the order.
- **Expected result:** The order status is **Shipped**.

### TC-04: Confirming delivery moves a Shipped order to Delivered

- **Covers:** AC-3
- **Preconditions:** An order with status **Shipped**.
- **Steps:**
  1. Confirm delivery of the order.
  2. Open the order.
- **Expected result:** The order status is **Delivered**.

### TC-05: Cancelling a Placed order moves it to Cancelled

- **Covers:** AC-4
- **Preconditions:** An order with status **Placed**.
- **Steps:**
  1. Cancel the order.
  2. Open the order.
- **Expected result:** The order status is **Cancelled**.

### TC-06: Cancelling a Paid order moves it to Cancelled

- **Covers:** AC-4
- **Preconditions:** An order with status **Paid**.
- **Steps:**
  1. Cancel the order.
  2. Open the order.
- **Expected result:** The order status is **Cancelled**.

### TC-07: Recording a payment on a Paid order is refused

- **Covers:** AC-1 (negative), A1
- **Preconditions:** An order with status **Paid**.
- **Steps:**
  1. Record a payment on the order.
  2. Open the order.
- **Expected result:** The action is refused with an error. The order status is still **Paid**.

### TC-08: Recording a payment on a Shipped, Delivered or Cancelled order is refused

- **Covers:** AC-1 (negative), A1
- **Preconditions:** 3 orders, one each with status **Shipped**, **Delivered** and **Cancelled**.
- **Steps:**
  1. Record a payment on each order.
  2. Open each order.
- **Expected result:** Each action is refused with an error. Each order keeps its status.

### TC-09: Marking a Placed order as shipped is refused

- **Covers:** AC-2 (negative), A1
- **Preconditions:** An order with status **Placed** and no payment recorded.
- **Steps:**
  1. Mark the order as shipped.
  2. Open the order.
- **Expected result:** The action is refused with an error. The order status is still **Placed**.

### TC-10: Marking a Shipped, Delivered or Cancelled order as shipped is refused

- **Covers:** AC-2 (negative), A1
- **Preconditions:** 3 orders, one each with status **Shipped**, **Delivered** and **Cancelled**.
- **Steps:**
  1. Mark each order as shipped.
  2. Open each order.
- **Expected result:** Each action is refused with an error. Each order keeps its status.

### TC-11: Confirming delivery of a Placed or Paid order is refused

- **Covers:** AC-3 (negative), A1
- **Preconditions:** 2 orders, one with status **Placed** and one with status **Paid**.
- **Steps:**
  1. Confirm delivery of each order.
  2. Open each order.
- **Expected result:** Each action is refused with an error. Each order keeps its status.

### TC-12: Confirming delivery of a Delivered or Cancelled order is refused

- **Covers:** AC-3 (negative), A1, A2
- **Preconditions:** 2 orders, one with status **Delivered** and one with status **Cancelled**.
- **Steps:**
  1. Confirm delivery of each order.
  2. Open each order.
- **Expected result:** Each action is refused with an error. Each order keeps its status.

### TC-13: Cancelling a Shipped order is refused with the exact message

- **Covers:** AC-5
- **Preconditions:** An order with status **Shipped**.
- **Steps:**
  1. Cancel the order.
  2. Read the message shown.
  3. Open the order.
- **Expected result:** The message reads exactly "Shipped orders cannot be cancelled." The order status is still **Shipped**.

### TC-14: Cancelling a Delivered order is refused

- **Covers:** A1, A2
- **Preconditions:** An order with status **Delivered**.
- **Steps:**
  1. Cancel the order.
  2. Open the order.
- **Expected result:** The action is refused with an error. The order status is still **Delivered**.

### TC-15: Cancelling a Cancelled order makes no change

- **Covers:** A1, A2
- **Preconditions:** An order with status **Cancelled**.
- **Steps:**
  1. Cancel the order.
  2. Open the order.
- **Expected result:** The action is refused with an error. The order status is still **Cancelled**.

### TC-16: An order passes through every status in order

- **Covers:** AC-1, AC-2, AC-3 end to end
- **Preconditions:** None.
- **Steps:**
  1. Create a new order. Check the status is **Placed**.
  2. Record a payment. Check the status is **Paid**.
  3. Mark the order as shipped. Check the status is **Shipped**.
  4. Confirm delivery. Check the status is **Delivered**.
- **Expected result:** Each check passes. The order never shows any status other than the 5 named in A3.

### TC-17: Staff and the customer see the same status after each change

- **Covers:** Story goal, A5
- **Preconditions:** An order with status **Placed**, and a customer account that placed it.
- **Steps:**
  1. As a store operator, record a payment on the order.
  2. As the customer, open the order.
  3. As a store operator, mark the order as shipped.
  4. As the customer, open the order again.
- **Expected result:** The customer sees **Paid** after step 2 and **Shipped** after step 4, with no refresh needed beyond opening the order.

## Not covered

- Who may perform each action. The story names only a store operator, so role checks are out of scope.
- Partial payments, refunds, or reopening a cancelled order. The story does not mention them.
- Status history or timestamps. The story requires only the current status.
