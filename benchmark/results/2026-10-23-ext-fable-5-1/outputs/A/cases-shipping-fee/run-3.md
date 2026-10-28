# Test Cases: SHIP-9 Shipping fee at checkout

## Assumptions

- "Subtotal" means the merchandise total after item-level discounts and before tax and shipping. Promo codes applied at cart level are included in the subtotal.
- The $50.00 threshold is inclusive: a subtotal of exactly $50.00 qualifies for free standard shipping.
- "Member" means a logged-in account with an active membership flag. A logged-in non-member is treated as a non-member. A guest is a non-member.
- Only two shipping methods exist: Standard and Express. Express is available to all shoppers.
- Fees are displayed in USD with two decimal places and are included in the order total.
- Membership status is evaluated at the time the checkout fee is calculated, so changes during checkout (login, membership expiry) are reflected on the next recalculation.
- A subtotal of $0.00 (empty cart) cannot reach checkout, so it is out of scope.

## Test cases

### AC-1: Standard shipping threshold for non-members

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-01 | Subtotal below threshold charges $5.99 | Non-member (guest), cart subtotal $49.99 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $5.99. Order total = subtotal + tax + $5.99. |
| TC-02 | Subtotal exactly at threshold is free | Non-member, cart subtotal $50.00 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $0.00 (or "Free"). Order total excludes any shipping charge. |
| TC-03 | Subtotal above threshold is free | Non-member, cart subtotal $50.01 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $0.00. |
| TC-04 | Large subtotal is free | Non-member, cart subtotal $1,000.00 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $0.00. |
| TC-05 | Minimal subtotal charges $5.99 | Non-member, cart subtotal $0.01 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $5.99. |
| TC-06 | Logged-in non-member is treated as non-member | Logged-in account without membership, subtotal $49.99 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $5.99. |
| TC-07 | Discount dropping subtotal below threshold restores fee | Non-member, subtotal $55.00, 20% promo code available | 1. Go to checkout, select Standard. 2. Confirm fee is $0.00. 3. Apply promo code (subtotal becomes $44.00). | Fee recalculates to $5.99 without page reload or on next render. Order total updates. |
| TC-08 | Removing an item below threshold restores fee | Non-member, two items totalling $60.00 | 1. Go to checkout, select Standard. 2. Remove an item so subtotal is $30.00. | Fee updates to $5.99. |
| TC-09 | Adding an item to cross threshold removes fee | Non-member, subtotal $45.00 | 1. Go to checkout, select Standard, confirm $5.99. 2. Add an item worth $5.00. | Fee updates to $0.00. |
| TC-10 | Tax does not count toward threshold | Non-member, subtotal $48.00 with tax bringing pre-shipping total to $52.00 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $5.99, since the subtotal before tax is below $50.00. |

### AC-2: Members get free standard shipping

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-11 | Member below threshold gets free standard | Logged-in active member, subtotal $10.00 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $0.00. |
| TC-12 | Member at threshold gets free standard | Active member, subtotal $50.00 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $0.00. |
| TC-13 | Member with minimal subtotal gets free standard | Active member, subtotal $0.01 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $0.00. |
| TC-14 | Member fee stays free after discount lowers subtotal | Active member, subtotal $55.00 | 1. Go to checkout, select Standard. 2. Apply promo code reducing subtotal to $20.00. | Shipping fee remains $0.00. |
| TC-15 | Logging in as a member mid-checkout removes fee | Guest, subtotal $30.00 | 1. Go to checkout, select Standard, confirm $5.99. 2. Log in as an active member. | Fee recalculates to $0.00. |
| TC-16 | Expired membership is treated as non-member | Logged-in account whose membership expired yesterday, subtotal $30.00 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $5.99. |

