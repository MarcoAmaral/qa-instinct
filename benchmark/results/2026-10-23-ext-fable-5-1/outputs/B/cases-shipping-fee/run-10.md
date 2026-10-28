# Test Cases — SHIP-9: Shipping fee at checkout

## 1. Scope and assumptions

The story defines three rules. Where it is silent, the following assumptions apply to every test below. Each is flagged so it can be confirmed or corrected by the product owner.

| # | Assumption | Rationale |
|---|---|---|
| A1 | "Subtotal" means the sum of line-item prices after any item-level or cart-level promotional discounts, **before** tax and before shipping. | Common e-commerce convention; the story says "order subtotal", not "order total". |
| A2 | The $50.00 threshold is inclusive: $50.00 qualifies for free standard shipping, $49.99 does not. | AC-1 says "$50.00 or more". |
| A3 | "Member" means a shopper signed in to an account with an active membership at the moment the fee is calculated. Guests and signed-in non-members are both "non-members". | Story does not define membership; this is the most conservative reading. |
| A4 | Two shipping methods exist: Standard and Express. No other method is in scope. | Only these two are named. |
| A5 | Non-member express is a flat $12.99 regardless of subtotal; the $50 threshold does **not** apply to express. | AC-3 gives no threshold for express. |
| A6 | Currency is USD, displayed with two decimal places and a leading `$`. | All figures in the story are in USD. |
| A7 | The shipping fee is recalculated whenever the subtotal, shipping method, or membership status changes during checkout, and the displayed fee always matches the fee that is charged. | "So that I know what I will pay" implies the displayed figure must be the charged figure. |
| A8 | Empty carts cannot reach checkout, so subtotal $0.00 is tested only via a 100 % discount, not an empty cart. | Standard checkout behaviour. |

## 2. Fee matrix (expected results reference)

| Shopper type | Subtotal | Standard | Express |
|---|---|---|---|
| Non-member | < $50.00 | $5.99 | $12.99 |
| Non-member | ≥ $50.00 | $0.00 (Free) | $12.99 |
| Member | any | $0.00 (Free) | $7.99 |

## 3. Test data

| ID | Description |
|---|---|
| U-GUEST | Not signed in |
| U-NONMEM | Signed in, no membership |
| U-MEMBER | Signed in, active membership |
| U-EXPIRED | Signed in, membership expired yesterday |
| P-10 | Product priced $10.00 |
| P-49.99 | Product priced $49.99 |
| P-50 | Product priced $50.00 |
| P-0.01 | Product priced $0.01 |
| C-10OFF | Coupon: $10.00 off cart |
| C-100PCT | Coupon: 100 % off cart |

## 4. Test cases

Priority: **P1** = core AC / boundary, **P2** = important variation, **P3** = edge / UX.

---

### AC-1: Standard shipping threshold (non-members)

**TC-01 — Standard fee below threshold (P1)**
- Pre: U-GUEST, cart contains 1 × P-10 (subtotal $10.00).
- Steps: Proceed to checkout, select Standard shipping.
- Expected: Shipping fee displays **$5.99**; order total = $10.00 + $5.99 + tax.
- Covers: AC-1

**TC-02 — Standard fee at exact threshold boundary (P1)**
- Pre: U-GUEST, cart contains 1 × P-50 (subtotal $50.00).
- Steps: Checkout, select Standard.
- Expected: Shipping fee displays **$0.00 / "Free"**. (Confirms "or more" is inclusive — A2.)
- Covers: AC-1

**TC-03 — Standard fee one cent below threshold (P1)**
- Pre: U-GUEST, cart contains 1 × P-49.99 (subtotal $49.99).
- Steps: Checkout, select Standard.
- Expected: Shipping fee displays **$5.99**.
- Covers: AC-1

**TC-04 — Standard fee one cent above threshold (P2)**
- Pre: U-GUEST, cart contains 1 × P-50 + 1 × P-0.01 (subtotal $50.01).
- Steps: Checkout, select Standard.
- Expected: Shipping fee displays **$0.00 / "Free"**.
- Covers: AC-1

