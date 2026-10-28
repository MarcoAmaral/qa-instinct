---
feature: Cart — Change item quantity
feature_code: CART
tc_count: 16
tracker_issues: [CART-12]
risk_level: MEDIUM
runbook: N/A — no runbook requested
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-23
---

# Test Cases — Cart — Change item quantity

| Field            | Value                                                                  |
| ---------------- | ---------------------------------------------------------------------- |
| **Project**      | N/A — not stated in the ticket                                         |
| **Author**       | [Name] — Senior QA Analyst                                             |
| **Date Created** | 2026-10-23                                                             |
| **Last Updated** | 2026-10-23                                                             |
| **Methodology**  | ISTQB CTFL v4.0 — EP, BVA (three-value), Decision Table, Error Guessing |

## Assumptions (nothing could be verified in a codebase)

The working directory holds no source code, so no precondition or expected result below is grounded in an implementation. Every case rests on these assumptions; each is flagged again in the **Note** row where it matters.

- **A1 — Input control.** The quantity field is a numeric text input committed on blur or Enter. If the product uses +/− stepper buttons instead, the Steps columns change but the expected results do not.
- **A2 — Totals.** The line total equals unit price × quantity, and the cart subtotal is the sum of line totals. A valid change updates both.
- **A3 — AC-3 message placement.** "You can buy at most 20 of this item." is shown inline next to the field and the field reverts to the previous quantity.
- **A4 — AC-2 dialog.** "Remove this item?" is a modal with a confirm action (**Remove**) and a cancel action (**Cancel**). Closing the dialog by ESC or the close icon counts as not confirming.
- **A5 — Invalid non-numeric input.** Decimals, text, negatives and an empty field are not covered by any AC. Assumed behaviour: the change is rejected and the previous quantity is kept. Cases are marked `Added by QA` and need PO confirmation.
- **A6 — Tracker.** `CART-12` matches both Linear and Jira identifier formats and no base URL was given, so the ID is used as plain text.

## Technique coverage

**BVA on AC-1 (1–20, three-value):** 0 → AC-2 dialog · 1 (min) · 2 (min+1) · 19 (max−1) · 20 (max) · 21 (max+1) → AC-3.

**Decision table for AC-2:**

| Condition                      | R1  | R2  | R3  |
| ------------------------------ | --- | --- | --- |
| Quantity entered is 0          | T   | T   | F   |
| Shopper confirms the dialog    | T   | F   | –   |
| **Actions**                    |     |     |     |
| "Remove this item?" is shown   | X   | X   |     |
| Item is removed                | X   |     |     |
| Previous quantity is kept      |     | X   |     |

R3 is covered by the AC-1 cases (no dialog on a valid change).

---

## TC-CART-001: Change quantity to a valid value updates line total and subtotal

| Field                  | Value                                                                                                                                                                      |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                                    |
| **Issue**              | CART-12                                                                                                                                                                    |
| **Automation Score**   | HIGH (60/67.5)                                                                                                                                                             |
| **ISTQB Technique**    | EP — EP1 (valid: whole number 1–20), representative value 5                                                                                                                |
| **Manual Env**         | Local, Staging                                                                                                                                                             |
| **Precondition**       | Shopper signed in or guest cart active. Cart contains one item at quantity 1 with a known unit price. Item stock is at least 20.                                           |
| **Steps**              | 1. Open the cart page <br> 2. Clear the quantity field of the item and type `5` <br> 3. Commit the value (blur or Enter)                                                    |
| **Expected**           | The field shows `5`. The line total equals 5 × unit price. The cart subtotal equals the new line total. No error message and no dialog appear.                             |
| **data-testid needed** | `cart-item-row`, `cart-item-qty-input`, `cart-item-line-total`, `cart-subtotal`                                                                                            |
| **Source**             | AC-1                                                                                                                                                                       |
| **Note**               | Relies on assumption A1 (input control) and A2 (totals).                                                                                                                   |

---

## TC-CART-002: Quantity 1 (minimum) is accepted

