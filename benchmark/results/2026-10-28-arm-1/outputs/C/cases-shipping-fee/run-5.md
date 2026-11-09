# Test Cases for SHIP-9: Shipping Fee at Checkout

## Assumptions

- "Members" refers to logged-in users with an active membership status.
- "Order subtotal" excludes shipping costs and taxes.
- Shipping method can be selected at checkout before the fee is calculated.
- The fee displayed is final; no additional discounts apply after display.
- Standard shipping is the default option.

---

## AC-1: Standard Shipping Cost for Non-Members

| Test Case | Scenario | Expected Result |
| --- | --- | --- |
| AC-1.1 | Non-member, standard shipping, subtotal $50.00 | Shipping fee: $0.00 |
| AC-1.2 | Non-member, standard shipping, subtotal $50.01 | Shipping fee: $0.00 |
| AC-1.3 | Non-member, standard shipping, subtotal $49.99 | Shipping fee: $5.99 |
| AC-1.4 | Non-member, standard shipping, subtotal $0.01 | Shipping fee: $5.99 |

---

## AC-2: Standard Shipping for Members

| Test Case | Scenario | Expected Result |
| --- | --- | --- |
| AC-2.1 | Member, standard shipping, subtotal $50.00 | Shipping fee: $0.00 |
| AC-2.2 | Member, standard shipping, subtotal $25.00 | Shipping fee: $0.00 |
| AC-2.3 | Member, standard shipping, subtotal $0.01 | Shipping fee: $0.00 |
| AC-2.4 | Member loses membership status mid-checkout, subtotal $25.00 | Shipping fee: $5.99 |

---

## AC-3: Express Shipping Cost

| Test Case | Scenario | Expected Result |
| --- | --- | --- |
| AC-3.1 | Non-member, express shipping, any subtotal | Shipping fee: $12.99 |
| AC-3.2 | Member, express shipping, any subtotal | Shipping fee: $7.99 |
| AC-3.3 | Member, express shipping, subtotal $0.01 | Shipping fee: $7.99 |

---

## Edge Cases

| Test Case | Scenario | Expected Result |
| --- | --- | --- |
| EC-1 | Subtotal exactly $50.00, shipping method switched from express to standard | Fee updates from $12.99 to $0.00 |
| EC-2 | Member with $49.99 subtotal, shipping method switched from standard to express | Fee updates from $0.00 to $7.99 |
| EC-3 | Membership status changes at checkout, subtotal $30.00, standard shipping selected | Fee updates from $5.99 to $0.00 |
