# Test cases: SHIP-9 Shipping fee at checkout

## Assumptions

- **Subtotal** means the sum of item prices in the cart after item discounts and promo codes, before tax and before shipping. The threshold check uses this value.
- **Member** means a shopper who is signed in and whose membership is active. Guests and signed-in non-members are treated the same.
- The checkout page offers exactly 2 options: **Standard** and **Express**. **Standard** is selected by default.
- A free fee shows as **Free** on the **Shipping** line and adds $0.00 to the order total.
- All prices are in USD, and the threshold is compared to the cent, so $49.99 is below and $50.00 is at the threshold.
- The fee recalculates on the checkout page whenever the cart or the shipping option changes, with no page reload.
- An expired or cancelled membership counts as non-member.

## Test data

| Account | Membership |
| --- | --- |
| guest | Not signed in |
| nonmember@example.com | Signed in, no membership |
| member@example.com | Signed in, active membership |
| expired@example.com | Signed in, membership expired yesterday |

## Standard shipping, non-member (AC-1)

| ID | Subtotal | Expected **Shipping** line | Expected effect on total |
| --- | --- | --- | --- |
| SHIP-9-01 | $0.01 | $5.99 | +$5.99 |
| SHIP-9-02 | $25.00 | $5.99 | +$5.99 |
| SHIP-9-03 | $49.99 | $5.99 | +$5.99 |
| SHIP-9-04 | $50.00 | Free | +$0.00 |
| SHIP-9-05 | $50.01 | Free | +$0.00 |
| SHIP-9-06 | $500.00 | Free | +$0.00 |

Steps for each row:

1. As **guest**, add items so the cart subtotal equals the value in the row.
2. Go to checkout.
3. Confirm **Standard** is selected.
4. Check the **Shipping** line and the order total.

Repeat SHIP-9-03 and SHIP-9-04 as **nonmember@example.com** (SHIP-9-07, SHIP-9-08). Expected results are the same as for guest.

## Standard shipping, member (AC-2)

| ID | Account | Subtotal | Expected **Shipping** line |
| --- | --- | --- | --- |
| SHIP-9-09 | member@example.com | $0.01 | Free |
| SHIP-9-10 | member@example.com | $49.99 | Free |
| SHIP-9-11 | member@example.com | $50.00 | Free |
| SHIP-9-12 | expired@example.com | $49.99 | $5.99 |

Steps for each row:

1. Sign in as the account in the row.
2. Add items so the cart subtotal equals the value in the row.
3. Go to checkout with **Standard** selected.
4. Check the **Shipping** line and the order total.

## Express shipping (AC-3)

| ID | Account | Subtotal | Expected **Shipping** line |
| --- | --- | --- | --- |
| SHIP-9-13 | guest | $25.00 | $12.99 |
| SHIP-9-14 | guest | $49.99 | $12.99 |
| SHIP-9-15 | guest | $50.00 | $12.99 |
| SHIP-9-16 | nonmember@example.com | $500.00 | $12.99 |
| SHIP-9-17 | member@example.com | $0.01 | $7.99 |
| SHIP-9-18 | member@example.com | $49.99 | $7.99 |
| SHIP-9-19 | member@example.com | $50.00 | $7.99 |
| SHIP-9-20 | expired@example.com | $50.00 | $12.99 |

Steps for each row:

1. Sign in as the account in the row, or stay signed out for guest.
2. Add items so the cart subtotal equals the value in the row.
3. Go to checkout.
4. Select **Express**.
5. Check the **Shipping** line and the order total.

Note for SHIP-9-15 and SHIP-9-19: the free-shipping threshold must not reduce the express fee.

## Fee updates when the shopper changes something

**SHIP-9-21: Switching between options updates the fee**

1. As **guest** with a $25.00 subtotal, go to checkout.
2. Confirm the **Shipping** line shows $5.99.
3. Select **Express**.
4. Confirm the **Shipping** line shows $12.99 and the total rises by $7.00.
5. Select **Standard**.
6. Confirm the **Shipping** line shows $5.99 again.

**SHIP-9-22: Crossing the threshold upward updates the fee**

1. As **guest** with a $45.00 subtotal, go to checkout with **Standard** selected.
2. Confirm the **Shipping** line shows $5.99.
3. From checkout, raise the quantity of an item so the subtotal becomes $50.00 or more.
4. Confirm the **Shipping** line shows **Free** without a page reload.

**SHIP-9-23: Crossing the threshold downward updates the fee**

1. As **guest** with a $55.00 subtotal, go to checkout with **Standard** selected.
2. Confirm the **Shipping** line shows **Free**.
3. Remove an item so the subtotal drops to $49.99 or less.
4. Confirm the **Shipping** line shows $5.99.

**SHIP-9-24: Signing in as a member at checkout updates the fee**

1. As **guest** with a $25.00 subtotal, go to checkout with **Standard** selected.
2. Confirm the **Shipping** line shows $5.99.
3. Sign in as **member@example.com** without leaving checkout.
4. Confirm the **Shipping** line shows **Free**.

**SHIP-9-25: A promo code that drops the subtotal below the threshold removes free shipping**

1. As **guest** with a $52.00 subtotal, go to checkout with **Standard** selected.
2. Confirm the **Shipping** line shows **Free**.
3. Apply a promo code worth $5.00 off.
4. Confirm the subtotal shows $47.00 and the **Shipping** line shows $5.99.

This case depends on the subtotal assumption above. If the product owner decides the threshold uses the pre-discount subtotal, the expected result in step 4 changes to **Free**.

## Fee is carried through to the order

**SHIP-9-26: The placed order charges the fee shown at checkout**

1. As **guest** with a $25.00 subtotal, select **Express** and place the order.
2. Open the order confirmation page and the confirmation email.
3. Confirm both show a shipping fee of $12.99 and a total that includes it.

**SHIP-9-27: Tax is not counted toward the threshold**

1. As **guest**, add items with a subtotal of $48.00 to a tax-charging address so that subtotal plus tax exceeds $50.00.
2. Go to checkout with **Standard** selected.
3. Confirm the **Shipping** line shows $5.99.

## Out of scope for this story

- Shipping to addresses outside the United States.
- Carts that contain only items that do not ship, such as gift cards.
- Membership that starts or ends during the checkout session.

Each of these should get its own story before it is tested.
