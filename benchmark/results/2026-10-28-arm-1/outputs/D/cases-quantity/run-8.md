---
feature: Change Quantity in Cart
feature_code: CART
tc_count: 8
tracker_issues: CART-12
risk_level: MEDIUM
runbook: N/A — standard cart interaction, no special runbook required
implementation_pack: N/A — not specified
spec: N/A — not specified
last_updated: 2026-10-28
---

# Test Cases — Change Quantity in Cart

| Field            | Value                                    |
| ---------------- | ---------------------------------------- |
| **Project**      | E-commerce Platform                     |
| **Author**       | QA Engineer — Senior QA ISTQB CTFL v4.0 |
| **Date Created** | 2026-10-28                               |
| **Last Updated** | 2026-10-28                               |
| **Methodology**  | ISTQB CTFL v4.0 — BVA, EP, State Transition, Error Guessing |

---

## TC-CART-001: Set quantity to valid value within range

| Field                  | Value                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                          |
| **Issue**              | CART-12                                                                                     |
| **Automation Score**   | HIGH (60/67.5)                                                                              |
| **ISTQB Technique**    | EP — valid partition (quantity within 1–20)                                                 |
| **Manual Env**         | Local, Staging                                                                              |
| **Precondition**       | Cart contains at least one item with quantity currently set to 1                            |
| **Steps**              | 1. Click the quantity field for the item <br> 2. Clear current value <br> 3. Enter `5` <br> 4. Press Enter or click outside the field |
| **Expected**           | Quantity updates to 5. Cart total updates accordingly. Item remains in cart.                |
| **data-testid needed** | `quantity-input-{item-id}`, `cart-total`                                                   |
| **Source**             | AC-1                                                                                        |
| **Note**               | Assumption: quantity field updates on blur or Enter key. Cart recalculates totals in real-time. |

---

## TC-CART-002: Set quantity to minimum valid value (1)

| Field                  | Value                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @e2e @cart @candidate`                                                     |
| **Issue**              | CART-12                                                                                     |
| **Automation Score**   | HIGH (58/67.5)                                                                              |
| **ISTQB Technique**    | BVA — boundary minimum (1)                                                                  |
| **Manual Env**         | Local, Staging                                                                              |
| **Precondition**       | Cart contains an item with quantity currently set to 5                                      |
| **Steps**              | 1. Click the quantity field <br> 2. Clear and enter `1` <br> 3. Press Enter                 |
| **Expected**           | Quantity updates to 1. Item remains in cart. Cart total updates.                           |
| **data-testid needed** | `quantity-input-{item-id}`, `cart-item-row`                                                |
| **Source**             | AC-1                                                                                        |
| **Note**               | N/A — no caveats                                                                            |

---

## TC-CART-003: Set quantity to maximum valid value (20)

| Field                  | Value                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @e2e @cart @candidate`                                                     |
| **Issue**              | CART-12                                                                                     |
| **Automation Score**   | HIGH (58/67.5)                                                                              |
| **ISTQB Technique**    | BVA — boundary maximum (20)                                                                 |
| **Manual Env**         | Local, Staging                                                                              |
| **Precondition**       | Cart contains an item with quantity currently set to 5                                      |
| **Steps**              | 1. Click the quantity field <br> 2. Clear and enter `20` <br> 3. Press Enter                |
| **Expected**           | Quantity updates to 20. Item remains in cart. Cart total updates.                          |
| **data-testid needed** | `quantity-input-{item-id}`, `cart-total`                                                   |
| **Source**             | AC-1                                                                                        |
| **Note**               | N/A — no caveats                                                                            |

---

## TC-CART-004: Attempt to set quantity above maximum (21)

| Field                  | Value                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                     |
| **Issue**              | CART-12                                                                                     |
| **Automation Score**   | HIGH (56/67.5)                                                                              |
| **ISTQB Technique**    | BVA — boundary maximum+1 (21); invalid partition                                           |
| **Manual Env**         | Local, Staging                                                                              |
| **Precondition**       | Cart contains an item with quantity currently set to 10                                     |
| **Steps**              | 1. Click the quantity field <br> 2. Clear and enter `21` <br> 3. Press Enter                |
| **Expected**           | Error message displays: "You can buy at most 20 of this item." Quantity reverts to 10 (previous valid value). Item remains in cart. |
| **data-testid needed** | `quantity-input-{item-id}`, `quantity-error-message`                                       |
| **Source**             | AC-3                                                                                        |
| **Note**               | Assumption: field validates and reverts on blur or Enter. Error message matches AC-3 exactly. |

