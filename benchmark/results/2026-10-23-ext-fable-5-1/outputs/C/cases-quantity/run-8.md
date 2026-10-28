# Test cases: CART-12 Change the quantity of an item in the cart

## Assumptions

- The cart page shows a **Quantity** field for each item. The shopper types a number or uses **+** and **−** controls. Where the story does not say otherwise, tests below use the typed field.
- The quantity is applied when the shopper leaves the field or selects **Update**. Tests say "apply the quantity" to cover both.
- The "Remove this item?" prompt has **Remove** and **Cancel** controls.
- The "You can buy at most 20 of this item." message appears next to the field and does not block the rest of the page.
- The cart subtotal and item line total update when the quantity changes.
- Stock limits, per-order limits other than 20, and signed-out carts are out of scope.

## Setup for all tests

- A shopper is signed in and has 1 item in the cart with a quantity of 2.
- The item costs 10.00, so the line total is 20.00.

## AC-1: The quantity field accepts whole numbers from 1 to 20

| ID | Title | Steps | Expected result |
| --- | --- | --- | --- |
| TC-01 | Change quantity to a value in range | 1. Open the cart. 2. Enter **5** in **Quantity**. 3. Apply the quantity. | The field shows 5. The line total shows 50.00. The subtotal updates to match. No message appears. |
| TC-02 | Lower boundary: quantity 1 | 1. Enter **1** in **Quantity**. 2. Apply the quantity. | The field shows 1. The line total shows 10.00. The item stays in the cart. |
| TC-03 | Upper boundary: quantity 20 | 1. Enter **20** in **Quantity**. 2. Apply the quantity. | The field shows 20. The line total shows 200.00. No message appears. |
| TC-04 | Decimal value is rejected | 1. Enter **2.5** in **Quantity**. 2. Apply the quantity. | The field does not accept the value, or shows a message that only whole numbers are allowed. The quantity stays 2. The line total stays 20.00. |
| TC-05 | Negative value is rejected | 1. Enter **-1** in **Quantity**. 2. Apply the quantity. | The value is rejected. The quantity stays 2. No "Remove this item?" prompt appears. |
| TC-06 | Letters and symbols are rejected | 1. Enter **abc** in **Quantity**. 2. Apply the quantity. | The field does not accept the text, or shows a message. The quantity stays 2. |
| TC-07 | Blank value is rejected | 1. Clear **Quantity**. 2. Apply the quantity. | The quantity returns to 2, or a message asks for a number. The item is not removed. |
| TC-08 | Leading zero is treated as a whole number | 1. Enter **05** in **Quantity**. 2. Apply the quantity. | The field shows 5. The line total shows 50.00. |
| TC-09 | Quantity change persists after reload | 1. Enter **7** in **Quantity**. 2. Apply the quantity. 3. Reload the cart page. | The field still shows 7. The line total shows 70.00. |
| TC-10 | Quantity change with **+** and **−** controls | 1. Select **+** 3 times. 2. Select **−** once. | The field shows 4. The line total shows 40.00. |

## AC-2: Setting the quantity to 0 asks "Remove this item?" and removes only on confirmation

| ID | Title | Steps | Expected result |
| --- | --- | --- | --- |
| TC-11 | Quantity 0 shows the remove prompt | 1. Enter **0** in **Quantity**. 2. Apply the quantity. | A prompt appears with the exact text "Remove this item?". The item is still in the cart behind the prompt. |
| TC-12 | Confirm removes the item | 1. Enter **0** in **Quantity**. 2. Apply the quantity. 3. Select **Remove**. | The item disappears from the cart. The subtotal updates. If the cart is now empty, the empty-cart state shows. |
| TC-13 | Cancel keeps the item | 1. Enter **0** in **Quantity**. 2. Apply the quantity. 3. Select **Cancel**. | The prompt closes. The item stays in the cart. The field shows the previous quantity, 2. The line total stays 20.00. |
| TC-14 | Closing the prompt without a choice keeps the item | 1. Enter **0** in **Quantity**. 2. Apply the quantity. 3. Close the prompt with the close control or the Escape key. | The item stays in the cart with quantity 2. |
| TC-15 | **−** from 1 shows the remove prompt | 1. Enter **1** in **Quantity** and apply it. 2. Select **−**. | The prompt "Remove this item?" appears. The item is not removed until the shopper selects **Remove**. |
| TC-16 | Removal persists after reload | 1. Complete TC-12. 2. Reload the cart page. | The item is still gone. |
| TC-17 | Removing one item does not affect other items | 1. Add a second item to the cart. 2. Set the first item's **Quantity** to **0** and apply it. 3. Select **Remove**. | Only the first item is removed. The second item keeps its quantity and line total. |

