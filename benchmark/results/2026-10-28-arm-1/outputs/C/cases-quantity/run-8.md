# Test Cases for CART-12: Change the Quantity of an Item in the Cart

## Assumptions

- The cart displays items with editable quantity fields
- The quantity field is a numeric input that accepts user input
- "Change quantity" means editing the current quantity value
- Confirmation dialog title is exactly "Remove this item?"
- Error message text is exactly "You can buy at most 20 of this item."
- The product is an e-commerce shopping cart
- Previous quantity refers to the value before the user's attempted change

---

## AC-1: The quantity field accepts whole numbers from 1 to 20

| Test Case ID | Title | Steps | Expected Result |
| --- | --- | --- | --- |
| TC-1.1 | Accept minimum quantity | Change quantity to 1 | Field updates to 1; cart total updates |
| TC-1.2 | Accept maximum quantity | Change quantity to 20 | Field updates to 20; cart total updates |
| TC-1.3 | Accept quantity in middle range | Change quantity to 10 | Field updates to 10; cart total updates |
| TC-1.4 | Accept decimal input rounded down | Enter 5.7 | Field updates to 5 (or rejects decimals) |
| TC-1.5 | Reject negative numbers | Enter -5 | Field does not update; shows error or reverts to previous |
| TC-1.6 | Reject non-numeric characters | Enter "abc" | Field does not update; no change in cart |
| TC-1.7 | Accept leading zeros | Enter 05 | Field updates to 5 |
| TC-1.8 | Preserve valid quantity after failed attempt | Try 25, then enter 15 | Field updates to 15 after failed 25 entry |

---

## AC-2: Setting quantity to 0 asks "Remove this item?" and removes item only when confirmed

| Test Case ID | Title | Steps | Expected Result |
| --- | --- | --- | --- |
| TC-2.1 | Show confirmation dialog on zero entry | Enter 0 in quantity field | Dialog appears with text "Remove this item?" |
| TC-2.2 | Remove item when user confirms | Enter 0, then select confirm in dialog | Item is removed from cart; cart count decreases |
| TC-2.3 | Keep item when user cancels | Enter 0, dialog appears, select cancel | Dialog closes; quantity field reverts to previous value; item remains in cart |
| TC-2.4 | Keep item when user closes dialog without action | Enter 0, dialog appears, select close (X) button | Dialog closes; quantity field reverts to previous value; item remains in cart |
| TC-2.5 | Remove item from cart total on confirm | Item costs $10, quantity 2 (total $20), enter 0 and confirm | Cart total decreases by $20 |
| TC-2.6 | Dialog appears only once | Enter 0 twice without closing dialog | Dialog appears once; second entry while dialog open has no effect |

---

## AC-3: Quantity above 20 shows error and keeps previous quantity

| Test Case ID | Title | Steps | Expected Result |
| --- | --- | --- | --- |
| TC-3.1 | Show error for quantity 21 | Enter 21 | Error message "You can buy at most 20 of this item." appears; field keeps previous value |
| TC-3.2 | Show error for quantity 50 | Enter 50 | Error message displays; field keeps previous value |
| TC-3.3 | Preserve previous quantity on error | Current quantity 10, enter 25 | Error displays; field shows 10; cart total unchanged |
| TC-3.4 | Dismiss error and maintain state | Error appears for 30, dismiss error | Error clears; quantity field still shows previous value |
| TC-3.5 | Allow valid entry after error | Enter 30 (error), then enter 18 | Error for 30; after dismissing, 18 is accepted |
| TC-3.6 | Show error for quantity 100+ | Enter 999 | Error message displays; quantity unchanged |

---

## Edge Cases and Integration

| Test Case ID | Title | Steps | Expected Result |
| --- | --- | --- | --- |
| TC-4.1 | Change quantity multiple times in sequence | Enter 5, then 10, then 3 | Each update applies; cart total reflects final quantity |
| TC-4.2 | Update quantity when cart has multiple items | Cart has 2 items; change first item quantity | Only the changed item updates; other items unaffected |
| TC-4.3 | Prevent quantity overflow on rapid clicks | Rapidly click +1 button 25 times | Quantity caps at 20; error shows on excess attempts |
| TC-4.4 | Empty field behavior | Clear quantity field without entering value | Field shows error or reverts to previous value |
