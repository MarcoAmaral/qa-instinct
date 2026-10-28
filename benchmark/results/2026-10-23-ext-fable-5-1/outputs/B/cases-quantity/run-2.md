# Test Cases: CART-12 — Change the quantity of an item in the cart

## Assumptions

Where the story is silent, these assumptions apply. Each is flagged in the relevant test case.

- **A1.** The quantity control is a free-text numeric input on the cart line item, with optional +/- stepper buttons. Tests cover both typed input and steppers; stepper cases are marked and can be dropped if steppers do not exist.
- **A2.** A quantity change is committed on blur, Enter, or pressing a stepper button, not on every keystroke.
- **A3.** After a valid change, the line subtotal and cart total update to reflect the new quantity.
- **A4.** Non-numeric, blank, negative, and decimal entries are invalid. The field reverts to the previous quantity. The exact message is unspecified, so tests only assert that the previous quantity is kept and the cart is unchanged.
- **A5.** The 1–20 limit is a per-line-item limit, independent of the shopper's other cart lines and of stock. Stock-driven limits are out of scope unless noted.
- **A6.** The "Remove this item?" dialog offers a confirm action and a cancel/dismiss action. Cancel, Escape, and clicking outside the dialog all count as not confirming.
- **A7.** Cart state persists across page reload for the same session.
- **A8.** Error messages are shown inline near the quantity field and are announced to assistive technology.

## Preconditions (all cases unless stated)

- Shopper has a cart containing at least one item ("Item A") with quantity 2.
- The item has at least 20 units in stock.
- Prices: Item A unit price is known so subtotal checks can be made.

---

## 1. Valid quantity changes (AC-1)

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-01 | Set quantity to minimum (1) | 1. Clear the quantity field for Item A. 2. Type `1`. 3. Commit (blur/Enter). | Quantity shows 1. Line subtotal = 1 × unit price. Cart total updates. No error shown. |
| TC-02 | Set quantity to maximum (20) | 1. Type `20`. 2. Commit. | Quantity shows 20. Subtotal = 20 × unit price. No error shown. |
| TC-03 | Set quantity to a mid-range value | 1. Type `7`. 2. Commit. | Quantity shows 7. Subtotal and total update. |
| TC-04 | Increase quantity | Starting at 2, set to 5. | Quantity 5. Subtotal and cart total increase correctly. |
| TC-05 | Decrease quantity (not to 0) | Starting at 5, set to 1. | Quantity 1. No removal dialog appears. Subtotal and total decrease correctly. |
| TC-06 | Re-enter the same quantity | Starting at 2, type `2` and commit. | Quantity stays 2. No error, no dialog, totals unchanged. |
| TC-07 | Boundary just inside lower limit vs. 0 | Set to 1, then set to 0, cancel the dialog. | After step 1 no dialog. After step 2 dialog appears. Confirms the boundary sits between 0 and 1. |
| TC-08 | Boundary just inside upper limit vs. 21 | Set to 20, then set to 21. | 20 accepted with no error. 21 shows the max-quantity error and field reverts to 20. |
| TC-09 | Leading zeros | Type `05` and commit. | Treated as 5. Quantity shows 5 (normalised). Subtotal = 5 × unit price. (A4) |
| TC-10 | Leading/trailing whitespace | Type ` 4 ` and commit. | Treated as 4. Quantity shows 4. (A4) |
| TC-11 | Stepper increment (A1) | Starting at 2, click `+` three times. | Quantity 5. Subtotal updates after each click. |
| TC-12 | Stepper decrement (A1) | Starting at 5, click `−` twice. | Quantity 3. Subtotal updates. |
| TC-13 | Stepper at upper bound (A1) | Set quantity to 20, click `+`. | Quantity stays 20. Either `+` is disabled or the max-quantity error is shown. Quantity never shows 21. |
| TC-14 | Stepper at lower bound (A1) | Set quantity to 1, click `−`. | "Remove this item?" dialog appears (same as AC-2). Quantity stays 1 until confirmed. |
| TC-15 | Change quantity on one of several items | Cart has Item A (qty 2) and Item B (qty 3). Set Item A to 6. | Item A = 6, Item B still 3. Cart total reflects both correctly. |
| TC-16 | Change persists on reload (A7) | Set Item A to 8. Reload the cart page. | Item A still shows 8. Totals correct. |
| TC-17 | Change persists to checkout | Set Item A to 8. Proceed to checkout. | Checkout summary shows Item A × 8 with matching subtotal. |
| TC-18 | Rapid successive changes | Type `3`, commit; immediately type `9`, commit; immediately type `4`, commit. | Final quantity 4. Totals reflect 4, not an earlier value (no race between requests). |
| TC-19 | Keyboard-only operation | Tab to the field, type `6`, press Enter. | Quantity 6 committed. Focus remains in a sensible place (field or next focusable element). |
| TC-20 | Quantity change updates cart badge / header count | Set Item A from 2 to 6. | Any header cart counter reflects the new item count. |

