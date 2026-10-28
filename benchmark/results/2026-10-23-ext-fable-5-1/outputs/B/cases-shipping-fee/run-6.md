# Test Cases: SHIP-9 Shipping fee at checkout

## Assumptions

- "Subtotal" means the sum of item prices after item-level and cart-level discounts, before tax and before the shipping fee. If the team defines subtotal differently, TC-13 and TC-14 need re-evaluation.
- Threshold comparison is inclusive: exactly $50.00 qualifies for free standard shipping (per AC-1 "or more").
- "Member" means a signed-in shopper with an active membership. Guests and signed-in non-members are treated identically.
- Only two shipping methods exist: Standard and Express. Prices are in USD and displayed to two decimal places.
- Express has no free threshold for anyone. Members pay $7.99 for express even at subtotals of $50.00 or more.
- The fee is recalculated whenever the subtotal, membership state, or selected method changes during checkout, and the fee shown at checkout is the fee charged on the order.
- Standard shipping is the default pre-selected method on the checkout page.

## Shipping fee matrix (expected results)

| Shopper | Subtotal | Standard | Express |
|---|---|---|---|
| Non-member | < $50.00 | $5.99 | $12.99 |
| Non-member | ≥ $50.00 | $0.00 (Free) | $12.99 |
| Member | any | $0.00 (Free) | $7.99 |

## Functional test cases

### AC-1: Standard shipping threshold (non-member)

**TC-01 Standard fee below threshold**
Precondition: Guest shopper, cart subtotal $30.00.
Steps: Proceed to checkout, select Standard shipping.
Expected: Shipping fee displays $5.99. Order total = $30.00 + $5.99 + applicable tax.

**TC-02 Standard fee just below threshold (boundary)**
Precondition: Guest shopper, cart subtotal exactly $49.99.
Steps: Proceed to checkout, select Standard.
Expected: Shipping fee $5.99.

**TC-03 Standard fee at threshold (boundary)**
Precondition: Guest shopper, cart subtotal exactly $50.00.
Steps: Proceed to checkout, select Standard.
Expected: Shipping fee $0.00, labelled "Free". No $5.99 charge anywhere in the order summary.

**TC-04 Standard fee just above threshold (boundary)**
Precondition: Guest shopper, cart subtotal exactly $50.01.
Steps: Proceed to checkout, select Standard.
Expected: Shipping fee $0.00 (Free).

**TC-05 Standard fee well above threshold**
Precondition: Guest shopper, cart subtotal $250.00.
Steps: Proceed to checkout, select Standard.
Expected: Shipping fee $0.00 (Free).

**TC-06 Signed-in non-member treated as non-member**
Precondition: Shopper signed in to an account with no active membership, subtotal $20.00.
Steps: Checkout, select Standard.
Expected: Shipping fee $5.99 (same as guest).

### AC-2: Member standard shipping

**TC-07 Member standard, low subtotal**
Precondition: Signed-in member, subtotal $5.00.
Steps: Checkout, select Standard.
Expected: Shipping fee $0.00 (Free).

**TC-08 Member standard, just below threshold**
Precondition: Signed-in member, subtotal $49.99.
Steps: Checkout, select Standard.
Expected: Shipping fee $0.00 (Free).

**TC-09 Member standard, at and above threshold**
Precondition: Signed-in member, subtotal $50.00; repeat with $120.00.
Steps: Checkout, select Standard.
Expected: Shipping fee $0.00 (Free) in both cases.

### AC-3: Express shipping

**TC-10 Non-member express, below threshold**
Precondition: Guest shopper, subtotal $30.00.
Steps: Checkout, select Express.
Expected: Shipping fee $12.99.

**TC-11 Non-member express, at and above threshold**
Precondition: Guest shopper, subtotal $50.00; repeat with $200.00.
Steps: Checkout, select Express.
Expected: Shipping fee $12.99 in both cases. The free-standard threshold does not reduce express.

**TC-12 Member express, below and above threshold**
Precondition: Signed-in member, subtotal $10.00; repeat with $50.00 and $200.00.
Steps: Checkout, select Express.
Expected: Shipping fee $7.99 in all cases.

### Recalculation and state changes

**TC-13 Discount code drops subtotal below threshold**
Precondition: Guest shopper, subtotal $55.00, Standard selected, fee shows Free.
Steps: Apply a $10.00 off coupon.
Expected: Subtotal becomes $45.00 and shipping fee updates to $5.99 without a page reload. Order total reflects both changes.

**TC-14 Discount code brings subtotal exactly to threshold**
Precondition: Guest shopper, subtotal $60.00 with a $10.00 coupon applied.
Steps: Checkout, select Standard.
Expected: Subtotal $50.00, shipping fee Free.

**TC-15 Quantity change crosses threshold upward**
Precondition: Guest shopper, one item at $25.00, Standard selected, fee $5.99.
Steps: Increase quantity to 2 from the checkout page.
Expected: Subtotal $50.00, shipping fee updates to Free.

**TC-16 Item removal crosses threshold downward**
Precondition: Guest shopper, subtotal $65.00, Standard selected, fee Free.
Steps: Remove a $20.00 item.
Expected: Subtotal $45.00, shipping fee updates to $5.99.

**TC-17 Switch between methods**
Precondition: Guest shopper, subtotal $30.00.
Steps: Select Standard, then Express, then Standard again.
Expected: Fee shows $5.99, then $12.99, then $5.99. Order total updates each time. Only one method is selected at a time.

**TC-18 Guest signs in as member mid-checkout**
Precondition: Guest shopper, subtotal $30.00, Standard selected, fee $5.99.
Steps: Sign in to a member account from the checkout page.
Expected: Fee updates to Free without losing the cart. If Express is selected, fee updates from $12.99 to $7.99.

