# Test Cases — CART-12: Change the quantity of an item in the cart

## Assumptions

- A-1: The quantity control is a numeric text input with "+" and "−" stepper buttons; both paths must satisfy the same rules.
- A-2: A quantity change is committed on blur, on Enter, or on clicking a stepper button; the server call is asynchronous.
- A-3: Non-integer, negative, blank, or non-numeric entries are rejected and the field reverts to the previous quantity with the message "Enter a whole number from 1 to 20." (The story does not define this message; the exact wording is a placeholder to be confirmed with the product owner.)
- A-4: The "Remove this item?" prompt has "Remove" and "Cancel" actions; closing the dialog by Escape or clicking outside counts as Cancel.
- A-5: The 20-unit maximum is a per-line-item limit and is independent of stock availability. Stock-limit behaviour is out of scope for this story.
- A-6: Line subtotal, cart subtotal, and header cart badge recalculate immediately after a successful change.
- A-7: Cart changes persist across page reload for both guest and signed-in shoppers.
- A-8: The feature is in scope for desktop and mobile web; the "+" stepper is disabled at 20 and the "−" stepper at 1 is replaced by, or behaves as, a remove action that triggers the AC-2 prompt.

## Preconditions (common)

- Shopper has a cart containing at least one item ("Item A") with quantity 2, unit price 10.00, unless a test states otherwise.
- Cart page is open.

---

## AC-1: The quantity field accepts whole numbers from 1 to 20

| ID | Title | Steps | Expected result | Priority |
|---|---|---|---|---|
| TC-01 | Set quantity to lower boundary (1) | 1. Clear the quantity field for Item A. 2. Type `1`. 3. Press Enter. | Quantity shows 1. Line subtotal is 10.00. Cart subtotal and badge update. No error shown. | High |
| TC-02 | Set quantity to upper boundary (20) | 1. Type `20` in the quantity field. 2. Blur the field. | Quantity shows 20. Line subtotal is 200.00. No error shown. "+" stepper becomes disabled (A-8). | High |
| TC-03 | Set a mid-range quantity (e.g. 7) | 1. Type `7`. 2. Press Enter. | Quantity shows 7. Line subtotal is 70.00. | High |
| TC-04 | Increase via "+" stepper | 1. Click "+" once. | Quantity goes from 2 to 3. Totals update. | High |
| TC-05 | Decrease via "−" stepper | 1. Click "−" once. | Quantity goes from 2 to 1. Totals update. No prompt shown. | High |
| TC-06 | Step up to exactly 20 | 1. Set quantity to 19. 2. Click "+". | Quantity shows 20. "+" is disabled. No error shown. | Medium |
| TC-07 | Same value re-entered | 1. Type `2` (the current value). 2. Blur. | No change, no error, no duplicate network call (verify in dev tools). | Low |
| TC-08 | Leading zeros | 1. Type `05`. 2. Blur. | Treated as 5. Quantity shows 5. Totals reflect 5 units. | Medium |
| TC-09 | Leading/trailing whitespace | 1. Type ` 4 `. 2. Blur. | Treated as 4 or rejected per A-3. Behaviour must be consistent with TC-08 handling. Record actual result. | Low |
| TC-10 | Reject decimal | 1. Type `2.5`. 2. Blur. | Rejected. Field reverts to 2. Message per A-3 shown. Totals unchanged. | High |
| TC-11 | Reject negative | 1. Type `-1`. 2. Blur. | Rejected. Field reverts to 2. Message per A-3 shown. | High |
| TC-12 | Reject non-numeric text | 1. Type `abc`. 2. Blur. | Rejected (or input blocked). Field reverts to 2. | High |
| TC-13 | Reject blank | 1. Clear the field. 2. Blur. | Rejected. Field reverts to 2. Item is not removed. Message per A-3 shown. | High |
| TC-14 | Reject scientific notation / symbols | 1. Type `1e1`, then `+5`, then `٣` (Arabic-Indic digit) in separate attempts. | Each attempt rejected or normalised consistently. Quantity never becomes an invalid value. Record actual result. | Low |
| TC-15 | Paste invalid value | 1. Paste `25abc` into the field. 2. Blur. | Rejected. Field reverts to 2. | Medium |
| TC-16 | Quantity persists after reload | 1. Set quantity to 6. 2. Reload the page. | Quantity still shows 6. Totals correct. | High |
| TC-17 | Quantity change with multiple line items | 1. Add Item B (qty 1). 2. Change Item A to 4. | Only Item A changes. Item B remains 1. Cart subtotal equals sum of both lines. | High |
| TC-18 | Server error during update | 1. Simulate the update API returning 500. 2. Set quantity to 5. | Field reverts to 2. A user-visible error is shown. Totals unchanged. No partial state. | Medium |
| TC-19 | Rapid successive changes | 1. Click "+" five times quickly. | Final quantity is 7. Totals match 7 units. No lost or out-of-order updates. | Medium |
| TC-20 | Keyboard accessibility | 1. Tab to the quantity field. 2. Use Arrow Up/Down. 3. Tab to "+" and "−" and press Space/Enter. | All controls reachable and operable by keyboard. Field has an accessible label (e.g. "Quantity for Item A"). | Medium |
| TC-21 | Screen reader announcements | 1. With a screen reader on, change quantity and trigger an error. | Quantity changes and error messages are announced (aria-live or equivalent). | Medium |
| TC-22 | Mobile numeric keyboard | 1. On a mobile device, tap the field. | Numeric keyboard appears (`inputmode="numeric"` or equivalent). | Low |

