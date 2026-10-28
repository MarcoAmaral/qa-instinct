# LOY-3 Loyalty points — BDD scenarios

## Assumptions

The story leaves several points open. Scenarios below use these assumptions; each is marked with its ID where it applies.

| ID | Assumption |
|----|------------|
| A1 | Points are earned on the order subtotal **before** tier discount, tax and shipping, rounded **down** to the whole dollar. |
| A2 | Points are credited when the order is placed and paid. Cancelled or refunded orders are out of scope for this story. |
| A3 | Tier is derived from the member's **current points balance**, so redeeming points can lower the tier. (If tier should be based on lifetime points earned, the "tier after redemption" scenarios change.) |
| A4 | Tier discount applies to the subtotal of every order, including the order that crosses the threshold only on the **next** order (points earned on an order do not change its own discount). |
| A5 | Redemption value is 100 points = $1.00 off, in whole-point amounts. Redemption is applied at checkout against the subtotal after tier discount. |
| A6 | Redeeming exactly the full balance is allowed. Redeeming zero or a negative number is a validation error, not a loyalty rule. |
| A7 | Non-members (guest checkout) earn no points and see no loyalty discount. |
| A8 | "Load fast" for AC-4 is interpreted as: 95th percentile server response ≤ 500 ms and page fully interactive ≤ 2 s on a standard broadband profile, for a member with up to 10,000 points transactions. **This needs product sign-off.** |
| A9 | Currency is USD; subtotals have at most two decimal places. |

## Feature file

