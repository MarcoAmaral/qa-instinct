# Test Cases — CART-12: Change the quantity of an item in the cart

## Assumptions

The story does not specify the following. These assumptions apply to every test case below unless a case says otherwise.

| # | Assumption |
|---|------------|
| A1 | The cart page shows each line item with an editable quantity input and optional +/− stepper buttons. Both paths lead to the same validation. |
| A2 | A quantity change is committed on blur, Enter, or an explicit "Update" action. "Commit" below means whichever of these the implementation uses. |
| A3 | Each line item has a stock level. Stock limits are out of scope for this story and are tested only as a conflict check (TC-32). |
| A4 | The "Remove this item?" prompt is a modal dialog with Confirm and Cancel actions. It can also be dismissed with Escape or by clicking outside. |
| A5 | Line subtotal, cart subtotal, item count badge, and any server-side cart state must reflect a committed quantity. |
| A6 | Non-numeric, decimal, negative, and blank input are rejected and the previous quantity is restored. The story defines messages only for 0 and >20, so the exact message text for other invalid input is not asserted. |
| A7 | The 1–20 limit is per line item, not across the cart. |
| A8 | A shopper can be a guest or signed in. Behaviour is identical unless stated. |
| A9 | The previous quantity is the last successfully committed quantity, not an intermediate rejected value. |

---

## AC-1: The quantity field accepts whole numbers from 1 to 20

### TC-01 — Set quantity to the lower boundary (1)
**Priority:** High
**Preconditions:** Cart contains one item with quantity 3.
**Steps:**
1. Clear the quantity field and type `1`.
2. Commit the change.

**Expected:** Quantity shows 1. Line subtotal equals unit price × 1. Cart subtotal and item count update. No error is shown. Reloading the page shows quantity 1.

### TC-02 — Set quantity to the upper boundary (20)
**Priority:** High
**Preconditions:** Cart contains one item with quantity 3.
**Steps:**
1. Clear the quantity field and type `20`.
2. Commit the change.

**Expected:** Quantity shows 20. Line subtotal equals unit price × 20. Totals update. No error is shown. Value persists on reload.

### TC-03 — Set a mid-range quantity (10)
**Priority:** Medium
**Preconditions:** Cart contains one item with quantity 1.
**Steps:**
1. Change the quantity to `10` and commit.

**Expected:** Quantity shows 10. Totals update correctly. No error.

### TC-04 — Increase quantity by one using the + stepper
**Priority:** Medium
**Preconditions:** Cart contains one item with quantity 5. Stepper buttons exist (A1).
**Steps:**
1. Click + once.

**Expected:** Quantity becomes 6 and totals update. The change is committed without further action.

### TC-05 — Decrease quantity by one using the − stepper
**Priority:** Medium
**Preconditions:** Cart contains one item with quantity 5.
**Steps:**
1. Click − once.

**Expected:** Quantity becomes 4 and totals update.

### TC-06 — Stepper + at 20 does not exceed the limit
**Priority:** High
**Preconditions:** Cart contains one item with quantity 20.
**Steps:**
1. Click + once.

**Expected:** Quantity stays 20. Either the + button is disabled or the AC-3 message is shown. Totals unchanged.

### TC-07 — Stepper − at 1 triggers the removal prompt
**Priority:** High
**Preconditions:** Cart contains one item with quantity 1.
**Steps:**
1. Click − once.

**Expected:** "Remove this item?" prompt appears (AC-2 path). Quantity is not changed until the shopper confirms.

### TC-08 — Setting the same quantity is a no-op
**Priority:** Low
**Preconditions:** Cart contains one item with quantity 4.
**Steps:**
1. Clear the field, type `4`, commit.

**Expected:** Quantity remains 4. No error, no duplicate network request that changes state, totals unchanged.

### TC-09 — Quantity change on one item does not affect other items
**Priority:** High
**Preconditions:** Cart contains item A (qty 2) and item B (qty 5).
**Steps:**
1. Change item A to `7` and commit.

**Expected:** Item A shows 7. Item B still shows 5. Cart subtotal equals (A price × 7) + (B price × 5).

### TC-10 — Leading zeros are normalised
**Priority:** Low
**Preconditions:** Cart contains one item with quantity 2.
**Steps:**
1. Type `007` and commit.

