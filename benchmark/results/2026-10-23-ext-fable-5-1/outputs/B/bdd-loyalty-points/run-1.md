# LOY-3 Loyalty points: BDD scenarios

## Assumptions

The story leaves several rules undefined. The scenarios below use these assumptions, and each one should be confirmed with the product owner before the scenarios are automated.

- **A1 Subtotal** means the merchandise total before tax and shipping. Tax and shipping never earn points.
- **A2 Truncation** Points are whole numbers. Fractional dollars are dropped, never rounded up ($24.99 earns 24, $0.99 earns 0).
- **A3 Earning base** Points are earned on the subtotal after the tier discount and after any points redemption, since that is the amount actually paid.
- **A4 Tier basis** Tier is decided by lifetime points earned, not the current spendable balance. Redeeming points therefore never demotes a member.
- **A5 Tier timing** Tier is evaluated when the order is placed. Points from that order are credited after placement, so an order that crosses a threshold does not itself get the new discount.
- **A6 Discount rounding** Tier discounts are rounded to the nearest cent, half up.
- **A7 Redemption value** 100 points equal $1.00 off. Points are redeemed in whole numbers, there is no minimum, and a redemption cannot exceed the order's discounted subtotal.
- **A8 Redemption timing** Redeemed points are deducted when the order is placed and returned if the order fails payment.
- **A9 Membership** Guests and non-members earn nothing and see no loyalty UI at checkout.
- **A10 Performance target** "Fast" is read as: the points page is fully interactive within 2 seconds at the 95th percentile, measured on a mid-tier device over a 4G connection profile, for a member with 10,000 history entries. This is a placeholder and must be ratified.
- **A11 Currency** USD only.

## Scenarios

```gherkin
@LOY-3 @AC-1
Feature: Earning loyalty points
  As a loyalty programme member
  I want to earn 1 point per whole dollar of my order subtotal
  So that I build up points for later discounts

  Background:
    Given I am logged in as a Basic member with a points balance of 0

  Scenario Outline: Points are earned per whole dollar of the subtotal
    When I place an order with a subtotal of $<subtotal>
    Then my points balance is <points>
    And my points history shows an entry of "+<points>" for that order

    Examples: Whole-dollar truncation
      | subtotal | points |
      | 24.99    | 24     |
      | 25.00    | 25     |
      | 25.01    | 25     |
      | 1.00     | 1      |
      | 0.99     | 0      |
      | 0.00     | 0      |
      | 1234.56  | 1234   |

  Scenario: Tax and shipping do not earn points
    When I place an order with a subtotal of $40.00, tax of $3.50 and shipping of $5.99
    Then my points balance is 40

  Scenario: Points accumulate across orders
    When I place an order with a subtotal of $24.99
    And I place an order with a subtotal of $25.00
    Then my points balance is 49

  Scenario: Points are earned on the amount paid after a tier discount
    Given I am a Silver member with a points balance of 500
    When I place an order with a subtotal of $100.00
    Then a 5% tier discount of $5.00 is applied
    And I earn 95 points
    And my points balance is 595

  Scenario: Points are earned on the amount paid after redeeming points
    Given my points balance is 1000
    When I place an order with a subtotal of $50.00 and redeem 1000 points
    Then $10.00 is deducted from the order
    And I earn 40 points
    And my points balance is 40

  Scenario: A guest checkout earns no points
    Given I am not logged in
    When I complete a guest checkout with a subtotal of $80.00
    Then no loyalty points are awarded
    And the order confirmation does not show a points section

  Scenario: Points are credited only once if the order confirmation is retried
    When I place an order with a subtotal of $30.00
    And the order confirmation request is retried by the client
    Then my points balance is 30
    And my points history shows exactly one entry for that order
```

