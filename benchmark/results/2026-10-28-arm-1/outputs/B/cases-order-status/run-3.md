# Test Cases for ORD-4: Order Status Changes

## Assumptions
- Orders are identified by a unique Order ID
- Status transitions are atomic operations
- Only one status can be active per order at any time
- Timestamps are recorded for each status change
- Store operators have authorization to perform all status transitions
- System prevents invalid transitions with appropriate error messages

---

## TC-1: Order Creation with Initial Status
**Priority:** Critical  
**Acceptance Criteria:** Initial state requirement

| Field | Value |
|-------|-------|
| **Objective** | Verify new orders are created with "Placed" status |
| **Preconditions** | System is operational |
| **Steps** | 1. Create a new order via system interface<br>2. Retrieve order details<br>3. Verify status field |
| **Expected Result** | Order status is "Placed" upon creation |

---

## TC-2: Record Payment on Placed Order (AC-1)
**Priority:** Critical  
**Acceptance Criteria:** AC-1

| Field | Value |
|-------|-------|
| **Objective** | Verify payment recording changes Placed order to Paid |
| **Preconditions** | Order exists with status "Placed" |
| **Steps** | 1. Select order in system<br>2. Click "Record Payment"<br>3. Enter payment details (amount, method)<br>4. Confirm transaction<br>5. Retrieve order status |
| **Expected Result** | Order status changes to "Paid"; payment record is created with timestamp |

---

## TC-3: Mark Paid Order as Shipped (AC-2)
**Priority:** Critical  
**Acceptance Criteria:** AC-2

| Field | Value |
|-------|-------|
| **Objective** | Verify marking Paid order as shipped changes status to Shipped |
| **Preconditions** | Order exists with status "Paid" |
| **Steps** | 1. Select order in system<br>2. Click "Mark as Shipped"<br>3. Enter tracking number (optional)<br>4. Confirm shipment<br>5. Retrieve order status |
| **Expected Result** | Order status changes to "Shipped"; shipment timestamp is recorded |

---

## TC-4: Confirm Delivery of Shipped Order (AC-3)
**Priority:** Critical  
**Acceptance Criteria:** AC-3

| Field | Value |
|-------|-------|
| **Objective** | Verify confirming delivery of Shipped order changes status to Delivered |
| **Preconditions** | Order exists with status "Shipped" |
| **Steps** | 1. Select order in system<br>2. Click "Confirm Delivery"<br>3. Enter delivery confirmation details<br>4. Confirm action<br>5. Retrieve order status |
| **Expected Result** | Order status changes to "Delivered"; delivery timestamp is recorded |

---

## TC-5: Cancel Placed Order (AC-4)
**Priority:** Critical  
**Acceptance Criteria:** AC-4

| Field | Value |
|-------|-------|
| **Objective** | Verify Placed order can be cancelled and status changes to Cancelled |
| **Preconditions** | Order exists with status "Placed" |
| **Steps** | 1. Select order in system<br>2. Click "Cancel Order"<br>3. Enter cancellation reason (optional)<br>4. Confirm cancellation<br>5. Retrieve order status |
| **Expected Result** | Order status changes to "Cancelled"; cancellation timestamp is recorded |

---

## TC-6: Cancel Paid Order (AC-4)
**Priority:** Critical  
**Acceptance Criteria:** AC-4

| Field | Value |
|-------|-------|
| **Objective** | Verify Paid order can be cancelled and status changes to Cancelled |
| **Preconditions** | Order exists with status "Paid" |
| **Steps** | 1. Select order in system<br>2. Click "Cancel Order"<br>3. Enter cancellation reason<br>4. Confirm cancellation<br>5. Retrieve order status |
| **Expected Result** | Order status changes to "Cancelled"; cancellation timestamp and refund record are created |

---

## TC-7: Attempt to Cancel Shipped Order (AC-5)
**Priority:** Critical  
**Acceptance Criteria:** AC-5

| Field | Value |
|-------|-------|
| **Objective** | Verify Shipped orders cannot be cancelled |
| **Preconditions** | Order exists with status "Shipped" |
| **Steps** | 1. Select order in system<br>2. Click "Cancel Order"<br>3. Attempt to confirm cancellation |
| **Expected Result** | System displays error message: "Shipped orders cannot be cancelled."<br>Order status remains "Shipped"<br>No cancellation record is created |

---

## TC-8: Attempt to Cancel Delivered Order
**Priority:** High  
**Acceptance Criteria:** Related to AC-5 scope

