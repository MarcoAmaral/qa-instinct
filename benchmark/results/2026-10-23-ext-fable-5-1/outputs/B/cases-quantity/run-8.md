# Test Cases: CART-12 Change the quantity of an item in the cart

## Assumptions

- A1: The quantity control is a numeric text input with increment (+) and decrement (−) buttons. Changes commit on blur, Enter, or button click.
- A2: Only one item is affected at a time; other cart lines are untouched by a quantity change.
- A3: Line subtotal and cart total update immediately after a successful change.
- A4: Non-numeric, decimal, negative, and empty input is rejected and the previous quantity is kept (behaviour mirrors AC-3). The exact message is not specified; the test expects an inline validation message and no change.
- A5: The "Remove this item?" prompt has Confirm and Cancel options. Cancel, Escape, and closing the dialog all count as declining.
- A6: Stock limits are out of scope; 20 is a hard per-line maximum regardless of inventory.
- A7: Cart changes persist across page reload for the same session.
- A8: Quantity below 0 (e.g. −1) is treated as invalid input, not as a removal request.

## Preconditions (all tests)

- Shopper is on the cart page with at least one item in the cart.
- Unless stated otherwise, the item under test has quantity 2 and unit price P.

## Test Cases

### AC-1: Whole numbers 1 to 20

| ID | Title | Steps | Expected Result | Priority |
|---|---|---|---|---|
| TC-01 | Set quantity to minimum (1) | 1. Clear the field. 2. Type `1`. 3. Press Enter. | Quantity shows 1. Line subtotal = 1 × P. Cart total updated. No message shown. | High |
| TC-02 | Set quantity to maximum (20) | 1. Clear the field. 2. Type `20`. 3. Press Enter. | Quantity shows 20. Line subtotal = 20 × P. No message shown. | High |
| TC-03 | Set a mid-range quantity (10) | 1. Clear the field. 2. Type `10`. 3. Blur the field. | Quantity shows 10. Subtotal and total updated. | High |
| TC-04 | Increment with + button | 1. Click + once. | Quantity goes from 2 to 3. Subtotal updated. | High |
| TC-05 | Decrement with − button | 1. Click − once. | Quantity goes from 2 to 1. Subtotal updated. | High |
| TC-06 | + button at maximum | 1. Set quantity to 20. 2. Click +. | Quantity stays 20. Message "You can buy at most 20 of this item." shown, or + button is disabled. | Medium |
| TC-07 | Leading zeros | 1. Type `05`. 2. Press Enter. | Quantity is treated as 5. Field displays `5`. | Low |
| TC-08 | Decimal value rejected | 1. Type `2.5`. 2. Press Enter. | Change rejected. Quantity stays 2. Inline validation message shown (A4). | Medium |
| TC-09 | Negative value rejected | 1. Type `-1`. 2. Press Enter. | Change rejected. Quantity stays 2. No "Remove this item?" prompt (A8). | Medium |
| TC-10 | Non-numeric text rejected | 1. Type `abc`. 2. Press Enter. | Change rejected. Quantity stays 2. | Medium |
| TC-11 | Empty field rejected | 1. Clear the field. 2. Blur. | Field reverts to 2. Item is not removed. | Medium |
| TC-12 | Whitespace padding | 1. Type ` 7 ` (with spaces). 2. Press Enter. | Quantity is treated as 7. | Low |
| TC-13 | Same value re-entered | 1. Type `2` (current value). 2. Press Enter. | No change, no message, no extra network request or duplicate update. | Low |
| TC-14 | Change persists across reload | 1. Set quantity to 6. 2. Reload the page. | Quantity still shows 6. | Medium |
| TC-15 | Other lines unaffected | 1. Cart has items A (qty 2) and B (qty 3). 2. Change A to 5. | A shows 5. B still shows 3. Total reflects both. | High |
| TC-16 | Paste a valid number | 1. Paste `15` into the field. 2. Blur. | Quantity shows 15. | Low |
| TC-17 | Keyboard arrow keys | 1. Focus the field. 2. Press ArrowUp twice, ArrowDown once. | Quantity goes 2 → 3 → 4 → 3 and respects the 1 to 20 bounds. | Low |

### AC-2: Quantity 0 prompts for removal

