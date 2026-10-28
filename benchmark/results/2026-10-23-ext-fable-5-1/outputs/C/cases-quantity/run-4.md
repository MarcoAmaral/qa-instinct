# Test cases: CART-12 Change the quantity of an item in the cart

## Assumptions

The story does not describe the cart page, so these tests assume the following. Correct any label that does not match the product before running.

- Each cart item has a number field labelled **Quantity**. A change applies when the shopper presses Enter or moves focus out of the field.
- The "Remove this item?" prompt is a dialog with a **Remove** button and a **Cancel** button. Closing the dialog another way (Esc, the close icon) counts as cancel.
- The "You can buy at most 20 of this item." message appears next to the **Quantity** field of that item only, and clears on the next valid change.
- Entries that are not whole numbers (decimals, negatives, letters, blank) are not covered by the story. These tests assume they are rejected and the previous quantity is kept, with no removal prompt.
- The limit of 20 applies per cart item, not to the whole cart.
- The item subtotal and the cart total update to match the new quantity.
- Stock limits, discounts and sign-in state are out of scope.

**Shared precondition for every test:** the shopper is on the cart page with one item, "Blue mug", at quantity 2 and unit price 10.00, unless the test says otherwise.

## AC-1: The quantity field accepts whole numbers from 1 to 20

### TC-01 Increase the quantity within range

1. In the **Quantity** field for Blue mug, enter `5`.
2. Press Enter.

**Expected:** the field shows 5. The item subtotal shows 50.00 and the cart total updates to match. No message or dialog appears.

### TC-02 Decrease the quantity within range

Precondition: Blue mug is at quantity 5.

1. In the **Quantity** field, enter `2`.
2. Press Enter.

**Expected:** the field shows 2. The subtotal shows 20.00. No message or dialog appears.

### TC-03 Set the quantity to the lower limit, 1

1. In the **Quantity** field, enter `1`.
2. Press Enter.

**Expected:** the field shows 1. The item stays in the cart. No removal prompt appears.

### TC-04 Set the quantity to the upper limit, 20

1. In the **Quantity** field, enter `20`.
2. Press Enter.

**Expected:** the field shows 20. The subtotal shows 200.00. No limit message appears.

### TC-05 Apply the change by leaving the field

1. In the **Quantity** field, enter `4`.
2. Select anywhere outside the field.

**Expected:** the field shows 4 and the subtotal updates, the same as pressing Enter.

### TC-06 Change one item without affecting another

Precondition: the cart also holds "Red bowl" at quantity 3.

1. In the **Quantity** field for Blue mug, enter `6`.
2. Press Enter.

**Expected:** Blue mug shows 6. Red bowl still shows 3. The cart total reflects both.

### TC-07 Change persists after reload

1. In the **Quantity** field, enter `7`.
2. Press Enter.
3. Reload the page.

**Expected:** Blue mug still shows quantity 7.

## AC-2: Setting the quantity to 0 asks "Remove this item?"

### TC-08 Set the quantity to 0 and confirm removal

1. In the **Quantity** field, enter `0`.
2. Press Enter.
3. In the dialog, select **Remove**.

**Expected:** after step 2, a dialog shows the exact text "Remove this item?". After step 3, Blue mug is no longer in the cart and the cart total no longer includes it.

### TC-09 Set the quantity to 0 and cancel

1. In the **Quantity** field, enter `0`.
2. Press Enter.
3. In the dialog, select **Cancel**.

**Expected:** the dialog closes. Blue mug stays in the cart with the **Quantity** field back at 2 and the subtotal at 20.00.

### TC-10 Set the quantity to 0 and close the dialog without choosing

1. In the **Quantity** field, enter `0`.
2. Press Enter.
3. Press Esc.

**Expected:** same as TC-09. The item stays and the quantity returns to 2.

### TC-11 Remove the last item in the cart

Precondition: Blue mug is the only item.

1. In the **Quantity** field, enter `0`.
2. Press Enter.
3. Select **Remove**.

**Expected:** the cart shows its empty state and the total is 0.00.

### TC-12 Confirm removal with other items in the cart

Precondition: the cart also holds Red bowl at quantity 3.

1. In the **Quantity** field for Blue mug, enter `0`.
2. Press Enter.
3. Select **Remove**.

**Expected:** only Blue mug is removed. Red bowl stays at quantity 3 and the total equals the Red bowl subtotal.

## AC-3: A quantity above 20 shows a message and keeps the previous quantity

### TC-13 Enter 21, one above the limit

1. In the **Quantity** field, enter `21`.
2. Press Enter.

**Expected:** the message "You can buy at most 20 of this item." appears next to the field, with that exact wording. The field returns to 2 and the subtotal stays 20.00.

### TC-14 Enter a much larger number

1. In the **Quantity** field, enter `999`.
2. Press Enter.

**Expected:** same as TC-13. The message appears and the quantity stays 2.

### TC-15 Limit message applies to the edited item only

Precondition: the cart also holds Red bowl at quantity 3.

1. In the **Quantity** field for Blue mug, enter `25`.
2. Press Enter.

**Expected:** the message appears next to Blue mug only. Red bowl shows no message and stays at 3.

### TC-16 Message clears after a valid entry

1. In the **Quantity** field, enter `30`.
2. Press Enter.
3. In the same field, enter `10`.
4. Press Enter.

**Expected:** after step 2, the limit message appears. After step 4, the message is gone and the field shows 10.

### TC-17 Previous quantity kept when it was already at the limit

Precondition: Blue mug is at quantity 20.

1. In the **Quantity** field, enter `21`.
2. Press Enter.

**Expected:** the message appears and the field returns to 20, not to any earlier value.

## Entries not covered by the story (assumed rejected)

### TC-18 Enter a decimal

1. In the **Quantity** field, enter `2.5`.
2. Press Enter.

**Expected:** the field returns to 2. No removal prompt appears. Any message shown is noted for the product owner to confirm.

### TC-19 Enter a negative number

1. In the **Quantity** field, enter `-1`.
2. Press Enter.

**Expected:** the field returns to 2. No removal prompt appears.

### TC-20 Enter letters

1. In the **Quantity** field, enter `abc`.
2. Press Enter.

**Expected:** the field returns to 2, or the field does not accept the characters at all. No removal prompt appears.

### TC-21 Leave the field blank

1. In the **Quantity** field, clear the value.
2. Press Enter.

**Expected:** the field returns to 2. The item is not removed and no removal prompt appears.

## Coverage

| Acceptance criterion | Test cases |
| --- | --- |
| AC-1: whole numbers 1 to 20 | TC-01 to TC-07 |
| AC-2: 0 asks "Remove this item?" and removes only on confirm | TC-08 to TC-12 |
| AC-3: above 20 shows the limit message and keeps the previous quantity | TC-13 to TC-17 |
| Not specified, assumed behaviour | TC-18 to TC-21 |

## Open points for the product owner

- Confirm how a change is applied: Enter, leaving the field, or an **Update** button.
- Confirm the dialog button labels and what closing the dialog without choosing does.
- Confirm the expected handling for decimals, negatives, letters and blank entries.
- Confirm whether the limit of 20 is per item or across the cart.
