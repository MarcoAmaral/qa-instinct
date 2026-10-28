---
feature: Shipping fee at checkout
feature_code: SHIP
tc_count: 14
tracker_issues: [SHIP-9]
risk_level: HIGH
runbook: N/A — no runbook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-24
---

# Test Cases — Shipping fee at checkout

| Field            | Value                                                    |
| ---------------- | -------------------------------------------------------- |
| **Project**      | SHIP (checkout)                                          |
| **Author**       | Marco — Senior QA Analyst                                |
| **Date Created** | 2026-10-24                                               |
| **Last Updated** | 2026-10-24                                               |
| **Methodology**  | ISTQB CTFL v4.0 — Decision Table, BVA, EP, Error Guessing |

## Context and assumptions

The working directory contains no source code, so `Precondition` and `Expected` could not be grounded in an implementation. Every case below rests on the story text plus the assumptions listed here; each assumption is flagged again in the **Note** row of the case it affects.

- **A1 — Subtotal definition.** "Order subtotal" is the sum of item prices after item-level discounts and before tax, promo codes and shipping. The threshold is inclusive: a subtotal of exactly $50.00 earns free standard shipping.
- **A2 — Membership.** "Member" is a flag on the signed-in account. A guest or a signed-in non-member is a non-member.
- **A3 — Two shipping options only.** Checkout offers Standard and Express. Standard is pre-selected.
- **A4 — Display.** The fee appears in an order summary line labelled "Shipping" and is included in the order total. A free fee is shown as "Free" (not "$0.00"). Prices are USD with two decimals.
- **A5 — Live recalculation.** Changing the cart, the shipping option or the sign-in state on the checkout page recalculates the fee without a page reload.
- **A6 — Fee rules are server-side.** The server computes the fee and the client displays it; the client cannot submit its own fee.
- **A7 — Tracker.** SHIP-9 is used as a plain-text ID. No base URL was given, so no link is formed.

Decision table used for the rule cases (AC-1 to AC-3):

| Rule | Member? | Standard subtotal ≥ $50.00? | Option   | Fee    | Case        |
| ---- | ------- | --------------------------- | -------- | ------ | ----------- |
| R1   | No      | No                          | Standard | $5.99  | TC-SHIP-001 |
| R2   | No      | Yes                         | Standard | Free   | TC-SHIP-002 |
| R3   | Yes     | No                          | Standard | Free   | TC-SHIP-003 |
| R4   | Yes     | Yes                         | Standard | Free   | TC-SHIP-004 |
| R5   | No      | (irrelevant)                | Express  | $12.99 | TC-SHIP-005 |
| R6   | Yes     | (irrelevant)                | Express  | $7.99  | TC-SHIP-006 |

Release gate: cases tagged `@gate` (TC-SHIP-001, 002, 003, 005, 006, 008).

---

## TC-SHIP-001: Non-member below threshold pays $5.99 for standard shipping

| Field                  | Value                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                                   |
| **Issue**              | SHIP-9                                                                                                                                                     |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                                             |
| **ISTQB Technique**    | Decision Table — R1 (non-member, subtotal < $50.00, Standard)                                                                                              |
| **Manual Env**         | Local, Staging                                                                                                                                             |
| **Precondition**       | Guest session (not signed in). Cart contains one item priced $30.00. Standard shipping is the selected option.                                             |
| **Steps**              | 1. Open the checkout page <br> 2. Read the order summary "Shipping" line and the order total                                                               |
| **Expected**           | Shipping line shows `$5.99`. Order total equals subtotal + tax + $5.99.                                                                                     |
| **data-testid needed** | `checkout-shipping-fee`, `checkout-subtotal`, `checkout-order-total`, `shipping-option-standard`                                                           |
| **Source**             | AC-1                                                                                                                                                       |
| **Note**               | Relies on A1, A3, A4. Guest is used as the non-member representative (A2); TC-SHIP-010 covers a signed-in non-member.                                       |

---

## TC-SHIP-002: Non-member at or above threshold gets free standard shipping

