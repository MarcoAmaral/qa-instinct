# Test Cases for SHIP-9: Shipping Fee at Checkout

## Test Data Setup
- **Assumption**: Shipping types are "Standard" and "Express"
- **Assumption**: User types are "Guest/Regular" and "Member"
- **Assumption**: Order subtotal is calculated before shipping and taxes
- **Assumption**: Prices are in USD with 2 decimal places

---

## AC-1: Standard Shipping for Non-Members

| Test ID | Scenario | Subtotal | Expected Fee | Status |
|---------|----------|----------|--------------|--------|
| SHIP-9-AC1-001 | Standard shipping with subtotal exactly $50.00 | $50.00 | Free | |
| SHIP-9-AC1-002 | Standard shipping with subtotal above $50.00 | $75.99 | Free | |
| SHIP-9-AC1-003 | Standard shipping with subtotal $49.99 | $49.99 | $5.99 | |
| SHIP-9-AC1-004 | Standard shipping with subtotal $1.00 | $1.00 | $5.99 | |
| SHIP-9-AC1-005 | Standard shipping with high subtotal | $1,000.00 | Free | |
| SHIP-9-AC1-006 | Standard shipping displays correct total (subtotal + fee) | $45.00 | Total: $50.99 | |

---

## AC-2: Standard Shipping for Members

| Test ID | Scenario | Subtotal | User Type | Expected Fee | Status |
|---------|----------|----------|-----------|--------------|--------|
| SHIP-9-AC2-001 | Standard shipping for member with low subtotal | $10.00 | Member | Free | |
| SHIP-9-AC2-002 | Standard shipping for member with $50+ subtotal | $50.00 | Member | Free | |
| SHIP-9-AC2-003 | Standard shipping for member with $1.00 | $1.00 | Member | Free | |
| SHIP-9-AC2-004 | Standard shipping for member displays correct total | $25.00 | Member | Total: $25.00 | |

---

## AC-3: Express Shipping Fees

| Test ID | Scenario | User Type | Expected Fee | Status |
|---------|----------|-----------|--------------|--------|
| SHIP-9-AC3-001 | Express shipping for non-member | Guest/Regular | $12.99 | |
| SHIP-9-AC3-002 | Express shipping for member | Member | $7.99 | |
| SHIP-9-AC3-003 | Express shipping non-member total calculation | Guest/Regular (Subtotal: $30.00) | Total: $42.99 | |
| SHIP-9-AC3-004 | Express shipping member total calculation | Member (Subtotal: $30.00) | Total: $37.99 | |

---

## Boundary & Edge Cases

| Test ID | Scenario | Details | Expected Behavior | Status |
|---------|----------|---------|-------------------|--------|
| SHIP-9-BND-001 | Boundary: exactly $50.00 standard shipping | Non-member, $50.00 subtotal, Standard | Free shipping | |
| SHIP-9-BND-002 | Boundary: $49.99 standard shipping | Non-member, $49.99 subtotal, Standard | $5.99 fee | |
| SHIP-9-BND-003 | Zero subtotal order | Guest user, $0.00 subtotal, Standard | $5.99 fee | |
| SHIP-9-BND-004 | Very large order | Member, $9,999.99 subtotal, Standard | Free shipping | |

---

## UI & Display Cases

| Test ID | Scenario | Expected Display | Status |
|---------|----------|------------------|--------|
| SHIP-9-UI-001 | Shipping fee displayed at checkout | "Shipping: Free" or "Shipping: $X.XX" | |
| SHIP-9-UI-002 | Order total reflects shipping fee | Subtotal + Shipping = Order Total | |
| SHIP-9-UI-003 | Shipping method selector available | User can choose Standard or Express | |
| SHIP-9-UI-004 | Shipping fee updates on method change | Switching Express→Standard updates fee | |
| SHIP-9-UI-005 | Member status affects displayed shipping | Same order shows different fees for member vs guest | |

---

## Integration Cases

| Test ID | Scenario | Details | Expected Behavior | Status |
|---------|----------|---------|-------------------|--------|
| SHIP-9-INT-001 | Multi-item order with standard shipping | 3 items, $60 subtotal, non-member, Standard | Free shipping | |
| SHIP-9-INT-002 | Discount applied before shipping calculation | $100 subtotal → $40 after coupon, Standard | $5.99 shipping | |
| SHIP-9-INT-003 | Membership status confirmed at checkout | System validates user is member before applying discount | Correct fee applied | |
