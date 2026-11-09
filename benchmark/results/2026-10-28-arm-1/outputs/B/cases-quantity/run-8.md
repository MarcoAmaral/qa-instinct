# Test Cases for CART-12: Change Quantity of Item in Cart

## Assumptions
- Quantity field is an input field that accepts text entry
- "Previous quantity" refers to the quantity before the invalid input attempt
- Quantity validation occurs on input blur or submit
- Cart item persists until user confirms removal at quantity 0
- Error/confirmation messages are displayed as modal dialogs or inline alerts
- All quantity operations are for a single item in an existing cart

---

## Test Case 1: Valid Quantity - Lower Boundary
**ID:** CART-12-TC-001  
**Title:** Set quantity to minimum valid value (1)  
**Steps:**
1. Open cart with an item having quantity > 1
2. Click quantity field and clear current value
3. Enter "1"
4. Trigger input validation (blur or submit)

**Expected Result:** Quantity updates to 1, item remains in cart, no error message displayed

---

## Test Case 2: Valid Quantity - Upper Boundary
**ID:** CART-12-TC-002  
**Title:** Set quantity to maximum valid value (20)  
**Steps:**
1. Open cart with an item
2. Click quantity field and clear current value
3. Enter "20"
4. Trigger input validation

**Expected Result:** Quantity updates to 20, item remains in cart, no error message displayed

---

## Test Case 3: Valid Quantity - Mid-Range
**ID:** CART-12-TC-003  
**Title:** Set quantity to value within valid range  
**Steps:**
1. Open cart with an item
2. Click quantity field and clear current value
3. Enter "10"
4. Trigger input validation

**Expected Result:** Quantity updates to 10, item remains in cart

---

## Test Case 4: Zero Quantity - Confirm Removal
**ID:** CART-12-TC-004  
**Title:** Remove item by setting quantity to 0 and confirming removal  
**Steps:**
1. Open cart with an item having quantity ≥ 1
2. Click quantity field and clear current value
3. Enter "0"
4. Trigger input validation
5. Confirmation dialog appears: "Remove this item?"
6. Click "Yes" or "Confirm" button

**Expected Result:** Item is removed from cart, cart updates accordingly

---

## Test Case 5: Zero Quantity - Cancel Removal
**ID:** CART-12-TC-005  
**Title:** Cancel removal when setting quantity to 0  
**Steps:**
1. Open cart with an item having quantity = 5
2. Click quantity field and clear current value
3. Enter "0"
4. Trigger input validation
5. Confirmation dialog appears: "Remove this item?"
6. Click "Cancel" or "No" button

**Expected Result:** Item remains in cart with quantity of 5 (previous value restored)

---

## Test Case 6: Quantity Above Maximum
**ID:** CART-12-TC-006  
**Title:** Attempt to set quantity above maximum (21)  
**Steps:**
1. Open cart with an item having quantity = 10
2. Click quantity field and clear current value
3. Enter "21"
4. Trigger input validation

**Expected Result:** Error message displays: "You can buy at most 20 of this item.", quantity remains 10, item stays in cart

---

## Test Case 7: Quantity Significantly Above Maximum
**ID:** CART-12-TC-007  
**Title:** Attempt to set quantity far above maximum  
**Steps:**
1. Open cart with an item having quantity = 5
2. Click quantity field and clear current value
3. Enter "100"
4. Trigger input validation

**Expected Result:** Error message displays: "You can buy at most 20 of this item.", quantity remains 5

---

## Test Case 8: Negative Quantity
**ID:** CART-12-TC-008  
**Title:** Attempt to set negative quantity  
**Steps:**
1. Open cart with an item
2. Click quantity field and clear current value
3. Enter "-5"
4. Trigger input validation

**Expected Result:** Input rejected or error displayed, quantity unchanged

---

## Test Case 9: Decimal Quantity
**ID:** CART-12-TC-009  
**Title:** Attempt to enter decimal value  
**Steps:**
1. Open cart with an item having quantity = 3
2. Click quantity field and clear current value
3. Enter "5.5"
4. Trigger input validation

**Expected Result:** Input rejected, quantity remains 3, error message displays (or input field only accepts integers)

---

## Test Case 10: Non-Numeric Input
**ID:** CART-12-TC-010  
**Title:** Attempt to enter non-numeric characters  
**Steps:**
1. Open cart with an item having quantity = 2
2. Click quantity field and clear current value
3. Enter "abc"
4. Trigger input validation

**Expected Result:** Input rejected, quantity remains 2, field clears or reverts to previous value

---

## Test Case 11: Empty Quantity Field
**ID:** CART-12-TC-011  
**Title:** Submit with empty quantity field  
**Steps:**
1. Open cart with an item having quantity = 4
2. Click quantity field and clear it completely
3. Leave field empty and trigger validation

**Expected Result:** Error message displays or field reverts to previous value, quantity remains 4

---

## Test Case 12: Quantity 0 Without Confirmation Timeout
**ID:** CART-12-TC-012  
**Title:** Confirmation dialog remains until user acts  
**Steps:**
1. Open cart with an item
2. Enter "0" and trigger validation
3. Confirmation dialog appears
4. Wait 30 seconds without clicking any button

**Expected Result:** Dialog remains visible, item is not removed without user action

---

## Test Case 13: Rapid Quantity Changes
**ID:** CART-12-TC-013  
**Title:** Change quantity multiple times in succession  
**Steps:**
1. Open cart with an item
2. Set quantity to 5, then 10, then 15
3. Trigger validation after each change

**Expected Result:** Each change updates correctly, final quantity is 15

---

## Test Case 14: Update Quantity at Boundary After Error
**ID:** CART-12-TC-014  
**Title:** Successfully set quantity to 20 after attempting 21  
**Steps:**
1. Open cart with an item having quantity = 5
2. Enter "21" and trigger validation (error message appears)
3. Clear field and enter "20"
4. Trigger validation

**Expected Result:** Quantity updates to 20, error message disappears

---

## Test Case 15: Update Quantity After Canceling Removal
**ID:** CART-12-TC-015  
**Title:** Change quantity after canceling removal confirmation  
**Steps:**
1. Open cart with an item having quantity = 8
2. Enter "0" and trigger validation
3. In confirmation dialog, click "Cancel"
4. Enter "12" in quantity field
5. Trigger validation

**Expected Result:** Quantity updates to 12, item remains in cart
