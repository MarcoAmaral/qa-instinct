# Test Cases — SHIP-9: Shipping fee at checkout

## Assumptions

Because the story leaves these points open, the following assumptions apply to every test below. Each should be confirmed with the product owner; if any is wrong, the affected cases are marked.

| # | Assumption | Affected cases |
|---|---|---|
| A1 | "Subtotal" means the merchandise total after item-level and cart-level discounts (promo codes) are applied, but **before** tax and before the shipping fee itself. | TC-05, TC-06, TC-18, TC-19 |
| A2 | The $50.00 threshold is inclusive: exactly $50.00 qualifies for free standard shipping. (This is stated in AC-1 as "or more".) | TC-02 |
| A3 | Subtotal is compared at cent precision; no rounding of partial cents is involved because prices are stored in cents. | TC-01 to TC-03 |
| A4 | "Member" means a shopper who is logged in with an active membership at the time the checkout page is rendered. Guests and logged-in non-members are treated the same (non-member). | TC-07 to TC-12, TC-20, TC-21 |
| A5 | Only two shipping methods exist: Standard and Express. The shopper selects one; Standard is pre-selected by default. | TC-13, TC-14 |
| A6 | Fees are displayed in USD with two decimals and a dollar sign, and free shipping is displayed as "Free" (or "$0.00"). The exact label is a UI detail to be confirmed. | TC-15 |
| A7 | The fee shown on the checkout page must equal the fee charged on the order and shown on the confirmation page. | TC-16 |
| A8 | The rules apply to a single-shipment, domestic order. Multi-shipment and international shipping are out of scope for SHIP-9. | Out of scope section |

---

## Section 1 — AC-1: Standard shipping threshold (non-member)

Precondition for all cases in this section: shopper is a guest or a logged-in non-member; Standard shipping is selected.

| ID | Title | Steps | Expected result | Priority |
|---|---|---|---|---|
| TC-01 | Subtotal just below threshold | Add items so the subtotal is exactly **$49.99**. Proceed to checkout. | Standard shipping fee displays **$5.99**. Order total = $49.99 + tax + $5.99. | High |
| TC-02 | Subtotal exactly at threshold (boundary) | Add items so the subtotal is exactly **$50.00**. Proceed to checkout. | Standard shipping fee displays **Free / $0.00**. Order total = $50.00 + tax. | High |
| TC-03 | Subtotal just above threshold | Add items so the subtotal is exactly **$50.01**. Proceed to checkout. | Standard shipping fee displays **Free / $0.00**. | High |
| TC-04 | Low-value subtotal | Add a single item priced **$0.01**. Proceed to checkout. | Standard shipping fee displays **$5.99**. | Medium |
| TC-05 | Promo code pushes subtotal below threshold | Add items totalling $55.00. Apply a $10.00-off promo code so the subtotal becomes $45.00. | Standard shipping fee changes to **$5.99**. The fee is recalculated after the discount is applied (A1). | High |
| TC-06 | Promo code removed, subtotal returns above threshold | Continue from TC-05. Remove the promo code. | Standard shipping fee returns to **Free / $0.00** without a page reload or with a reload, consistent with the rest of checkout. | Medium |
| TC-07 | Large subtotal | Add items totalling **$1,000.00** or more. | Standard shipping fee displays **Free / $0.00**. No overflow or formatting issue in the total. | Low |
| TC-08 | Quantity change crosses threshold in cart | Add one item at $30.00 (fee $5.99 at checkout). Return to cart and change quantity to 2 (subtotal $60.00). Return to checkout. | Standard shipping fee updates to **Free / $0.00**. | High |
| TC-09 | Item removal crosses threshold downward | Checkout shows a $60.00 subtotal with free standard shipping. Remove a $20.00 item (subtotal $40.00). | Standard shipping fee updates to **$5.99**. The stale "Free" value is not retained. | High |

## Section 2 — AC-2: Member standard shipping

Precondition: shopper is logged in with an active membership (A4); Standard shipping is selected.

