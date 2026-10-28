# Test cases: SHIP-9 Shipping fee at checkout

## Assumptions

- **Subtotal** is the merchandise total after any discount codes and before shipping and tax. A discount that drops the subtotal below $50.00 removes free standard shipping.
- **Member** is a shopper signed in to an account with an active membership. Guests, signed-in shoppers without a membership, and shoppers with an expired membership are **non-members**.
- The $50.00 threshold is inclusive. A subtotal of exactly $50.00 gets free standard shipping.
- Checkout shows two options, **Standard shipping** and **Express shipping**, each with its fee beside it. A zero fee shows as **Free**.
- Fees are in US dollars and do not depend on weight, destination, or item type.
- The shipping fee on the checkout page updates without a page reload when the cart or shipping option changes.
- Fee labels (**Standard shipping**, **Express shipping**, **Free**) are assumed. Correct them to match the checkout page before running.

## Shared setup

- One non-member account, one guest session, one member account with an active membership, and one account with an expired membership.
- Products priced so that subtotals of $0.01, $49.99, $50.00, $50.01, and $150.00 can be reached without discounts.
- One discount code that takes $5.00 off the subtotal.

## Fee matrix

For each row: add items to reach the subtotal, go to checkout, select the shipping option, and read the fee shown beside it and in the order summary.

| ID | AC | Shopper | Subtotal | Option | Expected fee |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-1 | Non-member | $0.01 | Standard | $5.99 |
| TC-02 | AC-1 | Non-member | $49.99 | Standard | $5.99 |
| TC-03 | AC-1 | Non-member | $50.00 | Standard | Free |
| TC-04 | AC-1 | Non-member | $50.01 | Standard | Free |
| TC-05 | AC-1 | Non-member | $150.00 | Standard | Free |
| TC-06 | AC-2 | Member | $0.01 | Standard | Free |
| TC-07 | AC-2 | Member | $49.99 | Standard | Free |
| TC-08 | AC-2 | Member | $50.00 | Standard | Free |
| TC-09 | AC-2 | Member | $150.00 | Standard | Free |
| TC-10 | AC-3 | Non-member | $49.99 | Express | $12.99 |
| TC-11 | AC-3 | Non-member | $50.00 | Express | $12.99 |
| TC-12 | AC-3 | Non-member | $150.00 | Express | $12.99 |
| TC-13 | AC-3 | Member | $0.01 | Express | $7.99 |
| TC-14 | AC-3 | Member | $49.99 | Express | $7.99 |
| TC-15 | AC-3 | Member | $50.00 | Express | $7.99 |
| TC-16 | AC-3 | Member | $150.00 | Express | $7.99 |

TC-11 and TC-12 confirm the free-shipping threshold applies to standard shipping only.

## Behaviour tests

### TC-17: Guest is treated as a non-member (AC-1, AC-3)

1. Start a guest session with no sign-in.
2. Add items to reach a subtotal of $49.99 and go to checkout.
3. Select **Standard shipping**, then **Express shipping**.

Expected: **Standard shipping** shows $5.99 and **Express shipping** shows $12.99.

### TC-18: Expired membership is treated as a non-member (AC-2, AC-3)

1. Sign in with the expired-membership account.
2. Add items to reach a subtotal of $20.00 and go to checkout.
3. Select **Standard shipping**, then **Express shipping**.

Expected: **Standard shipping** shows $5.99 and **Express shipping** shows $12.99.

### TC-19: Fee updates when the subtotal drops below the threshold (AC-1)

1. As a non-member, add items to reach a subtotal of $52.00 and go to checkout.
2. Confirm **Standard shipping** shows **Free**.
3. Remove an item so the subtotal becomes $48.00.

Expected: **Standard shipping** changes to $5.99 without a page reload, and the order total updates.

### TC-20: Fee updates when the subtotal rises to the threshold (AC-1)

1. As a non-member, add items to reach a subtotal of $45.00 and go to checkout.
2. Confirm **Standard shipping** shows $5.99.
3. Add an item so the subtotal becomes $50.00.

Expected: **Standard shipping** changes to **Free**.

### TC-21: Discount code lowers the subtotal below the threshold (AC-1)

1. As a non-member, add items to reach a subtotal of $52.00 and go to checkout.
2. Apply the $5.00 discount code.

Expected: Subtotal shows $47.00 and **Standard shipping** shows $5.99. If the team decides the threshold uses the pre-discount subtotal, change the expected fee to **Free** and update the assumption above.

### TC-22: Switching shipping option updates the fee (AC-1, AC-3)

1. As a non-member, add items to reach a subtotal of $30.00 and go to checkout.
2. Select **Standard shipping**. Confirm the fee shows $5.99.
3. Select **Express shipping**. Confirm the fee shows $12.99.
4. Select **Standard shipping** again.

Expected: The fee returns to $5.99, and the order total matches subtotal plus the selected fee at each step.

### TC-23: Signing in as a member during checkout updates the fee (AC-2, AC-3)

1. As a guest, add items to reach a subtotal of $30.00 and go to checkout.
2. Confirm **Standard shipping** shows $5.99 and **Express shipping** shows $12.99.
3. Sign in with the member account without leaving checkout.

Expected: **Standard shipping** shows **Free** and **Express shipping** shows $7.99.

### TC-24: Order total includes the shipping fee shown (AC-1, AC-3)

1. As a non-member, add items to reach a subtotal of $30.00 and go to checkout.
2. Select **Express shipping**.
3. Read the order summary.

Expected: Order total equals $30.00 plus $12.99 plus any tax shown. The fee in the summary matches the fee beside **Express shipping**.

### TC-25: Fee charged matches the fee shown (AC-1, AC-2, AC-3)

1. Complete an order for each of TC-02, TC-07, TC-10, and TC-13.
2. Open the order confirmation page and the confirmation email for each.

Expected: The shipping fee on the confirmation and the email matches the fee shown at checkout.

## Coverage

| AC | Tests |
| --- | --- |
| AC-1 | TC-01 to TC-05, TC-17, TC-19 to TC-22, TC-24, TC-25 |
| AC-2 | TC-06 to TC-09, TC-18, TC-23, TC-25 |
| AC-3 | TC-10 to TC-16, TC-17, TC-18, TC-22 to TC-25 |
