## Test Cases: CART-12 — Change the quantity of an item in the cart

### Assumptions

- A1: The quantity field is a numeric input in the cart line item, with a visible current value, and changes are applied on blur or on pressing Enter (no separate "Update" button). If an "Update" button exists, read "apply the change" as clicking it.
- A2: Non-numeric, negative, decimal, and blank input is rejected and the previous quantity is kept. The story does not specify a message for these cases, so the tests only assert that the quantity is unchanged and no item is removed.
- A3: The "Remove this item?" prompt offers a confirm action ("Remove") and a cancel action ("Cancel" or closing the dialog). Declining restores the previous quantity.
- A4: The line subtotal and cart total recalculate after a successful quantity change.
- A5: Stock availability is out of scope for this story; the 1–20 limit is the only upper bound tested.
- A6: A shopper is logged in or has a guest cart, and the cart contains at least one item with quantity 1 unless stated otherwise.

### Preconditions (all tests)

- The shopper is on the cart page.
- The cart contains item "Widget A" at unit price 10.00 with quantity 1, unless the test says otherwise.

---

### AC-1: The quantity field accepts whole numbers from 1 to 20

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-01 | Increase quantity to a value within range | 1. Set the quantity of Widget A to 5.<br>2. Apply the change. | Quantity shows 5. Line subtotal shows 50.00. Cart total updates accordingly. No message is shown. |
| TC-02 | Lower boundary: quantity 1 | 1. Start with Widget A at quantity 3.<br>2. Set quantity to 1.<br>3. Apply the change. | Quantity shows 1. Line subtotal shows 10.00. Item remains in the cart. No prompt or message is shown. |
| TC-03 | Upper boundary: quantity 20 | 1. Set quantity to 20.<br>2. Apply the change. | Quantity shows 20. Line subtotal shows 200.00. No message is shown. |
| TC-04 | Decrease quantity within range | 1. Start with Widget A at quantity 10.<br>2. Set quantity to 4.<br>3. Apply the change. | Quantity shows 4. Line subtotal shows 40.00. |
| TC-05 | Re-enter the same quantity | 1. Start with Widget A at quantity 7.<br>2. Set quantity to 7.<br>3. Apply the change. | Quantity remains 7. No message is shown. Cart total unchanged. |
| TC-06 | Change persists after page reload | 1. Set quantity to 6 and apply.<br>2. Reload the cart page. | Quantity still shows 6. Line subtotal shows 60.00. |
| TC-07 | Decimal value is rejected (A2) | 1. Enter 2.5 in the quantity field.<br>2. Apply the change. | Quantity reverts to 1. Item remains in the cart. No "Remove this item?" prompt is shown. |
| TC-08 | Negative value is rejected (A2) | 1. Enter -1.<br>2. Apply the change. | Quantity reverts to 1. Item remains in the cart. No prompt is shown. |
| TC-09 | Non-numeric value is rejected (A2) | 1. Enter "abc".<br>2. Apply the change. | Quantity reverts to 1. Item remains in the cart. |
| TC-10 | Blank value is rejected (A2) | 1. Clear the quantity field.<br>2. Apply the change. | Quantity reverts to 1. Item is not removed and no prompt is shown. |
| TC-11 | Leading zeros are normalised | 1. Enter 05.<br>2. Apply the change. | Quantity shows 5. Line subtotal shows 50.00. |
| TC-12 | Changing one item does not affect others | 1. Add "Widget B" at quantity 2.<br>2. Set Widget A quantity to 8 and apply. | Widget A shows 8. Widget B still shows 2. Cart total equals the sum of both line subtotals. |

