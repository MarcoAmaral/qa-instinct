# Test Cases for CART-12: Change the Quantity of an Item in the Cart

## Assumptions
- An item must already exist in the cart before quantity can be modified
- The quantity field is a text input or numeric input element
- "Previous quantity" refers to the quantity value before an invalid change attempt
- System validates quantity changes synchronously (real-time or on blur)
- Decimal inputs are treated as invalid (not rounded)
- Copy-paste of invalid values follows the same validation rules as manual entry

---

## AC-1: The quantity field accepts whole numbers from 1 to 20

### TC-AC1-001: Change quantity to valid value (1)
**Preconditions:** Item exists in cart with quantity 2
**Steps:**
1. Click quantity field for the item
2. Clear current value
3. Enter "1"
4. Confirm/blur field

**Expected:** Quantity updates to 1; cart total recalculates; no error message displays

---

### TC-AC1-002: Change quantity to valid value (mid-range, 10)
**Preconditions:** Item exists in cart with quantity 5
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter "10"
4. Confirm/blur field

**Expected:** Quantity updates to 10; cart total recalculates; no error message displays

---

### TC-AC1-003: Change quantity to valid value (maximum boundary, 20)
**Preconditions:** Item exists in cart with quantity 1
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter "20"
4. Confirm/blur field

**Expected:** Quantity updates to 20; cart total recalculates; no error message displays

---

### TC-AC1-004: Increment quantity within valid range
**Preconditions:** Item exists in cart with quantity 5
**Steps:**
1. Click quantity field
2. Select all text
3. Enter "15"
4. Confirm/blur field

**Expected:** Quantity updates to 15; no error displays

---

### TC-AC1-005: Decrement quantity within valid range
**Preconditions:** Item exists in cart with quantity 10
**Steps:**
1. Click quantity field
2. Select all text
3. Enter "3"
4. Confirm/blur field

**Expected:** Quantity updates to 3; no error displays

---

### TC-AC1-006: Accept only whole numbers (reject decimal .5)
**Preconditions:** Item exists in cart with quantity 5
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter "10.5"
4. Confirm/blur field

**Expected:** Entry is rejected or rounded down to 10; previous quantity (5) is retained; error message may display

---

### TC-AC1-007: Accept only whole numbers (reject decimal .99)
**Preconditions:** Item exists in cart with quantity 8
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter "15.99"
4. Confirm/blur field

**Expected:** Entry is rejected; quantity remains 8; no change to cart

---

---

## AC-2: Setting quantity to 0 asks "Remove this item?" and removes only on confirmation

### TC-AC2-001: Enter 0 and confirm removal
**Preconditions:** Item exists in cart with quantity 5
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter "0"
4. Confirm/blur field
5. Confirmation dialog appears asking "Remove this item?"
6. Click "Yes" or "Confirm" button

**Expected:** Dialog displays; upon confirmation, item is removed from cart; cart total updates; cart item row disappears

---

### TC-AC2-002: Enter 0 and cancel removal
**Preconditions:** Item exists in cart with quantity 5
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter "0"
4. Confirm/blur field
5. Confirmation dialog appears asking "Remove this item?"
6. Click "No" or "Cancel" button

**Expected:** Dialog displays; upon cancellation, quantity reverts to previous value (5); item remains in cart

---

### TC-AC2-003: Enter 0 and dismiss dialog by clicking outside
**Preconditions:** Item exists in cart with quantity 3
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter "0"
4. Confirm/blur field
5. Confirmation dialog appears
6. Click outside the dialog (on cart background)

**Expected:** Dialog closes; quantity reverts to 3; item remains in cart

---

### TC-AC2-004: Enter 0 and dismiss dialog via Escape key
**Preconditions:** Item exists in cart with quantity 7
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter "0"
4. Confirm/blur field
5. Confirmation dialog appears
6. Press Escape key

**Expected:** Dialog closes; quantity reverts to 7; item remains in cart

---

### TC-AC2-005: Confirm removal from dialog with keyboard (Enter key)
**Preconditions:** Item exists in cart with quantity 2
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter "0"
4. Confirm/blur field
5. Confirmation dialog appears with focus on "Confirm" button
6. Press Enter

**Expected:** Item is removed from cart; dialog closes; cart updates

---

---

## AC-3: A quantity above 20 shows "You can buy at most 20 of this item." and keeps previous quantity

### TC-AC3-001: Enter 21 (boundary + 1)
**Preconditions:** Item exists in cart with quantity 10
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter "21"
4. Confirm/blur field

**Expected:** Error message "You can buy at most 20 of this item." displays; quantity remains 10; cart total unchanged

---

### TC-AC3-002: Enter 25 (well above limit)
**Preconditions:** Item exists in cart with quantity 5
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter "25"
4. Confirm/blur field

