# Test Cases — CART-12: Change the quantity of an item in the cart

## Assumptions

- The quantity field is a numeric input with a visible value; the new quantity is applied on blur, Enter, or an "Update" action (whichever the implementation uses, referred to below as "apply").
- "Whole numbers" means integers only; decimals, negatives, blanks, and non-numeric text are rejected and the previous quantity is kept.
- The "Remove this item?" prompt has a confirm and a cancel option. Cancelling restores the previous quantity.
- Cart line subtotal and cart total recalculate after a successful quantity change.
- Changes persist across page reload for the same shopper session.
- The error message in AC-3 is shown inline near the field and is dismissed on the next valid change.
- Stock limits are out of scope for this story.

## Preconditions (all cases)

- Shopper is on the cart page with at least one item in the cart.
- Unless stated otherwise, the item under test has quantity 5 and unit price 10.00.

---

## AC-1: Quantity field accepts whole numbers from 1 to 20

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-01 | Set quantity to lower boundary (1) | 1. Enter `1` in the quantity field. 2. Apply. | Quantity shows 1. Line subtotal is 10.00. Cart total updates. No message shown. |
| TC-02 | Set quantity to upper boundary (20) | 1. Enter `20`. 2. Apply. | Quantity shows 20. Line subtotal is 200.00. Cart total updates. No message shown. |
| TC-03 | Set quantity to a mid-range value (10) | 1. Enter `10`. 2. Apply. | Quantity shows 10. Line subtotal is 100.00. Cart total updates. |
| TC-04 | Increase quantity by one (5 → 6) | 1. Enter `6` (or use "+" stepper if present). 2. Apply. | Quantity shows 6. Line subtotal is 60.00. |
| TC-05 | Decrease quantity by one (5 → 4) | 1. Enter `4` (or use "−" stepper if present). 2. Apply. | Quantity shows 4. Line subtotal is 40.00. |
| TC-06 | Re-apply the same quantity (5 → 5) | 1. Leave `5` in the field. 2. Apply. | Quantity remains 5. No error, no duplicate line, totals unchanged. |
| TC-07 | Quantity change persists after reload | 1. Set quantity to `7`. 2. Apply. 3. Reload the cart page. | Quantity still shows 7. Line subtotal is 70.00. |
| TC-08 | Reject decimal value | 1. Enter `2.5`. 2. Apply. | Value is rejected. Quantity stays 5. Line subtotal unchanged. A validation message is shown (exact text not specified in story). |
| TC-09 | Reject negative value | 1. Enter `-1`. 2. Apply. | Value is rejected. Quantity stays 5. Validation message shown. |
| TC-10 | Reject non-numeric text | 1. Enter `abc`. 2. Apply. | Value is rejected. Quantity stays 5. Validation message shown. |
| TC-11 | Reject empty field | 1. Clear the field. 2. Apply. | Value is rejected. Quantity stays 5. Validation message shown. Item is not removed. |
| TC-12 | Leading zeros are normalised | 1. Enter `007`. 2. Apply. | Quantity shows 7. Line subtotal is 70.00. |
| TC-13 | Whitespace around a valid number | 1. Enter ` 3 ` (with spaces). 2. Apply. | Quantity shows 3. Line subtotal is 30.00. |
| TC-14 | Changing one item does not affect others | Precondition: cart has two distinct items, both at quantity 5. 1. Change item A to `2`. 2. Apply. | Item A shows 2. Item B still shows 5. Cart total reflects both correctly. |
| TC-15 | Keyboard-only operation | 1. Tab to the quantity field. 2. Type `8`. 3. Press Enter. | Quantity shows 8. Focus remains in a sensible place (field or next focusable element). |

---

