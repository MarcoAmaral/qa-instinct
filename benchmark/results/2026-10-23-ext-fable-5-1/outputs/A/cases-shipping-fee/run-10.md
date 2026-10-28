# Test Cases: SHIP-9 Shipping Fee at Checkout

## Assumptions

- **A1:** "Order subtotal" means the merchandise total after item-level discounts and before tax, shipping, or order-level promo codes.
- **A2:** Only two shipping methods exist: Standard and Express. Both are always available to all shoppers.
- **A3:** A "member" is a shopper logged in with an active membership. Guests and logged-in non-members are treated identically as non-members.
- **A4:** The displayed fee updates whenever the cart contents or selected shipping method changes.
- **A5:** Currency is USD, displayed to two decimal places.
- **A6:** A subtotal of exactly $0.00 is not reachable at checkout, so it is tested only as a defensive edge case.

## Standard shipping, non-member (AC-1)

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-01 | Subtotal below threshold charges $5.99 | Non-member; Standard selected | Add items totalling $49.99; proceed to checkout | Shipping fee shows $5.99 |
| TC-02 | Subtotal exactly at threshold is free | Non-member; Standard selected | Add items totalling $50.00; proceed to checkout | Shipping fee shows $0.00 |
| TC-03 | Subtotal above threshold is free | Non-member; Standard selected | Add items totalling $50.01; proceed to checkout | Shipping fee shows $0.00 |
| TC-04 | Low subtotal charges $5.99 | Non-member; Standard selected | Add a single $0.01 item; proceed to checkout | Shipping fee shows $5.99 |
| TC-05 | High subtotal is free | Non-member; Standard selected | Add items totalling $1,000.00; proceed to checkout | Shipping fee shows $0.00 |
| TC-06 | Fee updates when cart crosses threshold upward | Non-member; Standard selected; cart at $45.00 | At checkout, increase item quantity so subtotal becomes $55.00 | Fee changes from $5.99 to $0.00 without reload |
| TC-07 | Fee updates when cart crosses threshold downward | Non-member; Standard selected; cart at $55.00 | At checkout, remove an item so subtotal becomes $45.00 | Fee changes from $0.00 to $5.99 |
| TC-08 | Item discount lowers subtotal below threshold | Non-member; Standard selected | Add a $60.00 item with a 20% item-level discount (subtotal $48.00) | Shipping fee shows $5.99 (per A1) |
| TC-09 | Order-level promo does not affect threshold | Non-member; Standard selected | Add items totalling $52.00; apply a $5 order-level promo code | Shipping fee remains $0.00 (per A1) |
| TC-10 | Tax is excluded from threshold | Non-member; Standard selected; tax applies | Add items totalling $48.00 in a taxed region where tax pushes total over $50 | Shipping fee shows $5.99 |

## Standard shipping, member (AC-2)

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-11 | Member free below threshold | Logged-in member; Standard selected | Add items totalling $10.00; proceed to checkout | Shipping fee shows $0.00 |
| TC-12 | Member free at threshold | Logged-in member; Standard selected | Add items totalling $50.00; proceed to checkout | Shipping fee shows $0.00 |
| TC-13 | Member free above threshold | Logged-in member; Standard selected | Add items totalling $200.00; proceed to checkout | Shipping fee shows $0.00 |
| TC-14 | Member free at minimum subtotal | Logged-in member; Standard selected | Add a single $0.01 item; proceed to checkout | Shipping fee shows $0.00 |
| TC-15 | Logging in as member at checkout removes fee | Guest; Standard selected; cart at $30.00 showing $5.99 | Log in as a member from the checkout page | Fee updates to $0.00 |
| TC-16 | Logging out at checkout restores fee | Member; Standard selected; cart at $30.00 showing $0.00 | Log out and continue as guest | Fee updates to $5.99 |
| TC-17 | Expired membership is treated as non-member | Logged-in user whose membership has expired; Standard selected | Add items totalling $30.00; proceed to checkout | Shipping fee shows $5.99 (per A3) |

