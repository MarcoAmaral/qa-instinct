# Test Cases for ORD-4: Order Status Changes

## TC-ORD-4.1: New Order Created with Placed Status
**Objective:** Verify that a newly created order has status "Placed"

**Preconditions:** Test database is empty or isolated

**Steps:**
1. Create a new order with valid order data (customer, items, amounts)
2. Retrieve the order details

**Expected Result:** Order status is "Placed"

**Assumptions:** Order creation endpoint returns/stores status automatically

---

## TC-ORD-4.2.1: Record Payment on Placed Order - Status Changes to Paid (AC-1)
**Objective:** Verify payment recording transitions Placed order to Paid

**Preconditions:** Order exists with status "Placed"

**Steps:**
1. Call payment recording endpoint with valid payment details (amount, method, reference)
2. Retrieve the order status

**Expected Result:** Order status is "Paid"

**Assumptions:** Payment amount matches order total; timestamp is recorded for audit trail

---

## TC-ORD-4.2.2: Record Partial Payment on Placed Order
**Objective:** Verify behavior when partial payment is recorded

**Preconditions:** Order exists with status "Placed", order total is $100

**Steps:**
1. Record payment of $50
2. Check order status

**Expected Result:** Order remains "Placed" or transitions to a different status based on business logic

**Assumptions:** Partial payments do not transition to Paid; system requires full payment

---

## TC-ORD-4.2.3: Attempt to Record Payment on Already Paid Order
**Objective:** Verify idempotency or error handling for duplicate payments

**Preconditions:** Order exists with status "Paid"

**Steps:**
1. Attempt to record another payment
2. Check order status

**Expected Result:** System either accepts payment (idempotent) or returns error 409/400; status remains "Paid"

**Assumptions:** Duplicate payment attempts are rejected to prevent double-billing

---

## TC-ORD-4.3.1: Ship a Paid Order - Status Changes to Shipped (AC-2)
**Objective:** Verify shipping a Paid order transitions status to Shipped

**Preconditions:** Order exists with status "Paid", items are in stock and picked

**Steps:**
1. Call ship/mark-shipped endpoint with tracking information
2. Retrieve order status

**Expected Result:** Order status is "Shipped"

**Assumptions:** Shipping endpoint validates stock before marking shipped; tracking number is stored

---

## TC-ORD-4.3.2: Attempt to Ship a Placed Order
**Objective:** Verify Placed orders cannot be shipped without payment

**Preconditions:** Order exists with status "Placed"

**Steps:**
1. Attempt to call ship endpoint on Placed order
2. Observe response

**Expected Result:** Request is rejected with 400 or 409 status; order remains "Placed"

**Assumptions:** Business rule requires payment before shipping

---

## TC-ORD-4.3.3: Attempt to Ship Already Shipped Order
**Objective:** Verify idempotency for ship operation

**Preconditions:** Order exists with status "Shipped"

**Steps:**
1. Attempt to ship the order again with same or different tracking
2. Check order status

**Expected Result:** System either accepts (idempotent) or returns error; status remains "Shipped"

**Assumptions:** Re-shipping same order is either rejected or silently accepted

---

## TC-ORD-4.4.1: Confirm Delivery of Shipped Order - Status Changes to Delivered (AC-3)
**Objective:** Verify delivery confirmation transitions Shipped order to Delivered

**Preconditions:** Order exists with status "Shipped", shipping in transit

**Steps:**
1. Call delivery confirmation endpoint (with signature/proof if applicable)
2. Retrieve order status

**Expected Result:** Order status is "Delivered"

**Assumptions:** Delivery proof is optional; timestamp is recorded when delivery confirmed

---

## TC-ORD-4.4.2: Attempt to Confirm Delivery on Placed Order
**Objective:** Verify Placed orders cannot be marked delivered

**Preconditions:** Order exists with status "Placed"

**Steps:**
1. Attempt to call delivery confirmation endpoint
2. Observe response

**Expected Result:** Request rejected with 400 or 409; order remains "Placed"

**Assumptions:** Order must progress through Paid and Shipped before delivery confirmation

---

## TC-ORD-4.4.3: Attempt to Confirm Delivery on Paid Order
**Objective:** Verify Paid orders cannot be marked delivered (must be shipped first)

**Preconditions:** Order exists with status "Paid"

