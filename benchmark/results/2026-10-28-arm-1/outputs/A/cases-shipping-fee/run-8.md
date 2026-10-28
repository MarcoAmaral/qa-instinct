# Test Cases for SHIP-9: Shipping Fee at Checkout

## Assumptions
- Two shipping methods available: Standard and Express
- Users are either members or non-members (boolean flag)
- Shipping fee depends only on: shipping method, membership status, and order subtotal
- Order subtotal is in USD with two decimal places
- Minimum valid subtotal is $0.01

---

## Test Cases

| Test ID | Scenario | Shipping Method | Customer Type | Order Subtotal | Expected Fee | Notes |
|---------|----------|-----------------|----------------|-----------------|--------------|-------|
| TC-1.1 | Non-member standard shipping below threshold | Standard | Non-member | $0.00 | $5.99 | AC-1: Below $50 |
| TC-1.2 | Non-member standard shipping just below threshold | Standard | Non-member | $49.99 | $5.99 | AC-1: Edge case |
| TC-1.3 | Non-member standard shipping at threshold | Standard | Non-member | $50.00 | $0.00 | AC-1: At $50 |
| TC-1.4 | Non-member standard shipping just above threshold | Standard | Non-member | $50.01 | $0.00 | AC-1: Edge case |
| TC-1.5 | Non-member standard shipping well above threshold | Standard | Non-member | $100.00 | $0.00 | AC-1: Above $50 |
| TC-2.1 | Member standard shipping with low subtotal | Standard | Member | $10.00 | $0.00 | AC-2: Free for members |
| TC-2.2 | Member standard shipping with threshold subtotal | Standard | Member | $50.00 | $0.00 | AC-2: Free at any subtotal |
| TC-2.3 | Member standard shipping with high subtotal | Standard | Member | $200.00 | $0.00 | AC-2: Free at any subtotal |
| TC-3.1 | Non-member express shipping with low subtotal | Express | Non-member | $25.00 | $12.99 | AC-3: Non-member rate |
| TC-3.2 | Non-member express shipping with high subtotal | Express | Non-member | $150.00 | $12.99 | AC-3: No threshold for express |
| TC-3.3 | Member express shipping with low subtotal | Express | Member | $10.00 | $7.99 | AC-3: Member express rate |
| TC-3.4 | Member express shipping with high subtotal | Express | Member | $150.00 | $7.99 | AC-3: Member rate applies to all |
| TC-4.1 | Member vs non-member standard shipping comparison | Standard | Both | $30.00 | $5.99 / $0.00 | Verify member discount |
| TC-4.2 | Member vs non-member express shipping comparison | Express | Both | $75.00 | $12.99 / $7.99 | Verify member discount |
| TC-5.1 | Non-member cannot receive member standard shipping benefit | Standard | Non-member | $60.00 | $0.00 | Confirm AC-1 not AC-2 |
| TC-5.2 | Member free express cannot exceed stated price | Express | Member | $500.00 | $7.99 | Verify max price is $7.99 |

---

## Additional Scenarios (Non-Functional)

| Test ID | Scenario |
|---------|----------|
| TC-6.1 | Verify shipping fee displays correctly in checkout summary |
| TC-6.2 | Verify membership status correctly determines shipping tier |
| TC-6.3 | Verify shipping method selection persists when changing order |
| TC-6.4 | Verify subtotal changes recalculate shipping fee automatically |
| TC-6.5 | Verify express and standard options are both selectable |
