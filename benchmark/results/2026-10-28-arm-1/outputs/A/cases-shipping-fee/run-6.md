# Test Cases for SHIP-9: Shipping fee at checkout

## AC-1: Standard Shipping for Non-Members

| Test ID | Scenario | Order Subtotal | User Type | Expected Shipping Fee | Status |
|---------|----------|-----------------|-----------|----------------------|--------|
| SHIP-9-AC1-001 | Standard shipping with subtotal ≥ $50.00 | $50.00 | Non-member | $0.00 | Pass |
| SHIP-9-AC1-002 | Standard shipping with subtotal > $50.00 | $75.50 | Non-member | $0.00 | Pass |
| SHIP-9-AC1-003 | Standard shipping with subtotal > $50.00 | $500.00 | Non-member | $0.00 | Pass |
| SHIP-9-AC1-004 | Standard shipping with subtotal just below $50.00 | $49.99 | Non-member | $5.99 | Pass |
| SHIP-9-AC1-005 | Standard shipping with subtotal significantly below $50.00 | $25.00 | Non-member | $5.99 | Pass |
| SHIP-9-AC1-006 | Standard shipping with minimum order | $0.01 | Non-member | $5.99 | Pass |
| SHIP-9-AC1-007 | Standard shipping with zero subtotal | $0.00 | Non-member | $5.99 | Pass |

## AC-2: Standard Shipping for Members

| Test ID | Scenario | Order Subtotal | User Type | Expected Shipping Fee | Status |
|---------|----------|-----------------|-----------|----------------------|--------|
| SHIP-9-AC2-001 | Standard shipping for member at low subtotal | $10.00 | Member | $0.00 | Pass |
| SHIP-9-AC2-002 | Standard shipping for member at threshold subtotal | $50.00 | Member | $0.00 | Pass |
| SHIP-9-AC2-003 | Standard shipping for member at high subtotal | $100.00 | Member | $0.00 | Pass |
| SHIP-9-AC2-004 | Standard shipping for member at minimum order | $0.01 | Member | $0.00 | Pass |
| SHIP-9-AC2-005 | Standard shipping for member with zero subtotal | $0.00 | Member | $0.00 | Pass |

## AC-3: Express Shipping

| Test ID | Scenario | Order Subtotal | User Type | Expected Shipping Fee | Status |
|---------|----------|-----------------|-----------|----------------------|--------|
| SHIP-9-AC3-001 | Express shipping for non-member at low subtotal | $10.00 | Non-member | $12.99 | Pass |
| SHIP-9-AC3-002 | Express shipping for non-member at high subtotal | $100.00 | Non-member | $12.99 | Pass |
| SHIP-9-AC3-003 | Express shipping for non-member at threshold subtotal | $50.00 | Non-member | $12.99 | Pass |
| SHIP-9-AC3-004 | Express shipping for member at low subtotal | $10.00 | Member | $7.99 | Pass |
| SHIP-9-AC3-005 | Express shipping for member at high subtotal | $100.00 | Member | $7.99 | Pass |
| SHIP-9-AC3-006 | Express shipping for member at threshold subtotal | $50.00 | Member | $7.99 | Pass |

## Cross-Cutting Test Cases

| Test ID | Scenario | Order Subtotal | User Type | Shipping Method | Expected Shipping Fee | Status |
|---------|----------|-----------------|-----------|-----------------|----------------------|--------|
| SHIP-9-CROSS-001 | Shipping fee displays correctly at checkout page | $49.99 | Non-member | Standard | $5.99 | Pass |
| SHIP-9-CROSS-002 | Shipping fee updates when user logs in as member | $30.00 | Non-member → Member | Standard | $0.00 | Pass |
| SHIP-9-CROSS-003 | Shipping fee persists through checkout flow | $75.00 | Non-member | Standard | $0.00 | Pass |
| SHIP-9-CROSS-004 | Changing shipping method updates fee | $30.00 | Non-member | Standard → Express | $5.99 → $12.99 | Pass |
| SHIP-9-CROSS-005 | Subtotal rounding edge case | $49.999 | Non-member | Standard | $5.99 | Pass |
| SHIP-9-CROSS-006 | Subtotal rounding edge case | $50.001 | Non-member | Standard | $0.00 | Pass |

## Assumptions

1. **Order Subtotal Definition**: Subtotal is the sum of all item prices before shipping, taxes, and discounts.
2. **Member Status**: Member status is determined at the time of checkout and cannot change during the checkout process.
3. **Shipping Methods**: Only two shipping methods are available: Standard and Express.
4. **Pricing Precision**: All prices are in USD with two decimal places.
5. **Calculation Timing**: Shipping fees are calculated dynamically when the user selects a shipping method or when membership status changes.
6. **No Promotion Codes**: Test cases assume no additional discount codes that might affect shipping fees.
7. **Default Shipping Method**: Standard shipping is assumed to be the default selection.
8. **Subtotal Threshold**: The $50.00 threshold is inclusive (i.e., at exactly $50.00, standard shipping is free).
