# Test Cases for CART-12: Change the Quantity of an Item in the Cart

**Assumptions:**
- The cart is a web-based application with an input field for quantity
- Quantity changes trigger immediate validation
- Previous quantity is persisted in memory/state before attempting a change
- The item has an ID and can be uniquely identified in the cart
- All tests use a cart with at least one item present

---

## AC-1: Valid Quantity Input (1-20)

| Test Case | Precondition | Action | Expected Result | Notes |
|-----------|--------------|--------|-----------------|-------|
| TC-1.1: Lower boundary | Item in cart with quantity 5 | Change quantity to 1 | Quantity updates to 1; item remains in cart | Minimum valid value |
| TC-1.2: Upper boundary | Item in cart with quantity 5 | Change quantity to 20 | Quantity updates to 20; item remains in cart | Maximum valid value |
| TC-1.3: Mid-range value | Item in cart with quantity 5 | Change quantity to 10 | Quantity updates to 10; item remains in cart | Random valid value |
| TC-1.4: Single digit | Item in cart with quantity 5 | Change quantity to 7 | Quantity updates to 7; item remains in cart | Valid single digit |
| TC-1.5: Decimal rejection | Item in cart with quantity 5 | Enter 5.5 | Quantity remains at 5; input rejected or decimal truncated | Non-whole number handling |
| TC-1.6: Negative number rejection | Item in cart with quantity 5 | Enter -3 | Quantity remains at 5; input rejected | Negative values not allowed |
| TC-1.7: Non-numeric input | Item in cart with quantity 5 | Enter "abc" | Quantity remains at 5; input rejected | Invalid character handling |
| TC-1.8: Empty field | Item in cart with quantity 5 | Clear field and move focus away | Quantity reverts to 5 or shows validation error | Empty state handling |

---

## AC-2: Zero Quantity Triggers Removal Confirmation

| Test Case | Precondition | Action | Expected Result | Notes |
|-----------|--------------|--------|-----------------|-------|
| TC-2.1: Zero triggers dialog | Item in cart with quantity 5 | Change quantity to 0 | Confirmation dialog appears with text "Remove this item?" | Dialog must display |
| TC-2.2: Confirm removal | Confirmation dialog is open | Click "Confirm" or "Yes" button | Item is removed from cart; cart updates | Removal is committed |
| TC-2.3: Cancel removal | Confirmation dialog is open | Click "Cancel" or "No" button | Dialog closes; item remains in cart with original quantity (5) | Quantity is restored |
| TC-2.4: Close dialog without action | Confirmation dialog is open | Click outside dialog or press Escape | Dialog closes; item remains in cart with original quantity | Cancellation behavior |
| TC-2.5: Zero on single item | Only one item in cart with quantity 3 | Change quantity to 0 and confirm | Item is removed; cart is empty | Edge case: empty cart |

---

## AC-3: Quantity Above 20 Rejected with Error Message

| Test Case | Precondition | Action | Expected Result | Notes |
|-----------|--------------|--------|-----------------|-------|
| TC-3.1: Just above limit | Item in cart with quantity 10 | Change quantity to 21 | Error message "You can buy at most 20 of this item." displays; quantity stays at 10 | Boundary test above limit |
| TC-3.2: Significantly above limit | Item in cart with quantity 10 | Change quantity to 100 | Error message displays; quantity stays at 10 | Large overage |
| TC-3.3: Very large number | Item in cart with quantity 10 | Enter 9999 | Error message displays; quantity stays at 10 | Extreme value |
| TC-3.4: Quantity 21 persistence | Item in cart with quantity 20 (at max) | Attempt to change to 21 | Error message displays; quantity remains at 20 | Previous max quantity preserved |
| TC-3.5: Error message dismissal | Error message is displayed | Click OK or dismiss | Error message disappears; quantity unchanged | User can clear error |
| TC-3.6: Consecutive invalid attempts | Item in cart with quantity 15 | Change to 25, then 30, then 40 | Each attempt shows error message; quantity stays at 15 after each attempt | Multiple failures don't compound |

---

## Additional Edge Cases

| Test Case | Precondition | Action | Expected Result | Notes |
|-----------|--------------|--------|-----------------|-------|
| TC-4.1: Leading zeros | Item in cart with quantity 5 | Enter "05" | Quantity updates to 5 (leading zeros ignored or accepted) | Input normalization |
| TC-4.2: Rapid quantity changes | Item in cart | Change quantity to 3, then 8, then 15 in quick succession | Final quantity is 15; no race conditions or skipped values | State consistency |
| TC-4.3: Quantity change persists on page refresh | Item quantity changed to 12 | Refresh page | Quantity remains 12 (assuming persistence layer) | Data persistence |
| TC-4.4: Multiple items, change one | Cart with 3 items (qty 5, 10, 3) | Change middle item to 15 | Only middle item updates; others unchanged | Isolation between items |