| Field                  | Value                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                                   |
| **Issue**              | SHIP-9                                                                                                                                                     |
| **Automation Score**   | HIGH (61/67.5)                                                                                                                                             |
| **ISTQB Technique**    | Decision Table — R2 (non-member, subtotal ≥ $50.00, Standard)                                                                                              |
| **Manual Env**         | Local, Staging                                                                                                                                             |
| **Precondition**       | Guest session. Cart contains items totalling $80.00. Standard shipping is selected.                                                                        |
| **Steps**              | 1. Open the checkout page <br> 2. Read the "Shipping" line and the order total                                                                              |
| **Expected**           | Shipping line shows `Free`. Order total equals subtotal + tax with no shipping added.                                                                       |
| **data-testid needed** | `checkout-shipping-fee`, `checkout-order-total`                                                                                                            |
| **Source**             | AC-1                                                                                                                                                       |
| **Note**               | Relies on A4 for the "Free" label. If the implementation shows `$0.00`, record a correction here rather than failing the case.                              |

---

## TC-SHIP-003: Member below threshold gets free standard shipping

| Field                  | Value                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                                   |
| **Issue**              | SHIP-9                                                                                                                                                     |
| **Automation Score**   | HIGH (58/67.5)                                                                                                                                             |
| **ISTQB Technique**    | Decision Table — R3 (member, subtotal < $50.00, Standard)                                                                                                  |
| **Manual Env**         | Local, Staging                                                                                                                                             |
| **Precondition**       | Signed in as an account with the member flag set. Cart contains one item priced $10.00. Standard shipping is selected.                                    |
| **Steps**              | 1. Open the checkout page <br> 2. Read the "Shipping" line and the order total                                                                              |
| **Expected**           | Shipping line shows `Free`. No shipping amount is added to the order total.                                                                                 |
| **data-testid needed** | `checkout-shipping-fee`, `checkout-order-total`                                                                                                            |
| **Source**             | AC-2                                                                                                                                                       |
| **Note**               | Relies on A2 (membership is an account flag). The member fixture account must exist in each manual environment.                                            |

---

## TC-SHIP-004: Member at or above threshold gets free standard shipping

| Field                  | Value                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                    |
| **Issue**              | SHIP-9                                                                                                                                                     |
| **Automation Score**   | HIGH (55/67.5)                                                                                                                                             |
| **ISTQB Technique**    | Decision Table — R4 (member, subtotal ≥ $50.00, Standard)                                                                                                  |
| **Manual Env**         | Local, Staging                                                                                                                                             |
| **Precondition**       | Signed in as a member. Cart contains items totalling $120.00. Standard shipping is selected.                                                               |
| **Steps**              | 1. Open the checkout page <br> 2. Read the "Shipping" line                                                                                                  |
| **Expected**           | Shipping line shows `Free`.                                                                                                                                 |
| **data-testid needed** | `checkout-shipping-fee`                                                                                                                                     |
| **Source**             | AC-1, AC-2                                                                                                                                                 |
| **Note**               | Both rules grant free shipping here; the case guards against one rule overriding the other with a charge.                                                  |

---

## TC-SHIP-005: Non-member pays $12.99 for express shipping regardless of subtotal

| Field                  | Value                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                                   |
| **Issue**              | SHIP-9                                                                                                                                                     |
| **Automation Score**   | HIGH (59/67.5)                                                                                                                                             |
| **ISTQB Technique**    | Decision Table — R5 (non-member, Express); EP on subtotal (one value below, one above $50.00)                                                              |
| **Manual Env**         | Local, Staging                                                                                                                                             |
| **Precondition**       | Guest session. Cart contains one item priced $30.00. Checkout page open with Standard selected.                                                           |
| **Steps**              | 1. Select **Express** shipping <br> 2. Read the "Shipping" line and order total <br> 3. Return to the cart and add an item so the subtotal is $80.00 <br> 4. Return to checkout with Express still selected and read the "Shipping" line |
| **Expected**           | After step 2: Shipping line shows `$12.99` and the total includes it. After step 4: Shipping line still shows `$12.99`; the $50.00 threshold does not apply to Express. |
| **data-testid needed** | `shipping-option-express`, `checkout-shipping-fee`, `checkout-order-total`                                                                                  |
| **Source**             | AC-3                                                                                                                                                       |
| **Note**               | Relies on A3 (Express is selectable) and A5 (selection persists across cart edits). If selection resets, re-select Express at step 4 and log it as a finding. |

