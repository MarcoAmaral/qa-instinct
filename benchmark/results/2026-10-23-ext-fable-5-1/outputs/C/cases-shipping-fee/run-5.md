# Test cases: SHIP-9 Shipping fee at checkout

## Assumptions

- **Subtotal** means the total price of items in the cart after item-level discounts, before tax and shipping. Promo codes applied to the whole order are out of scope.
- **Member** means a shopper signed in to an account with an active membership. A guest or a signed-in shopper without membership is a non-member.
- The checkout page shows a **Shipping method** section with two options, **Standard** and **Express**, each with its fee beside it. **Standard** is selected by default.
- Free shipping is shown as **Free**, not **$0.00**. If the product shows **$0.00**, the editor should swap the expected text.
- All prices are in US dollars. The threshold comparison is on the subtotal as shown, rounded to cents.
- The fee shown in the shipping section matches the shipping line in the **Order summary** and the **Order total**.

## Test cases

| ID | Title | Covers | Preconditions | Steps | Expected result |
| --- | --- | --- | --- | --- | --- |
| TC-01 | Standard fee below threshold, non-member | AC-1 | Guest shopper. Cart subtotal $49.99. | 1. Go to checkout. 2. Keep **Standard** selected. | **Standard** shows **$5.99**. Shipping line in **Order summary** shows $5.99. |
| TC-02 | Standard free at exact threshold, non-member | AC-1 | Guest shopper. Cart subtotal $50.00. | 1. Go to checkout. 2. Keep **Standard** selected. | **Standard** shows **Free**. Shipping line shows $0.00 or Free. |
| TC-03 | Standard free above threshold, non-member | AC-1 | Guest shopper. Cart subtotal $50.01. | 1. Go to checkout. 2. Keep **Standard** selected. | **Standard** shows **Free**. |
| TC-04 | Standard fee at low subtotal, non-member | AC-1 | Guest shopper. Cart subtotal $0.01 (lowest-priced item). | 1. Go to checkout. | **Standard** shows **$5.99**. |
| TC-05 | Standard free for member below threshold | AC-2 | Member signed in. Cart subtotal $10.00. | 1. Go to checkout. 2. Keep **Standard** selected. | **Standard** shows **Free**. |
| TC-06 | Standard free for member at threshold | AC-2 | Member signed in. Cart subtotal $50.00. | 1. Go to checkout. | **Standard** shows **Free**. |
| TC-07 | Standard free for member above threshold | AC-2 | Member signed in. Cart subtotal $120.00. | 1. Go to checkout. | **Standard** shows **Free**. |
| TC-08 | Express fee below threshold, non-member | AC-3 | Guest shopper. Cart subtotal $20.00. | 1. Go to checkout. 2. Select **Express**. | **Express** shows **$12.99**. Shipping line and **Order total** update to include $12.99. |
| TC-09 | Express fee above threshold, non-member | AC-3 | Guest shopper. Cart subtotal $80.00. | 1. Go to checkout. 2. Select **Express**. | **Express** shows **$12.99**. Free standard shipping does not reduce the express fee. |
| TC-10 | Express fee for member below threshold | AC-3 | Member signed in. Cart subtotal $20.00. | 1. Go to checkout. 2. Select **Express**. | **Express** shows **$7.99**. |
| TC-11 | Express fee for member above threshold | AC-3 | Member signed in. Cart subtotal $80.00. | 1. Go to checkout. 2. Select **Express**. | **Express** shows **$7.99**. |
| TC-12 | Both options shown with correct fees, non-member | AC-1, AC-3 | Guest shopper. Cart subtotal $30.00. | 1. Go to checkout. 2. Read both options without selecting. | **Standard** shows **$5.99**. **Express** shows **$12.99**. |
| TC-13 | Both options shown with correct fees, member | AC-2, AC-3 | Member signed in. Cart subtotal $30.00. | 1. Go to checkout. 2. Read both options without selecting. | **Standard** shows **Free**. **Express** shows **$7.99**. |
| TC-14 | Fee updates when subtotal crosses threshold | AC-1 | Guest shopper. Cart subtotal $45.00. | 1. Go to checkout. Note **Standard** fee. 2. Return to cart and add an item priced $5.00. 3. Return to checkout. | Step 1 shows **$5.99**. Step 3 shows **Free**. |
| TC-15 | Fee updates when subtotal drops below threshold | AC-1 | Guest shopper. Cart subtotal $55.00 with a $10.00 item. | 1. Go to checkout. Note **Standard** fee. 2. Return to cart and remove the $10.00 item. 3. Return to checkout. | Step 1 shows **Free**. Step 3 shows **$5.99**. |
| TC-16 | Fee updates when shopper signs in as member at checkout | AC-2, AC-3 | Guest shopper. Member account available. Cart subtotal $30.00. | 1. Go to checkout as guest. Note both fees. 2. Sign in to the member account from checkout. | Step 1: **Standard** $5.99, **Express** $12.99. Step 2: **Standard** Free, **Express** $7.99. Cart contents unchanged. |
| TC-17 | Signed-in non-member treated as non-member | AC-1, AC-3 | Shopper signed in with an account that has no membership. Cart subtotal $30.00. | 1. Go to checkout. | **Standard** shows **$5.99**. **Express** shows **$12.99**. |
| TC-18 | Expired membership treated as non-member | AC-2 | Shopper signed in with an expired membership. Cart subtotal $30.00. | 1. Go to checkout. | **Standard** shows **$5.99**. **Express** shows **$12.99**. |
| TC-19 | Switching between options updates total | AC-1, AC-3 | Guest shopper. Cart subtotal $30.00. | 1. Go to checkout. 2. Select **Express**. 3. Select **Standard**. | **Order total** is $30.00 + tax + $12.99 after step 2. It is $30.00 + tax + $5.99 after step 3. |
| TC-20 | Subtotal threshold ignores tax | AC-1 | Guest shopper in a taxed region. Cart subtotal $48.00. Tax brings the total above $50.00. | 1. Go to checkout. | **Standard** shows **$5.99**. Tax does not count toward the threshold. |
| TC-21 | Subtotal threshold uses discounted item prices | AC-1 | Guest shopper. Cart has one item listed at $60.00 with a $15.00 item discount. Subtotal $45.00. | 1. Go to checkout. | **Standard** shows **$5.99**. |
| TC-22 | Fee carried to order confirmation | AC-1 | Guest shopper. Cart subtotal $30.00. Valid payment details. | 1. Go to checkout. 2. Keep **Standard**. 3. Place the order. | Order confirmation shows shipping $5.99 and matches the fee shown at checkout. |

## Out of scope

- Shipping outside the United States and multi-currency display.
- Order-level promo codes and whether they change the subtotal used for the threshold.
- Membership that starts mid-session through a purchase in the same cart.

## Labels assumed

**Shipping method**, **Standard**, **Express**, **Free**, **Order summary**, **Order total**. Correct these to match the checkout page before running the cases.
