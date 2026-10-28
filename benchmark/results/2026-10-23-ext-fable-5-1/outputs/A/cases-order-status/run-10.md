# Test Cases: ORD-4 Order status changes

## Assumptions

- A1: Status values are exactly `Placed`, `Paid`, `Shipped`, `Delivered`, `Cancelled`. No other statuses exist.
- A2: The lifecycle is strictly linear: Placed → Paid → Shipped → Delivered, with Cancelled reachable only from Placed or Paid. Transitions not listed in the ACs (for example, shipping a Placed order, or recording payment on a Shipped order) are refused and leave the status unchanged. The story is silent on this, so these cases are marked as assumption-based.
- A3: Delivered and Cancelled are terminal. Any action on an order in either status is refused and leaves the status unchanged. The story is silent on this, so these cases are marked as assumption-based.
- A4: The story specifies only the Shipped cancellation message. Error messages for other refused transitions are not specified, so those tests assert only that the transition is refused and the status is unchanged.
- A5: A refused transition must not mutate the order in any way, including status, and must surface the refusal to the caller (error, exception, or failed result, depending on the implementation).
- A6: Each action is idempotent-unsafe: repeating an action that already succeeded (for example, paying a Paid order) is treated as an invalid transition under A2.

## Transition matrix

| From \ Action | Record payment | Mark shipped | Confirm delivery | Cancel |
|---|---|---|---|---|
| Placed | Paid (AC-1) | refused (A2) | refused (A2) | Cancelled (AC-4) |
| Paid | refused (A2) | Shipped (AC-2) | refused (A2) | Cancelled (AC-4) |
| Shipped | refused (A2) | refused (A2) | Delivered (AC-3) | refused, message (AC-5) |
| Delivered | refused (A3) | refused (A3) | refused (A3) | refused (A3) |
| Cancelled | refused (A3) | refused (A3) | refused (A3) | refused (A3) |

## Test cases

### Initial state

**TC-01: New order starts as Placed**
- Preconditions: none.
- Steps: Create a new order.
- Expected: Order status is `Placed`.

### AC-1: Record payment

**TC-02: Payment on Placed order moves to Paid**
- Preconditions: Order in `Placed`.
- Steps: Record a payment on the order.
- Expected: Status is `Paid`. Action succeeds.

**TC-03: Payment on Paid order is refused (A2, A6)**
- Preconditions: Order in `Paid`.
- Steps: Record a payment on the order.
- Expected: Action is refused. Status remains `Paid`.

**TC-04: Payment on Shipped order is refused (A2)**
- Preconditions: Order in `Shipped`.
- Steps: Record a payment.
- Expected: Action is refused. Status remains `Shipped`.

**TC-05: Payment on Delivered order is refused (A3)**
- Preconditions: Order in `Delivered`.
- Steps: Record a payment.
- Expected: Action is refused. Status remains `Delivered`.

**TC-06: Payment on Cancelled order is refused (A3)**
- Preconditions: Order in `Cancelled`.
- Steps: Record a payment.
- Expected: Action is refused. Status remains `Cancelled`.

### AC-2: Mark shipped

**TC-07: Shipping a Paid order moves to Shipped**
- Preconditions: Order in `Paid`.
- Steps: Mark the order as shipped.
- Expected: Status is `Shipped`. Action succeeds.

**TC-08: Shipping a Placed order is refused (A2)**
- Preconditions: Order in `Placed` (no payment recorded).
- Steps: Mark the order as shipped.
- Expected: Action is refused. Status remains `Placed`.

**TC-09: Shipping a Shipped order is refused (A2, A6)**
- Preconditions: Order in `Shipped`.
- Steps: Mark the order as shipped.
- Expected: Action is refused. Status remains `Shipped`.

**TC-10: Shipping a Delivered order is refused (A3)**
- Preconditions: Order in `Delivered`.
- Steps: Mark the order as shipped.
- Expected: Action is refused. Status remains `Delivered`.

**TC-11: Shipping a Cancelled order is refused (A3)**
- Preconditions: Order in `Cancelled`.
- Steps: Mark the order as shipped.
- Expected: Action is refused. Status remains `Cancelled`.

### AC-3: Confirm delivery

