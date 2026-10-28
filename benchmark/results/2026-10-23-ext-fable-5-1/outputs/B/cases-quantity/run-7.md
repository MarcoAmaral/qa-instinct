# Test Cases — CART-12: Change the quantity of an item in the cart

## Scope and assumptions

The story does not specify the UI, so these assumptions apply to every case below. Each is marked where it drives an expected result.

- **A1.** The cart page shows a numeric quantity field per line item. Changes commit on blur, Enter, or a stepper click. If the real UI has an explicit "Update" button, read "commit" as pressing it.
- **A2.** The line subtotal and cart total recalculate after a committed quantity change.
- **A3.** The "Remove this item?" prompt has a confirm action ("Remove") and a cancel action ("Cancel"). Cancelling restores the previous quantity.
- **A4.** Non-numeric, decimal, negative, and empty input are invalid. The field reverts to the previous quantity, and either shows a validation message or blocks the keystroke. Exact wording is not specified, so the cases check for "quantity unchanged" rather than a specific message.
- **A5.** The 20-item cap applies per line item, not per cart. Stock availability limits are out of scope.
- **A6.** The field has a visible label and the error message is announced to assistive technology. Exact ARIA wiring is unspecified.
- **A7.** Committed quantities persist across page reload for the same session or account.

## Test data

| Item | Starting quantity | Unit price | Notes |
|---|---|---|---|
| Item A | 3 | 10.00 | Primary item for most cases |
| Item B | 1 | 25.00 | Used for multi-item isolation |

---

## AC-1: Quantity field accepts whole numbers 1 to 20

| ID | Title | Preconditions | Steps | Expected result | Priority |
|---|---|---|---|---|---|
| TC-01 | Change quantity to a mid-range value | Cart contains Item A ×3 | 1. Set Item A quantity to 7. 2. Commit. | Field shows 7. Line subtotal is 70.00. Cart total updates accordingly (A2). No error shown. | High |
| TC-02 | Lower boundary: quantity 1 | Cart contains Item A ×3 | 1. Set quantity to 1. 2. Commit. | Field shows 1. Subtotal is 10.00. No removal prompt appears. No error. | High |
| TC-03 | Upper boundary: quantity 20 | Cart contains Item A ×3 | 1. Set quantity to 20. 2. Commit. | Field shows 20. Subtotal is 200.00. No error shown. | High |
| TC-04 | Just below upper boundary: quantity 19 | Cart contains Item A ×3 | 1. Set quantity to 19. 2. Commit. | Field shows 19. Subtotal is 190.00. No error. | Medium |
| TC-05 | Just above lower boundary: quantity 2 | Cart contains Item A ×3 | 1. Set quantity to 2. 2. Commit. | Field shows 2. Subtotal is 20.00. No error. | Medium |
| TC-06 | Increase via stepper | Cart contains Item A ×3. UI has +/- steppers (A1). | 1. Click + once. | Field shows 4. Subtotal is 40.00. | Medium |
| TC-07 | Decrease via stepper to 1 | Cart contains Item A ×2 | 1. Click − once. | Field shows 1. No removal prompt. | Medium |
| TC-08 | Stepper at upper limit | Cart contains Item A ×20 | 1. Click + once. | Quantity stays 20. Message "You can buy at most 20 of this item." shown, or + control is disabled. Either outcome is acceptable, but record which. | Medium |
| TC-09 | Re-enter the same quantity | Cart contains Item A ×3 | 1. Set quantity to 3. 2. Commit. | No change, no error, totals unchanged. No duplicate network request is required, but if one is sent it must be harmless. | Low |
| TC-10 | Leading zeros | Cart contains Item A ×3 | 1. Type `05`. 2. Commit. | Treated as 5. Field normalises to 5. Subtotal is 50.00. | Low |
| TC-11 | Surrounding whitespace | Cart contains Item A ×3 | 1. Type ` 6 ` (with spaces). 2. Commit. | Treated as 6, or whitespace is blocked from entry. Quantity must not revert to 3 without a visible reason. | Low |
| TC-12 | Decimal input rejected | Cart contains Item A ×3 | 1. Type `2.5`. 2. Commit. | Quantity remains 3 (A4). Decimal is not silently rounded to 2 or 3. A validation message is shown, or the `.` keystroke is blocked. | High |
| TC-13 | Negative input rejected | Cart contains Item A ×3 | 1. Type `-1`. 2. Commit. | Quantity remains 3 (A4). No removal prompt. | High |
| TC-14 | Non-numeric input rejected | Cart contains Item A ×3 | 1. Type `abc`. 2. Commit. | Quantity remains 3 (A4). | High |
| TC-15 | Empty field rejected | Cart contains Item A ×3 | 1. Clear the field. 2. Commit. | Quantity remains 3 (A4). Field is not left blank. Item is not removed and no removal prompt appears. | High |
| TC-16 | Pasted invalid value | Cart contains Item A ×3 | 1. Paste `1e2` into the field. 2. Commit. | Quantity remains 3. Value is not interpreted as 100. | Medium |
| TC-17 | Change is isolated to one line item | Cart contains Item A ×3 and Item B ×1 | 1. Set Item A to 8. 2. Commit. | Item A shows 8. Item B still shows 1. Cart total is 105.00. | High |
| TC-18 | Quantity persists after reload | Cart contains Item A ×3 | 1. Set quantity to 9. 2. Commit. 3. Reload the page. | Item A shows 9 (A7). | High |
| TC-19 | Keyboard-only operation | Cart contains Item A ×3 | 1. Tab to the quantity field. 2. Type 4. 3. Press Enter. | Quantity commits to 4 without using a mouse. Focus stays on or near the field. | Medium |
| TC-20 | Field label and error are accessible | Cart contains Item A ×3 | 1. Inspect the field with a screen reader. 2. Trigger the over-limit error (see TC-27). | Field has an accessible name that identifies the item. Error text is announced (A6). | Medium |

