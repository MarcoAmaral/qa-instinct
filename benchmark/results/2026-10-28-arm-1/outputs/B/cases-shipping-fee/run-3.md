# Test Cases for SHIP-9: Shipping Fee at Checkout

## Assumptions
- Two customer types: Members and Non-members
- Two shipping methods available: Standard and Express
- Subtotal is calculated before shipping fees
- Shipping method is selected during checkout before final payment
- Currency is USD with two decimal places
- One order per checkout session
- Shipping fees are presented before payment confirmation

---

## Test Cases

### Standard Shipping - Non-member Scenarios

**TC-SHIP-001: Standard shipping free for non-member at $50.00 subtotal (boundary)**
- **Precondition:** User is not a member; cart subtotal is exactly $50.00
- **Steps:** 
  1. Add items to cart totaling $50.00
  2. Proceed to checkout
  3. Select standard shipping
- **Expected Result:** Shipping fee displays as $0.00

**TC-SHIP-002: Standard shipping free for non-member above $50.00**
- **Precondition:** User is not a member; cart subtotal is $75.50
- **Steps:** 
  1. Add items to cart totaling $75.50
  2. Proceed to checkout
  3. Select standard shipping
- **Expected Result:** Shipping fee displays as $0.00

**TC-SHIP-003: Standard shipping charged $5.99 for non-member below $50.00**
- **Precondition:** User is not a member; cart subtotal is $49.99
- **Steps:** 
  1. Add items to cart totaling $49.99
  2. Proceed to checkout
  3. Select standard shipping
- **Expected Result:** Shipping fee displays as $5.99

**TC-SHIP-004: Standard shipping charged $5.99 for non-member at $0.01 subtotal**
- **Precondition:** User is not a member; cart subtotal is $0.01
- **Steps:** 
  1. Add item to cart totaling $0.01
  2. Proceed to checkout
  3. Select standard shipping
- **Expected Result:** Shipping fee displays as $5.99

---

### Standard Shipping - Member Scenarios

**TC-SHIP-005: Standard shipping free for member at low subtotal**
- **Precondition:** User is a member; cart subtotal is $10.00
- **Steps:** 
  1. Log in as member
  2. Add items to cart totaling $10.00
  3. Proceed to checkout
  4. Select standard shipping
- **Expected Result:** Shipping fee displays as $0.00

**TC-SHIP-006: Standard shipping free for member at $50.00 subtotal**
- **Precondition:** User is a member; cart subtotal is $50.00
- **Steps:** 
  1. Log in as member
  2. Add items to cart totaling $50.00
  3. Proceed to checkout
  4. Select standard shipping
- **Expected Result:** Shipping fee displays as $0.00

**TC-SHIP-007: Standard shipping free for member above $50.00**
- **Precondition:** User is a member; cart subtotal is $200.00
- **Steps:** 
  1. Log in as member
  2. Add items to cart totaling $200.00
  3. Proceed to checkout
  4. Select standard shipping
- **Expected Result:** Shipping fee displays as $0.00

---

### Express Shipping - Non-member Scenarios

**TC-SHIP-008: Express shipping costs $12.99 for non-member at low subtotal**
- **Precondition:** User is not a member; cart subtotal is $25.00
- **Steps:** 
  1. Add items to cart totaling $25.00
  2. Proceed to checkout
  3. Select express shipping
- **Expected Result:** Shipping fee displays as $12.99

**TC-SHIP-009: Express shipping costs $12.99 for non-member above $50.00**
- **Precondition:** User is not a member; cart subtotal is $100.00
- **Steps:** 
  1. Add items to cart totaling $100.00
  2. Proceed to checkout
  3. Select express shipping
- **Expected Result:** Shipping fee displays as $12.99

---

### Express Shipping - Member Scenarios

**TC-SHIP-010: Express shipping costs $7.99 for member at low subtotal**
- **Precondition:** User is a member; cart subtotal is $25.00
- **Steps:** 
  1. Log in as member
  2. Add items to cart totaling $25.00
  3. Proceed to checkout
  4. Select express shipping
