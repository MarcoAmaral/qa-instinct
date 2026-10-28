# LOY-3 Loyalty points: BDD scenarios

## Assumptions

The story leaves several points open. The scenarios below use the assumptions listed here. Each one should be confirmed with the product owner before the scenarios are automated.

| # | Gap | Assumption used |
|---|-----|-----------------|
| A1 | What "subtotal" means | Merchandise total before tier discount, point redemption, tax and shipping. |
| A2 | Rounding rule | Points are the whole-dollar floor of the subtotal. Cents are never rounded up or carried over. |
| A3 | Which points decide tier | Lifetime earned points, not the spendable balance. Redeeming points does not drop a member's tier. |
| A4 | When tier takes effect | Immediately after the order that crosses the threshold. The crossing order itself does not get the new discount. |
| A5 | Redemption value | 100 points = $1.00 off. Points are redeemed in whole-point amounts. |
| A6 | Order of discounts | Tier discount is applied to the subtotal first, then redeemed points, then tax and shipping. |
| A7 | When points are earned | At successful order placement. Refunds and cancellations are out of scope for LOY-3. |
| A8 | Non-members | Guests and non-enrolled customers earn nothing and see no tier discount. |
| A9 | "Load fast" (AC-4) | AC-4 is not testable as written. Assumed target: 95th percentile page load under 2 seconds for a member with up to 10,000 point transactions. |
| A10 | Insufficient-points message | Shown inline on the redemption form, and the order total is unchanged. |

## Feature file

