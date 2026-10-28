# Test Cases for CART-12: Change the Quantity of an Item in the Cart

## Test Case 1: Valid Quantity Change - Lower Range
**ID:** TC-CART-12-001  
**Title:** Change quantity to valid lower range value (1)  
**Precondition:** Item exists in cart with quantity > 1  
**Steps:**
1. Locate the quantity field for the item
2. Clear the current quantity value
3. Enter "1"
4. Confirm/apply the change

**Expected Result:** Quantity updates to 1, cart total recalculates, no error message appears

---

## Test Case 2: Valid Quantity Change - Middle Range
**ID:** TC-CART-12-002  
**Title:** Change quantity to valid middle range value (10)  
**Precondition:** Item exists in cart with quantity ≠ 10  
**Steps:**
1. Locate the quantity field for the item
2. Clear the current quantity value
3. Enter "10"
4. Confirm/apply the change

**Expected Result:** Quantity updates to 10, cart total recalculates correctly, no error message appears

---

## Test Case 3: Valid Quantity Change - Upper Boundary
**ID:** TC-CART-12-003  
**Title:** Change quantity to valid upper boundary (20)  
**Precondition:** Item exists in cart with quantity < 20  
**Steps:**
1. Locate the quantity field for the item
2. Clear the current quantity value
3. Enter "20"
4. Confirm/apply the change

**Expected Result:** Quantity updates to 20, cart total recalculates correctly, no error message appears

---

## Test Case 4: Invalid Quantity - Zero Value, User Cancels
**ID:** TC-CART-12-004  
**Title:** Set quantity to 0 and cancel removal  
**Precondition:** Item exists in cart with quantity ≥ 1  
**Steps:**
1. Locate the quantity field for the item
2. Clear the current quantity value
3. Enter "0"
4. Confirm/apply the change
5. Confirmation dialog appears asking "Remove this item?"
6. Click "Cancel" or "No" button

**Expected Result:** Dialog closes, item remains in cart with previous quantity unchanged

---

## Test Case 5: Invalid Quantity - Zero Value, User Confirms
**ID:** TC-CART-12-005  
**Title:** Set quantity to 0 and confirm removal  
**Precondition:** Item exists in cart with quantity ≥ 1  
**Steps:**
1. Locate the quantity field for the item
2. Clear the current quantity value
3. Enter "0"
4. Confirm/apply the change
5. Confirmation dialog appears asking "Remove this item?"
6. Click "Confirm", "Yes", or "Remove" button

**Expected Result:** Item is removed from cart, cart total recalculates, cart displays updated item list

---

## Test Case 6: Invalid Quantity - Above Maximum (21)
**ID:** TC-CART-12-006  
**Title:** Attempt to set quantity to 21 (exceeds maximum)  
**Precondition:** Item exists in cart with quantity < 21  
**Steps:**
1. Locate the quantity field for the item
2. Clear the current quantity value
3. Enter "21"
4. Confirm/apply the change

**Expected Result:** Error message "You can buy at most 20 of this item." displays, quantity reverts to previous value, cart total unchanged

---

## Test Case 7: Invalid Quantity - Far Above Maximum
**ID:** TC-CART-12-007  
**Title:** Attempt to set quantity to 100  
**Precondition:** Item exists in cart with known quantity  
**Steps:**
1. Locate the quantity field for the item
2. Clear the current quantity value
3. Enter "100"
4. Confirm/apply the change

**Expected Result:** Error message "You can buy at most 20 of this item." displays, quantity reverts to previous value, cart total unchanged

---

## Test Case 8: Invalid Input - Decimal Number
**ID:** TC-CART-12-008  
**Title:** Attempt to enter decimal quantity (3.5)  
**Precondition:** Item exists in cart  
**Steps:**
1. Locate the quantity field for the item
2. Clear the current quantity value
3. Enter "3.5"
4. Attempt to confirm/apply the change

**Expected Result:** Field rejects decimal input or rounds to nearest whole number (3), quantity does not update to 3.5

---

## Test Case 9: Invalid Input - Negative Number
**ID:** TC-CART-12-009  
**Title:** Attempt to enter negative quantity (-5)  
**Precondition:** Item exists in cart  
**Steps:**
1. Locate the quantity field for the item
2. Clear the current quantity value
3. Enter "-5"
4. Attempt to confirm/apply the change

**Expected Result:** Field rejects negative input, quantity does not update

---

## Test Case 10: Invalid Input - Non-Numeric Characters
**ID:** TC-CART-12-010  
**Title:** Attempt to enter alphabetic characters  
**Precondition:** Item exists in cart  
**Steps:**
1. Locate the quantity field for the item
2. Clear the current quantity value
3. Enter "abc"
4. Attempt to confirm/apply the change

**Expected Result:** Field rejects alphabetic input, quantity does not update

---

## Test Case 11: Boundary Test - Transition from Valid to Invalid
**ID:** TC-CART-12-011  
**Title:** Change quantity from 20 to 21  
**Precondition:** Item exists in cart with quantity = 20  
**Steps:**
1. Locate the quantity field for the item
2. Clear the current quantity value
3. Enter "21"
4. Confirm/apply the change

**Expected Result:** Error message "You can buy at most 20 of this item." displays, quantity reverts to 20, cart total unchanged

---

## Test Case 12: Multiple Sequential Changes
**ID:** TC-CART-12-012  
**Title:** Make multiple quantity changes in succession  
**Precondition:** Item exists in cart  
**Steps:**
1. Change quantity to 5, confirm
2. Change quantity to 15, confirm
3. Change quantity to 8, confirm

**Expected Result:** Each change updates successfully, cart total recalculates correctly after each change, no residual errors

---

## Test Case 13: Quantity Change With Cart Persistence
**ID:** TC-CART-12-013  
**Title:** Verify quantity change persists after page navigation  
**Precondition:** Item exists in cart  
**Steps:**
1. Change item quantity to 7
2. Confirm the change
3. Navigate away from cart page
4. Return to cart page

**Expected Result:** Item quantity remains 7, cart total reflects the updated quantity

---

## Test Case 14: Edge Case - Special Characters
**ID:** TC-CART-12-014  
**Title:** Attempt to enter special characters  
**Precondition:** Item exists in cart  
**Steps:**
1. Locate the quantity field for the item
2. Clear the current quantity value
3. Enter "@#$%"
4. Attempt to confirm/apply the change

**Expected Result:** Field rejects special characters, quantity does not update

---

## Test Case 15: Edge Case - Whitespace/Empty Field
**ID:** TC-CART-12-015  
**Title:** Leave quantity field empty and attempt to confirm  
**Precondition:** Item exists in cart with quantity value  
**Steps:**
1. Locate the quantity field for the item
2. Clear the current quantity value completely
3. Leave the field empty
4. Attempt to confirm/apply the change

**Expected Result:** Either field displays validation error message or reverts to previous quantity value

---

## Assumptions Made
1. The quantity field is an editable input field (not a dropdown or increment/decrement buttons only)
2. Changes are applied via a confirm/apply action (button click, Enter key, or blur event)
3. Cart persists changes to a database or local storage
4. Only one item is being modified at a time in these tests
5. The shopper is authenticated and has appropriate permissions
6. The error messages appear in a toast, alert, or inline validation message
7. Previous quantity value is tracked and accessible for reversion
8. The cart UI updates immediately upon successful quantity changes
9. No inventory constraints beyond the 20-unit maximum are considered in these tests
