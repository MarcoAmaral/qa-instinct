# Test Cases: CART-12 Change the quantity of an item in the cart

## Assumptions

- A-1: The quantity control is a numeric text input with +/- stepper buttons. Both paths are covered; if steppers do not exist, skip the stepper cases.
- A-2: A change is committed on blur, Enter, or a stepper click. There is no separate "Update" button.
- A-3: The "Remove this item?" prompt has a Confirm and a Cancel action. Cancel or dismissing the prompt restores the previous quantity.
- A-4: Validation messages appear inline next to the quantity field. "Previous quantity" means the last successfully committed value.
- A-5: The limit of 20 is per cart line, not per cart. Stock availability below 20 is out of scope for this story.
- A-6: Line total and cart subtotal update after a committed quantity change.
- A-7: Non-numeric or empty input is rejected and the previous quantity is kept. The exact message is not specified; tests check that the quantity is unchanged and some validation feedback appears.

## Preconditions (all cases)

- Shopper is on the cart page with at least one item in the cart.
- Unless stated otherwise, the item's starting quantity is 5 and its unit price is known.

## AC-1: Quantity field accepts whole numbers from 1 to 20

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-01 | Lower boundary: set quantity to 1 | 1. Clear the field and type `1`. 2. Press Enter. | Quantity is 1. Line total equals 1 x unit price. Subtotal updates. No message shown. |
| TC-02 | Upper boundary: set quantity to 20 | 1. Type `20`. 2. Blur the field. | Quantity is 20. Line total equals 20 x unit price. No message shown. |
| TC-03 | Mid-range value | 1. Type `12`. 2. Press Enter. | Quantity is 12 and totals update. |
| TC-04 | Just inside upper boundary | 1. Type `19`. 2. Press Enter. | Quantity is 19 and totals update. No message shown. |
| TC-05 | Just inside lower boundary | 1. Type `2`. 2. Press Enter. | Quantity is 2 and totals update. No message shown. |
| TC-06 | Increase via stepper | 1. Click + once from quantity 5. | Quantity is 6 and totals update. |
| TC-07 | Decrease via stepper | 1. Click - once from quantity 5. | Quantity is 4 and totals update. |
| TC-08 | Stepper stops at 20 | 1. Set quantity to 20. 2. Click +. | Quantity stays 20. Either the + control is disabled or the AC-3 message appears. No value above 20 is ever shown. |
| TC-09 | Decimal value rejected | 1. Type `2.5`. 2. Press Enter. | Quantity stays 5. Validation feedback shown. Totals unchanged. |
| TC-10 | Negative value rejected | 1. Type `-3`. 2. Press Enter. | Quantity stays 5. Validation feedback shown. No removal prompt. |
| TC-11 | Non-numeric input rejected | 1. Type `abc`. 2. Blur. | Quantity stays 5. Validation feedback shown. |
| TC-12 | Empty field rejected | 1. Clear the field. 2. Blur. | Quantity stays 5. Field redisplays 5 or shows validation feedback. Item is not removed. |
| TC-13 | Leading zeros normalized | 1. Type `007`. 2. Press Enter. | Quantity is 7 and displays as `7`. |
| TC-14 | Surrounding whitespace trimmed | 1. Type ` 8 ` with spaces. 2. Press Enter. | Quantity is 8. |
| TC-15 | Pasted valid value | 1. Paste `15` into the field. 2. Blur. | Quantity is 15 and totals update. |
| TC-16 | Pasted invalid value | 1. Paste `1e3`. 2. Blur. | Quantity stays 5. Validation feedback shown. |
| TC-17 | Same value re-entered | 1. Type `5` over existing 5. 2. Press Enter. | No error. No duplicate request or visible flicker. Totals unchanged. |
| TC-18 | Change persists after reload | 1. Set quantity to 9. 2. Reload the cart page. | Quantity is still 9. |
| TC-19 | Independent lines | 1. With two different items in the cart, set the first to 3. | Only the first item changes. Second item quantity is unchanged. Subtotal reflects both lines. |
| TC-20 | Rapid successive edits | 1. Type `3`, press Enter, immediately type `7`, press Enter. | Final quantity is 7. Totals match 7 x unit price. No stale value overwrites the final one. |

## AC-2: Setting quantity to 0 prompts for removal

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-21 | Zero triggers prompt | 1. Type `0`. 2. Press Enter. | A prompt with the exact text "Remove this item?" appears. Item is still in the cart behind the prompt. |
| TC-22 | Confirm removes item | 1. Type `0`, press Enter. 2. Choose Confirm. | Item is removed from the cart. Subtotal no longer includes it. Item count decreases by one. |
| TC-23 | Cancel keeps item | 1. Type `0`, press Enter. 2. Choose Cancel. | Prompt closes. Item remains with quantity 5. Totals unchanged. |
| TC-24 | Dismiss by Escape keeps item | 1. Type `0`, press Enter. 2. Press Escape. | Same as TC-23. |
| TC-25 | Dismiss by clicking outside keeps item | 1. Type `0`, press Enter. 2. Click outside the prompt. | Same as TC-23. Assumption A-3 applies. |
| TC-26 | Stepper down from 1 | 1. Set quantity to 1. 2. Click -. | Prompt "Remove this item?" appears. Item not removed until confirmed. |
| TC-27 | Zero with leading zeros | 1. Type `00`. 2. Press Enter. | Treated as 0. Prompt appears. |
| TC-28 | Removal persists after reload | 1. Complete TC-22. 2. Reload the page. | Item is still absent. |
| TC-29 | Cancel persists after reload | 1. Complete TC-23. 2. Reload the page. | Item is present with quantity 5. |
| TC-30 | Removing the last item | 1. With one item in the cart, set quantity to 0 and confirm. | Cart shows its empty state. No error. |
| TC-31 | Prompt targets correct item | 1. With two items in the cart, set the second item to 0 and confirm. | Only the second item is removed. First item is untouched. |
| TC-32 | No prompt for non-zero values | 1. Type `1`. 2. Press Enter. | No removal prompt appears. |
| TC-33 | Prompt cannot be bypassed | 1. Type `0`. 2. Without confirming, navigate to another page and return to the cart. | Item is still in the cart with quantity 5. |

