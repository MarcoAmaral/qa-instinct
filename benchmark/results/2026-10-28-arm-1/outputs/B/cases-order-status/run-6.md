# Test Cases for ORD-4: Order Status Changes

## Assumptions
- Order creation initializes status to "Placed" automatically
- Status transitions are persisted in the database
- Status transitions are idempotent (applying same transition multiple times is safe)
- Cancelled is a terminal state (no transitions from Cancelled)
- Status transitions are applied via dedicated API/method calls
- Timestamps are recorded with status changes
- Only valid transitions mentioned in AC are allowed; others are rejected

---

## Test Case 1: Order Created with Status Placed
**Objective:** Verify new orders initialize with "Placed" status

| Field | Value |
|-------|-------|
| ID | ORD-4.1 |
| Precondition | No order exists |
| Steps | 1. Create new order |
| Expected Result | Order status is "Placed" |
| Priority | High |

---

## Test Case 2: Record Payment on Placed Order
**Objective:** Verify AC-1 - payment transitions Placed → Paid

| Field | Value |
|-------|-------|
| ID | ORD-4.2 |
| Precondition | Order exists with status "Placed" |
| Steps | 1. Record payment on order |
| Expected Result | Order status changes to "Paid" |
| Priority | High |

---

## Test Case 3: Mark Paid Order as Shipped
**Objective:** Verify AC-2 - shipped transition changes Paid → Shipped

| Field | Value |
|-------|-------|
| ID | ORD-4.3 |
| Precondition | Order exists with status "Paid" |
| Steps | 1. Mark order as shipped |
| Expected Result | Order status changes to "Shipped" |
| Priority | High |

---

## Test Case 4: Confirm Delivery of Shipped Order
**Objective:** Verify AC-3 - delivery confirmation changes Shipped → Delivered

| Field | Value |
|-------|-------|
| ID | ORD-4.4 |
| Precondition | Order exists with status "Shipped" |
| Steps | 1. Confirm delivery of order |
| Expected Result | Order status changes to "Delivered" |
| Priority | High |

---

## Test Case 5: Cancel Placed Order
**Objective:** Verify AC-4 - Placed order can be cancelled

| Field | Value |
|-------|-------|
| ID | ORD-4.5 |
| Precondition | Order exists with status "Placed" |
| Steps | 1. Cancel order |
| Expected Result | Order status changes to "Cancelled" |
| Priority | High |

---

## Test Case 6: Cancel Paid Order
**Objective:** Verify AC-4 - Paid order can be cancelled

| Field | Value |
|-------|-------|
| ID | ORD-4.6 |
| Precondition | Order exists with status "Paid" |
| Steps | 1. Cancel order |
| Expected Result | Order status changes to "Cancelled" |
| Priority | High |

---

## Test Case 7: Cancel Shipped Order Rejected
**Objective:** Verify AC-5 - Shipped order cannot be cancelled

| Field | Value |
|-------|-------|
| ID | ORD-4.7 |
| Precondition | Order exists with status "Shipped" |
| Steps | 1. Attempt to cancel order |
| Expected Result | Cancellation rejected with error message "Shipped orders cannot be cancelled." |
| Priority | High |

---

## Test Case 8: Cancel Delivered Order Rejected
**Objective:** Verify terminal state behavior - Delivered order cannot be cancelled

| Field | Value |
|-------|-------|
| ID | ORD-4.8 |
| Precondition | Order exists with status "Delivered" |
| Steps | 1. Attempt to cancel order |
| Expected Result | Cancellation rejected |
| Priority | Medium |

---

## Test Case 9: Reject Payment Recording on Non-Placed Order
**Objective:** Verify invalid status transition - cannot record payment on Paid order

| Field | Value |
|-------|-------|
| ID | ORD-4.9 |
| Precondition | Order exists with status "Paid" |
| Steps | 1. Attempt to record payment |
| Expected Result | Payment recording rejected (order already paid) |
| Priority | Medium |

---

## Test Case 10: Reject Shipped Transition on Placed Order
**Objective:** Verify invalid status transition - cannot mark Placed order as shipped

| Field | Value |
|-------|-------|
| ID | ORD-4.10 |
| Precondition | Order exists with status "Placed" |
| Steps | 1. Attempt to mark order as shipped |
| Expected Result | Transition rejected (payment required first) |
| Priority | Medium |

---

## Test Case 11: Reject Delivery Confirmation on Paid Order
**Objective:** Verify invalid status transition - cannot confirm delivery on Paid order

| Field | Value |
|-------|-------|
| ID | ORD-4.11 |
| Precondition | Order exists with status "Paid" |
| Steps | 1. Attempt to confirm delivery |
| Expected Result | Transition rejected (shipment required first) |
| Priority | Medium |

---

## Test Case 12: Idempotent Status Transition
**Objective:** Verify recording payment twice on same order is safe

| Field | Value |
|-------|-------|
| ID | ORD-4.12 |
| Precondition | Order exists with status "Paid" (already transitioned once) |
| Steps | 1. Record payment again |
| Expected Result | Status remains "Paid"; no error or duplicate transaction |
| Priority | Medium |

---

## Test Case 13: Complete Happy Path
**Objective:** Verify full workflow from creation to delivery

| Field | Value |
|-------|-------|
| ID | ORD-4.13 |
| Precondition | No order exists |
| Steps | 1. Create order<br/>2. Record payment<br/>3. Mark shipped<br/>4. Confirm delivery |
| Expected Result | Order progresses: Placed → Paid → Shipped → Delivered |
| Priority | High |

---

## Test Case 14: Cancellation from Placed Prevents Further Transitions
**Objective:** Verify cancelled order is terminal state

| Field | Value |
|-------|-------|
| ID | ORD-4.14 |
| Precondition | Order exists with status "Cancelled" |
| Steps | 1. Attempt to record payment |
| Expected Result | Transition rejected |
| Priority | Medium |

---

## Test Case 15: Status Transition Persists Across Sessions
**Objective:** Verify status changes are durable in storage

| Field | Value |
|-------|-------|
| ID | ORD-4.15 |
| Precondition | Order exists with status "Paid" |
| Steps | 1. Record payment<br/>2. Close application/session<br/>3. Reopen and retrieve order |
| Expected Result | Order status is still "Paid" |
| Priority | High |
