# Feature: Loyalty Points

**Assumptions made:**
- Members are authenticated users who have logged into the system
- Order subtotal is the pre-tax, pre-shipping amount
- Tier assignment is automatic when a member's points cross a threshold
- Redemption requires the member to specify an amount
- "Fast load" assumes under 2 seconds

---

```gherkin
Feature: Loyalty Points Earning and Redemption
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Scenario: Member earns 1 point per whole dollar
    Given I am a loyalty programme member with 0 points
    When I place an order with a subtotal of $24.99
    Then I should have 24 loyalty points

  Scenario: Larger order yields proportional points
    Given I am a loyalty programme member with 0 points
    When I place an order with a subtotal of $150.75
    Then I should have 150 loyalty points

  Scenario: Member tier is Basic below 500 points
    Given I am a loyalty programme member with 499 points
    Then my membership tier should be Basic
    And my order discount should be 0%

  Scenario: Member tier becomes Silver at 500 points
    Given I am a loyalty programme member with 500 points
    Then my membership tier should be Silver
    And my order discount should be 5%

  Scenario: Member tier becomes Gold at 2000 points
    Given I am a loyalty programme member with 2000 points
    Then my membership tier should be Gold
    And my order discount should be 10%

  Scenario: Silver discount applies to subsequent orders
    Given I am a Silver member
    When I place an order with a subtotal of $100.00
    Then the discounted price should be $95.00
    And I should earn 100 additional points

  Scenario: Gold discount applies to subsequent orders
    Given I am a Gold member
    When I place an order with a subtotal of $100.00
    Then the discounted price should be $90.00
    And I should earn 100 additional points

  Scenario: Cannot redeem more points than available balance
    Given I am a loyalty programme member with 100 points
    When I attempt to redeem 150 points
    Then the message "You don't have enough points." should appear
    And my points balance should remain 100

  Scenario: Successful redemption within balance
    Given I am a loyalty programme member with 500 points
    When I redeem 100 points
    Then my points balance should be 400
    And the redemption should be processed

  Scenario: Points page loads within acceptable time
    Given I am a loyalty programme member
    When I navigate to my points page
    Then the page should fully load within 2 seconds
```