| Field                  | Value                                                                                                                      |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                     |
| **Issue**              | CART-12                                                                                                                    |
| **Automation Score**   | HIGH (56/67.5)                                                                                                             |
| **ISTQB Technique**    | BVA — three-value, min = 1                                                                                                 |
| **Manual Env**         | Local, Staging                                                                                                             |
| **Precondition**       | Cart contains one item at quantity 5.                                                                                      |
| **Steps**              | 1. Open the cart page <br> 2. Set the quantity field to `1` <br> 3. Commit the value                                       |
| **Expected**           | The field shows `1`. Line total equals 1 × unit price. No "Remove this item?" dialog and no error message appear.          |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`                                                                              |
| **Source**             | AC-1                                                                                                                       |
| **Note**               | Guards the off-by-one where 1 is wrongly treated like 0 (AC-2).                                                            |

---

## TC-CART-003: Quantity 20 (maximum) is accepted

| Field                  | Value                                                                                                                      |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                     |
| **Issue**              | CART-12                                                                                                                    |
| **Automation Score**   | HIGH (56/67.5)                                                                                                             |
| **ISTQB Technique**    | BVA — three-value, max = 20                                                                                                |
| **Manual Env**         | Local, Staging                                                                                                             |
| **Precondition**       | Cart contains one item at quantity 1. Item stock is at least 20.                                                           |
| **Steps**              | 1. Open the cart page <br> 2. Set the quantity field to `20` <br> 3. Commit the value                                      |
| **Expected**           | The field shows `20`. Line total equals 20 × unit price. The message "You can buy at most 20 of this item." does NOT appear. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`, `cart-qty-error`                                                            |
| **Source**             | AC-1                                                                                                                       |
| **Note**               | Guards the off-by-one where 20 is wrongly rejected by the AC-3 rule.                                                       |

---

## TC-CART-004: Quantities 2 and 19 (inner boundaries) are accepted

| Field                  | Value                                                                                                                                    |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                   |
| **Issue**              | CART-12                                                                                                                                  |
| **Automation Score**   | HIGH (54/67.5)                                                                                                                           |
| **ISTQB Technique**    | BVA — three-value, min+1 = 2 and max−1 = 19                                                                                              |
| **Manual Env**         | Local, Staging                                                                                                                           |
| **Precondition**       | Cart contains one item at quantity 1. Item stock is at least 20.                                                                         |
| **Steps**              | 1. Open the cart page <br> 2. Set the quantity to `2` and commit <br> 3. Set the quantity to `19` and commit                              |
| **Expected**           | After step 2 the field shows `2` and the line total is 2 × unit price. After step 3 the field shows `19` and the line total is 19 × unit price. No message or dialog appears at either step. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`                                                                                            |
| **Source**             | AC-1                                                                                                                                     |
| **Note**               | N/A — no caveats                                                                                                                         |

---

## TC-CART-005: Quantity 21 shows the maximum message and keeps the previous quantity

| Field                  | Value                                                                                                                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                                                |
| **Issue**              | CART-12                                                                                                                                                                                |
| **Automation Score**   | HIGH (58/67.5)                                                                                                                                                                         |
| **ISTQB Technique**    | BVA — three-value, max+1 = 21                                                                                                                                                          |
| **Manual Env**         | Local, Staging                                                                                                                                                                         |
| **Precondition**       | Cart contains one item at quantity 5.                                                                                                                                                  |
| **Steps**              | 1. Open the cart page <br> 2. Set the quantity field to `21` <br> 3. Commit the value                                                                                                   |
| **Expected**           | The message "You can buy at most 20 of this item." is shown. The field shows `5`. Line total and subtotal still reflect quantity 5. No remove dialog appears.                           |
| **data-testid needed** | `cart-item-qty-input`, `cart-qty-error`, `cart-item-line-total`, `cart-subtotal`                                                                                                       |
| **Source**             | AC-3                                                                                                                                                                                   |
| **Note**               | Relies on assumption A3 (message placement). The exact message text must match the AC character for character.                                                                       |

---

## TC-CART-006: A far larger quantity (999) is rejected the same way as 21

| Field                  | Value                                                                                                                                            |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                           |
| **Issue**              | CART-12                                                                                                                                          |
| **Automation Score**   | HIGH (53/67.5)                                                                                                                                   |
| **ISTQB Technique**    | EP — EP2 (invalid: above 20), representative value 999                                                                                           |
| **Manual Env**         | Local, Staging                                                                                                                                   |
| **Precondition**       | Cart contains one item at quantity 5.                                                                                                            |
| **Steps**              | 1. Open the cart page <br> 2. Set the quantity field to `999` <br> 3. Commit the value                                                            |
| **Expected**           | The message "You can buy at most 20 of this item." is shown. The field shows `5`. Totals are unchanged.                                           |
| **data-testid needed** | `cart-item-qty-input`, `cart-qty-error`, `cart-item-line-total`                                                                                  |
| **Source**             | AC-3                                                                                                                                             |
| **Note**               | Catches an implementation that only checks `=== 21` or clamps silently to 20 instead of rejecting.                                                |

---

## TC-CART-007: Quantity 0 asks "Remove this item?" and confirming removes the item

| Field                  | Value                                                                                                                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                                                   |
| **Issue**              | CART-12                                                                                                                                                                                   |
| **Automation Score**   | HIGH (57/67.5)                                                                                                                                                                            |
| **ISTQB Technique**    | Decision Table — R1 (quantity 0, confirmed); also BVA min−1 = 0                                                                                                                           |
| **Manual Env**         | Local, Staging                                                                                                                                                                            |
| **Precondition**       | Cart contains two items, A at quantity 3 and B at quantity 1.                                                                                                                             |
| **Steps**              | 1. Open the cart page <br> 2. Set the quantity of item A to `0` <br> 3. Commit the value <br> 4. In the dialog, click **Remove**                                                           |
| **Expected**           | After step 3 a dialog with the text "Remove this item?" appears and item A is still in the cart. After step 4 the dialog closes, item A is no longer listed, item B is unchanged at quantity 1, and the subtotal equals item B's line total. |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`, `remove-item-confirm`, `cart-item-row`, `cart-subtotal`                                                                                      |
| **Source**             | AC-2                                                                                                                                                                                      |
| **Note**               | Relies on assumption A4 (dialog actions). Step 3 checks that the item is NOT removed before confirmation.                                                                                 |

