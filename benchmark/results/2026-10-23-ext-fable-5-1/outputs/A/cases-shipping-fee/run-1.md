# Test Cases: SHIP-9 Shipping Fee at Checkout

## Assumptions

- **A1:** "Subtotal" means the merchandise total after item-level discounts and before tax, shipping, and order-level promo codes. Boundary checks use this value.
- **A2:** Currency is USD with two-decimal rounding; the $50.00 threshold is compared inclusively ($50.00 qualifies).
- **A3:** "Member" is a logged-in account with an active membership flag. Guests and logged-in non-members are treated identically ("non-member").
- **A4:** Only two shipping methods exist: Standard and Express. Standard is the default selection.
- **A5:** Express is never free, including for members and including above $50.00 (AC-3 says "at any subtotal").
- **A6:** The fee recalculates immediately when subtotal, membership state, or selected method changes, without a page reload.
- **A7:** The displayed fee and the fee used in the order total are the same value.

## Test Cases

### AC-1: Standard shipping, non-member, subtotal threshold

| ID | Title | Preconditions | Steps | Expected Result |
|---|---|---|---|---|
| TC-01 | Standard fee below threshold | Non-member; cart subtotal $49.99; Standard selected | 1. Open checkout | Shipping fee shows $5.99; order total includes $5.99 |
| TC-02 | Standard free at exact threshold | Non-member; cart subtotal $50.00; Standard selected | 1. Open checkout | Shipping fee shows $0.00 / "Free" |
| TC-03 | Standard free above threshold | Non-member; cart subtotal $50.01; Standard selected | 1. Open checkout | Shipping fee shows $0.00 / "Free" |
| TC-04 | Standard free well above threshold | Non-member; cart subtotal $250.00; Standard selected | 1. Open checkout | Shipping fee shows $0.00 / "Free" |
| TC-05 | Standard fee at minimal subtotal | Non-member; cart subtotal $0.01; Standard selected | 1. Open checkout | Shipping fee shows $5.99 |
| TC-06 | Fee updates when subtotal crosses threshold upward | Non-member; cart subtotal $45.00; at checkout; Standard selected | 1. Increase item quantity so subtotal becomes $55.00 | Fee changes from $5.99 to $0.00 without reload (A6) |
| TC-07 | Fee updates when subtotal crosses threshold downward | Non-member; cart subtotal $55.00; at checkout; Standard selected | 1. Remove item so subtotal becomes $45.00 | Fee changes from $0.00 to $5.99 |
| TC-08 | Item-level discount reduces subtotal below threshold | Non-member; items list at $52.00 with a $5.00 item discount applied (subtotal $47.00); Standard selected | 1. Open checkout | Fee shows $5.99 (threshold uses post-discount subtotal, A1) |
| TC-09 | Order-level promo code does not affect threshold | Non-member; cart subtotal $52.00; order-level promo code of $10.00 applied; Standard selected | 1. Open checkout | Fee shows $0.00 (threshold uses pre-promo subtotal, A1) |
| TC-10 | Tax excluded from threshold | Non-member; cart subtotal $48.00; tax brings total to $52.00; Standard selected | 1. Open checkout | Fee shows $5.99 |
| TC-11 | Guest and logged-in non-member treated the same | Two sessions: guest, and logged-in non-member; both subtotal $30.00; Standard selected | 1. Open checkout in each | Both show $5.99 (A3) |

### AC-2: Standard shipping, member

| ID | Title | Preconditions | Steps | Expected Result |
|---|---|---|---|---|
| TC-12 | Member standard free below threshold | Member; cart subtotal $10.00; Standard selected | 1. Open checkout | Fee shows $0.00 / "Free" |
| TC-13 | Member standard free at minimal subtotal | Member; cart subtotal $0.01; Standard selected | 1. Open checkout | Fee shows $0.00 / "Free" |
| TC-14 | Member standard free at threshold | Member; cart subtotal $50.00; Standard selected | 1. Open checkout | Fee shows $0.00 / "Free" |
| TC-15 | Member standard free above threshold | Member; cart subtotal $120.00; Standard selected | 1. Open checkout | Fee shows $0.00 / "Free" |
| TC-16 | Logging in as member at checkout removes fee | Guest; cart subtotal $20.00; at checkout showing $5.99 | 1. Log in as a member | Fee updates to $0.00; cart is preserved |
| TC-17 | Expired membership treated as non-member | Logged-in user with expired/cancelled membership; subtotal $20.00; Standard selected | 1. Open checkout | Fee shows $5.99 (A3) |

