---
feature: Cart Quantity Management
feature_code: CART
tc_count: 8
tracker_issues: [CART-12]
risk_level: MEDIUM
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-28
---

# Test Cases — Cart Quantity Management

| Field                | Value                                  |
| -------------------- | -------------------------------------- |
| **Project**          | E-commerce Platform                    |
| **Author**           | Senior QA Engineer — ISTQB CTFL v4.0   |
| **Date Created**     | 2026-10-28                             |
| **Last Updated**     | 2026-10-28                             |
| **Methodology**      | ISTQB CTFL v4.0 — EP, BVA, State Trans |

---

## TC-CART-001: Quantity accepts valid whole numbers within range

| Field                  | Value                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                    |
| **Issue**              | CART-12                                                                               |
| **Automation Score**   | HIGH (56/67.5)                                                                        |
| **ISTQB Technique**    | EP — valid partition (whole number 1–20)                                              |
| **Manual Env**         | Local, Staging                                                                        |
| **Precondition**       | An item exists in the cart with current quantity 1; quantity input field is visible   |
| **Steps**              | 1. Click the quantity input field <br> 2. Clear current value <br> 3. Enter `5` <br> 4. Press Enter or blur the field |
| **Expected**           | Quantity updates to 5. Cart total recalculates. Item remains in cart. No error shown. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-total-price`                                        |
| **Source**             | AC-1                                                                                  |
| **Note**               | Assumption: quantity field accepts keyboard input and blur/Enter to confirm           |

---

## TC-CART-002: Quantity boundary — minimum valid value (1)

| Field                  | Value                                                                        |
| ---------------------- | ---------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                      |
| **Issue**              | CART-12                                                                      |
| **Automation Score**   | HIGH (54/67.5)                                                               |
| **ISTQB Technique**    | BVA — min boundary (1 is the lowest valid quantity)                          |
| **Manual Env**         | Local, Staging                                                               |
| **Precondition**       | An item exists in the cart with current quantity 5; quantity input visible   |
| **Steps**              | 1. Click quantity input <br> 2. Clear and enter `1` <br> 3. Confirm (Enter) |
| **Expected**           | Quantity updates to 1. Item remains. No removal dialog appears.              |
| **data-testid needed** | `cart-item-quantity-input`, `cart-item-remove-dialog`                        |
| **Source**             | AC-1                                                                         |
| **Note**               | Boundary value test ensures 1 is accepted and does not trigger removal flow  |

---

## TC-CART-003: Quantity boundary — maximum valid value (20)

| Field                  | Value                                                                         |
| ---------------------- | ----------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                       |
| **Issue**              | CART-12                                                                       |
| **Automation Score**   | HIGH (54/67.5)                                                                |
| **ISTQB Technique**    | BVA — max boundary (20 is the highest valid quantity)                         |
| **Manual Env**         | Local, Staging                                                                |
| **Precondition**       | An item exists in the cart with current quantity 5; quantity input visible    |
| **Steps**              | 1. Click quantity input <br> 2. Clear and enter `20` <br> 3. Confirm (Enter) |
| **Expected**           | Quantity updates to 20. Cart total recalculates. No error shown.              |
| **data-testid needed** | `cart-item-quantity-input`, `cart-total-price`                                |
| **Source**             | AC-1                                                                          |
| **Note**               | Boundary value test ensures 20 is the inclusive upper limit                   |

---

## TC-CART-004: Quantity zero triggers removal confirmation dialog

| Field                  | Value                                                                                                                     |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                                                        |
| **Issue**              | CART-12                                                                                                                   |
| **Automation Score**   | HIGH (58/67.5)                                                                                                            |
| **ISTQB Technique**    | State Transition — from "item in cart" to "removal pending" state (entry condition)                                        |
| **Manual Env**         | Local, Staging                                                                                                            |
| **Precondition**       | An item exists in the cart with quantity 5; quantity input field is visible                                               |
| **Steps**              | 1. Click quantity input <br> 2. Clear and enter `0` <br> 3. Confirm (Enter or blur)                                      |
| **Expected**           | A dialog appears with the text "Remove this item?" and offers confirm/cancel buttons. Item quantity is still shown as `0`. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-item-remove-dialog`, `remove-confirm-btn`, `remove-cancel-btn`                         |
| **Source**             | AC-2                                                                                                                      |
| **Note**               | Assumption: the dialog appears synchronously; quantity field displays 0 until action is confirmed                         |

