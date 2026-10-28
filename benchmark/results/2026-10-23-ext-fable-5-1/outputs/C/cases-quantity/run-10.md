# Test cases: CART-12 Change the quantity of an item in the cart

## Assumptions

The story does not say how the cart page is laid out, so these test cases assume the labels below. Correct them before the test run if the product uses different ones.

- The cart shows a **Quantity** field next to each item. The shopper types a number, or uses **+** and **−** buttons, then leaves the field or selects **Update**.
- The confirmation dialog in AC-2 is titled **Remove this item?** and has two buttons: **Remove** and **Cancel**.
- The message in AC-3 appears next to the **Quantity** field, and the field goes back to the previous quantity at the same time.
- Values the field does not accept (decimals, negatives, letters, blank) are treated as invalid. The story does not say what happens, so the assumed behaviour is: the field keeps the previous quantity and shows no silent change. The exact message, if any, is a question for the product owner.
- The cart subtotal and the item line total update whenever a quantity change is accepted.
- The 20-item limit is per line item, not per cart.
- Stock limits below 20 are out of scope for this story.
- The shopper can be signed in or a guest. The cart has at least one item before each test.

## Test cases

Each test starts on the cart page with one item at quantity 2 unless the preconditions say otherwise.

### AC-1: The quantity field accepts whole numbers from 1 to 20

| ID | Title | Steps | Expected result |
| --- | --- | --- | --- |
| TC-01 | Change to a value in range | Enter **5** in **Quantity**, then leave the field. | The quantity shows 5. The line total and subtotal update to 5 times the unit price. |
| TC-02 | Lower boundary: 1 | Enter **1**, then leave the field. | The quantity shows 1. No dialog opens. Totals update. |
| TC-03 | Upper boundary: 20 | Enter **20**, then leave the field. | The quantity shows 20. No message appears. Totals update. |
| TC-04 | Increase with the plus button | Select **+** once. | The quantity shows 3. Totals update. |
| TC-05 | Decrease with the minus button | Select **−** once. | The quantity shows 1. Totals update. |
| TC-06 | Plus button at 20 | Precondition: quantity is 20. Select **+**. | The quantity stays 20. The message **You can buy at most 20 of this item.** appears (see AC-3). |
| TC-07 | Decimal value | Enter **2.5**, then leave the field. | The field keeps 2. Totals do not change. |
| TC-08 | Negative value | Enter **-1**, then leave the field. | The field keeps 2. No dialog opens. Totals do not change. |
| TC-09 | Letters or symbols | Enter **abc**, then leave the field. | The field keeps 2. Totals do not change. |
| TC-10 | Blank value | Clear the field, then leave it. | The field keeps 2. The item is not removed. |
| TC-11 | Leading zero | Enter **07**, then leave the field. | The quantity shows 7. Totals update. |
| TC-12 | Change persists after reload | Enter **4**, leave the field, then reload the page. | The quantity still shows 4. |
| TC-13 | Two items changed independently | Precondition: cart has two different items. Change the first to **3** and the second to **6**. | Each item shows its own new quantity. The subtotal reflects both. |

### AC-2: Setting the quantity to 0 asks before removing

| ID | Title | Steps | Expected result |
| --- | --- | --- | --- |
| TC-14 | Typing 0 opens the dialog | Enter **0**, then leave the field. | A dialog titled **Remove this item?** opens with **Remove** and **Cancel**. The item is still in the cart behind the dialog. |
| TC-15 | Minus button from 1 opens the dialog | Precondition: quantity is 1. Select **−**. | The **Remove this item?** dialog opens. |
| TC-16 | Confirm removal | In the dialog, select **Remove**. | The item disappears from the cart. The subtotal no longer includes it. |
| TC-17 | Cancel removal | In the dialog, select **Cancel**. | The dialog closes. The item stays with quantity 2. Totals do not change. |
| TC-18 | Close the dialog without choosing | Press **Esc** or select outside the dialog. | Same result as **Cancel**: the item stays with quantity 2. |
| TC-19 | Removing the last item | Precondition: cart has one item. Enter **0**, then select **Remove**. | The cart shows its empty state. The subtotal is 0. |
| TC-20 | Removal persists after reload | Complete TC-16, then reload the page. | The item is still gone. |
| TC-21 | Cancel persists after reload | Complete TC-17, then reload the page. | The item is still in the cart with quantity 2. |

### AC-3: A quantity above 20 is rejected

| ID | Title | Steps | Expected result |
| --- | --- | --- | --- |
| TC-22 | Just above the limit: 21 | Enter **21**, then leave the field. | The message **You can buy at most 20 of this item.** appears. The field shows 2. Totals do not change. |
| TC-23 | Far above the limit | Enter **999**, then leave the field. | Same as TC-22. |
| TC-24 | Previous quantity was the limit | Precondition: quantity is 20. Enter **25**, then leave the field. | The message appears. The field shows 20. |
| TC-25 | Message clears after a valid change | Complete TC-22, then enter **10** and leave the field. | The message disappears. The quantity shows 10. Totals update. |
| TC-26 | Limit applies per item, not per cart | Precondition: cart has two different items. Set the first to **20**, then the second to **20**. | Both changes are accepted. No message appears. |
| TC-27 | Rejected value does not persist | Complete TC-22, then reload the page. | The quantity still shows 2. |

### Cross-cutting checks

| ID | Title | Steps | Expected result |
| --- | --- | --- | --- |
| TC-28 | Keyboard only | Using only the keyboard, tab to **Quantity**, enter **3**, and press **Enter**. | The quantity shows 3. Focus stays on or near the field. |
| TC-29 | Screen reader announces the limit message | With a screen reader on, complete TC-22. | The message **You can buy at most 20 of this item.** is read aloud when it appears. |
| TC-30 | Dialog is reachable by keyboard | Complete TC-14, then press **Tab**. | Focus moves inside the dialog between **Remove** and **Cancel**. |
| TC-31 | Mobile layout | On a phone-sized screen, complete TC-01, TC-14 and TC-22. | Each behaves as described. The dialog and message are fully visible without scrolling sideways. |
| TC-32 | Guest cart | Signed out, add an item, then complete TC-01 and TC-16. | Both behave as described. |

## Open questions for the product owner

- What should the shopper see when they enter a decimal, a negative number, letters or nothing? The story only covers 0 and values above 20.
- Does the change apply when the shopper leaves the field, or only after selecting an **Update** button?
- Should the **Remove this item?** dialog name the product, for example **Remove Blue Mug from your cart?**
