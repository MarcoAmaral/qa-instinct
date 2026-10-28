# Test Cases for CART-12: Change the Quantity of an Item in the Cart

## Test Case 1: Valid Quantity Update - Single Digit
**ID:** CART-12-TC-001  
**Title:** Update quantity to a valid single-digit number  
**Precondition:** Shopper is logged in with at least one item in cart  
**Steps:**
1. Navigate to cart
2. Locate the quantity field for an item
3. Clear the current value and enter "5"
4. Press Enter or click Update button

**Expected Result:** Quantity updates to 5, cart total is recalculated, item remains in cart

---

## Test Case 2: Valid Quantity Update - Double Digit
**ID:** CART-12-TC-002  
**Title:** Update quantity to a valid double-digit number within range  
**Precondition:** Shopper is logged in with at least one item in cart  
**Steps:**
1. Navigate to cart
2. Locate the quantity field for an item
3. Clear the current value and enter "15"
4. Press Enter or click Update button

**Expected Result:** Quantity updates to 15, cart total is recalculated, item remains in cart

---

## Test Case 3: Boundary - Minimum Valid Quantity
**ID:** CART-12-TC-003  
**Title:** Update quantity to minimum valid value (1)  
**Precondition:** Shopper is logged in with at least one item in cart (quantity > 1)  
**Steps:**
1. Navigate to cart
2. Locate the quantity field
3. Clear and enter "1"
4. Press Enter or click Update button

**Expected Result:** Quantity updates to 1, cart total is recalculated, item remains in cart

---

## Test Case 4: Boundary - Maximum Valid Quantity
**ID:** CART-12-TC-004  
**Title:** Update quantity to maximum valid value (20)  
**Precondition:** Shopper is logged in with at least one item in cart  
**Steps:**
1. Navigate to cart
2. Locate the quantity field
3. Clear and enter "20"
4. Press Enter or click Update button

**Expected Result:** Quantity updates to 20, cart total is recalculated, item remains in cart

---

## Test Case 5: Exceed Maximum Quantity
**ID:** CART-12-TC-005  
**Title:** Attempt to set quantity above maximum (21)  
**Precondition:** Shopper is logged in with an item in cart (current quantity: 5)  
**Steps:**
1. Navigate to cart
2. Locate the quantity field
3. Clear and enter "21"
4. Press Enter or click Update button

**Expected Result:** Error message displays "You can buy at most 20 of this item.", quantity reverts to 5 (previous value), cart total remains unchanged

---

## Test Case 6: Exceed Maximum by Large Margin
**ID:** CART-12-TC-006  
**Title:** Attempt to set quantity significantly above maximum (100)  
**Precondition:** Shopper is logged in with an item in cart (current quantity: 3)  
**Steps:**
1. Navigate to cart
2. Locate the quantity field
3. Clear and enter "100"
4. Press Enter or click Update button

**Expected Result:** Error message displays "You can buy at most 20 of this item.", quantity reverts to 3, cart total remains unchanged

---

## Test Case 7: Remove Item - Confirm Deletion
**ID:** CART-12-TC-007  
**Title:** Set quantity to 0 and confirm removal  
**Precondition:** Shopper is logged in with at least one item in cart  
**Steps:**
1. Navigate to cart
2. Locate the quantity field
3. Clear and enter "0"
4. Press Enter or click Update button
5. Confirmation dialog appears asking "Remove this item?"
6. Click "Yes" or "Confirm" button

**Expected Result:** Item is removed from cart, confirmation dialog closes, cart updates and total is recalculated

---

## Test Case 8: Remove Item - Cancel Deletion
**ID:** CART-12-TC-008  
**Title:** Set quantity to 0 but cancel removal  
**Precondition:** Shopper is logged in with an item in cart (current quantity: 2)  
**Steps:**
1. Navigate to cart
2. Locate the quantity field
3. Clear and enter "0"
4. Press Enter or click Update button
5. Confirmation dialog appears asking "Remove this item?"
6. Click "No" or "Cancel" button

**Expected Result:** Confirmation dialog closes, quantity reverts to 2, item remains in cart, cart total unchanged

---

## Test Case 9: Invalid Input - Decimal Number
**ID:** CART-12-TC-009  
**Title:** Attempt to enter decimal quantity  
**Precondition:** Shopper is logged in with an item in cart (current quantity: 4)  
**Steps:**
1. Navigate to cart
2. Locate the quantity field
3. Clear and enter "5.5"
4. Press Enter or click Update button

**Expected Result:** Input is rejected or rounded, field either rejects entry or reverts to 4, error message may appear (assumption: decimals not accepted)

---

## Test Case 10: Invalid Input - Negative Number
**ID:** CART-12-TC-010  
**Title:** Attempt to enter negative quantity  
**Precondition:** Shopper is logged in with an item in cart (current quantity: 3)  
**Steps:**
1. Navigate to cart
2. Locate the quantity field
3. Clear and enter "-5"
4. Press Enter or click Update button