## 2. Removing via quantity 0 (AC-2)

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-21 | Entering 0 prompts for removal | Type `0` and commit. | Dialog with text exactly "Remove this item?" appears. Item is NOT yet removed. Cart total unchanged while dialog is open. |
| TC-22 | Confirm removal | Type `0`, commit, choose confirm. | Item A is removed from the cart. Cart total and item count update. No error shown. |
| TC-23 | Cancel removal via cancel button (A6) | Type `0`, commit, choose cancel. | Dialog closes. Item A remains with previous quantity (2). Totals unchanged. Field shows 2, not 0. |
| TC-24 | Dismiss removal via Escape key (A6) | Type `0`, commit, press Escape. | Same as TC-23: item remains, quantity reverts to 2. |
| TC-25 | Dismiss removal by clicking outside dialog (A6) | Type `0`, commit, click the page backdrop. | Same as TC-23. |
| TC-26 | Dialog identifies the correct item | Cart has Item A and Item B. Set Item B to 0, confirm. | Item B is removed; Item A untouched with original quantity. |
| TC-27 | Removing the last item | Cart has only Item A. Set to 0, confirm. | Cart becomes empty and shows the empty-cart state. Total is 0. |
| TC-28 | Leading zero form of 0 | Type `00` and commit. | Treated as 0. Dialog appears. (A4) |
| TC-29 | Remove then undo via browser back/reload | Set to 0, confirm, reload the page. | Item remains removed (removal was persisted). |
| TC-30 | Stepper to 0 (A1) | At quantity 1, click `−`. | Dialog appears. Cancel keeps quantity 1; confirm removes. |
| TC-31 | Dialog accessibility | Open dialog via keyboard. | Focus moves into the dialog. Dialog has an accessible name/role. Tab is trapped inside the dialog. Confirm and cancel are reachable by keyboard. Focus returns to the quantity field on cancel. |
| TC-32 | Quantity field state while dialog is open | Type `0`, commit, observe the field behind the dialog. | Field either shows previous quantity or is read-only/disabled. Shopper cannot submit a second change while the dialog is open. |
| TC-33 | Double-submit protection on confirm | Type `0`, commit, click confirm twice quickly. | Item removed once. No error, no duplicate request side effects. |

