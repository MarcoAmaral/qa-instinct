# Test Cases for SHIP-9: Shipping fee at checkout

**Assumptions:**
- "Members" refers to logged-in users with an active membership status
- "Order subtotal" excludes shipping and taxes
- Both Standard and Express shipping options are available at checkout
- Shipping fees display before order confirmation
- Membership status is confirmed before checkout
- Currency is USD
- Rules apply globally (no geographic restrictions)

## Test Case: TC-1.1 - Standard Shipping: Non-member, subtotal below threshold

| Field | Value |
| --- | --- |
| Precondition | Non-member user, not logged in or membership inactive |
| Steps | 1. Add items totaling $49.99 to cart<br>2. Proceed to checkout<br>3. Select Standard shipping |
| Expected Result | Shipping fee displays as $5.99 |
| Acceptance Criteria | AC-1 |

## Test Case: TC-1.2 - Standard Shipping: Non-member, subtotal at threshold

| Field | Value |
| --- | --- |
| Precondition | Non-member user |
| Steps | 1. Add items totaling exactly $50.00 to cart<br>2. Proceed to checkout<br>3. Select Standard shipping |
| Expected Result | Shipping fee displays as $0.00 (free) |
| Acceptance Criteria | AC-1 |

## Test Case: TC-1.3 - Standard Shipping: Non-member, subtotal above threshold

| Field | Value |
| --- | --- |
| Precondition | Non-member user |
| Steps | 1. Add items totaling $150.00 to cart<br>2. Proceed to checkout<br>3. Select Standard shipping |
| Expected Result | Shipping fee displays as $0.00 (free) |
| Acceptance Criteria | AC-1 |

## Test Case: TC-2.1 - Standard Shipping: Member, subtotal below threshold

| Field | Value |
| --- | --- |
| Precondition | Member user logged in with active membership, items totaling $25.00 |
| Steps | 1. Proceed to checkout<br>2. Confirm membership is active<br>3. Select Standard shipping |
| Expected Result | Shipping fee displays as $0.00 (free) |
| Acceptance Criteria | AC-2 |

## Test Case: TC-2.2 - Standard Shipping: Member, subtotal above threshold

| Field | Value |
| --- | --- |
| Precondition | Member user logged in with active membership, items totaling $100.00 |
| Steps | 1. Proceed to checkout<br>2. Confirm membership is active<br>3. Select Standard shipping |
| Expected Result | Shipping fee displays as $0.00 (free) |
| Acceptance Criteria | AC-2 |

## Test Case: TC-3.1 - Express Shipping: Non-member, any subtotal

| Field | Value |
| --- | --- |
| Precondition | Non-member user, any subtotal |
| Steps | 1. Add any items to cart<br>2. Proceed to checkout<br>3. Select Express shipping |
| Expected Result | Shipping fee displays as $12.99 |
| Acceptance Criteria | AC-3 |

## Test Case: TC-3.2 - Express Shipping: Member, any subtotal

| Field | Value |
| --- | --- |
| Precondition | Member user logged in with active membership, any subtotal |
| Steps | 1. Add any items to cart<br>2. Proceed to checkout<br>3. Confirm membership is active<br>4. Select Express shipping |
| Expected Result | Shipping fee displays as $7.99 |
| Acceptance Criteria | AC-3 |

## Test Case: TC-4.1 - Shipping method change: Mid-checkout

| Field | Value |
| --- | --- |
| Precondition | User at checkout with Standard shipping selected ($5.99 shown) |
| Steps | 1. Change selection from Standard to Express shipping<br>2. Observe fee update |
| Expected Result | Shipping fee updates to $12.99 (or $7.99 if member) immediately |
| Acceptance Criteria | AC-1, AC-3 |

## Test Case: TC-5.1 - Membership status change: Before checkout

| Field | Value |
| --- | --- |
| Precondition | User in cart, previously logged out; items totaling $30.00 |
| Steps | 1. Log in with member account<br>2. Proceed to checkout<br>3. Select Standard shipping<br>4. Verify fee |
| Expected Result | Shipping fee displays as $0.00 (free) based on membership |
| Acceptance Criteria | AC-2 |

## Test Case: TC-6.1 - Boundary: Subtotal $49.99 vs $50.00

| Field | Value |
| --- | --- |
| Precondition | Non-member user |
| Steps | 1. Create two test cases: one with subtotal $49.99, one with $50.00<br>2. Select Standard shipping in each<br>3. Compare fees |
| Expected Result | $49.99 subtotal = $5.99 fee; $50.00 subtotal = free shipping |
| Acceptance Criteria | AC-1 |