---

## TC-SHIP-006: Member pays $7.99 for express shipping regardless of subtotal

| Field                  | Value                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @ship @candidate @gate`                                                                                                                   |
| **Issue**              | SHIP-9                                                                                                                                                     |
| **Automation Score**   | HIGH (57/67.5)                                                                                                                                             |
| **ISTQB Technique**    | Decision Table — R6 (member, Express); EP on subtotal (one value below, one above $50.00)                                                                  |
| **Manual Env**         | Local, Staging                                                                                                                                             |
| **Precondition**       | Signed in as a member. Cart contains one item priced $30.00. Checkout page open with Standard selected.                                                   |
| **Steps**              | 1. Select **Express** shipping <br> 2. Read the "Shipping" line and order total <br> 3. Return to the cart and add an item so the subtotal is $80.00 <br> 4. Return to checkout with Express still selected and read the "Shipping" line |
| **Expected**           | After step 2: Shipping line shows `$7.99`, not `$12.99` and not `Free`. After step 4: Shipping line still shows `$7.99`.                                     |
| **data-testid needed** | `shipping-option-express`, `checkout-shipping-fee`, `checkout-order-total`                                                                                  |
| **Source**             | AC-3                                                                                                                                                       |
| **Note**               | Guards the common defect of the member free-shipping rule (AC-2) leaking into Express.                                                                     |

---

## TC-SHIP-007: Standard fee at the $50.00 boundary for a non-member

| Field                  | Value                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @api @ship @candidate`                                                                                                                    |
| **Issue**              | SHIP-9                                                                                                                                                     |
| **Automation Score**   | HIGH (63/67.5)                                                                                                                                             |
| **ISTQB Technique**    | BVA — three-value on the $50.00 threshold: $49.98, $49.99, $50.00, $50.01                                                                                  |
| **Manual Env**         | Local, Staging                                                                                                                                             |
| **Precondition**       | Guest session. Catalogue has items (or a price-override fixture) that allow exact subtotals of $49.98, $49.99, $50.00 and $50.01. Standard shipping selected. |
| **Steps**              | 1. Set the cart subtotal to $49.98 and open checkout; read the "Shipping" line <br> 2. Repeat with $49.99 <br> 3. Repeat with $50.00 <br> 4. Repeat with $50.01 |
| **Expected**           | $49.98 → `$5.99`. $49.99 → `$5.99`. $50.00 → `Free`. $50.01 → `Free`.                                                                                        |
| **data-testid needed** | `checkout-shipping-fee`                                                                                                                                     |
| **Source**             | AC-1                                                                                                                                                       |
| **Note**               | Relies on A1 (inclusive threshold, "or more"). Tagged `@api` because the cleanest execution is against the fee calculation endpoint with exact subtotals; run the $49.99 and $50.00 values through the UI as well. |

---

## TC-SHIP-008: Fee recalculates when the cart crosses the threshold on the checkout page

