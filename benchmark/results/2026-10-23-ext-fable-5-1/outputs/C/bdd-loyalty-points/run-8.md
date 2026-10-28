# BDD scenarios: LOY-3 Loyalty points

## Assumptions

- **Points are earned on the subtotal before any tier discount and before any points redemption.** The story only says "subtotal".
- **Tier is based on lifetime points earned, not the current balance.** Redeeming points does not lower a member's tier. The story says "500 points" without saying which count.
- **Tier is evaluated at the time an order is placed.** Points earned on an order change the tier for the next order, not the one that earned them.
- **Redemption rate is 100 points = $1.00 off**, applied after the tier discount, on the same order. The story gives no rate.
- **Points are redeemed in whole numbers only.** A member chooses how many points to redeem at checkout in a field labelled **Points to redeem**.
- **"Load fast" means the points page is fully loaded within 2 seconds for 95% of requests.** The story gives no number. This is better measured by a performance test than by a Gherkin scenario, so the scenario below records the threshold and the measurement, and the product owner should confirm the figure.
- **Currency is US dollars** and discounts are rounded to the nearest cent.
- **Interface labels** assumed: **Points to redeem**, **Place order**, **My points**. An editor should check these against the product.

## Feature file

```gherkin
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am signed in as a loyalty programme member

  # AC-1: earning points

  Rule: A member earns 1 point for every whole dollar of an order's subtotal

    Scenario Outline: Points earned are the subtotal rounded down to whole dollars
      Given my points balance is 0
      When I place an order with a subtotal of $<subtotal>
      Then I earn <points> points
      And my points balance is <points>

      Examples:
        | subtotal | points |
        | 24.99    | 24     |
        | 25.00    | 25     |
        | 0.99     | 0      |
        | 1.00     | 1      |
        | 100.50   | 100    |

    Scenario: Points are calculated on the subtotal before the tier discount
      Given I am a Silver member
      When I place an order with a subtotal of $100.00
      Then the 5% tier discount reduces the total to $95.00
      And I earn 100 points

    Scenario: Points are calculated on the subtotal before points are redeemed
      Given my points balance is 1000
      When I place an order with a subtotal of $50.00
      And I redeem 500 points
      Then the total is $45.00
      And I earn 50 points
      And my points balance is 550

  # AC-2: tiers and tier discounts

  Rule: Tier is Basic below 500 lifetime points, Silver from 500 and Gold from 2,000

    Scenario Outline: Tier is set by lifetime points earned
      Given I have earned <lifetime_points> points in total
      Then my tier is <tier>

      Examples:
        | lifetime_points | tier   |
        | 0               | Basic  |
        | 499             | Basic  |
        | 500             | Silver |
        | 1999            | Silver |
        | 2000            | Gold   |
        | 5000            | Gold   |

    Scenario: Redeeming points does not lower the tier
      Given I have earned 2000 points in total
      And my points balance is 2000
      When I redeem 1500 points on an order
      Then my points balance is 500
      And my tier is still Gold

    Scenario: Crossing a tier threshold applies to the next order
      Given I have earned 480 points in total
      And my tier is Basic
      When I place an order with a subtotal of $30.00
      Then no tier discount is applied to that order
      And I earn 30 points
      And my tier is Silver

  Rule: Silver members get 5% off every order and Gold members get 10% off

    Scenario Outline: Tier discount is applied to the order subtotal
      Given I am a <tier> member
      When I place an order with a subtotal of $<subtotal>
      Then a <discount>% tier discount is applied
      And the total is $<total>

      Examples:
        | tier   | subtotal | discount | total |
        | Basic  | 80.00    | 0        | 80.00 |
        | Silver | 80.00    | 5        | 76.00 |
        | Gold   | 80.00    | 10       | 72.00 |
        | Silver | 24.99    | 5        | 23.74 |
        | Gold   | 24.99    | 10       | 22.49 |

  # AC-3: redeeming points

  Rule: A member cannot redeem more points than their balance

    Scenario: Redeeming more points than the balance shows an error and redeems nothing
      Given my points balance is 300
      And I am checking out an order with a subtotal of $50.00
      When I enter 400 in the "Points to redeem" field
      And I select "Place order"
      Then I see the message "You don't have enough points."
      And no points are redeemed
      And my points balance is still 300
      And the total is still $50.00

    Scenario: Redeeming exactly the balance succeeds
      Given my points balance is 300
      And I am checking out an order with a subtotal of $50.00
      When I enter 300 in the "Points to redeem" field
      And I select "Place order"
      Then 300 points are redeemed
      And the total is $47.00
      And my points balance is 0

    Scenario: Redeeming fewer points than the balance succeeds
      Given my points balance is 1000
      And I am checking out an order with a subtotal of $50.00
      When I enter 200 in the "Points to redeem" field
      And I select "Place order"
      Then 200 points are redeemed
      And the total is $48.00
      And my points balance is 800

    Scenario: Points are redeemed after the tier discount
      Given I am a Gold member
      And my points balance is 1000
      And I am checking out an order with a subtotal of $100.00
      When I enter 1000 in the "Points to redeem" field
      And I select "Place order"
      Then the 10% tier discount reduces the total to $90.00
      And 1000 points reduce the total to $80.00
      And my points balance is 0

  # AC-4: points page performance

  Rule: The points page loads within 2 seconds for 95% of requests

    @performance
    Scenario: The points page loads within the agreed time
      Given the loyalty service is under normal production load
      When 100 members open the "My points" page
      Then at least 95 of the pages are fully loaded within 2 seconds
```

## Open points for the product owner

- **Redemption rate.** The 100 points = $1.00 rate is a placeholder. The totals in the AC-3 scenarios change if the rate changes.
- **Tier basis.** If tier should follow the current balance rather than lifetime points, the scenario "Redeeming points does not lower the tier" must be reversed.
- **Performance threshold.** Replace 2 seconds and 95% with the agreed figures, and run the AC-4 scenario in the performance suite rather than the functional suite.
