# Test cases: CART-12 Change the quantity of an item in the cart

## Assumptions

The story does not describe the cart page, so these test cases assume the following. An editor or the product owner should correct any label that differs from the product.

- The cart page shows each item with a **Quantity** field, a **–** button and a **+** button.
- A typed value applies when the shopper presses Enter or leaves the field.
- The prompt in AC-2 is a dialog with the text "Remove this item?" and two buttons: **Remove** and **Cancel**.
- The message in AC-3 appears below the **Quantity** field and disappears on the next valid change.
- Values that are not whole numbers (letters, decimals, blanks, negatives) are rejected and the previous quantity is kept. The story does not say which message, if any, appears. Expected results below say "the previous quantity is kept" and leave the message open.
- The item subtotal and the cart total update after every accepted change.
- The quantity is saved to the cart on the server, so it survives a page refresh.
- The 20-item limit is per line item, not per cart.

Each test starts from the same state unless the preconditions say otherwise: a signed-in shopper has 1 item in the cart with a quantity of 2, and the cart page is open.

## AC-1: The quantity field accepts whole numbers from 1 to 20

| ID | Title | Steps | Expected result |
| --- | --- | --- | --- |
| TC-01 | Set a quantity in the middle of the range | 1. Select the **Quantity** field. 2. Enter `5`. 3. Press Enter. | The field shows 5. The item subtotal and cart total update to 5 times the unit price. |
| TC-02 | Set the lowest allowed quantity | 1. Enter `1` in the **Quantity** field. 2. Press Enter. | The field shows 1. The item stays in the cart. Totals update. |
| TC-03 | Set the highest allowed quantity | 1. Enter `20` in the **Quantity** field. 2. Press Enter. | The field shows 20. No message appears. Totals update. |
| TC-04 | Increase the quantity with the plus button | 1. Select **+** once. | The field shows 3. Totals update. |
| TC-05 | Decrease the quantity with the minus button | 1. Select **–** once. | The field shows 1. Totals update. |
| TC-06 | Enter a decimal | 1. Enter `2.5` in the **Quantity** field. 2. Press Enter. | The previous quantity (2) is kept. Totals do not change. |
| TC-07 | Enter letters | 1. Enter `abc` in the **Quantity** field. 2. Press Enter. | The previous quantity (2) is kept. Totals do not change. |
| TC-08 | Enter a negative number | 1. Enter `-1` in the **Quantity** field. 2. Press Enter. | The previous quantity (2) is kept. The "Remove this item?" dialog does not open. |
| TC-09 | Leave the field blank | 1. Clear the **Quantity** field. 2. Press Enter. | The previous quantity (2) is kept. The item is not removed. |
| TC-10 | Enter a number with leading zeros | 1. Enter `007` in the **Quantity** field. 2. Press Enter. | The field shows 7. Totals update to 7 times the unit price. |
| TC-11 | Enter a number with spaces | 1. Enter ` 4 ` in the **Quantity** field. 2. Press Enter. | The field shows 4. Totals update. |
| TC-12 | Apply a change by leaving the field | 1. Enter `6` in the **Quantity** field. 2. Select elsewhere on the page. | The field shows 6. Totals update without pressing Enter. |
| TC-13 | Quantity survives a refresh | 1. Enter `8` in the **Quantity** field. 2. Press Enter. 3. Refresh the page. | The field still shows 8. Totals match 8 times the unit price. |
| TC-14 | Change one item without affecting another | Precondition: the cart has 2 different items, each with a quantity of 2. 1. Enter `9` in the **Quantity** field of the first item. 2. Press Enter. | The first item shows 9. The second item still shows 2. The cart total is the sum of both. |

## AC-2: Setting the quantity to 0 asks "Remove this item?"