| Field                  | Value                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p1 @e2e @ship @candidate @gate`                                                                                                                  |
| **Issue**              | SHIP-9                                                                                                                                                     |
| **Automation Score**   | MEDIUM (49/67.5)                                                                                                                                           |
| **ISTQB Technique**    | State Transition — below threshold → at/above threshold → below threshold, Standard selected                                                               |
| **Manual Env**         | Local, Staging                                                                                                                                             |
| **Precondition**       | Guest session. Cart contains one item at $45.00 and one item at $10.00 (subtotal $55.00). Checkout page open, Standard selected, Shipping shows `Free`.    |
| **Steps**              | 1. Remove the $10.00 item (via the checkout cart summary, or the cart page then return) <br> 2. Read the "Shipping" line and total <br> 3. Add the $10.00 item back <br> 4. Read the "Shipping" line and total |
| **Expected**           | After step 2: subtotal `$45.00`, Shipping `$5.99`, total updated. After step 4: subtotal `$55.00`, Shipping `Free`, total updated. No stale value is shown at any point. |
| **data-testid needed** | `checkout-subtotal`, `checkout-shipping-fee`, `checkout-order-total`, `cart-item-remove`                                                                    |
| **Source**             | Added by QA (the story asks for "the right shipping fee" but no AC covers recalculation after a cart change)                                               |
| **Note**               | Relies on A5. If the checkout page does not allow cart edits, perform them on the cart page and return; the expectation is unchanged.                      |

---

## TC-SHIP-009: Fee recalculates when switching between Standard and Express

| Field                  | Value                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                    |
| **Issue**              | SHIP-9                                                                                                                                                     |
| **Automation Score**   | HIGH (56/67.5)                                                                                                                                             |
| **ISTQB Technique**    | State Transition — Standard → Express → Standard for a non-member and for a member                                                                        |
| **Manual Env**         | Local, Staging                                                                                                                                             |
| **Precondition**       | Guest session. Cart subtotal $30.00. Checkout open, Standard selected.                                                                                    |
| **Steps**              | 1. Select **Express**; read the "Shipping" line <br> 2. Select **Standard**; read the "Shipping" line <br> 3. Sign in as a member on the same checkout <br> 4. Select **Express**; read the line <br> 5. Select **Standard**; read the line |
| **Expected**           | Step 1: `$12.99`. Step 2: `$5.99`. Step 4: `$7.99`. Step 5: `Free`. The order total follows each change.                                                    |
| **data-testid needed** | `shipping-option-standard`, `shipping-option-express`, `checkout-shipping-fee`, `checkout-order-total`                                                      |
| **Source**             | AC-1, AC-2, AC-3                                                                                                                                           |
| **Note**               | Relies on A5. If signing in mid-checkout redirects to the cart, resume from checkout with Standard selected and continue from step 4.                       |

---

## TC-SHIP-010: Signed-in non-member is charged as a non-member

| Field                  | Value                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                    |
| **Issue**              | SHIP-9                                                                                                                                                     |
| **Automation Score**   | HIGH (54/67.5)                                                                                                                                             |
| **ISTQB Technique**    | EP — non-member partition, second representative (signed in, member flag off)                                                                              |
| **Manual Env**         | Local, Staging                                                                                                                                             |
| **Precondition**       | Signed in as an account without the member flag. Cart subtotal $30.00. Checkout open.                                                                     |
| **Steps**              | 1. With Standard selected, read the "Shipping" line <br> 2. Select **Express**; read the "Shipping" line                                                   |
| **Expected**           | Step 1: `$5.99`. Step 2: `$12.99`. Being signed in does not by itself grant member pricing.                                                                 |
| **data-testid needed** | `shipping-option-express`, `checkout-shipping-fee`                                                                                                          |
| **Source**             | Added by QA (the ticket does not say whether "member" means any signed-in account; A2 assumes a separate flag)                                             |
| **Note**               | If product confirms that every signed-in account is a member, mark this case dropped with a dated note and move its steps into TC-SHIP-003.                 |

---

## TC-SHIP-011: Fee updates when a guest signs in as a member during checkout

| Field                  | Value                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @ship @candidate`                                                                                                                    |
| **Issue**              | SHIP-9                                                                                                                                                     |
| **Automation Score**   | MEDIUM (46/67.5)                                                                                                                                           |
| **ISTQB Technique**    | State Transition — guest → member on the checkout page, Standard selected, subtotal < $50.00                                                               |
| **Manual Env**         | Local, Staging                                                                                                                                             |
| **Precondition**       | Guest session. Cart subtotal $30.00. Checkout open, Standard selected, Shipping shows `$5.99`.                                                             |
| **Steps**              | 1. Sign in as a member from the checkout page <br> 2. Read the "Shipping" line and order total <br> 3. Sign out <br> 4. Read the "Shipping" line and order total |
| **Expected**           | After step 2: Shipping `Free`, total reduced by $5.99. After step 4: Shipping `$5.99` again (or the shopper is returned to a guest checkout showing `$5.99`). |
| **data-testid needed** | `checkout-shipping-fee`, `checkout-order-total`, `checkout-sign-in-link`                                                                                    |
| **Source**             | Added by QA (the ticket is silent on a sign-in state change during checkout)                                                                               |
| **Note**               | Relies on A5. Cart must be preserved across sign-in; if it is not, that is a separate finding against the cart, not this story.                            |

