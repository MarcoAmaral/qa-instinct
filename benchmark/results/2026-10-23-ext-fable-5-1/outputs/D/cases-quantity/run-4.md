---
feature: Cart — Change item quantity
feature_code: CART
tc_count: 13
tracker_issues: [CART-12]
risk_level: MEDIUM
runbook: N/A — no runbook requested for this story
implementation_pack: N/A — no implementation pack exists
spec: N/A — not automated yet
last_updated: 2026-10-23
---

# Test Cases — Cart: Change item quantity

| Field            | Value                                                          |
| ---------------- | -------------------------------------------------------------- |
| **Project**      | Shop cart (project name not given in the ticket)               |
| **Author**       | QA — Senior QA Analyst                                         |
| **Date Created** | 2026-10-23                                                     |
| **Last Updated** | 2026-10-23                                                     |
| **Methodology**  | ISTQB CTFL v4.0 — EP, BVA, Decision Table, State Transition, Error Guessing |

## Assumptions

The working directory holds no source code, so no precondition or expected result below is grounded in an implementation. Every case is derived from the story text alone. Verify the items marked "assumed" against the build before the first run.

- **A1 (assumed)**: The quantity field is a free-text numeric input. The value is committed on blur or on pressing Enter. If the build commits on an **Update** button instead, read "commit the value" as "click Update".
- **A2 (assumed)**: The AC-3 message is shown inline under the field and the field reverts to the previous quantity.
- **A3 (assumed)**: The AC-2 dialog has a confirm button labelled **Remove** and a cancel button labelled **Cancel**. Closing the dialog with ESC or by clicking outside it counts as cancel.
- **A4 (assumed)**: Values that are not whole numbers in 1–20 (decimals, negatives, blank, letters) are rejected and the previous quantity is kept. The ticket states no message for these; the cases only assert that the previous quantity is kept and nothing is silently rounded.
- **A5 (assumed)**: The line total and the cart subtotal recalculate after a successful change.
- **A6**: The tracker ID `CART-12` has a Linear-style format. No base URL was given, so the ID is written as plain text.
- **A7**: The `context-discovery` and `testing-guidelines` rules were not available in this session and no `qa-rules` skill is installed. The context-discovery rule could not be applied to code (there is none); the tag taxonomy follows the four required categories listed in the command itself.

Release gate: cases tagged `@gate` (TC-CART-001, 004, 005, 006) answer "does the feature work and did it break the cart?". The rest are the full analysis.

---

## TC-CART-001: Change quantity to a valid value and see the cart update

| Field                  | Value                                                                                                                                                                                                                 |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                                                                              |
| **Issue**              | CART-12                                                                                                                                                                                                               |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                                                                                                        |
| **ISTQB Technique**    | EP — valid partition (whole number inside 1–20, representative value 5)                                                                                                                                               |
| **Manual Env**         | Local, Staging                                                                                                                                                                                                        |
| **Precondition**       | Shopper is on the cart page. The cart holds one item with quantity 2 and a known unit price.                                                                                                                           |
| **Steps**              | 1. Clear the quantity field of the item <br> 2. Type `5` <br> 3. Commit the value (blur or Enter, per A1)                                                                                                             |
| **Expected**           | The quantity field shows `5`. The item stays in the cart. The line total equals 5 × unit price and the cart subtotal is recalculated (A5). No message is shown.                                                        |
| **data-testid needed** | `cart-item-row`, `cart-item-qty-input`, `cart-item-line-total`, `cart-subtotal`                                                                                                                                       |
| **Source**             | AC-1                                                                                                                                                                                                                  |
| **Note**               | Line total and subtotal assertions rest on A5; if the build does not show them, drop those assertions rather than the case.                                                                                           |

---

## TC-CART-002: Change quantity to the minimum value 1

| Field                  | Value                                                                                                             |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                           |
| **Issue**              | CART-12                                                                                                           |
| **Automation Score**   | HIGH (58/67.5)                                                                                                    |
| **ISTQB Technique**    | BVA — two-value, lower boundary (min = 1)                                                                         |
| **Manual Env**         | Local, Staging                                                                                                    |
| **Precondition**       | Shopper is on the cart page. The cart holds one item with quantity 3.                                             |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `1` <br> 3. Commit the value                                             |
| **Expected**           | The quantity field shows `1`. The item stays in the cart. No "Remove this item?" dialog appears. No message is shown. The line total equals 1 × unit price. |
| **data-testid needed** | `cart-item-row`, `cart-item-qty-input`, `cart-remove-dialog`, `cart-item-line-total`                              |
| **Source**             | AC-1                                                                                                              |
| **Note**               | Guards against an off-by-one that treats 1 like 0 (AC-2 path).                                                    |

