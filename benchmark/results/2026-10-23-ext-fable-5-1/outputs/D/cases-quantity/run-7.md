---
feature: Cart — Change item quantity
feature_code: CART
tc_count: 12
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
| **Project**      | Shop web app (project name not provided)                     |
| **Author**       | Senior QA Analyst (name not provided)                        |
| **Date Created** | 2026-10-23                                                   |
| **Last Updated** | 2026-10-23                                                   |
| **Methodology**  | ISTQB CTFL v4.0 — EP, BVA (two-value), Decision Table, Error Guessing |

## Context and assumptions

The working directory holds no source code, so no `Precondition` or `Expected` below could be verified against an implementation. Every case rests on the story text plus these stated assumptions:

- **A1 — Commit point.** The quantity field is a numeric input on the cart page. A new value is applied when the field loses focus or the shopper presses Enter. If the real UI has an explicit **Update** button, replace "press Enter" with that click in every Steps row.
- **A2 — Confirmation dialog.** The "Remove this item?" prompt is a modal with a confirm action (assumed label **Remove**) and a dismiss action (assumed label **Cancel**). Closing the dialog any other way (ESC, backdrop click) counts as not confirming.
- **A3 — Rejected input.** For input the field "accepts" per AC-1 the inverse is assumed: a value that is not a whole number, is negative, or is empty is rejected and the previous quantity is kept. The story gives no message for these, so no message text is asserted; the only asserted outcome is that the previous quantity remains.
- **A4 — Totals and persistence.** Line total and cart subtotal recalculate on a successful change, and the change survives a page reload. The story does not say this; the cases that check it are marked "Added by QA".
- **A5 — Tracker.** `CART-12` matches a Linear or Jira key. No base URL was given, so the ID is used as plain text.
- **A6 — Starting state.** Each case starts with one item in the cart at quantity 5 unless the Precondition says otherwise.

Rules not applied: `context-discovery` and `testing-guidelines` were not loaded in this session and no `qa-rules` skill is installed; their intent was followed from the instructions in this command (grounding flagged as assumptions above; four-category tagging applied).

Release gate: cases tagged `@gate` are the minimum set to answer "do the three ACs work, and did the basic cart path break?". The rest stay in the document for the full run.

---

## TC-CART-001: Change quantity to a valid value and see the cart update

| Field                  | Value                                                                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                   |
| **Issue**              | CART-12                                                                                                                                   |
| **Automation Score**   | HIGH (64/67.5)                                                                                                                            |
| **ISTQB Technique**    | EP — valid partition (whole number inside 1–20; representative value 7)                                                                   |
| **Manual Env**         | Local, Staging                                                                                                                            |
| **Precondition**       | Shopper is on the cart page with one item at quantity 5 (A6). Item unit price is known (for example 10.00).                               |
| **Steps**              | 1. Clear the quantity field for the item <br> 2. Type `7` <br> 3. Press Enter (A1)                                                        |
| **Expected**           | Quantity field shows `7`. No dialog and no error message appear. Line total shows 7 × unit price (70.00 in the example). Cart subtotal updates to match (A4). |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`, `cart-subtotal`                                                                            |
| **Source**             | AC-1                                                                                                                                      |
| **Note**               | Totals assertion depends on A4; if the product owner confirms totals are out of scope, drop that sentence from Expected.                   |

---

## TC-CART-002: Change quantity to the minimum value 1

| Field                  | Value                                                                                                     |
| ---------------------- | --------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                   |
| **Issue**              | CART-12                                                                                                   |
| **Automation Score**   | HIGH (62/67.5)                                                                                            |
| **ISTQB Technique**    | BVA — two-value, lower boundary (min = 1)                                                                 |
| **Manual Env**         | Local, Staging                                                                                            |
| **Precondition**       | Shopper is on the cart page with one item at quantity 5 (A6).                                             |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `1` <br> 3. Press Enter (A1)                                     |
| **Expected**           | Quantity field shows `1`. No "Remove this item?" dialog appears. Item remains in the cart. Line total equals 1 × unit price. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`, `remove-item-dialog`                                       |
| **Source**             | AC-1                                                                                                      |
| **Note**               | Guards against an off-by-one where 1 is treated like 0 and triggers the removal prompt.                   |

