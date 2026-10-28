# Test Cases — SHIP-9: Shipping fee at checkout

## Assumptions

- "Subtotal" means the merchandise total after item-level discounts and before tax, shipping, and gift cards. Promo codes that reduce the subtotal are applied before the $50.00 check.
- "Member" means a shopper logged in with an active membership. Guests and logged-in non-members are treated identically as non-members.
- The $50.00 threshold is inclusive (AC-1 says "or more"), and comparison is done on the exact cent value.
- Express is never free. The only express prices are $12.99 (non-member) and $7.99 (member).
- Only two shipping methods exist: Standard and Express. Currency is USD.
- The fee is recomputed whenever the cart changes or the login/membership state changes before the order is placed.
- A $0.00 subtotal (e.g. fully discounted cart) is out of scope for this story; one case is included to document behaviour and should be confirmed with product.

## Test case table

| ID | AC | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|---|
| TC-01 | AC-1 | Non-member, standard, subtotal below threshold | Non-member session; cart subtotal $49.99 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows **$5.99**. Order total = $49.99 + $5.99 + tax. |
| TC-02 | AC-1 | Non-member, standard, subtotal exactly at threshold | Non-member session; cart subtotal $50.00 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows **$0.00** / "Free". |
| TC-03 | AC-1 | Non-member, standard, subtotal just above threshold | Non-member session; cart subtotal $50.01 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows **$0.00** / "Free". |
| TC-04 | AC-1 | Non-member, standard, minimal subtotal | Non-member session; cart subtotal $0.01 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows **$5.99**. |
| TC-05 | AC-1 | Non-member, standard, large subtotal | Non-member session; cart subtotal $1,000.00 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows **$0.00** / "Free". |
| TC-06 | AC-1 | Threshold uses subtotal after promo discount | Non-member session; items total $55.00; promo code worth −$10.00 | 1. Apply promo. 2. Go to checkout. 3. Select Standard. | Subtotal is $45.00; shipping fee shows **$5.99**. |
| TC-07 | AC-1 | Threshold excludes tax | Non-member session; subtotal $48.00; applicable tax brings total above $50.00 | 1. Go to checkout. 2. Select Standard. | Shipping fee shows **$5.99** (tax does not count toward threshold). |
| TC-08 | AC-1 | Fee updates when cart crosses threshold upward | Non-member session; subtotal $45.00 at checkout | 1. Select Standard; note fee. 2. Return to cart, add $5.00 item. 3. Return to checkout. | Fee changes from $5.99 to **$0.00**; total recalculates. |
| TC-09 | AC-1 | Fee updates when cart crosses threshold downward | Non-member session; subtotal $52.00 at checkout | 1. Select Standard; note fee $0.00. 2. Remove an item so subtotal is $47.00. 3. Return to checkout. | Fee changes from $0.00 to **$5.99**; total recalculates. |
| TC-10 | AC-2 | Member, standard, subtotal below threshold | Logged-in active member; subtotal $10.00 | 1. Go to checkout. 2. Select Standard. | Shipping fee shows **$0.00** / "Free". |
| TC-11 | AC-2 | Member, standard, subtotal exactly at threshold | Logged-in active member; subtotal $50.00 | 1. Go to checkout. 2. Select Standard. | Shipping fee shows **$0.00** / "Free". |
| TC-12 | AC-2 | Member, standard, subtotal above threshold | Logged-in active member; subtotal $120.00 | 1. Go to checkout. 2. Select Standard. | Shipping fee shows **$0.00** / "Free". |
| TC-13 | AC-2 | Member, standard, minimal subtotal | Logged-in active member; subtotal $0.01 | 1. Go to checkout. 2. Select Standard. | Shipping fee shows **$0.00** / "Free". |
| TC-14 | AC-2 | Logging in as member at checkout removes standard fee | Guest session; subtotal $30.00; Standard selected showing $5.99 | 1. Log in as an active member from checkout. | Fee updates to **$0.00**; total recalculates without re-selecting shipping. |
| TC-15 | AC-2 | Expired/cancelled membership is treated as non-member | Logged-in user whose membership has expired; subtotal $30.00 | 1. Go to checkout. 2. Select Standard. | Shipping fee shows **$5.99**. |
| TC-16 | AC-3 | Non-member, express, subtotal below threshold | Non-member session; subtotal $20.00 | 1. Go to checkout. 2. Select Express. | Shipping fee shows **$12.99**. |
| TC-17 | AC-3 | Non-member, express, subtotal at/above threshold | Non-member session; subtotal $50.00 | 1. Go to checkout. 2. Select Express. | Shipping fee shows **$12.99** (free-shipping threshold does not apply to Express). |
| TC-18 | AC-3 | Non-member, express, large subtotal | Non-member session; subtotal $500.00 | 1. Go to checkout. 2. Select Express. | Shipping fee shows **$12.99**. |
| TC-19 | AC-3 | Member, express, subtotal below threshold | Active member; subtotal $20.00 | 1. Go to checkout. 2. Select Express. | Shipping fee shows **$7.99**. |
| TC-20 | AC-3 | Member, express, subtotal at threshold | Active member; subtotal $50.00 | 1. Go to checkout. 2. Select Express. | Shipping fee shows **$7.99** (not free). |
| TC-21 | AC-3 | Member, express, large subtotal | Active member; subtotal $500.00 | 1. Go to checkout. 2. Select Express. | Shipping fee shows **$7.99**. |
| TC-22 | AC-3 | Logging in as member at checkout lowers express fee | Guest session; subtotal $30.00; Express selected showing $12.99 | 1. Log in as an active member from checkout. | Fee updates to **$7.99**; total recalculates. |
| TC-23 | AC-1/3 | Switching between methods updates fee (non-member, below threshold) | Non-member; subtotal $30.00 | 1. Select Standard. 2. Select Express. 3. Select Standard again. | Fee shows $5.99 → $12.99 → $5.99; total recalculates each time. |
| TC-24 | AC-1/3 | Switching between methods updates fee (non-member, above threshold) | Non-member; subtotal $80.00 | 1. Select Standard. 2. Select Express. | Fee shows $0.00 → $12.99. |
| TC-25 | AC-2/3 | Switching between methods updates fee (member) | Active member; subtotal $30.00 | 1. Select Standard. 2. Select Express. | Fee shows $0.00 → $7.99. |
| TC-26 | All | Fee shown at checkout is the fee charged | Any persona/method from the table above | 1. Complete the order. 2. Open order confirmation and order history. | Shipping fee on confirmation, receipt email, and order record equals the fee displayed at checkout. |
| TC-27 | All | Fee cannot be manipulated client-side | Non-member; subtotal $30.00; Standard selected | 1. Intercept the place-order request and set shipping fee to $0.00. 2. Submit. | Server rejects or recomputes the fee; order is charged **$5.99** or the request is refused. Fee is never trusted from the client. |
| TC-28 | AC-1 | Rounding/precision at the threshold | Non-member; cart constructed so unrounded subtotal is $49.995 | 1. Go to checkout. 2. Select Standard. | Displayed subtotal and threshold check agree. If displayed subtotal is $50.00, shipping is free; if $49.99, fee is $5.99. No case where display and fee disagree. |
| TC-29 | AC-1/2 | Free shipping displayed clearly | Any case where fee is $0.00 | 1. Go to checkout. 2. Select Standard. | Fee line reads "Free" or "$0.00" consistently per design; it is not blank or missing. |
| TC-30 | Edge | Zero subtotal cart (to confirm with product) | Non-member; cart fully discounted to $0.00 | 1. Go to checkout. 2. Select Standard. | Per AC-1 literally, fee is **$5.99**. Record actual behaviour and raise with product if a different rule is intended. |

## Decision table (reference)

| Member? | Method | Subtotal | Fee |
|---|---|---|---|
| No | Standard | < $50.00 | $5.99 |
| No | Standard | ≥ $50.00 | $0.00 |
| Yes | Standard | any | $0.00 |
| No | Express | any | $12.99 |
| Yes | Express | any | $7.99 |

## Coverage notes

- Boundary values for AC-1: $49.99, $50.00, $50.01, plus $0.01 and a large value.
- Each cell of the decision table has at least one test; the threshold cells have multiple.
- Dynamic recalculation (cart change, login change, method change) is covered by TC-08, TC-09, TC-14, TC-22, TC-23–25.
- Persistence to the placed order and server-side enforcement are covered by TC-26 and TC-27.

## Open questions for product (not blocking)

1. Does "subtotal" include or exclude gift-wrap, gift cards, or other non-merchandise line items?
2. Is a $0.00 subtotal order possible, and if so, what shipping should apply (TC-30)?
3. Are there regions or item types (oversized, hazardous) that override these fees? None are in scope here.