---

## TC-CART-005: Set quantity to 0 and confirm item removal

| Field                  | Value                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                     |
| **Issue**              | CART-12                                                                                     |
| **Automation Score**   | MEDIUM (48/67.5)                                                                            |
| **ISTQB Technique**    | State Transition — invalid quantity triggers removal flow                                   |
| **Manual Env**         | Local, Staging                                                                              |
| **Precondition**       | Cart contains at least one item with quantity 3; confirmation dialog not previously dismissed |
| **Steps**              | 1. Click the quantity field <br> 2. Clear and enter `0` <br> 3. Press Enter <br> 4. In the confirmation dialog, click **Remove** |
| **Expected**           | Confirmation dialog appears with text "Remove this item?". On **Remove** click, item is deleted from cart. Cart updates. |
| **data-testid needed** | `quantity-input-{item-id}`, `remove-confirmation-dialog`, `remove-confirm-btn`, `remove-cancel-btn` |
| **Source**             | AC-2                                                                                        |
| **Note**               | Assumption: entering 0 triggers a modal/dialog, not inline removal. Confirmation is required per AC-2. |

---

## TC-CART-006: Set quantity to 0, then cancel removal

| Field                  | Value                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                     |
| **Issue**              | CART-12                                                                                     |
| **Automation Score**   | MEDIUM (46/67.5)                                                                            |
| **ISTQB Technique**    | State Transition — cancellation path                                                        |
| **Manual Env**         | Local, Staging                                                                              |
| **Precondition**       | Cart contains at least one item with quantity 3                                             |
| **Steps**              | 1. Click the quantity field <br> 2. Clear and enter `0` <br> 3. Press Enter <br> 4. In the confirmation dialog, click **Cancel** |
| **Expected**           | Confirmation dialog appears. On **Cancel** click, dialog closes. Quantity field reverts to 3. Item remains in cart unchanged. |
| **data-testid needed** | `quantity-input-{item-id}`, `remove-confirmation-dialog`, `remove-cancel-btn`              |
| **Source**             | AC-2                                                                                        |
| **Note**               | Assumption: cancellation reverts the field to the previous valid quantity, not to empty or 0. |

---

## TC-CART-007: Enter non-integer value (decimal)

| Field                  | Value                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                     |
| **Issue**              | CART-12                                                                                     |
| **Automation Score**   | MEDIUM (40/67.5)                                                                            |
| **ISTQB Technique**    | EP — invalid partition (non-integer input)                                                  |
| **Manual Env**         | Local, Staging                                                                              |
| **Precondition**       | Cart contains an item with quantity set to 5                                                |
| **Steps**              | 1. Click the quantity field <br> 2. Clear and enter `5.5` <br> 3. Press Enter               |
| **Expected**           | Entry is rejected or field reverts to 5. No error message required (input validation silently prevents invalid entry) or error is shown per design. Quantity remains 5. |
| **data-testid needed** | `quantity-input-{item-id}`                                                                 |
| **Source**             | Added by QA (AC-1 requires whole numbers; this verifies rejection of fractional input)      |
| **Note**               | Assumption: field type is numeric and does not accept decimal points, or input is validated on submit. |

---

## TC-CART-008: Attempt to leave quantity field empty

| Field                  | Value                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                     |
| **Issue**              | CART-12                                                                                     |
| **Automation Score**   | MEDIUM (38/67.5)                                                                            |
| **ISTQB Technique**    | Error Guessing — empty state validation                                                     |
| **Manual Env**         | Local, Staging                                                                              |
| **Precondition**       | Cart contains an item with quantity 5                                                       |
| **Steps**              | 1. Click the quantity field <br> 2. Clear the field completely <br> 3. Press Enter or click outside |
| **Expected**           | Field either reverts to 5 or shows an inline error (e.g., "Quantity is required"). Item remains in cart. |
| **data-testid needed** | `quantity-input-{item-id}`                                                                 |
| **Source**             | Added by QA (the ticket is silent on empty input; empty state is a boundary condition)      |
| **Note**               | Assumption: required-field validation is implemented. Field does not allow submission with no value. |
