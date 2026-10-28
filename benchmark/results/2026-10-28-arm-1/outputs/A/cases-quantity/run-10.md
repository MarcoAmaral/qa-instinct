# Test Cases for CART-12: Change the Quantity of an Item in the Cart

## Assumptions
- The quantity field is an input field that accepts text entry and/or increment/decrement buttons
- "Previous quantity" refers to the quantity before the invalid input was attempted
- The cart persists across browser sessions unless explicitly cleared
- Only one item type is in the cart during most tests
- The shopper is logged in and has a cart with at least one item
- Quantity changes take effect immediately without requiring a save button

---

## Test Cases

### AC-1: Valid Quantity Range (1-20)

| Test ID | Title | Preconditions | Steps | Expected Result | Priority |
|---------|-------|---------------|-------|-----------------|----------|
| TC-001 | Set quantity to minimum (1) | Item in cart with quantity > 1 | Clear quantity field, enter "1", confirm input | Quantity updates to 1, cart total recalculates | High |
| TC-002 | Set quantity to maximum (20) | Item in cart with quantity < 20 | Clear quantity field, enter "20", confirm input | Quantity updates to 20, cart total recalculates | High |
| TC-003 | Increment quantity within range | Item in cart with quantity 5 | Click increment button or enter "6" | Quantity updates to 6 | High |
| TC-004 | Decrement quantity within range | Item in cart with quantity 10 | Click decrement button or enter "9" | Quantity updates to 9 | High |
| TC-005 | Set quantity to midrange value (10) | Item in cart | Enter "10" | Quantity updates to 10 | Medium |
| TC-006 | Verify decimal input is rejected | Item in cart | Enter "5.5" | Quantity field rejects input or converts to whole number (5 or 6), shows error message | Medium |
| TC-007 | Verify negative number rejected | Item in cart | Enter "-5" | Quantity field rejects input, shows error message | Medium |
| TC-008 | Verify leading zeros handled | Item in cart | Enter "05" | Quantity updates to 5 | Low |

---

### AC-2: Quantity Zero Triggers Confirmation Dialog

| Test ID | Title | Preconditions | Steps | Expected Result | Priority |
|---------|-------|---------------|-------|-----------------|----------|
| TC-009 | Set quantity to 0 shows confirmation | Item in cart with quantity > 0 | Enter "0" in quantity field | Confirmation dialog appears with message "Remove this item?" | High |
| TC-010 | Confirm removal deletes item | Confirmation dialog shown for quantity 0 | Click "Yes" or "Confirm" button | Item removed from cart, cart updates | High |
| TC-011 | Cancel removal keeps item | Confirmation dialog shown for quantity 0 | Click "No" or "Cancel" button | Dialog closes, item remains in cart with previous quantity | High |
| TC-012 | Dismissing dialog keeps item | Confirmation dialog shown for quantity 0 | Press Escape key or click outside dialog | Dialog closes, item remains in cart with previous quantity | Medium |
| TC-013 | Multiple items, remove one | Two items in cart | Set quantity of first item to 0, confirm removal | Only first item removed, second item remains | Medium |
| TC-014 | Item removal updates cart total | Item worth $10 with quantity 2 in cart with total $50 | Set quantity to 0, confirm removal | Cart total updates to $30 | High |

---

### AC-3: Quantity Above 20 Shows Error

| Test ID | Title | Preconditions | Steps | Expected Result | Priority |
|---------|-------|---------------|-------|-----------------|----------|
| TC-015 | Set quantity to 21 shows error | Item in cart with quantity 10 | Enter "21" | Error message "You can buy at most 20 of this item." appears, quantity remains 10 | High |
| TC-016 | Set quantity to 100 shows error | Item in cart with quantity 5 | Enter "100" | Error message "You can buy at most 20 of this item." appears, quantity remains 5 | High |
| TC-017 | Increment past 20 shows error | Item in cart with quantity 20 | Click increment button or enter "21" | Error message shown, quantity remains 20 | High |
| TC-018 | Very large number rejected | Item in cart with quantity 1 | Enter "999999" | Error message "You can buy at most 20 of this item." appears, quantity remains 1 | Medium |
| TC-019 | Error message is dismissible | Error message displayed | Click "OK" or dismiss error | Error message closes, quantity field still shows previous quantity | Medium |

---

## Additional Edge Cases

| Test ID | Title | Preconditions | Steps | Expected Result | Priority |
|---------|-------|---------------|-------|-----------------|----------|
| TC-020 | Quantity field is empty | Item in cart | Clear quantity field, leave empty, tab away | Field shows previous quantity or shows validation error | Medium |
| TC-021 | Special characters in field | Item in cart | Enter "@#$%" in quantity field | Input rejected or sanitized, field shows previous quantity | Medium |
| TC-022 | Whitespace handling | Item in cart | Enter " 5 " (with spaces) | Whitespace trimmed, quantity updates to 5 | Low |
| TC-023 | Rapid quantity changes | Item in cart | Quickly change quantity from 5 to 15 to 8 | All changes process correctly, final quantity is 8 | Medium |
| TC-024 | Change quantity with low stock | Item with only 15 units available | Attempt to set quantity to 20 | Either error message shown or quantity caps at 15 (implementation-dependent) | Medium |
| TC-025 | Verify cart persistence | Change item quantity to 15 | Refresh page or navigate away and return | Quantity persists as 15 | High |
| TC-026 | Quantity change reflects in order summary | Set quantity to 20 | Verify item price × 20 in order total | Order total updates correctly | High |

---

## Regression Tests

| Test ID | Title | Expected Result | Priority |
|---------|-------|-----------------|----------|
| TC-027 | Other cart items unaffected | When changing quantity of one item, other items remain unchanged | High |
| TC-028 | Checkout process works after quantity change | User can proceed to checkout after modifying quantity | High |
| TC-029 | Coupon/discount applies correctly | Discounts recalculate based on new quantity | Medium |
