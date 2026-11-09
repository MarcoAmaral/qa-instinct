# Test Cases for CART-12: Change the Quantity of an Item in the Cart

## TC-1: Valid Quantity Input - Lower Boundary
**Objective:** Verify that the quantity field accepts 1 (minimum valid quantity)
**Preconditions:** 
- User has an item in their cart with quantity 2
**Steps:**
1. User clicks on the quantity field for the item
2. User clears the field and enters "1"
3. User confirms the change
**Expected Result:** 
- Quantity updates to 1
- No error message is displayed
- Cart total is recalculated

---

## TC-2: Valid Quantity Input - Upper Boundary
**Objective:** Verify that the quantity field accepts 20 (maximum valid quantity)
**Preconditions:** 
- User has an item in their cart with quantity 5
**Steps:**
1. User clicks on the quantity field for the item
2. User clears the field and enters "20"
3. User confirms the change
**Expected Result:** 
- Quantity updates to 20
- No error message is displayed
- Cart total is recalculated

---

## TC-3: Valid Quantity Input - Mid-Range
**Objective:** Verify that the quantity field accepts mid-range values
**Preconditions:** 
- User has an item in their cart with quantity 3
**Steps:**
1. User clicks on the quantity field for the item
2. User clears the field and enters "10"
3. User confirms the change
**Expected Result:** 
- Quantity updates to 10
- No error message is displayed
- Cart total is recalculated

---

## TC-4: Zero Quantity - Confirms Removal
**Objective:** Verify that entering 0 triggers confirmation dialog and removes item when confirmed
**Preconditions:** 
- User has an item in their cart with quantity 2
**Steps:**
1. User clicks on the quantity field for the item
2. User clears the field and enters "0"
3. User confirms the change
4. Confirmation dialog appears with text "Remove this item?"
5. User clicks "Yes" or "Confirm"
**Expected Result:** 
- Item is removed from the cart
- Cart total is recalculated
- Cart count decreases

---

## TC-5: Zero Quantity - Cancels Removal
**Objective:** Verify that entering 0 and canceling keeps the item with previous quantity
**Preconditions:** 
- User has an item in their cart with quantity 3
**Steps:**
1. User clicks on the quantity field for the item
2. User clears the field and enters "0"
3. User confirms the change
4. Confirmation dialog appears with text "Remove this item?"
5. User clicks "No" or "Cancel"
**Expected Result:** 
- Item remains in the cart
- Quantity reverts to the previous value (3)
- No changes to cart total

---

## TC-6: Quantity Above Maximum - Single Digit
**Objective:** Verify that entering 21 shows error message and retains previous quantity
**Preconditions:** 
- User has an item in their cart with quantity 15
**Steps:**
1. User clicks on the quantity field for the item
2. User clears the field and enters "21"
3. User confirms the change
**Expected Result:** 
- Error message displays: "You can buy at most 20 of this item."
- Quantity remains at 15 (previous value)
- Cart total is unchanged

---

## TC-7: Quantity Above Maximum - Large Number
**Objective:** Verify that entering a significantly large number shows error message and retains previous quantity
**Preconditions:** 
- User has an item in their cart with quantity 8
**Steps:**
1. User clicks on the quantity field for the item
2. User clears the field and enters "100"
3. User confirms the change
**Expected Result:** 
- Error message displays: "You can buy at most 20 of this item."
- Quantity remains at 8 (previous value)
- Cart total is unchanged

---

## TC-8: Negative Number Input
**Objective:** Verify that entering a negative number is rejected
**Preconditions:** 
- User has an item in their cart with quantity 5
**Steps:**
1. User clicks on the quantity field for the item
2. User clears the field and enters "-5"
3. User confirms the change
**Expected Result:** 
- Error message is displayed (either "You can buy at most 20 of this item." or quantity-specific validation error)
- Quantity remains at 5 (previous value)

**Assumption:** Negative numbers are treated as invalid input and rejected.

---

## TC-9: Non-Numeric Input - Letters
**Objective:** Verify that non-numeric input is rejected
**Preconditions:** 
- User has an item in their cart with quantity 4
**Steps:**
1. User clicks on the quantity field for the item
2. User clears the field and enters "abc"
3. User attempts to confirm
**Expected Result:** 
- Field shows validation error or rejects non-numeric input
- Quantity remains at 4 (previous value)

**Assumption:** Non-numeric characters are not accepted by the field or trigger validation error.

---

## TC-10: Empty Field
**Objective:** Verify that leaving quantity field empty is handled appropriately
**Preconditions:** 
- User has an item in their cart with quantity 6
**Steps:**
1. User clicks on the quantity field for the item
2. User clears the field completely
3. User attempts to confirm or tabs away
**Expected Result:** 
- Either quantity field shows validation error or automatically reverts to previous value (6)
- Cart is not updated

**Assumption:** Empty input is not allowed and the system requires a valid number.

---

## TC-11: Decimal Number Input
**Objective:** Verify that decimal numbers are rejected (only whole numbers allowed)
**Preconditions:** 
- User has an item in their cart with quantity 7
**Steps:**
1. User clicks on the quantity field for the item
2. User clears the field and enters "5.5"
3. User attempts to confirm
**Expected Result:** 
- Field shows validation error or rejects decimal input
- Quantity remains at 7 (previous value)

**Assumption:** Only whole numbers are accepted; decimals are invalid.

---

## TC-12: Rapid Quantity Changes
**Objective:** Verify that multiple rapid quantity changes are handled correctly
**Preconditions:** 
- User has an item in their cart with quantity 2
**Steps:**
1. User changes quantity to 5
2. Immediately changes quantity to 10
3. Waits for confirmation
**Expected Result:** 
- Final quantity displayed is 10
- Cart total reflects the latest change (10)
- No error or race condition occurs

---

## TC-13: Boundary Test - Quantity 1 to 2
**Objective:** Verify increment from minimum quantity works
**Preconditions:** 
- User has an item in their cart with quantity 1
**Steps:**
1. User clicks on the quantity field for the item
2. User changes field to "2"
3. User confirms the change
**Expected Result:** 
- Quantity updates to 2
- Cart total is recalculated

---

## TC-14: Boundary Test - Quantity 20 to 21
**Objective:** Verify that incrementing from 20 to 21 is rejected
**Preconditions:** 
- User has an item in their cart with quantity 20
**Steps:**
1. User clicks on the quantity field for the item
2. User changes field to "21"
3. User confirms the change
**Expected Result:** 
- Error message displays: "You can buy at most 20 of this item."
- Quantity remains at 20

---

## TC-15: Multiple Items - Independent Changes
**Objective:** Verify that changing quantity of one item does not affect other items
**Preconditions:** 
- User has 2 items in cart: Item A (qty 3) and Item B (qty 5)
**Steps:**
1. User changes quantity of Item A to 7
2. User confirms the change
**Expected Result:** 
- Item A quantity updates to 7
- Item B quantity remains at 5
- Cart total reflects only Item A's change

---

## TC-16: Special Characters Input
**Objective:** Verify that special characters in quantity field are rejected
**Preconditions:** 
- User has an item in their cart with quantity 4
**Steps:**
1. User clicks on the quantity field for the item
2. User enters "@" or "#" or other special characters
3. User attempts to confirm
**Expected Result:** 
- Field does not accept special characters or shows validation error
- Quantity remains at 4

**Assumption:** Special characters are not accepted by the field.