---

## TC-SHIP-012: Server rejects a client-supplied shipping fee

| Field                  | Value                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p0 @api @ship @candidate`                                                                                                                    |
| **Issue**              | SHIP-9                                                                                                                                                     |
| **Automation Score**   | HIGH (60/67.5)                                                                                                                                             |
| **ISTQB Technique**    | Error Guessing — tampered request (security)                                                                                                               |
| **Manual Env**         | Local, Staging                                                                                                                                             |
| **Precondition**       | Guest session with a cart subtotal of $30.00 and Standard selected. API client (or browser dev tools) able to edit the order-placement request.           |
| **Steps**              | 1. Capture the order-placement request <br> 2. Add or change a shipping-fee field to `0` (and, in a second run, to `-5.99`) <br> 3. Send the request <br> 4. Inspect the response and the stored order |
| **Expected**           | The order is either rejected with a 4xx validation error or accepted with the server-computed fee of `$5.99`. The stored order never carries `0` or a negative shipping fee. |
| **data-testid needed** | N/A — API-level case, no UI element is asserted                                                                                                             |
| **Source**             | Added by QA (the ticket is silent on where the fee is computed; A6 assumes server-side)                                                                    |
| **Note**               | If the request has no fee field at all, record that as the pass evidence for the "rejected or ignored" expectation.                                        |

---

## TC-SHIP-013: Shipping fee shown at checkout matches the placed order

| Field                  | Value                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@sanity @p1 @e2e @ship @candidate`                                                                                                                        |
| **Issue**              | SHIP-9                                                                                                                                                     |
| **Automation Score**   | MEDIUM (47/67.5)                                                                                                                                           |
| **ISTQB Technique**    | EP — end-to-end consistency, one representative per fee value ($5.99 and $7.99)                                                                             |
| **Manual Env**         | Staging                                                                                                                                                    |
| **Precondition**       | Guest session, cart subtotal $30.00, test payment method available. A member account with the same cart is also prepared.                                 |
| **Steps**              | 1. As guest with Standard selected, note the Shipping line (`$5.99`) and place the order <br> 2. Open the order confirmation page and the order in the account/order history or admin <br> 3. Repeat as the member with Express selected (`$7.99`) |
| **Expected**           | The confirmation page and the stored order show the same shipping fee and total that checkout displayed: `$5.99` for the guest order, `$7.99` for the member order. |
| **data-testid needed** | `checkout-shipping-fee`, `checkout-place-order`, `order-confirmation-shipping-fee`, `order-confirmation-total`                                               |
| **Source**             | Added by QA (the story's goal is "so that I know what I will pay"; no AC checks that the displayed fee is what is charged)                                 |
| **Note**               | Needs a sandbox payment method. Mark `@manual-only` if none exists in Local.                                                                                |

---

## TC-SHIP-014: Fee display is correct for an empty cart and after a full cart removal

| Field                  | Value                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @ship @candidate`                                                                                                                    |
| **Issue**              | SHIP-9                                                                                                                                                     |
| **Automation Score**   | MEDIUM (44/67.5)                                                                                                                                           |
| **ISTQB Technique**    | Error Guessing — empty state, subtotal $0.00 (BVA minimum)                                                                                                 |
| **Manual Env**         | Local, Staging                                                                                                                                             |
| **Precondition**       | Guest session. Cart contains one item priced $30.00. Checkout open, Standard selected, Shipping `$5.99`.                                                   |
| **Steps**              | 1. Remove the only item from the cart <br> 2. Observe the checkout page <br> 3. Attempt to open `/checkout` directly with the empty cart                   |
| **Expected**           | Checkout does not show a shipping charge on an empty cart. Either the shopper is redirected to the empty-cart page, or the summary shows subtotal `$0.00` with no payable shipping fee and the place-order action disabled. No `$5.99` is shown for a $0.00 subtotal. |
| **data-testid needed** | `checkout-shipping-fee`, `checkout-place-order`, `cart-empty-state`                                                                                         |
| **Source**             | Added by QA (the ticket is silent on the empty-cart state; a $0.00 subtotal is below the threshold and would otherwise read as a $5.99 charge)             |
| **Note**               | Exact behaviour (redirect vs. disabled button) is unspecified; record what the implementation does as a correction here on first run.                      |

---

## Automation score detail

| TC          | Freq ×2 | Crit ×2 | Stab ×2 | Cmplx ×1.5 | Data ×1.5 | Determ ×1.5 | ROI ×2 | Time ×1 | Total |
| ----------- | ------- | ------- | ------- | ---------- | --------- | ----------- | ------ | ------- | ----- |
| TC-SHIP-001 | 10      | 10      | 8       | 7.5        | 7.5       | 7.5         | 8      | 4       | 61    |
| TC-SHIP-002 | 10      | 10      | 8       | 7.5        | 7.5       | 7.5         | 8      | 4       | 61    |
| TC-SHIP-003 | 10      | 10      | 8       | 7.5        | 6         | 7.5         | 8      | 4       | 58    |
| TC-SHIP-004 | 8       | 8       | 8       | 7.5        | 6         | 7.5         | 8      | 4       | 55    |
| TC-SHIP-005 | 10      | 10      | 8       | 6          | 7.5       | 7.5         | 8      | 3       | 59    |
| TC-SHIP-006 | 10      | 10      | 8       | 6          | 6         | 7.5         | 8      | 3       | 57    |
| TC-SHIP-007 | 10      | 10      | 8       | 7.5        | 6         | 7.5         | 10     | 5       | 63    |
| TC-SHIP-008 | 8       | 8       | 6       | 4.5        | 6         | 6           | 8      | 3       | 49    |
| TC-SHIP-009 | 8       | 8       | 8       | 6          | 6         | 7.5         | 8      | 3       | 56    |
| TC-SHIP-010 | 8       | 8       | 8       | 7.5        | 6         | 7.5         | 8      | 4       | 54    |
| TC-SHIP-011 | 6       | 8       | 6       | 4.5        | 6         | 6           | 6      | 3       | 46    |
| TC-SHIP-012 | 8       | 10      | 8       | 6          | 7.5       | 7.5         | 8      | 5       | 60    |
| TC-SHIP-013 | 6       | 8       | 6       | 4.5        | 4.5       | 6           | 8      | 2       | 47    |
| TC-SHIP-014 | 6       | 6       | 6       | 6          | 7.5       | 6           | 6      | 3       | 44    |

## Coverage summary

| Source                              | Cases                                            |
| ----------------------------------- | ------------------------------------------------ |
| AC-1                                | 001, 002, 004, 007, 009                          |
| AC-2                                | 003, 004, 009                                    |
| AC-3                                | 005, 006, 009                                    |
| Added by QA                         | 008, 010, 011, 012, 013, 014                     |

Open questions for the product owner, carried as assumptions until answered: whether the subtotal is measured before or after promo codes (A1), whether "member" is a flag or any signed-in account (A2), and how a free fee is labelled (A4).

Rules not applied: the `context-discovery` and `testing-guidelines` rules were not in context and no `qa-rules` skill is installed, so the cases were grounded in the story text and the stated assumptions rather than the codebase, which is empty in this working directory.
