# Test Cases for ORD-4: Order Status Changes

## Assumptions
- Order statuses are: `Placed`, `Paid`, `Shipped`, `Delivered`, `Cancelled`
- `Delivered` and `Cancelled` are terminal states; no further transitions are allowed
- Status transitions are attempted through dedicated actions: `recordPayment()`, `markShipped()`, `confirmDelivery()`, `cancel()`
- Attempting an invalid transition raises a domain exception with the provided error message

---

## Test Cases

### TC-1: Order Creation Status
**Given** a new order is created  
**When** the order is persisted  
**Then** the order status should be `Placed`

---

### TC-2: Record Payment on Placed Order (AC-1)
**Given** an order with status `Placed`  
**When** a payment is recorded  
**Then** the order status should change to `Paid`

---

### TC-3: Record Payment on Non-Placed Order
**Given** an order with status `Paid`  
**When** a payment is recorded  
**Then** the operation should fail or remain in `Paid` status

---

### TC-4: Mark Paid Order as Shipped (AC-2)
**Given** an order with status `Paid`  
**When** the order is marked as shipped  
**Then** the order status should change to `Shipped`

---

### TC-5: Mark Non-Paid Order as Shipped
**Given** an order with status `Placed`  
**When** the order is marked as shipped  
**Then** the operation should fail and status remains `Placed`

---

### TC-6: Confirm Delivery of Shipped Order (AC-3)
**Given** an order with status `Shipped`  
**When** delivery is confirmed  
**Then** the order status should change to `Delivered`

---

### TC-7: Confirm Delivery of Non-Shipped Order
**Given** an order with status `Paid`  
**When** delivery is confirmed  
**Then** the operation should fail and status remains `Paid`

---

### TC-8: Cancel a Placed Order (AC-4)
**Given** an order with status `Placed`  
**When** the order is cancelled  
**Then** the order status should change to `Cancelled`

---

### TC-9: Cancel a Paid Order (AC-4)
**Given** an order with status `Paid`  
**When** the order is cancelled  
**Then** the order status should change to `Cancelled`

---

### TC-10: Cancel a Shipped Order (AC-5)
**Given** an order with status `Shipped`  
**When** a cancellation is attempted  
**Then** the operation should fail with error message: `"Shipped orders cannot be cancelled."`

---

### TC-11: Cancel a Delivered Order
**Given** an order with status `Delivered`  
**When** a cancellation is attempted  
**Then** the operation should fail (terminal state)

---

### TC-12: Cancel an Already Cancelled Order
**Given** an order with status `Cancelled`  
**When** a cancellation is attempted  
**Then** the operation should fail (terminal state)

---

### TC-13: Transition from Cancelled Order
**Given** an order with status `Cancelled`  
**When** any status-changing action is attempted (payment, shipment, delivery)  
**Then** the operation should fail (terminal state)

---

### TC-14: Transition from Delivered Order
**Given** an order with status `Delivered`  
**When** any status-changing action is attempted (payment, shipment, cancellation)  
**Then** the operation should fail (terminal state)

---

### TC-15: Complete Order Flow: Placed → Paid → Shipped → Delivered
**Given** a new order  
**When** payment is recorded, then shipped, then delivery is confirmed  
**Then** the order progresses through statuses: `Placed` → `Paid` → `Shipped` → `Delivered`

---

### TC-16: Complete Order Flow with Cancellation: Placed → Paid → Cancelled
**Given** a new order  
**When** payment is recorded, then the order is cancelled  
**Then** the order progresses through statuses: `Placed` → `Paid` → `Cancelled`
