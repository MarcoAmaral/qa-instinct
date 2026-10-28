# Test Cases: CART-12 Change the quantity of an item in the cart

## Assumptions

- A-1: The quantity control is a numeric text input with "+" and "−" stepper buttons. Changes are applied when the field loses focus, Enter is pressed, or a stepper button is clicked.
- A-2: "Previous quantity" in AC-3 means the last successfully saved quantity for that line item.
- A-3: The "Remove this item?" prompt is a modal dialog with "Remove" and "Cancel" actions. Closing the dialog by Escape, overlay click, or the X button counts as Cancel.
- A-4: Non-numeric or non-whole input (letters, decimals, negatives, blank) is rejected and the previous quantity is restored. No specific message text is defined for these cases, so tests only assert that the quantity is unchanged and a validation state is shown.
- A-5: Changing a quantity updates the line subtotal, cart total, and header cart badge immediately after the change is accepted.
- A-6: The cart persists per session for guests and per account for signed-in shoppers.
- A-7: The 20-unit limit applies per line item, not across the whole cart.
- A-8: Stock limits below 20 are out of scope for this story and are not tested here.

## Common preconditions

- Shopper is on the cart page.
- Cart contains at least one item, "Item A", with quantity 5 unless stated otherwise.

---

## AC-1: Quantity field accepts whole numbers 1 to 20

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-01 | Lower boundary: set quantity to 1 | 1. Clear the field. 2. Type `1`. 3. Press Enter. | Quantity saves as 1. Line subtotal, cart total, and cart badge reflect 1. No error shown. |
| TC-02 | Upper boundary: set quantity to 20 | 1. Clear the field. 2. Type `20`. 3. Press Enter. | Quantity saves as 20. Totals and badge update. No error shown. |
| TC-03 | Mid-range value | 1. Clear the field. 2. Type `13`. 3. Press Enter. | Quantity saves as 13. Totals and badge update. |
| TC-04 | Commit on blur | 1. Clear the field. 2. Type `7`. 3. Click elsewhere on the page. | Quantity saves as 7. Totals update without pressing Enter. |
| TC-05 | Stepper "+" increments by 1 | 1. Click "+" once. | Quantity becomes 6. Totals update. |
| TC-06 | Stepper "−" decrements by 1 | 1. Click "−" once. | Quantity becomes 4. Totals update. |
| TC-07 | Stepper "+" at upper boundary | Precondition: quantity is 20. 1. Click "+". | Quantity stays 20. Either the "+" button is disabled or the AC-3 message is shown. No change to totals. |
| TC-08 | Stepper "−" at lower boundary | Precondition: quantity is 1. 1. Click "−". | Quantity goes to 0 and the AC-2 "Remove this item?" prompt appears (see TC-20). |
| TC-09 | Same value re-entered | 1. Clear the field. 2. Type `5`. 3. Press Enter. | Quantity remains 5. No error, no duplicate request or flicker in totals. |
| TC-10 | Decimal value rejected | 1. Clear the field. 2. Type `2.5`. 3. Press Enter. | Value is rejected. Quantity reverts to 5. Field shows a validation state. Totals unchanged. |
| TC-11 | Negative value rejected | 1. Clear the field. 2. Type `-3`. 3. Press Enter. | Value is rejected. Quantity reverts to 5. Totals unchanged. No removal prompt shown. |
| TC-12 | Alphabetic input rejected | 1. Clear the field. 2. Type `abc`. 3. Press Enter. | Value is rejected or characters are not accepted at all. Quantity reverts to 5. |
| TC-13 | Mixed input rejected | 1. Clear the field. 2. Type `1e1`. 3. Press Enter. | Value is rejected. Quantity reverts to 5. (Guards against scientific notation being parsed as 10.) |
| TC-14 | Blank field rejected | 1. Clear the field. 2. Press Enter. | Quantity reverts to 5. Field shows a validation state. No removal prompt shown. |
| TC-15 | Whitespace-only input rejected | 1. Clear the field. 2. Type three spaces. 3. Press Enter. | Treated as blank. Quantity reverts to 5. |
| TC-16 | Leading zeros normalised | 1. Clear the field. 2. Type `007`. 3. Press Enter. | Quantity saves and displays as 7. |
| TC-17 | Leading and trailing spaces trimmed | 1. Clear the field. 2. Type ` 8 `. 3. Press Enter. | Quantity saves as 8. |
| TC-18 | Pasted valid value | 1. Copy `12` to clipboard. 2. Clear the field. 3. Paste. 4. Press Enter. | Quantity saves as 12. |
| TC-19 | Pasted invalid value | 1. Copy `12abc` to clipboard. 2. Clear the field. 3. Paste. 4. Press Enter. | Value is rejected. Quantity reverts to 5. |

