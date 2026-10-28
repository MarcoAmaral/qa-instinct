# Test cases: CART-12 Change the quantity of an item in the cart

## Assumptions

The story does not describe the cart page, so these tests assume the following. Correct the labels before running.

- Each cart item has a **Quantity** field. A change applies when the shopper presses Enter or leaves the field. There is no separate **Update** button.
- The "Remove this item?" dialog has two buttons: **Remove** and **Cancel**.
- Input that is not a whole number (decimals, negative numbers, letters, blank) keeps the previous quantity. The story does not give a message for these cases, so the tests record what appears.
- The item subtotal and the cart total update after a valid change.
- The cart is saved to the shopper's account, so a change survives a page reload.
- Stock limits below 20 are out of scope for this story.
- An item added to the cart starts with a quantity of 1.

## Common preconditions

- You are signed in as a shopper.
- The cart holds at least one item, "Blue mug", with a quantity of 2 unless a test says otherwise.
- The cart page is open.

---

### TC-01 Change the quantity to a value inside the range

Covers: AC-1

1. In the **Quantity** field for Blue mug, enter `5`.
2. Press Enter.

Expected: The field shows 5. The Blue mug subtotal and the cart total update to match 5 items. No message appears.

### TC-02 Set the quantity to the lower limit, 1

Covers: AC-1

1. In the **Quantity** field for Blue mug, enter `1`.
2. Press Enter.

Expected: The field shows 1. The item stays in the cart. No dialog and no message appear.

### TC-03 Set the quantity to the upper limit, 20

Covers: AC-1

1. In the **Quantity** field for Blue mug, enter `20`.
2. Press Enter.

Expected: The field shows 20. Subtotal and total update to match 20 items. No message appears.

### TC-04 Enter a quantity one above the limit

Covers: AC-3

1. In the **Quantity** field for Blue mug, enter `21`.
2. Press Enter.

Expected: The message "You can buy at most 20 of this item." appears. The field returns to 2. Subtotal and total do not change.

### TC-05 Enter a quantity far above the limit

Covers: AC-3

1. In the **Quantity** field for Blue mug, enter `999`.
2. Press Enter.

Expected: Same as TC-04. The message appears and the field returns to 2.

### TC-06 Message clears after a valid entry

Covers: AC-3

1. Complete TC-04 so the message is showing.
2. In the **Quantity** field, enter `3`.
3. Press Enter.

Expected: The message disappears. The field shows 3. Subtotal and total update.

### TC-07 Set the quantity to 0 and confirm removal

Covers: AC-2

1. In the **Quantity** field for Blue mug, enter `0`.
2. Press Enter.
3. In the dialog, select **Remove**.

Expected: After step 2, a dialog appears with the exact text "Remove this item?". After step 3, Blue mug is no longer in the cart and the cart total no longer includes it.

### TC-08 Set the quantity to 0 and cancel

Covers: AC-2

1. In the **Quantity** field for Blue mug, enter `0`.
2. Press Enter.
3. In the dialog, select **Cancel**.

Expected: The dialog closes. Blue mug stays in the cart with a quantity of 2. Subtotal and total do not change.

### TC-09 Set the quantity to 0 and close the dialog without choosing

Covers: AC-2

1. In the **Quantity** field for Blue mug, enter `0`.
2. Press Enter.
3. Press Esc, or select the dialog's close control.

Expected: The dialog closes. Blue mug stays in the cart with a quantity of 2. Closing the dialog counts as not confirming.

### TC-10 Remove the only item in the cart

Covers: AC-2

Precondition: The cart holds only Blue mug.

1. In the **Quantity** field, enter `0`.
2. Press Enter.
3. Select **Remove**.

Expected: The cart is empty and shows the empty-cart state. The cart total is 0.

### TC-11 Enter a decimal

Covers: AC-1 (whole numbers only)

1. In the **Quantity** field for Blue mug, enter `2.5`.
2. Press Enter.

Expected: The quantity does not change to 2.5. The field shows 2. Record any message that appears; the story does not define one.

### TC-12 Enter a negative number

Covers: AC-1

1. In the **Quantity** field for Blue mug, enter `-1`.
2. Press Enter.

Expected: The field returns to 2. The "Remove this item?" dialog does not appear. Record any message that appears.

### TC-13 Enter letters or leave the field blank

Covers: AC-1

1. In the **Quantity** field for Blue mug, enter `abc`.
2. Press Enter.
3. Clear the field so it is blank.
4. Press Enter.

Expected: After each entry, the field returns to 2. The item is not removed. Record any message that appears.

### TC-14 Enter a number with leading zeros

Covers: AC-1

1. In the **Quantity** field for Blue mug, enter `007`.
2. Press Enter.

Expected: The field shows 7. Subtotal and total update to match 7 items.

### TC-15 A change to one item does not affect another

Covers: AC-1

Precondition: The cart also holds "Red mug" with a quantity of 4.

1. In the **Quantity** field for Blue mug, enter `6`.
2. Press Enter.

Expected: Blue mug shows 6. Red mug still shows 4. The cart total equals both subtotals added together.

### TC-16 A change survives a page reload

Covers: AC-1

1. In the **Quantity** field for Blue mug, enter `8`.
2. Press Enter.
3. Reload the page.

Expected: Blue mug still shows 8 and the total matches.

### TC-17 Removal survives a page reload

Covers: AC-2

1. Complete TC-07.
2. Reload the page.

Expected: Blue mug is still absent from the cart.

---

## Coverage

| Criterion | Test cases |
| --- | --- |
| AC-1: whole numbers 1 to 20 | TC-01, TC-02, TC-03, TC-11, TC-12, TC-13, TC-14, TC-15, TC-16 |
| AC-2: quantity 0 asks before removing | TC-07, TC-08, TC-09, TC-10, TC-17 |
| AC-3: above 20 shows message, keeps previous | TC-04, TC-05, TC-06 |

## Open points for the product owner

- What message, if any, appears for decimals, negative numbers, letters and blank entries (TC-11 to TC-13)?
- Is there a **+** / **−** stepper beside the field? If so, add tests for pressing **+** at 20 and **−** at 1.
- Does the limit of 20 apply per item or across the cart? These tests assume per item.
