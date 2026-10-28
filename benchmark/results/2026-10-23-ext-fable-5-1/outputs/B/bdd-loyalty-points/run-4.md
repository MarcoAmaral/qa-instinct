## Assumptions

The story leaves several things undefined. Each scenario below is written against these assumptions; anything marked **(confirm)** materially changes behaviour if wrong.

| # | Area | Assumption |
|---|------|------------|
| A1 | Rounding | Points are the subtotal rounded **down** to the whole dollar (floor), per the $24.99 → 24 example. |
| A2 | "Subtotal" | Sum of line items **before** tier discount, point redemption, tax and shipping. Points are earned on this pre-discount figure. **(confirm)** |
| A3 | When points are earned | Credited when the order is successfully placed (payment authorised). Cancellations/refunds reverse the credit. |
| A4 | Tier basis | Tier is derived from the member's **current points balance**, as the AC literally states. Redeeming can therefore lower a tier. **(confirm – lifetime-earned points is the more common model)** |
| A5 | Tier evaluation time | Tier is evaluated at checkout, before the order's own points are credited. |
| A6 | Discount base | Tier discount applies to the subtotal, before tax and shipping. Discount amounts round half-up to the cent. |
| A7 | Redemption rate | 100 points = $1.00 off. Points are redeemed in whole-point integers, minimum 1. **(confirm)** |
| A8 | Stacking order | Tier discount is applied first, then the point redemption, then tax/shipping. Redemption cannot exceed the remaining order total. |
| A9 | Guests | Non-members earn nothing and see no loyalty UI. |
| A10 | "Fast" (AC-4) | Points page renders in ≤ 2.0 s at the 95th percentile with a 10,000-transaction history, under normal load. **(confirm – AC-4 is not testable as written)** |
| A11 | Currency | Single currency (USD). |

---

## Feature: Earning points (AC-1)

```gherkin
Feature: Earn loyalty points on orders
  As a loyalty programme member
  I want to earn points on every order
  So that I can redeem them for discounts later

  Background:
    Given the loyalty programme is active
    And "Ana" is a loyalty member with a balance of 0 points

  @happy-path
  Scenario Outline: Points equal the whole-dollar portion of the subtotal
    Given Ana has an order with a subtotal of $<subtotal>
    When Ana places the order successfully
    Then Ana's balance should be <points> points
    And Ana's points history should show "+<points> points – Order <order_id>"

    Examples: Rounding boundaries
      | subtotal | points | note                       |
      | 24.99    | 24     | example from the story     |
      | 25.00    | 25     | exact dollar               |
      | 25.01    | 25     | just over a dollar         |
      | 0.99     | 0      | under one dollar, no points|
      | 1.00     | 1      | minimum earning order      |
      | 0.00     | 0      | fully-discounted order     |
      | 999.99   | 999    | large order                |
      | 1234.50  | 1234   | thousands                  |

  Scenario: Points are earned on the pre-discount subtotal, not the amount paid
    # Assumption A2
    Given Ana has a balance of 600 points and is therefore Silver
    And Ana has an order with a subtotal of $100.00
    When Ana places the order
    Then the 5% Silver discount makes the amount charged $95.00
    And Ana earns 100 points, not 95

  Scenario: Tax and shipping do not earn points
    Given Ana has an order with a subtotal of $40.00
    And tax of $3.20 and shipping of $5.99 are added
    When Ana places the order
    Then Ana earns 40 points

  Scenario: Points are credited only once per order
    Given Ana has an order with a subtotal of $50.00
    When Ana places the order
    And the order confirmation page is refreshed
    And the payment provider sends a duplicate "payment captured" webhook
    Then Ana's balance should be 50 points

  Scenario: Points are not credited when payment fails
    Given Ana has an order with a subtotal of $50.00
    When payment for the order is declined
    Then Ana's balance should remain 0 points
    And no entry is added to Ana's points history

  Scenario: Points are reversed when an order is cancelled
    # Assumption A3
    Given Ana placed an order with a subtotal of $50.00 and now has 50 points
    When the order is cancelled before dispatch
    Then Ana's balance should be 0 points
    And Ana's points history should show "-50 points – Order cancelled"

  Scenario: Points reversal cannot drive the balance negative
    Given Ana placed an order with a subtotal of $50.00 and now has 50 points
    And Ana redeems 50 points on a second order
    When the first order is refunded in full
    Then Ana's balance should be 0 points
    And the shortfall of 50 points is recorded for finance review

  Scenario: Guests do not earn points
    # Assumption A9
    Given a guest shopper is not signed in to a loyalty account
    When the guest places an order with a subtotal of $80.00
    Then no points are credited to any account
    And the order confirmation does not mention loyalty points

  Scenario: Order placed by a member who joins the programme after checkout
    Given "Ben" is a registered customer but not a loyalty member
    And Ben placed an order with a subtotal of $80.00
    When Ben joins the loyalty programme
    Then Ben's balance should be 0 points
```

