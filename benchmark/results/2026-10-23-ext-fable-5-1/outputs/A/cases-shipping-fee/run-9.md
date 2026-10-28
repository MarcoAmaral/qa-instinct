# Test Cases — SHIP-9: Shipping fee at checkout

## Assumptions

- "Subtotal" means the sum of item prices after item-level discounts and promo codes, before tax and shipping. Threshold comparison uses the subtotal in USD rounded to the cent.
- "Members" are shoppers signed in to an account with an active membership. Guests and signed-in non-members are treated the same (non-member).
- Both shipping options are always available and selectable for every order; the shopper picks one at checkout, with Standard selected by default.
- Fee is recalculated whenever subtotal or shipping method changes while on the checkout page.
- The displayed fee must match the fee charged in the order total and on the placed order.

## Non-member, Standard shipping (AC-1)

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-01 | Standard fee below threshold | Non-member, cart subtotal $49.99 | Open checkout, select Standard | Shipping fee displays $5.99; order total = subtotal + tax + $5.99 |
| TC-02 | Standard free exactly at threshold | Non-member, cart subtotal $50.00 | Open checkout, select Standard | Shipping fee displays $0.00 / "Free" |
| TC-03 | Standard free above threshold | Non-member, cart subtotal $50.01 | Open checkout, select Standard | Shipping fee displays $0.00 / "Free" |
| TC-04 | Standard fee on minimal order | Non-member, cart subtotal $0.01 | Open checkout, select Standard | Shipping fee displays $5.99 |
| TC-05 | Standard free on large order | Non-member, cart subtotal $500.00 | Open checkout, select Standard | Shipping fee displays $0.00 / "Free" |
| TC-06 | Promo code drops subtotal below threshold | Non-member, cart subtotal $55.00 | At checkout with Standard selected, apply a $10 promo code | Subtotal becomes $45.00; shipping fee updates to $5.99 without page reload |
| TC-07 | Quantity change crosses threshold upward | Non-member, cart subtotal $45.00 with Standard selected showing $5.99 | Increase an item quantity so subtotal becomes $52.00 | Shipping fee updates to $0.00 / "Free" |
| TC-08 | Threshold uses subtotal, not total with tax | Non-member, cart subtotal $48.00, tax brings total above $50.00 | Open checkout, select Standard | Shipping fee displays $5.99 (tax does not count toward threshold) |

## Member, Standard shipping (AC-2)

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-09 | Member free Standard below threshold | Signed-in active member, cart subtotal $10.00 | Open checkout, select Standard | Shipping fee displays $0.00 / "Free" |
| TC-10 | Member free Standard at threshold | Signed-in active member, cart subtotal $50.00 | Open checkout, select Standard | Shipping fee displays $0.00 / "Free" |
| TC-11 | Member free Standard above threshold | Signed-in active member, cart subtotal $120.00 | Open checkout, select Standard | Shipping fee displays $0.00 / "Free" |
| TC-12 | Member free Standard on minimal order | Signed-in active member, cart subtotal $0.01 | Open checkout, select Standard | Shipping fee displays $0.00 / "Free" |
| TC-13 | Sign-in as member mid-checkout | Guest, cart subtotal $20.00, Standard selected showing $5.99 | Sign in as an active member on the checkout page | Shipping fee updates to $0.00 / "Free" |
| TC-14 | Expired membership treated as non-member | Signed-in user whose membership has lapsed, cart subtotal $20.00 | Open checkout, select Standard | Shipping fee displays $5.99 |

## Express shipping (AC-3)

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-15 | Non-member Express below threshold | Non-member, cart subtotal $20.00 | Open checkout, select Express | Shipping fee displays $12.99 |
| TC-16 | Non-member Express at threshold | Non-member, cart subtotal $50.00 | Open checkout, select Express | Shipping fee displays $12.99 (free-threshold does not apply to Express) |
| TC-17 | Non-member Express above threshold | Non-member, cart subtotal $200.00 | Open checkout, select Express | Shipping fee displays $12.99 |
| TC-18 | Member Express below threshold | Signed-in active member, cart subtotal $20.00 | Open checkout, select Express | Shipping fee displays $7.99 |
| TC-19 | Member Express at threshold | Signed-in active member, cart subtotal $50.00 | Open checkout, select Express | Shipping fee displays $7.99 |
| TC-20 | Member Express above threshold | Signed-in active member, cart subtotal $200.00 | Open checkout, select Express | Shipping fee displays $7.99 |
| TC-21 | Switch Standard to Express (non-member, above threshold) | Non-member, cart subtotal $60.00, Standard selected showing Free | Select Express | Fee updates to $12.99; order total increases by $12.99 |
| TC-22 | Switch Express to Standard (non-member, below threshold) | Non-member, cart subtotal $30.00, Express selected showing $12.99 | Select Standard | Fee updates to $5.99; order total decreases by $7.00 |
| TC-23 | Switch Express to Standard (member) | Active member, cart subtotal $30.00, Express selected showing $7.99 | Select Standard | Fee updates to $0.00 / "Free" |

## Consistency and end-to-end

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-24 | Charged fee matches displayed fee (non-member Standard) | Non-member, cart subtotal $30.00 | Select Standard, place order | Order confirmation and order record show shipping $5.99; payment captured includes $5.99 |
| TC-25 | Charged fee matches displayed fee (member Express) | Active member, cart subtotal $30.00 | Select Express, place order | Order confirmation and order record show shipping $7.99 |
| TC-26 | Fee shown before payment step | Non-member, cart subtotal $30.00 | Proceed through checkout steps | Shipping fee is visible in the order summary before the shopper enters payment details |
| TC-27 | Default option fee on checkout load | Non-member, cart subtotal $30.00 | Open checkout without changing the shipping selection | Standard is preselected and $5.99 is shown immediately on page load |
| TC-28 | Fee survives page refresh | Non-member, cart subtotal $30.00, Express selected | Refresh checkout page | Express remains selected and $12.99 is shown |
| TC-29 | Fee uses two-decimal currency formatting | Any user, any subtotal | Observe shipping fee display for each option | Fees render as $5.99, $12.99, $7.99, or $0.00/"Free"; no rounding artifacts such as $5.9899 |
| TC-30 | Item removal to empty cart | Non-member, single item cart | Remove the item at checkout | No shipping fee charged; checkout cannot be completed with an empty cart |

## Decision table (fee matrix)

| Shopper | Subtotal | Standard | Express |
|---|---|---|---|
| Non-member | < $50.00 | $5.99 | $12.99 |
| Non-member | ≥ $50.00 | $0.00 | $12.99 |
| Member | < $50.00 | $0.00 | $7.99 |
| Member | ≥ $50.00 | $0.00 | $7.99 |

## Open questions for the product owner (tested under the assumptions above)

- Does "subtotal" include or exclude promo/discount codes and gift card amounts?
- Is a member who is signed out but recognized by cookie treated as a member?
- Are there regions or item types (oversized, hazardous) where Express is unavailable or priced differently?