---

## TC-CART-008: Cancelling the "Remove this item?" dialog keeps the item at its previous quantity

| Field                  | Value                                                                                                                                                         |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                       |
| **Issue**              | CART-12                                                                                                                                                       |
| **Automation Score**   | HIGH (56/67.5)                                                                                                                                                |
| **ISTQB Technique**    | Decision Table — R2 (quantity 0, not confirmed via Cancel)                                                                                                    |
| **Manual Env**         | Local, Staging                                                                                                                                                |
| **Precondition**       | Cart contains one item at quantity 3.                                                                                                                         |
| **Steps**              | 1. Open the cart page <br> 2. Set the quantity field to `0` <br> 3. Commit the value <br> 4. In the dialog, click **Cancel**                                   |
| **Expected**           | The dialog closes. The item is still in the cart. The field shows `3`, not `0`. Line total and subtotal still reflect quantity 3.                              |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`, `remove-item-cancel`, `cart-item-row`, `cart-item-line-total`                                                    |
| **Source**             | AC-2                                                                                                                                                          |
| **Note**               | A common defect leaves the field showing `0` after cancel; the expected result asserts the field value explicitly.                                             |

---

## TC-CART-009: Dismissing the dialog with ESC or the close icon counts as not confirming

| Field                  | Value                                                                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                                  |
| **Issue**              | CART-12                                                                                                                                                 |
| **Automation Score**   | HIGH (53/67.5)                                                                                                                                          |
| **ISTQB Technique**    | Decision Table — R2 (quantity 0, not confirmed via dismiss)                                                                                             |
| **Manual Env**         | Local, Staging                                                                                                                                          |
| **Precondition**       | Cart contains one item at quantity 3.                                                                                                                   |
| **Steps**              | 1. Open the cart page <br> 2. Set the quantity field to `0` and commit <br> 3. Press ESC <br> 4. Repeat step 2, then click the dialog's close icon        |
| **Expected**           | After each dismissal the dialog closes, the item remains in the cart and the field shows `3`.                                                           |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`, `remove-item-close`                                                                                        |
| **Source**             | AC-2                                                                                                                                                    |
| **Note**               | Relies on assumption A4. AC-2 says "only when the shopper confirms", so any non-confirm path must keep the item.                                          |