| ID | Title | Steps | Expected result |
| --- | --- | --- | --- |
| TC-15 | Type 0 and confirm removal | 1. Enter `0` in the **Quantity** field. 2. Press Enter. 3. In the dialog, select **Remove**. | The dialog shows the text "Remove this item?" before step 3. After step 3, the item is gone from the cart and the cart total updates. |
| TC-16 | Type 0 and cancel | 1. Enter `0` in the **Quantity** field. 2. Press Enter. 3. In the dialog, select **Cancel**. | The dialog closes. The item stays in the cart with the previous quantity (2). Totals do not change. |
| TC-17 | Reach 0 with the minus button | Precondition: the item quantity is 1. 1. Select **–** once. | The "Remove this item?" dialog opens. The item is not removed until the shopper selects **Remove**. |
| TC-18 | Close the dialog without choosing | 1. Enter `0` in the **Quantity** field. 2. Press Enter. 3. Press Escape, or select outside the dialog. | The dialog closes. The item stays in the cart with the previous quantity (2). |
| TC-19 | Remove the only item in the cart | 1. Enter `0` in the **Quantity** field. 2. Press Enter. 3. Select **Remove**. | The cart is empty and shows the empty-cart state. The cart total is 0. |
| TC-20 | Remove one of several items | Precondition: the cart has 2 different items. 1. Enter `0` in the first item's **Quantity** field. 2. Press Enter. 3. Select **Remove**. | Only the first item is removed. The second item keeps its quantity. The cart total updates. |
| TC-21 | Removal survives a refresh | 1. Complete TC-15. 2. Refresh the page. | The item is still gone. |
| TC-22 | Cancel then change the quantity again | 1. Complete TC-16. 2. Enter `3` in the **Quantity** field. 3. Press Enter. | The field shows 3. No dialog opens. Totals update. |

## AC-3: A quantity above 20 shows a message and keeps the previous quantity

| ID | Title | Steps | Expected result |
| --- | --- | --- | --- |
| TC-23 | Type one above the limit | 1. Enter `21` in the **Quantity** field. 2. Press Enter. | The message "You can buy at most 20 of this item." appears. The field shows the previous quantity (2). Totals do not change. |
| TC-24 | Type a much larger number | 1. Enter `999` in the **Quantity** field. 2. Press Enter. | The same message appears. The field shows 2. Totals do not change. |
| TC-25 | Use the plus button at the limit | Precondition: the item quantity is 20. 1. Select **+** once. | The message "You can buy at most 20 of this item." appears. The field still shows 20. |
| TC-26 | Message clears after a valid change | 1. Complete TC-23. 2. Enter `10` in the **Quantity** field. 3. Press Enter. | The message disappears. The field shows 10. Totals update. |
| TC-27 | Limit applies per item | Precondition: the cart has 2 different items, each with a quantity of 20. 1. Confirm the cart total. | Both items show 20 with no message. The cart holds 40 units in total. |
| TC-28 | Message text matches exactly | 1. Complete TC-23. 2. Read the message. | The text is exactly "You can buy at most 20 of this item." including the full stop. |
| TC-29 | Limit holds when the request bypasses the page | 1. Send a cart update request directly to the server with a quantity of 21. 2. Reload the cart page. | The server rejects the change. The cart page shows the previous quantity (2). |

## Accessibility and other checks

| ID | Title | Steps | Expected result |
| --- | --- | --- | --- |
| TC-30 | Change the quantity with the keyboard only | 1. Tab to the **Quantity** field. 2. Enter `4`. 3. Press Enter. 4. Tab to **+** and press Enter. | The field shows 5. Every control can be reached and used without a mouse. |
| TC-31 | Dialog is announced by a screen reader | 1. Enter `0` and press Enter with a screen reader running. | The screen reader reads "Remove this item?" and the two button names. Focus moves into the dialog. |
| TC-32 | Limit message is announced by a screen reader | 1. Enter `21` and press Enter with a screen reader running. | The screen reader reads "You can buy at most 20 of this item." without the shopper moving focus. |
| TC-33 | Change the quantity on a phone | 1. Open the cart on a mobile browser. 2. Select the **Quantity** field. 3. Enter `3`. | A numeric keypad opens. The field shows 3 and totals update. |

## Coverage summary

| Acceptance criterion | Test cases |
| --- | --- |
| AC-1 | TC-01 to TC-14, TC-30, TC-33 |
| AC-2 | TC-15 to TC-22, TC-31 |
| AC-3 | TC-23 to TC-29, TC-32 |

## Open questions for the product owner

These do not block testing, but the expected results above depend on the answers.

- What should the shopper see after entering letters, a decimal, a blank or a negative number? The story names no message for these cases.
- Does the limit of 20 apply per line item or per cart?
- Does a change apply on Enter, on leaving the field, or on a separate **Update** button?