---

## AC-2: Quantity 0 prompts "Remove this item?" and removes only on confirm

| ID | Title | Preconditions | Steps | Expected result | Priority |
|---|---|---|---|---|---|
| TC-21 | Set quantity to 0 shows prompt | Cart contains Item A ×3 | 1. Set quantity to 0. 2. Commit. | A prompt with the exact text "Remove this item?" appears. Item A is still in the cart behind the prompt. Totals are unchanged. | High |
| TC-22 | Confirm removal | Cart contains Item A ×3 and Item B ×1 | 1. Set Item A to 0. 2. Commit. 3. Confirm. | Item A is removed from the cart. Item B remains ×1. Cart total is 25.00. | High |
| TC-23 | Cancel removal | Cart contains Item A ×3 | 1. Set Item A to 0. 2. Commit. 3. Cancel. | Item A remains in the cart. Quantity field shows 3 (A3), not 0. Totals unchanged. | High |
| TC-24 | Dismiss prompt without choosing | Cart contains Item A ×3 | 1. Set Item A to 0. 2. Commit. 3. Press Escape or click outside the prompt. | Treated as cancel. Item A remains with quantity 3. | High |
| TC-25 | Removal persists after reload | Cart contains Item A ×3 | 1. Set to 0, commit, confirm. 2. Reload. | Item A is not in the cart. | Medium |
| TC-26 | Cancel persists after reload | Cart contains Item A ×3 | 1. Set to 0, commit, cancel. 2. Reload. | Item A is in the cart with quantity 3. | Medium |
| TC-27 | Stepper down from 1 | Cart contains Item A ×1 | 1. Click − once. | Prompt "Remove this item?" appears, or the − control is disabled at 1. Item is not removed without confirmation. Record which behaviour is implemented. | Medium |
| TC-28 | Remove the last item in the cart | Cart contains only Item A ×1 | 1. Set to 0, commit, confirm. | Cart shows its empty state. Total is 0.00. No error. | High |
| TC-29 | Leading zeros on zero | Cart contains Item A ×3 | 1. Type `00`. 2. Commit. | Treated as 0. Prompt appears. | Low |
| TC-30 | Prompt refers to the right item | Cart contains Item A ×3 and Item B ×1 | 1. Set Item B to 0. 2. Commit. 3. Confirm. | Item B is removed. Item A remains ×3. If the prompt names the item, it names Item B. | High |
| TC-31 | Prompt is keyboard accessible | Cart contains Item A ×3 | 1. Set to 0 and commit via keyboard. 2. Tab through the prompt. | Focus moves into the prompt. Both actions are reachable and operable by keyboard. Focus returns to the field or the cart after closing. | Medium |

---

## AC-3: Quantity above 20 shows an error and keeps the previous quantity