**TC-05 — Standard fee well above threshold (P2)**
- Pre: U-GUEST, cart contains 10 × P-50 (subtotal $500.00).
- Steps: Checkout, select Standard.
- Expected: Shipping fee **$0.00 / "Free"**.
- Covers: AC-1

**TC-06 — Signed-in non-member treated the same as guest (P1)**
- Pre: U-NONMEM, cart subtotal $10.00.
- Steps: Checkout, select Standard.
- Expected: Shipping fee **$5.99**. Signing in without membership grants no benefit.
- Covers: AC-1, AC-2 (negative)

**TC-07 — Threshold reached by quantity, not single item (P2)**
- Pre: U-GUEST, cart contains 5 × P-10 (subtotal $50.00).
- Steps: Checkout, select Standard.
- Expected: Shipping fee **$0.00 / "Free"**.
- Covers: AC-1

**TC-08 — Discount pulls subtotal below threshold (P1, depends on A1)**
- Pre: U-GUEST, cart contains 1 × P-50 (subtotal $50.00).
- Steps: Apply C-10OFF (subtotal becomes $40.00), select Standard.
- Expected: Shipping fee **$5.99**. Fee is based on post-discount subtotal.
- Covers: AC-1

**TC-09 — Discount applied after shipping method chosen recalculates fee (P1)**
- Pre: U-GUEST, cart subtotal $55.00, Standard selected, fee shows Free.
- Steps: Apply C-10OFF (subtotal $45.00).
- Expected: Fee updates to **$5.99** without page reload or re-selecting the method; order total updates accordingly.
- Covers: AC-1, A7

**TC-10 — Removing an item drops subtotal below threshold at checkout (P1)**
- Pre: U-GUEST, cart 2 × P-49.99 (subtotal $99.98), Standard selected, fee Free.
- Steps: From checkout, reduce quantity to 1 (subtotal $49.99).
- Expected: Fee updates to **$5.99**.
- Covers: AC-1, A7

**TC-11 — Adding an item lifts subtotal above threshold at checkout (P2)**
- Pre: U-GUEST, cart 1 × P-49.99, Standard selected, fee $5.99.
- Steps: Increase quantity to 2 (subtotal $99.98).
- Expected: Fee updates to **$0.00 / "Free"**.
- Covers: AC-1, A7

**TC-12 — Tax is excluded from threshold calculation (P2, depends on A1)**
- Pre: U-GUEST in a taxable region; cart 1 × P-49.99 so that subtotal + tax ≥ $50.00 but subtotal < $50.00.
- Steps: Checkout, select Standard.
- Expected: Fee **$5.99**. Tax does not count toward the threshold.
- Covers: AC-1

**TC-13 — Shipping fee itself is excluded from threshold (P3)**
- Pre: U-GUEST, cart subtotal $45.00.
- Steps: Select Standard (fee $5.99; subtotal + fee = $50.99).
- Expected: Fee remains **$5.99**; the fee must not feed back into the threshold check.
- Covers: AC-1

**TC-14 — Subtotal reduced to $0.00 by 100 % coupon (P3, depends on A8)**
- Pre: U-GUEST, cart 1 × P-10.
- Steps: Apply C-100PCT (subtotal $0.00), select Standard.
- Expected: Fee **$5.99** ($0.00 is below the threshold). Order total $5.99 + tax. No error.
- Covers: AC-1

---

### AC-2: Members get free standard shipping

**TC-15 — Member, standard, below threshold (P1)**
- Pre: U-MEMBER, cart subtotal $10.00.
- Steps: Checkout, select Standard.
- Expected: Fee **$0.00 / "Free"**.
- Covers: AC-2

**TC-16 — Member, standard, exact threshold (P2)**
- Pre: U-MEMBER, cart subtotal $50.00.
- Steps: Checkout, select Standard.
- Expected: Fee **$0.00 / "Free"**.
- Covers: AC-2

