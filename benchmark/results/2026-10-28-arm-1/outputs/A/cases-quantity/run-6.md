# Test Cases for CART-12: Change Quantity of Item in Cart

## Assumptions
- Tests assume a web-based shopping cart with quantity input fields
- Validation occurs on field blur or explicit submit
- "Previous quantity" means the quantity value before the user attempted the invalid change
- Negative numbers and decimal values are considered invalid input
- The cart item is stored in the system and persists after valid quantity changes
- A confirmation dialog appears as a modal when attempting to set quantity to 0

---

## Test Cases

### AC-1: Quantity Field Accepts Whole Numbers 1-20

| Test ID | Scenario | Steps | Expected Result |
|---------|----------|-------|-----------------|
| T1.1 | Enter valid quantity at lower bound | Add item to cart, set quantity to 1 | Quantity updates to 1, item remains in cart |
| T1.2 | Enter valid quantity at upper bound | Add item to cart, set quantity to 20 | Quantity updates to 20, item remains in cart |
| T1.3 | Enter valid quantity in middle range | Add item to cart, set quantity to 10 | Quantity updates to 10, item remains in cart |
| T1.4 | Update quantity from valid to valid | Item in cart with quantity 5, change to 15 | Quantity updates to 15 |
| T1.5 | Enter decimal number (e.g., 5.5) | Add item to cart, set quantity to 5.5 | Input rejected or rounded; error displayed or previous quantity retained |
| T1.6 | Enter negative number (e.g., -5) | Add item to cart, set quantity to -5 | Input rejected; error message displayed; previous quantity retained |
| T1.7 | Enter non-numeric characters (e.g., "abc") | Add item to cart, set quantity to "abc" | Input rejected; previous quantity retained |
| T1.8 | Leave field empty | Add item to cart, clear quantity field | Field treated as invalid; previous quantity retained or default value applied |
| T1.9 | Enter leading zeros (e.g., "005") | Add item to cart, set quantity to 005 | Accepted as valid number 5, quantity updates to 5 |

---

### AC-2: Setting Quantity to 0 Shows Confirmation Dialog

| Test ID | Scenario | Steps | Expected Result |
|---------|----------|-------|-----------------|
| T2.1 | Set quantity to 0 and confirm removal | Add item to cart, set quantity to 0, click "Yes" in confirmation dialog | "Remove this item?" dialog appears; item is removed from cart after confirmation |
| T2.2 | Set quantity to 0 and cancel removal | Add item to cart, set quantity to 0, click "No" or cancel in confirmation dialog | "Remove this item?" dialog appears; dialog closes; quantity reverts to previous value; item remains in cart |
| T2.3 | Set quantity to 0 with close dialog button | Add item to cart, set quantity to 0, click X or close button on confirmation dialog | Dialog closes; quantity reverts to previous value; item remains in cart |
| T2.4 | Set quantity to 0 for item with quantity 1 | Item in cart with quantity 1, set quantity to 0 | Dialog asks "Remove this item?"; confirm removal removes the item |
| T2.5 | Set quantity to 0 for item with quantity 20 | Item in cart with quantity 20, set quantity to 0 | Dialog asks "Remove this item?"; confirm removal removes the item |
| T2.6 | User closes browser during confirmation | Add item to cart, set quantity to 0, don't respond to dialog, close browser | Dialog persists when browser reopened (if session maintained) or cart state reflects pre-dialog state |

---

### AC-3: Quantity Above 20 Shows Error and Retains Previous Quantity

| Test ID | Scenario | Steps | Expected Result |
|---------|----------|-------|-----------------|
| T3.1 | Enter quantity 21 | Add item to cart, set quantity to 21 | Error message "You can buy at most 20 of this item." displayed; quantity field reverts to previous value |
| T3.2 | Enter quantity 100 | Add item to cart, set quantity to 100 | Error message "You can buy at most 20 of this item." displayed; quantity field reverts to previous value |
| T3.3 | Update from valid to over limit | Item with quantity 5, attempt to set to 25 | Error message displayed; quantity remains at 5 |
| T3.4 | Enter quantity 21 for new item | Add item to cart, set quantity to 21 on first change | Error message displayed; quantity reverts to initial/default value |
| T3.5 | Error persists and can be dismissed | Item with invalid attempt (quantity 21), user clicks elsewhere or clears error | Error message disappears; quantity field shows previous valid value |
| T3.6 | Retry after error with valid quantity | Item with quantity 5, attempt 25 (error shown), then set to 15 | First attempt shows error and retains 5; second attempt succeeds and updates to 15 |

---

### Integration & Edge Cases

| Test ID | Scenario | Steps | Expected Result |
|---------|----------|-------|-----------------|
| T4.1 | Multiple items in cart, change one | Cart with 2+ items, change quantity of one | Only target item quantity changes; other items unaffected |
| T4.2 | Rapid quantity changes | Add item, quickly change quantity 3+ times between valid values | Final quantity reflects last valid input; no race conditions or lost updates |
| T4.3 | Change quantity, then close browser, reopen | Set item quantity to 15, close and reopen browser/refresh page | Cart persists with quantity 15 (assuming session/persistence enabled) |
| T4.4 | Quantity field accepts paste input | Add item, paste "12" into quantity field | Quantity updates to 12 if valid |
| T4.5 | Tab navigation through quantity field | Add item, tab to quantity field, enter value, tab out | Validation triggers on blur; error or success state updates |
| T4.6 | Touch input on mobile | Add item on mobile device, tap quantity field, enter value | Same validation behavior as desktop; responsiveness maintained |
