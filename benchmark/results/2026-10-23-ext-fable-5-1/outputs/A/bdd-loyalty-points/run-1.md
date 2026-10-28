# LOY-3 Loyalty points — BDD scenarios

## Assumptions

- Points are calculated on the order subtotal before any tier discount or points redemption, and fractions of a dollar are dropped (floor), per the $24.99 example.
- Tier is derived from the member's current points balance, so redeeming points can lower the tier. Tier is evaluated at checkout time.
- Tier discount applies to the subtotal; redeemed points are then deducted from the discounted total.
- Redemption rate is 100 points = $1.00 off, since the story does not specify one.
- Points are credited when the order is placed. Refunds and cancellations are out of scope for this story.
- "Fast" for AC-4 means the points page renders in under 2 seconds at the 95th percentile, for a member with up to 10,000 point transactions. This threshold should be confirmed with the product owner.
- Non-members are out of scope. Every scenario assumes a logged-in loyalty member.

```gherkin
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am logged in as a loyalty programme member

  # AC-1: Earning points

  Scenario Outline: Points are earned per whole dollar of the order subtotal
    Given my points balance is 0
    When I place an order with a subtotal of <subtotal>
    Then my points balance is <points>

    Examples:
      | subtotal | points |
      | $24.99   | 24     |
      | $25.00   | 25     |
      | $0.99    | 0      |
      | $1.00    | 1      |
      | $0.00    | 0      |
      | $1000.50 | 1000   |

  Scenario: Earned points are added to the existing balance
    Given my points balance is 100
    When I place an order with a subtotal of $24.99
    Then my points balance is 124

  Scenario: Points are earned on the subtotal before the tier discount
    Given my points balance is 500
    And my tier is Silver
    When I place an order with a subtotal of $100.00
    Then the tier discount applied is $5.00
    And I earn 100 points for the order
    And my points balance is 600

  Scenario: Points are earned on the subtotal before redeemed points are deducted
    Given my points balance is 400
    When I place an order with a subtotal of $50.00
    And I redeem 300 points on the order
    Then I earn 50 points for the order
    And my points balance is 150

  # AC-2: Tiers and tier discounts

  Scenario Outline: Tier is determined by points balance
    Given my points balance is <balance>
    When I view the points page
    Then my tier is shown as <tier>

    Examples:
      | balance | tier   |
      | 0       | Basic  |
      | 499     | Basic  |
      | 500     | Silver |
      | 1999    | Silver |
      | 2000    | Gold   |
      | 10000   | Gold   |

  Scenario Outline: Tier discount is applied to every order
    Given my points balance is <balance>
    When I place an order with a subtotal of $100.00
    Then the tier discount applied is <discount>
    And the order total is <total>

    Examples:
      | balance | discount | total   |
      | 499     | $0.00    | $100.00 |
      | 500     | $5.00    | $95.00  |
      | 1999    | $5.00    | $95.00  |
      | 2000    | $10.00   | $90.00  |

  Scenario: Member is promoted to Silver when an order takes the balance to 500
    Given my points balance is 480
    And my tier is Basic
    When I place an order with a subtotal of $20.00
    Then my points balance is 500
    And my tier is Silver

  Scenario: Member is promoted to Gold when an order takes the balance to 2000
    Given my points balance is 1950
    And my tier is Silver
    When I place an order with a subtotal of $50.00
    Then my points balance is 2000
    And my tier is Gold

  Scenario: Tier for the current order uses the balance before the order's points are credited
    Given my points balance is 480
    And my tier is Basic
    When I place an order with a subtotal of $100.00
    Then the tier discount applied is $0.00
    And my points balance is 580
    And my tier is Silver

  Scenario: Redeeming points below a tier threshold lowers the tier
    Given my points balance is 520
    And my tier is Silver
    When I place an order with a subtotal of $10.00
    And I redeem 100 points on the order
    Then my points balance is 430
    And my tier is Basic

  # AC-3: Redeeming points

  Scenario: Redeeming points within the balance reduces the order total
    Given my points balance is 1000
    When I place an order with a subtotal of $50.00
    And I redeem 500 points on the order
    Then the order total is reduced by $5.00
    And my points balance after redemption is 500

  Scenario: Redeeming the entire balance is allowed
    Given my points balance is 300
    When I place an order with a subtotal of $50.00
    And I redeem 300 points on the order
    Then the order total is reduced by $3.00
    And my points balance after redemption is 0

  Scenario: Redeeming more points than the balance is rejected
    Given my points balance is 300
    When I place an order with a subtotal of $50.00
    And I attempt to redeem 301 points on the order
    Then I see the message "You don't have enough points."
    And no points are redeemed
    And the order total is not reduced
    And my points balance is still 300

  Scenario: Redeeming points with a zero balance is rejected
    Given my points balance is 0
    When I place an order with a subtotal of $50.00
    And I attempt to redeem 1 point on the order
    Then I see the message "You don't have enough points."
    And no points are redeemed
    And my points balance is still 0

  Scenario: Tier discount is applied before redeemed points are deducted
    Given my points balance is 1000
    And my tier is Silver
    When I place an order with a subtotal of $100.00
    And I redeem 500 points on the order
    Then the tier discount applied is $5.00
    And the points redemption applied is $5.00
    And the order total is $90.00

  # AC-4: Points page performance

  Scenario: Points page loads quickly for a typical member
    Given I have 50 point transactions in my history
    When I open the points page
    Then the page is fully rendered within 2 seconds

  Scenario: Points page loads quickly for a member with a large history
    Given I have 10000 point transactions in my history
    When I open the points page
    Then the page is fully rendered within 2 seconds

  Scenario: Points page meets the load target under normal load
    Given the system is serving 200 concurrent members
    When each member opens the points page
    Then the 95th percentile page render time is under 2 seconds
```

## Open points for the product owner

- Confirm the redemption rate (assumed 100 points = $1.00).
- Confirm whether tier should follow the current balance or lifetime points earned. The scenarios assume current balance, which means redeeming can demote a member.
- Confirm the "fast" threshold and whether it is measured server-side or in the browser (assumed 2 seconds at p95, fully rendered).
- Confirm whether points should be credited at order placement or at fulfilment, and how refunds affect the balance.
