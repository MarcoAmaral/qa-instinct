# Test Cases: Order Status Changes (ORD-4)

## Test Case 1: Order Creation
**Scenario:** New order is created
**Given:** A new order is initiated
**When:** The order is created
**Then:** The order status should be "Placed"

---

## Test Case 2: Payment Recording on Placed Order (AC-1)
**Scenario:** Record payment on a Placed order
**Given:** An order exists with status "Placed"
**When:** A payment is recorded on the order
**Then:** The order status should change to "Paid"

---

## Test Case 3: Payment Recording on Non-Placed Order (AC-1)
**Scenario:** Attempt to record payment on an order that is not Placed
**Given:** An order exists with status "Paid"
**When:** A payment is recorded on the order
**Then:** The payment should not be recorded and an appropriate error should be returned

---

## Test Case 4: Mark as Shipped on Paid Order (AC-2)
**Scenario:** Mark a Paid order as shipped
**Given:** An order exists with status "Paid"
**When:** The order is marked as shipped
**Then:** The order status should change to "Shipped"

---

## Test Case 5: Mark as Shipped on Non-Paid Order (AC-2)
**Scenario:** Attempt to mark as shipped an order that is not Paid
**Given:** An order exists with status "Placed"
**When:** The order is marked as shipped
**Then:** The order should not be marked as shipped and an appropriate error should be returned

---

## Test Case 6: Confirm Delivery on Shipped Order (AC-3)
**Scenario:** Confirm delivery of a Shipped order
**Given:** An order exists with status "Shipped"
**When:** Delivery is confirmed on the order
**Then:** The order status should change to "Delivered"

---

## Test Case 7: Confirm Delivery on Non-Shipped Order (AC-3)
**Scenario:** Attempt to confirm delivery on an order that is not Shipped
**Given:** An order exists with status "Paid"
**When:** Delivery is confirmed on the order
**Then:** The order should not be updated and an appropriate error should be returned

---

## Test Case 8: Cancel Placed Order (AC-4)
**Scenario:** Cancel an order with status Placed
**Given:** An order exists with status "Placed"
**When:** The order is cancelled
**Then:** The order status should change to "Cancelled"

---

## Test Case 9: Cancel Paid Order (AC-4)
**Scenario:** Cancel an order with status Paid
**Given:** An order exists with status "Paid"
**When:** The order is cancelled
**Then:** The order status should change to "Cancelled"

---

## Test Case 10: Cancel Shipped Order (AC-5)
**Scenario:** Attempt to cancel a Shipped order
**Given:** An order exists with status "Shipped"
**When:** The order is cancelled
**Then:** The cancellation should be refused and an error message "Shipped orders cannot be cancelled." should be returned

---

## Test Case 11: Cancel Delivered Order (AC-5)
**Scenario:** Attempt to cancel a Delivered order
**Given:** An order exists with status "Delivered"
**When:** The order is cancelled
**Then:** The cancellation should be refused and an appropriate error should be returned

---

## Test Case 12: Cancel Cancelled Order
**Scenario:** Attempt to cancel an order that is already cancelled
**Given:** An order exists with status "Cancelled"
**When:** The order is cancelled
**Then:** The cancellation should be refused and an appropriate error should be returned

---

## Test Case 13: Transition from Cancelled Order
**Scenario:** Attempt to perform operations on a Cancelled order
**Given:** An order exists with status "Cancelled"
**When:** A payment is recorded on the order
**Then:** The operation should not be allowed and an appropriate error should be returned
