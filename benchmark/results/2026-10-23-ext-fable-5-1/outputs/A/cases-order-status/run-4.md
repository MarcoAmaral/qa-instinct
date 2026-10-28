**Assumptions**

- Orders are created with status `Placed`; no other initial status exists.
- Transitions are triggered by discrete operations: record payment, mark shipped, confirm delivery, cancel.
- A transition that is not listed in AC-1 through AC-5 (for example, shipping a Placed order) is refused and leaves the status unchanged. The story gives no error text for these, so tests assert only on refusal and unchanged status.
- `Delivered` and `Cancelled` are terminal; no further transitions are allowed from them.
- A refused operation returns an error to the caller and does not raise a silent no-op.
- Status values are compared exactly as written in the story.

**Test cases**

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-01 | New order starts as Placed | None | 1. Create an order. 2. Read its status. | Status is `Placed`. | Intro |
| TC-02 | Payment moves Placed to Paid | Order exists with status `Placed`. | 1. Record a payment on the order. 2. Read its status. | Status is `Paid`. | AC-1 |
| TC-03 | Shipping moves Paid to Shipped | Order exists with status `Paid`. | 1. Mark the order as shipped. 2. Read its status. | Status is `Shipped`. | AC-2 |
| TC-04 | Delivery moves Shipped to Delivered | Order exists with status `Shipped`. | 1. Confirm delivery. 2. Read its status. | Status is `Delivered`. | AC-3 |
| TC-05 | Full happy path end to end | None | 1. Create order. 2. Record payment. 3. Mark shipped. 4. Confirm delivery. Read status after each step. | Statuses in order: `Placed`, `Paid`, `Shipped`, `Delivered`. | AC-1, AC-2, AC-3 |
| TC-06 | Cancel a Placed order | Order exists with status `Placed`. | 1. Cancel the order. 2. Read its status. | Status is `Cancelled`. | AC-4 |
| TC-07 | Cancel a Paid order | Order exists with status `Paid`. | 1. Cancel the order. 2. Read its status. | Status is `Cancelled`. | AC-4 |
| TC-08 | Cancel a Shipped order is refused | Order exists with status `Shipped`. | 1. Attempt to cancel the order. 2. Read its status. | Operation is refused with message exactly `Shipped orders cannot be cancelled.` Status remains `Shipped`. | AC-5 |
| TC-09 | Cancel a Delivered order is refused | Order exists with status `Delivered`. | 1. Attempt to cancel. 2. Read status. | Operation is refused. Status remains `Delivered`. | Assumption (terminal) |
| TC-10 | Cancel a Cancelled order is refused | Order exists with status `Cancelled`. | 1. Attempt to cancel again. 2. Read status. | Operation is refused. Status remains `Cancelled`. | Assumption (terminal) |
| TC-11 | Ship a Placed order is refused | Order exists with status `Placed`. | 1. Attempt to mark shipped. 2. Read status. | Operation is refused. Status remains `Placed`. | Assumption (no skipping) |
| TC-12 | Deliver a Placed order is refused | Order exists with status `Placed`. | 1. Attempt to confirm delivery. 2. Read status. | Operation is refused. Status remains `Placed`. | Assumption (no skipping) |
| TC-13 | Deliver a Paid order is refused | Order exists with status `Paid`. | 1. Attempt to confirm delivery. 2. Read status. | Operation is refused. Status remains `Paid`. | Assumption (no skipping) |
| TC-14 | Pay a Paid order is refused | Order exists with status `Paid`. | 1. Record a second payment. 2. Read status. | Operation is refused. Status remains `Paid`. | Assumption (no repeat) |
| TC-15 | Pay a Shipped order is refused | Order exists with status `Shipped`. | 1. Attempt to record payment. 2. Read status. | Operation is refused. Status remains `Shipped`. | Assumption (no backward move) |
| TC-16 | Ship a Shipped order is refused | Order exists with status `Shipped`. | 1. Attempt to mark shipped again. 2. Read status. | Operation is refused. Status remains `Shipped`. | Assumption (no repeat) |
| TC-17 | Deliver a Delivered order is refused | Order exists with status `Delivered`. | 1. Attempt to confirm delivery again. 2. Read status. | Operation is refused. Status remains `Delivered`. | Assumption (terminal) |
| TC-18 | No transitions from Cancelled | Order exists with status `Cancelled`. | 1. Attempt record payment. 2. Attempt mark shipped. 3. Attempt confirm delivery. Read status after each. | Each operation is refused. Status remains `Cancelled` throughout. | Assumption (terminal) |
| TC-19 | No transitions from Delivered other than none | Order exists with status `Delivered`. | 1. Attempt record payment. 2. Attempt mark shipped. Read status after each. | Each operation is refused. Status remains `Delivered`. | Assumption (terminal) |
| TC-20 | Refused cancel does not alter other orders | Two orders: A is `Shipped`, B is `Paid`. | 1. Attempt to cancel A. 2. Read status of A and B. | A is refused and remains `Shipped`. B remains `Paid`. | AC-5, isolation |
| TC-21 | Status is visible after each change | Order exists with status `Placed`. | 1. Record payment. 2. Reload the order from storage or via its read endpoint. | Reloaded status is `Paid`, confirming the change is persisted and not only in memory. | Story goal |
| TC-22 | Cancelled order cannot be paid afterwards | Order exists with status `Placed`. | 1. Cancel the order. 2. Attempt to record payment. 3. Read status. | Cancel succeeds. Payment is refused. Status remains `Cancelled`. | AC-4, assumption (terminal) |

**Transition matrix used to derive the negative cases**

| From \ Operation | Record payment | Mark shipped | Confirm delivery | Cancel |
|---|---|---|---|---|
| Placed | Paid (TC-02) | Refused (TC-11) | Refused (TC-12) | Cancelled (TC-06) |
| Paid | Refused (TC-14) | Shipped (TC-03) | Refused (TC-13) | Cancelled (TC-07) |
| Shipped | Refused (TC-15) | Refused (TC-16) | Delivered (TC-04) | Refused with message (TC-08) |
| Delivered | Refused (TC-19) | Refused (TC-19) | Refused (TC-17) | Refused (TC-09) |
| Cancelled | Refused (TC-18) | Refused (TC-18) | Refused (TC-18) | Refused (TC-10) |

**Open points for the product owner**

- Error messages for refusals other than AC-5 are unspecified. Tests above assert only on refusal and unchanged status until wording is defined.
- Whether a Cancelled Paid order triggers a refund is out of scope for this story and not tested here.
