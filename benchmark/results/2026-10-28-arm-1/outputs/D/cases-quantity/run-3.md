---
feature: Cart Quantity Management
feature_code: CART
tc_count: 9
tracker_issues: CART-12
risk_level: MEDIUM
runbook: N/A — no runbook yet
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-28
---

# Test Cases — Cart Quantity Management

| Field                | Value                                    |
| -------------------- | ---------------------------------------- |
| **Project**          | E-commerce Platform                      |
| **Author**           | Senior QA Engineer                       |
| **Date Created**     | 2026-10-28                               |
| **Last Updated**     | 2026-10-28                               |
| **Methodology**      | ISTQB CTFL v4.0 — EP, BVA, Decision Table |

---

## TC-CART-001: Set quantity to minimum valid value (1)

| Field                  | Value                                                    |
| ---------------------- | -------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                       |
| **Issue**              | CART-12                                                  |
| **Automation Score**   | HIGH (59/67.5)                                           |
| **ISTQB Technique**    | BVA — minimum valid boundary (1)                         |
| **Manual Env**         | Local, Staging                                           |
| **Precondition**       | Cart contains one item with quantity 5; quantity field is visible and editable |
| **Steps**              | 1. Click the quantity input field <br> 2. Clear current value <br> 3. Enter `1` <br> 4. Press Enter or Tab to confirm |
| **Expected**           | Quantity updates to 1. No error message appears. Item remains in cart. Cart total updates correctly. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-total-price`           |
| **Source**             | AC-1                                                     |
| **Note**               | N/A — no caveats                                         |

---

## TC-CART-002: Set quantity to maximum valid value (20)

| Field                  | Value                                                    |
| ---------------------- | -------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                       |
| **Issue**              | CART-12                                                  |
| **Automation Score**   | HIGH (59/67.5)                                           |
| **ISTQB Technique**    | BVA — maximum valid boundary (20)                        |
| **Manual Env**         | Local, Staging                                           |
| **Precondition**       | Cart contains one item with quantity 5; quantity field is visible and editable |
| **Steps**              | 1. Click the quantity input field <br> 2. Clear current value <br> 3. Enter `20` <br> 4. Press Enter or Tab to confirm |
| **Expected**           | Quantity updates to 20. No error message appears. Item remains in cart. Cart total updates correctly. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-total-price`           |
| **Source**             | AC-1                                                     |
| **Note**               | N/A — no caveats                                         |

---

## TC-CART-003: Set quantity to valid mid-range value (10)

