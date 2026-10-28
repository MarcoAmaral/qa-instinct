# LOY-3 Loyalty points: BDD scenarios

## Assumptions

The story leaves these points open. Each scenario below follows these assumptions; change the scenario if the assumption is wrong.

- **Subtotal** means the merchandise total before tier discount, points redemption, tax and shipping.
- **Points are earned** when the order is placed and paid. Refunds and cancellations are out of scope for this story.
- **Tier is based on lifetime points earned**, not the current balance, so redeeming points does not lower a tier. Tier changes take effect on the next order.
- **Tier discount** applies to the subtotal automatically on every order. Any redeemed points are deducted after the tier discount.
- **Redemption rate** is 100 points = $1.00, redeemed at checkout in whole points, with no minimum.
- **Redemption cannot exceed the order total** after the tier discount. This is not in the story and needs product owner confirmation.
- **"Fast" in AC-4** is not testable as written. The scenario assumes the points page is usable within 2 seconds at the 95th percentile for a member with up to 1,000 history entries. The product owner should confirm the threshold.
- **Interface labels** such as **Points**, **Redeem points** and **Apply** are assumed. An editor should replace them with the product's real labels.

## Feature: Earn points on orders

```gherkin
@LOY-3 @AC-1
Feature: Earn loyalty points on orders
  As a member of the loyalty programme
  I want to earn points on each order
  So that I can get discounts on later orders

  Background:
    Given I am signed in as a loyalty programme member
    And my points balance is 0

  Scenario Outline: Points are earned per whole dollar of the subtotal
    When I place and pay for an order with a subtotal of <subtotal>
    Then my points balance is <points>

    Examples:
      | subtotal | points |
      | $24.99   | 24     |
      | $25.00   | 25     |
      | $0.99    | 0      |
      | $100.50  | 100    |
      | $1.00    | 1      |

  Scenario: Points are based on the subtotal, not the total paid
    Given I have an order with a subtotal of $40.00
    And tax on the order is $3.20
    And shipping on the order is $5.00
    When I pay for the order
    Then my points balance is 40

  Scenario: Points are based on the subtotal before the tier discount
    Given I am a Silver member
    And I have an order with a subtotal of $100.00
    When I pay for the order with the 5% tier discount applied
    Then my points balance increases by 100

  Scenario: Points from several orders add up
    Given I have placed and paid for an order with a subtotal of $30.00
    When I place and pay for another order with a subtotal of $12.49
    Then my points balance is 42

  Scenario: A guest does not earn points
    Given I am checking out as a guest, not as a member
    When I place and pay for an order with a subtotal of $50.00
    Then no points are awarded for the order
```

## Feature: Tiers and tier discounts

```gherkin
@LOY-3 @AC-2
Feature: Membership tiers and tier discounts
  As a member of the loyalty programme
  I want my tier to rise as I earn points
  So that I get a discount on every order

  Background:
    Given I am signed in as a loyalty programme member

  Scenario Outline: Tier is set by lifetime points earned
    Given I have earned <lifetime_points> points in total
    When I open the Points page
    Then my tier is shown as "<tier>"

    Examples:
      | lifetime_points | tier   |
      | 0               | Basic  |
      | 499             | Basic  |
      | 500             | Silver |
      | 1999            | Silver |
      | 2000            | Gold   |
      | 5000            | Gold   |

  Scenario Outline: Tier discount is applied to the subtotal of every order
    Given my tier is <tier>
    And I have an order with a subtotal of $100.00
    When I reach the checkout
    Then a tier discount of <discount> is shown
    And the subtotal after the tier discount is <subtotal_after>

    Examples:
      | tier   | discount | subtotal_after |
      | Basic  | $0.00    | $100.00        |
      | Silver | $5.00    | $95.00         |
      | Gold   | $10.00   | $90.00         |

  Scenario: Crossing a tier boundary applies on the next order
    Given I have earned 480 points in total
    And my tier is Basic
    When I place and pay for an order with a subtotal of $20.00
    Then my tier becomes Silver
    And no discount is applied to the order that was just paid
    And my next order gets a 5% tier discount

  Scenario: Redeeming points does not lower the tier
    Given I have earned 600 points in total
    And my tier is Silver
    When I redeem 300 points
    Then my points balance is 300
    And my tier is still Silver
```

## Feature: Redeem points

```gherkin
@LOY-3 @AC-3
Feature: Redeem loyalty points at checkout
  As a member of the loyalty programme
  I want to redeem points on an order
  So that I pay less

  Background:
    Given I am signed in as a loyalty programme member
    And I have an order with a subtotal of $50.00 at the checkout

  Scenario: Redeem fewer points than the balance
    Given my points balance is 1000
    When I enter 500 in "Redeem points" and select "Apply"
    Then $5.00 is deducted from the order total
    And my points balance is 500

  Scenario: Redeem the whole balance
    Given my points balance is 1000
    When I enter 1000 in "Redeem points" and select "Apply"
    Then $10.00 is deducted from the order total
    And my points balance is 0

  Scenario: Redeem more points than the balance
    Given my points balance is 300
    When I enter 301 in "Redeem points" and select "Apply"
    Then I see the message "You don't have enough points."
    And no points are deducted from the order total
    And my points balance is still 300

  Scenario: Redeem with a balance of zero
    Given my points balance is 0
    When I enter 1 in "Redeem points" and select "Apply"
    Then I see the message "You don't have enough points."
    And my points balance is still 0

  Scenario: Tier discount and redeemed points apply together
    Given my tier is Gold
    And my points balance is 1000
    When I enter 1000 in "Redeem points" and select "Apply"
    Then the tier discount of $5.00 is applied first
    And $10.00 of redeemed points is deducted after the tier discount
    And the order total before tax and shipping is $35.00

  Scenario: Points are only deducted when the order is paid
    Given my points balance is 1000
    And I have applied 500 points to the order
    When I leave the checkout without paying
    Then my points balance is still 1000
```

## Feature: Points page performance

```gherkin
@LOY-3 @AC-4
Feature: Points page loads quickly
  As a member of the loyalty programme
  I want the Points page to load quickly
  So that I can check my balance without waiting

  # AC-4 says "should load fast" with no number. The threshold below is an
  # assumption and must be confirmed by the product owner before this
  # scenario is used for sign-off.

  Scenario: Points page is usable within the agreed time
    Given I am signed in as a loyalty programme member
    And I have up to 1,000 entries in my points history
    When I open the Points page
    Then my balance, tier and history are shown within 2 seconds
    And this holds for at least 95% of page loads under normal load
```

## Open questions for the product owner

- Is tier based on lifetime points or current balance? The scenarios assume lifetime points.
- What is the redemption rate? The scenarios assume 100 points = $1.00.
- Can redeemed points exceed the order total, and if so, what happens to the remainder?
- What does "fast" mean in AC-4? The scenarios assume 2 seconds at the 95th percentile.
- Should points be revoked when an order is refunded or cancelled?