| ID | Title | Steps | Expected result | Priority |
|---|---|---|---|---|
| TC-10 | Member, subtotal below threshold | Subtotal **$49.99**. Proceed to checkout. | Standard shipping fee displays **Free / $0.00**. | High |
| TC-11 | Member, minimal subtotal | Subtotal **$0.01**. Proceed to checkout. | Standard shipping fee displays **Free / $0.00**. | Medium |
| TC-12 | Member, subtotal at and above threshold | Subtotal **$50.00**, then **$150.00**. | Standard shipping fee displays **Free / $0.00** in both cases. Member benefit and threshold rule do not conflict or double-apply (no negative fee). | Medium |
| TC-20 | Guest logs in as member during checkout | Start checkout as a guest with subtotal $30.00 (fee shows $5.99). Log in to a member account on the checkout page. | Standard shipping fee updates to **Free / $0.00** after login. | High |
| TC-21 | Expired or cancelled membership | Log in with an account whose membership has expired or been cancelled. Subtotal $30.00. | Shopper is treated as a non-member: Standard shipping fee displays **$5.99**. | High |
| TC-22 | Membership status changes mid-session | Member starts checkout (fee Free). In another session, the membership is cancelled. Member refreshes checkout. | Fee reflects current status: **$5.99**. Note: if the system is designed to honour the status at session start, this expected result changes; confirm with product. | Low |

## Section 3 — AC-3: Express shipping

| ID | Title | Steps | Expected result | Priority |
|---|---|---|---|---|
| TC-13 | Non-member express, below threshold | Guest, subtotal **$49.99**. Select Express. | Express shipping fee displays **$12.99**. | High |
| TC-14 | Non-member express, at and above threshold | Guest, subtotal **$50.00**, then **$500.00**. Select Express. | Express shipping fee displays **$12.99** in both cases. The $50 free-shipping threshold does **not** apply to Express. | High |
| TC-23 | Member express, below threshold | Member, subtotal **$0.01** and **$49.99**. Select Express. | Express shipping fee displays **$7.99**. | High |
| TC-24 | Member express, at and above threshold | Member, subtotal **$50.00** and **$500.00**. Select Express. | Express shipping fee displays **$7.99**. Member express is never free. | High |
| TC-25 | Switch from Standard to Express and back (non-member, above threshold) | Guest, subtotal $60.00. Standard selected (Free). Select Express, then select Standard again. | Fee shows **$12.99** on Express, then returns to **Free / $0.00** on Standard. Order total updates each time. | High |
| TC-26 | Switch from Standard to Express and back (member) | Member, subtotal $30.00. Standard (Free). Select Express, then Standard. | Fee shows **$7.99**, then **Free / $0.00**. | Medium |
| TC-27 | Express selected, then subtotal drops below threshold | Guest, subtotal $60.00, Express selected ($12.99). Remove an item (subtotal $40.00). | Express fee remains **$12.99** (unchanged). Standard option, if shown alongside, now shows $5.99. | Medium |
| TC-28 | Guest logs in as member with Express selected | Guest, Express selected ($12.99). Log in as member. | Express fee updates to **$7.99**. | High |

## Section 4 — Display, totals, and persistence

