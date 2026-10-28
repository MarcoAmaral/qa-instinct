## CART-12: Change quantity of an item in the cart — Test Cases

### Assumptions

- The quantity control is a numeric input field; a +/– stepper may also exist. Where a stepper exists, the same rules apply to it (minimum 1, maximum 20, "Remove this item?" when stepping down from 1).
- The quantity is applied on blur, Enter, or an explicit "Update" action. Tests below say "submit the quantity" to cover whichever mechanism is implemented.
- The "Remove this item?" prompt has a confirm action (e.g. "Remove") and a cancel action (e.g. "Keep" / close / Escape).
- The "You can buy at most 20 of this item." message is shown inline near the quantity field and is dismissed once a valid quantity is entered.
- The maximum of 20 is a per-line-item limit, not a limit on the whole cart.
- Stock availability is out of scope for this story; the limit of 20 applies regardless of stock.
- The cart line subtotal and the cart total are recalculated whenever the quantity changes.
- The cart is persisted server-side for logged-in users and in the session for guests.
- Non-numeric characters are either blocked at input time or rejected on submit; test expectations accept either as long as the previous quantity is kept and no crash occurs.

### Preconditions (all tests)

- Shopper has a cart containing at least one item with quantity 2 and a known unit price, unless a test states otherwise.

---

### AC-1: Quantity field accepts whole numbers from 1 to 20

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-01 | Set quantity to minimum valid value | 1. Enter `1` in the quantity field. 2. Submit. | Quantity shows 1. Line subtotal = unit price × 1. Cart total updates. No message shown. |
| TC-02 | Set quantity to maximum valid value | 1. Enter `20`. 2. Submit. | Quantity shows 20. Line subtotal = unit price × 20. Cart total updates. No message shown. |
| TC-03 | Set quantity to a mid-range value | 1. Enter `7`. 2. Submit. | Quantity shows 7. Subtotal and total update correctly. |
| TC-04 | Increase quantity via stepper (if present) | 1. Click "+" once. | Quantity increments by 1 (2 → 3). Totals update. |
| TC-05 | Decrease quantity via stepper (if present) | 1. Click "–" once. | Quantity decrements by 1 (2 → 1). Totals update. |
| TC-06 | Stepper "+" at 20 (if present) | 1. Set quantity to 20. 2. Click "+". | Quantity stays 20. Either "+" is disabled or the AC-3 message is shown. No value of 21 is ever shown. |
| TC-07 | Same quantity resubmitted | 1. With quantity 2, enter `2`. 2. Submit. | No change; no error; no duplicate line item; totals unchanged. |
| TC-08 | Decimal value rejected | 1. Enter `2.5`. 2. Submit. | Value is not accepted (blocked at input or rejected on submit). Quantity remains 2. Clear validation feedback or no change. |
| TC-09 | Negative value rejected | 1. Enter `-1`. 2. Submit. | Value is not accepted. Quantity remains 2. No "Remove this item?" prompt. |
| TC-10 | Alphabetic / symbol input rejected | 1. Enter `abc`, then `1e2`, then `+5`, then `٣` (non-ASCII digit). 2. Submit each. | Each is rejected or sanitized; quantity remains 2; no script error. |
| TC-11 | Empty field submitted | 1. Clear the field. 2. Submit. | Field reverts to the previous quantity (2) or shows an inline validation message. Item is not removed. No quantity of 0 is applied. |
| TC-12 | Leading zeros | 1. Enter `007`. 2. Submit. | Interpreted as 7. Quantity shows 7. |
| TC-13 | Whitespace around value | 1. Enter ` 5 `. 2. Submit. | Interpreted as 5 (trimmed) or rejected; previous quantity kept if rejected. No crash. |
| TC-14 | Paste a valid value | 1. Paste `12` into the field. 2. Submit. | Quantity shows 12. Totals update. |
| TC-15 | Paste an invalid value | 1. Paste `12abc`. 2. Submit. | Rejected or sanitized; quantity remains 2. |
| TC-16 | Quantity persists after page reload | 1. Set quantity to 5 and submit. 2. Reload the page. | Quantity still shows 5. |
| TC-17 | Quantity persists across sessions (logged-in) | 1. Log in, set quantity to 5. 2. Log out and back in on another browser. | Cart shows quantity 5. |
| TC-18 | Changing quantity on one line does not affect other lines | 1. Cart has items A and B. 2. Change A to 4. | Only A changes. B's quantity and subtotal unchanged. Cart total reflects both correctly. |
| TC-19 | Keyboard operation | 1. Tab to the quantity field. 2. Type `3`, press Enter. | Quantity updates to 3 without using the mouse. Focus remains in a sensible place. |
| TC-20 | Screen reader semantics | 1. Inspect the quantity field with a screen reader / accessibility tree. | Field has an accessible label including the product name (e.g. "Quantity for <item>"), `min`/`max` or equivalent announced, validation messages announced. |
| TC-21 | Server-side enforcement of range | 1. Using the API or dev tools, submit quantity `21` and `0` directly, bypassing the UI. | Server rejects out-of-range values with an appropriate error; cart is unchanged. |
| TC-22 | Network failure during update | 1. Simulate request failure while submitting quantity 5. | User sees an error; displayed quantity reverts to or remains 2; totals are consistent with the stored cart. |

---

