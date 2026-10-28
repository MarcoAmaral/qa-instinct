## Assumptions

- Loyalty programme members are authenticated
- Points are earned immediately upon order placement
- Discounts apply to subtotal before tax
- "Fast page load" = under 2 seconds
- Tier changes apply to subsequent orders
- Redeeming points is a separate action after earning (not automatic)

---

## Feature: Loyalty Points

```gherkin
Feature: Loyalty Points Programme
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  # AC-1: Points Earning
  Scenario: Member earns 1 point per whole dollar spent
    Given I am a loyalty programme member
    When I place an order with subtotal $24.99
    Then I should earn 24 loyalty points

  Scenario: Fractional dollars do not generate points
    Given I am a loyalty programme member
    When I place an order with subtotal $50.49
    Then I should earn 50 loyalty points
    And no points are awarded for the $0.49

  Scenario: Zero points earned for subtotal under $1
    Given I am a loyalty programme member
    When I place an order with subtotal $0.99
    Then I should earn 0 loyalty points

  # AC-2: Tier Classification and Discounts
  Scenario: New member has Basic tier below 500 points
    Given I am a loyalty programme member with 100 loyalty points
    When I view my account
    Then my tier should be "Basic"
    And I receive 0% discount on orders

  Scenario: Member reaches Silver tier at 500 points
    Given I am a loyalty programme member with 499 loyalty points
    When I earn 1 loyalty point from a purchase
    Then my tier should be "Silver"
    And I should receive 5% discount on all future orders

  Scenario: Member maintains Silver tier below 2000 points
    Given I am a loyalty programme member with 1500 loyalty points
    When I view my account
    Then my tier should be "Silver"
    And I receive 5% discount on orders

  Scenario: Member reaches Gold tier at 2000 points
    Given I am a loyalty programme member with 1999 loyalty points
    When I earn 1 loyalty point from a purchase
    Then my tier should be "Gold"
    And I should receive 10% discount on all future orders

  Scenario: Gold member discount applies correctly
    Given I am a Gold tier member with 2000 loyalty points
    When I place an order with subtotal $100.00
    Then a 10% discount ($10.00) should be applied
    And the adjusted order total should be $90.00

  Scenario: Silver member discount applies correctly
    Given I am a Silver tier member with 500 loyalty points
    When I place an order with subtotal $100.00
    Then a 5% discount ($5.00) should be applied
    And the adjusted order total should be $95.00

  # AC-3: Insufficient Points Error Handling
  Scenario: Redeeming more points than available shows error
    Given I am a loyalty programme member with 100 loyalty points
    When I attempt to redeem 150 loyalty points
    Then I should see the message "You don't have enough points."
    And my loyalty point balance should remain 100
    And no points should be deducted

  Scenario: Redeeming exact balance succeeds
    Given I am a loyalty programme member with 50 loyalty points
    When I redeem 50 loyalty points
    Then my loyalty point balance should become 0
    And the redemption should complete successfully

  Scenario: Redeeming partial balance succeeds
    Given I am a loyalty programme member with 500 loyalty points
    When I redeem 200 loyalty points
    Then my loyalty point balance should become 300
    And the redemption should complete successfully

  # AC-4: Performance
  Scenario: Loyalty points page loads quickly
    Given I am a loyalty programme member
    When I navigate to the loyalty points page
    Then the page should fully load within 2 seconds
    And all account information should be visible
```