**TC-19 Member signs out mid-checkout**
Precondition: Member signed in, subtotal $30.00, Express selected, fee $7.99.
Steps: Sign out and continue checkout as guest.
Expected: Fee updates to $12.99. Standard would show $5.99.

**TC-20 Expired or cancelled membership**
Precondition: Signed-in account whose membership expired yesterday, subtotal $30.00.
Steps: Checkout, select Standard, then Express.
Expected: Fees are $5.99 and $12.99. No member pricing applied.

**TC-21 Membership purchased in the same cart**
Precondition: Guest shopper with a membership product and a $20.00 item in the cart.
Steps: Checkout, select Standard.
Expected: Documented behaviour. Assumption: membership is not active until the order completes, so fee is $5.99 on a $20.00 + membership-price subtotal, or Free if the membership price pushes the subtotal to $50.00 or more. Flag for product owner confirmation.

### Order integrity

**TC-22 Fee shown equals fee charged**
Precondition: Guest shopper, subtotal $30.00, Standard.
Steps: Complete the order. Check the confirmation page, confirmation email, order history, and the payment captured.
Expected: $5.99 shipping appears consistently across all of them and matches the amount charged.

**TC-23 Free shipping shown as $0.00 across order records**
Precondition: Member, subtotal $30.00, Standard.
Steps: Complete the order and check confirmation, email, and order history.
Expected: Shipping line shows $0.00 or "Free". Total excludes any shipping charge.

**TC-24 Server-side enforcement**
Precondition: Guest shopper, subtotal $30.00.
Steps: Intercept the place-order request and alter the shipping fee to $0.00 or the method to a member rate.
Expected: Server rejects the request or recalculates the correct fee. Order is not created with a tampered fee.

**TC-25 Price change between cart and checkout**
Precondition: Guest shopper, cart subtotal $50.00 built earlier; an item's price is then reduced by $1.00 in the catalog.
Steps: Reload checkout.
Expected: Subtotal shows $49.00 and standard shipping shows $5.99. No stale Free label.

### Edge cases and validation

**TC-26 Rounding near threshold**
Precondition: Cart whose unrounded subtotal is $49.995 (for example, 3 × $16.665 if fractional-cent unit pricing exists).
Steps: Checkout, select Standard.
Expected: Fee decision uses the same rounded subtotal that is displayed. If displayed subtotal is $50.00, shipping is Free; if $49.99, shipping is $5.99. No mismatch between displayed subtotal and fee.

**TC-27 Tax not counted toward threshold**
Precondition: Guest shopper, subtotal $48.00, tax $4.00 (post-tax total $52.00).
Steps: Checkout, select Standard.
Expected: Fee is $5.99. Tax does not lift the subtotal over the threshold.

**TC-28 Shipping fee not counted toward threshold**
Precondition: Guest shopper, subtotal $45.00, Express selected (fee $12.99).
Steps: Switch to Standard.
Expected: Fee is $5.99. The previous express fee is not part of the subtotal.

**TC-29 Gift card or store credit payment**
Precondition: Guest shopper, subtotal $60.00, paying $55.00 with a gift card.
Steps: Checkout, select Standard.
Expected: Fee is Free. Payment method does not change the subtotal used for the threshold.

**TC-30 Empty cart**
Precondition: Guest shopper, no items.
Steps: Attempt to reach checkout.
Expected: Checkout is not reachable, or no shipping fee is displayed. No $5.99 charged on a $0.00 subtotal.

**TC-31 Fee display format**
Precondition: Any shopper, any subtotal.
Steps: Observe the shipping method selector and order summary.
Expected: Fees display as "$5.99", "$12.99", "$7.99", and "Free" or "$0.00" with two decimals and the currency symbol. Member-specific rates are shown only to members.

**TC-32 Member pricing not leaked to non-members**
Precondition: Guest shopper, any subtotal.
Steps: Inspect the shipping options and page source or API response.
Expected: $7.99 express rate is not offered or selectable for a non-member.

### Non-functional and regression checks

**TC-33 Fee updates without full page reload**
Steps: Perform TC-13, TC-15, and TC-17.
Expected: Fee and total update inline within a reasonable time (assumption: under 2 seconds) with no stale values visible.

**TC-34 Concurrent sessions**
Precondition: Same member account open in two browsers, subtotal $30.00.
Steps: Cancel the membership in browser A, then select Express in browser B.
Expected: Browser B shows $12.99 after recalculation, not $7.99.

**TC-35 Accessibility of fee information**
Steps: Navigate the shipping selector with a screen reader and keyboard.
Expected: Each option announces its name and fee, including "Free". Selection changes are announced.

**TC-36 Existing shipping flows unaffected**
Steps: Place one order per row of the fee matrix end to end.
Expected: All six combinations charge the matrix fee. No regressions in address entry, payment, or confirmation.

## Traceability

| AC | Test cases |
|---|---|
| AC-1 | TC-01 to TC-06, TC-13 to TC-16, TC-25 to TC-28, TC-30 |
| AC-2 | TC-07 to TC-09, TC-18 to TC-21, TC-23 |
| AC-3 | TC-10 to TC-12, TC-17 to TC-20, TC-32 |
| Cross-cutting | TC-22, TC-24, TC-29, TC-31, TC-33 to TC-36 |

## Open questions for the product owner

- Does "subtotal" include or exclude discounts, gift wrap, and other add-on charges?
- Is a membership purchased in the same order active for that order's shipping fee (TC-21)?
- Are there any regions, item types, or oversized items excluded from these rates?