### AC-2: Setting the quantity to 0 prompts for removal

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-23 | Enter 0 shows prompt | 1. Enter `0`. 2. Submit. | Dialog with text "Remove this item?" appears, with confirm and cancel options. Item is still in the cart while the prompt is open. |
| TC-24 | Confirm removal | 1. Enter `0`, submit. 2. Confirm. | Item is removed from the cart. Cart total excludes the item. Cart item count decrements. |
| TC-25 | Cancel removal | 1. Enter `0`, submit. 2. Cancel. | Item remains in the cart with the previous quantity (2). Totals unchanged. Prompt closes. |
| TC-26 | Dismiss prompt via Escape / close icon / click outside | 1. Enter `0`, submit. 2. Press Escape (then repeat with close icon, then clicking outside if applicable). | Treated as cancel: item remains with quantity 2. |
| TC-27 | Stepper "–" from 1 (if present) | 1. Set quantity to 1. 2. Click "–". | "Remove this item?" prompt appears. Confirm removes; cancel keeps quantity 1. |
| TC-28 | Remove last item in cart | 1. Cart contains only one item. 2. Enter `0`, submit, confirm. | Item removed; empty-cart state is shown; total is 0. |
| TC-29 | Remove one of several items | 1. Cart has items A and B. 2. Set A to 0, confirm. | Only A removed. B unchanged. Total = B's subtotal. |
| TC-30 | Removal persists after reload | 1. Remove item via quantity 0 and confirm. 2. Reload. | Item is still gone. |
| TC-31 | Cancel then change to a valid quantity | 1. Enter `0`, submit, cancel. 2. Enter `3`, submit. | Quantity updates to 3 normally; no leftover prompt state. |
| TC-32 | Prompt text is exact | 1. Enter `0`, submit. | Dialog text reads exactly "Remove this item?" (check spelling, punctuation, and localisation key if applicable). |
| TC-33 | Prompt accessibility | 1. Enter `0`, submit. | Dialog receives focus, is announced as a dialog, focus is trapped inside, and focus returns to the quantity field on close. |
| TC-34 | Double-submit of confirm | 1. Enter `0`, submit. 2. Click confirm twice rapidly. | Item removed once; no error for "item not found"; cart state consistent. |
| TC-35 | Leading-zero zero | 1. Enter `00`. 2. Submit. | Treated as 0: "Remove this item?" prompt appears. |

---

### AC-3: Quantity above 20 shows a message and keeps the previous quantity

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-36 | Boundary: 21 | 1. Enter `21`. 2. Submit. | Message "You can buy at most 20 of this item." is shown. Quantity field and line reset to 2. Totals unchanged. |
| TC-37 | Large value | 1. Enter `999`. 2. Submit. | Same as TC-36. |
| TC-38 | Very large value | 1. Enter `99999999999999999999`. 2. Submit. | Same as TC-36; no overflow, no crash, no negative or wrapped value displayed. |
| TC-39 | Message text is exact | 1. Enter `21`, submit. | Message reads exactly "You can buy at most 20 of this item." (check spelling and punctuation). |
| TC-40 | Message clears after valid entry | 1. Enter `21`, submit (message shown). 2. Enter `10`, submit. | Message disappears. Quantity shows 10. Totals update. |
| TC-41 | Message does not persist after reload | 1. Enter `21`, submit. 2. Reload. | Quantity is 2; no message shown. |
| TC-42 | Previous quantity preserved when previous was the max | 1. Set quantity to 20, submit. 2. Enter `25`, submit. | Message shown; quantity remains 20. |
| TC-43 | Over-limit on one line does not affect others | 1. Cart has A (qty 2) and B (qty 3). 2. Set A to 21, submit. | Message shown on A only. A stays 2, B stays 3. Total unchanged. |
| TC-44 | Over-limit message is accessible | 1. Enter `21`, submit. | Message is associated with the field (e.g. `aria-describedby`) and announced by screen readers. |
| TC-45 | Server rejects over-limit | 1. Submit quantity `21` via API, bypassing UI. | Server rejects; cart unchanged. (Shared with TC-21; verify the error payload supports the UI message.) |
| TC-46 | Over-limit via stepper (if present) | 1. Set quantity to 20. 2. Click "+". | Either "+" is disabled at 20, or the message is shown and quantity remains 20. |
| TC-47 | Over-limit immediately followed by 0 | 1. Enter `21`, submit (message shown). 2. Enter `0`, submit. | Over-limit message clears; "Remove this item?" prompt appears. Cancel keeps quantity 2. |

---

### Cross-cutting / non-functional

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-48 | Mobile layout | 1. On a mobile viewport, change quantity to 5. | Numeric keypad is shown for the field (`inputmode="numeric"`). Controls are tappable; message and prompt are readable. |
| TC-49 | Rapid successive changes | 1. Quickly change quantity 2 → 5 → 8 → 3 before responses return. | Final displayed quantity and totals match the last submitted value (3). No out-of-order responses override the final state. |
| TC-50 | Concurrent sessions | 1. Logged in on two browsers. 2. Set quantity to 5 in browser A. 3. Refresh browser B. | Browser B shows 5. |
| TC-51 | Price recalculation accuracy | 1. Unit price 19.99. 2. Set quantity to 3, then 20. | Subtotals 59.97 and 399.80; no floating-point artefacts (e.g. 59.970000001). |
| TC-52 | Analytics / events (if applicable) | 1. Change quantity; remove via 0. | Corresponding cart-update and remove events fire once each with correct payload. |
| TC-53 | Localisation (if applicable) | 1. Switch site language. 2. Trigger both messages. | Messages are translated; numeric parsing still correct for the locale. |

---

### Open questions (assumptions applied, listed for the product owner)

1. Should the over-limit message appear immediately on typing or only on submit? (Assumed: on submit.)
2. Should an empty field be treated as 0 (prompt removal) or as invalid (revert)? (Assumed: invalid, revert.)
3. Should the 20-unit cap also consider stock levels when stock is lower than 20? (Assumed: out of scope.)
4. Is there a separate "Remove" button, and if so should it use the same confirmation prompt? (Assumed: out of scope for this story.)
