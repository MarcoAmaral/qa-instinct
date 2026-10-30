# Test Cases for SHIP-9: Shipping Fee at Checkout

## Assumptions
- "Member" is a boolean status determined at checkout (e.g., logged-in member account)
- "Subtotal" is the order total before shipping, taxes, and other fees
- Shipping fees are calculated independently; customer can select shipping method
- Currency is USD
- Exact threshold ($50.00) qualifies for free standard shipping
- Test environment has member and non-member test accounts available

---

## Test Case Suite

### AC-1: Standard Shipping Based on Subtotal (Non-Members)

| Test ID | Scenario | Subtotal | Member | Shipping Method | Expected Fee | Priority |
|---------|----------|----------|--------|-----------------|--------------|----------|
| AC1-001 | Subtotal below threshold | $49.99 | No | Standard | $5.99 | P0 |
| AC1-002 | Subtotal at threshold | $50.00 | No | Standard | $0.00 | P0 |
| AC1-003 | Subtotal above threshold | $50.01 | No | Standard | $0.00 | P0 |
| AC1-004 | Low subtotal | $10.00 | No | Standard | $5.99 | P1 |
| AC1-005 | High subtotal | $200.00 | No | Standard | $0.00 | P1 |
| AC1-006 | Subtotal $49.98 (just under) | $49.98 | No | Standard | $5.99 | P1 |
| AC1-007 | Multiple items under threshold | $25.00 + $24.99 | No | Standard | $5.99 | P1 |

### AC-2: Standard Shipping for Members

| Test ID | Scenario | Subtotal | Member | Shipping Method | Expected Fee | Priority |
|---------|----------|----------|--------|-----------------|--------------|----------|
| AC2-001 | Member with low subtotal | $10.00 | Yes | Standard | $0.00 | P0 |
| AC2-002 | Member at threshold | $50.00 | Yes | Standard | $0.00 | P0 |
| AC2-003 | Member above threshold | $100.00 | Yes | Standard | $0.00 | P0 |
| AC2-004 | Member with minimal order | $0.01 | Yes | Standard | $0.00 | P1 |
| AC2-005 | Member with subtotal just under non-member threshold | $49.99 | Yes | Standard | $0.00 | P1 |

### AC-3: Express Shipping Pricing

| Test ID | Scenario | Subtotal | Member | Shipping Method | Expected Fee | Priority |
|---------|----------|----------|--------|-----------------|--------------|----------|
| AC3-001 | Non-member express shipping | $25.00 | No | Express | $12.99 | P0 |
| AC3-002 | Non-member express with high subtotal | $200.00 | No | Express | $12.99 | P0 |
| AC3-003 | Member express shipping | $25.00 | Yes | Express | $7.99 | P0 |
| AC3-004 | Member express with high subtotal | $200.00 | Yes | Express | $7.99 | P0 |
| AC3-005 | Non-member express at threshold | $50.00 | No | Express | $12.99 | P1 |
| AC3-006 | Member express at low subtotal | $0.01 | Yes | Express | $7.99 | P1 |

### Combined Scenarios (Cross-Acceptance Criteria)

| Test ID | Scenario | Subtotal | Member | Shipping Method | Expected Fee | Priority |
|---------|----------|----------|--------|-----------------|--------------|----------|
| AC-COM-001 | Non-member: compare standard vs express at low subtotal | $30.00 | No | Standard | $5.99 | P2 |
| AC-COM-002 | Non-member: compare standard vs express at high subtotal | $100.00 | No | Standard | $0.00 | P2 |
| AC-COM-003 | Member: standard and express pricing equivalence test | $10.00 | Yes | Both options | Standard: $0.00, Express: $7.99 | P2 |
| AC-COM-004 | Non-member switches to express at free standard threshold | $50.00 | No | Standard then Express | $0.00 then $12.99 | P2 |
| AC-COM-005 | Membership upgrade affects shipping cost | $30.00 | No→Yes | Standard | $5.99 → $0.00 | P1 |

### Boundary & Edge Cases

| Test ID | Scenario | Subtotal | Member | Shipping Method | Expected Fee | Priority |
|---------|----------|----------|--------|-----------------|--------------|----------|
| EDGE-001 | Zero dollar order (gift card scenario) | $0.00 | No | Standard | $5.99 | P3 |
| EDGE-002 | Zero dollar order for member | $0.00 | Yes | Standard | $0.00 | P3 |
| EDGE-003 | Very large subtotal | $10,000.00 | No | Standard | $0.00 | P3 |
| EDGE-004 | Rounding: $50.001 (if fractions permitted) | $50.001 | No | Standard | $0.00 | P3 |
| EDGE-005 | Rounding: $49.999 (if fractions permitted) | $49.999 | No | Standard | $5.99 | P3 |
| EDGE-006 | Multiple shipping method selections | $30.00 | No | Standard & Express | $5.99 & $12.99 (isolated) | P2 |

### Negative/Error Cases

| Test ID | Scenario | Subtotal | Member | Shipping Method | Expected Behavior | Priority |
|---------|----------|----------|--------|-----------------|-------------------|----------|
| NEG-001 | Negative subtotal (data error) | -$10.00 | No | Standard | Error or treated as $0 | P2 |
| NEG-002 | Non-existent shipping method | $50.00 | No | "SuperFast" | Error message | P2 |
| NEG-003 | Missing subtotal value | NULL | No | Standard | Error message | P2 |
| NEG-004 | Ambiguous member status | $50.00 | Unknown | Standard | Default to non-member pricing ($0.00) or error | P2 |

---

## Test Execution Notes

- **Regression**: Re-run AC1, AC2, AC3 test cases on each release
- **Integration**: Verify shipping fee calculations persist through payment processing
- **UI**: Confirm shipping fee displays correctly in checkout summary and order confirmation
- **Data**: Test with various product combinations and multi-warehouse scenarios if applicable
- **Performance**: Verify shipping calculation does not impact checkout page load time