| ID | Title | Steps | Expected Result | Priority |
|---|---|---|---|---|
| TC-18 | Enter 0 shows prompt | 1. Type `0`. 2. Press Enter. | Dialog with text "Remove this item?" appears. Item is still in the cart behind the dialog. | High |
| TC-19 | Confirm removal | 1. Type `0`, press Enter. 2. Click Confirm. | Item is removed from the cart. Cart total excludes the item. Remaining items unchanged. | High |
| TC-20 | Cancel keeps item and quantity | 1. Type `0`, press Enter. 2. Click Cancel. | Dialog closes. Item remains with quantity 2. Subtotal unchanged. | High |
| TC-21 | Escape key declines | 1. Type `0`, press Enter. 2. Press Escape. | Same as TC-20. | Medium |
| TC-22 | Close dialog via X or backdrop | 1. Type `0`, press Enter. 2. Click the close control or outside the dialog. | Same as TC-20. | Medium |
| TC-23 | Decrement from 1 to 0 via − button | 1. Set quantity to 1. 2. Click −. | "Remove this item?" prompt appears. Behaves as TC-19 / TC-20 on confirm / cancel. | High |
| TC-24 | Remove last item in cart | 1. Cart has one item. 2. Set to 0 and confirm. | Cart shows the empty-cart state. Total is 0. | High |
| TC-25 | Remove one of several items | 1. Cart has A, B, C. 2. Set B to 0 and confirm. | B is removed. A and C remain with their quantities and order. | High |
| TC-26 | Removal persists across reload | 1. Confirm removal of an item. 2. Reload. | Item does not reappear. | Medium |
| TC-27 | Prompt is not shown for other values | 1. Type `1`. 2. Press Enter. | No "Remove this item?" prompt. | Medium |
| TC-28 | Focus after cancel | 1. Type `0`, press Enter. 2. Cancel. | Focus returns to the quantity field. Field shows 2. | Low |

### AC-3: Quantity above 20

| ID | Title | Steps | Expected Result | Priority |
|---|---|---|---|---|
| TC-29 | Boundary 21 rejected | 1. Type `21`. 2. Press Enter. | Message "You can buy at most 20 of this item." shown. Quantity stays 2. Subtotal unchanged. | High |
| TC-30 | Large value rejected | 1. Type `999`. 2. Press Enter. | Same message. Quantity stays 2. | Medium |
| TC-31 | Very large value | 1. Type `99999999999999999999`. 2. Press Enter. | Same message. Quantity stays 2. No UI error or crash. | Low |
| TC-32 | Previous quantity is the last committed value | 1. Set quantity to 15 and commit. 2. Type `25`, press Enter. | Message shown. Quantity reverts to 15, not 2. | High |
| TC-33 | Message clears on valid entry | 1. Type `21`, press Enter (message shown). 2. Type `5`, press Enter. | Message disappears. Quantity shows 5. | Medium |
| TC-34 | Rejection does not affect other lines | 1. Cart has A (qty 2), B (qty 3). 2. Set A to `30`. | Message shown on A only. B stays 3. Total unchanged. | Medium |
| TC-35 | Rejected value not persisted | 1. Type `21`, press Enter. 2. Reload. | Quantity is 2 (or last committed value). | Medium |
| TC-36 | Exact message text | 1. Type `21`, press Enter. | Message text is exactly "You can buy at most 20 of this item." including the full stop. | Medium |

### Cross-cutting

| ID | Title | Steps | Expected Result | Priority |
|---|---|---|---|---|
| TC-37 | Server-side enforcement of maximum | 1. Send the quantity-update request directly with qty 21 (API or DevTools). | Server rejects the request (4xx). Cart quantity unchanged. | High |
| TC-38 | Server-side enforcement of minimum | 1. Send qty 0 or −1 directly to the update endpoint. | Server rejects or treats as explicit remove only via the dedicated remove action. Item is not silently set to 0. | High |
| TC-39 | Rapid successive changes | 1. Click + five times quickly. | Final quantity is 7. Subtotal matches 7 × P. No lost or duplicated updates. | Medium |
| TC-40 | Network failure during update | 1. Simulate offline. 2. Change quantity to 5. | An error is shown. Quantity reverts to 2 or indicates a pending state. No silent mismatch between UI and server. | Medium |
| TC-41 | Price and total accuracy | 1. Item price 19.99. 2. Set quantity to 3. | Subtotal shows 59.97. Cart total and any tax or shipping lines recalculate correctly. | High |
| TC-42 | Checkout reflects new quantity | 1. Change quantity to 4. 2. Proceed to checkout. | Checkout summary shows quantity 4. | High |
| TC-43 | Screen reader announcements | 1. With a screen reader, enter `21`. 2. Enter `0`. | Error message is announced (aria-live). Dialog is announced and focus moves into it. | Medium |
| TC-44 | Keyboard-only operation | 1. Tab to the field, change value, Tab to the +/− buttons, operate the dialog with keyboard. | All actions are completable without a mouse. | Medium |
| TC-45 | Mobile input mode | 1. Open the cart on a mobile device. 2. Focus the quantity field. | Numeric keypad is shown. Field and buttons are tappable at a usable size. | Low |
| TC-46 | Quantity field for a removed item | 1. Remove item in one tab. 2. In a second tab, change its quantity. | Second tab shows a clear error or refreshes the cart. No ghost line is created. | Low |

## Traceability

| AC | Test Cases |
|---|---|
| AC-1 | TC-01 to TC-17, TC-39, TC-41, TC-42 |
| AC-2 | TC-18 to TC-28, TC-38 |
| AC-3 | TC-29 to TC-37 |

## Open Questions for the Product Owner

- Should values 21+ be blocked at keystroke level or only on commit?
- Should the − button be disabled at quantity 1, or should it trigger the removal prompt (assumed: trigger prompt, TC-23)?
- What message, if any, is shown for non-numeric or decimal input?
- Should stock availability below 20 lower the effective maximum and change the message?
