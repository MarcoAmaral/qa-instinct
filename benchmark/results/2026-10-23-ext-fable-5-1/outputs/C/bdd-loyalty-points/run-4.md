# LOY-3: Loyalty points — BDD scenarios

## Assumptions

The story leaves these points open. Each scenario below follows the assumption stated here. Change the scenario if the assumption is wrong.

- **A1 (AC-1):** "Subtotal" means the item total before tier discount, redeemed points, tax and shipping. Points are rounded down to the whole dollar, so $0.99 earns 0 points.
- **A2 (AC-2):** Tier is based on **lifetime points earned**, not the current balance, so redeeming points never lowers a tier. The tier is evaluated when the order is placed, and points earned by that order do not change the discount on that same order.
- **A3 (AC-2):** The tier discount applies to the subtotal, before tax and shipping. Thresholds are inclusive: 500 points is Silver, 2,000 points is Gold.
- **A4 (AC-3):** Points are redeemed at checkout. 100 points are worth $1.00 off, and only whole multiples of 100 can be redeemed. The discount from points is applied after the tier discount.
- **A5 (AC-3):** Redeeming exactly the full balance is allowed.
- **A6 (AC-4):** "Fast" is not testable as written. The scenario uses 2 seconds at the 95th percentile on a standard test account with 500 transactions as a placeholder. The product owner must confirm the target before this scenario is accepted.
- **Labels:** Page and message names (**Points**, **Redeem points**, **Apply**) are assumed. Use the product's real labels.

## Feature file

