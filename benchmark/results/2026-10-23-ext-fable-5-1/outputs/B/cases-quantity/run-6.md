# Test Cases — CART-12: Change the quantity of an item in the cart

## Assumptions

- A-1: The cart page shows a numeric quantity field per line item. Changes apply on blur, Enter, or a visible update control. If the real UI uses +/- steppers, the stepper cases (TC-22, TC-23) apply; otherwise they are N/A.
- A-2: Non-integer, negative, empty, and non-numeric input is rejected and the previous quantity is kept. The story does not specify a message for these, so the test only checks rejection and retention of the prior value.
- A-3: Cancelling the "Remove this item?" prompt keeps the item with its previous quantity and the field reverts to show that value.
- A-4: The limit of 20 is per cart line, not per order, and applies independently per product.
- A-5: Line subtotal and cart total recalculate after every successful quantity change.
- A-6: The quantity change is persisted server-side, so it survives a page reload.
- A-7: Stock availability is out of scope for this story. If stock is lower than the requested quantity, behaviour is governed by another story.
- A-8: The test cart contains at least two distinct items so cross-line isolation can be checked.

## Preconditions (all cases unless stated)

- Shopper is signed in or has a guest session with an active cart.
- Cart contains item A (quantity 2, unit price 10.00) and item B (quantity 1).
- Cart page is open.

## AC-1: Quantity field accepts whole numbers 1 to 20

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-01 | Set quantity to lower boundary (1) | Change item A quantity from 2 to 1 and apply. | Quantity shows 1. Line subtotal shows 10.00. Cart total recalculates. No message shown. |
| TC-02 | Set quantity to upper boundary (20) | Change item A quantity to 20 and apply. | Quantity shows 20. Line subtotal shows 200.00. No message shown. |
| TC-03 | Set quantity to a mid-range value | Change item A quantity to 7 and apply. | Quantity shows 7. Line subtotal shows 70.00. |
| TC-04 | Increase then decrease in one session | Set item A to 15, apply. Then set to 3, apply. | Each change is applied in order. Final quantity is 3, subtotal 30.00. |
| TC-05 | Re-enter the same quantity | Item A is 2. Enter 2 and apply. | Quantity stays 2. No error, no duplicate line, totals unchanged. |
| TC-06 | Change persists across reload | Set item A to 5, apply, reload the page. | Item A shows 5 after reload. |
| TC-07 | Change is isolated to one line | Set item A to 4, apply. | Item B still shows 1. Only item A's subtotal changes. |
| TC-08 | Reject decimal input | Enter 2.5 for item A and apply. | Change is rejected. Field returns to 2. Subtotal unchanged. (A-2) |
| TC-09 | Reject negative input | Enter -1 for item A and apply. | Change is rejected. Field returns to 2. (A-2) |
| TC-10 | Reject non-numeric input | Enter "abc" for item A and apply. | Change is rejected. Field returns to 2. (A-2) |
| TC-11 | Reject empty input | Clear the field for item A and apply. | Change is rejected. Field returns to 2. Item is not removed and no removal prompt appears. (A-2) |
| TC-12 | Leading zeros and whitespace | Enter " 05 " for item A and apply. | Treated as 5. Quantity shows 5. |
| TC-13 | Keyboard-only operation | Tab to item A quantity field, type 6, press Enter. | Quantity updates to 6 without using a mouse. Focus stays in a sensible place (field or update control). |
| TC-14 | Field has an accessible label | Inspect item A quantity field with a screen reader or accessibility tree. | Field is announced with a label that identifies it as the quantity for item A. |

