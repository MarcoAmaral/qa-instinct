# Test Cases: CART-12 Change Quantity of Item in Cart

**Assumptions Made:**
- Quantity field can be updated via direct text input and/or increment/decrement buttons
- Items in cart are in stock; no inventory constraints beyond the 20-item limit
- System rejects non-integer, negative, or decimal inputs
- Test environment uses modern web browsers (Chrome, Firefox, Safari, Edge)
- "Remove item" confirmation dialog appears inline or as a modal popup
- Previous quantity is retained in the input field when an invalid value is rejected

---

## AC-1: Valid Quantity Input (1–20)

### CART-12-TC-01: Set Quantity to Minimum Valid Value (1)
**Precondition:** User has an item in cart with quantity > 1
**Steps:**
1. Locate the quantity field for the item
2. Clear the current value and enter "1"
3. Press Enter or click outside the field

**Expected Result:** Quantity updates to 1; cart total updates accordingly

---

### CART-12-TC-02: Set Quantity to Mid-Range Value (10)
**Precondition:** User has an item in cart with quantity ≠ 10
**Steps:**
1. Locate the quantity field for the item
2. Clear the current value and enter "10"
3. Press Enter or click outside the field

**Expected Result:** Quantity updates to 10; cart total updates accordingly

---

### CART-12-TC-03: Set Quantity to Maximum Valid Value (20)
**Precondition:** User has an item in cart with quantity < 20
**Steps:**
1. Locate the quantity field for the item
2. Clear the current value and enter "20"
3. Press Enter or click outside the field

**Expected Result:** Quantity updates to 20; cart total updates accordingly

---

### CART-12-TC-04: Increment Quantity Using + Button (if available)
**Precondition:** User has an item in cart with quantity < 20; a "+" increment button exists
**Steps:**
1. Click the "+" button repeatedly to increase quantity from 1 to 5

**Expected Result:** Quantity increments by 1 with each click; cart total updates

---

### CART-12-TC-05: Decrement Quantity Using − Button (if available)
**Precondition:** User has an item in cart with quantity > 1; a "−" decrement button exists
**Steps:**
1. Click the "−" button repeatedly to decrease quantity from 5 to 1

**Expected Result:** Quantity decrements by 1 with each click; cart total updates

---

## AC-1: Invalid Input Rejection

### CART-12-TC-06: Reject Quantity of 0 via Text Input (Triggers AC-2)
**Precondition:** User has an item in cart
**Steps:**
1. Locate the quantity field for the item
2. Clear and enter "0"
3. Press Enter or click outside the field

**Expected Result:** Confirmation dialog appears with text "Remove this item?" (Refer to AC-2 test cases)

---

### CART-12-TC-07: Reject Quantity Above 20 (Triggers AC-3)
**Precondition:** User has an item in cart with current quantity < 20
**Steps:**
1. Locate the quantity field for the item
2. Clear and enter "21"
3. Press Enter or click outside the field

**Expected Result:** Error message displays: "You can buy at most 20 of this item."; quantity field retains previous value (Refer to AC-3 test cases)

---

### CART-12-TC-08: Reject Decimal Input
**Precondition:** User has an item in cart
**Steps:**
1. Locate the quantity field for the item
2. Clear and enter "5.5"
3. Press Enter or click outside the field

**Expected Result:** Input is rejected or rounded to integer (e.g., 5 or 6); error message may display or field reverts to previous value

---

### CART-12-TC-09: Reject Negative Number
**Precondition:** User has an item in cart with quantity > 1
**Steps:**
1. Locate the quantity field for the item
2. Clear and enter "−5"
3. Press Enter or click outside the field

**Expected Result:** Input is rejected; field reverts to previous value; no confirmation dialog appears

---

### CART-12-TC-10: Reject Non-Numeric Characters
**Precondition:** User has an item in cart
**Steps:**
1. Locate the quantity field for the item
2. Clear and enter "five" or "abc"
3. Press Enter or click outside the field

**Expected Result:** Input is rejected; field reverts to previous value; no update to cart

---

### CART-12-TC-11: Reject Empty Field
**Precondition:** User has an item in cart with quantity > 0
**Steps:**
1. Locate the quantity field for the item
2. Clear the field completely (leave blank)
3. Press Enter or click outside the field

**Expected Result:** Field reverts to previous value or shows error; quantity does not change

---

## AC-2: Remove Item at Quantity 0

### CART-12-TC-12: Confirm Item Removal After Setting Quantity to 0
**Precondition:** User has an item in cart; quantity field is currently set to a value > 0
**Steps:**
1. Locate the quantity field for the item
2. Clear and enter "0"
3. Press Enter or click outside the field
4. Confirmation dialog appears with message "Remove this item?"
5. Click the "Confirm" or "Yes" button

