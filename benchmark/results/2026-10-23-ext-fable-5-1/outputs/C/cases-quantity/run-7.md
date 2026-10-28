# Test cases: CART-12 Change the quantity of an item in the cart

## Assumptions

The story does not describe the interface or the behaviour outside the three acceptance criteria. These test cases assume the following. An editor or developer should correct any that do not match the product.

- The cart page shows one **Quantity** field per item, and the change applies when the shopper selects **Update** or leaves the field.
- The "Remove this item?" prompt is a dialog with the buttons **Remove** and **Cancel**.
- The message "You can buy at most 20 of this item." appears next to the **Quantity** field and disappears on the next valid change.
- The item line total and the cart subtotal update after a valid quantity change.
- Values outside AC-1 that the story does not cover (letters, decimals, negative numbers, an empty field) are rejected and the previous quantity is kept. Each such case is marked **Assumed** in its expected result.
- Stock limits are out of scope. Every test item has at least 20 units available.

## Common preconditions

- The shopper is on the cart page.
- The cart contains an item called "Test Mug" with quantity 5 and a unit price of 10.00, unless a test case says otherwise.

## AC-1: The quantity field accepts whole numbers from 1 to 20

### TC-01 Change the quantity to a value inside the range

1. In the **Quantity** field for Test Mug, enter 7.
2. Select **Update**.

**Expected result:** The quantity shows 7. The line total shows 70.00. The subtotal changes by the same amount. No message appears.

### TC-02 Change the quantity to the lower limit, 1

1. In the **Quantity** field, enter 1.
2. Select **Update**.

**Expected result:** The quantity shows 1. The line total shows 10.00. No message appears and no dialog opens.

### TC-03 Change the quantity to the upper limit, 20

1. In the **Quantity** field, enter 20.
2. Select **Update**.

**Expected result:** The quantity shows 20. The line total shows 200.00. No message appears.

### TC-04 Enter a decimal number

1. In the **Quantity** field, enter 2.5.
2. Select **Update**.

**Expected result (Assumed):** The field rejects the value or the quantity stays at 5. The line total stays at 50.00.

### TC-05 Enter letters

1. In the **Quantity** field, enter "abc".
2. Select **Update**.

**Expected result (Assumed):** The field rejects the value or the quantity stays at 5. The line total stays at 50.00.

### TC-06 Enter a negative number

1. In the **Quantity** field, enter -1.
2. Select **Update**.

**Expected result (Assumed):** The quantity stays at 5. The "Remove this item?" dialog does not open.

### TC-07 Leave the field empty

1. In the **Quantity** field, delete the value.
2. Select **Update**.

**Expected result (Assumed):** The quantity stays at 5. The item is not removed.

### TC-08 Change the quantity twice in a row

1. In the **Quantity** field, enter 3, then select **Update**.
2. In the **Quantity** field, enter 12, then select **Update**.

**Expected result:** After step 1 the quantity shows 3 and the line total shows 30.00. After step 2 the quantity shows 12 and the line total shows 120.00.

### TC-09 Change the quantity of one item when the cart holds several

**Precondition:** The cart also contains "Test Plate" with quantity 2.

1. In the **Quantity** field for Test Mug, enter 8.
2. Select **Update**.

**Expected result:** Test Mug shows 8. Test Plate still shows 2. The subtotal reflects both.

### TC-10 Reload the page after a change

1. In the **Quantity** field, enter 9, then select **Update**.
2. Reload the page.

**Expected result:** The quantity still shows 9.

## AC-2: Setting the quantity to 0 asks "Remove this item?"

### TC-11 Set the quantity to 0 and confirm

1. In the **Quantity** field, enter 0.
2. Select **Update**.
   A dialog with the text "Remove this item?" opens.
3. Select **Remove**.

**Expected result:** The dialog closes. Test Mug no longer appears in the cart. The subtotal no longer includes it.

### TC-12 Set the quantity to 0 and cancel

1. In the **Quantity** field, enter 0.
2. Select **Update**.
   A dialog with the text "Remove this item?" opens.
3. Select **Cancel**.

**Expected result:** The dialog closes. Test Mug is still in the cart with quantity 5. The line total still shows 50.00.

### TC-13 Set the quantity to 0 and close the dialog without choosing

1. In the **Quantity** field, enter 0.
2. Select **Update**.
3. Close the dialog with the Escape key or its close control.

**Expected result (Assumed):** The item is not removed. The quantity shows 5.

### TC-14 Remove the only item in the cart

**Precondition:** Test Mug is the only item in the cart.

1. In the **Quantity** field, enter 0.
2. Select **Update**.
3. Select **Remove**.

**Expected result:** The cart shows its empty state. The subtotal shows 0.00.

### TC-15 Confirm removal when the cart holds several items

**Precondition:** The cart also contains "Test Plate" with quantity 2.

1. In the **Quantity** field for Test Mug, enter 0.
2. Select **Update**.
3. Select **Remove**.

**Expected result:** Only Test Mug is removed. Test Plate still shows quantity 2.

## AC-3: A quantity above 20 shows a message and keeps the previous quantity

### TC-16 Enter 21, one above the limit

1. In the **Quantity** field, enter 21.
2. Select **Update**.

**Expected result:** The message "You can buy at most 20 of this item." appears. The quantity shows 5. The line total stays at 50.00.

### TC-17 Enter a much larger number

1. In the **Quantity** field, enter 999.
2. Select **Update**.

**Expected result:** The message "You can buy at most 20 of this item." appears. The quantity shows 5.

### TC-18 The message clears after a valid change

1. In the **Quantity** field, enter 25, then select **Update**.
2. In the **Quantity** field, enter 10, then select **Update**.

**Expected result:** After step 1 the message appears and the quantity shows 5. After step 2 the message is gone and the quantity shows 10.

### TC-19 Previous quantity is kept when it was already 20

**Precondition:** Test Mug has quantity 20.

1. In the **Quantity** field, enter 21.
2. Select **Update**.

**Expected result:** The message appears. The quantity shows 20.

### TC-20 Exact message text

1. In the **Quantity** field, enter 30.
2. Select **Update**.

**Expected result:** The message reads exactly "You can buy at most 20 of this item." with the full stop and no other wording.

## Coverage summary

| Acceptance criterion | Test cases |
| --- | --- |
| AC-1 | TC-01 to TC-10 |
| AC-2 | TC-11 to TC-15 |
| AC-3 | TC-16 to TC-20 |

## Open points for the story owner

- Whether letters, decimals, negative numbers and an empty field should show a message, and which one.
- Whether the quantity applies on **Update** only, or also when the field loses focus.
- Whether stock limits lower than 20 change the message in AC-3.
