---
feature: Change Quantity in Cart
feature_code: CART
tc_count: 9
tracker_issues: [CART-12]
risk_level: MEDIUM
runbook: N/A — runbook not provided
implementation_pack: N/A — implementation pack not provided
spec: N/A — not specified in request
last_updated: 2026-10-28
---

# Test Cases — Change Quantity in Cart

| Field                | Value                                                     |
| -------------------- | --------------------------------------------------------- |
| **Project**          | E-commerce Platform                                       |
| **Author**           | Senior QA Engineer                                        |
| **Date Created**     | 2026-10-28                                                |
| **Last Updated**     | 2026-10-28                                                |
| **Methodology**      | ISTQB CTFL v4.0 — EP, BVA, Error Guessing                |

---

## TC-CART-001: Set quantity to valid value within mid-range (10)

| Field                  | Value                                                               |
| ---------------------- | ------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                  |
| **Issue**              | CART-12                                                             |
| **Automation Score**   | HIGH (64.5/67.5)                                                    |
| **ISTQB Technique**    | EP — valid partition (quantity 1–20)                                |
| **Manual Env**         | Local, Staging                                                      |
| **Precondition**       | Cart contains an item with current quantity of 5                    |
| **Steps**              | 1. Locate the quantity field for the item <br> 2. Clear field <br> 3. Enter `10` <br> 4. Trigger update (blur or click confirm button) |
| **Expected**           | Quantity field displays `10`. Cart total updates. No error message appears. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-total-price`                      |
| **Source**             | AC-1                                                                |
| **Note**               | Assumption: quantity input loses focus to trigger update; adjust if button confirmation is required |

---

## TC-CART-002: Set quantity to minimum boundary (1)

| Field                  | Value                                                               |
| ---------------------- | ------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                  |
| **Issue**              | CART-12                                                             |
| **Automation Score**   | HIGH (64.5/67.5)                                                    |
| **ISTQB Technique**    | BVA — min boundary (1)                                              |
| **Manual Env**         | Local, Staging                                                      |
| **Precondition**       | Cart contains an item with current quantity of 5                    |
| **Steps**              | 1. Locate the quantity field <br> 2. Clear and enter `1` <br> 3. Trigger update |
| **Expected**           | Quantity field displays `1`. Cart total updates correctly. No error or removal prompt appears. |
| **data-testid needed** | `cart-item-quantity-input`                                          |
| **Source**             | AC-1                                                                |
| **Note**               | N/A — no caveats                                                    |

---

## TC-CART-003: Set quantity to maximum boundary (20)

| Field                  | Value                                                               |
| ---------------------- | ------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                  |
| **Issue**              | CART-12                                                             |
| **Automation Score**   | HIGH (64.5/67.5)                                                    |
| **ISTQB Technique**    | BVA — max boundary (20)                                             |
| **Manual Env**         | Local, Staging                                                      |
| **Precondition**       | Cart contains an item with current quantity of 5                    |
| **Steps**              | 1. Locate the quantity field <br> 2. Clear and enter `20` <br> 3. Trigger update |
| **Expected**           | Quantity field displays `20`. Cart total updates. No error message appears. |
| **data-testid needed** | `cart-item-quantity-input`                                          |
| **Source**             | AC-1                                                                |
| **Note**               | N/A — no caveats                                                    |

---

## TC-CART-004: Set quantity to 0 displays removal confirmation dialog

| Field                  | Value                                                               |
| ---------------------- | ------------------------------------------------------------------- |
| **Tags**               | `@smoke @p1 @e2e @cart @candidate`                                  |
| **Issue**              | CART-12                                                             |
| **Automation Score**   | HIGH (63/67.5)                                                      |
| **ISTQB Technique**    | EP — invalid partition (0 triggers business logic)                 |
| **Manual Env**         | Local, Staging                                                      |
| **Precondition**       | Cart contains an item with current quantity of 5                    |
| **Steps**              | 1. Locate the quantity field <br> 2. Clear and enter `0` <br> 3. Trigger update |
| **Expected**           | Modal or inline dialog appears with text "Remove this item?" and two options: confirm and cancel. Item remains in cart with original quantity (5). |
| **data-testid needed** | `cart-item-quantity-input`, `remove-confirmation-dialog`, `remove-confirm-btn`, `remove-cancel-btn` |
| **Source**             | AC-2                                                                |
| **Note**               | Assumption: "Remove this item?" exact text; adjust if wording differs |

---

## TC-CART-005: Confirm removal after setting quantity to 0

| Field                  | Value                                                               |
| ---------------------- | ------------------------------------------------------------------- |
| **Tags**               | `@smoke @p1 @e2e @cart @candidate`                                  |
| **Issue**              | CART-12                                                             |
| **Automation Score**   | HIGH (63/67.5)                                                      |
| **ISTQB Technique**    | State Transition — Confirm removal action                           |
| **Manual Env**         | Local, Staging                                                      |
| **Precondition**       | Cart contains an item; removal confirmation dialog is open and visible |
| **Steps**              | 1. Click the confirm button in the dialog <br> 2. Wait for update   |
| **Expected**           | Item is removed from cart. Dialog closes. Cart total updates. Item no longer appears in cart line items. |
| **data-testid needed** | `remove-confirm-btn`, `cart-items-list`                             |
| **Source**             | AC-2                                                                |
| **Note**               | N/A — no caveats                                                    |

---

## TC-CART-006: Cancel removal after setting quantity to 0

| Field                  | Value                                                               |
| ---------------------- | ------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                             |
| **Issue**              | CART-12                                                             |
| **Automation Score**   | HIGH (63/67.5)                                                      |
| **ISTQB Technique**    | State Transition — Cancel removal action (return to previous state) |
| **Manual Env**         | Local, Staging                                                      |
| **Precondition**       | Cart contains an item with quantity 5; removal confirmation dialog is visible |
| **Steps**              | 1. Click the cancel button in the dialog <br> 2. Wait for response  |
| **Expected**           | Dialog closes. Item remains in cart with original quantity (5). Quantity field displays `5`. No item is removed. |
| **data-testid needed** | `remove-cancel-btn`, `cart-item-quantity-input`                     |
| **Source**             | AC-2                                                                |
| **Note**               | N/A — no caveats                                                    |

---

## TC-CART-007: Set quantity above 20 displays error message

| Field                  | Value                                                               |
| ---------------------- | ------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                             |
| **Issue**              | CART-12                                                             |
| **Automation Score**   | HIGH (64.5/67.5)                                                    |
| **ISTQB Technique**    | BVA — max+1 boundary (21)                                           |
| **Manual Env**         | Local, Staging                                                      |
| **Precondition**       | Cart contains an item with current quantity of 5                    |
| **Steps**              | 1. Locate the quantity field <br> 2. Clear and enter `21` <br> 3. Trigger update |
| **Expected**           | Error message displays: "You can buy at most 20 of this item." Quantity field reverts to previous value (5). No item is removed. |
| **data-testid needed** | `cart-item-quantity-input`, `quantity-error-message`                |
| **Source**             | AC-3                                                                |
| **Note**               | Assumption: exact error message text provided; verify in app       |

---

## TC-CART-008: Set quantity to high value (100) shows error and preserves quantity

| Field                  | Value                                                               |
| ---------------------- | ------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                             |
| **Issue**              | CART-12                                                             |
| **Automation Score**   | HIGH (62.5/67.5)                                                    |
| **ISTQB Technique**    | BVA — far boundary (100); Error Guessing (user input validation)    |
| **Manual Env**         | Local, Staging                                                      |
| **Precondition**       | Cart contains an item with current quantity of 5                    |
| **Steps**              | 1. Locate the quantity field <br> 2. Clear and enter `100` <br> 3. Trigger update |
| **Expected**           | Error message displays: "You can buy at most 20 of this item." Quantity field reverts to `5`. Cart total unchanged. |
| **data-testid needed** | `cart-item-quantity-input`, `quantity-error-message`                |
| **Source**             | AC-3                                                                |
| **Note**               | Added by QA (tests boundary enforcement beyond AC-3 example) |

---

## TC-CART-009: Set quantity to decimal or non-whole number (e.g., 5.5) is rejected

| Field                  | Value                                                               |
| ---------------------- | ------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @deferred`                              |
| **Issue**              | CART-12                                                             |
| **Automation Score**   | MEDIUM (42/67.5)                                                    |
| **ISTQB Technique**    | Error Guessing — type validation                                    |
| **Manual Env**         | Local, Staging                                                      |
| **Precondition**       | Cart contains an item with current quantity of 5                    |
| **Steps**              | 1. Locate the quantity field <br> 2. Clear and enter `5.5` <br> 3. Attempt to trigger update |
| **Expected**           | Input is either rejected (field does not accept decimal), silently truncated to `5`, or an error message appears. Quantity field does not display `5.5`. Cart reflects no change. |
| **data-testid needed** | `cart-item-quantity-input`                                          |
| **Source**             | Added by QA (AC-1 states "whole numbers"; spec of how decimals are handled is missing) |
| **Note**               | Assumption: input type="number" with step="1", or client-side validation strips decimals. Verify exact behavior before automation. |