```gherkin
@LOY-3 @loyalty
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given the loyalty programme is enabled
    And 100 points are worth $1.00 when redeemed

  # ---------------------------------------------------------------
  # AC-1: Earning points
  # ---------------------------------------------------------------

  @AC-1
  Scenario Outline: Member earns one point per whole dollar of subtotal
    Given a Basic member with a balance of 0 points
    When the member places an order with a subtotal of <subtotal>
    Then the member's balance is <points> points

    Examples: Whole-dollar flooring
      | subtotal | points |
      | $24.99   | 24     |
      | $25.00   | 25     |
      | $25.01   | 25     |
      | $1.00    | 1      |
      | $0.99    | 0      |
      | $0.00    | 0      |
      | $1000.50 | 1000   |

  @AC-1
  Scenario: Points accumulate across orders
    Given a Basic member with a balance of 10 points
    When the member places an order with a subtotal of $24.99
    And the member places an order with a subtotal of $30.00
    Then the member's balance is 64 points

  @AC-1
  Scenario: Points are calculated on the subtotal before tier discount, tax and shipping
    Given a Silver member with a balance of 600 points
    When the member places an order with a subtotal of $100.00
    And the order has $8.00 tax and $5.00 shipping
    Then the member earns 100 points
    And the member's balance is 700 points

  @AC-1
  Scenario: Points are calculated on the subtotal before redeemed points are deducted
    Given a Basic member with a balance of 400 points
    When the member places an order with a subtotal of $50.00
    And the member redeems 200 points on that order
    Then the member earns 50 points
    And the member's balance is 250 points

  @AC-1
  Scenario: Fractional cents never carry over between orders
    Given a Basic member with a balance of 0 points
    When the member places an order with a subtotal of $10.60
    And the member places an order with a subtotal of $10.60
    Then the member's balance is 20 points

  @AC-1 @negative
  Scenario: A non-member does not earn points
    Given a guest customer who is not enrolled in the loyalty programme
    When the customer places an order with a subtotal of $24.99
    Then no points are awarded
    And no loyalty balance is created for the customer

  @AC-1 @negative
  Scenario: A failed payment does not award points
    Given a Basic member with a balance of 0 points
    When the member attempts an order with a subtotal of $24.99
    And the payment is declined
    Then the member's balance remains 0 points

  # ---------------------------------------------------------------
  # AC-2: Tiers and tier discounts
  # ---------------------------------------------------------------

  @AC-2
  Scenario Outline: Tier is determined by lifetime earned points
    Given a member with <lifetime> lifetime earned points
    When the member views the points page
    Then the member's tier is shown as "<tier>"

    Examples: Threshold boundaries
      | lifetime | tier   |
      | 0        | Basic  |
      | 499      | Basic  |
      | 500      | Silver |
      | 1999     | Silver |
      | 2000     | Gold   |
      | 50000    | Gold   |

  @AC-2
  Scenario Outline: Tier discount is applied to every order
    Given a <tier> member
    When the member places an order with a subtotal of $100.00
    Then a tier discount of <discount> is shown on the order
    And the discounted subtotal is <discounted>

    Examples:
      | tier   | discount | discounted |
      | Basic  | $0.00    | $100.00    |
      | Silver | $5.00    | $95.00     |
      | Gold   | $10.00   | $90.00     |

  @AC-2
  Scenario Outline: Tier discount is rounded to the nearest cent
    Given a <tier> member
    When the member places an order with a subtotal of <subtotal>
    Then a tier discount of <discount> is shown on the order

    Examples:
      | tier   | subtotal | discount |
      | Silver | $24.99   | $1.25    |
      | Gold   | $24.99   | $2.50    |
      | Silver | $0.10    | $0.01    |
      | Gold   | $0.01    | $0.00    |

  @AC-2
  Scenario: Tier discount applies to the subtotal, not to tax or shipping
    Given a Gold member
    When the member places an order with a subtotal of $100.00
    And the order has $8.00 tax and $5.00 shipping
    Then a tier discount of $10.00 is shown on the order
    And the order total is $103.00

  @AC-2
  Scenario: Member is upgraded to Silver after crossing 500 lifetime points
    Given a Basic member with 480 lifetime earned points
    When the member places an order with a subtotal of $20.00
    Then no tier discount is applied to that order
    And the member's lifetime earned points are 500
    And the member's tier is "Silver"
    When the member places another order with a subtotal of $100.00
    Then a tier discount of $5.00 is shown on that order

  @AC-2
  Scenario: Member is upgraded to Gold after crossing 2,000 lifetime points
    Given a Silver member with 1999 lifetime earned points
    When the member places an order with a subtotal of $1.00
    Then a tier discount of $0.05 is shown on that order
    And the member's tier is "Gold"
    When the member places another order with a subtotal of $100.00
    Then a tier discount of $10.00 is shown on that order

  @AC-2
  Scenario: Redeeming points does not lower the member's tier
    Given a Silver member with 600 lifetime earned points and a balance of 600 points
    When the member redeems 500 points on an order
    Then the member's balance is 100 points
    And the member's tier is still "Silver"
    And the next order receives a tier discount of 5%

  @AC-2
  Scenario: Tier discount and redeemed points combine on one order
    Given a Gold member with a balance of 1000 points
    When the member places an order with a subtotal of $100.00
    And the member redeems 500 points on that order
    Then a tier discount of $10.00 is shown on the order
    And a points discount of $5.00 is shown on the order
    And the discounted subtotal is $85.00

  # ---------------------------------------------------------------
  # AC-3: Redeeming points
  # ---------------------------------------------------------------

  @AC-3
  Scenario: Member redeems fewer points than the balance
    Given a member with a balance of 300 points
    When the member redeems 200 points on an order with a subtotal of $50.00
    Then a points discount of $2.00 is shown on the order
    And the member's balance is 100 points

  @AC-3
  Scenario: Member redeems exactly the full balance
    Given a member with a balance of 300 points
    When the member redeems 300 points on an order with a subtotal of $50.00
    Then a points discount of $3.00 is shown on the order
    And the member's balance is 0 points

  @AC-3 @negative
  Scenario: Redeeming more points than the balance redeems nothing
    Given a member with a balance of 300 points
    When the member attempts to redeem 301 points on an order with a subtotal of $50.00
    Then the message "You don't have enough points." is shown
    And no points discount is applied to the order
    And the member's balance is still 300 points

  @AC-3 @negative
  Scenario: Redeeming from a zero balance redeems nothing
    Given a member with a balance of 0 points
    When the member attempts to redeem 1 point on an order with a subtotal of $50.00
    Then the message "You don't have enough points." is shown
    And no points discount is applied to the order
    And the member's balance is still 0 points

  @AC-3 @negative
  Scenario: Insufficient-points message does not block the rest of checkout
    Given a member with a balance of 100 points
    When the member attempts to redeem 500 points on an order with a subtotal of $50.00
    Then the message "You don't have enough points." is shown
    And the member can still complete the order without redeeming points
    And the order total is calculated with no points discount

  @AC-3 @negative
  Scenario: Message is cleared when the member corrects the amount
    Given a member with a balance of 100 points
    And the member has attempted to redeem 500 points and seen "You don't have enough points."
    When the member changes the redemption amount to 100 points
    Then the message is no longer shown
    And a points discount of $1.00 is shown on the order

  @AC-3 @negative
  Scenario Outline: Invalid redemption amounts are rejected
    Given a member with a balance of 300 points
    When the member attempts to redeem <amount> points
    Then the redemption is rejected
    And the member's balance is still 300 points

    Examples:
      | amount |
      | 0      |
      | -1     |
      | 1.5    |
      | abc    |

  @AC-3 @negative
  Scenario: Two concurrent redemptions cannot overspend the balance
    Given a member with a balance of 300 points
    When two orders each attempt to redeem 200 points at the same time
    Then exactly one redemption succeeds
    And the other shows "You don't have enough points."
    And the member's balance is 100 points

  @AC-3 @negative
  Scenario: Points cannot be redeemed for more than the discounted subtotal
    Given a Basic member with a balance of 10000 points
    When the member attempts to redeem 10000 points on an order with a subtotal of $50.00
    Then the points discount is capped at $50.00
    And only 5000 points are deducted
    And the member's balance is 5000 points

  # ---------------------------------------------------------------
  # AC-4: Points page performance
  # ---------------------------------------------------------------

  @AC-4 @performance
  Scenario: Points page loads within the performance budget for a typical member
    Given a member with 50 point transactions in their history
    When the member opens the points page
    Then the page is fully loaded within 2 seconds at the 95th percentile over 100 requests

  @AC-4 @performance
  Scenario: Points page loads within the performance budget for a heavy member
    Given a member with 10000 point transactions in their history
    When the member opens the points page
    Then the page is fully loaded within 2 seconds at the 95th percentile over 100 requests

  @AC-4 @performance
  Scenario: Points page shows the correct balance and tier
    Given a Silver member with a balance of 750 points and 1200 lifetime earned points
    When the member opens the points page
    Then the balance shown is 750 points
    And the tier shown is "Silver"
    And the points needed for the next tier are shown as 800
```

## Open questions for the product owner

- **Tier basis (A3).** If tier is meant to follow the spendable balance instead of lifetime points, the two "upgrade" scenarios and the "redeeming does not lower tier" scenario must be rewritten, and a downgrade scenario added.
- **Points on discounted vs. original subtotal (A1).** If points should be earned on the post-discount amount, the "before tier discount" scenario flips and Silver and Gold members earn fewer points.
- **Redemption cap (last AC-3 scenario).** The story does not say whether points can exceed the order value. The capped behaviour is an assumption, and a refusal with an error message is an equally valid design.
- **AC-4 wording.** "Should load fast" cannot be verified. The 2-second p95 target needs sign-off, or the AC should be reworded to a measurable value.
