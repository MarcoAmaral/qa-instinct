# Test Cases for SHIP-9: Shipping Fee at Checkout

## Assumptions
- Members are authenticated users with active membership status
- "Order subtotal" refers to pre-tax product total
- Subtotal of exactly $50.00 qualifies for free shipping threshold
- Standard shipping and Express shipping are mutually exclusive options
- Shipping fees are applied before tax calculation
- Non-member shoppers must explicitly select a shipping method

---

## Test Suite: Standard Shipping - Non-Members

| Test ID | Scenario | Setup | Expected Result | Priority |
|---------|----------|-------|-----------------|----------|
| T1.1 | Subtotal below $50 | Non-member, $49.99 subtotal, selects standard shipping | Shipping fee displays as $5.99 | High |
| T1.2 | Subtotal at threshold | Non-member, $50.00 subtotal, selects standard shipping | Shipping fee displays as $0.00 (free) | High |
| T1.3 | Subtotal above threshold | Non-member, $50.01 subtotal, selects standard shipping | Shipping fee displays as $0.00 (free) | High |
| T1.4 | Large subtotal | Non-member, $500.00 subtotal, selects standard shipping | Shipping fee displays as $0.00 (free) | Medium |
| T1.5 | Minimal order | Non-member, $0.01 subtotal, selects standard shipping | Shipping fee displays as $5.99 | Medium |

---

## Test Suite: Standard Shipping - Members

| Test ID | Scenario | Setup | Expected Result | Priority |
|---------|----------|-------|-----------------|----------|
| T2.1 | Member, low subtotal | Member, $10.00 subtotal, selects standard shipping | Shipping fee displays as $0.00 (free) | High |
| T2.2 | Member, threshold amount | Member, $50.00 subtotal, selects standard shipping | Shipping fee displays as $0.00 (free) | High |
| T2.3 | Member, high subtotal | Member, $500.00 subtotal, selects standard shipping | Shipping fee displays as $0.00 (free) | High |
| T2.4 | Member, minimal order | Member, $0.01 subtotal, selects standard shipping | Shipping fee displays as $0.00 (free) | Medium |

---

## Test Suite: Express Shipping - Non-Members

| Test ID | Scenario | Setup | Expected Result | Priority |
|---------|----------|-------|-----------------|----------|
| T3.1 | Express shipping, low subtotal | Non-member, $10.00 subtotal, selects express shipping | Shipping fee displays as $12.99 | High |
| T3.2 | Express shipping, at threshold | Non-member, $50.00 subtotal, selects express shipping | Shipping fee displays as $12.99 | High |
| T3.3 | Express shipping, high subtotal | Non-member, $500.00 subtotal, selects express shipping | Shipping fee displays as $12.99 | High |
| T3.4 | Express vs standard comparison | Non-member, $60.00 subtotal; express = $12.99, standard = $0.00 | Correct fees displayed for both options | Medium |

---

## Test Suite: Express Shipping - Members

| Test ID | Scenario | Setup | Expected Result | Priority |
|---------|----------|-------|-----------------|----------|
| T4.1 | Member express, low subtotal | Member, $10.00 subtotal, selects express shipping | Shipping fee displays as $7.99 | High |
| T4.2 | Member express, at threshold | Member, $50.00 subtotal, selects express shipping | Shipping fee displays as $7.99 | High |
| T4.3 | Member express, high subtotal | Member, $500.00 subtotal, selects express shipping | Shipping fee displays as $7.99 | High |
| T4.4 | Member savings comparison | Member, $100.00 subtotal; express member = $7.99 vs non-member = $12.99 | Correct member discount applied | Medium |

---

## Test Suite: Edge Cases & Precision

| Test ID | Scenario | Setup | Expected Result | Priority |
|---------|----------|-------|-----------------|----------|
| T5.1 | Decimal precision at threshold | Non-member, $49.99 subtotal, standard | Shipping $5.99 (correctly below threshold) | High |
| T5.2 | Decimal precision above threshold | Non-member, $50.01 subtotal, standard | Shipping $0.00 (correctly above threshold) | High |
| T5.3 | Member status transition | User upgrades to membership mid-checkout, standard shipping selected | Shipping recalculates to $0.00 | Medium |
| T5.4 | Membership expiration | Member with expired membership, standard shipping | Shipping fee calculated as non-member ($5.99 for subtotal < $50) | Medium |

---

## Test Suite: Checkout Display & Interaction

| Test ID | Scenario | Setup | Expected Result | Priority |
|---------|----------|-------|-----------------|----------|
| T6.1 | Shipping fee displays in order summary | Any scenario | Shipping fee line item visible in checkout breakdown | High |
| T6.2 | Total updated with shipping | Non-member, $40 subtotal, standard selected | Order total = $40 + $5.99 + tax | High |
| T6.3 | Shipping method toggle | Non-member, standard $5.99 displayed, switches to express | Express fee updates to $12.99 | High |
| T6.4 | Default shipping method | Non-member at checkout, no selection made | Standard shipping pre-selected with appropriate fee displayed | Medium |

---

## Test Suite: Error Handling & Validation

| Test ID | Scenario | Setup | Expected Result | Priority |
|---------|----------|-------|-----------------|----------|
| T7.1 | Membership verification fails | Member flag unclear or system error | System defaults to non-member rates and logs error | Medium |
| T7.2 | Missing shipping selection | User attempts to complete checkout without selecting shipping method | Error message displayed, checkout blocked until selection made | High |
| T7.3 | Subtotal calculation error | Subtotal computed incorrectly | Shipping fee based on erroneous subtotal; error escalated (separate defect) | Low |