## AC-3: A quantity above 20 shows a message and keeps the previous quantity

| ID | Title | Steps | Expected result |
| --- | --- | --- | --- |
| TC-18 | Just above the limit: 21 | 1. Enter **21** in **Quantity**. 2. Apply the quantity. | The message "You can buy at most 20 of this item." appears with that exact text. The field shows 2. The line total stays 20.00. |
| TC-19 | Far above the limit | 1. Enter **999** in **Quantity**. 2. Apply the quantity. | The same message appears. The quantity stays 2. |
| TC-20 | **+** at 20 does not go to 21 | 1. Enter **20** in **Quantity** and apply it. 2. Select **+**. | The field stays at 20. The message "You can buy at most 20 of this item." appears, or **+** is disabled at 20. |
| TC-21 | Message clears after a valid entry | 1. Complete TC-18. 2. Enter **10** in **Quantity**. 3. Apply the quantity. | The message disappears. The field shows 10. The line total shows 100.00. |
| TC-22 | Previous quantity is the last applied value | 1. Enter **8** in **Quantity** and apply it. 2. Enter **25** in **Quantity** and apply it. | The message appears. The field shows 8, not 2. The line total shows 80.00. |
| TC-23 | Over-limit value is not saved | 1. Enter **30** in **Quantity**. 2. Apply the quantity. 3. Reload the cart page. | The field shows 2. The line total shows 20.00. |

## Cross-cutting checks

| ID | Title | Steps | Expected result |
| --- | --- | --- | --- |
| TC-24 | Checkout uses the new quantity | 1. Enter **6** in **Quantity** and apply it. 2. Select **Checkout**. | The checkout page shows the item with quantity 6 and a line total of 60.00. |
| TC-25 | Keyboard-only use | 1. Move focus to **Quantity** with the Tab key. 2. Type **4** and press Enter. 3. Repeat with **0** and use the keyboard to select **Cancel**. | Every step works without a mouse. Focus returns to the field after the prompt closes. |
| TC-26 | Screen reader announces messages | 1. With a screen reader on, enter **25** in **Quantity** and apply it. 2. Enter **0** and apply it. | The screen reader reads "You can buy at most 20 of this item." and then "Remove this item?" when each appears. |
| TC-27 | Mobile layout | 1. Open the cart on a phone-sized screen. 2. Run TC-01, TC-12 and TC-18. | The field, the prompt and the message are fully visible and usable. The numeric keyboard opens for **Quantity**. |

## Coverage summary

| Acceptance criterion | Test cases |
| --- | --- |
| AC-1 | TC-01 to TC-10 |
| AC-2 | TC-11 to TC-17 |
| AC-3 | TC-18 to TC-23 |
| Not in an AC, but needed for a release | TC-24 to TC-27 |

## Open points for the product owner

- Confirm the exact label and control names used above: **Quantity**, **Update**, **+**, **−**, **Remove**, **Cancel**, **Checkout**.
- Confirm what the field does with a decimal or letters: block the keystroke, or accept it and show a message. TC-04, TC-06 and TC-07 accept either until this is decided.
- Confirm whether the limit of 20 is the same for every item or can differ per item. If it differs, TC-18 to TC-23 need one run per limit.
