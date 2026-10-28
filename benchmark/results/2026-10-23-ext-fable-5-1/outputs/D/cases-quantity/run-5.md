---
feature: Cart — Change item quantity
feature_code: CART
tc_count: 13
tracker_issues: [CART-12]
risk_level: MEDIUM
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-23
---

# Test Cases — Cart — Change item quantity

| Field            | Value                                                                      |
| ---------------- | -------------------------------------------------------------------------- |
| **Project**      | N/A — project name not stated in the request                               |
| **Author**       | Marco — Senior QA Analyst                                                  |
| **Date Created** | 2026-10-23                                                                 |
| **Last Updated** | 2026-10-23                                                                 |
| **Methodology**  | ISTQB CTFL v4.0 — EP, BVA (two-value), Decision Table, Error Guessing      |

## Scope and assumptions

The workspace contains no source code, so no precondition or expected result below was verified against an implementation. Every case is grounded in the story text only. Assumptions made to fill gaps:

- **A1 — How a change is committed.** The quantity field is a numeric text input on the cart line; a new value is applied when the field loses focus or the shopper presses Enter. If the real UI uses an **Update** button or +/− steppers, replace the "commit the value" step accordingly.
- **A2 — Rejected input keeps the previous quantity.** AC-3 states this for values above 20. The same behaviour is assumed for negative, decimal, non-numeric and empty input, which the story does not cover (cases 008–010 are marked Added by QA).
- **A3 — Cancelling the removal prompt.** AC-2 says the item is removed "only when the shopper confirms". It is assumed that Cancel, ESC and clicking outside the dialog all keep the item at its previous quantity.
- **A4 — Totals.** The line total and cart subtotal are assumed to recalculate after a successful change. The story implies this ("buy the amount I need") but no AC states it.
- **A5 — Stock limits** are out of scope; 20 is treated as a fixed per-item cap regardless of inventory.
- **A6 — Tracker.** `CART-12` is a Linear-style identifier; no base URL was given, so the ID is used as plain text.

**Release gate:** cases tagged `@gate` (001, 003, 004, 006, 007) answer "does the feature work and did it break the cart?" and should run on every candidate build.

---

## TC-CART-001: Change quantity to a valid value inside the range

| Field                  | Value                                                                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                                                               |
| **Issue**              | CART-12                                                                                                                                                                                                |
| **Automation Score**   | HIGH (64/67.5)                                                                                                                                                                                         |
| **ISTQB Technique**    | EP — EP1 (valid: whole number 1–20), representative value 5                                                                                                                                            |
| **Manual Env**         | Local, Staging                                                                                                                                                                                         |
| **Precondition**       | Shopper is on the cart page with one item at quantity 2 (unit price known, e.g. 10.00)                                                                                                                 |
| **Steps**              | 1. Clear the quantity field for the item <br> 2. Type `5` <br> 3. Commit the value (blur or Enter, per A1)                                                                                             |
| **Expected**           | Field shows `5`. No message or dialog appears. Item stays in the cart. Line total and cart subtotal reflect 5 × unit price (per A4). The item's cart count elsewhere on the page (header badge) shows 5. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`, `cart-subtotal`                                                                                                                                         |
| **Source**             | AC-1                                                                                                                                                                                                   |
| **Note**               | Assumption A1 and A4 apply.                                                                                                                                                                            |

---

## TC-CART-002: Change quantity to the minimum value 1

