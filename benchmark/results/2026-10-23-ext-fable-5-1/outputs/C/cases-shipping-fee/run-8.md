# Test cases: SHIP-9 Shipping fee at checkout

## Assumptions

The story does not define the following. These test cases use these assumptions until the product owner corrects them.

- **Subtotal** means the sum of item prices after item and order discounts, before tax and shipping.
- **$50.00 or more** includes exactly $50.00 (boundary is inclusive).
- **Member** means a shopper signed in to an account with an active membership. Guests and signed-in shoppers without membership are non-members.
- Only 2 shipping methods exist: **Standard** and **Express**. The shopper picks one at checkout.
- All amounts are in US dollars and display with 2 decimal places. Free shipping displays as **Free**, not **$0.00**.
- The shipping fee is shown on the checkout page as a **Shipping** line and is included in the **Order total**.
- The fee recalculates whenever the subtotal, membership status or shipping method changes during checkout.

## Expected fee matrix

| Shopper | Subtotal | Standard | Express |
| --- | --- | --- | --- |
| Non-member | Under $50.00 | $5.99 | $12.99 |
| Non-member | $50.00 or more | Free | $12.99 |
| Member | Any | Free | $7.99 |

## Test cases

### TC-01: Non-member, standard, subtotal below threshold (AC-1)

- **Preconditions:** Shopper is a guest. Cart subtotal is $25.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping.
- **Expected result:** **Shipping** shows **$5.99**. **Order total** equals subtotal plus $5.99 plus tax.

### TC-02: Non-member, standard, subtotal just below threshold (AC-1, boundary)

- **Preconditions:** Shopper is a guest. Cart subtotal is $49.99.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping.
- **Expected result:** **Shipping** shows **$5.99**.

### TC-03: Non-member, standard, subtotal exactly at threshold (AC-1, boundary)

- **Preconditions:** Shopper is a guest. Cart subtotal is $50.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping.
- **Expected result:** **Shipping** shows **Free**. **Order total** equals subtotal plus tax.

### TC-04: Non-member, standard, subtotal just above threshold (AC-1, boundary)

- **Preconditions:** Shopper is a guest. Cart subtotal is $50.01.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping.
- **Expected result:** **Shipping** shows **Free**.

### TC-05: Non-member, standard, large subtotal (AC-1)

- **Preconditions:** Shopper is a guest. Cart subtotal is $500.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping.
- **Expected result:** **Shipping** shows **Free**.

### TC-06: Signed-in non-member, standard, below threshold (AC-1, AC-2)

- **Preconditions:** Shopper is signed in to an account with no active membership. Cart subtotal is $30.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping.
- **Expected result:** **Shipping** shows **$5.99**. Signing in alone does not grant member pricing.

### TC-07: Member, standard, below threshold (AC-2)

- **Preconditions:** Shopper is signed in with an active membership. Cart subtotal is $10.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping.
- **Expected result:** **Shipping** shows **Free**.

### TC-08: Member, standard, at or above threshold (AC-2)

- **Preconditions:** Shopper is signed in with an active membership. Cart subtotal is $75.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping.
- **Expected result:** **Shipping** shows **Free**.

### TC-09: Non-member, express, below threshold (AC-3)

- **Preconditions:** Shopper is a guest. Cart subtotal is $25.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Express** shipping.
- **Expected result:** **Shipping** shows **$12.99**.

### TC-10: Non-member, express, at or above threshold (AC-3)

- **Preconditions:** Shopper is a guest. Cart subtotal is $120.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Express** shipping.
- **Expected result:** **Shipping** shows **$12.99**. The free-shipping threshold does not apply to express.

### TC-11: Member, express, below threshold (AC-3)

- **Preconditions:** Shopper is signed in with an active membership. Cart subtotal is $15.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Express** shipping.
- **Expected result:** **Shipping** shows **$7.99**.

### TC-12: Member, express, at or above threshold (AC-3)

- **Preconditions:** Shopper is signed in with an active membership. Cart subtotal is $200.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Express** shipping.
- **Expected result:** **Shipping** shows **$7.99**. Members never get free express shipping.

### TC-13: Switching shipping method updates the fee (AC-1, AC-3)

- **Preconditions:** Shopper is a guest. Cart subtotal is $60.00. **Standard** is selected and shows **Free**.
- **Steps:**
  1. Select **Express** shipping.
  2. Select **Standard** shipping again.
- **Expected result:** After step 1, **Shipping** shows **$12.99**. After step 2, **Shipping** shows **Free**. **Order total** updates each time.

### TC-14: Discount code drops subtotal below threshold (AC-1, assumption on subtotal)

- **Preconditions:** Shopper is a guest. Cart subtotal is $55.00. **Standard** is selected and shows **Free**.
- **Steps:**
  1. Apply a $10.00 discount code at checkout.
- **Expected result:** Subtotal becomes $45.00. **Shipping** changes to **$5.99**. Removing the code restores **Free**.

### TC-15: Removing an item at checkout drops subtotal below threshold (AC-1)

- **Preconditions:** Shopper is a guest. Cart has 2 items totalling $52.00. **Standard** shows **Free**.
- **Steps:**
  1. Remove an item worth $5.00 from the checkout page.
- **Expected result:** Subtotal becomes $47.00. **Shipping** changes to **$5.99** without a page reload.

### TC-16: Signing in as a member during checkout (AC-2)

- **Preconditions:** Shopper is a guest. Cart subtotal is $20.00. **Standard** shows **$5.99**.
- **Steps:**
  1. Sign in from the checkout page using a member account.
- **Expected result:** **Shipping** changes to **Free**. If **Express** is selected instead, the fee changes from **$12.99** to **$7.99**.

### TC-17: Expired membership is treated as non-member (AC-2, assumption on member)

- **Preconditions:** Shopper is signed in. Their membership expired yesterday. Cart subtotal is $20.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping.
- **Expected result:** **Shipping** shows **$5.99**.

### TC-18: Tax is excluded from the threshold check (AC-1, assumption on subtotal)

- **Preconditions:** Shopper is a guest in a region with sales tax. Cart subtotal is $48.00. Tax brings the pre-shipping total above $50.00.
- **Steps:**
  1. Go to checkout.
  2. Select **Standard** shipping.
- **Expected result:** **Shipping** shows **$5.99**. Tax does not count toward the $50.00 threshold.

### TC-19: Fee charged matches fee displayed (all ACs)

- **Preconditions:** Any case from TC-01 to TC-12.
- **Steps:**
  1. Complete the order.
  2. Open the order confirmation and the payment record.
- **Expected result:** The shipping fee on the confirmation and the amount charged match the fee shown at checkout.

## Out of scope

- Shipping to regions where **Express** is not offered.
- Currencies other than US dollars.
- Mixed carts with items that ship separately.
- How membership is purchased or renewed.
