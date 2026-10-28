# LOY-3 Loyalty points — BDD scenarios

## Assumptions

- **A1 Rounding:** points are the subtotal rounded down to the whole dollar (per the $24.99 example). Subtotal is pre-tax, pre-shipping, after item-level promotions, before the tier discount.
- **A2 Tier basis:** tier is derived from the member's current points balance, read literally from AC-2. If the business intends lifetime earned points, the "tier after redemption" scenarios below invert.
- **A3 Redemption rate:** 100 points = $1.00 off, points must be redeemed in whole-point amounts, and a redemption cannot exceed the order total. Not stated in the story.
- **A4 Discount order:** the tier discount is applied to the subtotal first, then redeemed points are deducted. Points are earned on the subtotal before either deduction.
- **A5 Tier timing:** a tier change takes effect on the next order, not retroactively on the order that crossed the threshold.
- **A6 Earning timing:** points are credited when the order is placed, and reversed in full if the order is cancelled or fully refunded.
- **A7 "Fast" (AC-4):** interpreted as p95 page load under 2 seconds and first contentful paint under 1 second for a member with up to 1,000 points-history entries, measured on the staging environment. Needs product sign-off.
- **A8 Non-members** neither earn nor redeem points and see no tier discount.

```gherkin
Feature: Earning loyalty points (AC-1)
  As a member of the loyalty programme
  I want to earn points on my orders
  So that I can get discounts on later orders

  Background:
    Given a loyalty member "Ada" with a points balance of 0

  Scenario Outline: Points equal the subtotal rounded down to the whole dollar
    When Ada places an order with a subtotal of <subtotal>
    Then Ada's points balance is <points>

    Examples: Whole and fractional dollars
      | subtotal | points |
      | $24.99   | 24     |
      | $25.00   | 25     |
      | $25.01   | 25     |
      | $1.00    | 1      |
      | $0.99    | 0      |
      | $0.00    | 0      |
      | $1000.50 | 1000   |

  Scenario: Points are calculated on the subtotal, not the grand total
    When Ada places an order with a subtotal of $40.00, tax of $3.20 and shipping of $5.99
    Then Ada's points balance is 40

  Scenario: Points accumulate across orders
    Given Ada has placed an order with a subtotal of $24.99
    When Ada places another order with a subtotal of $10.50
    Then Ada's points balance is 34

  Scenario: Points are earned on the subtotal before the tier discount is applied
    Given Ada's points balance is 600 and her tier is Silver
    When Ada places an order with a subtotal of $100.00
    Then the order total is $95.00
    And Ada earns 100 points for the order
    And Ada's points balance is 700

  Scenario: Points are earned on the subtotal before redeemed points are deducted
    Given Ada's points balance is 300
    When Ada places an order with a subtotal of $50.00 and redeems 200 points
    Then Ada earns 50 points for the order
    And Ada's points balance is 150

  Scenario: Points are reversed when an order is cancelled
    Given Ada has placed an order with a subtotal of $60.00
    And Ada's points balance is 60
    When that order is cancelled
    Then Ada's points balance is 0
    And the points page shows a history entry of "-60" for the cancellation

  Scenario: A guest checkout does not earn points
    Given a guest shopper who is not a loyalty member
    When the guest places an order with a subtotal of $80.00
    Then no points are awarded
    And the order confirmation does not mention loyalty points

  Scenario: Earned points appear in the points history
    When Ada places order "ORD-1001" with a subtotal of $24.99
    Then the points page shows a history entry of "+24" linked to order "ORD-1001"
```

