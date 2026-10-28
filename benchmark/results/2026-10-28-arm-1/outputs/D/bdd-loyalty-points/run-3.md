@loyalty
Feature: Loyalty Points Earning and Redemption
  As a loyalty programme member
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given a loyalty programme member with an active account

  @smoke @p0
  Scenario: Member earns points for order subtotal
    Given I have 0 loyalty points
    When I place an order with subtotal $24.99
    Then I earn 24 loyalty points
    And my account balance is 24 points

  @smoke @p0
  Scenario: Member earns points using whole-dollar rule
    Given I have 0 loyalty points
    When I place an order with subtotal $99.99
    Then I earn 99 loyalty points
    And my account balance is 99 points

  @p0 @tier
  Scenario: Member reaches Silver tier and receives discount
    Given I have 500 loyalty points
    When I place an order with subtotal $100.00
    Then the order is discounted 5%
    And my final price is $95.00
    And I earn 100 additional points

  @p0 @tier
  Scenario: Member reaches Gold tier and receives discount
    Given I have 2000 loyalty points
    When I place an order with subtotal $100.00
    Then the order is discounted 10%
    And my final price is $90.00
    And I earn 100 additional points

  @p1 @tier
  Scenario: Basic tier member receives no discount
    Given I have 100 loyalty points
    When I place an order with subtotal $100.00
    Then no discount is applied
    And my final price is $100.00
    And I earn 100 points

  # Added by QA, the ticket does not specify tier boundaries
  @regression @tier
  Scenario: Member at exactly 500 points qualifies for Silver tier
    Given I have 499 loyalty points
    When I place an order with subtotal $1.00
    Then I earn 1 point and reach Silver tier
    And my next order receives 5% discount

  # Added by QA, the ticket does not specify tier boundaries
  @regression @tier
  Scenario: Member at exactly 2000 points qualifies for Gold tier
    Given I have 1999 loyalty points
    When I place an order with subtotal $1.00
    Then I earn 1 point and reach Gold tier
    And my next order receives 10% discount

  @p0
  Scenario: Redemption fails when points are insufficient
    Given I have 100 loyalty points
    When I attempt to redeem 150 points
    Then the redemption is rejected
    And the error message is "You don't have enough points."
    And my points balance remains 100

  # Added by QA, the ticket does not specify what redemption means or when it succeeds
  @regression @p1
  Scenario: Successful points redemption
    Given I have 500 loyalty points
    When I redeem 100 points
    Then the redemption succeeds
    And my points balance is 400

  @p2 @performance
  Scenario: Points page loads within acceptable time
    Given I navigate to my loyalty points page
    When the page begins loading
    Then the points balance and tier information display within 2 seconds

---

**Assumptions applied:**

1. **Point earning trigger**: Points are awarded when an order is placed, not pending payment.
2. **Tier starting point**: Members begin at Basic tier with 0 points.
3. **Discount application**: Tier discounts apply automatically at checkout; earning points and receiving a discount are separate mechanics.
4. **Redemption mechanic**: Points redemption is a distinct action the member initiates; discount application is not a redemption (ticket AC-3 suggests a separate "redeem" flow).
5. **Performance baseline**: "Fast" = page loads within 2 seconds (typical web performance standard).
6. **Tier persistence**: Once a member reaches a tier, they remain in that tier for all future orders.
7. **Rounding rule**: Only whole dollars count (cents are truncated, not rounded).
