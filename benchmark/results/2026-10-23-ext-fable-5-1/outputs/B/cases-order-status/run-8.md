# Test Cases: ORD-4 Order Status Changes

## Assumptions

- **A1:** Only the transitions named in AC-1 to AC-5 are valid. Any transition not listed (for example, shipping a Placed order) is refused and the status is unchanged. Delivered and Cancelled are terminal states.
- **A2:** Refusals of unlisted transitions return a generic error of the form "Order cannot be <action> from status <Status>." Exact wording is a stand-in and should be confirmed with the product owner.
- **A3:** Status values are the exact strings `Placed`, `Paid`, `Shipped`, `Delivered`, `Cancelled`.
- **A4:** Status is readable through the same interface used by store operators and by the customer-facing order view, so both see the same value.
- **A5:** Transitions are triggered by discrete actions: "record payment", "mark shipped", "confirm delivery", "cancel". The channel (UI, API) is not specified; tests are written to be channel-neutral.
- **A6:** Each transition is atomic. A refused transition leaves the order fully unchanged.

## Preconditions (common)

- A store operator account with permission to change order status exists and is authenticated.
- A product and a customer exist so that orders can be created.
- Helpers are available to create an order and advance it to a given status through the valid path.

---

## Section 1: Order creation

### TC-01 New order starts in Placed
- **Covers:** Story preamble
- **Steps:**
  1. Create a new order.
  2. Read the order's status.
- **Expected:** Status is `Placed`.

### TC-02 Newly created order shows Placed to both operator and customer
- **Covers:** Story goal, A4
- **Steps:**
  1. Create an order for a customer.
  2. View the order as the store operator.
  3. View the same order as the customer.
- **Expected:** Both views show `Placed`.

---

## Section 2: Happy-path transitions

### TC-03 Record payment on Placed order
- **Covers:** AC-1
- **Steps:**
  1. Create an order (status `Placed`).
  2. Record a payment against it.
  3. Read the status.
- **Expected:** Status is `Paid`. No error is returned.

### TC-04 Mark Paid order as shipped
- **Covers:** AC-2
- **Steps:**
  1. Create an order and record payment (status `Paid`).
  2. Mark the order as shipped.
  3. Read the status.
- **Expected:** Status is `Shipped`.

### TC-05 Confirm delivery of Shipped order
- **Covers:** AC-3
- **Steps:**
  1. Create an order, record payment, mark shipped (status `Shipped`).
  2. Confirm delivery.
  3. Read the status.
- **Expected:** Status is `Delivered`.

### TC-06 Full lifecycle Placed to Delivered
- **Covers:** AC-1, AC-2, AC-3 end to end
- **Steps:**
  1. Create an order and read status.
  2. Record payment and read status.
  3. Mark shipped and read status.
  4. Confirm delivery and read status.
- **Expected:** Status sequence is exactly `Placed`, `Paid`, `Shipped`, `Delivered`, with no intermediate or skipped values.

### TC-07 Each transition is visible to the customer immediately after
- **Covers:** Story goal, A4
- **Steps:**
  1. Create an order. View as customer.
  2. Record payment. View as customer.
  3. Mark shipped. View as customer.
  4. Confirm delivery. View as customer.
- **Expected:** Customer view shows `Placed`, `Paid`, `Shipped`, `Delivered` respectively after each step.

---

## Section 3: Cancellation

### TC-08 Cancel a Placed order
- **Covers:** AC-4
- **Steps:**
  1. Create an order (status `Placed`).
  2. Cancel the order.
  3. Read the status.
- **Expected:** Status is `Cancelled`. No error is returned.

### TC-09 Cancel a Paid order
- **Covers:** AC-4
- **Steps:**
  1. Create an order and record payment (status `Paid`).
  2. Cancel the order.
  3. Read the status.
- **Expected:** Status is `Cancelled`.

### TC-10 Cancelling a Shipped order is refused
- **Covers:** AC-5
- **Steps:**
  1. Create an order, record payment, mark shipped (status `Shipped`).
  2. Attempt to cancel the order.
  3. Read the status.
- **Expected:** The cancel is refused with the exact message:
  ```
  Shipped orders cannot be cancelled.
  ```
  Status remains `Shipped`.

### TC-11 Refusal message text is exact
- **Covers:** AC-5
- **Steps:**
  1. Reproduce TC-10.
  2. Compare the returned message character for character against the specified text.
- **Expected:** Message matches exactly, including capitalisation and trailing full stop. No extra prefix, suffix, or whitespace.

### TC-12 Cancelling a Delivered order is refused
- **Covers:** A1 (Delivered is terminal)
- **Steps:**
  1. Advance an order to `Delivered`.
  2. Attempt to cancel.
  3. Read the status.
- **Expected:** Cancel is refused. Status remains `Delivered`. Note: the AC-5 message refers to Shipped orders only. Confirm with product owner whether the Delivered case reuses that text or a different one (see Open Questions).

### TC-13 Cancelling an already Cancelled order
- **Covers:** A1 (Cancelled is terminal)
- **Steps:**
  1. Create an order and cancel it (status `Cancelled`).
  2. Attempt to cancel again.
  3. Read the status.
