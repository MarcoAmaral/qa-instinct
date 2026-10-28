# Test Cases: CART-12 — Change the quantity of an item in the cart

## Assumptions

- The quantity field is a numeric input with no explicit +/- stepper; tests cover typed input and, where present, stepper controls.
- Changes are committed on blur or Enter (not on every keystroke).
- "Previous quantity" in AC-3 means the last successfully saved quantity, not an intermediate rejected value.
- Non-integer, negative, blank, and non-numeric input is rejected and the previous quantity is kept. The story does not specify this; the assumed message is "Enter a whole number from 1 to 20." Adjust the expected message once confirmed.
- The "Remove this item?" prompt offers Confirm and Cancel; dismissing it (Escape, click outside) behaves like Cancel.
- The 1–20 limit is per line item, not per cart total.
- The cart subtotal and item count update after a successful quantity change.

## Preconditions (all cases unless noted)

- Shopper is on the cart page with at least one item ("Item A") at quantity 2.
- Item A has sufficient stock for 20 units.

---

### AC-1: Accepts whole numbers from 1 to 20

| ID | Title | Steps | Expected Result |
|---|---|---|---|
| TC-01 | Set quantity to lower boundary (1) | 1. Clear the quantity field for Item A. 2. Enter `1`. 3. Press Enter. | Quantity saves as 1. No error. Line total and subtotal reflect 1 unit. |
| TC-02 | Set quantity to upper boundary (20) | 1. Enter `20`. 2. Press Enter. | Quantity saves as 20. No error. Line total and subtotal reflect 20 units. |
| TC-03 | Set quantity to a mid-range value (10) | 1. Enter `10`. 2. Press Enter. | Quantity saves as 10. Totals update. |
| TC-04 | Increase quantity by 1 from current (2 → 3) | 1. Enter `3` (or click +). 2. Commit. | Quantity saves as 3. Totals update. |
| TC-05 | Decrease quantity by 1 from current (2 → 1) | 1. Enter `1` (or click −). 2. Commit. | Quantity saves as 1. No removal prompt. |
| TC-06 | Commit via blur instead of Enter | 1. Enter `5`. 2. Click elsewhere on the page. | Quantity saves as 5. |
| TC-07 | Quantity persists after page reload | 1. Set quantity to 7 and commit. 2. Reload the cart page. | Item A shows quantity 7. |
| TC-08 | Leading zeros are normalised | 1. Enter `05`. 2. Commit. | Quantity saves and displays as 5. |
| TC-09 | Re-entering the same quantity | 1. Enter `2` (current value). 2. Commit. | No error, no prompt, quantity remains 2. |
| TC-10 | Decimal input is rejected | 1. Enter `2.5`. 2. Commit. | Validation message shown (assumed: "Enter a whole number from 1 to 20."). Quantity stays 2. |
| TC-11 | Negative input is rejected | 1. Enter `-1`. 2. Commit. | Validation message shown. Quantity stays 2. No removal prompt. |
| TC-12 | Non-numeric input is rejected | 1. Enter `abc`. 2. Commit. | Validation message shown or characters are not accepted. Quantity stays 2. |
| TC-13 | Blank input is rejected | 1. Clear the field. 2. Commit. | Validation message shown. Quantity stays 2. No removal prompt. |
| TC-14 | Whitespace-padded input is accepted | 1. Enter ` 4 ` (with spaces). 2. Commit. | Quantity saves as 4. |
| TC-15 | Changing one item does not affect others | Precondition: cart also has Item B at quantity 3. 1. Set Item A to 6. 2. Commit. | Item A = 6, Item B remains 3. Subtotal reflects both. |

### AC-2: Quantity 0 prompts for removal