```gherkin
Feature: Loyalty tiers and tier discounts (AC-2)
  As a loyalty member
  I want my tier to reflect my points
  So that I receive the right discount on every order

  Scenario Outline: Tier is determined by the points balance at the thresholds
    Given a loyalty member with a points balance of <balance>
    Then the member's tier is <tier>
    And the member's discount is <discount>

    Examples: Boundaries
      | balance | tier   | discount |
      | 0       | Basic  | 0%       |
      | 499     | Basic  | 0%       |
      | 500     | Silver | 5%       |
      | 1999    | Silver | 5%       |
      | 2000    | Gold   | 10%      |
      | 25000   | Gold   | 10%      |

  Scenario Outline: The tier discount is applied to the order subtotal
    Given a loyalty member whose tier is <tier>
    When the member places an order with a subtotal of $80.00, tax of $6.40 and shipping of $5.00
    Then the discount line on the order is <discount_amount>
    And the discount is applied to the subtotal only, not to tax or shipping

    Examples:
      | tier   | discount_amount |
      | Basic  | $0.00           |
      | Silver | $4.00           |
      | Gold   | $8.00           |

  Scenario: The tier discount rounds to the nearest cent
    Given a loyalty member whose tier is Silver
    When the member places an order with a subtotal of $24.99
    Then the discount line on the order is $1.25

  Scenario: A member is promoted when an order takes the balance to the threshold
    Given a loyalty member with a points balance of 480 and a tier of Basic
    When the member places an order with a subtotal of $20.00
    Then no tier discount is applied to that order
    And the member's points balance is 500
    And the member's tier is Silver
    And the next order receives a 5% discount

  Scenario: A member is promoted from Silver straight to Gold in one order
    Given a loyalty member with a points balance of 1900 and a tier of Silver
    When the member places an order with a subtotal of $150.00
    Then that order receives a 5% discount
    And the member's tier is Gold

  Scenario: A member is demoted when a redemption takes the balance below the threshold
    Given a loyalty member with a points balance of 500 and a tier of Silver
    When the member redeems 100 points
    Then the member's points balance is 400
    And the member's tier is Basic

  Scenario: A member is demoted when a cancellation takes the balance below the threshold
    Given a loyalty member with a points balance of 2010 and a tier of Gold
    And the member's most recent order earned 50 points
    When that order is cancelled
    Then the member's points balance is 1960
    And the member's tier is Silver

  Scenario: The tier discount is applied to the whole order, not only to eligible items
    Given a loyalty member whose tier is Gold
    When the member places an order containing three different products with a subtotal of $120.00
    Then the discount line on the order is $12.00

  Scenario: The points page shows the current tier and the points needed for the next tier
    Given a loyalty member with a points balance of 350
    When the member opens the points page
    Then the page shows the tier "Basic"
    And the page shows "150 points to Silver"

  Scenario: The points page shows no next tier for a Gold member
    Given a loyalty member with a points balance of 2500
    When the member opens the points page
    Then the page shows the tier "Gold"
    And the page does not show a "points to next tier" message
```

