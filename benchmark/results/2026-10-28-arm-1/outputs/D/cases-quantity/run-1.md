---
feature: Cart Quantity Management
feature_code: CART
tc_count: 10
tracker_issues: CART-12
risk_level: MEDIUM
runbook: N/A — no runbook exists yet
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-28
---

# Test Cases — Cart Quantity Management

| Field            | Value                                                                    |
| ---------------- | ------------------------------------------------------------------------ |
| **Project**      | E-commerce Shopping Cart                                                 |
| **Author**       | Senior QA Engineer — ISTQB CTFL v4.0                                    |
| **Date Created** | 2026-10-28                                                               |
| **Last Updated** | 2026-10-28                                                               |
| **Methodology**  | ISTQB CTFL v4.0 — Equivalence Partitioning, Boundary Value Analysis, Decision Table |

---

## TC-CART-001: Update quantity to minimum valid value (1)

| Field                  | Value                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                    |
| **Issue**              | CART-12                                                                               |
| **Automation Score**   | HIGH (57.5/67.5)                                                                      |
| **ISTQB Technique**    | EP — valid partition (quantity = 1); BVA — minimum boundary                          |
| **Manual Env**         | Local, Staging                                                                        |
| **Precondition**       | Cart contains at least one item with current quantity of 5 or higher                  |
| **Steps**              | 1. Locate the quantity input field for an item <br> 2. Clear the field <br> 3. Enter `1` <br> 4. Press Enter or move focus away |
| **Expected**           | Quantity updates to 1. Item remains in cart. Cart subtotal recalculates correctly.   |
| **data-testid needed** | `cart-item-quantity-input`, `cart-subtotal`                                           |
| **Source**             | AC-1                                                                                  |
| **Note**               | Tests the lower valid boundary; assumption that field accepts direct input            |

---

## TC-CART-002: Update quantity to mid-range valid value (10)

| Field                  | Value                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                               |
| **Issue**              | CART-12                                                                               |
| **Automation Score**   | MEDIUM (52/67.5)                                                                      |
| **ISTQB Technique**    | EP — valid partition (quantity between 2 and 19)                                     |
| **Manual Env**         | Local, Staging                                                                        |
| **Precondition**       | Cart contains at least one item with current quantity of 5 or different value         |
| **Steps**              | 1. Locate the quantity input field for an item <br> 2. Clear the field <br> 3. Enter `10` <br> 4. Press Enter or move focus away |
| **Expected**           | Quantity updates to 10. Item remains in cart. Cart subtotal recalculates correctly.  |
| **data-testid needed** | `cart-item-quantity-input`, `cart-subtotal`                                           |
| **Source**             | AC-1                                                                                  |
| **Note**               | Tests a representative valid value in the middle of the accepted range                |

---

## TC-CART-003: Update quantity to maximum valid value (20)

| Field                  | Value                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                    |
| **Issue**              | CART-12                                                                               |
| **Automation Score**   | HIGH (57.5/67.5)                                                                      |
| **ISTQB Technique**    | BVA — maximum valid boundary (quantity = 20)                                         |
| **Manual Env**         | Local, Staging                                                                        |
| **Precondition**       | Cart contains at least one item with current quantity lower than 20                   |
| **Steps**              | 1. Locate the quantity input field for an item <br> 2. Clear the field <br> 3. Enter `20` <br> 4. Press Enter or move focus away |
| **Expected**           | Quantity updates to 20. Item remains in cart. Cart subtotal recalculates correctly.  |
| **data-testid needed** | `cart-item-quantity-input`, `cart-subtotal`                                           |
| **Source**             | AC-1                                                                                  |
| **Note**               | Tests the upper valid boundary                                                       |

---

## TC-CART-004: Set quantity to 0 and confirm item removal

| Field                  | Value                                                                                                                       |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                                                          |
| **Issue**              | CART-12                                                                                                                     |
| **Automation Score**   | HIGH (52.5/67.5)                                                                                                            |
| **ISTQB Technique**    | Decision Table — condition (quantity = 0); action (confirm removal = true); outcome (item removed)                         |
| **Manual Env**         | Local, Staging                                                                                                              |
| **Precondition**       | Cart contains at least one item with quantity > 0. Confirmation dialog is enabled.                                         |
| **Steps**              | 1. Locate the quantity input field for an item <br> 2. Clear the field <br> 3. Enter `0` <br> 4. Press Enter <br> 5. Wait for confirmation dialog <br> 6. Click "Confirm" or "Yes" button |
| **Expected**           | Confirmation dialog appears with text "Remove this item?". Upon confirmation, item is removed from cart. Cart updates immediately. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-remove-confirmation-dialog`, `cart-remove-confirm-button`                                |
| **Source**             | AC-2                                                                                                                        |
| **Note**               | Dialog text must match exactly; assumption that removal happens on confirmation only                                       |

---

## TC-CART-005: Set quantity to 0 and cancel item removal

| Field                  | Value                                                                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                             |
| **Issue**              | CART-12                                                                                                                             |
| **Automation Score**   | MEDIUM (47.5/67.5)                                                                                                                  |
| **ISTQB Technique**    | Decision Table — condition (quantity = 0); action (confirm removal = false); outcome (quantity reverts, item kept)               |
| **Manual Env**         | Local, Staging                                                                                                                      |
| **Precondition**       | Cart contains at least one item with quantity of 5 or higher. Confirmation dialog is enabled.                                      |
| **Steps**              | 1. Locate the quantity input field for an item <br> 2. Clear the field <br> 3. Enter `0` <br> 4. Press Enter <br> 5. Wait for confirmation dialog <br> 6. Click "Cancel" or "No" button |
| **Expected**           | Confirmation dialog appears with text "Remove this item?". Upon cancellation, dialog closes. Quantity field reverts to its previous value (e.g., 5). Item remains in cart. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-remove-confirmation-dialog`, `cart-remove-cancel-button`                                         |
| **Source**             | AC-2                                                                                                                                 |
| **Note**               | Tests that cancellation preserves the item and its previous quantity                                                               |

