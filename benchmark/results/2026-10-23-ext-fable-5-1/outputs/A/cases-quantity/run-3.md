# Test Cases: CART-12 Change the quantity of an item in the cart

## Assumptions

- The quantity field is a numeric input with an editable text box; it is not stepper-only. If the real UI also has +/- buttons, the boundary cases below apply to them as well.
- A quantity change is applied on blur or Enter, not on each keystroke. "Previous quantity" in AC-3 means the last successfully applied quantity.
- Values below 0, decimals, and non-numeric input are rejected by keeping the previous quantity. The story does not specify a message for these, so the test only checks that the previous quantity is restored.
- Cancelling the "Remove this item?" prompt restores the previous quantity.
- The cart line subtotal and cart total update after a successful quantity change.
- Stock limits per product are out of scope for this story. The 20 limit is a fixed rule.

## Preconditions (all cases)

- Shopper is on the cart page.
- Cart contains one item, "Item A", with unit price 10.00 and quantity 5, unless the case says otherwise.

## AC-1: Accepts whole numbers from 1 to 20

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-01 | Set quantity to lower bound 1 | Change quantity to 1 and apply. | Quantity shows 1. Line subtotal is 10.00. No message is shown. |
| TC-02 | Set quantity to upper bound 20 | Change quantity to 20 and apply. | Quantity shows 20. Line subtotal is 200.00. No message is shown. |
| TC-03 | Set quantity to a mid-range value | Change quantity to 7 and apply. | Quantity shows 7. Line subtotal is 70.00. |
| TC-04 | Increase then decrease in one session | Change quantity to 12, apply, then change to 3, apply. | Quantity shows 3 after the second change. Line subtotal is 30.00. |
| TC-05 | Change persists after reload | Change quantity to 8, apply, reload the page. | Quantity still shows 8. |
| TC-06 | Change with multiple items in cart | Precondition: cart also has "Item B" at quantity 2. Change Item A quantity to 4 and apply. | Item A shows 4. Item B still shows 2. Cart total reflects both lines. |
| TC-07 | Decimal value is rejected | Enter 2.5 and apply. | Quantity remains 5. Entry is not accepted as 2 or 3. |
| TC-08 | Negative value is rejected | Enter -1 and apply. | Quantity remains 5. No "Remove this item?" prompt appears. |
| TC-09 | Non-numeric value is rejected | Enter "abc" and apply. | Quantity remains 5. |
| TC-10 | Empty field is rejected | Clear the field and apply. | Quantity remains 5. Item is not removed and no prompt appears. |
| TC-11 | Leading zero is accepted as the number | Enter 07 and apply. | Quantity shows 7. |
| TC-12 | Surrounding whitespace is tolerated | Enter " 6 " and apply. | Quantity shows 6. |
| TC-13 | Re-entering the same quantity | Enter 5 (the current value) and apply. | Quantity remains 5. No message and no prompt. |

## AC-2: Quantity 0 asks for confirmation before removal

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-14 | Zero prompts for confirmation | Change quantity to 0 and apply. | A prompt with the text "Remove this item?" is shown. The item is still in the cart while the prompt is open. |
| TC-15 | Confirm removal | Change quantity to 0, apply, confirm the prompt. | Item A is removed from the cart. Cart total no longer includes it. |
| TC-16 | Cancel removal | Change quantity to 0, apply, cancel the prompt. | Item A remains in the cart with quantity 5. Line subtotal is 50.00. |
| TC-17 | Dismiss prompt without choosing | Change quantity to 0, apply, close the prompt by pressing Escape or clicking outside. | Treated as cancel. Item A remains with quantity 5. |
| TC-18 | Removing the last item empties the cart | Precondition: cart contains only Item A. Change quantity to 0, apply, confirm. | Cart shows its empty state. Cart total is 0.00. |
| TC-19 | Removing one of several items | Precondition: cart also has Item B at quantity 2. Set Item A to 0, apply, confirm. | Item A is removed. Item B remains unchanged at quantity 2. |
| TC-20 | Removal persists after reload | Set quantity to 0, apply, confirm, reload the page. | Item A is not in the cart. |
| TC-21 | Cancelled removal persists after reload | Set quantity to 0, apply, cancel, reload the page. | Item A is in the cart with quantity 5. |
| TC-22 | Prompt text is exact | Set quantity to 0 and apply. | Prompt text reads exactly "Remove this item?". |

## AC-3: Quantity above 20 shows a message and keeps the previous quantity

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-23 | Just above the limit | Enter 21 and apply. | Message "You can buy at most 20 of this item." is shown. Quantity remains 5. Line subtotal is 50.00. |
| TC-24 | Far above the limit | Enter 999 and apply. | Same message is shown. Quantity remains 5. |
| TC-25 | Previous quantity is the last applied value, not the default | Change quantity to 15, apply, then enter 25 and apply. | Message is shown. Quantity remains 15, not 5. |
| TC-26 | Message text is exact | Enter 21 and apply. | Message reads exactly "You can buy at most 20 of this item." |
| TC-27 | Valid entry after an over-limit entry | Enter 21, apply, then enter 20 and apply. | Message is cleared. Quantity shows 20. |
| TC-28 | Over-limit value is not persisted | Enter 21, apply, reload the page. | Quantity shows 5. |
| TC-29 | Over-limit on one item does not affect others | Precondition: cart also has Item B at quantity 2. Enter 30 for Item A and apply. | Message is shown for Item A only. Item A remains 5. Item B remains 2. |
| TC-30 | Limit applies per item line | Precondition: cart has Item A at 20 and Item B at 20. Change Item B to 20 again and apply. | No message. Both items remain at 20. The limit is not a cart-wide limit. |

## Boundary summary

| Input | Expected behaviour |
|---|---|
| -1 | Rejected, previous quantity kept |
| 0 | "Remove this item?" prompt |
| 1 | Accepted |
| 20 | Accepted |
| 21 | "You can buy at most 20 of this item.", previous quantity kept |

## Out of scope for this story

- Per-product stock limits lower than 20.
- Quantity changes from the product page or mini-cart.
- Concurrent edits from another session.
