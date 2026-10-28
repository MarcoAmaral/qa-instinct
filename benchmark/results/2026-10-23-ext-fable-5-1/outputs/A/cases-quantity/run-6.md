# Test Cases: CART-12 Change the quantity of an item in the cart

## Assumptions

- The cart is a web page with a quantity field per line item, and the change applies when the field loses focus or the shopper presses Enter. There is no separate "Update" button.
- Validation messages are shown inline next to the quantity field of the affected item.
- The "Remove this item?" prompt is a dialog with "Remove" and "Cancel" actions. Closing the dialog by any other means (Escape, click outside) behaves like Cancel.
- Non-integer and non-numeric input is rejected and the previous quantity is kept. The story does not specify a message for this case, so the tests check only that the value is kept.
- Negative numbers are treated as invalid input, not as a zero removal request.
- Stock limits do not apply. The limit of 20 is a per-item purchase cap independent of inventory.
- The line total and cart subtotal are recalculated after every accepted change.

## Preconditions (all cases)

- Shopper has a cart containing one item "Widget" at unit price 10.00 with quantity 5, unless stated otherwise.

---

## AC-1: Quantity accepts whole numbers 1 to 20

| ID | Title | Steps | Expected result |
|----|-------|-------|-----------------|
| TC-01 | Set quantity to lower bound 1 | 1. Clear the quantity field. 2. Enter `1`. 3. Press Enter. | Quantity shows 1. Line total shows 10.00. No message is shown. |
| TC-02 | Set quantity to upper bound 20 | 1. Clear the quantity field. 2. Enter `20`. 3. Press Enter. | Quantity shows 20. Line total shows 200.00. No message is shown. |
| TC-03 | Set quantity to a mid-range value | 1. Clear the quantity field. 2. Enter `12`. 3. Press Enter. | Quantity shows 12. Line total shows 120.00. |
| TC-04 | Increase from 19 to 20 | Precondition: quantity is 19. 1. Change to `20`. 2. Press Enter. | Quantity shows 20. Accepted without message. |
| TC-05 | Decrease from 2 to 1 | Precondition: quantity is 2. 1. Change to `1`. 2. Press Enter. | Quantity shows 1. No removal prompt appears. |
| TC-06 | Change persists after page reload | 1. Set quantity to `7`. 2. Press Enter. 3. Reload the page. | Quantity still shows 7. |
| TC-07 | Change applies on blur | 1. Enter `3`. 2. Click elsewhere on the page without pressing Enter. | Quantity shows 3. Line total shows 30.00. |
| TC-08 | Subtotal updates across multiple items | Precondition: cart also contains "Gadget" at 4.00, quantity 2. 1. Set Widget quantity to `10`. 2. Press Enter. | Widget line total 100.00. Gadget unchanged at 8.00. Cart subtotal 108.00. |
| TC-09 | Decimal value is rejected | 1. Enter `2.5`. 2. Press Enter. | Quantity reverts to 5. Line total stays 50.00. |
| TC-10 | Alphabetic input is rejected | 1. Enter `abc`. 2. Press Enter. | Quantity reverts to 5. |
| TC-11 | Empty field is rejected | 1. Clear the field. 2. Press Enter. | Quantity reverts to 5. No removal prompt appears. |
| TC-12 | Negative number is rejected | 1. Enter `-1`. 2. Press Enter. | Quantity reverts to 5. No removal prompt appears. |
| TC-13 | Leading and trailing whitespace is trimmed | 1. Enter ` 4 ` (with spaces). 2. Press Enter. | Quantity shows 4. |
| TC-14 | Leading zero is accepted as the number | 1. Enter `07`. 2. Press Enter. | Quantity shows 7. |
| TC-15 | Re-entering the same quantity makes no change | 1. Enter `5`. 2. Press Enter. | Quantity stays 5. No message or prompt is shown. |

## AC-2: Setting quantity to 0 prompts for removal

