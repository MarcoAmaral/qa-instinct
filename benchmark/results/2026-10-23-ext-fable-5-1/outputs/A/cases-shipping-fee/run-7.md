## Test Cases: SHIP-9 Shipping fee at checkout

### Assumptions

- "Subtotal" is the sum of item prices after item-level discounts and promo codes, before tax and before shipping.
- The $50.00 threshold is inclusive: a subtotal of exactly $50.00 qualifies for free standard shipping.
- "Member" means a logged-in account with an active membership. Guests and logged-in non-members are treated identically as non-members.
- Only two shipping methods exist: Standard and Express. Standard is the default selection at checkout.
- All amounts are USD rounded to two decimals. Fees display as `$X.XX` or `Free`.
- Membership status is evaluated at the moment the checkout page loads and re-evaluated if the shopper logs in during checkout.
- Fee is recalculated whenever the subtotal or shipping method changes without a page reload.

### Fee matrix under test

| Shopper | Subtotal | Standard | Express |
|---|---|---|---|
| Non-member | < $50.00 | $5.99 | $12.99 |
| Non-member | ≥ $50.00 | Free | $12.99 |
| Member | any | Free | $7.99 |

---

### AC-1: Standard shipping threshold (non-member)

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-01 | Standard fee below threshold | Guest shopper, cart subtotal $49.99 | 1. Open checkout. 2. Confirm Standard is selected. | Shipping fee shows $5.99. Order total = $49.99 + tax + $5.99. |
| TC-02 | Standard free at exact threshold | Guest shopper, cart subtotal $50.00 | 1. Open checkout. 2. Select Standard. | Shipping fee shows Free ($0.00). |
| TC-03 | Standard free above threshold | Guest shopper, cart subtotal $50.01 | 1. Open checkout. 2. Select Standard. | Shipping fee shows Free. |
| TC-04 | Standard fee at low subtotal | Guest shopper, cart subtotal $0.01 | 1. Open checkout. 2. Select Standard. | Shipping fee shows $5.99. |
| TC-05 | Standard fee at large subtotal | Guest shopper, cart subtotal $999.99 | 1. Open checkout. 2. Select Standard. | Shipping fee shows Free. |
| TC-06 | Logged-in non-member matches guest | Logged-in non-member, subtotal $49.99 | 1. Open checkout. 2. Select Standard. | Shipping fee shows $5.99, identical to TC-01. |
| TC-07 | Subtotal crosses threshold upward | Guest, subtotal $45.00 with Standard selected (fee $5.99) | 1. Increase item quantity so subtotal becomes $52.00. 2. Observe fee. | Fee updates to Free without page reload. |
| TC-08 | Subtotal crosses threshold downward | Guest, subtotal $52.00 with Standard selected (Free) | 1. Remove an item so subtotal becomes $45.00. 2. Observe fee. | Fee updates to $5.99. |
| TC-09 | Promo code drops subtotal below threshold | Guest, subtotal $55.00, Standard selected | 1. Apply a $10 promo code. 2. Observe fee. | Subtotal becomes $45.00 and fee changes to $5.99 (per assumption that discounts reduce subtotal). |
| TC-10 | Tax does not count toward threshold | Guest, subtotal $48.00 where tax brings pre-shipping total above $50.00 | 1. Open checkout. 2. Select Standard. | Fee shows $5.99. Tax is excluded from the threshold check. |

### AC-2: Member standard shipping

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-11 | Member standard free below threshold | Logged-in member, subtotal $10.00 | 1. Open checkout. 2. Select Standard. | Shipping fee shows Free. |
| TC-12 | Member standard free at minimum subtotal | Logged-in member, subtotal $0.01 | 1. Open checkout. 2. Select Standard. | Shipping fee shows Free. |
| TC-13 | Member standard free at threshold | Logged-in member, subtotal $50.00 | 1. Open checkout. 2. Select Standard. | Shipping fee shows Free. |
| TC-14 | Member standard free above threshold | Logged-in member, subtotal $250.00 | 1. Open checkout. 2. Select Standard. | Shipping fee shows Free. |
| TC-15 | Login as member during checkout | Guest, subtotal $20.00, Standard selected (fee $5.99) | 1. Log in as a member from the checkout page. 2. Observe fee. | Fee updates to Free. |
| TC-16 | Expired membership treated as non-member | Logged-in user with expired membership, subtotal $20.00 | 1. Open checkout. 2. Select Standard. | Fee shows $5.99. |