**TC-12: Confirming delivery of a Shipped order moves to Delivered**
- Preconditions: Order in `Shipped`.
- Steps: Confirm delivery.
- Expected: Status is `Delivered`. Action succeeds.

**TC-13: Confirming delivery of a Placed order is refused (A2)**
- Preconditions: Order in `Placed`.
- Steps: Confirm delivery.
- Expected: Action is refused. Status remains `Placed`.

**TC-14: Confirming delivery of a Paid order is refused (A2)**
- Preconditions: Order in `Paid`.
- Steps: Confirm delivery.
- Expected: Action is refused. Status remains `Paid`.

**TC-15: Confirming delivery of a Delivered order is refused (A3, A6)**
- Preconditions: Order in `Delivered`.
- Steps: Confirm delivery.
- Expected: Action is refused. Status remains `Delivered`.

**TC-16: Confirming delivery of a Cancelled order is refused (A3)**
- Preconditions: Order in `Cancelled`.
- Steps: Confirm delivery.
- Expected: Action is refused. Status remains `Cancelled`.

### AC-4: Cancel Placed or Paid

**TC-17: Cancelling a Placed order moves to Cancelled**
- Preconditions: Order in `Placed`.
- Steps: Cancel the order.
- Expected: Status is `Cancelled`. Action succeeds.

**TC-18: Cancelling a Paid order moves to Cancelled**
- Preconditions: Order in `Paid`.
- Steps: Cancel the order.
- Expected: Status is `Cancelled`. Action succeeds.

**TC-19: Cancelling a Delivered order is refused (A3)**
- Preconditions: Order in `Delivered`.
- Steps: Cancel the order.
- Expected: Action is refused. Status remains `Delivered`.

**TC-20: Cancelling a Cancelled order is refused (A3, A6)**
- Preconditions: Order in `Cancelled`.
- Steps: Cancel the order.
- Expected: Action is refused. Status remains `Cancelled`.

### AC-5: Cancel Shipped

**TC-21: Cancelling a Shipped order is refused with the specified message**
- Preconditions: Order in `Shipped`.
- Steps: Cancel the order.
- Expected: Action is refused. The error message is exactly `Shipped orders cannot be cancelled.` including the trailing period. Status remains `Shipped`.

**TC-22: Refused cancellation of a Shipped order does not block delivery**
- Preconditions: Order in `Shipped`. A cancel attempt has been made and refused (TC-21).
- Steps: Confirm delivery.
- Expected: Status is `Delivered`. The earlier refusal left no side effects.

### End-to-end flows

**TC-23: Full happy path**
- Steps: Create order; record payment; mark shipped; confirm delivery.
- Expected: Status after each step is `Placed`, `Paid`, `Shipped`, `Delivered` respectively.

**TC-24: Cancel after payment, then no further transitions**
- Steps: Create order; record payment; cancel; attempt to mark shipped.
- Expected: Status after cancel is `Cancelled`. The ship attempt is refused and status remains `Cancelled`.

**TC-25: Refused transitions are reported, not silently ignored (A5)**
- Preconditions: Any order and any refused transition from the matrix (for example TC-08).
- Steps: Attempt the refused transition.
- Expected: The caller receives an explicit failure signal (error, exception, or failed result). The call does not return as if successful.

### Traceability

| AC | Test cases |
|---|---|
| Initial state | TC-01 |
| AC-1 | TC-02, TC-03, TC-04, TC-05, TC-06 |
| AC-2 | TC-07, TC-08, TC-09, TC-10, TC-11 |
| AC-3 | TC-12, TC-13, TC-14, TC-15, TC-16 |
| AC-4 | TC-17, TC-18, TC-19, TC-20 |
| AC-5 | TC-21, TC-22 |
| Cross-cutting | TC-23, TC-24, TC-25 |

### Open points for the story owner

- Confirm A2 and A3: should unlisted transitions be refused, and are Delivered and Cancelled terminal? If skipping steps is allowed (for example, shipping an unpaid order), TC-08, TC-13, and TC-14 must change.
- Confirm A4: should refused transitions other than Shipped cancellation carry specific messages?
- The story does not mention who may perform each action. No authorization tests are included.
