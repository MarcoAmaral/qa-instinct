# Test Cases — SHIP-9: Shipping fee at checkout

## Assumptions

- **A1 — Subtotal definition:** "Order subtotal" is the sum of item prices after item-level and cart-level promotional discounts are applied, but before tax and before the shipping fee itself. Gift cards and store credit are payment methods and do not reduce the subtotal.
- **A2 — Member definition:** A "member" is a shopper who is signed in and whose account has an active membership at the moment of checkout. Guests and signed-in non-members are "non-members." An expired or cancelled membership is treated as non-member.
- **A3 — Shipping methods:** Only two methods exist: Standard and Express. Both are available for every order in scope. Currency is USD, displayed to two decimals.
- **A4 — Fee recalculation:** The shipping fee is recalculated and displayed whenever the subtotal, selected shipping method, or member status changes while on the checkout page.
- **A5 — Threshold comparison:** The $50.00 threshold is inclusive (≥ $50.00 is free), and comparison is done on the rounded two-decimal subtotal shown to the shopper.
- **A6 — Order total:** The displayed order total equals subtotal + tax + shipping fee, so a shipping fee change must be reflected in the total.

## Fee matrix under test

| Shopper | Subtotal < $50.00 | Subtotal ≥ $50.00 |
|---|---|---|
| Non-member, Standard | $5.99 | $0.00 |
| Non-member, Express | $12.99 | $12.99 |
| Member, Standard | $0.00 | $0.00 |
| Member, Express | $7.99 | $7.99 |

## Test cases

### AC-1: Standard shipping threshold for non-members

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-01 | Non-member, Standard, subtotal just below threshold | Guest shopper; cart subtotal = $49.99 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $5.99. Order total includes $5.99. |
| TC-02 | Non-member, Standard, subtotal exactly at threshold | Guest shopper; cart subtotal = $50.00 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $0.00 (or "Free"). Order total includes no shipping charge. |
| TC-03 | Non-member, Standard, subtotal just above threshold | Guest shopper; cart subtotal = $50.01 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $0.00 / "Free". |
| TC-04 | Non-member, Standard, low subtotal | Guest shopper; cart subtotal = $0.01 (lowest-priced item) | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $5.99. |
| TC-05 | Non-member, Standard, high subtotal | Guest shopper; cart subtotal = $999.99 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $0.00 / "Free". |
| TC-06 | Signed-in non-member behaves like guest | Shopper signed in, no membership; subtotal = $49.99 | 1. Go to checkout. 2. Select Standard shipping. | Shipping fee shows $5.99. |
| TC-07 | Discount brings subtotal below threshold | Guest shopper; items total $55.00; 10% promo code available | 1. Go to checkout, select Standard. 2. Confirm fee is $0.00. 3. Apply promo code (subtotal → $49.50). | After promo, shipping fee updates to $5.99 and order total updates accordingly (per A1, A4). |
| TC-08 | Discount brings subtotal exactly to threshold | Guest shopper; items total $55.00; $5.00 off promo available | 1. Go to checkout, select Standard. 2. Apply promo (subtotal → $50.00). | Shipping fee remains $0.00 / "Free". |
| TC-09 | Adding an item crosses threshold upward | Guest shopper; subtotal = $45.00 | 1. Go to checkout, select Standard; confirm fee $5.99. 2. Return to cart, add $5.00 item (subtotal → $50.00). 3. Return to checkout. | Shipping fee shows $0.00 / "Free". |
| TC-10 | Removing an item crosses threshold downward | Guest shopper; subtotal = $50.00 | 1. Go to checkout, select Standard; confirm fee $0.00. 2. Remove an item (subtotal → $49.99). 3. Return to checkout. | Shipping fee shows $5.99. |
| TC-11 | Quantity change crosses threshold | Guest shopper; one item at $25.00, qty 1 | 1. Go to checkout, select Standard; confirm fee $5.99. 2. Change quantity to 2 (subtotal → $50.00). | Shipping fee updates to $0.00 / "Free" without a page reload (per A4). |
| TC-12 | Tax is excluded from threshold calculation | Guest shopper in a taxed region; subtotal = $48.00; tax ≥ $2.00 | 1. Go to checkout. 2. Select Standard. | Shipping fee shows $5.99 (subtotal + tax ≥ $50 does not qualify). |
| TC-13 | Shipping fee itself is excluded from threshold | Guest shopper; subtotal = $45.00 | 1. Go to checkout. 2. Select Express ($12.99). 3. Switch to Standard. | Standard shows $5.99 (subtotal + prior shipping fee is not used). |
| TC-14 | Gift card / store credit does not change subtotal | Guest shopper; subtotal = $60.00; $20 gift card | 1. Go to checkout, select Standard. 2. Apply gift card. | Shipping fee remains $0.00 (subtotal still $60.00 per A1). |

