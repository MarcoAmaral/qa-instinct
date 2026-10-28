## Test Cases: ORD-4 Order status changes

**Assumptions**
- Each transition is exposed as a distinct operation: record payment, mark shipped, confirm delivery, cancel.
- Transitions not listed in the story (for example, shipping a Placed order, paying a Paid order, or any action on a Delivered or Cancelled order) are invalid and must be refused without changing status. The story does not give messages for these refusals, so the tests check only that the status is unchanged and the operation reports failure.
- A refused operation leaves the order exactly as it was, including status.
- Status values are compared as the exact strings Placed, Paid, Shipped, Delivered, Cancelled.

### Happy path

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-01 | New order starts as Placed | None | 1. Create a new order. 2. Read its status. | Status is Placed. | Story preamble |
| TC-02 | Payment moves Placed to Paid | Order exists with status Placed | 1. Record a payment on the order. 2. Read its status. | Operation succeeds. Status is Paid. | AC-1 |
| TC-03 | Shipping moves Paid to Shipped | Order exists with status Paid | 1. Mark the order as shipped. 2. Read its status. | Operation succeeds. Status is Shipped. | AC-2 |
| TC-04 | Delivery moves Shipped to Delivered | Order exists with status Shipped | 1. Confirm delivery. 2. Read its status. | Operation succeeds. Status is Delivered. | AC-3 |
| TC-05 | Cancel a Placed order | Order exists with status Placed | 1. Cancel the order. 2. Read its status. | Operation succeeds. Status is Cancelled. | AC-4 |
| TC-06 | Cancel a Paid order | Order exists with status Paid | 1. Cancel the order. 2. Read its status. | Operation succeeds. Status is Cancelled. | AC-4 |
| TC-07 | Full lifecycle end to end | None | 1. Create an order. 2. Record payment. 3. Mark shipped. 4. Confirm delivery. Read status after each step. | Statuses in order: Placed, Paid, Shipped, Delivered. | AC-1, AC-2, AC-3 |

### Refused transitions

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-08 | Cancel a Shipped order is refused | Order exists with status Shipped | 1. Cancel the order. 2. Read its status. | Operation fails with the exact message "Shipped orders cannot be cancelled." Status remains Shipped. | AC-5 |
| TC-09 | Cancel a Delivered order is refused | Order exists with status Delivered | 1. Cancel the order. 2. Read its status. | Operation fails. Status remains Delivered. | Assumption |
| TC-10 | Cancel an already Cancelled order is refused | Order exists with status Cancelled | 1. Cancel the order. 2. Read its status. | Operation fails. Status remains Cancelled. | Assumption |
| TC-11 | Ship a Placed order is refused | Order exists with status Placed | 1. Mark the order as shipped. 2. Read its status. | Operation fails. Status remains Placed. | Assumption |
| TC-12 | Confirm delivery on a Paid order is refused | Order exists with status Paid | 1. Confirm delivery. 2. Read its status. | Operation fails. Status remains Paid. | Assumption |
| TC-13 | Confirm delivery on a Placed order is refused | Order exists with status Placed | 1. Confirm delivery. 2. Read its status. | Operation fails. Status remains Placed. | Assumption |
| TC-14 | Record payment on a Paid order is refused | Order exists with status Paid | 1. Record a payment. 2. Read its status. | Operation fails. Status remains Paid. | Assumption |
| TC-15 | Record payment on a Shipped order is refused | Order exists with status Shipped | 1. Record a payment. 2. Read its status. | Operation fails. Status remains Shipped. | Assumption |
| TC-16 | Ship a Delivered order is refused | Order exists with status Delivered | 1. Mark the order as shipped. 2. Read its status. | Operation fails. Status remains Delivered. | Assumption |
| TC-17 | Cancelled order accepts no further transitions | Order exists with status Cancelled | 1. Record a payment. 2. Mark shipped. 3. Confirm delivery. Read status after each. | Every operation fails. Status remains Cancelled throughout. | Assumption |
| TC-18 | Delivered order accepts no further transitions | Order exists with status Delivered | 1. Record a payment. 2. Mark shipped. 3. Confirm delivery. Read status after each. | Every operation fails. Status remains Delivered throughout. | Assumption |

### Edge cases

| ID | Title | Preconditions | Steps | Expected result | Covers |
|---|---|---|---|---|---|
| TC-19 | Refused cancel does not block later delivery | Order exists with status Shipped | 1. Cancel the order and observe refusal. 2. Confirm delivery. 3. Read its status. | Step 1 fails with "Shipped orders cannot be cancelled." Step 2 succeeds. Status is Delivered. | AC-3, AC-5 |
| TC-20 | Transitions are isolated per order | Two orders A and B exist, both Placed | 1. Record payment on A. 2. Read status of A and B. | A is Paid. B remains Placed. | AC-1 |
| TC-21 | Refusal message is exact | Order exists with status Shipped | 1. Cancel the order. 2. Capture the error message. | Message equals "Shipped orders cannot be cancelled." exactly, including the trailing period and capitalisation. | AC-5 |

### Traceability

| Acceptance criterion | Test cases |
|---|---|
| Created as Placed | TC-01, TC-07 |
| AC-1 | TC-02, TC-07, TC-20 |
| AC-2 | TC-03, TC-07 |
| AC-3 | TC-04, TC-07, TC-19 |
| AC-4 | TC-05, TC-06 |
| AC-5 | TC-08, TC-19, TC-21 |
| Unlisted transitions refused (assumption) | TC-09 to TC-18 |
