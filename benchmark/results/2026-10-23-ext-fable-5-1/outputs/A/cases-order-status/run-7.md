**Assumptions**

- A1: Transitions not listed in the acceptance criteria (e.g. recording payment on a Paid order, shipping a Placed order, confirming delivery of a Paid order, cancelling a Delivered or Cancelled order) are refused and leave the status unchanged. The story gives no message text for these, so tests only assert refusal and unchanged status, not the exact wording.
- A2: Delivered and Cancelled are terminal; no action changes their status.
- A3: Refusal is observable as an error or rejected result; the order's status is unchanged and nothing else about the order is altered.
- A4: Status transitions are performed through the system's order actions (API or UI); the test cases are written at the behavioural level and apply to either.

**Test cases**

| ID | Title | AC | Preconditions | Steps | Expected result |
|---|---|---|---|---|---|
| TC-01 | New order starts as Placed | Intro | None | 1. Create a new order. | Order status is Placed. |
| TC-02 | Payment on Placed order | AC-1 | Order exists with status Placed. | 1. Record a payment on the order. | Status is Paid. |
| TC-03 | Ship a Paid order | AC-2 | Order exists with status Paid. | 1. Mark the order as shipped. | Status is Shipped. |
| TC-04 | Confirm delivery of Shipped order | AC-3 | Order exists with status Shipped. | 1. Confirm delivery. | Status is Delivered. |
| TC-05 | Full happy path | AC-1 to AC-3 | New order. | 1. Create order. 2. Record payment. 3. Mark shipped. 4. Confirm delivery. | Status moves Placed, Paid, Shipped, Delivered in order, with each step's status visible after that step. |
| TC-06 | Cancel a Placed order | AC-4 | Order exists with status Placed. | 1. Cancel the order. | Status is Cancelled. |
| TC-07 | Cancel a Paid order | AC-4 | Order exists with status Paid. | 1. Cancel the order. | Status is Cancelled. |
| TC-08 | Cancel a Shipped order is refused | AC-5 | Order exists with status Shipped. | 1. Attempt to cancel the order. | Request refused with the message "Shipped orders cannot be cancelled." Status remains Shipped. |
| TC-09 | Cancel a Delivered order is refused | A1, A2 | Order exists with status Delivered. | 1. Attempt to cancel the order. | Request refused. Status remains Delivered. |
| TC-10 | Cancel an already Cancelled order is refused | A1, A2 | Order exists with status Cancelled. | 1. Attempt to cancel the order again. | Request refused. Status remains Cancelled. |
| TC-11 | Payment on a non-Placed order is refused | A1 | Four orders, one each in Paid, Shipped, Delivered, Cancelled. | 1. Record a payment on each order. | Each request refused. Each order's status unchanged. |
| TC-12 | Shipping a non-Paid order is refused | A1 | Four orders, one each in Placed, Shipped, Delivered, Cancelled. | 1. Mark each order as shipped. | Each request refused. Each order's status unchanged. Placed order in particular cannot skip Paid. |
| TC-13 | Confirming delivery of a non-Shipped order is refused | A1 | Four orders, one each in Placed, Paid, Delivered, Cancelled. | 1. Confirm delivery on each order. | Each request refused. Each order's status unchanged. |
| TC-14 | Cancelled order cannot be revived | A2 | Order cancelled from Placed. | 1. Record a payment. 2. Mark shipped. 3. Confirm delivery. | Every request refused. Status remains Cancelled throughout. |
| TC-15 | Refused cancellation does not alter other order data | AC-5, A3 | Order with status Shipped; note its items, totals, and timestamps. | 1. Attempt to cancel. 2. Re-read the order. | Items, totals, and timestamps are identical to before the attempt. Status is Shipped. |
| TC-16 | Status visible to staff and customer after each change | Story goal | Order in Placed with a customer view and a staff view available. | 1. Record payment. 2. Check both views. 3. Mark shipped. 4. Check both views. | Both views show the current status after each change, with no stale value. |
| TC-17 | Concurrent cancel and ship on a Paid order | AC-2, AC-4 | Order with status Paid. | 1. Submit "mark shipped" and "cancel" at the same time. | Exactly one succeeds. Final status is either Shipped or Cancelled, never both applied and never an intermediate or invalid value. The losing request is refused. |
| TC-18 | Repeated identical transition is refused | A1 | Order with status Paid (payment already recorded). | 1. Record a payment again. | Request refused. Status remains Paid. No duplicate payment effect on the order. |
| TC-19 | Status changes are persisted | All | Order moved to Shipped. | 1. Reload the order from storage, or restart the service and fetch the order. | Status is still Shipped. |
| TC-20 | Message text exact match | AC-5 | Order with status Shipped. | 1. Attempt to cancel. 2. Capture the returned message. | Message equals "Shipped orders cannot be cancelled." exactly, including the trailing period and capitalisation. |

**Coverage notes**

- AC-1 to AC-5 are each covered by at least one positive test (TC-02, TC-03, TC-04, TC-06, TC-07, TC-08).
- TC-09 to TC-14 and TC-18 cover the transitions the story does not define, under assumption A1. If the product owner decides some of these should be allowed, those cases should be rewritten rather than removed.
- TC-17 is the only test that needs a concurrent harness. It can be deferred if the system is single-threaded per order.
