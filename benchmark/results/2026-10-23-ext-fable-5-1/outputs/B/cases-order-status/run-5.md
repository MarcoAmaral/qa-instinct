# Test Cases — ORD-4: Order status changes

## Assumptions

- A1: Statuses are exactly `Placed`, `Paid`, `Shipped`, `Delivered`, `Cancelled`. No other statuses exist.
- A2: Transitions not listed in the acceptance criteria are refused and leave the status unchanged. The story only specifies the refusal message for cancelling a Shipped order, so for other invalid transitions these tests assert only that the status does not change and an error is returned, not the message text.
- A3: Delivered and Cancelled are terminal. No transition leaves them.
- A4: Each transition is exposed as a distinct operation: record payment, mark shipped, confirm delivery, cancel. These tests are written against that interface, whether it is an API, a UI action, or a service method.
- A5: A refused transition is reported as an error to the caller and is not silently ignored.
- A6: The order's status is persisted and the same value is returned on re-read after any operation.
- A7: Order creation itself is in scope only as far as the initial status is concerned.

## Traceability

| AC | Test cases |
|---|---|
| Initial status | TC-01 |
| AC-1 | TC-02, TC-10, TC-11, TC-12, TC-13 |
| AC-2 | TC-03, TC-14, TC-15, TC-16, TC-17 |
| AC-3 | TC-04, TC-18, TC-19, TC-20, TC-21 |
| AC-4 | TC-05, TC-06, TC-22, TC-23 |
| AC-5 | TC-07, TC-08 |
| Full lifecycle | TC-09 |
| Idempotency / repeat calls | TC-24, TC-25 |
| Persistence / concurrency | TC-26, TC-27 |

---

## Positive path

### TC-01: New order has status Placed
- **Covers:** Story preamble
- **Preconditions:** None.
- **Steps:**
  1. Create a new order.
  2. Read the order's status.
- **Expected:** Status is `Placed`.

### TC-02: Payment on Placed order moves it to Paid
- **Covers:** AC-1
- **Preconditions:** Order exists with status `Placed`.
- **Steps:**
  1. Record a payment on the order.
  2. Read the order's status.
- **Expected:** Operation succeeds. Status is `Paid`.

### TC-03: Shipping a Paid order moves it to Shipped
- **Covers:** AC-2
- **Preconditions:** Order exists with status `Paid`.
- **Steps:**
  1. Mark the order as shipped.
  2. Read the order's status.
- **Expected:** Operation succeeds. Status is `Shipped`.

### TC-04: Confirming delivery of a Shipped order moves it to Delivered
- **Covers:** AC-3
- **Preconditions:** Order exists with status `Shipped`.
- **Steps:**
  1. Confirm delivery of the order.
  2. Read the order's status.
- **Expected:** Operation succeeds. Status is `Delivered`.

### TC-05: Cancelling a Placed order moves it to Cancelled
- **Covers:** AC-4
- **Preconditions:** Order exists with status `Placed`.
- **Steps:**
  1. Cancel the order.
  2. Read the order's status.
- **Expected:** Operation succeeds. Status is `Cancelled`.

### TC-06: Cancelling a Paid order moves it to Cancelled
- **Covers:** AC-4
- **Preconditions:** Order exists with status `Paid`.
- **Steps:**
  1. Cancel the order.
  2. Read the order's status.
- **Expected:** Operation succeeds. Status is `Cancelled`.

### TC-07: Cancelling a Shipped order is refused with the specified message
- **Covers:** AC-5
- **Preconditions:** Order exists with status `Shipped`.
- **Steps:**
  1. Cancel the order.
  2. Read the order's status.
- **Expected:** Operation is refused. Error message is exactly `Shipped orders cannot be cancelled.` (including the trailing full stop). Status remains `Shipped`.

### TC-08: Refused cancellation of Shipped order does not block later delivery
- **Covers:** AC-5, AC-3
- **Preconditions:** Order exists with status `Shipped`.
- **Steps:**
  1. Cancel the order (expect refusal per TC-07).
  2. Confirm delivery of the order.
  3. Read the order's status.
- **Expected:** Step 2 succeeds. Status is `Delivered`. The failed cancel leaves no residual state that interferes with the normal path.

### TC-09: Full happy-path lifecycle
- **Covers:** Preamble, AC-1, AC-2, AC-3
- **Preconditions:** None.
- **Steps:**
  1. Create an order; verify status `Placed`.
  2. Record payment; verify status `Paid`.
  3. Mark shipped; verify status `Shipped`.
  4. Confirm delivery; verify status `Delivered`.
- **Expected:** Each step succeeds and the status at each checkpoint is as listed. No step is skipped or merged.

---

## Negative path: invalid transitions

Per A2, each of these expects the operation to be refused and the status to be unchanged.

### TC-10: Payment on a Paid order is refused
- **Covers:** AC-1 (boundary)
- **Preconditions:** Order with status `Paid`.
- **Steps:** Record a payment. Read status.
- **Expected:** Refused. Status remains `Paid`.

### TC-11: Payment on a Shipped order is refused
- **Preconditions:** Order with status `Shipped`.
- **Steps:** Record a payment. Read status.
- **Expected:** Refused. Status remains `Shipped`.

### TC-12: Payment on a Delivered order is refused
- **Preconditions:** Order with status `Delivered`.
- **Steps:** Record a payment. Read status.
- **Expected:** Refused. Status remains `Delivered`.

