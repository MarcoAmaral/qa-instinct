# Test Cases for CART-12: Change the Quantity of an Item in the Cart

## Assumptions
- The quantity field is a numeric input field on each cart item.
- The cart is rendered on a dedicated cart page or panel.
- The shopper is logged in with at least one item in the cart.
- Quantity validation occurs on input blur or in real-time.
- The confirmation dialog for removal is a modal popup.
- "Previous quantity" means the quantity before the invalid change attempt.

---

## Test Case 1: Update quantity within valid range (1–20)

**TC-1.1: Change quantity from 1 to 5**

- **Precondition:** Cart contains an item with quantity 1.
- **Steps:**
  1. Locate the quantity field for the item.
  2. Clear the field and enter 5.
  3. Move focus away from the field (blur).
- **Expected Result:** Quantity updates to 5. Cart subtotal updates. No error or confirmation message appears.

**TC-1.2: Change quantity from 10 to 1**

- **Precondition:** Cart contains an item with quantity 10.
- **Steps:**
  1. Locate the quantity field for the item.
  2. Clear the field and enter 1.
  3. Move focus away from the field (blur).
- **Expected Result:** Quantity updates to 1. Cart subtotal updates. No error or confirmation message appears.

**TC-1.3: Set quantity to 20 (maximum valid value)**

- **Precondition:** Cart contains an item with quantity 5.
- **Steps:**
  1. Locate the quantity field for the item.
  2. Clear the field and enter 20.
  3. Move focus away from the field (blur).
- **Expected Result:** Quantity updates to 20. Cart subtotal updates. No error message appears.

---

## Test Case 2: Decimal and non-whole numbers

**TC-2.1: Enter a decimal number (e.g., 2.5)**

- **Precondition:** Cart contains an item with quantity 2.
- **Steps:**
  1. Locate the quantity field for the item.
  2. Clear the field and enter 2.5.
  3. Move focus away from the field (blur).
- **Expected Result:** Quantity field either rejects the input, rounds it, or truncates it (behavior to be clarified). Field reverts to previous quantity.

**TC-2.2: Enter text or special characters (e.g., "abc")**

- **Precondition:** Cart contains an item with quantity 3.
- **Steps:**
  1. Locate the quantity field for the item.
  2. Clear the field and enter abc.
  3. Move focus away from the field (blur).
- **Expected Result:** Field rejects input and reverts to the previous quantity (3).

---

## Test Case 3: Remove item by setting quantity to 0

**TC-3.1: Set quantity to 0 and confirm removal**

- **Precondition:** Cart contains an item with quantity 5.
- **Steps:**
  1. Locate the quantity field for the item.
  2. Clear the field and enter 0.
  3. Move focus away from the field (blur).
  4. A confirmation dialog appears with the message "Remove this item?"
  5. Select the confirm button (e.g., "Yes" or "Remove").
- **Expected Result:** Item is removed from the cart. Cart subtotal and item count update.

**TC-3.2: Set quantity to 0 and cancel removal**

- **Precondition:** Cart contains an item with quantity 8.
- **Steps:**
  1. Locate the quantity field for the item.
  2. Clear the field and enter 0.
  3. Move focus away from the field (blur).
  4. A confirmation dialog appears with the message "Remove this item?"
  5. Select the cancel button (e.g., "No" or "Cancel").
- **Expected Result:** Confirmation dialog closes. Item remains in the cart with its original quantity (8). Cart totals unchanged.

---

## Test Case 4: Quantity above 20

**TC-4.1: Enter quantity 21**

- **Precondition:** Cart contains an item with quantity 5.
- **Steps:**
  1. Locate the quantity field for the item.
  2. Clear the field and enter 21.
  3. Move focus away from the field (blur).
- **Expected Result:** Error message displays: "You can buy at most 20 of this item." Quantity field reverts to 5. Cart totals unchanged.

**TC-4.2: Enter quantity 100**

- **Precondition:** Cart contains an item with quantity 15.
- **Steps:**
  1. Locate the quantity field for the item.
  2. Clear the field and enter 100.
  3. Move focus away from the field (blur).
- **Expected Result:** Error message displays: "You can buy at most 20 of this item." Quantity field reverts to 15. Cart totals unchanged.

**TC-4.3: Enter a negative number (e.g., -5)**

- **Precondition:** Cart contains an item with quantity 10.
- **Steps:**
  1. Locate the quantity field for the item.
  2. Clear the field and enter -5.
  3. Move focus away from the field (blur).
- **Expected Result:** Error message or field rejection occurs. Quantity reverts to 10.

---

## Test Case 5: Edge cases

**TC-5.1: Multiple rapid quantity changes**

- **Precondition:** Cart contains an item with quantity 5.
- **Steps:**
  1. Change quantity to 10, then immediately to 15, then to 8 (without waiting for focus loss).
  2. Move focus away from the field.
- **Expected Result:** Final quantity is 8. Cart subtotal reflects 8 items.

**TC-5.2: Update quantity on a second item without affecting the first**

- **Precondition:** Cart contains two items, both with quantity 3.
- **Steps:**
  1. Change the quantity of the second item to 12.
  2. Move focus away from the field.
- **Expected Result:** Second item quantity updates to 12. First item remains at 3. Cart subtotal updates correctly.

**TC-5.3: Empty quantity field**

- **Precondition:** Cart contains an item with quantity 4.
- **Steps:**
  1. Locate the quantity field for the item.
  2. Clear the field completely and move focus away.
- **Expected Result:** Field either treats empty as 0 (triggering the removal dialog) or reverts to the previous quantity (4).
