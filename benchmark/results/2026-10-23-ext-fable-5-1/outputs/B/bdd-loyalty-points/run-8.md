# LOY-3 Loyalty points — BDD scenarios

## Assumptions

The story leaves several things undefined. These scenarios use the assumptions below; each is tagged in the feature files so it can be found and changed once Product confirms.

| # | Assumption |
|---|---|
| A1 | "Subtotal" is the merchandise total before tier discount, points redemption, tax and shipping. Points are computed on the whole-dollar part (floor), never rounded up. |
| A2 | Points are credited when the order is placed and reversed in full if the order is cancelled or fully refunded. Partial refunds are out of scope for this story. |
| A3 | Tier is derived from the member's current points balance, not lifetime points earned. Redeeming points can therefore lower a tier. |
| A4 | The tier used for an order is the tier at the moment the order is placed. Points earned by that order do not retroactively change its discount. |
| A5 | Tier discount is applied to the subtotal and rounded half-up to the cent. |
| A6 | Redemption rate is 100 points = $1.00 off. Points are redeemed in whole numbers, at checkout, after the tier discount is applied. Points cannot reduce the total below $0.00. |
| A7 | Redemption is validated server-side against the live balance at submit time, not the balance shown when the page loaded. |
| A8 | "Load fast" (AC-4) means: 95th-percentile server response under 500 ms and page fully interactive under 2 s on a standard desktop connection, for a member with up to 10,000 history entries. The thresholds are placeholders to confirm. |
| A9 | Guests and non-members never earn, see, or redeem points. |

## Feature: Earning points (AC-1)

```gherkin
@LOY-3 @AC-1
Feature: Earning loyalty points
  As a loyalty member
  I want to earn 1 point per whole dollar of my order subtotal
  So that I can build up a balance to redeem later

  Background:
    Given I am logged in as a loyalty member with a balance of 0 points

  @happy-path
  Scenario Outline: Points are earned on the whole-dollar part of the subtotal
    Given my cart has a subtotal of $<subtotal>
    When I place the order
    Then my points balance is <points>
    And my points history shows "+<points> points" for that order

    Examples: Boundary and rounding cases
      | subtotal | points |
      | 24.99    | 24     |
      | 25.00    | 25     |
      | 25.01    | 25     |
      | 0.99     | 0      |
      | 0.00     | 0      |
      | 1.00     | 1      |
      | 1000.01  | 1000   |

  @assumption-A1
  Scenario: Tax and shipping do not earn points
    Given my cart has a subtotal of $40.00
    And tax of $3.50 and shipping of $9.99 are added
    When I place the order
    Then my points balance is 40

  @assumption-A1
  Scenario: Points are earned on the subtotal before the tier discount
    Given I am a Silver member with a balance of 600 points
    And my cart has a subtotal of $100.00
    When I place the order
    Then the order total shows a 5% discount of $5.00
    And my points balance is 700

  @assumption-A1 @assumption-A6
  Scenario: Points are earned on the subtotal before points are redeemed
    Given my balance is 1,000 points
    And my cart has a subtotal of $30.00
    And I redeem 500 points for $5.00 off
    When I place the order
    Then I pay $25.00
    And my points balance is 530

  @assumption-A2
  Scenario: Points are reversed when an order is cancelled
    Given I placed an order with a subtotal of $80.00 and earned 80 points
    When that order is cancelled
    Then my points balance is 0
    And my points history shows "-80 points" with the reason "Order cancelled"

  @assumption-A2 @negative
  Scenario: Reversal cannot drive the balance below zero
    Given I placed an order with a subtotal of $80.00 and earned 80 points
    And I redeemed 50 points on a later order
    When the first order is cancelled
    Then my points balance is 0
    And an adjustment of -80 points is recorded with the shortfall flagged for review

  @assumption-A9 @negative
  Scenario: Guest checkout earns no points
    Given I am not logged in
    And my cart has a subtotal of $50.00
    When I place the order as a guest
    Then no points are credited to any account
    And the order confirmation does not mention points

  @negative
  Scenario: A failed payment earns no points
    Given my cart has a subtotal of $50.00
    When I attempt to place the order and the payment is declined
    Then my points balance is 0
    And my points history has no entry for the attempt
```

## Feature: Tiers and tier discounts (AC-2)

