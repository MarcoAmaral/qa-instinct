# Test Cases: CART-12 — Change the quantity of an item in the cart

## Assumptions

- A-1: The quantity field is a numeric input on the cart line item, with a visible "Update" action or auto-apply on blur/Enter. Tests say "apply the quantity" to cover either implementation.
- A-2: Non-numeric, negative, decimal, and blank input are rejected with an inline validation message and the previous quantity is kept (behavior not specified by the story; treated as a reasonable default and flagged for product confirmation).
- A-3: The "Remove this item?" prompt is a modal dialog with Confirm and Cancel actions. Cancel, closing the dialog, or pressing Escape all count as "not confirmed".
- A-4: The 20-unit maximum is a per-line cap and is independent of stock availability. Stock limits are out of scope for this story.
- A-5: Line subtotal and cart total recalculate immediately after a successful quantity change.
- A-6: Cart changes persist for a logged-in shopper across page reload and for a guest within the session.
- A-7: Numeric values in the examples below are in the shop's base currency; exact prices are placeholders.

## Preconditions (apply to all cases unless overridden)

- Shopper has a cart containing at least one item, "Item A", with quantity 2 and unit price 10.00.
- Item A has at least 20 units in stock.

---

## AC-1: Quantity field accepts whole numbers 1–20

| ID | Title | Steps | Expected result | Priority |
|---|---|---|---|---|
| TC-01 | Set quantity to minimum boundary (1) | 1. Open cart. 2. Change Item A quantity to 1. 3. Apply. | Quantity shows 1. Line subtotal is 10.00. Cart total updates. No error shown. | High |
| TC-02 | Set quantity to maximum boundary (20) | 1. Change Item A quantity to 20. 2. Apply. | Quantity shows 20. Line subtotal is 200.00. No error shown. | High |
| TC-03 | Set quantity to a mid-range value | 1. Change Item A quantity to 7. 2. Apply. | Quantity shows 7. Line subtotal is 70.00. | High |
| TC-04 | Increase quantity from current value | 1. Change quantity from 2 to 5. 2. Apply. | Quantity shows 5. Cart total increases by 30.00. | High |
| TC-05 | Decrease quantity to a non-zero value | 1. Change quantity from 2 to 1. 2. Apply. | Quantity shows 1. Cart total decreases by 10.00. | High |
| TC-06 | Re-apply the same quantity | 1. Leave quantity at 2. 2. Apply. | No change, no error, no duplicate line item. | Medium |
| TC-07 | Quantity persists after reload (logged-in) | 1. Log in. 2. Set quantity to 5. 3. Apply. 4. Reload page. | Quantity still shows 5. (A-6) | High |
| TC-08 | Quantity persists after reload (guest) | 1. As guest, set quantity to 5. 2. Apply. 3. Reload page. | Quantity still shows 5 within the session. (A-6) | Medium |
| TC-09 | Leading zero is normalised | 1. Enter "05". 2. Apply. | Quantity shows 5. No error. | Low |
| TC-10 | Leading/trailing whitespace is trimmed | 1. Enter " 5 " (if the field allows it). 2. Apply. | Quantity shows 5. No error. | Low |
| TC-11 | Change quantity on one of several items | 1. Add Item B (qty 3). 2. Change Item A to 4. 3. Apply. | Item A shows 4. Item B remains 3. Cart total reflects both. | High |
| TC-12 | Stepper/plus-minus controls (if present) | 1. Click "+" once from 2. 2. Click "−" twice. | Quantity goes 2 → 3 → 2 → 1. "−" at 1 either disables or triggers the AC-2 flow (see TC-26). | Medium |

## AC-1 negative: invalid input (per A-2)

