# Test Cases for ORD-4: Order Status Changes

**Assumptions Made:**
- Order status transitions can be triggered via an API or system function
- Invalid status transitions should be rejected (e.g., attempting to move Delivered → Paid)
- Timestamps are recorded when statuses change
- Only one status change can occur at a time (no concurrent transitions)
- A cancelled order cannot be reopened or re-transitioned
- System validates state transitions before applying them

---

## Test Case 1: Order Created with Initial Status
**Given:** A new order is created in the system  
**When:** The order is retrieved  
**Then:** The order status should be "Placed"

---

## Test Case 2: AC-1 – Payment Recording on Placed Order
**Given:** An order exists with status "Placed"  
**When:** A payment is recorded on the order  
**Then:** The order status should change to "Paid"  
**And:** The timestamp of the status change should be recorded

---

## Test Case 3: AC-1 – Payment Recording on Non-Placed Order (Negative)
**Given:** An order exists with status "Shipped"  
**When:** A payment is recorded on the order  
**Then:** The system should reject the action  
**And:** The order status should remain "Shipped"

---

## Test Case 4: AC-2 – Marking Paid Order as Shipped
**Given:** An order exists with status "Paid"  
**When:** The order is marked as shipped  
**Then:** The order status should change to "Shipped"  
**And:** The timestamp of the status change should be recorded

---

## Test Case 5: AC-2 – Marking Non-Paid Order as Shipped (Negative)
**Given:** An order exists with status "Placed"  
**When:** The order is marked as shipped  
**Then:** The system should reject the action  
**And:** The order status should remain "Placed"

---

## Test Case 6: AC-3 – Confirming Delivery of Shipped Order
**Given:** An order exists with status "Shipped"  
**When:** Delivery is confirmed for the order  
**Then:** The order status should change to "Delivered"  
**And:** The timestamp of the status change should be recorded

---

## Test Case 7: AC-3 – Confirming Delivery of Non-Shipped Order (Negative)
**Given:** An order exists with status "Paid"  
**When:** Delivery is confirmed for the order  
**Then:** The system should reject the action  
**And:** The order status should remain "Paid"

---

## Test Case 8: AC-4 – Cancelling a Placed Order
**Given:** An order exists with status "Placed"  
**When:** The order is cancelled  
**Then:** The order status should change to "Cancelled"  
**And:** The timestamp of the status change should be recorded

---

## Test Case 9: AC-4 – Cancelling a Paid Order
**Given:** An order exists with status "Paid"  
**When:** The order is cancelled  
**Then:** The order status should change to "Cancelled"  
**And:** The timestamp of the status change should be recorded

---

## Test Case 10: AC-5 – Cancelling a Shipped Order (Negative)
**Given:** An order exists with status "Shipped"  
**When:** An attempt is made to cancel the order  
**Then:** The system should refuse the action with error message "Shipped orders cannot be cancelled."  
**And:** The order status should remain "Shipped"

---

## Test Case 11: AC-5 – Cancelling a Delivered Order (Negative)
**Given:** An order exists with status "Delivered"  
**When:** An attempt is made to cancel the order  
**Then:** The system should refuse the action  
**And:** The order status should remain "Delivered"

---

## Test Case 12: State Transition – Complete Happy Path
**Given:** A new order is created  
**When:** Payment is recorded, then marked as shipped, then delivery is confirmed  
**Then:** The order should transition through states: Placed → Paid → Shipped → Delivered  
**And:** Each status change should be timestamped and auditable

---

## Test Case 13: State Transition – Cancelled Order Cannot Progress
**Given:** An order has been cancelled (from Placed or Paid status)  
**When:** An attempt is made to record a payment or mark it as shipped  
**Then:** The system should reject the action  
**And:** The order status should remain "Cancelled"

---

## Test Case 14: Concurrent Status Change Attempt (Edge Case)
**Given:** An order exists with status "Paid"  
**When:** Two simultaneous requests attempt to: (1) mark as shipped and (2) cancel the order  
**Then:** Only one transition should succeed  
**And:** The order status should be either "Shipped" or "Cancelled" (not in an inconsistent state)  
**And:** The second request should receive a conflict or failure response

---

## Test Case 15: Idempotency – Recording Payment Twice (Edge Case)
**Given:** An order with status "Paid" (payment already recorded)  
**When:** Another payment recording action is attempted on the same order  
**Then:** The system should either reject the action or treat it as idempotent  
**And:** The order status should remain "Paid"