**TC-17 — Member, standard, above threshold (P2)**
- Pre: U-MEMBER, cart subtotal $500.00.
- Steps: Checkout, select Standard.
- Expected: Fee **$0.00 / "Free"**.
- Covers: AC-2

**TC-18 — Member, standard, minimum possible subtotal (P3)**
- Pre: U-MEMBER, cart 1 × P-0.01.
- Steps: Checkout, select Standard.
- Expected: Fee **$0.00 / "Free"**.
- Covers: AC-2

**TC-19 — Member discount does not stack into negative fee (P2)**
- Pre: U-MEMBER, cart subtotal $60.00 (qualifies for free standard under both AC-1 and AC-2).
- Steps: Checkout, select Standard.
- Expected: Fee **$0.00**, never negative; no double "free shipping" credit applied to the order total.
- Covers: AC-1, AC-2

**TC-20 — Expired membership treated as non-member (P1, depends on A3)**
- Pre: U-EXPIRED, cart subtotal $10.00.
- Steps: Checkout, select Standard.
- Expected: Fee **$5.99**.
- Covers: AC-2 (negative)

**TC-21 — Guest signs in as member during checkout (P1)**
- Pre: U-GUEST, cart subtotal $10.00, at checkout, Standard selected, fee $5.99.
- Steps: Sign in as U-MEMBER without leaving checkout.
- Expected: Fee updates to **$0.00 / "Free"**; order total updates.
- Covers: AC-2, A7

**TC-22 — Member signs out during checkout (P2)**
- Pre: U-MEMBER, subtotal $10.00, Standard, fee Free.
- Steps: Sign out, continue as guest with the same cart.
- Expected: Fee updates to **$5.99**.
- Covers: AC-2, A7

---

### AC-3: Express shipping

**TC-23 — Non-member, express, below threshold (P1)**
- Pre: U-GUEST, subtotal $10.00.
- Steps: Checkout, select Express.
- Expected: Fee **$12.99**.
- Covers: AC-3

**TC-24 — Non-member, express, at/above threshold (P1, depends on A5)**
- Pre: U-GUEST, subtotal $50.00.
- Steps: Checkout, select Express.
- Expected: Fee **$12.99**. The $50 free-shipping threshold does not apply to Express.
- Covers: AC-3

**TC-25 — Non-member, express, far above threshold (P2)**
- Pre: U-GUEST, subtotal $500.00.
- Steps: Checkout, select Express.
- Expected: Fee **$12.99**.
- Covers: AC-3

**TC-26 — Signed-in non-member, express (P2)**
- Pre: U-NONMEM, subtotal $10.00.
- Steps: Checkout, select Express.
- Expected: Fee **$12.99**.
- Covers: AC-3

**TC-27 — Member, express, below threshold (P1)**
- Pre: U-MEMBER, subtotal $10.00.
- Steps: Checkout, select Express.
- Expected: Fee **$7.99**.
- Covers: AC-3

**TC-28 — Member, express, at threshold (P2)**
- Pre: U-MEMBER, subtotal $50.00.
- Steps: Checkout, select Express.
- Expected: Fee **$7.99** (not free — member benefit on express is a discount, not a waiver).
- Covers: AC-3

**TC-29 — Member, express, far above threshold (P2)**
- Pre: U-MEMBER, subtotal $500.00.
- Steps: Checkout, select Express.
- Expected: Fee **$7.99**.
- Covers: AC-3

**TC-30 — Expired member, express (P2)**
- Pre: U-EXPIRED, subtotal $10.00.
- Steps: Checkout, select Express.
- Expected: Fee **$12.99**.
- Covers: AC-3 (negative)

**TC-31 — Guest signs in as member with Express selected (P2)**
- Pre: U-GUEST, subtotal $10.00, Express selected, fee $12.99.
- Steps: Sign in as U-MEMBER during checkout.
- Expected: Fee updates to **$7.99**.
- Covers: AC-3, A7

