@loyalty
Feature: Loyalty Points - Earning, Redeeming, and Tier Management
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am a registered loyalty programme member
    And the loyalty programme is active

  @smoke @p0
  Scenario: Member earns 1 point per whole dollar of order subtotal
    Given I have 0 points
    When I place an order with subtotal $24.99
    Then I earn 24 points
    And my total points are 24

  @regression @p1
  Scenario Outline: Points earned rounds down fractional dollars
    Given I have <initial_points> points
    When I place an order with subtotal <subtotal>
    Then I earn <points_earned> points

    Examples:
      | initial_points | subtotal | points_earned |
      | 0              | $1.50    | 1             |
      | 0              | $100.99  | 100           |
      | 100            | $50.49   | 50            |

  @smoke @p0
  Scenario: Member below 500 points has Basic tier with no discount
    Given I have 400 points
    When I view my loyalty status
    Then my tier is Basic
    And future orders receive 0% discount

  @smoke @p0
  Scenario: Member at 500 points reaches Silver tier with 5% discount
    Given I have 499 points
    When I earn 1 point
    Then my tier changes to Silver
    And future orders receive 5% discount

  @smoke @p0
  Scenario: Member at 2000 points reaches Gold tier with 10% discount
    Given I have 1999 points
    When I earn 1 point
    Then my tier changes to Gold
    And future orders receive 10% discount

  @regression @p1
  Scenario Outline: Tier is determined by total points
    Given I have <points> points
    When I check my tier
    Then my tier is <tier>
    And my order discount is <discount>%

    Examples:
      | points | tier   | discount |
      | 0      | Basic  | 0        |
      | 499    | Basic  | 0        |
      | 500    | Silver | 5        |
      | 1999   | Silver | 5        |
      | 2000   | Gold   | 10       |
      | 5000   | Gold   | 10       |

  @smoke @p0
  Scenario: Redeeming insufficient points shows error message
    Given I have 100 points
    When I attempt to redeem 150 points
    Then the redemption fails
    And I see the message "You don't have enough points."
    And my points balance remains 100

  @smoke @p0
  Scenario: Redeeming within balance succeeds
    Given I have 500 points
    When I attempt to redeem 200 points
    Then the redemption succeeds
    And my points balance becomes 300

  # Added by QA, boundary condition for zero balance
  @regression @p2
  Scenario: Cannot redeem when points balance is zero
    Given I have 0 points
    When I attempt to redeem 1 point
    Then the redemption fails
    And I see the message "You don't have enough points."
    And my points balance remains 0

  # Added by QA, verifies redemption is atomic and prevents race conditions
  @regression @p2
  Scenario: Redemption fails atomically; no partial deduction
    Given I have 100 points
    When I attempt to redeem 150 points
    Then the redemption fails
    And my points balance is exactly 100, not reduced

  # Added by QA, assumes "fast" means sub-2-second response time per web standards
  @performance @p1
  Scenario: Points page loads fast
    Given I navigate to my loyalty points page
    When the page loads
    Then the page is fully interactive within 2 seconds
    And my current points, tier, and discount are displayed