### AC-3: Express shipping

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-17 | Non-member express below threshold | Guest, subtotal $20.00 | 1. Open checkout. 2. Select Express. | Shipping fee shows $12.99. |
| TC-18 | Non-member express at threshold | Guest, subtotal $50.00 | 1. Open checkout. 2. Select Express. | Shipping fee shows $12.99. Free-standard threshold does not apply to Express. |
| TC-19 | Non-member express above threshold | Guest, subtotal $500.00 | 1. Open checkout. 2. Select Express. | Shipping fee shows $12.99. |
| TC-20 | Member express below threshold | Member, subtotal $20.00 | 1. Open checkout. 2. Select Express. | Shipping fee shows $7.99. |
| TC-21 | Member express at threshold | Member, subtotal $50.00 | 1. Open checkout. 2. Select Express. | Shipping fee shows $7.99. |
| TC-22 | Member express above threshold | Member, subtotal $500.00 | 1. Open checkout. 2. Select Express. | Shipping fee shows $7.99. |
| TC-23 | Switch Standard to Express (non-member) | Guest, subtotal $60.00, Standard selected (Free) | 1. Select Express. 2. Observe fee and total. | Fee changes to $12.99 and total increases by $12.99. |
| TC-24 | Switch Express to Standard (member) | Member, subtotal $20.00, Express selected ($7.99) | 1. Select Standard. 2. Observe fee and total. | Fee changes to Free and total decreases by $7.99. |
| TC-25 | Login as member with Express selected | Guest, subtotal $30.00, Express selected ($12.99) | 1. Log in as a member on the checkout page. 2. Observe fee. | Fee updates to $7.99. |

### Order total and persistence

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-26 | Fee carried into placed order | Guest, subtotal $40.00, Standard | 1. Place the order. 2. Open order confirmation and order detail. | Shipping line shows $5.99 on confirmation, order detail, and receipt email. |
| TC-27 | Fee matches displayed value at payment | Member, subtotal $40.00, Express | 1. Proceed to payment. 2. Compare charged amount with checkout summary. | Charged amount includes exactly $7.99 shipping. |
| TC-28 | Backend validates fee independently | Guest, subtotal $40.00 | 1. Submit the checkout request with the shipping fee tampered to $0.00. | Server rejects or recomputes to $5.99. Client-supplied fee is not trusted. |
| TC-29 | Fee is zero for free shipping, not omitted | Member, subtotal $20.00, Standard | 1. Place the order. 2. Inspect order record. | Shipping fee stored as $0.00 and displayed as Free. |

### Negative and edge cases

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-30 | Rounding near threshold | Guest, items summing to $49.995 before rounding | 1. Open checkout. 2. Select Standard. | Subtotal rounds to $50.00 (or $49.99 per the platform's rounding rule) and the fee follows the rounded value consistently. Document observed rule. |
| TC-31 | Membership service unavailable | Member, subtotal $20.00, membership lookup failing | 1. Open checkout. | System degrades safely: either shows non-member pricing with a clear message, or blocks checkout. It must not grant member pricing without verification. |
| TC-32 | Multiple rapid cart changes | Guest, subtotal $45.00, Standard selected | 1. Quickly add and remove items crossing the $50.00 line several times. | Final fee matches the final subtotal. No stale value displayed. |
| TC-33 | Fee display format | Any shopper, any subtotal | 1. Open checkout. 2. Inspect fee for both shipping options. | Paid fees show two decimals with a currency symbol. Free shipping shows Free or $0.00 consistently with the rest of the site. |

### Traceability

| AC | Test cases |
|---|---|
| AC-1 | TC-01 to TC-10, TC-26, TC-28, TC-30, TC-32 |
| AC-2 | TC-11 to TC-16, TC-29, TC-31 |
| AC-3 | TC-17 to TC-25, TC-27 |