## 3. Quantity above 20 (AC-3)

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-34 | Entering 21 | Starting at 2, type `21` and commit. | Message exactly "You can buy at most 20 of this item." is shown. Field shows 2. Subtotal and total unchanged. |
| TC-35 | Entering a large number | Type `999` and commit. | Same message. Field shows 2. Totals unchanged. |
| TC-36 | Entering a very large number | Type `99999999999999999999` and commit. | Same message. Field reverts to 2. No overflow, no crash, no scientific-notation display. |
| TC-37 | Over-limit on an item already at 20 | Set to 20 (accepted), then type `25` and commit. | Message shown. Field reverts to 20 (the previous accepted value, not the original 2). |
| TC-38 | Over-limit via stepper (A1) | At 20, click `+`. | Quantity stays 20 and either the message is shown or `+` is disabled. (Covers TC-13 from the AC-3 angle.) |
| TC-39 | Error clears on next valid entry | Trigger the max error with `21`, then type `5` and commit. | Message disappears. Quantity 5. |
| TC-40 | Error persists until corrected | Trigger the max error, click elsewhere on the page without changing the field. | Message remains visible (or is cleared only by a new commit). Quantity still 2. Record observed behaviour. |
| TC-41 | Over-limit on one item does not affect others | Item A qty 2, Item B qty 3. Set Item A to `30`. | Message shown on Item A only. Item A stays 2, Item B stays 3. Totals unchanged. |
| TC-42 | Over-limit is enforced server-side | Using browser dev tools or API client, send a quantity update of 21 directly. | Server rejects the update. Cart on reload still shows the previous quantity. |
| TC-43 | Leading zeros over limit | Type `021` and commit. | Treated as 21. Message shown. Field reverts. |
| TC-44 | Error message accessibility (A8) | Trigger the max error with a screen reader running. | Message is announced (e.g. via `aria-live` or association with the field). Field is marked invalid. |

## 4. Invalid input (A4; not explicitly in ACs but required by "whole numbers")

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-45 | Decimal value | Type `2.5` and commit. | Not accepted. Field reverts to 2. Totals unchanged. No removal dialog. |
| TC-46 | Decimal that rounds to 0 | Type `0.4` and commit. | Not accepted as 0. No "Remove this item?" dialog. Field reverts to 2. |
| TC-47 | Decimal that rounds above 20 | Type `20.5` and commit. | Not accepted. Field reverts. Whether the max message or a generic message appears, 20.5 must not become 20 or 21 silently. Record behaviour. |
| TC-48 | Negative number | Type `-1` and commit. | Not accepted. Field reverts to 2. No removal dialog. |
| TC-49 | Negative zero | Type `-0` and commit. | Must not be silently treated as 0 without dialog. Either rejected (reverts to 2) or treated as 0 with dialog. Record behaviour. |
| TC-50 | Blank field | Clear the field and commit. | Not accepted. Field reverts to 2. Item not removed. |
| TC-51 | Non-numeric text | Type `abc` and commit. | Not accepted. Field reverts to 2. |
| TC-52 | Mixed alphanumeric | Type `1a` and commit. | Not accepted. Field reverts to 2. Does not become 1. |
| TC-53 | Scientific notation | Type `1e1` and commit. | Not silently accepted as 10. Field reverts to 2 (or, if the product decides to accept it, shows 10; record behaviour). |
| TC-54 | Plus sign | Type `+5` and commit. | Either rejected or treated as 5. Record behaviour. Must not error out. |
| TC-55 | Paste of invalid content | Paste `5; DROP TABLE carts` into the field and commit. | Not accepted. Field reverts to 2. No server error, no 500. |
| TC-56 | Script injection | Type `<script>alert(1)</script>` and commit. | Rejected. No script executes. Field reverts. |
| TC-57 | Unicode digits | Type `٣` (Arabic-Indic 3) or `３` (full-width 3) and commit. | Either rejected or normalised to 3. Must not crash. Record behaviour. |
| TC-58 | Hexadecimal | Type `0x10` and commit. | Rejected. Not treated as 16. |
| TC-59 | Mouse wheel over a focused number input | Focus the field, scroll the wheel. | Value does not change unintentionally (or, if it does, stays within 1–20 and commits normally). Record behaviour. |

## 5. Stock and availability interactions (A5, exploratory)

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-60 | Item with fewer than 20 in stock | Item C has 5 in stock. Set quantity to 10. | Record behaviour. Expected: a stock-based message, not "You can buy at most 20." Quantity should not exceed available stock. |
| TC-61 | Item becomes out of stock between changes | Set quantity to 3, then simulate stock going to 0, then set quantity to 4. | Graceful message, cart stays consistent. No silent acceptance. |

