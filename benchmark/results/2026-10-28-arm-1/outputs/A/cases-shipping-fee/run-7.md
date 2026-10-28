# Test Cases for SHIP-9: Shipping fee at checkout

## Assumptions
- Only two shipping methods available: Standard and Express
- Currency is USD
- Subtotal threshold of $50.00 is inclusive (at exactly $50.00, non-member standard shipping is free)
- User can be either a member or non-member
- Shipping fee calculation applies only to the order subtotal (excluding tax, discounts applied separately)
- Minimum order subtotal is $0.00

---

## Standard Shipping - Non-Member

| Test Case | Subtotal | Expected Fee | Notes |
|-----------|----------|--------------|-------|
| Below minimum threshold | $49.99 | $5.99 | Just below the $50 threshold |
| At threshold | $50.00 | $0.00 | Exactly at the free threshold |
| Above threshold | $50.01 | $0.00 | Just above the $50 threshold |
| High subtotal | $500.00 | $0.00 | Well above threshold |
| Zero order | $0.00 | $5.99 | Empty cart scenario |

## Standard Shipping - Member

| Test Case | Subtotal | Expected Fee | Notes |
|-----------|----------|--------------|-------|
| Minimum | $0.00 | $0.00 | Free at any subtotal |
| Below $50 | $25.00 | $0.00 | Member benefit applies |
| At $50 | $50.00 | $0.00 | Free regardless |
| Above $50 | $100.00 | $0.00 | Free regardless |

## Express Shipping - Non-Member

| Test Case | Subtotal | Expected Fee | Notes |
|-----------|----------|--------------|-------|
| Minimum | $0.00 | $12.99 | Fixed cost applies |
| Below $50 | $25.00 | $12.99 | Same fee regardless of subtotal |
| At $50 | $50.00 | $12.99 | No discount at threshold |
| Above $50 | $100.00 | $12.99 | No discount at threshold |

## Express Shipping - Member

| Test Case | Subtotal | Expected Fee | Notes |
|-----------|----------|--------------|-------|
| Minimum | $0.00 | $7.99 | Member rate applies |
| Below $50 | $25.00 | $7.99 | Member discount on express |
| At $50 | $50.00 | $7.99 | Member discount applies |
| Above $50 | $100.00 | $7.99 | Member discount applies |

## Edge Cases

| Test Case | Scenario | Expected Behavior |
|-----------|----------|-------------------|
| Member status change | User membership status changes before checkout | Updated shipping fee applies based on current member status |
| Shipping method change | User switches from Standard to Express | Correct fee applies for selected method |
| Membership expiration | Membership expires during checkout | Non-member rates apply if checkout is not completed before expiration |
| Decimal precision | Subtotal is $49.999 | Treated as $49.99; standard shipping is $5.99 |