---

## TC-CART-010: A decimal quantity is rejected and the previous quantity is kept

| Field                  | Value                                                                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                     |
| **Issue**              | CART-12                                                                                                                                    |
| **Automation Score**   | HIGH (53/67.5)                                                                                                                             |
| **ISTQB Technique**    | EP — EP3 (invalid: not a whole number), representative value 2.5                                                                           |
| **Manual Env**         | Local, Staging                                                                                                                             |
| **Precondition**       | Cart contains one item at quantity 3.                                                                                                      |
| **Steps**              | 1. Open the cart page <br> 2. Type `2.5` in the quantity field <br> 3. Commit the value                                                      |
| **Expected**           | The value is not accepted: either the field refuses the character or the change is rejected with a validation message. The field shows `3` and totals are unchanged. Neither the AC-3 message nor the remove dialog appears. |
| **data-testid needed** | `cart-item-qty-input`, `cart-qty-error`, `cart-item-line-total`                                                                            |
| **Source**             | Added by QA (AC-1 says "whole numbers" but no AC states what happens with a decimal)                                                        |
| **Note**               | Relies on assumption A5. Also catches silent rounding or truncation (2.5 → 2 or 3) which would be a defect against AC-1.                   |

---

## TC-CART-011: Non-numeric text is rejected and the previous quantity is kept

| Field                  | Value                                                                                                                                                 |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                                |
| **Issue**              | CART-12                                                                                                                                               |
| **Automation Score**   | HIGH (53/67.5)                                                                                                                                        |
| **ISTQB Technique**    | EP — EP4 (invalid: non-numeric), representative value `abc`                                                                                           |
| **Manual Env**         | Local, Staging                                                                                                                                        |
| **Precondition**       | Cart contains one item at quantity 3.                                                                                                                 |
| **Steps**              | 1. Open the cart page <br> 2. Type `abc` in the quantity field <br> 3. Commit the value                                                                |
| **Expected**           | The value is not accepted. The field shows `3` and totals are unchanged. No remove dialog appears (the input must not be parsed as 0).                  |
| **data-testid needed** | `cart-item-qty-input`, `cart-qty-error`                                                                                                               |
| **Source**             | Added by QA (the ticket is silent on non-numeric input)                                                                                                |
| **Note**               | Relies on assumption A5. `Number("abc")` is `NaN` and `parseInt("abc") || 0` is `0`; both paths are known defect sources.                             |

---

## TC-CART-012: A negative quantity is rejected and the previous quantity is kept

| Field                  | Value                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                                     |
| **Issue**              | CART-12                                                                                                                                                    |
| **Automation Score**   | HIGH (53/67.5)                                                                                                                                             |
| **ISTQB Technique**    | EP — EP5 (invalid: below 0), representative value −1                                                                                                       |
| **Manual Env**         | Local, Staging                                                                                                                                             |
| **Precondition**       | Cart contains one item at quantity 3.                                                                                                                      |
| **Steps**              | 1. Open the cart page <br> 2. Type `-1` in the quantity field <br> 3. Commit the value                                                                      |
| **Expected**           | The value is not accepted. The field shows `3` and totals are unchanged. The remove dialog does NOT appear (−1 must not be treated as "0 or less").          |
| **data-testid needed** | `cart-item-qty-input`, `cart-qty-error`, `remove-item-dialog`                                                                                              |
| **Source**             | Added by QA (the ticket is silent on negative values)                                                                                                      |
| **Note**               | Relies on assumption A5. An implementation using `qty <= 0` would wrongly open the remove dialog here; PO to confirm which behaviour is wanted.             |

---

## TC-CART-013: An empty quantity field keeps the previous quantity

