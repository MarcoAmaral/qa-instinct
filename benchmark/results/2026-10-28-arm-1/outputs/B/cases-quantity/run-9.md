# Test Cases for CART-12: Change the Quantity of an Item in the Cart

**Assumptions:**
- Quantity is entered through a numeric input field in the cart UI
- Quantity validation occurs on input change or field blur
- The system maintains the cart state across interactions
- A shopper must have at least one item in their cart to test this feature
- "Quantity" refers to the number of identical items

---

## Acceptance Criteria Coverage

### AC-1: Quantity Field Accepts Whole Numbers 1-20

| Test ID | Test Case | Steps | Expected Result | Priority |
|---------|-----------|-------|-----------------|----------|
| CART-12-001 | Enter minimum valid quantity (1) | 1. Open cart with item 2. Enter "1" in quantity field 3. Trigger field blur/confirm | Quantity updates to 1, cart total recalculates | P0 |
| CART-12-002 | Enter maximum valid quantity (20) | 1. Open cart with item 2. Enter "20" in quantity field 3. Trigger field blur/confirm | Quantity updates to 20, cart total recalculates | P0 |
| CART-12-003 | Enter mid-range valid quantity (5) | 1. Open cart with item 2. Enter "5" in quantity field 3. Trigger field blur/confirm | Quantity updates to 5, cart total recalculates | P1 |
| CART-12-004 | Enter mid-range valid quantity (15) | 1. Open cart with item 2. Enter "15" in quantity field 3. Trigger field blur/confirm | Quantity updates to 15, cart total recalculates | P1 |
| CART-12-005 | Quantity field rejects decimal numbers | 1. Open cart with item 2. Attempt to enter "5.5" in quantity field | Field rejects decimal or rounds to whole number (5 or 6) | P0 |
| CART-12-006 | Quantity field rejects negative numbers | 1. Open cart with item 2. Attempt to enter "-5" in quantity field | Field rejects negative value or treats as 0 | P0 |
| CART-12-007 | Update quantity from existing value to different valid value | 1. Open cart with item quantity of 3 2. Change quantity field to "10" 3. Confirm update | Quantity updates to 10, cart total recalculates | P1 |

### AC-2: Setting Quantity to 0 Triggers Removal Confirmation

| Test ID | Test Case | Steps | Expected Result | Priority |
|---------|-----------|-------|-----------------|----------|
| CART-12-008 | Set quantity to 0 displays confirmation dialog | 1. Open cart with item 2. Enter "0" in quantity field 3. Trigger field blur/confirm | Confirmation modal appears with message "Remove this item?" | P0 |
| CART-12-009 | Confirm item removal | 1. Open cart with item quantity X 2. Set quantity to 0 3. Confirmation dialog appears 4. Click "Confirm" or "Yes" button | Item is removed from cart, cart total updates, item no longer visible in cart | P0 |
| CART-12-010 | Cancel item removal | 1. Open cart with item quantity X 2. Set quantity to 0 3. Confirmation dialog appears 4. Click "Cancel" or "No" button | Dialog closes, quantity reverts to previous value X, item remains in cart | P0 |
| CART-12-011 | Close confirmation dialog without selecting option | 1. Open cart with item quantity X 2. Set quantity to 0 3. Confirmation dialog appears 4. Click outside dialog or press Escape | Dialog closes, quantity reverts to previous value X, item remains in cart | P1 |
| CART-12-012 | Attempt to set multiple items to 0 sequentially | 1. Open cart with 2+ items 2. Set first item quantity to 0, confirm removal 3. Set second item quantity to 0, confirm removal | Each confirmation dialog appears separately, each item is removed upon confirmation | P1 |

### AC-3: Quantity Above 20 Shows Error and Retains Previous Quantity

| Test ID | Test Case | Steps | Expected Result | Priority |
|---------|-----------|-------|-----------------|----------|
| CART-12-013 | Enter quantity 21 (one above maximum) | 1. Open cart with item (previous quantity: 1) 2. Enter "21" in quantity field 3. Trigger field blur/confirm | Error message "You can buy at most 20 of this item." appears, quantity reverts to 1 | P0 |
| CART-12-014 | Enter quantity 100 (well above maximum) | 1. Open cart with item (previous quantity: 5) 2. Enter "100" in quantity field 3. Trigger field blur/confirm | Error message "You can buy at most 20 of this item." appears, quantity reverts to 5 | P0 |
| CART-12-015 | Enter quantity 50 (above maximum) | 1. Open cart with item (previous quantity: 10) 2. Enter "50" in quantity field 3. Trigger field blur/confirm | Error message "You can buy at most 20 of this item." appears, quantity reverts to 10 | P1 |
| CART-12-016 | Quantity field retains value when error shown | 1. Open cart with item (quantity: 3) 2. Enter "30" 3. Error message appears 4. Close error message | Quantity field shows "3" (original value), error is dismissed | P1 |
| CART-12-017 | Error message styling and visibility | 1. Open cart with item 2. Enter "25" in quantity field 3. Error message appears | Error message is clearly visible, properly formatted (red/warning color), readable text | P1 |

---

## Edge Cases & Additional Coverage

| Test ID | Test Case | Steps | Expected Result | Priority |
|---------|-----------|-------|-----------------|----------|
| CART-12-018 | Clear field and leave empty | 1. Open cart with item 2. Clear quantity field completely 3. Trigger field blur | Field either: (a) shows error, (b) reverts to previous value, or (c) defaults to 1 | P1 |
| CART-12-019 | Rapidly change quantity multiple times | 1. Open cart with item 2. Change quantity to 5, then 10, then 3 in quick succession | Each change processes correctly, final cart state shows quantity of 3 | P2 |
| CART-12-020 | Cart updates persist on page refresh | 1. Open cart, change item quantity to 15 2. Refresh page | Quantity remains 15 in cart after refresh | P0 |
| CART-12-021 | Quantity field accepts leading zeros | 1. Open cart with item 2. Enter "05" in quantity field 3. Trigger field blur/confirm | Field interprets as 5, quantity updates to 5 | P2 |
| CART-12-022 | Cart total recalculates correctly | 1. Open cart with item (price $10, quantity 2, subtotal $20) 2. Change quantity to 5 | Cart total updates to $50 (or applies relevant tax/shipping) | P0 |
| CART-12-023 | Quantity change for item with multiple variants | 1. Open cart with same product in different sizes/colors 2. Change quantity of one variant | Only the selected variant's quantity changes, other variants remain unchanged | P1 |
| CART-12-024 | Validation with special characters | 1. Open cart with item 2. Attempt to enter "5#" or "5@" in quantity field | Field rejects special characters or displays validation error | P2 |
| CART-12-025 | Accessibility: Quantity field has proper label | 1. Open cart 2. Inspect quantity input element for accessibility | Input has associated label or aria-label, keyboard navigation works | P1 |
