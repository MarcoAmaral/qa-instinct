@loyalty
Feature: Loyalty Points Earning and Redemption
  As a loyalty programme member
  I want to earn points on purchases and redeem them for discounts
  So that I receive rewards and incentives for my continued business

  Background:
    Given the loyalty programme is active
    And I am a registered loyalty programme member

  @smoke @p0
  Scenario: Member earns 1 point per whole dollar of order subtotal
    Given I have a current points balance of 0
    When I complete an order with a subtotal of $24.99
    Then my points balance is 24

  @regression
  Scenario Outline: Points earned rounded down to whole dollars only
    Given I have a current points balance of 0
    When I complete an order with a subtotal of <subtotal>
    Then my points balance is <points_earned>

    Examples:
      | subtotal | points_earned |
      | $10.00   | 10            |
      | $10.99   | 10            |
      | $99.50   | 99            |
      | $100.00  | 100           |
      | $0.99    | 0             |

  @smoke @p0
  Scenario: Member tier is Basic below 500 points
    Given I have a current points balance of 499
    When I review my account tier
    Then my tier is Basic
    And no automatic discount is applied to my orders

  @smoke @p0
  Scenario: Member tier is Silver with 500+ points
    Given I have a current points balance of 500
    When I review my account tier
    Then my tier is Silver
    And a 5% discount is applied to my orders

  @smoke @p0
  Scenario: Member tier is Gold with 2000+ points
    Given I have a current points balance of 2000
    When I review my account tier
    Then my tier is Gold
    And a 10% discount is applied to my orders

  # Added by QA, ticket does not specify tier transition behaviour
  @regression
  Scenario: Tier upgrades immediately when points threshold is reached
    Given I have a current points balance of 499
    When I complete an order earning 1 point
    Then my points balance is 500
    And my tier is upgraded to Silver
    And the 5% discount applies to my next order

  @smoke @p0
  Scenario: Redemption fails when points balance is insufficient
    Given I have a current points balance of 50
    When I attempt to redeem 75 points
    Then the error message "You don't have enough points." is displayed
    And my points balance remains 50
    And no points are deducted

  # Added by QA, AC-3 silent on successful redemption; testing inverse case
  @regression
  Scenario: Redemption succeeds when points balance is sufficient
    Given I have a current points balance of 100
    When I redeem 50 points
    Then the redemption is successful
    And my points balance decreases to 50

  # Added by QA, AC-4 performance requirement; assuming 3-second threshold as industry standard
  @performance @p1
  Scenario: Points page loads within acceptable performance threshold
    Given I navigate to my loyalty points page
    When the page begins loading
    Then the page fully loads and displays my balance within 3 seconds
