---
feature: Cart — Change item quantity
feature_code: CART
tc_count: 18
tracker_issues: [CART-12]
risk_level: MEDIUM
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-23
---

# Test Cases — Cart — Change item quantity

| Field            | Value                                                        |
| ---------------- | ------------------------------------------------------------ |
| **Project**      | N/A — not stated; assumed a web storefront with a cart page  |
| **Author**       | Bem-te-vi — Senior QA Analyst                                |
| **Date Created** | 2026-10-23                                                   |
| **Last Updated** | 2026-10-23                                                   |
| **Methodology**  | ISTQB CTFL v4.0 — EP, BVA (three-value), Decision Table, State Transition, Error Guessing |

## Assumptions and unverified items

The working directory holds no source code, so no `Precondition` or `Expected` below is grounded in an implementation. Every case rests on the story text and the assumptions here; verify them against the code before the first run.

- **A1 — Commit of a value.** The quantity field is a text/number input; a value is committed by pressing Enter or leaving the field (blur). If the product uses an **Update** button or stepper buttons instead, replace the "commit" step in every case.
- **A2 — Cancel restores the previous quantity.** AC-2 says the item is removed only when the shopper confirms. On cancel, the field is assumed to show the quantity it had before `0` was typed.
- **A3 — Dismissing the dialog equals cancel.** ESC, clicking outside, or the close icon are treated as "not confirmed".
- **A4 — Limit of 20 is per line item** and independent of stock. Stock limits are out of scope.
- **A5 — Non-integer, non-numeric, negative and empty input** are outside the ACs. Assumed outcome: the value is rejected and the previous quantity is kept; the exact message is not asserted.
- **A6 — Line subtotal and cart total** recalculate after an accepted change; the story does not state this.
- **A7 — Tracker.** `CART-12` has no base URL, so it is written as plain text. Environments assumed: Local, Staging.
- **Rules not applied.** The `context-discovery` and `testing-guidelines` rules were not in context and no `qa-rules` skill is installed; the `qa-reference` worked examples were not read. The format in this skill was followed as written.

---

## TC-CART-001: Change quantity to a valid mid-range value

| Field                  | Value                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                   |
| **Issue**              | CART-12                                                                                                                                                    |
| **Automation Score**   | HIGH (60/67.5)                                                                                                                                             |
| **ISTQB Technique**    | EP — valid partition (whole number inside 1–20)                                                                                                            |
| **Manual Env**         | Local, Staging                                                                                                                                             |
| **Precondition**       | Shopper is on the cart page with one item at quantity 1                                                                                                    |
| **Steps**              | 1. Clear the quantity field of the item <br> 2. Type `10` <br> 3. Commit the value (Enter or blur, per A1)                                                 |
| **Expected**           | Field shows `10`. No error message or dialog appears. The item stays in the cart.                                                                          |
| **data-testid needed** | `cart-item-row`, `cart-item-qty-input`                                                                                                                     |
| **Source**             | AC-1                                                                                                                                                       |
| **Note**               | N/A — no caveats                                                                                                                                           |

---

## TC-CART-002: Accept the minimum quantity 1

| Field                  | Value                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                 |
| **Issue**              | CART-12                                                                                                 |
| **Automation Score**   | HIGH (56/67.5)                                                                                          |
| **ISTQB Technique**    | BVA — three-value, min (1)                                                                              |
| **Manual Env**         | Local, Staging                                                                                          |
| **Precondition**       | Shopper is on the cart page with one item at quantity 5                                                 |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `1` <br> 3. Commit the value                                   |
| **Expected**           | Field shows `1`. No error message or dialog appears. The item stays in the cart.                        |
| **data-testid needed** | `cart-item-row`, `cart-item-qty-input`                                                                  |
| **Source**             | AC-1                                                                                                    |
| **Note**               | Pairs with TC-CART-008 (min-1 = 0) and TC-CART-003 (min+1).                                             |

---

