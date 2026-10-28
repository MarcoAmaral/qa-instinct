# LOY-3 Loyalty points: BDD scenarios

## Assumptions

- **Points balance, not lifetime total, decides the tier.** AC-2 says "below 500 points", which reads as the current balance. This means redeeming points can lower a member's tier. If product intends lifetime earned points instead, change the Background and the tier scenarios.
- **Points round down** to the nearest whole dollar of the subtotal, per the $24.99 example.
- **Subtotal excludes shipping, tax and discounts.** Points are earned on the subtotal before the tier discount and before any points are redeemed.
- **Points are credited when the order is placed.** Returns and cancellations are out of scope for this story.
- **The tier discount uses the tier at the moment the order is placed.** Points earned by that order change the tier for the next order, not the current one.
- **Redemption rate is 100 points = $1 off**, applied to the order total after the tier discount. Redemption happens on the checkout page in a field labelled **Points to redeem**.
- **AC-4 is not testable as written.** The scenario below uses 2 seconds at the 95th percentile on a balance of 10,000 point transactions. Replace these numbers with the agreed target before automating.

## Feature file

```gherkin
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am signed in as a loyalty programme member
    And my tier is calculated from my current points balance

  # AC-1: Earning points

  Scenario Outline: Earn 1 point for every whole dollar of the subtotal
    Given my points balance is 0
    When I place an order with a subtotal of $<subtotal>
    Then I earn <points> points
    And my points balance is <points>

    Examples:
      | subtotal | points |
      | 24.99    | 24     |
      | 24.00    | 24     |
      | 0.99     | 0      |
      | 1.00     | 1      |
      | 100.50   | 100    |

  Scenario: Shipping and tax do not earn points
    Given my points balance is 0
    When I place an order with a subtotal of $40.00, shipping of $5.99 and tax of $3.20
    Then I earn 40 points

  Scenario: Points are earned on the subtotal before the tier discount
    Given my points balance is 500
    And my tier is Silver
    When I place an order with a subtotal of $100.00
    Then the order total is $95.00
    And I earn 100 points
    And my points balance is 600

  # AC-2: Tiers and tier discounts

  Scenario Outline: Tier is set by the points balance
    Given my points balance is <balance>
    Then my tier is <tier>

    Examples:
      | balance | tier   |
      | 0       | Basic  |
      | 499     | Basic  |
      | 500     | Silver |
      | 1999    | Silver |
      | 2000    | Gold   |
      | 5000    | Gold   |

  Scenario Outline: Tier discount is applied to every order
    Given my points balance is <balance>
    When I place an order with a subtotal of $100.00
    Then a tier discount of <discount> is applied
    And the order total is $<total>

    Examples:
      | balance | discount | total  |
      | 0       | 0%       | 100.00 |
      | 500     | 5%       | 95.00  |
      | 2000    | 10%      | 90.00  |

  Scenario: Reaching a tier applies to the next order, not the current one
    Given my points balance is 480
    And my tier is Basic
    When I place an order with a subtotal of $20.00
    Then the order total is $20.00
    And my points balance is 500
    And my tier is Silver
    When I place an order with a subtotal of $100.00
    Then the order total is $95.00

  Scenario: Redeeming points can lower the tier
    Given my points balance is 520
    And my tier is Silver
    When I redeem 100 points on an order
    Then my points balance is 420
    And my tier is Basic

  # AC-3: Redeeming points

  Scenario: Redeem fewer points than the balance
    Given my points balance is 500
    And I have an order with a total of $50.00
    When I enter 200 in "Points to redeem" and apply it
    Then the order total is $48.00
    And my points balance is 300

  Scenario: Redeem exactly the full balance
    Given my points balance is 100
    And I have an order with a total of $50.00
    When I enter 100 in "Points to redeem" and apply it
    Then the order total is $49.00
    And my points balance is 0

  Scenario: Redeem more points than the balance
    Given my points balance is 100
    And I have an order with a total of $50.00
    When I enter 150 in "Points to redeem" and apply it
    Then I see the message "You don't have enough points."
    And the order total is still $50.00
    And my points balance is still 100

  Scenario: Redeem with a zero balance
    Given my points balance is 0
    And I have an order with a total of $50.00
    When I enter 1 in "Points to redeem" and apply it
    Then I see the message "You don't have enough points."
    And the order total is still $50.00

  # AC-4: Points page performance

  @non-functional
  Scenario: Points page loads within the agreed time
    Given my points history has 10000 point transactions
    When I open the points page 100 times under normal load
    Then 95 or more of the page loads finish within 2 seconds
```

## Open points for the product owner

- Confirm whether tier is based on current balance or lifetime earned points. The "Redeeming points can lower the tier" scenario exists only to make this choice visible.
- Confirm the redemption rate and whether points can be redeemed against shipping and tax.
- Replace the AC-4 numbers with a measurable target, or move AC-4 out of this story into a performance requirement.
