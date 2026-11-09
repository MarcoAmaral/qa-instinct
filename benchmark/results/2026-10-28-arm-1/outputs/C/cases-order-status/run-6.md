# Test Cases for ORD-4: Order Status Changes

**Assumptions:**
- Orders are created in the system with an initial "Placed" status.
- A "payment recording" action exists (API, UI, or both) to move an order to "Paid".
- A "mark as shipped" action exists to move an order to "Shipped".
- A "confirm delivery" action exists to move an order to "Delivered".
- A "cancel order" action exists; cancellation is restricted based on order status.
- All state transitions are idempotent or validated (attempting the same action twice is handled).

---

## Test Case 1: Order Created in Placed Status
**Given** a new order is created  
**When** the order is retrieved from the system  
**Then** its status is "Placed"

---

## Test Case 2: Payment Recording Transitions Placed to Paid
**Given** an order with status "Placed"  
**When** a payment is recorded on the order  
**Then** the order status becomes "Paid"  
**And** the status change is persisted

---

## Test Case 3: Mark Paid Order as Shipped
**Given** an order with status "Paid"  
**When** the order is marked as shipped  
**Then** the order status becomes "Shipped"  
**And** the status change is persisted

---

## Test Case 4: Confirm Delivery of Shipped Order
**Given** an order with status "Shipped"  
**When** delivery of the order is confirmed  
**Then** the order status becomes "Delivered"  
**And** the status change is persisted

---

## Test Case 5: Cancel a Placed Order
**Given** an order with status "Placed"  
**When** the order is cancelled  
**Then** the order status becomes "Cancelled"  
**And** the status change is persisted

---

## Test Case 6: Cancel a Paid Order
**Given** an order with status "Paid"  
**When** the order is cancelled  
**Then** the order status becomes "Cancelled"  
**And** the status change is persisted

---

## Test Case 7: Cannot Cancel a Shipped Order
**Given** an order with status "Shipped"  
**When** a cancellation is attempted on the order  
**Then** the cancellation is refused  
**And** an error message "Shipped orders cannot be cancelled." is returned  
**And** the order status remains "Shipped"

---

## Test Case 8: Cannot Cancel a Delivered Order
**Given** an order with status "Delivered"  
**When** a cancellation is attempted on the order  
**Then** the cancellation is refused  
**And** the order status remains "Delivered"

---

## Test Case 9: Cannot Cancel a Cancelled Order
**Given** an order with status "Cancelled"  
**When** a cancellation is attempted on the order  
**Then** the cancellation is refused  
**And** the order status remains "Cancelled"

---

## Test Case 10: Cannot Record Payment on Already Paid Order
**Given** an order with status "Paid"  
**When** a payment is recorded again on the order  
**Then** the system either accepts it (idempotent) or returns an error  
**And** the order status remains "Paid"

---

## Test Case 11: Cannot Ship a Cancelled Order
**Given** an order with status "Cancelled"  
**When** a mark-as-shipped action is attempted  
**Then** the action is refused  
**And** the order status remains "Cancelled"

---

## Test Case 12: Complete Happy Path
**Given** a newly created order in "Placed" status  
**When** a payment is recorded, the order is marked as shipped, and delivery is confirmed  
**Then** the order transitions through all states: Placed → Paid → Shipped → Delivered  
**And** each transition is persisted

---

## Test Case 13: Cancel After Payment
**Given** an order that has transitioned to "Paid" status  
**When** the order is cancelled before shipment  
**Then** the order status becomes "Cancelled"  
**And** no further status transitions are allowed
