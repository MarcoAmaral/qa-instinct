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

| Field            | Value                                                     |
| ---------------- | --------------------------------------------------------- |
| **Project**      | Shop (name not given in the ticket)                       |
| **Author**       | Marco — Senior QA Analyst                                 |
| **Date Created** | 2026-10-23                                                |
| **Last Updated** | 2026-10-23                                                |
| **Methodology**  | ISTQB CTFL v4.0 — EP, BVA (two-value), Decision Table, Error Guessing |

## Assumptions

The working directory holds no source code, so none of the preconditions or expected results below could be checked against an implementation. Every case rests on the story text and the following assumptions:

- **A1.** The quantity control is a numeric text input on each cart line, and the new value is applied on blur or Enter. If the product uses +/− steppers instead, the typed steps become clicks and the "above 20" cases become one click past 20.
- **A2.** The "Remove this item?" prompt has a confirm action and a cancel action. Cancelling, closing, or pressing Escape leaves the item with its previous quantity.
- **A3.** Changing a quantity updates the line subtotal and the cart total; the ticket does not say so, so those checks are marked `Added by QA`.
- **A4.** The ticket says nothing about non-integer or non-numeric input. The cases below expect such input to be rejected and the previous quantity kept, in line with AC-3's "keep the previous quantity" pattern. Confirm with the PO.
- **A5.** Tracker is Linear (ID pattern `CART-12`). No base URL was given, so the ID is written as plain text.
- **A6.** `{APP_URL}` is the environment under test; a test account with a cart holding at least two distinct items is available.

Cases tagged `@gate` form the release gate for this story: the happy path, both AC-2 outcomes, and the AC-3 cap.

---

## TC-CART-001: Change quantity to a valid value inside the range

| Field                  | Value                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                   |
| **Issue**              | CART-12                                                                                                                                                    |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                                             |
| **ISTQB Technique**    | EP — valid partition (whole number 1–20), representative value 5                                                                                           |
| **Manual Env**         | Local, Staging                                                                                                                                             |
| **Precondition**       | Shopper is signed in; cart contains item A with quantity 2 at unit price P; cart page is open                                                              |
| **Steps**              | 1. Navigate to `{APP_URL}/cart` <br> 2. Clear the quantity field of item A and type `5` <br> 3. Press Enter (or blur the field)                            |
| **Expected**           | Quantity field shows `5`. No message is shown. Item A remains in the cart. Line subtotal shows 5 × P and the cart total updates accordingly (A3).          |
| **data-testid needed** | `cart-item-quantity`, `cart-item-subtotal`, `cart-total`                                                                                                   |
| **Source**             | AC-1                                                                                                                                                       |
| **Note**               | Subtotal and total assertions rest on assumption A3                                                                                                        |

---

## TC-CART-002: Change quantity to the minimum value 1

| Field                  | Value                                                                                                                              |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                            |
| **Issue**              | CART-12                                                                                                                            |
| **Automation Score**   | HIGH (59/67.5)                                                                                                                     |
| **ISTQB Technique**    | BVA — two-value, lower boundary (min = 1)                                                                                          |
| **Manual Env**         | Local, Staging                                                                                                                     |
| **Precondition**       | Shopper is signed in; cart contains item A with quantity 3; cart page is open                                                      |
| **Steps**              | 1. Clear the quantity field of item A and type `1` <br> 2. Press Enter                                                             |
| **Expected**           | Quantity field shows `1`. No message and no removal prompt is shown. Item A remains in the cart. Line subtotal shows 1 × P.        |
| **data-testid needed** | `cart-item-quantity`, `cart-item-subtotal`, `remove-item-dialog`                                                                   |
| **Source**             | AC-1                                                                                                                               |
| **Note**               | Checks that the value 1 is not mistaken for the removal path of AC-2                                                               |

---

## TC-CART-003: Change quantity to the maximum value 20