### AC-2: Members get free standard shipping at any subtotal

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-15 | Member, Standard, subtotal below threshold | Signed-in active member; subtotal = $49.99 | 1. Go to checkout. 2. Select Standard. | Shipping fee shows $0.00 / "Free". |
| TC-16 | Member, Standard, minimum subtotal | Signed-in active member; subtotal = $0.01 | 1. Go to checkout. 2. Select Standard. | Shipping fee shows $0.00 / "Free". |
| TC-17 | Member, Standard, subtotal at threshold | Signed-in active member; subtotal = $50.00 | 1. Go to checkout. 2. Select Standard. | Shipping fee shows $0.00 / "Free". |
| TC-18 | Member, Standard, subtotal above threshold | Signed-in active member; subtotal = $150.00 | 1. Go to checkout. 2. Select Standard. | Shipping fee shows $0.00 / "Free". |
| TC-19 | Signing in as member removes Standard fee | Guest cart with subtotal = $30.00 | 1. Go to checkout, select Standard; confirm fee $5.99. 2. Sign in as active member (cart preserved). | Shipping fee updates to $0.00 / "Free". |
| TC-20 | Signing out of member account restores fee | Active member signed in; subtotal = $30.00 | 1. At checkout with Standard, confirm fee $0.00. 2. Sign out (cart preserved as guest). 3. Return to checkout. | Shipping fee shows $5.99. |
| TC-21 | Expired membership treated as non-member | Signed-in account with expired membership; subtotal = $30.00 | 1. Go to checkout. 2. Select Standard. | Shipping fee shows $5.99 (per A2). |
| TC-22 | Cancelled membership treated as non-member | Signed-in account with cancelled membership; subtotal = $30.00 | 1. Go to checkout. 2. Select Standard. | Shipping fee shows $5.99 (per A2). |
| TC-23 | Membership expires mid-session | Member whose membership expires in the next minute; subtotal = $30.00 | 1. Open checkout before expiry, confirm Standard fee $0.00. 2. Wait for expiry. 3. Refresh / re-trigger fee calculation. | Shipping fee shows $5.99 after expiry. |
| TC-24 | Membership purchased in the same session | Signed-in non-member; subtotal = $30.00 | 1. Confirm Standard fee $5.99 at checkout. 2. Purchase/activate membership. 3. Return to checkout. | Shipping fee shows $0.00 / "Free". |

### AC-3: Express shipping pricing

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-25 | Non-member, Express, subtotal below threshold | Guest shopper; subtotal = $49.99 | 1. Go to checkout. 2. Select Express. | Shipping fee shows $12.99. |
| TC-26 | Non-member, Express, subtotal at threshold | Guest shopper; subtotal = $50.00 | 1. Go to checkout. 2. Select Express. | Shipping fee shows $12.99 (threshold does not apply to Express). |
| TC-27 | Non-member, Express, subtotal above threshold | Guest shopper; subtotal = $500.00 | 1. Go to checkout. 2. Select Express. | Shipping fee shows $12.99. |
| TC-28 | Member, Express, subtotal below threshold | Active member; subtotal = $49.99 | 1. Go to checkout. 2. Select Express. | Shipping fee shows $7.99. |
| TC-29 | Member, Express, subtotal at threshold | Active member; subtotal = $50.00 | 1. Go to checkout. 2. Select Express. | Shipping fee shows $7.99. |
| TC-30 | Member, Express, subtotal above threshold | Active member; subtotal = $500.00 | 1. Go to checkout. 2. Select Express. | Shipping fee shows $7.99. |
| TC-31 | Member, Express, minimum subtotal | Active member; subtotal = $0.01 | 1. Go to checkout. 2. Select Express. | Shipping fee shows $7.99 (member Express is never free). |
| TC-32 | Expired member, Express | Expired membership; subtotal = $30.00 | 1. Go to checkout. 2. Select Express. | Shipping fee shows $12.99. |
| TC-33 | Signing in as member updates Express fee | Guest; subtotal = $30.00 | 1. At checkout, select Express; confirm $12.99. 2. Sign in as active member. | Shipping fee updates to $7.99. |
| TC-34 | Express fee unaffected by subtotal crossing threshold | Guest; subtotal = $49.99 | 1. Select Express; confirm $12.99. 2. Increase quantity so subtotal = $50.00. | Shipping fee remains $12.99. |