---

### Method switching and recalculation

**TC-32 — Non-member switches Standard → Express → Standard, subtotal below threshold (P1)**
- Pre: U-GUEST, subtotal $10.00.
- Steps: Select Standard; select Express; select Standard again.
- Expected: Fee shows $5.99 → $12.99 → $5.99. Order total updates each time. No stale value.
- Covers: AC-1, AC-3

**TC-33 — Non-member switches methods, subtotal above threshold (P1)**
- Pre: U-GUEST, subtotal $60.00.
- Steps: Select Standard; select Express; select Standard.
- Expected: Fee shows Free → $12.99 → Free.
- Covers: AC-1, AC-3

**TC-34 — Member switches methods (P1)**
- Pre: U-MEMBER, subtotal $10.00.
- Steps: Select Standard; select Express; select Standard.
- Expected: Fee shows Free → $7.99 → Free.
- Covers: AC-2, AC-3

**TC-35 — Default shipping method shows correct fee on first load of checkout (P1)**
- Pre: Each of U-GUEST (subtotal $10), U-GUEST (subtotal $60), U-MEMBER (subtotal $10).
- Steps: Land on checkout without interacting.
- Expected: Whatever method is pre-selected, its fee matches the matrix; the fee is never blank, "—", or $0.00 for a case that should be $5.99/$12.99.
- Covers: AC-1, AC-2, AC-3

**TC-36 — Fee shown in method selector matches fee in order summary (P1)**
- Pre: Any user/subtotal combination.
- Steps: Observe fee next to each shipping option and the "Shipping" line in the order summary after selecting each.
- Expected: Both locations always show the same value for the selected method.
- Covers: A7

---

### Charged amount matches displayed amount

**TC-37 — Placed order charges displayed standard fee, non-member (P1)**
- Pre: U-GUEST, subtotal $10.00, Standard.
- Steps: Complete payment; inspect order confirmation, payment gateway record, and order record in admin/DB.
- Expected: Shipping line = **$5.99** in all three places; total charged = displayed total.
- Covers: AC-1, A7

**TC-38 — Placed order charges $0.00 standard, member (P1)**
- Pre: U-MEMBER, subtotal $10.00, Standard.
- Steps: Complete payment; inspect records.
- Expected: Shipping line = **$0.00** everywhere.
- Covers: AC-2, A7

**TC-39 — Placed order charges $7.99 express, member (P1)**
- Pre: U-MEMBER, subtotal $10.00, Express.
- Steps: Complete payment; inspect records.
- Expected: Shipping line = **$7.99** everywhere.
- Covers: AC-3, A7

**TC-40 — Placed order charges $12.99 express, non-member above threshold (P2)**
- Pre: U-GUEST, subtotal $60.00, Express.
- Steps: Complete payment; inspect records.
- Expected: Shipping line = **$12.99** everywhere.
- Covers: AC-3, A7

**TC-41 — Server-side validation rejects tampered fee (P1, security)**
- Pre: U-GUEST, subtotal $10.00, Standard.
- Steps: Intercept the place-order request and alter the shipping fee to $0.00 (or the method to Standard while claiming member pricing).
- Expected: Server recalculates the fee from subtotal + method + membership and either charges **$5.99** or rejects the order. Client-supplied fee is never trusted.
- Covers: AC-1, AC-2, AC-3

**TC-42 — Membership lapses between checkout display and order submission (P3)**
- Pre: U-MEMBER whose membership expires in 1 minute; subtotal $10.00; Standard selected, fee Free.
- Steps: Wait until expiry, then place the order.
- Expected: Defined behaviour, one of: (a) fee re-evaluated to $5.99 and shopper is shown the updated total before charge, or (b) displayed fee honoured. Shopper must not be silently charged more than displayed. (Flag to PO: story does not specify; test records actual behaviour.)
- Covers: AC-2, A7

---

### Display, formatting, and messaging

