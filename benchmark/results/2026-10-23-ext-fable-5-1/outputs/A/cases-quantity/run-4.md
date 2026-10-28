## Test Cases — CART-12: Change the quantity of an item in the cart

### Assumptions

- A1: The quantity field is a numeric input with an immediate update on change (blur or Enter). If the UI has an explicit "Update" button, "submit" below means pressing that button.
- A2: The field is pre-populated with the item's current quantity. All tests start with one item in the cart at quantity 2 unless stated otherwise.
- A3: Non-integer, non-numeric, negative, and blank values are invalid. The story does not define their behavior; the expected result is that the previous quantity is kept and a validation message is shown. The exact wording is not specified and is not asserted.
- A4: Line subtotal and cart total recalculate after a successful quantity change.
- A5: "Remove this item?" is a modal with confirm and cancel actions. Closing the dialog by Escape or clicking outside is treated as cancel.
- A6: Stock availability is out of scope. The 20 cap is a hard limit independent of stock.
- A7: The limit message in AC-3 is shown inline next to the quantity field and is dismissed on the next valid change.

### Preconditions (all tests)

- Shopper is on the cart page.
- Cart contains item "Widget A" with quantity 2 and unit price 10.00.

---

### AC-1: Quantity field accepts whole numbers 1 to 20

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-01 | Set quantity to lower bound (1) | 1. Clear the field. 2. Enter `1`. 3. Submit. | Quantity shows 1. Line subtotal is 10.00. Cart total updates. No message shown. |
| TC-02 | Set quantity to upper bound (20) | 1. Clear the field. 2. Enter `20`. 3. Submit. | Quantity shows 20. Line subtotal is 200.00. No message shown. |
| TC-03 | Set quantity to a mid-range value (7) | 1. Clear the field. 2. Enter `7`. 3. Submit. | Quantity shows 7. Line subtotal is 70.00. |
| TC-04 | Increase quantity by one | 1. Change from 2 to 3. 2. Submit. | Quantity shows 3. Subtotal is 30.00. |
| TC-05 | Decrease quantity by one | 1. Change from 2 to 1. 2. Submit. | Quantity shows 1. Subtotal is 10.00. |
| TC-06 | Re-submit the same quantity | 1. Leave field at 2. 2. Submit. | Quantity stays 2. No error, no duplicate line item. |
| TC-07 | Change persists after page reload | 1. Set quantity to 5. 2. Submit. 3. Reload the page. | Quantity shows 5 after reload. |
| TC-08 | Change persists in a new session (logged-in shopper) | 1. Set quantity to 5. 2. Submit. 3. Log out and log in again. 4. Open cart. | Quantity shows 5. (Assumption A2 extends to server-side persistence for logged-in shoppers.) |
| TC-09 | Decimal value rejected | 1. Enter `2.5`. 2. Submit. | Quantity stays 2. Validation message shown (A3). |
| TC-10 | Negative value rejected | 1. Enter `-1`. 2. Submit. | Quantity stays 2. Validation message shown (A3). |
| TC-11 | Non-numeric value rejected | 1. Enter `abc`. 2. Submit. | Quantity stays 2. Validation message shown (A3), or input is blocked at keystroke level. |
| TC-12 | Blank value rejected | 1. Clear the field. 2. Submit. | Quantity stays 2. Validation message shown (A3). Item is not removed. |
| TC-13 | Leading zeros are normalized | 1. Enter `007`. 2. Submit. | Quantity shows 7. Subtotal is 70.00. |
| TC-14 | Surrounding whitespace is trimmed | 1. Enter ` 4 ` (with spaces). 2. Submit. | Quantity shows 4. |
| TC-15 | Scientific notation rejected | 1. Enter `1e1`. 2. Submit. | Quantity stays 2. Validation message shown (A3). |
| TC-16 | Changing one line does not affect other lines | Precondition: add "Widget B" at quantity 3. 1. Change Widget A to 6. 2. Submit. | Widget A shows 6. Widget B still shows 3. Cart total equals sum of both lines. |
| TC-17 | Field is keyboard-operable | 1. Tab to the quantity field. 2. Type `3`. 3. Press Enter. | Quantity shows 3. Focus remains in a sensible location (field or a confirmation region). |
| TC-18 | Field has an accessible label | Inspect the field with a screen reader or accessibility tree. | Field is announced with a label that identifies it as quantity for Widget A. |

---