```gherkin
@LOY-3 @AC-2
Feature: Membership tiers and tier discounts
  As a loyalty programme member
  I want my tier to reflect the points I have earned
  So that I receive the matching discount on every order

  Scenario Outline: Tier is determined by lifetime points earned
    Given I am a member with <lifetime> lifetime points earned
    When I view the points page
    Then my tier is shown as "<tier>"

    Examples: Threshold boundaries
      | lifetime | tier   |
      | 0        | Basic  |
      | 499      | Basic  |
      | 500      | Silver |
      | 1999     | Silver |
      | 2000     | Gold   |
      | 50000    | Gold   |

  Scenario Outline: Tier discount is applied to the order subtotal
    Given I am a "<tier>" member
    When I place an order with a subtotal of $100.00
    Then a tier discount of $<discount> is shown on the order summary
    And the discounted subtotal is $<discounted>

    Examples:
      | tier   | discount | discounted |
      | Basic  | 0.00     | 100.00     |
      | Silver | 5.00     | 95.00      |
      | Gold   | 10.00    | 90.00      |

  Scenario Outline: Tier discount is rounded to the nearest cent
    Given I am a "<tier>" member
    When I place an order with a subtotal of $<subtotal>
    Then a tier discount of $<discount> is applied

    Examples:
      | tier   | subtotal | discount |
      | Silver | 24.99    | 1.25     |
      | Silver | 0.10     | 0.01     |
      | Gold   | 24.99    | 2.50     |
      | Gold   | 0.05     | 0.01     |

  Scenario: Discount is applied on every order, not only the first
    Given I am a Gold member
    When I place three separate orders with a subtotal of $50.00 each
    Then each order shows a tier discount of $5.00

  Scenario: Tier discount does not apply to tax or shipping
    Given I am a Gold member
    When I place an order with a subtotal of $100.00, tax of $8.00 and shipping of $10.00
    Then the tier discount is $10.00
    And tax and shipping are charged in full

  Scenario: Crossing a threshold promotes the member for the next order
    Given I am a Basic member with 480 lifetime points
    When I place an order with a subtotal of $30.00
    Then no tier discount is applied to that order
    And my lifetime points are 510
    And my tier is shown as "Silver"
    When I place another order with a subtotal of $30.00
    Then a tier discount of $1.50 is applied

  Scenario: Reaching Gold in a single order promotes the member for the next order
    Given I am a Silver member with 1990 lifetime points
    When I place an order with a subtotal of $200.00
    Then a tier discount of $10.00 is applied
    And my tier is shown as "Gold"

  Scenario: Redeeming points does not demote a member
    Given I am a Silver member with 600 lifetime points and a balance of 600
    When I place an order with a subtotal of $10.00 and redeem 500 points
    Then my points balance is 100
    And my tier is still shown as "Silver"

  Scenario: Tier is evaluated at checkout, not at cart creation
    Given I am a Basic member with 499 lifetime points
    And I have a cart with a subtotal of $100.00
    When 1 point is credited to my account by a separate order
    And I check out the cart
    Then a tier discount of $5.00 is applied
```

