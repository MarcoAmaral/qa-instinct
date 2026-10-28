---
feature: Cart — Change item quantity
feature_code: CART
tc_count: 13
tracker_issues: [CART-12]
risk_level: MEDIUM
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-23
---

# Test Cases — Cart: Change item quantity

| Field            | Value                                                      |
| ---------------- | ---------------------------------------------------------- |
| **Project**      | Online store (name not given in the ticket)                |
| **Author**       | Marco — Senior QA Analyst                                  |
| **Date Created** | 2026-10-23                                                 |
| **Last Updated** | 2026-10-23                                                 |
| **Methodology**  | ISTQB CTFL v4.0 — BVA (three-value), EP, Error Guessing    |

## Assumptions

The workspace contains no code for this feature, so preconditions and expected results could not be checked against an implementation. Each assumption below is also flagged in the case that depends on it.

- **A1 — Input type.** The quantity is a text or number input on the cart page; validation runs when the value is committed (blur or Enter). No +/- stepper is assumed.
- **A2 — Previous quantity.** "Keeps the previous quantity" means both the stored quantity and the value shown in the field return to what they were before the edit.
- **A3 — Confirm dialog.** The "Remove this item?" prompt has a confirm button labelled **Remove** and a cancel button labelled **Cancel**. Closing the prompt any other way (Esc, clicking outside) counts as not confirming.
- **A4 — Totals.** The line subtotal and cart total recalculate after a valid quantity change. The ticket does not say this; it is treated as expected shopper-visible behaviour.
- **A5 — Inputs outside 0–20.** The ticket is silent on negative, decimal, empty and non-numeric values. Assumed: they are rejected and the previous quantity is kept, with no removal prompt.
- **A6 — Seed data.** Every case starts with a signed-in shopper whose cart holds one in-stock item, "Test Product", at quantity 5, unit price 10.00.
- **A7 — Tracker.** `CART-12` matches the Linear and Jira ID formats and no base URL was given, so the ID is used as plain text.
- **Environments.** Local and Staging; no other environment is known.

Release gate: cases tagged `@gate` (TC-CART-001, 002, 005, 007).

---

## TC-CART-001: Set quantity to 1 (lower boundary)

| Field                  | Value                                                                                                                       |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                     |
| **Issue**              | CART-12                                                                                                                     |
| **Automation Score**   | HIGH (64/67.5)                                                                                                              |
| **ISTQB Technique**    | BVA — three-value, min (1)                                                                                                   |
| **Manual Env**         | Local, Staging                                                                                                              |
| **Precondition**       | Shopper signed in; cart holds "Test Product" at quantity 5, unit price 10.00 (A6); cart page open                            |
| **Steps**              | 1. Clear the quantity field for "Test Product" <br> 2. Type `1` <br> 3. Commit the value (blur or Enter)                     |
| **Expected**           | Field shows `1`. No message or prompt appears. Line subtotal shows 10.00 and cart total updates to 10.00 (A4). Item remains. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-subtotal`, `cart-total`                                                                   |
| **Source**             | AC-1                                                                                                                        |
| **Note**               | Depends on A1, A4, A6                                                                                                       |

---

## TC-CART-002: Set quantity to 20 (upper boundary)

| Field                  | Value                                                                                                                        |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                      |
| **Issue**              | CART-12                                                                                                                      |
| **Automation Score**   | HIGH (64/67.5)                                                                                                               |
| **ISTQB Technique**    | BVA — three-value, max (20)                                                                                                   |
| **Manual Env**         | Local, Staging                                                                                                               |
| **Precondition**       | Shopper signed in; cart holds "Test Product" at quantity 5, unit price 10.00 (A6); cart page open                             |
| **Steps**              | 1. Clear the quantity field for "Test Product" <br> 2. Type `20` <br> 3. Commit the value                                    |
| **Expected**           | Field shows `20`. The message "You can buy at most 20 of this item." does NOT appear. Line subtotal 200.00, cart total 200.00. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-subtotal`, `cart-total`, `cart-qty-error`                                                  |
| **Source**             | AC-1, AC-3 (20 itself must not trigger the limit message)                                                                    |
| **Note**               | Off-by-one guard: a `>=` instead of `>` in the limit check fails this case. Depends on A1, A4, A6                            |

---

## TC-CART-003: Set quantity to 2 and 19 (inner boundaries)

