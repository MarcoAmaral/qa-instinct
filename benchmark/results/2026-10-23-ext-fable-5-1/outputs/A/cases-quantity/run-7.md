# Test Cases: CART-12 Change the quantity of an item in the cart

## Assumptions

- A-1: The quantity field is a numeric input with a visible value; changes are applied on blur, Enter, or an explicit Update control. Tests below say "submit" to mean whichever applies.
- A-2: When a quantity is rejected (AC-3) or a removal is cancelled (AC-2), the field reverts to the previous quantity and no cart update is sent to the server.
- A-3: Non-numeric, negative, decimal, and empty input are rejected and the previous quantity is kept. The story does not specify a message for these cases, so tests only check that the previous quantity is kept and no error state persists.
- A-4: The 20 limit is per line item, not per cart.
- A-5: The "Remove this item?" prompt has a confirm option and a cancel option, and can also be dismissed (Escape or clicking outside). Dismissal behaves like cancel.
- A-6: The line subtotal and cart total update after any accepted quantity change.
- A-7: Confirmed removal of the last item leaves an empty cart state.

## Preconditions (all tests)

- Shopper is on the cart page.
- Cart contains at least one item, referred to as Item A, with quantity 5 unless stated otherwise.
- Item A has at least 20 units in stock.

---

## AC-1: Quantity field accepts whole numbers 1 to 20

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-01 | Lower boundary: set quantity to 1 | 1. Enter `1` in Item A quantity. 2. Submit. | Quantity shows 1. Line subtotal and cart total reflect 1 unit. No message shown. |
| TC-02 | Upper boundary: set quantity to 20 | 1. Enter `20`. 2. Submit. | Quantity shows 20. Totals reflect 20 units. No message shown. |
| TC-03 | Mid-range value | 1. Enter `12`. 2. Submit. | Quantity shows 12. Totals reflect 12 units. |
| TC-04 | Increase quantity | Item A at 5. 1. Enter `7`. 2. Submit. | Quantity shows 7. Totals increase accordingly. |
| TC-05 | Decrease quantity | Item A at 5. 1. Enter `2`. 2. Submit. | Quantity shows 2. Totals decrease accordingly. |
| TC-06 | Same value resubmitted | Item A at 5. 1. Enter `5`. 2. Submit. | Quantity stays 5. No error, no duplicate line, totals unchanged. |
| TC-07 | Change persists after reload | 1. Enter `8`. 2. Submit. 3. Reload the cart page. | Quantity shows 8 after reload. |
| TC-08 | Change applies only to the targeted item | Cart has Item A (5) and Item B (3). 1. Change Item A to `9`. 2. Submit. | Item A shows 9. Item B still shows 3. |
| TC-09 | Decimal input rejected | 1. Enter `2.5`. 2. Submit. | Previous quantity 5 kept. Field does not show 2.5. (Per A-3.) |
| TC-10 | Negative input rejected | 1. Enter `-1`. 2. Submit. | Previous quantity 5 kept. No removal prompt shown. |
| TC-11 | Non-numeric input rejected | 1. Enter `abc`. 2. Submit. | Previous quantity 5 kept. |
| TC-12 | Empty input rejected | 1. Clear the field. 2. Submit. | Previous quantity 5 kept. Item is not removed, no removal prompt shown. |
| TC-13 | Leading zeros normalised | 1. Enter `007`. 2. Submit. | Quantity shows 7. Totals reflect 7 units. |
| TC-14 | Whitespace trimmed | 1. Enter ` 4 ` (with spaces). 2. Submit. | Quantity shows 4. |
| TC-15 | Keyboard entry via Enter key | 1. Type `6`. 2. Press Enter. | Quantity shows 6. Totals update. |