---

## TC-CART-003: Change quantity to the maximum value 20

| Field                  | Value                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate @gate`                                                              |
| **Issue**              | CART-12                                                                                                    |
| **Automation Score**   | HIGH (62/67.5)                                                                                             |
| **ISTQB Technique**    | BVA — two-value, upper boundary (max = 20)                                                                 |
| **Manual Env**         | Local, Staging                                                                                             |
| **Precondition**       | Shopper is on the cart page with one item at quantity 5 (A6).                                              |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `20` <br> 3. Press Enter (A1)                                     |
| **Expected**           | Quantity field shows `20`. The message "You can buy at most 20 of this item." does NOT appear. Line total equals 20 × unit price. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`, `qty-max-error`                                             |
| **Source**             | AC-1, AC-3                                                                                                 |
| **Note**               | Guards against an off-by-one where 20 is rejected as "above 20".                                           |

---

## TC-CART-004: Quantity 21 is rejected with the maximum message and the previous quantity is kept

| Field                  | Value                                                                                                                                          |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                        |
| **Issue**              | CART-12                                                                                                                                        |
| **Automation Score**   | HIGH (62/67.5)                                                                                                                                 |
| **ISTQB Technique**    | BVA — two-value, max+1 (21)                                                                                                                    |
| **Manual Env**         | Local, Staging                                                                                                                                 |
| **Precondition**       | Shopper is on the cart page with one item at quantity 5 (A6).                                                                                  |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `21` <br> 3. Press Enter (A1) <br> 4. Reload the page                                                 |
| **Expected**           | After step 3: the message "You can buy at most 20 of this item." is shown next to the item and the quantity field shows `5`. Line total and subtotal are unchanged. After step 4: the quantity is still `5`, proving the rejected value was never saved. |
| **data-testid needed** | `cart-item-qty-input`, `qty-max-error`, `cart-item-line-total`                                                                                 |
| **Source**             | AC-3                                                                                                                                           |
| **Note**               | Quote the message exactly, including the final period.                                                                                         |

---

## TC-CART-005: A quantity far above 20 is rejected the same way as 21

| Field                  | Value                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                |
| **Issue**              | CART-12                                                                                                                |
| **Automation Score**   | MEDIUM (51/67.5)                                                                                                       |
| **ISTQB Technique**    | EP — invalid partition (above 20; representative value 999)                                                            |
| **Manual Env**         | Local, Staging                                                                                                         |
| **Precondition**       | Shopper is on the cart page with one item at quantity 5 (A6).                                                          |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `999` <br> 3. Press Enter (A1)                                                |
| **Expected**           | The message "You can buy at most 20 of this item." is shown. Quantity field shows `5`. Line total and subtotal are unchanged. |
| **data-testid needed** | `cart-item-qty-input`, `qty-max-error`                                                                                 |
| **Source**             | AC-3                                                                                                                   |
| **Note**               | Separate from TC-CART-004 to catch a check written as `== 21` instead of `> 20`.                                        |

---

## TC-CART-006: Quantity 0 asks for confirmation and removes the item when confirmed

| Field                  | Value                                                                                                                                                                  |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                                                |
| **Issue**              | CART-12                                                                                                                                                                |
| **Issue**              | CART-12                                                                                                                                                                |
| **Automation Score**   | HIGH (60/67.5)                                                                                                                                                         |
| **ISTQB Technique**    | Decision Table — column: quantity = 0 AND shopper confirms → item removed. Also BVA min−1 (0).                                                                          |
| **Manual Env**         | Local, Staging                                                                                                                                                         |
| **Precondition**       | Shopper is on the cart page with two distinct items, item A at quantity 5 and item B at quantity 1.                                                                     |
| **Steps**              | 1. Clear item A's quantity field <br> 2. Type `0` <br> 3. Press Enter (A1) <br> 4. In the dialog, click **Remove** (A2) <br> 5. Reload the page                          |
| **Expected**           | After step 3: a dialog with the text "Remove this item?" appears; item A is still listed. After step 4: dialog closes, item A is gone, item B is unchanged at quantity 1, subtotal equals item B's line total. After step 5: item A is still absent. |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`, `remove-item-confirm`, `cart-item-row`, `cart-subtotal`                                                                   |
| **Source**             | AC-2                                                                                                                                                                   |
| **Note**               | Two items in the precondition prove the removal targets the right row. Confirm button label is assumed (A2).                                                            |