| Field                  | Value                                                                                                               |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                             |
| **Issue**              | CART-12                                                                                                             |
| **Automation Score**   | HIGH (61/67.5)                                                                                                      |
| **ISTQB Technique**    | BVA — two-value, lower boundary (min = 1)                                                                           |
| **Manual Env**         | Local, Staging                                                                                                      |
| **Precondition**       | Shopper is on the cart page with one item at quantity 3                                                             |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `1` <br> 3. Commit the value                                               |
| **Expected**           | Field shows `1`. No "Remove this item?" dialog and no limit message appear. Item stays in the cart. Totals reflect 1 × unit price. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`                                                                       |
| **Source**             | AC-1                                                                                                                |
| **Note**               | Guards against an off-by-one where 1 is wrongly treated like 0.                                                     |

---

## TC-CART-003: Change quantity to the maximum value 20

| Field                  | Value                                                                                                                     |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate @gate`                                                                             |
| **Issue**              | CART-12                                                                                                                   |
| **Automation Score**   | HIGH (61/67.5)                                                                                                            |
| **ISTQB Technique**    | BVA — two-value, upper boundary (max = 20)                                                                                |
| **Manual Env**         | Local, Staging                                                                                                            |
| **Precondition**       | Shopper is on the cart page with one item at quantity 2                                                                   |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `20` <br> 3. Commit the value                                                    |
| **Expected**           | Field shows `20`. The message "You can buy at most 20 of this item." is NOT shown. Totals reflect 20 × unit price.        |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-qty-error`, `cart-item-line-total`                                                      |
| **Source**             | AC-1, AC-3                                                                                                                |
| **Note**               | Guards against an off-by-one where the cap is applied with `>=` instead of `>`.                                           |

---

## TC-CART-004: Quantity 21 shows the limit message and keeps the previous quantity

| Field                  | Value                                                                                                                                                                                               |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                                                            |
| **Issue**              | CART-12                                                                                                                                                                                             |
| **Automation Score**   | HIGH (62/67.5)                                                                                                                                                                                      |
| **ISTQB Technique**    | BVA — two-value, max + 1 (21)                                                                                                                                                                       |
| **Manual Env**         | Local, Staging                                                                                                                                                                                      |
| **Precondition**       | Shopper is on the cart page with one item at quantity 4                                                                                                                                             |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `21` <br> 3. Commit the value                                                                                                                              |
| **Expected**           | The message "You can buy at most 20 of this item." appears next to the item. The field reverts to `4`. Line total and subtotal are unchanged (4 × unit price). The item stays in the cart.          |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-qty-error`, `cart-item-line-total`, `cart-subtotal`                                                                                                               |
| **Source**             | AC-3                                                                                                                                                                                                |
| **Note**               | Assert the exact message text, including the final full stop.                                                                                                                                       |

---

## TC-CART-005: A quantity far above the limit is rejected the same way

| Field                  | Value                                                                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                               |
| **Issue**              | CART-12                                                                                                                               |
| **Automation Score**   | MEDIUM (50/67.5)                                                                                                                      |
| **ISTQB Technique**    | EP — EP2 (invalid: above 20), representative value 999                                                                                |
| **Manual Env**         | Local, Staging                                                                                                                        |
| **Precondition**       | Shopper is on the cart page with one item at quantity 4                                                                               |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `999` <br> 3. Commit the value                                                               |
| **Expected**           | Same as TC-CART-004: message "You can buy at most 20 of this item." is shown, field reverts to `4`, totals unchanged.                 |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-qty-error`                                                                                          |
| **Source**             | AC-3                                                                                                                                  |
| **Note**               | Also covers the case where the input has a `max` attribute: typing must still be possible so the message can be verified.             |

---

## TC-CART-006: Quantity 0 prompts for removal and removes the item on confirm

| Field                  | Value                                                                                                                                                                                                 |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                                                              |
| **Issue**              | CART-12                                                                                                                                                                                               |
| **Automation Score**   | HIGH (60/67.5)                                                                                                                                                                                        |
| **ISTQB Technique**    | Decision Table — R1: quantity = 0 AND shopper confirms → item removed                                                                                                                                 |
| **Manual Env**         | Local, Staging                                                                                                                                                                                        |
| **Precondition**       | Shopper is on the cart page with two different items; item A at quantity 3, item B at quantity 1                                                                                                      |
| **Steps**              | 1. Clear item A's quantity field <br> 2. Type `0` <br> 3. Commit the value <br> 4. In the dialog, click the confirm action                                                                             |
| **Expected**           | After step 3 a dialog with the text "Remove this item?" appears and item A is still in the cart. After step 4 the dialog closes, item A is gone from the cart, item B is unchanged at quantity 1, and the subtotal equals item B's line total. |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`, `remove-item-confirm`, `cart-item-row`, `cart-subtotal`                                                                                                  |
| **Source**             | AC-2                                                                                                                                                                                                  |
| **Note**               | Two items in the precondition prove that only the targeted item is removed.                                                                                                                           |

---

## TC-CART-007: Cancelling the removal prompt keeps the item at its previous quantity

