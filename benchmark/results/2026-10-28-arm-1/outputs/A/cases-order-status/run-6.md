# Test Cases for ORD-4: Order Status Changes

## Test Setup
**Assumptions:**
- An order is created with status "Placed" by default
- Only valid state transitions are allowed; invalid transitions fail silently or raise an error
- A "store operator" has permissions to perform all state-change operations
- The system returns appropriate error messages for refused operations
- All operations are performed on existing orders

---

## AC-1: Recording Payment on Placed Order

**Test 1.1: Payment on Placed order transitions to Paid**
- Given an order with status "Placed"
- When a payment is recorded
- Then the order status becomes "Paid"

**Test 1.2: Payment recording on already-Paid order (idempotent or error)**
- Given an order with status "Paid"
- When a payment is recorded again
- Then the order remains "Paid" (or system prevents duplicate payment)

**Test 1.3: Cannot record payment on Cancelled order**
- Given an order with status "Cancelled"
- When a payment recording is attempted
- Then the operation fails (status remains "Cancelled")

---

## AC-2: Marking Paid Order as Shipped

**Test 2.1: Shipped transition on Paid order changes to Shipped**
- Given an order with status "Paid"
- When the order is marked as shipped
- Then the order status becomes "Shipped"

**Test 2.2: Cannot ship a Placed order (must be Paid first)**
- Given an order with status "Placed"
- When the order is marked as shipped
- Then the operation fails (status remains "Placed")

**Test 2.3: Cannot ship a Cancelled order**
- Given an order with status "Cancelled"
- When the order is marked as shipped
- Then the operation fails (status remains "Cancelled")

---

## AC-3: Confirming Delivery of Shipped Order

**Test 3.1: Delivery confirmation on Shipped order changes to Delivered**
- Given an order with status "Shipped"
- When delivery is confirmed
- Then the order status becomes "Delivered"

**Test 3.2: Cannot confirm delivery on Paid order (must be Shipped first)**
- Given an order with status "Paid"
- When delivery confirmation is attempted
- Then the operation fails (status remains "Paid")

**Test 3.3: Cannot confirm delivery on Cancelled order**
- Given an order with status "Cancelled"
- When delivery confirmation is attempted
- Then the operation fails (status remains "Cancelled")

---

## AC-4: Cancelling Placed or Paid Orders

**Test 4.1: Cancel Placed order**
- Given an order with status "Placed"
- When the order is cancelled
- Then the order status becomes "Cancelled"

**Test 4.2: Cancel Paid order**
- Given an order with status "Paid"
- When the order is cancelled
- Then the order status becomes "Cancelled"

**Test 4.3: Cannot cancel already-Cancelled order**
- Given an order with status "Cancelled"
- When cancellation is attempted again
- Then the operation fails (status remains "Cancelled")

**Test 4.4: Cannot cancel Delivered order**
- Given an order with status "Delivered"
- When cancellation is attempted
- Then the operation fails (status remains "Delivered")

---

## AC-5: Shipped Orders Cannot Be Cancelled

**Test 5.1: Reject cancellation of Shipped order with specific error message**
- Given an order with status "Shipped"
- When the order cancellation is attempted
- Then the operation is refused
- And the error message is exactly "Shipped orders cannot be cancelled."
- And the order status remains "Shipped"

**Test 5.2: Cancellation attempt leaves order audit trail**
- Given an order with status "Shipped"
- When cancellation is attempted and refused
- Then a cancellation-attempt event is recorded (or system logs the refusal)
- And the order remains "Shipped"

---

## Integration / State Flow Tests

**Test 6.1: Complete happy-path order lifecycle**
- Given a new order (status "Placed")
- When payment is recorded → Then status is "Paid"
- When order is marked shipped → Then status is "Shipped"
- When delivery is confirmed → Then status is "Delivered"

**Test 6.2: Order cancelled after payment but before shipment**
- Given an order with status "Paid"
- When the order is cancelled → Then status becomes "Cancelled"
- And subsequent shipment marking fails

**Test 6.3: Cannot transition from Delivered to any other status**
- Given an order with status "Delivered"
- When any state-change operation is attempted (cancel, re-ship, etc.)
- Then all operations fail and status remains "Delivered"

---

## Edge Cases

**Test 7.1: Multiple concurrent status-change requests (concurrency)**
- Given an order with status "Placed"
- When payment and cancellation requests arrive simultaneously
- Then one operation succeeds and the other fails consistently (no race conditions)

**Test 7.2: Status change with missing or invalid order**
- Given a non-existent order ID
- When any status-change operation is attempted
- Then the system raises an appropriate error (order not found)