**Expected:** Quantity is accepted as 7 and displayed as `7`.

### TC-11 — Surrounding whitespace is trimmed
**Priority:** Low
**Preconditions:** Cart contains one item with quantity 2.
**Steps:**
1. Type ` 5 ` (with spaces) and commit.

**Expected:** Quantity is accepted as 5.

### TC-12 — Decimal input is rejected
**Priority:** High
**Preconditions:** Cart contains one item with quantity 3.
**Steps:**
1. Type `2.5` and commit.

**Expected:** Value is rejected. Quantity reverts to 3. A validation message is shown (text not asserted, A6). Totals unchanged. Field remains focused or focus returns to it.

### TC-13 — Negative input is rejected
**Priority:** High
**Preconditions:** Cart contains one item with quantity 3.
**Steps:**
1. Type `-1` and commit.

**Expected:** Value is rejected. Quantity reverts to 3. Removal prompt is **not** shown. Totals unchanged.

### TC-14 — Alphabetic and symbol input is rejected
**Priority:** High
**Preconditions:** Cart contains one item with quantity 3.
**Steps:**
1. For each of `abc`, `5a`, `+5`, `1e1`, `٣` (Arabic-Indic digit), `５` (full-width digit), type the value and commit.

**Expected:** Each value is rejected, or `+5`/`1e1` are rejected rather than parsed to 5/10. Quantity reverts to 3 each time. Totals unchanged.

### TC-15 — Blank input is rejected
**Priority:** High
**Preconditions:** Cart contains one item with quantity 3.
**Steps:**
1. Clear the field completely and commit.

**Expected:** Quantity reverts to 3. The item is **not** removed and the removal prompt is **not** shown. Totals unchanged.

### TC-16 — Pasting an invalid value is rejected
**Priority:** Medium
**Preconditions:** Clipboard contains `12abc`. Cart contains one item with quantity 3.
**Steps:**
1. Paste into the field and commit.

**Expected:** Value is rejected. Quantity reverts to 3.

### TC-17 — Quantity is not changed until committed
**Priority:** Medium
**Preconditions:** Cart contains one item with quantity 3.
**Steps:**
1. Type `8` but do not commit.
2. Observe totals.
3. Press Escape or navigate away without committing.

**Expected:** Totals do not change while typing. After abandoning, quantity shows 3 on return.

### TC-18 — Quantity persists for a signed-in shopper across devices
**Priority:** Medium
**Preconditions:** Signed-in shopper, cart contains one item with quantity 2.
**Steps:**
1. Change to `6` and commit.
2. Open the cart in a second browser session signed in as the same shopper.

**Expected:** Second session shows quantity 6.

### TC-19 — Server rejects values the client would reject
**Priority:** High
**Preconditions:** API access to the cart update endpoint.
**Steps:**
1. Send quantity update requests directly with values `0`, `21`, `-1`, `2.5`, `"abc"`, `null`, and a missing quantity field.

**Expected:** Each request returns a 4xx validation error. Cart quantity is unchanged. `0` via API does not remove the item unless a separate explicit remove call is defined.

### TC-20 — Server accepts boundary values
**Priority:** High
**Preconditions:** API access.
**Steps:**
1. Send quantity update requests with `1` and `20`.

**Expected:** Both return success and the cart reflects the new quantity.

---

## AC-2: Setting the quantity to 0 asks "Remove this item?" and removes the item only when the shopper confirms

### TC-21 — Entering 0 shows the removal prompt with exact text
**Priority:** High
**Preconditions:** Cart contains one item with quantity 2.
**Steps:**
1. Type `0` and commit.

**Expected:** A prompt appears containing the exact text "Remove this item?" with Confirm and Cancel actions. The item is still in the cart behind the prompt. Totals unchanged.

### TC-22 — Confirming removes the item
**Priority:** High
**Preconditions:** TC-21 prompt is open.
**Steps:**
1. Click Confirm.

**Expected:** Item is removed from the cart. Cart subtotal and item count exclude it. Reloading confirms it is gone. If it was the only item, the empty-cart state is shown.

### TC-23 — Cancelling keeps the item with its previous quantity
**Priority:** High
**Preconditions:** Cart contains one item with quantity 2. Prompt open after entering 0.
**Steps:**
1. Click Cancel.

