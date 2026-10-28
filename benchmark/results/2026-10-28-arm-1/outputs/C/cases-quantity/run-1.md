# Test Cases for CART-12: Change the Quantity of an Item in the Cart

## Assumptions
- The quantity field is a text input or number input in the cart item row.
- Validation messages appear when the user exits the field (blur) or attempts to submit.
- "Previous quantity" means the last valid quantity before the user's invalid input.
- The confirmation dialog for quantity 0 is a modal or inline prompt.
- The cart contains at least one item for testing.

---

## Test Case 1: Valid Quantity Entry (1–20)

**Title:** Accept valid whole numbers in the 1–20 range

**Steps:**
1. Open the cart with at least one item.
2. Click the quantity field for an item.
3. Clear the field and enter a valid number: 1, 5, 10, or 20.
4. Exit the field (blur).

**Expected Result:** The quantity updates without error. No validation message appears.

---

## Test Case 2: Quantity = 0 Shows Confirmation Dialog

**Title:** Display "Remove this item?" confirmation when quantity is set to 0

**Steps:**
1. Open the cart with at least one item (starting quantity > 0).
2. Click the quantity field.
3. Clear the field and enter 0.
4. Exit the field (blur) or press Enter.

**Expected Result:** A confirmation dialog appears with the text "Remove this item?" and two options (e.g., "Yes" and "Cancel").

---

## Test Case 3: Quantity = 0 Confirmation – User Confirms

**Title:** Remove the item when the user confirms the "Remove this item?" dialog

**Steps:**
1. Follow Test Case 2 to trigger the confirmation dialog.
2. Select "Yes" or the confirm button.

**Expected Result:** The item is removed from the cart. The cart updates and reflects the change (fewer items, updated total).

---

## Test Case 4: Quantity = 0 Confirmation – User Cancels

**Title:** Keep the item in the cart when the user cancels the "Remove this item?" dialog

**Steps:**
1. Follow Test Case 2 to trigger the confirmation dialog.
2. Select "Cancel" or close the dialog.

**Expected Result:** The item remains in the cart. The quantity field reverts to the previous valid quantity.

---

## Test Case 5: Quantity > 20 Shows Error Message

**Title:** Display error message "You can buy at most 20 of this item." when quantity exceeds 20

**Steps:**
1. Open the cart with at least one item.
2. Click the quantity field.
3. Enter a number greater than 20 (e.g., 21, 50, 100).
4. Exit the field (blur) or press Enter.

**Expected Result:** An error message appears: "You can buy at most 20 of this item." The quantity field reverts to the previous valid quantity and does not update.

---

## Test Case 6: Quantity > 20 – Previous Quantity Preserved

**Title:** Verify the quantity reverts to the previous valid value after an out-of-range error

**Steps:**
1. Set an item's quantity to 10 (valid).
2. Click the quantity field.
3. Change the value to 50.
4. Exit the field (blur).
5. Check the quantity field value.

**Expected Result:** The error message "You can buy at most 20 of this item." appears. The quantity field shows 10 (the previous valid quantity).

---

## Test Case 7: Non-Whole Numbers Are Rejected

**Title:** Reject decimal or fractional inputs

**Steps:**
1. Open the cart with at least one item.
2. Click the quantity field.
3. Enter a decimal number (e.g., 2.5, 3.7) or a fraction.
4. Exit the field (blur).

**Expected Result:** The field rejects the input and reverts to the previous valid quantity. A validation message may appear (e.g., "Quantity must be a whole number").

---

## Test Case 8: Non-Numeric Input Is Rejected

**Title:** Reject letters, symbols, or other non-numeric characters

**Steps:**
1. Open the cart with at least one item.
2. Click the quantity field.
3. Enter text (e.g., "abc", "2x", "item").
4. Exit the field (blur) or attempt to submit the cart.

**Expected Result:** The field rejects the input and reverts to the previous valid quantity.

---

## Test Case 9: Negative Numbers Are Rejected

**Title:** Reject negative quantities

**Steps:**
1. Open the cart with at least one item.
2. Click the quantity field.
3. Enter a negative number (e.g., -5, -1).
4. Exit the field (blur).

**Expected Result:** The field rejects the input and reverts to the previous valid quantity.

---

## Test Case 10: Empty Field Is Handled Gracefully

**Title:** Handle an empty quantity field

**Steps:**
1. Open the cart with at least one item.
2. Click the quantity field.
3. Clear the field completely.
4. Exit the field (blur).

**Expected Result:** The field either reverts to the previous quantity or displays an error (e.g., "Quantity is required"). The item is not removed from the cart.

---

## Test Case 11: Boundary Test – Quantity = 1 (Minimum Valid)

**Title:** Accept quantity of 1 (lower boundary)

**Steps:**
1. Open the cart with an item at quantity 5 or higher.
2. Change the quantity to 1.
3. Exit the field (blur).

**Expected Result:** The quantity updates to 1 without error.

---

## Test Case 12: Boundary Test – Quantity = 20 (Maximum Valid)

**Title:** Accept quantity of 20 (upper boundary)

**Steps:**
1. Open the cart with an item.
2. Change the quantity to 20.
3. Exit the field (blur).

**Expected Result:** The quantity updates to 20 without error.

---

## Test Case 13: Quantity = 21 (Just Above Maximum)

**Title:** Reject quantity of 21 (just above upper boundary)

**Steps:**
1. Open the cart with an item.
2. Change the quantity to 21.
3. Exit the field (blur).

**Expected Result:** The error message "You can buy at most 20 of this item." appears. The quantity reverts to the previous valid value.

---

## Test Case 14: Multiple Items – Update One Quantity

**Title:** Update the quantity of one item without affecting others

**Steps:**
1. Open the cart with 2 or more items.
2. Change the quantity of the first item to 5.
3. Verify the other items' quantities are unchanged.

**Expected Result:** Only the first item's quantity updates to 5. Other items retain their original quantities.

---

## Test Case 15: Rapid Quantity Changes

**Title:** Handle rapid or repeated changes to the quantity field

**Steps:**
1. Open the cart with an item.
2. Click the quantity field and rapidly change it multiple times (e.g., 5 → 10 → 3 → 15).
3. Exit the field.

**Expected Result:** The final valid value is accepted. The field does not cause errors or race conditions.

---

## Test Case 16: Cart Persistence After Quantity Change

**Title:** Verify the updated quantity persists after navigation or refresh

**Steps:**
1. Open the cart and change an item's quantity to 7.
2. Refresh the page or navigate away and return to the cart.

**Expected Result:** The item's quantity remains 7.
