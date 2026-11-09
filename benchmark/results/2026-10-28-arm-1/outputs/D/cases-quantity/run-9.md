---
feature: Cart Item Quantity Management
feature_code: CART
tc_count: 11
tracker_issues: CART-12
risk_level: HIGH
runbook: N/A — runbook not provided
implementation_pack: N/A — implementation pack path not provided
spec: N/A — not automated yet
last_updated: 2026-10-28
---

# Test Cases — Cart Item Quantity Management

| Field            | Value                                            |
| ---------------- | ------------------------------------------------ |
| **Project**      | E-Commerce Platform                              |
| **Author**       | Senior QA Engineer                               |
| **Date Created** | 2026-10-28                                       |
| **Last Updated** | 2026-10-28                                       |
| **Methodology**  | ISTQB CTFL v4.0 — Equivalence Partitioning, BVA |

---

## TC-CART-001: Set quantity to minimum valid value (1)

| Field                  | Value                                                              |
| ---------------------- | ------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                 |
| **Issue**              | CART-12                                                            |
| **Automation Score**   | HIGH (56/67.5)                                                     |
| **ISTQB Technique**    | BVA — minimum boundary value                                       |
| **Manual Env**         | Local, Staging                                                     |
| **Precondition**       | Cart contains an item with quantity ≥ 2; cart page is loaded       |
| **Steps**              | 1. Locate the quantity field for any cart item <br> 2. Clear field and enter `1` <br> 3. Confirm/blur the field |
| **Expected**           | Quantity updates to 1. Item remains in cart. No error message.     |
| **data-testid needed** | `cart-item-quantity-input`, `cart-item`                             |
| **Source**             | AC-1                                                               |
| **Note**               | N/A — no caveats                                                   |

---

## TC-CART-002: Set quantity to maximum valid value (20)

| Field                  | Value                                                              |
| ---------------------- | ------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                 |
| **Issue**              | CART-12                                                            |
| **Automation Score**   | HIGH (56/67.5)                                                     |
| **ISTQB Technique**    | BVA — maximum boundary value                                       |
| **Manual Env**         | Local, Staging                                                     |
| **Precondition**       | Cart contains an item with current quantity < 20; cart page loaded |
| **Steps**              | 1. Locate the quantity field for any cart item <br> 2. Clear field and enter `20` <br> 3. Confirm/blur the field |
| **Expected**           | Quantity updates to 20. Item remains in cart. No error message.    |
| **data-testid needed** | `cart-item-quantity-input`, `cart-item`                             |
| **Source**             | AC-1                                                               |
| **Note**               | N/A — no caveats                                                   |

---

## TC-CART-003: Set quantity to value within valid range (mid-range)

| Field                  | Value                                                              |
| ---------------------- | ------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                            |
| **Issue**              | CART-12                                                            |
| **Automation Score**   | HIGH (54/67.5)                                                     |
| **ISTQB Technique**    | EP — valid partition (interior value)                              |
| **Manual Env**         | Local, Staging                                                     |
| **Precondition**       | Cart contains an item with quantity ≠ 10; cart page loaded         |
| **Steps**              | 1. Locate the quantity field for any cart item <br> 2. Clear field and enter `10` <br> 3. Confirm/blur the field |
| **Expected**           | Quantity updates to 10. Item remains in cart. No error message.    |
| **data-testid needed** | `cart-item-quantity-input`, `cart-item`                             |
| **Source**             | AC-1                                                               |
| **Note**               | N/A — no caveats                                                   |

---

## TC-CART-004: Set quantity to 0 and confirm item removal