```gherkin
Feature: Redeeming loyalty points (AC-3)
  As a loyalty member
  I want to redeem my points at checkout
  So that I get a discount on my order

  Background:
    Given a loyalty member "Ada" with a points balance of 300
    And Ada is at checkout with an order subtotal of $50.00

  Scenario: Redeeming more points than the balance is rejected
    When Ada attempts to redeem 301 points
    Then the message "You don't have enough points." is shown
    And no points are deducted from Ada's balance
    And the order total is unchanged at $50.00

  Scenario: Redeeming far more points than the balance is rejected with the same message
    When Ada attempts to redeem 10000 points
    Then the message "You don't have enough points." is shown
    And Ada's points balance is 300

  Scenario: Redeeming exactly the balance succeeds
    When Ada redeems 300 points
    Then Ada's points balance is 0
    And the order total is $47.00

  Scenario: Redeeming fewer points than the balance succeeds
    When Ada redeems 200 points
    Then Ada's points balance is 100
    And the order total is $48.00

  Scenario: A member with no points cannot redeem
    Given Ada's points balance is 0
    When Ada attempts to redeem 1 point
    Then the message "You don't have enough points." is shown
    And Ada's points balance is 0

  Scenario: A failed redemption does not block the order
    When Ada attempts to redeem 500 points
    And the message "You don't have enough points." is shown
    And Ada completes the order without redeeming points
    Then the order is placed at $50.00
    And Ada's points balance is 350

  Scenario: A successful redemption is recorded in the points history
    When Ada redeems 200 points on order "ORD-2001"
    Then the points page shows a history entry of "-200" linked to order "ORD-2001"

  Scenario: Points are returned when an order with a redemption is cancelled
    Given Ada redeemed 200 points on order "ORD-2001"
    And Ada's points balance is 150
    When order "ORD-2001" is cancelled
    Then the 50 points earned on the order are reversed
    And the 200 redeemed points are returned
    And Ada's points balance is 300

  Scenario: The balance is re-checked when the order is placed, not only when the redemption is entered
    Given Ada has entered a redemption of 300 points at checkout
    And Ada's balance drops to 100 points in another session before the order is placed
    When Ada places the order
    Then the message "You don't have enough points." is shown
    And the order is not placed
    And Ada's points balance is 100

  Scenario: Two simultaneous redemptions cannot overdraw the balance
    Given Ada submits two orders at the same time, each redeeming 300 points
    When both orders are processed
    Then exactly one redemption succeeds
    And the other shows "You don't have enough points."
    And Ada's points balance is never below 0

  Scenario Outline: Invalid redemption amounts are rejected without touching the balance
    When Ada attempts to redeem <amount> points
    Then a validation message is shown
    And Ada's points balance is 300

    Examples:
      | amount |
      | 0      |
      | -50    |
      | 12.5   |
      | abc    |

  Scenario: A redemption cannot exceed the order total
    Given Ada's points balance is 6000
    And Ada is at checkout with an order subtotal of $50.00
    When Ada attempts to redeem 6000 points
    Then the redemption is capped at 5000 points
    And the order total is $0.00
    And Ada is told that 5000 points were applied

  Scenario: The tier discount is applied before redeemed points
    Given Ada's points balance is 700 and her tier is Silver
    And Ada is at checkout with an order subtotal of $100.00
    When Ada redeems 500 points
    Then the tier discount line is $5.00
    And the points discount line is $5.00
    And the order total is $90.00
```

```gherkin
Feature: Points page performance (AC-4)
  As a loyalty member
  I want the points page to load quickly
  So that checking my balance does not feel slow

  # Thresholds are assumption A7 and need product sign-off.

  Scenario: Points page loads within the agreed budget for a typical member
    Given a loyalty member with 50 entries in their points history
    When the member opens the points page
    Then the page is interactive within 2 seconds at the 95th percentile over 100 loads
    And first contentful paint occurs within 1 second at the 95th percentile

  Scenario: Points page loads within the agreed budget for a heavy member
    Given a loyalty member with 1000 entries in their points history
    When the member opens the points page
    Then the page is interactive within 2 seconds at the 95th percentile over 100 loads
    And the history is paginated or lazily loaded rather than fully rendered

  Scenario: Points page stays within budget under concurrent load
    Given 500 members open the points page within the same 10-second window
    Then the 95th percentile page load time is under 2 seconds
    And no request returns a server error

  Scenario: Balance and tier are shown before the history finishes loading
    Given a loyalty member whose points history is slow to load
    When the member opens the points page
    Then the balance and tier are visible within 1 second
    And a loading indicator is shown for the history section

  Scenario: Points page does not regress in the performance budget
    Given the points page performance test runs in CI
    When a change pushes the 95th percentile load time above 2 seconds
    Then the build fails
```

## Open questions for the product owner

- Confirm **A2**: should tier be based on current balance or lifetime earned points? Lifetime-based tiers mean redeeming never demotes a member, which is the more common loyalty pattern.
- Confirm **A3**: the points-to-currency rate and whether a redemption can zero out an order.
- Confirm **A7**: concrete numbers for "fast", the device and network profile to test on, and whether the budget applies to the API or the full page.
- Clarify whether partial refunds reverse points proportionally.
