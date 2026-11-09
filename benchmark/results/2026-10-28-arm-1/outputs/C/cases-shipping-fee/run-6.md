# Test Cases for SHIP-9: Shipping fee at checkout

## Assumptions

- Membership status is determined before checkout begins and does not change during the session
- The system supports exactly two shipping methods: standard and express
- Subtotal is calculated before any taxes or discounts
- Shipping fees are applied and shown before final payment confirmation
- A subtotal of $0.00 is a valid edge case (empty cart or all-free items)

---

## Test Case Suite: Shipping Fee Calculation

### Standard Shipping – Non-Member

| TC ID | Scenario | Subtotal | Membership | Expected Fee | Notes |
| --- | --- | --- | --- | --- | --- |
| SHIP-9-01 | Subtotal meets threshold | $50.00 | No | Free | Boundary: minimum free threshold |
| SHIP-9-02 | Subtotal exceeds threshold | $75.00 | No | Free | Above threshold |
| SHIP-9-03 | Subtotal below threshold | $49.99 | No | $5.99 | Just below threshold |
| SHIP-9-04 | Very low subtotal | $1.00 | No | $5.99 | Minimum order |
| SHIP-9-05 | Empty cart | $0.00 | No | $5.99 | Edge case; assume fee applies even at $0 |
| SHIP-9-06 | High subtotal | $500.00 | No | Free | Well above threshold |

### Standard Shipping – Member

| TC ID | Scenario | Subtotal | Membership | Expected Fee | Notes |
| --- | --- | --- | --- | --- | --- |
| SHIP-9-07 | Member, low subtotal | $1.00 | Yes | Free | Member bypasses all subtotal checks |
| SHIP-9-08 | Member, at threshold | $50.00 | Yes | Free | Membership overrides threshold rule |
| SHIP-9-09 | Member, above threshold | $100.00 | Yes | Free | Membership overrides threshold rule |
| SHIP-9-10 | Member, empty cart | $0.00 | Yes | Free | Membership applies even at $0 |

### Express Shipping – Non-Member

| TC ID | Scenario | Subtotal | Membership | Expected Fee | Notes |
| --- | --- | --- | --- | --- | --- |
| SHIP-9-11 | Low subtotal | $1.00 | No | $12.99 | Express fee fixed regardless of subtotal |
| SHIP-9-12 | At threshold | $50.00 | No | $12.99 | Subtotal does not affect express pricing |
| SHIP-9-13 | High subtotal | $200.00 | No | $12.99 | Subtotal does not affect express pricing |
| SHIP-9-14 | Empty cart | $0.00 | No | $12.99 | Assume express is available even at $0 |

### Express Shipping – Member

| TC ID | Scenario | Subtotal | Membership | Expected Fee | Notes |
| --- | --- | --- | --- | --- | --- |
| SHIP-9-15 | Low subtotal | $1.00 | Yes | $7.99 | Member express rate applied |
| SHIP-9-16 | At threshold | $50.00 | Yes | $7.99 | Membership discount on express |
| SHIP-9-17 | High subtotal | $200.00 | Yes | $7.99 | Membership discount on express |
| SHIP-9-18 | Empty cart | $0.00 | Yes | $7.99 | Member express rate applies |

### Integration & Edge Cases

| TC ID | Scenario | Subtotal | Membership | Expected Behavior |
| --- | --- | --- | --- | --- |
| SHIP-9-19 | Switch shipping method | $30.00 | No | Standard: $5.99 → Express: $12.99 |
| SHIP-9-20 | Switch shipping method | $30.00 | Yes | Standard: Free → Express: $7.99 |
| SHIP-9-21 | Display both options at checkout | $30.00 | No | Both standard ($5.99) and express ($12.99) shown and selectable |
| SHIP-9-22 | Display both options at checkout | $30.00 | Yes | Both standard (Free) and express ($7.99) shown and selectable |
| SHIP-9-23 | Fee recalculation after adding item | $40.00 → $55.00 | No | Standard fee updates from $5.99 → Free |
| SHIP-9-24 | Fee recalculation after removing item | $55.00 → $40.00 | No | Standard fee updates from Free → $5.99 |

---

## Acceptance Criteria Mapping

- **AC-1** (Standard free ≥$50 / $5.99 otherwise): Tested by TC SHIP-9-01 through SHIP-9-06, TC SHIP-9-23, TC SHIP-9-24
- **AC-2** (Members free standard always): Tested by TC SHIP-9-07 through SHIP-9-10
- **AC-3** (Express $12.99 / Members $7.99): Tested by TC SHIP-9-11 through SHIP-9-18
