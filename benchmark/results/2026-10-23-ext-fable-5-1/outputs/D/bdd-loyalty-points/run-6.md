# LOY-3 — Loyalty points: BDD scenarios

## Context discovery

The working directory is empty, so no code, routes, selectors or copy could be checked. Every step below is written from the ticket alone and is marked `@candidate` until confirmed against the real system.

## AC quality check (SMART)

| AC | Verdict | Note |
| --- | --- | --- |
| AC-1 | Pass | Specific, measurable, worked example given. Silent on whether the subtotal is taken before or after tier discount. |
| AC-2 | Pass with gap | Thresholds are clear. Silent on whether tier uses current balance or lifetime earned points, and whether tier discount applies to the order that crosses the threshold. |
| AC-3 | Pass | Exact message and outcome given. Silent on the redemption rate and on redeeming 0 points. |
| AC-4 | Fail | "Fast" is not measurable. Scenario below uses an assumed threshold and must be confirmed with the product owner. |

## Assumptions

1. Tier is derived from the **current points balance**, as the AC literally states, so redeeming points can lower a tier. Needs product owner confirmation.
2. Points are earned on the **subtotal before the tier discount**, tax and shipping.
3. Points are credited **when the order is confirmed**, not on delivery.
4. Redemption rate is **100 points = $1.00 off**, redeemed in whole-dollar amounts.
5. The tier discount is applied **first**, then redeemed points, and the total never goes below $0.00.
6. The tier shown at checkout is the tier **before** the current order's points are credited.
7. "Fast" for AC-4 means the points page is fully loaded **within 2 seconds** on a normal connection.
8. A member cannot redeem a negative number of points, and 0 points is rejected as "nothing to redeem".

## Feature file

