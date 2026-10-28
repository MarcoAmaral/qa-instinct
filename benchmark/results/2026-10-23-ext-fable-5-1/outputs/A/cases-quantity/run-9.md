# Test Cases: CART-12 — Change the quantity of an item in the cart

## Assumptions

- The quantity control is a text/number input on the cart page, applied on blur, Enter, or an explicit "Update" action. Tests below say "apply the quantity" to cover whichever the implementation uses.
- The "Remove this item?" prompt has a Confirm action and a Cancel action.
- When a value is rejected (AC-3, invalid input), the field reverts to the previous quantity and the cart line total and subtotal are unchanged.
- Non-integer, negative, blank, and non-numeric input are rejected and the previous quantity is kept. The story gives no message text for these cases, so tests check only that the previous quantity is restored and no server update occurs.
- The 20-item cap is a per-line maximum, independent of stock levels. Stock-based limits are out of scope.
- Changing the quantity updates the line total, the cart subtotal, and the header cart count.
- Preconditions for every test: shopper is on the cart page with one line item "Widget" at quantity 2, unit price 10.00, unless stated otherwise.

## AC-1: Quantity accepts whole numbers 1 to 20

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-01 | Increase quantity within range | Set quantity to 5 and apply. | Field shows 5. Line total is 50.00. Subtotal and header count update to match. Item remains in cart. |
| TC-02 | Decrease quantity within range | Set quantity to 1 and apply. | Field shows 1. Line total is 10.00. No removal prompt appears. |
| TC-03 | Lower boundary: 1 | From quantity 2, set quantity to 1 and apply. | Accepted. Quantity is 1. No prompt or error. |
| TC-04 | Upper boundary: 20 | Set quantity to 20 and apply. | Accepted. Quantity is 20. Line total is 200.00. No error message. |
| TC-05 | Set same quantity as current | Set quantity to 2 (unchanged) and apply. | Quantity stays 2. No error, no prompt, totals unchanged. |
| TC-06 | Change persists after reload | Set quantity to 7, apply, then reload the cart page. | Quantity still shows 7. Totals reflect 7. |
| TC-07 | Leading zeros | Enter "05" and apply. | Treated as 5. Field shows 5. Line total is 50.00. |
| TC-08 | Surrounding whitespace | Enter " 4 " and apply. | Treated as 4. Field shows 4. |
| TC-09 | Decimal value rejected | Enter 2.5 and apply. | Rejected. Field reverts to 2. Totals unchanged. |
| TC-10 | Negative value rejected | Enter -1 and apply. | Rejected. Field reverts to 2. No removal prompt appears. |
| TC-11 | Non-numeric value rejected | Enter "abc" and apply. | Rejected. Field reverts to 2. |
| TC-12 | Blank value rejected | Clear the field and apply. | Rejected. Field reverts to 2. Item is not removed and no prompt appears. |
| TC-13 | Multiple items updated independently | Cart has Widget (qty 2) and Gadget (qty 3). Set Widget to 6 and apply. | Widget shows 6. Gadget still shows 3. Subtotal reflects both. |
| TC-14 | Keyboard-only operation | Tab to the quantity field, type 3, press Enter. | Quantity updates to 3. Focus remains on or returns to a sensible element. Field has an accessible label naming the item. |

## AC-2: Setting quantity to 0 prompts for removal

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-15 | Zero shows the removal prompt | Set quantity to 0 and apply. | Prompt "Remove this item?" appears with Confirm and Cancel actions. Item is still in the cart while the prompt is open. |
| TC-16 | Confirm removal | Set quantity to 0, apply, choose Confirm. | Widget is removed from the cart. Subtotal and header count exclude it. Removal persists after reload. |
| TC-17 | Cancel removal | Set quantity to 0, apply, choose Cancel. | Prompt closes. Widget remains in cart at quantity 2. Totals unchanged. |
| TC-18 | Dismiss prompt without choosing | Set quantity to 0, apply, close the prompt via Escape or clicking outside. | Treated as Cancel. Widget remains at quantity 2. |
| TC-19 | Zero on one item does not affect others | Cart has Widget (qty 2) and Gadget (qty 3). Set Widget to 0, apply, Confirm. | Only Widget is removed. Gadget still shows 3. |
| TC-20 | Removing the only item | Cart has only Widget. Set to 0, apply, Confirm. | Cart shows its empty state. Header count is 0. |
| TC-21 | Prompt message text | Set quantity to 0 and apply. | Prompt text is exactly "Remove this item?". |
| TC-22 | Zero with leading zeros | Enter "00" and apply. | Treated as 0. Removal prompt appears. |
| TC-23 | Cancel then change again | Set to 0, apply, Cancel, then set to 4 and apply. | Quantity updates to 4 normally. No stale prompt. |

## AC-3: Quantity above 20 is rejected

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-24 | Just above the limit: 21 | Set quantity to 21 and apply. | Message "You can buy at most 20 of this item." is shown. Field reverts to 2. Line total and subtotal unchanged. |
| TC-25 | Far above the limit | Set quantity to 999 and apply. | Same message. Field reverts to 2. |
| TC-26 | Very large number | Enter 99999999999999999999 and apply. | Same message. Field reverts to 2. No crash or server error. |
| TC-27 | Above limit from a previous valid change | Set quantity to 15, apply, then set to 25 and apply. | Message shown. Field reverts to 15, not to the original 2. |
| TC-28 | Message text is exact | Set quantity to 21 and apply. | Message text is exactly "You can buy at most 20 of this item." |
| TC-29 | Message clears on valid entry | Set to 21, apply (message shown), then set to 10 and apply. | Message disappears. Quantity is 10. |
| TC-30 | Rejected value is not persisted | Set to 21, apply, then reload the cart page. | Quantity shows 2. |
| TC-31 | Message is announced to assistive tech | Set to 21 and apply with a screen reader active. | Message is announced (for example via a live region or associated error) and the field is marked invalid. |
| TC-32 | Limit applies per item | Cart has Widget (qty 2) and Gadget (qty 3). Set Gadget to 30 and apply. | Message shown on Gadget's line only. Gadget reverts to 3. Widget unaffected. |

## Server-side and robustness

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-33 | API rejects out-of-range quantity | Bypass the UI and send a cart update request with quantity 21. | Request is rejected with a validation error. Cart quantity unchanged. |
| TC-34 | API rejects non-integer quantity | Send a cart update request with quantity 2.5, -1, or "abc". | Request is rejected with a validation error. Cart quantity unchanged. |
| TC-35 | API accepts boundary values | Send cart update requests with quantity 1 and 20. | Both succeed. Cart reflects the new quantity. |
| TC-36 | API with quantity 0 | Send a cart update request with quantity 0. | Item is removed, or request is rejected, per implementation. Assumption: 0 via API removes the item, since the confirmation is a UI concern. |
| TC-37 | Rapid successive changes | Change quantity to 3, then immediately to 4, then to 5 before responses return. | Final quantity is 5. Totals match 5. No intermediate value wins the race. |
| TC-38 | Update fails on the server | Simulate a server error on the update request, set quantity to 5 and apply. | Field reverts to 2. An error is shown to the shopper. Cart is not left in an inconsistent state. |
| TC-39 | Item removed in another tab | Open cart in two tabs. Remove Widget in tab A. In tab B, set Widget to 5 and apply. | Tab B shows an appropriate error or refreshes to show the item is gone. No orphaned line is created. |
