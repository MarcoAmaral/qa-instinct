# Assumptions:
# - Points are credited upon order confirmation
# - Discounts are applied automatically at checkout based on member tier
# - "Fast" for AC-4 is defined as < 2 seconds page load time
# - Members can view their current point balance, tier, and transaction history on the points page
# - Redemption is instantaneous (not subject to pending/approval workflows)

@loyalty @points
Feature: Loyalty Points - Earning and Redemption
  As a loyalty programme member
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given the loyalty programme is active
    And I am a registered member

  @smoke @p0 @earning
  Scenario: Member earns one point per whole dollar of order subtotal
    Given I have 0 points
    When I place an order with subtotal $24.99
    And the order is confirmed
    Then I earn 24 points
    And my point balance is 24

  @regression @earning
  Scenario: Fractional dollars do not earn points
    Given I have 0 points
    When I place an order with subtotal $50.49
    And the order is confirmed
    Then I earn 50 points
    And my point balance is 50

  @smoke @p0 @tier
  Scenario: Basic member receives no discount
    Given I am a Basic tier member with 100 points
    When I place an order with subtotal $100.00
    Then no discount is applied
    And my order total is $100.00

  @smoke @p0 @tier
  Scenario: Silver member receives 5% discount
    Given I am a Silver tier member with 500 points
    When I place an order with subtotal $100.00
    Then a 5% discount is applied
    And my order total is $95.00

  @smoke @p0 @tier
  Scenario: Gold member receives 10% discount
    Given I am a Gold tier member with 2000 points
    When I place an order with subtotal $100.00
    Then a 10% discount is applied
    And my order total is $90.00

  # Added by QA, AC-2 does not specify tier transition points
  @regression @p1 @tier
  Scenario: Member advances to Silver tier upon reaching 500 points
    Given I am a Basic tier member with 499 points
    When I earn 1 point
    Then my tier advances to Silver
    And my point balance is 500
    And 5% discount applies to my next order

  # Added by QA, AC-2 does not specify tier transition points
  @regression @p1 @tier
  Scenario: Member advances to Gold tier upon reaching 2000 points
    Given I am a Silver tier member with 1999 points
    When I earn 1 point
    Then my tier advances to Gold
    And my point balance is 2000
    And 10% discount applies to my next order

  @smoke @p0 @redemption
  Scenario: Redeeming more points than balance shows error
    Given my point balance is 100
    When I attempt to redeem 150 points
    Then the error message "You don't have enough points." is displayed
    And my point balance remains 100
    And 0 points are redeemed

  @smoke @p1 @redemption
  Scenario: Member successfully redeems points within balance
    Given my point balance is 100
    When I redeem 50 points
    Then the redemption succeeds
    And my point balance becomes 50

  @performance @p1
  Scenario: Points dashboard page loads fast
    Given I navigate to the loyalty points page
    When the page begins loading
    Then the page fully loads within 2 seconds
    And I can view my point balance
    And I can view my current tier
    And I can view redemption options

  # Added by QA, AC-3 does not address invalid amounts
  @regression @p2 @redemption
  Scenario Outline: Invalid redemption amounts are rejected
    Given my point balance is 100
    When I attempt to redeem <amount> points
    Then the redemption is rejected
    And the message is "<message>"

    Examples:
      | amount | message                       |
      | 0      | Enter a valid point amount    |
      | -5     | Points must be positive       |
      | 101    | You don't have enough points. |
