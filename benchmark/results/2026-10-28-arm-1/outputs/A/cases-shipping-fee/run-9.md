# Test Cases for SHIP-9: Shipping Fee at Checkout

## Assumptions
- Order subtotal refers to the sum of item prices before shipping and tax
- Membership status is binary (member/non-member)
- Prices are in USD with two decimal places
- Exact threshold ($50.00) qualifies for free standard shipping
- Both Standard and Express shipping options are always available

---

## Test Cases

### Standard Shipping - Non-Member

| Test ID | Subtotal | Member | Expected Fee | Description |
|---------|----------|--------|--------------|-------------|
| STD-NM-001 | $49.99 | No | $5.99 | Just below threshold |
| STD-NM-002 | $50.00 | No | $0.00 | Exact threshold |
| STD-NM-003 | $50.01 | No | $0.00 | Just above threshold |
| STD-NM-004 | $100.00 | No | $0.00 | Well above threshold |
| STD-NM-005 | $0.01 | No | $5.99 | Minimum order |

### Standard Shipping - Member

| Test ID | Subtotal | Member | Expected Fee | Description |
|---------|----------|--------|--------------|-------------|
| STD-M-001 | $0.01 | Yes | $0.00 | Minimum order |
| STD-M-002 | $25.00 | Yes | $0.00 | Below non-member threshold |
| STD-M-003 | $49.99 | Yes | $0.00 | Just below non-member threshold |
| STD-M-004 | $50.00 | Yes | $0.00 | At non-member threshold |
| STD-M-005 | $1000.00 | Yes | $0.00 | Large order |

### Express Shipping - Non-Member

| Test ID | Subtotal | Member | Expected Fee | Description |
|---------|----------|--------|--------------|-------------|
| EXP-NM-001 | $0.01 | No | $12.99 | Minimum order |
| EXP-NM-002 | $25.00 | No | $12.99 | Below standard free threshold |
| EXP-NM-003 | $50.00 | No | $12.99 | At standard free threshold |
| EXP-NM-004 | $1000.00 | No | $12.99 | Large order |

### Express Shipping - Member

| Test ID | Subtotal | Member | Expected Fee | Description |
|---------|----------|--------|--------------|-------------|
| EXP-M-001 | $0.01 | Yes | $7.99 | Minimum order |
| EXP-M-002 | $25.00 | Yes | $7.99 | Below standard free threshold |
| EXP-M-003 | $50.00 | Yes | $7.99 | At standard free threshold |
| EXP-M-004 | $1000.00 | Yes | $7.99 | Large order |

---

## Scenario Tests

| Test ID | Scenario | Subtotal | Member | Shipping | Expected Fee | Notes |
|---------|----------|----------|--------|----------|--------------|-------|
| SCEN-001 | New shopper, small order | $35.00 | No | Standard | $5.99 | Upsell opportunity |
| SCEN-002 | New shopper, bulk order | $75.00 | No | Standard | $0.00 | Achieved free shipping |
| SCEN-003 | New shopper prefers speed | $35.00 | No | Express | $12.99 | Paying for speed |
| SCEN-004 | Member, any order | $20.00 | Yes | Standard | $0.00 | Member benefit |
| SCEN-005 | Member choosing faster option | $20.00 | Yes | Express | $7.99 | Member discount on express |
| SCEN-006 | Switching from standard to express | $60.00 | No | Standard→Express | $0.00→$12.99 | Fee difference shown |
