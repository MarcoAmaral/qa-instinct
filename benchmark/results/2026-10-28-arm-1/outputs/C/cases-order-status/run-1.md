The writing-guide skill is for help-center articles (how-to, concept, troubleshooting, reference). Test cases are QA specifications, not end-user documentation. I'll write the test cases you need in standard format instead.

---

# Test Cases: Order Status Changes (ORD-4)

## Setup Assumptions
- An order object has a `status` field (enum: Placed, Paid, Shipped, Delivered, Cancelled)
- Orders are created in Placed status by default
- Status transitions are enforced by business logic (not allowed via direct field update)
- Actions are: `recordPayment()`, `markShipped()`, `confirmDelivery()`, `cancelOrder()`
- Cancellation raises an error rather than silently failing

---

## Test Case 1: AC-1 — Record payment on Placed order
**Given** an order with status Placed  
**When** `recordPayment()` is called  
**Then** status becomes Paid

---

## Test Case 2: AC-2 — Mark Paid order as shipped
**Given** an order with status Paid  
**When** `markShipped()` is called  
**Then** status becomes Shipped

---

## Test Case 3: AC-3 — Confirm delivery of Shipped order
**Given** an order with status Shipped  
**When** `confirmDelivery()` is called  
**Then** status becomes Delivered

---

## Test Case 4: AC-4a — Cancel Placed order
**Given** an order with status Placed  
**When** `cancelOrder()` is called  
**Then** status becomes Cancelled

---

## Test Case 5: AC-4b — Cancel Paid order
**Given** an order with status Paid  
**When** `cancelOrder()` is called  
**Then** status becomes Cancelled

---

## Test Case 6: AC-5 — Refuse to cancel Shipped order
**Given** an order with status Shipped  
**When** `cancelOrder()` is called  
**Then** cancellation is refused with error message "Shipped orders cannot be cancelled."  
**And** status remains Shipped

---

## Negative Test Cases (Edge Cases)

### NTC-1: Record payment on already Paid order
**Given** an order with status Paid  
**When** `recordPayment()` is called  
**Then** error or no-op (assumption: invalid transition)

### NTC-2: Mark Placed order as shipped (skip Paid)
**Given** an order with status Placed  
**When** `markShipped()` is called  
**Then** error or no-op (assumption: invalid transition)

### NTC-3: Confirm delivery on Paid order (skip Shipped)
**Given** an order with status Paid  
**When** `confirmDelivery()` is called  
**Then** error or no-op (assumption: invalid transition)

### NTC-4: Cancel Delivered order
**Given** an order with status Delivered  
**When** `cancelOrder()` is called  
**Then** error or no-op (assumption: Delivered orders are final)
