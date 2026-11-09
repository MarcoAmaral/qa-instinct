## Assumptions

- "Load fast" for AC-4 is interpreted as loading within 2 seconds
- Point redemption results in automatic discount application on the next order
- Discounts apply to order subtotal before tax and shipping
- Tier classification is determined by cumulative points balance
- Members remain in their current tier until points change

---

Feature: Loyalty Points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Scenario: Member earns 1 point per whole dollar of order subtotal
    Given I am a loyalty programme member with 0 points
    When I place an order with a subtotal of $24.99
    Then my points balance increases to 24

  Scenario: Member earns points rounded down to whole dollars
    Given I am a loyalty programme member with 0 points
    When I place an order with a subtotal of $99.99
    Then my points balance increases to 99 (not 100)

  Scenario: Member classified as Basic tier below 500 points
    Given I am a loyalty programme member with 499 points
    When I view my account
    Then my tier is Basic

  Scenario: Member classified as Silver tier from 500 points
    Given I am a loyalty programme member with 500 points
    When I view my account
    Then my tier is Silver

  Scenario: Member classified as Gold tier from 2000 points
    Given I am a loyalty programme member with 2000 points
    When I view my account
    Then my tier is Gold

  Scenario: Basic tier member receives no discount
    Given my tier is Basic
    When I place an order with a $100 subtotal
    Then the discount is $0
    And the subtotal charged is $100

  Scenario: Silver tier member receives 5% discount on orders
    Given my tier is Silver
    When I place an order with a $100 subtotal
    Then the discount is $5
    And the subtotal charged is $95

  Scenario: Gold tier member receives 10% discount on orders
    Given my tier is Gold
    When I place an order with a $100 subtotal
    Then the discount is $10
    And the subtotal charged is $90

  Scenario: Member cannot redeem insufficient points
    Given my points balance is 100
    When I attempt to redeem 150 points
    Then I see the message "You don't have enough points."
    And no points are deducted

  Scenario: Member can redeem exactly their points balance
    Given my points balance is 100
    When I attempt to redeem 100 points
    Then the redemption succeeds
    And my points balance becomes 0

  Scenario: Points page loads within performance threshold
    Given I am a loyalty programme member with 5000 points
    When I navigate to the points page
    Then the page loads in less than 2 seconds
