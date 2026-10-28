# Test Cases: SHIP-9 Shipping fee at checkout

## Assumptions

1. **Subtotal** means the merchandise total after item-level and cart-level discounts (promo codes), before tax, shipping, and gift-card payments. The $50.00 threshold is inclusive (≥ $50.00 is free).
2. **Member** means a shopper signed in to an account with an active membership. Guests, signed-in non-members, and shoppers with an expired or cancelled membership are treated as non-members.
3. Only two shipping methods exist: Standard and Express. Standard is pre-selected by default.
4. Fees are in USD; the store sells in a single currency.
5. The fee shown at checkout is recalculated server-side on every change to the cart, shipping method, or sign-in state, and the fee is locked into the order at placement.
6. The fee is displayed as a separate line in the order summary and included in the order total.

## Fee matrix (expected results)

| Shopper | Subtotal | Standard | Express |
|---|---|---|---|
| Non-member | < $50.00 | $5.99 | $12.99 |
| Non-member | ≥ $50.00 | Free ($0.00) | $12.99 |
| Member | < $50.00 | Free ($0.00) | $7.99 |
| Member | ≥ $50.00 | Free ($0.00) | $7.99 |

---

## 1. Standard shipping, non-member (AC-1)

**TC-01 Standard fee below threshold**
- Preconditions: Guest shopper, cart subtotal $30.00.
- Steps: Go to checkout, keep Standard selected.
- Expected: Shipping line shows $5.99. Order total = subtotal + tax + $5.99.

**TC-02 Boundary just below threshold**
- Preconditions: Guest shopper, cart subtotal $49.99.
- Steps: Go to checkout, Standard selected.
- Expected: Shipping fee $5.99.

**TC-03 Boundary exactly at threshold**
- Preconditions: Guest shopper, cart subtotal $50.00.
- Steps: Go to checkout, Standard selected.
- Expected: Shipping shows Free / $0.00. No $5.99 appears anywhere in the summary.

**TC-04 Boundary just above threshold**
- Preconditions: Guest shopper, cart subtotal $50.01.
- Steps: Go to checkout, Standard selected.
- Expected: Shipping Free / $0.00.

**TC-05 Large subtotal**
- Preconditions: Guest shopper, cart subtotal $1,250.00.
- Steps: Go to checkout, Standard selected.
- Expected: Shipping Free / $0.00.

**TC-06 Signed-in non-member behaves like guest**
- Preconditions: Signed-in account with no membership, subtotal $45.00.
- Steps: Go to checkout, Standard selected.
- Expected: Shipping $5.99.

**TC-07 Discount drops subtotal below threshold**
- Preconditions: Guest shopper, cart subtotal $55.00, valid 20% promo code.
- Steps: At checkout confirm Standard is Free, then apply the promo code.
- Expected: Subtotal becomes $44.00; shipping updates to $5.99 without a page reload; total reflects both changes.

**TC-08 Adding an item crosses threshold upward**
- Preconditions: Guest shopper, cart subtotal $48.00.
- Steps: At checkout confirm $5.99, increase a line-item quantity so subtotal is ≥ $50.00.
- Expected: Shipping updates to Free immediately; total updates accordingly.

**TC-09 Removing an item crosses threshold downward**
- Preconditions: Guest shopper, cart subtotal $52.00 across two items.
- Steps: At checkout confirm Free, remove an item so subtotal < $50.00.
- Expected: Shipping updates to $5.99.

**TC-10 Tax does not count toward threshold**
- Preconditions: Guest shopper in a taxed region, subtotal $48.00, tax brings pre-shipping total above $50.00.
- Steps: Go to checkout, Standard selected.
- Expected: Shipping $5.99 (threshold uses subtotal, not subtotal + tax).

**TC-11 Gift card payment does not change the threshold**
- Preconditions: Guest shopper, subtotal $60.00, $20 gift card applied as payment.
- Steps: Go to checkout, Standard selected.
- Expected: Shipping Free (subtotal is still $60.00; payment method does not affect the fee).

## 2. Standard shipping, member (AC-2)

**TC-12 Member, small subtotal**
- Preconditions: Signed-in active member, subtotal $5.00.
- Steps: Go to checkout, Standard selected.
- Expected: Shipping Free / $0.00.

**TC-13 Member, just below threshold**
- Preconditions: Active member, subtotal $49.99.
- Expected: Shipping Free.

**TC-14 Member, at and above threshold**
- Preconditions: Active member, subtotal $50.00; repeat with $200.00.
- Expected: Shipping Free in both cases.

**TC-15 Guest signs in as member mid-checkout**
- Preconditions: Guest with subtotal $30.00 sees $5.99 at checkout.
- Steps: Sign in with an active member account from the checkout page.
- Expected: Cart is preserved; shipping updates to Free; total recalculates.

