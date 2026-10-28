# Test Cases for ORD-4: Order Status Changes

## Test Case 1: Order Creation with Placed Status
**ID:** TC-ORD-4-001  
**Objective:** Verify that a new order is created with Placed status  
**Preconditions:** System is running; user has permission to create orders  
**Steps:**
1. Create a new order
2. Retrieve order details

**Expected Result:** Order status is "Placed"  
**Priority:** Critical

---

## Test Case 2: Record Payment on Placed Order
**ID:** TC-ORD-4-002  
**Objective:** Verify payment recording transitions order from Placed to Paid  
**Preconditions:** Order exists with status "Placed"  
**Steps:**
1. Record a payment on the order
2. Retrieve order details

**Expected Result:** Order status changes to "Paid"; timestamp of status change is recorded  
**Priority:** Critical

---

## Test Case 3: Mark Paid Order as Shipped
**ID:** TC-ORD-4-003  
**Objective:** Verify marking a Paid order as shipped transitions to Shipped status  
**Preconditions:** Order exists with status "Paid"  
**Steps:**
1. Mark the order as shipped
2. Retrieve order details

**Expected Result:** Order status changes to "Shipped"; timestamp is recorded  
**Priority:** Critical

---

## Test Case 4: Confirm Delivery of Shipped Order
**ID:** TC-ORD-4-004  
**Objective:** Verify confirming delivery transitions order from Shipped to Delivered  
**Preconditions:** Order exists with status "Shipped"  
**Steps:**
1. Confirm delivery of the order
2. Retrieve order details

**Expected Result:** Order status changes to "Delivered"; timestamp is recorded  
**Priority:** Critical

---

## Test Case 5: Cancel Placed Order
**ID:** TC-ORD-4-005  
**Objective:** Verify cancellation of Placed order transitions to Cancelled status  
**Preconditions:** Order exists with status "Placed"  
**Steps:**
1. Cancel the order
2. Retrieve order details

**Expected Result:** Order status changes to "Cancelled"; timestamp is recorded  
**Priority:** High

---

## Test Case 6: Cancel Paid Order
**ID:** TC-ORD-4-006  
**Objective:** Verify cancellation of Paid order transitions to Cancelled status  
**Preconditions:** Order exists with status "Paid"  
**Steps:**
1. Cancel the order
2. Retrieve order details

**Expected Result:** Order status changes to "Cancelled"; timestamp is recorded  
**Priority:** High

---

## Test Case 7: Attempt to Cancel Shipped Order - Failure
**ID:** TC-ORD-4-007  
**Objective:** Verify that cancelling a Shipped order is refused with appropriate error message  
**Preconditions:** Order exists with status "Shipped"  
**Steps:**
1. Attempt to cancel the order
2. Retrieve order details

**Expected Result:** Cancellation is refused; error message displayed is exactly "Shipped orders cannot be cancelled."; order status remains "Shipped"  
**Priority:** Critical

---

## Test Case 8: Attempt to Cancel Delivered Order - Failure
**ID:** TC-ORD-4-008  
**Objective:** Verify that cancelling a Delivered order is refused  
**Preconditions:** Order exists with status "Delivered"  
**Steps:**
1. Attempt to cancel the order

**Expected Result:** Cancellation is refused; order status remains "Delivered"  
**Assumption:** Based on AC-4 and AC-5, only Placed and Paid orders can be cancelled  
**Priority:** High

---

## Test Case 9: Complete Order Status Flow (Happy Path)
**ID:** TC-ORD-4-009  
**Objective:** Verify the complete status transition flow from creation to delivery  
**Preconditions:** System is running  
**Steps:**
1. Create a new order
2. Record payment on the order
3. Mark order as shipped
4. Confirm delivery

**Expected Result:** Order status transitions through Placed → Paid → Shipped → Delivered; each step updates the status and timestamp  
**Priority:** Critical

---

## Test Case 10: Attempt Invalid State Transition - Payment on Paid Order
**ID:** TC-ORD-4-010  
**Objective:** Verify that recording payment on already Paid order is handled appropriately  
**Preconditions:** Order exists with status "Paid"  
**Steps:**
1. Attempt to record another payment on the order

**Expected Result:** System either rejects the duplicate payment or handles it gracefully (assumption: rejects with appropriate error)  
**Assumption:** Double-payment should not be allowed  
**Priority:** Medium

---

## Test Case 11: Attempt Invalid State Transition - Ship Placed Order
**ID:** TC-ORD-4-011  
**Objective:** Verify that marking a Placed order as shipped (skipping Paid) is handled  
**Preconditions:** Order exists with status "Placed"  
**Steps:**
1. Attempt to mark the order as shipped without recording payment first

**Expected Result:** System rejects the operation or requires payment first  
**Assumption:** Status transitions must follow the defined sequence  
**Priority:** Medium

---

## Test Case 12: Status Change Audit Trail
**ID:** TC-ORD-4-012  
**Objective:** Verify that status change history is recorded and auditable  
**Preconditions:** Order has gone through multiple status changes (Placed → Paid → Shipped)  
**Steps:**
1. Retrieve order status history/audit log

**Expected Result:** All status transitions are recorded with timestamps and in correct chronological order  
**Assumption:** System maintains an audit trail of all status changes  
**Priority:** Medium

---

## Test Case 13: Concurrent Status Change Attempts
**ID:** TC-ORD-4-013  
**Objective:** Verify system handles concurrent status change requests correctly  
**Preconditions:** Order exists with status "Placed"  
**Steps:**
1. Simultaneously attempt two payment recordings on the same order from different sessions

**Expected Result:** One request succeeds and updates status to Paid; second request is rejected due to conflict or returns the already-updated status  
**Assumption:** System implements optimistic or pessimistic locking to prevent race conditions  
**Priority:** Medium

---

## Test Case 14: Cancelled Order Immutability
**ID:** TC-ORD-4-014  
**Objective:** Verify that a Cancelled order cannot transition to other statuses  
**Preconditions:** Order exists with status "Cancelled"  
**Steps:**
1. Attempt to record payment on Cancelled order
2. Attempt to mark Cancelled order as shipped

**Expected Result:** All attempts are rejected; order status remains "Cancelled"  
**Assumption:** Cancelled is a terminal state  
**Priority:** High

---

## Test Case 15: Delivered Order Immutability
**ID:** TC-ORD-4-015  
**Objective:** Verify that a Delivered order cannot transition to other statuses  
**Preconditions:** Order exists with status "Delivered"  
**Steps:**
1. Attempt to record payment on Delivered order
2. Attempt to ship Delivered order

**Expected Result:** All attempts are rejected; order status remains "Delivered"  
**Assumption:** Delivered is a terminal state  
**Priority:** High
