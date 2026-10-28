# Test Cases — SHIP-9: Shipping fee at checkout

## Assumptions

- **Subtotal** means the merchandise total after any item-level or promo-code discounts, before tax and before shipping. Gift cards and store credit are payment methods and do not reduce the subtotal.
- **Member** means a shopper signed in to an account with an active membership at the moment the checkout page is rendered. Guests and signed-in non-members are treated as non-members.
- Currency is USD. All amounts are shown with two decimal places. The $50.00 threshold is inclusive, per AC-1.
- Two shipping methods exist: Standard and Express. Standard is pre-selected by default.
- The shipping fee recalculates whenever the subtotal, the selected method, or the shopper's membership state changes while on the checkout page.
- The fee shown on the checkout page must match the fee charged on the order confirmation and in the order record.
- Fee rules apply to all destinations supported by the store. No regional surcharges are in scope.

## Fee matrix (expected results used throughout)

| Shopper | Subtotal | Standard | Express |
|---|---|---|---|
| Non-member | < $50.00 | $5.99 | $12.99 |
| Non-member | ≥ $50.00 | $0.00 | $12.99 |
| Member | any | $0.00 | $7.99 |

## Test cases

### AC-1: Standard shipping threshold for non-members

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-01 | Standard fee below threshold | Guest shopper; cart subtotal $25.00 | 1. Go to checkout. 2. Keep Standard selected. | Shipping fee shows $5.99. Order total = subtotal + tax + $5.99. |
| TC-02 | Standard fee at $49.99 (just below threshold) | Guest shopper; cart subtotal exactly $49.99 | 1. Go to checkout. 2. Keep Standard selected. | Shipping fee shows $5.99. |
| TC-03 | Standard free at exactly $50.00 (inclusive boundary) | Guest shopper; cart subtotal exactly $50.00 | 1. Go to checkout. 2. Keep Standard selected. | Shipping fee shows $0.00 (or "Free"). Order total excludes shipping. |
| TC-04 | Standard free at $50.01 (just above threshold) | Guest shopper; cart subtotal exactly $50.01 | 1. Go to checkout. 2. Keep Standard selected. | Shipping fee shows $0.00. |
| TC-05 | Standard free for large subtotal | Guest shopper; cart subtotal $1,250.00 | 1. Go to checkout. | Shipping fee shows $0.00. |
| TC-06 | Signed-in non-member treated the same as guest | Signed-in user with no membership; subtotal $30.00 | 1. Go to checkout. | Standard fee shows $5.99. |
| TC-07 | Promo code drops subtotal below threshold | Guest; subtotal $55.00 before discount; 20% promo code available | 1. Go to checkout, confirm Standard shows $0.00. 2. Apply promo code (subtotal becomes $44.00). | Standard fee updates to $5.99 without a page reload. Total reflects both the discount and the new fee. |
| TC-08 | Removing promo code restores free shipping | Continue from TC-07 | 1. Remove the promo code. | Standard fee returns to $0.00. |
| TC-09 | Promo code lands subtotal exactly at $50.00 | Guest; subtotal $60.00; $10.00-off promo code | 1. Apply promo code at checkout. | Subtotal shows $50.00. Standard fee shows $0.00. |
| TC-10 | Tax does not count toward threshold | Guest; subtotal $48.00; tax rate that produces ≥ $2.00 tax | 1. Go to checkout with a taxable address. | Standard fee shows $5.99 even though subtotal + tax ≥ $50.00. |
| TC-11 | Shipping fee itself does not count toward threshold | Guest; subtotal $45.00 | 1. Go to checkout. 2. Select Express ($12.99). 3. Switch back to Standard. | Standard fee shows $5.99. The Express fee is never added to the subtotal for threshold evaluation. |
| TC-12 | Quantity change crossing threshold upward | Guest; one item at $26.00 in cart | 1. Go to checkout, confirm Standard shows $5.99. 2. Change quantity to 2 (subtotal $52.00). | Standard fee updates to $0.00. |
| TC-13 | Quantity change crossing threshold downward | Guest; two items at $26.00 (subtotal $52.00) | 1. Go to checkout, confirm Standard shows $0.00. 2. Remove one item (subtotal $26.00). | Standard fee updates to $5.99. |
| TC-14 | Gift card payment does not reduce subtotal | Guest; subtotal $45.00; $20.00 gift card | 1. Go to checkout. 2. Apply gift card as payment. | Subtotal remains $45.00. Standard fee stays $5.99. Gift card reduces amount due only. |