```gherkin
@LOY-3 @AC-2
Feature: Loyalty tiers and discounts
  As a loyalty member
  I want my tier to reflect my points and give me a discount
  So that I am rewarded for being a regular customer

  @happy-path @assumption-A3
  Scenario Outline: Tier is determined by points balance
    Given I am a loyalty member with a balance of <points> points
    When I open the points page
    Then my tier is shown as "<tier>"

    Examples: Thresholds and boundaries
      | points | tier   |
      | 0      | Basic  |
      | 499    | Basic  |
      | 500    | Silver |
      | 501    | Silver |
      | 1999   | Silver |
      | 2000   | Gold   |
      | 2001   | Gold   |
      | 50000  | Gold   |

  @happy-path @assumption-A5
  Scenario Outline: Tier discount is applied to the order subtotal
    Given I am a loyalty member with a balance of <points> points
    And my cart has a subtotal of $<subtotal>
    When I view the checkout summary
    Then a "<tier> discount" line of -$<discount> is shown
    And the order total before tax and shipping is $<total>

    Examples:
      | points | tier   | subtotal | discount | total |
      | 0      | Basic  | 100.00   | 0.00     | 100.00 |
      | 499    | Basic  | 100.00   | 0.00     | 100.00 |
      | 500    | Silver | 100.00   | 5.00     | 95.00  |
      | 500    | Silver | 24.99    | 1.25     | 23.74  |
      | 1999   | Silver | 0.99     | 0.05     | 0.94   |
      | 2000   | Gold   | 100.00   | 10.00    | 90.00  |
      | 2000   | Gold   | 59.99    | 6.00     | 53.99  |
      | 2000   | Gold   | 0.01     | 0.00     | 0.01   |

  Scenario: Basic members see no discount line
    Given I am a loyalty member with a balance of 499 points
    And my cart has a subtotal of $100.00
    When I view the checkout summary
    Then no discount line is shown

  @assumption-A4
  Scenario: The order that crosses a threshold does not receive the new tier's discount
    Given I am a Basic member with a balance of 490 points
    And my cart has a subtotal of $20.00
    When I place the order
    Then the order total is $20.00 with no discount
    And my points balance is 510
    And my tier is shown as "Silver"

  @assumption-A4
  Scenario: The next order after reaching a tier receives the discount
    Given I am a Silver member with a balance of 510 points
    And my cart has a subtotal of $20.00
    When I view the checkout summary
    Then a "Silver discount" line of -$1.00 is shown

  @assumption-A3
  Scenario: Redeeming points below a threshold lowers the tier
    Given I am a Silver member with a balance of 520 points
    When I redeem 100 points on an order
    Then my points balance is 420
    And my tier is shown as "Basic"

  @assumption-A3
  Scenario: Cancelling an order can lower the tier
    Given I am a Gold member with a balance of 2,010 points
    And my most recent order earned 50 points
    When that order is cancelled
    Then my points balance is 1,960
    And my tier is shown as "Silver"

  @assumption-A4
  Scenario: Tier is locked when the order is placed, not when the cart is built
    Given I am a Basic member with a balance of 480 points
    And I have a cart with a subtotal of $50.00 open in my browser
    And a separate order is completed that raises my balance to 530 points
    When I refresh the checkout page
    Then a "Silver discount" line of -$2.50 is shown
    When I place the order
    Then the discount applied is $2.50

  @assumption-A6
  Scenario: Tier discount and points redemption combine in a fixed order
    Given I am a Gold member with a balance of 2,500 points
    And my cart has a subtotal of $50.00
    And I redeem 1,000 points
    When I view the checkout summary
    Then a "Gold discount" line of -$5.00 is shown
    And a "Points redeemed" line of -$10.00 is shown
    And the order total before tax and shipping is $35.00

  Scenario: Points page shows progress to the next tier
    Given I am a Silver member with a balance of 1,250 points
    When I open the points page
    Then I see "750 points to Gold"

  Scenario: Gold members see no next-tier prompt
    Given I am a Gold member with a balance of 2,000 points
    When I open the points page
    Then I do not see a "points to" progress message
    And I see that Gold is the highest tier
```

## Feature: Redeeming points (AC-3)