### Method switching and fee display

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-35 | Switch Standard → Express → Standard, non-member below threshold | Guest; subtotal = $30.00 | 1. Select Standard. 2. Select Express. 3. Select Standard. | Fee shows $5.99 → $12.99 → $5.99; order total updates each time. |
| TC-36 | Switch Standard → Express → Standard, member | Active member; subtotal = $30.00 | 1. Select Standard. 2. Select Express. 3. Select Standard. | Fee shows $0.00 → $7.99 → $0.00. |
| TC-37 | Shipping option list shows correct prices before selection | Guest; subtotal = $30.00 | 1. Go to checkout. 2. View shipping options list. | Standard labelled $5.99, Express labelled $12.99, before either is selected. |
| TC-38 | Shipping option list prices for member | Active member; subtotal = $30.00 | 1. Go to checkout. 2. View shipping options list. | Standard labelled Free/$0.00, Express labelled $7.99. |
| TC-39 | Shipping option list prices for non-member at/above threshold | Guest; subtotal = $50.00 | 1. Go to checkout. 2. View shipping options list. | Standard labelled Free/$0.00, Express labelled $12.99. |
| TC-40 | Default shipping selection shows a fee | Guest; subtotal = $30.00 | 1. Land on checkout page without choosing a method. | A shipping method is pre-selected (or a prompt is shown) and the displayed fee/total is consistent with that state; total never shows an undefined/blank shipping line. |
| TC-41 | Fee formatting | Any shopper | 1. View shipping fee for each scenario in the fee matrix. | All fees show as USD with two decimals ($5.99, $12.99, $7.99, $0.00 or "Free"); no values like "5.990" or "$6". |
| TC-42 | Fee persists through checkout steps | Guest; subtotal = $30.00; Standard selected | 1. Proceed from shipping to payment to review step. | $5.99 remains on every step and in the order summary. |
| TC-43 | Fee on order confirmation and order record | Guest; subtotal = $30.00; Standard selected | 1. Place the order. 2. View confirmation page and order history/email. | Shipping fee recorded as $5.99; order total matches checkout. |
| TC-44 | Charged amount matches displayed fee | Each row of the fee matrix | 1. Place the order. 2. Inspect payment capture / backend order record. | Captured amount = subtotal + tax + displayed shipping fee; no server-side discrepancy from the displayed fee. |
| TC-45 | Page refresh preserves correct fee | Active member; subtotal = $30.00; Express selected | 1. Refresh the checkout page. | Express still selected and fee still $7.99. |

### Negative, edge and security cases

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-46 | Rounding edge — subtotal $49.995 scenario | Guest; items whose raw sum before rounding is $49.995 (e.g., percentage discount) | 1. Go to checkout, select Standard. | Fee is determined by the displayed two-decimal subtotal (per A5). If displayed subtotal is $50.00, fee is $0.00; if $49.99, fee is $5.99. Displayed subtotal and fee must be consistent. |
| TC-47 | Server-side validation of fee on submit | Guest; subtotal = $30.00 | 1. Intercept the order submission request and change the shipping fee from 5.99 to 0.00. 2. Submit. | Server rejects or recalculates; order is not created with a $0.00 Standard fee for a non-member below threshold. |
| TC-48 | Server-side validation of member status | Guest; subtotal = $30.00 | 1. Intercept the order submission and set a member flag to true. 2. Submit. | Server derives member status from the authenticated account, not the request; fee remains $5.99. |
| TC-49 | Subtotal becomes $0.00 after full discount | Guest; subtotal $20.00; 100% promo code | 1. Apply promo. 2. Select Standard. | Fee shows $5.99 (subtotal < $50.00). Express shows $12.99. (Note: if business wants free shipping on $0 orders, this is a gap to raise.) |
| TC-50 | Concurrent cart update from another tab | Guest; subtotal $49.99 in tab A | 1. In tab B, add $0.01 item. 2. In tab A, proceed to place order without refreshing. | Server recalculates on submit; final order shows Standard = $0.00 and total matches the real subtotal. No stale $5.99 charged. |
| TC-51 | Multiple promo codes stacking across threshold | Guest; subtotal $60.00; two $6 promos | 1. Apply first promo (→ $54.00), confirm Standard free. 2. Apply second promo (→ $48.00). | Fee updates to $5.99 after second promo. |
| TC-52 | Removing a promo re-crosses threshold | Guest; subtotal $55.00; $10 promo applied (→ $45.00), Standard $5.99 | 1. Remove promo. | Fee updates to $0.00 / "Free". |
| TC-53 | Express selected, then membership expires before submit | Member with expiring membership; subtotal $30.00; Express selected ($7.99) | 1. Let membership expire. 2. Submit order. | Server charges $12.99 and the shopper is shown the updated fee before the charge is taken (no silent price change). |
| TC-54 | Accessibility of fee display | Any shopper | 1. Navigate shipping options with a screen reader / keyboard. | Each option announces its name and fee; "Free" is announced, not an empty value. |

## Traceability

| AC | Test cases |
|---|---|
| AC-1 | TC-01 – TC-14, TC-35, TC-37, TC-39, TC-40 – TC-44, TC-46, TC-47, TC-49 – TC-52 |
| AC-2 | TC-15 – TC-24, TC-36, TC-38, TC-45, TC-48 |
| AC-3 | TC-25 – TC-34, TC-35, TC-36, TC-37, TC-38, TC-45, TC-53 |

## Open questions to raise with the product owner (tests proceed under assumptions above)

1. Is subtotal measured before or after promotional discounts (A1)?
2. Should expired/cancelled memberships lose benefits immediately or at end of billing period (A2)?
3. Should a $0.00 subtotal order still incur a shipping fee (TC-49)?
4. Are there regions or item types where Express is unavailable (A3)?