| Field                  | Value                                                                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                                                |
| **Issue**              | CART-12                                                                                                                                                                |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                                                         |
| **ISTQB Technique**    | BVA — three-value, min+1 (2) and max-1 (19)                                                                                                                             |
| **Manual Env**         | Local, Staging                                                                                                                                                         |
| **Precondition**       | Shopper signed in; cart holds "Test Product" at quantity 5, unit price 10.00 (A6); cart page open                                                                       |
| **Steps**              | 1. Set the quantity to `2` and commit <br> 2. Check field and totals <br> 3. Set the quantity to `19` and commit <br> 4. Check field and totals                         |
| **Expected**           | After step 1: field shows `2`, subtotal 20.00, no message. After step 3: field shows `19`, subtotal 190.00, no message. Item remains throughout.                        |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-subtotal`, `cart-qty-error`                                                                                                          |
| **Source**             | AC-1                                                                                                                                                                   |
| **Note**               | Depends on A1, A4, A6                                                                                                                                                  |

---

## TC-CART-004: Set a typical quantity and see totals recalculate

| Field                  | Value                                                                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@sanity @p1 @e2e @cart @candidate`                                                                                                        |
| **Issue**              | CART-12                                                                                                                                    |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                             |
| **ISTQB Technique**    | EP — valid partition (whole number 1–20), representative value 7                                                                            |
| **Manual Env**         | Local, Staging                                                                                                                             |
| **Precondition**       | Shopper signed in; cart holds "Test Product" at quantity 5, unit price 10.00, plus a second item "Other Product" at quantity 1, price 3.00 |
| **Steps**              | 1. Set the quantity of "Test Product" to `7` <br> 2. Commit the value                                                                      |
| **Expected**           | Field shows `7`. "Test Product" subtotal 70.00. Cart total 73.00. "Other Product" unchanged at quantity 1.                                 |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-subtotal`, `cart-total`                                                                                  |
| **Source**             | AC-1                                                                                                                                       |
| **Note**               | Second item added by QA to prove the change affects only the edited line. Depends on A4, A6                                                |

---

## TC-CART-005: Quantity 21 shows the limit message and keeps the previous quantity

| Field                  | Value                                                                                                                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                                               |
| **Issue**              | CART-12                                                                                                                                                                               |
| **Automation Score**   | HIGH (62/67.5)                                                                                                                                                                        |
| **ISTQB Technique**    | BVA — three-value, max+1 (21)                                                                                                                                                          |
| **Manual Env**         | Local, Staging                                                                                                                                                                        |
| **Precondition**       | Shopper signed in; cart holds "Test Product" at quantity 5, unit price 10.00 (A6); cart page open                                                                                      |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `21` <br> 3. Commit the value <br> 4. Reload the cart page                                                                                    |
| **Expected**           | Message "You can buy at most 20 of this item." appears next to the item. Field returns to `5`; subtotal stays 50.00; cart total stays 50.00. After reload the quantity is still 5. No removal prompt. |
| **data-testid needed** | `cart-item-qty-input`, `cart-qty-error`, `cart-item-subtotal`, `cart-total`                                                                                                           |
| **Source**             | AC-3                                                                                                                                                                                  |
| **Note**               | Step 4 proves the server did not store 21. Depends on A1, A2, A6                                                                                                                      |

---

## TC-CART-006: A quantity far above the limit is rejected the same way

| Field                  | Value                                                                                                                              |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                            |
| **Issue**              | CART-12                                                                                                                            |
| **Automation Score**   | HIGH (55/67.5)                                                                                                                     |
| **ISTQB Technique**    | EP — invalid partition (above 20), representative value 999                                                                        |
| **Manual Env**         | Local, Staging                                                                                                                     |
| **Precondition**       | Shopper signed in; cart holds "Test Product" at quantity 5 (A6); cart page open                                                    |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `999` <br> 3. Commit the value                                                            |
| **Expected**           | Message "You can buy at most 20 of this item." appears. Field returns to `5`. Totals unchanged. No removal prompt.                 |
| **data-testid needed** | `cart-item-qty-input`, `cart-qty-error`                                                                                            |
| **Source**             | AC-3                                                                                                                               |
| **Note**               | Depends on A1, A2, A6                                                                                                              |

---

## TC-CART-007: Quantity 0 asks for confirmation and removes the item on confirm

| Field                  | Value                                                                                                                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                                                                 |
| **Issue**              | CART-12                                                                                                                                                                                                 |
| **Automation Score**   | HIGH (60/67.5)                                                                                                                                                                                          |
| **ISTQB Technique**    | State Transition — In cart → Pending removal → Removed (confirm event); also BVA min-1 (0)                                                                                                               |
| **Manual Env**         | Local, Staging                                                                                                                                                                                          |
| **Precondition**       | Shopper signed in; cart holds "Test Product" at quantity 5 and "Other Product" at quantity 1; cart page open                                                                                            |
| **Steps**              | 1. Clear the quantity field of "Test Product" <br> 2. Type `0` <br> 3. Commit the value <br> 4. In the prompt, click **Remove** <br> 5. Reload the cart page                                              |
| **Expected**           | After step 3: a prompt with the exact text "Remove this item?" appears; the item is still in the cart. After step 4: prompt closes, "Test Product" is gone, "Other Product" remains, cart total 3.00. After reload "Test Product" is still absent. |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`, `remove-item-confirm`, `cart-item-row`, `cart-total`                                                                                                       |
| **Source**             | AC-2                                                                                                                                                                                                    |
| **Note**               | Button label **Remove** is assumed (A3). Checking the item is still present before confirming is the core of "only when the shopper confirms".                                                           |