```gherkin
@LOY-3 @AC-3
Feature: Redeeming loyalty points
  As a loyalty programme member
  I want to redeem points against an order
  So that I pay less

  Background:
    Given I am logged in as a member
    And I have an order in checkout with a discounted subtotal of $50.00

  Scenario Outline: Redeeming more points than the balance is rejected
    Given my points balance is <balance>
    When I enter <requested> points to redeem
    Then I see the message "You don't have enough points."
    And no points are deducted
    And my points balance is still <balance>
    And the order total is unchanged

    Examples:
      | balance | requested |
      | 100     | 101       |
      | 100     | 150       |
      | 0       | 1         |
      | 4999    | 5000      |

  Scenario: Redeeming exactly the balance succeeds
    Given my points balance is 100
    When I redeem 100 points
    Then $1.00 is deducted from the order
    And my points balance is 0

  Scenario: Redeeming part of the balance succeeds
    Given my points balance is 1000
    When I redeem 250 points
    Then $2.50 is deducted from the order
    And my points balance is 750

  Scenario: Redemption is combined with a tier discount
    Given I am a Gold member with a points balance of 500
    And my order subtotal is $60.00
    When I redeem 500 points
    Then a tier discount of $6.00 is applied
    And a points discount of $5.00 is applied
    And the amount due before tax and shipping is $49.00

  Scenario Outline: Invalid redemption amounts are rejected without deducting points
    Given my points balance is 500
    When I enter "<input>" points to redeem
    Then I see a validation message "<message>"
    And my points balance is still 500

    Examples:
      | input | message                               |
      | 0     | Enter at least 1 point.               |
      | -50   | Enter at least 1 point.               |
      | 12.5  | Points must be a whole number.        |
      | abc   | Points must be a whole number.        |

  Scenario: Redemption cannot exceed the order value
    Given my points balance is 10000
    When I enter 6000 points to redeem against a discounted subtotal of $50.00
    Then I see the message "You can redeem up to 5000 points on this order."
    And my points balance is still 10000

  Scenario: Points are deducted only when the order is placed
    Given my points balance is 300
    When I apply 300 points at checkout
    And I abandon the checkout without placing the order
    Then my points balance is still 300

  Scenario: Points are returned when payment fails
    Given my points balance is 300
    When I place the order redeeming 300 points
    And the payment is declined
    Then the order is not created
    And my points balance is 300

  Scenario: Concurrent redemptions cannot overspend the balance
    Given my points balance is 100
    And I have the same checkout open in two browser sessions
    When session A redeems 100 points and places its order
    And session B then tries to redeem 100 points and place its order
    Then session A's order succeeds
    And session B sees the message "You don't have enough points."
    And my points balance is 0

  Scenario: The rejection message matches the specified text exactly
    Given my points balance is 10
    When I enter 20 points to redeem
    Then the message text is exactly "You don't have enough points."
    And the message is announced to screen readers as an alert
```

```gherkin
@LOY-3 @AC-4 @performance @non-functional
Feature: Points page performance
  As a loyalty programme member
  I want the points page to load fast
  So that I can check my balance without waiting

  # Target per assumption A10: fully interactive within 2 s at p95.

  Scenario: Points page loads within target for a member with a large history
    Given I am a member with 10,000 points history entries
    When I open the points page 100 times under a 4G network profile
    Then the page is fully interactive within 2 seconds at the 95th percentile
    And the balance and tier are visible within 1 second at the 95th percentile

  Scenario: Points page loads within target for a brand-new member
    Given I am a member with no points history
    When I open the points page
    Then the page is fully interactive within 2 seconds at the 95th percentile
    And the page shows a balance of 0 and tier "Basic"

  Scenario: Points page stays within target under concurrent load
    Given 200 members open the points page at the same time
    Then the page is fully interactive within 2 seconds at the 95th percentile for every member
    And no request returns an error

  Scenario: Large histories are paginated rather than loaded in full
    Given I am a member with 10,000 points history entries
    When I open the points page
    Then at most 50 history entries are requested in the initial load
    And further entries load when I request the next page

  Scenario: Balance shown on the page reflects the latest order
    Given my points balance is 100
    When I place an order that earns 24 points
    And I open the points page
    Then my balance is shown as 124
```

## Gaps to confirm with the product owner

- **Definition of "fast"** AC-4 has no measurable target. The 2-second p95 figure in A10 is a placeholder, and the scenarios will be blocked until a number is agreed.
- **Tier basis** Lifetime-earned versus current balance changes the outcome of the "redeeming does not demote" scenario.
- **Earning base** Whether points are earned on the full subtotal or on the amount paid after discounts changes the expected values in two AC-1 scenarios.
- **Redemption value and limits** The 100 points per dollar rate, the lack of a minimum, and the cap at order value are all assumed.
- **Refunds and cancellations** The story does not say whether earned points are clawed back or redeemed points returned. No scenarios cover this.
- **Points expiry** Not mentioned. Assumed to be out of scope.
- **Stacking with promo codes** The order of applying tier discount, promo codes, and points is undefined.
