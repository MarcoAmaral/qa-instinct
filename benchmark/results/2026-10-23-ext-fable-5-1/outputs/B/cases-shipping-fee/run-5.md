# Test Cases: SHIP-9 Shipping Fee at Checkout

## 1. Scope and assumptions

The story leaves several points undefined. Testing proceeds on the assumptions below; each one is a risk to confirm with the product owner before sign-off.

| # | Assumption | Why it matters |
|---|---|---|
| A1 | "Subtotal" is the merchandise total after item-level and promo-code discounts, before tax, shipping, and gift card/store credit application. | Decides whether a $55 cart with a $10 promo gets free shipping. Highest-risk ambiguity. |
| A2 | "Member" means a signed-in account whose membership is active at the moment the fee is calculated. Guests, registered non-members, expired, and never-paid memberships are all non-members. A cancelled membership still inside its paid period is active. | Drives AC-2 and AC-3 eligibility. |
| A3 | Prices are USD, stored to whole cents. The threshold comparison is exactly `subtotal >= 50.00`. | Boundary tests at $49.99 / $50.00 / $50.01. |
| A4 | Both Standard and Express are offered on every in-scope order. Standard is preselected. | Method-switch tests. |
| A5 | A free fee is displayed as "Free" and contributes $0.00 to the order total. | Display verification. |
| A6 | The fee recalculates whenever subtotal, selected method, or membership status changes during checkout. | Dynamic behaviour tests. |
| A7 | Single-address, single-shipment domestic orders only. International, split shipments, oversize surcharges, and "add $X for free shipping" nudges are out of scope. | Keeps the suite focused on the three ACs. |
| A8 | The fee is computed server-side and the value shown at checkout must equal the value authorised, confirmed, and stored on the order. | Integrity and tamper tests. |
| A9 | Tax is calculated on top of subtotal + shipping and never influences the threshold. | Tax tests. |

## 2. Test data

**Products** (all in stock, no shipping restrictions)

| SKU | Unit price |
|---|---|
| P-001 | $0.01 |
| P-010 | $10.00 |
| P-1666 | $16.66 |
| P-1667 | $16.67 |
| P-4999 | $49.99 |
| P-5000 | $50.00 |
| P-5001 | $50.01 |
| P-100 | $100.00 |
| P-010C | $0.10 |

**Promo codes**: `SAVE10` ($10.00 off merchandise), `FREE100` (100% off merchandise).

**Accounts**

| Account | State |
|---|---|
| GUEST | Not signed in |
| NONMEM | Signed in, never held membership |
| MEM | Signed in, active membership |
| EXPIRED | Signed in, membership expired yesterday |
| CANCELLED | Signed in, membership cancelled but paid through next month |

**Expected fee matrix** (derived from AC-1 to AC-3)

| Shopper | Subtotal | Standard | Express |
|---|---|---|---|
| Non-member | < $50.00 | $5.99 | $12.99 |
| Non-member | ≥ $50.00 | Free | $12.99 |
| Member | any | Free | $7.99 |

## 3. Core fee matrix and boundaries

Common steps unless stated otherwise: sign in as the given account (or stay guest), add the listed items, proceed to checkout, enter a domestic address, select the listed method, read the shipping line and order total.

| ID | Pri | AC | Shopper | Cart (subtotal) | Method | Expected fee | Notes |
|---|---|---|---|---|---|---|---|
| TC-01 | P1 | AC-1 | NONMEM | P-4999 ($49.99) | Standard | $5.99 | Upper boundary below threshold |
| TC-02 | P1 | AC-1 | NONMEM | P-5000 ($50.00) | Standard | Free | Exact threshold, inclusive |
| TC-03 | P1 | AC-1 | NONMEM | P-5001 ($50.01) | Standard | Free | Just above threshold |
| TC-04 | P1 | AC-1 | NONMEM | P-001 ($0.01) | Standard | $5.99 | Minimum subtotal |
| TC-05 | P2 | AC-1 | NONMEM | 10 × P-100 ($1,000.00) | Standard | Free | Large subtotal |
| TC-06 | P1 | AC-1 | GUEST | P-4999 ($49.99) | Standard | $5.99 | Guest treated as non-member |
| TC-07 | P1 | AC-1 | GUEST | P-5000 ($50.00) | Standard | Free | Guest reaches threshold |
| TC-08 | P1 | AC-1 | NONMEM | 5 × P-010 ($50.00) | Standard | Free | Threshold reached via quantity |
| TC-09 | P1 | AC-1 | NONMEM | 3 × P-1666 ($49.98) | Standard | $5.99 | Multiplied line just under |
| TC-10 | P1 | AC-1 | NONMEM | 3 × P-1667 ($50.01) | Standard | Free | Multiplied line just over |
| TC-11 | P2 | AC-1 | NONMEM | 500 × P-010C ($50.00) | Standard | Free | Floating-point accumulation must not yield 49.9999 |
| TC-12 | P1 | AC-2 | MEM | P-001 ($0.01) | Standard | Free | Member, minimum subtotal |
| TC-13 | P1 | AC-2 | MEM | P-4999 ($49.99) | Standard | Free | Member below threshold |
| TC-14 | P1 | AC-2 | MEM | P-5000 ($50.00) | Standard | Free | Member at threshold |
| TC-15 | P2 | AC-2 | MEM | 10 × P-100 ($1,000.00) | Standard | Free | Member large subtotal |
| TC-16 | P1 | AC-3 | NONMEM | P-4999 ($49.99) | Express | $12.99 | Non-member express below threshold |
| TC-17 | P1 | AC-3 | NONMEM | P-5000 ($50.00) | Express | $12.99 | Free-standard threshold must not leak into express |
| TC-18 | P2 | AC-3 | NONMEM | 10 × P-100 ($1,000.00) | Express | $12.99 | Non-member express large |
| TC-19 | P1 | AC-3 | GUEST | P-5000 ($50.00) | Express | $12.99 | Guest express |
| TC-20 | P1 | AC-3 | MEM | P-001 ($0.01) | Express | $7.99 | Member express minimum |
| TC-21 | P1 | AC-3 | MEM | P-4999 ($49.99) | Express | $7.99 | Member express below threshold |
| TC-22 | P1 | AC-3 | MEM | P-5000 ($50.00) | Express | $7.99 | Member express at threshold, not free |
| TC-23 | P2 | AC-3 | MEM | 10 × P-100 ($1,000.00) | Express | $7.99 | Member express large |