**Expected:** Prompt closes. Item remains with quantity 2 (not 0, not blank). Totals unchanged. Reloading shows quantity 2.

### TC-24 — Dismissing the prompt with Escape behaves like Cancel
**Priority:** Medium
**Preconditions:** Prompt open after entering 0 on an item with quantity 2.
**Steps:**
1. Press Escape.

**Expected:** Same as TC-23.

### TC-25 — Clicking outside the prompt behaves like Cancel
**Priority:** Medium
**Preconditions:** Prompt open after entering 0 on an item with quantity 2.
**Steps:**
1. Click the page backdrop outside the dialog.

**Expected:** Same as TC-23. The item is never removed without an explicit Confirm.

### TC-26 — Removal via 0 targets only the chosen item
**Priority:** High
**Preconditions:** Cart contains item A (qty 1) and item B (qty 3).
**Steps:**
1. Set item A to `0`, commit, confirm.

**Expected:** Item A is removed. Item B remains with quantity 3.

### TC-27 — Entering 0 with leading zeros (e.g. `00`) is treated as 0
**Priority:** Low
**Preconditions:** Cart contains one item with quantity 2.
**Steps:**
1. Type `00` and commit.

**Expected:** Removal prompt is shown, same as TC-21.

### TC-28 — Navigating away with the prompt open does not remove the item
**Priority:** Medium
**Preconditions:** Prompt open after entering 0 on an item with quantity 2.
**Steps:**
1. Reload the page or use the browser back button.
2. Return to the cart.

**Expected:** Item is still present with quantity 2.

### TC-29 — Prompt is keyboard accessible
**Priority:** Medium
**Preconditions:** Cart contains one item with quantity 2.
**Steps:**
1. Using keyboard only, Tab to the quantity field, type `0`, press Enter.
2. Observe focus.
3. Tab between Confirm and Cancel; activate Cancel with Enter.

**Expected:** Focus moves into the dialog on open. The dialog has an accessible role and the prompt text is announced. After Cancel, focus returns to the quantity field. Quantity shows 2.

### TC-30 — Confirm action removes only after the server acknowledges
**Priority:** Medium
**Preconditions:** Network throttled or server returns an error on remove.
**Steps:**
1. Enter `0`, commit, click Confirm while the remove request fails.

**Expected:** An error is shown. The item remains in the cart with its previous quantity. No optimistic removal that silently reverts without feedback.

---

## AC-3: A quantity above 20 shows "You can buy at most 20 of this item." and keeps the previous quantity

### TC-31 — Entering 21 shows the exact message and keeps the previous quantity
**Priority:** High
**Preconditions:** Cart contains one item with quantity 5.
**Steps:**
1. Type `21` and commit.

**Expected:** Message "You can buy at most 20 of this item." is shown, associated with the field (visually and via `aria-describedby` or equivalent). Quantity shows 5. Totals unchanged. Reloading shows 5.

### TC-32 — Stock limit lower than 20 does not conflict with the message
**Priority:** Medium
**Preconditions:** Item has stock 8. Quantity 2. (A3)
**Steps:**
1. Type `25` and commit.
2. Type `10` and commit.

**Expected:** Step 1 shows "You can buy at most 20 of this item." and keeps 2. Step 2 behaviour is governed by stock rules outside this story; record the observed result. Quantity never exceeds 20 in either case.

### TC-33 — Large values are rejected without overflow
**Priority:** Medium
**Preconditions:** Cart contains one item with quantity 5.
**Steps:**
1. For each of `100`, `999999999999`, `99999999999999999999999`, type the value and commit.

**Expected:** Each shows the AC-3 message and keeps quantity 5. No crash, no scientific-notation display, no acceptance of a truncated value.

### TC-34 — Message clears after a valid correction
**Priority:** High
**Preconditions:** TC-31 state, message visible, quantity 5.
**Steps:**
1. Type `12` and commit.

**Expected:** Message disappears. Quantity shows 12. Totals update.

### TC-35 — Repeated invalid entries keep the last committed value, not an intermediate one
**Priority:** Medium
**Preconditions:** Cart contains one item with quantity 5.
**Steps:**
1. Type `30`, commit (rejected).
2. Type `40`, commit (rejected).

**Expected:** Quantity shows 5 after both steps (A9). Message is shown once per attempt, not stacked.

