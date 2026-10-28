# Test Cases for CART-12: Change the Quantity of an Item in the Cart

## Assumptions
- Testing platform: Web application
- Browser compatibility: Chrome, Firefox, Safari, Edge (latest versions)
- Test environment: Staging
- Quantity field is a numeric input with up/down spinner controls and manual text entry
- Cart must contain at least one item before quantity can be changed
- Previous quantity state is preserved until confirmed change
- Tests execute after item is added to cart and cart view is displayed

---

## TC-001: Change Quantity to Valid Number (Within 1-20 Range)
**Priority:** P0 - Critical  
**Category:** Positive Path

**Preconditions:**
- User is logged in
- Cart contains a single item with quantity of 1

**Steps:**
1. Navigate to cart view
2. Locate the quantity field for the item
3. Clear current value and enter "5"
4. Trigger update (Enter key or Update button)

**Expected Result:**
- Quantity field updates to 5
- Cart subtotal/total recalculates correctly
- No error message displayed
- Item remains in cart

---

## TC-002: Change Quantity Using Increment Spinner
**Priority:** P1 - High  
**Category:** Positive Path

**Preconditions:**
- User is logged in
- Cart contains item with quantity of 3

**Steps:**
1. Navigate to cart view
2. Locate the quantity field
3. Click the increment (up arrow) button 4 times
4. Observe quantity field

**Expected Result:**
- Quantity increments to 7
- Each click increases quantity by 1
- No validation errors occur
- Cart totals update

---

## TC-003: Change Quantity Using Decrement Spinner
**Priority:** P1 - High  
**Category:** Positive Path

**Preconditions:**
- User is logged in
- Cart contains item with quantity of 10

**Steps:**
1. Navigate to cart view
2. Locate the quantity field
3. Click the decrement (down arrow) button 5 times

**Expected Result:**
- Quantity decreases to 5
- Each click decreases quantity by 1
- No validation errors occur
- Cart totals update

---

## TC-004: Set Quantity to Boundary Value - Minimum (1)
**Priority:** P1 - High  
**Category:** Boundary Testing

**Preconditions:**
- User is logged in
- Cart contains item with quantity of 5

**Steps:**
1. Navigate to cart view
2. Enter "1" in quantity field
3. Trigger update

**Expected Result:**
- Quantity updates to 1
- Item remains in cart
- No warning or error displayed

---

## TC-005: Set Quantity to Boundary Value - Maximum (20)
**Priority:** P1 - High  
**Category:** Boundary Testing

**Preconditions:**
- User is logged in
- Cart contains item with quantity of 10

**Steps:**
1. Navigate to cart view
2. Enter "20" in quantity field
3. Trigger update

**Expected Result:**
- Quantity updates to 20
- Item remains in cart
- No error or warning displayed

---

## TC-006: Attempt to Set Quantity Above Maximum (21)
**Priority:** P0 - Critical  
**Category:** Validation - Negative Path

**Preconditions:**
- User is logged in
- Cart contains item with quantity of 1
- Previous quantity is known to be 1

**Steps:**
1. Navigate to cart view
2. Enter "21" in quantity field
3. Attempt to trigger update

**Expected Result:**
- Error message displays: "You can buy at most 20 of this item."
- Quantity field reverts to previous value (1)
- Item remains in cart
- Cart totals not recalculated

---

## TC-007: Attempt to Set Quantity to Large Number (999)
**Priority:** P1 - High  
**Category:** Validation - Negative Path

**Preconditions:**
- User is logged in
- Cart contains item with quantity of 5
- Previous quantity is known to be 5

**Steps:**
1. Navigate to cart view
2. Enter "999" in quantity field
3. Trigger update

**Expected Result:**
- Error message displays: "You can buy at most 20 of this item."
- Quantity reverts to 5
- Item remains in cart

---

## TC-008: Set Quantity to Zero - Confirmation Accept
**Priority:** P0 - Critical  
**Category:** Removal Flow

**Preconditions:**
- User is logged in
- Cart contains item with quantity of 3

**Steps:**
1. Navigate to cart view
2. Enter "0" in quantity field
3. Trigger update
4. Confirmation dialog appears with text "Remove this item?"
5. Click "Yes" or "Confirm" button

**Expected Result:**
- Confirmation dialog displays
- Item is removed from cart
- Cart subtotal/total recalculates
- If cart is now empty, "Your cart is empty" message may display

---

## TC-009: Set Quantity to Zero - Confirmation Reject
**Priority:** P0 - Critical  
**Category:** Removal Flow