| Field                  | Value                                                                                                                                    |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate @gate`                                                                                            |
| **Issue**              | CART-12                                                                                                                                  |
| **Automation Score**   | HIGH (59/67.5)                                                                                                                           |
| **ISTQB Technique**    | BVA — two-value, upper boundary (max = 20)                                                                                               |
| **Manual Env**         | Local, Staging                                                                                                                           |
| **Precondition**       | Shopper is signed in; cart contains item A with quantity 2; cart page is open                                                            |
| **Steps**              | 1. Clear the quantity field of item A and type `20` <br> 2. Press Enter                                                                  |
| **Expected**           | Quantity field shows `20`. The message "You can buy at most 20 of this item." is NOT shown. Line subtotal shows 20 × P.                 |
| **data-testid needed** | `cart-item-quantity`, `cart-item-subtotal`, `quantity-error-message`                                                                     |
| **Source**             | AC-1, AC-3                                                                                                                               |
| **Note**               | Guards against an off-by-one where the cap is applied at ≥ 20 instead of > 20                                                            |

---

## TC-CART-004: Quantity 21 shows the maximum message and keeps the previous quantity

| Field                  | Value                                                                                                                                                                              |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                                           |
| **Issue**              | CART-12                                                                                                                                                                            |
| **Automation Score**   | HIGH (60/67.5)                                                                                                                                                                     |
| **ISTQB Technique**    | BVA — two-value, max + 1 (21)                                                                                                                                                      |
| **Manual Env**         | Local, Staging                                                                                                                                                                     |
| **Precondition**       | Shopper is signed in; cart contains item A with quantity 4; cart page is open                                                                                                      |
| **Steps**              | 1. Clear the quantity field of item A and type `21` <br> 2. Press Enter                                                                                                            |
| **Expected**           | The message "You can buy at most 20 of this item." is shown next to item A. Quantity field reverts to `4`. Line subtotal and cart total are unchanged. Item A remains in the cart. |
| **data-testid needed** | `cart-item-quantity`, `quantity-error-message`, `cart-item-subtotal`, `cart-total`                                                                                                 |
| **Source**             | AC-3                                                                                                                                                                               |
| **Note**               | Message text must match the ticket exactly, including the final period                                                                                                             |

---

## TC-CART-005: Quantity 0 asks to remove and removes the item on confirm

| Field                  | Value                                                                                                                                                                                                     |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                                                                  |
| **Issue**              | CART-12                                                                                                                                                                                                   |
| **Automation Score**   | HIGH (58/67.5)                                                                                                                                                                                            |
| **ISTQB Technique**    | Decision Table — column 1: quantity = 0 (Y), shopper confirms (Y) → item removed; also BVA min − 1                                                                                                         |
| **Manual Env**         | Local, Staging                                                                                                                                                                                            |
| **Precondition**       | Shopper is signed in; cart contains item A (quantity 2) and item B (quantity 1); cart page is open                                                                                                         |
| **Steps**              | 1. Clear the quantity field of item A and type `0` <br> 2. Press Enter <br> 3. Observe the prompt <br> 4. Click the confirm action                                                                        |
| **Expected**           | After step 2 a prompt with the text "Remove this item?" is shown and item A is still in the cart. After step 4 the prompt closes, item A is no longer listed, item B is unchanged, and the cart total equals item B's subtotal. |
| **data-testid needed** | `cart-item-quantity`, `remove-item-dialog`, `remove-item-confirm`, `cart-item-row`, `cart-total`                                                                                                           |
| **Source**             | AC-2                                                                                                                                                                                                      |
| **Note**               | Removal must not happen before the confirm click; assert item A is present between steps 2 and 4                                                                                                          |

---

## TC-CART-006: Quantity 0 then cancel keeps the item with its previous quantity

| Field                  | Value                                                                                                                                                                   |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate @gate`                                                                                                                           |
| **Issue**              | CART-12                                                                                                                                                                 |
| **Automation Score**   | HIGH (57/67.5)                                                                                                                                                          |
| **ISTQB Technique**    | Decision Table — column 2: quantity = 0 (Y), shopper confirms (N) → item kept, quantity unchanged                                                                        |
| **Manual Env**         | Local, Staging                                                                                                                                                          |
| **Precondition**       | Shopper is signed in; cart contains item A with quantity 2; cart page is open                                                                                           |
| **Steps**              | 1. Clear the quantity field of item A and type `0` <br> 2. Press Enter <br> 3. Click the cancel action on the "Remove this item?" prompt                                 |
| **Expected**           | Prompt closes. Item A remains in the cart. Quantity field shows `2`, not `0`. Line subtotal and cart total are unchanged.                                                |
| **data-testid needed** | `cart-item-quantity`, `remove-item-dialog`, `remove-item-cancel`, `cart-item-row`, `cart-total`                                                                          |
| **Source**             | AC-2                                                                                                                                                                    |
| **Note**               | The "reverts to previous quantity" part rests on assumption A2; the ticket only says the item is not removed                                                             |