| Field | Value |
|-------|-------|
| **Objective** | Verify Delivered orders cannot be cancelled |
| **Preconditions** | Order exists with status "Delivered" |
| **Steps** | 1. Select order in system<br>2. Attempt to click "Cancel Order" or call cancel API |
| **Expected Result** | Cancel option is unavailable or system returns error message; order status remains "Delivered" |

---

## TC-9: Attempt Invalid State Transition (Paid → Shipped without proper step)
**Priority:** Medium  
**Acceptance Criteria:** State machine validation

| Field | Value |
|-------|-------|
| **Objective** | Verify system enforces proper state transitions |
| **Preconditions** | Order exists with status "Paid" |
| **Steps** | 1. Attempt to manually set order status to "Delivered" without going through "Shipped"<br>2. Try API call or direct database manipulation if applicable |
| **Expected Result** | System prevents the transition; displays appropriate error message; status remains "Paid" |

---

## TC-10: Attempt Payment Recording on Non-Placed Order
**Priority:** Medium  
**Acceptance Criteria:** Related to AC-1

| Field | Value |
|-------|-------|
| **Objective** | Verify payment recording is restricted to Placed orders |
| **Preconditions** | Order exists with status "Shipped" or "Delivered" or "Cancelled" |
| **Steps** | 1. Select order in system<br>2. Attempt to click "Record Payment" or call payment API |
| **Expected Result** | Payment recording option is unavailable or system returns error; order status unchanged |

---

## TC-11: Complete Order Lifecycle (Happy Path)
**Priority:** Critical  
**Acceptance Criteria:** All ACs

| Field | Value |
|-------|-------|
| **Objective** | Verify full order journey: Placed → Paid → Shipped → Delivered |
| **Preconditions** | System is operational; new order can be created |
| **Steps** | 1. Create new order (status: Placed)<br>2. Record payment (status: Paid)<br>3. Mark as shipped (status: Shipped)<br>4. Confirm delivery (status: Delivered)<br>5. Retrieve final order record |
| **Expected Result** | Order progresses through all four states in sequence; all timestamps recorded; no errors during transitions |

---

## TC-12: Multiple Payment Attempts on Placed Order
**Priority:** Medium  
**Acceptance Criteria:** Related to AC-1

| Field | Value |
|-------|-------|
| **Objective** | Verify handling of multiple payment recordings |
| **Preconditions** | Order exists with status "Placed" |
| **Steps** | 1. Record first payment (full or partial amount)<br>2. Attempt to record second payment before order moves to Paid<br>3. Verify final status and payment records |
| **Expected Result** | System either: (a) accepts multiple payments until target amount reached, or (b) prevents second payment and returns error; final status is Paid only once |

---

## TC-13: Status Change Audit Trail
**Priority:** High  
**Acceptance Criteria:** Data integrity and traceability

| Field | Value |
|-------|-------|
| **Objective** | Verify all status changes are logged with timestamp and user info |
| **Preconditions** | Order has undergone at least 2 status changes |
| **Steps** | 1. Navigate to order history/audit log<br>2. Review all recorded status transitions |
| **Expected Result** | Each status change is logged with: previous status, new status, timestamp, and operator ID (if applicable) |

---

## TC-14: Concurrent Status Change Attempts
**Priority:** Medium  
**Acceptance Criteria:** Concurrency handling

| Field | Value |
|-------|-------|
| **Objective** | Verify system handles concurrent requests safely |
| **Preconditions** | Order exists with status "Placed" |
| **Steps** | 1. Simulate two simultaneous requests: one to record payment, one to cancel order<br>2. Observe which transaction completes first<br>3. Verify final order status |
| **Expected Result** | Only one operation succeeds; system maintains data consistency; final status is either "Paid" or "Cancelled", not both |

---

## TC-15: Cancel Order with Reason Recording
**Priority:** Medium  
**Acceptance Criteria:** Related to AC-4

| Field | Value |
|-------|-------|
| **Objective** | Verify cancellation reason is captured and stored |
| **Preconditions** | Order exists with status "Placed" or "Paid" |
| **Steps** | 1. Select order<br>2. Click "Cancel Order"<br>3. Enter cancellation reason (e.g., "Customer request", "Out of stock")<br>4. Confirm cancellation<br>5. Retrieve order details |
| **Expected Result** | Order status is "Cancelled"; cancellation reason is stored and retrievable |
