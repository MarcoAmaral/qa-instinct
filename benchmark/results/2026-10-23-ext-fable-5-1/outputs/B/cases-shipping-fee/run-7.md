# Test Cases — SHIP-9: Shipping fee at checkout

## Assumptions

1. **Subtotal** means the sum of item prices in the cart after item-level and cart-level promotional discounts, but **before** tax, shipping, and gift-card payments. The $50.00 threshold is compared against this value.
2. **Member** means a shopper who is signed in and whose membership is active at the time the checkout page loads. Guests, signed-in non-members, and shoppers with expired or cancelled memberships are treated as non-members.
3. Only two shipping methods exist: **Standard** and **Express**. Currency is USD with two-decimal precision.
4. The shipping fee is displayed in the checkout order summary, and the order total equals subtotal + tax + shipping fee. The fee recalculates whenever the subtotal or selected method changes without a full page reload being required.
5. A free fee is displayed as **"Free"** (or $0.00); the exact label is not specified, so tests accept either but require consistency.
6. Non-members never receive free Express shipping, regardless of subtotal.
7. The threshold comparison is inclusive: exactly $50.00 qualifies for free Standard shipping.
8. Checkout cannot be reached with an empty cart, so a $0.00 subtotal is tested only via a 100% discount code.

## Test data

| Label | Subtotal | Notes |
|---|---|---|
| S-LOW | $10.00 | Clearly below threshold |
| S-JUST-BELOW | $49.99 | One cent below threshold |
| S-AT | $50.00 | Exactly at threshold |
| S-JUST-ABOVE | $50.01 | One cent above threshold |
| S-HIGH | $250.00 | Clearly above threshold |
| S-ZERO | $0.00 | Achieved via 100% discount code |

Accounts: `GUEST` (not signed in), `NONMEMBER` (signed in, never a member), `MEMBER` (signed in, active membership), `EXPIRED` (signed in, membership lapsed yesterday).

## Fee matrix (expected results)

| Shopper | Subtotal | Standard | Express |
|---|---|---|---|
| Non-member | < $50.00 | $5.99 | $12.99 |
| Non-member | ≥ $50.00 | Free | $12.99 |
| Member | any | Free | $7.99 |

---

## AC-1: Standard shipping threshold (non-members)

| ID | Title | Preconditions | Steps | Expected result | Priority |
|---|---|---|---|---|---|
| TC-01 | Standard fee below threshold | NONMEMBER, cart = S-LOW | 1. Go to checkout. 2. Select Standard. | Shipping fee shows **$5.99**. Order total includes $5.99. | High |
| TC-02 | Standard fee one cent below threshold | NONMEMBER, cart = S-JUST-BELOW | 1. Go to checkout. 2. Select Standard. | Shipping fee shows **$5.99**. | High |
| TC-03 | Standard free at exact threshold | NONMEMBER, cart = S-AT | 1. Go to checkout. 2. Select Standard. | Shipping fee shows **Free / $0.00**. Order total excludes any shipping charge. | High |
| TC-04 | Standard free one cent above threshold | NONMEMBER, cart = S-JUST-ABOVE | 1. Go to checkout. 2. Select Standard. | Shipping fee shows **Free / $0.00**. | High |
| TC-05 | Standard free well above threshold | NONMEMBER, cart = S-HIGH | 1. Go to checkout. 2. Select Standard. | Shipping fee shows **Free / $0.00**. | Medium |
| TC-06 | Guest shopper treated as non-member (below) | GUEST, cart = S-LOW | 1. Go to checkout. 2. Select Standard. | Shipping fee shows **$5.99**. | High |
| TC-07 | Guest shopper treated as non-member (at threshold) | GUEST, cart = S-AT | 1. Go to checkout. 2. Select Standard. | Shipping fee shows **Free / $0.00**. | High |
| TC-08 | Fee recalculates when quantity crosses threshold upward | NONMEMBER, cart = one $25.00 item, Standard selected | 1. Go to checkout; confirm $5.99. 2. Increase quantity to 2 (subtotal $50.00). | Fee updates to **Free** without manual refresh. Order total updates accordingly. | High |
| TC-09 | Fee recalculates when item removal crosses threshold downward | NONMEMBER, cart = $30.00 + $25.00 items, Standard selected | 1. Go to checkout; confirm Free. 2. Remove the $25.00 item. | Fee updates to **$5.99**. Order total updates accordingly. | High |
| TC-10 | Discount code drops subtotal below threshold | NONMEMBER, cart = $55.00, Standard selected | 1. Go to checkout; confirm Free. 2. Apply a $10.00-off code (subtotal $45.00). | Fee updates to **$5.99**. | High |
| TC-11 | Discount code removal restores free shipping | Continue from TC-10 | 1. Remove the discount code. | Fee returns to **Free**. | Medium |
| TC-12 | Threshold ignores tax | NONMEMBER, cart = S-JUST-BELOW, shipping address in a taxed region so subtotal + tax > $50.00 | 1. Go to checkout. 2. Select Standard. | Fee shows **$5.99** (tax does not count toward threshold). | High |
| TC-13 | Threshold ignores the shipping fee itself | NONMEMBER, cart = $45.00 | 1. Go to checkout. 2. Select Standard. | Fee shows **$5.99**; the $5.99 is not added to the subtotal to reach $50.99 and flip to Free. | Medium |
| TC-14 | Gift card payment does not reduce subtotal for threshold | NONMEMBER, cart = S-HIGH, $240 gift card applied | 1. Go to checkout. 2. Apply gift card. 3. Select Standard. | Fee shows **Free** (gift card is a payment, not a discount). | Medium |
| TC-15 | Zero subtotal via 100% discount | NONMEMBER, cart = S-LOW with 100% code (S-ZERO) | 1. Go to checkout. 2. Select Standard. | Fee shows **$5.99**; order total = $5.99 + tax. No error or negative total. | Medium |

