# LOY-3: Loyalty points — BDD scenarios

## Assumptions

- **Earning basis:** Points are calculated on the order subtotal before tier discount, point redemption, tax and shipping. Fractional dollars are dropped (floor, not rounding).
- **Tier basis:** Tier is determined by the member's current points balance at the moment the order is placed, so redeeming points can lower a tier. If product intends lifetime-earned points instead, the tier scenarios need their `Given` steps changed, not their outcomes.
- **Discount basis:** The tier discount applies to the subtotal and is applied before any point redemption.
- **Redemption rate:** 100 points = $1.00 off. The story does not state a rate; this is a placeholder to be confirmed.
- **Crediting time:** Points are credited when the order is placed, not when it ships or is delivered.
- **Error text:** The message in AC-3 is matched exactly, including the apostrophe and full stop.
- **AC-4 "fast":** Treated as a 95th-percentile page load under 2 seconds for a member with 10,000 points history entries. The threshold and data volume are placeholders; AC-4 is not testable until product confirms them.

## Feature file

```gherkin
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am logged in as a loyalty programme member

  # AC-1: Earning points

  Scenario Outline: Points are earned per whole dollar of subtotal
    Given my points balance is 0
    When I place an order with a subtotal of <subtotal>
    Then my points balance is <points>

    Examples:
      | subtotal | points |
      | $24.99   | 24     |
      | $25.00   | 25     |
      | $0.99    | 0      |
      | $0.00    | 0      |
      | $1.00    | 1      |
      | $100.01  | 100    |

  Scenario: Points are earned on the subtotal before tax and shipping
    Given my points balance is 0
    When I place an order with a subtotal of $40.00, tax of $3.50 and shipping of $6.00
    Then my points balance is 40

  Scenario: Points are earned on the subtotal before the tier discount
    Given my points balance is 500
    When I place an order with a subtotal of $100.00
    Then the tier discount is $5.00
    And I earn 100 points
    And my points balance is 600

  Scenario: Earned points are added to an existing balance
    Given my points balance is 120
    When I place an order with a subtotal of $30.49
    Then my points balance is 150

  # AC-2: Tiers and discounts

  Scenario Outline: Tier is determined by points balance
    Given my points balance is <balance>
    When I view my loyalty tier
    Then my tier is <tier>

    Examples: Basic
      | balance | tier   |
      | 0       | Basic  |
      | 499     | Basic  |

    Examples: Silver
      | balance | tier   |
      | 500     | Silver |
      | 1999    | Silver |

    Examples: Gold
      | balance | tier   |
      | 2000    | Gold   |
      | 50000   | Gold   |

  Scenario Outline: Tier discount is applied to every order
    Given my points balance is <balance>
    When I place an order with a subtotal of $80.00
    Then the tier discount is <discount>
    And the order total before tax and shipping is <total>

    Examples:
      | balance | discount | total  |
      | 499     | $0.00    | $80.00 |
      | 500     | $4.00    | $76.00 |
      | 1999    | $4.00    | $76.00 |
      | 2000    | $8.00    | $72.00 |

  Scenario: Tier is upgraded as soon as the threshold is crossed
    Given my points balance is 480
    When I place an order with a subtotal of $20.00
    Then my points balance is 500
    And my tier is Silver

  Scenario: Discount uses the tier held when the order is placed
    Given my points balance is 480
    When I place an order with a subtotal of $20.00
    Then the tier discount is $0.00
    And my tier after the order is Silver

  Scenario: Redeeming points below a threshold lowers the tier
    Given my points balance is 500
    And my tier is Silver
    When I redeem 100 points
    Then my points balance is 400
    And my tier is Basic

  # AC-3: Redemption

  Scenario: Redeeming up to the full balance succeeds
    Given my points balance is 300
    When I redeem 300 points against an order with a subtotal of $50.00
    Then the redemption discount is $3.00
    And my points balance is 0

  Scenario: Redeeming part of the balance succeeds
    Given my points balance is 300
    When I redeem 150 points against an order with a subtotal of $50.00
    Then the redemption discount is $1.50
    And my points balance is 150

  Scenario: Redeeming more points than the balance is rejected
    Given my points balance is 300
    When I attempt to redeem 301 points against an order with a subtotal of $50.00
    Then I see the message "You don't have enough points."
    And the redemption discount is $0.00
    And my points balance is 300

  Scenario: Redeeming with a zero balance is rejected
    Given my points balance is 0
    When I attempt to redeem 1 point against an order with a subtotal of $50.00
    Then I see the message "You don't have enough points."
    And my points balance is 0

  Scenario: A rejected redemption does not block the order
    Given my points balance is 300
    And I have attempted to redeem 301 points against an order with a subtotal of $50.00
    When I place the order without redeeming points
    Then the order is placed
    And my points balance is 350

  Scenario: Tier discount and redemption are combined on one order
    Given my points balance is 2500
    When I redeem 1000 points against an order with a subtotal of $100.00
    And I place the order
    Then the tier discount is $10.00
    And the redemption discount is $10.00
    And the order total before tax and shipping is $80.00
    And my points balance is 1600

  # AC-4: Points page performance

  @performance @needs-threshold-confirmation
  Scenario: Points page loads within the agreed time
    Given my account has 10,000 points history entries
    When I open the points page 100 times under normal load
    Then the 95th-percentile page load time is under 2 seconds
    And every load shows my current balance and tier
```

## Open questions to confirm

- Is tier based on current balance or lifetime points earned?
- What is the points-to-dollar redemption rate, and is there a minimum or maximum redemption per order?
- What load time and data volume define "fast" for AC-4?