---

## Feature: Tiers and tier discounts (AC-2)

```gherkin
Feature: Loyalty tiers and tier discounts
  As a loyalty member
  I want my tier to reflect my points
  So that Silver and Gold members get automatic discounts

  Background:
    Given the loyalty programme is active

  @boundary
  Scenario Outline: Tier is determined by points balance
    # Assumption A4 – tier based on current balance
    Given "Ana" is a loyalty member with a balance of <balance> points
    When Ana views the points page
    Then Ana's tier should be shown as "<tier>"

    Examples:
      | balance | tier   | note                   |
      | 0       | Basic  | new member             |
      | 499     | Basic  | one below Silver       |
      | 500     | Silver | exact Silver threshold |
      | 501     | Silver |                        |
      | 1999    | Silver | one below Gold         |
      | 2000    | Gold   | exact Gold threshold   |
      | 2001    | Gold   |                        |
      | 50000   | Gold   | no tier above Gold     |

  @boundary
  Scenario Outline: Tier discount is applied to the order subtotal
    # Assumption A6
    Given "Ana" is a loyalty member with a balance of <balance> points
    And Ana has an order with a subtotal of $<subtotal>
    When Ana proceeds to checkout
    Then the order summary should show a "<tier> member discount" line of -$<discount>
    And the discounted subtotal should be $<after>

    Examples:
      | balance | tier   | subtotal | discount | after  |
      | 499     | Basic  | 100.00   | 0.00     | 100.00 |
      | 500     | Silver | 100.00   | 5.00     | 95.00  |
      | 1999    | Silver | 100.00   | 5.00     | 95.00  |
      | 2000    | Gold   | 100.00   | 10.00    | 90.00  |
      | 500     | Silver | 24.99    | 1.25     | 23.74  |
      | 2000    | Gold   | 24.99    | 2.50     | 22.49  |
      | 500     | Silver | 0.10     | 0.01     | 0.09   |
      | 500     | Silver | 0.01     | 0.00     | 0.01   |

  Scenario: Basic members see no discount line
    Given "Ana" is a loyalty member with a balance of 100 points
    And Ana has an order with a subtotal of $100.00
    When Ana proceeds to checkout
    Then no member discount line is shown
    And the order total equals subtotal plus tax and shipping

  Scenario: Tier discount does not apply to tax or shipping
    Given "Ana" is a Gold member
    And Ana has an order with a subtotal of $100.00, tax of $8.00 and shipping of $5.00
    When Ana proceeds to checkout
    Then the Gold member discount should be $10.00
    And the order total should be $103.00

  Scenario: Tier is evaluated before the current order's points are credited
    # Assumption A5
    Given "Ana" is a loyalty member with a balance of 450 points
    And Ana has an order with a subtotal of $100.00
    When Ana places the order
    Then no member discount is applied to this order
    And Ana's balance afterwards is 550 points
    And Ana's tier is now "Silver"
    And Ana's next order receives the 5% Silver discount

  Scenario: Member is promoted when a credit crosses a threshold
    Given "Ana" is a loyalty member with a balance of 1,950 points
    When Ana places an order with a subtotal of $50.00
    Then Ana's balance should be 2,000 points
    And Ana's tier should be "Gold"
    And Ana receives a "Welcome to Gold" notification

  Scenario: Member is demoted when a redemption drops the balance below a threshold
    # Consequence of assumption A4 – confirm this is intended behaviour
    Given "Ana" is a loyalty member with a balance of 520 points
    When Ana redeems 100 points on an order
    Then Ana's balance should be 420 points
    And Ana's tier should be "Basic"

  Scenario: Member is demoted when a cancellation drops the balance below a threshold
    Given "Ana" is a loyalty member with a balance of 2,020 points
    And 50 of those points came from order "ORD-1"
    When order "ORD-1" is cancelled
    Then Ana's balance should be 1,970 points
    And Ana's tier should be "Silver"

  Scenario: Tier discount is recalculated if the balance changes during checkout
    Given "Ana" is a Silver member with a balance of 500 points
    And Ana has started checkout on an order showing a 5% discount
    When an earlier order of Ana's is cancelled, dropping her balance to 450 points
    And Ana submits the order
    Then the order is re-priced with no member discount
    And Ana is shown "Your member discount has changed. Please review your order total."
    And the order is not placed until Ana confirms

  Scenario: Tier discount stacks with point redemption in the defined order
    # Assumption A8
    Given "Ana" is a Gold member with a balance of 3,000 points
    And Ana has an order with a subtotal of $100.00
    When Ana redeems 1,000 points at checkout
    Then the Gold discount of $10.00 is applied first, giving $90.00
    And the redemption of $10.00 is applied next, giving $80.00
    And Ana earns 100 points on the order

  Scenario: Tier shown on the points page matches the tier used at checkout
    Given "Ana" is a loyalty member with a balance of 2,000 points
    When Ana views the points page
    And Ana then proceeds to checkout on any order
    Then both the points page and checkout refer to the "Gold" tier
```