## AC-2: Setting the quantity to 0 asks "Remove this item?" and removes only on confirmation

| ID | Title | Steps | Expected result | Priority |
|---|---|---|---|---|
| TC-23 | Enter 0 and confirm | 1. Type `0`. 2. Blur. 3. In the prompt, click "Remove". | Prompt text is exactly "Remove this item?". Item A is removed from the cart. Totals and badge update. | High |
| TC-24 | Enter 0 and cancel | 1. Type `0`. 2. Blur. 3. Click "Cancel". | Item A remains with quantity 2. Totals unchanged. Focus returns to the quantity field. | High |
| TC-25 | Enter 0 and dismiss via Escape | 1. Type `0`. 2. Blur. 3. Press Escape. | Same as cancel (A-4): item remains with quantity 2. | High |
| TC-26 | Enter 0 and dismiss by clicking outside | 1. Type `0`. 2. Blur. 3. Click outside the dialog. | Same as cancel: item remains with quantity 2. | Medium |
| TC-27 | Decrement from 1 via "−" stepper | 1. Set quantity to 1. 2. Click "−". | "Remove this item?" prompt shown. No change until confirmed. | High |
| TC-28 | Prompt not shown before commit | 1. Type `0` but do not blur or press Enter. | No prompt yet (if commit is on blur/Enter per A-2). Record if implementation differs. | Low |
| TC-29 | Removal persists after reload | 1. Complete TC-23. 2. Reload. | Item A is still absent. | High |
| TC-30 | Cancel persists after reload | 1. Complete TC-24. 2. Reload. | Item A still present with quantity 2. | Medium |
| TC-31 | Removal of the last item | 1. Cart contains only Item A. 2. Type `0`, confirm. | Cart shows the empty-cart state. Badge shows 0 or hides. Checkout button is disabled/hidden. | High |
| TC-32 | Removal does not affect other items | 1. Cart has Item A and Item B. 2. Set Item A to 0, confirm. | Only Item A removed. Item B unchanged. | High |
| TC-33 | Server error on removal | 1. Simulate removal API returning 500. 2. Type `0`, confirm. | Item remains with quantity 2. Error message shown. | Medium |
| TC-34 | Leading-zero "00" treated as 0 | 1. Type `00`. 2. Blur. | Treated as 0: prompt shown. | Low |
| TC-35 | Dialog accessibility | 1. Trigger the prompt. | Dialog has role="dialog" or "alertdialog", focus moves into it, focus is trapped, and the question text is announced. | Medium |
| TC-36 | Double-trigger guard | 1. Type `0`. 2. Blur, then quickly press Enter. | Only one prompt is shown. | Low |

## AC-3: Quantity above 20 shows a message and keeps the previous quantity

