---
feature: Cart — Change item quantity
feature_code: CART
tc_count: 12
tracker_issues: [CART-12]
risk_level: MEDIUM
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-23
---

# Test Cases — Cart: Change item quantity

| Field            | Value                                                   |
| ---------------- | ------------------------------------------------------- |
| **Project**      | Shop cart (project name not given)                      |
| **Author**       | QA — Senior QA Analyst                                  |
| **Date Created** | 2026-10-23                                              |
| **Last Updated** | 2026-10-23                                              |
| **Methodology**  | ISTQB CTFL v4.0 — EP, BVA (two-value), State Transition, Error Guessing |

## Assumptions

The working directory holds no source code, so the `context-discovery` rule could not be applied against a codebase and no project test-case template exists to derive from. Every `Precondition`, `Expected` and `data-testid needed` below is an assumption to confirm against the implementation:

- **A1.** The cart is a web page where each line item has a numeric quantity input; a change is committed on blur or Enter (not on every keystroke).
- **A2.** Each test starts with one item in the cart at quantity **3** ("the previous quantity").
- **A3.** The AC-3 message is shown inline beside the quantity field and the field value reverts to the previous quantity.
- **A4.** The AC-2 prompt is a dialog with the text "Remove this item?" and two actions, **Remove** and **Cancel**.
- **A5.** Inputs the ACs do not cover (decimals, negatives, empty, text) are rejected and the previous quantity is kept, with no removal prompt. No message text is assumed for them.
- **A6.** Line total and cart subtotal recompute after a successful change (implied by the story goal, not stated in an AC).
- **A7.** Tracker identifier `CART-12` matches the Linear format; the base URL is unknown, so the ID is given as plain text.
- **A8.** `data-testid` values are proposed names, not existing ones.

Release gate (`@gate`): TC-CART-001, TC-CART-004, TC-CART-005 — one pass per AC on the shortest path.

---

## TC-CART-001: Change quantity to a valid value in range

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                |
| **Issue**              | CART-12                                                                                                 |
| **Automation Score**   | HIGH (61/67.5)                                                                                          |
| **ISTQB Technique**    | EP — valid partition (whole number 1–20), representative value 5                                        |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Cart contains one item at quantity 3 (A2); cart page is open                                            |
| **Steps**              | 1. Clear the quantity field of the item <br> 2. Type `5` <br> 3. Press Enter (or blur the field)        |
| **Expected**           | Quantity field shows `5`. No message or dialog appears. Item remains in the cart. Line total and subtotal reflect 5 units (A6). |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`, `cart-subtotal`                                          |
| **Source**             | AC-1                                                                                                    |
| **Note**               | Gate case for AC-1.                                                                                     |

---

## TC-CART-002: Change quantity to the minimum, 1

| Field                  | Value                                                                                        |
| ---------------------- | -------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                      |
| **Issue**              | CART-12                                                                                      |
| **Automation Score**   | HIGH (58/67.5)                                                                               |
| **ISTQB Technique**    | BVA — two-value, lower boundary (min = 1)                                                    |
| **Manual Env**         | Local, Staging                                                                               |
| **Precondition**       | Cart contains one item at quantity 3 (A2); cart page is open                                 |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `1` <br> 3. Press Enter                             |
| **Expected**           | Quantity field shows `1`. No "Remove this item?" dialog appears. Item remains in the cart. Totals reflect 1 unit. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`                                                |
| **Source**             | AC-1                                                                                         |
| **Note**               | Guards the off-by-one where 1 is wrongly treated like 0 (AC-2).                              |

---

## TC-CART-003: Change quantity to the maximum, 20

| Field                  | Value                                                                                        |
| ---------------------- | -------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                      |
| **Issue**              | CART-12                                                                                      |
| **Automation Score**   | HIGH (58/67.5)                                                                               |
| **ISTQB Technique**    | BVA — two-value, upper boundary (max = 20)                                                   |
| **Manual Env**         | Local, Staging                                                                               |
| **Precondition**       | Cart contains one item at quantity 3 (A2); cart page is open                                 |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `20` <br> 3. Press Enter                            |
| **Expected**           | Quantity field shows `20`. The message "You can buy at most 20 of this item." is NOT shown. Totals reflect 20 units. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-qty-error`                                                 |
| **Source**             | AC-1, AC-3                                                                                   |
| **Note**               | Guards the off-by-one where 20 is wrongly rejected as "above 20".                            |

---

## TC-CART-004: Quantity 21 shows the maximum message and keeps the previous quantity

| Field                  | Value                                                                                                                 |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                              |
| **Issue**              | CART-12                                                                                                               |
| **Automation Score**   | HIGH (60/67.5)                                                                                                        |
| **ISTQB Technique**    | BVA — two-value, max+1 (21)                                                                                           |
| **Manual Env**         | Local, Staging                                                                                                        |
| **Precondition**       | Cart contains one item at quantity 3 (A2); cart page is open                                                          |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `21` <br> 3. Press Enter                                                     |
| **Expected**           | The message "You can buy at most 20 of this item." is shown (exact text). Quantity field reverts to `3`. Totals still reflect 3 units. Item remains in the cart. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-qty-error`, `cart-item-line-total`                                                  |
| **Source**             | AC-3                                                                                                                  |
| **Note**               | Gate case for AC-3. Where the message is rendered (inline vs toast) is assumption A3.                                 |

