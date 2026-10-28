---
feature: Cart — Change Item Quantity
feature_code: CART
tc_count: 15
tracker_issues: [CART-12]
risk_level: MEDIUM
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-23
---

# Test Cases — Cart — Change Item Quantity

| Field            | Value                                                                 |
| ---------------- | --------------------------------------------------------------------- |
| **Project**      | Shop Cart (story CART-12)                                             |
| **Author**       | QA — Senior QA Analyst                                                |
| **Date Created** | 2026-10-23                                                            |
| **Last Updated** | 2026-10-23                                                            |
| **Methodology**  | ISTQB CTFL v4.0 — BVA (three-value), EP, Decision Table, State Transition, Error Guessing |

## Assumptions

The working directory contains no source code, so no `Precondition` or `Expected` below is verified against an implementation. The `context-discovery` rule could not be applied: no `qa-rules` skill is installed and the repository is empty. Every case therefore rests on the assumptions below; mark them verified or corrected once the code exists.

- **A1 — Input and commit.** The quantity is a text or number field on each cart line. A new value is committed on blur or Enter. If the real UI uses a stepper or an **Update** button, replace "commit the value" in the steps with that action.
- **A2 — Previous quantity.** "Previous quantity" means the value shown before the shopper started editing.
- **A3 — Cancelling removal.** When the shopper declines "Remove this item?", the item stays in the cart with its previous quantity. The story says the item is removed "only when the shopper confirms" but does not say what the field shows afterwards.
- **A4 — Rejected values.** Non-integer, non-numeric, negative and empty values are not covered by any AC. The cases below expect the field to keep the previous quantity and show no removal prompt. Any inline message for these is unspecified and is not asserted.
- **A5 — Messages.** Both quoted messages appear inline next to the quantity field. The removal question is a confirmation dialog with a confirm action (labelled **Remove**) and a cancel action (labelled **Cancel**).
- **A6 — Totals.** Line total and cart subtotal are recalculated after a quantity change. The story's goal ("buy the amount I need") implies it; no AC states it.
- **A7 — Tracker.** `CART-12` matches the Linear identifier format. No base URL is known, so the ID is given as plain text.
- **A8 — Selectors.** All `data-testid` values are proposals to be added by the developer.

Cases tagged `@gate` form the release gate: TC-CART-001, 002, 004, 005, 006.

---

## TC-CART-001: Set quantity to the minimum value 1

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                |
| **Issue**              | CART-12                                                                                                 |
| **Automation Score**   | HIGH (64/67.5)                                                                                          |
| **ISTQB Technique**    | BVA — three-value, min (1) of the valid range 1–20                                                      |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Signed-in or guest shopper with one item in the cart at quantity 3                                      |
| **Steps**              | 1. Open the cart <br> 2. Clear the quantity field of the item <br> 3. Type `1` <br> 4. Commit the value (A1) |
| **Expected**           | Field shows `1`. Item remains in the cart. No message and no dialog appear. Line total equals 1 × unit price (A6). |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`                                                           |
| **Source**             | AC-1                                                                                                    |
| **Note**               | N/A — no caveats                                                                                        |

---

## TC-CART-002: Set quantity to the maximum value 20

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                |
| **Issue**              | CART-12                                                                                                 |
| **Automation Score**   | HIGH (64/67.5)                                                                                          |
| **ISTQB Technique**    | BVA — three-value, max (20) of the valid range 1–20                                                     |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | One item in the cart at quantity 3                                                                      |
| **Steps**              | 1. Open the cart <br> 2. Clear the quantity field <br> 3. Type `20` <br> 4. Commit the value            |
| **Expected**           | Field shows `20`. No "You can buy at most 20 of this item." message. Item remains. Line total equals 20 × unit price. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-qty-error`, `cart-item-line-total`                                    |
| **Source**             | AC-1                                                                                                    |
| **Note**               | Confirms 20 is inclusive; a common off-by-one is treating 20 as "above 20".                             |

