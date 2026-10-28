---
feature: Cart — Change item quantity
feature_code: CART
tc_count: 18
tracker_issues: [CART-12]
risk_level: MEDIUM
runbook: N/A — no runbook requested for this story
implementation_pack: N/A — no implementation pack exists
spec: N/A — not automated yet
last_updated: 2026-10-23
---

# Test Cases — Cart — Change item quantity

| Field            | Value                                                   |
| ---------------- | ------------------------------------------------------- |
| **Project**      | Shop (name not given in the story)                      |
| **Author**       | <account email, redacted> — Senior QA Analyst                   |
| **Date Created** | 2026-10-23                                              |
| **Last Updated** | 2026-10-23                                              |
| **Methodology**  | ISTQB CTFL v4.0 — EP, BVA (three-value), Decision Table, Error Guessing |

**Assumptions (no codebase was available to verify them; the working directory is empty):**

- A1. The cart page is at `{APP_URL}/cart` and each line shows a numeric quantity input; a change is applied when the shopper presses Enter or the field loses focus.
- A2. The "Remove this item?" prompt is a modal dialog with a confirming button (**Remove**) and a declining button (**Cancel**).
- A3. The "You can buy at most 20 of this item." message is shown inline under the quantity field of the affected line.
- A4. For input the field cannot interpret as a whole number (decimal, negative, text, empty), the field reverts to the previous quantity and no change is sent. The ticket is silent on this; cases marked "Added by QA" cover it.
- A5. Stock-based limits below 20 are out of scope; the item under test has at least 20 in stock.
- A6. Tracker base URL unknown, so issue IDs are plain text.

Release gate cases carry the `@gate` tag.

---

## TC-CART-001: Set quantity to a valid mid-range value

| Field                  | Value                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                               |
| **Issue**              | CART-12                                                                                                |
| **Automation Score**   | HIGH (64/67.5)                                                                                         |
| **ISTQB Technique**    | EP — valid partition (whole number 1–20), representative value 5                                       |
| **Manual Env**         | Local, Staging                                                                                         |
| **Precondition**       | Shopper signed in; cart contains one item with quantity 1; item has ≥ 20 in stock (A5)                 |
| **Steps**              | 1. Open `{APP_URL}/cart` <br> 2. Clear the quantity field and type `5` <br> 3. Press Enter             |
| **Expected**           | Field shows `5`. No error message. Item remains in cart. Cart item count reflects 5.                   |
| **data-testid needed** | `cart-line-qty-input`, `cart-line-error`, `cart-item-count`                                            |
| **Source**             | AC-1                                                                                                   |
| **Note**               | N/A — no caveats                                                                                       |

---

## TC-CART-002: Set quantity to the minimum value 1

| Field                  | Value                                                                                          |
| ---------------------- | ---------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                        |
| **Issue**              | CART-12                                                                                        |
| **Automation Score**   | HIGH (62/67.5)                                                                                 |
| **ISTQB Technique**    | BVA — three-value, min (1)                                                                     |
| **Manual Env**         | Local, Staging                                                                                 |
| **Precondition**       | Cart contains one item with quantity 5                                                         |
| **Steps**              | 1. Open `{APP_URL}/cart` <br> 2. Clear the quantity field and type `1` <br> 3. Press Enter     |
| **Expected**           | Field shows `1`. No error message, no "Remove this item?" prompt. Item remains in cart.        |
| **data-testid needed** | `cart-line-qty-input`, `cart-line-error`, `remove-item-dialog`                                 |
| **Source**             | AC-1                                                                                           |
| **Note**               | N/A — no caveats                                                                               |

---

## TC-CART-003: Set quantity to min+1 (2)

| Field                  | Value                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                    |
| **Issue**              | CART-12                                                                                    |
| **Automation Score**   | HIGH (60/67.5)                                                                             |
| **ISTQB Technique**    | BVA — three-value, min+1 (2)                                                               |
| **Manual Env**         | Local, Staging                                                                             |
| **Precondition**       | Cart contains one item with quantity 1                                                     |
| **Steps**              | 1. Open `{APP_URL}/cart` <br> 2. Clear the quantity field and type `2` <br> 3. Press Enter |
| **Expected**           | Field shows `2`. No error message. Item remains in cart.                                   |
| **data-testid needed** | `cart-line-qty-input`, `cart-line-error`                                                   |
| **Source**             | AC-1                                                                                       |
| **Note**               | N/A — no caveats                                                                           |

