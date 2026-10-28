# Test Cases — CART-12: Change the quantity of an item in the cart

## Assumptions

- The quantity field is a numeric text input on the cart page with a visible confirm/update action (or it applies on blur/Enter). Tests refer to this as "apply the change".
- "Whole numbers" means the field rejects or strips non-integer and non-numeric input; the exact mechanism (blocked keystroke vs. validation error) is unspecified, so tests only assert the quantity is not changed to an invalid value.
- The upper limit of 20 is per cart line, not per product across lines or per order.
- On the "Remove this item?" dialog, the choices are a confirm action (e.g. "Remove") and a cancel action (e.g. "Keep"). Cancelling restores the previous quantity.
- The cart line subtotal and cart total recalculate after a successful quantity change.
- Error messages appear next to the affected cart line and the previous quantity is still shown in the field afterwards.
- Leading zeros ("05") are treated as the number 5.

## Preconditions (all tests)

- Shopper is on the cart page.
- Cart contains item A with quantity 5 and unit price 10.00, unless stated otherwise.
- Item A has at least 20 units in stock.

---

## AC-1: The quantity field accepts whole numbers from 1 to 20

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-01 | Set quantity to lower bound (1) | Enter `1` in item A's quantity field and apply the change. | Quantity shows 1. Line subtotal is 10.00. Cart total updates accordingly. No message is shown. |
| TC-02 | Set quantity to upper bound (20) | Enter `20` and apply the change. | Quantity shows 20. Line subtotal is 200.00. No message is shown. |
| TC-03 | Set quantity to a mid-range value | Enter `12` and apply the change. | Quantity shows 12. Line subtotal is 120.00. |
| TC-04 | Increase quantity | From 5, enter `6` and apply. | Quantity shows 6. Subtotal 60.00. |
| TC-05 | Decrease quantity | From 5, enter `2` and apply. | Quantity shows 2. Subtotal 20.00. |
| TC-06 | Re-apply the same quantity | Enter `5` (unchanged) and apply. | Quantity remains 5. No error. No duplicate line is created. |
| TC-07 | Decimal value rejected | Enter `2.5` and apply. | Quantity is not set to 2.5. Previous quantity (5) is retained or the input is prevented. |
| TC-08 | Non-numeric text rejected | Enter `abc` and apply. | Quantity is not changed. Previous quantity (5) is retained. |
| TC-09 | Negative number rejected | Enter `-1` and apply. | Quantity is not changed. Previous quantity (5) is retained. No "Remove this item?" prompt is shown. |
| TC-10 | Empty field rejected | Clear the field and apply. | Quantity is not changed to empty. Previous quantity (5) is retained. No "Remove this item?" prompt is shown. |
| TC-11 | Leading/trailing whitespace | Enter ` 7 ` and apply. | Quantity shows 7 (whitespace ignored). |
| TC-12 | Leading zero | Enter `05` and apply. | Quantity shows 5. |
| TC-13 | Quantity change persists after reload | Set quantity to 3, apply, then reload the cart page. | Quantity still shows 3. |
| TC-14 | Independent lines | Cart has items A (qty 5) and B (qty 2). Set A to 8 and apply. | A shows 8, B still shows 2. |
| TC-15 | Quantity carried to checkout | Set quantity to 4, apply, proceed to checkout. | Checkout shows item A with quantity 4. |

