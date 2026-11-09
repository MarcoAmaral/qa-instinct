# Loyalty Points Program

**Assumptions:**
- Members start with 0 points balance
- Tier status changes take effect immediately upon reaching threshold
- Discounts apply to the order subtotal
- "Fast loading" for the points page is defined as < 2 seconds
- Points can only be redeemed in whole-point amounts
- Discounts apply to all future orders once tier is achieved

---

Feature: Loyalty Points Earning and Redemption
  
  Background:
    Given I am a registered loyalty program member
    And I am logged into my account

  Scenario: Earn points based on whole dollars of order subtotal
    Given my current points balance is 0
    When I place an order with subtotal $24.99
    Then I should earn 24 loyalty points
    And my points balance should be 24

  Scenario: Earn maximum points from order subtotal
    Given my current points balance is 100
    When I place an order with subtotal $75.50
    Then I should earn 75 loyalty points
    And my points balance should be 175

  Scenario: No points earned when subtotal is less than $1
    Given my current points balance is 50
    When I place an order with subtotal $0.99
    Then I should earn 0 loyalty points
    And my points balance should be 50

  Scenario: Member with Basic tier classification
    Given my current points balance is 250
    When I view my loyalty account
    Then my membership tier should be Basic
    And I should not receive an order discount

  Scenario: Member transitions to Silver tier at 500 points
    Given my current points balance is 499
    When I earn 1 point from an order
    Then my points balance should be 500
    And my membership tier should change to Silver
    And I should receive a 5% discount on future orders

  Scenario: Silver member receives 5% discount on orders
    Given my current points balance is 500
    And my membership tier is Silver
    When I place an order with subtotal $100.00
    Then a 5% discount should be applied
    And my order total should be $95.00

  Scenario: Member transitions to Gold tier at 2000 points
    Given my current points balance is 1999
    When I earn 1 point from an order
    Then my points balance should be 2000
    And my membership tier should change to Gold
    And I should receive a 10% discount on future orders

  Scenario: Gold member receives 10% discount on orders
    Given my current points balance is 2000
    And my membership tier is Gold
    When I place an order with subtotal $100.00
    Then a 10% discount should be applied
    And my order total should be $90.00

  Scenario: Cannot redeem points exceeding available balance
    Given my current points balance is 100
    When I attempt to redeem 150 points
    Then the redemption should fail
    And an error message should display "You don't have enough points."
    And my points balance should remain 100

  Scenario: Successfully redeem points within available balance
    Given my current points balance is 500
    When I redeem 200 points
    Then the redemption should succeed
    And my points balance should be 300

  Scenario: Points page loads within acceptable time
    Given I navigate to my loyalty points page
    When the page begins loading
    Then the page should fully load within 2 seconds
    And all account information should be displayed
    And no loading errors should occur

  Scenario: Redemption attempt with exact balance
    Given my current points balance is 100
    When I attempt to redeem exactly 100 points
    Then the redemption should succeed
    And my points balance should be 0
