# Feature: Loyalty Points Program

**Assumptions:**
- Points are calculated from order subtotal, not including tax or shipping.
- Tier benefits (discounts) apply from the next order after reaching the threshold.
- "Fast" page load is defined as under 2 seconds.
- Members earn points on all orders regardless of amount.

---

```gherkin
Feature: Loyalty Points Program
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given a member is enrolled in the loyalty programme
    And the member has an active account

  # AC-1: Points Earning
  Scenario: Member earns 1 point per whole dollar of order subtotal
    Given a member has 0 points
    When the member places an order with subtotal $24.99
    Then the member should earn 24 points
    And the member's total points should be 24

  Scenario: Member earns points only for whole dollars
    Given a member has 0 points
    When the member places an order with subtotal $50.75
    Then the member should earn 50 points
    And the member's total points should be 50

  Scenario: Multiple orders accumulate points
    Given a member has 0 points
    When the member places an order with subtotal $100.00
    And the member places an order with subtotal $50.00
    Then the member's total points should be 150

  # AC-2: Tier System and Discounts
  Scenario: Member is Basic tier below 500 points
    Given a member has 499 points
    Then the member's tier should be "Basic"
    And the member should receive 0% discount

  Scenario: Member becomes Silver at 500 points
    Given a member has 500 points
    Then the member's tier should be "Silver"

  Scenario: Silver members receive 5% discount on orders
    Given a member's tier is "Silver"
    And a member places an order with subtotal $100.00
    Then the member should receive a 5% discount
    And the order total should be $95.00

  Scenario: Member becomes Gold at 2000 points
    Given a member has 2000 points
    Then the member's tier should be "Gold"

  Scenario: Gold members receive 10% discount on orders
    Given a member's tier is "Gold"
    And a member places an order with subtotal $100.00
    Then the member should receive a 10% discount
    And the order total should be $90.00

  Scenario: Discount applies on next order after tier upgrade
    Given a member has 490 points and is Basic tier
    When the member places an order with subtotal $20.00 (earning 20 points to reach 510)
    Then the member should not receive a discount on this order
    And the member should be Silver tier for the next order

  # AC-3: Redeem Points Validation
  Scenario: Member redeems fewer points than balance
    Given a member has 200 points
    When the member redeems 100 points
    Then the member should have 100 points remaining
    And the redemption should succeed

  Scenario: Member redeems exact points balance
    Given a member has 100 points
    When the member redeems 100 points
    Then the member should have 0 points remaining
    And the redemption should succeed

  Scenario: Member cannot redeem more points than balance
    Given a member has 50 points
    When the member attempts to redeem 100 points
    Then the error message "You don't have enough points." should be displayed
    And the member should still have 50 points
    And no points should be redeemed

  # AC-4: Performance
  Scenario: Points page loads quickly
    Given a member is on the loyalty points page
    When the page loads
    Then the page should load in less than 2 seconds
    And the member's point balance should be displayed
    And the member's tier should be displayed
```