### TC-36 — Message is scoped to the item being edited
**Priority:** Medium
**Preconditions:** Cart contains item A (qty 2) and item B (qty 3).
**Steps:**
1. Set item A to `21` and commit.

**Expected:** Message appears next to item A only. Item B shows no message and keeps quantity 3.

### TC-37 — Over-limit message does not appear for values of exactly 20
**Priority:** High
**Preconditions:** Cart contains one item with quantity 19.
**Steps:**
1. Type `20` and commit.

**Expected:** No message. Quantity is 20. (Guards against an off-by-one `>= 20` check.)

### TC-38 — Over-limit input via stepper hold or rapid clicks
**Priority:** Low
**Preconditions:** Cart contains one item with quantity 18. Steppers exist.
**Steps:**
1. Click + rapidly five times.

**Expected:** Quantity stops at 20. Either the button disables at 20 or the AC-3 message appears. Quantity never shows 21 or higher, even transiently after the final response.

---

## Cross-cutting and non-functional

### TC-39 — Concurrent edits on two tabs
**Priority:** Low
**Preconditions:** Signed-in shopper, cart open in two tabs, item quantity 3.
**Steps:**
1. In tab 1 set quantity to `6` and commit.
2. In tab 2 (not refreshed) set quantity to `9` and commit.
3. Refresh both tabs.

**Expected:** Both tabs show the same quantity (last write wins, assumed 9). No duplicate line items and no error that leaves the cart in an inconsistent state.

### TC-40 — Quantity input has correct HTML attributes
**Priority:** Medium
**Preconditions:** Cart contains one item.
**Steps:**
1. Inspect the quantity input.

**Expected:** Input has a visible or screen-reader label naming the product. Numeric input mode (`inputmode="numeric"` or `type="number"` with `min="0"` or `"1"`, `max="20"`, `step="1"`). Client attributes do not replace server validation (TC-19).

### TC-41 — Mobile numeric keyboard
**Priority:** Low
**Preconditions:** iOS and Android device.
**Steps:**
1. Tap the quantity field.

**Expected:** A numeric keypad opens. Entering and committing `7` works as in TC-03.

### TC-42 — Loading state during update
**Priority:** Low
**Preconditions:** Network throttled to slow 3G.
**Steps:**
1. Change quantity from 2 to `8` and commit.

**Expected:** A loading indicator or disabled field is shown until the server responds. The field cannot be committed again until the first update completes. Final state shows 8.

### TC-43 — Network failure during a valid update
**Priority:** Medium
**Preconditions:** Server returns 500 on quantity update.
**Steps:**
1. Change quantity from 2 to `8` and commit.

**Expected:** An error message is shown. Quantity reverts to 2. Totals unchanged. Retrying after the server recovers succeeds.

### TC-44 — Cart totals recalculate correctly, including tax and discounts
**Priority:** Medium
**Preconditions:** Item has a per-unit discount or a quantity-tier promotion; tax applies.
**Steps:**
1. Change quantity from 1 to `10` and commit.

**Expected:** Line subtotal, discount, tax, and order total all reflect 10 units. No stale values anywhere on the page, including a mini-cart or header badge.

### TC-45 — Analytics or event tracking (if present)
**Priority:** Low
**Preconditions:** Event tracking enabled in test environment.
**Steps:**
1. Change quantity 2 to 5. Then set to 0 and confirm.

**Expected:** A quantity-change event fires with old and new values, and a remove event fires on confirmed removal only. Cancelling the prompt fires no remove event.

---

## Traceability

| AC | Test cases |
|----|-----------|
| AC-1 | TC-01 to TC-20, TC-37, TC-40, TC-41 |
| AC-2 | TC-07, TC-21 to TC-30, TC-45 |
| AC-3 | TC-06, TC-31 to TC-38 |
| Cross-cutting | TC-39, TC-42, TC-43, TC-44 |

## Open questions for the product owner

These do not block testing under the stated assumptions but should be confirmed.

1. Is the 1–20 limit per line item or per product across the whole cart (e.g. same product in two variants)?
2. What message, if any, is shown for blank, decimal, negative, or non-numeric input?
3. Should the + stepper be disabled at 20, or show the AC-3 message?
4. Should Escape and backdrop click on the removal prompt be treated as Cancel?
5. Does the server side enforce the same 1–20 range, and what does the API return for 0?
