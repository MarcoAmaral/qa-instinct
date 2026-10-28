# Test Cases: SHIP-9 Shipping Fee at Checkout

## Assumptions

- **Subtotal** means the sum of item prices after any promo/coupon discounts and before tax and shipping. If the implementation uses pre-discount subtotal, tests TC-12 and TC-13 must be re-expected.
- **Member** means a shopper logged in to an account with active membership status. Guests and logged-in non-members are both "non-members."
- **Express shipping** has no free threshold for anyone; AC-1's $50 rule applies to standard shipping only.
- The shipping fee is displayed on the checkout page and is included in the order total.
- Currency is USD, displayed to two decimals.
- Only standard and express options exist in scope.
- Shipping fee is recalculated whenever the subtotal, shipping method, or membership status changes during checkout.

## Fee Matrix (expected results)

| Shopper | Subtotal | Standard | Express |
|---|---|---|---|
| Non-member | < $50.00 | $5.99 | $12.99 |
| Non-member | ≥ $50.00 | $0.00 | $12.99 |
| Member | any | $0.00 | $7.99 |

## Functional Test Cases

| ID | Title | AC | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|---|
| TC-01 | Non-member, standard, subtotal below threshold | AC-1 | Guest shopper; cart subtotal $30.00 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $5.99. Order total = $30.00 + tax + $5.99. | High |
| TC-02 | Non-member, standard, subtotal exactly at threshold | AC-1 | Guest shopper; cart subtotal $50.00 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $0.00 / "Free". | High |
| TC-03 | Non-member, standard, one cent below threshold | AC-1 | Guest shopper; cart subtotal $49.99 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $5.99. | High |
| TC-04 | Non-member, standard, one cent above threshold | AC-1 | Guest shopper; cart subtotal $50.01 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $0.00 / "Free". | High |
| TC-05 | Non-member, standard, large subtotal | AC-1 | Guest shopper; cart subtotal $1,250.00 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $0.00 / "Free". | Medium |
| TC-06 | Logged-in non-member treated same as guest | AC-1 | Logged-in account without membership; subtotal $30.00 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $5.99 (no member benefit applied). | High |
| TC-07 | Member, standard, subtotal below threshold | AC-2 | Logged-in member; subtotal $10.00 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $0.00 / "Free". | High |
| TC-08 | Member, standard, subtotal at threshold | AC-2 | Logged-in member; subtotal $50.00 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $0.00 / "Free". | Medium |
| TC-09 | Member, standard, minimal subtotal | AC-2 | Logged-in member; subtotal $0.01 (lowest-priced item) | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $0.00 / "Free". | Medium |
| TC-10 | Non-member, express, subtotal below threshold | AC-3 | Guest shopper; subtotal $30.00 | 1. Go to checkout. 2. Select Express shipping. | Shipping fee shows $12.99. | High |
| TC-11 | Non-member, express, subtotal at/above threshold | AC-3 | Guest shopper; subtotal $50.00 | 1. Go to checkout. 2. Select Express shipping. | Shipping fee shows $12.99 (free threshold does not apply to express). | High |
| TC-12 | Member, express, subtotal below threshold | AC-3 | Logged-in member; subtotal $30.00 | 1. Go to checkout. 2. Select Express shipping. | Shipping fee shows $7.99. | High |
| TC-13 | Member, express, subtotal at/above threshold | AC-3 | Logged-in member; subtotal $200.00 | 1. Go to checkout. 2. Select Express shipping. | Shipping fee shows $7.99 (not free, not $12.99). | High |
| TC-14 | Switching shipping method recalculates fee | AC-1, AC-3 | Guest shopper; subtotal $30.00 | 1. Go to checkout. 2. Select Standard. 3. Switch to Express. 4. Switch back to Standard. | Fee updates $5.99 → $12.99 → $5.99; order total updates each time. | High |
| TC-15 | Fee recalculates when subtotal crosses threshold upward | AC-1 | Guest shopper; subtotal $45.00; Standard selected | 1. Go to checkout. 2. Return to cart and add a $5.00 item (subtotal $50.00). 3. Return to checkout. | Standard fee changes from $5.99 to $0.00. | High |
| TC-16 | Fee recalculates when subtotal crosses threshold downward | AC-1 | Guest shopper; subtotal $55.00; Standard selected | 1. Go to checkout. 2. Remove an item so subtotal becomes $49.99. 3. Return to checkout. | Standard fee changes from $0.00 to $5.99. | High |
| TC-17 | Discount code drops subtotal below threshold | AC-1 (assumption) | Guest shopper; subtotal $55.00; Standard selected | 1. Go to checkout. 2. Apply 20% promo code (subtotal $44.00). | Standard fee becomes $5.99. If product rule uses pre-discount subtotal, expected is $0.00; flag to PO. | High |
| TC-18 | Discount code brings subtotal exactly to threshold | AC-1 (assumption) | Guest shopper; subtotal $60.00; $10 off code | 1. Go to checkout. 2. Apply $10 off code (subtotal $50.00). | Standard fee is $0.00. | Medium |
| TC-19 | Logging in as member mid-checkout applies member pricing | AC-2, AC-3 | Guest with subtotal $30.00; Standard selected ($5.99 shown) | 1. At checkout, log in as a member. 2. Observe fee. 3. Switch to Express. | Standard fee updates to $0.00; Express shows $7.99. | High |
| TC-20 | Logging in as non-member mid-checkout keeps non-member pricing | AC-1 | Guest with subtotal $30.00 | 1. At checkout, log in as a non-member account. | Standard fee remains $5.99; Express $12.99. | Medium |
| TC-21 | Expired/cancelled membership treated as non-member | AC-2, AC-3 | Account whose membership expired yesterday; subtotal $30.00 | 1. Go to checkout. 2. Check Standard and Express fees. | Standard $5.99; Express $12.99. | High |
| TC-22 | Membership activated same day is recognized | AC-2 | Account that purchased membership moments ago; subtotal $30.00 | 1. Go to checkout. 2. Check Standard and Express fees. | Standard $0.00; Express $7.99. | Medium |
| TC-23 | Tax excluded from threshold calculation | AC-1 (assumption) | Guest; subtotal $48.00; tax rate makes subtotal + tax ≥ $50.00 | 1. Go to checkout with a taxable address. 2. Select Standard. | Standard fee is $5.99 (threshold uses pre-tax subtotal). | High |
| TC-24 | Shipping fee itself excluded from threshold | AC-1 | Guest; subtotal $45.00 | 1. Go to checkout. 2. Select Express ($12.99). 3. Switch to Standard. | Standard fee is $5.99; prior express fee does not count toward subtotal. | Medium |
| TC-25 | Free shipping shown in order summary and total | AC-1, AC-2 | Member; subtotal $30.00 | 1. Go to checkout. 2. Select Standard. 3. Review order summary. | Shipping line reads $0.00 or "Free"; grand total excludes any shipping charge. | High |
| TC-26 | Fee at checkout matches fee on placed order | All | Guest; subtotal $30.00; Express selected | 1. Complete the order. 2. View order confirmation page and email. 3. Check order record in admin/back office. | All show shipping $12.99; totals consistent across checkout, confirmation, email, and order record. | High |
| TC-27 | Server-side validation of shipping fee | All | Guest; subtotal $30.00; browser dev tools | 1. At checkout, modify the client-side shipping fee value (e.g., set to 0.00) in the request. 2. Submit order. | Server rejects or recalculates to $5.99; order is not placed with a tampered fee. | High |
| TC-28 | Membership status cannot be spoofed client-side | AC-2 | Guest; subtotal $30.00; browser dev tools | 1. Modify client request to indicate member status. 2. Submit order with Standard. | Server charges $5.99; member benefit not granted. | High |
| TC-29 | Multi-quantity items counted in subtotal | AC-1 | Guest; 5 × $10.00 item | 1. Go to checkout. 2. Select Standard. | Subtotal $50.00; Standard fee $0.00. | Medium |
| TC-30 | Rounding does not create off-by-one-cent errors | AC-1 | Guest; items priced to produce subtotal $49.995 if unrounded (e.g., 3 × $16.665 where supported) | 1. Go to checkout. 2. Select Standard. | Subtotal displayed to two decimals; fee rule applied to the displayed/rounded subtotal consistently. Document observed behavior. | Low |
| TC-31 | Default shipping method on first load shows correct fee | AC-1 | Guest; subtotal $30.00 | 1. Go to checkout without selecting a method. | Default method (assumed Standard) is preselected with $5.99 displayed; no blank or $0.00 placeholder. | Medium |
| TC-32 | Fee persists through page refresh | AC-3 | Member; subtotal $30.00; Express selected | 1. Refresh checkout page. | Express still selected; fee still $7.99. | Low |
| TC-33 | Fee correct when checkout opened in two tabs with cart change | AC-1 | Guest; subtotal $45.00 | 1. Open checkout in Tab A. 2. In Tab B, add $10 item. 3. In Tab A, proceed to place order. | Order uses current subtotal $55.00 and Standard fee $0.00 (or Tab A refreshes to show updated fee before placing). | Low |
| TC-34 | Currency format of fee | All | Guest; subtotal $30.00 | 1. Go to checkout. 2. Inspect Standard and Express fees. | Fees shown as $5.99 and $12.99 with currency symbol and two decimals. | Low |
| TC-35 | Accessibility of shipping fee display | All | Screen reader enabled | 1. Navigate shipping options at checkout. | Each option announces method name and fee (e.g., "Standard shipping, $5.99"); free shipping announced as free/$0.00. | Medium |