| Field                  | Value                                                    |
| ---------------------- | -------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                  |
| **Issue**              | CART-12                                                  |
| **Automation Score**   | HIGH (57/67.5)                                           |
| **ISTQB Technique**    | EP — valid partition (any value 2–19)                    |
| **Manual Env**         | Local, Staging                                           |
| **Precondition**       | Cart contains one item with quantity 5; quantity field is visible and editable |
| **Steps**              | 1. Click the quantity input field <br> 2. Clear current value <br> 3. Enter `10` <br> 4. Press Enter or Tab to confirm |
| **Expected**           | Quantity updates to 10. No error message appears. Item remains in cart. Cart total updates correctly. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-total-price`           |
| **Source**             | AC-1                                                     |
| **Note**               | N/A — no caveats                                         |

---

## TC-CART-004: Set quantity to 0 and confirm removal

| Field                  | Value                                                    |
| ---------------------- | -------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                       |
| **Issue**              | CART-12                                                  |
| **Automation Score**   | HIGH (60/67.5)                                           |
| **ISTQB Technique**    | Decision Table — quantity=0, user confirms action        |
| **Manual Env**         | Local, Staging                                           |
| **Precondition**       | Cart contains one item with quantity 5; quantity field is visible and editable |
| **Steps**              | 1. Click the quantity input field <br> 2. Clear current value <br> 3. Enter `0` <br> 4. Press Enter or Tab <br> 5. In the confirmation dialog, click **Remove** button |
| **Expected**           | Confirmation dialog appears with text "Remove this item?". After confirming, item is deleted from cart. Cart updates. Empty-cart state shown if this was the last item. |
| **data-testid needed** | `cart-item-quantity-input`, `removal-confirm-dialog`, `removal-confirm-button` |
| **Source**             | AC-2                                                     |
| **Note**               | Dialog text must exactly match specification              |

---

## TC-CART-005: Set quantity to 0 and cancel removal

| Field                  | Value                                                    |
| ---------------------- | -------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                  |
| **Issue**              | CART-12                                                  |
| **Automation Score**   | MEDIUM (48/67.5)                                         |
| **ISTQB Technique**    | Decision Table — quantity=0, user cancels action         |
| **Manual Env**         | Local, Staging                                           |
| **Precondition**       | Cart contains one item with quantity 5; quantity field is visible and editable |
| **Steps**              | 1. Click the quantity input field <br> 2. Clear current value <br> 3. Enter `0` <br> 4. Press Enter or Tab <br> 5. In the confirmation dialog, click **Cancel** button |
| **Expected**           | Confirmation dialog appears. After canceling, dialog closes. Item remains in cart with previous quantity (5). No change to cart. |
| **data-testid needed** | `cart-item-quantity-input`, `removal-confirm-dialog`, `removal-cancel-button` |
| **Source**             | AC-2                                                     |
| **Note**               | Quantity field should revert to previous value (5) after cancel |

---

## TC-CART-006: Set quantity above 20 shows error message

| Field                  | Value                                                    |
| ---------------------- | -------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                       |
| **Issue**              | CART-12                                                  |
| **Automation Score**   | HIGH (58/67.5)                                           |
| **ISTQB Technique**    | BVA — above maximum (21, max+1)                          |
| **Manual Env**         | Local, Staging                                           |
| **Precondition**       | Cart contains one item with quantity 5; quantity field is visible and editable |
| **Steps**              | 1. Click the quantity input field <br> 2. Clear current value <br> 3. Enter `21` <br> 4. Press Enter or Tab to confirm |
| **Expected**           | Error message appears exactly: "You can buy at most 20 of this item." Quantity field reverts to previous value (5). Item remains in cart with original quantity. |
| **data-testid needed** | `cart-item-quantity-input`, `quantity-error-message`     |
| **Source**             | AC-3                                                     |
| **Note**               | Error message must match exactly; quantity must not change |

---

## TC-CART-007: Set quantity to 100 shows error and preserves previous quantity

| Field                  | Value                                                    |
| ---------------------- | -------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                  |
| **Issue**              | CART-12                                                  |
| **Automation Score**   | MEDIUM (47/67.5)                                         |
| **ISTQB Technique**    | EP — invalid partition (far above max)                   |
| **Manual Env**         | Local, Staging                                           |
| **Precondition**       | Cart contains one item with quantity 8; quantity field is visible and editable |
| **Steps**              | 1. Click the quantity input field <br> 2. Clear current value <br> 3. Enter `100` <br> 4. Press Enter or Tab to confirm |
| **Expected**           | Error message appears: "You can buy at most 20 of this item." Quantity field shows previous value (8). Cart total reflects quantity 8. |
| **data-testid needed** | `cart-item-quantity-input`, `quantity-error-message`, `cart-total-price` |
| **Source**             | AC-3                                                     |
| **Note**               | Tests large out-of-range value; error handling must be consistent |

---

## TC-CART-008: Set quantity to negative value is rejected

| Field                  | Value                                                    |
| ---------------------- | -------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                  |
| **Issue**              | CART-12                                                  |
| **Automation Score**   | MEDIUM (46/67.5)                                         |
| **ISTQB Technique**    | EP — invalid partition (negative)                        |
| **Manual Env**         | Local, Staging                                           |
| **Precondition**       | Cart contains one item with quantity 5; quantity field is visible and editable |
| **Steps**              | 1. Click the quantity input field <br> 2. Clear current value <br> 3. Enter `-5` <br> 4. Press Enter or Tab to confirm |
| **Expected**           | Input is rejected or an error message appears. Quantity remains at previous value (5). Item stays in cart. |
| **data-testid needed** | `cart-item-quantity-input`, `quantity-error-message`     |
| **Source**             | Added by QA (AC-1 requires whole numbers 1–20; negative numbers are outside this range) |
| **Note**               | Assumption: field validates via client-side or server-side; exact error message not specified in AC |

---

## TC-CART-009: Set quantity to decimal value is rejected

| Field                  | Value                                                    |
| ---------------------- | -------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                  |
| **Issue**              | CART-12                                                  |
| **Automation Score**   | MEDIUM (45/67.5)                                         |
| **ISTQB Technique**    | EP — invalid partition (decimal/non-integer)             |
| **Manual Env**         | Local, Staging                                           |
| **Precondition**       | Cart contains one item with quantity 5; quantity field is visible and editable |
| **Steps**              | 1. Click the quantity input field <br> 2. Clear current value <br> 3. Enter `5.5` <br> 4. Press Enter or Tab to confirm |
| **Expected**           | Input is rejected or rounded/truncated, or error appears. Quantity remains at previous value (5). Item stays in cart. |
| **data-testid needed** | `cart-item-quantity-input`, `quantity-error-message`     |
| **Source**             | Added by QA (AC-1 requires "whole numbers"; decimals violate this requirement) |
| **Note**               | Assumption: field type is `number` with `step="1"` or validation rejects decimals; exact behavior not specified in AC |
