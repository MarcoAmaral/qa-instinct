# Test Cases for Story ORD-4: Order Status Changes

## Assumptions
- Order status transitions are triggered via API endpoints or admin UI
- Only authenticated store operators can modify order status
- Status changes are persisted immediately in the database
- Orders are uniquely identified by Order ID
- Timestamps are recorded for status changes
- Concurrent requests are handled (last write wins or request queuing)

---

## Test Case TC-ORD-4.1: Create Order with Initial Status
**Priority:** Critical  
**Description:** Verify that new orders are created with "Placed" status

**Preconditions:**
- No specific preconditions

**Steps:**
1. Create a new order via API/UI
2. Retrieve the order details

**Expected Result:**
- Order is successfully created
- Order status = "Placed"
- Timestamp is recorded

---

## Test Case TC-ORD-4.2: Record Payment on Placed Order (AC-1)
**Priority:** Critical  
**Description:** Verify payment recording changes Placed order to Paid

**Preconditions:**
- Order exists with status "Placed"
- Valid payment information is available

**Steps:**
1. Record payment on Placed order
2. Retrieve order details
3. Verify status change timestamp

**Expected Result:**
- Order status changed to "Paid"
- Previous status recorded in audit trail
- Status change timestamp is current

---

## Test Case TC-ORD-4.3: Record Payment on Non-Placed Order
**Priority:** High  
**Description:** Verify payment recording fails on orders not in Placed status

**Preconditions:**
- Order exists with status "Paid"

**Steps:**
1. Attempt to record payment on Paid order
2. Check response

**Expected Result:**
- Request is rejected with appropriate error message
- Order status remains unchanged

---

## Test Case TC-ORD-4.4: Mark Paid Order as Shipped (AC-2)
**Priority:** Critical  
**Description:** Verify marking Paid order as shipped changes status to Shipped

**Preconditions:**
- Order exists with status "Paid"

**Steps:**
1. Mark order as shipped
2. Retrieve order details
3. Verify status change timestamp

**Expected Result:**
- Order status changed to "Shipped"
- Previous status recorded in audit trail
- Status change timestamp is current

---

## Test Case TC-ORD-4.5: Mark Non-Paid Order as Shipped
**Priority:** High  
**Description:** Verify marking non-Paid order as shipped is rejected

**Preconditions:**
- Order exists with status "Placed"

**Steps:**
1. Attempt to mark Placed order as shipped
2. Check response

**Expected Result:**
- Request is rejected with appropriate error message
- Order status remains "Placed"

---

## Test Case TC-ORD-4.6: Confirm Delivery of Shipped Order (AC-3)
**Priority:** Critical  
**Description:** Verify confirming delivery changes Shipped order to Delivered

**Preconditions:**
- Order exists with status "Shipped"

**Steps:**
1. Confirm delivery of order
2. Retrieve order details
3. Verify status change timestamp

**Expected Result:**
- Order status changed to "Delivered"
- Previous status recorded in audit trail
- Status change timestamp is current

---

## Test Case TC-ORD-4.7: Confirm Delivery of Non-Shipped Order
**Priority:** High  
**Description:** Verify confirming delivery of non-Shipped order is rejected

**Preconditions:**
- Order exists with status "Paid"

**Steps:**
1. Attempt to confirm delivery on Paid order
2. Check response

**Expected Result:**
- Request is rejected with appropriate error message
- Order status remains "Paid"

---

## Test Case TC-ORD-4.8: Cancel Placed Order (AC-4)
**Priority:** Critical  
**Description:** Verify cancelling Placed order changes status to Cancelled

**Preconditions:**
- Order exists with status "Placed"

**Steps:**
1. Cancel order
2. Retrieve order details
3. Verify status change timestamp

**Expected Result:**
- Order status changed to "Cancelled"
- Previous status recorded in audit trail
- Status change timestamp is current

---

## Test Case TC-ORD-4.9: Cancel Paid Order (AC-4)
**Priority:** Critical  
**Description:** Verify cancelling Paid order changes status to Cancelled

**Preconditions:**
- Order exists with status "Paid"

**Steps:**
1. Cancel order
2. Retrieve order details
3. Verify status change timestamp

**Expected Result:**
- Order status changed to "Cancelled"
- Previous status recorded in audit trail
- Status change timestamp is current

---

## Test Case TC-ORD-4.10: Cancel Shipped Order (AC-5)
**Priority:** Critical  
**Description:** Verify cancelling Shipped order is rejected with specific error message

**Preconditions:**
- Order exists with status "Shipped"

