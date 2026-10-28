# Test Cases: Change Quantity in Cart (CART-12)

## Assumptions
- Quantity field is a text or number input, not a stepper
- Previous quantity is stored before user action
- Confirmation dialog is modal and blocks further interaction
- Quantity updates are immediate upon confirmation (no server delay shown to user)
- Cart persists across page refreshes within a session
- Non-numeric input is rejected without clearing the field

---

## Test Case 1: Valid quantity change (1–20)
**Given** an item with quantity 1 in the cart  
**When** the shopper enters 5 in the quantity field and confirms  
**Then** the cart updates to show quantity 5  
**And** the total price recalculates

---

## Test Case 2: Minimum valid quantity
**Given** an item in the cart  
**When** the shopper enters 1 in the quantity field  
**Then** the quantity updates to 1  
**And** no warning or removal dialog appears

---

## Test Case 3: Maximum valid quantity
**Given** an item in the cart  
**When** the shopper enters 20 in the quantity field  
**Then** the quantity updates to 20

---

## Test Case 4: Quantity above limit shows error
**Given** an item with quantity 5 in the cart  
**When** the shopper enters 21 in the quantity field  
**Then** the error message "You can buy at most 20 of this item." appears  
**And** the quantity remains 5 (previous value)

---

## Test Case 5: Quantity above limit (multiple times)
**Given** an item in the cart  
**When** the shopper enters 25, then 100 in the quantity field  
**Then** the error message appears each time  
**And** the quantity remains at the original value

---

## Test Case 6: Setting quantity to 0 triggers confirmation
**Given** an item with quantity 5 in the cart  
**When** the shopper enters 0 in the quantity field  
**Then** a confirmation dialog appears with the message "Remove this item?"  
**And** the quantity field still shows 0 or is disabled  
**And** the item is not removed until confirmation

---

## Test Case 7: User confirms item removal
**Given** the "Remove this item?" confirmation dialog is open  
**When** the shopper selects the confirm button (assumed label: "Remove")  
**Then** the item is removed from the cart  
**And** the cart total updates  
**And** the dialog closes

---

## Test Case 8: User cancels item removal
**Given** the "Remove this item?" confirmation dialog is open  
**When** the shopper selects the cancel button (assumed label: "Keep")  
**Then** the item remains in the cart with its previous quantity  
**And** the quantity field reverts to the previous value  
**And** the dialog closes

---

## Test Case 9: Invalid input (non-numeric)
**Given** an item in the cart  
**When** the shopper enters "abc" or special characters in the quantity field  
**Then** the input is rejected  
**And** the quantity field is cleared or returns to the previous value  
**And** no item is removed

---

## Test Case 10: Decimal input
**Given** an item in the cart  
**When** the shopper enters "5.5" in the quantity field  
**Then** the input is rejected (assumed: whole numbers only per AC-1)  
**And** the quantity remains unchanged

---

## Test Case 11: Negative quantity
**Given** an item in the cart  
**When** the shopper enters "-5" in the quantity field  
**Then** the input is rejected or treated as invalid  
**And** the quantity remains unchanged

---

## Test Case 12: Empty quantity field
**Given** an item in the cart with quantity 3  
**When** the shopper clears the quantity field and leaves it blank  
**Then** the field returns to the previous value (3)  
**Or** an error message appears (assumed behavior)

---

## Test Case 13: Multiple items, change one quantity
**Given** the cart contains Item A (qty 2) and Item B (qty 1)  
**When** the shopper changes Item A's quantity to 5  
**Then** Item A updates to quantity 5  
**And** Item B remains at quantity 1  
**And** the cart total reflects both quantities

---

## Test Case 14: Change quantity after server sync
**Given** the cart was synced with the server 30 seconds ago  
**When** the shopper changes a quantity from 3 to 8  
**Then** the quantity updates to 8  
**And** the change is persisted (assumed: sent to server)

</body>
</command-message>