### AC-2: Members get free standard shipping

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-15 | Member, low subtotal | Signed-in active member; subtotal $5.00 | 1. Go to checkout. 2. Keep Standard selected. | Standard fee shows $0.00. |
| TC-16 | Member, $49.99 | Signed-in active member; subtotal $49.99 | 1. Go to checkout. | Standard fee shows $0.00. |
| TC-17 | Member, $50.00 | Signed-in active member; subtotal $50.00 | 1. Go to checkout. | Standard fee shows $0.00. |
| TC-18 | Member, high subtotal | Signed-in active member; subtotal $500.00 | 1. Go to checkout. | Standard fee shows $0.00. |
| TC-19 | Member, subtotal reduced by promo to $0.01 | Signed-in member; subtotal $10.00; $9.99-off promo | 1. Apply promo at checkout. | Standard fee shows $0.00. |
| TC-20 | Guest signs in as member during checkout | Guest with subtotal $20.00 on checkout page; member credentials available | 1. Confirm Standard shows $5.99. 2. Sign in as member from checkout. | Standard fee updates to $0.00. Cart contents are preserved. |
| TC-21 | Member signs out during checkout | Member with subtotal $20.00 on checkout page | 1. Confirm Standard shows $0.00. 2. Sign out and return to checkout as guest. | Standard fee shows $5.99. |
| TC-22 | Expired membership is treated as non-member | Signed-in user whose membership expired yesterday; subtotal $20.00 | 1. Go to checkout. | Standard fee shows $5.99. |
| TC-23 | Membership expiring today | Signed-in user whose membership expires at end of today; subtotal $20.00 | 1. Go to checkout before expiry. | Standard fee shows $0.00. (Assumes membership is active through end of its last day.) |
| TC-24 | Membership cancelled but still within paid period | Signed-in user who cancelled auto-renew but paid term has not ended; subtotal $20.00 | 1. Go to checkout. | Standard fee shows $0.00. |
| TC-25 | Member benefit not stacked into a negative fee | Signed-in member; subtotal $60.00 | 1. Go to checkout. | Standard fee shows $0.00, never a negative or credited amount. |

### AC-3: Express shipping

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-26 | Non-member express below threshold | Guest; subtotal $20.00 | 1. Go to checkout. 2. Select Express. | Shipping fee shows $12.99. |
| TC-27 | Non-member express at $50.00 | Guest; subtotal $50.00 | 1. Go to checkout. 2. Select Express. | Shipping fee shows $12.99. The free-standard threshold does not discount Express. |
| TC-28 | Non-member express above threshold | Guest; subtotal $200.00 | 1. Go to checkout. 2. Select Express. | Shipping fee shows $12.99. |
| TC-29 | Member express below threshold | Signed-in member; subtotal $20.00 | 1. Go to checkout. 2. Select Express. | Shipping fee shows $7.99. |
| TC-30 | Member express at $50.00 | Signed-in member; subtotal $50.00 | 1. Go to checkout. 2. Select Express. | Shipping fee shows $7.99. |
| TC-31 | Member express above threshold | Signed-in member; subtotal $200.00 | 1. Go to checkout. 2. Select Express. | Shipping fee shows $7.99. Not $0.00: the free-standard benefit does not apply to Express. |
| TC-32 | Toggle Standard ↔ Express as non-member | Guest; subtotal $20.00 | 1. Select Express. 2. Select Standard. 3. Select Express again. | Fee reads $12.99 → $5.99 → $12.99. Order total updates each time. |
| TC-33 | Toggle Standard ↔ Express as member | Member; subtotal $20.00 | 1. Select Express. 2. Select Standard. 3. Select Express again. | Fee reads $7.99 → $0.00 → $7.99. |
| TC-34 | Express selected, then subtotal crosses threshold | Guest; subtotal $45.00; Express selected | 1. Add an item so subtotal becomes $55.00. | Express fee remains $12.99. Standard option now shows $0.00 as its price. |
| TC-35 | Guest with Express selected signs in as member | Guest; subtotal $30.00; Express selected ($12.99) | 1. Sign in as member from checkout. | Express remains selected and fee updates to $7.99. |
| TC-36 | Both option prices displayed in the shipping picker | Guest; subtotal $30.00 | 1. Open the shipping method picker. | Standard shows $5.99 and Express shows $12.99 side by side before either is chosen. |
| TC-37 | Both option prices displayed for member | Member; subtotal $30.00 | 1. Open the shipping method picker. | Standard shows $0.00/Free and Express shows $7.99. |