---

## TC-CART-004: Set quantity to max-1 (19)

| Field                  | Value                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                     |
| **Issue**              | CART-12                                                                                     |
| **Automation Score**   | HIGH (60/67.5)                                                                              |
| **ISTQB Technique**    | BVA — three-value, max-1 (19)                                                               |
| **Manual Env**         | Local, Staging                                                                              |
| **Precondition**       | Cart contains one item with quantity 1; item has ≥ 20 in stock (A5)                         |
| **Steps**              | 1. Open `{APP_URL}/cart` <br> 2. Clear the quantity field and type `19` <br> 3. Press Enter |
| **Expected**           | Field shows `19`. No error message. Item remains in cart.                                   |
| **data-testid needed** | `cart-line-qty-input`, `cart-line-error`                                                    |
| **Source**             | AC-1                                                                                        |
| **Note**               | N/A — no caveats                                                                            |

---

## TC-CART-005: Set quantity to the maximum value 20

| Field                  | Value                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                    |
| **Issue**              | CART-12                                                                                     |
| **Automation Score**   | HIGH (62/67.5)                                                                              |
| **ISTQB Technique**    | BVA — three-value, max (20)                                                                 |
| **Manual Env**         | Local, Staging                                                                              |
| **Precondition**       | Cart contains one item with quantity 1; item has ≥ 20 in stock (A5)                         |
| **Steps**              | 1. Open `{APP_URL}/cart` <br> 2. Clear the quantity field and type `20` <br> 3. Press Enter |
| **Expected**           | Field shows `20`. The message "You can buy at most 20 of this item." is NOT shown. Item remains in cart. |
| **data-testid needed** | `cart-line-qty-input`, `cart-line-error`                                                    |
| **Source**             | AC-1, AC-3                                                                                  |
| **Note**               | Off-by-one check: 20 is allowed, 21 is not (TC-CART-006).                                   |

---

## TC-CART-006: Quantity 21 shows the maximum message and keeps the previous quantity

| Field                  | Value                                                                                                                                    |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                 |
| **Issue**              | CART-12                                                                                                                                  |
| **Automation Score**   | HIGH (62/67.5)                                                                                                                           |
| **ISTQB Technique**    | BVA — three-value, max+1 (21)                                                                                                            |
| **Manual Env**         | Local, Staging                                                                                                                           |
| **Precondition**       | Cart contains one item with quantity 3                                                                                                   |
| **Steps**              | 1. Open `{APP_URL}/cart` <br> 2. Clear the quantity field and type `21` <br> 3. Press Enter <br> 4. Reload the page                      |
| **Expected**           | Message "You can buy at most 20 of this item." is shown (exact text). Field shows `3`. After reload the quantity is still `3`.            |
| **data-testid needed** | `cart-line-qty-input`, `cart-line-error`                                                                                                 |
| **Source**             | AC-3                                                                                                                                     |
| **Note**               | Step 4 proves the rejected value was not persisted, not only hidden in the UI.                                                           |

---

## TC-CART-007: Quantity far above the maximum (999) is rejected the same way

| Field                  | Value                                                                                        |
| ---------------------- | -------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                      |
| **Issue**              | CART-12                                                                                      |
| **Automation Score**   | HIGH (58/67.5)                                                                               |
| **ISTQB Technique**    | EP — invalid partition (> 20), representative value 999                                      |
| **Manual Env**         | Local, Staging                                                                               |
| **Precondition**       | Cart contains one item with quantity 3                                                       |
| **Steps**              | 1. Open `{APP_URL}/cart` <br> 2. Clear the quantity field and type `999` <br> 3. Press Enter |
| **Expected**           | Message "You can buy at most 20 of this item." is shown. Field shows `3`.                    |
| **data-testid needed** | `cart-line-qty-input`, `cart-line-error`                                                     |
| **Source**             | AC-3                                                                                         |
| **Note**               | N/A — no caveats                                                                             |

---

## TC-CART-008: Quantity 0 with confirmation removes the item

