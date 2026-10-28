# Test cases: SHIP-9 Shipping fee at checkout

## Assumptions

- **Subtotal** means the total of item prices after item and cart discounts, before tax and shipping. Prices are in US dollars.
- **Member** means a shopper signed in to an account with an active membership. Guests and signed-in shoppers without a membership are **non-members**.
- Checkout shows two shipping options, labelled **Standard** and **Express**. **Standard** is selected by default.
- The fee appears next to the selected option and in the order summary as **Shipping**, with 2 decimal places, for example `$5.99`. Free shipping shows as `Free`.
- The fee is recalculated whenever the subtotal or the selected option changes, without a page reload.
- The $50.00 threshold compares the exact subtotal. There is no rounding to whole dollars.

## Test cases

| ID | Title | AC | Preconditions | Steps | Expected result |
| --- | --- | --- | --- | --- | --- |
| TC-01 | Non-member, standard, subtotal below threshold | AC-1 | Signed out. Cart subtotal $49.99. | 1. Go to checkout. 2. Keep **Standard** selected. | **Shipping** shows `$5.99`. Order total = $49.99 + tax + $5.99. |
| TC-02 | Non-member, standard, subtotal at threshold | AC-1 | Signed out. Cart subtotal $50.00. | 1. Go to checkout. 2. Keep **Standard** selected. | **Shipping** shows `Free`. Order total = $50.00 + tax. |
| TC-03 | Non-member, standard, subtotal above threshold | AC-1 | Signed out. Cart subtotal $120.00. | 1. Go to checkout. 2. Keep **Standard** selected. | **Shipping** shows `Free`. |
| TC-04 | Non-member, standard, one cent below threshold after discount | AC-1 | Signed out. Cart subtotal $55.00. Valid 10% discount code. | 1. Go to checkout. 2. Apply the discount code. 3. Keep **Standard** selected. | Subtotal becomes $49.50. **Shipping** changes to `$5.99` without a reload. |
| TC-05 | Non-member, standard, low-value cart | AC-1 | Signed out. Cart subtotal $0.99. | 1. Go to checkout. 2. Keep **Standard** selected. | **Shipping** shows `$5.99`. |
| TC-06 | Signed-in non-member, standard, below threshold | AC-1 | Signed in with no membership. Cart subtotal $30.00. | 1. Go to checkout. 2. Keep **Standard** selected. | **Shipping** shows `$5.99`. Being signed in does not grant the member rate. |
| TC-07 | Member, standard, subtotal below threshold | AC-2 | Signed in as a member. Cart subtotal $10.00. | 1. Go to checkout. 2. Keep **Standard** selected. | **Shipping** shows `Free`. |
| TC-08 | Member, standard, subtotal at threshold | AC-2 | Signed in as a member. Cart subtotal $50.00. | 1. Go to checkout. 2. Keep **Standard** selected. | **Shipping** shows `Free`. |
| TC-09 | Member, standard, subtotal above threshold | AC-2 | Signed in as a member. Cart subtotal $200.00. | 1. Go to checkout. 2. Keep **Standard** selected. | **Shipping** shows `Free`. |
| TC-10 | Non-member, express, subtotal below threshold | AC-3 | Signed out. Cart subtotal $20.00. | 1. Go to checkout. 2. Select **Express**. | **Shipping** shows `$12.99`. Order total = $20.00 + tax + $12.99. |
| TC-11 | Non-member, express, subtotal at threshold | AC-3 | Signed out. Cart subtotal $50.00. | 1. Go to checkout. 2. Select **Express**. | **Shipping** shows `$12.99`. The free standard threshold does not apply to express. |
| TC-12 | Non-member, express, subtotal above threshold | AC-3 | Signed out. Cart subtotal $500.00. | 1. Go to checkout. 2. Select **Express**. | **Shipping** shows `$12.99`. |
| TC-13 | Member, express, subtotal below threshold | AC-3 | Signed in as a member. Cart subtotal $20.00. | 1. Go to checkout. 2. Select **Express**. | **Shipping** shows `$7.99`. |
| TC-14 | Member, express, subtotal above threshold | AC-3 | Signed in as a member. Cart subtotal $150.00. | 1. Go to checkout. 2. Select **Express**. | **Shipping** shows `$7.99`. Express is never free for members. |
| TC-15 | Switch between standard and express | AC-1, AC-3 | Signed out. Cart subtotal $40.00. | 1. Go to checkout. 2. Select **Express**. 3. Select **Standard**. | Step 2: **Shipping** shows `$12.99`. Step 3: **Shipping** returns to `$5.99`. Order total updates each time. |
| TC-16 | Subtotal crosses threshold after removing an item | AC-1 | Signed out. Cart has 2 items, subtotal $60.00. Each item $30.00. | 1. Go to checkout. 2. Keep **Standard** selected. 3. Remove 1 item. | Step 2: **Shipping** shows `Free`. Step 3: subtotal is $30.00 and **Shipping** changes to `$5.99`. |
| TC-17 | Subtotal crosses threshold after adding quantity | AC-1 | Signed out. Cart has 1 item at $25.00. | 1. Go to checkout. 2. Keep **Standard** selected. 3. Change quantity to 2. | Step 2: **Shipping** shows `$5.99`. Step 3: subtotal is $50.00 and **Shipping** changes to `Free`. |
| TC-18 | Guest signs in as member during checkout | AC-1, AC-2 | Signed out. Cart subtotal $30.00. A member account exists. | 1. Go to checkout. 2. Keep **Standard** selected. 3. Sign in to the member account. | Step 2: **Shipping** shows `$5.99`. Step 3: **Shipping** changes to `Free`. |
| TC-19 | Guest signs in as member with express selected | AC-3 | Signed out. Cart subtotal $30.00. A member account exists. | 1. Go to checkout. 2. Select **Express**. 3. Sign in to the member account. | Step 2: **Shipping** shows `$12.99`. Step 3: **Shipping** changes to `$7.99` and **Express** stays selected. |
| TC-20 | Expired membership is treated as non-member | AC-2 | Signed in to an account whose membership expired yesterday. Cart subtotal $30.00. | 1. Go to checkout. 2. Keep **Standard** selected. 3. Select **Express**. | Step 2: **Shipping** shows `$5.99`. Step 3: **Shipping** shows `$12.99`. |
| TC-21 | Fee shown at checkout matches the placed order | AC-1, AC-3 | Signed out. Cart subtotal $40.00. Valid payment details. | 1. Go to checkout. 2. Select **Express**. 3. Place the order. 4. Open the order confirmation. | Confirmation shows **Shipping** `$12.99`, the same as checkout. Order total matches. |
| TC-22 | Fee format and rounding | AC-1 | Signed out. Cart subtotal $49.995 is not possible; use subtotal $49.99 and $50.00 as in TC-01 and TC-02. | 1. Check the **Shipping** line in both cases. | Fee shows with a currency symbol and exactly 2 decimal places. `Free` is shown as text, not `$0.00`, unless the product style guide says otherwise. |

## Traceability

| Acceptance criterion | Test cases |
| --- | --- |
| AC-1 Standard free at $50.00 or more, else $5.99 | TC-01, TC-02, TC-03, TC-04, TC-05, TC-06, TC-15, TC-16, TC-17, TC-18, TC-21, TC-22 |
| AC-2 Members get free standard at any subtotal | TC-07, TC-08, TC-09, TC-18, TC-20 |
| AC-3 Express $12.99, members $7.99 | TC-10, TC-11, TC-12, TC-13, TC-14, TC-15, TC-19, TC-20, TC-21 |

## Out of scope

- Tax calculation, except that the shipping fee is added to the total after tax is shown.
- Shipping to addresses outside the US, where different fees may apply.
- Promotions that grant free shipping by code rather than by subtotal or membership.

## Labels to confirm before running

- The shipping options are assumed to be labelled **Standard** and **Express**.
- The fee line is assumed to be labelled **Shipping** in the order summary.
- Free shipping is assumed to display as `Free`.