### Display, persistence, and order integrity

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-38 | Fee shown in order summary line item | Guest; subtotal $20.00 | 1. Go to checkout. | Order summary contains a distinct "Shipping" line showing $5.99, separate from subtotal, tax, and total. |
| TC-39 | Free shipping label | Member; subtotal $20.00 | 1. Go to checkout. | Shipping line shows $0.00 or "Free" consistently with the rest of the app. It is not blank or hidden. |
| TC-40 | Total arithmetic | Guest; subtotal $20.00; known tax amount | 1. Go to checkout with Standard. 2. Switch to Express. | Total = subtotal + tax + shipping in both cases, correct to the cent. |
| TC-41 | Fee persists through page refresh | Guest; subtotal $20.00; Express selected | 1. Refresh the checkout page. | Express still selected; fee still $12.99. |
| TC-42 | Fee persists through payment step | Guest; subtotal $20.00; Express selected | 1. Proceed to the payment step. 2. Review the final summary. | Shipping shows $12.99 on the review/payment page. |
| TC-43 | Charged amount matches displayed fee | Guest; subtotal $20.00; Standard | 1. Place the order. 2. Check confirmation page, confirmation email, order history, and backend order record. | All four show shipping $5.99 and the same total as checkout displayed. |
| TC-44 | Member order charged correct express fee end to end | Member; subtotal $20.00; Express | 1. Place the order. 2. Check confirmation, email, order history, and backend. | All show shipping $7.99. |
| TC-45 | Fee recalculated server-side at order placement | Guest; subtotal $55.00; Standard ($0.00) | 1. On the checkout page, in a second tab remove an item so subtotal becomes $25.00. 2. Return to the first tab and submit without refreshing. | Order is placed with $5.99 shipping (or user is shown an updated total before confirmation). The stale $0.00 is not honored. |
| TC-46 | Client-side tampering is rejected | Guest; subtotal $20.00 | 1. Intercept the place-order request and set the shipping fee to $0.00. | Server rejects or recomputes to $5.99. The order is never created with a tampered fee. |
| TC-47 | Membership change between checkout load and submit | Member on checkout page with subtotal $20.00; Standard ($0.00) | 1. In another session, cancel/expire the membership. 2. Submit the order. | Server recalculates to $5.99 and either prompts the shopper or charges the correct fee. Not charged $0.00. |
| TC-48 | Rounding and formatting | Guest; subtotal $20.00 | 1. Inspect fees and totals across Standard and Express. | All amounts have exactly two decimals, a currency symbol, and no floating-point artefacts (e.g. $5.99, not $5.9899999). |
| TC-49 | Mobile and desktop parity | Guest; subtotal $20.00 | 1. Run TC-32 on a mobile viewport and on desktop. | Same fees and behavior on both. |
| TC-50 | Accessibility of fee updates | Guest; subtotal $20.00; screen reader enabled | 1. Switch between Standard and Express. | The updated fee and total are announced (live region) and the selected method is exposed to assistive technology. |

