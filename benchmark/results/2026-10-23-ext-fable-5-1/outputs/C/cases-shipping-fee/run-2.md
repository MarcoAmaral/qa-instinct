# Test cases: SHIP-9 Shipping fee at checkout

## Assumptions

- "Subtotal" means the sum of item prices after item-level discounts and promo codes, before tax and before the shipping fee. If the team defines subtotal differently, cases TC-02, TC-03 and TC-11 need their amounts rechecked.
- "Member" means a shopper signed in to an account with an active membership. A signed-in shopper without membership is treated the same as a guest.
- The checkout offers exactly two shipping options, **Standard** and **Express**, and the shopper picks one before paying.
- All amounts are in USD and shown to 2 decimal places. A free fee is displayed as **Free**, not **$0.00**. Confirm this label with the product team.
- The fee shown at checkout is the fee charged. Each case checks both the displayed fee and the order total.
- The boundary is inclusive: a subtotal of exactly $50.00 earns free standard shipping.

## Fee matrix

| Shopper | Subtotal | Standard | Express |
| --- | --- | --- | --- |
| Non-member | under $50.00 | $5.99 | $12.99 |
| Non-member | $50.00 or more | Free | $12.99 |
| Member | any | Free | $7.99 |

## Test cases

### TC-01: Non-member, subtotal below threshold, standard shipping (AC-1)

- **Preconditions:** Shopper is not signed in. Cart subtotal is $49.99.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping.
- **Expected:** Shipping fee shows **$5.99**. Order total equals $49.99 plus $5.99 plus tax.

### TC-02: Non-member, subtotal exactly at threshold, standard shipping (AC-1, boundary)

- **Preconditions:** Shopper is not signed in. Cart subtotal is $50.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping.
- **Expected:** Shipping fee shows **Free**. Order total equals $50.00 plus tax.

### TC-03: Non-member, subtotal one cent below threshold (AC-1, boundary)

- **Preconditions:** Shopper is not signed in. Cart subtotal is $49.99.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping.
- **Expected:** Shipping fee shows **$5.99**. The fee is not free.

### TC-04: Non-member, subtotal well above threshold, standard shipping (AC-1)

- **Preconditions:** Shopper is not signed in. Cart subtotal is $120.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping.
- **Expected:** Shipping fee shows **Free**.

### TC-05: Member, subtotal below threshold, standard shipping (AC-2)

- **Preconditions:** Shopper is signed in with an active membership. Cart subtotal is $10.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping.
- **Expected:** Shipping fee shows **Free**. Order total equals $10.00 plus tax.

### TC-06: Member, subtotal above threshold, standard shipping (AC-2)

- **Preconditions:** Shopper is signed in with an active membership. Cart subtotal is $75.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping.
- **Expected:** Shipping fee shows **Free**.

### TC-07: Non-member, subtotal below threshold, express shipping (AC-3)

- **Preconditions:** Shopper is not signed in. Cart subtotal is $20.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Express** shipping.
- **Expected:** Shipping fee shows **$12.99**. Order total equals $20.00 plus $12.99 plus tax.

### TC-08: Non-member, subtotal above threshold, express shipping (AC-3)

- **Preconditions:** Shopper is not signed in. Cart subtotal is $80.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Express** shipping.
- **Expected:** Shipping fee shows **$12.99**. The free standard threshold does not reduce the express fee.

### TC-09: Member, subtotal below threshold, express shipping (AC-3)

- **Preconditions:** Shopper is signed in with an active membership. Cart subtotal is $20.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Express** shipping.
- **Expected:** Shipping fee shows **$7.99**. Order total equals $20.00 plus $7.99 plus tax.

### TC-10: Member, subtotal above threshold, express shipping (AC-3)

- **Preconditions:** Shopper is signed in with an active membership. Cart subtotal is $80.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Express** shipping.
- **Expected:** Shipping fee shows **$7.99**, not **Free** and not **$12.99**.

### TC-11: Promo code drops subtotal below threshold (AC-1, assumption check)

- **Preconditions:** Shopper is not signed in. Cart subtotal is $55.00. A $10.00 promo code is available.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping. Confirm the fee shows **Free**.
  3. Apply the promo code.
- **Expected:** Subtotal becomes $45.00. Shipping fee updates to **$5.99** without a page reload.

### TC-12: Fee updates when the cart changes at checkout (AC-1)

- **Preconditions:** Shopper is not signed in. Cart subtotal is $45.00. **Standard** is selected.
- **Steps:**
  1. Go to checkout. Confirm the fee shows **$5.99**.
  2. Increase an item quantity so the subtotal reaches $50.00 or more.
- **Expected:** Shipping fee updates to **Free** and the order total reflects the change.

### TC-13: Fee updates when a member signs in during checkout (AC-2)

- **Preconditions:** Shopper is not signed in. Cart subtotal is $30.00. **Standard** is selected.
- **Steps:**
  1. Go to checkout. Confirm the fee shows **$5.99**.
  2. Sign in to an account with an active membership.
- **Expected:** Shipping fee updates to **Free**. The cart contents are unchanged.

### TC-14: Fee updates when switching between shipping options (AC-1, AC-3)

- **Preconditions:** Shopper is signed in with an active membership. Cart subtotal is $30.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Express**. Confirm the fee shows **$7.99**.
  3. Select **Standard**.
- **Expected:** Shipping fee shows **Free** and the order total drops by $7.99.

### TC-15: Signed-in shopper without membership is treated as a non-member (AC-2)

- **Preconditions:** Shopper is signed in to an account with no membership. Cart subtotal is $30.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping. Note the fee.
  3. Select **Express** shipping. Note the fee.
- **Expected:** Standard shows **$5.99**. Express shows **$12.99**.

### TC-16: Expired membership is treated as a non-member (AC-2, AC-3)

- **Preconditions:** Shopper is signed in to an account whose membership expired yesterday. Cart subtotal is $30.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping. Note the fee.
  3. Select **Express** shipping. Note the fee.
- **Expected:** Standard shows **$5.99**. Express shows **$12.99**.

### TC-17: Charged fee matches displayed fee (all ACs)

- **Preconditions:** Any shopper and subtotal from the fee matrix. A test payment method is available.
- **Steps:**
  1. Go to checkout and select a shipping option.
  2. Note the displayed shipping fee and order total.
  3. Complete the purchase.
- **Expected:** The order confirmation, the payment amount and the stored order record all show the same shipping fee and total as step 2.

### TC-18: Fee rounding and display format (all ACs)

- **Preconditions:** Shopper is not signed in. Cart subtotal is $49.995 or the closest amount the catalog allows, such as 3 items at $16.665.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping.
- **Expected:** The subtotal and fee are rounded to 2 decimal places using the store's standard rounding rule. The free threshold is judged on the rounded subtotal. Record the actual result if the catalog cannot produce a fractional cent.

## Traceability

| AC | Test cases |
| --- | --- |
| AC-1 | TC-01, TC-02, TC-03, TC-04, TC-11, TC-12, TC-14, TC-17, TC-18 |
| AC-2 | TC-05, TC-06, TC-13, TC-15, TC-16, TC-17 |
| AC-3 | TC-07, TC-08, TC-09, TC-10, TC-14, TC-15, TC-16, TC-17 |

## Open questions for the product owner

- Is the free standard fee displayed as **Free** or **$0.00**?
- Is subtotal measured before or after promo codes? TC-11 assumes after.
- Does any item type, such as oversized goods, override these fees? No case covers this because the story does not mention it.
