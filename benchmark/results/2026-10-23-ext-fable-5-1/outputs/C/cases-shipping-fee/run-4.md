# Test cases: SHIP-9 Shipping fee at checkout

## Assumptions

The story does not define these points. Each test below follows these assumptions until the product owner corrects them.

- **Subtotal** means the sum of item prices after item-level discounts and promo codes, before tax and before the shipping fee.
- **Member** means a shopper who is signed in and has an active membership. A signed-in shopper without a membership is treated the same as a guest.
- **Standard** and **Express** are the only shipping options, and they appear as radio buttons labelled **Standard** and **Express** in the **Shipping method** section of checkout.
- Free shipping displays as **Free**, not as **$0.00**.
- Prices are in US dollars and rounding is to the cent.
- The shipping fee updates without a page reload when the cart or the selected method changes.
- An expired or cancelled membership counts as non-member from the moment it ends.

## Test data

| ID | Shopper | Subtotal |
| --- | --- | --- |
| D1 | Guest | $49.99 |
| D2 | Guest | $50.00 |
| D3 | Guest | $50.01 |
| D4 | Guest | $0.01 |
| D5 | Signed in, no membership | $49.99 |
| D6 | Member | $0.01 |
| D7 | Member | $49.99 |
| D8 | Member | $50.00 |
| D9 | Member | $500.00 |
| D10 | Shopper with expired membership | $49.99 |

## AC-1: Standard shipping for non-members

**TC-01 Standard fee just below the threshold**
Preconditions: D1.
Steps: Open checkout. Select **Standard**.
Expected: Shipping fee shows **$5.99**. Order total equals subtotal plus $5.99 plus tax.

**TC-02 Standard fee exactly at the threshold**
Preconditions: D2.
Steps: Open checkout. Select **Standard**.
Expected: Shipping fee shows **Free**. Order total equals subtotal plus tax.

**TC-03 Standard fee just above the threshold**
Preconditions: D3.
Steps: Open checkout. Select **Standard**.
Expected: Shipping fee shows **Free**.

**TC-04 Standard fee at the lowest possible subtotal**
Preconditions: D4.
Steps: Open checkout. Select **Standard**.
Expected: Shipping fee shows **$5.99**.

**TC-05 Signed-in non-member is charged like a guest**
Preconditions: D5.
Steps: Open checkout. Select **Standard**.
Expected: Shipping fee shows **$5.99**.

**TC-06 Fee drops to free when the cart crosses the threshold**
Preconditions: D1, checkout open with **Standard** selected and **$5.99** shown.
Steps: Increase an item quantity so the subtotal becomes $50.00 or more.
Expected: Shipping fee changes to **Free** without a page reload. Order total updates.

**TC-07 Fee returns when the cart drops below the threshold**
Preconditions: D2, checkout open with **Standard** selected and **Free** shown.
Steps: Remove an item so the subtotal falls to $49.99 or less.
Expected: Shipping fee changes to **$5.99**. Order total updates.

**TC-08 Promo code that pushes the subtotal below the threshold**
Preconditions: Guest, subtotal $55.00, a promo code worth $10.00 off items.
Steps: Select **Standard**. Apply the promo code.
Expected: Subtotal shows $45.00. Shipping fee changes from **Free** to **$5.99**.

**TC-09 Threshold ignores tax**
Preconditions: Guest, subtotal $48.00, shipping address in a region with sales tax that brings the taxed amount above $50.00.
Steps: Select **Standard**.
Expected: Shipping fee shows **$5.99**. Tax is not counted toward the threshold.

## AC-2: Standard shipping for members

**TC-10 Member below the threshold**
Preconditions: D7.
Steps: Open checkout. Select **Standard**.
Expected: Shipping fee shows **Free**.

**TC-11 Member at the lowest possible subtotal**
Preconditions: D6.
Steps: Open checkout. Select **Standard**.
Expected: Shipping fee shows **Free**.

**TC-12 Member at and above the threshold**
Preconditions: D8, then D9.
Steps: Open checkout. Select **Standard**.
Expected: Shipping fee shows **Free** in both cases.

**TC-13 Fee updates when a guest signs in as a member**
Preconditions: D1, checkout open with **Standard** selected and **$5.99** shown.
Steps: Sign in with a member account. Return to checkout.
Expected: Shipping fee shows **Free**. The cart contents are unchanged.

**TC-14 Expired membership pays the non-member fee**
Preconditions: D10.
Steps: Open checkout. Select **Standard**.
Expected: Shipping fee shows **$5.99**.

## AC-3: Express shipping

**TC-15 Guest express below the threshold**
Preconditions: D1.
Steps: Open checkout. Select **Express**.
Expected: Shipping fee shows **$12.99**.

**TC-16 Guest express at and above the threshold**
Preconditions: D2, then D3.
Steps: Open checkout. Select **Express**.
Expected: Shipping fee shows **$12.99** in both cases. The $50.00 threshold does not apply to express.

**TC-17 Signed-in non-member express**
Preconditions: D5.
Steps: Open checkout. Select **Express**.
Expected: Shipping fee shows **$12.99**.

**TC-18 Member express below the threshold**
Preconditions: D6, then D7.
Steps: Open checkout. Select **Express**.
Expected: Shipping fee shows **$7.99** in both cases.

**TC-19 Member express at and above the threshold**
Preconditions: D8, then D9.
Steps: Open checkout. Select **Express**.
Expected: Shipping fee shows **$7.99** in both cases. Express is never free for members.

**TC-20 Expired membership pays the non-member express fee**
Preconditions: D10.
Steps: Open checkout. Select **Express**.
Expected: Shipping fee shows **$12.99**.

**TC-21 Switching methods updates the fee**
Preconditions: D7, checkout open with **Standard** selected and **Free** shown.
Steps: Select **Express**. Then select **Standard** again.
Expected: Fee shows **$7.99** after the first step and **Free** after the second. Order total updates each time.

## Order total and persistence

**TC-22 Fee shown at checkout matches the order confirmation**
Preconditions: One shopper from each of D1, D2, D7 and D9.
Steps: Select a method. Place the order.
Expected: The shipping fee on the confirmation page and in the confirmation email equals the fee shown at checkout.

**TC-23 Fee is recalculated on the server**
Preconditions: D1.
Steps: Select **Standard**. Using browser developer tools, change the displayed fee to $0.00 and submit the order.
Expected: The order is charged **$5.99** for shipping, or the order is rejected. The client-side value is not trusted.

**TC-24 Fee survives a page reload**
Preconditions: D1, **Express** selected.
Steps: Reload the checkout page.
Expected: **Express** remains selected and the fee still shows **$12.99**.

## Coverage summary

| Acceptance criterion | Test cases |
| --- | --- |
| AC-1 | TC-01 to TC-09, TC-14 |
| AC-2 | TC-10 to TC-14 |
| AC-3 | TC-15 to TC-21 |
| Cross-cutting | TC-22 to TC-24 |

## Open questions for the product owner

These do not block testing but each could change an expected result.

- Does the threshold use the subtotal before or after promo codes? TC-08 assumes after.
- Does a signed-in shopper without a membership see any different treatment from a guest? TC-05 and TC-17 assume no.
- Are there other shipping methods, regions or item types, such as oversized items, that override these fees?
- Should the fee show as **Free** or **$0.00**?