### Negative and edge cases

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-51 | Empty cart | Any shopper; empty cart | 1. Navigate directly to checkout. | Checkout is not reachable or shows an empty-cart state. No shipping fee is shown or charged. |
| TC-52 | Subtotal $0.00 after full discount, non-member | Guest; subtotal $20.00; 100% promo code | 1. Apply promo at checkout. | Subtotal $0.00 is below threshold, so Standard shows $5.99 and Express $12.99. (Assumption: physical goods still ship and incur the fee.) |
| TC-53 | Subtotal $0.01 | Guest; single item priced $0.01 | 1. Go to checkout. | Standard $5.99, Express $12.99. |
| TC-54 | Multiple shipments / split order | Guest; subtotal $60.00 with items from two warehouses | 1. Go to checkout. | A single Standard fee of $0.00 is applied to the order. The fee is not charged per shipment. (Assumption: fee is per order.) |
| TC-55 | Fee rule service unavailable | Guest; subtotal $20.00; shipping-rate service mocked to fail | 1. Go to checkout. | A clear error or retry is shown. The shopper cannot place an order with a missing or $0.00 fee by default. |
| TC-56 | Concurrent membership purchase in same session | Guest; subtotal $20.00 on checkout | 1. Purchase a membership in another tab. 2. Return and refresh checkout. | Standard shows $0.00 and Express $7.99. |
| TC-57 | Back-navigation after changing method | Guest; subtotal $20.00 | 1. Select Express. 2. Go to payment. 3. Use browser back. 4. Select Standard. 5. Go forward. | Payment page shows $5.99, not the stale $12.99. |
| TC-58 | Non-USD locale display | Store configured for en-GB locale display, USD pricing | 1. Go to checkout. | Fees still evaluate against $50.00 USD and display correctly for the locale. (Out of scope if the store is USD-only; note and skip.) |

### Automated unit-level checks (fee calculator)

| ID | Input (isMember, subtotal, method) | Expected fee |
|---|---|---|
| UT-01 | false, 0.00, Standard | 5.99 |
| UT-02 | false, 49.99, Standard | 5.99 |
| UT-03 | false, 50.00, Standard | 0.00 |
| UT-04 | false, 50.01, Standard | 0.00 |
| UT-05 | true, 0.00, Standard | 0.00 |
| UT-06 | true, 49.99, Standard | 0.00 |
| UT-07 | true, 50.00, Standard | 0.00 |
| UT-08 | false, 49.99, Express | 12.99 |
| UT-09 | false, 50.00, Express | 12.99 |
| UT-10 | true, 49.99, Express | 7.99 |
| UT-11 | true, 50.00, Express | 7.99 |
| UT-12 | false, 49.995 (rounds to 50.00), Standard | Per rounding rule; assert subtotal is rounded to cents before comparison and fee is 0.00 |
| UT-13 | false, negative subtotal, Standard | Rejected or treated as 0.00 → 5.99; must not throw unhandled |
| UT-14 | any, any, unknown method | Validation error; no fee returned |

## Traceability

| AC | Test cases |
|---|---|
| AC-1 | TC-01–TC-14, TC-34, TC-45, TC-52, TC-53, UT-01–UT-04 |
| AC-2 | TC-15–TC-25, TC-20, TC-35, TC-47, TC-56, UT-05–UT-07 |
| AC-3 | TC-26–TC-37, TC-44, UT-08–UT-11 |
| Cross-cutting | TC-38–TC-51, TC-54–TC-58, UT-12–UT-14 |

## Open questions to confirm with product (assumptions used in the meantime)

1. Is the subtotal evaluated before or after promo-code discounts? Assumed after.
2. Is membership evaluated at checkout render or at order submission? Assumed both, with server-side recalculation at submission.
3. Does a fully discounted ($0.00) physical order still incur the standard fee? Assumed yes.
4. Is the shipping fee per order or per shipment for split orders? Assumed per order.
5. Should "Free" or "$0.00" be displayed? Assumed either is acceptable if consistent.