---

## TC-CART-007: Cancelling the "Remove this item?" dialog keeps the item at its previous quantity

| Field                  | Value                                                                                                                                         |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @cart @candidate @gate`                                                                                                       |
| **Issue**              | CART-12                                                                                                                                       |
| **Automation Score**   | HIGH (60/67.5)                                                                                                                                |
| **ISTQB Technique**    | Decision Table — column: quantity = 0 AND shopper does not confirm → item kept                                                                 |
| **Manual Env**         | Local, Staging                                                                                                                                |
| **Precondition**       | Shopper is on the cart page with one item at quantity 5 (A6).                                                                                 |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `0` <br> 3. Press Enter (A1) <br> 4. In the dialog, click **Cancel** (A2) <br> 5. Reload the page     |
| **Expected**           | After step 4: dialog closes, item is still in the cart, quantity field shows `5`, line total and subtotal are unchanged. After step 5: quantity is still `5`. |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`, `remove-item-cancel`, `cart-item-row`                                                            |
| **Source**             | AC-2                                                                                                                                          |
| **Note**               | "Only when the shopper confirms" is the clause under test. The field must not stay at `0` after cancel.                                        |

---

## TC-CART-008: Dismissing the dialog with ESC or a backdrop click does not remove the item

| Field                  | Value                                                                                                                                   |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                                 |
| **Issue**              | CART-12                                                                                                                                 |
| **Automation Score**   | MEDIUM (50/67.5)                                                                                                                        |
| **ISTQB Technique**    | Error Guessing — non-button dismissal paths treated as implicit confirmation                                                             |
| **Manual Env**         | Local, Staging                                                                                                                          |
| **Precondition**       | Shopper is on the cart page with one item at quantity 5 (A6).                                                                           |
| **Steps**              | 1. Clear the quantity field, type `0`, press Enter <br> 2. Press ESC <br> 3. Observe the cart <br> 4. Repeat step 1 <br> 5. Click outside the dialog on the page backdrop <br> 6. Observe the cart |
| **Expected**           | After steps 2 and 5 the dialog is closed (or still open if the modal is non-dismissable; either is acceptable). In both cases the item remains in the cart and its quantity field shows `5`. |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`, `cart-item-row`                                                                            |
| **Source**             | Added by QA (AC-2 says removal happens only on confirmation; the ticket is silent on ESC and backdrop dismissal)                         |
| **Note**               | Depends on A2. If the dialog is not a modal, adapt steps 2 and 5 to whatever dismissal path exists.                                      |

---

## TC-CART-009: A decimal quantity is rejected and the previous quantity is kept

| Field                  | Value                                                                                                                     |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                                   |
| **Issue**              | CART-12                                                                                                                   |
| **Automation Score**   | HIGH (55/67.5)                                                                                                            |
| **ISTQB Technique**    | EP — invalid partition (not a whole number; representative value 2.5)                                                      |
| **Manual Env**         | Local, Staging                                                                                                            |
| **Precondition**       | Shopper is on the cart page with one item at quantity 5 (A6).                                                             |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `2.5` <br> 3. Press Enter (A1) <br> 4. Reload the page                            |
| **Expected**           | The value is not applied: after step 3 the quantity field shows `5` (or the input refuses the `.` character so `25` is never formed and `2` is not silently saved). No "Remove this item?" dialog and no "at most 20" message appear. After step 4 the quantity is still `5`. |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`, `qty-max-error`                                                              |
| **Source**             | Added by QA (AC-1 says "whole numbers"; the ticket does not say what happens to a decimal)                                 |
| **Note**               | Depends on A3. Watch for silent rounding: `2.5` saved as `2` or `3` is a failure. If the field strips the dot and forms `25`, that must surface the AC-3 message, not a silent save. |

