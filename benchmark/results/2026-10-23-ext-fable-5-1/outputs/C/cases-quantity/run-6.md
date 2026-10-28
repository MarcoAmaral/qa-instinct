# Test cases: CART-12 Change the quantity of an item in the cart

## Assumptions

The story does not describe the interface, so these tests assume the following. Correct the labels before running the tests.

- The cart page shows each item with a field labelled **Quantity**. The field is a text input, not a dropdown. The shopper types a value and it applies when they press Enter or leave the field.
- The remove prompt is a dialog with the text "Remove this item?" and 2 buttons: **Remove** and **Cancel**.
- The limit message "You can buy at most 20 of this item." appears under the **Quantity** field for that item.
- The limit of 20 is per cart line, not per order.
- The item subtotal and the cart total update when the quantity changes.
- Stock levels are not part of this story. Every test uses an item with at least 20 in stock.
- Each test starts with a signed-in shopper and a cart that holds 1 item, "Blue Notebook", at a quantity of 5, unless the test says otherwise.

## AC-1: The quantity field accepts whole numbers from 1 to 20

### TC-01 Change the quantity to a value inside the range

1. Open the cart.
2. In the **Quantity** field for Blue Notebook, enter `7`.
3. Press Enter.

Expected: the field shows 7. The item subtotal shows 7 times the unit price. The cart total updates to match. No message appears.

### TC-02 Lower boundary: set the quantity to 1

1. Open the cart.
2. In the **Quantity** field, enter `1`.
3. Press Enter.

Expected: the field shows 1. The item stays in the cart. The subtotal shows the unit price once. No message appears.

### TC-03 Upper boundary: set the quantity to 20

1. Open the cart.
2. In the **Quantity** field, enter `20`.
3. Press Enter.

Expected: the field shows 20. The subtotal shows 20 times the unit price. No limit message appears.

### TC-04 Decimal value is rejected

1. Open the cart.
2. In the **Quantity** field, enter `2.5`.
3. Press Enter.

Expected: the quantity is not changed. The field shows the previous quantity, 5. A message says the quantity must be a whole number. The subtotal does not change.

Assumption: the exact wording of the whole-number message is not in the story. Record the actual text.

### TC-05 Negative value is rejected

1. Open the cart.
2. In the **Quantity** field, enter `-3`.
3. Press Enter.

Expected: the quantity is not changed. The field shows 5. A message says the quantity must be between 1 and 20. The remove prompt does not appear.

### TC-06 Letters and symbols are rejected

1. Open the cart.
2. In the **Quantity** field, enter `abc`.
3. Press Enter.
4. Repeat steps 2 and 3 with `1e2`, `+4`, and a single space.

Expected: in every case the quantity is not changed and the field shows 5. A message says the quantity must be a whole number. The remove prompt does not appear.

### TC-07 Empty field is rejected

1. Open the cart.
2. Clear the **Quantity** field.
3. Press Enter.

Expected: the quantity is not changed. The field shows 5. The item is not removed. The remove prompt does not appear.

### TC-08 Leading zeros are read as the number

1. Open the cart.
2. In the **Quantity** field, enter `007`.
3. Press Enter.

Expected: the field shows 7. The subtotal shows 7 times the unit price.

### TC-09 Entering the same quantity makes no change

1. Open the cart.
2. In the **Quantity** field, enter `5`.
3. Press Enter.

Expected: the field shows 5. No message appears. The cart total does not change.

### TC-10 Change applies when the shopper leaves the field

1. Open the cart.
2. In the **Quantity** field, enter `3`.
3. Select anywhere outside the field.

Expected: the field shows 3 and the subtotal updates, the same as pressing Enter.

### TC-11 Change persists after a page reload

1. Open the cart.
2. In the **Quantity** field, enter `9`.
3. Press Enter.
4. Reload the page.

Expected: the field still shows 9. The cart total matches 9 items.

### TC-12 Each item keeps its own quantity

Precondition: the cart holds Blue Notebook at 5 and Red Pen at 2.

1. Open the cart.
2. In the **Quantity** field for Blue Notebook, enter `12`.
3. Press Enter.

Expected: Blue Notebook shows 12. Red Pen still shows 2. The cart total equals both lines added together.

## AC-2: Setting the quantity to 0 asks to remove the item

### TC-13 Enter 0 and confirm removal