## AC-2: Quantity 0 prompts for removal

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-15 | Zero prompts for confirmation | Enter 0 for item A and apply. | Prompt with text "Remove this item?" appears. Item A is still in the cart behind the prompt with quantity 2. |
| TC-16 | Confirm removes the item | From TC-15, confirm the prompt. | Item A is removed from the cart. Item B remains with quantity 1. Cart total reflects only item B. |
| TC-17 | Cancel keeps the item | From TC-15, cancel or dismiss the prompt. | Prompt closes. Item A remains with quantity 2 and the field shows 2. Totals unchanged. (A-3) |
| TC-18 | Dismiss via Escape or outside click | From TC-15, press Escape (or click outside the dialog if applicable). | Behaves as cancel: item A stays with quantity 2. |
| TC-19 | Removal persists after reload | From TC-16, reload the page. | Item A is absent. Item B still present. |
| TC-20 | Removing the last item | Cart contains only item B. Enter 0, confirm. | Item B removed. Cart shows its empty state. No error. |
| TC-21 | Zero with leading characters | Enter "00" for item A and apply. | Treated as 0. Removal prompt appears. |
| TC-22 | Stepper decrement to 0 (if stepper exists) | Item A at 1. Press the decrement control. | Removal prompt appears. Cancel keeps quantity 1. (A-1) |
| TC-23 | Stepper decrement below 0 is not possible (if stepper exists) | Item A at 1. Press decrement twice quickly. | Only one prompt appears. Quantity never shows a negative value. (A-1) |
| TC-24 | Prompt is accessible | From TC-15, inspect the prompt. | Prompt receives keyboard focus, is announced as a dialog, and both confirm and cancel actions are reachable by keyboard. |
| TC-25 | Repeated zero after cancel | Cancel the prompt (TC-17), then enter 0 again and apply. | Prompt appears again. Confirm removes the item. |

## AC-3: Quantity above 20 is rejected with a message

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-26 | Just above the limit (21) | Enter 21 for item A and apply. | Message "You can buy at most 20 of this item." is shown. Field shows 2. Subtotal unchanged. |
| TC-27 | Far above the limit | Enter 999 for item A and apply. | Same message. Field shows 2. |
| TC-28 | Very large value | Enter 99999999999999999999 for item A and apply. | Same message. No crash, no overflow, no change to quantity. |
| TC-29 | Previous quantity is the last accepted value | Set item A to 15, apply. Enter 25, apply. | Message shown. Field shows 15, not 2. |
| TC-30 | Message does not block further edits | After TC-26, enter 10 and apply. | Message disappears. Quantity updates to 10. |
| TC-31 | Message is scoped to the correct line | Enter 21 for item A. Observe item B. | Message appears against item A only. Item B unaffected. |
| TC-32 | Stepper increment past 20 (if stepper exists) | Item A at 20. Press increment. | Message shown or control disabled. Quantity stays 20. (A-1) |
| TC-33 | Message text and accessibility | Trigger the message. | Text matches "You can buy at most 20 of this item." exactly. Message is associated with the field (for example via aria-describedby) and announced by a screen reader. |
| TC-34 | Limit does not persist as an error | Trigger the message, then reload. | Field shows the previous valid quantity. No error state shown after reload. |
| TC-35 | Server-side enforcement | Submit a quantity of 21 directly to the cart update endpoint, bypassing the UI. | Server rejects the value. Cart quantity remains unchanged. |

## Cross-cutting and non-functional

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-36 | Rapid successive changes | Quickly change item A to 3, then 4, then 5 before each request completes. | Final displayed quantity and persisted quantity are both 5. No stale response overwrites the latest value. |
| TC-37 | Network failure during update | Simulate a failed request when changing item A to 6. | Field reverts to the previous quantity or shows a clear error. Cart does not show an unsaved value as saved. |
| TC-38 | Mini-cart and header badge | Change item A to 8. Check the header cart count or mini-cart. | Item count updates consistently everywhere the cart is shown. |
| TC-39 | Multiple tabs | Open the cart in two tabs. Change item A to 9 in tab 1. Reload tab 2. | Tab 2 shows 9. |
| TC-40 | Mobile viewport | Repeat TC-01, TC-15, TC-26 at a narrow viewport. | Field, prompt, and message are fully visible and usable. Numeric keyboard is shown on touch devices. |
| TC-41 | Checkout reflects the change | Set item A to 12, proceed to checkout. | Checkout summary shows quantity 12 and the matching subtotal. |

## Traceability

| AC | Test cases |
|---|---|
| AC-1 | TC-01 to TC-14, TC-36 to TC-41 |
| AC-2 | TC-15 to TC-25 |
| AC-3 | TC-26 to TC-35 |

## Open points for the product owner

- Message and behaviour for decimal, negative, empty, and non-numeric input (A-2).
- Whether the 20-item limit is per line or per product across duplicate lines (A-4).
- Interaction between the limit and actual stock levels (A-7).