| Field                  | Value                                                                                                                                                       |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                    |
| **Issue**              | CART-12                                                                                                                                                     |
| **Automation Score**   | HIGH (60/67.5)                                                                                                                                              |
| **ISTQB Technique**    | Decision Table — R1: quantity = 0, shopper confirms → item removed                                                                                          |
| **Manual Env**         | Local, Staging                                                                                                                                              |
| **Precondition**       | Cart contains two distinct items, item A with quantity 2 and item B with quantity 1                                                                         |
| **Steps**              | 1. Open `{APP_URL}/cart` <br> 2. Clear item A's quantity field and type `0` <br> 3. Press Enter <br> 4. In the dialog click **Remove** <br> 5. Reload the page |
| **Expected**           | A dialog with the text "Remove this item?" (exact) appears after step 3. After step 4 item A is no longer listed; item B remains with quantity 1. After reload item A is still absent. |
| **data-testid needed** | `cart-line-qty-input`, `remove-item-dialog`, `remove-item-confirm`, `cart-line`                                                                             |
| **Source**             | AC-2                                                                                                                                                        |
| **Note**               | Item B guards against removing the wrong line or clearing the whole cart.                                                                                   |

---

## TC-CART-009: Quantity 0 then cancel keeps the item with its previous quantity

| Field                  | Value                                                                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@sanity @p0 @e2e @cart @candidate @gate`                                                                                                  |
| **Issue**              | CART-12                                                                                                                                    |
| **Automation Score**   | HIGH (58/67.5)                                                                                                                             |
| **ISTQB Technique**    | Decision Table — R2: quantity = 0, shopper declines → item kept                                                                            |
| **Manual Env**         | Local, Staging                                                                                                                             |
| **Precondition**       | Cart contains one item with quantity 2                                                                                                     |
| **Steps**              | 1. Open `{APP_URL}/cart` <br> 2. Clear the quantity field and type `0` <br> 3. Press Enter <br> 4. In the dialog click **Cancel** <br> 5. Reload the page |
| **Expected**           | Dialog closes. Item is still listed and the field shows `2` (not `0`). After reload the quantity is still `2`.                             |
| **data-testid needed** | `cart-line-qty-input`, `remove-item-dialog`, `remove-item-cancel`, `cart-line`                                                             |
| **Source**             | AC-2                                                                                                                                       |
| **Note**               | "Only when the shopper confirms" means a declined dialog must leave the previous quantity, not 0.                                          |

---

## TC-CART-010: Dismissing the removal dialog with Esc counts as not confirming

| Field                  | Value                                                                                                                          |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                        |
| **Issue**              | CART-12                                                                                                                        |
| **Automation Score**   | MEDIUM (50/67.5)                                                                                                               |
| **ISTQB Technique**    | Decision Table — R3: quantity = 0, dialog dismissed without a choice → item kept                                                |
| **Manual Env**         | Local, Staging                                                                                                                 |
| **Precondition**       | Cart contains one item with quantity 2                                                                                         |
| **Steps**              | 1. Open `{APP_URL}/cart` <br> 2. Clear the quantity field and type `0` <br> 3. Press Enter <br> 4. Press Esc <br> 5. Repeat steps 2–3 and click outside the dialog |
| **Expected**           | In both variants the dialog closes, the item remains and the field shows `2`.                                                   |
| **data-testid needed** | `cart-line-qty-input`, `remove-item-dialog`                                                                                    |
| **Source**             | Added by QA (the ticket defines confirm only; dismissing without a choice must not remove the item)                             |
| **Note**               | Depends on A2 (modal dialog). If the prompt is inline, adapt step 4 to navigating away from the line.                           |

---

## TC-CART-011: Decimal quantity is not accepted

| Field                  | Value                                                                                         |
| ---------------------- | --------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                       |
| **Issue**              | CART-12                                                                                       |
| **Automation Score**   | HIGH (56/67.5)                                                                                |
| **ISTQB Technique**    | EP — invalid partition (non-whole number), representative value 2.5                           |
| **Manual Env**         | Local, Staging                                                                                |
| **Precondition**       | Cart contains one item with quantity 3                                                        |
| **Steps**              | 1. Open `{APP_URL}/cart` <br> 2. Clear the quantity field and type `2.5` <br> 3. Press Enter  |
| **Expected**           | The value is not applied; field shows `3`. No "Remove this item?" dialog. Item remains.       |
| **data-testid needed** | `cart-line-qty-input`, `cart-line-error`, `remove-item-dialog`                                |
| **Source**             | AC-1                                                                                          |
| **Note**               | AC-1 says "whole numbers"; the ticket does not say whether a message is shown (A4). Record what is shown. |

---

## TC-CART-012: Negative quantity is not accepted

| Field                  | Value                                                                                        |
| ---------------------- | -------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                      |
| **Issue**              | CART-12                                                                                      |
| **Automation Score**   | HIGH (56/67.5)                                                                               |
| **ISTQB Technique**    | EP — invalid partition (< 0), representative value -1                                        |
| **Manual Env**         | Local, Staging                                                                               |
| **Precondition**       | Cart contains one item with quantity 3                                                       |
| **Steps**              | 1. Open `{APP_URL}/cart` <br> 2. Clear the quantity field and type `-1` <br> 3. Press Enter  |
| **Expected**           | The value is not applied; field shows `3`. No "Remove this item?" dialog. Item remains.      |
| **data-testid needed** | `cart-line-qty-input`, `cart-line-error`, `remove-item-dialog`                               |
| **Source**             | AC-1                                                                                         |
| **Note**               | A negative value must not be treated as 0 (removal) or as a credit.                          |

---

## TC-CART-013: Non-numeric text is not accepted

| Field                  | Value                                                                                         |
| ---------------------- | --------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                       |
| **Issue**              | CART-12                                                                                       |
| **Automation Score**   | HIGH (54/67.5)                                                                                |
| **ISTQB Technique**    | EP — invalid partition (non-numeric), representative value `abc`                              |
| **Manual Env**         | Local, Staging                                                                                |
| **Precondition**       | Cart contains one item with quantity 3                                                        |
| **Steps**              | 1. Open `{APP_URL}/cart` <br> 2. Clear the quantity field and paste `abc` <br> 3. Press Enter |
| **Expected**           | The value is not applied; field shows `3`. No dialog. Item remains.                           |
| **data-testid needed** | `cart-line-qty-input`, `cart-line-error`                                                      |
| **Source**             | AC-1                                                                                          |
| **Note**               | Use paste, since a native number input may block typed letters but not pasted text.           |

---

## TC-CART-014: Empty quantity field keeps the previous quantity

| Field                  | Value                                                                                         |
| ---------------------- | --------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                       |
| **Issue**              | CART-12                                                                                       |
| **Automation Score**   | HIGH (54/67.5)                                                                                |
| **ISTQB Technique**    | EP — invalid partition (empty input)                                                          |
| **Manual Env**         | Local, Staging                                                                                |
| **Precondition**       | Cart contains one item with quantity 3                                                        |
| **Steps**              | 1. Open `{APP_URL}/cart` <br> 2. Clear the quantity field <br> 3. Click elsewhere on the page |
| **Expected**           | Field shows `3`. No "Remove this item?" dialog. Item remains.                                 |
| **data-testid needed** | `cart-line-qty-input`, `remove-item-dialog`                                                   |
| **Source**             | Added by QA (the ticket is silent on an empty field; an empty value must not be coerced to 0 and trigger removal) |
| **Note**               | Error Guessing: empty string parsed as 0 is a common defect.                                  |

---

## TC-CART-015: Line total and cart total update after a quantity change

| Field                  | Value                                                                                                              |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@sanity @p1 @e2e @cart @candidate @gate`                                                                          |
| **Issue**              | CART-12                                                                                                            |
| **Automation Score**   | HIGH (58/67.5)                                                                                                     |
| **ISTQB Technique**    | EP — valid partition, observed on the dependent totals                                                             |
| **Manual Env**         | Local, Staging                                                                                                     |
| **Precondition**       | Cart contains one item priced 10.00 with quantity 1; no discounts or shipping applied                               |
| **Steps**              | 1. Open `{APP_URL}/cart` <br> 2. Clear the quantity field and type `4` <br> 3. Press Enter                         |
| **Expected**           | Line total shows 40.00. Cart subtotal shows 40.00. Header cart badge shows 4.                                       |
| **data-testid needed** | `cart-line-qty-input`, `cart-line-total`, `cart-subtotal`, `cart-item-count`                                       |
| **Source**             | Added by QA (the story goal "buy the amount I need" implies the price follows the quantity; no AC states it)       |
| **Note**               | N/A — no caveats                                                                                                   |

