# Test Cases for ORD-4: Order Status Changes

## Setup
Assume an `Order` entity with:
- `status` field (enum: Placed, Paid, Shipped, Delivered, Cancelled)
- Methods: `recordPayment()`, `markShipped()`, `confirmDelivery()`, `cancel()`
- `create()` factory that returns an Order with status=Placed

---

## AC-1: Recording Payment Changes Placed Order to Paid

**Test: Record payment on Placed order**
- Given: An order with status Placed
- When: recordPayment() is called
- Then: Order status is Paid

**Test: Recording payment is idempotent**
- Given: An order with status Paid
- When: recordPayment() is called
- Then: Order status remains Paid (or method handles gracefully)

---

## AC-2: Marking Paid Order as Shipped

**Test: Mark Paid order as shipped**
- Given: An order with status Paid
- When: markShipped() is called
- Then: Order status is Shipped

**Test: Cannot ship a Placed order**
- Given: An order with status Placed
- When: markShipped() is called
- Then: An error is raised or method fails gracefully

---

## AC-3: Confirming Delivery of Shipped Order

**Test: Confirm delivery of Shipped order**
- Given: An order with status Shipped
- When: confirmDelivery() is called
- Then: Order status is Delivered

**Test: Cannot confirm delivery of non-shipped order**
- Given: An order with status Paid
- When: confirmDelivery() is called
- Then: An error is raised or method fails gracefully

---

## AC-4: Placed or Paid Orders Can Be Cancelled

**Test: Cancel Placed order**
- Given: An order with status Placed
- When: cancel() is called
- Then: Order status is Cancelled

**Test: Cancel Paid order**
- Given: An order with status Paid
- When: cancel() is called
- Then: Order status is Cancelled

**Test: Cannot cancel Delivered order**
- Given: An order with status Delivered
- When: cancel() is called
- Then: An error is raised or method fails gracefully

---

## AC-5: Shipped Orders Cannot Be Cancelled

**Test: Refuse cancellation of Shipped order with error message**
- Given: An order with status Shipped
- When: cancel() is called
- Then: An error is raised with message "Shipped orders cannot be cancelled."

---

## End-to-End Status Flow

**Test: Happy path from Placed to Delivered**
- Given: A new order with status Placed
- When: recordPayment() is called, then markShipped(), then confirmDelivery()
- Then: Final status is Delivered

**Test: Happy path with cancellation after payment**
- Given: An order with status Placed
- When: recordPayment() is called, then cancel()
- Then: Final status is Cancelled