| Field                  | Value                                                              |
| ---------------------- | ------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate`                                 |
| **Issue**              | CART-12                                                            |
| **Automation Score**   | HIGH (57/67.5)                                                     |
| **ISTQB Technique**    | State Transition — transition to removal state                     |
| **Manual Env**         | Local, Staging                                                     |
| **Precondition**       | Cart contains at least one item; cart page loaded                  |
| **Steps**              | 1. Locate the quantity field for any cart item <br> 2. Clear field and enter `0` <br> 3. Confirm/blur the field <br> 4. Click confirmation button in the removal dialog |
| **Expected**           | Confirmation dialog appears with text "Remove this item?" <br> Item is removed from cart upon confirmation. Cart item count decreases. |
| **data-testid needed** | `cart-item-quantity-input`, `remove-confirmation-dialog`, `confirm-remove-btn` |
| **Source**             | AC-2                                                               |
| **Note**               | N/A — no caveats                                                   |

---

## TC-CART-005: Set quantity to 0 and cancel removal

| Field                  | Value                                                              |
| ---------------------- | ------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                            |
| **Issue**              | CART-12                                                            |
| **Automation Score**   | MEDIUM (45/67.5)                                                   |
| **ISTQB Technique**    | State Transition — cancel transition (remain in cart state)        |
| **Manual Env**         | Local, Staging                                                     |
| **Precondition**       | Cart contains at least one item with quantity ≥ 1; cart page loaded |
| **Steps**              | 1. Locate the quantity field for any cart item <br> 2. Clear field and enter `0` <br> 3. Confirm/blur the field <br> 4. Click cancel/dismiss button in the removal dialog |
| **Expected**           | Confirmation dialog appears with text "Remove this item?" <br> On cancel: dialog closes, item remains in cart with original quantity restored. |
| **data-testid needed** | `cart-item-quantity-input`, `remove-confirmation-dialog`, `cancel-remove-btn` |
| **Source**             | AC-2                                                               |
| **Note**               | N/A — no caveats                                                   |

---

## TC-CART-006: Set quantity one above maximum (21)

| Field                  | Value                                                              |
| ---------------------- | ------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                            |
| **Issue**              | CART-12                                                            |
| **Automation Score**   | HIGH (55/67.5)                                                     |
| **ISTQB Technique**    | BVA — one above maximum boundary                                   |
| **Manual Env**         | Local, Staging                                                     |
| **Precondition**       | Cart contains an item with quantity < 20 (e.g., 5); cart page loaded |
| **Steps**              | 1. Note the current quantity value <br> 2. Locate the quantity field <br> 3. Clear field and enter `21` <br> 4. Confirm/blur the field |
| **Expected**           | Error message appears exactly: "You can buy at most 20 of this item." <br> Quantity reverts to the previous value (5). Item remains in cart. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-quantity-error-message`           |
| **Source**             | AC-3                                                               |
| **Note**               | N/A — no caveats                                                   |

---

## TC-CART-007: Set quantity far above maximum (100)

| Field                  | Value                                                              |
| ---------------------- | ------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                            |
| **Issue**              | CART-12                                                            |
| **Automation Score**   | MEDIUM (42/67.5)                                                   |
| **ISTQB Technique**    | EP — invalid partition (far out of range)                          |
| **Manual Env**         | Local, Staging                                                     |
| **Precondition**       | Cart contains an item with quantity ≥ 1 (e.g., 3); cart page loaded |
| **Steps**              | 1. Note the current quantity value <br> 2. Locate the quantity field <br> 3. Clear field and enter `100` <br> 4. Confirm/blur the field |
| **Expected**           | Error message appears exactly: "You can buy at most 20 of this item." <br> Quantity reverts to the previous value (3). Item remains in cart. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-quantity-error-message`           |
| **Source**             | AC-3                                                               |
| **Note**               | N/A — no caveats                                                   |

---

## TC-CART-008: Attempt to set quantity to negative number

| Field                  | Value                                                              |
| ---------------------- | ------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @cart @manual-only`                          |
| **Issue**              | CART-12                                                            |
| **Automation Score**   | LOW (28/67.5)                                                      |
| **ISTQB Technique**    | EP — invalid partition (negative value)                            |
| **Manual Env**         | Local, Staging                                                     |
| **Precondition**       | Cart contains an item with quantity ≥ 1 (e.g., 2); cart page loaded |
| **Steps**              | 1. Note the current quantity value <br> 2. Locate the quantity field <br> 3. Clear field and enter `-5` <br> 4. Confirm/blur the field |
| **Expected**           | Field rejects negative input (via HTML input type constraint) OR error message shown. Quantity remains at previous value (2). No state change. |
| **data-testid needed** | `cart-item-quantity-input`                                          |
| **Source**             | Added by QA (AC-1 specifies 1–20; negative numbers violate spec) |
| **Note**               | Assumption: input field uses HTML type="number" or equivalent validation. Behavior unspecified; marked manual-only to verify. |

