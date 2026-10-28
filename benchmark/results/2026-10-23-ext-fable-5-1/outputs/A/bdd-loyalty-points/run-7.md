# LOY-3: Loyalty points — BDD scenarios

## Assumptions

The story leaves several points open. I have taken the following positions; each is flagged in the feature file with a comment and should be confirmed with the product owner.

1. **Rounding (AC-1):** points are the subtotal rounded *down* to the whole dollar. "Subtotal" means merchandise value before tier discount, redeemed points, tax and shipping.
2. **Points award timing (AC-1):** points are credited when the order is placed, not when shipped. Cancelled orders are out of scope for this story.
3. **Tier basis (AC-2):** tier is based on **lifetime points earned**, not current balance, so redeeming points never demotes a member. If tier is meant to follow the spendable balance, the "tier is unaffected by redemption" scenario must be inverted.
4. **Tier boundaries (AC-2):** thresholds are inclusive, so 500 points is Silver and 2,000 points is Gold.
5. **Discount base (AC-2):** the tier discount applies to the order subtotal, before tax and shipping, and is applied before any points redemption.
6. **Redemption rate (AC-3, not stated):** 100 points = $1.00 off. Redemptions must be a positive whole number of points and may not exceed the order subtotal after tier discount.
7. **"Fast" (AC-4, not measurable as written):** the points page renders in under 2 seconds at the 95th percentile for a member with 10,000 points transactions. This number needs sign‑off before it is used as a release gate.
8. **Non-members** neither earn nor redeem points; guest checkout is unaffected.

## Feature file

