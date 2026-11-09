**Assumptions:**
- Points are earned immediately upon order completion
- Tier discount is applied at checkout based on current points balance
- "Redeeming points" refers to using points for rewards/discounts
- "Fast load" is defined as completing within 2 seconds
- Basic tier provides no discount (0%)

---

Feature: Loyalty Points Programme
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Scenario: Member earns points based on whole dollars of order subtotal
    Given I am a loyalty member with 0 points
    When I complete an order with a subtotal of $100.00
    Then I should earn 100 points
    And my points balance should be 100

  Scenario: Fractional dollars do not earn points
    Given I am a loyalty member with 0 points
    When I complete an order with a subtotal of $24.99
    Then I should earn 24 points
    And my points balance should be 24

  Scenario: Member with no points is in Basic tier
    Given I am a loyalty member with 0 points
    When I view my tier status
    Then my tier should be Basic
    And I should receive 0% discount on orders

  Scenario: Member with 499 points is in Basic tier
    Given I am a loyalty member with 499 points
    When I view my tier status
    Then my tier should be Basic
    And I should receive 0% discount on orders

  Scenario: Member with 500 points reaches Silver tier
    Given I am a loyalty member with 500 points
    When I place an order with a subtotal of $100.00
    Then my tier should be Silver
    And I should receive a 5% discount
    And my order total should be $95.00

  Scenario: Member with 1999 points remains in Silver tier
    Given I am a loyalty member with 1999 points
    When I view my tier status
    Then my tier should be Silver
    And I should receive a 5% discount on orders

  Scenario: Member with 2000 points reaches Gold tier
    Given I am a loyalty member with 2000 points
    When I place an order with a subtotal of $100.00
    Then my tier should be Gold
    And I should receive a 10% discount
    And my order total should be $90.00

  Scenario: Redeeming insufficient points shows error message
    Given I am a loyalty member with 100 points
    When I attempt to redeem 150 points
    Then I should see the error message "You don't have enough points."
    And my points balance should remain 100

  Scenario: Points page loads within acceptable time
    Given I am a loyalty member
    When I navigate to my loyalty points page
    Then the page should fully load within 2 seconds