## Negative / Edge Cases

| ID | Title | Steps | Expected Result | Priority |
|---|---|---|---|---|
| TC-36 | Empty cart at checkout | Navigate directly to checkout URL with empty cart. | Checkout blocked or redirected to cart; no shipping fee computed or displayed. | Medium |
| TC-37 | Membership service unavailable | Simulate membership lookup failure; logged-in member with subtotal $30.00 proceeds to checkout. | System fails safe with a defined behavior (assumed: treat as non-member and show $5.99 / $12.99, with error logged) and does not crash. Confirm behavior with PO. | Medium |
| TC-38 | Shipping rate configuration missing | Simulate missing rate config for Express. | Checkout shows a clear error or hides Express; does not display $0.00 or NaN. | Low |
| TC-39 | Negative or zero subtotal after 100% discount | Apply a 100% off code to a $30.00 cart (subtotal $0.00) as guest. | Standard fee $5.99 (subtotal below $50); order total = $5.99 + tax. Confirm with PO whether shipping should be charged on $0 merchandise. | Low |

## Regression / Out-of-Scope Notes

- Verify existing checkout flows (payment, address validation, tax) are unaffected by fee changes.
- Not covered: international shipping, multiple shipping addresses, split shipments, gift cards affecting subtotal, and shipping-method availability by region. These need separate stories.

## Open Questions for Product Owner (tests proceed on stated assumptions)

1. Is the $50.00 threshold evaluated on pre- or post-discount subtotal? (Affects TC-17, TC-18.)
2. Should a $0.00 subtotal order (full discount) still incur shipping? (TC-39.)
3. What is the fail-safe behavior when membership status cannot be determined? (TC-37.)
4. Is Standard the default preselected method? (TC-31.)