| ID | Title | Steps | Expected result | Priority |
|---|---|---|---|---|
| TC-13 | Decimal value rejected | 1. Enter 2.5. 2. Apply. | Validation message shown. Quantity stays 2. Subtotal unchanged. | High |
| TC-14 | Negative value rejected | 1. Enter -1. 2. Apply. | Validation message shown. Quantity stays 2. | High |
| TC-15 | Alphabetic input rejected | 1. Enter "abc". 2. Apply. | Validation message shown (or input prevented). Quantity stays 2. | High |
| TC-16 | Blank value rejected | 1. Clear the field. 2. Apply. | Validation message shown. Quantity stays 2. Item is not removed. | High |
| TC-17 | Mixed alphanumeric rejected | 1. Enter "1e1" or "5x". 2. Apply. | Validation message shown. Quantity stays 2. (Note: "1e1" is numerically 10; it should not be accepted as 10.) | Medium |
| TC-18 | Special characters rejected | 1. Enter "+5", "٥" (non-ASCII digit), or "5;". 2. Apply. | Validation message shown. Quantity stays 2. | Low |
| TC-19 | Extremely long input | 1. Enter a 50-digit number. 2. Apply. | AC-3 message or validation error. No crash, no overflow, quantity stays 2. | Medium |
| TC-20 | Script/markup input is not rendered | 1. Enter `<script>alert(1)</script>`. 2. Apply. | Input rejected. No script executes. Message, if echoed, is escaped. | High |

## AC-2: Setting quantity to 0 prompts for removal

| ID | Title | Steps | Expected result | Priority |
|---|---|---|---|---|
| TC-21 | Zero triggers the confirmation prompt | 1. Change Item A quantity to 0. 2. Apply. | Dialog appears with text "Remove this item?" and Confirm/Cancel actions. Item is still in cart behind the dialog. | High |
| TC-22 | Confirm removes the item | 1. Set 0, apply. 2. Click Confirm. | Item A is removed. Cart total decreases by 20.00. If cart is now empty, empty-cart state is shown. | High |
| TC-23 | Cancel keeps the item with previous quantity | 1. Set 0, apply. 2. Click Cancel. | Dialog closes. Item A remains with quantity 2 (not 0). Subtotal unchanged. | High |
| TC-24 | Closing dialog (X / Escape / click outside) keeps the item | 1. Set 0, apply. 2. Press Escape. 3. Repeat with X and clicking the backdrop. | Each path behaves like Cancel: item remains at quantity 2. (A-3) | High |
| TC-25 | Removal persists after reload | 1. Set 0, Confirm. 2. Reload page. | Item A is still absent. | High |
| TC-26 | Cancel then reload shows previous quantity | 1. Set 0, Cancel. 2. Reload page. | Item A shows quantity 2. No pending "0" state was saved. | Medium |
| TC-27 | Stepper "−" from 1 to 0 triggers prompt | 1. Set quantity to 1, apply. 2. Click "−". | "Remove this item?" prompt appears (or "−" is disabled at 1; confirm expected behaviour with product). | Medium |
| TC-28 | Zero on one of several items removes only that item | 1. Cart has Items A and B. 2. Set Item A to 0, Confirm. | Only Item A removed. Item B unchanged. | High |
| TC-29 | Leading-zero "00" is treated as 0 | 1. Enter "00". 2. Apply. | "Remove this item?" prompt appears. | Low |
| TC-30 | Prompt is keyboard accessible | 1. Trigger the prompt. 2. Navigate with Tab/Shift+Tab. 3. Press Enter on Confirm. | Focus is trapped in dialog, Confirm and Cancel are reachable, Enter activates focused button, focus returns to the cart after close. | Medium |
| TC-31 | Prompt announced to screen readers | 1. With a screen reader active, trigger the prompt. | Dialog has role "dialog"/"alertdialog" and the text "Remove this item?" is announced. | Medium |

## AC-3: Quantity above 20 is rejected

| ID | Title | Steps | Expected result | Priority |
|---|---|---|---|---|
| TC-32 | Boundary: 21 is rejected | 1. Enter 21. 2. Apply. | Message "You can buy at most 20 of this item." shown. Quantity stays 2. Subtotal unchanged. | High |
| TC-33 | Large value rejected | 1. Enter 999. 2. Apply. | Same message. Quantity stays 2. | High |
| TC-34 | Previous quantity kept when previous was 20 | 1. Set 20, apply. 2. Enter 25, apply. | Message shown. Quantity stays 20 (not reset to 1 or default). | High |
| TC-35 | Exact message text and punctuation | 1. Enter 21. 2. Apply. | Message text matches exactly: "You can buy at most 20 of this item." | Medium |
| TC-36 | Stepper "+" at 20 | 1. Set 20, apply. 2. Click "+". | Either "+" is disabled at 20, or the AC-3 message appears and quantity stays 20. | Medium |
| TC-37 | Message clears after a valid correction | 1. Enter 21, apply (message shown). 2. Enter 5, apply. | Message disappears. Quantity shows 5. | Medium |
| TC-38 | Over-limit does not persist after reload | 1. Enter 21, apply. 2. Reload. | Quantity shows 2. No "21" was saved. | High |
| TC-39 | Over-limit on one item does not affect others | 1. Cart has A (2) and B (3). 2. Set A to 21, apply. | Message shown on A only. B remains 3. | Medium |
| TC-40 | Message is announced to assistive tech | 1. Enter 21, apply with screen reader active. | Message is associated with the field (aria-describedby or live region) and announced. | Medium |