**Expected:** Error message displays; quantity remains 5; no cart update occurs

---

### TC-AC3-003: Enter 100 (far above limit)
**Preconditions:** Item exists in cart with quantity 15
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter "100"
4. Confirm/blur field

**Expected:** Error message displays; quantity remains 15; error persists until valid entry

---

### TC-AC3-004: Enter 999999 (extreme value)
**Preconditions:** Item exists in cart with quantity 8
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter "999999"
4. Confirm/blur field

**Expected:** Error message displays; quantity remains 8

---

### TC-AC3-005: Attempt to paste value above 20
**Preconditions:** Item exists in cart with quantity 12
**Steps:**
1. Click quantity field
2. Select all text
3. Paste "50" from clipboard
4. Blur field

**Expected:** Error message displays; quantity remains 12

---

---

## Additional Edge Cases & Validation Tests

### TC-EDGE-001: Enter negative number (-5)
**Preconditions:** Item exists in cart with quantity 10
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter "-5"
4. Confirm/blur field

**Expected:** Entry is rejected; quantity remains 10; error message may display

---

### TC-EDGE-002: Enter non-numeric text (alphabetic)
**Preconditions:** Item exists in cart with quantity 7
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter "abc"
4. Confirm/blur field

**Expected:** Entry is rejected; quantity remains 7; field shows error or clears invalid input

---

### TC-EDGE-003: Enter special characters (@, #, $)
**Preconditions:** Item exists in cart with quantity 6
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter "@#$"
4. Confirm/blur field

**Expected:** Entry is rejected; quantity remains 6

---

### TC-EDGE-004: Enter empty/blank value
**Preconditions:** Item exists in cart with quantity 9
**Steps:**
1. Click quantity field
2. Select all text
3. Delete to make field empty
4. Blur field

**Expected:** Field either reverts to previous quantity (9) or shows required field error; item not removed

---

### TC-EDGE-005: Enter value with leading zeros (007)
**Preconditions:** Item exists in cart with quantity 5
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter "007"
4. Confirm/blur field

**Expected:** Quantity updates to 7 (leading zeros ignored) or displays as "7"; no error

---

### TC-EDGE-006: Enter value with leading spaces ( 15)
**Preconditions:** Item exists in cart with quantity 4
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter " 15" (space before 15)
4. Confirm/blur field

**Expected:** Spaces trimmed; quantity updates to 15 OR entry rejected and quantity remains 4

---

### TC-EDGE-007: Rapidly change quantity multiple times
**Preconditions:** Item exists in cart with quantity 5
**Steps:**
1. Click quantity field
2. Enter "10"
3. Blur field (cart updates)
4. Click quantity field again
5. Enter "15"
6. Blur field (cart updates)
7. Click quantity field again
8. Enter "8"
9. Blur field

**Expected:** Each valid change updates cart sequentially; final quantity is 8; no race conditions; cart total reflects final quantity

---

### TC-EDGE-008: Attempt to change quantity to 0 then immediately change to valid value (undo via field)
**Preconditions:** Item exists in cart with quantity 6
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter "0"
4. Blur field
5. Confirmation dialog appears
6. Click "Cancel"
7. Click quantity field again
8. Enter "12"
9. Blur field

**Expected:** Dialog closes on cancel, quantity reverts to 6; then quantity successfully updates to 12

---

### TC-EDGE-009: Multiple items in cart—change quantity of one item, verify others unaffected
**Preconditions:** Cart contains Item A (qty 5) and Item B (qty 3)
**Steps:**
1. Click quantity field for Item A
2. Clear current value
3. Enter "18"
4. Blur field

**Expected:** Item A quantity updates to 18; Item B remains 3; cart total reflects correct calculation for both items

---

### TC-EDGE-010: Verify error message text is exactly as specified
**Preconditions:** Item exists in cart with quantity 5
**Steps:**
1. Click quantity field
2. Clear current value
3. Enter "21"
4. Blur field
5. Observe error message text

**Expected:** Error message displays exactly: "You can buy at most 20 of this item."

---

### TC-EDGE-011: Enter quantity at boundary, then exceed
**Preconditions:** Item exists in cart with quantity 1
**Steps:**
1. Click quantity field
2. Enter "20"
3. Blur field (succeeds)
4. Click quantity field again
5. Enter "21"
6. Blur field

**Expected:** First update succeeds (qty = 20); second update fails with error message; quantity remains 20

---

### TC-EDGE-012: Accessibility—Change quantity using only keyboard
**Preconditions:** Item exists in cart with quantity 5
**Steps:**
1. Tab to quantity field
2. Clear value (Ctrl+A, Delete)
3. Type "12"
4. Press Tab to move focus away (blur)

**Expected:** Quantity updates to 12; confirmation/error messages are accessible to screen readers

---