---

## TC-CART-008: Cancelling the removal prompt keeps the item at its previous quantity

| Field                  | Value                                                                                                                                                       |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p0 @e2e @cart @candidate`                                                                                                                         |
| **Issue**              | CART-12                                                                                                                                                     |
| **Automation Score**   | HIGH (60/67.5)                                                                                                                                              |
| **ISTQB Technique**    | State Transition — Pending removal → In cart (cancel event)                                                                                                 |
| **Manual Env**         | Local, Staging                                                                                                                                              |
| **Precondition**       | Shopper signed in; cart holds "Test Product" at quantity 5 (A6); cart page open                                                                             |
| **Steps**              | 1. Set the quantity to `0` and commit <br> 2. In the "Remove this item?" prompt, click **Cancel** <br> 3. Reload the cart page                               |
| **Expected**           | Prompt closes. "Test Product" remains with field showing `5`, not `0`. Totals unchanged at 50.00. After reload quantity is 5.                                |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`, `remove-item-cancel`, `cart-item-row`                                                                          |
| **Source**             | AC-2                                                                                                                                                        |
| **Note**               | Watch for the field staying at `0` after cancel: that leaves an item whose displayed quantity is invalid. Depends on A2, A3                                   |

---

## TC-CART-009: Dismissing the removal prompt without choosing counts as not confirming