---

## TC-CART-007: Dismissing the remove prompt with Escape or the close control behaves as cancel

| Field                  | Value                                                                                                                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                                                                    |
| **Issue**              | CART-12                                                                                                                                                                                    |
| **Automation Score**   | MEDIUM (49/67.5)                                                                                                                                                                           |
| **ISTQB Technique**    | Error Guessing — dialog dismissed by a path other than the two buttons                                                                                                                     |
| **Manual Env**         | Local, Staging                                                                                                                                                                             |
| **Precondition**       | Shopper is signed in; cart contains item A with quantity 2; cart page is open                                                                                                              |
| **Steps**              | 1. Clear the quantity field of item A and type `0` <br> 2. Press Enter <br> 3. Press Escape <br> 4. Repeat steps 1–2 and click the dialog's close (×) control, if one exists                |
| **Expected**           | In both cases the prompt closes, item A remains in the cart, and the quantity field shows `2`. The item is never removed without an explicit confirm.                                       |
| **data-testid needed** | `cart-item-quantity`, `remove-item-dialog`, `remove-item-close`                                                                                                                            |
| **Source**             | Added by QA (AC-2 says "only when the shopper confirms" but does not define dismissal paths other than cancel)                                                                              |
| **Note**               | If the dialog has no close control, run step 3 only and record step 4 as N/A                                                                                                                |

---

## TC-CART-008: A value far above the maximum is rejected the same way as 21

| Field                  | Value                                                                                                                                    |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                  |
| **Issue**              | CART-12                                                                                                                                  |
| **Automation Score**   | HIGH (55/67.5)                                                                                                                           |
| **ISTQB Technique**    | EP — invalid partition (> 20), representative value 999                                                                                  |
| **Manual Env**         | Local, Staging                                                                                                                           |
| **Precondition**       | Shopper is signed in; cart contains item A with quantity 4; cart page is open                                                            |
| **Steps**              | 1. Clear the quantity field of item A and type `999` <br> 2. Press Enter                                                                 |
| **Expected**           | The message "You can buy at most 20 of this item." is shown. Quantity field reverts to `4`. Cart total is unchanged.                     |
| **data-testid needed** | `cart-item-quantity`, `quantity-error-message`, `cart-total`                                                                             |
| **Source**             | AC-3                                                                                                                                     |
| **Note**               | Also covers any `maxlength` or numeric-overflow handling on the field                                                                    |

---

## TC-CART-009: A negative quantity is rejected and the previous quantity is kept

| Field                  | Value                                                                                                                                                                   |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                                                 |
| **Issue**              | CART-12                                                                                                                                                                 |
| **Automation Score**   | HIGH (54/67.5)                                                                                                                                                          |
| **ISTQB Technique**    | EP — invalid partition (< 0), representative value −1                                                                                                                   |
| **Manual Env**         | Local, Staging                                                                                                                                                          |
| **Precondition**       | Shopper is signed in; cart contains item A with quantity 2; cart page is open                                                                                           |
| **Steps**              | 1. Clear the quantity field of item A and type `-1` <br> 2. Press Enter                                                                                                 |
| **Expected**           | The value is not accepted: quantity field shows `2`, item A remains in the cart, no "Remove this item?" prompt is shown, and the cart total is unchanged.                |
| **data-testid needed** | `cart-item-quantity`, `remove-item-dialog`, `cart-total`                                                                                                                |
| **Source**             | Added by QA (the ticket defines 0 and > 20 but is silent on negative values)                                                                                             |
| **Note**               | Rests on assumption A4. A field that blocks the minus key at input time also passes; record which behaviour was observed                                                |

---

## TC-CART-010: A decimal quantity is rejected and the previous quantity is kept

