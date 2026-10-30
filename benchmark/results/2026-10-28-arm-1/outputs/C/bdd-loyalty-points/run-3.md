```gherkin
Feature: Loyalty Points Program

  Background:
    Given I am a member of the loyalty programme
    And I am logged into my account

  Scenario: Earn 1 point for every whole dollar spent
    Given I have 0 loyalty points
    When I place an order with a subtotal of $24.99
    Then I should earn 24 loyalty points
    And my loyalty points balance should be 24

  Scenario: Fractional dollars do not earn points
    Given I have 0 loyalty points
    When I place an order with a subtotal of $50.75
    Then I should earn 50 loyalty points
    And the $0.75 cents should not earn points

  Scenario: Member with less than 500 points has Basic tier
    Given I have 499 loyalty points
    Then my loyalty tier should be Basic
    And I should receive no discount on orders

  Scenario: Member with 500 points qualifies for Silver tier
    Given I have 500 loyalty points
    Then my loyalty tier should be Silver
    And I should receive 5% off on orders

  Scenario: Member with 1999 points remains in Silver tier
    Given I have 1999 loyalty points
    Then my loyalty tier should be Silver
    And I should receive 5% off on orders

  Scenario: Member with 2000 points qualifies for Gold tier
    Given I have 2000 loyalty points
    Then my loyalty tier should be Gold
    And I should receive 10% off on orders

  Scenario: Silver member discount is applied at checkout
    Given I have 500 loyalty points and Silver tier status
    When I place an order with a subtotal of $100
    Then a 5% discount should be applied
    And my order total should be $95

  Scenario: Gold member discount is applied at checkout
    Given I have 2000 loyalty points and Gold tier status
    When I place an order with a subtotal of $100
    Then a 10% discount should be applied
    And my order total should be $90

  Scenario: Redeem points with sufficient balance
    Given I have 200 loyalty points
    When I redeem 75 loyalty points
    Then the redemption should succeed
    And my loyalty points balance should be 125

  Scenario: Redeem more points than available balance
    Given I have 50 loyalty points
    When I attempt to redeem 100 loyalty points
    Then the redemption should fail
    And I should see the message "You don't have enough points."
    And my loyalty points balance should remain 50

  Scenario: Points page loads within acceptable time
    Given I navigate to the loyalty points page
    When the page begins loading
    Then the page should fully load within 2 seconds
    And all account information should be displayed

  Assumptions:
  - "1 whole dollar" means rounding down (floor function)
  - Basic tier is the default tier for all new members
  - Tier status updates immediately upon reaching point thresholds
  - Discounts apply to order subtotal only
  - Successful order placement triggers point earning
  - Redemptions deduct points before merchant fulfillment
  - "Fast load" is defined as 2 seconds for page load completion
  - All scenarios assume standard network conditions
```