| ID | Title | Steps | Expected result | Priority |
|---|---|---|---|---|
| TC-37 | Enter 21 (just above boundary) | 1. Type `21`. 2. Blur. | Message "You can buy at most 20 of this item." shown. Field reverts to 2. Totals unchanged. No API call made (or call rejected and state unchanged). | High |
| TC-38 | Enter a large number | 1. Type `999`. 2. Blur. | Same as TC-37. | High |
| TC-39 | Enter a very large number | 1. Paste `99999999999999999999`. 2. Blur. | Same as TC-37. No overflow, no crash, no NaN displayed. | Medium |
| TC-40 | "+" stepper at 20 | 1. Set quantity to 20. 2. Attempt to click "+". | "+" is disabled; if enabled, clicking shows the AC-3 message and quantity stays 20. | High |
| TC-41 | Keyboard Arrow Up at 20 | 1. Set quantity to 20. 2. Focus field, press Arrow Up. | Quantity stays 20. Message shown or action silently blocked (record actual). | Medium |
| TC-42 | Previous quantity preserved is the last committed value | 1. Set quantity to 5 and commit. 2. Type `30`, blur. | Message shown. Field reverts to 5 (not to the original 2). | High |
| TC-43 | Message clears on next valid entry | 1. Complete TC-37. 2. Type `3`, blur. | Message disappears. Quantity shows 3. | Medium |
| TC-44 | Message is per-item | 1. Cart has Item A and Item B. 2. Enter `25` for Item A. | Message appears only next to Item A. Item B shows no message. | Medium |
| TC-45 | Server-side enforcement | 1. Send a direct API request to set quantity to 21 (bypassing the UI). | Server rejects with a 4xx and a validation error. Cart quantity unchanged. | High |
| TC-46 | Server-side enforcement for 0 and negative | 1. Send direct API requests with quantity `0`, `-1`, `2.5`, `"abc"`. | Each rejected with 4xx. Cart unchanged. 0 via API does not silently remove the item unless the API contract says so (record). | High |
| TC-47 | Over-limit after reload | 1. Complete TC-37. 2. Reload. | Quantity shows 2. | Medium |
| TC-48 | Message accessibility | 1. Trigger the AC-3 message. | Message is associated with the field (aria-describedby) and announced. Field marked aria-invalid. | Medium |

## Cross-cutting and non-functional

| ID | Title | Steps | Expected result | Priority |
|---|---|---|---|---|
| TC-49 | Guest vs signed-in parity | 1. Repeat TC-01, TC-23, TC-37 as a guest and as a signed-in shopper. | Identical behaviour. | High |
| TC-50 | Cross-browser | 1. Run TC-01 to TC-05, TC-23, TC-24, TC-37 on latest Chrome, Firefox, Safari, Edge, and mobile Safari/Chrome. | Identical behaviour. Numeric input does not render browser-native spinners that bypass the 20 limit. | Medium |
| TC-51 | Cross-tab consistency | 1. Open cart in two tabs. 2. Change quantity to 5 in tab 1. 3. Refresh tab 2. | Tab 2 shows 5. | Low |
| TC-52 | Price recalculation accuracy | 1. Use an item priced 19.99. 2. Set quantity to 3, then 20. | Line subtotals are 59.97 and 399.80 with correct rounding. | Medium |
| TC-53 | Promotions and shipping thresholds | 1. With a free-shipping threshold or quantity discount configured, change quantity across the threshold. | Discounts and shipping messaging recalculate correctly. | Medium |
| TC-54 | Analytics event | 1. Change quantity; remove via 0. | Expected analytics events fire with correct item ID, old and new quantities. | Low |
| TC-55 | Performance | 1. Change quantity. | UI responds within the agreed budget (assume < 1 s to updated totals). | Low |

## Out of scope / open questions for the product owner

- Exact text and style of the invalid-input message (A-3).
- Whether the 20 limit should also respect available stock when stock is lower than 20 (A-5).
- Whether the "−" stepper at 1 should be disabled instead of prompting for removal (A-8).
- Whether the prompt is required when 0 is sent through the API rather than the UI (TC-46).
