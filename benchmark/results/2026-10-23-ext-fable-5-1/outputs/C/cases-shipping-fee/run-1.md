# Test cases: SHIP-9 Shipping fee at checkout

## Assumptions

- **Subtotal** means the sum of item prices after item discounts and promo codes, before tax and shipping. The $50.00 threshold uses this value.
- **Member** means a shopper signed in to an account with an active membership. Everyone else, including signed-in shoppers without a membership and guests, is a **non-member**.
- Non-member express has no free threshold. It costs $12.99 at any subtotal.
- Checkout shows a **Shipping method** section with two options, **Standard** and **Express**, each with its fee beside it. The order summary shows a **Shipping** line and a **Total** line.
- Fees display in USD with 2 decimal places. Free shipping displays as **Free**, not $0.00.
- Changing the cart or the shipping method updates the fee without reloading the page.
- The fee shown at checkout is the fee charged on the order. Order confirmation uses the same value.

## Shared setup

- A product catalog that lets the tester reach exact subtotals, for example items priced $0.01, $5.00, $10.00 and $49.99.
- One non-member account, one guest session, and one active member account.

## AC-1: Standard shipping threshold (non-member)

| ID | Title | Preconditions | Steps | Expected result |
| --- | --- | --- | --- | --- |
| SHIP-9-01 | Standard is $5.99 below threshold | Non-member signed in | 1. Add items with subtotal $49.99. 2. Go to checkout. 3. Select **Standard**. | **Standard** shows **$5.99**. **Shipping** line shows $5.99. **Total** equals subtotal plus tax plus $5.99. |
| SHIP-9-02 | Standard is free at exactly $50.00 | Non-member signed in | 1. Add items with subtotal $50.00. 2. Go to checkout. 3. Select **Standard**. | **Standard** shows **Free**. **Shipping** line shows Free. **Total** equals subtotal plus tax. |
| SHIP-9-03 | Standard is free above threshold | Non-member signed in | 1. Add items with subtotal $50.01. 2. Go to checkout. 3. Select **Standard**. | **Standard** shows **Free**. |
| SHIP-9-04 | Standard is $5.99 at minimum subtotal | Non-member signed in | 1. Add one item priced $0.01. 2. Go to checkout. 3. Select **Standard**. | **Standard** shows **$5.99**. |
| SHIP-9-05 | Guest gets the same standard fee as a non-member | Not signed in | 1. Repeat SHIP-9-01 and SHIP-9-02 as a guest. | Results match SHIP-9-01 and SHIP-9-02. |
| SHIP-9-06 | Fee updates when the cart crosses the threshold | Non-member signed in, cart subtotal $49.99, **Standard** selected at checkout | 1. Increase an item quantity so the subtotal is $50.00 or more. 2. Return to or stay on checkout. | **Standard** changes from $5.99 to **Free** without a page reload. **Total** updates. |
| SHIP-9-07 | Fee updates when the cart drops below the threshold | Non-member signed in, cart subtotal $50.00, **Standard** selected at checkout | 1. Remove an item so the subtotal is below $50.00. | **Standard** changes from Free to **$5.99**. **Total** updates. |
| SHIP-9-08 | Promo code that lowers the subtotal below threshold | Non-member signed in, cart subtotal $55.00, a $10.00 promo code exists | 1. Go to checkout. 2. Select **Standard**. 3. Apply the promo code. | Subtotal shows $45.00. **Standard** shows **$5.99**. See assumption on subtotal. |
| SHIP-9-09 | Tax does not count toward the threshold | Non-member signed in, tax rate greater than 0 for the shipping address | 1. Add items with subtotal $48.00. 2. Enter an address that adds at least $2.00 tax. 3. Select **Standard**. | **Standard** shows **$5.99**. Tax does not raise the subtotal to $50.00. |

## AC-2: Member standard shipping

| ID | Title | Preconditions | Steps | Expected result |
| --- | --- | --- | --- | --- |
| SHIP-9-10 | Member standard is free below threshold | Member signed in | 1. Add items with subtotal $49.99. 2. Go to checkout. 3. Select **Standard**. | **Standard** shows **Free**. |
| SHIP-9-11 | Member standard is free at minimum subtotal | Member signed in | 1. Add one item priced $0.01. 2. Go to checkout. 3. Select **Standard**. | **Standard** shows **Free**. |
| SHIP-9-12 | Member standard is free above threshold | Member signed in | 1. Add items with subtotal $120.00. 2. Go to checkout. 3. Select **Standard**. | **Standard** shows **Free**. |
| SHIP-9-13 | Signing in as a member during checkout removes the fee | Guest, cart subtotal $20.00, at checkout with **Standard** selected showing $5.99 | 1. Sign in with the member account. | **Standard** changes to **Free**. **Total** updates. Cart contents are kept. |
| SHIP-9-14 | Signing out of a member account restores the fee | Member signed in, cart subtotal $20.00, **Standard** showing Free | 1. Sign out. 2. Return to checkout as a guest with the same cart. | **Standard** shows **$5.99**. |
| SHIP-9-15 | Expired membership is treated as non-member | Account whose membership ended before today | 1. Sign in. 2. Add items with subtotal $20.00. 3. Go to checkout. 4. Select **Standard**. | **Standard** shows **$5.99**. |

