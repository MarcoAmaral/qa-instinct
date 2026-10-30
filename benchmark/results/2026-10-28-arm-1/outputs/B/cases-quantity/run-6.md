# Test Cases for CART-12: Change Quantity of Item in Cart

**Assumptions:**
- The quantity field is a text input or numeric input control
- Previous quantity refers to the quantity before the user's attempted change
- The cart contains at least one item for testing
- Quantity changes trigger immediate validation
- The system persists quantity changes (cart state is saved)
- Dialog confirmation/cancellation works as expected

---

## TC-01: Valid Quantity Change - Single Item
**Precondition:** Cart contains an item with quantity 1  
**Steps:**
1. Click quantity field for the item
2. Clear current value and enter "5"
3. Trigger change (blur, press Enter, or click confirm)

**Expected Result:** Quantity updates to 5; no error message; item remains in cart

---

## TC-02: Valid Quantity Change - Maximum Allowed
**Precondition:** Cart contains an item with quantity 10  
**Steps:**
1. Click quantity field
2. Change value to "20"
3. Trigger change

**Expected Result:** Quantity updates to 20; no error message; item remains in cart

---

## TC-03: Valid Quantity Change - Minimum Allowed
**Precondition:** Cart contains an item with quantity 5  
**Steps:**
1. Click quantity field
2. Change value to "1"
3. Trigger change

**Expected Result:** Quantity updates to 1; no error message; item remains in cart

---

## TC-04: Quantity Zero - Confirm Removal
**Precondition:** Cart contains an item with quantity 3  
**Steps:**
1. Click quantity field
2. Enter "0"
3. Trigger change
4. Confirmation dialog appears with message "Remove this item?"
5. Click "Yes" or "Confirm" button

**Expected Result:** Item is removed from cart; confirmation dialog closes; cart updates

---

## TC-05: Quantity Zero - Cancel Removal
**Precondition:** Cart contains an item with quantity 3  
**Steps:**
1. Click quantity field
2. Enter "0"
3. Trigger change
4. Confirmation dialog appears
5. Click "No" or "Cancel" button

**Expected Result:** Confirmation dialog closes; quantity remains 3; item stays in cart

---

## TC-06: Quantity Above Maximum (21)
**Precondition:** Cart contains an item with quantity 5  
**Steps:**
1. Click quantity field
2. Enter "21"
3. Trigger change

**Expected Result:** Error message displays "You can buy at most 20 of this item."; quantity reverts to 5 (previous value); item remains in cart

---

## TC-07: Quantity Above Maximum (100)
**Precondition:** Cart contains an item with quantity 10  
**Steps:**
1. Click quantity field
2. Enter "100"
3. Trigger change

**Expected Result:** Error message displays "You can buy at most 20 of this item."; quantity reverts to 10; item remains in cart

---

## TC-08: Decimal/Non-Whole Number Input
**Precondition:** Cart contains an item with quantity 2  
**Steps:**
1. Click quantity field
2. Enter "5.5"
3. Trigger change

**Expected Result:** Input is either rejected/not allowed, or decimal is stripped and quantity updates to 5 (or system displays validation error and keeps previous quantity of 2)

---

## TC-09: Negative Number Input
**Precondition:** Cart contains an item with quantity 3  
**Steps:**
1. Click quantity field
2. Enter "-5"
3. Trigger change

**Expected Result:** Input is rejected; validation error displays (or confirmation dialog triggers if treated as zero); quantity reverts to 3

---

## TC-10: Non-Numeric Input
**Precondition:** Cart contains an item with quantity 4  
**Steps:**
1. Click quantity field
2. Enter "abc"
3. Trigger change

**Expected Result:** Input is rejected; validation error displays or quantity field remains unchanged; previous quantity of 4 persists

---

## TC-11: Empty/Blank Input
**Precondition:** Cart contains an item with quantity 6  
**Steps:**
1. Click quantity field
2. Clear all characters (leave field blank)
3. Trigger change

**Expected Result:** Either treated as zero (confirmation dialog appears) or validation error displays; quantity doesn't update to blank

---

## TC-12: Boundary Test - Change from 20 to 1
**Precondition:** Cart contains an item with quantity 20  
**Steps:**
1. Click quantity field
2. Change value to "1"
3. Trigger change

**Expected Result:** Quantity updates to 1; no error; item remains in cart

---

## TC-13: Rapid Quantity Changes
**Precondition:** Cart contains an item with quantity 5  
**Steps:**
1. Click quantity field and enter "10"
2. Immediately change to "15" without waiting for first change to complete
3. Trigger change

**Expected Result:** Final quantity is 15; no errors; cart reflects latest valid input

---

## TC-14: Quantity Change with Multiple Items in Cart
**Precondition:** Cart contains 3 items (Qty: 2, 3, 5)  
**Steps:**
1. Change quantity of second item from 3 to 8
2. Trigger change

**Expected Result:** Only second item quantity updates to 8; other items (2 and 5) remain unchanged

---

## TC-15: Dialog Cancel Followed by Valid Change
**Precondition:** Cart contains an item with quantity 2  
**Steps:**
1. Enter "0" and cancel removal dialog
2. Enter "10" and trigger change

**Expected Result:** Quantity updates to 10; item remains in cart

---

## TC-16: Whitespace in Input
**Precondition:** Cart contains an item with quantity 3  
**Steps:**
1. Click quantity field
2. Enter " 5 " (spaces around number)
3. Trigger change

**Expected Result:** Spaces are trimmed; quantity updates to 5

---