**TC-16 Member signs out mid-checkout**
- Preconditions: Member with subtotal $30.00 sees Free at checkout.
- Steps: Sign out and continue as guest with the same cart.
- Expected: Shipping updates to $5.99.

**TC-17 Expired membership treated as non-member**
- Preconditions: Signed-in account whose membership expired yesterday, subtotal $30.00.
- Expected: Shipping $5.99.

**TC-18 Membership expiring today**
- Preconditions: Membership end date = today, subtotal $30.00.
- Expected: Behaviour per product rule for end-date inclusivity. Assumption: active through end of day, so shipping Free. Flag if behaviour differs.

## 3. Express shipping (AC-3)

**TC-19 Non-member express, below threshold**
- Preconditions: Guest, subtotal $30.00.
- Steps: At checkout select Express.
- Expected: Shipping $12.99.

**TC-20 Non-member express, at and above threshold**
- Preconditions: Guest, subtotal $50.00; repeat with $500.00.
- Steps: Select Express.
- Expected: Shipping $12.99 in both cases (free-shipping threshold does not apply to Express).

**TC-21 Member express, below threshold**
- Preconditions: Active member, subtotal $10.00.
- Steps: Select Express.
- Expected: Shipping $7.99.

**TC-22 Member express, at and above threshold**
- Preconditions: Active member, subtotal $50.00; repeat with $500.00.
- Steps: Select Express.
- Expected: Shipping $7.99 in both cases.

**TC-23 Switch between methods updates fee**
- Preconditions: Guest, subtotal $30.00.
- Steps: Select Express, then back to Standard, then Express again.
- Expected: Fee shows $12.99 → $5.99 → $12.99; total updates each time; only one method is selected at a time.

**TC-24 Express fee unchanged by cart edits**
- Preconditions: Guest, subtotal $48.00, Express selected ($12.99).
- Steps: Add items to push subtotal above $50.00.
- Expected: Express remains $12.99; Standard option (if displayed with price) now shows Free.

**TC-25 Member switches methods**
- Preconditions: Active member, subtotal $30.00.
- Steps: Select Express, then Standard.
- Expected: $7.99 → Free.

**TC-26 Guest signs in as member with Express selected**
- Preconditions: Guest, subtotal $30.00, Express selected ($12.99).
- Steps: Sign in as active member.
- Expected: Express fee updates to $7.99; Express remains selected.

## 4. Display and order integrity

**TC-27 Method options show correct prices before selection**
- Preconditions: Guest, subtotal $30.00.
- Expected: Shipping options list shows Standard $5.99 and Express $12.99. Repeat for member: Standard Free, Express $7.99. Repeat for guest ≥ $50: Standard Free, Express $12.99.

**TC-28 Fee formatting**
- Expected: Fees display with two decimals and currency symbol ($5.99, $12.99, $7.99). Free shipping shows "Free" or "$0.00" consistently (not "$0", "-", or blank).

**TC-29 Fee persisted on placed order**
- Steps: Place orders for each row of the fee matrix.
- Expected: Order confirmation page, confirmation email, and order history show the same shipping fee that was displayed at checkout; order total matches.

**TC-30 Fee locked at placement despite later changes**
- Steps: Place an order as a member with Express ($7.99), then cancel the membership.
- Expected: The placed order still shows $7.99.

**TC-31 Server-side validation of fee**
- Steps: With a guest cart at $30.00 and Standard selected, intercept the place-order request and change the shipping fee to $0.00 or the method to a cheaper value.
- Expected: Server recalculates and rejects or corrects the tampered fee; order is not placed with an incorrect fee.

**TC-32 Fee recalculated on checkout reload**
- Steps: Guest at $30.00, Standard ($5.99). Open the cart in another tab, add items to reach $60.00, return to checkout and refresh.
- Expected: Shipping shows Free after refresh.

**TC-33 Zero subtotal**
- Preconditions: Guest cart where the subtotal is $0.00 after a 100% promo code.
- Expected: Standard $5.99, Express $12.99 (subtotal < $50.00). Flag as a product question if free shipping is expected here.

**TC-34 Rounding at threshold**
- Preconditions: Guest, items and discount that compute to $49.995 before rounding.
- Expected: Threshold comparison uses the displayed, rounded subtotal; fee is consistent with the subtotal shown to the shopper.

**TC-35 Accessibility of fee display**
- Expected: Shipping options are radio buttons with associated labels that include the price; fee changes are announced to screen readers (live region) or are otherwise discoverable; no information is conveyed by colour alone.

**TC-36 Mobile layout**
- Steps: Repeat TC-23 on a mobile viewport.
- Expected: Fee and total remain visible and update correctly; options are tappable.

## 5. Out of scope / open questions for the product owner

- Whether subtotal is measured before or after promo codes (assumed after).
- Treatment of trial, paused, or same-day-expiring memberships.
- Non-USD currencies and international destinations.
- Whether Express availability depends on address or item type.
- Whether a $0.00 subtotal order should ever be charged shipping.
