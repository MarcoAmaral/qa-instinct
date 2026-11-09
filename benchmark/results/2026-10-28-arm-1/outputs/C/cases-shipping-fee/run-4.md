# Test Cases: Shipping Fee at Checkout (SHIP-9)

## Assumptions
- Shopper account can be either a member or non-member
- "Subtotal" refers to product total before shipping charges
- Both standard and express shipping options are available at checkout
- Shipping fee is displayed before final payment confirmation
- Members are identified in the system at checkout time

## Standard Shipping - Non-Member

| Test ID | Scenario | Subtotal | Expected Fee | Status |
|---------|----------|----------|--------------|--------|
| SHIP-9-001 | Non-member, standard shipping, subtotal below threshold | $25.00 | $5.99 | AC-1 |
| SHIP-9-002 | Non-member, standard shipping, subtotal exactly at threshold | $50.00 | $0.00 | AC-1 |
| SHIP-9-003 | Non-member, standard shipping, subtotal above threshold | $75.00 | $0.00 | AC-1 |
| SHIP-9-004 | Non-member, standard shipping, subtotal just below threshold | $49.99 | $5.99 | AC-1 |
| SHIP-9-005 | Non-member, standard shipping, subtotal just above threshold | $50.01 | $0.00 | AC-1 |

## Standard Shipping - Member

| Test ID | Scenario | Subtotal | Expected Fee | Status |
|---------|----------|----------|--------------|--------|
| SHIP-9-006 | Member, standard shipping, subtotal $10.00 | $10.00 | $0.00 | AC-2 |
| SHIP-9-007 | Member, standard shipping, subtotal $49.99 | $49.99 | $0.00 | AC-2 |
| SHIP-9-008 | Member, standard shipping, subtotal $50.00 | $50.00 | $0.00 | AC-2 |
| SHIP-9-009 | Member, standard shipping, subtotal $100.00 | $100.00 | $0.00 | AC-2 |

## Express Shipping - Non-Member

| Test ID | Scenario | Subtotal | Expected Fee | Status |
|---------|----------|----------|--------------|--------|
| SHIP-9-010 | Non-member, express shipping, subtotal $25.00 | $25.00 | $12.99 | AC-3 |
| SHIP-9-011 | Non-member, express shipping, subtotal $50.00 | $50.00 | $12.99 | AC-3 |
| SHIP-9-012 | Non-member, express shipping, subtotal $100.00 | $100.00 | $12.99 | AC-3 |

## Express Shipping - Member

| Test ID | Scenario | Subtotal | Expected Fee | Status |
|---------|----------|----------|--------------|--------|
| SHIP-9-013 | Member, express shipping, subtotal $25.00 | $25.00 | $7.99 | AC-3 |
| SHIP-9-014 | Member, express shipping, subtotal $50.00 | $50.00 | $7.99 | AC-3 |
| SHIP-9-015 | Member, express shipping, subtotal $100.00 | $100.00 | $7.99 | AC-3 |

## Total Price Calculation

| Test ID | Scenario | Subtotal | Shipping Method | Member | Subtotal + Fee | Status |
|---------|----------|----------|-----------------|--------|---|--------|
| SHIP-9-016 | Order total with non-member standard, under threshold | $30.00 | Standard | No | $35.99 | AC-1 |
| SHIP-9-017 | Order total with non-member standard, at threshold | $50.00 | Standard | No | $50.00 | AC-1 |
| SHIP-9-018 | Order total with member express | $40.00 | Express | Yes | $47.99 | AC-2, AC-3 |
| SHIP-9-019 | Order total with non-member express | $60.00 | Express | No | $72.99 | AC-3 |
