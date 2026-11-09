# Test Cases for Story ORD-4: Order Status Changes

## Assumptions

- Orders are created via an order creation function or API that automatically sets status to "Placed"
- Status changes are recorded with timestamps for audit purposes
- "Recording a payment" involves a method like `recordPayment()` or an API endpoint
- "Marking as shipped" involves a method like `markShipped()` or an API endpoint
- "Confirming delivery" involves a method like `confirmDelivery()` or an API endpoint
- "Cancelling" involves a method like `cancel()` or an API endpoint
- Status transitions reject invalid operations with error messages
- Tests cover both happy path and error cases

---

## Test Case 1: Order Initializes with Placed Status
**Scenario:** A new order is created

**Given:** No prior order exists  
**When:** A new order is created  
**Then:** The order status is "Placed"

---

## Test Case 2: Payment Recording on Placed Order Changes Status to Paid
**Scenario:** Record payment on a Placed order

**Given:** An order with status "Placed"  
**When:** `recordPayment()` is called on the order  
**Then:** The order status changes to "Paid"  
**And:** The payment timestamp is recorded

---

## Test Case 3: Marking Paid Order as Shipped Changes Status to Shipped
**Scenario:** Mark a Paid order as shipped

**Given:** An order with status "Paid"  
**When:** `markShipped()` is called on the order  
**Then:** The order status changes to "Shipped"  
**And:** The shipment timestamp is recorded

---

## Test Case 4: Confirming Delivery of Shipped Order Changes Status to Delivered
**Scenario:** Confirm delivery of a Shipped order

**Given:** An order with status "Shipped"  
**When:** `confirmDelivery()` is called on the order  
**Then:** The order status changes to "Delivered"  
**And:** The delivery timestamp is recorded

---

## Test Case 5: Placed Order Can Be Cancelled
**Scenario:** Cancel a Placed order

**Given:** An order with status "Placed"  
**When:** `cancel()` is called on the order  
**Then:** The order status changes to "Cancelled"  
**And:** The cancellation timestamp is recorded

---

## Test Case 6: Paid Order Can Be Cancelled
**Scenario:** Cancel a Paid order

**Given:** An order with status "Paid"  
**When:** `cancel()` is called on the order  
**Then:** The order status changes to "Cancelled"  
**And:** The cancellation timestamp is recorded

---

## Test Case 7: Shipped Order Cannot Be Cancelled
**Scenario:** Attempt to cancel a Shipped order

**Given:** An order with status "Shipped"  
**When:** `cancel()` is called on the order  
**Then:** The status remains "Shipped"  
**And:** An error is returned with the message "Shipped orders cannot be cancelled."  
**And:** No cancellation timestamp is recorded

---

## Test Case 8: Invalid Status Transition Rejected (Payment on Already Paid Order)
**Scenario:** Attempt to record payment on a Paid order

**Given:** An order with status "Paid"  
**When:** `recordPayment()` is called on the order  
**Then:** The status remains "Paid"  
**And:** An error is returned indicating the transition is invalid

---

## Test Case 9: Invalid Status Transition Rejected (Shipment on Placed Order)
**Scenario:** Attempt to mark as shipped without payment

**Given:** An order with status "Placed"  
**When:** `markShipped()` is called on the order  
**Then:** The status remains "Placed"  
**And:** An error is returned indicating the transition is invalid

---

## Test Case 10: Delivered Order Cannot Be Cancelled
**Scenario:** Attempt to cancel a Delivered order

**Given:** An order with status "Delivered"  
**When:** `cancel()` is called on the order  
**Then:** The status remains "Delivered"  
**And:** An error is returned indicating cancellation is not permitted

---

## Test Case 11: Cancelled Order Status Cannot Be Changed
**Scenario:** Attempt any status change on a Cancelled order

**Given:** An order with status "Cancelled"  
**When:** Any state-changing method (`recordPayment()`, `markShipped()`, `confirmDelivery()`) is called  
**Then:** The status remains "Cancelled"  
**And:** An error is returned indicating the order is cancelled

---

## Test Case 12: Full Happy Path Order Progression
**Scenario:** Order moves through all valid states

**Given:** A new order  
**When:** `recordPayment()` is called, then `markShipped()`, then `confirmDelivery()`  
**Then:** Status progresses: Placed → Paid → Shipped → Delivered  
**And:** All timestamps are recorded in sequence
