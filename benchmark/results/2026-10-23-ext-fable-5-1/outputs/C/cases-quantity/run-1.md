# Test cases: CART-12 Change the quantity of an item in the cart

## Assumptions

The story does not describe the cart page, so these test cases assume the following. Correct the labels before running the tests.

- The cart page shows each item with a numeric field labelled **Quantity** and an **Update** button. The quantity is applied when the shopper selects **Update**.
- The field shows the current quantity when the page opens.
- The "Remove this item?" prompt is a dialog with **Remove** and **Cancel** buttons.
- Validation messages appear next to the **Quantity** field of the item in question.
- Input that is not a whole number (decimals, letters, negative numbers, an empty field) is treated like an out-of-range value: a message appears and the previous quantity is kept. The message text for these cases is not specified and is marked as "a validation message" below.
- Changing the quantity updates the line total and the cart total on the same page.
- Stock limits and per-order limits other than 20 are out of scope.
- "Previous quantity" means the quantity shown before the shopper started editing.

## Shared preconditions

- The shopper is signed in or has a guest cart.
- The cart contains 1 item, "Sample Mug", at a unit price of 5.00, with a quantity of 2.
- The cart page is open.

---

### TC-01: Set a quantity in the middle of the range

Covers: AC-1

1. In the **Quantity** field for Sample Mug, enter `5`.
2. Select **Update**.

Expected result:

- The **Quantity** field shows `5`.
- The line total shows 25.00 and the cart total shows 25.00.
- No message is shown.

---

### TC-02: Set the quantity to the lower boundary, 1

Covers: AC-1 (boundary)

1. In the **Quantity** field, enter `1`.
2. Select **Update**.

Expected result:

- The **Quantity** field shows `1`.
- The line total and cart total show 5.00.
- No message is shown.

---

### TC-03: Set the quantity to the upper boundary, 20

Covers: AC-1 (boundary)

1. In the **Quantity** field, enter `20`.
2. Select **Update**.

Expected result:

- The **Quantity** field shows `20`.
- The line total and cart total show 100.00.
- No message is shown.

---

### TC-04: Set the quantity to 21, one above the limit

Covers: AC-3 (boundary)

1. In the **Quantity** field, enter `21`.
2. Select **Update**.

Expected result:

- The message "You can buy at most 20 of this item." appears next to the **Quantity** field.
- The **Quantity** field shows `2`.
- The line total and cart total still show 10.00.
- Sample Mug is still in the cart.

---

### TC-05: Set the quantity to a large number

Covers: AC-3

1. In the **Quantity** field, enter `999`.
2. Select **Update**.

Expected result:

- The message "You can buy at most 20 of this item." appears.
- The **Quantity** field shows `2`.
- The line total and cart total still show 10.00.

---

### TC-06: Correct a quantity after the limit message

Covers: AC-3, AC-1

1. In the **Quantity** field, enter `25`.
2. Select **Update**. The limit message appears.
3. In the **Quantity** field, enter `10`.
4. Select **Update**.

Expected result:

- The limit message is no longer shown.
- The **Quantity** field shows `10`.
- The line total and cart total show 50.00.

---

### TC-07: Set the quantity to 0 and confirm removal

Covers: AC-2

1. In the **Quantity** field, enter `0`.
2. Select **Update**.
3. In the dialog, select **Remove**.

Expected result:

- After step 2, a dialog with the text "Remove this item?" appears.
- After step 3, the dialog closes and Sample Mug is no longer listed in the cart.
- The cart total shows 0.00, or the page shows the empty-cart state.

---

### TC-08: Set the quantity to 0 and cancel removal

Covers: AC-2

1. In the **Quantity** field, enter `0`.
2. Select **Update**.
3. In the dialog, select **Cancel**.

Expected result:

- After step 2, a dialog with the text "Remove this item?" appears.
- After step 3, the dialog closes and Sample Mug is still in the cart.
- The **Quantity** field shows `2`.
- The line total and cart total still show 10.00.

---

### TC-09: Set the quantity to 0 and close the dialog without choosing

Covers: AC-2 (assumption: closing the dialog by other means counts as not confirming)