| Field                  | Value                                                                                                                                                 |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                               |
| **Issue**              | CART-12                                                                                                                                               |
| **Automation Score**   | HIGH (54/67.5)                                                                                                                                        |
| **ISTQB Technique**    | EP — invalid partition (non-integer), representative value 2.5                                                                                        |
| **Manual Env**         | Local, Staging                                                                                                                                        |
| **Precondition**       | Shopper is signed in; cart contains item A with quantity 2; cart page is open                                                                         |
| **Steps**              | 1. Clear the quantity field of item A and type `2.5` <br> 2. Press Enter                                                                              |
| **Expected**           | The value is not accepted: quantity field shows `2` and the cart total is unchanged. The value is not silently rounded to 2 or 3.                      |
| **data-testid needed** | `cart-item-quantity`, `cart-total`                                                                                                                    |
| **Source**             | Added by QA (AC-1 says "whole numbers" but states no behaviour for decimals)                                                                           |
| **Note**               | Rests on assumption A4. Silent rounding is a finding, not a pass; the shopper would get a quantity they did not type                                   |

---

## TC-CART-011: Non-numeric or empty input is rejected and the previous quantity is kept

| Field                  | Value                                                                                                                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                                                               |
| **Issue**              | CART-12                                                                                                                                                                               |
| **Automation Score**   | HIGH (53/67.5)                                                                                                                                                                        |
| **ISTQB Technique**    | EP — invalid partitions (non-numeric text; empty)                                                                                                                                     |
| **Manual Env**         | Local, Staging                                                                                                                                                                        |
| **Precondition**       | Shopper is signed in; cart contains item A with quantity 2; cart page is open                                                                                                         |
| **Steps**              | 1. Clear the quantity field of item A and type `abc` <br> 2. Press Enter <br> 3. Clear the quantity field and leave it empty <br> 4. Blur the field                                   |
| **Expected**           | After step 2 the field shows `2` and the cart total is unchanged. After step 4 the field shows `2`, no "Remove this item?" prompt appears, and item A remains in the cart.             |
| **data-testid needed** | `cart-item-quantity`, `remove-item-dialog`, `cart-total`                                                                                                                              |
| **Source**             | Added by QA (the ticket is silent on text and empty input)                                                                                                                            |
| **Note**               | Rests on assumption A4. An empty field must not be treated as 0 and trigger removal                                                                                                    |

---

## TC-CART-012: A changed quantity survives a page reload and does not affect other items

| Field                  | Value                                                                                                                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                                                              |
| **Issue**              | CART-12                                                                                                                                                                              |
| **Automation Score**   | HIGH (56/67.5)                                                                                                                                                                       |
| **ISTQB Technique**    | Error Guessing — persistence and cross-line interference                                                                                                                             |
| **Manual Env**         | Local, Staging                                                                                                                                                                       |
| **Precondition**       | Shopper is signed in; cart contains item A (quantity 2) and item B (quantity 3); cart page is open                                                                                    |
| **Steps**              | 1. Clear the quantity field of item A and type `7` <br> 2. Press Enter <br> 3. Reload the page                                                                                        |
| **Expected**           | After step 2 item A shows `7` and item B still shows `3`. After step 3 item A still shows `7`, item B still shows `3`, and the cart total equals 7 × P(A) + 3 × P(B).                 |
| **data-testid needed** | `cart-item-row`, `cart-item-quantity`, `cart-total`                                                                                                                                  |
| **Source**             | Added by QA (the story goal "buy the amount I need" implies the change is saved; no AC states it)                                                                                     |
| **Note**               | Rests on assumption A3. If the cart is client-side only for guests, run with a signed-in shopper as the precondition states                                                           |

---

## Coverage summary

| AC / area                       | Cases                                        |
| ------------------------------- | -------------------------------------------- |
| AC-1 valid range 1–20           | TC-CART-001, TC-CART-002, TC-CART-003        |
| AC-2 zero → prompt → confirm/cancel | TC-CART-005, TC-CART-006, TC-CART-007    |
| AC-3 above 20                   | TC-CART-003, TC-CART-004, TC-CART-008        |
| Added by QA (input hygiene)     | TC-CART-009, TC-CART-010, TC-CART-011        |
| Added by QA (persistence)       | TC-CART-012                                  |
| Release gate (`@gate`)          | TC-CART-001, 003, 004, 005, 006              |

Rules not applied: the `context-discovery` and `testing-guidelines` rules were not loaded and no `qa-rules` skill is installed; the repository is empty, so no precondition or expected result was verified against code.
