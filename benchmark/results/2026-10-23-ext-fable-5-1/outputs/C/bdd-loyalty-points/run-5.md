**Assumptions** (not stated in LOY-3, confirm with the product owner before these scenarios are automated):

- A1: "Subtotal" is the merchandise total before the tier discount, tax and shipping. Points are rounded down to the whole dollar.
- A2: Tier is based on the member's lifetime points earned, so redeeming points never lowers a tier.
- A3: The tier discount applies to the subtotal and is applied before any points redemption.
- A4: Redemption value is 100 points = $1.00 off, in whole-dollar steps. The story gives no rate.
- A5: AC-4 "should load fast" is not testable as written. The scenario below uses a placeholder target of 2 seconds for 95% of page loads at normal traffic. The product owner must confirm the number or the scenario stays pending.
- A6: Guests and non-members earn nothing. The story only describes members.

```gherkin
# Story LOY-3: Loyalty points
@LOY-3
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given "Ana" is a member of the loyalty programme

  # ---------------------------------------------------------------
  # AC-1: 1 point per whole dollar of the order subtotal
  # ---------------------------------------------------------------
  @AC-1
  Scenario Outline: A member earns 1 point for every whole dollar of the subtotal
    Given Ana has a points balance of 0
    When Ana completes an order with a subtotal of <subtotal>
    Then Ana's points balance is <points>

    Examples: Cents are ignored
      | subtotal | points |
      | $24.99   | 24     |
      | $24.00   | 24     |
      | $0.99    | 0      |
      | $1.00    | 1      |
      | $150.50  | 150    |

  @AC-1
  Scenario: Points are earned on the subtotal, not on tax or shipping
    Given Ana has a points balance of 0
    When Ana completes an order with a subtotal of $40.00, tax of $3.20 and shipping of $5.00
    Then Ana's points balance is 40

  @AC-1
  Scenario: Earned points are added to the existing balance
    Given Ana has a points balance of 100
    When Ana completes an order with a subtotal of $24.99
    Then Ana's points balance is 124

  @AC-1
  Scenario: A non-member earns no points
    Given "Ben" is not a member of the loyalty programme
    When Ben completes an order with a subtotal of $24.99
    Then no points are recorded for Ben

  # ---------------------------------------------------------------
  # AC-2: Tiers and tier discounts
  # ---------------------------------------------------------------
  @AC-2
  Scenario Outline: A member's tier is set by lifetime points earned
    Given Ana has earned <lifetime_points> points in total
    When Ana views the points page
    Then Ana's tier is shown as "<tier>"

    Examples: Tier boundaries
      | lifetime_points | tier   |
      | 0               | Basic  |
      | 499             | Basic  |
      | 500             | Silver |
      | 1999            | Silver |
      | 2000            | Gold   |
      | 10000           | Gold   |

  @AC-2
  Scenario Outline: The tier discount is applied to every order
    Given Ana has earned <lifetime_points> points in total
    When Ana places an order with a subtotal of $100.00
    Then a tier discount of <discount> is applied
    And the order total before tax and shipping is <total>

    Examples:
      | lifetime_points | discount | total   |
      | 499             | $0.00    | $100.00 |
      | 500             | $5.00    | $95.00  |
      | 2000            | $10.00   | $90.00  |

  @AC-2
  Scenario: A member moves up a tier when an order crosses the threshold
    Given Ana has earned 480 points in total
    When Ana completes an order with a subtotal of $24.99
    Then Ana's points balance is 504
    And Ana's tier is shown as "Silver"
    And the next order Ana places receives a 5% tier discount

  @AC-2
  Scenario: The order that crosses a threshold does not get the new discount
    Given Ana has earned 480 points in total
    When Ana places an order with a subtotal of $100.00
    Then a tier discount of $0.00 is applied

  @AC-2
  Scenario: Redeeming points does not lower the tier
    Given Ana has earned 600 points in total
    And Ana has a points balance of 600
    When Ana redeems 500 points on an order
    Then Ana's points balance is 100
    And Ana's tier is shown as "Silver"

  # ---------------------------------------------------------------
  # AC-3: Redeeming more points than the balance
  # ---------------------------------------------------------------
  @AC-3
  Scenario: Redeeming more points than the balance is refused
    Given Ana has a points balance of 300
    And Ana has an order with a subtotal of $50.00 at checkout
    When Ana tries to redeem 400 points
    Then the message "You don't have enough points." is shown
    And no points are deducted from Ana's balance
    And no points discount is applied to the order

  @AC-3
  Scenario: Redeeming exactly the balance is allowed
    Given Ana has a points balance of 300
    And Ana has an order with a subtotal of $50.00 at checkout
    When Ana redeems 300 points
    Then a points discount of $3.00 is applied to the order
    And Ana's points balance is 0

  @AC-3
  Scenario: Redeeming fewer points than the balance is allowed
    Given Ana has a points balance of 300
    And Ana has an order with a subtotal of $50.00 at checkout
    When Ana redeems 200 points
    Then a points discount of $2.00 is applied to the order
    And Ana's points balance is 100

  @AC-3
  Scenario: Redeeming with a zero balance is refused
    Given Ana has a points balance of 0
    And Ana has an order with a subtotal of $50.00 at checkout
    When Ana tries to redeem 100 points
    Then the message "You don't have enough points." is shown
    And Ana's points balance is 0

  @AC-3 @AC-2
  Scenario: Tier discount and points discount apply together
    Given Ana has earned 600 points in total
    And Ana has a points balance of 600
    And Ana has an order with a subtotal of $100.00 at checkout
    When Ana redeems 500 points
    Then a tier discount of $5.00 is applied
    And a points discount of $5.00 is applied
    And the order total before tax and shipping is $90.00

  # ---------------------------------------------------------------
  # AC-4: Points page performance
  # ---------------------------------------------------------------
  @AC-4 @pending @needs-target
  Scenario: The points page loads within the agreed time
    # AC-4 says "fast" with no number. Placeholder target below; confirm before automating.
    Given the site is under normal traffic
    When 100 members open the points page
    Then 95 or more of those page loads complete within 2 seconds
```

**Open questions recorded as assumptions above:** the redemption rate (A4), whether tier uses lifetime points or current balance (A2), whether the subtotal is measured before or after the tier discount (A1), and a numeric target for AC-4 (A5). The AC-4 scenario is tagged pending until that number is agreed.
