---
feature: Cart — Change Item Quantity
feature_code: CART
tc_count: 8
tracker_issues: [CART-12]
risk_level: HIGH
runbook: N/A — no runbook required
implementation_pack: N/A — no implementation pack
spec: N/A — not yet automated
last_updated: 2026-10-28
---

# Test Cases — Change Item Quantity in Cart

| Field                | Value                                              |
| -------------------- | -------------------------------------------------- |
| **Project**          | E-commerce Platform                               |
| **Author**           | Senior QA Engineer — ISTQB CTFL v4.0              |
| **Date Created**     | 2026-10-28                                         |
| **Last Updated**     | 2026-10-28                                         |
| **Methodology**      | ISTQB CTFL v4.0 — BVA, EP, Error Guessing         |

**Assumptions:**
- Cart page displays item(s) with a quantity input field
- Quantity changes apply immediately or via a Save/Update button (treated as immediate for scope)
- The confirmation dialog for removal is modal and blocks further interaction until resolved
- Current item quantity is preserved when invalid input is rejected
- The app runs on a web platform with data-testid attributes for UI selectors
- Minimum version: cart contains at least one item before tests start

---

## TC-CART-001: Change quantity to valid value within range

| Field                  | Value                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                                         |
| **Issue**              | [CART-12](https://linear.app/cart-12)                                                                      |
| **Automation Score**   | HIGH (58/67.5)                                                                                             |
| **ISTQB Technique**    | EP — valid partition (quantity in range 1–20)                                                              |
| **Manual Env**         | Local, Staging                                                                                             |
| **Precondition**       | Cart page loaded with one item in cart; current quantity is 2; quantity input field is visible and enabled |
| **Steps**              | 1. Locate the quantity input field for the item <br> 2. Clear the current value <br> 3. Enter 5 <br> 4. Confirm change (Submit or blur if auto-save) |
| **Expected**           | Quantity updates to 5. Cart total recalculates. No error message. Item remains in cart.                    |
| **data-testid needed** | `cart-item-qty-input`, `cart-total`                                                                        |
| **Source**             | AC-1                                                                                                       |
| **Note**               | N/A — no caveats                                                                                           |

---

## TC-CART-002: Change quantity to minimum boundary (1)

| Field                  | Value                                                                                                    |
| ---------------------- | -------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                                       |
| **Issue**              | [CART-12](https://linear.app/cart-12)                                                                    |
| **Automation Score**   | HIGH (58/67.5)                                                                                           |
| **ISTQB Technique**    | BVA — boundary value, minimum (1)                                                                         |
| **Manual Env**         | Local, Staging                                                                                           |
| **Precondition**       | Cart page loaded with one item; current quantity is 10; quantity input field is visible                   |
| **Steps**              | 1. Locate the quantity input field <br> 2. Clear and enter 1 <br> 3. Confirm change                       |
| **Expected**           | Quantity updates to 1. Cart recalculates. Item remains in cart. No removal confirmation shown.            |
| **data-testid needed** | `cart-item-qty-input`                                                                                     |
| **Source**             | AC-1                                                                                                     |
| **Note**               | N/A — no caveats                                                                                          |

---

## TC-CART-003: Change quantity to maximum boundary (20)

| Field                  | Value                                                                                                    |
| ---------------------- | -------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                                       |
| **Issue**              | [CART-12](https://linear.app/cart-12)                                                                    |
| **Automation Score**   | HIGH (58/67.5)                                                                                           |
| **ISTQB Technique**    | BVA — boundary value, maximum (20)                                                                        |
| **Manual Env**         | Local, Staging                                                                                           |
| **Precondition**       | Cart page loaded with one item; current quantity is 5; quantity input field is visible                    |
| **Steps**              | 1. Locate the quantity input field <br> 2. Clear and enter 20 <br> 3. Confirm change                      |
| **Expected**           | Quantity updates to 20. Cart recalculates. Item remains. No error or warning shown.                       |
| **data-testid needed** | `cart-item-qty-input`, `cart-total`                                                                      |
| **Source**             | AC-1                                                                                                     |
| **Note**               | N/A — no caveats                                                                                          |

---

## TC-CART-004: Set quantity to 0 and confirm item removal

| Field                  | Value                                                                                                         |
| ---------------------- | ------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                                            |
| **Issue**              | [CART-12](https://linear.app/cart-12)                                                                         |
| **Automation Score**   | HIGH (56/67.5)                                                                                                |
| **ISTQB Technique**    | State Transition — quantity 0 triggers modal state; confirm action transitions to item-removed state          |
| **Manual Env**         | Local, Staging                                                                                                |
| **Precondition**       | Cart page loaded with one item; current quantity is 3; quantity input field is visible                       |
| **Steps**              | 1. Locate the quantity input field <br> 2. Clear and enter 0 <br> 3. A confirmation dialog appears <br> 4. Click **Confirm** or **Yes** button |
| **Expected**           | Dialog shows "Remove this item?" or similar confirmation message. Item is removed from cart. Cart total updates. No item row visible. |
| **data-testid needed** | `cart-item-qty-input`, `remove-confirmation-dialog`, `remove-confirm-btn`                                     |
| **Source**             | AC-2                                                                                                          |
| **Note**               | N/A — no caveats                                                                                              |

---

## TC-CART-005: Set quantity to 0, then cancel removal

| Field                  | Value                                                                                                         |
| ---------------------- | ------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                       |
| **Issue**              | [CART-12](https://linear.app/cart-12)                                                                         |
| **Automation Score**   | MEDIUM (52/67.5)                                                                                              |
| **ISTQB Technique**    | State Transition — quantity 0; cancel action reverts to previous quantity state                              |
| **Manual Env**         | Local, Staging                                                                                                |
| **Precondition**       | Cart page loaded with one item; current quantity is 2; quantity input field is visible                       |
| **Steps**              | 1. Locate the quantity input field <br> 2. Clear and enter 0 <br> 3. Confirmation dialog appears <br> 4. Click **Cancel** or **No** button |
| **Expected**           | Dialog closes without removing item. Quantity field reverts to previous value (2). Item remains in cart. Cart total unchanged. |
| **data-testid needed** | `cart-item-qty-input`, `remove-confirmation-dialog`, `remove-cancel-btn`                                      |
| **Source**             | AC-2                                                                                                          |
| **Note**               | N/A — no caveats                                                                                              |

---

## TC-CART-006: Attempt to set quantity above maximum (21)

| Field                  | Value                                                                                                                          |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                        |
| **Issue**              | [CART-12](https://linear.app/cart-12)                                                                                          |
| **Automation Score**   | HIGH (57/67.5)                                                                                                                 |
| **ISTQB Technique**    | BVA — invalid boundary, above maximum (max+1 = 21); EP — out-of-range partition                                                |
| **Manual Env**         | Local, Staging                                                                                                                 |
| **Precondition**       | Cart page loaded with one item; current quantity is 10; quantity input field is visible                                        |
| **Steps**              | 1. Locate the quantity input field <br> 2. Clear and enter 21 <br> 3. Attempt to confirm change (Submit or blur)               |
| **Expected**           | Error or warning message displays: "You can buy at most 20 of this item." Quantity reverts to and displays previous value (10). Item remains in cart. |
| **data-testid needed** | `cart-item-qty-input`, `qty-error-message`, `cart-total`                                                                       |
| **Source**             | AC-3                                                                                                                            |
| **Note**               | N/A — no caveats                                                                                                                |

---

## TC-CART-007: Attempt to set quantity to non-numeric value (letter)

| Field                  | Value                                                                                                                              |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @manual-only`                                                                                         |
| **Issue**              | [CART-12](https://linear.app/cart-12)                                                                                             |
| **Automation Score**   | MEDIUM (48/67.5)                                                                                                                  |
| **ISTQB Technique**    | Error Guessing — invalid input type (character where number expected); EP — invalid partition (non-numeric)                       |
| **Manual Env**         | Local, Staging                                                                                                                    |
| **Precondition**       | Cart page loaded with one item; current quantity is 5; quantity input field is visible and accepts text input                    |
| **Steps**              | 1. Locate the quantity input field <br> 2. Clear and enter 'abc' <br> 3. Attempt to confirm (Submit or blur)                     |
| **Expected**           | Input is rejected or sanitized. Quantity field either remains empty, shows an error message, or reverts to previous value (5). Item quantity unchanged. |
| **data-testid needed** | `cart-item-qty-input`, `qty-error-message`                                                                                        |
| **Source**             | Added by QA (the ticket is silent on invalid input type handling)                                                                 |
| **Note**               | Manual-only pending clarification of input validation UX (HTML5 `type=number` vs custom validation)                              |

---

## TC-CART-008: Attempt to set quantity to decimal value (3.5)

| Field                  | Value                                                                                                          |
| ---------------------- | -------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @manual-only`                                                                      |
| **Issue**              | [CART-12](https://linear.app/cart-12)                                                                          |
| **Automation Score**   | MEDIUM (48/67.5)                                                                                               |
| **ISTQB Technique**    | Error Guessing — fractional quantity (whole numbers required per AC-1); EP — invalid partition (non-integer)    |
| **Manual Env**         | Local, Staging                                                                                                 |
| **Precondition**       | Cart page loaded with one item; current quantity is 7; quantity input field is visible                         |
| **Steps**              | 1. Locate the quantity input field <br> 2. Clear and enter 3.5 <br> 3. Attempt to confirm change              |
| **Expected**           | Input rejected or converted to whole number (rounded down to 3, or rejected with error). Quantity reverts to 7 (previous). |
| **data-testid needed** | `cart-item-qty-input`                                                                                          |
| **Source**             | Added by QA (AC-1 specifies whole numbers; ticket silent on decimal handling)                                  |
| **Note**               | Behavior TBD: clarify whether decimals are stripped, rounded, or rejected                                      |