### AC-2: Setting quantity to 0 prompts for removal

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-19 | Zero triggers removal prompt | 1. Enter `0`. 2. Submit. | Dialog appears with text "Remove this item?" and confirm and cancel actions. Item is still in the cart behind the dialog. |
| TC-20 | Confirm removes the item | 1. Enter `0`. 2. Submit. 3. Confirm. | Dialog closes. Widget A is removed from the cart. Cart total updates. |
| TC-21 | Cancel keeps the item at previous quantity | 1. Enter `0`. 2. Submit. 3. Cancel. | Dialog closes. Widget A remains with quantity 2. Subtotal is 20.00. |
| TC-22 | Escape key keeps the item | 1. Enter `0`. 2. Submit. 3. Press Escape. | Same as TC-21 (A5). |
| TC-23 | Clicking outside the dialog keeps the item | 1. Enter `0`. 2. Submit. 3. Click the page backdrop. | Same as TC-21 (A5). |
| TC-24 | Removing the only item leaves an empty cart | Precondition: cart has only Widget A. 1. Enter `0`. 2. Submit. 3. Confirm. | Cart shows its empty state. Cart total is 0.00. |
| TC-25 | Removing one of several items leaves the rest | Precondition: add Widget B at quantity 3. 1. Set Widget A to `0`. 2. Submit. 3. Confirm. | Widget A removed. Widget B still at 3. Cart total is Widget B's subtotal. |
| TC-26 | Leading zeros equal to zero trigger the prompt | 1. Enter `00`. 2. Submit. | "Remove this item?" dialog appears (value normalizes to 0). |
| TC-27 | Removal persists after reload | 1. Enter `0`. 2. Submit. 3. Confirm. 4. Reload. | Widget A is still absent. |
| TC-28 | Cancelled removal persists after reload | 1. Enter `0`. 2. Submit. 3. Cancel. 4. Reload. | Widget A shows quantity 2. |
| TC-29 | Dialog is focus-trapped and announced | 1. Enter `0`. 2. Submit. 3. Tab through the dialog. | Focus moves to the dialog on open and cycles within it. Dialog has an accessible role and the text "Remove this item?" is announced. |
| TC-30 | Dialog opened for the correct item | Precondition: add Widget B at quantity 3. 1. Set Widget B to `0`. 2. Submit. 3. Confirm. | Widget B is removed. Widget A is untouched. |

---

### AC-3: Quantity above 20 is rejected with a message

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-31 | 21 shows the limit message and keeps previous quantity | 1. Enter `21`. 2. Submit. | Message "You can buy at most 20 of this item." is shown. Quantity shows 2. Subtotal stays 20.00. |
| TC-32 | Large value (999) rejected | 1. Enter `999`. 2. Submit. | Same as TC-31. |
| TC-33 | Very large value rejected without error | 1. Enter `99999999999999999999`. 2. Submit. | Same as TC-31. No crash or unhandled error. |
| TC-34 | Previous quantity preserved when previous was 20 | Precondition: set quantity to 20 first. 1. Enter `25`. 2. Submit. | Message shown. Quantity shows 20. |
| TC-35 | Message clears after a valid change | 1. Enter `21`. 2. Submit. 3. Enter `5`. 4. Submit. | Message is gone. Quantity shows 5 (A7). |
| TC-36 | Message shown again on a repeat violation | 1. Enter `21`. 2. Submit. 3. Enter `30`. 4. Submit. | Message is shown once, not duplicated. Quantity still 2. |
| TC-37 | Rejection persists after reload | 1. Enter `21`. 2. Submit. 3. Reload. | Quantity shows 2. Nothing above 20 was saved. |
| TC-38 | Limit applies per line item | Precondition: add Widget B at quantity 3. 1. Set Widget A to `21`. 2. Submit. | Message is shown next to Widget A only. Widget B unaffected. |
| TC-39 | Message text matches exactly | 1. Enter `21`. 2. Submit. | Message text is exactly "You can buy at most 20 of this item." including the period. |
| TC-40 | Message is announced to assistive tech | 1. Enter `21`. 2. Submit. | Message is in an element with a live region or is associated with the field so a screen reader announces it. |
| TC-41 | Stepper cannot exceed 20 (if a stepper exists) | Precondition: set quantity to 20. 1. Click the increment control. | Quantity stays 20. Either the control is disabled or the limit message is shown. |

---

### Cross-cutting and non-functional

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-42 | Server rejects out-of-range quantity even if client validation is bypassed | 1. Send the update request directly with quantity 21. 2. Send with quantity -1. 3. Send with quantity 2.5. | Each request is rejected with a 4xx response. Cart quantity remains 2. |
| TC-43 | Server treats quantity 0 as removal only via the explicit removal path | 1. Send the update request directly with quantity 0. | Either the server rejects it or removes the item, consistently with the chosen API design. It must not store a line with quantity 0. |
| TC-44 | Rapid successive changes settle on the last value | 1. Change to 3, 4, 5 quickly without waiting for each response. | Final quantity shows 5. Subtotal is 50.00. No stale value overwrites the last one. |
| TC-45 | Network failure keeps previous quantity | 1. Simulate the update request failing. 2. Change quantity to 6. 3. Submit. | Quantity reverts to or stays at 2. An error is shown. No partial update. |
| TC-46 | Cart item count in header updates | 1. Change quantity from 2 to 5. 2. Submit. | Header cart badge reflects the new total item count. |
| TC-47 | Change works on a mobile viewport | 1. Open the cart at a 375px-wide viewport. 2. Change quantity to 3. 3. Submit. | Quantity updates. Field and message remain visible and readable. |
| TC-48 | Numeric keyboard on mobile | 1. Focus the quantity field on a touch device. | A numeric keypad is shown. |

### Traceability

| AC | Test cases |
|---|---|
| AC-1 | TC-01 to TC-18, TC-42, TC-44 to TC-48 |
| AC-2 | TC-19 to TC-30, TC-43 |
| AC-3 | TC-31 to TC-41, TC-42 |
