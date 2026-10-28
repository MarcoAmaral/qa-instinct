# Feature: LOY-3 Loyalty points

## Assumptions

The story leaves several things undefined. Scenarios below use these assumptions; each should be confirmed with the Product Owner before the scenarios are automated.

| # | Gap | Assumption used |
|---|-----|-----------------|
| A1 | What "subtotal" means | Merchandise total before tier discount, point redemption, tax and shipping |
| A2 | When points are credited | On successful order placement (not on delivery); cancelled or refunded orders reverse the points |
| A3 | What "points" the tier is based on | The member's current points balance at the moment the order is placed, not lifetime earned. Redeeming can therefore lower a tier. This is the biggest open question. |
| A4 | What the tier discount applies to | The subtotal, before tax and shipping; applied before any point redemption |
| A5 | Redemption value | 100 points = $1.00 off; points are redeemed in whole numbers; a redemption cannot exceed the order's post-discount subtotal |
| A6 | Points earned on an order with discounts | Based on the subtotal per A1, i.e. not reduced by the tier discount or the points redeemed |
| A7 | Non-members | Guests and non-enrolled accounts earn nothing and see no loyalty UI |
| A8 | AC-4 "fast" | p95 page load under 2 seconds and p99 under 4 seconds at the expected peak of 200 concurrent members, measured server-side plus first contentful paint. The story owner must replace these numbers with real targets. |
| A9 | Rounding | Points are the floor of the whole-dollar subtotal; no rounding up, no fractional points |

---