## AC-2: Members get free Standard shipping

| ID | Title | Preconditions | Steps | Expected result | Priority |
|---|---|---|---|---|---|
| TC-16 | Member free Standard below threshold | MEMBER, cart = S-LOW | 1. Go to checkout. 2. Select Standard. | Fee shows **Free / $0.00**. | High |
| TC-17 | Member free Standard one cent below threshold | MEMBER, cart = S-JUST-BELOW | 1. Go to checkout. 2. Select Standard. | Fee shows **Free / $0.00**. | High |
| TC-18 | Member free Standard at and above threshold | MEMBER, cart = S-AT, then S-HIGH | 1. Go to checkout with each cart. 2. Select Standard. | Fee shows **Free / $0.00** in both cases. | Medium |
| TC-19 | Member free Standard at zero subtotal | MEMBER, cart = S-ZERO | 1. Go to checkout. 2. Select Standard. | Fee shows **Free / $0.00**. | Low |
| TC-20 | Expired membership does not get free Standard | EXPIRED, cart = S-LOW | 1. Go to checkout. 2. Select Standard. | Fee shows **$5.99**. | High |
| TC-21 | Signing in as member mid-checkout removes fee | GUEST, cart = S-LOW, Standard selected showing $5.99 | 1. Sign in as MEMBER from the checkout page. | Fee updates to **Free** after sign-in. | High |
| TC-22 | Signing out of member account mid-checkout restores fee | MEMBER, cart = S-LOW, Standard selected showing Free | 1. Sign out. 2. Return to checkout as guest with same cart. | Fee shows **$5.99**. | Medium |
| TC-23 | Membership that expires during an open checkout session | MEMBER whose membership expires in 1 minute, cart = S-LOW | 1. Open checkout; confirm Free. 2. Wait until expiry. 3. Change quantity to trigger recalculation. | Fee becomes **$5.99** (or page prompts re-evaluation). Order cannot be placed with Free Standard after expiry. | Low |
| TC-24 | Member discount is not stacked as a negative fee | MEMBER, cart = S-HIGH | 1. Go to checkout. 2. Select Standard. | Fee is exactly **$0.00**, never negative; order total = subtotal + tax. | Medium |

## AC-3: Express shipping pricing

