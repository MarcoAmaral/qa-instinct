# Test Cases for CART-12: Change the Quantity of an Item in the Cart

## AC-1: The quantity field accepts whole numbers from 1 to 20

| Test ID | Test Case | Precondition | Steps | Expected Result |
|---------|-----------|--------------|-------|-----------------|
| AC1-001 | Accept quantity of 1 | Item in cart with quantity > 1 | Enter "1" in quantity field and confirm | Quantity updates to 1, cart total recalculates |
| AC1-002 | Accept quantity of 20 | Item in cart with quantity < 20 | Enter "20" in quantity field and confirm | Quantity updates to 20, cart total recalculates |
| AC1-003 | Accept quantity of 10 (middle value) | Item in cart | Enter "10" in quantity field and confirm | Quantity updates to 10, cart total recalculates |
| AC1-004 | Reject quantity of 0 | Item in cart | Enter "0" in quantity field | Removal confirmation dialog appears (per AC-2) |
| AC1-005 | Reject quantity of 21 | Item in cart | Enter "21" in quantity field and confirm | Error message displays (per AC-3), quantity unchanged |
| AC1-006 | Reject negative numbers | Item in cart | Enter "-5" in quantity field and confirm | Quantity field rejects input or shows error, quantity unchanged |
| AC1-007 | Reject decimal numbers | Item in cart | Enter "5.5" in quantity field and confirm | Quantity field rejects input or shows error, quantity unchanged |
| AC1-008 | Reject non-numeric characters | Item in cart | Enter "abc" in quantity field and confirm | Quantity field rejects input or shows error, quantity unchanged |
| AC1-009 | Reject empty field | Item in cart with quantity 5 | Clear quantity field without entering a value and confirm | System retains previous quantity (5) or shows validation error |
| AC1-010 | Accept leading zeros (1 vs 01) | Item in cart | Enter "01" in quantity field and confirm | System interprets as 1 and updates quantity |

## AC-2: Setting the quantity to 0 asks "Remove this item?" and removes the item only when the shopper confirms

| Test ID | Test Case | Precondition | Steps | Expected Result |
|---------|-----------|--------------|-------|-----------------|
| AC2-001 | Confirmation dialog appears on zero entry | Item in cart with quantity 3 | Enter "0" in quantity field | Confirmation dialog appears with text "Remove this item?" |
| AC2-002 | Item removed when user confirms | Confirmation dialog displayed | Click "Confirm" or "Yes" button | Item is removed from cart, cart updates immediately |
| AC2-003 | Item retained when user cancels | Confirmation dialog displayed | Click "Cancel" or "No" button | Dialog closes, item remains in cart with previous quantity |
| AC2-004 | Item retained when user dismisses dialog | Confirmation dialog displayed | Close dialog via X button or outside click | Item remains in cart with previous quantity |
| AC2-005 | Correct quantity shown after cancel | Item originally had quantity 7 | Set to 0, dialog appears, then cancel | Item still displays quantity 7 in cart |
| AC2-006 | Cart total recalculates after removal | Item in cart with quantity 5 at $10 each ($50 subtotal) | Set quantity to 0 and confirm removal | Item removed and cart subtotal decreases by $50 |

## AC-3: A quantity above 20 shows "You can buy at most 20 of this item." and keeps the previous quantity

| Test ID | Test Case | Precondition | Steps | Expected Result |
|---------|-----------|--------------|-------|-----------------|
| AC3-001 | Error message for quantity 21 | Item in cart with quantity 15 | Enter "21" in quantity field and confirm | Error message displays: "You can buy at most 20 of this item.", quantity remains 15 |
| AC3-002 | Error message for quantity 100 | Item in cart with quantity 10 | Enter "100" in quantity field and confirm | Error message displays: "You can buy at most 20 of this item.", quantity remains 10 |
| AC3-003 | Error message for large number | Item in cart with quantity 5 | Enter "9999" in quantity field and confirm | Error message displays: "You can buy at most 20 of this item.", quantity remains 5 |
| AC3-004 | Quantity preserved at boundary | Item in cart with quantity 20 | Attempt to change to 21 and confirm | Error message displays, quantity remains 20 |
| AC3-005 | Error message dismissible | Error message is displayed | Close error message via X button or timeout | Error message disappears, quantity field retains previous quantity |
| AC3-006 | User can retry after error | Error message displayed for invalid quantity | Clear field and enter valid quantity (e.g., 12) | Error clears, quantity updates to 12 |

## Assumptions

1. **User Interface**: A text input field for quantity with increment/decrement buttons or direct text entry
2. **Validation Timing**: Validation occurs on blur or when user confirms/submits the quantity change
3. **Error Messages**: Error messages appear as inline notifications, toasts, or modal dialogs
4. **Previous Quantity Definition**: "Previous quantity" refers to the quantity before the failed update attempt
5. **Cart State**: Cart persists across browser sessions or is managed by backend persistence
6. **Item Identification**: Each item in the cart is uniquely identifiable for update operations
7. **No Multi-Select**: Tests assume single item quantity updates, not bulk operations
8. **Accessibility**: Error messages and dialogs are announced to screen readers (ARIA-compliant)
9. **Network Behavior**: Tests assume successful backend updates; network failures are out of scope
10. **Concurrent Updates**: Tests assume single-user behavior; concurrent cart modifications from multiple sessions are out of scope