1. In the **Quantity** field, enter `0`.
2. Select **Update**.
3. Close the dialog with the Escape key or the close control, without selecting **Remove** or **Cancel**.

Expected result:

- Sample Mug is still in the cart.
- The **Quantity** field shows `2`.
- The line total and cart total still show 10.00.

---

### TC-10: Removal with 0 affects only the chosen item

Covers: AC-2

Extra precondition: the cart also contains "Sample Plate" at 8.00, quantity 1.

1. In the **Quantity** field for Sample Mug, enter `0`.
2. Select **Update**.
3. Select **Remove**.

Expected result:

- Sample Mug is no longer listed.
- Sample Plate is still listed with a quantity of 1.
- The cart total shows 8.00.

---

### TC-11: Enter a decimal quantity

Covers: AC-1 (whole numbers only)

1. In the **Quantity** field, enter `2.5`.
2. Select **Update**.

Expected result:

- A validation message appears next to the **Quantity** field.
- The **Quantity** field shows `2`.
- The line total and cart total still show 10.00.

---

### TC-12: Enter a negative quantity

Covers: AC-1

1. In the **Quantity** field, enter `-1`.
2. Select **Update**.

Expected result:

- A validation message appears next to the **Quantity** field.
- The "Remove this item?" dialog does not appear.
- The **Quantity** field shows `2`.
- The line total and cart total still show 10.00.

---

### TC-13: Enter letters or symbols in the quantity field

Covers: AC-1

1. In the **Quantity** field, enter `abc`.
2. Select **Update**.

Expected result:

- Either the field does not accept the characters, or a validation message appears.
- The **Quantity** field shows `2`.
- The line total and cart total still show 10.00.

---

### TC-14: Leave the quantity field empty

Covers: AC-1

1. Clear the **Quantity** field.
2. Select **Update**.

Expected result:

- A validation message appears next to the **Quantity** field.
- The "Remove this item?" dialog does not appear.
- The **Quantity** field shows `2`.
- The line total and cart total still show 10.00.

---

### TC-15: Enter a whole number with leading zeros

Covers: AC-1

1. In the **Quantity** field, enter `007`.
2. Select **Update**.

Expected result:

- The **Quantity** field shows `7`.
- The line total and cart total show 35.00.
- No message is shown.

---

### TC-16: Changed quantity is kept after reloading the page

Covers: AC-1 (persistence)

1. In the **Quantity** field, enter `4`.
2. Select **Update**.
3. Reload the cart page.

Expected result:

- The **Quantity** field shows `4`.
- The line total and cart total show 20.00.

---

### TC-17: Rejected quantity is not saved after reloading the page

Covers: AC-3 (persistence)

1. In the **Quantity** field, enter `30`.
2. Select **Update**. The limit message appears.
3. Reload the cart page.

Expected result:

- The **Quantity** field shows `2`.
- The line total and cart total show 10.00.

---

### TC-18: Change the quantity using the keyboard only

Covers: AC-1, AC-2 (accessibility)

1. Use the Tab key to move focus to the **Quantity** field.
2. Type `0` and press Enter, or Tab to **Update** and press Enter.
3. In the dialog, use Tab to reach **Cancel** and press Enter.

Expected result:

- The dialog receives focus when it opens.
- After step 3, focus returns to the **Quantity** field or to **Update**.
- Sample Mug is still in the cart with a quantity of 2.

---

## Coverage summary

| Acceptance criterion | Test cases |
| --- | --- |
| AC-1: whole numbers from 1 to 20 | TC-01, TC-02, TC-03, TC-06, TC-11, TC-12, TC-13, TC-14, TC-15, TC-16, TC-18 |
| AC-2: 0 asks to remove, removes only on confirm | TC-07, TC-08, TC-09, TC-10, TC-18 |
| AC-3: above 20 shows message, keeps previous quantity | TC-04, TC-05, TC-06, TC-17 |

## Open points for the product owner

- What message, if any, should appear for decimals, negative numbers, letters and an empty field? TC-11 to TC-14 assume a message appears and the previous quantity is kept.
- Should closing the dialog without a choice count as cancelling? TC-09 assumes yes.
- Does the quantity apply on **Update**, or as soon as the shopper leaves the field? The steps assume **Update**.