## AC-2: Setting quantity to 0 prompts for removal

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-16 | Zero shows the removal prompt | 1. Enter `0`. 2. Apply. | A dialog with the text "Remove this item?" is shown. Item is still in the cart behind the dialog. |
| TC-17 | Confirm removal | 1. Enter `0`. 2. Apply. 3. Choose the confirm option. | Item is removed from the cart. Cart total no longer includes the item. If it was the only item, the empty-cart state is shown. |
| TC-18 | Cancel removal | 1. Enter `0`. 2. Apply. 3. Choose the cancel option. | Dialog closes. Item remains in the cart. Quantity field shows the previous value (5). Totals unchanged. |
| TC-19 | Dismiss prompt by other means (Escape / close icon / click outside) | 1. Enter `0`. 2. Apply. 3. Press Escape (or close icon, or click outside). | Treated as cancel: item remains, quantity reverts to 5. |
| TC-20 | Removal persists after reload | 1. Enter `0`. 2. Apply. 3. Confirm. 4. Reload the cart page. | Item is not in the cart. |
| TC-21 | Cancel persists after reload | 1. Enter `0`. 2. Apply. 3. Cancel. 4. Reload the cart page. | Item is still in the cart at quantity 5. |
| TC-22 | Decrement stepper to zero (if stepper exists) | Precondition: item at quantity 1. 1. Press "−". | "Remove this item?" prompt is shown, same behaviour as TC-16. |
| TC-23 | Zero on one of several items | Precondition: two distinct items in cart. 1. Set item A to `0`. 2. Apply. 3. Confirm. | Only item A is removed. Item B unchanged. |
| TC-24 | Prompt is accessible | 1. Enter `0`. 2. Apply. | Dialog receives keyboard focus; confirm and cancel are reachable by Tab; dialog is announced by a screen reader. |
| TC-25 | Zero with leading zeros (`00`) | 1. Enter `00`. 2. Apply. | Treated as 0: "Remove this item?" prompt is shown. |

---

## AC-3: Quantity above 20 is rejected

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-26 | Just above the limit (21) | 1. Enter `21`. 2. Apply. | Message "You can buy at most 20 of this item." is shown. Quantity field reverts to 5. Line subtotal and cart total unchanged. |
| TC-27 | Far above the limit (999) | 1. Enter `999`. 2. Apply. | Same as TC-26. |
| TC-28 | Very large value | 1. Enter `99999999999`. 2. Apply. | Same as TC-26. No crash, no overflow, no scientific-notation display. |
| TC-29 | Stepper beyond 20 (if stepper exists) | Precondition: item at quantity 20. 1. Press "+". | Message "You can buy at most 20 of this item." is shown. Quantity stays 20. |
| TC-30 | Message text is exact | 1. Enter `21`. 2. Apply. | Message text matches exactly: `You can buy at most 20 of this item.` (including capitalisation and trailing full stop). |
| TC-31 | Message clears after a valid change | 1. Enter `21`. 2. Apply. 3. Enter `3`. 4. Apply. | Message is no longer shown. Quantity shows 3. |
| TC-32 | Over-limit does not persist | 1. Enter `21`. 2. Apply. 3. Reload the cart page. | Quantity shows 5. |
| TC-33 | Over-limit on one item does not affect others | Precondition: two distinct items at quantity 5. 1. Set item A to `25`. 2. Apply. | Message shown for item A only. Item A stays 5. Item B stays 5. |
| TC-34 | Over-limit via paste | 1. Paste `50` into the field. 2. Apply. | Same as TC-26. |

---

## Cross-cutting / regression

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-35 | Sequence: valid → over-limit → zero (cancel) → valid | 1. Set `10`, apply. 2. Set `25`, apply. 3. Set `0`, apply, cancel. 4. Set `2`, apply. | Final quantity is 2. After step 2 the field shows 10. After step 3 the field shows 10. Only the final state is persisted. |
| TC-36 | Server rejects out-of-range value submitted directly (API) | 1. Send an update request with quantity `21` bypassing the UI. | Request is rejected with a validation error. Cart quantity unchanged. |
| TC-37 | Server rejects quantity 0 without confirmation flow (API) | 1. Send an update request with quantity `0` bypassing the UI. | Either rejected with a validation error, or treated as remove, per API contract. Behaviour must be documented and consistent with AC-2. |
| TC-38 | Rapid repeated changes | 1. Quickly change the quantity several times (3, 4, 5, 6) and apply each. | Final quantity shows 6. Totals match the last applied value. No stale value overwrites the latest one. |
| TC-39 | Cart badge / header count updates | 1. Set quantity from 5 to `8`. 2. Apply. | Mini-cart or header item count reflects the new total quantity. |
| TC-40 | Change quantity then proceed to checkout | 1. Set quantity to `3`. 2. Apply. 3. Go to checkout. | Checkout shows the item at quantity 3 with matching totals. |
