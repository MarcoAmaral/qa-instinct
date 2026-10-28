# Test Cases — SHIP-9: Shipping fee at checkout

## Assumptions

1. "Subtotal" is the merchandise total after item-level discounts and before tax and shipping. Promo codes applied at cart level are included in the subtotal; whether this is correct should be confirmed with the product owner.
2. "Member" means a shopper logged into an account with an active membership. Guests and logged-in non-members are treated identically as non-members.
3. The $50.00 threshold is inclusive (AC-1 says "or more").
4. Only two shipping methods exist: Standard and Express. Standard is the default selection.
5. The fee is recalculated whenever the subtotal, membership state, or selected method changes while on the checkout page.
6. Currency is USD and amounts are displayed to two decimal places.
7. Free shipping displays as "$0.00" or "Free"; either is acceptable unless the design specifies one.
8. A fee of $12.99 for Express applies regardless of subtotal for non-members (AC-3 gives no threshold).

## Fee matrix (expected results)

| Shopper | Subtotal | Standard | Express |
|---|---|---|---|
| Non-member | < $50.00 | $5.99 | $12.99 |
| Non-member | ≥ $50.00 | $0.00 | $12.99 |
| Member | any | $0.00 | $7.99 |

## Test cases

### AC-1: Standard shipping threshold (non-member)

**TC-01 — Subtotal below threshold charges $5.99**
- Preconditions: Guest shopper. Cart subtotal $25.00. Standard shipping selected.
- Steps: Proceed to checkout. Observe shipping line.
- Expected: Shipping fee shows $5.99. Order total equals subtotal + $5.99 + tax.

**TC-02 — Subtotal exactly $50.00 is free**
- Preconditions: Guest shopper. Cart subtotal exactly $50.00. Standard selected.
- Steps: Proceed to checkout.
- Expected: Shipping fee is $0.00 / Free.

**TC-03 — Subtotal one cent below threshold charges $5.99**
- Preconditions: Guest shopper. Cart subtotal $49.99. Standard selected.
- Steps: Proceed to checkout.
- Expected: Shipping fee is $5.99.

**TC-04 — Subtotal one cent above threshold is free**
- Preconditions: Guest shopper. Cart subtotal $50.01. Standard selected.
- Steps: Proceed to checkout.
- Expected: Shipping fee is $0.00 / Free.

**TC-05 — Large subtotal is free**
- Preconditions: Guest shopper. Cart subtotal $1,000.00. Standard selected.
- Steps: Proceed to checkout.
- Expected: Shipping fee is $0.00 / Free.

**TC-06 — Logged-in non-member behaves as guest**
- Preconditions: Shopper logged in with an account that has no membership. Subtotal $30.00. Standard selected.
- Steps: Proceed to checkout.
- Expected: Shipping fee is $5.99.

**TC-07 — Discount drops subtotal below threshold**
- Preconditions: Guest shopper. Items total $55.00. A promo code worth $10.00 is applied, giving a subtotal of $45.00. Standard selected.
- Steps: Proceed to checkout.
- Expected: Shipping fee is $5.99 (assumption 1). Flag to product owner if the intended behaviour is to use the pre-discount amount.

**TC-08 — Fee updates when cart is edited at checkout**
- Preconditions: Guest shopper. Subtotal $45.00 at checkout, shipping shows $5.99.
- Steps: Increase item quantity so subtotal becomes $60.00. Observe shipping line without reloading.
- Expected: Shipping fee changes to $0.00 / Free. Order total updates accordingly.

**TC-09 — Fee updates when cart drops below threshold**
- Preconditions: Guest shopper. Subtotal $60.00 at checkout, shipping shows Free.
- Steps: Remove an item so subtotal becomes $40.00.
- Expected: Shipping fee changes to $5.99.

**TC-10 — Tax is excluded from the threshold calculation**
- Preconditions: Guest shopper in a taxable region. Subtotal $48.00, estimated tax $4.00 (total before shipping $52.00). Standard selected.
- Steps: Proceed to checkout.
- Expected: Shipping fee is $5.99 because the subtotal, not the taxed total, is compared to $50.00.

### AC-2: Member standard shipping

**TC-11 — Member with small subtotal gets free standard**
- Preconditions: Logged-in member. Subtotal $5.00. Standard selected.
- Steps: Proceed to checkout.
- Expected: Shipping fee is $0.00 / Free.

**TC-12 — Member at $49.99 gets free standard**
- Preconditions: Logged-in member. Subtotal $49.99. Standard selected.
- Steps: Proceed to checkout.
- Expected: Shipping fee is $0.00 / Free.

**TC-13 — Member at or above $50.00 gets free standard**
- Preconditions: Logged-in member. Subtotal $75.00. Standard selected.
- Steps: Proceed to checkout.
- Expected: Shipping fee is $0.00 / Free.

