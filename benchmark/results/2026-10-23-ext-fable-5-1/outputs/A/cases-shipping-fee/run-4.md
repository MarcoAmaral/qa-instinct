# Test Cases — SHIP-9: Shipping fee at checkout

## Assumptions

- **Subtotal** means the merchandise total after item-level discounts and promo codes but before tax and shipping. If the product defines it differently, the boundary tests (TC-02 to TC-04) still apply at the defined value.
- **Member** means a shopper signed in with an active membership at the time the checkout fee is calculated. Guests and signed-in non-members are treated identically.
- Currency is USD and comparison is at cent precision, so $50.00 qualifies and $49.99 does not.
- Non-member express is $12.99 regardless of subtotal; the $50 threshold applies only to standard shipping.
- Checkout shows both shipping options with their fees, and the order total updates when the selection changes.
- The fee displayed at checkout is the fee charged on the placed order.

## Standard shipping, non-member (AC-1)

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-01 | Standard fee below threshold | Guest or non-member, cart subtotal $20.00 | 1. Go to checkout. 2. Select Standard shipping. | Standard shows $5.99. Order total = $20.00 + $5.99 + tax. |
| TC-02 | Boundary: just below threshold | Non-member, cart subtotal $49.99 | 1. Go to checkout. 2. Select Standard. | Standard shows $5.99. |
| TC-03 | Boundary: exactly at threshold | Non-member, cart subtotal $50.00 | 1. Go to checkout. 2. Select Standard. | Standard shows Free ($0.00). |
| TC-04 | Boundary: just above threshold | Non-member, cart subtotal $50.01 | 1. Go to checkout. 2. Select Standard. | Standard shows Free ($0.00). |
| TC-05 | Large order | Non-member, cart subtotal $500.00 | 1. Go to checkout. 2. Select Standard. | Standard shows Free ($0.00). |
| TC-06 | Promo code drops subtotal below threshold | Non-member, cart subtotal $55.00, valid promo for $10 off | 1. Go to checkout. 2. Apply promo. 3. Select Standard. | Subtotal becomes $45.00. Standard shows $5.99. |
| TC-07 | Promo code raises eligibility is impossible; removing promo restores free shipping | Non-member, state from TC-06 | 1. Remove the promo code. | Subtotal returns to $55.00. Standard shows Free. |
| TC-08 | Fee updates when cart changes at checkout | Non-member, cart subtotal $45.00 | 1. Go to checkout. 2. Increase an item quantity so subtotal is $60.00. 3. Return to checkout. | Standard shows Free. Order total reflects $0.00 shipping. |
| TC-09 | Fee updates when item removed at checkout | Non-member, cart subtotal $60.00 | 1. Go to checkout. 2. Remove an item so subtotal is $40.00. | Standard shows $5.99. |
| TC-10 | Signed-in non-member matches guest | Signed-in account with no membership, subtotal $30.00 | 1. Go to checkout. 2. Select Standard. | Standard shows $5.99, same as guest. |

## Standard shipping, member (AC-2)

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-11 | Member, below threshold | Active member, subtotal $10.00 | 1. Go to checkout. 2. Select Standard. | Standard shows Free ($0.00). |
| TC-12 | Member, boundary just below | Active member, subtotal $49.99 | 1. Go to checkout. 2. Select Standard. | Standard shows Free ($0.00). |
| TC-13 | Member, at and above threshold | Active member, subtotal $50.00, then $120.00 | 1. Go to checkout. 2. Select Standard. 3. Repeat with $120.00 cart. | Standard shows Free in both cases. |
| TC-14 | Member, minimum-value cart | Active member, subtotal $0.01 | 1. Go to checkout. 2. Select Standard. | Standard shows Free. |
| TC-15 | Expired membership treated as non-member | Account whose membership expired yesterday, subtotal $30.00 | 1. Go to checkout. 2. Select Standard. | Standard shows $5.99. |
| TC-16 | Signing in as member during checkout | Guest, subtotal $30.00, Standard shows $5.99 | 1. Sign in as an active member from the checkout page. | Standard updates to Free without re-adding items. |
| TC-17 | Member fee in placed order | Active member, subtotal $30.00 | 1. Select Standard. 2. Place order. 3. View order confirmation and order details. | Shipping line is $0.00 on confirmation, email, and order history. |

