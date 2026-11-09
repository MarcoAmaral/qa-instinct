Feature: Loyalty Points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Scenario: Earn 1 point per whole dollar of order subtotal
    Given I am a loyalty programme member with 0 points
    When I place an order with a subtotal of $24.99
    Then I should earn 24 loyalty points
    And my loyalty point balance should be 24

  Scenario: Fractional dollars do not generate points
    Given I am a loyalty programme member with 0 points
    When I place an order with a subtotal of $10.50
    Then I should earn 10 loyalty points

  Scenario: Basic tier for members below 500 points
    Given I am a loyalty programme member
    And my loyalty point balance is 499
    When I check my membership tier
    Then my tier should be "Basic"
    And no automatic discount applies to my orders

  Scenario: Silver tier for members at 500 or more points
    Given I am a loyalty programme member
    And my loyalty point balance is 500
    When I place an order with a subtotal of $100.00
    Then my tier should be "Silver"
    And I should receive a 5% discount
    And the discount amount should be $5.00

  Scenario: Gold tier for members at 2000 or more points
    Given I am a loyalty programme member
    And my loyalty point balance is 2000
    When I place an order with a subtotal of $100.00
    Then my tier should be "Gold"
    And I should receive a 10% discount
    And the discount amount should be $10.00

  Scenario: Cannot redeem more points than balance
    Given I am a loyalty programme member
    And my loyalty point balance is 100
    When I attempt to redeem 150 loyalty points
    Then the redemption should fail
    And I should see the message "You don't have enough points."
    And my loyalty point balance should remain 100

  Scenario: Loyalty points page loads quickly
    When I navigate to my loyalty points page
    Then the page should load within 2 seconds