| ID | Title | Preconditions | Steps | Expected result | Priority |
|---|---|---|---|---|---|
| TC-25 | Non-member Express below threshold | NONMEMBER, cart = S-LOW | 1. Go to checkout. 2. Select Express. | Fee shows **$12.99**. | High |
| TC-26 | Non-member Express at threshold (no free Express) | NONMEMBER, cart = S-AT | 1. Go to checkout. 2. Select Express. | Fee shows **$12.99**. Threshold does not apply to Express. | High |
| TC-27 | Non-member Express well above threshold | NONMEMBER, cart = S-HIGH | 1. Go to checkout. 2. Select Express. | Fee shows **$12.99**. | Medium |
| TC-28 | Guest Express | GUEST, cart = S-AT | 1. Go to checkout. 2. Select Express. | Fee shows **$12.99**. | Medium |
| TC-29 | Member Express below threshold | MEMBER, cart = S-LOW | 1. Go to checkout. 2. Select Express. | Fee shows **$7.99**. | High |
| TC-30 | Member Express at and above threshold | MEMBER, cart = S-AT, then S-HIGH | 1. Go to checkout with each cart. 2. Select Express. | Fee shows **$7.99** in both cases (not Free). | High |
| TC-31 | Expired membership pays full Express | EXPIRED, cart = S-LOW | 1. Go to checkout. 2. Select Express. | Fee shows **$12.99**. | High |
| TC-32 | Switching Standard → Express → Standard (non-member, above threshold) | NONMEMBER, cart = S-HIGH | 1. Select Standard; note Free. 2. Select Express. 3. Select Standard again. | Fees shown in order: **Free → $12.99 → Free**. Order total updates each time. | High |
| TC-33 | Switching Standard → Express → Standard (member) | MEMBER, cart = S-LOW | 1. Select Standard. 2. Select Express. 3. Select Standard. | Fees shown in order: **Free → $7.99 → Free**. | Medium |
| TC-34 | Express fee unchanged when subtotal crosses threshold | NONMEMBER, cart = S-JUST-BELOW, Express selected | 1. Confirm $12.99. 2. Add an item so subtotal ≥ $50.00. | Fee remains **$12.99**. | Medium |
| TC-35 | Member signs in with Express already selected | GUEST, cart = S-LOW, Express selected showing $12.99 | 1. Sign in as MEMBER. | Fee updates to **$7.99**; Express remains selected. | Medium |

## Cross-cutting, display, and integrity

| ID | Title | Preconditions | Steps | Expected result | Priority |
|---|---|---|---|---|---|
| TC-36 | Order total arithmetic | Any account; cart = S-LOW, tax known | 1. Select each shipping method. | Order total = subtotal + tax + displayed shipping fee, to the cent, for every method/account combination. | High |
| TC-37 | Shipping option list shows the price for each method before selection | NONMEMBER, cart = S-LOW | 1. Open shipping method selector. | Standard labelled $5.99 and Express labelled $12.99 before either is chosen; labels match fee charged after selection. | Medium |
| TC-38 | Shipping option labels reflect member pricing | MEMBER, cart = S-LOW | 1. Open shipping method selector. | Standard labelled Free, Express labelled $7.99. | Medium |
| TC-39 | Fee persists after page refresh | NONMEMBER, cart = S-LOW, Express selected | 1. Refresh checkout page. | Express still selected, fee still $12.99. | Medium |
| TC-40 | Fee persists through payment step and order confirmation | MEMBER, cart = S-LOW, Express selected | 1. Complete payment. 2. View order confirmation and emailed receipt. | Shipping line shows **$7.99** on confirmation, receipt, and in order history. Charged amount matches. | High |
| TC-41 | Server-side validation of fee | NONMEMBER, cart = S-LOW | 1. Using browser dev tools, alter the submitted shipping fee to $0.00 and place order. | Order is rejected or server recalculates to $5.99; shopper is never charged the tampered amount. | High |
| TC-42 | Server-side validation of membership flag | GUEST, cart = S-LOW | 1. Alter the request to claim member status. 2. Place order. | Server determines membership from the authenticated session, not the request body; fee is $5.99. | High |
| TC-43 | Currency formatting | Any | 1. View fees across all scenarios. | All fees shown with `$` and exactly two decimals ($5.99, $12.99, $7.99, $0.00/Free). No $5.990 or $5.9. | Low |
| TC-44 | Large subtotal | NONMEMBER, cart = $9,999.99 | 1. Select Standard and Express. | Standard Free, Express $12.99; no overflow or formatting break. | Low |
| TC-45 | Multiple shipping-related rules do not double-apply | MEMBER, cart = S-HIGH | 1. Select Standard. | Only one free-shipping reason applies; no duplicate "Free shipping" discount lines appear in the summary. | Medium |
| TC-46 | Accessibility of fee display | Any | 1. Navigate checkout with a screen reader. | Each shipping option announces its name and price; the selected fee and updated total are announced on change. | Low |
| TC-47 | Mobile layout | NONMEMBER, cart = S-LOW, viewport 375px | 1. Open checkout; switch methods. | Fees and totals visible and update correctly without truncation. | Low |

## Out of scope / open questions for the Product Owner

- Whether the $50.00 threshold is measured before or after promotional discounts (assumed **after**; TC-10, TC-11, TC-15 depend on this).
- Whether a subtotal of exactly $0.00 should allow checkout at all.
- Behaviour for multi-shipment orders, international addresses, or oversized items — no rule given, so not tested.
- Whether the "Free" label versus "$0.00" is mandated.
- Whether a membership trial counts as an active membership.