## AC-3: Quantity above 20 shows a message and keeps the previous quantity

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-34 | Just above upper boundary | 1. Type `21`. 2. Press Enter. | Message "You can buy at most 20 of this item." appears, exact text. Quantity stays 5. Totals unchanged. |
| TC-35 | Large value | 1. Type `999`. 2. Press Enter. | Same as TC-34. |
| TC-36 | Very large value | 1. Paste `99999999999999999999`. 2. Press Enter. | Same as TC-34. No crash, overflow, or scientific notation shown. |
| TC-37 | Previous quantity means last committed value | 1. Set quantity to 12 and press Enter. 2. Type `25` and press Enter. | Message shown. Quantity is 12, not 5. |
| TC-38 | Message clears on valid entry | 1. Trigger TC-34. 2. Type `10`, press Enter. | Message disappears. Quantity is 10. |
| TC-39 | Message clears on cancel edit | 1. Type `30`. 2. Press Escape or blur without committing. | Field shows 5. Message either never appears or clears. |
| TC-40 | Boundary pairing | 1. Type `20`, press Enter. 2. Type `21`, press Enter. | Step 1 succeeds. Step 2 shows the message and quantity stays 20. |
| TC-41 | Over-limit via stepper | 1. Set quantity to 20. 2. Click + repeatedly. | Quantity never exceeds 20. If the button is enabled, the message appears. |
| TC-42 | Over-limit with decimal | 1. Type `20.5`. 2. Press Enter. | Quantity stays 5. Validation feedback shown. Treated as invalid rather than rounding to 20 or 21. |
| TC-43 | Over-limit does not affect other lines | 1. With two items, enter `50` on the first. | Message shown on the first line only. Second line unaffected. |
| TC-44 | Over-limit not persisted | 1. Trigger TC-34. 2. Reload the page. | Quantity is 5. |
| TC-45 | Repeated over-limit entries | 1. Type `21`, Enter. 2. Type `22`, Enter. | Message shown once per attempt, no stacking of duplicate messages. Quantity stays 5. |

## Cross-cutting and non-functional

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-46 | Keyboard-only operation | 1. Tab to the quantity field. 2. Type `3`, Enter. 3. Tab to the stepper buttons and press Space. | All controls reachable and operable by keyboard. Focus stays visible. |
| TC-47 | Screen reader announcements | 1. With a screen reader on, trigger the AC-3 message and the AC-2 prompt. | Message is announced via a live region. Prompt receives focus and its text is read. Field has an accessible label naming the item. |
| TC-48 | Mobile numeric keyboard | 1. Open the cart on a mobile device. 2. Tap the quantity field. | Numeric keyboard appears. All AC-1 to AC-3 behaviors hold on touch. |
| TC-49 | Server-side enforcement | 1. Using the browser dev tools or API client, send an update request with quantity 25. 2. Send one with quantity 0 and no confirmation flag. 3. Send one with quantity -1. | Server rejects 25 and -1 with a validation error. Zero either removes only via the documented remove endpoint or is rejected. Cart state in the UI after reload matches the server. |
| TC-50 | Network failure on update | 1. Simulate the update request failing. 2. Set quantity to 7. | An error is shown. Field reverts to 5. Totals unchanged. |
| TC-51 | Network failure on removal | 1. Simulate the remove request failing. 2. Set quantity to 0 and confirm. | An error is shown. Item remains with quantity 5. |
| TC-52 | Concurrent tab update | 1. Open the cart in two tabs. 2. Set quantity to 8 in tab A. 3. Set quantity to 3 in tab B. 4. Reload tab A. | Tab A shows 3 after reload. No lost updates without feedback. |
| TC-53 | Cart badge and header count | 1. Set quantity from 5 to 7. 2. Remove an item via AC-2. | Header cart count reflects each change immediately. |
| TC-54 | Totals precision | 1. Use an item priced at 0.33. 2. Set quantity to 3. | Line total displays 0.99 with no floating point artifacts. |

## Traceability

| Acceptance criterion | Test cases |
|---|---|
| AC-1 | TC-01 to TC-20, TC-46, TC-48, TC-49, TC-50 |
| AC-2 | TC-21 to TC-33, TC-47, TC-49, TC-51 |
| AC-3 | TC-34 to TC-45, TC-47, TC-49 |

## Open questions for the product owner

These do not block testing. The assumptions above apply until answered.

1. Should the + stepper be disabled at 20, or stay enabled and show the AC-3 message?
2. What message, if any, is shown for non-numeric, decimal, or empty input?
3. Should an empty field on blur revert silently or show an error?
4. Does dismissing the removal prompt by clicking outside count as Cancel?