| Field                  | Value                                                                                                                                                                              |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                                                            |
| **Issue**              | CART-12                                                                                                                                                                            |
| **Automation Score**   | MEDIUM (50/67.5)                                                                                                                                                                   |
| **ISTQB Technique**    | State Transition — Pending removal, invalid/implicit event (Esc, click outside)                                                                                                     |
| **Manual Env**         | Local, Staging                                                                                                                                                                     |
| **Precondition**       | Shopper signed in; cart holds "Test Product" at quantity 5 (A6); cart page open                                                                                                    |
| **Steps**              | 1. Set the quantity to `0` and commit <br> 2. Press **Esc** <br> 3. Check the cart <br> 4. Repeat step 1, then click outside the prompt <br> 5. Check the cart                      |
| **Expected**           | In both cases the prompt closes (or stays open, see Note) and the item is NOT removed; field shows `5`; totals unchanged.                                                            |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`, `cart-item-row`                                                                                                                        |
| **Source**             | AC-2 ("only when the shopper confirms")                                                                                                                                            |
| **Note**               | A modal that ignores Esc and outside clicks also passes; the only failure is removal without an explicit confirm. Depends on A3                                                      |

---

## TC-CART-010: A negative quantity is rejected

| Field                  | Value                                                                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                            |
| **Issue**              | CART-12                                                                                                                                            |
| **Automation Score**   | HIGH (55/67.5)                                                                                                                                     |
| **ISTQB Technique**    | BVA — below 0 (-1); EP invalid partition (negative)                                                                                                |
| **Manual Env**         | Local, Staging                                                                                                                                     |
| **Precondition**       | Shopper signed in; cart holds "Test Product" at quantity 5 (A6); cart page open                                                                    |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `-1` <br> 3. Commit the value <br> 4. Reload the cart page                                                 |
| **Expected**           | Value is rejected: field returns to `5`, totals unchanged, no "Remove this item?" prompt, item not removed. After reload quantity is 5.             |
| **data-testid needed** | `cart-item-qty-input`, `cart-qty-error`, `remove-item-dialog`                                                                                      |
| **Source**             | Added by QA (the ticket is silent on negative values; AC-1 defines 1–20 and AC-2 defines 0 only)                                                   |
| **Note**               | The error message for this case is not specified (A5); any clear validation message is acceptable, but the limit message from AC-3 would be wrong. |

---

## TC-CART-011: A decimal quantity is rejected

| Field                  | Value                                                                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                   |
| **Issue**              | CART-12                                                                                                                                   |
| **Automation Score**   | HIGH (55/67.5)                                                                                                                            |
| **ISTQB Technique**    | EP — invalid partition (not a whole number), representative value 2.5                                                                     |
| **Manual Env**         | Local, Staging                                                                                                                            |
| **Precondition**       | Shopper signed in; cart holds "Test Product" at quantity 5 (A6); cart page open                                                           |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `2.5` <br> 3. Commit the value <br> 4. Reload the cart page                                       |
| **Expected**           | Value is rejected or the field refuses the character: quantity stays `5`, totals unchanged. It is NOT silently rounded to 2 or 3. After reload quantity is 5. |
| **data-testid needed** | `cart-item-qty-input`, `cart-qty-error`                                                                                                   |
| **Source**             | Added by QA (AC-1 says "whole numbers" but no AC states what happens to a decimal)                                                         |
| **Note**               | Silent rounding would change what the shopper is charged for without telling them. Depends on A5                                          |

---

## TC-CART-012: Empty or non-numeric input is rejected

| Field                  | Value                                                                                                                                                                       |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                                                     |
| **Issue**              | CART-12                                                                                                                                                                     |
| **Automation Score**   | MEDIUM (52/67.5)                                                                                                                                                            |
| **ISTQB Technique**    | EP — invalid partitions (empty; non-numeric)                                                                                                                                |
| **Manual Env**         | Local, Staging                                                                                                                                                              |
| **Precondition**       | Shopper signed in; cart holds "Test Product" at quantity 5 (A6); cart page open                                                                                             |
| **Steps**              | 1. Clear the quantity field and commit (empty) <br> 2. Check the cart <br> 3. Type `abc` and commit <br> 4. Check the cart <br> 5. Type `1e1` and commit <br> 6. Check the cart |
| **Expected**           | After each commit: quantity returns to `5`, totals unchanged, no removal prompt, item not removed. An empty field is not treated as 0.                                        |
| **data-testid needed** | `cart-item-qty-input`, `cart-qty-error`, `remove-item-dialog`                                                                                                               |
| **Source**             | Added by QA (the ticket is silent on empty and non-numeric input)                                                                                                           |
| **Note**               | `1e1` parses to 10 in many number inputs; it is included to catch a parser that accepts exponent notation as a "whole number". Depends on A5                                 |

---

## TC-CART-013: Changed quantity survives reload and a new session

| Field                  | Value                                                                                                                                                 |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                               |
| **Issue**              | CART-12                                                                                                                                               |
| **Automation Score**   | MEDIUM (47/67.5)                                                                                                                                      |
| **ISTQB Technique**    | Error Guessing — stale state, optimistic UI not persisted                                                                                             |
| **Manual Env**         | Local, Staging                                                                                                                                        |
| **Precondition**       | Shopper signed in; cart holds "Test Product" at quantity 5 (A6); cart page open                                                                       |
| **Steps**              | 1. Set the quantity to `12` and commit <br> 2. Reload the page <br> 3. Sign out, sign in again as the same shopper <br> 4. Open the cart              |
| **Expected**           | After step 2 and after step 4 the field shows `12` and the subtotal is 120.00.                                                                        |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-subtotal`                                                                                                           |
| **Source**             | Added by QA (the ticket does not say where the quantity is stored; a change that only lives in the page is useless to the shopper)                     |
| **Note**               | Step 3 only applies if carts are tied to the account; if carts are guest-only, stop after step 2 and record that.                                     |

---

Rules not applied: the `context-discovery` and `testing-guidelines` rules were not in context and no `qa-rules` skill is installed, so the cases were written from the ticket and the assumptions above rather than from the codebase (the workspace holds no cart code to derive from).