```gherkin
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given the loyalty programme is enabled
    And tiers are configured as:
      | tier   | minimum points | discount |
      | Basic  | 0              | 0%       |
      | Silver | 500            | 5%       |
      | Gold   | 2000           | 10%      |
    And 100 points are worth $1.00 when redeemed
    And member "Priya" is enrolled in the loyalty programme

  # ---------------------------------------------------------------
  Rule: A member earns 1 point for every whole dollar of an order's subtotal (AC-1)

    Scenario Outline: Points earned are the whole-dollar part of the subtotal
      Given Priya has a balance of 0 points
      When Priya places an order with a subtotal of <subtotal>
      Then Priya's balance becomes <points> points
      And the order confirmation shows "You earned <points> points"

      Examples: Fractional dollars are floored, never rounded
        | subtotal | points |
        | $24.99   | 24     |
        | $24.01   | 24     |
        | $24.50   | 24     |
        | $25.00   | 25     |
        | $0.99    | 0      |
        | $1.00    | 1      |
        | $0.00    | 0      |
        | $1234.56 | 1234   |

    Scenario: Points are earned on the subtotal, not the grand total
      Given Priya has a balance of 0 points
      When Priya places an order with:
        | subtotal | $40.00 |
        | tax      | $3.50  |
        | shipping | $5.99  |
        | total    | $49.49 |
      Then Priya's balance becomes 40 points

    Scenario: Points are earned on the pre-discount subtotal
      Given Priya has a balance of 600 points
      And Priya is therefore a Silver member
      When Priya places an order with a subtotal of $100.00
      Then the Silver discount of $5.00 is applied
      And Priya earns 100 points, not 95
      And Priya's balance becomes 700 points

    Scenario: Points are earned on top of an order that redeemed points
      Given Priya has a balance of 300 points
      When Priya places an order with a subtotal of $50.00 and redeems 200 points
      Then the order is charged $48.00
      And Priya earns 50 points
      And Priya's balance becomes 150 points

    Scenario: Points are added to an existing balance
      Given Priya has a balance of 130 points
      When Priya places an order with a subtotal of $19.99
      Then Priya's balance becomes 149 points

    Scenario: Points are not credited for an order that fails payment
      Given Priya has a balance of 100 points
      When Priya attempts an order with a subtotal of $60.00
      And the payment is declined
      Then Priya's balance remains 100 points

    Scenario: Points are reversed when an order is cancelled
      Given Priya placed an order with a subtotal of $80.00
      And Priya's balance is 80 points
      When the order is cancelled before dispatch
      Then Priya's balance returns to 0 points
      And Priya's points history shows a "-80 Order cancelled" entry

    Scenario: Points are partially reversed on a partial refund
      Given Priya placed an order with a subtotal of $80.00
      And Priya's balance is 80 points
      When $30.00 of merchandise from that order is refunded
      Then Priya's balance becomes 50 points

    Scenario: A guest earns no points
      Given a shopper is not signed in
      When the shopper places an order with a subtotal of $24.99
      Then no loyalty points are awarded
      And the order confirmation does not mention points

    Scenario: A signed-in customer who is not enrolled earns no points
      Given customer "Tom" has an account but is not enrolled in the loyalty programme
      When Tom places an order with a subtotal of $24.99
      Then no loyalty points are awarded
      And Tom is shown a prompt to join the loyalty programme

    Scenario: Points history records the earning event
      Given Priya has a balance of 0 points
      When Priya places order "ORD-1001" with a subtotal of $24.99
      Then Priya's points page shows a history entry:
        | date  | today       |
        | event | Order ORD-1001 |
        | change | +24        |
        | balance | 24        |

  # ---------------------------------------------------------------
  Rule: Tier is Basic below 500, Silver from 500, Gold from 2,000 (AC-2)

    Scenario Outline: Tier is determined by the points balance, boundaries inclusive
      Given Priya has a balance of <balance> points
      When Priya views the points page
      Then her tier is shown as "<tier>"

      Examples:
        | balance | tier   |
        | 0       | Basic  |
        | 499     | Basic  |
        | 500     | Silver |
        | 501     | Silver |
        | 1999    | Silver |
        | 2000    | Gold   |
        | 2001    | Gold   |
        | 50000   | Gold   |

    Scenario Outline: Tier discount is applied to the subtotal of every order
      Given Priya has a balance of <balance> points
      When Priya adds items with a subtotal of $100.00 to the basket
      And proceeds to checkout
      Then the checkout shows a "<tier> member discount" of <discount>
      And the discounted subtotal is <discounted subtotal>

      Examples:
        | balance | tier   | discount | discounted subtotal |
        | 499     | Basic  | $0.00    | $100.00             |
        | 500     | Silver | $5.00    | $95.00              |
        | 2000    | Gold   | $10.00   | $90.00              |

    Scenario: Basic members see no discount line at all
      Given Priya has a balance of 100 points
      When Priya proceeds to checkout with a subtotal of $100.00
      Then no member discount line is shown
      And the subtotal remains $100.00

    Scenario: Gold discount replaces, not stacks with, Silver discount
      Given Priya has a balance of 2500 points
      When Priya proceeds to checkout with a subtotal of $100.00
      Then exactly one member discount line is shown
      And the discount is $10.00, not $15.00

    Scenario Outline: Tier discount rounds to the nearest cent
      Given Priya has a balance of <balance> points
      When Priya proceeds to checkout with a subtotal of <subtotal>
      Then the member discount is <discount>

      Examples:
        | balance | subtotal | discount |
        | 500     | $24.99   | $1.25    |
        | 500     | $0.10    | $0.01    |
        | 500     | $0.09    | $0.00    |
        | 2000    | $24.99   | $2.50    |
        | 2000    | $33.33   | $3.33    |

    Scenario: Tier discount is applied before tax
      Given Priya has a balance of 2000 points
      And the tax rate is 10%
      When Priya proceeds to checkout with a subtotal of $100.00
      Then the member discount is $10.00
      And tax is calculated on $90.00 as $9.00
      And the order total is $99.00 plus shipping

    Scenario: Tier discount does not apply to shipping
      Given Priya has a balance of 2000 points
      When Priya proceeds to checkout with a subtotal of $100.00 and shipping of $10.00
      Then the member discount is $10.00
      And shipping remains $10.00

    Scenario: Tier is evaluated at the moment the order is placed
      Given Priya has a balance of 480 points
      And Priya has a basket with a subtotal of $100.00 showing no discount
      When another of Priya's orders completes and credits 30 points
      And Priya refreshes the checkout
      Then Priya's tier is now Silver
      And a member discount of $5.00 is shown

    Scenario: Points earned on the current order do not count towards its own discount
      Given Priya has a balance of 450 points
      When Priya places an order with a subtotal of $100.00
      Then no member discount is applied to this order
      And Priya's balance becomes 550 points
      And Priya's next order will receive the Silver discount

    Scenario: Member is promoted to Silver and notified
      Given Priya has a balance of 490 points
      When Priya places an order with a subtotal of $10.00
      Then Priya's balance becomes 500 points
      And Priya's tier becomes Silver
      And the order confirmation shows "Congratulations, you've reached Silver"

    Scenario: Redeeming points below a threshold lowers the tier (per assumption A3)
      Given Priya has a balance of 520 points
      And Priya is a Silver member
      When Priya places an order with a subtotal of $30.00 and redeems 100 points
      Then the Silver discount of $1.50 is applied to this order
      And Priya's balance becomes 450 points
      And Priya's tier becomes Basic
      And the checkout warned "Redeeming 100 points will move you to Basic" before confirmation

    Scenario: Cancelling an order can demote the member
      Given Priya has a balance of 520 points after order "ORD-2001" credited 40 points
      When order "ORD-2001" is cancelled
      Then Priya's balance becomes 480 points
      And Priya's tier becomes Basic

    Scenario: Tier discount is shown consistently across basket, checkout and confirmation
      Given Priya has a balance of 2000 points
      When Priya adds items with a subtotal of $100.00 and completes checkout
      Then the basket, checkout, order confirmation and order history all show a Gold discount of $10.00

  # ---------------------------------------------------------------
  Rule: Redeeming more points than the balance redeems nothing (AC-3)

    Scenario: Redeeming more points than the balance is rejected with the exact message
      Given Priya has a balance of 150 points
      When Priya tries to redeem 200 points at checkout
      Then the message "You don't have enough points." is shown
      And no points are deducted
      And Priya's balance remains 150 points
      And the order total is unchanged

    Scenario: Redeeming one point more than the balance is rejected
      Given Priya has a balance of 150 points
      When Priya tries to redeem 151 points at checkout
      Then the message "You don't have enough points." is shown
      And Priya's balance remains 150 points

    Scenario: Redeeming exactly the balance succeeds
      Given Priya has a balance of 150 points
      When Priya redeems 150 points on an order with a subtotal of $20.00
      Then the order is reduced by $1.50
      And Priya's balance becomes 0 points
      And no error message is shown

    Scenario: Redeeming fewer points than the balance succeeds
      Given Priya has a balance of 1000 points
      When Priya redeems 400 points on an order with a subtotal of $50.00
      Then the order is reduced by $4.00
      And Priya's balance becomes 600 points

    Scenario: Redeeming with a zero balance is rejected
      Given Priya has a balance of 0 points
      When Priya tries to redeem 1 point at checkout
      Then the message "You don't have enough points." is shown
      And Priya's balance remains 0 points

    Scenario: Failed redemption does not block completing the order without points
      Given Priya has a balance of 150 points
      And Priya tried to redeem 200 points and saw "You don't have enough points."
      When Priya clears the redemption field and completes checkout
      Then the order is placed at full price
      And Priya's balance becomes 150 points plus the points earned on this order

    Scenario: Member can correct the amount after a rejected redemption
      Given Priya has a balance of 150 points
      And Priya tried to redeem 200 points and saw "You don't have enough points."
      When Priya changes the amount to 100 points and applies it
      Then the error message disappears
      And the order is reduced by $1.00
      And Priya's balance becomes 50 points

    Scenario: Balance changed in another session is respected at the moment of redemption
      Given Priya has a balance of 300 points
      And Priya has entered a redemption of 300 points at checkout in browser A
      When Priya completes a separate order in browser B that redeems 100 points
      And Priya then confirms the order in browser A
      Then the message "You don't have enough points." is shown in browser A
      And the order in browser A is not placed
      And Priya's balance remains 200 points

    Scenario: Two simultaneous redemptions cannot overdraw the balance
      Given Priya has a balance of 300 points
      When two checkout requests each redeeming 300 points are submitted at the same instant
      Then exactly one of them succeeds
      And the other shows "You don't have enough points."
      And Priya's balance is 0 points, never negative

    Scenario: Redemption request is validated server-side
      Given Priya has a balance of 150 points
      When a checkout request redeeming 200 points is sent directly to the API, bypassing the UI
      Then the API responds with a validation error containing "You don't have enough points."
      And no points are deducted
      And no order is created

    Scenario Outline: Invalid redemption amounts are rejected without touching the balance
      Given Priya has a balance of 500 points
      When Priya tries to redeem "<amount>" points
      Then the message "<message>" is shown
      And Priya's balance remains 500 points

      Examples:
        | amount | message                               |
        | -50    | Enter a whole number of points.       |
        | 12.5   | Enter a whole number of points.       |
        | abc    | Enter a whole number of points.       |
        |        | Enter a whole number of points.       |
        | 0      | Enter at least 1 point.               |

    Scenario: Redemption cannot exceed the value of the order (per assumption A5)
      Given Priya has a balance of 5000 points
      When Priya tries to redeem 3000 points on an order whose discounted subtotal is $20.00
      Then the message "You can redeem up to 2000 points on this order." is shown
      And Priya's balance remains 5000 points

    Scenario: Redeemed points are returned if the order is cancelled
      Given Priya has a balance of 100 points after redeeming 200 points on order "ORD-3001"
      When order "ORD-3001" is cancelled before dispatch
      Then Priya's balance becomes 300 points
      And Priya's points history shows a "+200 Points returned, order ORD-3001 cancelled" entry

    Scenario: Redeemed points are not deducted if payment fails
      Given Priya has a balance of 300 points
      When Priya attempts an order redeeming 200 points
      And the payment is declined
      Then Priya's balance remains 300 points

    Scenario: Redemption is applied after the tier discount
      Given Priya has a balance of 2000 points
      When Priya places an order with a subtotal of $100.00 and redeems 500 points
      Then the Gold discount of $10.00 is applied first, giving $90.00
      And the 500 points reduce the order by $5.00, giving $85.00
      And Priya's balance becomes 1500 points plus 100 points earned

  # ---------------------------------------------------------------
  Rule: The points page loads fast (AC-4, thresholds per assumption A8)

    Scenario: Points page meets the load-time target under normal load
      Given 200 members are browsing the site concurrently
      And Priya has 50 entries in her points history
      When Priya opens the points page 100 times
      Then the p95 time to first contentful paint is under 2 seconds
      And the p99 time is under 4 seconds
      And the server response time p95 is under 500 milliseconds

    Scenario: Points page stays fast for a member with a very long history
      Given Priya has 10,000 entries in her points history
      When Priya opens the points page
      Then the page renders the balance, tier and the most recent 50 entries within 2 seconds
      And older entries are loaded on demand via pagination

    Scenario: Points page is fast on a slow mobile connection
      Given the network is throttled to "Slow 3G"
      When Priya opens the points page
      Then the balance and tier are visible within 5 seconds
      And the total page weight is under 500 KB

    Scenario: Points page shows the balance before non-critical content
      When Priya opens the points page
      Then the balance and tier are rendered before promotional banners and history
      And no blocking third-party script delays the balance

    Scenario: Points page does not degrade under peak load
      Given 1,000 members are opening the points page concurrently
      Then the p95 server response time stays under 1 second
      And no request returns an error

    Scenario: Points page shows the current balance, not a stale cached one
      Given Priya has a balance of 100 points
      And Priya opened the points page 1 minute ago
      When Priya places an order with a subtotal of $50.00
      And Priya opens the points page again
      Then the balance shown is 150 points

  # ---------------------------------------------------------------
  Rule: Points page content and accessibility

    Scenario: Points page shows balance, tier and progress to the next tier
      Given Priya has a balance of 350 points
      When Priya opens the points page
      Then the page shows:
        | balance       | 350 points                 |
        | tier          | Basic                      |
        | next tier     | 150 points to reach Silver |
        | tier benefit  | Silver members get 5% off  |

    Scenario: Gold members are not shown a next tier
      Given Priya has a balance of 2000 points
      When Priya opens the points page
      Then the page shows tier "Gold"
      And no "points to reach" message is shown

    Scenario: Points page is only accessible to signed-in members
      Given a shopper is not signed in
      When the shopper navigates to the points page URL
      Then the shopper is redirected to sign in
      And after signing in as a member, the shopper lands on the points page

    Scenario: Points page is keyboard navigable and screen-reader friendly
      When Priya opens the points page
      Then every interactive element is reachable by keyboard in a logical order
      And the balance has an accessible name including "points balance"
      And the page passes WCAG 2.2 AA automated checks with no violations
```

---

## Open questions for the Product Owner

1. **Tier basis (A3)**: Is the tier based on current balance, or on points earned in a rolling 12 months? The current wording lets a member lose Silver by redeeming, which is unusual and worth confirming.
2. **Redemption rate (A5)**: The story never says what a point is worth. Every redemption scenario depends on this.
3. **AC-4 target**: "Fast" is untestable as written. The numbers in A8 are placeholders and need a real SLO, device profile and load level.
4. **Earning on discounted subtotal (A6)**: Should points be earned on the amount before or after the tier discount and redemption? The scenarios assume before.
5. **Timing of credit (A2)**: Should points be available immediately on placement, or held until the return window closes?