**Expected Result:** Input is rejected, quantity reverts to 3, item remains in cart

---

## Test Case 11: Invalid Input - Non-Numeric Characters
**ID:** CART-12-TC-011  
**Title:** Attempt to enter text/letters in quantity field  
**Precondition:** Shopper is logged in with an item in cart (current quantity: 2)  
**Steps:**
1. Navigate to cart
2. Locate the quantity field
3. Clear and enter "abc"
4. Press Enter or click Update button

**Expected Result:** Input is rejected, quantity reverts to 2, item remains in cart

---

## Test Case 12: Invalid Input - Special Characters
**ID:** CART-12-TC-012  
**Title:** Attempt to enter special characters in quantity field  
**Precondition:** Shopper is logged in with an item in cart (current quantity: 6)  
**Steps:**
1. Navigate to cart
2. Locate the quantity field
3. Clear and enter "@#$%"
4. Press Enter or click Update button

**Expected Result:** Input is rejected, quantity reverts to 6, item remains in cart

---

## Test Case 13: Empty Quantity Field
**ID:** CART-12-TC-013  
**Title:** Submit with empty quantity field  
**Precondition:** Shopper is logged in with an item in cart (current quantity: 8)  
**Steps:**
1. Navigate to cart
2. Locate the quantity field
3. Clear the field completely
4. Press Enter or click Update button

**Expected Result:** Input is rejected or field defaults to previous value, quantity remains 8, error message may appear

---

## Test Case 14: Update Multiple Items Sequential
**ID:** CART-12-TC-014  
**Title:** Update quantity on multiple items in sequence  
**Precondition:** Shopper is logged in with 3+ items in cart  
**Steps:**
1. Navigate to cart
2. Update first item quantity to 7
3. Update second item quantity to 3
4. Update third item quantity to 12
5. Verify cart totals

**Expected Result:** Each item updates independently, cart total reflects all changes accurately

---

## Test Case 15: Whitespace Input
**ID:** CART-12-TC-015  
**Title:** Submit quantity field with only whitespace  
**Precondition:** Shopper is logged in with an item in cart (current quantity: 5)  
**Steps:**
1. Navigate to cart
2. Locate the quantity field
3. Clear and enter "   " (spaces only)
4. Press Enter or click Update button

**Expected Result:** Input is rejected or trimmed, quantity reverts to 5, item remains in cart

---

## Test Case 16: Boundary - Zero Confirmation Timeout
**ID:** CART-12-TC-016  
**Title:** Set quantity to 0 and let confirmation dialog timeout (if applicable)  
**Precondition:** Shopper is logged in with an item in cart (current quantity: 3); confirmation dialog has timeout  
**Steps:**
1. Navigate to cart
2. Clear quantity field and enter "0"
3. Press Enter or click Update button
4. Confirmation dialog appears
5. Wait for timeout period without clicking Yes/No

**Expected Result:** Dialog auto-closes (assumption: defaults to cancel), quantity reverts to 3, item remains in cart

---

## Test Case 17: Update with Browser Back Button
**ID:** CART-12-TC-017  
**Title:** Update quantity then navigate away using browser back button  
**Precondition:** Shopper is logged in with an item in cart  
**Steps:**
1. Navigate to cart
2. Update item quantity to 10
3. Click browser back button
4. Return to cart

**Expected Result:** Quantity change is persisted, cart displays quantity as 10

---

## Test Case 18: Rapid Sequential Updates
**ID:** CART-12-TC-018  
**Title:** Rapidly update quantity multiple times on same item  
**Precondition:** Shopper is logged in with an item in cart  
**Steps:**
1. Navigate to cart
2. Update quantity to 5
3. Immediately update to 10
4. Immediately update to 15
5. Wait for updates to process

**Expected Result:** Final quantity is 15, cart total reflects final value, no conflicts or errors occur

---

## Test Case 19: Update Quantity of Last Item to Zero
**ID:** CART-12-TC-019  
**Title:** Remove the only item in cart by setting quantity to 0  
**Precondition:** Shopper has exactly one item in cart  
**Steps:**
1. Navigate to cart
2. Clear quantity field and enter "0"
3. Press Enter or click Update button
4. Confirmation dialog asks "Remove this item?"
5. Click "Yes" or "Confirm"

**Expected Result:** Item is removed, cart displays empty state message, cart total shows 0

---

## Test Case 20: Session Persistence
**ID:** CART-12-TC-020  
**Title:** Verify quantity change persists across sessions  
**Precondition:** Shopper is logged in with items in cart  
**Steps:**
1. Navigate to cart
2. Update item quantity to 12
3. Close browser/logout
4. Login again and navigate to cart

**Expected Result:** Item quantity displays as 12, changes are persisted in backend
