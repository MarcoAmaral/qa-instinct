```gherkin
@loyalty
Feature: Loyalty Points Earning and Redemption
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  # Assumptions: Points are earned immediately when an order is placed.
  # Discounts apply automatically based on current tier. Page load "fast" = < 2 seconds.
  # Tier discount applies to subtotal only. Redemption is a separate action from tier discounts.

  Background:
    Given the member is logged in

  @smoke @p0
  Scenario: Member earns 1 point per whole dollar of order subtotal
    Given the member has 0 points
    When the member places an order with subtotal $24.99
    Then the member earns 24 points
    And the points balance is 24

  @p0
  Scenario: Fractional dollars do not earn points
    Given the member has 0 points
    When the member places an order with subtotal $100.85
    Then the member earns 100 points
    And the points balance is 100

  @p0
  Scenario: Basic tier member below 500 points receives no discount
    Given the member has 400 points
    When the member places an order with subtotal $100.00
    Then no tier discount is applied
    And the order charge is $100.00

  @smoke @p0
  Scenario: Silver tier member at 500 points receives 5% discount
    Given the member has 500 points
    When the member places an order with subtotal $100.00
    Then the 5% Silver tier discount is applied
    And the order charge is $95.00

  @p0
  Scenario: Gold tier member at 2000 points receives 10% discount
    Given the member has 2000 points
    When the member places an order with subtotal $100.00
    Then the 10% Gold tier discount is applied
    And the order charge is $90.00

  @p1
  Scenario: Tier promotion activates immediately when threshold is reached
    Given the member has 499 points
    When the member places an order earning 1 point
    Then the member becomes Silver tier with 500 points
    And the 5% discount is applied to that order

  @smoke @p0
  Scenario: Redeeming more points than the balance shows error
    Given the member has 100 points
    When the member attempts to redeem 150 points
    Then the error "You don't have enough points." is displayed
    And the points balance remains 100

  @p0
  Scenario: Redeeming within balance succeeds
    Given the member has 100 points
    When the member redeems 50 points
    Then the redemption completes
    And the points balance is 50

  @p1 @performance
  Scenario: Points page loads quickly
    Given the member opens the points page
    When the page loads
    Then the balance and tier information are visible within 2 seconds

  # Added by QA, validates points balance updates after transaction
  @regression @p0
  Scenario: Points balance updates after order completion
    Given the member has 250 points
    When the member places an order with subtotal $75.50
    Then the member's balance updates to 325 points

  # Added by QA, confirms Silver tier maintains eligibility through orders
  @regression @p0
  Scenario: Silver tier discount applies across multiple orders
    Given the member has 500 points
    When the member places an order with subtotal $100.00 earning 100 points
    And the member places another order with subtotal $50.00
    Then both orders receive the 5% Silver discount
    And the final balance is 650 points

  # Added by QA, edge case for Gold tier threshold
  @p1
  Scenario: Gold tier activates at exactly 2000 points
    Given the member has exactly 2000 points
    When the member places an order with subtotal $100.00
    Then the 10% Gold tier discount applies
    And the order charge is $90.00
```