**Steps:**
1. Attempt to cancel Shipped order
2. Check response message

**Expected Result:**
- Request is rejected
- Error message = "Shipped orders cannot be cancelled."
- Order status remains "Shipped"

---

## Test Case TC-ORD-4.11: Cancel Delivered Order
**Priority:** High  
**Description:** Verify cancelling Delivered order is rejected

**Preconditions:**
- Order exists with status "Delivered"

**Steps:**
1. Attempt to cancel Delivered order
2. Check response

**Expected Result:**
- Request is rejected with appropriate error message
- Order status remains "Delivered"

---

## Test Case TC-ORD-4.12: Cancel Already Cancelled Order
**Priority:** Medium  
**Description:** Verify cancelling an already cancelled order is rejected or idempotent

**Preconditions:**
- Order exists with status "Cancelled"

**Steps:**
1. Attempt to cancel Cancelled order
2. Check response

**Expected Result:**
- Request is rejected OR returns success (idempotent behavior)
- Order status remains "Cancelled"

---

## Test Case TC-ORD-4.13: Mark Cancelled Order as Shipped
**Priority:** High  
**Description:** Verify status transitions into Cancelled order are rejected

**Preconditions:**
- Order exists with status "Cancelled"

**Steps:**
1. Attempt to mark Cancelled order as shipped
2. Check response

**Expected Result:**
- Request is rejected with appropriate error message
- Order status remains "Cancelled"

---

## Test Case TC-ORD-4.14: Status Transition Sequence
**Priority:** High  
**Description:** Verify complete happy path: Placed → Paid → Shipped → Delivered

**Preconditions:**
- No preconditions

**Steps:**
1. Create order; verify status = "Placed"
2. Record payment; verify status = "Paid"
3. Mark as shipped; verify status = "Shipped"
4. Confirm delivery; verify status = "Delivered"

**Expected Result:**
- All status transitions succeed in sequence
- Order audit trail shows all four status changes with timestamps

---

## Test Case TC-ORD-4.15: Status Transition Audit Trail
**Priority:** Medium  
**Description:** Verify complete audit trail is maintained for all status changes

**Preconditions:**
- Order has undergone multiple status transitions

**Steps:**
1. Retrieve order audit trail
2. Verify all status changes are recorded
3. Verify timestamps and user who made changes (if applicable)

**Expected Result:**
- Audit trail contains all status changes
- Each entry includes: previous status, new status, timestamp, and operator ID
- Entries are in chronological order

---

## Test Case TC-ORD-4.16: Multiple Concurrent Status Change Requests
**Priority:** Medium  
**Description:** Verify system handles concurrent status change requests safely

**Preconditions:**
- Order exists with status "Placed"

**Steps:**
1. Send two simultaneous payment recording requests
2. Check final status and audit trail

**Expected Result:**
- Only one request succeeds
- OR both requests succeed but status changes only once (idempotent)
- OR one request is queued and processes sequentially
- Audit trail reflects the actual sequence of events

---

## Test Case TC-ORD-4.17: Invalid Status Values
**Priority:** Medium  
**Description:** Verify system rejects invalid status values

**Preconditions:**
- Order exists with status "Placed"

**Steps:**
1. Attempt to directly set order status to invalid value (e.g., "InTransit", "Pending")
2. Check response

**Expected Result:**
- Request is rejected
- Order status remains unchanged
- Error message indicates invalid status

---

## Test Case TC-ORD-4.18: Missing Order ID
**Priority:** High  
**Description:** Verify status change request with missing order ID is rejected

**Preconditions:**
- No preconditions

**Steps:**
1. Attempt status change without specifying order ID
2. Check response

**Expected Result:**
- Request is rejected with validation error
- Appropriate error message indicating missing required field

---

## Test Case TC-ORD-4.19: Non-Existent Order ID
**Priority:** High  
**Description:** Verify status change request for non-existent order is rejected

**Preconditions:**
- No preconditions

**Steps:**
1. Attempt status change on order ID that doesn't exist
2. Check response

**Expected Result:**
- Request is rejected with "Order not found" error
- No new order is created

---

## Test Case TC-ORD-4.20: Unauthorized User Attempts Status Change
**Priority:** High  
**Description:** Verify users without store operator role cannot change order status

**Preconditions:**
- Order exists with status "Placed"
- User without store operator permissions is logged in

**Steps:**
1. Attempt to record payment on order
2. Check response

**Expected Result:**
- Request is rejected with authorization error
- Order status remains unchanged