---

## TC-CART-006: Attempt to set quantity above maximum (21)

| Field                  | Value                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                                                       |
| **Issue**              | CART-12                                                                                                                  |
| **Automation Score**   | HIGH (54/67.5)                                                                                                           |
| **ISTQB Technique**    | BVA — just above maximum boundary (quantity = 21)                                                                        |
| **Manual Env**         | Local, Staging                                                                                                           |
| **Precondition**       | Cart contains at least one item with quantity of 10. Field is editable.                                                  |
| **Steps**              | 1. Locate the quantity input field for an item <br> 2. Clear the field <br> 3. Enter `21` <br> 4. Press Enter or move focus away |
| **Expected**           | Error message appears: "You can buy at most 20 of this item." Quantity field reverts to previous value (e.g., 10). Item remains in cart. No confirmation dialog appears. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-error-message`                                                                         |
| **Source**             | AC-3                                                                                                                     |
| **Note**               | Error message must match exactly; boundary +1 is most critical to test                                                   |

---

## TC-CART-007: Attempt to set quantity well above maximum (100)

| Field                  | Value                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @cart`                                                                                             |
| **Issue**              | CART-12                                                                                                                  |
| **Automation Score**   | MEDIUM (50/67.5)                                                                                                         |
| **ISTQB Technique**    | EP — invalid partition (quantity far above maximum)                                                                      |
| **Manual Env**         | Local, Staging                                                                                                           |
| **Precondition**       | Cart contains at least one item with quantity of 5. Field is editable.                                                   |
| **Steps**              | 1. Locate the quantity input field for an item <br> 2. Clear the field <br> 3. Enter `100` <br> 4. Press Enter or move focus away |
| **Expected**           | Error message appears: "You can buy at most 20 of this item." Quantity field reverts to previous value (e.g., 5). Item remains in cart. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-error-message`                                                                         |
| **Source**             | AC-3                                                                                                                     |
| **Note**               | Tests error handling for extreme out-of-range values                                                                     |

---

## TC-CART-008: Attempt to set quantity to decimal value (1.5)

| Field                  | Value                                                                                                                       |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @manual-only`                                                                                  |
| **Issue**              | CART-12                                                                                                                    |
| **Automation Score**   | MEDIUM (45/67.5)                                                                                                           |
| **ISTQB Technique**    | EP — invalid partition (fractional quantity)                                                                              |
| **Manual Env**         | Local, Staging                                                                                                             |
| **Precondition**       | Cart contains at least one item with quantity of 5. Quantity input field is visible.                                      |
| **Steps**              | 1. Locate the quantity input field for an item <br> 2. Clear the field <br> 3. Enter `1.5` <br> 4. Press Enter or move focus away |
| **Expected**           | Input is rejected (field remains empty or reverts to previous value). No error message required, but field does not accept the decimal. Quantity remains at previous value. |
| **data-testid needed** | `cart-item-quantity-input`                                                                                                 |
| **Source**             | Added by QA (AC-1 requires whole numbers; story is silent on how to handle decimal input)                                 |
| **Note**               | Assumption: field should reject non-integer input at input level or at submission; manual testing recommended due to varying browser input type behaviors |

---

## TC-CART-009: Attempt to set quantity to negative value (-5)

| Field                  | Value                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @cart @manual-only`                                                                                 |
| **Issue**              | CART-12                                                                                                                  |
| **Automation Score**   | MEDIUM (45/67.5)                                                                                                         |
| **ISTQB Technique**    | EP — invalid partition (negative quantity)                                                                               |
| **Manual Env**         | Local, Staging                                                                                                           |
| **Precondition**       | Cart contains at least one item with quantity of 5. Quantity input field is visible.                                     |
| **Steps**              | 1. Locate the quantity input field for an item <br> 2. Clear the field <br> 3. Enter `-5` <br> 4. Press Enter or move focus away |
| **Expected**           | Input is rejected. Field reverts to previous value (e.g., 5). No removal dialog appears. Item remains in cart.           |
| **data-testid needed** | `cart-item-quantity-input`                                                                                                |
| **Source**             | Added by QA (AC-1 requires positive whole numbers 1–20; story is silent on negative handling)                             |
| **Note**               | Assumption: field should reject negative input; validate using a number input type attribute if available                |

---

## TC-CART-010: Attempt to set quantity to non-numeric value (ABC)

| Field                  | Value                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @cart @manual-only`                                                                                 |
| **Issue**              | CART-12                                                                                                                  |
| **Automation Score**   | MEDIUM (45/67.5)                                                                                                         |
| **ISTQB Technique**    | EP — invalid partition (non-numeric input)                                                                               |
| **Manual Env**         | Local, Staging                                                                                                           |
| **Precondition**       | Cart contains at least one item with quantity of 5. Quantity input field is visible.                                     |
| **Steps**              | 1. Locate the quantity input field for an item <br> 2. Clear the field <br> 3. Enter `ABC` <br> 4. Press Enter or move focus away |
| **Expected**           | Input is rejected (field does not accept alphabetic characters or clears them automatically). Quantity remains at previous value (e.g., 5). Item remains in cart. |
| **data-testid needed** | `cart-item-quantity-input`                                                                                                |
| **Source**             | Added by QA (AC-1 requires whole numbers; story is silent on non-numeric input handling)                                  |
| **Note**               | Assumption: input field uses `type="number"` or includes client-side validation to reject non-numeric input              |