## Express shipping (AC-3)

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-18 | Non-member express, below $50 | Non-member, subtotal $20.00 | 1. Go to checkout. 2. Select Express. | Express shows $12.99. Order total = $20.00 + $12.99 + tax. |
| TC-19 | Non-member express, at $50 | Non-member, subtotal $50.00 | 1. Go to checkout. 2. Select Express. | Express shows $12.99. Threshold does not discount express. |
| TC-20 | Non-member express, large order | Non-member, subtotal $500.00 | 1. Go to checkout. 2. Select Express. | Express shows $12.99. |
| TC-21 | Member express, below $50 | Active member, subtotal $20.00 | 1. Go to checkout. 2. Select Express. | Express shows $7.99. |
| TC-22 | Member express, at $50 | Active member, subtotal $50.00 | 1. Go to checkout. 2. Select Express. | Express shows $7.99. |
| TC-23 | Member express, large order | Active member, subtotal $500.00 | 1. Go to checkout. 2. Select Express. | Express shows $7.99. Fee does not drop to free. |
| TC-24 | Expired member express | Membership expired, subtotal $30.00 | 1. Go to checkout. 2. Select Express. | Express shows $12.99. |
| TC-25 | Switching between options recalculates total | Non-member, subtotal $30.00 | 1. Select Standard. 2. Note total. 3. Select Express. 4. Select Standard again. | Total changes $5.99 to $12.99 and back to $5.99. No stale value remains. |
| TC-26 | Both options listed with correct fees side by side | Active member, subtotal $30.00 | 1. Go to checkout. | Shipping options display Standard: Free and Express: $7.99 before any selection. |
| TC-27 | Express fee in placed order | Active member, subtotal $30.00 | 1. Select Express. 2. Place order. | Shipping line is $7.99 on confirmation, email, and order history. |

## Combined matrix

Each cell is the expected shipping fee. Every cell should be covered by at least one test above.

| Subtotal | Non-member Standard | Member Standard | Non-member Express | Member Express |
|---|---|---|---|---|
| $0.01 | $5.99 | $0.00 | $12.99 | $7.99 |
| $49.99 | $5.99 | $0.00 | $12.99 | $7.99 |
| $50.00 | $0.00 | $0.00 | $12.99 | $7.99 |
| $50.01 | $0.00 | $0.00 | $12.99 | $7.99 |
| $500.00 | $0.00 | $0.00 | $12.99 | $7.99 |

## Edge and robustness

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-28 | Rounding does not misclassify threshold | Non-member, items priced so subtotal computes to $49.995 before display rounding | 1. Go to checkout. 2. Select Standard. | Fee is based on the stored cent-precision subtotal consistently with the displayed subtotal. No case where display shows $50.00 but fee is $5.99. |
| TC-29 | Membership lapses mid-session | Active member with membership expiring during checkout session, subtotal $30.00 | 1. Open checkout as member. 2. Let membership expire. 3. Refresh or proceed to payment. | Fee recalculates to $5.99 Standard / $12.99 Express before the order is placed. |
| TC-30 | Fee persists through payment step | Any shopper | 1. Select a shipping option. 2. Proceed to payment. 3. Return to shipping step. | Selected option and fee are unchanged. |
| TC-31 | Server-side fee matches client display | Any shopper | 1. Select shipping. 2. Place order. 3. Inspect order record via API or admin. | Stored shipping fee equals the displayed fee. Client cannot submit a different fee. |
| TC-32 | Tampered shipping fee rejected | Non-member, subtotal $30.00 | 1. Intercept the place-order request. 2. Change shipping fee to $0.00. 3. Submit. | Server recalculates and charges $5.99, or rejects the request. |
| TC-33 | Fee displayed in correct currency format | Any shopper | 1. Go to checkout. | Fees display as $5.99, $12.99, $7.99, or Free/$0.00 with two decimal places. |
