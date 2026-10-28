**Assumptions** (the story leaves these open; each is tagged in the scenarios it affects)

- A1: "Subtotal" is the merchandise total before tier discount, tax and shipping. Points are calculated on the pre-discount subtotal and credited when the order is placed.
- A2: Tier is derived from the member's *current* points balance, so redeeming points can lower a tier. If tier should be based on lifetime points earned, the tier scenarios need a second column.
- A3: Points cannot go negative. Redemption value is not stated; the scenarios assume 100 points = $1.00 off and that a redemption must be a positive whole number of points.
- A4: "Load fast" is not testable as written. The scenario assumes a 95th-percentile response time under 2 seconds for a member with 10,000 history entries, measured server-side. The product owner should confirm the budget.
- A5: Tier discounts stack with points redemption: the tier discount is applied first, then redeemed points are subtracted.

```gherkin
Feature: Loyalty points (LOY-3)
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am logged in as a loyalty programme member

  # ---------------------------------------------------------------
  # AC-1: earning points
  # ---------------------------------------------------------------

  @AC-1
  Scenario Outline: Points are earned per whole dollar of the subtotal
    Given my points balance is 0
    When I place an order with a subtotal of <subtotal>
    Then my points balance is <points>

    Examples:
      | subtotal | points |
      | $24.99   | 24     |
      | $24.00   | 24     |
      | $0.99    | 0      |
      | $1.00    | 1      |
      | $100.50  | 100    |

  @AC-1 @A1
  Scenario: Points are calculated on the subtotal before tier discount, tax and shipping
    Given my points balance is 600
    And my tier is Silver
    When I place an order with a subtotal of $100.00, tax of $8.00 and shipping of $5.99
    Then the order total is $113.99
    And my points balance is 700

  @AC-1
  Scenario: Points are added to an existing balance
    Given my points balance is 150
    When I place an order with a subtotal of $49.50
    Then my points balance is 199

  # ---------------------------------------------------------------
  # AC-2: tiers and tier discounts
  # ---------------------------------------------------------------

  @AC-2 @A2
  Scenario Outline: Tier is determined by points balance
    Given my points balance is <balance>
    When I view my loyalty status
    Then my tier is <tier>

    Examples:
      | balance | tier   |
      | 0       | Basic  |
      | 499     | Basic  |
      | 500     | Silver |
      | 1999    | Silver |
      | 2000    | Gold   |
      | 5000    | Gold   |

  @AC-2
  Scenario Outline: Tier discount is applied to every order
    Given my tier is <tier>
    When I place an order with a subtotal of $200.00
    Then a tier discount of <discount> is applied
    And the discounted subtotal is <discounted_subtotal>

    Examples:
      | tier   | discount | discounted_subtotal |
      | Basic  | $0.00    | $200.00             |
      | Silver | $10.00   | $190.00             |
      | Gold   | $20.00   | $180.00             |

  @AC-2
  Scenario: Crossing a tier threshold upgrades the member for the next order
    Given my points balance is 480
    And my tier is Basic
    When I place an order with a subtotal of $30.00
    Then my points balance is 510
    And my tier is Silver
    And no tier discount was applied to that order

  @AC-2 @A2
  Scenario: Redeeming points below a threshold lowers the tier
    Given my points balance is 2000
    And my tier is Gold
    When I redeem 100 points
    Then my points balance is 1900
    And my tier is Silver

  # ---------------------------------------------------------------
  # AC-3: redeeming points
  # ---------------------------------------------------------------

  @AC-3 @A3
  Scenario: Redeeming more points than the balance is rejected
    Given my points balance is 300
    When I try to redeem 301 points
    Then I see the message "You don't have enough points."
    And my points balance is still 300
    And no discount is applied to my order

  @AC-3 @A3
  Scenario: Redeeming exactly the full balance succeeds
    Given my points balance is 300
    And I have an order with a subtotal of $50.00
    When I redeem 300 points
    Then $3.00 is deducted from the order
    And my points balance is 0

  @AC-3 @A3
  Scenario: Redeeming part of the balance succeeds
    Given my points balance is 1000
    And I have an order with a subtotal of $50.00
    When I redeem 250 points
    Then $2.50 is deducted from the order
    And my points balance is 750

  @AC-3 @A3
  Scenario Outline: Invalid redemption amounts are rejected
    Given my points balance is 300
    When I try to redeem <amount> points
    Then I see the message "<message>"
    And my points balance is still 300

    Examples:
      | amount | message                                   |
      | 0      | Enter a whole number of points to redeem. |
      | -50    | Enter a whole number of points to redeem. |
      | 12.5   | Enter a whole number of points to redeem. |

  @AC-3 @A5
  Scenario: Tier discount is applied before redeemed points are deducted
    Given my points balance is 1000
    And my tier is Silver
    And I have an order with a subtotal of $100.00
    When I redeem 500 points
    Then a tier discount of $5.00 is applied
    And $5.00 is deducted for redeemed points
    And the discounted subtotal is $90.00
    And my points balance is 500

  @AC-1 @AC-3
  Scenario: Points earned on an order are not available to redeem on that same order
    Given my points balance is 0
    And I have an order with a subtotal of $120.00
    When I try to redeem 100 points on that order
    Then I see the message "You don't have enough points."
    When I place the order
    Then my points balance is 120

  # ---------------------------------------------------------------
  # AC-4: points page performance (non-functional)
  # ---------------------------------------------------------------

  @AC-4 @A4 @non-functional
  Scenario: Points page loads within the performance budget
    Given my account has 10,000 points history entries
    When I open the points page 100 times under normal production load
    Then the 95th-percentile server response time is under 2 seconds
    And every response shows my current balance and tier
```

**Open points for the product owner**

- Confirm whether tier uses current balance or lifetime earned points (A2).
- Confirm the dollar value of a point and whether partial redemption is allowed (A3).
- Replace "load fast" with a measurable budget and the conditions it applies under (A4).
- Confirm whether tier discount and points redemption stack, and in which order (A5).
- Decide what happens to earned points when an order is cancelled or refunded. This is out of scope for LOY-3 as written.