**Steps:**
1. Attempt delivery confirmation on Paid order

**Expected Result:** Request rejected; order remains "Paid"

**Assumptions:** Shipped status is required before delivery confirmation

---

## TC-ORD-4.5.1: Cancel a Placed Order (AC-4)
**Objective:** Verify Placed orders can be cancelled

**Preconditions:** Order exists with status "Placed"

**Steps:**
1. Call cancel endpoint with cancellation reason
2. Retrieve order status

**Expected Result:** Order status is "Cancelled"

**Assumptions:** Inventory is not restored on cancellation of Placed orders; no refund processed

---

## TC-ORD-4.5.2: Cancel a Paid Order (AC-4)
**Objective:** Verify Paid orders can be cancelled

**Preconditions:** Order exists with status "Paid"

**Steps:**
1. Call cancel endpoint with cancellation reason
2. Retrieve order status

**Expected Result:** Order status is "Cancelled"

**Assumptions:** System processes refund when cancelling Paid order; refund status is tracked separately

---

## TC-ORD-4.5.3: Cancel a Shipped Order - Refused with Error Message (AC-5)
**Objective:** Verify Shipped orders cannot be cancelled and return correct error message

**Preconditions:** Order exists with status "Shipped"

**Steps:**
1. Call cancel endpoint on Shipped order
2. Observe error response

**Expected Result:** Request returns 400 or 409; error message is "Shipped orders cannot be cancelled."; order remains "Shipped"

**Assumptions:** Exact error message must match; shipped orders are non-cancellable

---

## TC-ORD-4.5.4: Attempt to Cancel a Delivered Order
**Objective:** Verify Delivered orders cannot be cancelled

**Preconditions:** Order exists with status "Delivered"

**Steps:**
1. Call cancel endpoint on Delivered order

**Expected Result:** Request rejected; order remains "Delivered"

**Assumptions:** Delivered orders cannot be cancelled; only returns/refunds possible

---

## TC-ORD-4.6.1: Verify Status Transition Audit Trail
**Objective:** Verify all status transitions are logged with timestamp and user/operator info

**Preconditions:** Order exists

**Steps:**
1. Perform complete flow: Create → Pay → Ship → Deliver
2. Query order history/audit log endpoint
3. Verify all transitions are recorded

**Expected Result:** Audit log shows all status changes with timestamps and operator ID

**Assumptions:** System maintains immutable audit trail; status change endpoints record who made the change

---

## TC-ORD-4.6.2: Verify Cannot Transition to Invalid Status
**Objective:** Verify only valid status transitions are allowed

**Preconditions:** Order exists with any status

**Steps:**
1. Attempt direct status update to invalid next state (e.g., Placed → Delivered)
2. Attempt PATCH with invalid status value

**Expected Result:** Request rejected; order status unchanged

**Assumptions:** Direct status manipulation via PATCH is either disallowed or validated; only workflow endpoints change status

---

## TC-ORD-4.6.3: Concurrent Status Transitions
**Objective:** Verify race condition handling when multiple status change requests arrive simultaneously

**Preconditions:** Order exists with status "Paid"

**Steps:**
1. Send two concurrent ship requests
2. Check final order status and response codes

**Expected Result:** One request succeeds (status → Shipped), other is rejected with 409 Conflict

**Assumptions:** Optimistic or pessimistic locking is implemented; database prevents race conditions

---

## TC-ORD-4.6.4: Cancelled Order Cannot Transition Further
**Objective:** Verify Cancelled status is terminal and prevents further transitions

**Preconditions:** Order exists with status "Cancelled"

**Steps:**
1. Attempt to record payment on Cancelled order
2. Attempt to ship Cancelled order
3. Attempt to deliver Cancelled order

**Expected Result:** All operations rejected; status remains "Cancelled"

**Assumptions:** Cancelled is a terminal state; no transitions from Cancelled to other statuses

---

## TC-ORD-4.6.5: Delivered Order Cannot Transition Further
**Objective:** Verify Delivered status is terminal and prevents further transitions

**Preconditions:** Order exists with status "Delivered"

**Steps:**
1. Attempt to record additional payment
2. Attempt to cancel the order
3. Attempt to ship the order

**Expected Result:** All operations rejected; status remains "Delivered"

**Assumptions:** Delivered is terminal; no transitions from Delivered except for returns/RMA (out of scope)
