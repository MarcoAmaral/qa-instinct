# Test Cases — ORD-4: Order status changes

## Assumptions

- **A1.** The status set is exactly: Placed, Paid, Shipped, Delivered, Cancelled. No other statuses exist.
- **A2.** Only the transitions listed in AC-1 to AC-4 are valid. Any other transition (e.g. shipping a Placed order, recording payment on a Shipped order) is refused and the status is unchanged. The story does not define the error text for these, so tests assert only that the action is refused and the status is unchanged.
- **A3.** Delivered and Cancelled are terminal. No action changes an order out of either state. Cancelling a Delivered or Cancelled order is refused (the story only specifies the Shipped message; the message for these is not asserted).
- **A4.** A refused action produces an error visible to the caller (UI message or API error response) and does not partially apply any change.
- **A5.** Status transitions are triggered through the operator interface or API; the test steps below are interface-neutral and name the action, not the button or endpoint.
- **A6.** Error text matching in AC-5 is exact, including the trailing period and capitalisation.
- **A7.** Status changes are persisted immediately and survive a reload or re-fetch of the order.

## Traceability

| Area | Test cases |
|---|---|
| Order creation (preamble) | TC-01 |
| AC-1 Placed → Paid | TC-02, TC-10, TC-11, TC-12, TC-13 |
| AC-2 Paid → Shipped | TC-03, TC-14, TC-15, TC-16, TC-17 |
| AC-3 Shipped → Delivered | TC-04, TC-18, TC-19, TC-20, TC-21 |
| AC-4 Cancel Placed / Paid | TC-05, TC-06 |
| AC-5 Cancel Shipped refused | TC-07, TC-08 |
| Terminal states | TC-09, TC-22, TC-23 |
| End-to-end / persistence | TC-24, TC-25 |

## Happy path

### TC-01: New order starts as Placed
- **Covers:** Story preamble
- **Preconditions:** Operator can create an order.
- **Steps:**
  1. Create a new order.
  2. View the order's status.
- **Expected:** Status is Placed.

### TC-02: Record payment on a Placed order
- **Covers:** AC-1
- **Preconditions:** An order in status Placed.
- **Steps:**
  1. Record a payment on the order.
  2. View the order's status.
- **Expected:** Status is Paid. No error is shown.

### TC-03: Mark a Paid order as shipped
- **Covers:** AC-2
- **Preconditions:** An order in status Paid.
- **Steps:**
  1. Mark the order as shipped.
  2. View the order's status.
- **Expected:** Status is Shipped. No error is shown.

### TC-04: Confirm delivery of a Shipped order
- **Covers:** AC-3
- **Preconditions:** An order in status Shipped.
- **Steps:**
  1. Confirm delivery of the order.
  2. View the order's status.
- **Expected:** Status is Delivered. No error is shown.

### TC-05: Cancel a Placed order
- **Covers:** AC-4
- **Preconditions:** An order in status Placed.
- **Steps:**
  1. Cancel the order.
  2. View the order's status.
- **Expected:** Status is Cancelled. No error is shown.

### TC-06: Cancel a Paid order
- **Covers:** AC-4
- **Preconditions:** An order in status Paid.
- **Steps:**
  1. Cancel the order.
  2. View the order's status.
- **Expected:** Status is Cancelled. No error is shown.

## Refused cancellation (AC-5)

### TC-07: Cancelling a Shipped order is refused with the exact message
- **Covers:** AC-5, A6
- **Preconditions:** An order in status Shipped.
- **Steps:**
  1. Cancel the order.
  2. Capture the error message.
  3. View the order's status.
- **Expected:** The action is refused. The message is exactly `Shipped orders cannot be cancelled.` Status remains Shipped.

### TC-08: Shipped order can still be delivered after a refused cancellation
- **Covers:** AC-5, AC-3, A4
- **Preconditions:** An order in status Shipped on which a cancel attempt has just been refused (TC-07).
- **Steps:**
  1. Confirm delivery of the order.
  2. View the order's status.
- **Expected:** Status is Delivered. The refused cancellation left no side effects that block the normal flow.

### TC-09: Cancelling a Delivered order is refused
- **Covers:** A3
- **Preconditions:** An order in status Delivered.
- **Steps:**
  1. Cancel the order.
  2. View the order's status.
- **Expected:** The action is refused. Status remains Delivered.

## Invalid transitions — recording payment

### TC-10: Record payment on a Paid order
- **Covers:** A2
- **Preconditions:** An order in status Paid.
- **Steps:**
  1. Record a payment on the order.
  2. View the order's status.
- **Expected:** The action is refused. Status remains Paid.

### TC-11: Record payment on a Shipped order
- **Covers:** A2
- **Preconditions:** An order in status Shipped.
- **Steps:**
  1. Record a payment on the order.
- **Expected:** The action is refused. Status remains Shipped.

### TC-12: Record payment on a Delivered order
- **Covers:** A2, A3
- **Preconditions:** An order in status Delivered.
- **Steps:**
  1. Record a payment on the order.
