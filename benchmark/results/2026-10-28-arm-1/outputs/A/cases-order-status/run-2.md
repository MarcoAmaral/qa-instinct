# Test Cases for ORD-4: Order Status Changes

## Assumptions
- Orders are created through an API or system that initializes status to "Placed"
- Status changes are triggered through specific operations (record payment, mark shipped, confirm delivery, cancel)
- The system validates transitions and rejects invalid ones
- Status values are: Placed, Paid, Shipped, Delivered, Cancelled
- Error responses return appropriate HTTP status codes (e.g., 400 for invalid operation)

---

## TC-1: Order Created with Placed Status
**Objective:** Verify new orders are initialized with Placed status

**Given:** A new order is created
**When:** The order is retrieved
**Then:** Status equals "Placed"

---

## TC-2: Record Payment on Placed Order
**Objective:** Verify payment recording transitions Placed → Paid

**Given:** An order exists with status "Placed"
**When:** Payment is recorded on the order
**Then:** Status changes to "Paid"
**And:** Payment details are stored with the order

---

## TC-3: Mark Paid Order as Shipped
**Objective:** Verify shipping transition from Paid → Shipped

**Given:** An order exists with status "Paid"
**When:** The order is marked as shipped
**Then:** Status changes to "Shipped"
**And:** Shipping timestamp is recorded

---

## TC-4: Confirm Delivery of Shipped Order
**Objective:** Verify delivery confirmation transitions Shipped → Delivered

**Given:** An order exists with status "Shipped"
**When:** Delivery is confirmed
**Then:** Status changes to "Delivered"
**And:** Delivery timestamp is recorded

---

## TC-5: Cancel Placed Order
**Objective:** Verify cancellation of Placed orders

**Given:** An order exists with status "Placed"
**When:** The order is cancelled
**Then:** Status changes to "Cancelled"
**And:** Cancellation timestamp is recorded

---

## TC-6: Cancel Paid Order
**Objective:** Verify cancellation of Paid orders

**Given:** An order exists with status "Paid"
**When:** The order is cancelled
**Then:** Status changes to "Cancelled"
**And:** Cancellation reason is stored

---

## TC-7: Attempt to Cancel Shipped Order
**Objective:** Verify cancellation of Shipped orders is rejected

**Given:** An order exists with status "Shipped"
**When:** Cancellation is attempted
**Then:** Operation fails with error message "Shipped orders cannot be cancelled."
**And:** Status remains "Shipped"

---

## TC-8: Attempt to Cancel Delivered Order
**Objective:** Verify cancellation of Delivered orders is rejected

**Given:** An order exists with status "Delivered"
**When:** Cancellation is attempted
**Then:** Operation fails (assumed invalid transition)
**And:** Status remains "Delivered"

---

## TC-9: Invalid Transition - Payment on Already Paid Order
**Objective:** Verify duplicate payment is rejected

**Given:** An order exists with status "Paid"
**When:** Payment recording is attempted again
**Then:** Operation fails (assumed invalid transition)
**And:** Status remains "Paid"

---

## TC-10: Invalid Transition - Ship Before Payment
**Objective:** Verify shipping cannot occur on Placed order

**Given:** An order exists with status "Placed"
**When:** Attempt to mark as shipped without payment
**Then:** Operation fails (assumed invalid transition)
**And:** Status remains "Placed"

---

## TC-11: Complete Order Lifecycle
**Objective:** Verify full happy path: Placed → Paid → Shipped → Delivered

**Given:** A new order is created
**When:** Payment is recorded
**Then:** Status is "Paid"
**When:** Order is marked shipped
**Then:** Status is "Shipped"
**When:** Delivery is confirmed
**Then:** Status is "Delivered"
**And:** All timestamps are recorded in chronological order

---

## TC-12: Complete Order Lifecycle with Cancellation
**Objective:** Verify cancellation path: Placed → Paid → Cancelled

**Given:** A new order is created
**When:** Payment is recorded (status: "Paid")
**And:** Order is cancelled
**Then:** Status is "Cancelled"
**And:** Previous status transition is logged
