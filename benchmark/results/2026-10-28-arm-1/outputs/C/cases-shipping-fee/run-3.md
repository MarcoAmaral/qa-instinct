# Test Cases for SHIP-9: Shipping Fee at Checkout

## Assumptions

- **Member:** A user with an active account membership status
- **Non-member:** A guest user or account holder without membership
- **Subtotal:** Sum of item prices before shipping and tax
- **Shipping display:** Fees are shown on the checkout page before payment
- **Shipping options:** Both standard and express are available to all users
- **No promos:** Test assumes no discount codes or shipping promos apply

---

## Standard Shipping — Non-Member

| Test ID | Scenario | Setup | Steps | Expected Result |
| --- | --- | --- | --- | --- |
| TC-SS-001 | Subtotal $50+ shows free standard shipping | Non-member, cart subtotal $50.00 | 1. Go to checkout<br>2. Select **Standard shipping** | Standard shipping fee: $0.00 |
| TC-SS-002 | Subtotal $50+ shows free standard shipping (high amount) | Non-member, cart subtotal $100.00 | 1. Go to checkout<br>2. Select **Standard shipping** | Standard shipping fee: $0.00 |
| TC-SS-003 | Subtotal $49.99 shows $5.99 fee | Non-member, cart subtotal $49.99 | 1. Go to checkout<br>2. Select **Standard shipping** | Standard shipping fee: $5.99 |
| TC-SS-004 | Subtotal $1.00 shows $5.99 fee | Non-member, cart subtotal $1.00 | 1. Go to checkout<br>2. Select **Standard shipping** | Standard shipping fee: $5.99 |
| TC-SS-005 | Subtotal exactly $50.00 is threshold for free shipping | Non-member, cart subtotal $50.00 | 1. Go to checkout<br>2. Select **Standard shipping** | Standard shipping fee: $0.00 |
| TC-SS-006 | Subtotal $49.99 is below threshold | Non-member, cart subtotal $49.99 | 1. Go to checkout<br>2. Select **Standard shipping** | Standard shipping fee: $5.99 |

---

## Standard Shipping — Member

| Test ID | Scenario | Setup | Steps | Expected Result |
| --- | --- | --- | --- | --- |
| TC-SM-001 | Member with subtotal $50+ shows free standard shipping | Member, cart subtotal $50.00 | 1. Go to checkout (logged in as member)<br>2. Select **Standard shipping** | Standard shipping fee: $0.00 |
| TC-SM-002 | Member with low subtotal shows free standard shipping | Member, cart subtotal $1.00 | 1. Go to checkout (logged in as member)<br>2. Select **Standard shipping** | Standard shipping fee: $0.00 |
| TC-SM-003 | Member with zero subtotal shows free standard shipping | Member, cart subtotal $0.00 | 1. Go to checkout (logged in as member)<br>2. Select **Standard shipping** | Standard shipping fee: $0.00 |

---

## Express Shipping — Non-Member

| Test ID | Scenario | Setup | Steps | Expected Result |
| --- | --- | --- | --- | --- |
| TC-ES-001 | Non-member express shipping costs $12.99 (high subtotal) | Non-member, cart subtotal $100.00 | 1. Go to checkout<br>2. Select **Express shipping** | Express shipping fee: $12.99 |
| TC-ES-002 | Non-member express shipping costs $12.99 (low subtotal) | Non-member, cart subtotal $1.00 | 1. Go to checkout<br>2. Select **Express shipping** | Express shipping fee: $12.99 |
| TC-ES-003 | Non-member express shipping costs $12.99 | Non-member, cart subtotal $50.00 | 1. Go to checkout<br>2. Select **Express shipping** | Express shipping fee: $12.99 |

---

## Express Shipping — Member

| Test ID | Scenario | Setup | Steps | Expected Result |
| --- | --- | --- | --- | --- |
| TC-EM-001 | Member express shipping costs $7.99 (high subtotal) | Member, cart subtotal $100.00 | 1. Go to checkout (logged in as member)<br>2. Select **Express shipping** | Express shipping fee: $7.99 |
| TC-EM-002 | Member express shipping costs $7.99 (low subtotal) | Member, cart subtotal $1.00 | 1. Go to checkout (logged in as member)<br>2. Select **Express shipping** | Express shipping fee: $7.99 |
| TC-EM-003 | Member express shipping costs $7.99 | Member, cart subtotal $50.00 | 1. Go to checkout (logged in as member)<br>2. Select **Express shipping** | Express shipping fee: $7.99 |

---

## Shipping Selection Switching

| Test ID | Scenario | Setup | Steps | Expected Result |
| --- | --- | --- | --- | --- |
| TC-SW-001 | User changes from standard to express | Non-member, cart subtotal $100.00, standard selected | 1. Go to checkout<br>2. Select **Standard shipping** (shows $0.00)<br>3. Select **Express shipping** | Express shipping fee updates to $12.99 |
| TC-SW-002 | User changes from express to standard | Non-member, cart subtotal $30.00, express selected | 1. Go to checkout<br>2. Select **Express shipping** (shows $12.99)<br>3. Select **Standard shipping** | Standard shipping fee updates to $5.99 |
| TC-SW-003 | Member changes from express to standard | Member, express selected | 1. Go to checkout (logged in as member)<br>2. Select **Express shipping** (shows $7.99)<br>3. Select **Standard shipping** | Standard shipping fee updates to $0.00 |

---

## Edge Cases

| Test ID | Scenario | Setup | Steps | Expected Result |
| --- | --- | --- | --- | --- |
| TC-EC-001 | Membership expires mid-checkout | Member with expired membership, cart subtotal $10.00 | 1. Go to checkout<br>2. Select **Standard shipping** | Standard shipping fee: $5.99 (non-member rate) |
| TC-EC-002 | Member becomes non-member after checkout starts | User loses membership between cart and checkout, subtotal $30.00 | 1. Add items ($30.00)<br>2. Start checkout (membership active)<br>3. Membership expires<br>4. Select **Standard shipping** | Standard shipping fee: $5.99 (non-member rate) |
| TC-EC-003 | Decimal subtotal rounds correctly | Non-member, cart subtotal $50.01 | 1. Go to checkout<br>2. Select **Standard shipping** | Standard shipping fee: $0.00 |
