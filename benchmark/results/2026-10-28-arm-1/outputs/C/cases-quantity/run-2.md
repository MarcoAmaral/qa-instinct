# Test Cases for CART-12: Change Quantity of an Item in Cart

| Test ID | Title | Preconditions | Steps | Expected Result |
|---------|-------|---------------|-------|-----------------|
| TC-CART-12-001 | Quantity accepts value 1 | Item in cart with any quantity | 1. Open cart<br>2. Select quantity field on item<br>3. Clear field and enter `1`<br>4. Confirm change | Quantity updates to 1; item remains in cart |
| TC-CART-12-002 | Quantity accepts value 20 | Item in cart with any quantity | 1. Open cart<br>2. Select quantity field on item<br>3. Clear field and enter `20`<br>4. Confirm change | Quantity updates to 20; item remains in cart |
| TC-CART-12-003 | Quantity accepts mid-range value | Item in cart with any quantity | 1. Open cart<br>2. Select quantity field on item<br>3. Clear field and enter `10`<br>4. Confirm change | Quantity updates to 10; item remains in cart |
| TC-CART-12-004 | Quantity rejects decimal value | Item in cart | 1. Open cart<br>2. Select quantity field on item<br>3. Enter `5.5` | Field does not accept decimal; value is rejected or rounded to whole number |
| TC-CART-12-005 | Quantity rejects negative value | Item in cart | 1. Open cart<br>2. Select quantity field on item<br>3. Enter `-5` | Field does not accept negative value; change is rejected |
| TC-CART-12-006 | Quantity rejects non-numeric input | Item in cart | 1. Open cart<br>2. Select quantity field on item<br>3. Enter `abc` | Field does not accept letters; value is rejected |
| TC-CART-12-007 | Setting quantity to 0 shows removal confirmation | Item in cart with quantity 1 or higher | 1. Open cart<br>2. Select quantity field on item<br>3. Clear field and enter `0`<br>4. Confirm change | Dialog appears with message "Remove this item?"; item remains in cart |
| TC-CART-12-008 | Confirming removal deletes item | Removal confirmation dialog open | 1. Dialog shows "Remove this item?"<br>2. Select **Confirm** or **Yes** button | Item is removed from cart; cart updates to reflect removal |
| TC-CART-12-009 | Canceling removal keeps item | Removal confirmation dialog open | 1. Dialog shows "Remove this item?"<br>2. Select **Cancel** or **No** button | Dialog closes; item remains in cart with previous quantity unchanged |
| TC-CART-12-010 | Closing dialog cancels removal | Removal confirmation dialog open | 1. Dialog shows "Remove this item?"<br>2. Select close button (X) or press Escape | Dialog closes; item remains in cart with previous quantity unchanged |
| TC-CART-12-011 | Quantity above 20 shows error message | Item in cart with any quantity | 1. Open cart<br>2. Select quantity field on item<br>3. Clear field and enter `21`<br>4. Confirm change | Message appears: "You can buy at most 20 of this item."; quantity reverts to previous value |
| TC-CART-12-012 | Quantity well above 20 shows error message | Item in cart with any quantity | 1. Open cart<br>2. Select quantity field on item<br>3. Clear field and enter `100`<br>4. Confirm change | Message appears: "You can buy at most 20 of this item."; quantity reverts to previous value |
| TC-CART-12-013 | Previous quantity maintained after rejected change | Item in cart with quantity 5 | 1. Open cart<br>2. Select quantity field on item<br>3. Clear field and enter `25`<br>4. Confirm change | Error message appears; quantity remains 5 |
| TC-CART-12-014 | Multiple items can have different quantities | Two or more items in cart | 1. Open cart<br>2. Change first item quantity to 3<br>3. Change second item quantity to 15 | Each item reflects its updated quantity independently |

## Assumptions

- The quantity field is editable via text input.
- Dialog has **Confirm** and **Cancel** (or equivalent) buttons.
- "Confirm change" means pressing Enter, Tab, or selecting an implicit save action.
- Non-integer inputs (decimals, letters, negative values) are rejected silently or with validation feedback.
- The error message for quantities above 20 appears as a modal dialog or inline alert.
- Previous quantity is retained in memory until a valid change is confirmed.
