---
feature: Cart Quantity Management
feature_code: CART
tc_count: 10
tracker_issues: [CART-12]
risk_level: HIGH
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-28
---

# Test Cases — Change Quantity of Cart Item

| Field            | Value                                |
| ---------------- | ------------------------------------ |
| **Project**      | E-commerce Platform                  |
| **Author**       | Senior QA Engineer                   |
| **Date Created** | 2026-10-28                           |
| **Last Updated** | 2026-10-28                           |
| **Methodology**  | ISTQB CTFL v4.0 — BVA, EP, ST        |

**Assumptions:**
- Cart feature is part of a web-based e-commerce application.
- A quantity input field exists on the cart item row (numeric or text).
- "Previous quantity" refers to the quantity before the user's attempted change.
- Removal confirmation is a modal dialog or inline confirmation UI.
- An item must already exist in the cart before each test begins.

---

## TC-CART-001: Quantity at lower boundary (1) accepted

| Field                  | Value                                                |
| ---------------------- | ---------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                   |
| **Issue**              | [CART-12](https://linear.app/issues/CART-12)         |
| **Automation Score**   | HIGH (54/67.5)                                       |
| **ISTQB Technique**    | BVA — lower boundary (min = 1)                       |
| **Manual Env**         | Local, Staging                                       |
| **Precondition**       | Item in cart with quantity 5                         |
| **Steps**              | 1. Click the quantity field <br> 2. Clear the field <br> 3. Enter `1` <br> 4. Press Enter or click outside the field |
| **Expected**           | Quantity updates to 1. Cart total recalculates.      |
| **data-testid needed** | `quantity-input`, `cart-item-total`                  |
| **Source**             | AC-1                                                 |
| **Note**               | N/A — no caveats                                     |

---

## TC-CART-002: Quantity at upper boundary (20) accepted

| Field                  | Value                                                |
| ---------------------- | ---------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                   |
| **Issue**              | [CART-12](https://linear.app/issues/CART-12)         |
| **Automation Score**   | HIGH (54/67.5)                                       |
| **ISTQB Technique**    | BVA — upper boundary (max = 20)                      |
| **Manual Env**         | Local, Staging                                       |
| **Precondition**       | Item in cart with quantity 5                         |
| **Steps**              | 1. Click the quantity field <br> 2. Clear the field <br> 3. Enter `20` <br> 4. Press Enter or click outside the field |
| **Expected**           | Quantity updates to 20. Cart total recalculates.     |
| **data-testid needed** | `quantity-input`, `cart-item-total`                  |
| **Source**             | AC-1                                                 |
| **Note**               | N/A — no caveats                                     |

---

## TC-CART-003: Quantity in valid middle range accepted

| Field                  | Value                                                |
| ---------------------- | ---------------------------------------------------- |
| **Tags**               | `@sanity @p0 @e2e @cart @candidate`                  |
| **Issue**              | [CART-12](https://linear.app/issues/CART-12)         |
| **Automation Score**   | HIGH (55/67.5)                                       |
| **ISTQB Technique**    | EP — valid partition (1 < q < 20)                    |
| **Manual Env**         | Local, Staging                                       |
| **Precondition**       | Item in cart with quantity 5                         |
| **Steps**              | 1. Click the quantity field <br> 2. Clear the field <br> 3. Enter `10` <br> 4. Press Enter or click outside the field |
| **Expected**           | Quantity updates to 10. Cart total recalculates.     |
| **data-testid needed** | `quantity-input`, `cart-item-total`                  |
| **Source**             | AC-1                                                 |
| **Note**               | N/A — no caveats                                     |

---

## TC-CART-004: Quantity zero triggers removal confirmation

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                      |
| **Issue**              | [CART-12](https://linear.app/issues/CART-12)                                            |
| **Automation Score**   | HIGH (53/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — Quantity → Removal Confirmation state                                |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | Item in cart with quantity 5                                                            |
| **Steps**              | 1. Click the quantity field <br> 2. Clear the field <br> 3. Enter `0` <br> 4. Press Enter or click outside the field |
| **Expected**           | A confirmation dialog appears with the text "Remove this item?". The item remains in the cart with its previous quantity (5). |
| **data-testid needed** | `quantity-input`, `remove-confirmation-dialog`, `cart-item-quantity-display`             |
| **Source**             | AC-2                                                                                     |
| **Note**               | N/A — no caveats                                                                        |

---

## TC-CART-005: Confirming removal deletes item from cart

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                                      |
| **Issue**              | [CART-12](https://linear.app/issues/CART-12)                                            |
| **Automation Score**   | HIGH (52/67.5)                                                                          |
| **ISTQB Technique**    | State Transition — Removal Confirmation → Item Removed state                            |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | Removal confirmation dialog is visible; item is in cart with quantity 0 attempted       |
| **Steps**              | 1. Click the confirm/remove button in the dialog                                        |
| **Expected**           | Dialog closes. Item is removed from cart. Cart total updates.                           |
| **data-testid needed** | `remove-confirmation-confirm-btn`, `cart-item-list`, `cart-total`                      |
| **Source**             | AC-2                                                                                     |
| **Note**               | N/A — no caveats                                                                        |

---

## TC-CART-006: Canceling removal keeps item in cart

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p1 @e2e @cart @candidate`                                                     |
| **Issue**              | [CART-12](https://linear.app/issues/CART-12)                                            |
| **Automation Score**   | MEDIUM (48/67.5)                                                                        |
| **ISTQB Technique**    | State Transition — Removal Confirmation → Item Remains state (invalid event)            |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | Removal confirmation dialog is visible; item was at quantity 5 before removal attempt   |
| **Steps**              | 1. Click the cancel button in the dialog                                                |
| **Expected**           | Dialog closes. Item remains in cart with its previous quantity (5) unchanged.           |
| **data-testid needed** | `remove-confirmation-cancel-btn`, `cart-item-quantity-display`                         |
| **Source**             | AC-2                                                                                     |
| **Note**               | N/A — no caveats                                                                        |

---

## TC-CART-007: Quantity just above max (21) rejected with error

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p1 @e2e @cart @candidate`                                                      |
| **Issue**              | [CART-12](https://linear.app/issues/CART-12)                                            |
| **Automation Score**   | HIGH (53/67.5)                                                                          |
| **ISTQB Technique**    | BVA — just above upper boundary (max + 1)                                               |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | Item in cart with quantity 10                                                           |
| **Steps**              | 1. Click the quantity field <br> 2. Clear the field <br> 3. Enter `21` <br> 4. Press Enter or click outside the field |
| **Expected**           | Error message "You can buy at most 20 of this item." appears. Quantity remains 10.      |
| **data-testid needed** | `quantity-input`, `error-message`, `cart-item-quantity-display`                         |
| **Source**             | AC-3                                                                                     |
| **Note**               | N/A — no caveats                                                                        |

---

## TC-CART-008: Quantity well above max (100) rejected with error

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                 |
| **Issue**              | [CART-12](https://linear.app/issues/CART-12)                                            |
| **Automation Score**   | MEDIUM (42/67.5)                                                                        |
| **ISTQB Technique**    | EP — invalid partition (well exceeds max)                                               |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | Item in cart with quantity 8                                                            |
| **Steps**              | 1. Click the quantity field <br> 2. Clear the field <br> 3. Enter `100` <br> 4. Press Enter or click outside the field |
| **Expected**           | Error message "You can buy at most 20 of this item." appears. Quantity remains 8.       |
| **data-testid needed** | `quantity-input`, `error-message`, `cart-item-quantity-display`                         |
| **Source**             | AC-3                                                                                     |
| **Note**               | N/A — no caveats                                                                        |

---

## TC-CART-009: Negative quantity rejected

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                 |
| **Issue**              | [CART-12](https://linear.app/issues/CART-12)                                            |
| **Automation Score**   | MEDIUM (40/67.5)                                                                        |
| **ISTQB Technique**    | EP — invalid partition (negative quantity)                                              |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | Item in cart with quantity 5                                                            |
| **Steps**              | 1. Click the quantity field <br> 2. Clear the field <br> 3. Enter `-5` <br> 4. Press Enter or click outside the field |
| **Expected**           | Field rejects input or shows error message. Quantity remains 5.                         |
| **data-testid needed** | `quantity-input`, `cart-item-quantity-display`                                          |
| **Source**             | Added by QA (the ticket is silent on negative quantities; whole numbers 1–20 are valid) |
| **Note**               | Assumption: field may reject negative input via HTML5 constraint or display an error.   |

---

## TC-CART-010: Non-integer decimal quantity rejected

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                 |
| **Issue**              | [CART-12](https://linear.app/issues/CART-12)                                            |
| **Automation Score**   | MEDIUM (39/67.5)                                                                        |
| **ISTQB Technique**    | EP — invalid partition (non-whole number)                                               |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | Item in cart with quantity 3                                                            |
| **Steps**              | 1. Click the quantity field <br> 2. Clear the field <br> 3. Enter `5.5` <br> 4. Press Enter or click outside the field |
| **Expected**           | Field rejects input or rounds to nearest whole number and shows error. Quantity remains 3. |
| **data-testid needed** | `quantity-input`, `cart-item-quantity-display`                                          |
| **Source**             | Added by QA (the ticket specifies whole numbers; decimal input is out of scope)         |
| **Note**               | Assumption: field is type="number" step="1" or shows validation error.                  |
