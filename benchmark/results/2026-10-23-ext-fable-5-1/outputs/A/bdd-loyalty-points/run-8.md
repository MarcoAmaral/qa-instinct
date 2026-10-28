# Feature: Loyalty points (LOY-3)

**Assumptions** (not stated in the story):

- Redemption rate: 100 points = $1.00 off, applied to the current order. Points are redeemed in whole-point amounts.
- Tier is based on the member's current points balance and is re-evaluated whenever the balance changes.
- Points are earned on the subtotal before tier discounts, redemptions, tax and shipping.
- Points are credited when the order is placed. Earned points do not count toward the order they were earned on.
- Tier discount applies to the subtotal and stacks with a points redemption.
- "Load fast" is read as a 95th-percentile page load under 2 seconds, measured on a member with a large history.

```gherkin
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am signed in as a loyalty programme member

  # AC-1: earning points

  Scenario Outline: Points are earned per whole dollar of the subtotal
    Given my points balance is 0
    When I place an order with a subtotal of <subtotal>
    Then my points balance is <points>

    Examples:
      | subtotal | points |
      | $24.99   | 24     |
      | $25.00   | 25     |
      | $0.99    | 0      |
      | $100.01  | 100    |

  Scenario: Points are earned on the pre-discount subtotal
    Given my points balance is 600 and my tier is Silver
    When I place an order with a subtotal of $40.00
    Then a 5% discount of $2.00 is applied
    And I earn 40 points

  Scenario: Earned points are added to the existing balance
    Given my points balance is 120
    When I place an order with a subtotal of $30.50
    Then my points balance is 150

  # AC-2: tiers and discounts

  Scenario Outline: Tier is determined by points balance
    Given my points balance is <balance>
    When I view the points page
    Then my tier is shown as <tier>

    Examples:
      | balance | tier   |
      | 0       | Basic  |
      | 499     | Basic  |
      | 500     | Silver |
      | 1999    | Silver |
      | 2000    | Gold   |
      | 5000    | Gold   |

  Scenario Outline: Tier discount is applied to the order subtotal
    Given my points balance is <balance>
    When I place an order with a subtotal of $100.00
    Then a discount of <discount> is applied
    And the order total before tax and shipping is <total>

    Examples:
      | balance | discount | total   |
      | 499     | $0.00    | $100.00 |
      | 500     | $5.00    | $95.00  |
      | 2000    | $10.00   | $90.00  |

  Scenario: Crossing a tier threshold upgrades the member
    Given my points balance is 480 and my tier is Basic
    When I place an order with a subtotal of $20.00
    Then my points balance is 500
    And my tier is Silver

  Scenario: Redeeming points below a threshold downgrades the member
    Given my points balance is 2000 and my tier is Gold
    When I redeem 100 points on an order
    Then my points balance is 1900
    And my tier is Silver

  # AC-3: redeeming points

  Scenario: Redeeming points within the balance applies a discount
    Given my points balance is 300
    And I have an order with a subtotal of $50.00
    When I redeem 200 points on the order
    Then a discount of $2.00 is applied
    And my points balance is 100

  Scenario: Redeeming the entire balance is allowed
    Given my points balance is 300
    And I have an order with a subtotal of $50.00
    When I redeem 300 points on the order
    Then a discount of $3.00 is applied
    And my points balance is 0

  Scenario: Redeeming more points than the balance is rejected
    Given my points balance is 300
    And I have an order with a subtotal of $50.00
    When I attempt to redeem 301 points on the order
    Then I see the message "You don't have enough points."
    And no discount is applied to the order
    And my points balance is still 300

  Scenario: Redeeming with a zero balance is rejected
    Given my points balance is 0
    And I have an order with a subtotal of $50.00
    When I attempt to redeem 1 point on the order
    Then I see the message "You don't have enough points."
    And my points balance is still 0

  Scenario: Tier discount and points redemption stack on one order
    Given my points balance is 700 and my tier is Silver
    And I have an order with a subtotal of $100.00
    When I redeem 500 points on the order
    Then a 5% tier discount of $5.00 is applied
    And a redemption discount of $5.00 is applied
    And the order total before tax and shipping is $90.00
    And my points balance is 200

  # AC-4: points page performance

  Scenario: Points page loads quickly for a member with a large history
    Given I have 1,000 orders in my points history
    When I open the points page
    Then the page is fully loaded within 2 seconds
    And it shows my current balance and tier

  Scenario: Points page meets the load target under normal traffic
    Given the points page is requested 100 times under normal production-like load
    Then the 95th-percentile load time is under 2 seconds
```
