# Test cases: CART-12 Change the quantity of an item in the cart

## Assumptions

The story does not describe the interface, so these tests assume the following. Correct any label that differs from the product.

- The cart page shows each item with a text field labelled **Quantity** and two buttons, **−** and **+**.
- A typed value applies when the shopper presses Enter or moves focus out of the field.
- The "Remove this item?" dialog has two buttons, **Remove** and **Cancel**.
- The error "You can buy at most 20 of this item." appears under the **Quantity** field and clears on the next valid change.
- The line total and the cart subtotal update when the quantity changes.
- Letters, decimals, negative numbers and an empty field are invalid input. The field restores the previous quantity and shows no removal dialog.
- Stock levels are not part of this story. Every test item has at least 20 in stock.

## Common preconditions

- The shopper is on the cart page.
- The cart contains one item, "Blue mug", with quantity 2 and unit price 10.00, unless a test says otherwise.

---

## AC-1: The quantity field accepts whole numbers from 1 to 20

### TC-01 Type a quantity inside the range

1. Select the **Quantity** field for "Blue mug".
2. Replace the value with 5 and press Enter.

**Expected:** The field shows 5. The line total shows 50.00. The subtotal shows 50.00. No message appears.

### TC-02 Type the lower boundary

1. Replace the **Quantity** value with 1 and press Enter.

**Expected:** The field shows 1. The line total shows 10.00. No message appears.

### TC-03 Type the upper boundary

1. Replace the **Quantity** value with 20 and press Enter.

**Expected:** The field shows 20. The line total shows 200.00. No message appears.

### TC-04 Increase with the plus button

1. Select **+** once.

**Expected:** The field shows 3. The line total shows 30.00.

### TC-05 Decrease with the minus button

1. Select **−** once.

**Expected:** The field shows 1. The line total shows 10.00.

### TC-06 Plus button at the upper boundary

Precondition: quantity is 20.

1. Select **+** once.

**Expected:** The field still shows 20. The message "You can buy at most 20 of this item." appears, or the **+** button is disabled. Either behaviour passes; record which one the product uses.

### TC-07 Decimal input

1. Replace the **Quantity** value with 2.5 and press Enter.

**Expected:** The field restores 2. No removal dialog appears. The line total stays 20.00.

### TC-08 Letters and symbols

1. Replace the **Quantity** value with abc and press Enter.
2. Repeat with the value 3x.

**Expected:** In both cases the field restores 2. No removal dialog appears.

### TC-09 Negative number

1. Replace the **Quantity** value with -1 and press Enter.

**Expected:** The field restores 2. No removal dialog appears.

### TC-10 Empty field

1. Clear the **Quantity** field and move focus away.

**Expected:** The field restores 2. No removal dialog appears.

### TC-11 Leading zero and spaces

1. Replace the **Quantity** value with 07 and press Enter.
2. Replace the value with " 4 " including the spaces, and press Enter.

**Expected:** Step 1 shows 7. Step 2 shows 4. Both line totals match the new quantity.

### TC-12 Change persists after reload

1. Replace the **Quantity** value with 6 and press Enter.
2. Reload the cart page.

**Expected:** The field shows 6. The subtotal shows 60.00.

### TC-13 Only the edited item changes

Precondition: the cart also contains "Red bowl" with quantity 3.

1. Replace the **Quantity** value for "Blue mug" with 4 and press Enter.

**Expected:** "Blue mug" shows 4. "Red bowl" still shows 3. The subtotal reflects both lines.

---

## AC-2: Setting the quantity to 0 asks to remove the item

### TC-14 Typing 0 shows the removal dialog

1. Replace the **Quantity** value with 0 and press Enter.

**Expected:** A dialog with the text "Remove this item?" appears. The item is still in the cart behind the dialog with quantity 2.

### TC-15 Confirm removal

1. Replace the **Quantity** value with 0 and press Enter.
2. Select **Remove**.