---

## Feature: Redeeming points (AC-3)

```gherkin
Feature: Redeem loyalty points
  As a loyalty member
  I want to redeem points against an order
  So that I pay less

  Background:
    Given the loyalty programme is active
    And "Ana" is a loyalty member with a balance of 300 points
    And Ana has an order with a subtotal of $50.00 at checkout

  @happy-path
  Scenario Outline: Redeeming up to the full balance succeeds
    # Assumption A7 – 100 points = $1.00
    When Ana enters <redeem> in the "Redeem points" field and applies it
    Then a "Points redeemed" line of -$<value> is shown
    And Ana's balance after placing the order should be <remaining> points plus the points earned on this order

    Examples:
      | redeem | value | remaining | note               |
      | 1      | 0.01  | 299       | minimum            |
      | 100    | 1.00  | 200       |                    |
      | 299    | 2.99  | 1         | one below balance  |
      | 300    | 3.00  | 0         | exact balance      |

  @negative
  Scenario Outline: Redeeming more than the balance is rejected and redeems nothing
    When Ana enters <redeem> in the "Redeem points" field and applies it
    Then the message "You don't have enough points." is shown
    And no "Points redeemed" line is added to the order
    And the order total is unchanged
    And Ana's balance remains 300 points

    Examples:
      | redeem  | note                  |
      | 301     | one over balance      |
      | 1000    | well over balance     |
      | 999999  | very large number     |

  Scenario: Member with zero balance cannot redeem
    Given Ana's balance is 0 points
    When Ana enters 1 in the "Redeem points" field and applies it
    Then the message "You don't have enough points." is shown
    And Ana's balance remains 0 points

  Scenario: Error message text is exact
    When Ana enters 301 in the "Redeem points" field and applies it
    Then the error text is exactly "You don't have enough points."
    And the error is announced to assistive technology
    And the "Redeem points" field keeps focus with the entered value

  Scenario: Member can correct the amount after an insufficient-balance error
    Given Ana has been shown "You don't have enough points." after entering 301
    When Ana changes the value to 300 and applies it
    Then the error disappears
    And a "Points redeemed" line of -$3.00 is shown

  @negative
  Scenario Outline: Invalid redemption inputs are rejected with a validation message
    When Ana enters "<input>" in the "Redeem points" field and applies it
    Then the message "<message>" is shown
    And nothing is redeemed

    Examples:
      | input | message                                  |
      | 0     | Enter at least 1 point.                  |
      | -50   | Enter at least 1 point.                  |
      | 10.5  | Enter a whole number of points.          |
      | abc   | Enter a whole number of points.          |
      |       | Enter a whole number of points.          |

  Scenario: Redemption cannot exceed the order total
    # Assumption A8
    Given Ana's balance is 10,000 points
    And Ana's order total after tier discount, tax and shipping is $55.00
    When Ana enters 10,000 points and applies it
    Then the message "You can redeem up to 5,500 points on this order." is shown
    And nothing is redeemed

  Scenario: Redeemed points are deducted only when the order is placed
    When Ana applies 200 points
    And Ana abandons checkout without placing the order
    Then Ana's balance remains 300 points

  Scenario: Redeemed points are not deducted when payment fails
    When Ana applies 200 points
    And payment for the order is declined
    Then Ana's balance remains 300 points
    And the redemption remains applied so Ana can retry payment

  Scenario: Points redeemed on a cancelled order are returned
    Given Ana placed the order redeeming 200 points
    When the order is cancelled before dispatch
    Then the 200 points are returned to Ana's balance
    And the points earned on that order are reversed

  Scenario: Balance is validated at placement, not only when applied
    Given Ana applied 300 points at checkout
    And Ana's balance has since dropped to 100 points because an earlier order was refunded
    When Ana places the order
    Then the order is not placed
    And the message "You don't have enough points." is shown
    And the "Points redeemed" line is removed

  @concurrency
  Scenario: Two simultaneous checkouts cannot both redeem the same points
    Given Ana has checkout open on two devices
    And each checkout has 300 points applied
    When both orders are placed at the same moment
    Then exactly one order is placed with 300 points redeemed
    And the other order fails with "You don't have enough points."
    And Ana's balance is never negative

  @security
  Scenario: Server rejects a tampered redemption request
    When a request to redeem 5,000 points is sent directly to the API, bypassing the UI
    Then the API responds with a 4xx error and "You don't have enough points."
    And Ana's balance remains 300 points
    And no discount is applied to the order

  @security
  Scenario: A member cannot redeem another member's points
    Given "Ben" is a loyalty member with 2,000 points
    When Ana's session sends a redemption request referencing Ben's account
    Then the request is rejected
    And Ben's balance remains 2,000 points
```