---

## TC-CART-009: Attempt to set quantity to decimal number

| Field                  | Value                                                              |
| ---------------------- | ------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @cart @manual-only`                          |
| **Issue**              | CART-12                                                            |
| **Automation Score**   | LOW (30/67.5)                                                      |
| **ISTQB Technique**    | EP — invalid partition (non-integer)                               |
| **Manual Env**         | Local, Staging                                                     |
| **Precondition**       | Cart contains an item with quantity ≥ 1 (e.g., 4); cart page loaded |
| **Steps**              | 1. Note the current quantity value <br> 2. Locate the quantity field <br> 3. Clear field and enter `5.5` <br> 4. Confirm/blur the field |
| **Expected**           | Field rejects decimal input (via step="1" or validation) OR rounds to nearest integer. Quantity behavior is defined and consistent. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-quantity-error-message`           |
| **Source**             | Added by QA (AC-1 explicitly specifies "whole numbers") |
| **Note**               | Assumption: input field uses step="1" or equivalent validation. Behavior unspecified in AC; marked manual-only. |

---

## TC-CART-010: Attempt to set quantity to empty/blank value

| Field                  | Value                                                              |
| ---------------------- | ------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @cart @manual-only`                          |
| **Issue**              | CART-12                                                            |
| **Automation Score**   | LOW (32/67.5)                                                      |
| **ISTQB Technique**    | Error Guessing — empty state edge case                             |
| **Manual Env**         | Local, Staging                                                     |
| **Precondition**       | Cart contains an item with quantity ≥ 1 (e.g., 3); cart page loaded |
| **Steps**              | 1. Note the current quantity value <br> 2. Locate the quantity field <br> 3. Clear field completely (leave empty) <br> 4. Confirm/blur the field |
| **Expected**           | Field either: (a) re-populates with the previous quantity, (b) shows required field error, or (c) defaults to 1. Quantity is never lost. Item is never removed unintentionally. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-quantity-error-message`           |
| **Source**             | Added by QA (edge case: empty field behavior not specified in AC-1–AC-3) |
| **Note**               | Assumption: blank field is treated as invalid per good UX practice. Marked manual-only to confirm intended behavior. |

---

## TC-CART-011: Change quantity multiple times in succession (state accumulation)

| Field                  | Value                                                              |
| ---------------------- | ------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                            |
| **Issue**              | CART-12                                                            |
| **Automation Score**   | MEDIUM (44/67.5)                                                   |
| **ISTQB Technique**    | Error Guessing — state accumulation and stale state                |
| **Manual Env**         | Local, Staging                                                     |
| **Precondition**       | Cart contains an item with quantity = 5; cart page loaded           |
| **Steps**              | 1. Change quantity to 10 and confirm/blur <br> 2. Change quantity to 2 and confirm/blur <br> 3. Change quantity to 15 and confirm/blur |
| **Expected**           | Each change persists correctly without losing state. Final quantity is 15. Cart subtotal reflects each update correctly. No stale renders. |
| **data-testid needed** | `cart-item-quantity-input`, `cart-subtotal-price`                   |
| **Source**             | Added by QA (state management stability under repeated mutations) |
| **Note**               | N/A — no caveats                                                   |
