# Test Cases: Change Quantity of Cart Item (CART-12)

## AC-1: Valid Quantity Range (1-20)

| Test ID | Description | Steps | Expected Result |
|---------|-------------|-------|-----------------|
| CART-12-TC-01 | Change quantity to minimum valid value | 1. View cart with an item. 2. Enter quantity `1` in the quantity field. 3. Confirm/apply change. | Item quantity updates to 1. |
| CART-12-TC-02 | Change quantity to maximum valid value | 1. View cart with an item. 2. Enter quantity `20` in the quantity field. 3. Confirm/apply change. | Item quantity updates to 20. |
| CART-12-TC-03 | Change quantity within valid range | 1. View cart with an item at quantity 5. 2. Enter quantity `15` in the quantity field. 3. Confirm/apply change. | Item quantity updates to 15. |
| CART-12-TC-04 | Quantity field rejects decimal values | 1. View cart with an item. 2. Attempt to enter quantity `5.5` in the quantity field. | Quantity field does not accept the decimal or rounds to nearest whole number (assumption: no decimals allowed). |
| CART-12-TC-05 | Quantity field rejects negative values | 1. View cart with an item. 2. Attempt to enter quantity `-3` in the quantity field. | Quantity field does not accept negative input or field clears. |
| CART-12-TC-06 | Quantity field rejects non-numeric input | 1. View cart with an item. 2. Attempt to enter quantity `abc` in the quantity field. | Quantity field does not accept non-numeric input or displays validation error. |

## AC-2: Remove Item via Zero Quantity

| Test ID | Description | Steps | Expected Result |
|---------|-------------|-------|-----------------|
| CART-12-TC-07 | Zero quantity triggers removal confirmation | 1. View cart with an item at quantity 5. 2. Enter quantity `0` in the quantity field. | Confirmation dialog appears with message "Remove this item?" |
| CART-12-TC-08 | Confirm removal from dialog | 1. Complete TC-07. 2. Select **Confirm** button in the dialog. | Item is removed from cart. Cart updates and reflects new total. |
| CART-12-TC-09 | Cancel removal from dialog | 1. Complete TC-07. 2. Select **Cancel** button in the dialog. | Item remains in cart at previous quantity. Confirmation dialog closes. |
| CART-12-TC-10 | Close confirmation dialog without action | 1. Complete TC-07. 2. Close the dialog (X button or press Escape). | Item remains in cart at previous quantity. Confirmation dialog closes. |

## AC-3: Quantity Above 20

| Test ID | Description | Steps | Expected Result |
|---------|-------------|-------|-----------------|
| CART-12-TC-11 | Quantity 21 shows error message | 1. View cart with an item at quantity 5. 2. Enter quantity `21` in the quantity field. | Error message displays: "You can buy at most 20 of this item." Item quantity remains 5. |
| CART-12-TC-12 | Quantity 100 shows error message | 1. View cart with an item at quantity 10. 2. Enter quantity `100` in the quantity field. | Error message displays: "You can buy at most 20 of this item." Item quantity remains 10. |
| CART-12-TC-13 | Previous quantity preserved after error | 1. View cart with an item at quantity 12. 2. Enter quantity `25`. 3. Error message appears. 4. Clear the quantity field and close the error message. | Quantity field displays 12 again. Item is not modified. |
| CART-12-TC-14 | Error message clears when valid quantity entered | 1. Complete TC-11. 2. Clear the quantity field and enter `18`. | Error message disappears. Item quantity updates to 18. |

## Edge Cases & Additional Scenarios

| Test ID | Description | Steps | Expected Result |
|---------|-------------|-------|-----------------|
| CART-12-TC-15 | Multiple quantity changes in sequence | 1. View cart with an item. 2. Change quantity to 5. 3. Change quantity to 15. 4. Change quantity to 3. | Each change applies successfully; final quantity is 3. |
| CART-12-TC-16 | Quantity persists across page navigation | 1. Change an item's quantity to 12. 2. Navigate away and return to cart. | Item quantity remains 12. |
| CART-12-TC-17 | Cart total updates correctly with quantity change | 1. View cart with item priced at $10, quantity 2 (subtotal $20). 2. Change quantity to 5. | Subtotal updates to $50. Cart total recalculates. |

## Assumptions

- Quantity field is a numeric input that validates in real-time or on blur/submit.
- "Apply" or "confirm" is automatic (field blur) or via an explicit button (assumption: automatic on blur or enter key).
- Previous quantity is retained in memory or session until explicitly changed or item is removed.
- Error messages are displayed inline near the quantity field or in a toast/alert.
- The cart must contain at least one item to test quantity changes.
- Browser/client-side validation occurs before any server submission.