| Field                  | Value                                                                                                                                           |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                          |
| **Issue**              | CART-12                                                                                                                                         |
| **Automation Score**   | MEDIUM (47/67.5)                                                                                                                                |
| **ISTQB Technique**    | Error Guessing — empty state                                                                                                                    |
| **Manual Env**         | Local, Staging                                                                                                                                  |
| **Precondition**       | Cart contains one item at quantity 3.                                                                                                           |
| **Steps**              | 1. Open the cart page <br> 2. Clear the quantity field so it is empty <br> 3. Commit (blur)                                                       |
| **Expected**           | The field reverts to `3`. Totals are unchanged. No remove dialog appears (empty must not be parsed as 0).                                         |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`                                                                                                     |
| **Source**             | Added by QA (the ticket is silent on an empty field)                                                                                             |
| **Note**               | Relies on assumption A5. If the product instead shows a validation message, record it as a dated correction here rather than failing the case.    |

---

## TC-CART-014: A changed quantity persists after page reload

| Field                  | Value                                                                                                                            |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                           |
| **Issue**              | CART-12                                                                                                                          |
| **Automation Score**   | MEDIUM (49/67.5)                                                                                                                 |
| **ISTQB Technique**    | Error Guessing — state not saved to the backing store                                                                            |
| **Manual Env**         | Local, Staging                                                                                                                   |
| **Precondition**       | Cart contains one item at quantity 1.                                                                                            |
| **Steps**              | 1. Open the cart page <br> 2. Set the quantity to `7` and commit <br> 3. Wait for any save indicator to finish <br> 4. Reload the page |
| **Expected**           | After reload the item shows quantity `7` and the line total is 7 × unit price.                                                    |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`                                                                                    |
| **Source**             | Added by QA (the story's goal "so that I buy the amount I need" implies the change is kept; no AC states persistence)              |
| **Note**               | Where the cart is saved (server, cookie, local storage) is unknown; the case is valid for any of them.                             |

---

## TC-CART-015: Changing one item's quantity does not affect other items

| Field                  | Value                                                                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                             |
| **Issue**              | CART-12                                                                                                                                            |
| **Automation Score**   | HIGH (54/67.5)                                                                                                                                     |
| **ISTQB Technique**    | Error Guessing — wrong row targeted / shared state between rows                                                                                     |
| **Manual Env**         | Local, Staging                                                                                                                                     |
| **Precondition**       | Cart contains three items A, B and C, each at quantity 2.                                                                                          |
| **Steps**              | 1. Open the cart page <br> 2. Set the quantity of item B to `6` and commit                                                                          |
| **Expected**           | Item B shows `6` with its line total updated. Items A and C still show `2` with unchanged line totals. Subtotal equals the sum of the three line totals. |
| **data-testid needed** | `cart-item-row`, `cart-item-qty-input`, `cart-item-line-total`, `cart-subtotal`                                                                    |
| **Source**             | Added by QA (the ticket is silent on carts with more than one item)                                                                                 |
| **Note**               | Targets index-based handlers and shared form state across rows.                                                                                     |

---

## TC-CART-016: Rapid successive changes apply only the last committed value

| Field                  | Value                                                                                                                                                                      |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @manual @cart @manual-only`                                                                                                                                |
| **Issue**              | CART-12                                                                                                                                                                    |
| **Automation Score**   | LOW (33/67.5)                                                                                                                                                              |
| **ISTQB Technique**    | Error Guessing — race condition between out-of-order save responses                                                                                                        |
| **Manual Env**         | Staging (with network throttling enabled in browser devtools)                                                                                                              |
| **Precondition**       | Cart contains one item at quantity 1. Browser devtools network throttling set to "Slow 3G" or similar.                                                                      |
| **Steps**              | 1. Open the cart page <br> 2. Set the quantity to `3` and commit <br> 3. Within one second set it to `8` and commit <br> 4. Wait for all requests to finish <br> 5. Reload the page |
| **Expected**           | Before and after reload the item shows `8` and the line total is 8 × unit price. The value never settles back to `3`.                                                        |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`                                                                                                                              |
| **Source**             | Added by QA (the ticket is silent on concurrent updates)                                                                                                                    |
| **Note**               | Kept manual: outcome depends on request timing, so an automated version would be non-deterministic without request interception. Revisit once the save mechanism is known.  |

---

Rules not applied: `context-discovery` and `testing-guidelines` were not loaded and no `qa-rules` skill is installed. The codebase directory is also empty, so no case could be grounded in an implementation; see the Assumptions section.