- **Expected Result:** Shipping fee displays as $7.99

**TC-SHIP-011: Express shipping costs $7.99 for member above $50.00**
- **Precondition:** User is a member; cart subtotal is $100.00
- **Steps:** 
  1. Log in as member
  2. Add items to cart totaling $100.00
  3. Proceed to checkout
  4. Select express shipping
- **Expected Result:** Shipping fee displays as $7.99

---

### Order Total Calculation

**TC-SHIP-012: Order total correctly includes standard shipping for non-member**
- **Precondition:** User is not a member; cart subtotal is $49.99
- **Steps:** 
  1. Add items to cart totaling $49.99
  2. Proceed to checkout
  3. Select standard shipping
  4. Verify order total line item breakdown
- **Expected Result:** Subtotal: $49.99, Shipping: $5.99, Total: $55.98

**TC-SHIP-013: Order total correctly excludes standard shipping for qualifying non-member**
- **Precondition:** User is not a member; cart subtotal is $50.00
- **Steps:** 
  1. Add items to cart totaling $50.00
  2. Proceed to checkout
  3. Select standard shipping
  4. Verify order total line item breakdown
- **Expected Result:** Subtotal: $50.00, Shipping: $0.00, Total: $50.00

**TC-SHIP-014: Order total correctly includes express shipping for member**
- **Precondition:** User is a member; cart subtotal is $50.00
- **Steps:** 
  1. Log in as member
  2. Add items to cart totaling $50.00
  3. Proceed to checkout
  4. Select express shipping
  5. Verify order total line item breakdown
- **Expected Result:** Subtotal: $50.00, Shipping: $7.99, Total: $57.99

---

### Shipping Method Changes

**TC-SHIP-015: Shipping fee updates when switching from standard to express**
- **Precondition:** User is not a member; cart subtotal is $75.00; standard shipping ($0.00) is selected
- **Steps:** 
  1. Add items to cart totaling $75.00
  2. Proceed to checkout
  3. Verify standard shipping shows $0.00
  4. Change to express shipping
- **Expected Result:** Shipping fee updates to $12.99; order total increases accordingly

**TC-SHIP-016: Shipping fee updates when switching from express to standard**
- **Precondition:** User is a member; cart subtotal is $30.00; express shipping ($7.99) is selected
- **Steps:** 
  1. Log in as member
  2. Add items to cart totaling $30.00
  3. Proceed to checkout
  4. Verify express shipping shows $7.99
  5. Change to standard shipping
- **Expected Result:** Shipping fee updates to $0.00; order total decreases by $7.99

---

### Edge Cases and Data Validation

**TC-SHIP-017: Shipping calculation with fractional cent amounts**
- **Precondition:** User is not a member; cart subtotal is $49.99
- **Steps:** 
  1. Add items to cart totaling $49.99
  2. Proceed to checkout
  3. Select standard shipping
- **Expected Result:** Shipping fee displays exactly $5.99 with no rounding errors; total is $55.98

**TC-SHIP-018: Shipping fee displays correctly for very large order**
- **Precondition:** User is not a member; cart subtotal is $10,000.00
- **Steps:** 
  1. Add items to cart totaling $10,000.00
  2. Proceed to checkout
  3. Select standard shipping
- **Expected Result:** Shipping fee displays as $0.00

**TC-SHIP-019: Membership status correctly applied at checkout**
- **Precondition:** User logs in as member after adding items as guest
- **Steps:** 
  1. Add items to cart totaling $30.00 (as guest)
  2. Log in as member before checkout
  3. Proceed to checkout
  4. Select express shipping
- **Expected Result:** Shipping fee displays $7.99 (member rate), not $12.99

**TC-SHIP-020: Non-member rate applied when logged out**
- **Precondition:** User logs out during checkout after being logged in as member
- **Steps:** 
  1. Log in as member
  2. Add items to cart totaling $30.00
  3. Proceed to checkout
  4. Log out or end session
  5. Complete checkout as guest
  6. Select express shipping
- **Expected Result:** Shipping fee displays $12.99 (non-member rate)
