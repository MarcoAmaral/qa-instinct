# Test Cases for Story ORD-4: Order Status Changes

## Assumptions
- Order status transitions are validated at the application layer
- All status change operations (record payment, mark shipped, confirm delivery, cancel) are atomic and immediately persisted
- The system prevents invalid status transitions with appropriate error responses
- A "Placed" order is successfully created as the baseline state
- API/method calls return appropriate success/error responses with relevant data

---

## Test Case Suite

### TC-1.1: Create Order in Placed Status
**Objective:** Verify order is created with Placed status
- **Given:** A new order is created
- **When:** Order creation completes
- **Then:** Order status should be "Placed"

---

### TC-2.1: AC-1 - Record Payment on Placed Order
**Objective:** Verify payment recording transitions Placed order to Paid
- **Given:** An order with status "Placed"
- **When:** Payment is recorded
- **Then:** Order status should change to "Paid"
- **And:** Payment details should be stored

### TC-2.2: AC-1 - Negative - Record Payment on Non-Placed Order
**Objective:** Verify payment cannot be recorded on order not in Placed status
- **Given:** An order with status "Shipped"
- **When:** Attempt to record payment
- **Then:** Operation should fail with an appropriate error message
- **And:** Order status should remain "Shipped"

### TC-2.3: AC-1 - Record Payment on Paid Order
**Objective:** Verify payment recording on already-Paid order is handled correctly
- **Given:** An order with status "Paid"
- **When:** Attempt to record payment again
- **Then:** System should reject the operation or idempotently succeed
- **And:** Order status should remain "Paid"

---

### TC-3.1: AC-2 - Mark Paid Order as Shipped
**Objective:** Verify shipping a Paid order transitions to Shipped
- **Given:** An order with status "Paid"
- **When:** Order is marked as shipped
- **Then:** Order status should change to "Shipped"
- **And:** Shipment timestamp should be recorded

### TC-3.2: AC-2 - Negative - Mark Placed Order as Shipped
**Objective:** Verify Placed order cannot be marked shipped without payment
- **Given:** An order with status "Placed"
- **When:** Attempt to mark order as shipped
- **Then:** Operation should fail with an appropriate error
- **And:** Order status should remain "Placed"

### TC-3.3: AC-2 - Mark Shipped Order as Shipped Again
**Objective:** Verify re-shipping an already-shipped order is handled
- **Given:** An order with status "Shipped"
- **When:** Attempt to mark order as shipped again
- **Then:** System should reject the operation or idempotently succeed
- **And:** Order status should remain "Shipped"

---

### TC-4.1: AC-3 - Confirm Delivery of Shipped Order
**Objective:** Verify confirming delivery transitions Shipped order to Delivered
- **Given:** An order with status "Shipped"
- **When:** Delivery is confirmed
- **Then:** Order status should change to "Delivered"
- **And:** Delivery timestamp should be recorded

### TC-4.2: AC-3 - Negative - Confirm Delivery of Paid Order
**Objective:** Verify delivery cannot be confirmed on non-shipped order
- **Given:** An order with status "Paid"
- **When:** Attempt to confirm delivery
- **Then:** Operation should fail with an appropriate error
- **And:** Order status should remain "Paid"

### TC-4.3: AC-3 - Confirm Delivery of Delivered Order
**Objective:** Verify delivery confirmation on already-delivered order is handled
- **Given:** An order with status "Delivered"
- **When:** Attempt to confirm delivery again
- **Then:** System should reject the operation or idempotently succeed
- **And:** Order status should remain "Delivered"

---

### TC-5.1: AC-4 - Cancel Placed Order
**Objective:** Verify Placed order can be cancelled
- **Given:** An order with status "Placed"
- **When:** Order is cancelled
- **Then:** Order status should change to "Cancelled"
- **And:** Cancellation reason or timestamp should be recorded

### TC-5.2: AC-4 - Cancel Paid Order
**Objective:** Verify Paid order can be cancelled
- **Given:** An order with status "Paid"
- **When:** Order is cancelled
- **Then:** Order status should change to "Cancelled"
- **And:** Refund process should be initiated (if applicable)

### TC-5.3: AC-4 - Negative - Cancel Delivered Order
**Objective:** Verify Delivered order cannot be cancelled
- **Given:** An order with status "Delivered"
- **When:** Attempt to cancel order
- **Then:** Operation should fail with an appropriate error
- **And:** Order status should remain "Delivered"

### TC-5.4: AC-4 - Cancel Already Cancelled Order
**Objective:** Verify cancelling a cancelled order is handled
- **Given:** An order with status "Cancelled"
- **When:** Attempt to cancel order again
- **Then:** System should reject the operation or idempotently succeed
- **And:** Order status should remain "Cancelled"

---

### TC-6.1: AC-5 - Refuse Cancellation of Shipped Order
**Objective:** Verify Shipped orders cannot be cancelled and correct error message is returned
- **Given:** An order with status "Shipped"
- **When:** Attempt to cancel order
- **Then:** Operation should fail
- **And:** Error message should be exactly "Shipped orders cannot be cancelled."
- **And:** Order status should remain "Shipped"

---

### TC-7.1: Full Happy Path - Order Lifecycle
**Objective:** Verify complete order flow through all statuses
- **Given:** A new order
- **When:** Payment is recorded → Order is shipped → Delivery is confirmed
- **Then:** Order progresses through statuses: Placed → Paid → Shipped → Delivered
- **And:** All timestamps and related data are correctly recorded at each step

### TC-7.2: Happy Path - Placed to Cancelled
**Objective:** Verify order can be cancelled immediately after creation
- **Given:** A newly created order with status "Placed"
- **When:** Order is cancelled without payment
- **Then:** Order status changes directly to "Cancelled"

### TC-7.3: Happy Path - Paid to Cancelled
**Objective:** Verify paid order can be cancelled before shipment
- **Given:** An order with status "Paid"
- **When:** Order is cancelled before shipping
- **Then:** Order status changes to "Cancelled"

---

### TC-8.1: Concurrent Status Transitions
**Objective:** Verify system handles concurrent status change attempts safely
- **Given:** An order with status "Placed"
- **When:** Two simultaneous requests attempt to record payment
- **Then:** Only one should succeed; the second should fail gracefully
- **And:** Order status should be "Paid"

### TC-8.2: Invalid Status Transition Sequence
**Objective:** Verify system rejects out-of-order transitions
- **Given:** An order with status "Placed"
- **When:** Attempt to mark order as delivered without intermediate states
- **Then:** Operation should fail
- **And:** Order status should remain "Placed"

---

### TC-9.1: Idempotency - Verify Multiple Same Requests
**Objective:** Verify status transitions are idempotent where applicable
- **Given:** An order successfully transitioned to "Paid"
- **When:** The same payment recording request is sent again
- **Then:** Response should indicate success
- **And:** Order status should remain "Paid"
- **And:** No duplicate payment records should exist