## 4. Membership status edge cases

| ID | Pri | AC | Preconditions | Steps | Expected |
|---|---|---|---|---|---|
| TC-24 | P1 | AC-2 | EXPIRED account, cart P-4999 | Checkout, select Standard | $5.99. Expired member gets non-member rate. |
| TC-25 | P1 | AC-3 | EXPIRED account, cart P-5000 | Checkout, select Express | $12.99 |
| TC-26 | P2 | AC-2, AC-3 | CANCELLED account (paid through future date), cart P-4999 | Checkout; check Standard then Express | Standard Free, Express $7.99 (per A2). Flag if product decides otherwise. |
| TC-27 | P2 | AC-2 | MEM account, cart P-4999 added while active; via admin set membership expiry to yesterday before opening checkout | Open checkout, select Standard | $5.99. Status evaluated at checkout time, not cart time. |
| TC-28 | P2 | AC-2 | NONMEM account, cart P-4999 in checkout showing $5.99 | In another tab purchase/activate membership; return and refresh checkout | Standard becomes Free, Express becomes $7.99. |

## 5. Subtotal composition

| ID | Pri | AC | Preconditions | Steps | Expected |
|---|---|---|---|---|---|
| TC-29 | P1 | AC-1 | NONMEM, cart P-5000 + P-010 ($60.00) | Checkout, Standard shows Free. Apply `SAVE10`. | Subtotal $50.00, Standard still Free (threshold inclusive after discount). |
| TC-30 | P1 | AC-1 | NONMEM, cart P-5001 + P-001 ($50.02) | Checkout, Standard shows Free. Apply `SAVE10`. | Subtotal $40.02, Standard changes to $5.99, total updates (per A1). Confirm rule with PO. |
| TC-31 | P2 | AC-1 | Continue from TC-30 | Remove the promo code | Standard returns to Free. |
| TC-32 | P1 | AC-1 | NONMEM, cart 47 × P-001 ... use P-4999 ($49.99); shipping address in a taxed state so total exceeds $50 | Checkout, Standard | $5.99. Tax does not count toward threshold. |
| TC-33 | P1 | AC-1 | NONMEM, cart P-4999 ($49.99), Standard $5.99 so total is $55.98 | Observe fee after total is computed | Fee stays $5.99. Shipping fee must not feed back into the subtotal check. |
| TC-34 | P2 | AC-1 | NONMEM, cart P-5000, gift card worth $30 on account | Checkout, apply gift card to payment | Standard remains Free. Payment tender does not alter subtotal. |
| TC-35 | P2 | AC-1 | NONMEM, cart P-010, apply `FREE100` | Checkout, Standard | Subtotal $0.00, fee $5.99 per literal AC-1. Flag to PO: charging shipping on a fully discounted order may be undesired. |
| TC-36 | P2 | AC-3 | MEM, cart P-010, apply `FREE100` | Checkout, Express | $7.99 |

## 6. Dynamic recalculation during checkout

