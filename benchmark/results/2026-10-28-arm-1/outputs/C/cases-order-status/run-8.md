# Test Cases for ORD-4: Order Status Changes

**Assumptions:**
- Orders start in "Placed" status when created
- Status transitions are one-way and sequential unless explicitly allowed
- "Recording a payment" means marking a payment as received/confirmed
- "Marking as shipped" is performed by store staff
- "Confirming delivery" is performed by staff or customer
- Only the stated transitions are allowed; all others are rejected

---

## TC-01: Order Created in Placed Status
**Given:** A new order is created
**When:** The order is initialized
**Then:** The order status is "Placed"

---

## TC-02: Placed Order → Paid (Payment Recorded)
**Given:** An order with status "Placed"
**When:** A payment is recorded on the order
**Then:** The order status changes to "Paid"

---

## TC-03: Paid Order → Shipped (Mark as Shipped)
**Given:** An order with status "Paid"
**When:** The order is marked as shipped
**Then:** The order status changes to "Shipped"

---

## TC-04: Shipped Order → Delivered (Confirm Delivery)
**Given:** An order with status "Shipped"
**When:** Delivery is confirmed
**Then:** The order status changes to "Delivered"

---

## TC-05: Placed Order Cancellation
**Given:** An order with status "Placed"
**When:** The order is cancelled
**Then:** The order status changes to "Cancelled"

---

## TC-06: Paid Order Cancellation
**Given:** An order with status "Paid"
**When:** The order is cancelled
**Then:** The order status changes to "Cancelled"

---

## TC-07: Shipped Order Cancellation Refused
**Given:** An order with status "Shipped"
**When:** An attempt is made to cancel the order
**Then:** The cancellation is refused with the message "Shipped orders cannot be cancelled."
**And:** The order status remains "Shipped"

---

## TC-08: Delivered Order Cancellation Refused
**Given:** An order with status "Delivered"
**When:** An attempt is made to cancel the order
**Then:** The cancellation is refused (no transition defined)
**And:** The order status remains "Delivered"

---

## TC-09: Cancelled Order Has No Further Transitions
**Given:** An order with status "Cancelled"
**When:** An attempt is made to record a payment, ship, or confirm delivery
**Then:** All transitions are refused
**And:** The order status remains "Cancelled"

---

## TC-10: Skip Intermediate Status (Paid → Shipped Requires Paid State)
**Given:** An order with status "Placed"
**When:** An attempt is made to mark the order as shipped without recording payment first
**Then:** The transition is refused
**And:** The order status remains "Placed"

---

## TC-11: Payment on Already-Paid Order
**Given:** An order with status "Paid"
**When:** Another payment is recorded
**Then:** The status remains "Paid" or the action is refused (duplicate payment handling)

---

## TC-12: Multiple Status Transitions in Sequence
**Given:** A new order in "Placed" status
**When:** Payment is recorded, then marked as shipped, then delivery is confirmed in sequence
**Then:** The order transitions through Placed → Paid → Shipped → Delivered
**And:** The final status is "Delivered"