---

## TC-CART-016: Changed quantity persists across reload and a new session

| Field                  | Value                                                                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                 |
| **Issue**              | CART-12                                                                                                                                 |
| **Automation Score**   | MEDIUM (44/67.5)                                                                                                                        |
| **ISTQB Technique**    | Error Guessing — client-only state not saved                                                                                            |
| **Manual Env**         | Staging                                                                                                                                 |
| **Precondition**       | Shopper signed in; cart contains one item with quantity 1                                                                               |
| **Steps**              | 1. Open `{APP_URL}/cart` <br> 2. Set quantity to `7` and press Enter <br> 3. Reload the page <br> 4. Sign out, sign in again, open the cart |
| **Expected**           | Quantity is `7` after step 3 and after step 4.                                                                                           |
| **data-testid needed** | `cart-line-qty-input`                                                                                                                   |
| **Source**             | Added by QA (the ticket is silent on persistence)                                                                                       |
| **Note**               | Step 4 applies only to signed-in carts; for guest carts stop at step 3.                                                                 |

---

## TC-CART-017: Removing the last item shows the empty cart state

| Field                  | Value                                                                                                                       |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                     |
| **Issue**              | CART-12                                                                                                                     |
| **Automation Score**   | HIGH (54/67.5)                                                                                                              |
| **ISTQB Technique**    | Error Guessing — empty state after removal                                                                                  |
| **Manual Env**         | Local, Staging                                                                                                              |
| **Precondition**       | Cart contains exactly one item with quantity 1                                                                              |
| **Steps**              | 1. Open `{APP_URL}/cart` <br> 2. Clear the quantity field and type `0` <br> 3. Press Enter <br> 4. Click **Remove**         |
| **Expected**           | No line remains. The empty-cart message is shown. Subtotal shows 0.00 or is hidden. Checkout button is disabled or hidden.  |
| **data-testid needed** | `cart-empty-state`, `cart-subtotal`, `checkout-button`                                                                      |
| **Source**             | Added by QA (the ticket is silent on removing the last item)                                                                |
| **Note**               | N/A — no caveats                                                                                                            |