---

## TC-CART-010: A negative quantity is rejected and the previous quantity is kept

| Field                  | Value                                                                                                                 |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @cart @candidate`                                                                               |
| **Issue**              | CART-12                                                                                                               |
| **Automation Score**   | HIGH (55/67.5)                                                                                                        |
| **ISTQB Technique**    | EP — invalid partition (below 0; representative value −1)                                                              |
| **Manual Env**         | Local, Staging                                                                                                        |
| **Precondition**       | Shopper is on the cart page with one item at quantity 5 (A6).                                                         |
| **Steps**              | 1. Clear the quantity field <br> 2. Type `-1` <br> 3. Press Enter (A1)                                                |
| **Expected**           | Quantity field shows `5`. No "Remove this item?" dialog appears (a negative value must not be treated as 0). Item remains in the cart. Line total and subtotal are unchanged. |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`, `cart-item-row`                                                          |
| **Source**             | Added by QA (the ticket is silent on negative values)                                                                  |
| **Note**               | Depends on A3. A check written as `qty <= 0 → prompt removal` would fail this case; that is the bug being hunted.       |

---

## TC-CART-011: An empty or non-numeric quantity is rejected and the previous quantity is kept

| Field                  | Value                                                                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                            |
| **Issue**              | CART-12                                                                                                                                            |
| **Automation Score**   | MEDIUM (49/67.5)                                                                                                                                   |
| **ISTQB Technique**    | EP — invalid partitions (empty string; non-numeric text `abc`)                                                                                     |
| **Manual Env**         | Local, Staging                                                                                                                                     |
| **Precondition**       | Shopper is on the cart page with one item at quantity 5 (A6).                                                                                      |
| **Steps**              | 1. Clear the quantity field, leave it empty, press Enter (A1) <br> 2. Observe <br> 3. Clear the field, type `abc`, press Enter <br> 4. Observe       |
| **Expected**           | After steps 1 and 3: the quantity field shows `5`, no removal dialog appears, item remains in the cart, totals are unchanged. A numeric input that blocks letters entirely is an acceptable way to pass step 3. |
| **data-testid needed** | `cart-item-qty-input`, `remove-item-dialog`                                                                                                        |
| **Source**             | Added by QA (the ticket is silent on empty and non-numeric input)                                                                                  |
| **Note**               | Depends on A3. An empty field coerced to `0` that then prompts removal is a failure.                                                                |

---

## TC-CART-012: Two quick successive changes end with the last value, not an earlier one

| Field                  | Value                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Tags**               | `@regression @p2 @e2e @cart @candidate`                                                                                                                |
| **Issue**              | CART-12                                                                                                                                                |
| **Automation Score**   | MEDIUM (41/67.5)                                                                                                                                       |
| **ISTQB Technique**    | Error Guessing — out-of-order responses / stale state after rapid edits                                                                                 |
| **Manual Env**         | Local, Staging (throttle network to "Slow 3G" in DevTools)                                                                                             |
| **Precondition**       | Shopper is on the cart page with one item at quantity 5 (A6). Network throttled so a quantity update takes at least 1 s.                                 |
| **Steps**              | 1. Clear the field, type `3`, press Enter <br> 2. Immediately (within 500 ms) clear the field, type `8`, press Enter <br> 3. Wait for all requests to finish <br> 4. Reload the page |
| **Expected**           | After step 3: quantity field shows `8`, line total equals 8 × unit price, subtotal matches. After step 4: quantity is still `8`. No error message and no removal dialog appear at any point. |
| **data-testid needed** | `cart-item-qty-input`, `cart-item-line-total`, `cart-subtotal`                                                                                         |
| **Source**             | Added by QA (the ticket is silent on rapid repeated edits; a slow first response overwriting a fast second one is a common cart defect)                 |
| **Note**               | In Playwright, use route delays rather than DevTools throttling to keep the case deterministic. Score is MEDIUM because of the timing setup.            |
