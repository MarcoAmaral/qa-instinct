# Test Cases - ORD-4: Order Status Changes

## Test Case 1: Order Created with Placed Status
**ID:** ORD-4-TC-001  
**Title:** New order initializes with Placed status  
**Description:** Verify that a newly created order has status set to Placed  
**Precondition:** None  
**Steps:**
1. Create a new order
2. Retrieve the order details
3. Verify the status field

**Expected Result:** Order status is "Placed"

---

## Test Case 2: AC-1 - Record Payment on Placed Order
**ID:** ORD-4-TC-002  
**Title:** Recording payment transitions Placed order to Paid  
**Description:** Verify that processing a payment on a Placed order changes its status to Paid  
**Precondition:** Order exists with status "Placed"  
**Steps:**
1. Retrieve the Placed order
2. Record a payment for the order
3. Retrieve the order details
4. Verify the status field

**Expected Result:** Order status is "Paid"

---

## Test Case 3: AC-1 - Cannot Record Payment on Non-Placed Order
**ID:** ORD-4-TC-003  
**Title:** Recording payment on Paid order is rejected  
**Precondition:** Order exists with status "Paid"  
**Steps:**
1. Attempt to record a payment on the Paid order
2. Observe the system response

**Expected Result:** Request is rejected with appropriate error message; status remains "Paid"

---

## Test Case 4: AC-2 - Mark Paid Order as Shipped
**ID:** ORD-4-TC-004  
**Title:** Marking a Paid order as shipped transitions to Shipped status  
**Description:** Verify that marking a Paid order as shipped changes its status to Shipped  
**Precondition:** Order exists with status "Paid"  
**Steps:**
1. Retrieve the Paid order
2. Mark the order as shipped
3. Retrieve the order details
4. Verify the status field

**Expected Result:** Order status is "Shipped"

---

## Test Case 5: AC-2 - Cannot Ship Non-Paid Order
**ID:** ORD-4-TC-005  
**Title:** Marking a Placed order as shipped is rejected  
**Precondition:** Order exists with status "Placed"  
**Steps:**
1. Attempt to mark the Placed order as shipped
2. Observe the system response

**Expected Result:** Request is rejected with appropriate error message; status remains "Placed"

---

## Test Case 6: AC-3 - Confirm Delivery of Shipped Order
**ID:** ORD-4-TC-006  
**Title:** Confirming delivery transitions Shipped order to Delivered  
**Description:** Verify that confirming delivery on a Shipped order changes its status to Delivered  
**Precondition:** Order exists with status "Shipped"  
**Steps:**
1. Retrieve the Shipped order
2. Confirm delivery for the order
3. Retrieve the order details
4. Verify the status field

**Expected Result:** Order status is "Delivered"

---

## Test Case 7: AC-3 - Cannot Deliver Non-Shipped Order
**ID:** ORD-4-TC-007  
**Title:** Confirming delivery on Paid order is rejected  
**Precondition:** Order exists with status "Paid"  
**Steps:**
1. Attempt to confirm delivery on the Paid order
2. Observe the system response

**Expected Result:** Request is rejected with appropriate error message; status remains "Paid"

---

## Test Case 8: AC-4 - Cancel Placed Order
**ID:** ORD-4-TC-008  
**Title:** Cancelling a Placed order transitions to Cancelled status  
**Description:** Verify that cancelling a Placed order changes its status to Cancelled  
**Precondition:** Order exists with status "Placed"  
**Steps:**
1. Retrieve the Placed order
2. Cancel the order
3. Retrieve the order details
4. Verify the status field

**Expected Result:** Order status is "Cancelled"

---

## Test Case 9: AC-4 - Cancel Paid Order
**ID:** ORD-4-TC-009  
**Title:** Cancelling a Paid order transitions to Cancelled status  
**Description:** Verify that cancelling a Paid order changes its status to Cancelled  
**Precondition:** Order exists with status "Paid"  
**Steps:**
1. Retrieve the Paid order
2. Cancel the order
3. Retrieve the order details
4. Verify the status field