---

## TC-CART-018: Maximum message clears after a valid quantity is entered

| Field                  | Value                                                                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                            |
| **Issue**              | CART-12                                                                                                                                            |
| **Automation Score**   | MEDIUM (48/67.5)                                                                                                                                   |
| **ISTQB Technique**    | Error Guessing — stale error state                                                                                                                 |
| **Manual Env**         | Local, Staging                                                                                                                                     |
| **Precondition**       | Cart contains one item with quantity 3                                                                                                             |
| **Steps**              | 1. Open `{APP_URL}/cart` <br> 2. Type `25` and press Enter <br> 3. Confirm the message is shown <br> 4. Clear the field, type `10`, press Enter     |
| **Expected**           | After step 4 the message "You can buy at most 20 of this item." is no longer shown and the field shows `10`.                                       |
| **data-testid needed** | `cart-line-qty-input`, `cart-line-error`                                                                                                           |
| **Source**             | Added by QA (the ticket says when the message appears, not when it goes away)                                                                      |
| **Note**               | N/A — no caveats                                                                                                                                   |

---

## Traceability

| Source | Cases                                                              |
| ------ | ------------------------------------------------------------------ |
| AC-1   | TC-CART-001, 002, 003, 004, 005, 011, 012, 013                     |
| AC-2   | TC-CART-008, 009                                                   |
| AC-3   | TC-CART-005, 006, 007                                              |
| Added by QA | TC-CART-010, 014, 015, 016, 017, 018                          |

**Release gate (`@gate`):** TC-CART-001, 005, 006, 008, 009, 015.

**Rules not applied:** the `context-discovery` and `testing-guidelines` rules were not loaded and no `qa-rules` skill is installed, so preconditions and expected results rest on assumptions A1–A6 rather than on verified code. The working directory contained no source files to ground them.
