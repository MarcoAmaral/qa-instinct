# Test cases: ORD-4 Order status changes

## Assumptions

- The status set is exactly Placed, Paid, Shipped, Delivered and Cancelled. No other status exists.
- Each action is available as a button on the order page: **Record payment**, **Mark as shipped**, **Confirm delivery** and **Cancel order**. An editor can correct these labels.
- Any transition the story does not list is refused and the status does not change. The story gives a refusal message only for AC-5, so other refusals are checked for "status unchanged" only.
- A refused action shows its message on the order page and leaves no record of a status change.
- Delivered and Cancelled are end states. No action moves an order out of them.
- A new order can be created in the test environment without a real payment.

## Setup for all cases

- Sign in as a store operator.
- Create a new order before each case unless the case says otherwise. Note its order number.

## Happy path

| ID | Title | Preconditions | Steps | Expected result | Covers |
| --- | --- | --- | --- | --- | --- |
| TC-01 | New order starts as Placed | None | 1. Create an order. 2. Open the order page. | Status shows **Placed**. | Intro |
| TC-02 | Record payment on a Placed order | Order is Placed | 1. Open the order. 2. Select **Record payment**. | Status changes to **Paid**. | AC-1 |
| TC-03 | Ship a Paid order | Order is Paid | 1. Open the order. 2. Select **Mark as shipped**. | Status changes to **Shipped**. | AC-2 |
| TC-04 | Deliver a Shipped order | Order is Shipped | 1. Open the order. 2. Select **Confirm delivery**. | Status changes to **Delivered**. | AC-3 |
| TC-05 | Full life cycle in one run | Order is Placed | 1. Select **Record payment**. 2. Select **Mark as shipped**. 3. Select **Confirm delivery**. | Status reads Paid, then Shipped, then Delivered, after each step in turn. | AC-1 to AC-3 |
| TC-06 | Cancel a Placed order | Order is Placed | 1. Open the order. 2. Select **Cancel order**. | Status changes to **Cancelled**. | AC-4 |
| TC-07 | Cancel a Paid order | Order is Paid | 1. Open the order. 2. Select **Cancel order**. | Status changes to **Cancelled**. | AC-4 |

## Refused transitions

| ID | Title | Preconditions | Steps | Expected result | Covers |
| --- | --- | --- | --- | --- | --- |
| TC-08 | Cancel a Shipped order is refused | Order is Shipped | 1. Open the order. 2. Select **Cancel order**. | Message reads exactly "Shipped orders cannot be cancelled." Status stays **Shipped**. | AC-5 |
| TC-09 | Message text matches exactly | Order is Shipped | 1. Select **Cancel order**. 2. Copy the message shown. | Text is "Shipped orders cannot be cancelled." with the same capitals and final full stop. | AC-5 |
| TC-10 | Cancel a Delivered order is refused | Order is Delivered | 1. Select **Cancel order**. | Status stays **Delivered**. | Assumption |
| TC-11 | Cancel a Cancelled order has no effect | Order is Cancelled | 1. Select **Cancel order**. | Status stays **Cancelled**. No second cancellation is recorded. | Assumption |
| TC-12 | Ship a Placed order is refused | Order is Placed, no payment | 1. Select **Mark as shipped**. | Status stays **Placed**. | Assumption |
| TC-13 | Deliver a Placed order is refused | Order is Placed | 1. Select **Confirm delivery**. | Status stays **Placed**. | Assumption |
| TC-14 | Deliver a Paid order is refused | Order is Paid | 1. Select **Confirm delivery**. | Status stays **Paid**. | Assumption |
| TC-15 | Record payment twice is refused | Order is Paid | 1. Select **Record payment** again. | Status stays **Paid**. No second payment is recorded. | Assumption |
| TC-16 | Record payment on a Cancelled order is refused | Order is Cancelled | 1. Select **Record payment**. | Status stays **Cancelled**. | Assumption |
| TC-17 | Ship a Cancelled order is refused | Order is Cancelled | 1. Select **Mark as shipped**. | Status stays **Cancelled**. | Assumption |
| TC-18 | Delivered is a final state | Order is Delivered | 1. Select each of **Record payment**, **Mark as shipped** and **Confirm delivery** in turn. | Status stays **Delivered** after each action. | Assumption |

## Visibility to customers and staff

| ID | Title | Preconditions | Steps | Expected result | Covers |
| --- | --- | --- | --- | --- | --- |
| TC-19 | Staff see the new status without a refresh delay | Order is Placed, open in a second staff session | 1. In session 1, select **Record payment**. 2. In session 2, reload the order. | Session 2 shows **Paid**. | Story goal |
| TC-20 | Customer sees the same status | Order is Shipped, customer signed in | 1. Open the order in the customer account. | Customer view shows **Shipped**, the same word the staff view uses. | Story goal |
| TC-21 | Refused cancellation is not shown to the customer as a change | Order is Shipped, customer signed in | 1. As operator, select **Cancel order**. 2. As customer, reload the order. | Customer view still shows **Shipped**. | AC-5 |

## Traceability

| Criterion | Test cases |
| --- | --- |
| Order starts as Placed | TC-01 |
| AC-1 | TC-02, TC-05, TC-15, TC-16 |
| AC-2 | TC-03, TC-05, TC-12, TC-17 |
| AC-3 | TC-04, TC-05, TC-13, TC-14 |
| AC-4 | TC-06, TC-07 |
| AC-5 | TC-08, TC-09, TC-21 |
| Final states (assumed) | TC-10, TC-11, TC-18 |

## Open points for the product owner

- Confirm the refusal message, if any, for transitions other than cancelling a Shipped order. TC-10 to TC-18 check only that the status is unchanged.
- Confirm whether a Delivered order can ever be cancelled or returned. TC-10 assumes it cannot.
- Confirm the button labels assumed above.
