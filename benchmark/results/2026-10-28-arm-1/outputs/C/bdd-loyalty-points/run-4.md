```gherkin
Feature: Loyalty points earning and redemption
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am a loyalty programme member

  Scenario: Earn 1 point per whole dollar of order subtotal
    Given I have 0 points
    When I complete an order with a subtotal of $24.99
    Then I should earn 24 points

  Scenario: Fractional dollars do not earn points
    Given I have 10 points
    When I complete an order with a subtotal of $15.75
    Then I should earn 15 points
    And my total points should be 25

  Scenario: Reach Silver tier at 500 points
    Given I have 450 points
    When I complete an order with a subtotal of $50.00
    Then I should have 500 points
    And my tier should be "Silver"

  Scenario: Silver tier member receives 5% discount
    Given I have 500 points
    And my tier is "Silver"
    When I place an order with a subtotal of $100.00
    Then the discount applied should be 5%
    And the order total should be $95.00

  Scenario: Reach Gold tier at 2000 points
    Given I have 1900 points
    When I complete an order with a subtotal of $100.00
    Then I should have 2000 points
    And my tier should be "Gold"

  Scenario: Gold tier member receives 10% discount
    Given I have 2000 points
    And my tier is "Gold"
    When I place an order with a subtotal of $100.00
    Then the discount applied should be 10%
    And the order total should be $90.00

  Scenario: Basic tier below 500 points receives no discount
    Given I have 400 points
    And my tier is "Basic"
    When I place an order with a subtotal of $100.00
    Then no discount should be applied
    And the order total should be $100.00

  Scenario: Redeem points successfully
    Given I have 500 points
    When I redeem 200 points
    Then I should have 300 points remaining

  Scenario: Attempt to redeem more points than available
    Given I have 100 points
    When I attempt to redeem 150 points
    Then the message "You don't have enough points." should be displayed
    And I should still have 100 points
    And the redemption should fail

  Scenario: Redeem exact point balance
    Given I have 250 points
    When I redeem 250 points
    Then I should have 0 points remaining

  Scenario: Points page loads within acceptable time
    When I load the loyalty points page
    Then the page should display within 2 seconds
    And the points balance should be visible
    And the current tier should be visible

  Scenario: Tier updates reflect discount at next purchase
    Given I am a Basic tier member with 450 points
    When I complete an order with a subtotal of $100.00 earning 100 points
    Then I should reach 550 points in Silver tier
    When I place another order with a subtotal of $50.00
    Then the 5% Silver discount should be applied
    And the order total should be $47.50
```

**Assumptions made:**
- Points are earned immediately after order completion
- Tier changes take effect immediately upon reaching the threshold
- Discounts are applied automatically at checkout based on current tier
- "Fast" page load is defined as 2 seconds (standard performance threshold)
- Redemption is a separate action from earning, not automatic
- Tier progression is linear: Basic → Silver → Gold
