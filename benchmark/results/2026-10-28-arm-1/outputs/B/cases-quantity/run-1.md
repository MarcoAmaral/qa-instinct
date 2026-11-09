# Test Cases for CART-12: Change Quantity of Item in Cart

## Assumptions
- The quantity field is a text input with increment/decrement controls or direct entry
- "Previous quantity" refers to the value before the user's attempted change
- Changes persist in the session/storage until checkout or page reload
- The cart contains at least one item before testing
- Browser: Chrome/Firefox/Safari (latest versions)
- Device: Desktop (1920x1080 minimum)

---

## Valid Quantity Entry (AC-1)

### TC-001: Enter minimum valid quantity (1)
**Given:** Item is in cart with quantity 2  
**When:** User changes quantity to 1  
**Then:** Quantity updates to 1, item remains in cart, price recalculates

### TC-002: Enter maximum valid quantity (20)
**Given:** Item is in cart with quantity 1  
**When:** User changes quantity to 20  
**Then:** Quantity updates to 20, item remains in cart, price recalculates

### TC-003: Enter mid-range valid quantity (10)
**Given:** Item is in cart with quantity 5  
**When:** User changes quantity to 10  
**Then:** Quantity updates to 10, item remains in cart, price recalculates

### TC-004: Increment quantity using + button
**Given:** Item is in cart with quantity 5  
**When:** User clicks + button 3 times  
**Then:** Quantity becomes 8, item remains in cart

### TC-005: Decrement quantity using - button
**Given:** Item is in cart with quantity 10  
**When:** User clicks - button 4 times  
**Then:** Quantity becomes 6, item remains in cart

### TC-006: Enter quantity via direct typing
**Given:** Item is in cart with quantity 2  
**When:** User clears field and types "15"  
**Then:** Quantity updates to 15 on blur or Enter key

### TC-007: Verify cart total recalculates correctly
**Given:** Item costs $10, quantity is 2 (subtotal $20)  
**When:** User changes quantity to 5  
**Then:** Item subtotal updates to $50, cart total recalculates

---

## Quantity Zero - Removal Confirmation (AC-2)

### TC-008: Set quantity to 0 triggers confirmation dialog
**Given:** Item is in cart with quantity 3  
**When:** User changes quantity to 0  
**Then:** Modal/dialog appears with message "Remove this item?"

### TC-009: Confirm removal removes item from cart
**Given:** Removal confirmation dialog is displayed  
**When:** User clicks "Confirm" or "Yes"  
**Then:** Item is removed from cart, cart item count decreases by 1

### TC-010: Cancel removal keeps item in cart
**Given:** Removal confirmation dialog is displayed  
**When:** User clicks "Cancel" or "No"  
**Then:** Item remains in cart with original quantity

### TC-011: Close dialog by X button keeps item
**Given:** Removal confirmation dialog is displayed  
**When:** User clicks X button to close dialog  
**Then:** Item remains in cart with original quantity, dialog closes

### TC-012: Close dialog by clicking outside keeps item
**Given:** Removal confirmation dialog is displayed and has backdrop  
**When:** User clicks outside the dialog on backdrop  
**Then:** Item remains in cart with original quantity, dialog closes

### TC-013: Zero on multiple items removes only selected item
**Given:** Cart contains 3 items  
**When:** User sets quantity to 0 on item 2 and confirms  
**Then:** Only item 2 is removed, items 1 and 3 remain

---

## Quantity Above Maximum (AC-3)

### TC-014: Enter quantity 21 shows error message
**Given:** Item is in cart with quantity 10  
**When:** User enters 21 in quantity field  
**Then:** Error message "You can buy at most 20 of this item." displays

### TC-015: Quantity stays at previous value after 21 entry
**Given:** Item has quantity 10, user enters 21  
**When:** Error message is shown  
**Then:** Quantity field reverts to 10 (previous value)

### TC-016: Enter quantity 100 shows error and reverts
**Given:** Item is in cart with quantity 5  
**When:** User types "100"  
**Then:** Error displays, quantity remains 5

### TC-017: Increment beyond 20 at boundary
**Given:** Item quantity is 20  
**When:** User clicks + button  
**Then:** Quantity stays at 20, no error (boundary protection)

