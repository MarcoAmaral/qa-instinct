## Test Cases — ORD-4: Order status changes

**Assumptions**
- A1: A newly created order has status `Placed` and this is the only initial status.
- A2: The five transitions in AC-1 to AC-5 are the only permitted ones. Any other action on an order in a given status (e.g. shipping a Placed order, paying a Paid order, cancelling a Delivered order) is refused and leaves the status unchanged. Exact wording of those refusal messages is unspecified, so tests assert the refusal and unchanged status only, except for AC-5 where the text is given.
- A3: `Delivered` and `Cancelled` are terminal. No action moves an order out of them.
- A4: A refused action leaves the order fully unchanged (status and any status history).
- A5: Status comparison is exact: `Placed`, `Paid`, `Shipped`, `Delivered`, `Cancelled`.

---

### Setup / initial state

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-01 | New order starts as Placed | None | 1. Create an order. 2. Read its status. | Status is `Placed`. | Story intro, A1 |

### AC-1: Payment

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-02 | Payment on Placed order | Order in `Placed` | 1. Record a payment. 2. Read status. | Status is `Paid`. | AC-1 |
| TC-03 | Payment on Paid order is refused | Order in `Paid` | 1. Record a payment. 2. Read status. | Action is refused. Status remains `Paid`. | AC-1, A2 |
| TC-04 | Payment on Shipped order is refused | Order in `Shipped` | 1. Record a payment. | Refused. Status remains `Shipped`. | A2 |
| TC-05 | Payment on Delivered order is refused | Order in `Delivered` | 1. Record a payment. | Refused. Status remains `Delivered`. | A2, A3 |
| TC-06 | Payment on Cancelled order is refused | Order in `Cancelled` | 1. Record a payment. | Refused. Status remains `Cancelled`. | A2, A3 |

### AC-2: Shipping

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-07 | Ship a Paid order | Order in `Paid` | 1. Mark as shipped. 2. Read status. | Status is `Shipped`. | AC-2 |
| TC-08 | Ship a Placed (unpaid) order is refused | Order in `Placed` | 1. Mark as shipped. | Refused. Status remains `Placed`. | AC-2, A2 |
| TC-09 | Ship a Shipped order is refused | Order in `Shipped` | 1. Mark as shipped. | Refused. Status remains `Shipped`. | A2 |
| TC-10 | Ship a Delivered order is refused | Order in `Delivered` | 1. Mark as shipped. | Refused. Status remains `Delivered`. | A2, A3 |
| TC-11 | Ship a Cancelled order is refused | Order in `Cancelled` | 1. Mark as shipped. | Refused. Status remains `Cancelled`. | A2, A3 |

### AC-3: Delivery

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-12 | Confirm delivery of a Shipped order | Order in `Shipped` | 1. Confirm delivery. 2. Read status. | Status is `Delivered`. | AC-3 |
| TC-13 | Confirm delivery of a Placed order is refused | Order in `Placed` | 1. Confirm delivery. | Refused. Status remains `Placed`. | A2 |
| TC-14 | Confirm delivery of a Paid order is refused | Order in `Paid` | 1. Confirm delivery. | Refused. Status remains `Paid`. | A2 |
| TC-15 | Confirm delivery of a Delivered order is refused | Order in `Delivered` | 1. Confirm delivery. | Refused. Status remains `Delivered`. | A2, A3 |
| TC-16 | Confirm delivery of a Cancelled order is refused | Order in `Cancelled` | 1. Confirm delivery. | Refused. Status remains `Cancelled`. | A2, A3 |

### AC-4: Cancellation (allowed)

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-17 | Cancel a Placed order | Order in `Placed` | 1. Cancel. 2. Read status. | Status is `Cancelled`. | AC-4 |
| TC-18 | Cancel a Paid order | Order in `Paid` | 1. Cancel. 2. Read status. | Status is `Cancelled`. | AC-4 |
| TC-19 | Cancel a Cancelled order is refused | Order in `Cancelled` | 1. Cancel. | Refused. Status remains `Cancelled`. | A2, A3 |

### AC-5: Cancellation (refused)

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-20 | Cancel a Shipped order is refused with message | Order in `Shipped` | 1. Cancel. 2. Read status. | Refused with exactly `Shipped orders cannot be cancelled.` Status remains `Shipped`. | AC-5 |
| TC-21 | Cancel a Delivered order is refused | Order in `Delivered` | 1. Cancel. 2. Read status. | Refused. Status remains `Delivered`. | A2, A3 |
| TC-22 | Shipped order remains shippable-flow after refused cancel | Order in `Shipped` | 1. Cancel (refused per TC-20). 2. Confirm delivery. | Step 2 succeeds. Status is `Delivered`. | AC-5, AC-3, A4 |

### End-to-end flows

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-23 | Full happy path | None | 1. Create order. 2. Record payment. 3. Mark shipped. 4. Confirm delivery. | Status after each step: `Placed` → `Paid` → `Shipped` → `Delivered`. | AC-1, AC-2, AC-3 |
| TC-24 | Pay then cancel | None | 1. Create order. 2. Record payment. 3. Cancel. | Status after each step: `Placed` → `Paid` → `Cancelled`. | AC-1, AC-4 |
| TC-25 | Cancel immediately after placing | None | 1. Create order. 2. Cancel. | `Placed` → `Cancelled`. | AC-4 |
| TC-26 | Refused action does not advance state | Order in `Placed` | 1. Mark shipped (refused). 2. Record payment. 3. Mark shipped. | Step 1 refused, status `Placed`. Step 2 → `Paid`. Step 3 → `Shipped`. Order was not corrupted by the earlier refusal. | A2, A4 |
| TC-27 | Independence of orders | Two orders A and B, both `Placed` | 1. Record payment on A. 2. Read status of B. | A is `Paid`. B is still `Placed`. | Story intro |

### Transition matrix (coverage check)

Rows are current status, columns are actions. ✔ = transition succeeds to the status shown, ✘ = refused, unchanged.

| Current \ Action | Record payment | Mark shipped | Confirm delivery | Cancel |
|---|---|---|---|---|
| Placed | ✔ Paid (TC-02) | ✘ (TC-08) | ✘ (TC-13) | ✔ Cancelled (TC-17) |
| Paid | ✘ (TC-03) | ✔ Shipped (TC-07) | ✘ (TC-14) | ✔ Cancelled (TC-18) |
| Shipped | ✘ (TC-04) | ✘ (TC-09) | ✔ Delivered (TC-12) | ✘ with message (TC-20) |
| Delivered | ✘ (TC-05) | ✘ (TC-10) | ✘ (TC-15) | ✘ (TC-21) |
| Cancelled | ✘ (TC-06) | ✘ (TC-11) | ✘ (TC-16) | ✘ (TC-19) |

All 20 status/action pairs are covered by exactly one test case.

### Open questions for the product owner (not blocking)

- Should refused actions other than AC-5 return a specific message? Tests currently assert refusal only.
- Should a payment attempt on a Cancelled order be refused, or should it be accepted and the order remain Cancelled? Assumed refused (A2).
- Is status history or an audit trail expected? Not tested here as it is outside the story.