### AC-3: Express shipping

| ID | Title | Preconditions | Steps | Expected Result |
|---|---|---|---|---|
| TC-18 | Non-member express below threshold | Non-member; subtotal $20.00 | 1. Open checkout 2. Select Express | Fee shows $12.99 |
| TC-19 | Non-member express at threshold | Non-member; subtotal $50.00 | 1. Open checkout 2. Select Express | Fee shows $12.99 (no free express, A5) |
| TC-20 | Non-member express above threshold | Non-member; subtotal $500.00 | 1. Open checkout 2. Select Express | Fee shows $12.99 |
| TC-21 | Member express below threshold | Member; subtotal $20.00 | 1. Open checkout 2. Select Express | Fee shows $7.99 |
| TC-22 | Member express at threshold | Member; subtotal $50.00 | 1. Open checkout 2. Select Express | Fee shows $7.99 |
| TC-23 | Member express above threshold | Member; subtotal $500.00 | 1. Open checkout 2. Select Express | Fee shows $7.99 (never free, A5) |
| TC-24 | Switch Standard to Express, non-member | Non-member; subtotal $60.00; checkout shows Standard $0.00 | 1. Select Express | Fee changes to $12.99; total updates |
| TC-25 | Switch Express back to Standard, non-member | Non-member; subtotal $40.00; Express selected ($12.99) | 1. Select Standard | Fee changes to $5.99 |
| TC-26 | Switch Standard to Express, member | Member; subtotal $40.00; checkout shows Standard $0.00 | 1. Select Express | Fee changes to $7.99 |
| TC-27 | Express fee unaffected by subtotal change | Non-member; subtotal $45.00; Express selected ($12.99) | 1. Increase subtotal to $55.00 | Fee remains $12.99 |

### Display and totals

| ID | Title | Preconditions | Steps | Expected Result |
|---|---|---|---|---|
| TC-28 | Order total matches displayed fee | Non-member; subtotal $30.00; tax $2.40; Standard selected | 1. Open checkout | Total = $30.00 + $2.40 + $5.99 = $38.39 (A7) |
| TC-29 | Free shipping shown clearly | Member; subtotal $30.00; Standard selected | 1. Open checkout | Fee displayed as $0.00 or "Free", not blank or hidden |
| TC-30 | Both method options show their price before selection | Non-member; subtotal $30.00 | 1. Open checkout 2. View shipping options | Standard labelled $5.99, Express labelled $12.99 |
| TC-31 | Both method options show member prices | Member; subtotal $30.00 | 1. Open checkout 2. View shipping options | Standard labelled Free/$0.00, Express labelled $7.99 |
| TC-32 | Currency formatting | Any user; any subtotal | 1. Open checkout | Fee shows two decimals with $ prefix (e.g. $5.99, not $5.9 or 5.99) |
| TC-33 | Fee persists through order placement | Non-member; subtotal $30.00; Standard $5.99 | 1. Place order 2. View confirmation | Confirmation shows shipping $5.99 and matching total |

### Negative / edge

| ID | Title | Preconditions | Steps | Expected Result |
|---|---|---|---|---|
| TC-34 | Empty cart | Any user; cart empty | 1. Attempt to open checkout | No shipping fee shown; checkout blocked or shows empty-cart message (fee is not $5.99 on $0.00) |
| TC-35 | Rounding near threshold | Non-member; three items at $16.666 each (rounds to $50.00 subtotal); Standard selected | 1. Open checkout | Fee is consistent with the displayed subtotal: if subtotal displays $50.00, fee is $0.00 (A2) |
| TC-36 | Membership expires mid-session | Member at checkout with subtotal $20.00 showing $0.00; membership expires server-side | 1. Refresh checkout or proceed to payment | Fee re-evaluates to $5.99 before payment is taken |
| TC-37 | Client-side tampering of fee rejected | Non-member; subtotal $20.00; Standard selected | 1. Intercept order submission and set shipping fee to $0.00 | Server recalculates; order charged $5.99 or request rejected |

## Traceability

| AC | Test Cases |
|---|---|
| AC-1 | TC-01 to TC-11, TC-25, TC-28, TC-30, TC-33, TC-34, TC-35, TC-37 |
| AC-2 | TC-12 to TC-17, TC-26, TC-29, TC-31, TC-36 |
| AC-3 | TC-18 to TC-27, TC-30, TC-31 |