### TC-018: Error clears when valid quantity entered
**Given:** Error message is displayed after invalid entry  
**When:** User enters valid quantity (e.g., 15)  
**Then:** Error message disappears, quantity updates to 15

### TC-019: Multiple invalid attempts accumulate correctly
**Given:** Item quantity is 10  
**When:** User tries 25, then 30, then enters 12  
**Then:** Each attempt shows error, final valid entry updates to 12

---

## Invalid Input Handling

### TC-020: Non-numeric input is rejected
**Given:** Quantity field is active  
**When:** User types "abc" or "12a"  
**Then:** Non-numeric characters are not accepted or field remains unchanged

### TC-021: Decimal input is rejected or rounded
**Given:** Quantity field is active  
**When:** User enters "5.5"  
**Then:** Either rejected or rounded to nearest whole number (5 or 6)

### TC-022: Negative numbers rejected
**Given:** Quantity field is active  
**When:** User enters "-5"  
**Then:** Negative value is rejected, field remains at previous value

### TC-023: Empty field returns to previous quantity
**Given:** Item has quantity 10, user clears field  
**When:** User triggers blur or presses Enter with empty field  
**Then:** Field reverts to 10

### TC-024: Leading zeros handled correctly
**Given:** Quantity field accepts input  
**When:** User enters "007"  
**Then:** Quantity is set to 7 (leading zeros stripped)

---

## Edge Cases & State Management

### TC-025: Rapid quantity changes process correctly
**Given:** Item is in cart  
**When:** User rapidly clicks +/- button 5 times each in succession  
**Then:** Final quantity reflects total changes accurately

### TC-026: Quantity persists after page refresh
**Given:** User sets quantity to 15  
**When:** Page is refreshed  
**Then:** Quantity remains 15 in cart (assumes cart persistence)

### TC-027: Quantity updates with multiple tabs open
**Given:** Item is in cart in two browser tabs  
**When:** User changes quantity in tab 1 to 5  
**Then:** Tab 2 shows updated quantity (or refresh shows 5)

### TC-028: Quantity change at maximum cart items
**Given:** Cart is full or has max items limit  
**When:** User tries to increase quantity beyond system limit  
**Then:** Appropriate error displays (distinguish from AC-3)

### TC-029: Quantity field focus/blur behavior
**Given:** Quantity field with value 5  
**When:** User focuses field and enters "12" then tabs away  
**Then:** Quantity updates to 12 on blur

### TC-030: Quantity change during checkout flow
**Given:** User is on checkout page with cart visible  
**When:** User changes item quantity  
**Then:** Cart totals update immediately, checkout amount reflects new total

---

## Accessibility & Usability

### TC-031: Quantity field is keyboard accessible
**Given:** Tab focus in cart  
**When:** User tabs to quantity field and enters value via keyboard  
**Then:** Change applies without mouse interaction

### TC-032: Error message is announced to screen readers
**Given:** User enters invalid quantity  
**When:** Error message appears  
**Then:** Screen reader announces error message and associated field

### TC-033: Confirmation dialog has proper focus management
**Given:** Removal confirmation dialog appears  
**When:** Dialog opens  
**Then:** Focus moves to dialog (preferably on primary button)

### TC-034: Quantity field label is clear
**Given:** Quantity input is displayed  
**When:** User views cart  
**Then:** Field is clearly labeled "Quantity" or similar, not ambiguous

---

## Performance & Load

### TC-035: Quantity change is responsive
**Given:** Cart loaded  
**When:** User changes quantity  
**Then:** UI responds within 500ms (no visible lag)

### TC-036: Large cart quantity changes perform
**Given:** Cart contains 50+ items  
**When:** User changes quantity on any item  
**Then:** Update completes and page remains responsive

---

## Related Feature Integration

### TC-037: Discount recalculates with quantity change
**Given:** Cart has bulk discount (e.g., 10% off when qty ≥ 15)  
**When:** User increases quantity to 15  
**Then:** Discount applies and total recalculates

### TC-038: Stock availability checked with quantity change
**Given:** Item has limited stock (e.g., 5 available)  
**When:** User tries to set quantity to 10  
**Then:** Warning shows or quantity caps at available stock (assume implementation detail)

### TC-039: Loyalty points update with quantity change
**Given:** Item awards loyalty points  
**When:** User changes quantity from 2 to 5  
**Then:** Points display updates to reflect new quantity