| ID | Title | Steps | Expected result | Priority |
|---|---|---|---|---|
| TC-15 | Fee formatting | Trigger each possible fee: $5.99, $12.99, $7.99, Free. | Each fee is shown with currency symbol and two decimals ($5.99, not $5.9 or 5.99). Free shipping uses a consistent label ("Free" or "$0.00") per A6. No "$-0.00" or "NaN". | Medium |
| TC-16 | Fee consistency through order placement | For each fee outcome (at least one Free, $5.99, $12.99, $7.99), place the order. | The shipping fee on the review step, the confirmation page, the confirmation email, and the stored order record all match the fee shown at checkout (A7). The charged amount equals subtotal + tax + shipping fee. | High |
| TC-17 | Order total arithmetic | Guest, subtotal $49.99, Standard. Note tax amount T. | Displayed total equals exactly $49.99 + T + $5.99 with no rounding drift (e.g., off-by-one-cent). | High |
| TC-18 | Tax excluded from threshold calculation | Guest, subtotal **$47.00** with tax that brings subtotal + tax to **$50.50**. Standard. | Fee is **$5.99**: tax does not count toward the $50 threshold (A1). | High |
| TC-19 | Shipping fee not counted toward its own threshold | Guest, subtotal **$45.00**. Standard. | Fee is **$5.99**. Subtotal + the $5.99 fee ($50.99) must not be used to qualify for free shipping (A1). | High |
| TC-29 | Free-shipping messaging (if present) | Guest, subtotal $45.00. Observe checkout page. | If the UI shows a "spend $X more for free shipping" message, X is **$5.00**. At $50.00 the message is absent. Members never see the message. Skip if no such message exists. | Low |
| TC-30 | Fee persists on page refresh | Guest, subtotal $30.00, Express selected ($12.99). Refresh the page. | Express remains selected and fee still shows **$12.99**. If selection resets to Standard by design, fee shows **$5.99**, not a blank. | Medium |
| TC-31 | Fee is calculated server-side | Guest, subtotal $30.00. Using browser dev tools, modify the displayed fee or the fee value in the client request to $0.00 and submit the order. | Server rejects the tampered value or recalculates it; order is charged **$5.99**. Client-side manipulation cannot change the fee. | High |

## Section 5 — Negative and edge cases

| ID | Title | Steps | Expected result | Priority |
|---|---|---|---|---|
| TC-32 | Empty cart | Clear the cart and navigate directly to the checkout URL. | Shopper is redirected to the cart or shown an empty-cart state. No shipping fee is displayed or charged. | Medium |
| TC-33 | Subtotal reduced to $0.00 by a 100% promo | Guest, subtotal $20.00. Apply a 100%-off promo code. | Standard shipping fee is **$5.99** (subtotal below $50). Express is **$12.99**. Confirm with product whether a fully discounted order should still carry shipping; this is the behaviour per the stated rules. | Low |
| TC-34 | Membership flag and threshold race | Member with subtotal exactly $50.00 selects Standard, then Express, then Standard. | Fee never shows a negative or doubled discount. Standard is Free, Express is $7.99. | Low |
| TC-35 | Multiple browser tabs | Open checkout in two tabs as a guest with subtotal $60.00 (Free). In tab 1, remove an item (subtotal $40.00). In tab 2, submit the order without refreshing. | Server recalculates and charges **$5.99**; the stale Free fee from tab 2 is not honoured. The shopper is shown the updated total before or at confirmation. | Medium |
| TC-36 | Currency with no fractional cents (regression guard) | Enter prices that are whole dollars only: subtotal $50 exactly from five $10 items. | Fee is Free; the comparison does not fail because of integer vs decimal handling. | Low |

---

## Traceability

| Acceptance criterion | Covered by |
|---|---|
| AC-1 | TC-01 to TC-09, TC-17 to TC-19, TC-31, TC-33, TC-36 |
| AC-2 | TC-10 to TC-12, TC-20 to TC-22 |
| AC-3 | TC-13, TC-14, TC-23 to TC-28 |
| Cross-cutting (display, totals, security) | TC-15, TC-16, TC-29, TC-30, TC-32, TC-34, TC-35 |

## Out of scope for SHIP-9 (per A8; raise as separate stories if needed)

- International or regional shipping rates and multi-currency display.
- Orders split into multiple shipments or shipped from multiple warehouses.
- Shipping fee refunds on partial returns or cancellations.
- Gift cards or store credit and whether they reduce the subtotal used for the threshold.
- Tax applied to the shipping fee itself.

## Open questions for the product owner

1. Does "subtotal" include or exclude cart-level promo discounts? (Assumed excluded discounts, i.e., post-discount; see A1.)
2. Should a fully discounted $0.00 order still be charged shipping? (TC-33)
3. If membership lapses between adding to cart and paying, which status governs? (TC-22)
4. What is the exact label for a free fee: "Free", "$0.00", or both? (A6)
