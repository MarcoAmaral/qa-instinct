# Test Cases for SHIP-9: Shipping Fee at Checkout

## Assumptions
- User types: Non-member (guest/registered customer without membership) and Member (active membership status)
- Shipping methods: Standard and Express
- Subtotal: Sum of item prices before shipping and taxes, in USD
- Cart minimum: Users can proceed to checkout with any subtotal ≥ $0
- Checkout flow: User selects shipping method, then views calculated shipping fee before payment

---

## Test Case 1: Non-Member Standard Shipping - Subtotal Below $50
**TC-1.1:** Subtotal $0.01, Standard Shipping Selected
- **Precondition:** Non-member user in checkout with items totaling $0.01
- **Steps:** Select Standard shipping method
- **Expected Result:** Shipping fee displays as $5.99
- **Priority:** High

**TC-1.2:** Subtotal $25.00, Standard Shipping Selected
- **Precondition:** Non-member user in checkout with items totaling $25.00
- **Steps:** Select Standard shipping method
- **Expected Result:** Shipping fee displays as $5.99
- **Priority:** High

**TC-1.3:** Subtotal $49.99, Standard Shipping Selected
- **Precondition:** Non-member user in checkout with items totaling $49.99
- **Steps:** Select Standard shipping method
- **Expected Result:** Shipping fee displays as $5.99
- **Priority:** High

---

## Test Case 2: Non-Member Standard Shipping - Subtotal $50 or More
**TC-2.1:** Subtotal $50.00, Standard Shipping Selected
- **Precondition:** Non-member user in checkout with items totaling exactly $50.00
- **Steps:** Select Standard shipping method
- **Expected Result:** Shipping fee displays as $0.00 (free)
- **Priority:** High

**TC-2.2:** Subtotal $50.01, Standard Shipping Selected
- **Precondition:** Non-member user in checkout with items totaling $50.01
- **Steps:** Select Standard shipping method
- **Expected Result:** Shipping fee displays as $0.00 (free)
- **Priority:** High

**TC-2.3:** Subtotal $100.00, Standard Shipping Selected
- **Precondition:** Non-member user in checkout with items totaling $100.00
- **Steps:** Select Standard shipping method
- **Expected Result:** Shipping fee displays as $0.00 (free)
- **Priority:** High

---

## Test Case 3: Member Standard Shipping - Any Subtotal
**TC-3.1:** Member, Subtotal $0.01, Standard Shipping Selected
- **Precondition:** Member user in checkout with items totaling $0.01
- **Steps:** Select Standard shipping method
- **Expected Result:** Shipping fee displays as $0.00 (free)
- **Priority:** High

**TC-3.2:** Member, Subtotal $25.00, Standard Shipping Selected
- **Precondition:** Member user in checkout with items totaling $25.00
- **Steps:** Select Standard shipping method
- **Expected Result:** Shipping fee displays as $0.00 (free)
- **Priority:** High

**TC-3.3:** Member, Subtotal $49.99, Standard Shipping Selected
- **Precondition:** Member user in checkout with items totaling $49.99
- **Steps:** Select Standard shipping method
- **Expected Result:** Shipping fee displays as $0.00 (free)
- **Priority:** High

**TC-3.4:** Member, Subtotal $150.00, Standard Shipping Selected
- **Precondition:** Member user in checkout with items totaling $150.00
- **Steps:** Select Standard shipping method
- **Expected Result:** Shipping fee displays as $0.00 (free)
- **Priority:** High

---

## Test Case 4: Non-Member Express Shipping
**TC-4.1:** Non-Member, Any Subtotal, Express Shipping Selected
- **Precondition:** Non-member user in checkout with items totaling $30.00
- **Steps:** Select Express shipping method
- **Expected Result:** Shipping fee displays as $12.99
- **Priority:** High

**TC-4.2:** Non-Member, Subtotal $0.01, Express Shipping Selected
- **Precondition:** Non-member user in checkout with items totaling $0.01
- **Steps:** Select Express shipping method
- **Expected Result:** Shipping fee displays as $12.99
- **Priority:** High

