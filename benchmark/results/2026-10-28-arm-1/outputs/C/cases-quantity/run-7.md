# Test Cases for CART-12: Change the Quantity of an Item in the Cart

## Assumptions

- The quantity field is a numeric input control in the cart UI
- "Previous quantity" refers to the quantity value before an invalid change attempt
- The cart displays one or more items with quantity controls
- The removal confirmation appears as a modal dialog
- Non-whole numbers are rejected before submission

---

## AC-1: Quantity Field Accepts Whole Numbers 1–20

| Test ID | Scenario | Steps | Expected Result |
|---------|----------|-------|-----------------|
| CART-12-AC1-001 | Set quantity to 1 | Enter "1" in the quantity field for a cart item | Quantity updates to 1; cart total recalculates |
| CART-12-AC1-002 | Set quantity to 20 | Enter "20" in the quantity field for a cart item | Quantity updates to 20; cart total recalculates |
| CART-12-AC1-003 | Set quantity to a midpoint value | Enter "10" in the quantity field for a cart item | Quantity updates to 10; cart total recalculates |
| CART-12-AC1-004 | Decimal input rejected | Enter "5.5" in the quantity field | Field rejects input or rounds to whole number (assumed: rejected); quantity does not change |
| CART-12-AC1-005 | Negative number rejected | Enter "-5" in the quantity field | Field rejects input; quantity does not change |
| CART-12-AC1-006 | Change quantity multiple times | Set quantity to 5, then to 15, then to 8 | Each update reflects correctly; cart total updates each time |

---

## AC-2: Setting Quantity to 0 Shows Confirmation and Removes Only on Confirm

| Test ID | Scenario | Steps | Expected Result |
|---------|----------|-------|-----------------|
| CART-12-AC2-001 | Set quantity to 0 and confirm removal | Enter "0" in the quantity field; select **Confirm** in the removal dialog | Item is removed from cart; cart total recalculates |
| CART-12-AC2-002 | Set quantity to 0 and cancel removal | Enter "0" in the quantity field; select **Cancel** in the removal dialog | Item remains in cart at previous quantity; dialog closes |
| CART-12-AC2-003 | Confirmation message text | Enter "0" in the quantity field | Dialog displays "Remove this item?" (exact text) |
| CART-12-AC2-004 | Multiple items, remove one at 0 | Set one item's quantity to 0 and confirm; verify other items remain | Targeted item removed; other items and their quantities unchanged |

---

## AC-3: Quantity Above 20 Shows Error and Retains Previous Quantity

| Test ID | Scenario | Steps | Expected Result |
|---------|----------|-------|-----------------|
| CART-12-AC3-001 | Set quantity to 21 | Enter "21" in the quantity field | Error message displays "You can buy at most 20 of this item."; quantity reverts to previous value |
| CART-12-AC3-002 | Set quantity to 100 | Enter "100" in the quantity field | Error message displays "You can buy at most 20 of this item."; quantity reverts to previous value |
| CART-12-AC3-003 | Set quantity above 20 from quantity of 5 | Set quantity to 5, then attempt to change to 25 | Error message displays; quantity returns to 5 |
| CART-12-AC3-004 | Error message persistence | Enter "50" and wait 3 seconds | Error message remains visible until dismissed or user corrects input |

---

## Cross-Functional Tests

| Test ID | Scenario | Steps | Expected Result |
|---------|----------|-------|-----------------|
| CART-12-CROSS-001 | Boundary test at 20 then 21 | Set quantity to 20; verify success; set to 21; verify error | 20 succeeds; 21 shows error and retains 20 |
| CART-12-CROSS-002 | Cart total updates correctly | Add item with quantity 1; change to 5; verify price multiplier | Cart subtotal = (item price × 5) |
| CART-12-CROSS-003 | Empty field behavior | Clear the quantity field without entering a value | Assumed: Field is required; no update occurs or error displays |
| CART-12-CROSS-004 | Non-numeric input | Enter letters or symbols in quantity field | Field rejects input; quantity does not change |