---

## TC-CART-005: Quantity 0 asks to remove and removes the item on confirm

| Field                  | Value                                                                                                                           |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                        |
| **Issue**              | CART-12                                                                                                                         |
| **Automation Score**   | HIGH (57/67.5)                                                                                                                  |
| **ISTQB Technique**    | State Transition — In cart → Remove prompt → Removed (valid transition, confirm)                                                |
| **Manual Env**         | Local, Staging                                                                                                                  |
| **Precondition**       | Cart contains one item at quantity 3 (A2); cart page is open                                                                    |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `0` <br> 3. Press Enter <br> 4. In the dialog, click **Remove**                        |
| **Expected**           | After step 3 a dialog with the text "Remove this item?" appears and the item is still in the cart. After step 4 the dialog closes, the item is no longer listed, and the cart shows its empty state with subtotal 0. |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`, `remove-item-confirm`, `cart-empty-state`                                          |
| **Source**             | AC-2                                                                                                                            |
| **Note**               | Gate case for AC-2. Confirm/cancel button labels are assumption A4.                                                             |

---

## TC-CART-006: Quantity 0 then cancel keeps the item at the previous quantity

| Field                  | Value                                                                                                                     |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @e2e @cart @candidate`                                                                                   |
| **Issue**              | CART-12                                                                                                                   |
| **Automation Score**   | HIGH (55/67.5)                                                                                                            |
| **ISTQB Technique**    | State Transition — In cart → Remove prompt → In cart (cancel; item must not be removed)                                   |
| **Manual Env**         | Local, Staging                                                                                                            |
| **Precondition**       | Cart contains one item at quantity 3 (A2); cart page is open                                                              |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `0` <br> 3. Press Enter <br> 4. In the "Remove this item?" dialog, click **Cancel** |
| **Expected**           | Dialog closes. Item remains in the cart. Quantity field shows `3`, not `0`. Totals reflect 3 units.                        |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`, `remove-item-cancel`                                                         |
| **Source**             | AC-2                                                                                                                      |
| **Note**               | "Only when the shopper confirms" — this is the negative half of AC-2.                                                     |

---

## TC-CART-007: Dismissing the remove dialog without choosing keeps the item

| Field                  | Value                                                                                                            |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                          |
| **Issue**              | CART-12                                                                                                          |
| **Automation Score**   | MEDIUM (49/67.5)                                                                                                 |
| **ISTQB Technique**    | State Transition — Remove prompt, ESC / click outside treated as "not confirmed"                                 |
| **Manual Env**         | Local, Staging                                                                                                   |
| **Precondition**       | Cart contains one item at quantity 3 (A2); the "Remove this item?" dialog is open after entering `0`             |
| **Steps**              | 1. Press ESC <br> 2. Reopen the dialog by entering `0` again and pressing Enter <br> 3. Click outside the dialog |
| **Expected**           | In both cases the dialog closes, the item remains, and the quantity field shows `3`. No removal occurs.          |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`                                                                      |
| **Source**             | Added by QA (AC-2 says removal happens only on confirm; the ticket is silent on dismissal paths)                 |
| **Note**               | If the dialog is non-dismissable by design, record that and mark step 1 and 3 as not applicable.                 |

---

## TC-CART-008: A value far above the maximum is rejected the same way as 21

