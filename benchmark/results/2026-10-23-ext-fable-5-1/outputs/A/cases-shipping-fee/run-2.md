# Test Cases — SHIP-9: Shipping fee at checkout

## Assumptions

- "Subtotal" is the merchandise total after item-level discounts and promo codes, before tax and shipping.
- The $50.00 threshold is inclusive: a subtotal of exactly $50.00 qualifies for free standard shipping.
- "Member" means a shopper signed in to an account with active membership at the time the checkout page renders. Guests and signed-in non-members are treated identically.
- Express pricing for non-members is $12.99 at any subtotal; there is no free-express threshold.
- Standard shipping is the default selected method when checkout loads.
- Prices are in USD and displayed to two decimal places. A free fee is displayed as "Free" (test cases note where this matters; adjust if the design says "$0.00").
- Changing the cart on the checkout page recalculates the fee without a full reload.

## Non-member, standard shipping (AC-1)

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-01 | Fee charged below threshold | Guest shopper, cart subtotal $49.99, standard selected | Open checkout | Shipping fee shows $5.99. Order total = $49.99 + tax + $5.99. |
| TC-02 | Free at exact threshold (boundary) | Guest, subtotal $50.00, standard selected | Open checkout | Shipping fee shows Free. Order total excludes any shipping charge. |
| TC-03 | Free just above threshold | Guest, subtotal $50.01, standard selected | Open checkout | Shipping fee shows Free. |
| TC-04 | Fee charged at minimum subtotal | Guest, subtotal $0.01 (lowest-priced item), standard selected | Open checkout | Shipping fee shows $5.99. |
| TC-05 | Fee charged well above threshold is still free | Guest, subtotal $500.00 | Open checkout | Shipping fee shows Free. |
| TC-06 | Promo code drops subtotal below threshold | Guest, subtotal $55.00, standard selected, checkout shows Free | Apply a $10 promo code | Subtotal becomes $45.00 and fee updates to $5.99 without page reload. |
| TC-07 | Adding item raises subtotal above threshold | Guest, subtotal $45.00, checkout shows $5.99 | Increase quantity so subtotal is $50.00 | Fee updates to Free. |
| TC-08 | Threshold uses subtotal, not total with tax | Guest, subtotal $48.00, tax brings total above $50.00 | Open checkout | Fee shows $5.99 (tax does not count toward threshold). |
| TC-09 | Signed-in non-member treated like guest | Shopper signed in without membership, subtotal $49.99 | Open checkout | Fee shows $5.99. |

## Member, standard shipping (AC-2)

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-10 | Member free below threshold | Signed-in member, subtotal $49.99, standard selected | Open checkout | Fee shows Free. |
| TC-11 | Member free at minimum subtotal | Member, subtotal $0.01 | Open checkout | Fee shows Free. |
| TC-12 | Member free at threshold and above | Member, subtotal $50.00; repeat with $500.00 | Open checkout | Fee shows Free in both cases. |
| TC-13 | Fee recalculates when member signs in mid-checkout | Guest, subtotal $30.00, checkout shows $5.99 | Sign in as a member from the checkout page | Fee updates to Free. Order total drops by $5.99. |
| TC-14 | Fee recalculates when member signs out | Member, subtotal $30.00, checkout shows Free | Sign out and continue as guest | Fee updates to $5.99. |
| TC-15 | Expired membership does not get member rate | Signed-in shopper whose membership expired yesterday, subtotal $30.00 | Open checkout | Fee shows $5.99. |

## Express shipping (AC-3)

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-16 | Non-member express below threshold | Guest, subtotal $20.00 | Select express | Fee shows $12.99. |
| TC-17 | Non-member express at and above threshold | Guest, subtotal $50.00; repeat with $500.00 | Select express | Fee shows $12.99 in both cases (free-standard threshold does not apply to express). |
| TC-18 | Member express below threshold | Member, subtotal $20.00 | Select express | Fee shows $7.99. |
| TC-19 | Member express at and above threshold | Member, subtotal $50.00; repeat with $500.00 | Select express | Fee shows $7.99 in both cases. |
| TC-20 | Member express at minimum subtotal | Member, subtotal $0.01 | Select express | Fee shows $7.99. |
| TC-21 | Switching express back to standard | Guest, subtotal $60.00, express selected ($12.99) | Select standard | Fee updates to Free. |
| TC-22 | Switching standard to express, member | Member, subtotal $10.00, standard selected (Free) | Select express | Fee updates to $7.99. |
| TC-23 | Express option list shows correct price per shopper type | Guest and member, any subtotal | Open the shipping method selector | Guest sees Express $12.99; member sees Express $7.99 in the option label before selecting. |

## Cross-cutting and negative cases

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-24 | Order total matches displayed fee | Any shopper, any method | Compare line items and total on checkout | Total = subtotal + tax + displayed shipping fee, to the cent. |
| TC-25 | Fee persisted to the order | Guest, subtotal $30.00, standard | Place order | Order record and confirmation page show shipping $5.99. |
| TC-26 | Fee snapshot not changed by later membership change | Guest places order with $5.99 fee; shopper later becomes a member | View order history | Placed order still shows $5.99. |
| TC-27 | Cart emptied at checkout | Any shopper, cart becomes empty | Remove all items | No shipping fee displayed or charged; checkout shows empty-cart state. |
| TC-28 | Server-side validation of fee | Guest, subtotal $30.00 | Tamper with the client request to submit shipping fee $0.00 | Order is rejected or server recalculates to $5.99. |
| TC-29 | Rounding at threshold | Guest, three items at $16.666 each (if fractional-cent pricing exists) | Open checkout | Subtotal rounds to $50.00 and fee shows Free; verify consistent rounding rule. |
| TC-30 | Fee display formatting | Any case showing a fee | Inspect fee text | Shows currency symbol and two decimals ($5.99, $12.99, $7.99); free shows "Free". |

## Traceability

| AC | Test cases |
|---|---|
| AC-1 | TC-01 to TC-09, TC-21, TC-24, TC-25, TC-28, TC-29 |
| AC-2 | TC-10 to TC-15, TC-22, TC-26 |
| AC-3 | TC-16 to TC-23 |