```gherkin
@LOY-3
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am signed in as a loyalty programme member

  # ---------------------------------------------------------------
  # AC-1: Earning points
  # ---------------------------------------------------------------

  @AC-1
  Scenario Outline: A member earns 1 point for every whole dollar of the subtotal
    Given my points balance is 0
    When I place an order with a subtotal of <subtotal>
    Then my points balance is <points_earned>

    Examples: Whole and fractional dollars
      | subtotal | points_earned |
      | $24.99   | 24            |
      | $25.00   | 25            |
      | $0.99    | 0             |
      | $1.00    | 1             |
      | $1,000.01| 1000          |

  @AC-1
  Scenario: Points are based on the subtotal, not the order total
    Given my points balance is 0
    When I place an order with a subtotal of $40.00, tax of $3.20 and shipping of $5.99
    Then my points balance is 40

  @AC-1
  Scenario: Points are based on the subtotal before discounts
    Given my lifetime points earned is 600
    And my points balance is 600
    When I place an order with a subtotal of $100.00
    Then the Silver discount of $5.00 is applied
    And I earn 100 points for the order

  @AC-1
  Scenario: Points earned are added to the existing balance
    Given my points balance is 120
    When I place an order with a subtotal of $30.50
    Then my points balance is 150

  # ---------------------------------------------------------------
  # AC-2: Tiers and tier discounts
  # ---------------------------------------------------------------

  @AC-2
  Scenario Outline: A member's tier is set by lifetime points earned
    Given my lifetime points earned is <lifetime_points>
    When I open the Points page
    Then my tier is shown as "<tier>"

    Examples: Boundaries
      | lifetime_points | tier   |
      | 0               | Basic  |
      | 499             | Basic  |
      | 500             | Silver |
      | 1999            | Silver |
      | 2000            | Gold   |
      | 50000           | Gold   |

  @AC-2
  Scenario Outline: Tier discount is applied to every order
    Given my lifetime points earned is <lifetime_points>
    When I place an order with a subtotal of $100.00
    Then a tier discount of <discount> is applied
    And the subtotal after discount is <discounted_subtotal>

    Examples:
      | lifetime_points | discount | discounted_subtotal |
      | 499             | $0.00    | $100.00             |
      | 500             | $5.00    | $95.00              |
      | 2000            | $10.00   | $90.00              |

  @AC-2
  Scenario: Discount is calculated on the subtotal, not on tax or shipping
    Given my lifetime points earned is 2000
    When I place an order with a subtotal of $50.00, tax of $4.00 and shipping of $6.00
    Then a tier discount of $5.00 is applied
    And the order total is $55.00

  @AC-2
  Scenario: Points earned on an order do not change the discount on that order
    Given my lifetime points earned is 450
    When I place an order with a subtotal of $100.00
    Then no tier discount is applied to this order
    And after the order my tier is "Silver"
    And my next order receives the Silver discount

  @AC-2
  Scenario: Redeeming points does not lower the tier
    Given my lifetime points earned is 2000
    And my points balance is 2000
    When I redeem 1500 points on an order
    Then my tier is still "Gold"

  # ---------------------------------------------------------------
  # AC-3: Redeeming points
  # ---------------------------------------------------------------

  @AC-3
  Scenario: Redeeming more points than the balance is refused
    Given my points balance is 300
    And I am at checkout with a subtotal of $50.00
    When I enter 400 in "Redeem points" and select "Apply"
    Then I see the message "You don't have enough points."
    And no points discount is applied to the order
    And my points balance is still 300

  @AC-3
  Scenario: Refused redemption does not block the order
    Given my points balance is 300
    And I am at checkout with a subtotal of $50.00
    And I tried to redeem 400 points and saw "You don't have enough points."
    When I place the order without redeeming points
    Then the order is placed
    And my points balance is 350

  @AC-3
  Scenario: Redeeming fewer points than the balance succeeds
    Given my points balance is 300
    And I am at checkout with a subtotal of $50.00
    When I redeem 200 points
    Then a points discount of $2.00 is applied
    And my points balance is 100

  @AC-3
  Scenario: Redeeming exactly the full balance succeeds
    Given my points balance is 300
    And I am at checkout with a subtotal of $50.00
    When I redeem 300 points
    Then a points discount of $3.00 is applied
    And my points balance is 0

  @AC-3
  Scenario: Redeeming with a balance of zero is refused
    Given my points balance is 0
    And I am at checkout with a subtotal of $50.00
    When I enter 100 in "Redeem points" and select "Apply"
    Then I see the message "You don't have enough points."
    And my points balance is still 0

  @AC-3 @AC-2
  Scenario: Tier discount and points discount apply together
    Given my lifetime points earned is 600
    And my points balance is 600
    And I am at checkout with a subtotal of $100.00
    When I redeem 500 points
    Then a tier discount of $5.00 is applied
    And a points discount of $5.00 is applied
    And the subtotal after discounts is $90.00
    And my points balance after the order is 200

  # ---------------------------------------------------------------
  # AC-4: Points page performance
  # ---------------------------------------------------------------

  @AC-4 @needs-clarification
  Scenario: The Points page loads within the agreed time
    # "Fast" is not measurable. 2 seconds at the 95th percentile is a
    # placeholder. The product owner must confirm the target, the
    # measurement point (server response or fully rendered page) and
    # the test conditions before this scenario is accepted.
    Given my account has 500 points transactions
    And the system is under normal load
    When I open the Points page 100 times
    Then 95 or more of the loads complete within 2 seconds
```

## Notes for the product owner

- **AC-4 is not testable as written.** Replace "should load fast" with a number, a percentile and a measurement point, for example "fully rendered within 2 seconds for 95% of loads with up to 500 transactions".
- **AC-2 does not say** whether tier is based on balance or lifetime points. The scenarios assume lifetime points. If tier is based on balance, remove "Redeeming points does not lower the tier" and add a scenario where redeeming drops a member from Silver to Basic.
- **AC-3 does not give** a points-to-dollar rate or a minimum redemption. The scenarios assume 100 points = $1.00. Update the figures in the AC-3 scenarios once the rate is set.
- **Not covered by any AC:** refunds and cancelled orders (are points removed?), point expiry, and whether guests or non-members earn points. Add acceptance criteria before writing scenarios for these.