---

## TC-CART-003: Set quantity to the inner boundaries 2 and 19

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                 |
| **Issue**              | CART-12                                                                                                 |
| **Automation Score**   | HIGH (60/67.5)                                                                                          |
| **ISTQB Technique**    | BVA — three-value, min+1 (2) and max-1 (19)                                                             |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | One item in the cart at quantity 5                                                                      |
| **Steps**              | 1. Open the cart <br> 2. Set the quantity to `2` and commit <br> 3. Set the quantity to `19` and commit |
| **Expected**           | After step 2 the field shows `2`; after step 3 it shows `19`. No message or dialog at either step. Line total follows each value. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`                                                           |
| **Source**             | AC-1                                                                                                    |
| **Note**               | N/A — no caveats                                                                                        |

---

## TC-CART-004: Quantity 21 is rejected and the previous quantity is kept

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                |
| **Issue**              | CART-12                                                                                                 |
| **Automation Score**   | HIGH (62/67.5)                                                                                          |
| **ISTQB Technique**    | BVA — three-value, max+1 (21)                                                                           |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | One item in the cart at quantity 7                                                                      |
| **Steps**              | 1. Open the cart <br> 2. Clear the quantity field <br> 3. Type `21` <br> 4. Commit the value            |
| **Expected**           | Message "You can buy at most 20 of this item." is shown next to the field. Field shows `7`. Line total is unchanged (7 × unit price). Item remains in the cart. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-qty-error`, `cart-item-line-total`                                    |
| **Source**             | AC-3                                                                                                    |
| **Note**               | Message text is quoted from AC-3 and must match exactly, including the final full stop.                 |

---

## TC-CART-005: Quantity 0 with confirmation removes the item

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                |
| **Issue**              | CART-12                                                                                                 |
| **Automation Score**   | HIGH (58/67.5)                                                                                          |
| **ISTQB Technique**    | Decision Table — column 1: quantity = 0, shopper confirms → item removed                                |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Two distinct items in the cart, item A at quantity 2 and item B at quantity 1                           |
| **Steps**              | 1. Open the cart <br> 2. Clear item A's quantity field <br> 3. Type `0` <br> 4. Commit the value <br> 5. In the dialog, choose **Remove** (A5) |
| **Expected**           | After step 4 a dialog shows "Remove this item?". After step 5 the dialog closes, item A is no longer listed, item B remains at quantity 1, and the subtotal equals item B's line total. |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`, `remove-item-confirm`, `cart-item-row`, `cart-subtotal`    |
| **Source**             | AC-2                                                                                                    |
| **Note**               | Item B guards against removing the wrong line.                                                          |

---

## TC-CART-006: Quantity 0 with cancellation keeps the item and its previous quantity

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                |
| **Issue**              | CART-12                                                                                                 |
| **Automation Score**   | HIGH (58/67.5)                                                                                          |
| **ISTQB Technique**    | Decision Table — column 2: quantity = 0, shopper cancels → item kept                                    |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | One item in the cart at quantity 2                                                                      |
| **Steps**              | 1. Open the cart <br> 2. Clear the quantity field <br> 3. Type `0` <br> 4. Commit the value <br> 5. In the dialog, choose **Cancel** |
| **Expected**           | Dialog closes. Item remains in the cart with the field showing `2` (A3). Line total and subtotal are unchanged. |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`, `remove-item-cancel`, `cart-item-row`                      |
| **Source**             | AC-2                                                                                                    |
| **Note**               | Covers the "only when the shopper confirms" clause. Also check closing the dialog with ESC behaves as Cancel; raise a defect if ESC removes the item. |

---

## TC-CART-007: Decimal quantity is rejected

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                 |
| **Issue**              | CART-12                                                                                                 |
| **Automation Score**   | HIGH (56/67.5)                                                                                          |
| **ISTQB Technique**    | EP — invalid partition: non-integer number (`2.5`)                                                      |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | One item in the cart at quantity 3                                                                      |
| **Steps**              | 1. Open the cart <br> 2. Clear the quantity field <br> 3. Type `2.5` <br> 4. Commit the value           |
| **Expected**           | Value is not accepted (A4): field shows `3` after commit, or the input refuses the `.` character. No removal dialog. Line total unchanged. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`                                                           |
| **Source**             | Added by QA (AC-1 says "whole numbers" but no AC states what happens to a fraction)                     |
| **Note**               | If the field silently rounds to 2 or 3, raise it as a question; rounding is not "accepts whole numbers". |