1. Open the cart.
2. In the **Quantity** field, enter `0`.
3. Press Enter.
   A dialog opens with the text "Remove this item?".
4. Select **Remove**.

Expected: Blue Notebook is no longer in the cart. The cart total no longer includes it. If it was the only item, the cart shows its empty state.

### TC-14 Enter 0 and cancel removal

1. Open the cart.
2. In the **Quantity** field, enter `0`.
3. Press Enter.
   A dialog opens with the text "Remove this item?".
4. Select **Cancel**.

Expected: the dialog closes. Blue Notebook is still in the cart. The **Quantity** field shows the previous quantity, 5. The subtotal does not change.

### TC-15 Enter 0 and close the dialog without choosing

1. Open the cart.
2. In the **Quantity** field, enter `0`.
3. Press Enter.
4. Press Escape, or select the dialog's close control.

Expected: the dialog closes without removing the item. The field shows 5. This matches cancelling.

### TC-16 Enter 00

1. Open the cart.
2. In the **Quantity** field, enter `00`.
3. Press Enter.

Expected: the remove dialog opens, the same as entering 0.

### TC-17 The dialog names only the item being changed

Precondition: the cart holds Blue Notebook at 5 and Red Pen at 2.

1. Open the cart.
2. In the **Quantity** field for Red Pen, enter `0`.
3. Press Enter.
4. Select **Remove**.

Expected: Red Pen is removed. Blue Notebook stays at 5.

### TC-18 Confirmed removal persists after a page reload

1. Complete TC-13.
2. Reload the page.

Expected: Blue Notebook is not in the cart.

## AC-3: A quantity above 20 shows a message and keeps the previous quantity

### TC-19 Boundary: enter 21

1. Open the cart.
2. In the **Quantity** field, enter `21`.
3. Press Enter.

Expected: the message "You can buy at most 20 of this item." appears under the field. The field shows the previous quantity, 5. The subtotal does not change.

### TC-20 Enter a very large number

1. Open the cart.
2. In the **Quantity** field, enter `999999`.
3. Press Enter.

Expected: the same message appears. The field shows 5. The page does not freeze or show an error.

### TC-21 The message clears after a valid change

1. Complete TC-19.
2. In the **Quantity** field, enter `10`.
3. Press Enter.

Expected: the message disappears. The field shows 10. The subtotal shows 10 times the unit price.

### TC-22 Over-limit entry does not change the cart after a reload

1. Complete TC-19.
2. Reload the page.

Expected: the field shows 5.

### TC-23 Over-limit entry from a quantity of 20

Precondition: Blue Notebook is at a quantity of 20.

1. Open the cart.
2. In the **Quantity** field, enter `25`.
3. Press Enter.

Expected: the message appears. The field shows 20.

### TC-24 Message wording matches the story exactly

1. Complete TC-19.
2. Compare the message to the story text.

Expected: the message reads "You can buy at most 20 of this item." with the same capitalisation, number and full stop.

## Accessibility and device checks

### TC-25 Keyboard only

1. Open the cart.
2. Use Tab to move focus to the **Quantity** field.
3. Enter `4` and press Enter.
4. Repeat with `0`, then use Tab and Enter to choose **Cancel** in the dialog.

Expected: every action completes without a mouse. Focus moves into the dialog when it opens and returns to the **Quantity** field when it closes.

### TC-26 Screen reader announces the messages

1. Turn on a screen reader.
2. Complete TC-19.
3. Complete TC-13 up to step 3.

Expected: the limit message is read out when it appears. The dialog title "Remove this item?" is read out when the dialog opens.

### TC-27 Mobile

1. Open the cart on a phone.
2. Select the **Quantity** field.
3. Complete TC-01, TC-13 and TC-19.

Expected: a numeric keyboard opens. Each test gives the same result as on desktop. The message and the dialog fit the screen without cutting off text.

## Traceability

| Acceptance criterion | Test cases |
| --- | --- |
| AC-1 | TC-01 to TC-12, TC-25, TC-27 |
| AC-2 | TC-13 to TC-18, TC-25, TC-26, TC-27 |
| AC-3 | TC-19 to TC-24, TC-26, TC-27 |

## Open points for the product owner

- Whether the field should block non-numeric characters as they are typed, or reject them on submit. TC-04 to TC-07 assume rejection on submit.
- Whether the limit of 20 applies per cart line or across all lines of the same product.
- Whether an item with less than 20 in stock shows a different message. Not covered here.
