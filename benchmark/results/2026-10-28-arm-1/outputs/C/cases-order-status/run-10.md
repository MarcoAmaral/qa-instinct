# Test Cases for ORD-4: Order Status Changes

## Test Case 1: Order Created in Placed Status
**Given** a new order is created  
**When** the order is saved  
**Then** the order status is "Placed"

## Test Case 2: Record Payment on Placed Order
**Given** an order with status "Placed"  
**When** a payment is recorded  
**Then** the order status changes to "Paid"

## Test Case 3: Mark Paid Order as Shipped
**Given** an order with status "Paid"  
**When** the order is marked as shipped  
**Then** the order status changes to "Shipped"

## Test Case 4: Confirm Delivery of Shipped Order
**Given** an order with status "Shipped"  
**When** delivery is confirmed  
**Then** the order status changes to "Delivered"

## Test Case 5: Cancel Placed Order
**Given** an order with status "Placed"  
**When** the order is cancelled  
**Then** the order status changes to "Cancelled"

## Test Case 6: Cancel Paid Order
**Given** an order with status "Paid"  
**When** the order is cancelled  
**Then** the order status changes to "Cancelled"

## Test Case 7: Attempt to Cancel Shipped Order
**Given** an order with status "Shipped"  
**When** a cancellation is attempted  
**Then** the cancellation is refused with the message "Shipped orders cannot be cancelled"  
**And** the order status remains "Shipped"

## Test Case 8: Invalid Status Transition – Record Payment on Paid Order
**Given** an order with status "Paid"  
**When** a payment is recorded  
**Then** the action is either ignored or an error is shown (assumption: system prevents duplicate payment)

## Test Case 9: Invalid Status Transition – Record Payment on Shipped Order
**Given** an order with status "Shipped"  
**When** a payment is recorded  
**Then** the action is either ignored or an error is shown (assumption: payment cannot be recorded after shipment)

## Test Case 10: Invalid Status Transition – Mark Placed Order as Shipped
**Given** an order with status "Placed"  
**When** the order is marked as shipped  
**Then** the action is either ignored or an error is shown (assumption: must be Paid before shipping)

## Test Case 11: Cancelled Order Cannot Transition
**Given** an order with status "Cancelled"  
**When** any status change is attempted  
**Then** the status remains "Cancelled" (assumption: Cancelled is a terminal state)

## Test Case 12: Delivered Order Cannot Transition
**Given** an order with status "Delivered"  
**When** any status change is attempted  
**Then** the status remains "Delivered" (assumption: Delivered is a terminal state)

**Assumptions Made:**
- Orders are created in "Placed" status through an automatic system process
- "Cancelled" and "Delivered" are terminal states with no further transitions
- Invalid state transitions are either prevented at the system level or return an error message
- Store operators have permission to perform all status-change actions
- Each status change is atomic and immediately persisted