```gherkin
@LOY-3 @AC-3
Feature: Redeeming loyalty points
  As a loyalty member
  I want to redeem points against an order
  So that I get money off

  Background:
    Given I am logged in as a loyalty member
    And I am at checkout with a subtotal of $50.00

  @happy-path @assumption-A6
  Scenario: Redeeming fewer points than the balance succeeds
    Given my balance is 1,000 points
    When I enter 300 in the redeem points field and apply
    Then a "Points redeemed" line of -$3.00 is shown
    And my available balance is shown as 700 points
    When I place the order
    Then my points balance is 700
    And my points history shows "-300 points" for that order

  Scenario: Redeeming exactly the balance succeeds
    Given my balance is 1,000 points
    When I enter 1000 in the redeem points field and apply
    Then a "Points redeemed" line of -$10.00 is shown
    And my available balance is shown as 0 points

  @negative
  Scenario: Redeeming more points than the balance is rejected
    Given my balance is 100 points
    When I enter 150 in the redeem points field and apply
    Then I see the message "You don't have enough points."
    And no "Points redeemed" line is shown
    And the order total is unchanged at $50.00
    And my available balance is still shown as 100 points

  @negative
  Scenario: Redeeming one point more than the balance is rejected
    Given my balance is 100 points
    When I enter 101 in the redeem points field and apply
    Then I see the message "You don't have enough points."
    And my available balance is still shown as 100 points

  @negative
  Scenario: Redeeming with a zero balance is rejected
    Given my balance is 0 points
    When I enter 1 in the redeem points field and apply
    Then I see the message "You don't have enough points."
    And the order total is unchanged at $50.00

  @negative
  Scenario: The rejected amount is not partially redeemed
    Given my balance is 100 points
    When I enter 150 in the redeem points field and apply
    Then I see the message "You don't have enough points."
    When I place the order without changing the redemption
    Then I pay $50.00
    And my points balance is 100

  @negative @assumption-A7
  Scenario: The balance is re-checked at submit, not at page load
    Given my balance is 500 points
    And the checkout page is open showing 500 available points
    And another session redeems 400 of my points
    When I enter 300 in the redeem points field and apply
    Then I see the message "You don't have enough points."
    And my available balance is refreshed to show 100 points

  @negative @assumption-A7
  Scenario: A concurrent redemption that overdraws the balance is rejected at order placement
    Given my balance is 500 points
    And I have applied 500 points in this session
    And another session has since redeemed 200 of my points
    When I place the order
    Then the order is not placed
    And I see the message "You don't have enough points."
    And my points balance is 300

  @negative
  Scenario: A failed redemption attempt leaves no trace in points history
    Given my balance is 100 points
    When I enter 150 in the redeem points field and apply
    And I open the points page
    Then my points history has no entry for the failed attempt

  Scenario: The member can correct the amount after a rejection
    Given my balance is 100 points
    And I entered 150 and saw "You don't have enough points."
    When I change the amount to 100 and apply
    Then the message is no longer shown
    And a "Points redeemed" line of -$1.00 is shown

  @negative @assumption-A6
  Scenario Outline: Invalid redemption inputs are rejected with a validation message
    Given my balance is 1,000 points
    When I enter "<input>" in the redeem points field and apply
    Then I see a validation message "Enter a whole number of points."
    And no points are redeemed

    Examples:
      | input |
      | 0     |
      | -50   |
      | 10.5  |
      | abc   |
      |       |

  @assumption-A6
  Scenario: Points cannot reduce the order total below zero
    Given my balance is 10,000 points
    And my subtotal after tier discount is $45.00
    When I enter 6000 in the redeem points field and apply
    Then I see the message "You can redeem up to 4,500 points on this order."
    And no points are redeemed

  @assumption-A6
  Scenario: Redeeming the maximum allowed for the order brings the total to zero
    Given my balance is 10,000 points
    And my subtotal after tier discount is $45.00
    When I enter 4500 in the redeem points field and apply
    Then the order total before tax and shipping is $0.00
    And my available balance is shown as 5,500 points

  @assumption-A9 @negative
  Scenario: Guests cannot see the redeem points field
    Given I am not logged in
    When I view the checkout page
    Then no redeem points field is shown

  @accessibility
  Scenario: The insufficient-points message is announced to assistive technology
    Given my balance is 100 points
    And I am using a screen reader
    When I enter 150 in the redeem points field and apply
    Then the message "You don't have enough points." is announced
    And focus moves to the redeem points field

  @security @negative
  Scenario: Redemption limits are enforced on the server
    Given my balance is 100 points
    When a request to redeem 150 points is sent directly to the API, bypassing the UI
    Then the API responds with a client error
    And the response body contains "You don't have enough points."
    And my points balance is 100
```

## Feature: Points page performance (AC-4)

```gherkin
@LOY-3 @AC-4 @non-functional
Feature: Points page performance
  As a loyalty member
  I want the points page to load fast
  So that I can check my balance without waiting

  # AC-4 gives no threshold. Figures below are assumption A8 and must be confirmed.

  Background:
    Given the system is under normal production-like load

  @assumption-A8
  Scenario: Points page loads within budget for a typical member
    Given I am a loyalty member with 50 entries in my points history
    When I request the points page
    Then the server responds within 500 ms at the 95th percentile over 100 requests
    And the page is interactive within 2 s at the 95th percentile

  @assumption-A8
  Scenario: Points page loads within budget for a member with a large history
    Given I am a loyalty member with 10,000 entries in my points history
    When I request the points page
    Then the server responds within 500 ms at the 95th percentile over 100 requests
    And the page is interactive within 2 s at the 95th percentile

  @assumption-A8
  Scenario: Large histories are paginated rather than loaded in full
    Given I am a loyalty member with 10,000 entries in my points history
    When I open the points page
    Then only the first 50 history entries are returned in the initial response
    And I can load further entries on demand

  @assumption-A8
  Scenario: Balance and tier are shown before history finishes loading
    Given I am a loyalty member with 10,000 entries in my points history
    When I open the points page
    Then my balance and tier are visible before the history list renders

  @assumption-A8
  Scenario: Performance holds under concurrent load
    Given 200 members request the points page concurrently for 5 minutes
    Then the 95th-percentile server response time stays within 500 ms
    And no request fails

  @assumption-A8
  Scenario: Performance is not regressed by a cold cache
    Given no cached data exists for my account
    When I request the points page for the first time
    Then the server responds within 1 s
    And a second request responds within 500 ms
```

## Items to confirm with Product

- Whether tier is based on current balance or lifetime earned points (A3). This changes the two downgrade scenarios.
- Redemption rate and any minimum redemption amount (A6).
- Whether the tier discount applies before or after points redemption (A6).
- Whether points are earned on the pre-discount or post-discount subtotal (A1).
- Handling of partial refunds (A2).
- Concrete performance targets and the reference device and network for AC-4 (A8).
