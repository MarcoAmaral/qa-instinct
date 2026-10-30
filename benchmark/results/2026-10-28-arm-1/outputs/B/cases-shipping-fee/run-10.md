# Test Cases for SHIP-9: Shipping Fee at Checkout

## Test Assumptions
- Test environment has user accounts with both member and non-member roles
- Subtotal is the order amount before taxes and shipping charges
- Shipping method selection occurs at checkout before payment
- Currency is USD with $0.01 precision
- System correctly identifies user membership status before displaying shipping fees

---

## Scenario 1: Standard Shipping - Non-Member Users

| Test ID | Title | Preconditions | Steps | Expected Result | AC Ref |
|---------|-------|---|---|---|---|
| TC-1.1 | Subtotal below $50 threshold | Non-member user; Standard shipping selected | 1. Add items totaling $49.99 to cart<br>2. Proceed to checkout<br>3. Select Standard Shipping<br>4. Review shipping fee | Shipping fee displays as $5.99 | AC-1 |
| TC-1.2 | Subtotal exactly at $50 | Non-member user; Standard shipping selected | 1. Add items totaling $50.00 to cart<br>2. Proceed to checkout<br>3. Select Standard Shipping<br>4. Review shipping fee | Shipping fee displays as $0.00 (free) | AC-1 |
| TC-1.3 | Subtotal above $50 | Non-member user; Standard shipping selected | 1. Add items totaling $100.00 to cart<br>2. Proceed to checkout<br>3. Select Standard Shipping<br>4. Review shipping fee | Shipping fee displays as $0.00 (free) | AC-1 |
| TC-1.4 | Subtotal just below $50 | Non-member user; Standard shipping selected | 1. Add items totaling $49.01 to cart<br>2. Proceed to checkout<br>3. Select Standard Shipping<br>4. Review shipping fee | Shipping fee displays as $5.99 | AC-1 |

---

## Scenario 2: Standard Shipping - Member Users

| Test ID | Title | Preconditions | Steps | Expected Result | AC Ref |
|---------|-------|---|---|---|---|
| TC-2.1 | Member with low subtotal | Member user; Subtotal $25.00; Standard shipping selected | 1. Log in as member<br>2. Add items totaling $25.00 to cart<br>3. Proceed to checkout<br>4. Select Standard Shipping<br>5. Review shipping fee | Shipping fee displays as $0.00 (free) | AC-2 |
| TC-2.2 | Member with high subtotal | Member user; Subtotal $200.00; Standard shipping selected | 1. Log in as member<br>2. Add items totaling $200.00 to cart<br>3. Proceed to checkout<br>4. Select Standard Shipping<br>5. Review shipping fee | Shipping fee displays as $0.00 (free) | AC-2 |
| TC-2.3 | Member at $50 boundary | Member user; Subtotal $50.00; Standard shipping selected | 1. Log in as member<br>2. Add items totaling $50.00 to cart<br>3. Proceed to checkout<br>4. Select Standard Shipping<br>5. Review shipping fee | Shipping fee displays as $0.00 (free) | AC-2 |

---

## Scenario 3: Express Shipping - Non-Member Users

| Test ID | Title | Preconditions | Steps | Expected Result | AC Ref |
|---------|-------|---|---|---|---|
| TC-3.1 | Non-member standard order | Non-member user; Any subtotal; Express shipping selected | 1. Add items to cart<br>2. Proceed to checkout<br>3. Select Express Shipping<br>4. Review shipping fee | Shipping fee displays as $12.99 | AC-3 |
| TC-3.2 | Non-member low subtotal express | Non-member user; Subtotal $10.00; Express shipping selected | 1. Add items totaling $10.00 to cart<br>2. Proceed to checkout<br>3. Select Express Shipping<br>4. Review shipping fee | Shipping fee displays as $12.99 | AC-3 |
| TC-3.3 | Non-member high subtotal express | Non-member user; Subtotal $500.00; Express shipping selected | 1. Add items totaling $500.00 to cart<br>2. Proceed to checkout<br>3. Select Express Shipping<br>4. Review shipping fee | Shipping fee displays as $12.99 | AC-3 |

---

## Scenario 4: Express Shipping - Member Users

| Test ID | Title | Preconditions | Steps | Expected Result | AC Ref |
|---------|-------|---|---|---|---|
| TC-4.1 | Member express shipping | Member user; Any subtotal; Express shipping selected | 1. Log in as member<br>2. Add items to cart<br>3. Proceed to checkout<br>4. Select Express Shipping<br>5. Review shipping fee | Shipping fee displays as $7.99 | AC-3 |
| TC-4.2 | Member low subtotal express | Member user; Subtotal $5.00; Express shipping selected | 1. Log in as member<br>2. Add items totaling $5.00 to cart<br>3. Proceed to checkout<br>4. Select Express Shipping<br>5. Review shipping fee | Shipping fee displays as $7.99 | AC-3 |

---

## Scenario 5: Edge Cases & Combinations

| Test ID | Title | Preconditions | Steps | Expected Result | AC Ref |
|---------|-------|---|---|---|---|
| TC-5.1 | Switch from standard to express | Non-member; Subtotal $75.00 | 1. Add items totaling $75.00<br>2. Checkout shows Standard Shipping as $0.00<br>3. Change selection to Express<br>4. Review shipping fee | Shipping fee updates to $12.99 immediately | AC-1, AC-3 |
| TC-5.2 | Switch from express to standard | Non-member; Subtotal $30.00 | 1. Add items totaling $30.00<br>2. Checkout shows Express Shipping as $12.99<br>3. Change selection to Standard<br>4. Review shipping fee | Shipping fee updates to $5.99 immediately | AC-1, AC-3 |
| TC-5.3 | Member status change impact | Initially non-member, then upgrades to member | 1. Add items totaling $40.00 as non-member<br>2. Proceed to checkout with Standard Shipping (shows $5.99)<br>3. Log out and upgrade account to member<br>4. Log back in and review cart/checkout<br>5. Select Standard Shipping | Shipping fee updates to $0.00 for member | AC-1, AC-2 |
| TC-5.4 | Verify total calculation includes shipping | Non-member; Subtotal $30.00; Standard shipping selected | 1. Add items totaling $30.00 to cart<br>2. Proceed to checkout<br>3. Select Standard Shipping<br>4. Review order total | Order total = $30.00 (subtotal) + $5.99 (shipping) | AC-1 |
| TC-5.5 | Zero subtotal edge case | Non-member user; Empty cart | 1. User at checkout with empty cart<br>2. Attempt to select shipping method | System either prevents checkout or displays applicable fee for $0.00 subtotal ($5.99 for standard) | AC-1 |

---

## Scenario 6: Persistence & Consistency

| Test ID | Title | Preconditions | Steps | Expected Result | AC Ref |
|---------|-------|---|---|---|---|
| TC-6.1 | Shipping fee persists through order review | Non-member; Subtotal $45.00; Standard shipping selected | 1. Add items totaling $45.00<br>2. Select Standard Shipping ($5.99)<br>3. Review order page<br>4. Navigate back to shipping options<br>5. Return to order review | Shipping fee remains $5.99 throughout flow | AC-1 |
| TC-6.2 | Correct fee on order confirmation | Non-member; Subtotal $60.00; Express shipping selected | 1. Add items totaling $60.00<br>2. Select Express Shipping ($12.99)<br>3. Complete payment<br>4. View order confirmation | Confirmation displays Express shipping at $12.99 | AC-3 |