| Field                  | Value                                                                                                                                                                   |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                                |
| **Issue**              | CART-12                                                                                                                                                                 |
| **Automation Score**   | HIGH (60/67.5)                                                                                                                                                          |
| **ISTQB Technique**    | Decision Table — R2: quantity = 0 AND shopper cancels → item kept                                                                                                       |
| **Manual Env**         | Local, Staging                                                                                                                                                          |
| **Precondition**       | Shopper is on the cart page with one item at quantity 3                                                                                                                 |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `0` <br> 3. Commit the value <br> 4. In the "Remove this item?" dialog, click the cancel action                                 |
| **Expected**           | Dialog closes. Item stays in the cart. Field shows `3` (not `0`). Totals unchanged (3 × unit price).                                                                    |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`, `remove-item-cancel`, `cart-item-row`                                                                                      |
| **Source**             | AC-2                                                                                                                                                                    |
| **Note**               | Assumption A3 applies. The "only when the shopper confirms" wording makes this the critical negative path of AC-2.                                                      |

---

## TC-CART-008: Dismissing the removal prompt without choosing behaves like cancel

| Field                  | Value                                                                                                                                                                         |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                                                       |
| **Issue**              | CART-12                                                                                                                                                                       |
| **Automation Score**   | MEDIUM (47/67.5)                                                                                                                                                              |
| **ISTQB Technique**    | Error Guessing — dialog dismissed by ESC or backdrop click instead of a button                                                                                                |
| **Manual Env**         | Local, Staging                                                                                                                                                                |
| **Precondition**       | Shopper is on the cart page with one item at quantity 3                                                                                                                       |
| **Steps**              | 1. Clear the quantity field, type `0`, commit the value <br> 2. Press ESC <br> 3. Repeat step 1 <br> 4. Click outside the dialog                                              |
| **Expected**           | In both cases the dialog closes, the item stays in the cart, the field shows `3`, and totals are unchanged. The item is never removed without an explicit confirm.             |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`, `cart-item-row`                                                                                                                  |
| **Source**             | Added by QA (AC-2 states removal happens only on confirm but does not say what dismissing the dialog does)                                                                    |
| **Note**               | Assumption A3 applies. If the dialog is non-dismissable, record that as the observed behaviour and mark this case not applicable.                                             |

---

## TC-CART-009: A negative quantity is rejected and the previous quantity is kept

| Field                  | Value                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                                |
| **Issue**              | CART-12                                                                                                                                                |
| **Automation Score**   | MEDIUM (49/67.5)                                                                                                                                       |
| **ISTQB Technique**    | EP — EP3 (invalid: below 0), representative value −1                                                                                                   |
| **Manual Env**         | Local, Staging                                                                                                                                         |
| **Precondition**       | Shopper is on the cart page with one item at quantity 3                                                                                                |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `-1` <br> 3. Commit the value                                                                                 |
| **Expected**           | The value is not accepted: either the field refuses the `-` character or, on commit, the field reverts to `3`. No "Remove this item?" dialog appears. Totals unchanged. |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`                                                                                                            |
| **Source**             | Added by QA (the ticket covers 0 and above 20 but is silent on negative values)                                                                        |
| **Note**               | Assumption A2 applies. A negative value must not be treated as 0 and trigger removal.                                                                   |

---

## TC-CART-010: A decimal quantity is rejected and the previous quantity is kept

| Field                  | Value                                                                                                                                                        |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                                      |
| **Issue**              | CART-12                                                                                                                                                      |
| **Automation Score**   | MEDIUM (49/67.5)                                                                                                                                             |
| **ISTQB Technique**    | EP — EP4 (invalid: not a whole number), representative value 2.5                                                                                             |
| **Manual Env**         | Local, Staging                                                                                                                                               |
| **Precondition**       | Shopper is on the cart page with one item at quantity 3                                                                                                      |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `2.5` <br> 3. Commit the value                                                                                      |
| **Expected**           | The value is not accepted: the field refuses the `.` character or reverts to `3` on commit. The quantity is not silently rounded to 2 or 3. Totals unchanged. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`                                                                                                                |
| **Source**             | Added by QA (AC-1 says "whole numbers" but gives no behaviour for decimals)                                                                                  |
| **Note**               | Assumption A2 applies. Also try `2,5` on a locale that uses a comma decimal separator.                                                                        |