| ID | Title | Preconditions | Steps | Expected result | Priority |
|---|---|---|---|---|---|
| TC-32 | Just above limit: 21 | Cart contains Item A ×3 | 1. Set quantity to 21. 2. Commit. | Message with exact text "You can buy at most 20 of this item." is shown. Field shows 3. Subtotal is 30.00. | High |
| TC-33 | Large value: 999 | Cart contains Item A ×3 | 1. Set quantity to 999. 2. Commit. | Same message. Field shows 3. | High |
| TC-34 | Very large value | Cart contains Item A ×3 | 1. Paste `99999999999999999999`. 2. Commit. | Same message, or input is truncated by a max length. No crash, no overflow to a negative or wrapped number. Field shows 3. | Medium |
| TC-35 | Error does not persist after a valid correction | Cart contains Item A ×3 | 1. Set to 21, commit. 2. Set to 10, commit. | Error message disappears. Field shows 10. Subtotal is 100.00. | High |
| TC-36 | Previous quantity is the last committed value | Cart contains Item A ×3 | 1. Set to 15, commit. 2. Set to 25, commit. | Message shown. Field reverts to 15, not 3. | High |
| TC-37 | Over-limit on one item does not affect another | Cart contains Item A ×3 and Item B ×1 | 1. Set Item A to 30. 2. Commit. | Error shown against Item A only. Item B unchanged. Cart total unchanged. | Medium |
| TC-38 | Over-limit via stepper | Cart contains Item A ×20 | Same as TC-08. | Cross-reference TC-08. | Medium |
| TC-39 | Over-limit value not persisted | Cart contains Item A ×3 | 1. Set to 21, commit. 2. Reload. | Field shows 3. | Medium |
| TC-40 | Error message is announced | Cart contains Item A ×3 | 1. Set to 21 with a screen reader active. 2. Commit. | Message text is read aloud (A6). | Medium |

---

## Cross-cutting and negative cases

| ID | Title | Preconditions | Steps | Expected result | Priority |
|---|---|---|---|---|---|
| TC-41 | Server-side validation for over-limit | API access to the cart update endpoint | 1. Send an update request with quantity 21, bypassing the UI. | Request is rejected with a 4xx response. Stored quantity is unchanged. | High |
| TC-42 | Server-side validation for zero without confirmation | API access | 1. Send an update request with quantity 0. | Either the server removes the item (confirmation is UI-only) or rejects it. Record and confirm against product intent. Item must not end up with a stored quantity of 0. | High |
| TC-43 | Server-side validation for negatives and decimals | API access | 1. Send quantity -1. 2. Send quantity 2.5. 3. Send quantity "abc". | All rejected with 4xx. Stored quantity unchanged. | High |
| TC-44 | Network failure during update | Cart contains Item A ×3. Network can be interrupted. | 1. Set to 7. 2. Commit while offline. | User sees an error. Field reverts to 3, or shows a clear pending state that resolves on retry. No silent mismatch between UI and server. | Medium |
| TC-45 | Rapid successive changes | Cart contains Item A ×3 | 1. Quickly set 5, 6, 7, committing each. | Final state is 7 in the UI and on the server after reload. No stale response overwrites the last value. | Medium |
| TC-46 | Same cart in two tabs | Cart contains Item A ×3, open in tabs 1 and 2 | 1. In tab 1, set to 8 and commit. 2. In tab 2, set to 12 and commit. 3. Reload both. | Both tabs show the same quantity after reload. Document which value wins. No duplicate line items. | Low |
| TC-47 | Browser autocomplete or form restore | Cart contains Item A ×3 | 1. Set to 21 (do not commit). 2. Navigate away and back with browser history. | Field shows the committed value 3, not a restored 21. | Low |
| TC-48 | Field is a numeric input on mobile | Mobile device or emulator | 1. Focus the quantity field. | Numeric keypad is shown. | Low |

---

## Traceability

| AC | Covered by |
|---|---|
| AC-1 | TC-01 to TC-20, TC-43, TC-45 |
| AC-2 | TC-21 to TC-31, TC-42 |
| AC-3 | TC-08, TC-32 to TC-41 |

## Open points for the product owner

These do not block testing but each assumption above should be confirmed.

- Whether invalid input (decimal, negative, text, empty) shows a message or is blocked at keystroke level, and the wording if shown.
- Whether the stepper at 1 opens the removal prompt or is disabled.
- Whether the server removes an item on quantity 0 without a UI confirmation step.
- Whether the 20 cap is a global constant or can vary per item. If per item, TC-32 to TC-36 need a per-item variant.
