# Test Cases for CART-12: Change the Quantity of an Item in the Cart

## Assumptions
- Quantity field is a numeric input on the cart item
- Validation occurs on input change or when the user attempts to leave the field
- Error/confirmation messages appear as modals or inline notifications
- Previous quantity is retained if validation fails
- The cart contains at least one item for testing
- Testing is performed in a standard web browser environment

---

## AC-1: Quantity Field Accepts Whole Numbers from 1 to 20

### TC-1.1: Accept quantity of 1
**Given** a user is viewing a cart item with quantity 2  
**When** the user changes the quantity to 1  
**Then** the quantity field updates to 1 and the item remains in the cart

### TC-1.2: Accept quantity of 20
**Given** a user is viewing a cart item with quantity 10  
**When** the user changes the quantity to 20  
**Then** the quantity field updates to 20 and the item remains in the cart

### TC-1.3: Accept quantity of 10 (middle range)
**Given** a user is viewing a cart item with quantity 5  
**When** the user changes the quantity to 10  
**Then** the quantity field updates to 10 and the item remains in the cart

### TC-1.4: Reject decimal input
**Given** a user is viewing a cart item  
**When** the user attempts to enter 5.5  
**Then** the quantity field does not accept the decimal value or auto-rounds to 5 or 6

### TC-1.5: Reject negative numbers
**Given** a user is viewing a cart item  
**When** the user attempts to enter -5  
**Then** the quantity field does not accept the negative value

### TC-1.6: Reject alphabetic input
**Given** a user is viewing a cart item  
**When** the user attempts to enter "abc"  
**Then** the quantity field does not accept alphabetic characters

### TC-1.7: Reject special characters
**Given** a user is viewing a cart item  
**When** the user attempts to enter "@#$"  
**Then** the quantity field does not accept special characters

### TC-1.8: Accept quantity after invalid attempt
**Given** a user attempts to enter an invalid quantity  
**When** the user clears the field and enters a valid quantity (e.g., 5)  
**Then** the quantity updates to the valid value

---

## AC-2: Setting Quantity to 0 Asks Confirmation and Removes Item Only When Confirmed

### TC-2.1: Display confirmation dialog on quantity 0
**Given** a user is viewing a cart item with quantity 1  
**When** the user changes the quantity to 0  
**Then** a confirmation dialog appears with the message "Remove this item?"

### TC-2.2: Confirm removal deletes item
**Given** a confirmation dialog displays asking "Remove this item?"  
**When** the user clicks "Confirm" or "Yes"  
**Then** the item is removed from the cart and no longer visible

### TC-2.3: Cancel removal keeps item
**Given** a confirmation dialog displays asking "Remove this item?"  
**When** the user clicks "Cancel" or "No"  
**Then** the item remains in the cart with its previous quantity

### TC-2.4: Previous quantity restored after cancel
**Given** a user changes quantity to 0 and then cancels the confirmation  
**When** the dialog closes  
**Then** the quantity field displays the previous quantity value

### TC-2.5: Escape key dismisses dialog without removal
**Given** a confirmation dialog is open  
**When** the user presses the Escape key  
**Then** the dialog closes and the item remains in the cart with previous quantity

### TC-2.6: Click outside dialog dismisses without removal
**Given** a confirmation dialog is open  
**When** the user clicks outside the dialog area  
**Then** the dialog closes and the item remains in the cart with previous quantity

---

## AC-3: Quantity Above 20 Shows Error Message and Keeps Previous Quantity

### TC-3.1: Reject quantity 21
**Given** a user is viewing a cart item with quantity 10  
**When** the user attempts to enter 21  
**Then** an error message "You can buy at most 20 of this item." is displayed and the quantity remains 10

### TC-3.2: Reject quantity 100
**Given** a user is viewing a cart item with quantity 5  
**When** the user attempts to enter 100  
**Then** an error message "You can buy at most 20 of this item." is displayed and the quantity remains 5

### TC-3.3: Reject quantity 22
**Given** a user is viewing a cart item  
**When** the user attempts to enter 22  
**Then** an error message "You can buy at most 20 of this item." is displayed

### TC-3.4: Quantity reverts to previous after error
**Given** a user attempts to enter a quantity above 20 and sees the error message  
**When** the error message is dismissed  
**Then** the quantity field displays the previous valid quantity

### TC-3.5: Accept valid quantity after failed attempt
**Given** a user previously attempted to enter 25 and saw the error message  
**When** the user enters a valid quantity (e.g., 15)  
**Then** the quantity updates to 15 and no error is shown

### TC-3.6: Consistent error message for all out-of-range values
**Given** a user attempts quantities 21, 50, and 999  
**When** each invalid quantity is entered  
**Then** the same error message "You can buy at most 20 of this item." displays for all attempts

---

## Cross-Functional Test Cases

### TC-4.1: Multiple items with different quantities
**Given** a cart contains multiple items with different quantities  
**When** the user updates one item's quantity  
**Then** only that item is affected; other items' quantities remain unchanged

### TC-4.2: Quantity updates persist after page refresh
**Given** a user updates an item's quantity to a valid value  
**When** the page is refreshed  
**Then** the cart displays the updated quantity

### TC-4.3: Rapid quantity changes
**Given** a user is viewing a cart item  
**When** the user rapidly changes the quantity multiple times  
**Then** the final quantity value is the last valid input entered

### TC-4.4: Empty cart state after removing last item
**Given** a user removes the only item in the cart via quantity 0 confirmation  
**When** the item is deleted  
**Then** the cart displays an empty state message (e.g., "Your cart is empty")