---

## AC-2: Quantity 0 asks "Remove this item?" and removes only on confirmation

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-20 | Typing 0 shows the prompt | 1. Clear the field. 2. Type `0`. 3. Press Enter. | Dialog appears with the exact text "Remove this item?" and Remove/Cancel actions. Item is still in the cart behind the dialog. Totals unchanged. |
| TC-21 | Confirm removal | 1. Perform TC-20. 2. Click "Remove". | Item A is removed from the cart. Cart total and badge update. Dialog closes. |
| TC-22 | Cancel removal | 1. Perform TC-20. 2. Click "Cancel". | Dialog closes. Item A remains with quantity 5. Totals unchanged. |
| TC-23 | Dismiss with Escape | 1. Perform TC-20. 2. Press Escape. | Same as Cancel. Item remains with quantity 5. |
| TC-24 | Dismiss by clicking overlay | 1. Perform TC-20. 2. Click outside the dialog. | Same as Cancel. Item remains with quantity 5. |
| TC-25 | Dismiss by closing the tab | 1. Perform TC-20. 2. Close the tab. 3. Reopen the cart page. | Item A is still in the cart with quantity 5. Removal was not applied. |
| TC-26 | Stepper to 0 shows the prompt | Precondition: quantity is 1. 1. Click "−". | Dialog "Remove this item?" appears. Item still present. |
| TC-27 | Stepper to 0 then cancel | 1. Perform TC-26. 2. Click "Cancel". | Quantity shows 1, not 0. |
| TC-28 | Remove last item in cart | Precondition: cart contains only Item A. 1. Set quantity to 0 and confirm. | Cart shows the empty-cart state. Badge shows 0 or is hidden. Checkout is disabled or hidden. |
| TC-29 | Remove one of several items | Precondition: cart has Item A and Item B. 1. Set Item A to 0 and confirm. | Only Item A is removed. Item B and its quantity are untouched. Total equals Item B's subtotal. |
| TC-30 | Removal does not affect duplicate SKU in another variant | Precondition: cart has Item A size M and Item A size L. 1. Set size M to 0 and confirm. | Only size M line is removed. Size L remains. |
| TC-31 | Leading-zero form of 0 | 1. Clear the field. 2. Type `00`. 3. Press Enter. | Treated as 0. Prompt appears. |
| TC-32 | Double-click on Remove | 1. Perform TC-20. 2. Double-click "Remove" quickly. | Item is removed exactly once. No error from a second removal request. |
| TC-33 | Prompt text and focus | 1. Perform TC-20. | Dialog receives keyboard focus. Tab cycles only within the dialog. Screen reader announces "Remove this item?". |

---

## AC-3: Quantity above 20 shows message and keeps previous quantity

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-40 | Boundary: 21 rejected | 1. Clear the field. 2. Type `21`. 3. Press Enter. | Message "You can buy at most 20 of this item." is shown. Field shows 5. Totals unchanged. |
| TC-41 | Large value rejected | 1. Clear the field. 2. Type `999`. 3. Press Enter. | Same as TC-40. Quantity remains 5. |
| TC-42 | Very large value rejected | 1. Clear the field. 2. Type `99999999999999999999`. 3. Press Enter. | Same as TC-40. No crash, no overflow to a negative or wrapped value. |
| TC-43 | Rejected on blur | 1. Clear the field. 2. Type `25`. 3. Click elsewhere. | Message shown. Quantity remains 5. |
| TC-44 | Previous quantity is the last saved value | 1. Set quantity to 12 and press Enter. 2. Clear the field. 3. Type `30`. 4. Press Enter. | Message shown. Quantity reverts to 12, not 5. |
| TC-45 | Message clears after valid entry | 1. Perform TC-40. 2. Clear the field. 3. Type `10`. 4. Press Enter. | Message disappears. Quantity saves as 10. |
| TC-46 | Message is per line item | Precondition: cart has Item A and Item B. 1. Enter `21` for Item A. | Message appears next to Item A only. Item B shows no message. |
| TC-47 | Exact message text | 1. Perform TC-40. | Text matches exactly, including the full stop: `You can buy at most 20 of this item.` |
| TC-48 | Pasted value above 20 | 1. Copy `50`. 2. Clear the field. 3. Paste. 4. Press Enter. | Message shown. Quantity remains 5. |
| TC-49 | Repeated "+" clicks past 20 | Precondition: quantity is 18. 1. Click "+" five times. | Quantity stops at 20. Either "+" becomes disabled at 20 or the message is shown on the third click. Quantity never exceeds 20. |
| TC-50 | Message accessibility | 1. Perform TC-40. | Message is announced by screen readers (live region or associated with the field via aria-describedby). Field is marked invalid. |