## Express shipping (AC-3)

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-18 | Non-member express below $50 | Non-member; Express selected | Add items totalling $30.00; proceed to checkout | Shipping fee shows $12.99 |
| TC-19 | Non-member express at $50 | Non-member; Express selected | Add items totalling $50.00; proceed to checkout | Shipping fee shows $12.99 (threshold does not apply to express) |
| TC-20 | Non-member express above $50 | Non-member; Express selected | Add items totalling $500.00; proceed to checkout | Shipping fee shows $12.99 |
| TC-21 | Member express below $50 | Logged-in member; Express selected | Add items totalling $30.00; proceed to checkout | Shipping fee shows $7.99 |
| TC-22 | Member express at $50 | Logged-in member; Express selected | Add items totalling $50.00; proceed to checkout | Shipping fee shows $7.99 |
| TC-23 | Member express above $50 | Logged-in member; Express selected | Add items totalling $500.00; proceed to checkout | Shipping fee shows $7.99 |
| TC-24 | Member express is not free | Logged-in member; Express selected | Add items totalling $10.00; proceed to checkout | Shipping fee shows $7.99, not $0.00 |

## Switching shipping method

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-25 | Non-member switches Standard to Express below $50 | Non-member; cart at $30.00; Standard selected ($5.99) | Select Express | Fee updates to $12.99 |
| TC-26 | Non-member switches Express to Standard above $50 | Non-member; cart at $80.00; Express selected ($12.99) | Select Standard | Fee updates to $0.00 |
| TC-27 | Member switches Standard to Express | Member; cart at $30.00; Standard selected ($0.00) | Select Express | Fee updates to $7.99 |
| TC-28 | Member switches Express to Standard | Member; cart at $80.00; Express selected ($7.99) | Select Standard | Fee updates to $0.00 |

## Order total and persistence

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-29 | Fee included in order total | Non-member; Standard selected; cart at $30.00 | View order summary at checkout | Total = $30.00 + $5.99 + any tax; shipping line shows $5.99 |
| TC-30 | Free shipping shown explicitly | Member; Standard selected; cart at $30.00 | View order summary | Shipping line shows $0.00 or "Free"; total excludes any shipping charge |
| TC-31 | Fee at order placement matches displayed fee | Non-member; Express selected; cart at $30.00 | Place the order | Order confirmation and stored order record show shipping fee $12.99 |
| TC-32 | Fee recalculated server-side | Non-member; Standard selected; cart at $30.00 | Tamper with the client request to submit a shipping fee of $0.00 | Server rejects or recalculates to $5.99; order is not placed with $0.00 shipping |
| TC-33 | Fee persists across page refresh | Non-member; Express selected; cart at $30.00 | Refresh the checkout page | Express remains selected and fee still shows $12.99 |

## Edge and defensive cases

| ID | Title | Preconditions | Steps | Expected result |
|---|---|---|---|---|
| TC-34 | Rounding near threshold | Non-member; Standard selected | Add items that sum to $49.995 before rounding (e.g. three items at $16.665) | Subtotal displays as $50.00 or $49.99 consistently and fee matches the displayed subtotal, with no half-cent mismatch |
| TC-35 | Zero subtotal | Non-member; Standard selected | Force a $0.00 subtotal (e.g. fully discounted item) if reachable | Fee shows $5.99 and no error occurs (per A6, defensive only) |
| TC-36 | Fee display format | Any shopper | View shipping fee for each scenario | Fee always shown with currency symbol and two decimals, e.g. "$5.99", "$0.00" |

## Traceability

| Acceptance criterion | Test cases |
|---|---|
| AC-1 | TC-01 to TC-10, TC-25, TC-26, TC-29, TC-31 to TC-36 |
| AC-2 | TC-11 to TC-17, TC-27, TC-28, TC-30 |
| AC-3 | TC-18 to TC-28, TC-31 |
