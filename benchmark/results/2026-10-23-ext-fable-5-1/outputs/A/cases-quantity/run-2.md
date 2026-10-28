## Assumptions

- The quantity control is a single numeric input with an explicit Update action. Where the real UI applies on blur or on stepper click, treat "submit the quantity" as that trigger.
- Decimal, negative, blank, and non-numeric input is rejected inline and the previous quantity is kept. The story does not define a message for these cases, so tests only check that the quantity is unchanged.
- The "Remove this item?" prompt has Confirm and Cancel options. Cancel keeps the item at its previous quantity.
- Line subtotal and cart total recalculate after any accepted change.
- Stock limits are out of scope. Each test starts with a cart containing one item at quantity 5 unless stated otherwise.

## Test cases

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-01 | Accept minimum quantity | Set quantity to 1 and submit. | Quantity shows 1. Line subtotal and cart total reflect 1 unit. No message shown. |
| TC-02 | Accept maximum quantity | Set quantity to 20 and submit. | Quantity shows 20. Totals reflect 20 units. No message shown. |
| TC-03 | Accept mid-range quantity | Set quantity to 7 and submit. | Quantity shows 7. Totals reflect 7 units. |
| TC-04 | Increase then decrease in one session | Set quantity to 12, submit, then set to 3 and submit. | Quantity shows 3 after the second submit. Totals reflect 3 units. |
| TC-05 | Reject decimal quantity | Set quantity to 2.5 and submit. | Quantity stays 5. Totals unchanged. |
| TC-06 | Reject negative quantity | Set quantity to -1 and submit. | Quantity stays 5. No removal prompt shown. Totals unchanged. |
| TC-07 | Reject non-numeric input | Type "abc" and submit. | Quantity stays 5. Totals unchanged. |
| TC-08 | Reject blank input | Clear the field and submit. | Quantity stays 5. No removal prompt shown. Totals unchanged. |
| TC-09 | Leading zeros treated as the number | Set quantity to 007 and submit. | Quantity shows 7. Totals reflect 7 units. |
| TC-10 | Zero prompts for removal | Set quantity to 0 and submit. | Prompt "Remove this item?" appears. Item is still in the cart while the prompt is open. |
| TC-11 | Confirm removal | Set quantity to 0, submit, then confirm the prompt. | Item is removed from the cart. Cart total excludes the item. If it was the only item, the empty cart state shows. |
| TC-12 | Cancel removal | Set quantity to 0, submit, then cancel the prompt. | Item remains with quantity 5. Totals unchanged. Prompt closes. |
| TC-13 | Dismiss removal prompt without choosing | Set quantity to 0, submit, then close the prompt with Escape or the close control. | Treated as cancel. Item remains with quantity 5. |
| TC-14 | Removal affects only the chosen item | Cart has items A and B. Set A to 0, submit, confirm. | A is removed. B keeps its quantity. Cart total equals B only. |
| TC-15 | Reject 21 with message | Set quantity to 21 and submit. | Message "You can buy at most 20 of this item." is shown. Quantity stays 5. Totals unchanged. |
| TC-16 | Reject a large value with message | Set quantity to 999 and submit. | Same message as TC-15. Quantity stays 5. |
| TC-17 | Previous quantity kept after earlier valid change | Set quantity to 15, submit, then set to 25 and submit. | Message shown. Quantity stays 15, not 5. |
| TC-18 | Message clears after a valid change | Trigger the message with 21, then set 10 and submit. | Message disappears. Quantity shows 10. |
| TC-19 | Over-limit message is per item | Cart has items A and B. Set A to 30 and submit. | Message appears against A only. B shows no message and keeps its quantity. |
| TC-20 | Boundary pair 20 and 21 | Submit 20, then submit 21. | 20 is accepted. 21 is rejected with the message and quantity stays 20. |
| TC-21 | Boundary pair 0 and 1 | Submit 1, then submit 0 and cancel. | 1 is accepted. 0 shows the removal prompt. After cancel, quantity stays 1. |
| TC-22 | Change persists on reload | Set quantity to 8, submit, reload the cart page. | Quantity shows 8 after reload. |
| TC-23 | Keyboard-only operation | Tab to the quantity field, type 4, press Enter. | Quantity shows 4. Focus remains in a sensible place. Removal prompt, when triggered with 0, is reachable and operable by keyboard. |
| TC-24 | Message is announced to assistive tech | Submit 21 with a screen reader active. | The over-limit message is announced and is associated with the quantity field. |