- **Expected:** Request is refused (or treated as a no-op, per A1 and Open Questions). Status remains `Cancelled`. The order is not cancelled twice and no duplicate cancellation record is created.

---

## Section 4: Invalid transitions (negative)

Each case: perform the action from the stated starting status, then verify the action is refused and the status is unchanged.

| ID | Starting status | Action | Expected |
|---|---|---|---|
| TC-14 | Placed | Mark shipped | Refused, status stays `Placed` |
| TC-15 | Placed | Confirm delivery | Refused, status stays `Placed` |
| TC-16 | Paid | Record payment | Refused, status stays `Paid` |
| TC-17 | Paid | Confirm delivery | Refused, status stays `Paid` |
| TC-18 | Shipped | Record payment | Refused, status stays `Shipped` |
| TC-19 | Shipped | Mark shipped | Refused, status stays `Shipped` |
| TC-20 | Delivered | Record payment | Refused, status stays `Delivered` |
| TC-21 | Delivered | Mark shipped | Refused, status stays `Delivered` |
| TC-22 | Delivered | Confirm delivery | Refused, status stays `Delivered` |
| TC-23 | Cancelled | Record payment | Refused, status stays `Cancelled` |
| TC-24 | Cancelled | Mark shipped | Refused, status stays `Cancelled` |
| TC-25 | Cancelled | Confirm delivery | Refused, status stays `Cancelled` |

- **Covers:** A1, A2. For each refused case, the error should identify the problem clearly and must not be a generic server failure.

---

## Section 5: Robustness and data integrity

### TC-26 Refused transition leaves the order fully unchanged
- **Covers:** A6
- **Steps:**
  1. Advance an order to `Shipped` and capture a full snapshot of the order record.
  2. Attempt to cancel (refused per AC-5).
  3. Capture a second snapshot.
- **Expected:** Snapshots are identical. No status, timestamp, or audit field changed.

### TC-27 Status transition is persisted
- **Covers:** AC-1 to AC-4
- **Steps:**
  1. Create an order and record payment.
  2. Re-read the order through a fresh session or a direct store lookup.
- **Expected:** Status is `Paid` after re-read, not just in the in-memory response.

### TC-28 Transitions on one order do not affect another
- **Covers:** Isolation
- **Steps:**
  1. Create orders A and B (both `Placed`).
  2. Record payment on A.
  3. Read status of B.
- **Expected:** A is `Paid`. B is still `Placed`.

### TC-29 Concurrent conflicting actions on the same order
- **Covers:** A6, race safety
- **Steps:**
  1. Advance an order to `Paid`.
  2. Simultaneously submit "mark shipped" and "cancel" for the same order.
  3. Read the final status.
- **Expected:** Exactly one action succeeds. Final status is either `Shipped` or `Cancelled`, never a mixed or undefined state. The losing request receives a refusal consistent with the final status (for example, if shipping won, the cancel is refused with the AC-5 message).

### TC-30 Transition on a non-existent order
- **Covers:** Input validation
- **Steps:**
  1. Attempt to record payment against an order ID that does not exist.
- **Expected:** A clear "order not found" style error. No order is created.

### TC-31 Status value is one of the fixed set only
- **Covers:** Story goal ("fixed set of statuses")
- **Steps:**
  1. Exercise every transition in Sections 2 and 3.
  2. Collect every status value observed.
- **Expected:** Only `Placed`, `Paid`, `Shipped`, `Delivered`, `Cancelled` are ever observed. No other value, no empty value, no case variation.

### TC-32 Status cannot be set directly to an arbitrary value
- **Covers:** A1, A3
- **Steps:**
  1. Create an order.
  2. Attempt to set status directly to `Delivered` (bypassing the Paid and Shipped actions), if the interface exposes any direct-write path.
  3. Attempt to set status to a value outside the set, for example `Refunded`.
- **Expected:** Both attempts are refused. Status remains `Placed`.

---

## Traceability

| Acceptance criterion | Test cases |
|---|---|
| Created as Placed | TC-01, TC-02 |
| AC-1 Placed to Paid | TC-03, TC-06, TC-07, TC-27 |
| AC-2 Paid to Shipped | TC-04, TC-06, TC-07 |
| AC-3 Shipped to Delivered | TC-05, TC-06, TC-07 |
| AC-4 Cancel Placed or Paid | TC-08, TC-09 |
| AC-5 Refuse cancel of Shipped | TC-10, TC-11, TC-26, TC-29 |
| Fixed status set / invalid transitions (assumed) | TC-12 to TC-25, TC-31, TC-32 |
| Integrity and isolation | TC-26 to TC-30 |

## Open questions for the product owner

- Should cancelling a Delivered order reuse the AC-5 message or a distinct one? TC-12 assumes a distinct refusal.
- Is cancelling an already Cancelled order an error or a silent no-op? TC-13 accepts either but must be pinned down.
- Is there any legitimate path back from Delivered or Cancelled (for example, returns or reinstatement)? Tests assume both are terminal.