**Expected Result:** Item is removed from cart; cart total updates; item no longer appears in cart display

---

### CART-12-TC-13: Cancel Item Removal After Setting Quantity to 0
**Precondition:** User has an item in cart; quantity field is currently set to a value > 0
**Steps:**
1. Locate the quantity field for the item
2. Clear and enter "0"
3. Press Enter or click outside the field
4. Confirmation dialog appears with message "Remove this item?"
5. Click the "Cancel" or "No" button (or press Esc)

**Expected Result:** Dialog closes; item remains in cart; quantity field reverts to previous value (> 0); cart total unchanged

---

### CART-12-TC-14: Dismiss Confirmation Dialog by Clicking Outside
**Precondition:** User has set quantity to 0 and confirmation dialog is open
**Steps:**
1. Click outside the confirmation dialog (on the page background, if modal allows)

**Expected Result:** Dialog closes; item remains in cart; quantity field reverts to previous value; cart total unchanged

---

## AC-3: Reject Quantity Above 20

### CART-12-TC-15: Reject Quantity of 21
**Precondition:** User has an item in cart with quantity ≤ 20
**Steps:**
1. Locate the quantity field for the item
2. Note the current quantity value
3. Clear and enter "21"
4. Press Enter or click outside the field

**Expected Result:** Error message displays: "You can buy at most 20 of this item."; quantity field retains the original value; cart total unchanged

---

### CART-12-TC-16: Reject Large Quantity (e.g., 100)
**Precondition:** User has an item in cart with quantity ≤ 20
**Steps:**
1. Locate the quantity field for the item
2. Note the current quantity value
3. Clear and enter "100"
4. Press Enter or click outside the field

**Expected Result:** Error message displays: "You can buy at most 20 of this item."; quantity field retains the original value; cart total unchanged

---

### CART-12-TC-17: Exceed Limit Using Increment Button Repeatedly
**Precondition:** User has an item in cart with quantity = 20; a "+" increment button exists
**Steps:**
1. Click the "+" button once to attempt incrementing from 20 to 21

**Expected Result:** Button click is disabled, no-op, or error message displays; quantity remains 20

---

## Edge Cases & Integration

### CART-12-TC-18: Update Multiple Items Sequentially
**Precondition:** User has 3 different items in cart
**Steps:**
1. Change quantity of item 1 from 2 to 5
2. Change quantity of item 2 from 1 to 10
3. Change quantity of item 3 from 4 to 3

**Expected Result:** All changes apply correctly; cart total reflects all three updates; no interference between items

---

### CART-12-TC-19: Rapid Successive Quantity Changes
**Precondition:** User has an item in cart
**Steps:**
1. Quickly enter "5", press Enter
2. Immediately enter "10", press Enter
3. Immediately enter "15", press Enter
4. Wait for cart to fully update

**Expected Result:** Final quantity is 15; cart total updates to reflect final state; no race conditions or lost updates

---

### CART-12-TC-20: Preserve Quantity on Page Refresh (Session Persistence)
**Precondition:** User has updated item quantity to a valid value (e.g., 7)
**Steps:**
1. Change quantity to 7
2. Refresh the browser page
3. Observe the cart contents

**Expected Result:** Item quantity is still 7; cart total matches the pre-refresh state

---

### CART-12-TC-21: Verify Price Calculation Accuracy
**Precondition:** User has an item with unit price $10.00 in cart at quantity 1
**Steps:**
1. Change quantity to 5
2. Observe the item subtotal and cart total

**Expected Result:** Item subtotal displays $50.00 (5 × $10.00); cart total is updated correctly with all items

---

### CART-12-TC-22: Ensure Accessibility (Screen Reader)
**Precondition:** User is using a screen reader; an item is in cart
**Steps:**
1. Navigate to the quantity field using keyboard/screen reader
2. Read the field label and description
3. Change the quantity value
4. Listen for confirmation of the update

**Expected Result:** Quantity field is properly labeled; value changes are announced; error messages and confirmations are read aloud

---

### CART-12-TC-23: Test on Mobile Device (Touch Input)
**Precondition:** User is on a mobile device; an item is in cart
**Steps:**
1. Tap the quantity field to open the keyboard
2. Enter a valid quantity (e.g., 8)
3. Tap outside the field or press Done

**Expected Result:** Quantity updates correctly; keyboard closes; cart total updates on mobile display

---

### CART-12-TC-24: Verify Field Input Type Attribute
**Precondition:** Browser developer tools are open
**Steps:**
1. Inspect the quantity input field HTML
2. Verify the input type attribute

**Expected Result:** Input type is `number` or `text` with appropriate validation; if `number`, browser native spinner controls (if any) function within 1–20 bounds
