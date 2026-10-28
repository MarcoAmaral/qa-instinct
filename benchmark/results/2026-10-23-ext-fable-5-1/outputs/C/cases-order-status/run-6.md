# Test cases: ORD-4 Order status changes

## Assumptions

- The story names the actions but not the interface labels. These test cases assume the buttons are **Record payment**, **Mark as shipped**, **Confirm delivery** and **Cancel order**. Replace them with the real labels before running the tests.
- The story does not say what happens when an action is used on an order in the wrong status, other than cancelling a Shipped order. These tests assume every other invalid action is refused and the status does not change. The refusal message is not specified, so those tests check only that the status is unchanged.
- The story does not say whether Delivered or Cancelled orders can be cancelled. These tests assume both are refused, because neither is Placed or Paid.
- "Customers and staff always see where an order is" is tested by checking the status on both the staff order page and the customer order page after each change.
- Each test starts with a new order in the status named under Preconditions. Tests do not depend on each other.

## Happy path

| ID | Covers | Preconditions | Steps | Expected result |
| --- | --- | --- | --- | --- |
| TC-01 | Initial status | None | 1. Create a new order. 2. Open the order. | Status is **Placed** on the staff order page and the customer order page. |
| TC-02 | AC-1 | Order in **Placed** | 1. Open the order. 2. Select **Record payment**. 3. Complete the payment details. | Status changes to **Paid**. Both pages show **Paid**. |
| TC-03 | AC-2 | Order in **Paid** | 1. Open the order. 2. Select **Mark as shipped**. | Status changes to **Shipped**. Both pages show **Shipped**. |
| TC-04 | AC-3 | Order in **Shipped** | 1. Open the order. 2. Select **Confirm delivery**. | Status changes to **Delivered**. Both pages show **Delivered**. |
| TC-05 | AC-4 | Order in **Placed** | 1. Open the order. 2. Select **Cancel order**. 3. Confirm the cancellation. | Status changes to **Cancelled**. Both pages show **Cancelled**. |
| TC-06 | AC-4 | Order in **Paid** | 1. Open the order. 2. Select **Cancel order**. 3. Confirm the cancellation. | Status changes to **Cancelled**. Both pages show **Cancelled**. |
| TC-07 | Full lifecycle | Order in **Placed** | 1. Select **Record payment**. 2. Select **Mark as shipped**. 3. Select **Confirm delivery**. Check the status after each step. | Status moves **Placed** → **Paid** → **Shipped** → **Delivered**, in that order, with no step skipped. |

## Refused actions

| ID | Covers | Preconditions | Steps | Expected result |
| --- | --- | --- | --- | --- |
| TC-08 | AC-5 | Order in **Shipped** | 1. Open the order. 2. Select **Cancel order**. | The action is refused. The message reads exactly: `Shipped orders cannot be cancelled.` Status stays **Shipped** on both pages. |
| TC-09 | AC-5 (message text) | Order in **Shipped** | 1. Attempt to cancel the order. 2. Compare the message with the acceptance criterion character by character. | Spelling, capitalisation and the final full stop match the acceptance criterion. |
| TC-10 | Assumed: cancel a Delivered order | Order in **Delivered** | 1. Open the order. 2. Attempt to cancel it. | The action is refused or unavailable. Status stays **Delivered**. |
| TC-11 | Assumed: cancel a Cancelled order | Order in **Cancelled** | 1. Open the order. 2. Attempt to cancel it again. | The action is refused or unavailable. Status stays **Cancelled**. |
| TC-12 | Assumed: skip payment | Order in **Placed** | 1. Open the order. 2. Attempt **Mark as shipped**. | The action is refused or unavailable. Status stays **Placed**. |
| TC-13 | Assumed: skip shipping | Order in **Paid** | 1. Open the order. 2. Attempt **Confirm delivery**. | The action is refused or unavailable. Status stays **Paid**. |
| TC-14 | Assumed: pay twice | Order in **Paid** | 1. Open the order. 2. Attempt **Record payment** again. | The action is refused or unavailable. Status stays **Paid**. |
| TC-15 | Assumed: act on a Cancelled order | Order in **Cancelled** | 1. Attempt **Record payment**. 2. Attempt **Mark as shipped**. 3. Attempt **Confirm delivery**. | Each action is refused or unavailable. Status stays **Cancelled**. |
| TC-16 | Assumed: act on a Delivered order | Order in **Delivered** | 1. Attempt **Record payment**. 2. Attempt **Mark as shipped**. 3. Attempt **Confirm delivery**. | Each action is refused or unavailable. Status stays **Delivered**. |

## Visibility and persistence

| ID | Covers | Preconditions | Steps | Expected result |
| --- | --- | --- | --- | --- |
| TC-17 | Status survives reload | Order in **Paid** | 1. Select **Mark as shipped**. 2. Reload the staff order page. 3. Open the customer order page in a new session. | Both pages show **Shipped** after reload. |
| TC-18 | Refused action leaves no trace | Order in **Shipped** | 1. Attempt to cancel the order. 2. Reload both pages. | Both pages still show **Shipped**. No cancellation is recorded. |
| TC-19 | Only the defined statuses exist | Any order | 1. Open the status filter or status list on the orders page. | The only statuses offered are **Placed**, **Paid**, **Shipped**, **Delivered** and **Cancelled**. |

## Open questions for the product owner

These do not block testing. The assumed answers above apply until confirmed.

- What message, if any, does the operator see for refused actions other than cancelling a Shipped order?
- Are refused actions hidden, disabled, or shown and then refused with a message?
- Can a Delivered order ever be cancelled, for example as a return?
- Does a status change notify the customer, and should that be tested here or in a separate story?
