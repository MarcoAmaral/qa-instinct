# Test Cases: ORD-4 Order status changes

## Assumptions

- A1: An order exposes a readable `status` field and the operations `recordPayment`, `markShipped`, `confirmDelivery`, and `cancel`.
- A2: Statuses are exactly `Placed`, `Paid`, `Shipped`, `Delivered`, `Cancelled`. No other statuses exist.
- A3: Any transition not listed in AC-1 to AC-4 is invalid and is refused with an error that leaves the status unchanged. The story only specifies the message for cancelling a Shipped order; other refusals are asserted on "operation refused, status unchanged" only, not on message text.
- A4: Delivered and Cancelled are terminal. No operation changes an order out of either status.
- A5: A refused operation does not create a status-change record or side effect (for example no shipment, no refund). Verified only where observable.
- A6: Status changes are atomic. Concurrent conflicting operations resolve so that exactly one wins and the resulting status is still a valid state. One test covers this at a basic level.

## Preconditions (all tests)

- A store operator with permission to change order status is authenticated.
- A fresh order is created per test unless the test states otherwise. Creating an order yields status `Placed` (verified in TC-01).

## Test cases

### Happy path (AC-1 to AC-4)

| ID | AC | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|---|
| TC-01 | Story | New order starts as Placed | None | 1. Create an order. 2. Read its status. | Status is `Placed`. |
| TC-02 | AC-1 | Payment moves Placed to Paid | Order in `Placed` | 1. Record a payment. 2. Read status. | Status is `Paid`. |
| TC-03 | AC-2 | Shipping moves Paid to Shipped | Order in `Paid` | 1. Mark as shipped. 2. Read status. | Status is `Shipped`. |
| TC-04 | AC-3 | Delivery moves Shipped to Delivered | Order in `Shipped` | 1. Confirm delivery. 2. Read status. | Status is `Delivered`. |
| TC-05 | AC-4 | Cancel a Placed order | Order in `Placed` | 1. Cancel the order. 2. Read status. | Status is `Cancelled`. |
| TC-06 | AC-4 | Cancel a Paid order | Order in `Paid` | 1. Cancel the order. 2. Read status. | Status is `Cancelled`. |
| TC-07 | AC-1..3 | Full lifecycle in sequence | Order in `Placed` | 1. Record payment. 2. Mark shipped. 3. Confirm delivery. Read status after each step. | Statuses are `Paid`, then `Shipped`, then `Delivered`, in that order. |

### Refused cancellation (AC-5)

| ID | AC | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|---|
| TC-08 | AC-5 | Cancel a Shipped order is refused | Order in `Shipped` | 1. Cancel the order. 2. Read status. | Operation is refused with the exact message `Shipped orders cannot be cancelled.` Status remains `Shipped`. |
| TC-09 | AC-5 | Refusal message is exact | Order in `Shipped` | 1. Cancel the order. 2. Capture the error message. | Message equals `Shipped orders cannot be cancelled.` character for character, including the trailing full stop and capitalisation. |
| TC-10 | AC-5, AC-3 | Shipped order can still be delivered after a refused cancel | Order in `Shipped` | 1. Attempt cancel (expect refusal). 2. Confirm delivery. 3. Read status. | Step 1 refused. Step 2 succeeds and status is `Delivered`. |
| TC-11 | AC-5 | Repeated cancel attempts on Shipped are each refused | Order in `Shipped` | 1. Attempt cancel three times. 2. Read status. | Every attempt is refused with the AC-5 message. Status remains `Shipped`. |

### Invalid transitions (assumption A3, A4)