## TC-CART-003: Accept quantity 2 (min+1)

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                 |
| **Issue**              | CART-12                                                                                 |
| **Automation Score**   | MEDIUM (50/67.5)                                                                        |
| **ISTQB Technique**    | BVA — three-value, min+1 (2)                                                            |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | Shopper is on the cart page with one item at quantity 1                                 |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `2` <br> 3. Commit the value                   |
| **Expected**           | Field shows `2`. No error message or dialog appears.                                    |
| **data-testid needed** | `cart-item-qty-input`                                                                   |
| **Source**             | AC-1                                                                                    |
| **Note**               | N/A — no caveats                                                                        |

---

## TC-CART-004: Accept quantity 19 (max-1)

| Field                  | Value                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                 |
| **Issue**              | CART-12                                                                                 |
| **Automation Score**   | MEDIUM (50/67.5)                                                                        |
| **ISTQB Technique**    | BVA — three-value, max-1 (19)                                                           |
| **Manual Env**         | Local, Staging                                                                          |
| **Precondition**       | Shopper is on the cart page with one item at quantity 1                                 |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `19` <br> 3. Commit the value                  |
| **Expected**           | Field shows `19`. No error message or dialog appears.                                   |
| **data-testid needed** | `cart-item-qty-input`                                                                   |
| **Source**             | AC-1                                                                                    |
| **Note**               | N/A — no caveats                                                                        |

---

## TC-CART-005: Accept the maximum quantity 20

| Field                  | Value                                                                                                 |
| ---------------------- | ----------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                              |
| **Issue**              | CART-12                                                                                               |
| **Automation Score**   | HIGH (58/67.5)                                                                                        |
| **ISTQB Technique**    | BVA — three-value, max (20)                                                                           |
| **Manual Env**         | Local, Staging                                                                                        |
| **Precondition**       | Shopper is on the cart page with one item at quantity 1                                               |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `20` <br> 3. Commit the value                                |
| **Expected**           | Field shows `20`. The message "You can buy at most 20 of this item." does NOT appear. Item stays.     |
| **data-testid needed** | `cart-item-qty-input`, `qty-error-message`                                                            |
| **Source**             | AC-1, AC-3 (20 is inside the limit, not above it)                                                     |
| **Note**               | Guards against an off-by-one where the limit is implemented as `< 20`.                                |

---

## TC-CART-006: Reject quantity 21 and keep the previous quantity

| Field                  | Value                                                                                                                                         |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                      |
| **Issue**              | CART-12                                                                                                                                       |
| **Automation Score**   | HIGH (60/67.5)                                                                                                                                |
| **ISTQB Technique**    | BVA — three-value, max+1 (21)                                                                                                                 |
| **Manual Env**         | Local, Staging                                                                                                                                |
| **Precondition**       | Shopper is on the cart page with one item at quantity 3                                                                                       |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `21` <br> 3. Commit the value                                                                        |
| **Expected**           | Message "You can buy at most 20 of this item." is shown. Field shows `3`. The item stays in the cart. No "Remove this item?" dialog appears.  |
| **data-testid needed** | `cart-item-qty-input`, `qty-error-message`                                                                                                    |
| **Source**             | AC-3                                                                                                                                          |
| **Note**               | Quote the message exactly, including the final period.                                                                                        |

---

## TC-CART-007: Reject a quantity far above the limit

| Field                  | Value                                                                                                            |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                          |
| **Issue**              | CART-12                                                                                                          |
| **Automation Score**   | MEDIUM (50/67.5)                                                                                                 |
| **ISTQB Technique**    | EP — invalid partition (whole number above 20), representative 999                                               |
| **Manual Env**         | Local, Staging                                                                                                   |
| **Precondition**       | Shopper is on the cart page with one item at quantity 3                                                          |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `999` <br> 3. Commit the value                                          |
| **Expected**           | Message "You can buy at most 20 of this item." is shown. Field shows `3`.                                        |
| **data-testid needed** | `cart-item-qty-input`, `qty-error-message`                                                                       |
| **Source**             | AC-3                                                                                                             |
| **Note**               | Also covers a field that truncates or clamps input instead of rejecting it; clamping to 20 would fail this case. |

