# Test cases: SHIP-9 Shipping fee at checkout

## Assumptions

- **Subtotal** means the sum of item prices after item discounts and promo codes, before tax and shipping.
- A subtotal of exactly $50.00 qualifies for free standard shipping (AC-1 says "or more").
- **Member** means a shopper signed in to an account with an active membership. Guests and signed-in non-members are treated the same.
- Only two shipping methods exist: **Standard** and **Express**. Standard is selected by default.
- All prices are in USD and shown to 2 decimal places. The shipping fee appears on the checkout page next to the selected method and is included in the order total.
- Shipping fee is recalculated whenever the subtotal, the selected method or the member status changes during checkout.

## Test cases

| ID | Title | Preconditions | Steps | Expected result |
| --- | --- | --- | --- | --- |
| TC-01 | Standard fee below threshold (AC-1) | Non-member; cart subtotal $49.99 | 1. Open checkout. 2. Keep **Standard** selected. | Shipping fee shows $5.99. Order total includes $5.99. |
| TC-02 | Standard free at threshold (AC-1, boundary) | Non-member; cart subtotal $50.00 | 1. Open checkout. 2. Keep **Standard** selected. | Shipping fee shows $0.00 (or "Free"). Order total adds no shipping. |
| TC-03 | Standard free above threshold (AC-1) | Non-member; cart subtotal $50.01 | 1. Open checkout. 2. Keep **Standard** selected. | Shipping fee shows $0.00. |
| TC-04 | Standard fee at minimum subtotal (AC-1, boundary) | Non-member; cart subtotal $0.01 | 1. Open checkout. 2. Keep **Standard** selected. | Shipping fee shows $5.99. |
| TC-05 | Promo code drops subtotal below threshold (AC-1) | Non-member; cart subtotal $55.00; promo code worth $10.00 | 1. Open checkout. Confirm fee is $0.00. 2. Apply the promo code. | Subtotal shows $45.00. Shipping fee updates to $5.99 without reloading the page. |
| TC-06 | Adding an item crosses the threshold (AC-1) | Non-member; cart subtotal $45.00 | 1. Open checkout. Confirm fee is $5.99. 2. Return to cart and add a $5.00 item. 3. Return to checkout. | Subtotal shows $50.00. Shipping fee shows $0.00. |
| TC-07 | Member standard free below threshold (AC-2) | Member signed in; cart subtotal $10.00 | 1. Open checkout. 2. Keep **Standard** selected. | Shipping fee shows $0.00. |
| TC-08 | Member standard free at low boundary (AC-2) | Member signed in; cart subtotal $0.01 | 1. Open checkout. 2. Keep **Standard** selected. | Shipping fee shows $0.00. |
| TC-09 | Member standard free above threshold (AC-2) | Member signed in; cart subtotal $120.00 | 1. Open checkout. 2. Keep **Standard** selected. | Shipping fee shows $0.00. |
| TC-10 | Member signs in during checkout (AC-2) | Guest; cart subtotal $20.00 | 1. Open checkout. Confirm fee is $5.99. 2. Sign in as a member. | Shipping fee updates to $0.00. Cart contents are kept. |
| TC-11 | Non-member express below threshold (AC-3) | Non-member; cart subtotal $20.00 | 1. Open checkout. 2. Select **Express**. | Shipping fee shows $12.99. Order total includes $12.99. |
| TC-12 | Non-member express above threshold (AC-3) | Non-member; cart subtotal $200.00 | 1. Open checkout. 2. Select **Express**. | Shipping fee shows $12.99. The $50.00 threshold does not apply to express. |
| TC-13 | Member express below threshold (AC-3) | Member signed in; cart subtotal $20.00 | 1. Open checkout. 2. Select **Express**. | Shipping fee shows $7.99. |
| TC-14 | Member express above threshold (AC-3) | Member signed in; cart subtotal $200.00 | 1. Open checkout. 2. Select **Express**. | Shipping fee shows $7.99. |
| TC-15 | Switch between methods updates fee (AC-1, AC-3) | Non-member; cart subtotal $30.00 | 1. Open checkout with **Standard** selected. 2. Select **Express**. 3. Select **Standard** again. | Fee shows $5.99, then $12.99, then $5.99. Order total changes each time. |
| TC-16 | Both fees shown before selection (AC-1, AC-3) | Non-member; cart subtotal $60.00 | 1. Open checkout. 2. Read the shipping options list. | **Standard** shows $0.00 and **Express** shows $12.99 before either is chosen. |
| TC-17 | Both fees shown for member (AC-2, AC-3) | Member signed in; cart subtotal $60.00 | 1. Open checkout. 2. Read the shipping options list. | **Standard** shows $0.00 and **Express** shows $7.99. |
| TC-18 | Expired membership treated as non-member (AC-2, AC-3) | Signed-in account whose membership has expired; cart subtotal $20.00 | 1. Open checkout. 2. Note the **Standard** fee. 3. Select **Express**. | Standard shows $5.99. Express shows $12.99. |
| TC-19 | Fee matches at order confirmation (all) | Non-member; cart subtotal $49.99; **Express** selected | 1. Complete checkout. 2. Open the order confirmation. | Confirmation shows shipping $12.99 and a total equal to the checkout total. |
| TC-20 | Rounding at the threshold (AC-1) | Non-member; items priced so the subtotal is $49.995 before rounding | 1. Open checkout. 2. Keep **Standard** selected. | Displayed subtotal and fee agree: if the subtotal shows $50.00 the fee is $0.00; if it shows $49.99 the fee is $5.99. |

## Coverage summary

| Acceptance criterion | Test cases |
| --- | --- |
| AC-1 | TC-01 to TC-06, TC-15, TC-16, TC-18, TC-19, TC-20 |
| AC-2 | TC-07 to TC-10, TC-17, TC-18 |
| AC-3 | TC-11 to TC-18, TC-19 |

## Open questions for the product owner

- Does tax count toward the $50.00 subtotal? These tests assume it does not.
- Is the member rate applied by account status alone, or does the shopper also need to select it?
- Are there regions where shipping fees differ? These tests assume one fee table for all addresses.
