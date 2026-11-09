# Test Cases for Shipping Fee at Checkout (SHIP-9)

## Test Case 1: Non-Member, Standard Shipping, Subtotal Below $50
- **Given:** Non-member shopper with order subtotal $49.99
- **When:** Standard shipping is selected at checkout
- **Then:** Shipping fee displays as $5.99
- **AC:** AC-1

## Test Case 2: Non-Member, Standard Shipping, Subtotal At $50.00
- **Given:** Non-member shopper with order subtotal $50.00
- **When:** Standard shipping is selected at checkout
- **Then:** Shipping fee displays as $0.00
- **AC:** AC-1

## Test Case 3: Non-Member, Standard Shipping, Subtotal Above $50
- **Given:** Non-member shopper with order subtotal $75.00
- **When:** Standard shipping is selected at checkout
- **Then:** Shipping fee displays as $0.00
- **AC:** AC-1

## Test Case 4: Member, Standard Shipping, Subtotal Below $50
- **Given:** Member shopper with order subtotal $25.00
- **When:** Standard shipping is selected at checkout
- **Then:** Shipping fee displays as $0.00
- **AC:** AC-2

## Test Case 5: Member, Standard Shipping, Subtotal Above $50
- **Given:** Member shopper with order subtotal $100.00
- **When:** Standard shipping is selected at checkout
- **Then:** Shipping fee displays as $0.00
- **AC:** AC-2

## Test Case 6: Non-Member, Express Shipping, Any Subtotal
- **Given:** Non-member shopper with order subtotal $35.00
- **When:** Express shipping is selected at checkout
- **Then:** Shipping fee displays as $12.99
- **AC:** AC-3

## Test Case 7: Member, Express Shipping, Subtotal Below $50
- **Given:** Member shopper with order subtotal $30.00
- **When:** Express shipping is selected at checkout
- **Then:** Shipping fee displays as $7.99
- **AC:** AC-3

## Test Case 8: Member, Express Shipping, Subtotal Above $50
- **Given:** Member shopper with order subtotal $80.00
- **When:** Express shipping is selected at checkout
- **Then:** Shipping fee displays as $7.99
- **AC:** AC-3

## Test Case 9: Shipping Fee Changes When Shipping Method Switches
- **Given:** Non-member shopper with order subtotal $45.00 on standard shipping ($5.99)
- **When:** Shipping method is changed to express
- **Then:** Shipping fee updates to $12.99 immediately
- **AC:** AC-1, AC-3

## Test Case 10: Total Price Updates with Shipping Fee
- **Given:** Non-member shopper with order subtotal $60.00 and free standard shipping
- **When:** Checkout page displays total price
- **Then:** Order total equals subtotal ($60.00) with no shipping charge added
- **AC:** AC-1

## Assumptions

- A "member" is determined by account status at the time of checkout and is independently verifiable.
- "Subtotal" excludes shipping and tax and is the sum of item prices before any discounts.
- Shipping fees are displayed in USD ($).
- Shipping method selection happens before the final review screen.
- Fees display to two decimal places (e.g., $5.99, not $5.9).
- Standard and express are the only two shipping methods offered.