## AC-3: Express shipping

| ID | Title | Preconditions | Steps | Expected result |
| --- | --- | --- | --- | --- |
| SHIP-9-16 | Non-member express below threshold | Non-member signed in | 1. Add items with subtotal $20.00. 2. Go to checkout. 3. Select **Express**. | **Express** shows **$12.99**. **Shipping** line shows $12.99. |
| SHIP-9-17 | Non-member express at or above threshold | Non-member signed in | 1. Add items with subtotal $50.00. 2. Go to checkout. 3. Select **Express**. | **Express** shows **$12.99**. The free standard threshold does not apply to express. |
| SHIP-9-18 | Guest express | Not signed in | 1. Add items with subtotal $80.00. 2. Go to checkout. 3. Select **Express**. | **Express** shows **$12.99**. |
| SHIP-9-19 | Member express below threshold | Member signed in | 1. Add items with subtotal $20.00. 2. Go to checkout. 3. Select **Express**. | **Express** shows **$7.99**. |
| SHIP-9-20 | Member express at or above threshold | Member signed in | 1. Add items with subtotal $50.00. 2. Go to checkout. 3. Select **Express**. | **Express** shows **$7.99**. Not free. |
| SHIP-9-21 | Member express at minimum subtotal | Member signed in | 1. Add one item priced $0.01. 2. Go to checkout. 3. Select **Express**. | **Express** shows **$7.99**. |
| SHIP-9-22 | Switching between Standard and Express updates the total | Non-member signed in, cart subtotal $20.00, at checkout | 1. Select **Standard**. Note the total. 2. Select **Express**. 3. Select **Standard** again. | Total changes by exactly $7.00 when switching to Express ($12.99 minus $5.99) and returns to the original value. |
| SHIP-9-23 | Member switching methods | Member signed in, cart subtotal $20.00, at checkout | 1. Select **Standard**. 2. Select **Express**. | **Standard** shows Free. **Express** shows $7.99. Total changes by exactly $7.99. |

## Cross-cutting checks

| ID | Title | Preconditions | Steps | Expected result |
| --- | --- | --- | --- | --- |
| SHIP-9-24 | Both options show fees before one is selected | Non-member signed in, cart subtotal $20.00 | 1. Go to checkout. 2. Look at **Shipping method** before selecting an option. | **Standard** shows $5.99 and **Express** shows $12.99 beside their labels. |
| SHIP-9-25 | Charged fee matches displayed fee | Any shopper type | 1. For each of SHIP-9-01, 02, 10, 16 and 19, place the order. 2. Open the order confirmation and the order record. | The shipping fee on the confirmation and in the order record equals the fee shown at checkout. |
| SHIP-9-26 | Fee cannot be changed by editing the request | Non-member signed in, cart subtotal $20.00 | 1. At checkout select **Standard**. 2. Using browser dev tools, change the shipping fee in the place-order request to 0. 3. Submit. | The server recalculates the fee. The order is charged $5.99, or the request is rejected with an error. |
| SHIP-9-27 | Currency and format | Any shopper type | 1. View each fee from the cases above. | Paid fees show as $5.99, $12.99 or $7.99 with 2 decimals. Free shipping shows as **Free**. |
| SHIP-9-28 | Fee persists after page reload | Non-member signed in, cart subtotal $20.00, **Express** selected | 1. Reload the checkout page. | **Express** is still selected and shows $12.99. |

## Summary matrix

| Shopper | Subtotal | Standard | Express |
| --- | --- | --- | --- |
| Non-member or guest | under $50.00 | $5.99 | $12.99 |
| Non-member or guest | $50.00 or more | Free | $12.99 |
| Member | any | Free | $7.99 |

## Out of scope for this story

- Shipping to addresses outside the United States and any surcharge for them.
- Items that cannot ship express, or oversize surcharges.
- Free-shipping promo codes that override the fee.
- Delivery time estimates shown beside each method.