```gherkin
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given the loyalty programme is active
    And the redemption rate is 100 points per $1.00
    # Assumption 6: redemption rate is not specified in the story

  # ---------------------------------------------------------------
  # AC-1: Earning points
  # ---------------------------------------------------------------

  Rule: A member earns 1 point for every whole dollar of an order's subtotal

    # Assumption 1: subtotal is rounded down, before discounts, tax and shipping
    # Assumption 2: points are credited when the order is placed

    Scenario Outline: Points are earned on the whole-dollar part of the subtotal
      Given a member with a points balance of 0
      When the member places an order with a subtotal of <subtotal>
      Then the member's points balance is <points>

      Examples:
        | subtotal | points |
        | $24.99   | 24     |
        | $25.00   | 25     |
        | $0.99    | 0      |
        | $0.00    | 0      |
        | $1.00    | 1      |
        | $1,234.56| 1234   |

    Scenario: Points are earned on the subtotal, not on tax, shipping or discounts
      Given a Silver member with a lifetime total of 600 points
      When the member places an order with a subtotal of $100.00
      And the order has $8.00 tax and $5.99 shipping
      And the member redeems 1000 points against the order
      Then the member earns 100 points for the order
      # Subtotal $100.00 → 100 points, regardless of the 5% tier discount,
      # the $10.00 redemption, tax or shipping

    Scenario: Earned points are added to an existing balance
      Given a member with a points balance of 150
      When the member places an order with a subtotal of $49.50
      Then the member's points balance is 199

    Scenario: A non-member does not earn points
      Given a shopper who is not enrolled in the loyalty programme
      When the shopper places an order with a subtotal of $80.00
      Then no points are awarded
      And the order confirmation does not mention points
      # Assumption 8

  # ---------------------------------------------------------------
  # AC-2: Tiers and tier discounts
  # ---------------------------------------------------------------

  Rule: Tier is Basic below 500 points, Silver from 500 and Gold from 2,000

    # Assumption 3: tier is based on lifetime points earned
    # Assumption 4: thresholds are inclusive

    Scenario Outline: Tier is determined by lifetime points earned
      Given a member with a lifetime total of <lifetime points> points
      Then the member's tier is <tier>

      Examples: Basic
        | lifetime points | tier   |
        | 0               | Basic  |
        | 499             | Basic  |

      Examples: Silver
        | lifetime points | tier   |
        | 500             | Silver |
        | 1999            | Silver |

      Examples: Gold
        | lifetime points | tier   |
        | 2000            | Gold   |
        | 50000           | Gold   |

    Scenario: A member is promoted when an order crosses a threshold
      Given a Basic member with a lifetime total of 480 points
      When the member places an order with a subtotal of $20.00
      Then the member's tier is Silver
      And the member is shown "You've reached Silver"

    Scenario: Tier is unaffected by redeeming points
      Given a Gold member with a lifetime total of 2100 points
      And a points balance of 2100
      When the member redeems 2000 points
      Then the member's points balance is 100
      And the member's tier is still Gold
      # Assumption 3 — invert this scenario if tier should follow the balance

  Rule: Silver members get 5% off every order and Gold members 10%

    # Assumption 5: discount applies to the subtotal before tax and shipping

    Scenario Outline: Tier discount is applied to every order
      Given a <tier> member
      When the member places an order with a subtotal of $200.00
      Then a tier discount of <discount> is applied
      And the order subtotal after tier discount is <discounted subtotal>

      Examples:
        | tier   | discount | discounted subtotal |
        | Basic  | $0.00    | $200.00             |
        | Silver | $10.00   | $190.00             |
        | Gold   | $20.00   | $180.00             |

    Scenario: Tier discount is rounded to the nearest cent
      Given a Silver member
      When the member places an order with a subtotal of $24.99
      Then a tier discount of $1.25 is applied
      # 5% of $24.99 = $1.2495, rounded to $1.25

    Scenario: The newly reached tier applies from the next order, not the current one
      Given a Basic member with a lifetime total of 480 points
      When the member places an order with a subtotal of $20.00
      Then no tier discount is applied to that order
      When the member places a second order with a subtotal of $100.00
      Then a tier discount of $5.00 is applied to the second order

  # ---------------------------------------------------------------
  # AC-3: Redeeming points
  # ---------------------------------------------------------------

  Rule: Redeeming more points than the balance shows an error and redeems nothing

    Scenario: Redeeming more points than the balance is rejected
      Given a member with a points balance of 300
      And the member is checking out an order with a subtotal of $50.00
      When the member tries to redeem 500 points
      Then the member sees "You don't have enough points."
      And the member's points balance is still 300
      And no discount is applied to the order

    Scenario: Redeeming exactly the full balance is allowed
      Given a member with a points balance of 500
      And the member is checking out an order with a subtotal of $50.00
      When the member redeems 500 points
      Then a redemption discount of $5.00 is applied to the order
      And the member's points balance is 0

    Scenario: Redeeming part of the balance reduces it by the amount redeemed
      Given a member with a points balance of 800
      And the member is checking out an order with a subtotal of $50.00
      When the member redeems 300 points
      Then a redemption discount of $3.00 is applied to the order
      And the member's points balance is 500

    Scenario: Redeeming with a zero balance is rejected
      Given a member with a points balance of 0
      And the member is checking out an order with a subtotal of $50.00
      When the member tries to redeem 1 point
      Then the member sees "You don't have enough points."
      And no discount is applied to the order

    Scenario: Tier discount and redeemed points are both applied, tier discount first
      Given a Gold member with a points balance of 1000
      And the member is checking out an order with a subtotal of $100.00
      When the member redeems 1000 points
      Then a tier discount of $10.00 is applied
      And a redemption discount of $10.00 is applied
      And the order subtotal after discounts is $80.00
      # Assumption 5

    Scenario: Redemption cannot exceed the discounted order value
      Given a member with a points balance of 10000
      And the member is checking out an order with a subtotal of $20.00
      When the member tries to redeem 5000 points
      Then the member sees "You can redeem up to 2,000 points on this order."
      And the member's points balance is still 10000
      # Assumption 6 — message wording to be confirmed

    Scenario: A failed redemption does not consume points if the order is abandoned
      Given a member with a points balance of 800
      And the member is checking out an order with a subtotal of $50.00
      And the member has redeemed 300 points against the order
      When the member abandons the checkout without placing the order
      Then the member's points balance is 800

  # ---------------------------------------------------------------
  # AC-4: Points page performance
  # ---------------------------------------------------------------

  Rule: The points page loads fast

    # Assumption 7: "fast" is not defined in the story. The targets below are
    # placeholders and must be agreed before they are used as a release gate.

    @non-functional @performance
    Scenario: Points page loads within the target for a member with a large history
      Given a member with 10,000 points transactions
      When the member opens the points page
      Then the page is fully rendered within 2 seconds at the 95th percentile
      And the balance, tier and most recent 20 transactions are visible

    @non-functional @performance
    Scenario: Points page loads within the target for a new member
      Given a member with no points transactions
      When the member opens the points page
      Then the page is fully rendered within 1 second at the 95th percentile
      And the page shows a balance of 0 and a tier of Basic

    @non-functional @performance
    Scenario: Points page stays within target under concurrent load
      Given 500 members opening the points page at the same time
      When the load test runs for 5 minutes
      Then the 95th percentile render time stays under 2 seconds
      And no request fails
```

## Open questions to confirm

- Is tier based on lifetime points earned or on the current balance? (Assumption 3)
- What is the points‑to‑dollar redemption rate, and is there a minimum redemption? (Assumption 6)
- What is the measurable target behind "fast"? (Assumption 7)
- Should points be clawed back when an order is cancelled or refunded? Not covered by this story; suggest a follow‑up ticket.
