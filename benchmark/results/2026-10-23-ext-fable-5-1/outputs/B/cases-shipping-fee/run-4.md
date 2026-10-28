# Test Cases: SHIP-9 Shipping fee at checkout

## Assumptions

1. **Subtotal** means merchandise total after item and cart discounts, before tax and shipping. Tax never counts toward the $50.00 threshold.
2. **Member** means a logged-in shopper with an active membership. Guests and logged-in shoppers without membership are non-members.
3. Only two shipping methods exist: Standard and Express. Both are offered for every deliverable address.
4. Currency is USD. All amounts are whole cents, so the threshold compares exactly at $50.00 with no rounding.
5. The fee recalculates immediately on any change to the cart, selected method, or login state during checkout.
6. A $0.00 fee displays as "Free". The order total shown at checkout equals subtotal plus shipping plus tax.
7. The server recalculates the fee on order placement. The client-displayed fee is not trusted.

## Traceability

| AC | Test cases |
|---|---|
| AC-1 | TC-01 to TC-05, TC-15 to TC-17, TC-20, TC-21, TC-23 |
| AC-2 | TC-06 to TC-08, TC-18, TC-19, TC-22 |
| AC-3 | TC-09 to TC-14, TC-16 |
| Cross-cutting | TC-24 to TC-28 |

## Standard shipping, non-member (AC-1)

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-01 | Just below threshold | Guest, cart subtotal $49.99 | Go to checkout, select Standard | Shipping fee $5.99. Order total includes $5.99. |
| TC-02 | Exactly at threshold | Guest, cart subtotal $50.00 | Go to checkout, select Standard | Shipping fee "Free". Order total adds $0.00 for shipping. |
| TC-03 | Just above threshold | Guest, cart subtotal $50.01 | Go to checkout, select Standard | Shipping fee "Free". |
| TC-04 | Minimum subtotal | Guest, single item priced $0.01 | Go to checkout, select Standard | Shipping fee $5.99. |
| TC-05 | Large subtotal | Guest, cart subtotal $1,250.00 | Go to checkout, select Standard | Shipping fee "Free". |

## Standard shipping, member (AC-2)

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-06 | Member, minimum subtotal | Active member logged in, subtotal $0.01 | Go to checkout, select Standard | Shipping fee "Free". |
| TC-07 | Member, below threshold | Active member, subtotal $49.99 | Go to checkout, select Standard | Shipping fee "Free". |
| TC-08 | Member, at threshold | Active member, subtotal $50.00 | Go to checkout, select Standard | Shipping fee "Free". |

## Express shipping (AC-3)

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-09 | Non-member, below threshold | Guest, subtotal $49.99 | Go to checkout, select Express | Shipping fee $12.99. |
| TC-10 | Non-member, at threshold | Guest, subtotal $50.00 | Go to checkout, select Express | Shipping fee $12.99. Free-shipping threshold does not apply to Express. |
| TC-11 | Non-member, large subtotal | Guest, subtotal $1,250.00 | Go to checkout, select Express | Shipping fee $12.99. |
| TC-12 | Member, below threshold | Active member, subtotal $0.01 | Go to checkout, select Express | Shipping fee $7.99. |
| TC-13 | Member, at threshold | Active member, subtotal $50.00 | Go to checkout, select Express | Shipping fee $7.99. |
| TC-14 | Member, large subtotal | Active member, subtotal $1,250.00 | Go to checkout, select Express | Shipping fee $7.99. |

## Recalculation on change

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-15 | Cross threshold upward | Guest, subtotal $49.99, Standard selected, fee shows $5.99 | Increase an item quantity so subtotal becomes $50.00 or more | Fee updates to "Free" without page reload. Order total updates to match. |
| TC-16 | Cross threshold downward | Guest, subtotal $50.00, Standard selected, fee shows "Free" | Remove an item so subtotal drops to $49.99 or less | Fee updates to $5.99. Order total updates to match. |
| TC-17 | Switch method | Guest, subtotal $30.00 | Select Standard, then Express, then Standard again | Fee shows $5.99, then $12.99, then $5.99. Order total follows each change. |
| TC-18 | Log in as member mid-checkout | Guest, subtotal $30.00, Standard fee shows $5.99 | Log in as an active member from the checkout page | Fee updates to "Free". Express option now shows $7.99. Cart contents preserved. |
| TC-19 | Expired or cancelled membership | Logged-in shopper whose membership expired yesterday, subtotal $30.00 | Go to checkout, view Standard and Express | Standard $5.99, Express $12.99. Treated as non-member. |
| TC-20 | Discount code pulls subtotal below threshold | Guest, subtotal $55.00, Standard selected, fee shows "Free" | Apply a $10.00 discount code | Subtotal becomes $45.00. Fee updates to $5.99. Removing the code restores "Free". |
| TC-21 | Tax does not count toward threshold | Guest, subtotal $48.00, address with 8% tax so pre-shipping total exceeds $50.00 | Go to checkout, select Standard | Fee is $5.99. Threshold uses subtotal only. |
| TC-22 | Logged-in non-member | Account holder with no membership, subtotal $30.00 | Go to checkout, view both methods | Standard $5.99, Express $12.99. Same as guest. |
| TC-23 | Express with member discount only, no free-shipping effect | Active member, subtotal $500.00 | Select Express | Fee is $7.99, not "Free". Member discount on Express never reduces it to zero. |

## Cross-cutting

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-24 | Fee display format | Any shopper | View shipping options at checkout | Paid fees show with currency symbol and two decimals, for example "$5.99". Zero fee shows "Free". Both methods are listed with their fee before selection. |
| TC-25 | Fee persists to order | Guest, subtotal $30.00, Standard selected | Place the order; open order confirmation page, confirmation email, and order record in admin | All three show shipping fee $5.99 and matching order total. |
| TC-26 | Server-side fee validation | Guest, subtotal $30.00 | Intercept the place-order request and change the shipping fee to $0.00, then submit | Server rejects the order or recalculates to $5.99. No order is stored with $0.00 shipping. |
| TC-27 | Default method | Guest, subtotal $30.00 | Open checkout without choosing a method | Standard is preselected and its fee $5.99 is shown. Order total reflects it. Assumption: Standard is the default. |
| TC-28 | Fee recalculation after returning to checkout | Guest, subtotal $49.99, fee shows $5.99 | Leave checkout, add an item in the cart bringing subtotal to $52.00, return to checkout | Fee shows "Free" on return. No stale value from the earlier session. |

## Open questions for the product owner

- Confirm whether the threshold uses the post-discount subtotal (TC-20) or the pre-discount subtotal.
- Confirm membership status fallback if the membership service is unavailable at checkout. Assumed fail-safe to non-member pricing.
- Confirm whether gift cards or store credit applied at checkout affect the subtotal used for the threshold.
