## LOY-3 Loyalty points: BDD scenarios

**Assumptions** (not stated in the story):

- Points are earned on the order subtotal before any discount, tax or shipping, and the fractional dollar is dropped (floor, never rounded up).
- Tier thresholds are inclusive: exactly 500 points is Silver, exactly 2,000 is Gold.
- Tier is based on the lifetime points earned, so redeeming points does not demote a member. The redeemable balance is a separate figure.
- Tier discount applies to the order subtotal and is applied before any points redemption.
- One point redeems for $0.01 off the order. Points must be redeemed in whole numbers and the redemption cannot exceed the order total after discount.
- AC-4 "fast" is defined as a page load of 2 seconds or less at the 95th percentile under normal production load. This needs product sign-off.
- Non-members earn no points and get no tier discount.

```gherkin
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given the loyalty programme is active
    And "Alex" is a registered loyalty member

  # AC-1: earning points

  Scenario Outline: A member earns one point per whole dollar of subtotal
    Given Alex has a points balance of 0
    When Alex places an order with a subtotal of <subtotal>
    Then Alex's points balance is <points>

    Examples:
      | subtotal | points |
      | $24.99   | 24     |
      | $25.00   | 25     |
      | $0.99    | 0      |
      | $0.00    | 0      |
      | $100.01  | 100    |

  Scenario: Points are calculated on the subtotal before tax and shipping
    Given Alex has a points balance of 0
    When Alex places an order with a subtotal of $40.00, tax of $3.20 and shipping of $5.99
    Then Alex's points balance is 40

  Scenario: Points are calculated on the subtotal before the tier discount
    Given Alex is a Silver member with a points balance of 600
    When Alex places an order with a subtotal of $100.00
    Then the order total after discount is $95.00
    And Alex's points balance is 700

  Scenario: Earned points accumulate across orders
    Given Alex has a points balance of 10
    When Alex places an order with a subtotal of $24.99
    Then Alex's points balance is 34

  Scenario: A non-member earns no points
    Given a guest shopper who is not a loyalty member
    When the guest places an order with a subtotal of $50.00
    Then no loyalty points are awarded for the order

  # AC-2: tiers and discounts

  Scenario Outline: Tier is determined by points earned
    Given Alex has earned a lifetime total of <points> points
    Then Alex's tier is <tier>

    Examples:
      | points | tier   |
      | 0      | Basic  |
      | 499    | Basic  |
      | 500    | Silver |
      | 1999   | Silver |
      | 2000   | Gold   |
      | 5000   | Gold   |

  Scenario Outline: Tier discount is applied to the order subtotal
    Given Alex's tier is <tier>
    When Alex places an order with a subtotal of $80.00
    Then a discount of <discount> is applied
    And the order total after discount is <total>

    Examples:
      | tier   | discount | total  |
      | Basic  | $0.00    | $80.00 |
      | Silver | $4.00    | $76.00 |
      | Gold   | $8.00    | $72.00 |

  Scenario: An order that crosses a tier threshold does not earn the new discount on itself
    Given Alex is a Basic member with a lifetime total of 490 points
    When Alex places an order with a subtotal of $20.00
    Then no tier discount is applied to the order
    And Alex's lifetime total is 510 points
    And Alex's tier is Silver

  Scenario: The next order after reaching a tier gets that tier's discount
    Given Alex is a Silver member with a lifetime total of 510 points
    When Alex places an order with a subtotal of $20.00
    Then a discount of $1.00 is applied

  Scenario: Redeeming points does not lower the member's tier
    Given Alex is a Gold member with a lifetime total of 2,100 points
    And Alex has a redeemable balance of 2,100 points
    When Alex redeems 1,000 points
    Then Alex's redeemable balance is 1,100 points
    And Alex's tier is still Gold

  # AC-3: redeeming points

  Scenario: A member redeems points within their balance
    Given Alex has a redeemable balance of 1,000 points
    And Alex has an order with a total after discount of $50.00
    When Alex redeems 500 points against the order
    Then $5.00 is deducted from the order total
    And the order total is $45.00
    And Alex's redeemable balance is 500 points

  Scenario: A member redeems their entire balance
    Given Alex has a redeemable balance of 300 points
    And Alex has an order with a total after discount of $50.00
    When Alex redeems 300 points against the order
    Then $3.00 is deducted from the order total
    And Alex's redeemable balance is 0 points

  Scenario: Redeeming more points than the balance is rejected
    Given Alex has a redeemable balance of 300 points
    And Alex has an order with a total after discount of $50.00
    When Alex attempts to redeem 301 points against the order
    Then the message "You don't have enough points." is shown
    And the order total is still $50.00
    And Alex's redeemable balance is still 300 points

  Scenario: Redeeming with a zero balance is rejected
    Given Alex has a redeemable balance of 0 points
    And Alex has an order with a total after discount of $50.00
    When Alex attempts to redeem 1 point against the order
    Then the message "You don't have enough points." is shown
    And Alex's redeemable balance is still 0 points

  Scenario: Redemption cannot exceed the order total
    Given Alex has a redeemable balance of 10,000 points
    And Alex has an order with a total after discount of $20.00
    When Alex attempts to redeem 2,500 points against the order
    Then the redemption is rejected
    And Alex's redeemable balance is still 10,000 points

  Scenario: Tier discount and points redemption both apply to the same order
    Given Alex is a Silver member with a redeemable balance of 1,000 points
    And Alex places an order with a subtotal of $100.00
    When Alex redeems 500 points against the order
    Then a tier discount of $5.00 is applied first
    And $5.00 of redeemed points is deducted after the discount
    And the order total is $90.00

  Scenario: Points from a cancelled order are reversed
    Given Alex has a points balance of 100
    And Alex placed an order with a subtotal of $30.00 that earned 30 points
    When that order is cancelled before shipment
    Then Alex's points balance is 100

  # AC-4: points page performance

  Scenario: The points page loads within the agreed threshold
    Given Alex is signed in
    And the system is under normal production load
    When Alex opens the points page
    Then the page is fully loaded within 2 seconds
    And the page shows Alex's current balance, tier and points history

  Scenario: The points page loads within the threshold for a member with a long history
    Given Alex is signed in
    And Alex has 1,000 or more points transactions
    When Alex opens the points page
    Then the page is fully loaded within 2 seconds
```

**Open questions for the product owner** (scenarios above use the stated assumptions):

- Rounding: is $24.99 always floored, or is there a case where it rounds up?
- Are tiers based on lifetime points earned or on the current redeemable balance?
- What is the cash value of one point, and is there a minimum redemption?
- Does the tier discount apply before or after points redemption?
- What does "fast" mean numerically for AC-4, and on which devices and networks is it measured?
- Are points reversed on cancellation, refund or partial refund?
