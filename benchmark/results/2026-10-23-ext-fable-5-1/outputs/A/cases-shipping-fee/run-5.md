# Test Cases — SHIP-9: Shipping fee at checkout

## Assumptions

- **Subtotal** means the merchandise total after item-level and promo discounts, before tax and shipping. A subtotal of $0.00 (fully discounted) counts as "below $50.00".
- **Member** means a logged-in shopper whose membership is active at the time the checkout page loads. Guests and logged-in non-members are treated the same.
- Standard is the default selected shipping method on the checkout page.
- The fee shown at checkout is the fee charged on the resulting order.
- Currency is USD, amounts rounded to cents; there are no regional or weight-based surcharges.
- There is only one "member" tier (no tiered membership pricing).

## Standard shipping — non-member (AC-1)

| ID | Title | Preconditions | Steps | Expected |
|---|---|---|---|---|
| TC-01 | Below threshold charges $5.99 | Non-member; cart subtotal $25.00 | Go to checkout; Standard selected | Shipping fee shows **$5.99**; order total = $25.00 + tax + $5.99 |
| TC-02 | Boundary: $49.99 charges $5.99 | Non-member; subtotal $49.99 | Go to checkout; Standard selected | Shipping fee **$5.99** |
| TC-03 | Boundary: exactly $50.00 is free | Non-member; subtotal $50.00 | Go to checkout; Standard selected | Shipping fee **$0.00** / "Free" |
| TC-04 | Boundary: $50.01 is free | Non-member; subtotal $50.01 | Go to checkout; Standard selected | Shipping fee **$0.00** / "Free" |
| TC-05 | Large order is free | Non-member; subtotal $1,250.00 | Go to checkout; Standard selected | Shipping fee **$0.00** / "Free" |
| TC-06 | Minimum subtotal charges $5.99 | Non-member; subtotal $0.01 | Go to checkout; Standard selected | Shipping fee **$5.99** |
| TC-07 | Threshold uses post-discount subtotal | Non-member; items $55.00, promo −$10.00 (subtotal $45.00) | Apply promo; go to checkout; Standard selected | Shipping fee **$5.99** (assumption: discount lowers subtotal below threshold) |
| TC-08 | Tax does not count toward threshold | Non-member; subtotal $48.00; tax brings total above $50.00 | Go to checkout; Standard selected | Shipping fee **$5.99** |
| TC-09 | Fee updates when cart crosses threshold | Non-member; subtotal $49.99 at checkout | Return to cart, raise subtotal to $50.00; return to checkout | Fee changes from $5.99 to **Free**; reverse edit changes it back to **$5.99** |

## Standard shipping — member (AC-2)

| ID | Title | Preconditions | Steps | Expected |
|---|---|---|---|---|
| TC-10 | Member below threshold is free | Active member; subtotal $25.00 | Go to checkout; Standard selected | Shipping fee **$0.00** / "Free" |
| TC-11 | Member at minimum subtotal is free | Active member; subtotal $0.01 | Go to checkout; Standard selected | Shipping fee **$0.00** / "Free" |
| TC-12 | Member at/above threshold is free | Active member; subtotal $50.00 and $500.00 | Go to checkout; Standard selected | Shipping fee **$0.00** / "Free" in both cases |
| TC-13 | Expired/cancelled membership is treated as non-member | Logged-in account with expired membership; subtotal $25.00 | Go to checkout; Standard selected | Shipping fee **$5.99** |
| TC-14 | Logging in as member mid-checkout removes fee | Guest; subtotal $25.00; fee shows $5.99 | Log in as active member on the checkout page | Fee recalculates to **Free** |

## Express shipping (AC-3)

| ID | Title | Preconditions | Steps | Expected |
|---|---|---|---|---|
| TC-15 | Non-member express below threshold | Non-member; subtotal $25.00 | Select Express | Shipping fee **$12.99** |
| TC-16 | Non-member express at/above threshold is not free | Non-member; subtotal $50.00 and $500.00 | Select Express | Shipping fee **$12.99** in both cases (free-threshold does not apply to Express) |
| TC-17 | Member express below threshold | Active member; subtotal $0.01 and $25.00 | Select Express | Shipping fee **$7.99** in both cases |
| TC-18 | Member express at/above threshold | Active member; subtotal $50.00 and $500.00 | Select Express | Shipping fee **$7.99** in both cases (member express is never free) |
| TC-19 | Expired membership pays non-member express | Expired membership; subtotal $100.00 | Select Express | Shipping fee **$12.99** |

## Cross-cutting

| ID | Title | Preconditions | Steps | Expected |
|---|---|---|---|---|
| TC-20 | Switching methods updates fee and total | Non-member; subtotal $25.00 | Toggle Standard → Express → Standard | Fee shows $5.99 → $12.99 → $5.99; order total updates each time without page reload errors |
| TC-21 | Both options visible with correct prices before selection | Member; subtotal $25.00 | Open shipping method selector | Standard listed as **Free**, Express listed as **$7.99** |
| TC-22 | Charged fee matches displayed fee | Any of TC-01–TC-19 | Place the order | Order confirmation and order record show the same shipping fee displayed at checkout |
| TC-23 | Fee persists across page refresh | Non-member; subtotal $25.00; Express selected | Refresh checkout page | Express still selected; fee still $12.99 |

## Coverage matrix

| AC | Test cases |
|---|---|
| AC-1 | TC-01 – TC-09, TC-13, TC-14, TC-20, TC-22 |
| AC-2 | TC-10 – TC-14, TC-21, TC-22 |
| AC-3 | TC-15 – TC-21, TC-22, TC-23 |

## Open questions (noted, not blocking)

- Whether promo/coupon discounts reduce the subtotal used for the $50.00 threshold (TC-07 assumes yes).
- Whether a membership that expires during an open checkout session is re-evaluated at order placement.
- Whether gift cards or store credit affect the subtotal for threshold purposes (assumed not; they are payment, not discount).