### AC-3: Express shipping pricing

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-17 | Non-member express below threshold | Non-member, subtotal $20.00 | 1. Go to checkout. 2. Select Express shipping. | Shipping fee shows $12.99. |
| TC-18 | Non-member express at or above threshold is still charged | Non-member, subtotal $50.00 | 1. Go to checkout. 2. Select Express shipping. | Shipping fee shows $12.99. The $50 free-shipping rule does not apply to express. |
| TC-19 | Non-member express with large subtotal | Non-member, subtotal $500.00 | 1. Go to checkout. 2. Select Express shipping. | Shipping fee shows $12.99. |
| TC-20 | Member express below threshold | Active member, subtotal $20.00 | 1. Go to checkout. 2. Select Express shipping. | Shipping fee shows $7.99. |
| TC-21 | Member express at or above threshold | Active member, subtotal $50.00 | 1. Go to checkout. 2. Select Express shipping. | Shipping fee shows $7.99. Members do not get free express. |
| TC-22 | Member express with minimal subtotal | Active member, subtotal $0.01 | 1. Go to checkout. 2. Select Express shipping. | Shipping fee shows $7.99. |
| TC-23 | Logging in as a member mid-checkout updates express fee | Guest, subtotal $30.00 | 1. Go to checkout, select Express, confirm $12.99. 2. Log in as an active member. | Fee recalculates to $7.99. |

### Switching between methods

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-24 | Non-member toggles Standard and Express below threshold | Non-member, subtotal $30.00 | 1. Select Standard. 2. Select Express. 3. Select Standard again. | Fee shows $5.99, then $12.99, then $5.99. Order total updates each time. |
| TC-25 | Non-member toggles methods above threshold | Non-member, subtotal $80.00 | 1. Select Standard. 2. Select Express. 3. Select Standard again. | Fee shows $0.00, then $12.99, then $0.00. |
| TC-26 | Member toggles methods | Active member, subtotal $30.00 | 1. Select Standard. 2. Select Express. 3. Select Standard again. | Fee shows $0.00, then $7.99, then $0.00. |
| TC-27 | Default method shows the correct fee on first load | Non-member, subtotal $30.00, Standard is the default method | 1. Go to checkout without selecting a method. | Fee shows $5.99 for the preselected Standard method. No blank or zero placeholder. |

### Persistence and order placement

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-28 | Fee shown at checkout matches placed order | Non-member, subtotal $30.00, Standard selected | 1. Note the fee at checkout. 2. Place the order. 3. Open the order confirmation and order details. | Confirmation and order record show the same $5.99 fee and the same total as checkout. |
| TC-29 | Member express fee persists to order | Active member, subtotal $30.00, Express selected | 1. Place the order. 2. Open order details. | Order shows $7.99 shipping. |
| TC-30 | Fee recalculates on page refresh | Non-member, subtotal $30.00, Standard selected | 1. Go to checkout. 2. Refresh the page. | Fee still shows $5.99 and the selected method is retained. |
| TC-31 | Server rejects tampered fee | Non-member, subtotal $30.00 | 1. Intercept the place-order request. 2. Change the shipping fee to $0.00. 3. Submit. | Server recalculates and either rejects the request or places the order with $5.99. Client-sent fee is not trusted. |

### Display and formatting

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-32 | Fee is formatted with two decimals and currency | Any shopper, any fee | 1. View the shipping line at checkout. | Fee shows as $5.99, $12.99, $7.99, or $0.00 / "Free". Never $5.9 or 5.99 without symbol. |
| TC-33 | Free shipping is clearly labelled | Non-member, subtotal $60.00, Standard selected | 1. View the shipping line. | Shipping line displays "Free" or $0.00 and the order total does not include a hidden charge. |
| TC-34 | Rounding does not create false threshold crossing | Non-member, items priced so the subtotal is $49.995 before rounding | 1. Go to checkout. 2. Select Standard shipping. | Threshold is evaluated on the displayed, rounded subtotal consistently. Fee and displayed subtotal agree (if subtotal displays $50.00, shipping is free; if $49.99, fee is $5.99). |

## Traceability

| AC | Test cases |
|---|---|
| AC-1 | TC-01 to TC-10, TC-24, TC-25, TC-27, TC-28, TC-30, TC-31, TC-34 |
| AC-2 | TC-11 to TC-16, TC-26 |
| AC-3 | TC-17 to TC-23, TC-24 to TC-26, TC-29 |

## Open questions flagged for the product owner

- Whether cart-level promo codes reduce the subtotal used for the threshold (assumed yes).
- Whether gift cards or store credit count as payment or reduce the subtotal (assumed payment, so no effect on shipping).
- Whether express shipping is available for all addresses and item types.
- Whether a membership that lapses between checkout and order placement should honour the fee shown at checkout.
