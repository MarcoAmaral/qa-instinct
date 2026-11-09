# Loyalty Points

**Assumptions:**
- Points are awarded immediately upon order completion based on subtotal (integer dollars only)
- Tier status is recalculated after each order and determines discount on that order
- Tier thresholds are inclusive: 500+ points enters Silver, 2,000+ enters Gold
- Discount tiers are mutually exclusive; only the highest tier's discount applies
- Point redemptions are a separate action from purchases and use current balance
- Performance requirement (AC-4) is testable through response-time assertions

```gherkin
Feature: Loyalty Points

  Background:
    Given a member is logged into their account

  Scenario: Earn 1 point per whole dollar of subtotal
    Given the member has 0 points
    When the member completes an order with subtotal $24.99
    Then the member earns 24 points
    And the member now has 24 points

  Scenario: Subtotal rounding down to whole dollars
    Given the member has 0 points
    When the member completes an order with subtotal $99.99
    Then the member earns 99 points

  Scenario: Accumulate points across multiple orders
    Given the member has 50 points
    When the member completes an order with subtotal $30.00
    Then the member now has 80 points

  Scenario: Basic tier below 500 points receives no discount
    Given the member has 250 points
    And the member's tier is Basic
    When the member completes an order with subtotal $100.00
    Then no discount is applied
    And the member pays $100.00

  Scenario: Enter Silver tier at 500 points and receive 5% discount
    Given the member has 475 points
    When the member completes an order with subtotal $100.00
    Then the member earns 100 points
    And the member now has 575 points
    And the member's tier is Silver
    And 5% discount is applied to the order
    And the member pays $95.00

  Scenario: Silver member receives 5% discount on subsequent orders
    Given the member has 500 points
    And the member's tier is Silver
    When the member completes an order with subtotal $100.00
    Then 5% discount is applied
    And the member pays $95.00

  Scenario: Enter Gold tier at 2000 points and receive 10% discount
    Given the member has 1975 points
    When the member completes an order with subtotal $100.00
    Then the member earns 100 points
    And the member now has 2075 points
    And the member's tier is Gold
    And 10% discount is applied to the order
    And the member pays $90.00

  Scenario: Gold member receives 10% discount on subsequent orders
    Given the member has 2000 points
    And the member's tier is Gold
    When the member completes an order with subtotal $100.00
    Then 10% discount is applied
    And the member pays $90.00

  Scenario: Downgrade tier when points fall below threshold
    Given the member has 600 points
    And the member's tier is Silver
    When the member redeems 150 points
    Then the member now has 450 points
    And the member's tier is Basic

  Scenario: Redeem points within available balance
    Given the member has 500 points
    When the member redeems 200 points
    Then the redemption succeeds
    And the member now has 300 points

  Scenario: Attempt to redeem more points than balance
    Given the member has 100 points
    When the member attempts to redeem 150 points
    Then the message "You don't have enough points." is displayed
    And the redemption fails
    And the member still has 100 points

  Scenario: Points page loads within performance threshold
    Given the member is viewing the loyalty points page
    When the page is requested
    Then the page loads within 2 seconds
    And the current point balance is displayed
    And the current tier is displayed
```