---

## TC-CART-003: Change quantity to the maximum value 20

| Field                  | Value                                                                                                                        |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                      |
| **Issue**              | CART-12                                                                                                                      |
| **Automation Score**   | HIGH (58/67.5)                                                                                                               |
| **ISTQB Technique**    | BVA — two-value, upper boundary (max = 20)                                                                                   |
| **Manual Env**         | Local, Staging                                                                                                               |
| **Precondition**       | Shopper is on the cart page. The cart holds one item with quantity 3.                                                        |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `20` <br> 3. Commit the value                                                       |
| **Expected**           | The quantity field shows `20`. The item stays in the cart. The message "You can buy at most 20 of this item." is NOT shown. The line total equals 20 × unit price. |
| **data-testid needed** | `cart-item-row`, `cart-item-qty-input`, `cart-item-qty-error`, `cart-item-line-total`                                        |
| **Source**             | AC-1, AC-3                                                                                                                   |
| **Note**               | Guards against an off-by-one that rejects 20 as "above 20".                                                                  |

---

## TC-CART-004: Quantity 21 is rejected with the maximum message and the previous quantity is kept

| Field                  | Value                                                                                                                                                                                            |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                                                         |
| **Issue**              | CART-12                                                                                                                                                                                          |
| **Automation Score**   | HIGH (59/67.5)                                                                                                                                                                                   |
| **ISTQB Technique**    | BVA — two-value, max + 1 (21)                                                                                                                                                                    |
| **Manual Env**         | Local, Staging                                                                                                                                                                                   |
| **Precondition**       | Shopper is on the cart page. The cart holds one item with quantity 3.                                                                                                                            |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `21` <br> 3. Commit the value                                                                                                                           |
| **Expected**           | The message "You can buy at most 20 of this item." is shown (exact text). The quantity field shows `3`. The line total and subtotal are unchanged. The item stays in the cart.                   |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-qty-error`, `cart-item-line-total`, `cart-subtotal`                                                                                                            |
| **Source**             | AC-3                                                                                                                                                                                             |
| **Note**               | Placement of the message rests on A2. The expected result asserts the text, not the position.                                                                                                    |

---

## TC-CART-005: Setting quantity to 0 and confirming removes the item

| Field                  | Value                                                                                                                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                                                                               |
| **Issue**              | CART-12                                                                                                                                                                                                                |
| **Automation Score**   | HIGH (57/67.5)                                                                                                                                                                                                         |
| **ISTQB Technique**    | Decision Table — column 1 (quantity = 0, shopper confirms → item removed); also BVA min − 1                                                                                                                             |
| **Manual Env**         | Local, Staging                                                                                                                                                                                                         |
| **Precondition**       | Shopper is on the cart page. The cart holds two different items, item A with quantity 2 and item B with quantity 1.                                                                                                     |
| **Steps**              | 1. Clear the quantity field of item A <br> 2. Type `0` <br> 3. Commit the value <br> 4. In the dialog, click **Remove** (A3)                                                                                            |
| **Expected**           | After step 3 a dialog with the text "Remove this item?" (exact) is shown and item A is still in the cart. After step 4 the dialog closes, item A is no longer listed, item B is unchanged with quantity 1, and the subtotal equals item B's line total. |
| **data-testid needed** | `cart-item-row`, `cart-item-qty-input`, `cart-remove-dialog`, `cart-remove-confirm-btn`, `cart-subtotal`                                                                                                                |
| **Source**             | AC-2                                                                                                                                                                                                                   |
| **Note**               | Two items are used so the test can prove the wrong row was not removed.                                                                                                                                                |

---

## TC-CART-006: Setting quantity to 0 and cancelling keeps the item with its previous quantity

| Field                  | Value                                                                                                                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                                                           |
| **Issue**              | CART-12                                                                                                                                                                                            |
| **Automation Score**   | HIGH (57/67.5)                                                                                                                                                                                     |
| **ISTQB Technique**    | Decision Table — column 2 (quantity = 0, shopper cancels → item kept)                                                                                                                              |
| **Manual Env**         | Local, Staging                                                                                                                                                                                     |
| **Precondition**       | Shopper is on the cart page. The cart holds one item with quantity 2.                                                                                                                              |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `0` <br> 3. Commit the value <br> 4. In the "Remove this item?" dialog, click **Cancel** (A3)                                                              |
| **Expected**           | The dialog closes. The item is still in the cart. The quantity field shows `2`. The line total and subtotal are unchanged.                                                                         |
| **data-testid needed** | `cart-item-row`, `cart-item-qty-input`, `cart-remove-dialog`, `cart-remove-cancel-btn`                                                                                                             |
| **Source**             | AC-2                                                                                                                                                                                               |
| **Note**               | The field must revert to `2`, not stay at `0`; the story says the item is removed "only when the shopper confirms".                                                                                |

---

## TC-CART-007: Dismissing the remove dialog with ESC or an outside click behaves as cancel

| Field                  | Value                                                                                                                                                                |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                                              |
| **Issue**              | CART-12                                                                                                                                                              |
| **Automation Score**   | MEDIUM (49/67.5)                                                                                                                                                     |
| **ISTQB Technique**    | State Transition — "Confirm pending" state; ESC and outside click are events that must return to "In cart", never to "Removed"                                       |
| **Manual Env**         | Local, Staging                                                                                                                                                       |
| **Precondition**       | Shopper is on the cart page. The cart holds one item with quantity 2.                                                                                                |
| **Steps**              | 1. Clear the quantity field, type `0`, commit <br> 2. Press ESC <br> 3. Repeat step 1 <br> 4. Click outside the dialog                                               |
| **Expected**           | After steps 2 and 4 the dialog closes, the item is still in the cart and the quantity field shows `2`.                                                               |
| **data-testid needed** | `cart-item-row`, `cart-item-qty-input`, `cart-remove-dialog`                                                                                                         |
| **Source**             | Added by QA (AC-2 says removal needs confirmation but does not say what dismissing the dialog does; assumption A3)                                                    |
| **Note**               | If the dialog is modal and cannot be dismissed by outside click, step 4 is N/A; record that in the run.                                                               |

---

## TC-CART-008: A decimal quantity is rejected and the previous quantity is kept

| Field                  | Value                                                                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                   |
| **Issue**              | CART-12                                                                                                                                   |
| **Automation Score**   | HIGH (55/67.5)                                                                                                                            |
| **ISTQB Technique**    | EP — invalid partition (non-integer, representative value 2.5)                                                                            |
| **Manual Env**         | Local, Staging                                                                                                                            |
| **Precondition**       | Shopper is on the cart page. The cart holds one item with quantity 3.                                                                     |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `2.5` <br> 3. Commit the value                                                                   |
| **Expected**           | The quantity is not set to 2.5 and is not silently rounded to 2 or 3 from the typed value. The quantity field shows `3`. The line total is unchanged. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`                                                                                             |
| **Source**             | Added by QA (AC-1 says "whole numbers" but the ticket does not say what happens to a decimal; assumption A4)                               |
| **Note**               | If the input blocks typing a dot, the field will read `25` after step 2; then the expected result is that of TC-CART-010 (above 20). Record which happened. |