---

## TC-CART-008: Set quantity to 0 and confirm removal

| Field                  | Value                                                                                                                                                                   |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                                |
| **Issue**              | CART-12                                                                                                                                                                 |
| **Automation Score**   | HIGH (57/67.5)                                                                                                                                                          |
| **ISTQB Technique**    | Decision Table — column: quantity = 0, shopper confirms → item removed (also BVA min-1)                                                                                 |
| **Manual Env**         | Local, Staging                                                                                                                                                          |
| **Precondition**       | Shopper is on the cart page with two distinct items, A at quantity 2 and B at quantity 1                                                                                |
| **Steps**              | 1. Clear the quantity field of item A <br> 2. Type `0` <br> 3. Commit the value <br> 4. In the dialog, choose the confirm action                                         |
| **Expected**           | After step 3 a dialog asks "Remove this item?". After step 4 item A is no longer in the cart. Item B remains at quantity 1. No error message is shown.                   |
| **data-testid needed** | `cart-item-row`, `cart-item-qty-input`, `remove-item-dialog`, `remove-item-confirm`                                                                                     |
| **Source**             | AC-2                                                                                                                                                                    |
| **Note**               | Second item added by QA to prove removal is scoped to one row.                                                                                                          |

---

## TC-CART-009: Set quantity to 0 and cancel keeps the item

| Field                  | Value                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                               |
| **Issue**              | CART-12                                                                                                                                                |
| **Automation Score**   | HIGH (55/67.5)                                                                                                                                         |
| **ISTQB Technique**    | Decision Table — column: quantity = 0, shopper cancels → item kept                                                                                     |
| **Manual Env**         | Local, Staging                                                                                                                                         |
| **Precondition**       | Shopper is on the cart page with one item at quantity 2                                                                                                |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `0` <br> 3. Commit the value <br> 4. In the "Remove this item?" dialog, choose the cancel action               |
| **Expected**           | Dialog closes. The item is still in the cart. Field shows `2` (per A2). No request to remove the item is sent.                                          |
| **data-testid needed** | `cart-item-row`, `cart-item-qty-input`, `remove-item-dialog`, `remove-item-cancel`                                                                     |
| **Source**             | AC-2                                                                                                                                                   |
| **Note**               | A2: the story does not say which quantity shows after cancel. If the field is left at `0`, record a finding.                                           |

---

## TC-CART-010: Dismiss the removal dialog without choosing

| Field                  | Value                                                                                                                                                          |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                                        |
| **Issue**              | CART-12                                                                                                                                                        |
| **Automation Score**   | MEDIUM (47/67.5)                                                                                                                                               |
| **ISTQB Technique**    | State Transition — Dialog open, event ESC / outside click; expected transition back to item kept                                                               |
| **Manual Env**         | Local, Staging                                                                                                                                                 |
| **Precondition**       | Shopper is on the cart page with one item at quantity 2                                                                                                        |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `0` <br> 3. Commit the value <br> 4. Press ESC <br> 5. Repeat steps 1–3 and click outside the dialog                   |
| **Expected**           | In both runs the dialog closes, the item is still in the cart and the field shows `2`. The item is never removed without an explicit confirm.                   |
| **data-testid needed** | `cart-item-row`, `cart-item-qty-input`, `remove-item-dialog`                                                                                                   |
| **Source**             | Added by QA (AC-2 says "only when the shopper confirms" but does not define dismissal; see A3)                                                                  |
| **Note**               | N/A — no caveats                                                                                                                                               |

---

## TC-CART-011: Reject a decimal quantity

