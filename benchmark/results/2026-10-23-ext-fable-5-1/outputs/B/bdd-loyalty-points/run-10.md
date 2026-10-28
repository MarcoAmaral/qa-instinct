# LOY-3 Loyalty points — BDD scenarios

## Assumptions

The story leaves several points open. I have proceeded on the following assumptions; each is tagged in the scenarios where it applies.

| # | Assumption | Why it matters |
|---|---|---|
| A1 | Points are earned on the order **subtotal before** tier discount, redemption, tax and shipping. Points are credited when the order is placed. | Defines the base amount for AC-1. |
| A2 | Earned points are **floored** to the whole dollar (never rounded up). | AC-1 example implies floor; $24.99 → 24. |
| A3 | Tier is determined by **lifetime earned points**, not the spendable balance, so redeeming points does not demote a member. | AC-2 does not say which balance drives tier. Needs PO confirmation. |
| A4 | Tier is evaluated at the moment of checkout, using points **before** the current order's points are added. | Prevents an order "earning its own discount". |
| A5 | Tier discount applies to the subtotal, before tax and shipping. | AC-2 says "off every order" without a base. |
| A6 | Redemption rate is **100 points = $1.00**, redeemable in whole-point amounts on an order at checkout. | AC-3 covers failure only; the success path needs a rate. |
| A7 | Redeemed points are deducted when the order is placed. Cancellation/refund handling is **out of scope** for LOY-3. | Keeps scope bounded; flagged for a follow-up story. |
| A8 | "Load fast" (AC-4) is interpreted as: 95th-percentile server response under **2 seconds** for a member with up to 1,000 points-history entries, on the standard test environment. | AC-4 is not testable as written; the threshold must be agreed with the PO. |
| A9 | Non-members (guest checkout) earn no points and see no tier discount. | Story says "as a member". |

## Feature file

