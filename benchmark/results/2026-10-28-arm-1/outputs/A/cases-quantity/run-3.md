# Test Cases for CART-12: Change the Quantity of an Item in the Cart

**Assumptions:**
- Quantity field is an input control (numeric field or spinner)
- "Previous quantity" refers to the last valid quantity before an invalid attempt
- Confirmation dialog has explicit Accept/Cancel or Yes/No actions
- Quantity changes persist in the cart until the user leaves the page or clears the cart
- Decimal values are rejected (only whole numbers accepted)

## AC-1: The quantity field accepts whole numbers from 1 to 20

| Test ID | Description | Steps | Expected Result | Priority |
|---------|-------------|-------|-----------------|----------|
| AC1-001 | Accept quantity of 1 | Enter "1" in quantity field and confirm | Quantity updates to 1, item remains in cart | High |
| AC1-002 | Accept quantity of 20 | Enter "20" in quantity field and confirm | Quantity updates to 20, item remains in cart | High |
| AC1-003 | Accept mid-range quantity | Enter "10" in quantity field and confirm | Quantity updates to 10, item remains in cart | High |
| AC1-004 | Accept quantity 2 | Enter "2" in quantity field and confirm | Quantity updates to 2, item remains in cart | Medium |
| AC1-005 | Accept quantity 15 | Enter "15" in quantity field and confirm | Quantity updates to 15, item remains in cart | Medium |
| AC1-006 | Reject decimal values | Enter "2.5" in quantity field | Quantity field rejects input or rounds to whole number | Medium |
| AC1-007 | Reject negative numbers | Enter "-5" in quantity field | Quantity field rejects input or shows error | Medium |
| AC1-008 | Reject non-numeric input | Enter "abc" in quantity field | Quantity field rejects input | Low |
| AC1-009 | Reject special characters | Enter "@#$" in quantity field | Quantity field rejects input | Low |
| AC1-010 | Update quantity multiple times | Change quantity from 5 to 10, then to 3 | Each update reflects correctly in the cart | Medium |

## AC-2: Setting the quantity to 0 asks "Remove this item?" and removes the item only when confirmed

| Test ID | Description | Steps | Expected Result | Priority |
|---------|-------------|-------|-----------------|----------|
| AC2-001 | Zero quantity shows confirmation | Enter "0" in quantity field | Confirmation dialog appears with message "Remove this item?" | High |
| AC2-002 | Confirm removal | Enter "0", click "Yes" or "Confirm" on dialog | Item is removed from cart, cart updates | High |
| AC2-003 | Cancel removal | Enter "0", click "No" or "Cancel" on dialog | Item remains in cart with previous quantity restored | High |
| AC2-004 | Confirmation dialog dismissal | Enter "0", press Escape key on dialog | Item remains in cart with previous quantity restored | Medium |
| AC2-005 | Confirmation dialog close button | Enter "0", click X button on dialog | Item remains in cart with previous quantity restored | Medium |
| AC2-006 | Quantity field after cancel | Enter "0", cancel removal, check field | Quantity field shows the previous quantity value | Medium |
| AC2-007 | Remove last item | Remove last item from cart via quantity 0 | Cart is empty, cart summary shows "0 items" | Medium |
| AC2-008 | Rapid zero entries | Attempt to set quantity to 0 multiple times in succession | Only one confirmation dialog appears per attempt | Low |

## AC-3: A quantity above 20 shows error message and keeps the previous quantity

| Test ID | Description | Steps | Expected Result | Priority |
|---------|-------------|-------|-----------------|----------|
| AC3-001 | Reject quantity 21 | Enter "21" in quantity field | Error message displays "You can buy at most 20 of this item." | High |
| AC3-002 | Previous quantity persists (21) | Attempt 21, check field after error | Quantity field displays previous valid quantity | High |
| AC3-003 | Reject quantity 100 | Enter "100" in quantity field | Error message displays "You can buy at most 20 of this item." | Medium |
| AC3-004 | Previous quantity persists (100) | Attempt 100, check field after error | Quantity field displays previous valid quantity | Medium |
| AC3-005 | Reject very large number | Enter "999999" in quantity field | Error message displays, previous quantity retained | Low |
| AC3-006 | Error message placement | Trigger the 20+ error | Error message is visible and clearly associated with the quantity field | Medium |
| AC3-007 | Error message dismissal | Trigger error, attempt to dismiss | User can proceed or clear error and edit field | Low |
| AC3-008 | Boundary: exactly 20 succeeds | Enter "20" in quantity field | Quantity updates to 20 (no error) | High |
| AC3-009 | From 20 to 21 | Quantity is 20, attempt to change to 21 | Error appears, quantity remains 20 | High |
| AC3-010 | Invalid input after max error | Quantity shows error, user enters valid quantity | New valid quantity is accepted | Medium |

## Cross-Functional / Integration Tests

| Test ID | Description | Steps | Expected Result | Priority |
|---------|-------------|-------|-----------------|----------|
| CF-001 | Cart total updates with quantity change | Change item quantity from 2 to 5 | Cart subtotal, tax, and total recalculate correctly | High |
| CF-002 | Quantity persists on page refresh | Set quantity to 5, refresh page | Quantity remains 5 after refresh | High |
| CF-003 | Multiple items, independent quantities | Add 2 items, change each to different quantities | Each item's quantity is independent and correct | Medium |
| CF-004 | Quantity field focus/blur | Click quantity field, enter value, click elsewhere | Change is committed on blur or explicit confirm | Medium |
| CF-005 | Accessibility: Keyboard only | Navigate to quantity field using Tab, modify using arrow keys or typing | All AC criteria work via keyboard alone | Medium |
| CF-006 | Mobile: Touch input | On mobile device, tap quantity field and enter value | Behavior matches AC requirements (no special mobile exceptions) | Medium |
