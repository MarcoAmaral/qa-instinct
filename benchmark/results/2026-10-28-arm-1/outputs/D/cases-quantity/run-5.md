---
feature: Change the quantity of an item in the cart
feature_code: CART
tc_count: 8
tracker_issues: [CART-12]
risk_level: MEDIUM
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: tests/e2e/cart-quantity.spec.ts
last_updated: 2026-10-28
---

# Test Cases — Change the quantity of an item in the cart

| Field                | Value                                                      |
| -------------------- | ---------------------------------------------------------- |
| **Project**          | E-commerce Platform                                        |
| **Author**           | QA Engineer — Senior QA Engineer                           |
| **Date Created**     | 2026-10-28                                                 |
| **Last Updated**     | 2026-10-28                                                 |
| **Methodology**      | ISTQB CTFL v4.0 — EP, BVA, Error Guessing                  |

---

## TC-CART-001: Change quantity to a valid value within range (5)

| Field                  | Value                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                    |
| **Issue**              | [CART-12]                                                                             |
| **Automation Score**   | HIGH (60/67.5)                                                                        |
| **ISTQB Technique**    | EP — valid partition (whole number 1–20)                                              |
| **Manual Env**         | Local, Staging                                                                        |
| **Precondition**       | Cart contains an item with quantity 1; quantity field is visible and editable         |
| **Steps**              | 1. Click the quantity field for the item <br> 2. Clear and enter `5` <br> 3. Confirm change (press Enter or click Update) |
| **Expected**           | Quantity updates to 5. Cart subtotal recalculates. Item remains in cart with new quantity displayed. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-item-update-btn`, `cart-subtotal`                   |
| **Source**             | AC-1                                                                                  |
| **Note**               | Assumption: field accepts direct text input and requires confirmation (Enter key or button click). |

---

## TC-CART-002: Change quantity to minimum boundary value (1)

| Field                  | Value                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                               |
| **Issue**              | [CART-12]                                                                             |
| **Automation Score**   | HIGH (58/67.5)                                                                        |
| **ISTQB Technique**    | BVA — min boundary (1)                                                                |
| **Manual Env**         | Local, Staging                                                                        |
| **Precondition**       | Cart contains an item with quantity 5; quantity field is visible and editable         |
| **Steps**              | 1. Click the quantity field <br> 2. Clear and enter `1` <br> 3. Confirm change       |
| **Expected**           | Quantity updates to 1. Cart subtotal recalculates. Item remains in cart.              |
| **data-testid needed** | `cart-item-quantity-input`, `cart-subtotal`                                           |
| **Source**             | AC-1                                                                                  |
| **Note**               | Boundary: confirms system accepts the minimum valid value.                           |

---

## TC-CART-003: Change quantity to maximum boundary value (20)

| Field                  | Value                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                               |
| **Issue**              | [CART-12]                                                                             |
| **Automation Score**   | HIGH (58/67.5)                                                                        |
| **ISTQB Technique**    | BVA — max boundary (20)                                                               |
| **Manual Env**         | Local, Staging                                                                        |
| **Precondition**       | Cart contains an item with quantity 5; quantity field is visible and editable         |
| **Steps**              | 1. Click the quantity field <br> 2. Clear and enter `20` <br> 3. Confirm change      |
| **Expected**           | Quantity updates to 20. Cart subtotal recalculates. Item remains in cart.             |
| **data-testid needed** | `cart-item-quantity-input`, `cart-subtotal`                                           |
| **Source**             | AC-1                                                                                  |
| **Note**               | Boundary: confirms system accepts the maximum valid value.                           |

---

## TC-CART-004: Set quantity to 0 and confirm removal

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                                      |
| **Issue**              | [CART-12]                                                                                               |
| **Automation Score**   | HIGH (62/67.5)                                                                                          |
| **ISTQB Technique**    | EP — removal confirmation path (zero = removal trigger)                                                 |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Cart contains an item with quantity 3; quantity field is visible and editable                           |
| **Steps**              | 1. Click the quantity field <br> 2. Clear and enter `0` <br> 3. Confirm/submit change <br> 4. Click **Confirm** on the removal dialog |
| **Expected**           | Removal confirmation dialog appears with text "Remove this item?" <br> After confirmation, item is removed from cart. Cart subtotal updates. |
| **data-testid needed** | `cart-item-quantity-input`, `removal-confirmation-dialog`, `removal-confirm-btn`                        |
| **Source**             | AC-2                                                                                                    |
| **Note**               | Assumption: entering 0 triggers a confirmation dialog before removal.                                   |

---

## TC-CART-005: Set quantity to 0 and cancel removal

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                 |
| **Issue**              | [CART-12]                                                                                               |
| **Automation Score**   | MEDIUM (42/67.5)                                                                                        |
| **ISTQB Technique**    | State Transition — zero entry; invalid event (cancel); return to previous state                         |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Cart contains an item with quantity 3; quantity field is visible and editable                           |
| **Steps**              | 1. Click the quantity field <br> 2. Clear and enter `0` <br> 3. Confirm/submit change <br> 4. Click **Cancel** on the removal dialog |
| **Expected**           | Removal dialog appears. After clicking Cancel, dialog closes. Item remains in cart with quantity 3. Quantity field reverts to 3. |
| **data-testid needed** | `cart-item-quantity-input`, `removal-confirmation-dialog`, `removal-cancel-btn`, `cart-item-quantity-display` |
| **Source**             | AC-2                                                                                                    |
| **Note**               | Confirms that cancellation prevents unintended removal.                                                 |

---

## TC-CART-006: Attempt to set quantity above 20 (21)

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                 |
| **Issue**              | [CART-12]                                                                                               |
| **Automation Score**   | HIGH (56/67.5)                                                                                          |
| **ISTQB Technique**    | BVA — max + 1 boundary (21); EP invalid partition                                                       |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Cart contains an item with quantity 5; quantity field is visible and editable                           |
| **Steps**              | 1. Click the quantity field <br> 2. Clear and enter `21` <br> 3. Attempt to confirm change             |
| **Expected**           | Error message displays: "You can buy at most 20 of this item." Quantity field reverts to previous value (5). Item remains in cart unchanged. |
| **data-testid needed** | `cart-item-quantity-input`, `quantity-error-message`                                                    |
| **Source**             | AC-3                                                                                                    |
| **Note**               | Assumption: error message appears inline or as a toast. Previous quantity is restored if user doesn't dismiss. |

---

## TC-CART-007: Attempt to set quantity to negative value (–5)

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @manual-only`                                                               |
| **Issue**              | [CART-12]                                                                                               |
| **Automation Score**   | LOW (28/67.5)                                                                                           |
| **ISTQB Technique**    | Error Guessing — off-by-one, invalid input class (negative)                                             |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Cart contains an item with quantity 5; quantity field is visible and editable                           |
| **Steps**              | 1. Click the quantity field <br> 2. Clear and enter `–5` <br> 3. Attempt to confirm change             |
| **Expected**           | Change is rejected. Error message displayed or field validation prevents submission. Quantity reverts to 5. Item remains unchanged. |
| **data-testid needed** | `cart-item-quantity-input`                                                                              |
| **Source**             | Added by QA (the ticket does not mention negative input; guessing boundary outside valid range)          |
| **Note**               | Assumption: system validates input before acceptance. May be client-side validation or server-side rejection. |

---

## TC-CART-008: Attempt to set quantity to decimal value (2.5)

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @manual-only`                                                               |
| **Issue**              | [CART-12]                                                                                               |
| **Automation Score**   | LOW (26/67.5)                                                                                           |
| **ISTQB Technique**    | Error Guessing — invalid input class (fractional when whole numbers only are accepted)                   |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Cart contains an item with quantity 5; quantity field is visible and editable                           |
| **Steps**              | 1. Click the quantity field <br> 2. Clear and enter `2.5` <br> 3. Attempt to confirm change            |
| **Expected**           | Change is rejected or decimal is truncated/rounded. If rejected, error message shown or field validation prevents submission. Quantity remains 5. |
| **data-testid needed** | `cart-item-quantity-input`                                                                              |
| **Source**             | Added by QA (AC-1 specifies "whole numbers"; testing that non-whole inputs are rejected)                |
| **Note**               | Assumption: field accepts only integer input via validation. Behavior (reject vs. truncate) is implementation-dependent. |
