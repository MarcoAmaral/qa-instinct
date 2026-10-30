# Test Cases for ORD-4: Order Status Changes

## Assumptions
- Orders are identified by a unique Order ID
- Status changes are initiated by store operators with appropriate permissions
- Status transitions are permanent and auditable
- Orders cannot be modified once in Delivered status
- Recording payment, marking shipped, confirming delivery, and cancelling are discrete operations requiring explicit user action
- Only one order status is active per order at any time
- Status checks are available via an order details/status endpoint
- Timestamp records are captured for each status change

---

## Test Case 1: Order Created with Placed Status
**Precondition:** System is initialized
**Steps:**
1. Create a new order with order data (order items, customer info, total amount)
**Expected Result:**
- Order is successfully created
- Order status is "Placed"
- Order ID is assigned and retrievable

---

## Test Case 2: Record Payment on Placed Order (AC-1)
**Precondition:** Order exists with status "Placed"
**Steps:**
1. Record a payment for the order with payment details (amount, method, reference)
**Expected Result:**
- Payment is recorded successfully
- Order status changes to "Paid"
- Status change timestamp is recorded
- Order details confirm status is "Paid"

---

## Test Case 3: Mark Paid Order as Shipped (AC-2)
**Precondition:** Order exists with status "Paid"
**Steps:**
1. Mark the order as shipped with shipping details (carrier, tracking number, date)
**Expected Result:**
- Order is marked as shipped successfully
- Order status changes to "Shipped"
- Shipping details are recorded
- Status change timestamp is recorded

---

## Test Case 4: Confirm Delivery of Shipped Order (AC-3)
**Precondition:** Order exists with status "Shipped"
**Steps:**
1. Confirm delivery of the order with delivery details (delivery date, signature/recipient info)
**Expected Result:**
- Delivery is confirmed successfully
- Order status changes to "Delivered"
- Delivery details are recorded
- Status change timestamp is recorded

---

## Test Case 5: Cancel Placed Order (AC-4)
**Precondition:** Order exists with status "Placed"
**Steps:**
1. Request cancellation of the order with cancellation reason
**Expected Result:**
- Order is cancelled successfully
- Order status changes to "Cancelled"
- Cancellation reason is recorded
- Status change timestamp is recorded

---

## Test Case 6: Cancel Paid Order (AC-4)
**Precondition:** Order exists with status "Paid"
**Steps:**
1. Request cancellation of the order with cancellation reason
**Expected Result:**
- Order is cancelled successfully
- Order status changes to "Cancelled"
- Cancellation reason is recorded
- Status change timestamp is recorded

---

## Test Case 7: Attempt to Cancel Shipped Order - Refused (AC-5)
**Precondition:** Order exists with status "Shipped"
**Steps:**
1. Request cancellation of the order
**Expected Result:**
- Cancellation request is rejected
- Error message returned: "Shipped orders cannot be cancelled."
- Order status remains "Shipped"
- No status change is recorded

---

## Test Case 8: Attempt Invalid Status Transition - Record Payment on Paid Order
**Precondition:** Order exists with status "Paid"
**Steps:**
1. Attempt to record another payment for the order
**Expected Result:**
- Action is rejected (payment already recorded)
- Order status remains "Paid"
- Appropriate error message is returned

---

## Test Case 9: Attempt Invalid Status Transition - Ship before Payment
**Precondition:** Order exists with status "Placed"
**Steps:**
1. Attempt to mark the order as shipped without recording payment first
**Expected Result:**
- Action is rejected
- Order status remains "Placed"
- Appropriate error message is returned (e.g., "Cannot ship unpaid orders")

---

## Test Case 10: Attempt Invalid Status Transition - Confirm Delivery on Paid Order
**Precondition:** Order exists with status "Paid"
**Steps:**
1. Attempt to confirm delivery without marking order as shipped first
**Expected Result:**
- Action is rejected
- Order status remains "Paid"
- Appropriate error message is returned

---

## Test Case 11: Attempt to Modify Delivered Order
**Precondition:** Order exists with status "Delivered"
**Steps:**
1. Attempt to record a payment, ship, or cancel the order
**Expected Result:**
- All actions are rejected
- Order status remains "Delivered"
- Appropriate error message is returned (e.g., "Delivered orders cannot be modified")

---

## Test Case 12: Status Visibility - Retrieve Order Status at Each Stage
**Precondition:** Order progresses through status changes
**Steps:**
1. Create order (status: Placed)
2. Record payment (status: Paid)
3. Mark as shipped (status: Shipped)
4. Confirm delivery (status: Delivered)
5. At each step, retrieve and verify order status
**Expected Result:**
- Order status is always accurate and immediately visible after each change
- All historical statuses are correctly reflected in order details

---

## Test Case 13: Multiple Orders - Independent Status Management
**Precondition:** Two orders are created
**Steps:**
1. Create Order A (status: Placed)
2. Create Order B (status: Placed)
3. Record payment for Order A (Order A → Paid)
4. Verify Order B status remains "Placed"
5. Record payment for Order B (Order B → Paid)
6. Cancel Order A
**Expected Result:**
- Each order's status changes independently
- Order A becomes "Cancelled"
- Order B remains "Paid"
- No cross-order status interference

---

## Test Case 14: Record Partial Payment on Placed Order
**Precondition:** Order exists with status "Placed" with total amount $100
**Steps:**
1. Record a payment of $50 (less than total order amount)
**Expected Result:**
- Payment is recorded
- Order status transitions to "Paid" (assumption: partial payments mark order as paid; alternative: status only changes when full amount received)
- Payment amount is recorded correctly

---

## Test Case 15: Cancel Delivered Order - Refused
**Precondition:** Order exists with status "Delivered"
**Steps:**
1. Attempt to cancel the order
**Expected Result:**
- Cancellation is rejected
- Order status remains "Delivered"
- Appropriate error message is returned (e.g., "Delivered orders cannot be cancelled")