**Preconditions:**
- User is logged in
- Cart contains item with quantity of 5

**Steps:**
1. Navigate to cart view
2. Enter "0" in quantity field
3. Trigger update
4. Confirmation dialog appears
5. Click "No" or "Cancel" button

**Expected Result:**
- Confirmation dialog closes
- Item remains in cart with original quantity (5)
- No changes to cart state
- No error message displayed

---

## TC-010: Set Quantity to Zero - Close Dialog Without Selection
**Priority:** P1 - High  
**Category:** Removal Flow

**Preconditions:**
- User is logged in
- Cart contains item with quantity of 7

**Steps:**
1. Navigate to cart view
2. Enter "0" in quantity field
3. Trigger update
4. Confirmation dialog appears with "Remove this item?"
5. Click the X button or press Escape key to close dialog

**Expected Result:**
- Dialog closes without action
- Item remains in cart with original quantity (7)
- Quantity field reverts to 7

---

## TC-011: Attempt to Set Quantity to Negative Number (-5)
**Priority:** P1 - High  
**Category:** Validation - Negative Path

**Preconditions:**
- User is logged in
- Cart contains item with quantity of 3

**Steps:**
1. Navigate to cart view
2. Enter "-5" in quantity field
3. Attempt to trigger update

**Expected Result:**
- Input field rejects negative value or shows validation error
- Quantity field remains unchanged at 3
- Item stays in cart

---

## TC-012: Attempt to Set Quantity to Decimal Number (2.5)
**Priority:** P1 - High  
**Category:** Validation - Negative Path

**Preconditions:**
- User is logged in
- Cart contains item with quantity of 4

**Steps:**
1. Navigate to cart view
2. Enter "2.5" in quantity field
3. Attempt to trigger update

**Expected Result:**
- Input field rejects decimal or rounds to whole number (2)
- If rounded, quantity updates to 2
- If rejected, quantity remains at 4 with error message
- Confirmation consistent with AC-1 (whole numbers only)

---

## TC-013: Attempt to Set Quantity to Non-Numeric Value (ABC)
**Priority:** P1 - High  
**Category:** Validation - Negative Path

**Preconditions:**
- User is logged in
- Cart contains item with quantity of 2

**Steps:**
1. Navigate to cart view
2. Enter "ABC" in quantity field
3. Attempt to trigger update

**Expected Result:**
- Input field rejects non-numeric characters
- Quantity field remains at 2
- Error message or validation feedback displayed
- Item remains in cart

---

## TC-014: Change Quantity Multiple Times Consecutively
**Priority:** P1 - High  
**Category:** User Flow

**Preconditions:**
- User is logged in
- Cart contains item with quantity of 1

**Steps:**
1. Navigate to cart view
2. Change quantity to 5
3. Trigger update and observe result
4. Change quantity to 12
5. Trigger update and observe result
6. Change quantity to 3
7. Trigger update and observe result

**Expected Result:**
- Each quantity change processes independently
- Final quantity is 3
- Cart totals update after each change
- No errors or unexpected behavior
- No data loss between updates

---

## TC-015: Change Quantity with Multiple Items in Cart
**Priority:** P1 - High  
**Category:** User Flow - Multi-item

**Preconditions:**
- User is logged in
- Cart contains 3 different items with quantities 2, 5, 10

**Steps:**
1. Navigate to cart view
2. Change quantity of second item from 5 to 8
3. Trigger update

**Expected Result:**
- Only the targeted item's quantity updates to 8
- First item remains quantity 2
- Third item remains quantity 10
- Cart totals recalculate correctly
- Other items unaffected

---

## TC-016: Verify Cart Totals Update After Quantity Change
**Priority:** P1 - High  
**Category:** Integration

**Preconditions:**
- User is logged in
- Cart contains item priced at $10.00 with quantity 2 (subtotal $20.00)

**Steps:**
1. Navigate to cart view
2. Change quantity to 5
3. Trigger update
4. Observe subtotal, taxes (if applicable), and total

**Expected Result:**
- Subtotal updates to $50.00 (5 × $10.00)
- Tax calculated correctly if applicable
- Total recalculates accurately
- Price per unit remains $10.00

---

## TC-017: Change Quantity Then Navigate Away and Return
**Priority:** P0 - Critical  
**Category:** Data Persistence

**Preconditions:**
- User is logged in
- Cart contains item with original quantity of 3

**Steps:**
1. Navigate to cart view
2. Change quantity to 7
3. Trigger update
4. Navigate to product page or home
5. Return to cart view

**Expected Result:**
- Quantity persists as 7
- Changes are saved to cart session/database
- No reversion to previous quantity