```gherkin
Feature: Loyalty points (LOY-3)
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given the loyalty programme is active
    And the redemption rate is 100 points per $1.00
    And the tier thresholds are:
      | tier   | from_points | discount |
      | Basic  | 0           | 0%       |
      | Silver | 500         | 5%       |
      | Gold   | 2000        | 10%      |

  # ---------------------------------------------------------------
  # AC-1: earning points
  # ---------------------------------------------------------------

  @AC-1 @happy-path
  Scenario Outline: Member earns one point per whole dollar of subtotal
    Given a logged-in member with a points balance of 0
    When the member places an order with a subtotal of <subtotal>
    Then the member's points balance is <points>

    Examples: Whole-dollar flooring
      | subtotal | points |
      | $24.99   | 24     |
      | $25.00   | 25     |
      | $25.01   | 25     |
      | $1.00    | 1      |
      | $0.99    | 0      |
      | $0.00    | 0      |
      | $1234.56 | 1234   |

  @AC-1
  Scenario: Points accumulate across multiple orders
    Given a logged-in member with a points balance of 24
    When the member places an order with a subtotal of $10.50
    Then the member's points balance is 34

  @AC-1 @assumption-A1
  Scenario: Points are calculated on the subtotal, not the discounted or taxed total
    Given a logged-in member in the Silver tier with a points balance of 600
    When the member places an order with:
      | subtotal | tier_discount | tax   | shipping | total  |
      | $100.00  | -$5.00        | $7.60 | $4.99    | $107.59|
    Then the member earns 100 points
    And the member's points balance is 700

  @AC-1 @assumption-A1
  Scenario: Points earned are not reduced by points redeemed on the same order
    Given a logged-in member with a points balance of 500
    When the member places an order with a subtotal of $40.00
    And redeems 1000 points worth $10.00 against that order
    Then the member earns 40 points for the order
    And the member's points balance is 40

  @AC-1 @assumption-A9
  Scenario: Guest checkout earns no points
    Given a guest shopper who is not logged in
    When the guest places an order with a subtotal of $50.00
    Then no loyalty points are awarded
    And no loyalty account is created

  @AC-1
  Scenario: Earned points are visible on the points page after ordering
    Given a logged-in member with a points balance of 0
    When the member places an order with a subtotal of $24.99
    And the member opens the points page
    Then the points page shows a balance of 24
    And the points history lists an entry of "+24" linked to that order

  # ---------------------------------------------------------------
  # AC-2: tiers and tier discounts
  # ---------------------------------------------------------------

  @AC-2 @boundary @assumption-A3
  Scenario Outline: Tier is determined by lifetime earned points at the boundaries
    Given a logged-in member with <lifetime_points> lifetime earned points
    When the member opens the points page
    Then the member's tier is shown as "<tier>"

    Examples:
      | lifetime_points | tier   |
      | 0               | Basic  |
      | 499             | Basic  |
      | 500             | Silver |
      | 1999            | Silver |
      | 2000            | Gold   |
      | 50000           | Gold   |

  @AC-2 @happy-path @assumption-A5
  Scenario Outline: Tier discount is applied to the order subtotal at checkout
    Given a logged-in member in the "<tier>" tier
    When the member proceeds to checkout with a subtotal of $80.00
    Then a tier discount of <discount_amount> is shown on the order summary
    And the discounted subtotal is <discounted_subtotal>

    Examples:
      | tier   | discount_amount | discounted_subtotal |
      | Basic  | $0.00           | $80.00              |
      | Silver | $4.00           | $76.00              |
      | Gold   | $8.00           | $72.00              |

  @AC-2 @rounding
  Scenario Outline: Tier discount is rounded to the nearest cent
    Given a logged-in member in the "<tier>" tier
    When the member proceeds to checkout with a subtotal of <subtotal>
    Then a tier discount of <discount_amount> is shown on the order summary

    Examples:
      | tier   | subtotal | discount_amount |
      | Silver | $24.99   | $1.25           |
      | Silver | $0.10    | $0.01           |
      | Gold   | $24.99   | $2.50           |
      | Gold   | $0.05    | $0.01           |

  @AC-2 @assumption-A4
  Scenario: The order that crosses a tier threshold does not receive the new tier's discount
    Given a logged-in member with 490 lifetime earned points in the Basic tier
    When the member places an order with a subtotal of $20.00
    Then no tier discount is applied to that order
    And the member earns 20 points
    And the member's tier is now "Silver"

  @AC-2
  Scenario: The next order after reaching a tier receives the discount
    Given a logged-in member who has just reached 510 lifetime earned points
    When the member proceeds to checkout with a subtotal of $100.00
    Then a tier discount of $5.00 is shown on the order summary

  @AC-2 @assumption-A3
  Scenario: Redeeming points does not lower the member's tier
    Given a logged-in member with 2000 lifetime earned points and a spendable balance of 2000
    When the member redeems 1500 points on an order
    Then the member's spendable balance is 500
    And the member's tier remains "Gold"
    And the member's next order receives a 10% tier discount

  @AC-2
  Scenario: Only the highest earned tier discount applies, never both
    Given a logged-in member in the "Gold" tier
    When the member proceeds to checkout with a subtotal of $100.00
    Then exactly one tier discount line is shown, for $10.00
    And no Silver discount line is shown

  @AC-2
  Scenario: Tier discount is applied before tax is calculated
    Given a logged-in member in the "Silver" tier
    And the applicable tax rate is 10%
    When the member proceeds to checkout with a subtotal of $100.00
    Then the order summary shows:
      | subtotal      | $100.00 |
      | tier discount | -$5.00  |
      | tax           | $9.50   |

  @AC-2 @assumption-A9
  Scenario: Guest checkout receives no tier discount
    Given a guest shopper who is not logged in
    When the guest proceeds to checkout with a subtotal of $100.00
    Then no tier discount line is shown on the order summary

  # ---------------------------------------------------------------
  # AC-3: redeeming points
  # ---------------------------------------------------------------

  @AC-3 @happy-path @assumption-A6
  Scenario: Member redeems points within their balance
    Given a logged-in member with a points balance of 1200
    And the member is at checkout with a subtotal of $50.00
    When the member redeems 1000 points
    Then a points discount of $10.00 is shown on the order summary
    And the order total is reduced by $10.00
    When the member places the order
    Then the member's points balance is 240
    And the points history lists an entry of "-1000" linked to that order

  @AC-3 @boundary
  Scenario: Member redeems exactly their full balance
    Given a logged-in member with a points balance of 500
    And the member is at checkout with a subtotal of $50.00
    When the member redeems 500 points
    Then a points discount of $5.00 is shown on the order summary
    And no error message is shown
    When the member places the order
    Then the member's points balance is 0

  @AC-3 @negative
  Scenario: Redeeming one point more than the balance is rejected
    Given a logged-in member with a points balance of 500
    And the member is at checkout with a subtotal of $50.00
    When the member attempts to redeem 501 points
    Then the message "You don't have enough points." is shown
    And no points discount is applied to the order
    And the order total is unchanged
    And the member's points balance remains 500

  @AC-3 @negative
  Scenario: Redeeming with a zero balance is rejected
    Given a logged-in member with a points balance of 0
    And the member is at checkout with a subtotal of $50.00
    When the member attempts to redeem 100 points
    Then the message "You don't have enough points." is shown
    And no points discount is applied to the order
    And the member's points balance remains 0

  @AC-3 @negative
  Scenario: Failed redemption leaves no partial deduction and no history entry
    Given a logged-in member with a points balance of 300
    And the member is at checkout with a subtotal of $50.00
    When the member attempts to redeem 1000 points
    Then the message "You don't have enough points." is shown
    And the member's points balance remains 300
    And no redemption entry is added to the points history

  @AC-3
  Scenario: Member can correct the amount after an insufficient-points error
    Given a logged-in member with a points balance of 300
    And the member is at checkout with a subtotal of $50.00
    And the member has attempted to redeem 1000 points and seen "You don't have enough points."
    When the member changes the redemption amount to 300 points
    Then the error message is cleared
    And a points discount of $3.00 is shown on the order summary

  @AC-3 @concurrency
  Scenario: Balance is re-validated at order placement, not only at entry
    Given a logged-in member with a points balance of 500
    And the member has entered a redemption of 500 points at checkout in one browser tab
    And the member has placed a separate order redeeming 500 points in another tab
    When the member places the order in the first tab
    Then the message "You don't have enough points." is shown
    And the order is not placed with a points discount
    And the member's points balance remains 0

  @AC-3 @validation
  Scenario Outline: Invalid redemption amounts are rejected without changing the balance
    Given a logged-in member with a points balance of 500
    And the member is at checkout with a subtotal of $50.00
    When the member attempts to redeem "<amount>" points
    Then a validation error is shown
    And no points discount is applied to the order
    And the member's points balance remains 500

    Examples:
      | amount |
      | 0      |
      | -100   |
      | 12.5   |
      | abc    |

  @AC-3
  Scenario: Points discount cannot exceed the order amount after tier discount
    Given a logged-in member in the "Basic" tier with a points balance of 10000
    And the member is at checkout with a subtotal of $30.00
    When the member attempts to redeem 5000 points
    Then the member is told the maximum redeemable on this order is 3000 points
    And no points discount is applied until a valid amount is entered

  @AC-2 @AC-3
  Scenario: Tier discount and points redemption combine on the same order
    Given a logged-in member in the "Silver" tier with a points balance of 1000
    When the member proceeds to checkout with a subtotal of $100.00
    And redeems 1000 points
    Then the order summary shows:
      | subtotal        | $100.00 |
      | tier discount   | -$5.00  |
      | points discount | -$10.00 |
      | total           | $85.00  |

  @AC-3 @security
  Scenario: Redemption request for another member's account is rejected
    Given a logged-in member "Alice" with a points balance of 1000
    And another member "Bob" with a points balance of 5000
    When "Alice" submits a redemption request referencing "Bob"'s loyalty account
    Then the request is rejected with an authorisation error
    And "Bob"'s points balance remains 5000
    And "Alice"'s points balance remains 1000

  # ---------------------------------------------------------------
  # AC-4: points page performance
  # ---------------------------------------------------------------

  @AC-4 @non-functional @assumption-A8
  Scenario: Points page loads within the agreed threshold for a typical member
    Given a logged-in member with 50 entries in their points history
    When the member requests the points page 100 times under normal load
    Then the 95th-percentile server response time is under 2 seconds
    And every response returns the correct balance and tier

  @AC-4 @non-functional @assumption-A8
  Scenario: Points page loads within the agreed threshold for a heavy member
    Given a logged-in member with 1000 entries in their points history
    When the member requests the points page 100 times under normal load
    Then the 95th-percentile server response time is under 2 seconds

  @AC-4 @non-functional
  Scenario: Points page remains responsive when the history is paginated
    Given a logged-in member with 1000 entries in their points history
    When the member opens the points page
    Then the balance and tier are rendered before the full history is loaded
    And the history is paginated or lazily loaded rather than rendered in full

  # ---------------------------------------------------------------
  # Points page content
  # ---------------------------------------------------------------

  @points-page
  Scenario: Points page shows balance, tier and progress to the next tier
    Given a logged-in member with 650 lifetime earned points and a spendable balance of 650
    When the member opens the points page
    Then the page shows a balance of 650
    And the page shows the tier "Silver"
    And the page shows 1350 points needed to reach "Gold"

  @points-page
  Scenario: Gold member sees no next-tier progress
    Given a logged-in member with 2500 lifetime earned points
    When the member opens the points page
    Then the page shows the tier "Gold"
    And no "points to next tier" message is shown

  @points-page @security
  Scenario: Points page requires authentication
    Given a shopper who is not logged in
    When the shopper requests the points page
    Then the shopper is redirected to the login page
    And no loyalty data is returned
```

## Open questions for the Product Owner

These do not block testing but each assumption above would change expected results if answered differently.

1. **Tier basis (A3):** lifetime earned points or current spendable balance? If the latter, the "redeeming does not lower tier" scenario inverts.
2. **Redemption rate (A6):** 100 points per $1 is a placeholder. Any minimum redemption (for example, 100-point blocks)?
3. **Order crossing a threshold (A4):** confirm the crossing order does not earn its own discount.
4. **Earning base (A1):** confirm points are on the pre-discount subtotal. If points are earned on the post-discount amount, Silver and Gold members earn fewer points.
5. **AC-4 threshold (A8):** "fast" needs a number, a percentile and a data volume. 2 seconds at p95 with 1,000 history entries is proposed.
6. **Refunds and cancellations (A7):** should earned points be clawed back and redeemed points returned? Recommend a separate story.
7. **Expiry:** do points expire? Not mentioned; assumed no expiry.