- **Expected:** The action is refused. Status remains Delivered.

### TC-13: Record payment on a Cancelled order
- **Covers:** A2, A3
- **Preconditions:** An order in status Cancelled.
- **Steps:**
  1. Record a payment on the order.
- **Expected:** The action is refused. Status remains Cancelled.

## Invalid transitions — marking as shipped

### TC-14: Mark a Placed order as shipped (skipping payment)
- **Covers:** A2
- **Preconditions:** An order in status Placed.
- **Steps:**
  1. Mark the order as shipped.
- **Expected:** The action is refused. Status remains Placed.

### TC-15: Mark a Shipped order as shipped
- **Covers:** A2
- **Preconditions:** An order in status Shipped.
- **Steps:**
  1. Mark the order as shipped.
- **Expected:** The action is refused. Status remains Shipped.

### TC-16: Mark a Delivered order as shipped
- **Covers:** A2, A3
- **Preconditions:** An order in status Delivered.
- **Steps:**
  1. Mark the order as shipped.
- **Expected:** The action is refused. Status remains Delivered.

### TC-17: Mark a Cancelled order as shipped
- **Covers:** A2, A3
- **Preconditions:** An order in status Cancelled.
- **Steps:**
  1. Mark the order as shipped.
- **Expected:** The action is refused. Status remains Cancelled.

## Invalid transitions — confirming delivery

### TC-18: Confirm delivery of a Placed order
- **Covers:** A2
- **Preconditions:** An order in status Placed.
- **Steps:**
  1. Confirm delivery of the order.
- **Expected:** The action is refused. Status remains Placed.

### TC-19: Confirm delivery of a Paid order (skipping shipment)
- **Covers:** A2
- **Preconditions:** An order in status Paid.
- **Steps:**
  1. Confirm delivery of the order.
- **Expected:** The action is refused. Status remains Paid.

### TC-20: Confirm delivery of a Delivered order
- **Covers:** A2, A3
- **Preconditions:** An order in status Delivered.
- **Steps:**
  1. Confirm delivery of the order.
- **Expected:** The action is refused. Status remains Delivered.

### TC-21: Confirm delivery of a Cancelled order
- **Covers:** A2, A3
- **Preconditions:** An order in status Cancelled.
- **Steps:**
  1. Confirm delivery of the order.
- **Expected:** The action is refused. Status remains Cancelled.

## Terminal states

### TC-22: Cancel an already Cancelled order
- **Covers:** A3
- **Preconditions:** An order in status Cancelled.
- **Steps:**
  1. Cancel the order.
- **Expected:** The action is refused. Status remains Cancelled.

### TC-23: Cancelled order cannot be revived by any action
- **Covers:** A3
- **Preconditions:** An order in status Cancelled.
- **Steps:**
  1. Attempt, in turn: record payment, mark as shipped, confirm delivery, cancel.
  2. View the order's status after each attempt.
- **Expected:** Every attempt is refused. Status remains Cancelled throughout.

## End-to-end and persistence

### TC-24: Full lifecycle in order
- **Covers:** Preamble, AC-1, AC-2, AC-3
- **Preconditions:** Operator can create an order.
- **Steps:**
  1. Create an order. Verify status is Placed.
  2. Record payment. Verify status is Paid.
  3. Mark as shipped. Verify status is Shipped.
  4. Confirm delivery. Verify status is Delivered.
- **Expected:** Each step succeeds and the status shown at each step matches the expected value. Final status is Delivered.

### TC-25: Status changes persist across reload
- **Covers:** A7
- **Preconditions:** An order in status Placed.
- **Steps:**
  1. Record payment on the order.
  2. Reload the order (refresh the page, or re-fetch via API in a new session).
  3. View the order's status.
- **Expected:** Status is Paid after reload.

## Transition matrix (summary of expected outcomes)

| Current status | Record payment | Mark shipped | Confirm delivery | Cancel |
|---|---|---|---|---|
| Placed | → Paid (TC-02) | Refused (TC-14) | Refused (TC-18) | → Cancelled (TC-05) |
| Paid | Refused (TC-10) | → Shipped (TC-03) | Refused (TC-19) | → Cancelled (TC-06) |
| Shipped | Refused (TC-11) | Refused (TC-15) | → Delivered (TC-04) | Refused, exact message (TC-07) |
| Delivered | Refused (TC-12) | Refused (TC-16) | Refused (TC-20) | Refused (TC-09) |
| Cancelled | Refused (TC-13) | Refused (TC-17) | Refused (TC-21) | Refused (TC-22) |

## Open questions for the product owner (not blocking)

- What error message, if any, should be shown for refused transitions other than cancelling a Shipped order (A2, A3)?
- Should cancelling a Paid order trigger a refund? The story does not mention it, so these tests do not assert on payment side effects.
- Is a status history or audit trail required? Not covered here.
- Are there role restrictions on who may perform each transition? Not covered here.