```gherkin
@LOY-3 @loyalty
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given the loyalty programme is active
    And "Mia" is a registered loyalty member

  # ---------------------------------------------------------------
  # AC-1: Earning points
  # ---------------------------------------------------------------

  Rule: A member earns 1 point for every whole dollar of an order's subtotal

    @AC-1 @happy-path
    Scenario Outline: Points are earned on the whole-dollar part of the subtotal
      Given Mia has a points balance of 0
      When Mia places and pays for an order with a subtotal of <subtotal>
      Then Mia's points balance is <points>
      And the order confirmation shows "You earned <points> points"

      Examples: Worked example from the story
        | subtotal | points |
        | $24.99   | 24     |

      Examples: Boundaries and rounding
        | subtotal | points |
        | $0.99    | 0      |
        | $1.00    | 1      |
        | $1.01    | 1      |
        | $24.00   | 24     |
        | $24.01   | 24     |
        | $25.00   | 25     |
        | $999.99  | 999    |
        | $1000.00 | 1000   |

    @AC-1 @edge
    Scenario: A zero-subtotal order earns no points
      Given Mia has a points balance of 10
      When Mia places an order with a subtotal of $0.00
      Then Mia's points balance remains 10
      And the order confirmation does not show an "earned points" message

    @AC-1 @A1
    Scenario: Points are calculated on the subtotal, not the discounted or taxed total
      Given Mia is a Silver member with a points balance of 600
      When Mia places and pays for an order with:
        | subtotal         | $100.00 |
        | tier discount    | $5.00   |
        | tax              | $8.55   |
        | shipping         | $6.00   |
        | total charged    | $109.55 |
      Then Mia earns 100 points
      And Mia's points balance is 700

    @AC-1
    Scenario: Points accumulate across multiple orders
      Given Mia has a points balance of 30
      When Mia places and pays for an order with a subtotal of $45.50
      And Mia places and pays for an order with a subtotal of $10.99
      Then Mia's points balance is 85

    @AC-1 @A7 @negative
    Scenario: A guest checkout earns no points
      Given a shopper is not signed in to a loyalty account
      When the shopper places and pays for an order with a subtotal of $80.00
      Then no points are awarded
      And the order confirmation does not show an "earned points" message

    @AC-1 @A2 @negative
    Scenario: Points are not earned until payment succeeds
      Given Mia has a points balance of 0
      When Mia places an order with a subtotal of $50.00
      And the payment is declined
      Then Mia's points balance remains 0

  # ---------------------------------------------------------------
  # AC-2: Tiers and discounts
  # ---------------------------------------------------------------

  Rule: Tier is Basic below 500 points, Silver from 500 and Gold from 2,000

    @AC-2 @A3
    Scenario Outline: Tier is determined by points balance
      Given Mia has a points balance of <balance>
      When Mia views the points page
      Then Mia's tier is shown as "<tier>"

      Examples: Boundaries
        | balance | tier   |
        | 0       | Basic  |
        | 499     | Basic  |
        | 500     | Silver |
        | 501     | Silver |
        | 1999    | Silver |
        | 2000    | Gold   |
        | 2001    | Gold   |
        | 50000   | Gold   |

  Rule: Silver members get 5% off every order and Gold members 10%

    @AC-2 @happy-path
    Scenario Outline: Tier discount is applied to the order subtotal
      Given Mia has a points balance of <balance>
      When Mia adds items with a subtotal of $100.00 to the basket
      And Mia proceeds to checkout
      Then the checkout shows a loyalty discount of <discount>
      And the discounted subtotal is <discounted>

      Examples:
        | balance | discount | discounted |
        | 0       | $0.00    | $100.00    |
        | 499     | $0.00    | $100.00    |
        | 500     | $5.00    | $95.00     |
        | 1999    | $5.00    | $95.00     |
        | 2000    | $10.00   | $90.00     |

    @AC-2 @A9
    Scenario Outline: Tier discount is rounded to the nearest cent
      Given Mia is a <tier> member
      When Mia proceeds to checkout with a subtotal of <subtotal>
      Then the loyalty discount is <discount>

      Examples:
        | tier   | subtotal | discount |
        | Silver | $24.99   | $1.25    |
        | Silver | $0.10    | $0.01    |
        | Gold   | $24.99   | $2.50    |
        | Gold   | $0.05    | $0.01    |

    @AC-2 @A4
    Scenario: Crossing a tier threshold on an order takes effect on the next order
      Given Mia has a points balance of 480
      When Mia places and pays for an order with a subtotal of $30.00 and no discount
      Then Mia's points balance is 510
      And Mia's tier is "Silver"
      When Mia proceeds to checkout with a subtotal of $50.00
      Then the loyalty discount is $2.50

    @AC-2 @A3
    Scenario: Tier is upgraded from Silver to Gold when balance reaches 2,000
      Given Mia has a points balance of 1950
      And Mia's tier is "Silver"
      When Mia places and pays for an order with a subtotal of $60.00
      Then Mia's points balance is 2007
      And Mia's tier is "Gold"

    @AC-2 @A3
    Scenario: Tier is downgraded when redeeming drops the balance below a threshold
      Given Mia has a points balance of 2100
      And Mia's tier is "Gold"
      When Mia redeems 200 points at checkout
      Then Mia's points balance is 1900
      And Mia's tier is "Silver"

    @AC-2 @A7 @negative
    Scenario: A guest checkout receives no tier discount
      Given a shopper is not signed in to a loyalty account
      When the shopper proceeds to checkout with a subtotal of $100.00
      Then no loyalty discount is shown
      And the discounted subtotal is $100.00

    @AC-2
    Scenario: Tier discount is applied automatically without member action
      Given Mia is a Gold member
      When Mia proceeds to checkout with a subtotal of $40.00
      Then the loyalty discount of $4.00 is applied without entering a code
      And the discount line is labelled "Gold member discount (10%)"

  # ---------------------------------------------------------------
  # AC-3: Redeeming points
  # ---------------------------------------------------------------

  Rule: Redeeming more points than the balance redeems nothing

    @AC-3 @happy-path @A5
    Scenario: Redeeming points within the balance reduces the order total and the balance
      Given Mia has a points balance of 1000
      And Mia proceeds to checkout with a subtotal of $50.00
      When Mia redeems 500 points
      Then a redemption discount of $5.00 is applied to the order
      And Mia's points balance is 500
      And the order confirmation shows "500 points redeemed"

    @AC-3 @A6
    Scenario: Redeeming exactly the full balance is allowed
      Given Mia has a points balance of 300
      And Mia proceeds to checkout with a subtotal of $50.00
      When Mia redeems 300 points
      Then a redemption discount of $3.00 is applied to the order
      And Mia's points balance is 0

    @AC-3 @negative
    Scenario Outline: Redeeming more points than the balance shows an error and redeems nothing
      Given Mia has a points balance of <balance>
      And Mia proceeds to checkout with a subtotal of $50.00
      When Mia attempts to redeem <requested> points
      Then the message "You don't have enough points." is shown
      And no redemption discount is applied to the order
      And Mia's points balance remains <balance>

      Examples:
        | balance | requested |
        | 0       | 1         |
        | 300     | 301       |
        | 300     | 1000      |

    @AC-3 @negative
    Scenario: A failed redemption does not partially redeem the available balance
      Given Mia has a points balance of 300
      And Mia proceeds to checkout with a subtotal of $50.00
      When Mia attempts to redeem 500 points
      Then the message "You don't have enough points." is shown
      And the order total is unchanged at $50.00
      And Mia's points balance remains 300

    @AC-3 @negative
    Scenario: Member can retry with a valid amount after a failed redemption
      Given Mia has a points balance of 300
      And Mia proceeds to checkout with a subtotal of $50.00
      And Mia has attempted to redeem 500 points and seen "You don't have enough points."
      When Mia redeems 200 points
      Then the error message is no longer shown
      And a redemption discount of $2.00 is applied to the order
      And Mia's points balance is 100

    @AC-3 @A2 @negative
    Scenario: Points are not deducted if the order payment fails
      Given Mia has a points balance of 1000
      And Mia proceeds to checkout with a subtotal of $50.00
      And Mia redeems 500 points
      When the payment is declined
      Then Mia's points balance remains 1000

    @AC-3 @concurrency
    Scenario: Balance is checked at the moment of redemption, not when the page was loaded
      Given Mia has a points balance of 300
      And Mia has the checkout page open showing 300 points available
      And Mia's balance is reduced to 100 points in another session
      When Mia attempts to redeem 300 points
      Then the message "You don't have enough points." is shown
      And Mia's points balance remains 100

    @AC-3 @A6 @validation
    Scenario Outline: Invalid redemption amounts are rejected without changing the balance
      Given Mia has a points balance of 300
      And Mia proceeds to checkout
      When Mia attempts to redeem "<input>" points
      Then a validation message is shown
      And Mia's points balance remains 300

      Examples:
        | input |
        | 0     |
        | -50   |
        | 12.5  |
        | abc   |
        |       |

    @AC-3 @AC-2 @A5
    Scenario: Tier discount and redemption discount are both applied on the same order
      Given Mia has a points balance of 2500
      And Mia proceeds to checkout with a subtotal of $100.00
      Then the Gold member discount of $10.00 is applied
      When Mia redeems 1000 points
      Then a redemption discount of $10.00 is applied
      And the discounted subtotal is $80.00
      And Mia's points balance is 1500

  # ---------------------------------------------------------------
  # AC-4: Points page performance
  # ---------------------------------------------------------------

  Rule: The points page loads fast

    @AC-4 @A8 @non-functional
    Scenario: Points page loads within target for a typical member
      Given Mia has 50 points transactions in her history
      When Mia opens the points page
      Then the server responds within 500 ms at the 95th percentile over 100 requests
      And the page is interactive within 2 seconds on a standard broadband profile

    @AC-4 @A8 @non-functional @edge
    Scenario: Points page loads within target for a member with a large history
      Given Mia has 10,000 points transactions in her history
      When Mia opens the points page
      Then the server responds within 500 ms at the 95th percentile over 100 requests
      And the page is interactive within 2 seconds on a standard broadband profile

    @AC-4 @A8 @non-functional @load
    Scenario: Points page stays within target under concurrent load
      Given 200 members each open the points page concurrently
      Then the server responds within 500 ms at the 95th percentile
      And no request fails

    @AC-4
    Scenario: Points page shows the current balance and tier
      Given Mia has a points balance of 750
      When Mia opens the points page
      Then the page shows a balance of 750 points
      And the page shows the tier "Silver"
      And the page shows "1,250 points to Gold"
```

## Open questions for product

These do not block testing under the assumptions above, but the answers would change scenarios.

1. **Tier basis.** Is tier based on current balance (A3) or on lifetime points earned? If lifetime, redemption never downgrades a tier and the downgrade scenario is removed.
2. **Redemption rate.** What is the dollar value of a point (A5), and is there a minimum redemption or a cap per order?
3. **Points on refunds and cancellations.** Are earned points reversed? Are redeemed points returned?
4. **Earning on a redeemed order.** Are points earned on the subtotal before or after the redemption discount is applied? A1 assumes before.
5. **"Fast" definition.** AC-4 has no measurable target. A8 proposes one; it needs an owner to confirm or replace it, otherwise AC-4 cannot be marked pass or fail.
6. **Points expiry.** Do points expire? Nothing in the story covers this.