```gherkin
@loyalty @candidate
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am signed in as a loyalty programme member

  # ---------- AC-1: earning ----------

  @smoke @p0 @earning
  Scenario: Points are earned per whole dollar of the subtotal
    Given my points balance is 0
    When I place an order with a subtotal of $24.99
    And the order is confirmed
    Then my points balance is 24

  @regression @p1 @earning
  Scenario Outline: Points round down to the whole dollar
    Given my points balance is 0
    When I place an order with a subtotal of $<subtotal>
    And the order is confirmed
    Then my points balance is <points>

    Examples:
      | subtotal | points |
      | 0.99     | 0      |
      | 1.00     | 1      |
      | 1.01     | 1      |
      | 24.99    | 24     |
      | 100.00   | 100    |
      | 100.50   | 100    |

  # Added by QA, the ticket does not say whether earning uses the pre- or post-discount subtotal (assumption 2)
  @regression @p1 @earning
  Scenario: Points are earned on the subtotal before the tier discount
    Given my points balance is 600
    And my tier is Silver
    When I place an order with a subtotal of $100.00
    And the order is confirmed
    Then the order total is $95.00
    And my points balance is 700

  # Added by QA, earned points must add to, not replace, the existing balance
  @regression @p1 @earning
  Scenario: Earned points are added to the existing balance
    Given my points balance is 150
    When I place an order with a subtotal of $50.00
    And the order is confirmed
    Then my points balance is 200

  # Added by QA, the ticket is silent on tax and shipping; assumption 2 excludes them
  @regression @p2 @earning
  Scenario: Tax and shipping do not earn points
    Given my points balance is 0
    When I place an order with a subtotal of $40.00, tax of $4.00 and shipping of $9.99
    And the order is confirmed
    Then my points balance is 40

  # ---------- AC-2: tiers ----------

  @smoke @p0 @tier
  Scenario Outline: Tier is determined by the points balance
    Given my points balance is <balance>
    When I open the points page
    Then my tier is shown as "<tier>"

    Examples:
      | balance | tier   |
      | 0       | Basic  |
      | 499     | Basic  |
      | 500     | Silver |
      | 1999    | Silver |
      | 2000    | Gold   |
      | 5000    | Gold   |

  @smoke @p0 @tier @discount
  Scenario Outline: Tier discount is applied to every order
    Given my points balance is <balance>
    And my tier is <tier>
    When I place an order with a subtotal of $100.00
    Then the tier discount shown is $<discount>
    And the order total is $<total>

    Examples:
      | balance | tier   | discount | total  |
      | 499     | Basic  | 0.00     | 100.00 |
      | 500     | Silver | 5.00     | 95.00  |
      | 2000    | Gold   | 10.00    | 90.00  |

  # Added by QA, crossing a threshold is the highest-risk boundary; assumption 6 says the new tier applies from the next order
  @regression @p1 @tier
  Scenario: Reaching 500 points upgrades the member to Silver for the next order
    Given my points balance is 480
    And my tier is Basic
    When I place an order with a subtotal of $20.00
    And the order is confirmed
    Then the order total is $20.00
    And my points balance is 500
    And my tier is shown as "Silver"

  # Added by QA, assumption 1 says tier follows the current balance; this scenario makes that decision visible
  @regression @p1 @tier
  Scenario: Redeeming points below a threshold lowers the tier
    Given my points balance is 2000
    And my tier is Gold
    When I redeem 100 points
    Then my points balance is 1900
    And my tier is shown as "Silver"

  # Added by QA, discount rounding is unspecified; checks half-cent handling
  @regression @p2 @discount
  Scenario Outline: Tier discount is rounded to the nearest cent
    Given my tier is <tier>
    When I place an order with a subtotal of $<subtotal>
    Then the tier discount shown is $<discount>

    Examples:
      | tier   | subtotal | discount |
      | Silver | 24.99    | 1.25     |
      | Silver | 0.10     | 0.01     |
      | Gold   | 24.99    | 2.50     |
      | Gold   | 0.05     | 0.01     |

  # ---------- AC-3 and redemption ----------

  @smoke @p0 @redeem
  Scenario: Redeeming more points than the balance is rejected
    Given my points balance is 100
    When I try to redeem 101 points
    Then I see the message "You don't have enough points."
    And my points balance is still 100
    And no discount is applied to the order

  @smoke @p0 @redeem
  Scenario: Redeeming the exact balance succeeds
    Given my points balance is 100
    When I redeem 100 points
    Then my points balance is 0
    And the points discount shown is $1.00

  # Added by QA, the ticket has no happy path for redemption; assumption 4 sets the rate
  @regression @p1 @redeem
  Scenario Outline: Redeemed points reduce the order total
    Given my points balance is <balance>
    And my tier is Basic
    When I place an order with a subtotal of $50.00
    And I redeem <redeem> points
    Then the points discount shown is $<discount>
    And the order total is $<total>
    And my points balance is <remaining>

    Examples:
      | balance | redeem | discount | total | remaining |
      | 100     | 100    | 1.00     | 49.00 | 0         |
      | 450     | 200    | 2.00     | 48.00 | 250       |
      | 450     | 400    | 4.00     | 46.00 | 50        |

  # Added by QA, invalid inputs are not covered by the ticket (assumption 8)
  @regression @p2 @redeem
  Scenario Outline: Invalid redemption amounts are rejected without changing the balance
    Given my points balance is 100
    When I try to redeem "<amount>" points
    Then I see the message "<message>"
    And my points balance is still 100

    Examples:
      | amount | message                             |
      | 0      | Enter a number of points to redeem. |
      | -10    | Enter a number of points to redeem. |
      | abc    | Enter a number of points to redeem. |
      | 1.5    | Enter a whole number of points.     |

  # Added by QA, the two discounts interact and the ticket does not say how (assumption 5)
  @regression @p1 @redeem @discount
  Scenario: Tier discount is applied before redeemed points
    Given my points balance is 700
    And my tier is Silver
    When I place an order with a subtotal of $100.00
    And I redeem 500 points
    Then the tier discount shown is $5.00
    And the points discount shown is $5.00
    And the order total is $90.00

  # Added by QA, protects against a negative total when the redemption exceeds the order value
  @regression @p2 @redeem
  Scenario: Order total never goes below zero
    Given my points balance is 2000
    When I place an order with a subtotal of $5.00
    And I redeem 2000 points
    Then the order total is $0.00
    And I am told that only 500 points were needed for this order

  # Added by QA, a failed order must not consume points
  @regression @p1 @redeem
  Scenario: Points are returned when the order fails after redemption
    Given my points balance is 300
    When I place an order with a subtotal of $20.00
    And I redeem 300 points
    And the payment is declined
    Then no order is created
    And my points balance is 300

  # ---------- AC-4: points page ----------

  @smoke @p1 @points-page
  Scenario: Points page shows balance and tier
    Given my points balance is 1250
    When I open the points page
    Then my points balance is shown as 1250
    And my tier is shown as "Silver"

  # AC-4 as written is not measurable; threshold taken from assumption 7 and must be confirmed with the product owner
  @performance @p2 @points-page
  Scenario: Points page loads within the agreed time
    Given my points balance is 1250
    When I open the points page
    Then the balance and tier are visible within 2 seconds

  # Added by QA, the empty state is the first thing a new member sees
  @regression @p2 @points-page
  Scenario: New member sees an empty points page
    Given my points balance is 0
    When I open the points page
    Then my points balance is shown as 0
    And my tier is shown as "Basic"
    And I see how many points are needed to reach Silver
```

## Open questions for the Three Amigos

- Does tier use current balance or lifetime earned points? Assumption 1 affects two scenarios.
- What is the redemption rate, and is there a minimum redemption?
- When are points credited: on confirmation, on payment capture, or after the return window?
- Does the tier discount apply to the order that crosses the threshold?
- What is the measurable load-time target for AC-4, and on what device and connection?
- What `data-testid` attributes will the points page and checkout expose for automation?

## Not included

Step definitions are omitted because no test stack was detected in the workspace. The `context-discovery` rule could not be loaded: the `qa-rules` skill is not installed, so the scenarios are grounded in the ticket only.