**TC-43 — Free fee is displayed clearly (P2)**
- Pre: U-GUEST, subtotal $60.00, Standard.
- Steps: Observe shipping fee.
- Expected: Displayed as "Free" or "$0.00" (per design); not blank, not "$0", not "-".
- Covers: AC-1, AC-2

**TC-44 — Fees formatted to two decimals with currency symbol (P2)**
- Pre: Each fee value ($5.99, $12.99, $7.99).
- Steps: Observe formatting in selector and summary.
- Expected: Exactly `$5.99`, `$12.99`, `$7.99`. No `$5.990`, `5.99`, or `$5.9`.
- Covers: AC-1, AC-3, A6

**TC-45 — Threshold nudge message (if present) is accurate (P3)**
- Pre: U-GUEST, subtotal $45.01.
- Steps: Observe any "Add $X for free shipping" message.
- Expected: If shown, X = **$4.99**. Not shown to members or when subtotal ≥ $50.00. (If no such message exists, mark N/A.)
- Covers: AC-1

**TC-46 — Member benefit messaging does not appear for non-members (P3)**
- Pre: U-GUEST and U-NONMEM.
- Steps: Observe checkout shipping section.
- Expected: No text implies the shopper receives member pricing.
- Covers: AC-2, AC-3

---

### Precision and rounding

**TC-47 — Floating-point subtotal lands exactly on threshold (P2)**
- Pre: U-GUEST, cart 3 × $16.67 (= $50.01) and separately 3 × $16.66 (= $49.98).
- Steps: Checkout, select Standard for each.
- Expected: $50.01 → **Free**; $49.98 → **$5.99**. No off-by-a-cent error from float arithmetic.
- Covers: AC-1

**TC-48 — Percentage discount producing fractional cents (P3)**
- Pre: U-GUEST, cart $55.55, coupon 10 % off (subtotal $49.995 before rounding).
- Steps: Checkout, select Standard.
- Expected: Fee follows the **rounded, displayed** subtotal: if displayed $50.00 → Free; if displayed $49.99 → $5.99. Fee must agree with the subtotal the shopper sees.
- Covers: AC-1

---

### Regression / cross-feature

**TC-49 — Cart page estimate matches checkout fee (P2)**
- Pre: Any combination from the fee matrix.
- Steps: Note any shipping estimate shown on the cart page; proceed to checkout.
- Expected: Checkout fee equals the cart estimate for the same method and membership state.
- Covers: AC-1, AC-2, AC-3

**TC-50 — Fee correct across supported browsers/devices (P2)**
- Pre: TC-01, TC-15, TC-27 as a smoke set.
- Steps: Execute on desktop Chrome, Firefox, Safari; mobile Safari, Android Chrome.
- Expected: Identical fees and formatting on all.
- Covers: AC-1, AC-2, AC-3

**TC-51 — Fee persists through page reload at checkout (P3)**
- Pre: U-GUEST, subtotal $10.00, Express selected, fee $12.99.
- Steps: Reload checkout page.
- Expected: Express still selected (or default restored), fee displayed matches the matrix for whichever method is selected.
- Covers: A7

## 5. Traceability

| AC | Test cases |
|---|---|
| AC-1 | TC-01–14, 19, 32, 33, 35–37, 41, 43–45, 47–50 |
| AC-2 | TC-06, 15–22, 34, 35, 38, 41–43, 46, 49, 50 |
| AC-3 | TC-23–35, 39–41, 44, 46, 49, 50 |

## 6. Out of scope / open questions for the Product Owner

1. Confirm A1: is the threshold evaluated on post-discount subtotal? (Drives TC-08, TC-09, TC-14, TC-48.)
2. Confirm A3: do expired, paused, or trial memberships count as "member"?
3. Confirm expected behaviour for TC-42 (membership change between display and charge).
4. Are there region or product restrictions (e.g., oversized items, international addresses) that alter fees? None are in the story; not tested here.
5. Is there a "free shipping" promotion or gift-card interaction that could stack with these rules? Not tested here.