---

## TC-CART-009: A negative quantity is rejected and the previous quantity is kept

| Field                  | Value                                                                                                                          |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                        |
| **Issue**              | CART-12                                                                                                                        |
| **Automation Score**   | HIGH (55/67.5)                                                                                                                 |
| **ISTQB Technique**    | EP — invalid partition (negative number, representative value −1)                                                              |
| **Manual Env**         | Local, Staging                                                                                                                 |
| **Precondition**       | Shopper is on the cart page. The cart holds one item with quantity 3.                                                          |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `-1` <br> 3. Commit the value                                                         |
| **Expected**           | The quantity field shows `3`. No "Remove this item?" dialog appears. The item stays in the cart. The line total is unchanged.   |
| **data-testid needed** | `cart-item-qty-input`, `cart-remove-dialog`, `cart-item-line-total`                                                            |
| **Source**             | Added by QA (the ticket is silent on negative values; assumption A4)                                                            |
| **Note**               | A negative value must not be treated as 0 and trigger removal.                                                                 |

---

## TC-CART-010: A quantity far above the maximum is rejected with the maximum message

| Field                  | Value                                                                                                                            |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                          |
| **Issue**              | CART-12                                                                                                                          |
| **Automation Score**   | HIGH (56/67.5)                                                                                                                   |
| **ISTQB Technique**    | EP — invalid partition (above 20, representative value 999)                                                                      |
| **Manual Env**         | Local, Staging                                                                                                                   |
| **Precondition**       | Shopper is on the cart page. The cart holds one item with quantity 3.                                                            |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `999` <br> 3. Commit the value                                                          |
| **Expected**           | The message "You can buy at most 20 of this item." is shown. The quantity field shows `3`. The quantity is not clamped to 20.    |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-qty-error`                                                                                     |
| **Source**             | AC-3                                                                                                                             |
| **Note**               | Clamping to 20 would be a defect: AC-3 says the previous quantity is kept.                                                       |

---

## TC-CART-011: A blank or non-numeric quantity is rejected and the previous quantity is kept

| Field                  | Value                                                                                                                                                 |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                               |
| **Issue**              | CART-12                                                                                                                                               |
| **Automation Score**   | MEDIUM (50/67.5)                                                                                                                                      |
| **ISTQB Technique**    | EP — invalid partitions (empty string; alphabetic text `abc`)                                                                                         |
| **Manual Env**         | Local, Staging                                                                                                                                        |
| **Precondition**       | Shopper is on the cart page. The cart holds one item with quantity 3.                                                                                 |
| **Steps**              | 1. Clear the quantity field and commit (blank) <br> 2. Observe <br> 3. Clear the field, type `abc`, commit <br> 4. Observe                            |
| **Expected**           | After each commit the quantity field shows `3`, no "Remove this item?" dialog appears, the item stays in the cart and the line total is unchanged.     |
| **data-testid needed** | `cart-item-qty-input`, `cart-remove-dialog`, `cart-item-line-total`                                                                                   |
| **Source**             | Added by QA (the ticket is silent on blank and non-numeric input; assumption A4)                                                                       |
| **Note**               | A blank must not be read as 0 and trigger the remove dialog. If the input blocks letters, step 3 leaves the field blank and repeats step 1; record that. |

---

## TC-CART-012: A changed quantity persists after reloading the cart page

| Field                  | Value                                                                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                 |
| **Issue**              | CART-12                                                                                                                                 |
| **Automation Score**   | MEDIUM (51/67.5)                                                                                                                        |
| **ISTQB Technique**    | Error Guessing — change applied only in UI state and lost on reload                                                                     |
| **Manual Env**         | Local, Staging                                                                                                                          |
| **Precondition**       | Shopper is on the cart page. The cart holds one item with quantity 2.                                                                   |
| **Steps**              | 1. Change the quantity to `7` and commit <br> 2. Wait for the line total to update <br> 3. Reload the page                              |
| **Expected**           | After the reload the item shows quantity `7` and the line total equals 7 × unit price.                                                  |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`                                                                                           |
| **Source**             | Added by QA (the story's goal "so that I buy the amount I need" requires the change to survive to checkout; the ticket does not say where it is stored) |
| **Note**               | Whether the cart is stored server-side or in the browser is unknown (no code available). Run in Staging with a signed-in shopper if carts are per account. |

---

## TC-CART-013: Rapid successive quantity changes end in the last committed value

| Field                  | Value                                                                                                                                                        |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @manual @cart @manual-only`                                                                                                                 |
| **Issue**              | CART-12                                                                                                                                                      |
| **Automation Score**   | LOW (31/67.5)                                                                                                                                                |
| **ISTQB Technique**    | Error Guessing — race between out-of-order update responses                                                                                                  |
| **Manual Env**         | Staging                                                                                                                                                      |
| **Precondition**       | Shopper is on the cart page. The cart holds one item with quantity 1. Browser dev tools network throttling is set to "Slow 3G".                              |
| **Steps**              | 1. Change the quantity to `5` and commit <br> 2. Immediately change it to `8` and commit <br> 3. Immediately change it to `3` and commit <br> 4. Wait until no request is pending <br> 5. Reload the page |
| **Expected**           | After step 4 the quantity field shows `3` and the line total equals 3 × unit price. After step 5 the quantity is still `3`. No error is shown.               |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`                                                                                                                |
| **Source**             | Added by QA (the ticket is silent on concurrent updates)                                                                                                     |
| **Note**               | Kept manual: outcome depends on network timing. If a stale response wins (field shows 5 or 8), file a defect with the request order from the network panel.  |