| Field                  | Value                                                                                                                |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                              |
| **Issue**              | CART-12                                                                                                              |
| **Automation Score**   | MEDIUM (51/67.5)                                                                                                     |
| **ISTQB Technique**    | EP — invalid partition (non-whole number), representative 2.5                                                        |
| **Manual Env**         | Local, Staging                                                                                                       |
| **Precondition**       | Shopper is on the cart page with one item at quantity 3                                                              |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `2.5` <br> 3. Commit the value                                              |
| **Expected**           | The value is not accepted: the field shows `3` after commit (or the field refuses the `.` character). No removal dialog appears. |
| **data-testid needed** | `cart-item-qty-input`                                                                                                |
| **Source**             | Added by QA (AC-1 says "whole numbers" but no AC states what happens to a decimal; see A5)                            |
| **Note**               | Rounding 2.5 to 2 or 3 silently would be a finding: the shopper did not choose that amount.                          |

---

## TC-CART-012: Reject non-numeric input

| Field                  | Value                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                  |
| **Issue**              | CART-12                                                                                                                  |
| **Automation Score**   | MEDIUM (51/67.5)                                                                                                         |
| **ISTQB Technique**    | EP — invalid partition (non-numeric text), representatives `abc` and `1e1`                                               |
| **Manual Env**         | Local, Staging                                                                                                           |
| **Precondition**       | Shopper is on the cart page with one item at quantity 3                                                                  |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `abc` <br> 3. Commit the value <br> 4. Repeat with `1e1`                         |
| **Expected**           | In both runs the field shows `3` after commit (or refuses the characters). No removal dialog, no crash, no console error. |
| **data-testid needed** | `cart-item-qty-input`                                                                                                    |
| **Source**             | Added by QA (the ticket is silent on non-numeric input; see A5)                                                          |
| **Note**               | `1e1` catches a `type="number"` input that parses scientific notation to 10.                                             |

---

## TC-CART-013: Reject a negative quantity

| Field                  | Value                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                  |
| **Issue**              | CART-12                                                                                                                  |
| **Automation Score**   | MEDIUM (51/67.5)                                                                                                         |
| **ISTQB Technique**    | EP — invalid partition (negative whole number), representative -1                                                        |
| **Manual Env**         | Local, Staging                                                                                                           |
| **Precondition**       | Shopper is on the cart page with one item at quantity 3                                                                  |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `-1` <br> 3. Commit the value                                                   |
| **Expected**           | Field shows `3` after commit (or refuses `-`). The "Remove this item?" dialog does NOT appear. The item stays.            |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`                                                                              |
| **Source**             | Added by QA (the ticket is silent on negative numbers; see A5)                                                           |
| **Note**               | A `<= 0` check would wrongly route -1 into the AC-2 removal flow.                                                        |

---

## TC-CART-014: Reject an empty quantity

| Field                  | Value                                                                                                                |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                              |
| **Issue**              | CART-12                                                                                                              |
| **Automation Score**   | MEDIUM (51/67.5)                                                                                                     |
| **ISTQB Technique**    | EP — invalid partition (empty value)                                                                                 |
| **Manual Env**         | Local, Staging                                                                                                       |
| **Precondition**       | Shopper is on the cart page with one item at quantity 3                                                              |
| **Steps**              | 1. Clear the quantity field <br> 2. Commit with the field empty                                                      |
| **Expected**           | Field shows `3` after commit. The "Remove this item?" dialog does NOT appear. The item stays.                         |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`                                                                          |
| **Source**             | Added by QA (the ticket is silent on an empty field; see A5)                                                         |
| **Note**               | An empty string parsed as 0 would wrongly trigger the removal dialog.                                                |

---

## TC-CART-015: Previous quantity kept after a rejected value is the last accepted one

