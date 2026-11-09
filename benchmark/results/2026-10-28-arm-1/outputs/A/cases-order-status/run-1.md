# Test Cases for ORD-4: Order Status Changes

## Test Case 1: Order Created with Placed Status
**Given** a new order is created  
**When** the order is retrieved  
**Then** the order status should be "Placed"

## Test Case 2: Record Payment on Placed Order
**Given** an order with status "Placed"  
**When** a payment is recorded  
**Then** the order status should change to "Paid"

## Test Case 3: Record Payment on Non-Placed Order Fails
**Given** an order with status "Paid"  
**When** attempting to record another payment  
**Then** the operation should fail or be rejected

## Test Case 4: Mark Paid Order as Shipped
**Given** an order with status "Paid"  
**When** the order is marked as shipped  
**Then** the order status should change to "Shipped"

## Test Case 5: Mark Non-Paid Order as Shipped Fails
**Given** an order with status "Placed"  
**When** attempting to mark it as shipped  
**Then** the operation should fail

## Test Case 6: Confirm Delivery of Shipped Order
**Given** an order with status "Shipped"  
**When** delivery is confirmed  
**Then** the order status should change to "Delivered"

## Test Case 7: Confirm Delivery of Non-Shipped Order Fails
**Given** an order with status "Paid"  
**When** attempting to confirm delivery  
**Then** the operation should fail

## Test Case 8: Cancel Placed Order
**Given** an order with status "Placed"  
**When** the order is cancelled  
**Then** the order status should change to "Cancelled"

## Test Case 9: Cancel Paid Order
**Given** an order with status "Paid"  
**When** the order is cancelled  
**Then** the order status should change to "Cancelled"

## Test Case 10: Cancel Shipped Order Returns Error
**Given** an order with status "Shipped"  
**When** attempting to cancel the order  
**Then** the operation should fail with the error message "Shipped orders cannot be cancelled."

## Test Case 11: Cancel Delivered Order Returns Error
**Given** an order with status "Delivered"  
**When** attempting to cancel the order  
**Then** the operation should fail (assumption: Delivered orders are also non-cancellable)

## Test Case 12: Cancel Cancelled Order Fails
**Given** an order with status "Cancelled"  
**When** attempting to cancel it again  
**Then** the operation should fail

## Test Case 13: Complete Order Lifecycle
**Given** a new order  
**When** payment is recorded, order is shipped, and delivery is confirmed in sequence  
**Then** the order should progress through statuses: Placed → Paid → Shipped → Delivered
