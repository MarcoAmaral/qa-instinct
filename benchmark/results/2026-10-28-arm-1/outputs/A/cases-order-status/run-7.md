# Test Cases for ORD-4: Order Status Changes

## Assumptions
- Order status transitions are managed by a service/repository with methods: `create_order()`, `record_payment()`, `mark_as_shipped()`, `confirm_delivery()`, `cancel_order()`
- Status field is a string or enum: "Placed", "Paid", "Shipped", "Delivered", "Cancelled"
- Errors are raised/returned with a message property
- Tests can create orders in isolation

---

## TC-1: Order Creation Status
**Given** a new order is created  
**When** the order is initialized  
**Then** the order status is "Placed"

## TC-2: Payment Recording on Placed Order (AC-1)
**Given** an order with status "Placed"  
**When** a payment is recorded  
**Then** the order status changes to "Paid"

## TC-3: Payment Recording on Non-Placed Order Fails
**Given** an order with status "Shipped"  
**When** a payment is recorded  
**Then** an error is raised (or rejected based on implementation)

## TC-4: Ship Paid Order (AC-2)
**Given** an order with status "Paid"  
**When** the order is marked as shipped  
**Then** the order status changes to "Shipped"

## TC-5: Ship Non-Paid Order Fails
**Given** an order with status "Placed"  
**When** the order is marked as shipped  
**Then** an error is raised

## TC-6: Confirm Delivery on Shipped Order (AC-3)
**Given** an order with status "Shipped"  
**When** delivery is confirmed  
**Then** the order status changes to "Delivered"

## TC-7: Confirm Delivery on Non-Shipped Order Fails
**Given** an order with status "Paid"  
**When** delivery is confirmed  
**Then** an error is raised

## TC-8: Cancel Placed Order (AC-4)
**Given** an order with status "Placed"  
**When** the order is cancelled  
**Then** the order status changes to "Cancelled"

## TC-9: Cancel Paid Order (AC-4)
**Given** an order with status "Paid"  
**When** the order is cancelled  
**Then** the order status changes to "Cancelled"

## TC-10: Cancel Shipped Order Refused (AC-5)
**Given** an order with status "Shipped"  
**When** the order is cancelled  
**Then** an error is raised with the message "Shipped orders cannot be cancelled."

## TC-11: Cancel Delivered Order Fails
**Given** an order with status "Delivered"  
**When** the order is cancelled  
**Then** an error is raised

## TC-12: Cancel Already Cancelled Order Fails
**Given** an order with status "Cancelled"  
**When** the order is cancelled again  
**Then** an error is raised

## TC-13: Full Order Lifecycle
**Given** a new order  
**When** payment is recorded, then shipped, then delivery confirmed  
**Then** the order transitions through "Placed" → "Paid" → "Shipped" → "Delivered"

## TC-14: Cancelled Order Cannot Progress
**Given** an order with status "Cancelled"  
**When** attempting to record payment, ship, or confirm delivery  
**Then** all operations are refused with an appropriate error

## TC-15: Multiple Payments on Placed Order
**Given** an order with status "Placed"  
**When** payment is recorded twice  
**Then** the second payment attempt is refused (idempotency or state validation)
