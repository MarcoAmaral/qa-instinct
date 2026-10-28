# LOY-3 Loyalty points — BDD scenarios

**Context discovery.** The workspace is empty, so no implementation, routes, selectors or existing step definitions could be checked. Every scenario below is derived from the ticket text and the assumptions listed next. Treat them as `@candidate` until confirmed against the real system in Three Amigos.

## Assumptions

1. **Subtotal** means the merchandise total before tier discount, tax and shipping. Points are floored to the whole dollar, so $24.99 earns 24 and $0.99 earns 0.
2. **Points are credited when the order is confirmed.** Refunds and cancellations are out of scope for this story.
3. **Tier is computed from the current points balance** at the moment the order is priced, not from lifetime points. Redeeming points can therefore lower a tier. This is the biggest open question for the PO.
4. **Tier discount applies to the subtotal** and is shown on the order summary. Basic gets 0%.
5. **Redemption rate** is not in the ticket. Assumed 100 points = $1.00 off, applied after the tier discount. Only the "not enough points" rule (AC-3) is asserted strictly; the rate appears in one `# Added by QA` scenario and must be confirmed.
6. **Redeeming a quantity equal to the balance is allowed** (the error triggers only when the requested amount exceeds the balance).
7. **AC-4 is not measurable** as written ("fast"). Assumed target: points page fully rendered within 2 seconds at the 95th percentile on the reference device and network. Scenario tagged `@candidate @nfr` until the PO sets the number.

## AC quality check (SMART)

| AC | Verdict | Note |
| --- | --- | --- |
| AC-1 | Pass | Specific, measurable, worked example given. Rounding rule (floor) confirmed by the example. |
| AC-2 | Pass with gap | Thresholds are clear. Does not say whether tier uses balance or lifetime points, nor whether the discount is applied to subtotal or total. |
| AC-3 | Pass | Exact message and "redeems nothing" make it testable. Does not say what the redemption rate is or whether redeeming the full balance is allowed. |
| AC-4 | Fail | "Fast" is not measurable. Needs a threshold, a percentile and a device/network baseline. |

## Feature file

