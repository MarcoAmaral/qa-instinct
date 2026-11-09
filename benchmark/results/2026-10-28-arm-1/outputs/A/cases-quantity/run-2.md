# Test Cases for CART-12: Change the Quantity of an Item in the Cart

## Assumptions
- The quantity field is an input field that validates on change or blur
- The cart maintains the previous quantity if validation fails
- The confirmation dialog for removal is a modal popup
- Quantity changes are persisted after confirmation
- The item card displays the current quantity

## Test Cases

### AC-1: Quantity Field Accepts Whole Numbers from 1 to 20

| ID | Test Case | Steps | Expected Result |
|---|---|---|---|
| CART-12-AC1-01 | Accept valid quantity 1 | 1. Add item to cart<br>2. Click quantity field<br>3. Enter "1"<br>4. Confirm change | Quantity updates to 1, item remains in cart |
| CART-12-AC1-02 | Accept valid quantity 10 | 1. Add item to cart with quantity 5<br>2. Change quantity to "10"<br>3. Confirm change | Quantity updates to 10 |
| CART-12-AC1-03 | Accept valid quantity 20 (upper boundary) | 1. Add item to cart<br>2. Change quantity to "20"<br>3. Confirm change | Quantity updates to 20 |
| CART-12-AC1-04 | Reject quantity 0 | 1. Add item to cart with quantity 5<br>2. Change quantity to "0" | Removal confirmation dialog appears (see AC-2) |
| CART-12-AC1-05 | Reject quantity 21 (above max) | 1. Add item to cart with quantity 10<br>2. Change quantity to "21"<br>3. Press Enter or blur field | Error message displays, quantity remains 10 |
| CART-12-AC1-06 | Reject negative quantity | 1. Add item to cart<br>2. Change quantity to "-5" | Quantity reverts to previous value or shows error |
| CART-12-AC1-07 | Reject decimal quantity | 1. Add item to cart<br>2. Change quantity to "5.5" | Quantity reverts to previous value or rounds/shows error |
| CART-12-AC1-08 | Reject non-numeric input | 1. Add item to cart<br>2. Change quantity to "abc" | Quantity reverts to previous value or shows error |
| CART-12-AC1-09 | Reject empty field | 1. Add item to cart<br>2. Clear quantity field and blur | Quantity reverts to previous value or field resets |

### AC-2: Quantity Set to 0 Asks for Confirmation Before Removing

| ID | Test Case | Steps | Expected Result |
|---|---|---|---|
| CART-12-AC2-01 | Show removal confirmation on zero quantity | 1. Add item to cart<br>2. Change quantity to "0"<br>3. Observe dialog | Confirmation dialog appears with text "Remove this item?" |
| CART-12-AC2-02 | Confirm removal | 1. Add item to cart<br>2. Change quantity to "0"<br>3. Confirmation dialog appears<br>4. Click "Yes" or "Confirm" button | Item is removed from cart, cart updates |
| CART-12-AC2-03 | Cancel removal | 1. Add item to cart with quantity 5<br>2. Change quantity to "0"<br>3. Confirmation dialog appears<br>4. Click "No" or "Cancel" button | Item remains in cart with quantity 5 |
| CART-12-AC2-04 | Dismiss confirmation via close button | 1. Add item to cart with quantity 5<br>2. Change quantity to "0"<br>3. Confirmation dialog appears<br>4. Click X or close icon | Item remains in cart with quantity 5 |
| CART-12-AC2-05 | Dismiss confirmation via escape key | 1. Add item to cart with quantity 5<br>2. Change quantity to "0"<br>3. Confirmation dialog appears<br>4. Press Escape key | Item remains in cart with quantity 5 |

### AC-3: Quantity Above 20 Shows Error Message and Keeps Previous Quantity

| ID | Test Case | Steps | Expected Result |
|---|---|---|---|
| CART-12-AC3-01 | Show error on quantity 21 | 1. Add item to cart with quantity 10<br>2. Change quantity to "21"<br>3. Blur or submit field | Error message "You can buy at most 20 of this item." displays, quantity remains 10 |
| CART-12-AC3-02 | Show error on quantity 100 | 1. Add item to cart with quantity 1<br>2. Change quantity to "100" | Error message displays, quantity remains 1 |
| CART-12-AC3-03 | Preserve previous quantity after error | 1. Add item to cart with quantity 15<br>2. Change quantity to "25"<br>3. Error message appears<br>4. Close/dismiss error | Quantity field shows 15, cart total reflects 15 items |
| CART-12-AC3-04 | Error clears when valid quantity entered | 1. Add item to cart<br>2. Change quantity to "25"<br>3. Error displays<br>4. Change quantity to "20" | Error clears, quantity updates to 20 |

### Additional Edge Cases

| ID | Test Case | Steps | Expected Result |
|---|---|---|---|
| CART-12-ADD-01 | Multiple quantity changes in succession | 1. Add item to cart<br>2. Change quantity to 5<br>3. Change quantity to 10<br>4. Change quantity to 15 | All changes apply correctly, cart total updates with each change |
| CART-12-ADD-02 | Quantity field maintains focus during validation | 1. Add item to cart<br>2. Click quantity field<br>3. Enter invalid value<br>4. Observe field behavior | Field remains focused, error displays, allows user to correct input |
| CART-12-ADD-03 | Cart totals update when quantity changes | 1. Add item ($10 each) with quantity 2 to cart<br>2. Change quantity to 5 | Subtotal updates from $20 to $50 |
| CART-12-ADD-04 | Changing last item to 0 removes item, shows empty cart state | 1. Add single item to cart with quantity 2<br>2. Change quantity to "0"<br>3. Confirm removal | Item removed, empty cart message or state displays |