### TC-13: Payment on a Cancelled order is refused
- **Preconditions:** Order with status `Cancelled`.
- **Steps:** Record a payment. Read status.
- **Expected:** Refused. Status remains `Cancelled`.

### TC-14: Shipping a Placed (unpaid) order is refused
- **Covers:** AC-2 (boundary)
- **Preconditions:** Order with status `Placed`.
- **Steps:** Mark shipped. Read status.
- **Expected:** Refused. Status remains `Placed`. An order must not ship before payment.

### TC-15: Shipping a Shipped order is refused
- **Preconditions:** Order with status `Shipped`.
- **Steps:** Mark shipped. Read status.
- **Expected:** Refused. Status remains `Shipped`.

### TC-16: Shipping a Delivered order is refused
- **Preconditions:** Order with status `Delivered`.
- **Steps:** Mark shipped. Read status.
- **Expected:** Refused. Status remains `Delivered`.

### TC-17: Shipping a Cancelled order is refused
- **Preconditions:** Order with status `Cancelled`.
- **Steps:** Mark shipped. Read status.
- **Expected:** Refused. Status remains `Cancelled`.

### TC-18: Confirming delivery of a Placed order is refused
- **Covers:** AC-3 (boundary)
- **Preconditions:** Order with status `Placed`.
- **Steps:** Confirm delivery. Read status.
- **Expected:** Refused. Status remains `Placed`.

### TC-19: Confirming delivery of a Paid order is refused
- **Preconditions:** Order with status `Paid`.
- **Steps:** Confirm delivery. Read status.
- **Expected:** Refused. Status remains `Paid`.

### TC-20: Confirming delivery of a Delivered order is refused
- **Preconditions:** Order with status `Delivered`.
- **Steps:** Confirm delivery. Read status.
- **Expected:** Refused. Status remains `Delivered`.

### TC-21: Confirming delivery of a Cancelled order is refused
- **Preconditions:** Order with status `Cancelled`.
- **Steps:** Confirm delivery. Read status.
- **Expected:** Refused. Status remains `Cancelled`.

### TC-22: Cancelling a Delivered order is refused
- **Covers:** AC-4 (boundary), A3
- **Preconditions:** Order with status `Delivered`.
- **Steps:** Cancel. Read status.
- **Expected:** Refused. Status remains `Delivered`. Note: the story does not specify the message for this case; the AC-5 message would be misleading here, so verify the message, if any, does not say "Shipped orders cannot be cancelled."

### TC-23: Cancelling a Cancelled order is refused
- **Covers:** AC-4 (boundary), A3
- **Preconditions:** Order with status `Cancelled`.
- **Steps:** Cancel. Read status.
- **Expected:** Refused. Status remains `Cancelled`.

---

## Repeated and out-of-order operations

### TC-24: Repeated invalid cancel on Shipped order is consistently refused
- **Covers:** AC-5
- **Preconditions:** Order with status `Shipped`.
- **Steps:**
  1. Cancel the order three times in succession.
  2. Read status after each attempt.
- **Expected:** Every attempt is refused with `Shipped orders cannot be cancelled.` Status is `Shipped` after each.

### TC-25: Skipping a step is not possible
- **Covers:** AC-1 to AC-3
- **Preconditions:** Order with status `Placed`.
- **Steps:**
  1. Confirm delivery directly (expect refusal).
  2. Mark shipped directly (expect refusal).
  3. Record payment.
  4. Confirm delivery (expect refusal).
  5. Mark shipped.
  6. Confirm delivery.
- **Expected:** Steps 1, 2, 4 refused with status unchanged. Steps 3, 5, 6 succeed. Final status `Delivered`. Each status is only reachable through its direct predecessor.

---

## Persistence and concurrency

### TC-26: Status survives re-read after each transition
- **Covers:** A6
- **Preconditions:** None.
- **Steps:**
  1. Create order, perform each valid transition in turn.
  2. After each transition, fetch the order again via a fresh read (new request / new session / cache bypass as applicable).
- **Expected:** Fresh read returns the same status as the transition response. No stale value.

### TC-27: Concurrent conflicting transitions result in exactly one winner
- **Covers:** AC-2, AC-4
- **Preconditions:** Order with status `Paid`.
- **Steps:**
  1. Simultaneously issue "mark shipped" and "cancel" against the same order.
  2. Read final status.
- **Expected:** Exactly one operation succeeds and the other is refused. Final status is either `Shipped` or `Cancelled`, never both applied, never a corrupted or intermediate value. If `Shipped` wins, the cancel is refused with `Shipped orders cannot be cancelled.`

### TC-28: Transition on a non-existent order is refused
- **Covers:** General robustness
- **Preconditions:** An order ID that does not exist.
- **Steps:** Attempt each of the four operations against the ID.
- **Expected:** Each is refused with a not-found error. No order is created as a side effect.

---

## Open questions for the product owner

These do not block testing but the expected behaviour is assumed rather than specified:

1. What is the error message for invalid transitions other than cancelling a Shipped order (TC-10 to TC-23)? Tests currently assert only that a refusal occurs.
2. Is cancelling a Delivered order expected to be refused (A3)? The story mentions only Shipped. If returns are in scope, that is presumably a separate status and story.
3. Should recording a payment on a Placed order require the payment amount to match the order total, or is any recorded payment sufficient? Not covered here since the story treats payment as a single event.
4. Are any transitions permitted to roll back, for example Paid back to Placed on refund? Assumed no.