| ID | Title | Steps | Expected result |
|----|-------|-------|-----------------|
| TC-16 | Zero shows the removal prompt | 1. Enter `0`. 2. Press Enter. | A dialog appears with the text "Remove this item?". The item is still in the cart behind the dialog. |
| TC-17 | Confirming removes the item | 1. Enter `0`. 2. Press Enter. 3. Choose "Remove". | Widget is no longer in the cart. Cart subtotal reflects the removal. |
| TC-18 | Cancelling keeps the item and previous quantity | 1. Enter `0`. 2. Press Enter. 3. Choose "Cancel". | Dialog closes. Widget remains with quantity 5. Line total stays 50.00. |
| TC-19 | Dismissing with Escape behaves as Cancel | 1. Enter `0`. 2. Press Enter. 3. Press Escape. | Dialog closes. Widget remains with quantity 5. |
| TC-20 | Clicking outside the dialog behaves as Cancel | 1. Enter `0`. 2. Press Enter. 3. Click outside the dialog. | Dialog closes. Widget remains with quantity 5. |
| TC-21 | Removal persists after reload | 1. Enter `0`. 2. Confirm removal. 3. Reload the page. | Widget is not in the cart. |
| TC-22 | Cancel persists after reload | 1. Enter `0`. 2. Cancel. 3. Reload the page. | Widget is in the cart with quantity 5. |
| TC-23 | Removing the last item leaves an empty cart | Precondition: Widget is the only item. 1. Enter `0`. 2. Confirm. | Cart shows its empty state. Subtotal is 0.00. |
| TC-24 | Only the targeted item is removed | Precondition: cart also contains "Gadget". 1. Set Widget quantity to `0`. 2. Confirm. | Widget is removed. Gadget is unchanged. |
| TC-25 | Zero with leading zeros prompts for removal | 1. Enter `00`. 2. Press Enter. | "Remove this item?" dialog appears. |
| TC-26 | Zero on blur prompts for removal | 1. Enter `0`. 2. Click elsewhere without pressing Enter. | "Remove this item?" dialog appears. |

## AC-3: Quantity above 20 is rejected with a message

| ID | Title | Steps | Expected result |
|----|-------|-------|-----------------|
| TC-27 | 21 is rejected at the boundary | 1. Enter `21`. 2. Press Enter. | Message "You can buy at most 20 of this item." is shown. Quantity reverts to 5. Line total stays 50.00. |
| TC-28 | Large value is rejected | 1. Enter `999`. 2. Press Enter. | Same message is shown. Quantity reverts to 5. |
| TC-29 | Previous quantity is the last accepted value | 1. Set quantity to `15` and press Enter. 2. Enter `25` and press Enter. | Message is shown. Quantity reverts to 15, not 5. |
| TC-30 | Message clears after a valid entry | 1. Enter `30` and press Enter. 2. Enter `10` and press Enter. | Message disappears. Quantity shows 10. |
| TC-31 | Message is tied to the correct item | Precondition: cart also contains "Gadget". 1. Set Widget quantity to `50`. 2. Press Enter. | Message appears next to Widget only. Gadget shows no message. |
| TC-32 | Rejected value does not persist | 1. Enter `21`. 2. Press Enter. 3. Reload the page. | Quantity shows 5. |
| TC-33 | Over-limit value on blur is rejected | 1. Enter `21`. 2. Click elsewhere without pressing Enter. | Message is shown. Quantity reverts to 5. |
| TC-34 | Subtotal unchanged after rejection | Precondition: cart also contains "Gadget" at 4.00, quantity 2. 1. Set Widget quantity to `21`. 2. Press Enter. | Cart subtotal stays 58.00. |

## Cross-cutting

| ID | Title | Steps | Expected result |
|----|-------|-------|-----------------|
| TC-35 | Quantity field is keyboard accessible | 1. Tab to the quantity field. 2. Type `8`. 3. Press Enter. | Field receives focus via Tab. Quantity shows 8. |
| TC-36 | Validation message is announced to screen readers | 1. With a screen reader running, enter `21`. 2. Press Enter. | The message "You can buy at most 20 of this item." is announced. |
| TC-37 | Removal dialog traps focus and is announced | 1. With a screen reader running, enter `0`. 2. Press Enter. | The dialog title "Remove this item?" is announced. Tab cycles only within the dialog. |
| TC-38 | Server rejects out-of-range values sent directly | 1. Submit a quantity update request with value `21` directly to the cart API, bypassing the UI. | Request is rejected. Cart quantity remains 5. |
| TC-39 | Server rejects non-integer values sent directly | 1. Submit a quantity update request with value `2.5` directly to the cart API. | Request is rejected. Cart quantity remains 5. |