**TC-14 — Guest logs in as member during checkout**
- Preconditions: Guest shopper. Subtotal $30.00. Standard selected. Shipping shows $5.99.
- Steps: Log in as a member from the checkout page.
- Expected: Shipping fee updates to $0.00 / Free without losing cart contents.

**TC-15 — Expired or cancelled membership is not treated as member**
- Preconditions: Logged-in shopper whose membership has expired. Subtotal $30.00. Standard selected.
- Steps: Proceed to checkout.
- Expected: Shipping fee is $5.99.

### AC-3: Express shipping

**TC-16 — Non-member express below threshold**
- Preconditions: Guest shopper. Subtotal $25.00.
- Steps: Select Express at checkout.
- Expected: Shipping fee is $12.99.

**TC-17 — Non-member express at or above threshold**
- Preconditions: Guest shopper. Subtotal $80.00.
- Steps: Select Express at checkout.
- Expected: Shipping fee is $12.99. The $50 free-shipping rule does not apply to Express.

**TC-18 — Member express with small subtotal**
- Preconditions: Logged-in member. Subtotal $10.00.
- Steps: Select Express.
- Expected: Shipping fee is $7.99.

**TC-19 — Member express with large subtotal**
- Preconditions: Logged-in member. Subtotal $200.00.
- Steps: Select Express.
- Expected: Shipping fee is $7.99.

**TC-20 — Switching methods recalculates fee (non-member)**
- Preconditions: Guest shopper. Subtotal $60.00. Standard selected, shipping shows Free.
- Steps: Switch to Express, then back to Standard.
- Expected: Fee shows $12.99 after switching to Express and returns to $0.00 / Free after switching back.

**TC-21 — Switching methods recalculates fee (member)**
- Preconditions: Logged-in member. Subtotal $30.00. Standard selected, shipping shows Free.
- Steps: Switch to Express, then back to Standard.
- Expected: Fee shows $7.99 on Express and $0.00 / Free on Standard.

**TC-22 — Member logs in while Express is selected**
- Preconditions: Guest shopper. Subtotal $30.00. Express selected, shipping shows $12.99.
- Steps: Log in as a member from the checkout page.
- Expected: Shipping fee updates to $7.99.

### Order total and persistence

**TC-23 — Order total includes the displayed shipping fee**
- Preconditions: Guest shopper. Subtotal $20.00. Tax $1.60. Standard selected.
- Steps: Proceed to checkout. Compare the total line.
- Expected: Total is $27.59 ($20.00 + $1.60 + $5.99). The displayed fee and the fee used in the total match.

**TC-24 — Charged amount matches displayed fee**
- Preconditions: Guest shopper. Subtotal $20.00. Express selected.
- Steps: Complete the order. Check the order confirmation and the stored order record.
- Expected: Shipping fee on the confirmation and in the order record is $12.99, matching what was shown at checkout.

**TC-25 — Fee is recalculated server-side at order placement**
- Preconditions: Guest shopper. Subtotal $40.00. Standard selected.
- Steps: Using browser tools, alter the shipping fee value in the place-order request to $0.00. Submit.
- Expected: The server rejects the request or charges $5.99. The client-supplied value is not trusted.

### Edge cases

**TC-26 — Empty cart**
- Preconditions: Guest shopper with no items.
- Steps: Attempt to reach checkout.
- Expected: Checkout is not reachable, or no shipping fee is shown. No error is thrown.

**TC-27 — Subtotal of $0.00 after a 100% discount**
- Preconditions: Guest shopper. Items total $30.00. A promo code makes the subtotal $0.00. Standard selected.
- Steps: Proceed to checkout.
- Expected: Shipping fee is $5.99 (subtotal is below $50.00). Flag to product owner if a fully discounted order should ship free.

**TC-28 — Rounding near the threshold**
- Preconditions: Guest shopper. Three items priced at $16.6666 each, so the raw subtotal is $49.9998 and the displayed subtotal is $50.00. Standard selected.
- Steps: Proceed to checkout.
- Expected: The threshold check uses the same rounded subtotal that is displayed, so shipping is $0.00 / Free. Displayed subtotal and fee are consistent with each other.

**TC-29 — Fee displayed with correct currency formatting**
- Preconditions: Any shopper and method.
- Steps: Observe the shipping line.
- Expected: Fee is shown with a dollar sign and exactly two decimal places (for example, $5.99, $12.99, $7.99, $0.00).

**TC-30 — Fee persists across page refresh**
- Preconditions: Logged-in member. Subtotal $30.00. Express selected, shipping shows $7.99.
- Steps: Refresh the checkout page.
- Expected: Express remains selected and the fee still shows $7.99.

## Traceability

| AC | Test cases |
|---|---|
| AC-1 | TC-01 to TC-10, TC-23, TC-25, TC-27, TC-28 |
| AC-2 | TC-11 to TC-15 |
| AC-3 | TC-16 to TC-22, TC-24, TC-30 |
