# Test Cases for ORD-4: Order Status Changes

## Test Case 1: AC-1 – Recording Payment on Placed Order
**Given:** An order with status "Placed"
**When:** A payment is recorded on the order
**Then:** The order status changes to "Paid"

## Test Case 2: AC-1 – Recording Payment on Non-Placed Order Fails
**Given:** An order with status "Paid"
**When:** A payment is recorded on the order
**Then:** The operation fails or is idempotent (assumption: fails with error "Payment already recorded" or similar)

## Test Case 3: AC-2 – Marking Paid Order as Shipped
**Given:** An order with status "Paid"
**When:** The order is marked as shipped
**Then:** The order status changes to "Shipped"

## Test Case 4: AC-2 – Marking Non-Paid Order as Shipped Fails
**Given:** An order with status "Placed"
**When:** The order is marked as shipped
**Then:** The operation fails with error "Order must be paid before shipping"

## Test Case 5: AC-3 – Confirming Delivery of Shipped Order
**Given:** An order with status "Shipped"
**When:** Delivery is confirmed
**Then:** The order status changes to "Delivered"

## Test Case 6: AC-3 – Confirming Delivery of Non-Shipped Order Fails
**Given:** An order with status "Paid"
**When:** Delivery is confirmed
**Then:** The operation fails with error "Order must be shipped before confirming delivery"

## Test Case 7: AC-4 – Cancelling a Placed Order
**Given:** An order with status "Placed"
**When:** The order is cancelled
**Then:** The order status changes to "Cancelled"

## Test Case 8: AC-4 – Cancelling a Paid Order
**Given:** An order with status "Paid"
**When:** The order is cancelled
**Then:** The order status changes to "Cancelled"

## Test Case 9: AC-4 – Cancelling a Delivered Order Fails
**Given:** An order with status "Delivered"
**When:** The order is cancelled
**Then:** The operation fails with error "Delivered orders cannot be cancelled"

## Test Case 10: AC-5 – Cancelling a Shipped Order Fails
**Given:** An order with status "Shipped"
**When:** The order is cancelled
**Then:** The operation fails with error "Shipped orders cannot be cancelled"

## Test Case 11: AC-5 – Cancelling an Already Cancelled Order
**Given:** An order with status "Cancelled"
**When:** The order is cancelled again
**Then:** The operation fails or is idempotent (assumption: fails with error "Order is already cancelled" or returns success)

## Test Case 12: Complete Happy Path
**Given:** A new order created with status "Placed"
**When:** The following sequence occurs:
  1. Payment is recorded
  2. Order is marked as shipped
  3. Delivery is confirmed
**Then:** The order transitions through all states: Placed → Paid → Shipped → Delivered

## Test Case 13: Order Cancelled After Payment
**Given:** An order with status "Paid"
**When:** Payment is recorded and then the order is cancelled
**Then:** The order status becomes "Cancelled" and no further operations are allowed (assumption: subsequent operations fail with "Order is cancelled")

## Test Case 14: Order Status Persistence
**Given:** An order whose status was changed to "Shipped"
**When:** The order is retrieved from storage
**Then:** The status remains "Shipped"