| Field                  | Value                                                                                                     |
| ---------------------- | --------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                   |
| **Issue**              | CART-12                                                                                                   |
| **Automation Score**   | HIGH (56/67.5)                                                                                            |
| **ISTQB Technique**    | EP — invalid partition (> 20), representative value 999                                                   |
| **Manual Env**         | Local, Staging                                                                                            |
| **Precondition**       | Cart contains one item at quantity 3 (A2); cart page is open                                              |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `999` <br> 3. Press Enter                                        |
| **Expected**           | "You can buy at most 20 of this item." is shown. Quantity reverts to `3`. Item is not removed.            |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-qty-error`                                                              |
| **Source**             | AC-3                                                                                                      |
| **Note**               | Complements the boundary in TC-CART-004 with a partition representative.                                  |

---

## TC-CART-009: A decimal quantity is rejected and the previous quantity is kept

| Field                  | Value                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                |
| **Issue**              | CART-12                                                                                                                |
| **Automation Score**   | MEDIUM (50/67.5)                                                                                                       |
| **ISTQB Technique**    | EP — invalid partition (non-whole number), representative value 2.5                                                    |
| **Manual Env**         | Local, Staging                                                                                                         |
| **Precondition**       | Cart contains one item at quantity 3 (A2); cart page is open                                                           |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `2.5` <br> 3. Press Enter                                                     |
| **Expected**           | The value is not accepted: either the field refuses the `.` keystroke or the commit is rejected. Quantity shows `3`. No "Remove this item?" dialog. Item not removed. |
| **data-testid needed** | `cart-item-qty-input`                                                                                                  |
| **Source**             | AC-1                                                                                                                   |
| **Note**               | AC-1 says "whole numbers"; the ticket gives no message for a decimal, so none is asserted (A5). Watch for silent rounding to 2 or 3, which would be a defect. |

---

## TC-CART-010: A negative quantity is rejected without a removal prompt

| Field                  | Value                                                                                                                |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                              |
| **Issue**              | CART-12                                                                                                              |
| **Automation Score**   | MEDIUM (50/67.5)                                                                                                     |
| **ISTQB Technique**    | EP — invalid partition (< 0), representative value -1                                                                |
| **Manual Env**         | Local, Staging                                                                                                       |
| **Precondition**       | Cart contains one item at quantity 3 (A2); cart page is open                                                         |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `-1` <br> 3. Press Enter                                                    |
| **Expected**           | The value is not accepted. Quantity shows `3`. No "Remove this item?" dialog appears. Item not removed. Totals unchanged. |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`                                                                          |
| **Source**             | Added by QA (the ticket covers 0 and > 20 but is silent on negative values)                                          |
| **Note**               | A negative value must not fall through to the AC-2 removal path.                                                     |

---

## TC-CART-011: Empty or non-numeric input is rejected and the previous quantity is kept

| Field                  | Value                                                                                                                     |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                   |
| **Issue**              | CART-12                                                                                                                   |
| **Automation Score**   | MEDIUM (47/67.5)                                                                                                          |
| **ISTQB Technique**    | Error Guessing — empty commit, letters, whitespace, leading zeros                                                         |
| **Manual Env**         | Local, Staging                                                                                                            |
| **Precondition**       | Cart contains one item at quantity 3 (A2); cart page is open                                                              |
| **Steps**              | 1. Clear the field and press Enter (empty) <br> 2. Type `abc` and press Enter <br> 3. Type ` 4 ` (with spaces) and press Enter <br> 4. Type `05` and press Enter |
| **Expected**           | Steps 1–2: value not accepted, field shows `3`, no dialog, item not removed. Step 3: accepted as `4` or rejected, never a crash or `NaN`. Step 4: accepted as `5` (leading zero stripped) or rejected; never treated as 0 and never opens the removal dialog. |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`                                                                               |
| **Source**             | Added by QA (the ticket is silent on empty and non-numeric input)                                                         |
| **Note**               | Record which of the accept/reject alternatives the product chose for steps 3–4 and pin it in the automated test.          |

---

## TC-CART-012: A changed quantity persists after reloading the cart

| Field                  | Value                                                                                                     |
| ---------------------- | --------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                   |
| **Issue**              | CART-12                                                                                                   |
| **Automation Score**   | HIGH (54/67.5)                                                                                            |
| **ISTQB Technique**    | State Transition — persisted state survives reload; EP valid value 7                                      |
| **Manual Env**         | Local, Staging                                                                                            |
| **Precondition**       | Cart contains one item at quantity 3 (A2); cart page is open                                              |
| **Steps**              | 1. Change the quantity to `7` and press Enter <br> 2. Wait for the field to show `7` <br> 3. Reload the page |
| **Expected**           | After reload the item is still in the cart at quantity `7`; totals reflect 7 units.                        |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`                                                             |
| **Source**             | Added by QA (the story goal "buy the amount I need" implies the change is saved; no AC states it)         |
| **Note**               | Step 2 avoids a race between the save request and the reload (stale-write risk).                          |

---

## Rules not applied

The `context-discovery` rule could not be applied: the working directory contains no source code to ground preconditions or expected results in. The `qa-reference` references were not loaded; tracker link format and technique worked examples were applied from the command's own guidance.