## 6. Concurrency, network, and resilience

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-62 | Network failure on quantity update | Throttle/offline the network, set quantity to 6, commit. | Shopper sees a failure message. Field reverts to 2 or shows pending state. On reconnect and reload, quantity is 2 (not partially applied). |
| TC-63 | Server error (5xx) on update | Simulate a 500 from the cart API. | User-facing error shown. Quantity reverts. No raw stack trace shown. |
| TC-64 | Same cart open in two tabs | Tab 1 sets quantity to 6. Tab 2 (stale, showing 2) sets quantity to 3. | Final persisted quantity is 3 (last write wins) or a conflict is surfaced. Tab 1 on reload shows the persisted value. No duplicate line items. |
| TC-65 | Session expiry during change | Let session expire, then change quantity. | Shopper is prompted to log in or the change is applied to the guest cart. No silent loss of the cart. |
| TC-66 | Slow response, user navigates away | Set quantity to 6, immediately navigate to checkout before the response returns. | Checkout shows a consistent quantity (6 if the update succeeded, 2 otherwise). Never an intermediate or blank quantity. |

## 7. Cross-platform and accessibility

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-67 | Mobile virtual keyboard | On a mobile device, tap the field. | A numeric keyboard appears (`inputmode="numeric"` or equivalent). Entry of 1–20 works. |
| TC-68 | Mobile dialog | On mobile, set to 0 and commit. | "Remove this item?" dialog is fully visible and both actions are tappable. |
| TC-69 | Screen reader: field labelling | Navigate to the field with a screen reader. | Field is announced with a label including the item name (e.g. "Quantity, Item A"). |
| TC-70 | Browser matrix | Repeat TC-01, TC-21, TC-34 on latest Chrome, Firefox, Safari, Edge, and mobile Safari/Chrome. | Behaviour identical across browsers. |
| TC-71 | Zoom 200% | At 200% browser zoom, change quantity and trigger the max error. | Field, message, and dialog remain legible and usable with no overlap or clipping. |

## 8. Non-functional / regression checks

| ID | Title | Steps | Expected result |
|---|---|---|---|
| TC-72 | Analytics / audit event | Change quantity and remove an item. | If the product emits cart events, correct events fire with correct quantities (verify in network tab or analytics debug). |
| TC-73 | Promotions recalculated | Cart has a "buy 3 get 1 free" promo. Change Item A from 2 to 3. | Promo applies. Change back to 2: promo is removed. Totals correct. |
| TC-74 | Shipping/tax recalculated | Change quantity from 2 to 10. | Any quantity- or value-dependent shipping and tax lines update. |
| TC-75 | Saved-for-later / wishlist unaffected | Item A is also in saved-for-later. Change cart quantity. | Saved-for-later entry is unchanged. |
| TC-76 | Performance | Measure time from commit to updated total. | Update completes within the product's agreed latency budget (assumed ≤ 1 s on a normal connection). |

---

## Traceability

| Acceptance criterion | Covering test cases |
|---|---|
| AC-1 (1–20 whole numbers) | TC-01 – TC-20, TC-45 – TC-59 |
| AC-2 (0 prompts, removes only on confirm) | TC-21 – TC-33, TC-46, TC-49 |
| AC-3 (>20 shows message, keeps previous) | TC-34 – TC-44, TC-47 |
| Not covered by ACs (gaps to raise with product) | TC-60 – TC-61 (stock), TC-62 – TC-66 (resilience), TC-67 – TC-71 (platform/a11y), TC-72 – TC-76 (regression) |

## Open questions for the product owner (tests proceed on assumptions above)

1. What message, if any, is shown for non-numeric, blank, decimal, or negative input? (A4)
2. Is there a stepper control, and should it be disabled at the bounds or show the error? (A1)
3. Does the 20 limit apply per line item, per SKU across variants, or per order? (A5)
4. How should the 20 limit interact with items that have fewer than 20 in stock? (TC-60)
5. Should the max-quantity error clear on blur, on next valid input, or after a timeout? (TC-40)