## Cross-cutting: totals, concurrency, API, and robustness

| ID | Title | Steps | Expected result | Priority |
|---|---|---|---|---|
| TC-41 | Cart total, tax, and shipping recalculate | 1. Change quantity 2 → 10. 2. Apply. | Line subtotal, cart subtotal, tax, shipping (if quantity-based), and grand total all update consistently. | High |
| TC-42 | Promo/discount recalculates with quantity | 1. Apply a quantity-based promo (e.g. "buy 3 get 10% off"). 2. Change quantity 2 → 3, then 3 → 2. | Discount applies at 3 and is removed at 2. | Medium |
| TC-43 | Rapid successive changes settle on the last value | 1. Quickly change 2 → 5 → 8 → 3 and apply each. | Final quantity is 3. No stale response overwrites it. | Medium |
| TC-44 | Double-submit does not double-apply | 1. Enter 5. 2. Click Apply twice rapidly. | Quantity is 5 once. No duplicate requests cause inconsistency. | Medium |
| TC-45 | Server-side enforcement of limits | 1. Via API/devtools, send quantity 21 directly. 2. Send 0 without confirmation. 3. Send -1 and 2.5. | Server rejects all with a 4xx and the cart is unchanged. Client validation is not the only guard. | High |
| TC-46 | Network failure on apply | 1. Simulate offline. 2. Change quantity to 5, apply. | Error message shown. Quantity reverts to or remains 2. No silent failure. | High |
| TC-47 | Slow response shows loading state | 1. Throttle network. 2. Apply a change. | Field/button shows pending state; shopper cannot submit a conflicting change mid-request. | Low |
| TC-48 | Cart modified in another tab | 1. Open cart in two tabs. 2. In tab 1 remove Item A. 3. In tab 2 change Item A to 5, apply. | Tab 2 shows an appropriate error or refreshes; no phantom line item is recreated. | Medium |
| TC-49 | Item becomes unavailable before apply | 1. Have Item A deactivated in admin. 2. Change quantity, apply. | Clear error; cart does not show a stale successful update. | Low |
| TC-50 | Mobile numeric keyboard | 1. Open cart on a mobile device. 2. Tap the quantity field. | Numeric keypad appears (inputmode="numeric"). Field and messages are readable at 320px width. | Medium |
| TC-51 | Cross-browser smoke | 1. Run TC-01, TC-21, TC-32 on Chrome, Firefox, Safari, Edge (latest). | Consistent behaviour and message text on all. | Medium |
| TC-52 | Keyboard-only quantity change | 1. Tab to quantity field. 2. Type 5, press Enter. | Quantity applies. Focus remains in a sensible place. | Medium |
| TC-53 | Paste into quantity field | 1. Paste "15". 2. Paste "abc". 3. Paste "30". | 15 accepted; "abc" rejected; 30 triggers AC-3 message. | Low |
| TC-54 | Analytics/event fired on change (if applicable) | 1. Change quantity, apply. | Cart-update event fires once with correct item ID and new quantity. | Low |

## Open questions to confirm with product (tests proceed on stated assumptions)

1. Is the field free-text, a stepper, or both? (Affects TC-12, TC-27, TC-36.)
2. Is apply on blur, on Enter, or on an explicit button? (Affects TC-43, TC-44, TC-52.)
3. What is the exact message for non-numeric/blank/decimal input? (A-2; TC-13–TC-19.)
4. Does closing the dialog by Escape/backdrop count as Cancel? (A-3; TC-24.)
5. Should the 20 cap also respect available stock when stock < 20? (A-4; out of scope here.)
