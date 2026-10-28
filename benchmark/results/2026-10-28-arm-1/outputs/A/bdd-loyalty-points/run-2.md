# Loyalty Points - Gherkin Scenarios

**Assumptions made:**
- New members start with 0 points
- Tier discounts apply automatically at checkout
- Points balance cannot go below 0
- "Fast page load" = under 2 seconds for the points page
- Redeemed points are deducted from balance immediately
- Tier is determined by cumulative lifetime points

---

```gherkin
Feature: Loyalty Points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given a member exists with 0 points
    And the member's tier is "Basic"

  Scenario: Earn points from order subtotal
    Given the member has 0 points
    When the member places an order with subtotal $100.00
    Then the member should earn 100 points
    And the member's total points should be 100

  Scenario Outline: Earn points rounded down to whole dollars
    Given the member has 0 points
    When the member places an order with subtotal <subtotal>
    Then the member should earn <points> points

    Examples:
      | subtotal | points |
      | $24.99   | 24     |
      | $100.50  | 100    |
      | $9.99    | 9      |
      | $1.01    | 1      |

  Scenario: Member reaches Silver tier at 500 points
    Given the member has 499 points and tier "Basic"
    When the member places an order with subtotal $10.00
    Then the member should earn 10 points
    And the member's tier should change to "Silver"
    And the member should receive 5% discount on future orders

  Scenario: Silver member receives discount on order
    Given the member has 500 points and tier "Silver"
    When the member places an order with subtotal $100.00
    Then the member should earn 100 points
    And a 5% discount should be applied to the order

  Scenario: Member reaches Gold tier at 2000 points
    Given the member has 1999 points and tier "Silver"
    When the member places an order with subtotal $5.00
    Then the member should earn 5 points
    And the member's tier should change to "Gold"
    And the member should receive 10% discount on future orders

  Scenario: Gold member receives discount on order
    Given the member has 2000 points and tier "Gold"
    When the member places an order with subtotal $100.00
    Then the member should earn 100 points
    And a 10% discount should be applied to the order

  Scenario: Redeem points within available balance
    Given the member has 500 points
    When the member redeems 250 points
    Then the redemption should succeed
    And the member's points balance should be 250

  Scenario: Redeem points exceeds available balance
    Given the member has 100 points
    When the member attempts to redeem 150 points
    Then the redemption should fail with error message "You don't have enough points."
    And the member's points balance should remain 100

  Scenario: Points page loads within acceptable time
    Given the member is on the loyalty points page
    When the page loads
    Then the page should render in under 2 seconds
    And all point balance and tier information should be displayed
```
