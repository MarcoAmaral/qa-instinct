# Test cases: ORD-4 Order status changes

## Assumptions

- The operator acts on an order through 4 controls: **Record payment**, **Mark as shipped**, **Confirm delivery** and **Cancel order**. Label names are assumed and should be checked against the product.
- Any status change that the story does not allow is refused. The order keeps its current status and the operator sees an error message. Only AC-5 specifies the message text, so other refusal messages are not asserted.
- An order's status is shown in the operator order view and in the customer's order page. Both show the same value.
- Each test starts with a fresh order unless the preconditions say otherwise. "Create an order" means placing a new order by the normal customer checkout path.

## Covered acceptance criteria

| Test | AC-1 | AC-2 | AC-3 | AC-4 | AC-5 |
| --- | --- | --- | --- | --- | --- |
| TC-01 | | | | | |
| TC-02 | ✓ | | | | |
| TC-03 | | ✓ | | | |
| TC-04 | | | ✓ | | |
| TC-05 | | | | ✓ | |
| TC-06 | | | | ✓ | |
| TC-07 | | | | | ✓ |
| TC-08 to TC-14 | negative paths, see each case | | | | |

TC-01 covers the opening statement that a new order starts as Placed.

---

## TC-01: A new order starts as Placed

**Preconditions:** None: any customer account can place an order.

**Steps:**

1. Create an order.
2. Open the order in the operator order view.
3. Open the same order on the customer's order page.

**Expected result:** Both views show the status **Placed**.

---

## TC-02: Recording a payment moves a Placed order to Paid (AC-1)

**Preconditions:** An order with status **Placed**.

**Steps:**

1. Open the order in the operator order view.
2. Select **Record payment**.
3. Check the status in the operator view and on the customer's order page.

**Expected result:** The status is **Paid** in both views.

---

## TC-03: Marking as shipped moves a Paid order to Shipped (AC-2)

**Preconditions:** An order with status **Paid**.

**Steps:**

1. Open the order in the operator order view.
2. Select **Mark as shipped**.
3. Check the status in the operator view and on the customer's order page.

**Expected result:** The status is **Shipped** in both views.

---

## TC-04: Confirming delivery moves a Shipped order to Delivered (AC-3)

**Preconditions:** An order with status **Shipped**.

**Steps:**

1. Open the order in the operator order view.
2. Select **Confirm delivery**.
3. Check the status in the operator view and on the customer's order page.

**Expected result:** The status is **Delivered** in both views.

---

## TC-05: Cancelling a Placed order moves it to Cancelled (AC-4)

**Preconditions:** An order with status **Placed**.

**Steps:**

1. Open the order in the operator order view.
2. Select **Cancel order**.
3. Check the status in the operator view and on the customer's order page.

**Expected result:** The status is **Cancelled** in both views. No error message is shown.

---

## TC-06: Cancelling a Paid order moves it to Cancelled (AC-4)

**Preconditions:** An order with status **Paid**.

**Steps:**

1. Open the order in the operator order view.
2. Select **Cancel order**.
3. Check the status in the operator view and on the customer's order page.

**Expected result:** The status is **Cancelled** in both views. No error message is shown.

---

## TC-07: Cancelling a Shipped order is refused (AC-5)

**Preconditions:** An order with status **Shipped**.

**Steps:**

1. Open the order in the operator order view.
2. Select **Cancel order**.
3. Read the message shown.
4. Check the status in the operator view and on the customer's order page.

**Expected result:** The message reads exactly "Shipped orders cannot be cancelled." The status stays **Shipped** in both views.

---

## TC-08: Cancelling a Delivered order is refused

**Preconditions:** An order with status **Delivered**.

**Steps:**

1. Open the order in the operator order view.
2. Select **Cancel order**.
3. Check the status.

**Expected result:** The cancellation is refused with an error message. The status stays **Delivered**.

Note: the story lists only Placed and Paid as cancellable. The exact message for a Delivered order is not specified and should be confirmed with the product owner.

---

## TC-09: Recording a payment on an order that is not Placed is refused

**Preconditions:** 4 orders, one in each status: **Paid**, **Shipped**, **Delivered**, **Cancelled**.

**Steps:**

1. Open the Paid order and select **Record payment**.
2. Repeat step 1 for the Shipped, Delivered and Cancelled orders.
3. Check the status of each order.

**Expected result:** Each attempt is refused with an error message. Each order keeps its starting status.

---

## TC-10: Marking an unpaid order as shipped is refused

**Preconditions:** An order with status **Placed**.

**Steps:**

1. Open the order in the operator order view.
2. Select **Mark as shipped**.
3. Check the status.

**Expected result:** The action is refused with an error message. The status stays **Placed**.

---

## TC-11: Marking as shipped is refused for Shipped, Delivered and Cancelled orders

**Preconditions:** 3 orders, one in each status: **Shipped**, **Delivered**, **Cancelled**.

**Steps:**

1. Open each order and select **Mark as shipped**.
2. Check the status of each order.

**Expected result:** Each attempt is refused with an error message. Each order keeps its starting status.

---

## TC-12: Confirming delivery is refused for orders that are not Shipped

**Preconditions:** 4 orders, one in each status: **Placed**, **Paid**, **Delivered**, **Cancelled**.

**Steps:**

1. Open each order and select **Confirm delivery**.
2. Check the status of each order.

**Expected result:** Each attempt is refused with an error message. Each order keeps its starting status.

---

## TC-13: A Cancelled order cannot change status again

**Preconditions:** An order with status **Cancelled**.

**Steps:**

1. Open the order in the operator order view.
2. Select **Cancel order**.
3. Select **Record payment**.
4. Select **Mark as shipped**.
5. Select **Confirm delivery**.
6. Check the status.

**Expected result:** Each action is refused with an error message. The status stays **Cancelled**.

---

## TC-14: Full order life cycle in one run

**Preconditions:** None: any customer account can place an order.

**Steps:**

1. Create an order. Confirm the status is **Placed**.
2. Select **Record payment**. Confirm the status is **Paid**.
3. Select **Mark as shipped**. Confirm the status is **Shipped**.
4. Select **Confirm delivery**. Confirm the status is **Delivered**.
5. Open the customer's order page.

**Expected result:** The order passed through Placed, Paid, Shipped and Delivered in that order with no skipped status. The customer's order page shows **Delivered**.

---

## Open questions for the product owner

- Which error message is shown when a transition other than the AC-5 case is refused.
- Whether a Cancelled order that was Paid should trigger a refund. The story does not say, so these tests do not check it.
- Whether a status change made by one operator appears for another operator without reloading the page.