| ID | AC | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|---|
| TC-12 | A3 | Ship a Placed order is refused | Order in `Placed` | 1. Mark as shipped. 2. Read status. | Refused. Status remains `Placed`. |
| TC-13 | A3 | Confirm delivery on a Placed order is refused | Order in `Placed` | 1. Confirm delivery. 2. Read status. | Refused. Status remains `Placed`. |
| TC-14 | A3 | Confirm delivery on a Paid order is refused | Order in `Paid` | 1. Confirm delivery. 2. Read status. | Refused. Status remains `Paid`. |
| TC-15 | A3 | Record payment on a Paid order is refused | Order in `Paid` | 1. Record a second payment. 2. Read status. | Refused. Status remains `Paid`. |
| TC-16 | A3 | Record payment on a Shipped order is refused | Order in `Shipped` | 1. Record a payment. 2. Read status. | Refused. Status remains `Shipped`. |
| TC-17 | A3 | Mark shipped on a Shipped order is refused | Order in `Shipped` | 1. Mark as shipped again. 2. Read status. | Refused. Status remains `Shipped`. |
| TC-18 | A4 | Delivered is terminal | Order in `Delivered` | 1. Attempt record payment. 2. Attempt mark shipped. 3. Attempt confirm delivery. 4. Attempt cancel. Read status after each. | Every attempt is refused. Status remains `Delivered` throughout. |
| TC-19 | A4 | Cancelled is terminal | Order in `Cancelled` (via TC-05 path) | 1. Attempt record payment. 2. Attempt mark shipped. 3. Attempt confirm delivery. 4. Attempt cancel. Read status after each. | Every attempt is refused. Status remains `Cancelled` throughout. |
| TC-20 | A4 | Cancelled from Paid is terminal | Order in `Cancelled` (via TC-06 path) | Same as TC-19. | Same as TC-19. |

### Side effects and consistency

| ID | AC | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|---|
| TC-21 | AC-5, A5 | Refused cancel leaves no trace | Order in `Shipped`, status history or audit log available | 1. Attempt cancel. 2. Read status history. | No new status-change entry is recorded for the refused attempt. Last entry is still the transition to `Shipped`. |
| TC-22 | All | Each successful transition is recorded | Order in `Placed`, status history available | 1. Record payment. 2. Mark shipped. 3. Confirm delivery. 4. Read history. | History contains exactly three entries, in order `Placed→Paid`, `Paid→Shipped`, `Shipped→Delivered`, each with a timestamp. |
| TC-23 | All | Status is persisted across reads | Order in `Placed` | 1. Record payment. 2. Re-fetch the order by ID from a fresh client or session. | Re-fetched status is `Paid`. |
| TC-24 | AC-4 | Customer view reflects staff change | Order in `Placed`, customer view available | 1. Operator cancels order. 2. Customer views the order. | Customer sees status `Cancelled`. |
| TC-25 | AC-1, AC-4, A6 | Concurrent payment and cancel on a Placed order | Order in `Placed` | 1. Issue record payment and cancel at the same time. 2. Read status. | Exactly one succeeds. Final status is either `Paid` or `Cancelled`, never both, never `Placed`, and never an inconsistent state. The losing operation is refused. |
| TC-26 | AC-2, AC-5, A6 | Concurrent ship and cancel on a Paid order | Order in `Paid` | 1. Issue mark shipped and cancel at the same time. 2. Read status. | Exactly one succeeds. Final status is `Shipped` or `Cancelled`. If ship won, the cancel is refused with the AC-5 message. |

### Input and error handling

| ID | AC | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|---|
| TC-27 | All | Operation on a non-existent order | No order with the given ID | 1. Attempt each of the four operations against an unknown order ID. | Each is refused with a not-found error. No order is created. |
| TC-28 | All | Operation without operator permission | Caller lacks the store operator role | 1. Attempt each of the four operations on a valid order. 2. Read status. | Each is refused with an authorisation error. Status is unchanged. |

## Traceability

| AC | Covered by |
|---|---|
| Story (initial status) | TC-01 |
| AC-1 | TC-02, TC-07, TC-22, TC-25 |
| AC-2 | TC-03, TC-07, TC-22, TC-26 |
| AC-3 | TC-04, TC-07, TC-10, TC-22 |
| AC-4 | TC-05, TC-06, TC-24, TC-25, TC-26 |
| AC-5 | TC-08, TC-09, TC-10, TC-11, TC-21, TC-26 |
| Assumptions A3/A4 | TC-12 to TC-20 |

## Open points for the product owner

- Confirm the exact error message, if any, for invalid transitions other than cancelling a Shipped order (TC-12 to TC-20).
- Confirm whether Delivered and Cancelled are terminal, or whether a return or reinstatement flow exists.
- Confirm whether a refused cancel on a Shipped order should be logged for audit purposes (TC-21 assumes not).