| Field                  | Value                                                                                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                                 |
| **Issue**              | CART-12                                                                                                                                                 |
| **Automation Score**   | MEDIUM (48/67.5)                                                                                                                                        |
| **ISTQB Technique**    | Error Guessing — stale state: "previous quantity" restored from the original load instead of the last accepted change                                   |
| **Manual Env**         | Local, Staging                                                                                                                                          |
| **Precondition**       | Shopper is on the cart page with one item at quantity 5                                                                                                 |
| **Steps**              | 1. Change the quantity to `12` and commit <br> 2. Change the quantity to `25` and commit <br> 3. Change the quantity to `21` and commit                   |
| **Expected**           | After step 1 the field shows `12`. After steps 2 and 3 the message "You can buy at most 20 of this item." is shown and the field shows `12`, not `5`.   |
| **data-testid needed** | `cart-item-qty-input`, `qty-error-message`                                                                                                              |
| **Source**             | AC-3                                                                                                                                                    |
| **Note**               | Also checks the message appears again on a second rejection and does not stay stuck from the first.                                                     |

---

## TC-CART-016: Removing the only item leaves an empty cart

| Field                  | Value                                                                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                |
| **Issue**              | CART-12                                                                                                                                |
| **Automation Score**   | HIGH (53/67.5)                                                                                                                         |
| **ISTQB Technique**    | State Transition — Cart with one item → (qty 0, confirm) → Empty cart                                                                 |
| **Manual Env**         | Local, Staging                                                                                                                         |
| **Precondition**       | Shopper is on the cart page with exactly one item at quantity 1                                                                        |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `0` <br> 3. Commit the value <br> 4. Confirm in the "Remove this item?" dialog                  |
| **Expected**           | The item row disappears. The cart's empty state is shown. The cart total is 0 (or hidden). Checkout cannot be started from an empty cart. |
| **data-testid needed** | `cart-item-row`, `remove-item-confirm`, `cart-empty-state`, `cart-total`                                                               |
| **Source**             | Added by QA (AC-2 covers removal but no AC states the cart's state after the last item goes)                                            |
| **Note**               | Empty-state copy and checkout behaviour are assumed; adjust once the page is known.                                                    |

---

## TC-CART-017: Line subtotal and cart total update after an accepted change

| Field                  | Value                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                                |
| **Issue**              | CART-12                                                                                                                                                |
| **Automation Score**   | HIGH (56/67.5)                                                                                                                                         |
| **ISTQB Technique**    | EP — valid partition, with the derived outputs (subtotal, total) asserted                                                                              |
| **Manual Env**         | Local, Staging                                                                                                                                         |
| **Precondition**       | Shopper is on the cart page with item A (unit price P1) at quantity 1 and item B (unit price P2) at quantity 1                                          |
| **Steps**              | 1. Change the quantity of item A to `4` and commit <br> 2. Change the quantity of item A to `21` and commit                                               |
| **Expected**           | After step 1: item A subtotal = 4 × P1, cart total = 4 × P1 + P2. After step 2: the limit message shows and subtotal and total are unchanged from step 1. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-subtotal`, `cart-total`, `qty-error-message`                                                                         |
| **Source**             | Added by QA (the story goal "buy the amount I need" implies the price follows the quantity; no AC states it; see A6)                                    |
| **Note**               | Tax and shipping rules are out of scope; compare only line subtotal and item total.                                                                    |

---

## TC-CART-018: Changed quantity persists after reload

| Field                  | Value                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                  |
| **Issue**              | CART-12                                                                                                                  |
| **Automation Score**   | MEDIUM (44/67.5)                                                                                                         |
| **ISTQB Technique**    | Error Guessing — change applied only in UI state and never saved                                                         |
| **Manual Env**         | Local, Staging                                                                                                           |
| **Precondition**       | Shopper is on the cart page with one item at quantity 1                                                                  |
| **Steps**              | 1. Change the quantity to `7` and commit <br> 2. Wait for any pending request to finish <br> 3. Reload the page             |
| **Expected**           | After reload the item shows quantity `7`.                                                                                |
| **data-testid needed** | `cart-item-qty-input`                                                                                                    |
| **Source**             | Added by QA (the ticket is silent on persistence of the change)                                                          |
| **Note**               | Whether the cart is server-side or local storage is unknown; the case holds either way.                                   |
