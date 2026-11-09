# Test Cases for SHIP-9: Shipping Fee at Checkout

## Assumptions
- "Subtotal" refers to the product total before shipping and taxes
- "Member" status is determined at checkout time
- Shipping methods are: Standard and Express
- Prices are in USD
- The system displays the shipping fee before payment confirmation

---

## Standard Shipping - Non-Member

| Test Case | Scenario | Expected Shipping Fee |
|-----------|----------|----------------------|
| TC-1.1 | Subtotal $25.00, standard shipping | $5.99 |
| TC-1.2 | Subtotal $49.99, standard shipping | $5.99 |
| TC-1.3 | Subtotal $50.00, standard shipping | $0.00 (free) |
| TC-1.4 | Subtotal $50.01, standard shipping | $0.00 (free) |
| TC-1.5 | Subtotal $100.00, standard shipping | $0.00 (free) |

---

## Standard Shipping - Member

| Test Case | Scenario | Expected Shipping Fee |
|-----------|----------|----------------------|
| TC-2.1 | Subtotal $0.01, member, standard shipping | $0.00 (free) |
| TC-2.2 | Subtotal $25.00, member, standard shipping | $0.00 (free) |
| TC-2.3 | Subtotal $49.99, member, standard shipping | $0.00 (free) |
| TC-2.4 | Subtotal $50.00, member, standard shipping | $0.00 (free) |
| TC-2.5 | Subtotal $100.00, member, standard shipping | $0.00 (free) |

---

## Express Shipping - Non-Member

| Test Case | Scenario | Expected Shipping Fee |
|-----------|----------|----------------------|
| TC-3.1 | Subtotal $0.01, non-member, express shipping | $12.99 |
| TC-3.2 | Subtotal $25.00, non-member, express shipping | $12.99 |
| TC-3.3 | Subtotal $50.00, non-member, express shipping | $12.99 |
| TC-3.4 | Subtotal $100.00, non-member, express shipping | $12.99 |

---

## Express Shipping - Member

| Test Case | Scenario | Expected Shipping Fee |
|-----------|----------|----------------------|
| TC-4.1 | Subtotal $0.01, member, express shipping | $7.99 |
| TC-4.2 | Subtotal $25.00, member, express shipping | $7.99 |
| TC-4.3 | Subtotal $50.00, member, express shipping | $7.99 |
| TC-4.4 | Subtotal $100.00, member, express shipping | $7.99 |

---

## Edge Cases

| Test Case | Scenario | Expected Shipping Fee |
|-----------|----------|----------------------|
| TC-5.1 | Subtotal $0.00, non-member, standard shipping | $5.99 |
| TC-5.2 | Subtotal $0.00, member, standard shipping | $0.00 (free) |
| TC-5.3 | Member status changes during checkout, final status member, standard shipping | $0.00 (free) |
| TC-5.4 | Multiple items, combined subtotal $50.00, non-member, standard shipping | $0.00 (free) |
| TC-5.5 | Multiple items, combined subtotal $49.99, non-member, standard shipping | $5.99 |
