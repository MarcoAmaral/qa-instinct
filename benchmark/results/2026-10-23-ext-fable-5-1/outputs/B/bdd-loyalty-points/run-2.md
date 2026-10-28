# LOY-3 Loyalty points: BDD scenarios

## Assumptions

The story leaves several things unspecified. The scenarios below are written against these assumptions, and each is flagged for the product owner to confirm.

| # | Gap | Assumption used |
|---|-----|-----------------|
| A1 | Tier basis: current balance or lifetime earned? | Tier is based on **lifetime points earned**. Redeeming points never demotes a member. |
| A2 | Rounding of fractional dollars | Always round **down** to the whole dollar (AC-1 example implies floor). $0.99 earns 0 points. |
| A3 | Subtotal basis for earning | Points are earned on the subtotal **before** tier discount, redemption and tax/shipping. |
| A4 | Cash value of a redeemed point | 100 points = $1.00. Redemption is in whole points, minimum 1. |
| A5 | When points are credited | On order **completion** (payment captured), not on checkout. Cancelled or refunded orders reverse the credit. |
| A6 | Redemption cap | A member cannot redeem more than the order total. The remaining balance stays on the account. |
| A7 | Discount stacking | Tier discount applies to the subtotal first, then redeemed points are deducted. |
| A8 | "Load fast" (AC-4) | Points page p95 response time ≤ 2 s and first contentful paint ≤ 1.5 s, measured with a member holding 10,000 points-ledger entries. |
| A9 | Points expiry | Points do not expire. Out of scope for this story. |

## Feature file