---

## TC-CART-008: Non-numeric text is rejected

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                 |
| **Issue**              | CART-12                                                                                                 |
| **Automation Score**   | HIGH (56/67.5)                                                                                          |
| **ISTQB Technique**    | EP — invalid partition: non-numeric input (`abc`)                                                       |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | One item in the cart at quantity 3                                                                      |
| **Steps**              | 1. Open the cart <br> 2. Clear the quantity field <br> 3. Type `abc` <br> 4. Commit the value           |
| **Expected**           | Value is not accepted: field shows `3` after commit, or letters cannot be typed. No removal dialog. No "at most 20" message. Line total unchanged. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-qty-error`                                                            |
| **Source**             | Added by QA (the ticket is silent on non-numeric input)                                                 |
| **Note**               | N/A — no caveats                                                                                        |

---

## TC-CART-009: Negative quantity is rejected without a removal prompt

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                 |
| **Issue**              | CART-12                                                                                                 |
| **Automation Score**   | HIGH (56/67.5)                                                                                          |
| **ISTQB Technique**    | EP — invalid partition: negative integer (`-1`)                                                         |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | One item in the cart at quantity 3                                                                      |
| **Steps**              | 1. Open the cart <br> 2. Clear the quantity field <br> 3. Type `-1` <br> 4. Commit the value            |
| **Expected**           | Value is not accepted: field shows `3`. No "Remove this item?" dialog. Item remains. Line total unchanged. |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`                                                             |
| **Source**             | Added by QA (the ticket is silent on negative numbers; a `< 1` check would wrongly route -1 to the AC-2 removal prompt) |
| **Note**               | Error guessing: implementations that test `qty < 1` instead of `qty === 0` trigger removal here.        |

---

## TC-CART-010: Empty quantity field keeps the previous quantity

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                 |
| **Issue**              | CART-12                                                                                                 |
| **Automation Score**   | HIGH (56/67.5)                                                                                          |
| **ISTQB Technique**    | EP — invalid partition: empty value                                                                     |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | One item in the cart at quantity 3                                                                      |
| **Steps**              | 1. Open the cart <br> 2. Clear the quantity field <br> 3. Commit with the field empty                   |
| **Expected**           | Field reverts to `3`. No removal dialog. Item remains. Line total unchanged.                            |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`                                                             |
| **Source**             | Added by QA (the ticket is silent on an empty field; an empty string coerced to 0 would trigger AC-2)   |
| **Note**               | Error guessing: `Number("")` is `0` in JavaScript.                                                      |

---

## TC-CART-011: Quantity far above the maximum shows the same limit message

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                 |
| **Issue**              | CART-12                                                                                                 |
| **Automation Score**   | HIGH (56/67.5)                                                                                          |
| **ISTQB Technique**    | EP — invalid partition: above max, interior value (`999`)                                               |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | One item in the cart at quantity 4                                                                      |
| **Steps**              | 1. Open the cart <br> 2. Clear the quantity field <br> 3. Type `999` <br> 4. Commit the value           |
| **Expected**           | Message "You can buy at most 20 of this item." is shown. Field shows `4`. Line total unchanged.         |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-qty-error`                                                            |
| **Source**             | AC-3                                                                                                    |
| **Note**               | Also try `00021` (leading zeros) by hand; it must be treated as 21, not as a valid value.               |