---

## TC-CART-011: Non-numeric or empty input is rejected and the previous quantity is kept

| Field                  | Value                                                                                                                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                                                               |
| **Issue**              | CART-12                                                                                                                                                                               |
| **Automation Score**   | MEDIUM (47/67.5)                                                                                                                                                                      |
| **ISTQB Technique**    | EP — EP5 (invalid: non-numeric `abc`) and EP6 (invalid: empty)                                                                                                                        |
| **Manual Env**         | Local, Staging                                                                                                                                                                        |
| **Precondition**       | Shopper is on the cart page with one item at quantity 3                                                                                                                               |
| **Steps**              | 1. Clear the quantity field, type `abc`, commit the value <br> 2. Clear the quantity field, leave it empty, commit the value                                                           |
| **Expected**           | In both cases the field reverts to `3`, no "Remove this item?" dialog appears, no limit message appears, and totals are unchanged. An empty field is not treated as 0.                 |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`, `cart-item-qty-error`                                                                                                                    |
| **Source**             | Added by QA (the ticket is silent on non-numeric and empty input)                                                                                                                     |
| **Note**               | Assumption A2 applies. Empty-to-0 coercion is a common defect; keep both inputs in one case so the regression is caught either way.                                                   |

---

## TC-CART-012: Changing one item's quantity does not affect other items

| Field                  | Value                                                                                                                                                       |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                                     |
| **Issue**              | CART-12                                                                                                                                                     |
| **Automation Score**   | HIGH (56/67.5)                                                                                                                                              |
| **ISTQB Technique**    | Error Guessing — wrong line targeted when several items share a form                                                                                        |
| **Manual Env**         | Local, Staging                                                                                                                                              |
| **Precondition**       | Shopper is on the cart page with three items: A at 1, B at 2, C at 3                                                                                        |
| **Steps**              | 1. Change item B's quantity to `7` and commit <br> 2. Change item C's quantity to `21` and commit                                                            |
| **Expected**           | After step 1: A = 1, B = 7, C = 3; subtotal updated for B only. After step 2: the limit message appears on item C only; A = 1, B = 7, C = 3; subtotal unchanged from step 1. |
| **data-testid needed** | `cart-item-row`, `cart-item-qty-input`, `cart-item-qty-error`, `cart-subtotal`                                                                              |
| **Source**             | Added by QA (the ticket describes a single item; multi-item carts are the normal case)                                                                      |
| **Note**               | Assumption A4 applies for the subtotal check.                                                                                                               |

---

## TC-CART-013: A changed quantity survives a page reload

| Field                  | Value                                                                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                |
| **Issue**              | CART-12                                                                                                                                |
| **Automation Score**   | HIGH (55/67.5)                                                                                                                         |
| **ISTQB Technique**    | Error Guessing — change applied to the view but not persisted                                                                          |
| **Manual Env**         | Local, Staging                                                                                                                         |
| **Precondition**       | Shopper is on the cart page with one item at quantity 2                                                                                |
| **Steps**              | 1. Change the quantity to `6` and commit <br> 2. Reload the page <br> 3. Set the quantity to `0`, confirm removal <br> 4. Reload the page |
| **Expected**           | After step 2 the item shows quantity 6 and totals match. After step 4 the item is absent and the cart shows its empty state (or only the remaining items). |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-row`, `cart-empty-state`                                                                             |
| **Source**             | Added by QA (the ticket is silent on persistence of the new quantity)                                                                  |
| **Note**               | If the cart is server-side, also check the cart API response after reload; if it is local storage only, note that in the result.      |

---

## Traceability

| Requirement | Cases                                        |
| ----------- | -------------------------------------------- |
| AC-1        | TC-CART-001, 002, 003                        |
| AC-2        | TC-CART-006, 007 (+ 008 added by QA)         |
| AC-3        | TC-CART-003, 004, 005                        |
| Added by QA | TC-CART-008, 009, 010, 011, 012, 013         |

**Rules not applied:** the `context-discovery` and `testing-guidelines` rules were not loaded and no `qa-rules` skill is installed, so they could not be read. In their place, the workspace was checked (it is empty) and every unverified assumption is listed under "Scope and assumptions" above.
