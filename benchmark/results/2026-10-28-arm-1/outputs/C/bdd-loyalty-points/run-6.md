# Feature: Loyalty Program Points

Earning and redeeming points for member discounts.

## Assumptions

- Points are calculated automatically after order completion.
- Tier is determined by total cumulative points, assigned automatically.
- Discounts apply at checkout for all orders placed by tier members.
- "Load fast" is defined as < 2 seconds.
- Redemption is a deliberate member action, not automatic.

## Scenarios

```gherkin
Feature: Loyalty Program Points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Scenario: Earn 1 point per whole dollar of order subtotal
    Given a member has 0 points
    When they place an order with a subtotal of $24.99
    Then they earn 24 points
    And their total points balance is 24

  Scenario: Earn additional points on subsequent orders
    Given a member has 100 points
    When they place an order with a subtotal of $50.00
    Then they earn 50 points
    And their total points balance is 150

  Scenario: Assign Basic tier below 500 points
    Given a member has 499 points
    When their membership tier is recalculated
    Then their tier is Basic
    And no automatic discount applies

  Scenario: Assign Silver tier at 500 points
    Given a member has 500 points
    When their membership tier is recalculated
    Then their tier is Silver

  Scenario: Apply 5% discount for Silver tier members
    Given a member is Silver tier
    When they place an order with a subtotal of $100
    Then a 5% discount is applied
    And the final price is $95

  Scenario: Assign Gold tier at 2000 points
    Given a member has 2000 points
    When their membership tier is recalculated
    Then their tier is Gold

  Scenario: Apply 10% discount for Gold tier members
    Given a member is Gold tier
    When they place an order with a subtotal of $100
    Then a 10% discount is applied
    And the final price is $90

  Scenario: Prevent redemption exceeding available balance
    Given a member has 100 points
    When they attempt to redeem 150 points
    Then the system shows "You don't have enough points."
    And no points are redeemed
    And their points balance remains 100

  Scenario: Allow redemption within available balance
    Given a member has 200 points
    When they attempt to redeem 100 points
    Then the redemption succeeds
    And their points balance is 100

  Scenario: Points page loads within performance target
    Given a member navigates to the loyalty points page
    When the page begins loading
    Then the page fully loads within 2 seconds
```
