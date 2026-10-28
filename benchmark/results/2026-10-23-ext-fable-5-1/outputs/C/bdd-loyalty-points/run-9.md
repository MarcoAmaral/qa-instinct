# LOY-3 Loyalty points: BDD scenarios

## Assumptions

The story leaves these points open. Each scenario below follows the assumption stated here. Correct the assumption and the scenario together.

1. **Points round down.** "Every whole dollar" means the cents are dropped, never rounded up, so $24.99 earns 24 points and $0.99 earns 0.
2. **Subtotal excludes tax, shipping and discounts.** Points are earned on the merchandise subtotal before any tier discount or redemption is applied.
3. **Tier is based on lifetime points earned**, not the current balance, so redeeming points never lowers a tier. The story says "below 500 points" without saying which count. If tier follows the current balance instead, scenarios tagged `@tier-basis` change.
4. **Tier discount applies to the subtotal**, and Basic members get 0%.
5. **Redemption rate is 100 points = $1.00 off**, applied after the tier discount. The story gives no rate.
6. **Points are credited when an order is placed**, not when it ships or is delivered.
7. **"Load fast" means the points page shows the balance and tier within 2 seconds** on a standard connection. AC-4 has no number, so it cannot be tested as written. This threshold is a placeholder for the product owner to confirm.
8. **The error message is shown on the checkout page** where points are redeemed, and the order can still be placed without points.

## Feature file

```gherkin
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am signed in as a loyalty programme member

  # AC-1: Earning points

  Scenario Outline: Points are earned on each whole dollar of the subtotal
    Given my points balance is 0
    When I place an order with a subtotal of <subtotal>
    Then my points balance is <points>

    Examples:
      | subtotal | points |
      | $24.99   | 24     |
      | $25.00   | 25     |
      | $0.99    | 0      |
      | $0.00    | 0      |
      | $100.50  | 100    |

  Scenario: Points are earned on the subtotal, not the order total
    Given my points balance is 0
    When I place an order with a subtotal of $40.00, tax of $3.20 and shipping of $5.99
    Then my points balance is 40

  Scenario: Points are earned on the subtotal before a tier discount
    Given I am a Silver member with a points balance of 500
    When I place an order with a subtotal of $100.00
    Then the order total is $95.00
    And my points balance is 600

  Scenario: Earned points are added to an existing balance
    Given my points balance is 130
    When I place an order with a subtotal of $19.99
    Then my points balance is 149

  # AC-2: Tiers and discounts

  @tier-basis
  Scenario Outline: Tier is set by lifetime points earned
    Given I have earned <lifetime points> points in total
    When I open the points page
    Then my tier is shown as <tier>

    Examples:
      | lifetime points | tier   |
      | 0               | Basic  |
      | 499             | Basic  |
      | 500             | Silver |
      | 1999            | Silver |
      | 2000            | Gold   |
      | 5000            | Gold   |

  Scenario Outline: Tier discount is applied to every order
    Given I am a <tier> member
    When I place an order with a subtotal of $200.00
    Then a <discount> discount is applied
    And the order total is <total>

    Examples:
      | tier   | discount | total   |
      | Basic  | 0%       | $200.00 |
      | Silver | 5%       | $190.00 |
      | Gold   | 10%      | $180.00 |

  Scenario: An order that crosses a tier threshold upgrades the tier for the next order
    Given I have earned 480 points in total
    When I place an order with a subtotal of $30.00
    Then no discount is applied to that order
    And my tier is Silver
    When I place another order with a subtotal of $100.00
    Then a 5% discount is applied
    And the order total is $95.00

  @tier-basis
  Scenario: Redeeming points does not lower the tier
    Given I have earned 2100 points in total
    And my points balance is 2100
    When I redeem 2000 points on an order
    Then my points balance is 100
    And my tier is Gold

  # AC-3: Redeeming points

  Scenario: Redeeming more points than the balance redeems nothing
    Given my points balance is 300
    When I try to redeem 500 points on an order with a subtotal of $50.00
    Then I see the message "You don't have enough points."
    And no points are deducted from my balance
    And my points balance is 300
    And no points discount is applied to the order

  Scenario: Redeeming the whole balance succeeds
    Given my points balance is 300
    When I redeem 300 points on an order with a subtotal of $50.00
    Then a $3.00 points discount is applied to the order
    And my points balance is 0

  Scenario: Redeeming part of the balance succeeds
    Given my points balance is 1000
    When I redeem 400 points on an order with a subtotal of $50.00
    Then a $4.00 points discount is applied to the order
    And my points balance is 600

  Scenario: Redeeming points with a zero balance redeems nothing
    Given my points balance is 0
    When I try to redeem 100 points on an order
    Then I see the message "You don't have enough points."
    And my points balance is 0

  Scenario: The order can still be placed after a failed redemption
    Given my points balance is 100
    And I tried to redeem 200 points and saw "You don't have enough points."
    When I place the order without redeeming points
    Then the order is placed at full price
    And I earn points on the order subtotal

  Scenario: Tier discount and points redemption apply together
    Given I am a Gold member with a points balance of 1000
    When I place an order with a subtotal of $100.00 and redeem 500 points
    Then a 10% tier discount is applied
    And a $5.00 points discount is applied
    And the order total is $85.00
    And my points balance is 600

  # AC-4: Points page performance (threshold assumed, see assumption 7)

  Scenario: The points page shows the balance and tier within 2 seconds
    Given my points balance is 1250
    When I open the points page
    Then my points balance and tier are displayed within 2 seconds

  Scenario: The points page shows the balance and tier within 2 seconds for a long history
    Given I have 1000 orders in my points history
    When I open the points page
    Then my points balance and tier are displayed within 2 seconds
```

## Open questions for the product owner

- **AC-4 needs a number.** "Fast" cannot pass or fail. Confirm or replace the 2-second placeholder, and say whether it is measured on the server, in the browser, or both.
- **Tier basis.** Confirm whether tier follows lifetime points earned or the current balance. The two `@tier-basis` scenarios change if it is the balance.
- **Redemption rate.** Confirm the value of a point. The scenarios use 100 points = $1.00.
- **Order of discounts.** Confirm the tier discount is applied before the points discount, as in the combined scenario.
- **Refunds and cancellations.** The story does not say whether points are removed when an order is refunded. No scenario covers this yet.
