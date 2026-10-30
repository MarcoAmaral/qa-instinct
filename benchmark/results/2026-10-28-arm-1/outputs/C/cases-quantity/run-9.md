I see you've invoked the help-articles skill, but your request is for test cases for a user story, not a help center article. I'll write the test cases directly using standard QA formats.

---

# Test Cases: CART-12 Change Item Quantity in Cart

## Assumptions
- Quantity field is a numerical input or spinner control
- Previous quantity refers to the value before the user's invalid attempt
- Confirmation dialog is modal and requires explicit user action
- Quantity limits apply per item, not cart-wide
- Shopper must be on the cart page or item detail view

---

## Test Case 1: Valid Quantity Entry (1-20)
**Precondition:** Item exists in cart with quantity 1

| # | Action | Expected Result |
|---|--------|-----------------|
| 1 | Enter quantity `5` in quantity field | Field updates to `5` |
| 2 | Confirm/save change | Cart item quantity updates to `5`; no error shown |

**Variations:** Test with quantities 1, 10, 20 (boundary values)

---

## Test Case 2: Quantity Above Maximum
**Precondition:** Item in cart with quantity 10

| # | Action | Expected Result |
|---|--------|-----------------|
| 1 | Enter quantity `21` in quantity field | Error message appears: "You can buy at most 20 of this item." |
| 2 | Verify quantity field value | Field still shows previous quantity: `10` |
| 3 | Verify cart total | Cart total unchanged |

**Variations:** Test with 25, 100, and 999 (to confirm max is 20, not higher)

---

## Test Case 3: Set Quantity to Zero
**Precondition:** Item in cart with quantity 3

| # | Action | Expected Result |
|---|--------|-----------------|
| 1 | Enter quantity `0` in quantity field | Confirmation modal appears with text: "Remove this item?" |
| 2 | Select "Cancel" button | Modal closes; quantity remains `3`; item stays in cart |

---

## Test Case 4: Remove Item via Zero Quantity Confirmation
**Precondition:** Item in cart with quantity 3; confirmation modal displayed

| # | Action | Expected Result |
|---|--------|-----------------|
| 1 | Select "Confirm" or "Yes" button | Item removed from cart; cart updates; page refreshes or animates item removal |

---

## Test Case 5: Invalid Quantity Formats
**Precondition:** Item in cart

| # | Action | Expected Result |
|---|--------|-----------------|
| 1 | Enter `-5` (negative) | Field rejects entry or shows error; quantity unchanged |
| 2 | Enter `5.5` (decimal) | Field accepts only whole number or rejects; quantity unchanged |
| 3 | Enter `abc` (text) | Field rejects or clears; quantity unchanged |
| 4 | Leave field empty, then save | Field either defaults to 1 or shows error requiring a value |

---

## Test Case 6: Rapid Quantity Changes
**Precondition:** Item in cart with quantity 5

| # | Action | Expected Result |
|---|--------|-----------------|
| 1 | Change quantity to `8` | Quantity updates to `8` |
| 2 | Change quantity to `15` before save completes | Final quantity resolves to `15`; no race condition or duplicates |

---

## Test Case 7: Quantity Change Persists After Navigation
**Precondition:** Item quantity changed to 7 and saved

| # | Action | Expected Result |
|---|--------|-----------------|
| 1 | Navigate away from cart (e.g., to product page) | Session saves quantity change |
| 2 | Return to cart | Item quantity still shows `7` |

---

## Test Case 8: Bulk Quantity Edge Cases
**Precondition:** Cart with multiple items

| # | Action | Expected Result |
|---|--------|-----------------|
| 1 | Set one item to quantity `20` | That item updates; other items unchanged |
| 2 | Set another item to `21` | Error shown only for that item; quantity reverts to previous |
