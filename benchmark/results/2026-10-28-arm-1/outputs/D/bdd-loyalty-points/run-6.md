```gherkin
@loyalty
Feature: Loyalty Programme Points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am logged in as a loyalty programme member

  @smoke @p0
  Scenario: Member earns 1 point per whole dollar of order subtotal
    Given I have 0 points
    When I place an order with a subtotal of $24.99
    Then I earn 24 points
    And my points balance is 24

  # Added by QA, to verify whole-dollar rounding behavior (floor, not round)
  @regression
  Scenario Outline: Points earned are calculated from whole dollars only
    Given I have 0 points
    When I place an order with a subtotal of "<subtotal>"
    Then I earn <points> points

    Examples:
      | subtotal | points |
      | $0.99    | 0      |
      | $1.00    | 1      |
      | $19.99   | 19     |
      | $100.50  | 100    |

  @smoke @p0
  Scenario: Member below 500 points is in Basic tier with no discount
    Given I have 450 points
    When I place an order with a subtotal of $100.00
    Then my tier is Basic
    And no automatic discount is applied

  @smoke @p0
  Scenario: Silver tier member receives 5% automatic discount
    Given I have 500 points
    And my tier is Silver
    When I place an order with a subtotal of $100.00
    Then a 5% discount is automatically applied
    And my final order total is $95.00

  @smoke @p0
  Scenario: Gold tier member receives 10% automatic discount
    Given I have 2000 points
    And my tier is Gold
    When I place an order with a subtotal of $100.00
    Then a 10% discount is automatically applied
    And my final order total is $90.00

  # Added by QA, to verify tier boundary at Silver threshold
  @regression
  Scenario: Member enters Silver tier when reaching 500 points
    Given I have 499 points
    When I place an order with a subtotal of $1.00
    Then I earn 1 point
    And my points balance is now 500
    And my tier is now Silver

  # Added by QA, to verify tier boundary at Gold threshold
  @regression
  Scenario: Member enters Gold tier when reaching 2000 points
    Given I have 1999 points
    When I place an order with a subtotal of $1.00
    Then I earn 1 point
    And my points balance is now 2000
    And my tier is now Gold

  @smoke @p0
  Scenario: Redemption fails when points balance is insufficient
    Given I have 50 points
    When I attempt to redeem 100 points
    Then the error "You don't have enough points." is displayed
    And no points are deducted
    And my points balance remains 50

  # Added by QA, to verify successful redemption when balance is sufficient
  @regression
  Scenario: Member can redeem when points balance is sufficient
    Given I have 500 points
    When I redeem 100 points
    Then the redemption succeeds
    And my points balance is now 400

  # Added by QA, performance non-functional requirement; assumption: "fast" means < 2 seconds
  @regression @performance
  Scenario: Points page loads within acceptable time
    When I navigate to the points page
    Then the page loads within 2 seconds
    And my current points balance is displayed
    And my current tier is displayed
    And redemption options are available
```