```gherkin
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given the loyalty programme is active
    And 100 points are worth $1.00 when redeemed

  # ---------------------------------------------------------------
  # AC-1: Earning points
  # ---------------------------------------------------------------

  @AC-1 @happy-path
  Scenario: Member earns one point per whole dollar of subtotal
    Given "Ana" is a loyalty member with a balance of 0 points
    When Ana completes an order with a subtotal of $24.99
    Then Ana's balance is 24 points
    And Ana's points ledger shows "+24 points" linked to that order

  @AC-1 @boundary
  Scenario Outline: Fractional dollars are rounded down
    Given "Ana" is a loyalty member with a balance of 0 points
    When Ana completes an order with a subtotal of <subtotal>
    Then Ana's balance is <points> points

    Examples:
      | subtotal  | points |
      | $0.00     | 0      |
      | $0.99     | 0      |
      | $1.00     | 1      |
      | $1.01     | 1      |
      | $24.99    | 24     |
      | $25.00    | 25     |
      | $1,234.56 | 1234   |

  @AC-1 @assumption-A3
  Scenario: Points are calculated on the subtotal, not the amount paid
    Given "Ana" is a loyalty member with a balance of 0 points
    When Ana completes an order with a subtotal of $100.00
    And tax of $8.00 and shipping of $5.99 are added
    Then Ana's balance is 100 points

  @AC-1 @assumption-A3
  Scenario: Tier discount does not reduce points earned
    Given "Gus" is a Gold member with a balance of 2,000 points
    When Gus completes an order with a subtotal of $100.00
    And a 10% tier discount reduces the amount paid to $90.00
    Then Gus earns 100 points for the order

  @AC-1 @assumption-A3
  Scenario: Redeeming points on an order does not reduce points earned
    Given "Ana" is a loyalty member with a balance of 500 points
    When Ana completes an order with a subtotal of $50.00
    And Ana redeems 500 points on that order
    Then Ana earns 50 points for the order
    And Ana's balance is 50 points

  @AC-1
  Scenario: Points accumulate across orders
    Given "Ana" is a loyalty member with a balance of 10 points
    When Ana completes an order with a subtotal of $30.50
    And Ana completes an order with a subtotal of $19.99
    Then Ana's balance is 59 points

  @AC-1 @assumption-A5
  Scenario: Points are credited on order completion, not at checkout
    Given "Ana" is a loyalty member with a balance of 0 points
    When Ana places an order with a subtotal of $40.00
    And the payment has not yet been captured
    Then Ana's balance is 0 points
    When the payment is captured and the order is completed
    Then Ana's balance is 40 points

  @AC-1 @assumption-A5
  Scenario: Cancelled order reverses earned points
    Given "Ana" is a loyalty member with a balance of 0 points
    And Ana completed an order with a subtotal of $40.00
    And Ana's balance is 40 points
    When that order is cancelled and fully refunded
    Then Ana's balance is 0 points
    And Ana's points ledger shows "-40 points" linked to that order

  @AC-1 @negative
  Scenario: Guest checkout earns no points
    Given a guest shopper who is not a loyalty member
    When the guest completes an order with a subtotal of $24.99
    Then no loyalty points are awarded
    And no loyalty balance is created for the guest

  @AC-1 @idempotency
  Scenario: Points are credited exactly once per order
    Given "Ana" is a loyalty member with a balance of 0 points
    When Ana completes an order with a subtotal of $24.99
    And the order-completed event is delivered a second time
    Then Ana's balance is 24 points

  # ---------------------------------------------------------------
  # AC-2: Tiers and tier discounts
  # ---------------------------------------------------------------

  @AC-2 @boundary
  Scenario Outline: Tier is determined by points thresholds
    Given "Ana" is a loyalty member with <points> lifetime points earned
    When Ana views the points page
    Then Ana's tier is shown as "<tier>"

    Examples:
      | points | tier   |
      | 0      | Basic  |
      | 499    | Basic  |
      | 500    | Silver |
      | 1999   | Silver |
      | 2000   | Gold   |
      | 50000  | Gold   |

  @AC-2 @boundary
  Scenario Outline: Tier discount is applied to the order subtotal
    Given "Ana" is a <tier> member
    When Ana places an order with a subtotal of $100.00
    Then a tier discount of <discount> is applied
    And the discounted subtotal is <discounted>

    Examples:
      | tier   | discount | discounted |
      | Basic  | $0.00    | $100.00    |
      | Silver | $5.00    | $95.00     |
      | Gold   | $10.00   | $90.00     |

  @AC-2
  Scenario: Tier discount rounds to the nearest cent
    Given "Ana" is a Silver member
    When Ana places an order with a subtotal of $24.99
    Then a tier discount of $1.25 is applied
    And the discounted subtotal is $23.74

  @AC-2
  Scenario: Member is promoted to Silver immediately on reaching 500 points
    Given "Ana" is a Basic member with 480 lifetime points earned
    When Ana completes an order with a subtotal of $20.00
    Then Ana's lifetime points earned is 500
    And Ana's tier is "Silver"
    When Ana places her next order with a subtotal of $100.00
    Then a tier discount of $5.00 is applied

  @AC-2
  Scenario: Promotion does not retroactively discount the promoting order
    Given "Ana" is a Basic member with 480 lifetime points earned
    When Ana completes an order with a subtotal of $20.00
    Then no tier discount is applied to that order
    And Ana's tier is "Silver" after the order completes

  @AC-2
  Scenario: Member is promoted to Gold immediately on reaching 2,000 points
    Given "Ana" is a Silver member with 1,950 lifetime points earned
    When Ana completes an order with a subtotal of $50.00
    Then Ana's tier is "Gold"

  @AC-2 @assumption-A1
  Scenario: Redeeming points does not demote the member
    Given "Gus" is a Gold member with 2,000 lifetime points earned
    And Gus has a balance of 2,000 points
    When Gus redeems 1,500 points on an order
    Then Gus's balance is 500 points
    And Gus's tier is still "Gold"

  @AC-2 @assumption-A5
  Scenario: Refund that drops lifetime points below a threshold demotes the member
    Given "Ana" is a Silver member with 500 lifetime points earned
    When an order worth 40 points is cancelled and fully refunded
    Then Ana's lifetime points earned is 460
    And Ana's tier is "Basic"

  @AC-2 @assumption-A7
  Scenario: Tier discount and point redemption stack in a fixed order
    Given "Gus" is a Gold member with a balance of 1,000 points
    When Gus places an order with a subtotal of $100.00
    And Gus redeems 1,000 points on that order
    Then the 10% tier discount is applied first, giving $90.00
    And the 1,000 points are deducted as $10.00
    And the amount payable is $80.00

  @AC-2 @ui
  Scenario: Tier discount is visible as a separate line at checkout
    Given "Ana" is a Silver member
    When Ana views the order summary for a subtotal of $100.00
    Then the summary shows a line "Silver member discount (5%)  -$5.00"

  @AC-2 @ui
  Scenario: Points page shows progress to the next tier
    Given "Ana" is a Basic member with 350 lifetime points earned
    When Ana views the points page
    Then the page shows "150 points to Silver"

  @AC-2 @ui
  Scenario: Gold member sees no next-tier progress
    Given "Gus" is a Gold member
    When Gus views the points page
    Then the page does not show a progress-to-next-tier message

  # ---------------------------------------------------------------
  # AC-3: Redeeming points
  # ---------------------------------------------------------------

  @AC-3 @happy-path
  Scenario: Member redeems part of their balance
    Given "Ana" is a loyalty member with a balance of 1,000 points
    When Ana places an order with a subtotal of $50.00
    And Ana redeems 400 points on that order
    Then the amount payable is $46.00
    And Ana's balance is 600 points
    And Ana's points ledger shows "-400 points" linked to that order

  @AC-3 @boundary
  Scenario: Member redeems exactly their full balance
    Given "Ana" is a loyalty member with a balance of 1,000 points
    When Ana places an order with a subtotal of $50.00
    And Ana redeems 1,000 points on that order
    Then the amount payable is $40.00
    And Ana's balance is 0 points

  @AC-3 @boundary @negative
  Scenario: Redeeming one point more than the balance is rejected
    Given "Ana" is a loyalty member with a balance of 1,000 points
    When Ana places an order with a subtotal of $50.00
    And Ana attempts to redeem 1,001 points on that order
    Then the message "You don't have enough points." is shown
    And no points are deducted
    And Ana's balance is 1,000 points
    And the amount payable is $50.00

  @AC-3 @negative
  Scenario: Redeeming with a zero balance is rejected
    Given "Ana" is a loyalty member with a balance of 0 points
    When Ana attempts to redeem 1 point on an order
    Then the message "You don't have enough points." is shown
    And Ana's balance is 0 points

  @AC-3 @negative
  Scenario: Redeeming far more than the balance is rejected with the same message
    Given "Ana" is a loyalty member with a balance of 50 points
    When Ana attempts to redeem 999,999 points on an order
    Then the message "You don't have enough points." is shown
    And Ana's balance is 50 points

  @AC-3 @negative
  Scenario: Failed redemption does not leave a partial deduction
    Given "Ana" is a loyalty member with a balance of 1,000 points
    When Ana attempts to redeem 1,500 points on an order
    Then the message "You don't have enough points." is shown
    And Ana's points ledger has no new entry for that attempt

  @AC-3 @negative
  Scenario: Message text is exact
    Given "Ana" is a loyalty member with a balance of 10 points
    When Ana attempts to redeem 20 points on an order
    Then the message shown is exactly "You don't have enough points."

  @AC-3 @validation
  Scenario Outline: Invalid redemption amounts are rejected with a validation error
    Given "Ana" is a loyalty member with a balance of 1,000 points
    When Ana attempts to redeem <input> points on an order
    Then a validation error is shown
    And the message "You don't have enough points." is not shown
    And Ana's balance is 1,000 points

    Examples:
      | input |
      | 0     |
      | -100  |
      | 10.5  |
      | abc   |
      |       |

  @AC-3 @assumption-A6
  Scenario: Redemption cannot exceed the order total
    Given "Ana" is a loyalty member with a balance of 10,000 points
    When Ana places an order with a subtotal of $20.00
    And Ana attempts to redeem 5,000 points on that order
    Then the message "You can redeem up to 2,000 points on this order." is shown
    And no points are deducted

  @AC-3 @concurrency
  Scenario: Concurrent redemptions cannot overdraw the balance
    Given "Ana" is a loyalty member with a balance of 1,000 points
    When Ana submits two orders at the same time, each redeeming 800 points
    Then exactly one redemption succeeds
    And the other shows "You don't have enough points."
    And Ana's balance is 200 points

  @AC-3 @assumption-A5
  Scenario: Cancelling an order with redeemed points restores them
    Given "Ana" is a loyalty member with a balance of 600 points
    And Ana completed an order on which she redeemed 400 points
    When that order is cancelled and fully refunded
    Then Ana's balance is 1,000 points

  @AC-3
  Scenario: Member can remove a redemption before paying
    Given "Ana" is a loyalty member with a balance of 1,000 points
    And Ana has applied 400 points to an order with a subtotal of $50.00
    When Ana removes the points redemption
    Then the amount payable is $50.00
    And Ana's balance is 1,000 points

  @AC-3 @ui
  Scenario: Checkout shows available points and their cash value
    Given "Ana" is a loyalty member with a balance of 1,250 points
    When Ana views the redemption section at checkout
    Then the section shows "You have 1,250 points (worth $12.50)"

  # ---------------------------------------------------------------
  # AC-4: Points page performance
  # ---------------------------------------------------------------

  @AC-4 @performance @assumption-A8
  Scenario: Points page loads within the performance budget for a typical member
    Given "Ana" is a loyalty member with 50 points-ledger entries
    When the points page is requested 100 times under normal load
    Then the 95th percentile server response time is at most 2 seconds
    And the 95th percentile first contentful paint is at most 1.5 seconds

  @AC-4 @performance @assumption-A8
  Scenario: Points page loads within budget for a member with a large ledger
    Given "Gus" is a loyalty member with 10,000 points-ledger entries
    When Gus requests the points page
    Then the server response time is at most 2 seconds
    And the ledger is paginated with at most 50 entries per page

  @AC-4 @performance
  Scenario: Points page shows balance and tier before the ledger finishes loading
    Given "Gus" is a loyalty member with 10,000 points-ledger entries
    When Gus requests the points page
    Then the balance and tier are visible within 1 second
    And the ledger loads without blocking the rest of the page

  @AC-4 @performance
  Scenario: Points page stays within budget under concurrent load
    Given 500 members request the points page within the same 10-second window
    Then the 95th percentile response time is at most 2 seconds
    And no request returns an error

  # ---------------------------------------------------------------
  # Cross-cutting
  # ---------------------------------------------------------------

  @access-control
  Scenario: Member cannot view another member's points
    Given "Ana" and "Gus" are loyalty members
    And Ana is signed in
    When Ana requests the points page for Gus's account
    Then access is denied
    And none of Gus's points data is returned

  @access-control
  Scenario: Signed-out user is redirected from the points page
    Given a visitor who is not signed in
    When the visitor requests the points page
    Then the visitor is redirected to sign in

  @ui
  Scenario: Points page shows balance, tier and recent activity
    Given "Ana" is a Silver member with a balance of 640 points
    And Ana earned 24 points on an order yesterday
    And Ana redeemed 100 points on an order last week
    When Ana views the points page
    Then the page shows a balance of "640 points"
    And the page shows the tier "Silver"
    And the activity list shows "+24 points" for yesterday's order
    And the activity list shows "-100 points" for last week's order
```

## Open questions for the product owner

1. **Tier basis (A1).** If tier should instead follow the current balance, the "redeeming does not demote" scenario inverts and members could lose their discount by spending points. This materially changes the design.
2. **Point value (A4).** 100 points = $1 is a placeholder. Confirm the exchange rate before the redemption scenarios are automated.
3. **Earning basis (A3).** Confirm whether points are earned on the pre-discount subtotal or on the amount actually paid. The latter would make Gold members earn fewer points per dollar than Basic members.
4. **AC-4 target (A8).** "Fast" is not testable as written. The 2 s / 1.5 s budgets are proposed values and should be agreed before the performance scenarios are used as a release gate.
5. **Refund handling (A5).** Partial refunds are not covered. Confirm whether points are reversed proportionally.