---

## Feature: Points page (AC-4 and supporting display behaviour)

```gherkin
Feature: Points page
  As a loyalty member
  I want to see my balance, tier and history
  So that I understand what I can redeem

  Background:
    Given the loyalty programme is active

  Scenario: Points page shows balance, tier and progress to next tier
    Given "Ana" is a loyalty member with a balance of 750 points
    When Ana opens the points page
    Then the page shows "750 points"
    And the page shows tier "Silver"
    And the page shows "1,250 points to Gold"

  Scenario: Gold members see no next-tier progress
    Given "Ana" is a loyalty member with a balance of 2,500 points
    When Ana opens the points page
    Then the page shows tier "Gold"
    And no next-tier progress is shown

  Scenario: Points page reflects an order placed moments ago
    Given "Ana" is a loyalty member with a balance of 0 points
    When Ana places an order with a subtotal of $24.99
    And Ana opens the points page within 5 seconds
    Then the page shows "24 points"

  Scenario: Non-members are prompted to join
    Given "Ben" is signed in but not a loyalty member
    When Ben opens the points page
    Then Ben sees a "Join the loyalty programme" call to action
    And no balance or tier is shown

  Scenario: Signed-out users are redirected to sign in
    Given no user is signed in
    When the points page URL is opened
    Then the user is redirected to sign in
    And after signing in is returned to the points page

  @performance
  Scenario Outline: Points page loads within the performance budget
    # Assumption A10 – AC-4 "fast" is undefined; 2.0 s p95 is a placeholder budget
    Given "Ana" is a loyalty member with <transactions> entries in her points history
    When the points page is requested 100 times under normal production-like load
    Then the 95th-percentile time to fully rendered content is at most 2.0 seconds
    And no request exceeds 5.0 seconds

    Examples:
      | transactions |
      | 0            |
      | 100          |
      | 10000        |

  @performance
  Scenario: Points history is paginated rather than loaded in full
    Given "Ana" is a loyalty member with 10,000 entries in her points history
    When Ana opens the points page
    Then at most 50 history entries are returned in the initial response
    And older entries are available via "Load more"

  @performance
  Scenario: Points page degrades gracefully if the loyalty service is slow
    Given the loyalty service is responding in 10 seconds
    When Ana opens the points page
    Then the page shell renders within 2.0 seconds
    And the balance area shows a loading state
    And after the timeout the message "We can't load your points right now. Please try again." is shown
```

---

## Open questions for the product owner

1. **Tier basis (A4):** balance vs. lifetime-earned. With balance-based tiers, a Gold member drops to Basic by redeeming 1,600 points, which is unusual and may be unintended.
2. **Redemption rate (A7):** the story never states what a point is worth.
3. **Points on discounted subtotal (A2):** pre- or post-tier-discount?
4. **AC-4 definition:** needs a measurable target (metric, percentile, data volume, environment) before it can pass or fail.
5. **Tier evaluation timing (A5):** should a 499-point member whose current order crosses 500 get Silver on that same order?
6. **Expiry, partial refunds, and multi-currency** are out of scope here but will need their own scenarios.