| ID | Pri | AC | Preconditions | Steps | Expected |
|---|---|---|---|---|---|
| TC-37 | P1 | AC-1 | NONMEM, cart 4 × P-010 ($40.00) at checkout, Standard shows $5.99 | Increase quantity to 5 in the checkout order summary | Subtotal $50.00, fee becomes Free, total recalculated, no stale value after reload. |
| TC-38 | P1 | AC-1 | NONMEM, cart 5 × P-010 ($50.00), Standard Free | Decrease quantity to 4 | Fee becomes $5.99, total updates. |
| TC-39 | P1 | AC-1 | NONMEM, cart P-4999 + P-001 ($50.00), Standard Free | Remove P-001 | Fee becomes $5.99. |
| TC-40 | P1 | AC-1, AC-3 | NONMEM, cart P-5000 | Switch Standard → Express → Standard | Free → $12.99 → Free. Total updates each time. |
| TC-41 | P1 | AC-2, AC-3 | MEM, cart P-010 | Switch Standard → Express → Standard | Free → $7.99 → Free. |
| TC-42 | P1 | AC-2, AC-3 | GUEST, cart P-4999 at checkout, Standard $5.99 | Sign in as MEM from the checkout page | Cart retained, Standard becomes Free, Express option shows $7.99. |
| TC-43 | P2 | AC-1 | GUEST, cart P-4999 at checkout | Sign in as NONMEM | Standard remains $5.99, Express $12.99. |
| TC-44 | P2 | AC-1, AC-2 | MEM, cart P-4999 at checkout, Standard Free | Sign out, continue as guest with same cart | Standard becomes $5.99. Member discount does not persist across sign-out. |
| TC-45 | P2 | AC-1 to AC-3 | Any shopper with Express selected at checkout | Refresh the page, then navigate away and back to checkout | Selected method and fee persist and remain correct. |
| TC-46 | P2 | AC-1 | NONMEM, cart P-4999 at checkout | Change shipping address between two domestic addresses | Fee unchanged at $5.99 (fee is not address-dependent in scope). |

## 7. Order integrity and server authority

| ID | Pri | AC | Preconditions | Steps | Expected |
|---|---|---|---|---|---|
| TC-47 | P1 | All | One order per matrix row: NONMEM/$49.99/Standard, NONMEM/$50/Standard, MEM/$10/Standard, NONMEM/$50/Express, MEM/$10/Express | Complete each order. Compare fee on review step, payment authorisation amount, confirmation page, confirmation email, order record in admin/DB. | All five values match in every order. |
| TC-48 | P1 | All | Same orders as TC-47 | Verify `total = subtotal + shipping + tax` to the cent | Arithmetic correct, no rounding drift. |
| TC-49 | P1 | AC-3 | NONMEM, cart P-010, Express selected | Intercept the place-order request and change the shipping fee to 0.00 or to 7.99 | Server rejects the order or recalculates to $12.99. Charged amount is $12.99. |
| TC-50 | P1 | AC-2 | NONMEM, cart P-010, Standard | Intercept the rate request and set any client-side "isMember" flag to true | Server returns $5.99. Membership determined server-side. |
| TC-51 | P2 | AC-1 | NONMEM, cart P-5000, Standard Free | Intercept place-order and reduce an item quantity so subtotal is $40.00 while leaving fee at 0.00 | Server recomputes fee to $5.99 or rejects. |
| TC-52 | P2 | All | Shipping-rate API available | Call the rate endpoint directly for every row of the expected fee matrix plus boundaries $49.99/$50.00/$50.01 | Responses match the matrix. Candidate for automated regression. |

## 8. Display and presentation

| ID | Pri | AC | Preconditions | Steps | Expected |
|---|---|---|---|---|---|
| TC-53 | P2 | All | NONMEM, cart P-4999 | View the shipping method selector before choosing | Standard labelled $5.99, Express labelled $12.99. |
| TC-54 | P2 | All | NONMEM, cart P-5000 | View selector | Standard labelled Free, Express $12.99. |
| TC-55 | P2 | All | MEM, cart P-4999 | View selector | Standard labelled Free, Express $7.99. |
| TC-56 | P3 | All | Any | Inspect fee formatting across selector, summary, confirmation | Two decimals with "$", free shown as "Free" consistently (per A5), no "$0" vs "$0.00" mismatch. |
| TC-57 | P3 | All | Screen reader enabled | Trigger a fee change (TC-37 or TC-40) | Updated fee and total are announced; selector options expose price in accessible name. |
| TC-58 | P3 | All | Mobile viewport | Run TC-40 | Fee and total visible and updating without layout breakage. |

## 9. Traceability

| AC | Test cases |
|---|---|
| AC-1 Standard threshold | TC-01 to TC-11, TC-24, TC-29 to TC-35, TC-37 to TC-40, TC-43 to TC-54 |
| AC-2 Member free standard | TC-12 to TC-15, TC-26 to TC-28, TC-41, TC-42, TC-44, TC-50, TC-55 |
| AC-3 Express pricing | TC-16 to TC-23, TC-25, TC-26, TC-36, TC-40 to TC-42, TC-49, TC-53 to TC-55 |

## 10. Items to confirm with the product owner

1. Whether promo discounts reduce the subtotal used for the $50 threshold (A1, exercised by TC-29 to TC-31).
2. Whether a $0.00 subtotal after a 100% discount should still incur $5.99 standard shipping (TC-35).
3. Whether a cancelled-but-paid-through membership counts as a member (TC-26).
4. Whether any upsell messaging ("add $X for free shipping") is expected; it is excluded here.
