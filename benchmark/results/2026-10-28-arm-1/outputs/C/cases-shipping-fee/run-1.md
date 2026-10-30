# Test Cases for Shipping Fee at Checkout (SHIP-9)

## Standard Shipping – Non-Member

**TC-1: Free standard shipping when subtotal ≥ $50.00**
- Precondition: User is not a member
- Action: Add items totaling $50.00 to cart; proceed to checkout; select standard shipping
- Expected: Shipping fee displays as $0.00

**TC-2: Free standard shipping when subtotal > $50.00**
- Precondition: User is not a member
- Action: Add items totaling $75.00 to cart; proceed to checkout; select standard shipping
- Expected: Shipping fee displays as $0.00

**TC-3: $5.99 standard shipping when subtotal < $50.00**
- Precondition: User is not a member
- Action: Add items totaling $49.99 to cart; proceed to checkout; select standard shipping
- Expected: Shipping fee displays as $5.99

**TC-4: $5.99 standard shipping when subtotal is $0**
- Precondition: User is not a member
- Action: Proceed to checkout with no items; select standard shipping
- Expected: Shipping fee displays as $5.99

## Standard Shipping – Member

**TC-5: Free standard shipping for members at $0 subtotal**
- Precondition: User is a member
- Action: Proceed to checkout with no items; select standard shipping
- Expected: Shipping fee displays as $0.00

**TC-6: Free standard shipping for members at $49.99 subtotal**
- Precondition: User is a member
- Action: Add items totaling $49.99 to cart; proceed to checkout; select standard shipping
- Expected: Shipping fee displays as $0.00

**TC-7: Free standard shipping for members at $100 subtotal**
- Precondition: User is a member
- Action: Add items totaling $100.00 to cart; proceed to checkout; select standard shipping
- Expected: Shipping fee displays as $0.00

## Express Shipping – Non-Member

**TC-8: $12.99 express shipping for non-members at low subtotal**
- Precondition: User is not a member
- Action: Add items totaling $25.00 to cart; proceed to checkout; select express shipping
- Expected: Shipping fee displays as $12.99

**TC-9: $12.99 express shipping for non-members at high subtotal**
- Precondition: User is not a member
- Action: Add items totaling $500.00 to cart; proceed to checkout; select express shipping
- Expected: Shipping fee displays as $12.99

## Express Shipping – Member

**TC-10: $7.99 express shipping for members at low subtotal**
- Precondition: User is a member
- Action: Add items totaling $30.00 to cart; proceed to checkout; select express shipping
- Expected: Shipping fee displays as $7.99

**TC-11: $7.99 express shipping for members at high subtotal**
- Precondition: User is a member
- Action: Add items totaling $200.00 to cart; proceed to checkout; select express shipping
- Expected: Shipping fee displays as $7.99

## Boundary Tests

**TC-12: Boundary – exactly $50.00 triggers free shipping (non-member)**
- Precondition: User is not a member
- Action: Add items totaling exactly $50.00 to cart; proceed to checkout; select standard shipping
- Expected: Shipping fee displays as $0.00

**TC-13: Boundary – $49.99 requires shipping fee (non-member)**
- Precondition: User is not a member
- Action: Add items totaling $49.99 to cart; proceed to checkout; select standard shipping
- Expected: Shipping fee displays as $5.99

## Dynamic Scenarios

**TC-14: Member status upgrade during checkout**
- Precondition: User is not a member; cart has $30 subtotal
- Action: Add items to cart; log in as a new member; proceed to checkout; select standard shipping
- Expected: Shipping fee displays as $0.00

**TC-15: Shipping method toggle updates fee correctly**
- Precondition: User is a member; cart has $40 subtotal
- Action: Proceed to checkout; select standard shipping
- Expected: Shipping fee displays as $0.00
- Action: Change selection to express shipping
- Expected: Shipping fee updates to $7.99

## Assumptions

1. "Members" is a boolean account attribute indicating active membership status.
2. Subtotal means item prices only, before shipping and taxes.
3. The threshold "$50.00 or more" means ≥ $50.00 (inclusive).
4. Shipping fees are displayed separately from subtotal and total price.
5. No coupon codes, discounts, or promotions affect shipping fee calculation.
6. The checkout page displays two shipping options: standard and express.
7. The system correctly handles currency values to at least two decimal places.
8. Shipping fees are applied before final order confirmation.