| ID | Title | Steps | Expected Result |
|---|---|---|---|
| TC-16 | Entering 0 shows the removal prompt | 1. Enter `0`. 2. Commit. | Dialog "Remove this item?" appears. Item A is still in the cart behind the dialog at quantity 2. |
| TC-17 | Confirm removal | 1. Enter `0`. 2. Commit. 3. Click Confirm. | Item A is removed from the cart. Subtotal and item count exclude it. |
| TC-18 | Cancel removal | 1. Enter `0`. 2. Commit. 3. Click Cancel. | Dialog closes. Item A remains with quantity 2 (previous value restored in the field). |
| TC-19 | Dismiss prompt with Escape | 1. Enter `0`. 2. Commit. 3. Press Escape. | Behaves like Cancel: item remains at quantity 2. |
| TC-20 | Dismiss prompt by clicking outside | 1. Enter `0`. 2. Commit. 3. Click outside the dialog. | Behaves like Cancel: item remains at quantity 2. |
| TC-21 | Decrement from 1 to 0 via stepper | Precondition: Item A at quantity 1. 1. Click − (if present). | Dialog "Remove this item?" appears; item not removed until confirmed. |
| TC-22 | Removal persists after reload | 1. Enter `0`, commit, confirm. 2. Reload the page. | Item A is absent. |
| TC-23 | Cancelled removal persists after reload | 1. Enter `0`, commit, cancel. 2. Reload the page. | Item A is present at quantity 2. |
| TC-24 | Removing the last item empties the cart | Precondition: Item A is the only item. 1. Enter `0`, commit, confirm. | Cart shows its empty state. Subtotal is zero. |
| TC-25 | Leading-zero variant of 0 | 1. Enter `00`. 2. Commit. | Treated as 0: removal prompt appears. |
| TC-26 | Removal prompt targets the correct item | Precondition: cart has Item A and Item B. 1. Set Item B to `0`, commit, confirm. | Item B is removed; Item A unchanged. |

### AC-3: Quantity above 20 is rejected

| ID | Title | Steps | Expected Result |
|---|---|---|---|
| TC-27 | Enter 21 (just above limit) | 1. Enter `21`. 2. Commit. | Message "You can buy at most 20 of this item." is shown. Quantity field reverts to 2. Totals unchanged. |
| TC-28 | Enter a large value | 1. Enter `999`. 2. Commit. | Same message. Quantity reverts to 2. |
| TC-29 | Increment past 20 via stepper | Precondition: Item A at quantity 20. 1. Click + (if present). | Same message, or + is disabled. Quantity stays 20. |
| TC-30 | Reverts to last saved value, not last typed value | 1. Set quantity to 15, commit. 2. Enter `25`, commit. | Message shown. Quantity reverts to 15 (not 2). |
| TC-31 | Error clears after a valid entry | 1. Enter `21`, commit (error shown). 2. Enter `10`, commit. | Message disappears. Quantity saves as 10. |
| TC-32 | Over-limit does not persist after reload | 1. Enter `21`, commit. 2. Reload the page. | Item A shows quantity 2. |
| TC-33 | Over-limit on one item does not affect another | Precondition: cart has Item A and Item B at 3. 1. Set Item A to `30`, commit. | Message shown for Item A only. Item B remains 3. |
| TC-34 | Paste an over-limit value | 1. Paste `100` into the field. 2. Commit. | Message shown. Quantity reverts to 2. |
| TC-35 | Server-side enforcement | 1. Using the browser dev tools or an API client, submit a quantity update of 21 directly. | Request is rejected. Cart quantity remains 2. |
| TC-36 | Server-side enforcement for 0 without confirmation | 1. Submit a quantity update of 0 directly via the API with no confirmation. | Behaviour matches a confirmed removal or is rejected, per API design. Item is not left in an invalid state with quantity 0. |

### Cross-cutting

| ID | Title | Steps | Expected Result |
|---|---|---|---|
| TC-37 | Keyboard-only operation | 1. Tab to the quantity field. 2. Type `4`, press Enter. 3. Type `0`, press Enter. 4. Tab to Confirm, press Enter. | All actions complete without a mouse. Focus lands on a sensible element after removal. |
| TC-38 | Screen reader announces validation and prompt | 1. With a screen reader active, enter `21` and commit. 2. Enter `0` and commit. | The limit message and the removal dialog are announced. |
| TC-39 | Rapid successive changes | 1. Enter `3`, commit. 2. Immediately enter `4`, commit. 3. Immediately enter `5`, commit. | Final saved quantity is 5. Totals match 5 units. |
| TC-40 | Network failure during update | 1. Simulate a failed save (offline). 2. Enter `6`, commit. | An error is shown and the quantity reverts to 2. No silent failure. |