---

## TC-CART-005: User confirms item removal after setting quantity to zero

| Field                  | Value                                                                                                       |
| ---------------------- | ----------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                                          |
| **Issue**              | CART-12                                                                                                     |
| **Automation Score**   | HIGH (56/67.5)                                                                                              |
| **ISTQB Technique**    | State Transition — "removal pending" → "item removed" (valid transition)                                     |
| **Manual Env**         | Local, Staging                                                                                              |
| **Precondition**       | A removal dialog is visible with quantity set to 0; dialog shows "Remove this item?" and confirm button      |
| **Steps**              | 1. Click the confirm button (or "Yes"/"Remove")                                                             |
| **Expected**           | Item is removed from cart. Dialog closes. Cart displays updated item count and total. Item no longer listed. |
| **data-testid needed** | `remove-confirm-btn`, `cart-item-list`, `cart-empty-message` (if cart becomes empty)                        |
| **Source**             | AC-2                                                                                                        |
| **Note**               | Assumption: confirm button is the primary action in the dialog                                              |

---

## TC-CART-006: User cancels item removal after setting quantity to zero

| Field                  | Value                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                            |
| **Issue**              | CART-12                                                                                            |
| **Automation Score**   | HIGH (52/67.5)                                                                                     |
| **ISTQB Technique**    | State Transition — "removal pending" → "item in cart" (cancellation path; invalid removal action)   |
| **Manual Env**         | Local, Staging                                                                                     |
| **Precondition**       | A removal dialog is visible with quantity set to 0; "Remove this item?" and cancel button showing   |
| **Steps**              | 1. Click the cancel button (or "No"/"Keep")                                                        |
| **Expected**           | Dialog closes. Item remains in cart. Quantity field reverts to its previous value (before 0 entry). |
| **data-testid needed** | `remove-cancel-btn`, `cart-item-quantity-input`                                                    |
| **Source**             | AC-2                                                                                               |
| **Note**               | Tests that cancellation preserves the item and restores the prior quantity value                   |

---

## TC-CART-007: Quantity above 20 shows error and preserves previous quantity

| Field                  | Value                                                                                                                                           |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                         |
| **Issue**              | CART-12                                                                                                                                         |
| **Automation Score**   | HIGH (54/67.5)                                                                                                                                  |
| **ISTQB Technique**    | BVA — max+1 boundary (21 exceeds the upper limit)                                                                                               |
| **Manual Env**         | Local, Staging                                                                                                                                  |
| **Precondition**       | An item exists in the cart with quantity 5; quantity input field is visible                                                                      |
| **Steps**              | 1. Click quantity input <br> 2. Clear and enter `21` <br> 3. Confirm (Enter or blur)                                                          |
| **Expected**           | Error message displays: "You can buy at most 20 of this item." Quantity field reverts to or displays 5 (the previous valid quantity). No update. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-quantity-error-msg`                                                                                           |
| **Source**             | AC-3                                                                                                                                            |
| **Note**               | Assumption: error message is visible inline near the quantity field; previous quantity is preserved in the cart model                         |

---

## TC-CART-008: Quantity field rejects non-whole numbers (decimal input)

| Field                  | Value                                                                                                                 |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @manual-only`                                                                             |
| **Issue**              | CART-12                                                                                                               |
| **Automation Score**   | MEDIUM (41/67.5)                                                                                                      |
| **ISTQB Technique**    | EP — invalid partition (non-whole number; the AC specifies whole numbers)                                              |
| **Manual Env**         | Local, Staging                                                                                                        |
| **Precondition**       | An item exists in the cart with quantity 3; quantity input field is visible                                           |
| **Steps**              | 1. Click quantity input <br> 2. Clear and enter `5.5` <br> 3. Attempt to confirm (Enter or blur)                     |
| **Expected**           | Quantity field rejects the decimal input. Field either clears, shows an error, or reverts to the previous value (3).   |
| **data-testid needed** | `cart-item-quantity-input`                                                                                            |
| **Source**             | Added by QA (AC-1 specifies "whole numbers" but does not detail the rejection behavior for decimals)                  |
| **Note**               | Assumption: input type is number or enforced via validation; marked manual because behavior (reject vs. round) is TBD |