---

## Cross-cutting and integration

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-60 | Totals recalculate correctly | Precondition: Item A unit price 10.00, quantity 5. 1. Set quantity to 8. | Line subtotal shows 80.00. Cart total and any tax or shipping lines recalculate. Badge shows 8 (plus other items). |
| TC-61 | Persistence after reload | 1. Set quantity to 9. 2. Reload the page. | Quantity still 9. |
| TC-62 | Persistence for signed-in shopper across devices | 1. Signed in, set quantity to 9. 2. Open the cart in another browser signed in as the same account. | Quantity is 9. |
| TC-63 | Server-side enforcement of upper limit | 1. Using browser dev tools or an API client, submit a quantity update of 21 directly to the cart endpoint. | Server rejects the request. Cart still shows 5. |
| TC-64 | Server-side enforcement of lower limit | 1. Submit a quantity update of -1 or 0 directly to the cart endpoint without confirmation. | Server rejects the request. Item is not removed. |
| TC-65 | Update fails due to network error | 1. Go offline. 2. Set quantity to 9. 3. Press Enter. | An error message is shown. Field reverts to 5 or clearly marks the change as unsaved. No silent failure. |
| TC-66 | Rapid successive changes | 1. Quickly type `3`, Enter, `15`, Enter, `6`, Enter. | Final saved quantity is 6. No stale response overwrites it. |
| TC-67 | Keyboard-only operation | 1. Tab to the quantity field. 2. Type `4`. 3. Press Enter. 4. Tab to "+" and press Space. | Quantity ends at 5. All controls reachable and operable by keyboard with visible focus. |
| TC-68 | Arrow keys in field | 1. Focus the field. 2. Press Up arrow twice. | Quantity becomes 7 if arrow stepping is supported. If not supported, value is unchanged and no error occurs. |
| TC-69 | Mobile numeric keyboard | 1. On a mobile device, tap the field. | A numeric keypad is shown (inputmode numeric). |
| TC-70 | Mobile layout | 1. On a 360px-wide viewport, view the cart. | Field, steppers, and the AC-3 message are fully visible and not clipped. |
| TC-71 | Cross-browser | Run TC-01, TC-20, TC-40 in Chrome, Firefox, Safari, and Edge. | Behaviour identical in all browsers. |
| TC-72 | Quantity change on mini-cart or drawer | If a mini-cart exposes a quantity control: 1. Repeat TC-02, TC-20, TC-40 there. | Same behaviour as the full cart page. |
| TC-73 | Checkout reflects latest quantity | 1. Set quantity to 11. 2. Proceed to checkout. | Checkout summary shows 11 for Item A. |

---

## Traceability

| AC | Test cases |
|---|---|
| AC-1 | TC-01 to TC-19, TC-60 to TC-73 |
| AC-2 | TC-08, TC-20 to TC-33, TC-64 |
| AC-3 | TC-07, TC-40 to TC-50, TC-63 |

## Open questions for the product owner

These do not block testing. Assumptions above apply until answered.

1. What message, if any, should be shown for non-numeric, decimal, or blank input (TC-10 to TC-15)?
2. Should the "+" button be disabled at 20, or should clicking it show the AC-3 message (TC-07, TC-49)?
3. Should stepping "−" from 1 trigger the removal prompt, or should "−" be disabled at 1 (TC-08, TC-26)?
4. Does the 20-unit limit interact with product stock levels lower than 20?
