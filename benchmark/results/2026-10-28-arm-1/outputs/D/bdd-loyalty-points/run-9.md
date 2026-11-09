@loyalty
Feature: Loyalty Points Program
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am a registered member of the loyalty programme
    And I am logged in
    And my points balance is visible in my account

  @smoke @p0
  Scenario: Member earns 1 point per whole dollar of order subtotal
    Given my current points balance is 0
    When I place an order with a subtotal of $24.99
    Then my points balance increases to 24 points

  @regression @p1
  Scenario: Fractional dollars are not converted to points
    Given my current points balance is 50 points
    When I place an order with a subtotal of $100.75
    Then my points balance becomes 150 points
    And only the $100 is counted

  @smoke @p0
  Scenario: Member in Basic tier below 500 points
    Given my current points balance is 450 points
    When I view my loyalty tier
    Then my tier is Basic
    And no discount applies to orders

  @smoke @p0
  Scenario: Member reaches Silver tier at 500 points
    Given my current points balance is 500 points
    When I place an order with a subtotal of $100.00
    Then my tier is Silver
    And a 5% discount is applied to the order

  @smoke @p0
  Scenario: Member reaches Gold tier at 2000 points
    Given my current points balance is 2000 points
    When I place an order with a subtotal of $100.00
    Then my tier is Gold
    And a 10% discount is applied to the order

  @smoke @p0
  Scenario: Redemption fails with insufficient points
    Given my current points balance is 50 points
    When I attempt to redeem 100 points
    Then the error message "You don't have enough points." is displayed
    And my points balance remains 50 points
    And no points are deducted

  # Added by QA, clarifying successful redemption behavior not specified in AC-3
  @regression @p1
  Scenario: Redemption succeeds with sufficient points
    Given my current points balance is 200 points
    When I redeem 75 points
    Then my points balance becomes 125 points
    And the redemption is confirmed

  # Added by QA, edge case for exact balance redemption
  @regression @p2
  Scenario: Member can redeem entire points balance
    Given my current points balance is 100 points
    When I redeem 100 points
    Then my points balance becomes 0 points
    And the redemption succeeds

  # Added by QA, clarifying tier demotion when balance drops
  @regression @p2
  Scenario: Member tier downgrades when balance falls below tier threshold
    Given I am in Silver tier with 500 points
    When I redeem 100 points
    Then my points balance becomes 400 points
    And my tier changes to Basic
    And future orders receive no tier discount

  @performance @p0
  Scenario: Points page loads quickly
    Given I navigate to my loyalty account page
    When the page starts loading
    Then all points balance and tier information is displayed within 2 seconds
