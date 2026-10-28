---
feature: Quantity Adjustment in Cart
feature_code: CART
tc_count: 8
tracker_issues: [CART-12]
risk_level: MEDIUM
runbook: N/A — no runbook for this feature
implementation_pack: N/A — not specified
spec: tests/e2e/cart.spec.ts
last_updated: 2026-10-28
---

# Test Cases — Quantity Adjustment in Cart

| Field            | Value                                          |
| ---------------- | ---------------------------------------------- |
| **Project**      | E-commerce Platform                            |
| **Author**       | Senior QA Engineer — ISTQB CTFL v4.0           |
| **Date Created** | 2026-10-28                                     |
| **Last Updated** | 2026-10-28                                     |
| **Methodology**  | ISTQB CTFL v4.0 — BVA, EP, State Transition    |

**Assumptions**:
- Cart is displayed with at least one item and an editable quantity field
- Shopper is logged in with an active session
- "Remove this item?" is the exact confirmation dialog message
- Previous quantity is retained when a quantity update is rejected
- Decimal inputs (e.g., 5.5) are rejected or truncated to whole numbers

---

## TC-CART-001: Change quantity to a valid value within range

| Field                  | Value                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                                     |
| **Issue**              | [CART-12](https://linear.app/issues/CART-12)                                                          |
| **Automation Score**   | HIGH (60/67.5)                                                                                        |
| **ISTQB Technique**    | EP — valid partition (quantity 5 within range 1–20)                                                   |
| **Manual Env**         | Local, Staging                                                                                        |
| **Precondition**       | Cart is displayed with at least one item. Quantity field shows current value (e.g., 2).               |
| **Steps**              | 1. Click the quantity field <br> 2. Clear the current value <br> 3. Enter 5 <br> 4. Press Enter or blur the field |
| **Expected**           | Quantity updates to 5. Line-item subtotal recalculates. No error message shown. Cart total updates.   |
| **data-testid needed** | `cart-item-quantity-input`, `cart-line-subtotal`, `cart-total`                                        |
| **Source**             | AC-1                                                                                                   |
| **Note**               | N/A — no caveats                                                                                       |

---

## TC-CART-002: Set quantity to minimum boundary (1)

| Field                  | Value                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                |
| **Issue**              | [CART-12](https://linear.app/issues/CART-12)                                                          |
| **Automation Score**   | HIGH (58/67.5)                                                                                        |
| **ISTQB Technique**    | BVA — boundary (min = 1)                                                                               |
| **Manual Env**         | Local, Staging                                                                                        |
| **Precondition**       | Cart displays an item with quantity 10.                                                               |
| **Steps**              | 1. Click the quantity field <br> 2. Change value to 1 <br> 3. Confirm the change                      |
| **Expected**           | Quantity updates to 1. Cart total recalculates. Item remains in the cart.                             |
| **data-testid needed** | `cart-item-quantity-input`, `cart-total`                                                              |
| **Source**             | AC-1                                                                                                   |
| **Note**               | N/A — no caveats                                                                                       |

---

## TC-CART-003: Set quantity to maximum boundary (20)

| Field                  | Value                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                |
| **Issue**              | [CART-12](https://linear.app/issues/CART-12)                                                          |
| **Automation Score**   | HIGH (58/67.5)                                                                                        |
| **ISTQB Technique**    | BVA — boundary (max = 20)                                                                              |
| **Manual Env**         | Local, Staging                                                                                        |
| **Precondition**       | Cart displays an item with quantity 5.                                                                |
| **Steps**              | 1. Click the quantity field <br> 2. Change value to 20 <br> 3. Confirm the change                     |
| **Expected**           | Quantity updates to 20. Cart total recalculates. No error or warning message shown.                   |
| **data-testid needed** | `cart-item-quantity-input`, `cart-total`                                                              |
| **Source**             | AC-1                                                                                                   |
| **Note**               | N/A — no caveats                                                                                       |

---

## TC-CART-004: Attempt to set quantity above maximum (21)

| Field                  | Value                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                |
| **Issue**              | [CART-12](https://linear.app/issues/CART-12)                                                          |
| **Automation Score**   | HIGH (60/67.5)                                                                                        |
| **ISTQB Technique**    | BVA — boundary violation (21, above max)                                                               |
| **Manual Env**         | Local, Staging                                                                                        |
| **Precondition**       | Cart displays an item with quantity 10.                                                               |
| **Steps**              | 1. Click the quantity field <br> 2. Enter 21 <br> 3. Press Enter or blur the field                     |
| **Expected**           | Error message "You can buy at most 20 of this item." is shown. Quantity field reverts to 10 (previous value). Cart total is unchanged. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-error-message`                                                      |
| **Source**             | AC-3                                                                                                   |
| **Note**               | N/A — no caveats                                                                                       |

---

## TC-CART-005: Attempt to set quantity to 0 and confirm removal

| Field                  | Value                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p0 @e2e @cart @candidate`                                                                |
| **Issue**              | [CART-12](https://linear.app/issues/CART-12)                                                          |
| **Automation Score**   | HIGH (62/67.5)                                                                                        |
| **ISTQB Technique**    | State Transition — Quantity 0 triggers confirmation dialog; confirm removes item                       |
| **Manual Env**         | Local, Staging                                                                                        |
| **Precondition**       | Cart displays an item with quantity 3. Item name is "Blue Widget".                                    |
| **Steps**              | 1. Click the quantity field <br> 2. Enter 0 <br> 3. Press Enter or blur the field <br> 4. In the confirmation dialog, click **Remove** or **Yes** |
| **Expected**           | Confirmation dialog appears with text "Remove this item?". After confirmation, the item is removed from the cart. Cart total and item count update. |
| **data-testid needed** | `cart-item-quantity-input`, `remove-confirmation-dialog`, `remove-confirmation-button`                |
| **Source**             | AC-2                                                                                                   |
| **Note**               | N/A — no caveats                                                                                       |

---

## TC-CART-006: Attempt to set quantity to 0 but cancel removal

| Field                  | Value                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                |
| **Issue**              | [CART-12](https://linear.app/issues/CART-12)                                                          |
| **Automation Score**   | MEDIUM (48/67.5)                                                                                      |
| **ISTQB Technique**    | State Transition — Quantity 0 triggers confirmation; cancel reverts change                             |
| **Manual Env**         | Local, Staging                                                                                        |
| **Precondition**       | Cart displays an item with quantity 7.                                                                |
| **Steps**              | 1. Click the quantity field <br> 2. Enter 0 <br> 3. Press Enter <br> 4. In the confirmation dialog, click **Cancel** or **No** |
| **Expected**           | Confirmation dialog appears. After cancel, dialog closes. Quantity field reverts to 7. Item remains in cart. |
| **data-testid needed** | `cart-item-quantity-input`, `remove-confirmation-dialog`, `cancel-confirmation-button`                |
| **Source**             | AC-2                                                                                                   |
| **Note**               | N/A — no caveats                                                                                       |

---

## TC-CART-007: Enter non-numeric input in quantity field

| Field                  | Value                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                |
| **Issue**              | [CART-12](https://linear.app/issues/CART-12)                                                          |
| **Automation Score**   | MEDIUM (40/67.5)                                                                                      |
| **ISTQB Technique**    | Error Guessing — invalid input type (letters, symbols)                                                 |
| **Manual Env**         | Local, Staging                                                                                        |
| **Precondition**       | Cart displays an item with quantity 4.                                                                |
| **Steps**              | 1. Click the quantity field <br> 2. Enter "abc" or special characters <br> 3. Press Enter or blur      |
| **Expected**           | Non-numeric input is rejected or ignored. Quantity field either clears, reverts to 4, or displays an inline error. Cart total is unchanged. |
| **data-testid needed** | `cart-item-quantity-input`                                                                            |
| **Source**             | Added by QA (error handling not specified in AC; ensures robustness)                                  |
| **Note**               | Exact behavior (reject vs. clear vs. revert) depends on implementation; verify during automation setup.    |

---

## TC-CART-008: Enter decimal quantity (e.g., 5.5)

| Field                  | Value                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @cart @deferred`                                                                 |
| **Issue**              | [CART-12](https://linear.app/issues/CART-12)                                                          |
| **Automation Score**   | LOW (32/67.5)                                                                                         |
| **ISTQB Technique**    | Error Guessing — fractional input violates "whole numbers" requirement                                |
| **Manual Env**         | Local, Staging                                                                                        |
| **Precondition**       | Cart displays an item with quantity 3.                                                                |
| **Steps**              | 1. Click the quantity field <br> 2. Enter 5.5 <br> 3. Press Enter or blur                             |
| **Expected**           | Decimal is rejected or truncated to 5 (whole number). Field reverts to 3, clears, or shows inline error. AC-1 requirement "whole numbers" is enforced. |
| **data-testid needed** | `cart-item-quantity-input`                                                                            |
| **Source**             | Added by QA (AC-1 says whole numbers; edge case for decimal input)                                   |
| **Note**               | Low automation score: behavior not critical to core flow and may vary by implementation. Marked `@deferred`.    |