---

## TC-018: Attempt Rapid Consecutive Quantity Changes
**Priority:** P2 - Medium  
**Category:** Edge Case - Performance

**Preconditions:**
- User is logged in
- Cart contains item with quantity of 1

**Steps:**
1. Navigate to cart view
2. Rapidly click increment button 10 times within 2 seconds
3. Allow cart to settle

**Expected Result:**
- All changes are processed correctly (quantity becomes 11)
- No race conditions or skipped increments
- Cart updates consistently
- No errors logged

---

## TC-019: Change Quantity with Low Inventory Stock (if applicable)
**Priority:** P2 - Medium  
**Category:** Business Logic

**Preconditions:**
- User is logged in
- Cart contains item with only 15 units in stock
- Quantity currently set to 5

**Steps:**
1. Navigate to cart view
2. Attempt to change quantity to 20

**Expected Result:**
- Either: Quantity updates to 20 and checkout shows stock warning, OR
- Error message displays: "Only 15 in stock" and quantity reverts to 5
- Behavior should be documented per business requirements

---

## TC-020: Verify Accessibility - Keyboard Navigation
**Priority:** P1 - High  
**Category:** Accessibility

**Preconditions:**
- User is logged in
- Cart contains item with quantity of 2
- Testing on keyboard-only navigation

**Steps:**
1. Navigate to cart view using Tab key
2. Focus quantity field for an item
3. Enter new quantity "8" using keyboard
4. Trigger update using Enter key
5. Observe confirmation dialog if applicable and respond using keyboard

**Expected Result:**
- All quantity field controls are keyboard accessible
- Tab order is logical and sequential
- Enter key triggers update
- Confirmation dialog is navigable via keyboard
- Screen reader announces field label and current value

---

## TC-021: Change Quantity on Mobile Device
**Priority:** P1 - High  
**Category:** Responsive Design

**Preconditions:**
- User is logged in
- Cart contains item with quantity of 3
- Testing on mobile device (iOS/Android) or responsive viewport (375px width)

**Steps:**
1. Navigate to cart view
2. Tap quantity field
3. Enter "7" using mobile keyboard
4. Tap update/confirm button

**Expected Result:**
- Quantity field is appropriately sized for touch
- Spinner buttons (if present) are easily tappable (minimum 44×44 px)
- Mobile keyboard appears correctly
- Update processes without issues
- No layout shifts or usability problems

---

## TC-022: Change Quantity with Session Timeout
**Priority:** P2 - Medium  
**Category:** Edge Case - Session Management

**Preconditions:**
- User is logged in
- Cart contains item with quantity of 4
- User session is about to expire

**Steps:**
1. Navigate to cart view
2. Wait for session to timeout
3. Change quantity to 8
4. Attempt to trigger update

**Expected Result:**
- User is prompted to re-authenticate, OR
- Error message indicates session expired
- Cart changes are not lost (retained if possible)
- User can login and retry the quantity change

---

## TC-023: Verify Error Message Clarity for Quantity 0
**Priority:** P1 - High  
**Category:** User Experience

**Preconditions:**
- User is logged in
- Cart contains item with quantity of 2

**Steps:**
1. Navigate to cart view
2. Set quantity to 0
3. Read confirmation dialog message carefully

**Expected Result:**
- Confirmation message is exactly: "Remove this item?"
- Message is clear and unambiguous
- Dialog has distinct "Yes/Confirm" and "No/Cancel" buttons
- Button labels are clear

---

## TC-024: Verify Error Message Clarity for Quantity Over 20
**Priority:** P1 - High  
**Category:** User Experience

**Preconditions:**
- User is logged in
- Cart contains item with quantity of 5

**Steps:**
1. Navigate to cart view
2. Enter "25" in quantity field
3. Read error message displayed

**Expected Result:**
- Error message is exactly: "You can buy at most 20 of this item."
- Message is clearly visible and distinguishable from success states
- Message uses appropriate color (e.g., red for error)
- Message disappears or is dismissed appropriately

---

## Notes on Testing Strategy
- **Priority Levels:** P0 (Critical - blockers), P1 (High - core functionality), P2 (Medium - nice-to-have)
- **Test Execution:** Manual testing recommended for UX/flow verification; automation recommended for regression suite
- **Browser Testing:** Run critical path tests (TC-001, TC-006, TC-008, TC-009) across all supported browsers
- **Regression:** After any backend quantity validation changes, re-run all AC-based tests (TC-004 through TC-013)
- **Performance:** Monitor cart update response time; acceptable threshold: <500ms
