**Assumptions** (not stated in LOY-3, chosen so the scenarios are concrete; confirm with the product owner):

- Points are earned on the order subtotal before tier discount, point redemption, tax and shipping, rounded down to the whole dollar. They are credited when the order is placed.
- Tier is derived from the member's current point balance, so redeeming points can move a member down a tier. If tier should instead use lifetime points earned, the "tier after redemption" scenario changes.
- Tier discount is applied to the subtotal, then redeemed points are deducted at a rate of 100 points = $1.00. The story gives no rate.
- A member may redeem up to and including the full balance. Redeeming zero or a negative amount is rejected.
- "Fast" (AC-4) is interpreted as: the points page returns in under 2 seconds at the 95th percentile for a member with up to 10,000 point-history entries, under normal load. This needs a real target from the product owner before it is treated as done.

Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am logged in as a loyalty programme member

  Rule: A member earns 1 point for every whole dollar of an order's subtotal (AC-1)

    Scenario Outline: Points are earned on the whole-dollar part of the subtotal
      Given my points balance is 0
      When I place an order with a subtotal of <subtotal>
      Then my points balance is <points>

      Examples:
        | subtotal | points |
        | $24.99   | 24     |
        | $25.00   | 25     |
        | $0.99    | 0      |
        | $0.00    | 0      |
        | $1,000.01 | 1000  |

    Scenario: Points are earned on the subtotal before discounts, tax and shipping
      Given my points balance is 600
      And my tier is Silver
      When I place an order with a subtotal of $100.00, $8.00 tax and $5.00 shipping
      Then the Silver discount of $5.00 is applied
      And my points balance is 700

    Scenario: Points are earned on the subtotal before any points redemption
      Given my points balance is 300
      When I place an order with a subtotal of $50.00 and redeem 200 points
      Then my points balance is 150

    Scenario: Points accumulate across orders
      Given my points balance is 40
      When I place an order with a subtotal of $10.50
      And I place an order with a subtotal of $19.99
      Then my points balance is 69

    Scenario: A non-member does not earn points
      Given I am checking out as a guest who is not a loyalty programme member
      When I place an order with a subtotal of $24.99
      Then no points are awarded

  Rule: Tier is Basic below 500 points, Silver from 500 and Gold from 2,000 (AC-2)

    Scenario Outline: Tier is determined by the current points balance
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
      When I place an order with a subtotal of $80.00
      Then a <tier> discount of <discount> is applied
      And the order total before tax and shipping is <total>

      Examples:
        | balance | tier   | discount | total  |
        | 499     | Basic  | $0.00    | $80.00 |
        | 500     | Silver | $4.00    | $76.00 |
        | 2000    | Gold   | $8.00    | $72.00 |

    Scenario: Earning points moves a member up a tier
      Given my points balance is 480
      And my tier is Basic
      When I place an order with a subtotal of $20.00
      Then my points balance is 500
      And my tier is Silver

    Scenario: The tier in effect when the order is placed determines the discount
      Given my points balance is 480
      And my tier is Basic
      When I place an order with a subtotal of $20.00
      Then no tier discount is applied to this order
      And my next order receives the Silver discount

    Scenario: Redeeming points moves a member down a tier
      Given my points balance is 2000
      And my tier is Gold
      When I redeem 100 points
      Then my points balance is 1900
      And my tier is Silver

  Rule: Redeeming more points than the balance is rejected (AC-3)

    Scenario: Redeeming more than the balance shows an error and redeems nothing
      Given my points balance is 300
      When I try to redeem 301 points
      Then I see the message "You don't have enough points."
      And my points balance is still 300
      And no discount is applied to the order

    Scenario: Redeeming exactly the balance succeeds
      Given my points balance is 300
      When I redeem 300 points on an order with a subtotal of $10.00
      Then my points balance is 0
      And a points discount of $3.00 is applied

    Scenario: Redeeming part of the balance succeeds
      Given my points balance is 300
      When I redeem 100 points on an order with a subtotal of $10.00
      Then my points balance is 200
      And a points discount of $1.00 is applied

    Scenario: Redeeming with a zero balance shows the error
      Given my points balance is 0
      When I try to redeem 1 point
      Then I see the message "You don't have enough points."
      And my points balance is still 0

    Scenario Outline: Redeeming a non-positive number of points is rejected
      Given my points balance is 300
      When I try to redeem <amount> points
      Then I see a validation message that the amount must be a positive whole number
      And my points balance is still 300

      Examples:
        | amount |
        | 0      |
        | -50    |
        | 2.5    |

    Scenario: A failed redemption does not consume points on a later attempt
      Given my points balance is 300
      And I have tried to redeem 500 points and seen "You don't have enough points."
      When I redeem 200 points
      Then my points balance is 100

  Rule: The points page loads fast (AC-4)

    Scenario: Points page meets the response-time target for a typical member
      Given I am a member with 50 point-history entries
      When I request the points page 100 times under normal load
      Then 95% of responses complete within 2 seconds

    Scenario: Points page meets the response-time target for a heavy member
      Given I am a member with 10,000 point-history entries
      When I request the points page 100 times under normal load
      Then 95% of responses complete within 2 seconds

    Scenario: Points page shows the correct balance and tier
      Given my points balance is 1250
      When I view the points page
      Then I see a balance of 1250 points
      And I see my tier as Silver
      And I see that 750 more points are needed to reach Gold
