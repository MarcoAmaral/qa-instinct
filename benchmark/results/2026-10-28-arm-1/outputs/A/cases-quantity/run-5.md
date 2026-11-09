# Test Cases for CART-12: Change the Quantity of an Item in the Cart

## AC-1: The quantity field accepts whole numbers from 1 to 20

| Test ID | Test Case | Given | When | Then |
|---------|-----------|-------|------|------|
| TC-1.1 | User enters valid minimum quantity | An item exists in the cart | User changes quantity to 1 | The quantity is updated to 1 and item remains in cart |
| TC-1.2 | User enters valid maximum quantity | An item exists in the cart | User changes quantity to 20 | The quantity is updated to 20 and item remains in cart |
| TC-1.3 | User enters valid middle-range quantity | An item exists in the cart with quantity 5 | User changes quantity to 10 | The quantity is updated to 10 and item remains in cart |
| TC-1.4 | User enters valid quantity with leading zeros | An item exists in the cart | User enters "05" in quantity field | The quantity is set to 5 (leading zeros ignored) |
| TC-1.5 | User enters decimal number | An item exists in the cart | User enters "5.5" in quantity field | Input is rejected or rounded down to 5 and user is notified |
| TC-1.6 | User enters negative number | An item exists in the cart | User enters "-5" in quantity field | Input is rejected and user is notified quantity must be positive |
| TC-1.7 | User enters non-numeric characters | An item exists in the cart with quantity 3 | User enters "abc" in quantity field | Input is rejected and previous quantity (3) is retained |
| TC-1.8 | User enters empty string | An item exists in the cart with quantity 5 | User clears the quantity field and submits | Input is rejected and previous quantity is retained |
| TC-1.9 | User enters space characters only | An item exists in the cart | User enters "   " (spaces only) | Input is rejected and previous quantity is retained |
| TC-1.10 | User changes quantity multiple times sequentially | An item exists in the cart | User changes quantity 3 → 7 → 15 → 2 | Each change updates successfully and cart reflects current quantity |

## AC-2: Setting the quantity to 0 asks "Remove this item?" and removes the item only when the shopper confirms

| Test ID | Test Case | Given | When | Then |
|---------|-----------|-------|------|------|
| TC-2.1 | User sets quantity to 0 and confirms removal | An item exists in the cart with quantity 5 | User changes quantity to 0 and clicks "Yes" on confirmation dialog | Item is removed from cart, confirmation dialog closes |
| TC-2.2 | User sets quantity to 0 and cancels removal | An item exists in the cart with quantity 5 | User changes quantity to 0 and clicks "No" on confirmation dialog | Item remains in cart with original quantity (5), confirmation dialog closes |
| TC-2.3 | User sets quantity to 0 and clicks outside confirmation dialog | An item exists in the cart with quantity 5 | User changes quantity to 0, confirmation dialog appears, user clicks outside dialog | Item remains in cart with original quantity (5), dialog closes |
| TC-2.4 | User sets quantity to 0 and presses Escape key | An item exists in the cart with quantity 5 | User changes quantity to 0, confirmation dialog appears, user presses Escape | Item remains in cart with original quantity (5), dialog closes |
| TC-2.5 | Cart updates correctly after confirming removal | Multiple items in cart, user removes one | User changes quantity of one item to 0 and confirms removal | Item is removed, remaining items remain unaffected, cart total updates correctly |
| TC-2.6 | Confirmation dialog displays correct item details | An item "Blue Shirt (Size M)" with quantity 3 exists in cart | User sets quantity to 0 | Confirmation dialog shows correct item name and quantity before removal |
| TC-2.7 | User sets quantity to 0 multiple times | An item exists in the cart | User changes quantity to 0, cancels, then changes to 0 again and confirms | First action keeps item, second action removes it |

## AC-3: A quantity above 20 shows "You can buy at most 20 of this item." and keeps the previous quantity

| Test ID | Test Case | Given | When | Then |
|---------|-----------|-------|------|------|
| TC-3.1 | User enters quantity 21 | An item exists in the cart with quantity 10 | User enters 21 in quantity field | Error message "You can buy at most 20 of this item." is displayed and quantity remains 10 |
| TC-3.2 | User enters quantity 100 | An item exists in the cart with quantity 5 | User enters 100 in quantity field | Error message displays and quantity remains 5 |
| TC-3.3 | User enters very large number | An item exists in the cart with quantity 3 | User enters 999999 in quantity field | Error message displays and quantity remains 3 |
| TC-3.4 | Error message is dismissed and quantity persists | An item exists in the cart with quantity 12 | User enters 50, error message displays, user dismisses error | Error message disappears and quantity still shows 12 |
| TC-3.5 | User corrects invalid entry to valid quantity | An item exists in the cart with quantity 8 | User enters 25 (invalid), then enters 15 (valid) | Error message appears for 25, then disappears when 15 is entered and quantity updates to 15 |
| TC-3.6 | Quantity 20 is accepted as valid maximum | An item exists in the cart with quantity 1 | User enters exactly 20 | Quantity updates to 20 successfully, no error message |

## Integration and Edge Cases

| Test ID | Test Case | Given | When | Then |
|---------|-----------|-------|------|------|
| TC-4.1 | Quantity change updates cart subtotal | Item priced at $10 in cart with quantity 2 | User changes quantity to 5 | Cart subtotal updates from $20 to $50 |
| TC-4.2 | Quantity change triggers inventory check | An item with 15 units available in stock | User changes quantity from 3 to 15 | Quantity updates successfully as stock allows |
| TC-4.3 | Quantity change when stock is insufficient | An item with 8 units available in stock, user has 5 in cart | User attempts to change quantity to 10 | Quantity remains at 5 and stock-limit error message appears |
| TC-4.4 | Quantity field focus behavior | An item exists in the cart | User clicks on quantity field | Field is focused, any existing text is selected for easy replacement |
| TC-4.5 | Quantity persists after page navigation | User changes quantity to 7, navigates away from cart | User returns to cart | Quantity shows 7 (unsaved changes persist in session) |
| TC-4.6 | Rapid quantity changes don't cause race conditions | An item exists in the cart | User rapidly changes quantity 2 → 5 → 8 → 3 in quick succession | Final quantity settles to 3 with no data inconsistencies |
