# Test cases: ORD-4 Order status changes

## Assumptions

- Order statuses are exactly **Placed**, **Paid**, **Shipped**, **Delivered** and **Cancelled**. No other status exists.
- The actions are named **Record payment**, **Mark as shipped**, **Confirm delivery** and **Cancel order**. An editor should correct these labels to match the product.
- A refused action leaves the order status unchanged and shows the refusal message to the operator.
- The story does not say what happens when an action is used on an order in the wrong status, apart from AC-5. Test cases TC-09 to TC-13 assume such actions are refused and the status does not change. If the product behaves differently, update the expected results.
- Each test case starts with a freshly created order so that cases are independent.

## Test cases

### TC-01: A new order has the status Placed

- **Covers:** Story preamble
- **Preconditions:** None.
- **Steps:**
  1. Create a new order.
  2. Open the order.
- **Expected result:** The order status is **Placed**.

### TC-02: Recording a payment moves a Placed order to Paid

- **Covers:** AC-1
- **Preconditions:** An order with status **Placed**.
- **Steps:**
  1. Open the order.
  2. Select **Record payment**.
- **Expected result:** The order status is **Paid**.

### TC-03: Marking a Paid order as shipped moves it to Shipped

- **Covers:** AC-2
- **Preconditions:** An order with status **Paid**.
- **Steps:**
  1. Open the order.
  2. Select **Mark as shipped**.
- **Expected result:** The order status is **Shipped**.

### TC-04: Confirming delivery moves a Shipped order to Delivered

- **Covers:** AC-3
- **Preconditions:** An order with status **Shipped**.
- **Steps:**
  1. Open the order.
  2. Select **Confirm delivery**.
- **Expected result:** The order status is **Delivered**.

### TC-05: Cancelling a Placed order moves it to Cancelled

- **Covers:** AC-4
- **Preconditions:** An order with status **Placed**.
- **Steps:**
  1. Open the order.
  2. Select **Cancel order**.
- **Expected result:** The order status is **Cancelled**.

### TC-06: Cancelling a Paid order moves it to Cancelled

- **Covers:** AC-4
- **Preconditions:** An order with status **Paid**.
- **Steps:**
  1. Open the order.
  2. Select **Cancel order**.
- **Expected result:** The order status is **Cancelled**.

### TC-07: Cancelling a Shipped order is refused

- **Covers:** AC-5
- **Preconditions:** An order with status **Shipped**.
- **Steps:**
  1. Open the order.
  2. Select **Cancel order**.
- **Expected result:** The message "Shipped orders cannot be cancelled." is shown. The order status stays **Shipped**.

### TC-08: Full path from Placed to Delivered

- **Covers:** AC-1, AC-2, AC-3 together
- **Preconditions:** None.
- **Steps:**
  1. Create a new order. The status is **Placed**.
  2. Select **Record payment**. The status is **Paid**.
  3. Select **Mark as shipped**. The status is **Shipped**.
  4. Select **Confirm delivery**.
- **Expected result:** The order status is **Delivered**. Each earlier step showed the status named in that step.

### TC-09: Marking a Placed order as shipped is refused

- **Covers:** AC-2 boundary (assumed behaviour)
- **Preconditions:** An order with status **Placed**.
- **Steps:**
  1. Open the order.
  2. Select **Mark as shipped**.
- **Expected result:** The action is refused. The order status stays **Placed**.

### TC-10: Confirming delivery of a Paid order is refused

- **Covers:** AC-3 boundary (assumed behaviour)
- **Preconditions:** An order with status **Paid**.
- **Steps:**
  1. Open the order.
  2. Select **Confirm delivery**.
- **Expected result:** The action is refused. The order status stays **Paid**.

### TC-11: Recording a payment on a Paid order is refused

- **Covers:** AC-1 boundary (assumed behaviour)
- **Preconditions:** An order with status **Paid**.
- **Steps:**
  1. Open the order.
  2. Select **Record payment**.
- **Expected result:** The action is refused. The order status stays **Paid**.

### TC-12: Cancelling a Delivered order is refused

- **Covers:** AC-4 boundary (assumed behaviour)
- **Preconditions:** An order with status **Delivered**.
- **Steps:**
  1. Open the order.
  2. Select **Cancel order**.
- **Expected result:** The action is refused. The order status stays **Delivered**.

### TC-13: No action changes a Cancelled order

- **Covers:** AC-4 boundary (assumed behaviour)
- **Preconditions:** An order with status **Cancelled**.
- **Steps:**
  1. Open the order.
  2. Select **Record payment**.
  3. Select **Mark as shipped**.
  4. Select **Confirm delivery**.
  5. Select **Cancel order**.
- **Expected result:** Each action is refused. The order status stays **Cancelled** after every step.

### TC-14: Status change is visible to another user

- **Covers:** Story goal ("customers and staff always see where an order is")
- **Preconditions:** An order with status **Placed**. A second user who can view the order.
- **Steps:**
  1. As the operator, select **Record payment** on the order.
  2. As the second user, open the order.
- **Expected result:** The second user sees the status **Paid**.

## Traceability

| Requirement | Test cases |
| --- | --- |
| Order is created as Placed | TC-01, TC-08 |
| AC-1 | TC-02, TC-08, TC-11 |
| AC-2 | TC-03, TC-08, TC-09 |
| AC-3 | TC-04, TC-08, TC-10 |
| AC-4 | TC-05, TC-06, TC-12, TC-13 |
| AC-5 | TC-07 |
| Visibility to staff and customers | TC-14 |

## Open points for the story owner

- Confirm the behaviour and message for actions used on an order in the wrong status (TC-09 to TC-13). AC-5 names a message for one case only.
- Confirm whether a Delivered order can be cancelled or refunded. The story does not say.
- Confirm the exact action labels used in the product so the steps above match the interface.