### AC-2: Setting quantity to 0 prompts for removal

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-13 | Quantity 0 shows the removal prompt | 1. Set quantity to 0.<br>2. Apply the change. | A prompt with the exact text "Remove this item?" appears. Widget A is still in the cart while the prompt is open. |
| TC-14 | Confirming removes the item | 1. Set quantity to 0 and apply.<br>2. Confirm the prompt. | Widget A is removed from the cart. Cart total no longer includes it. Item count decreases by one. |
| TC-15 | Cancelling keeps the item and restores the previous quantity | 1. Start with Widget A at quantity 3.<br>2. Set quantity to 0 and apply.<br>3. Cancel the prompt. | Widget A remains in the cart. Quantity shows 3. Line subtotal shows 30.00. |
| TC-16 | Dismissing the prompt (close / Escape) behaves as cancel | 1. Set quantity to 0 and apply.<br>2. Close the prompt without choosing an option (Escape key or close control). | Widget A remains in the cart with its previous quantity. |
| TC-17 | Removal of one item leaves other items untouched | 1. Add Widget B at quantity 2.<br>2. Set Widget A to 0, apply, and confirm. | Widget A is removed. Widget B remains at quantity 2. Cart total equals Widget B subtotal. |
| TC-18 | Removing the last item leaves an empty cart | 1. Ensure Widget A is the only item.<br>2. Set quantity to 0, apply, and confirm. | The cart shows its empty state. Cart total is 0.00. |
| TC-19 | Removal persists after reload | 1. Set quantity to 0, apply, and confirm.<br>2. Reload the cart page. | Widget A does not reappear. |
| TC-20 | Cancelled removal persists after reload | 1. Start at quantity 3. Set 0, apply, cancel.<br>2. Reload the cart page. | Widget A shows quantity 3. |
| TC-21 | Entering 00 is treated as 0 | 1. Enter 00.<br>2. Apply the change. | The "Remove this item?" prompt appears. |

### AC-3: Quantity above 20 is rejected with a message

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-22 | Boundary: quantity 21 is rejected | 1. Start with Widget A at quantity 5.<br>2. Set quantity to 21.<br>3. Apply the change. | Message with the exact text "You can buy at most 20 of this item." is shown. Quantity shows 5. Line subtotal shows 50.00. |
| TC-23 | Large value is rejected | 1. Start at quantity 5.<br>2. Set quantity to 999.<br>3. Apply the change. | Same message is shown. Quantity remains 5. |
| TC-24 | Previous quantity kept is the last applied value, not the typed one | 1. Set quantity to 12 and apply (accepted).<br>2. Set quantity to 25 and apply. | Message is shown. Quantity shows 12, not 1 and not 25. |
| TC-25 | Rejected value is not persisted | 1. Start at quantity 5.<br>2. Set 30 and apply (rejected).<br>3. Reload the cart page. | Quantity shows 5. |
| TC-26 | Message is per item | 1. Add Widget B at quantity 2.<br>2. Set Widget A to 21 and apply. | The message is shown for Widget A only. Widget B shows no message and remains at 2. |
| TC-27 | Message clears after a valid change | 1. Set 21 and apply (message shown).<br>2. Set 10 and apply. | The message is no longer shown. Quantity shows 10. |
| TC-28 | Over-limit value does not trigger the removal prompt | 1. Set 21 and apply. | "Remove this item?" is not shown. Only the maximum-quantity message appears. |
| TC-29 | Over-limit then zero still prompts correctly | 1. Set 21 and apply (rejected, quantity stays 1).<br>2. Set 0 and apply. | "Remove this item?" prompt appears. Cancelling restores quantity 1. |

### Cross-cutting

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-30 | Cart total reflects all quantity changes | 1. Add Widget B (unit price 5.00) at quantity 2.<br>2. Set Widget A to 4 and apply.<br>3. Set Widget B to 20 and apply. | Widget A subtotal 40.00. Widget B subtotal 100.00. Cart total 140.00. |
| TC-31 | Keyboard-only operation | 1. Tab to the quantity field.<br>2. Type 3 and press Enter.<br>3. Type 0, press Enter, and use the keyboard to choose Cancel in the prompt. | Quantity updates to 3 in step 2. The prompt is reachable and operable by keyboard. After cancel, quantity shows 3. |
| TC-32 | Validation and removal messages are announced to assistive technology | 1. With a screen reader active, set 21 and apply.<br>2. Set 0 and apply. | The maximum-quantity message is announced. The "Remove this item?" prompt receives focus and is announced. |

### Traceability

| AC | Test cases |
|---|---|
| AC-1 | TC-01 to TC-12, TC-30, TC-31 |
| AC-2 | TC-13 to TC-21, TC-29, TC-31, TC-32 |
| AC-3 | TC-22 to TC-29, TC-32 |