**Expected:** "Blue mug" disappears from the cart. The subtotal shows 0.00. If no items remain, the empty-cart message appears.

### TC-16 Cancel removal

1. Replace the **Quantity** value with 0 and press Enter.
2. Select **Cancel**.

**Expected:** The dialog closes. "Blue mug" stays in the cart with quantity 2. The line total shows 20.00.

### TC-17 Close the dialog without choosing

1. Replace the **Quantity** value with 0 and press Enter.
2. Press Escape, or select outside the dialog.

**Expected:** Same as TC-16. The item stays with quantity 2.

### TC-18 Minus button from quantity 1

Precondition: quantity is 1.

1. Select **−** once.

**Expected:** The "Remove this item?" dialog appears. Selecting **Remove** removes the item. Selecting **Cancel** keeps quantity 1.

### TC-19 Confirmed removal persists

1. Replace the **Quantity** value with 0, press Enter, then select **Remove**.
2. Reload the cart page.

**Expected:** "Blue mug" is not in the cart.

### TC-20 Removal with several items in the cart

Precondition: the cart also contains "Red bowl" with quantity 3.

1. Set "Blue mug" to 0 and select **Remove**.

**Expected:** Only "Blue mug" is removed. "Red bowl" stays with quantity 3. The subtotal equals the "Red bowl" line total.

---

## AC-3: A quantity above 20 shows a message and keeps the previous quantity

### TC-21 Type one above the limit

1. Replace the **Quantity** value with 21 and press Enter.

**Expected:** The message "You can buy at most 20 of this item." appears. The field shows 2. The line total stays 20.00.

### TC-22 Type a large number

1. Replace the **Quantity** value with 999 and press Enter.

**Expected:** Same as TC-21. The field shows 2.

### TC-23 Previous quantity is the last applied value, not the default

1. Replace the **Quantity** value with 15 and press Enter.
2. Replace the value with 25 and press Enter.

**Expected:** The message appears. The field shows 15, not 2. The line total shows 150.00.

### TC-24 Message clears after a valid change

1. Replace the **Quantity** value with 30 and press Enter.
2. Replace the value with 10 and press Enter.

**Expected:** After step 2 the message is gone. The field shows 10.

### TC-25 Over-limit value is not saved

1. Replace the **Quantity** value with 50 and press Enter.
2. Reload the cart page.

**Expected:** The field shows 2.

### TC-26 Message is specific to one item

Precondition: the cart also contains "Red bowl" with quantity 3.

1. Replace the **Quantity** value for "Blue mug" with 21 and press Enter.

**Expected:** The message appears under "Blue mug" only. "Red bowl" shows no message and keeps quantity 3.

---

## Accessibility and cross-cutting

### TC-27 Keyboard only

1. Using Tab, move focus to the **Quantity** field.
2. Type 8 and press Enter.
3. Tab to **−** and press Space.

**Expected:** The field shows 7. Focus stays visible on each control.

### TC-28 Screen reader announcements

1. With a screen reader running, set the quantity to 21 and press Enter.
2. Set the quantity to 0 and press Enter.

**Expected:** Step 1 reads the message "You can buy at most 20 of this item." Step 2 moves focus into the dialog and reads "Remove this item?" with both buttons.

### TC-29 Mobile layout

1. On a phone-sized screen, set the quantity to 4 using the on-screen keyboard.

**Expected:** The keyboard shown is numeric. The field shows 4 and the line total updates.

---

## Traceability

| Acceptance criterion | Test cases |
| --- | --- |
| AC-1 | TC-01 to TC-13, TC-27, TC-29 |
| AC-2 | TC-14 to TC-20, TC-28 |
| AC-3 | TC-21 to TC-26, TC-28 |

## Open points for the product owner

- Whether the **+** button at 20 shows the message or is disabled (TC-06).
- Whether invalid text restores the previous value silently or shows its own message (TC-07 to TC-10).
- Whether the limit of 20 applies per line or per product when the same product appears twice, for example in two sizes.
