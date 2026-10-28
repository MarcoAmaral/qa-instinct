# Test Cases: ORD-4 Order Status Changes

## Test Case 1.1: Create Order with Initial Status
**ID:** ORD-4-TC-001  
**Title:** New order is created with Placed status  
**Preconditions:** System is available  
**Steps:**
1. Create a new order
2. Retrieve order details
**Expected Result:** Order status is "Placed"

---

## Test Case 2.1: Payment Recording on Placed Order
**ID:** ORD-4-TC-002  
**Title:** Recording payment on Placed order transitions to Paid  
**Preconditions:** Order exists with status "Placed"  
**Steps:**
1. Record payment on the order
2. Retrieve order details
**Expected Result:** Order status is "Paid"

---

## Test Case 2.2: Payment Recording on Non-Placed Order
**ID:** ORD-4-TC-003  
**Title:** Recording payment on Paid order fails gracefully  
**Preconditions:** Order exists with status "Paid"  
**Steps:**
1. Attempt to record payment on the order
2. Retrieve order details
**Expected Result:** Operation fails or is rejected; status remains "Paid"

---

## Test Case 3.1: Shipping Paid Order
**ID:** ORD-4-TC-004  
**Title:** Marking Paid order as shipped transitions to Shipped  
**Preconditions:** Order exists with status "Paid"  
**Steps:**
1. Mark order as shipped
2. Retrieve order details
**Expected Result:** Order status is "Shipped"

---

## Test Case 3.2: Shipping Non-Paid Order
**ID:** ORD-4-TC-005  
**Title:** Marking Placed order as shipped fails  
**Preconditions:** Order exists with status "Placed"  
**Steps:**
1. Attempt to mark order as shipped
2. Retrieve order details
**Expected Result:** Operation fails; status remains "Placed"

---

## Test Case 4.1: Confirming Delivery of Shipped Order
**ID:** ORD-4-TC-006  
**Title:** Confirming delivery of Shipped order transitions to Delivered  
**Preconditions:** Order exists with status "Shipped"  
**Steps:**
1. Confirm delivery of the order
2. Retrieve order details
**Expected Result:** Order status is "Delivered"

---

## Test Case 4.2: Confirming Delivery of Non-Shipped Order
**ID:** ORD-4-TC-007  
**Title:** Confirming delivery of Paid order fails  
**Preconditions:** Order exists with status "Paid"  
**Steps:**
1. Attempt to confirm delivery
2. Retrieve order details
**Expected Result:** Operation fails; status remains "Paid"

---

## Test Case 5.1: Cancelling Placed Order
**ID:** ORD-4-TC-008  
**Title:** Cancelling Placed order transitions to Cancelled  
**Preconditions:** Order exists with status "Placed"  
**Steps:**
1. Cancel the order
2. Retrieve order details
**Expected Result:** Order status is "Cancelled"

---

## Test Case 5.2: Cancelling Paid Order
**ID:** ORD-4-TC-009  
**Title:** Cancelling Paid order transitions to Cancelled  
**Preconditions:** Order exists with status "Paid"  
**Steps:**
1. Cancel the order
2. Retrieve order details
**Expected Result:** Order status is "Cancelled"

---

## Test Case 5.3: Cancelling Shipped Order Fails with Message
**ID:** ORD-4-TC-010  
**Title:** Cancelling Shipped order is refused with specific error message  
**Preconditions:** Order exists with status "Shipped"  
**Steps:**
1. Attempt to cancel the order
2. Capture error message
3. Retrieve order details
**Expected Result:** Operation fails with error message "Shipped orders cannot be cancelled."; status remains "Shipped"

---

## Test Case 5.4: Cancelling Delivered Order
**ID:** ORD-4-TC-011  
**Title:** Cancelling Delivered order is refused  
**Preconditions:** Order exists with status "Delivered"  
**Steps:**
1. Attempt to cancel the order
2. Retrieve order details
**Expected Result:** Operation fails or is rejected; status remains "Delivered"

---

## Test Case 5.5: Cancelling Cancelled Order
**ID:** ORD-4-TC-012  
**Title:** Cancelling already-cancelled order fails gracefully  
**Preconditions:** Order exists with status "Cancelled"  
**Steps:**
1. Attempt to cancel the order
2. Retrieve order details
**Expected Result:** Operation fails or is rejected; status remains "Cancelled"

---

## Test Case 6.1: Complete Happy Path
**ID:** ORD-4-TC-013  
**Title:** Order transitions through all statuses in sequence  
**Preconditions:** System is available  
**Steps:**
1. Create order, verify status is "Placed"
2. Record payment, verify status is "Paid"
3. Mark as shipped, verify status is "Shipped"
4. Confirm delivery, verify status is "Delivered"
**Expected Result:** Order progresses through all statuses without errors

---

## Test Case 6.2: Cancel Before Shipping
**ID:** ORD-4-TC-014  
**Title:** Order created, paid, then cancelled before shipping  
**Preconditions:** System is available  
**Steps:**
1. Create order (status = "Placed")
2. Record payment (status = "Paid")
3. Cancel order
4. Verify status
**Expected Result:** Final status is "Cancelled"
