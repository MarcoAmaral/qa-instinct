# Test cases: CART-12 Change the quantity of an item in the cart

## Assumptions

The story does not describe the cart page, so these tests assume the following. Correct the labels before running the tests.

- The cart page shows each item with a **Quantity** text field. A change applies when the shopper leaves the field or presses Enter.
- The "Remove this item?" prompt is a dialog with two buttons, **Remove** and **Cancel**.
- The "You can buy at most 20 of this item." message appears next to the **Quantity** field and clears on the next valid change.
- Input that is not a whole number (blank, decimal, negative, letters) is outside the acceptance criteria. These tests assume the field keeps the previous quantity, as it does for values above 20.
- Stock limits below 20 are out of scope. Every test item has at least 20 in stock.
- The cart subtotal and item line total update after each accepted change.

## Common preconditions

- The shopper is on the cart page.
- The cart holds 1 item, "Test Mug", at a quantity of 5, unless a test says otherwise.

## AC-1: The quantity field accepts whole numbers from 1 to 20

| ID | Title | Steps | Expected result |
| --- | --- | --- | --- |
| TC-01 | Accept the lower boundary | Set **Quantity** to 1 and leave the field. | The quantity shows 1. The line total and subtotal update. No message appears. |
| TC-02 | Accept the upper boundary | Set **Quantity** to 20 and leave the field. | The quantity shows 20. The line total and subtotal update. No message appears. |
| TC-03 | Accept a value inside the range | Set **Quantity** to 12 and leave the field. | The quantity shows 12. The line total and subtotal update. |
| TC-04 | Increase then decrease | Set **Quantity** to 8, then to 3. | Each change applies in turn. The final quantity shows 3 and totals match 3 units. |
| TC-05 | Change persists after reload | Set **Quantity** to 7, then reload the page. | The quantity still shows 7. |
| TC-06 | Change persists across items | Add a second item "Test Plate" at quantity 2. Set "Test Mug" **Quantity** to 9. | "Test Mug" shows 9. "Test Plate" still shows 2. |
| TC-07 | Reject a decimal | Set **Quantity** to 2.5 and leave the field. | The quantity stays at 5. Totals do not change. (Assumed behaviour.) |
| TC-08 | Reject a negative number | Set **Quantity** to -1 and leave the field. | The quantity stays at 5. Totals do not change. (Assumed behaviour.) |
| TC-09 | Reject letters | Set **Quantity** to "abc" and leave the field. | The quantity stays at 5. Totals do not change. (Assumed behaviour.) |
| TC-10 | Reject a blank field | Clear **Quantity** and leave the field. | The quantity stays at 5. Totals do not change. (Assumed behaviour.) |
| TC-11 | Same value entered again | Set **Quantity** to 5 and leave the field. | The quantity stays at 5. No message or prompt appears. |

## AC-2: Setting the quantity to 0 asks to remove the item

| ID | Title | Steps | Expected result |
| --- | --- | --- | --- |
| TC-12 | Prompt appears on 0 | Set **Quantity** to 0 and leave the field. | A dialog shows "Remove this item?" with **Remove** and **Cancel**. The item is still in the cart behind the dialog. |
| TC-13 | Confirm removes the item | Set **Quantity** to 0, then select **Remove**. | "Test Mug" is no longer in the cart. The subtotal no longer includes it. |
| TC-14 | Cancel keeps the item | Set **Quantity** to 0, then select **Cancel**. | The dialog closes. "Test Mug" is still in the cart. The quantity shows 5. Totals do not change. |
| TC-15 | Closing the dialog keeps the item | Set **Quantity** to 0, then close the dialog with Escape or the close control. | Same result as TC-14. The item stays at quantity 5. |
| TC-16 | Removal persists after reload | Complete TC-13, then reload the page. | "Test Mug" is not in the cart. |
| TC-17 | Cancel persists after reload | Complete TC-14, then reload the page. | "Test Mug" is in the cart at quantity 5. |
| TC-18 | Only the chosen item is removed | Add "Test Plate" at quantity 2. Set "Test Mug" **Quantity** to 0 and select **Remove**. | "Test Mug" is removed. "Test Plate" stays at quantity 2. |
| TC-19 | Removing the last item empties the cart | With only "Test Mug" in the cart, set **Quantity** to 0 and select **Remove**. | The cart shows its empty state. The subtotal is 0 or hidden. |
| TC-20 | Prompt names the right item | Add "Test Plate" at quantity 2. Set "Test Plate" **Quantity** to 0. | The dialog relates to "Test Plate". Selecting **Remove** removes "Test Plate", not "Test Mug". |

## AC-3: A quantity above 20 shows a message and keeps the previous quantity

| ID | Title | Steps | Expected result |
| --- | --- | --- | --- |
| TC-21 | Reject the value just above the limit | Set **Quantity** to 21 and leave the field. | The message "You can buy at most 20 of this item." appears. The quantity shows 5. Totals do not change. |
| TC-22 | Reject a large value | Set **Quantity** to 999 and leave the field. | Same result as TC-21. |
| TC-23 | Message text is exact | Complete TC-21 and read the message. | The text matches "You can buy at most 20 of this item." exactly, including the full stop. |
| TC-24 | Previous quantity is the last accepted one | Set **Quantity** to 14, then to 25. | The message appears. The quantity shows 14, not 5. |
| TC-25 | Message clears after a valid change | Complete TC-21, then set **Quantity** to 10. | The message disappears. The quantity shows 10. |
| TC-26 | Message does not block other items | Add "Test Plate" at quantity 2. Set "Test Mug" **Quantity** to 30, then set "Test Plate" **Quantity** to 4. | The message shows only on "Test Mug". "Test Plate" changes to 4. |
| TC-27 | Rejected value does not persist | Complete TC-21, then reload the page. | The quantity shows 5. No message appears. |
| TC-28 | Rejected value does not reach checkout | Complete TC-21, then go to checkout. | Checkout lists "Test Mug" at quantity 5. |

## Cross-cutting checks

| ID | Title | Steps | Expected result |
| --- | --- | --- | --- |
| TC-29 | Keyboard only | Using only the keyboard, tab to **Quantity**, type 6, press Enter. Then type 0, press Enter, and tab to **Cancel**, press Enter. | Each action works without a mouse. Focus returns to the **Quantity** field after the dialog closes. |
| TC-30 | Screen reader announces results | With a screen reader on, repeat TC-21 and TC-12. | The limit message and the dialog are announced when they appear. |
| TC-31 | Mobile layout | Repeat TC-01, TC-13 and TC-21 on a phone-sized screen. | The field, dialog and message are visible and usable without horizontal scrolling. |
| TC-32 | Mini-cart or header count updates | Set **Quantity** to 8. | Any cart item count shown in the header updates to match. |

## Out of scope

- Stock limits lower than 20 per item.
- Per-order limits across several items.
- Quantity changes from the product page or checkout page.