**Expected Result:** Order status is "Cancelled"

---

## Test Case 10: AC-5 - Cannot Cancel Shipped Order
**ID:** ORD-4-TC-010  
**Title:** Attempting to cancel a Shipped order is refused  
**Description:** Verify that cancelling a Shipped order is rejected with specific error message  
**Precondition:** Order exists with status "Shipped"  
**Steps:**
1. Attempt to cancel the Shipped order
2. Observe the system response and error message

**Expected Result:** Request is rejected; error message is "Shipped orders cannot be cancelled."; order status remains "Shipped"

---

## Test Case 11: AC-5 - Cannot Cancel Delivered Order
**ID:** ORD-4-TC-011  
**Title:** Attempting to cancel a Delivered order is refused  
**Description:** Verify that cancelling a Delivered order is rejected (assumption: Delivered orders also cannot be cancelled)  
**Precondition:** Order exists with status "Delivered"  
**Steps:**
1. Attempt to cancel the Delivered order
2. Observe the system response

**Expected Result:** Request is rejected with appropriate error message; status remains "Delivered"

---

## Test Case 12: AC-5 - Cannot Cancel Cancelled Order
**ID:** ORD-4-TC-012  
**Title:** Attempting to cancel an already-Cancelled order is rejected  
**Precondition:** Order exists with status "Cancelled"  
**Steps:**
1. Attempt to cancel the Cancelled order
2. Observe the system response

**Expected Result:** Request is rejected with appropriate error message; status remains "Cancelled"

---

## Test Case 13: Complete Happy Path - Order Lifecycle
**ID:** ORD-4-TC-013  
**Title:** Order transitions through all statuses in normal flow  
**Description:** Verify an order can complete the entire lifecycle: Placed → Paid → Shipped → Delivered  
**Precondition:** None  
**Steps:**
1. Create a new order and verify status is "Placed"
2. Record payment and verify status is "Paid"
3. Mark as shipped and verify status is "Shipped"
4. Confirm delivery and verify status is "Delivered"
5. Verify no further status changes are possible

**Expected Result:** Order successfully transitions through all four statuses in sequence

---

## Test Case 14: Cancelled Order is Terminal
**ID:** ORD-4-TC-014  
**Title:** Cancelled order cannot transition to other statuses  
**Description:** Verify that a Cancelled order cannot be moved to Paid, Shipped, or Delivered  
**Precondition:** Order exists with status "Cancelled"  
**Steps:**
1. Attempt to record payment on the Cancelled order
2. Attempt to mark as shipped on the Cancelled order
3. Attempt to confirm delivery on the Cancelled order

**Expected Result:** All attempts are rejected; status remains "Cancelled"

---

## Test Case 15: Delivered Order is Terminal
**ID:** ORD-4-TC-015  
**Title:** Delivered order cannot transition to other statuses  
**Description:** Verify that a Delivered order cannot be moved to other statuses  
**Precondition:** Order exists with status "Delivered"  
**Steps:**
1. Attempt to record payment on the Delivered order
2. Attempt to mark as shipped on the Delivered order
3. Attempt to cancel the Delivered order

**Expected Result:** All attempts are rejected; status remains "Delivered"

---

## Test Case 16: Cancel Placed Order Before Payment
**ID:** ORD-4-TC-016  
**Title:** Order can be cancelled at Placed state without payment  
**Description:** Verify cancellation workflow for orders that never received payment  
**Precondition:** Order exists with status "Placed"  
**Steps:**
1. Wait to verify no payment has been recorded
2. Cancel the order
3. Verify status is "Cancelled"

**Expected Result:** Order successfully transitions to "Cancelled" status

---

## Assumptions
- Orders are identified by a unique order ID
- Status transitions are atomic operations
- The system maintains an audit trail of status changes (not explicitly tested here)
- "Recording payment" is idempotent or prevents duplicate payments
- No status change can occur without explicit system action (no automatic timeouts)
- Invalid state transitions return clear, descriptive error messages
- The system prevents race conditions during concurrent status update attempts
