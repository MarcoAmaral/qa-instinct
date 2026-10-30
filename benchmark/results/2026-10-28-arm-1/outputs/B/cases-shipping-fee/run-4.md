# Test Cases for SHIP-9: Shipping Fee at Checkout

## Assumptions
- Non-members and members are the two user types; default checkout uses non-member rates unless user is logged in with active membership
- Standard shipping is the default option; Express shipping is an alternative selection
- Order subtotal is calculated as the sum of item prices before applicable taxes and discounts
- Checkout flow includes a shipping method selection step where fees are displayed
- Currency is USD
- Shipping fees are calculated and displayed before final order submission
- Members are verified by login/account status at time of checkout

---

## Test Cases

### Standard Shipping - Non-Member

| ID | Scenario | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-001 | Non-member orders with subtotal below $50 | Logged out; items totaling $30.00 in cart | Proceed to checkout, select Standard shipping | Shipping fee of $5.99 is displayed | High |
| TC-002 | Non-member orders at exact $50.00 threshold | Logged out; items totaling $50.00 in cart | Proceed to checkout, select Standard shipping | Free standard shipping ($0.00) is displayed | High |
| TC-003 | Non-member orders above $50.00 | Logged out; items totaling $75.50 in cart | Proceed to checkout, select Standard shipping | Free standard shipping ($0.00) is displayed | High |
| TC-004 | Non-member with multiple items below $50 | Logged out; cart has 3 items: $10, $15, $20 | Proceed to checkout, select Standard shipping | Shipping fee of $5.99 is displayed; subtotal shown correctly as $45.00 | High |
| TC-005 | Non-member boundary test just below $50 | Logged out; items totaling $49.99 in cart | Proceed to checkout, select Standard shipping | Shipping fee of $5.99 is displayed | High |

### Standard Shipping - Member

| ID | Scenario | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-006 | Member orders with low subtotal | Logged in as member; items totaling $10.00 in cart | Proceed to checkout, Standard shipping displayed | Free standard shipping ($0.00) is displayed | High |
| TC-007 | Member orders with high subtotal | Logged in as member; items totaling $150.00 in cart | Proceed to checkout, Standard shipping displayed | Free standard shipping ($0.00) is displayed | High |
| TC-008 | Member membership status verified at checkout | Logged in as member; items totaling $30.00 in cart | Proceed to checkout step where membership is verified | Standard shipping is free; "Member benefit" or similar label shown | Medium |

### Express Shipping - Non-Member

| ID | Scenario | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-009 | Non-member selects Express shipping | Logged out; items totaling $40.00 in cart | Proceed to checkout, select Express shipping | Express shipping fee of $12.99 is displayed | High |
| TC-010 | Non-member Express with high subtotal | Logged out; items totaling $200.00 in cart | Proceed to checkout, select Express shipping | Express shipping fee of $12.99 is displayed (not affected by subtotal) | High |

### Express Shipping - Member

| ID | Scenario | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-011 | Member selects Express shipping | Logged in as member; items totaling $40.00 in cart | Proceed to checkout, select Express shipping | Express shipping fee of $7.99 is displayed | High |
| TC-012 | Member Express with very high subtotal | Logged in as member; items totaling $500.00 in cart | Proceed to checkout, select Express shipping | Express shipping fee of $7.99 is displayed (member rate applies regardless of subtotal) | High |

### Shipping Method Comparison

| ID | Scenario | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-013 | Non-member compares shipping options at $30 subtotal | Logged out; items totaling $30.00 in cart | View both shipping options in checkout | Standard shows $5.99, Express shows $12.99 | Medium |
| TC-014 | Member compares shipping options at $30 subtotal | Logged in as member; items totaling $30.00 in cart | View both shipping options in checkout | Standard shows $0.00, Express shows $7.99 | Medium |
| TC-015 | Non-member switches shipping method | Logged out; cart $45.00; Standard shipping initially selected | Select Express, then reselect Standard | Fee updates correctly: Standard to $5.99, back to Standard $5.99 | Medium |
| TC-016 | Member switches shipping method | Logged in as member; cart $45.00; Standard initially selected | Select Express, then reselect Standard | Fee updates correctly: Standard to $0.00, Express to $7.99, back to Standard $0.00 | Medium |

### Membership Edge Cases

| ID | Scenario | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-017 | Membership expires before checkout | Logged in; membership expiration date is today; items totaling $40 | Proceed to checkout | Non-member rates apply (Standard $5.99, Express $12.99) | Medium |
| TC-018 | Non-member upgrades to member mid-cart | Logged out; $35 in cart; user logs in as new member | Proceed to checkout after membership login | Member rates applied (Standard $0.00, Express $7.99) | Medium |

### Price Display and Order Total

| ID | Scenario | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-019 | Non-member sees complete total with $5.99 shipping | Logged out; items $30.00, Standard shipping | Verify order summary | Subtotal: $30.00, Shipping: $5.99, Total (before tax): $35.99 | High |
| TC-020 | Member sees complete total with free shipping | Logged in as member; items $30.00, Standard shipping | Verify order summary | Subtotal: $30.00, Shipping: $0.00, Total (before tax): $30.00 | High |
| TC-021 | Non-member sees total with Express shipping | Logged out; items $75.00, Express shipping | Verify order summary | Subtotal: $75.00, Shipping: $12.99, Total (before tax): $87.99 | High |
| TC-022 | Member sees total with Express shipping | Logged in as member; items $75.00, Express shipping | Verify order summary | Subtotal: $75.00, Shipping: $7.99, Total (before tax): $82.99 | High |

### Boundary and Precision

| ID | Scenario | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-023 | Order with exactly $50.01 subtotal | Logged out; items totaling $50.01 in cart | Select Standard shipping | Free standard shipping ($0.00) is displayed | Medium |
| TC-024 | Order with fractional amounts | Logged out; items totaling $49.99 in cart | Select Standard shipping | Shipping fee of $5.99 is displayed; total shown with correct decimals | Medium |
| TC-025 | Order with many items | Logged out; 20 items in cart totaling $55.00 | Select Standard shipping | Free standard shipping calculated correctly | Low |

### Negative/Error Cases

| ID | Scenario | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-026 | Empty cart at checkout | Logged out; empty cart | Attempt to view checkout | Checkout is blocked or warning shown that cart is empty; shipping fees not displayed | Low |
| TC-027 | Shipping method not selected | Logged out; $40 in cart | Proceed without selecting shipping method | Error message displayed; user must select Standard or Express before continuing | Medium |

---

## Test Coverage Summary
- **Standard Shipping (Non-Member):** 5 test cases
- **Standard Shipping (Member):** 3 test cases  
- **Express Shipping (Non-Member):** 2 test cases
- **Express Shipping (Member):** 2 test cases
- **Shipping Method Comparison:** 4 test cases
- **Membership Edge Cases:** 2 test cases
- **Price Display and Order Total:** 4 test cases
- **Boundary and Precision:** 3 test cases
- **Negative/Error Cases:** 2 test cases

**Total: 27 test cases** covering all acceptance criteria and edge cases.
