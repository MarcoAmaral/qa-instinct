# Test Cases for ORD-4: Order Status Changes

## Assumptions
- Order management system has API endpoints or methods for: create order, record payment, mark shipped, confirm delivery, and cancel order
- Status values are: Placed, Paid, Shipped, Delivered, Cancelled
- Invalid transitions should return an error response with appropriate status code
- Tests use Arrange-Act-Assert pattern

## Test Cases

### Initial State
- **TC-1.1**: Creating an order sets initial status to "Placed"
  - Given: A new order is created
  - When: Order is retrieved
  - Then: Order status is "Placed"

### AC-1: Payment Recording
- **TC-2.1**: Recording payment on Placed order changes status to Paid
  - Given: An order with status "Placed"
  - When: Payment is recorded
  - Then: Order status becomes "Paid"

- **TC-2.2**: Recording payment on non-Placed order is refused
  - Given: An order with status "Shipped"
  - When: Payment is recorded
  - Then: Error response returned (or payment action fails)

### AC-2: Shipping Paid Orders
- **TC-3.1**: Marking a Paid order as shipped changes status to Shipped
  - Given: An order with status "Paid"
  - When: Order is marked as shipped
  - Then: Order status becomes "Shipped"

- **TC-3.2**: Marking a non-Paid order as shipped is refused
  - Given: An order with status "Placed"
  - When: Order is marked as shipped
  - Then: Error response returned

### AC-3: Confirming Delivery
- **TC-4.1**: Confirming delivery of Shipped order changes status to Delivered
  - Given: An order with status "Shipped"
  - When: Delivery is confirmed
  - Then: Order status becomes "Delivered"

- **TC-4.2**: Confirming delivery of non-Shipped order is refused
  - Given: An order with status "Paid"
  - When: Delivery is confirmed
  - Then: Error response returned

### AC-4: Cancelling Placed or Paid Orders
- **TC-5.1**: Cancelling a Placed order changes status to Cancelled
  - Given: An order with status "Placed"
  - When: Order is cancelled
  - Then: Order status becomes "Cancelled"

- **TC-5.2**: Cancelling a Paid order changes status to Cancelled
  - Given: An order with status "Paid"
  - When: Order is cancelled
  - Then: Order status becomes "Cancelled"

- **TC-5.3**: Cancelling a Delivered order is refused
  - Given: An order with status "Delivered"
  - When: Order is cancelled
  - Then: Error response returned

### AC-5: Refusing to Cancel Shipped Orders
- **TC-6.1**: Cancelling a Shipped order returns specific error message
  - Given: An order with status "Shipped"
  - When: Order is cancelled
  - Then: Error message "Shipped orders cannot be cancelled." is returned

### Additional Edge Cases
- **TC-7.1**: Cancelling a Cancelled order is refused
  - Given: An order with status "Cancelled"
  - When: Order is cancelled
  - Then: Error response returned

- **TC-7.2**: Confirming delivery of a Delivered order is refused
  - Given: An order with status "Delivered"
  - When: Delivery is confirmed again
  - Then: Error response returned

- **TC-7.3**: Attempting multiple status transitions in sequence succeeds
  - Given: A new order
  - When: Payment recorded, then marked shipped, then delivery confirmed
  - Then: Status progresses through Placed → Paid → Shipped → Delivered