## AC-2: Quantity 0 prompts for removal

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-16 | Zero shows the removal prompt | 1. Enter `0`. 2. Submit. | A prompt with the exact text "Remove this item?" appears. Item A is still in the cart behind the prompt with quantity 5. |
| TC-17 | Confirm removes the item | 1. Enter `0`. 2. Submit. 3. Choose confirm. | Item A is removed from the cart. Cart total no longer includes Item A. |
| TC-18 | Cancel keeps the item | 1. Enter `0`. 2. Submit. 3. Choose cancel. | Prompt closes. Item A remains with quantity 5. Totals unchanged. |
| TC-19 | Dismissing the prompt keeps the item | 1. Enter `0`. 2. Submit. 3. Press Escape or click outside the prompt. | Prompt closes. Item A remains with quantity 5. (Per A-5.) |
| TC-20 | Removal persists after reload | 1. Complete TC-17. 2. Reload the cart page. | Item A is not present. |
| TC-21 | Cancel then re-enter zero prompts again | 1. Complete TC-18. 2. Enter `0` again. 3. Submit. | Prompt "Remove this item?" appears again. |
| TC-22 | Removing one of several items | Cart has Item A (5) and Item B (3). 1. Set Item A to `0`. 2. Confirm. | Item A removed. Item B still present with quantity 3. |
| TC-23 | Removing the last item | Cart has only Item A. 1. Set quantity to `0`. 2. Confirm. | Cart shows the empty cart state. (Per A-7.) |
| TC-24 | Zero entered as "00" | 1. Enter `00`. 2. Submit. | Treated as 0. Prompt "Remove this item?" appears. |
| TC-25 | No server update before confirmation | 1. Enter `0`. 2. Submit. 3. While prompt is open, reload page in another tab. | Item A still present with quantity 5 in the other tab. |

## AC-3: Quantity above 20 is rejected

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-26 | Boundary: 21 rejected | 1. Enter `21`. 2. Submit. | Message "You can buy at most 20 of this item." is shown. Quantity reverts to 5. Totals unchanged. |
| TC-27 | Large value rejected | 1. Enter `999`. 2. Submit. | Same message shown. Quantity reverts to 5. |
| TC-28 | Rejected value does not persist | 1. Complete TC-26. 2. Reload the cart page. | Quantity shows 5. |
| TC-29 | Previous quantity is the last accepted value | 1. Enter `15`. 2. Submit (accepted). 3. Enter `30`. 4. Submit. | Message shown. Quantity reverts to 15, not 5. |
| TC-30 | Message clears after a valid change | 1. Complete TC-26. 2. Enter `10`. 3. Submit. | Message is no longer shown. Quantity shows 10. |
| TC-31 | Message is per item | Cart has Item A (5) and Item B (3). 1. Set Item A to `25`. 2. Submit. | Message appears next to Item A only. Item B unchanged with no message. |
| TC-32 | 20 is accepted, 21 is not (adjacent boundary) | 1. Enter `20`, submit. 2. Enter `21`, submit. | Step 1 accepted with no message. Step 2 shows the message and reverts to 20. |
| TC-33 | Rejection does not trigger the removal prompt | 1. Enter `21`. 2. Submit. | Only the max message is shown. "Remove this item?" does not appear. |

## Cross-cutting and non-functional

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-34 | Accessibility: error message announced | Using a screen reader: 1. Enter `21`. 2. Submit. | The message "You can buy at most 20 of this item." is announced and is associated with the quantity field. |
| TC-35 | Accessibility: removal prompt is keyboard operable | 1. Enter `0`. 2. Submit. 3. Use Tab and Enter only. | Focus moves into the prompt. Confirm and cancel are both reachable and operable by keyboard. Focus returns to the quantity field after closing. |
| TC-36 | Rapid repeated changes | 1. Quickly enter `3`, submit, `4`, submit, `5`, submit. | Final quantity shows 5. Totals match 5 units. No stale value overwrites the last one. |
| TC-37 | Server-side validation | Using the cart API directly (bypassing the UI): 1. Send an update with quantity `21`. 2. Send quantity `0`. 3. Send quantity `-1`. | Each request is rejected with a validation error. Cart quantity remains unchanged. |
| TC-38 | Mobile numeric keyboard | On a mobile device: 1. Tap the quantity field. | A numeric keyboard is shown. |

## Traceability

| Acceptance criterion | Test cases |
|---|---|
| AC-1 | TC-01 to TC-15, TC-36, TC-37, TC-38 |
| AC-2 | TC-16 to TC-25, TC-33, TC-35, TC-37 |
| AC-3 | TC-26 to TC-34, TC-37 |
