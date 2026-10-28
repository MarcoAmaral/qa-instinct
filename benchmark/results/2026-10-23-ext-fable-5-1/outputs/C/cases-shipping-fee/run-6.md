# Test cases: SHIP-9 Shipping fee at checkout

## Assumptions

- **Subtotal** means the merchandise total after item discounts and coupon codes, before tax, shipping and gift cards. The $50.00 threshold is checked against this value.
- **Member** means a shopper signed in to an account with an active membership. Guests, signed-in non-members and shoppers with a lapsed membership are all non-members.
- Checkout offers exactly two methods, labelled **Standard** and **Express**. **Standard** is selected by default.
- The fee appears on the **Shipping** line of the order summary and is included in **Order total**. A zero fee is shown as **Free**.
- Prices are in USD. The $50.00 check is inclusive: $50.00 qualifies.
- Labels above are assumed; correct them if the checkout page uses different names.

## Shared setup

1. Create one product priced $0.99, one priced $49.99, one priced $50.00 and one priced $50.01.
2. Create a non-member account, a member account and a lapsed-member account.
3. Clear the cart before each case.

## Shared steps for TC-01 to TC-12

1. Sign in as the shopper in the **Shopper** column, or stay signed out for a guest.
2. Add items so the cart subtotal equals the **Subtotal** column.
3. Open checkout.
4. Select the method in the **Method** column.
5. Check the **Shipping** line and **Order total**.

| ID | AC | Shopper | Subtotal | Method | Expected shipping fee |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-1 | Non-member | $0.99 | Standard | $5.99 |
| TC-02 | AC-1 | Non-member | $49.99 | Standard | $5.99 |
| TC-03 | AC-1 | Non-member | $50.00 | Standard | Free |
| TC-04 | AC-1 | Non-member | $50.01 | Standard | Free |
| TC-05 | AC-1 | Guest (signed out) | $49.99 | Standard | $5.99 |
| TC-06 | AC-2 | Member | $0.99 | Standard | Free |
| TC-07 | AC-2 | Member | $49.99 | Standard | Free |
| TC-08 | AC-2 | Member | $50.00 | Standard | Free |
| TC-09 | AC-3 | Non-member | $49.99 | Express | $12.99 |
| TC-10 | AC-3 | Non-member | $50.01 | Express | $12.99 |
| TC-11 | AC-3 | Member | $0.99 | Express | $7.99 |
| TC-12 | AC-3 | Member | $50.01 | Express | $7.99 |

In every row, **Order total** must equal subtotal plus the expected fee plus any tax.

## Behaviour and edge cases

### TC-13: Coupon drops subtotal below the threshold (AC-1)

1. Sign in as a non-member and add the $50.01 product.
2. Open checkout with **Standard** selected. The **Shipping** line shows **Free**.
3. Apply a coupon worth $1.00.

Expected: subtotal becomes $49.01 and the **Shipping** line changes to $5.99 without a page reload.

### TC-14: Cart change crosses the threshold upward (AC-1)

1. Sign in as a non-member and add the $49.99 product.
2. Open checkout. The **Shipping** line shows $5.99.
3. Increase the quantity to 2 from the checkout page.

Expected: subtotal becomes $99.98 and the **Shipping** line changes to **Free**.

### TC-15: Switching methods updates the fee (AC-1, AC-3)

1. Sign in as a non-member and add the $49.99 product.
2. Open checkout. The **Shipping** line shows $5.99.
3. Select **Express**.
4. Select **Standard** again.

Expected: the fee shows $12.99 after step 3 and $5.99 after step 4. **Order total** updates each time.

### TC-16: Signing in as a member during checkout (AC-2, AC-3)

1. As a guest, add the $49.99 product and open checkout. The **Shipping** line shows $5.99.
2. Sign in as a member from the checkout page.
3. Select **Express**.

Expected: the fee shows **Free** after step 2 and $7.99 after step 3.

### TC-17: Lapsed membership is treated as non-member (AC-1, AC-3)

1. Sign in as the lapsed-member account and add the $49.99 product.
2. Open checkout with **Standard** selected.
3. Select **Express**.

Expected: the fee shows $5.99 after step 2 and $12.99 after step 3.

### TC-18: Fee at checkout matches the charged amount (all ACs)

1. Run TC-02, TC-07, TC-09 and TC-11 through to **Place order**.
2. Open each order confirmation page and the matching order in the admin or order history.

Expected: the shipping fee on the confirmation and the recorded order equals the fee shown at checkout.

### TC-19: Fee format (all ACs)

1. Open checkout for any case in the table.

Expected: paid fees show a dollar sign and 2 decimal places, for example $5.99. A zero fee shows the word **Free**, not $0.00.

## Out of scope

- Tax calculation, delivery dates and shipping addresses outside the United States.
- Free-shipping promotions other than the membership benefit.