**TC-4.3:** Non-Member, Subtotal $500.00, Express Shipping Selected
- **Precondition:** Non-member user in checkout with items totaling $500.00
- **Steps:** Select Express shipping method
- **Expected Result:** Shipping fee displays as $12.99
- **Priority:** High

---

## Test Case 5: Member Express Shipping
**TC-5.1:** Member, Any Subtotal, Express Shipping Selected
- **Precondition:** Member user in checkout with items totaling $30.00
- **Steps:** Select Express shipping method
- **Expected Result:** Shipping fee displays as $7.99
- **Priority:** High

**TC-5.2:** Member, Subtotal $0.01, Express Shipping Selected
- **Precondition:** Member user in checkout with items totaling $0.01
- **Steps:** Select Express shipping method
- **Expected Result:** Shipping fee displays as $7.99
- **Priority:** High

**TC-5.3:** Member, Subtotal $500.00, Express Shipping Selected
- **Precondition:** Member user in checkout with items totaling $500.00
- **Steps:** Select Express shipping method
- **Expected Result:** Shipping fee displays as $7.99
- **Priority:** High

---

## Test Case 6: Shipping Method Switching
**TC-6.1:** Non-Member, Switch from Standard (below $50) to Express
- **Precondition:** Non-member user in checkout with items totaling $25.00, Standard shipping selected showing $5.99
- **Steps:** Change shipping method to Express
- **Expected Result:** Shipping fee updates to $12.99
- **Priority:** Medium

**TC-6.2:** Member, Switch from Express to Standard
- **Precondition:** Member user in checkout with items totaling $75.00, Express shipping selected showing $7.99
- **Steps:** Change shipping method to Standard
- **Expected Result:** Shipping fee updates to $0.00 (free)
- **Priority:** Medium

---

## Test Case 7: Edge Cases
**TC-7.1:** Non-Member, Subtotal with Decimal Cents ($49.99), Standard Shipping
- **Precondition:** Non-member user in checkout with items totaling $49.99
- **Steps:** Select Standard shipping method
- **Expected Result:** Shipping fee displays as $5.99
- **Priority:** Medium

**TC-7.2:** Non-Member, Subtotal with Decimal Cents ($50.01), Standard Shipping
- **Precondition:** Non-member user in checkout with items totaling $50.01
- **Steps:** Select Standard shipping method
- **Expected Result:** Shipping fee displays as $0.00 (free)
- **Priority:** Medium

**TC-7.3:** Order Total Display includes Shipping Fee
- **Precondition:** Non-member user in checkout with items totaling $40.00, Standard shipping selected ($5.99 fee)
- **Steps:** Verify order total calculation
- **Expected Result:** Order total displays as $45.99 (subtotal $40.00 + shipping $5.99)
- **Priority:** High

---

## Test Case 8: Membership Status Verification
**TC-8.1:** Newly Upgraded Member, Standard Shipping
- **Precondition:** User recently upgraded to membership, items totaling $30.00
- **Steps:** Select Standard shipping method
- **Expected Result:** Shipping fee displays as $0.00 (free), confirming membership status is active
- **Priority:** Medium

**TC-8.2:** Expired Member, Standard Shipping
- **Precondition:** User with expired membership, items totaling $30.00
- **Steps:** Select Standard shipping method
- **Expected Result:** Shipping fee displays as $5.99 (non-member rate)
- **Priority:** Medium

---

## Test Case 9: Regression Tests
**TC-9.1:** Verify Standard Shipping Logic Does Not Apply to Express
- **Precondition:** Non-member user in checkout with items totaling $75.00
- **Steps:** Select Express shipping method
- **Expected Result:** Shipping fee displays as $12.99 (not affected by $50+ threshold)
- **Priority:** High

**TC-9.2:** Verify Member Express Discount Does Not Apply to Standard
- **Precondition:** Member user in checkout with items totaling $0.01
- **Steps:** Select Standard shipping method
- **Expected Result:** Shipping fee displays as $0.00 (member standard rate, not member express rate of $7.99)
- **Priority:** High
