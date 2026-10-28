# Test Cases — ORD-4: Order status changes

## Assumptions

- A1: "Record payment", "mark shipped", "confirm delivery", and "cancel" are the only four actions in scope. No other transitions (e.g. refund, return) exist in this story.
- A2: Any action not listed as allowed for a given status is refused and leaves the status unchanged. Only the Shipped-cancel refusal message is specified; the message for other invalid actions is unspecified and tests check only that status is unchanged and the action is reported as unsuccessful.
- A3: Delivered and Cancelled are terminal. No action changes an order out of them.
- A4: A refused action never changes the order's status.
- A5: Status values are the exact strings `Placed`, `Paid`, `Shipped`, `Delivered`, `Cancelled`.
- A6: Actions on a non-existent order are out of scope for this story.

## Happy path

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-01 | New order starts as Placed | None | 1. Create an order. 2. Read its status. | Status is `Placed`. | Story preamble |
| TC-02 | Payment moves Placed to Paid | Order exists with status `Placed`. | 1. Record a payment on the order. 2. Read its status. | Action succeeds. Status is `Paid`. | AC-1 |
| TC-03 | Shipping moves Paid to Shipped | Order exists with status `Paid`. | 1. Mark the order as shipped. 2. Read its status. | Action succeeds. Status is `Shipped`. | AC-2 |
| TC-04 | Delivery moves Shipped to Delivered | Order exists with status `Shipped`. | 1. Confirm delivery. 2. Read its status. | Action succeeds. Status is `Delivered`. | AC-3 |
| TC-05 | Cancel a Placed order | Order exists with status `Placed`. | 1. Cancel the order. 2. Read its status. | Action succeeds. Status is `Cancelled`. | AC-4 |
| TC-06 | Cancel a Paid order | Order exists with status `Paid`. | 1. Cancel the order. 2. Read its status. | Action succeeds. Status is `Cancelled`. | AC-4 |
| TC-07 | Full lifecycle end to end | None | 1. Create an order. 2. Record payment. 3. Mark shipped. 4. Confirm delivery. Read status after each step. | Statuses in order: `Placed`, `Paid`, `Shipped`, `Delivered`. | AC-1, AC-2, AC-3 |

## Refused transitions

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-08 | Cancel a Shipped order is refused | Order exists with status `Shipped`. | 1. Cancel the order. 2. Read its status. | Action is refused with message exactly `Shipped orders cannot be cancelled.` Status remains `Shipped`. | AC-5, A4 |
| TC-09 | Shipped order can still be delivered after refused cancel | Order exists with status `Shipped`. | 1. Attempt to cancel (refused). 2. Confirm delivery. 3. Read status. | Step 1 refused. Step 2 succeeds. Status is `Delivered`. | AC-5, AC-3 |
| TC-10 | Cancel a Delivered order is refused | Order exists with status `Delivered`. | 1. Cancel the order. 2. Read its status. | Action is refused. Status remains `Delivered`. | A2, A3 |
| TC-11 | Cancel an already Cancelled order is refused | Order exists with status `Cancelled`. | 1. Cancel the order. 2. Read its status. | Action is refused. Status remains `Cancelled`. | A2, A3 |
| TC-12 | Ship a Placed (unpaid) order is refused | Order exists with status `Placed`. | 1. Mark the order as shipped. 2. Read its status. | Action is refused. Status remains `Placed`. | A2 |
| TC-13 | Deliver a Placed order is refused | Order exists with status `Placed`. | 1. Confirm delivery. 2. Read its status. | Action is refused. Status remains `Placed`. | A2 |
| TC-14 | Deliver a Paid (unshipped) order is refused | Order exists with status `Paid`. | 1. Confirm delivery. 2. Read its status. | Action is refused. Status remains `Paid`. | A2 |
| TC-15 | Record payment on a Paid order is refused | Order exists with status `Paid`. | 1. Record a payment. 2. Read its status. | Action is refused. Status remains `Paid`. | A2 |
| TC-16 | Record payment on a Shipped order is refused | Order exists with status `Shipped`. | 1. Record a payment. 2. Read its status. | Action is refused. Status remains `Shipped`. | A2 |
| TC-17 | Record payment on a Cancelled order is refused | Order exists with status `Cancelled`. | 1. Record a payment. 2. Read its status. | Action is refused. Status remains `Cancelled`. | A2, A3 |
| TC-18 | Ship a Cancelled order is refused | Order exists with status `Cancelled`. | 1. Mark as shipped. 2. Read its status. | Action is refused. Status remains `Cancelled`. | A2, A3 |
| TC-19 | Any action on a Delivered order is refused | Order exists with status `Delivered`. | 1. Record payment. 2. Mark shipped. 3. Confirm delivery. Read status after each. | Each action is refused. Status remains `Delivered` throughout. | A2, A3 |
| TC-20 | Ship a Delivered order is refused | Order exists with status `Delivered`. | 1. Mark as shipped. 2. Read its status. | Action is refused. Status remains `Delivered`. | A2, A3 |

## Transition matrix (coverage check)

Rows are the current status, columns are the action. ✓ = allowed, ✗ = refused.

| From \ Action | Record payment | Mark shipped | Confirm delivery | Cancel |
|---|---|---|---|---|
| Placed | ✓ TC-02 | ✗ TC-12 | ✗ TC-13 | ✓ TC-05 |
| Paid | ✗ TC-15 | ✓ TC-03 | ✗ TC-14 | ✓ TC-06 |
| Shipped | ✗ TC-16 | ✗ (see note) | ✓ TC-04 | ✗ TC-08 |
| Delivered | ✗ TC-19 | ✗ TC-19/TC-20 | ✗ TC-19 | ✗ TC-10 |
| Cancelled | ✗ TC-17 | ✗ TC-18 | ✗ (see note) | ✗ TC-11 |

Note: Shipped + "mark shipped" and Cancelled + "confirm delivery" are the same-status re-application cases. Add two more cases if the implementation treats idempotent repeats differently from other refusals:

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-21 | Mark an already Shipped order as shipped | Order exists with status `Shipped`. | 1. Mark as shipped. 2. Read status. | Action is refused. Status remains `Shipped`. | A2 |
| TC-22 | Confirm delivery on a Cancelled order | Order exists with status `Cancelled`. | 1. Confirm delivery. 2. Read status. | Action is refused. Status remains `Cancelled`. | A2, A3 |

## Open points for the product owner

- The refusal message for transitions other than Shipped-cancel is not specified. TC-10 through TC-22 check status only. Confirm whether a specific message is required.
- Confirm that Delivered and Cancelled are terminal (A3). If a refund or return flow exists elsewhere, TC-10, TC-11, TC-17, TC-18, TC-19, TC-20, and TC-22 may need revising.
- Confirm whether a refused action should be surfaced as an error or as a no-op success. The cases above assume an error.