```gherkin
@loyalty @LOY-3
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am signed in as a loyalty programme member

  # ---------- AC-1: earning points ----------

  @smoke @p0 @ac1
  Scenario: Points are earned per whole dollar of the order subtotal
    Given my points balance is 0
    When I place an order with a subtotal of $24.99
    Then my points balance is 24
    And the order confirmation shows "You earned 24 points"

  @regression @p1 @ac1
  Scenario Outline: Points are floored to the whole dollar of the subtotal
    Given my points balance is 0
    When I place an order with a subtotal of $<subtotal>
    Then my points balance is <points>

    Examples:
      | subtotal | points |
      | 0.99     | 0      |
      | 1.00     | 1      |
      | 1.01     | 1      |
      | 24.99    | 24     |
      | 100.00   | 100    |
      | 100.50   | 100    |

  # Added by QA, the ticket does not say whether tax and shipping count toward the subtotal
  @regression @p1 @ac1
  Scenario: Tax and shipping do not earn points
    Given my points balance is 0
    When I place an order with a subtotal of $40.00, tax of $3.20 and shipping of $5.99
    Then my points balance is 40

  # Added by QA, the ticket does not say which amount earns points when a tier discount applies (assumption 1: pre-discount subtotal)
  @regression @p1 @ac1 @ac2 @candidate
  Scenario: Points are earned on the subtotal before the tier discount
    Given my points balance is 600
    When I place an order with a subtotal of $100.00
    Then a 5% tier discount of $5.00 is applied
    And my points balance is 700

  # Added by QA, points must accumulate across orders, not reset per order
  @regression @p1 @ac1
  Scenario: Points accumulate across orders
    Given my points balance is 30
    When I place an order with a subtotal of $24.99
    Then my points balance is 54

  # ---------- AC-2: tiers and discounts ----------

  @smoke @p0 @ac2
  Scenario Outline: Tier is derived from the points balance
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
      | 10000   | Gold   |

  @smoke @p0 @ac2
  Scenario Outline: Tier discount is applied to every order
    Given my points balance is <balance>
    When I place an order with a subtotal of $100.00
    Then the order summary shows a tier discount of $<discount>
    And the amount charged before tax and shipping is $<charged>

    Examples:
      | balance | discount | charged |
      | 0       | 0.00     | 100.00  |
      | 499     | 0.00     | 100.00  |
      | 500     | 5.00     | 95.00   |
      | 1999    | 5.00     | 95.00   |
      | 2000    | 10.00    | 90.00   |

  # Added by QA, tier changes mid-session must be reflected on the next order
  @regression @p1 @ac2
  Scenario: Reaching Silver on one order gives the discount on the next
    Given my points balance is 480
    When I place an order with a subtotal of $25.00
    Then my points balance is 505
    And my tier is shown as "Silver"
    When I place another order with a subtotal of $100.00
    Then the order summary shows a tier discount of $5.00

  # Added by QA, the order that crosses the threshold must not be discounted retroactively
  @regression @p2 @ac2
  Scenario: The order that crosses a tier threshold is priced at the previous tier
    Given my points balance is 490
    When I place an order with a subtotal of $100.00
    Then the order summary shows a tier discount of $0.00
    And my points balance is 590
    And my tier is shown as "Silver"

  # Added by QA, assumption 3 says tier follows the current balance; the PO must confirm this is intended
  @regression @p2 @ac2 @ac3 @candidate
  Scenario: Redeeming points below a threshold lowers the tier
    Given my points balance is 520
    And my tier is shown as "Silver"
    When I redeem 100 points
    Then my points balance is 420
    And my tier is shown as "Basic"

  # ---------- AC-3: redeeming points ----------

  @smoke @p0 @ac3
  Scenario: Redeeming more points than the balance is rejected
    Given my points balance is 300
    When I try to redeem 301 points
    Then I see the message "You don't have enough points."
    And my points balance is still 300
    And no discount is applied to the order

  @regression @p1 @ac3
  Scenario Outline: Redemption is only rejected when the request exceeds the balance
    Given my points balance is 300
    When I try to redeem <requested> points
    Then the redemption is "<result>"
    And my points balance is <balance_after>

    Examples:
      | requested | result   | balance_after |
      | 299       | accepted | 1             |
      | 300       | accepted | 0             |
      | 301       | rejected | 300           |

  @regression @p1 @ac3
  Scenario: Redeeming with a zero balance is rejected
    Given my points balance is 0
    When I try to redeem 1 point
    Then I see the message "You don't have enough points."
    And my points balance is still 0

  # Added by QA, the ticket gives no redemption rate (assumption 5: 100 points = $1.00)
  @regression @p1 @ac3 @candidate
  Scenario: Redeemed points reduce the amount charged
    Given my points balance is 300
    And I have an order with a subtotal of $50.00
    When I redeem 200 points on the order
    Then the order summary shows a points discount of $2.00
    And my points balance is 100

  # Added by QA, the ticket does not define valid redemption input
  @regression @p2 @ac3
  Scenario Outline: Invalid redemption amounts are rejected without changing the balance
    Given my points balance is 300
    When I try to redeem "<input>" points
    Then I see a validation message
    And my points balance is still 300

    Examples:
      | input |
      | 0     |
      | -50   |
      | 12.5  |
      | abc   |

  # Added by QA, the failed redemption and the successful one must not interfere
  @regression @p2 @ac3
  Scenario: A rejected redemption does not block a later valid one
    Given my points balance is 300
    And I tried to redeem 301 points and saw "You don't have enough points."
    When I redeem 300 points
    Then the redemption is accepted
    And my points balance is 0

  # Added by QA, double submission must not redeem twice
  @regression @p2 @ac3
  Scenario: Submitting the same redemption twice redeems only once
    Given my points balance is 300
    When I submit a redemption of 200 points twice in quick succession
    Then exactly one redemption of 200 points is recorded
    And my points balance is 100

  # ---------- AC-4: points page performance ----------

  # Assumption 7: "fast" is read as 2 s at p95; the PO must set the real target
  @nfr @performance @p2 @ac4 @candidate
  Scenario: Points page loads within the agreed time
    Given my account has 1,000 points transactions
    When I open the points page
    Then the balance, tier and transaction history are visible within 2 seconds
    And the measurement is taken at the 95th percentile over 20 loads on the reference device and network

  # Added by QA, the page must show the right data, not only load quickly
  @smoke @p1 @ac4
  Scenario: Points page shows balance and tier
    Given my points balance is 750
    When I open the points page
    Then the page shows a balance of 750 points
    And my tier is shown as "Silver"
    And the page shows how many points are needed to reach Gold
```

## Open questions for Three Amigos

- **Tier basis.** Balance or lifetime points? Assumption 3 picks balance. If lifetime, the "redeeming lowers the tier" scenario is wrong and must be deleted.
- **Redemption rate and cap.** What is a point worth, and can points cover the whole order?
- **Order the discount and points apply in.** Do points earn on the discounted or undiscounted subtotal? Assumption 1 picks undiscounted.
- **AC-4 target.** Needs a number, a percentile and a baseline before it can pass or fail.
- **Refunds and cancellations.** Are earned points reversed? Out of scope here but a likely follow-up story.

Step definitions were not written because the stack is unknown and the workspace is empty.

Rules not applied: the `context-discovery` and `testing-guidelines` rules were not in context and no `qa-rules` skill is installed, so I followed the command's own guidance only.
