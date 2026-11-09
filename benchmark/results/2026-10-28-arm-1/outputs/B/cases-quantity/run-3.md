# Test Cases: CART-12 Change Quantity of Item in Cart

## Assumptions
- Quantity field is an input control that accepts user entry and validation occurs on blur or submit
- The "previous quantity" refers to the quantity value before the user attempted to change it
- Both client-side and server-side validation are in place
- Confirmation dialog for removal (AC-2) appears as a modal or inline confirmation
- Cart persists across page loads and browser sessions
- Non-whole numbers are handled gracefully (rounded, rejected, or show error)

---

## Test Cases

### AC-1: Quantity Field Accepts Whole Numbers 1-20

| Test ID | Title | Precondition | Steps | Expected Result |
|---------|-------|--------------|-------|-----------------|
| CART-12-001 | Accept valid single digit quantity | Item in cart with current quantity 1 | 1. Click quantity field<br>2. Clear field<br>3. Enter "5"<br>4. Trigger field blur/submit | Quantity updates to 5; cart total recalculates |
| CART-12-002 | Accept valid double digit quantity | Item in cart with current quantity 5 | 1. Click quantity field<br>2. Clear field<br>3. Enter "15"<br>4. Trigger field blur/submit | Quantity updates to 15; cart total recalculates |
| CART-12-003 | Accept boundary value 1 | Item in cart with current quantity 10 | 1. Click quantity field<br>2. Clear field<br>3. Enter "1"<br>4. Trigger field blur/submit | Quantity updates to 1; cart total recalculates |
| CART-12-004 | Accept boundary value 20 | Item in cart with current quantity 5 | 1. Click quantity field<br>2. Clear field<br>3. Enter "20"<br>4. Trigger field blur/submit | Quantity updates to 20; cart total recalculates |
| CART-12-005 | Quantity persists after page reload | Quantity successfully changed to 7 | 1. Reload page<br>2. View cart | Quantity displays as 7 |

---

### AC-2: Setting Quantity to 0 Triggers Removal Confirmation

| Test ID | Title | Precondition | Steps | Expected Result |
|---------|-------|--------------|-------|-----------------|
| CART-12-006 | Remove item via zero quantity with confirmation | Item in cart with quantity 5 | 1. Click quantity field<br>2. Clear field<br>3. Enter "0"<br>4. Trigger field blur/submit | Confirmation dialog appears with text "Remove this item?" |
| CART-12-007 | Confirm removal on "Remove this item?" dialog | Confirmation dialog displayed after entering 0 | 1. Click "Confirm" or "Yes" button on dialog | Item is removed from cart; cart updates |
| CART-12-008 | Cancel removal on "Remove this item?" dialog | Confirmation dialog displayed after entering 0 | 1. Click "Cancel" or "No" button on dialog | Item remains in cart with original quantity; dialog closes |
| CART-12-009 | Cancel removal by closing dialog | Confirmation dialog displayed after entering 0 | 1. Click X button or click outside dialog to close | Item remains in cart with original quantity; dialog closes |
| CART-12-010 | Remove item persists after page reload | Item successfully removed via zero quantity | 1. Reload page<br>2. View cart | Item is not in cart |

---

### AC-3: Quantity Above 20 Shows Error and Retains Previous Quantity

| Test ID | Title | Precondition | Steps | Expected Result |
|---------|-------|--------------|-------|-----------------|
| CART-12-011 | Reject quantity 21 | Item in cart with quantity 10 | 1. Click quantity field<br>2. Clear field<br>3. Enter "21"<br>4. Trigger field blur/submit | Error message "You can buy at most 20 of this item." displays; quantity field shows 10 |
| CART-12-012 | Reject quantity 100 | Item in cart with quantity 8 | 1. Click quantity field<br>2. Clear field<br>3. Enter "100"<br>4. Trigger field blur/submit | Error message "You can buy at most 20 of this item." displays; quantity field shows 8 |
| CART-12-013 | Reject quantity 999 | Item in cart with quantity 15 | 1. Click quantity field<br>2. Clear field<br>3. Enter "999"<br>4. Trigger field blur/submit | Error message "You can buy at most 20 of this item." displays; quantity field shows 15 |
| CART-12-014 | Error message clears on valid re-entry | Error message displayed for quantity 25 | 1. Enter valid quantity "12"<br>2. Trigger field blur/submit | Error message disappears; quantity updates to 12 |

---

### Additional Edge Cases & Scenarios

| Test ID | Title | Precondition | Steps | Expected Result |
|---------|-------|--------------|-------|-----------------|
| CART-12-015 | Reject negative number | Item in cart with quantity 5 | 1. Click quantity field<br>2. Clear field<br>3. Enter "-5"<br>4. Trigger field blur/submit | Quantity reverts to 5; error message shown or value rejected |
| CART-12-016 | Reject decimal number | Item in cart with quantity 5 | 1. Click quantity field<br>2. Clear field<br>3. Enter "5.5"<br>4. Trigger field blur/submit | Quantity reverts to 5; error message shown or value rounded/rejected |
| CART-12-017 | Reject non-numeric input | Item in cart with quantity 5 | 1. Click quantity field<br>2. Clear field<br>3. Enter "abc"<br>4. Trigger field blur/submit | Quantity reverts to 5; error message shown or value rejected |
| CART-12-018 | Reject empty field submission | Item in cart with quantity 5 | 1. Click quantity field<br>2. Clear field completely<br>3. Trigger field blur/submit | Quantity reverts to 5; error message shown or field refills with previous value |
| CART-12-019 | Update multiple items independently | Cart with 2 items (Item A qty 5, Item B qty 3) | 1. Change Item A quantity to 12<br>2. Change Item B quantity to 8<br>3. Verify cart | Item A shows 12; Item B shows 8; cart total correct |
| CART-12-020 | Stock availability verification | Item with max stock of 15 | 1. Change quantity to 20<br>2. Observe result | Error message and quantity retained (assumes business rule: quantity limit applies regardless of stock) OR item updates if no stock constraint |
| CART-12-021 | Price recalculation on quantity change | Item priced at $10, quantity 5 (total $50) | 1. Change quantity to 10 | Item subtotal updates to $100; cart total recalculates |
| CART-12-022 | Rapid sequential quantity changes | Item in cart | 1. Change quantity to 5<br>2. Immediately change to 15<br>3. Immediately change to 8 | Final quantity is 8; no race condition; cart total reflects correct quantity |
