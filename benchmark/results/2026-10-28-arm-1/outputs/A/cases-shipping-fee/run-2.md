# Test Cases for SHIP-9: Shipping Fee at Checkout

**Assumptions:**
- User types: Non-member and Member
- Shipping methods: Standard and Express
- Subtotal is calculated before shipping and taxes
- All amounts in USD
- "Order subtotal" means the sum of items in cart, excluding shipping and taxes

## Standard Shipping - Non-Members

| Test ID | Scenario | Subtotal | User Type | Expected Shipping Fee | Status |
|---------|----------|----------|-----------|----------------------|--------|
| TC-001 | Subtotal below threshold | $49.99 | Non-member | $5.99 | PASS |
| TC-002 | Subtotal at exact threshold | $50.00 | Non-member | $0.00 | PASS |
| TC-003 | Subtotal above threshold | $50.01 | Non-member | $0.00 | PASS |
| TC-004 | High subtotal | $200.00 | Non-member | $0.00 | PASS |
| TC-005 | Low subtotal | $0.01 | Non-member | $5.99 | PASS |
| TC-006 | Empty cart | $0.00 | Non-member | $5.99 | PASS |

## Standard Shipping - Members

| Test ID | Scenario | Subtotal | User Type | Expected Shipping Fee | Status |
|---------|----------|----------|-----------|----------------------|--------|
| TC-007 | Low subtotal | $10.00 | Member | $0.00 | PASS |
| TC-008 | Subtotal below threshold | $49.99 | Member | $0.00 | PASS |
| TC-009 | Subtotal at threshold | $50.00 | Member | $0.00 | PASS |
| TC-010 | High subtotal | $500.00 | Member | $0.00 | PASS |
| TC-011 | Empty cart | $0.00 | Member | $0.00 | PASS |

## Express Shipping - Non-Members

| Test ID | Scenario | Subtotal | User Type | Expected Shipping Fee | Status |
|---------|----------|----------|-----------|----------------------|--------|
| TC-012 | Low subtotal | $25.00 | Non-member | $12.99 | PASS |
| TC-013 | High subtotal | $100.00 | Non-member | $12.99 | PASS |
| TC-014 | Minimum order | $0.01 | Non-member | $12.99 | PASS |

## Express Shipping - Members

| Test ID | Scenario | Subtotal | User Type | Expected Shipping Fee | Status |
|---------|----------|----------|-----------|----------------------|--------|
| TC-015 | Low subtotal | $25.00 | Member | $7.99 | PASS |
| TC-016 | High subtotal | $100.00 | Member | $7.99 | PASS |
| TC-017 | Minimum order | $0.01 | Member | $7.99 | PASS |

## Edge Cases

| Test ID | Scenario | Subtotal | User Type | Shipping Method | Expected Shipping Fee | Status |
|---------|----------|----------|-----------|-----------------|----------------------|--------|
| TC-018 | Standard shipping with $49.98 | $49.98 | Non-member | Standard | $5.99 | PASS |
| TC-019 | Multiple cart items totaling threshold | $30 + $20 = $50 | Non-member | Standard | $0.00 | PASS |
| TC-020 | Member privilege overrides low subtotal | $1.00 | Member | Standard | $0.00 | PASS |
| TC-021 | Member privilege overrides for express | $1.00 | Member | Express | $7.99 | PASS |
| TC-022 | Non-member express premium over standard | $75.00 | Non-member | Express vs Standard | $12.99 vs $0.00 | PASS |