## AC-2: Setting the quantity to 0 asks "Remove this item?" and removes only on confirmation

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-16 | Prompt appears on 0 | Enter `0` and apply the change. | A dialog with the text "Remove this item?" is displayed. Item A is still in the cart behind the dialog with quantity 5. |
| TC-17 | Confirm removal | Enter `0`, apply, then confirm in the dialog. | Item A is removed from the cart. Cart total no longer includes item A. |
| TC-18 | Cancel removal | Enter `0`, apply, then cancel/dismiss the dialog. | Item A remains in the cart with quantity 5. Line subtotal is 50.00. |
| TC-19 | Close dialog without choosing | Enter `0`, apply, then close the dialog (close icon / Escape / click outside). | Treated as cancel. Item A remains with quantity 5. |
| TC-20 | Confirmed removal persists | Perform TC-17, then reload the cart page. | Item A is not in the cart. |
| TC-21 | Cancelled removal persists | Perform TC-18, then reload the cart page. | Item A is in the cart with quantity 5. |
| TC-22 | Remove last item | Cart contains only item A. Enter `0`, apply, confirm. | Cart is empty and the empty-cart state is shown. |
| TC-23 | Remove one of several items | Cart has items A and B. Set A to 0, apply, confirm. | Only A is removed. B is unchanged. |
| TC-24 | Prompt is item-specific | Cart has items A and B. Set B to 0, apply, confirm. | B is removed, A remains. |
| TC-25 | Zero with leading zero | Enter `00` and apply. | Treated as 0: "Remove this item?" dialog appears. |
| TC-26 | No prompt for other values | Enter `1`, apply. | No "Remove this item?" dialog appears. |

## AC-3: Quantity above 20 shows a message and keeps the previous quantity

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-27 | Just above limit (21) | Enter `21` and apply. | Message "You can buy at most 20 of this item." is shown for item A. Quantity field shows 5. Line subtotal remains 50.00. |
| TC-28 | Far above limit | Enter `999` and apply. | Same message is shown. Quantity remains 5. |
| TC-29 | Very large value | Enter `99999999999` and apply. | Same message is shown. Quantity remains 5. No crash or unhandled error. |
| TC-30 | Previous quantity retained is the last applied value | Set quantity to 10 and apply (success). Then enter `25` and apply. | Message is shown. Quantity shows 10 (not 5 and not 25). |
| TC-31 | Over-limit does not persist | Perform TC-27, then reload the cart page. | Quantity is 5. |
| TC-32 | Message clears on valid change | Perform TC-27, then enter `15` and apply. | Message is no longer displayed. Quantity shows 15. |
| TC-33 | Message is line-specific | Cart has items A and B. Enter `30` for A and apply. | Message appears for A only. B shows no message and its quantity is unchanged. |
| TC-34 | Boundary pair | Enter `20`, apply; then enter `21`, apply. | 20 is accepted. 21 is rejected with the message and quantity stays 20. |
| TC-35 | Over-limit when already at limit | Quantity is 20. Enter `21` and apply. | Message is shown. Quantity remains 20. |

## Cross-cutting / negative

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-36 | Rapid successive changes | Enter `3`, apply; immediately enter `7`, apply. | Final quantity is 7. Subtotal 70.00. |
| TC-37 | Server-side enforcement of upper limit | Send a quantity update request directly to the cart API with quantity 21 (bypassing the UI). | Request is rejected. Cart quantity remains 5. |
| TC-38 | Server-side enforcement of lower bound | Send a cart update request with quantity -1 or 2.5. | Request is rejected. Cart quantity remains 5. |
| TC-39 | Server-side zero without confirmation | Send a cart update request with quantity 0. | Behaviour is consistent with AC-2 (item removed, since confirmation is a UI concern) or rejected; it must not leave a line with quantity 0 in the cart. |
| TC-40 | Keyboard accessibility | Tab to the quantity field, type `4`, press Enter. | Change is applied. Quantity shows 4. |
| TC-41 | Dialog accessibility | Trigger the "Remove this item?" dialog via keyboard only. | Focus moves into the dialog. Confirm and cancel are reachable via Tab. Escape cancels. |
| TC-42 | Error message accessibility | Trigger the over-limit message. | Message is announced by screen readers (e.g. via aria-live or associated with the field) and is visible without colour alone. |

## Traceability

| AC | Test cases |
|---|---|
| AC-1 | TC-01 – TC-15, TC-36, TC-38, TC-40 |
| AC-2 | TC-16 – TC-26, TC-39, TC-41 |
| AC-3 | TC-27 – TC-35, TC-37, TC-42 |