---

## TC-CART-012: Limit message clears after a valid quantity is entered

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                 |
| **Issue**              | CART-12                                                                                                 |
| **Automation Score**   | HIGH (54/67.5)                                                                                          |
| **ISTQB Technique**    | State Transition — Error shown → valid input → Normal                                                   |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | One item in the cart at quantity 4                                                                      |
| **Steps**              | 1. Open the cart <br> 2. Set the quantity to `21` and commit <br> 3. Set the quantity to `20` and commit |
| **Expected**           | After step 2 the limit message is shown and the field shows `4`. After step 3 the message is gone and the field shows `20`. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-qty-error`                                                            |
| **Source**             | Added by QA (the ticket is silent on when the AC-3 message disappears)                                  |
| **Note**               | Error guessing: stale error state left on screen after recovery.                                        |

---

## TC-CART-013: Removing the last item leaves an empty cart

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                 |
| **Issue**              | CART-12                                                                                                 |
| **Automation Score**   | HIGH (54/67.5)                                                                                          |
| **ISTQB Technique**    | State Transition — Cart with one item → remove → Empty cart                                             |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Exactly one item in the cart at quantity 1                                                              |
| **Steps**              | 1. Open the cart <br> 2. Set the quantity to `0` and commit <br> 3. Choose **Remove** in the dialog     |
| **Expected**           | No item rows remain. The cart's empty state is shown. Subtotal is zero or hidden. No console errors on the page. |
| **data-testid needed** | `cart-item-row`, `cart-empty-state`, `cart-subtotal`                                                    |
| **Source**             | Added by QA (the ticket is silent on the empty-cart state after removal)                                |
| **Note**               | Error guessing: empty-list rendering.                                                                   |

---

## TC-CART-014: Line total and subtotal update after a quantity change

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p1 @e2e @cart @candidate`                                                                     |
| **Issue**              | CART-12                                                                                                 |
| **Automation Score**   | HIGH (58/67.5)                                                                                          |
| **ISTQB Technique**    | EP — valid partition, observed on pricing rather than on the field                                      |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Two items in the cart: item A at quantity 1 with unit price P<sub>A</sub>, item B at quantity 2 with unit price P<sub>B</sub> |
| **Steps**              | 1. Open the cart <br> 2. Set item A's quantity to `5` and commit                                        |
| **Expected**           | Item A's line total equals 5 × P<sub>A</sub>. Item B's line total is unchanged. Subtotal equals 5 × P<sub>A</sub> + 2 × P<sub>B</sub>. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`, `cart-subtotal`                                          |
| **Source**             | Added by QA (the story goal "buy the amount I need" implies pricing follows quantity; no AC states it)  |
| **Note**               | Assumption A6.                                                                                          |

---

## TC-CART-015: Changed quantity persists after reloading the cart

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                 |
| **Issue**              | CART-12                                                                                                 |
| **Automation Score**   | MEDIUM (49/67.5)                                                                                        |
| **ISTQB Technique**    | State Transition — committed quantity survives a page reload                                            |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | One item in the cart at quantity 3                                                                      |
| **Steps**              | 1. Open the cart <br> 2. Set the quantity to `8` and commit <br> 3. Reload the page                     |
| **Expected**           | After reload the field shows `8` and the line total equals 8 × unit price.                              |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`                                                           |
| **Source**             | Added by QA (the ticket is silent on persistence; a change that only lives in component state is lost at checkout) |
| **Note**               | Scored MEDIUM because persistence depends on backend or storage setup not described in the story.       |

---

## Rule not applied

The `context-discovery` rule could not be loaded: no `qa-rules` skill is installed, and the working directory holds no source code to ground the cases in. All preconditions, messages and selectors above follow assumptions A1 to A8.
