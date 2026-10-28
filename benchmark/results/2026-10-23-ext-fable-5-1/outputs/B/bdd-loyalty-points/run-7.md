# LOY-3 Loyalty points — BDD scenarios

## Assumptions

The story leaves several things undefined. These scenarios assume the following; each is flagged so the product owner can correct it.

- **A1 Subtotal** means the sum of item prices before tier discount, point redemption, shipping and tax. Points are earned on this pre-discount figure.
- **A2 Points are credited** when an order is placed successfully. Cancellations and refunds are out of scope for this story.
- **A3 Tier is based on the current points balance**, as the acceptance criteria literally state. Redeeming points can therefore lower a tier. If tier is meant to be based on lifetime points earned, the downgrade scenario below must be inverted.
- **A4 Tier for an order** is evaluated when the order is placed, before that order's own points are added.
- **A5 Order of calculation**: tier discount applied to subtotal, then redeemed points deducted, then shipping and tax. Monetary results round half-up to the cent.
- **A6 Redemption value**: 100 points = $1.00. Redemption is in whole points, minimum 1, and cannot exceed the order's post-discount subtotal.
- **A7 "Fast"** is defined as 95th-percentile page load of 2 seconds or less for a member with 1,000 points transactions, measured on the reference test environment. AC-4 is not testable as written and should be rewritten with this or another concrete number.
- **A8 Non-members** see no points, earn none and get no tier discount.

```gherkin
@LOY-3
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

  @AC-1
  Scenario Outline: A member earns one point per whole dollar of subtotal
    Given Mia has a points balance of 0
    When Mia places an order with a subtotal of <subtotal>
    Then Mia's points balance is <points>

    Examples: Typical and boundary subtotals
      | subtotal   | points |
      | $24.99     | 24     |
      | $24.00     | 24     |
      | $25.00     | 25     |
      | $1.00      | 1      |
      | $0.99      | 0      |
      | $0.01      | 0      |
      | $0.00      | 0      |
      | $1,234.56  | 1234   |

  @AC-1
  Scenario: Points are added to an existing balance
    Given Mia has a points balance of 100
    When Mia places an order with a subtotal of $24.99
    Then Mia's points balance is 124

  @AC-1
  Scenario: Points are earned on the subtotal before discounts, shipping and tax
    Given Mia is a Silver member with a points balance of 600
    And shipping costs $5.00 and tax is 10%
    When Mia places an order with a subtotal of $100.00
    Then the tier discount applied is $5.00
    And the order total charged is $109.50
    And Mia earns 100 points
    And Mia's points balance is 700

  @AC-1
  Scenario: Points are earned on the subtotal even when points are redeemed on the same order
    Given Mia has a points balance of 1000
    When Mia places an order with a subtotal of $50.00
    And Mia redeems 500 points on that order
    Then Mia is charged $45.00 before shipping and tax
    And Mia earns 50 points
    And Mia's points balance is 550

  @AC-1
  Scenario: A guest shopper does not earn points
    Given a guest shopper who is not a loyalty member
    When the guest places an order with a subtotal of $80.00
    Then no points are credited to any account
    And the order confirmation does not mention loyalty points

  @AC-1
  Scenario: Points from a failed payment are not credited
    Given Mia has a points balance of 100
    When Mia attempts an order with a subtotal of $30.00
    And the payment is declined
    Then Mia's points balance remains 100

  # ---------------------------------------------------------------
  # AC-2: Tiers and tier discounts
  # ---------------------------------------------------------------

  @AC-2
  Scenario Outline: Tier is determined by points balance
    Given Mia has a points balance of <balance>
    When Mia views her points page
    Then Mia's tier is shown as "<tier>"

    Examples: Tier boundaries
      | balance | tier   |
      | 0       | Basic  |
      | 499     | Basic  |
      | 500     | Silver |
      | 1999    | Silver |
      | 2000    | Gold   |
      | 50000   | Gold   |

  @AC-2
  Scenario Outline: Tier discount is applied to the order subtotal
    Given Mia has a points balance of <balance>
    When Mia places an order with a subtotal of <subtotal>
    Then a tier discount of <discount> is applied
    And the discounted subtotal is <discounted>

    Examples: Each tier, including cent rounding
      | balance | subtotal | discount | discounted |
      | 499     | $100.00  | $0.00    | $100.00    |
      | 500     | $100.00  | $5.00    | $95.00     |
      | 1999    | $24.99   | $1.25    | $23.74     |
      | 2000    | $100.00  | $10.00   | $90.00     |
      | 2500    | $24.99   | $2.50    | $22.49     |

  @AC-2
  Scenario: Tier discount is shown as a separate line at checkout
    Given Mia is a Gold member
    When Mia proceeds to checkout with a subtotal of $200.00
    Then the order summary shows a line "Gold member discount (10%)" of -$20.00

  @AC-2
  Scenario: Points earned on the current order do not change the discount on that order
    Given Mia has a points balance of 450
    When Mia places an order with a subtotal of $100.00
    Then no tier discount is applied to this order
    And Mia's points balance is 550
    And Mia's tier is now "Silver"

  @AC-2
  Scenario: The upgraded tier applies to the next order
    Given Mia has a points balance of 550
    And Mia's tier is "Silver"
    When Mia places an order with a subtotal of $100.00
    Then a tier discount of $5.00 is applied

  @AC-2
  Scenario: A member is promoted to Gold after crossing 2,000 points
    Given Mia has a points balance of 1950
    When Mia places an order with a subtotal of $60.00
    Then Mia's points balance is 2010
    And Mia's tier is now "Gold"

  @AC-2 @assumption-A3
  Scenario: Redeeming points below a threshold lowers the tier
    Given Mia has a points balance of 520
    And Mia's tier is "Silver"
    When Mia redeems 100 points on an order with a subtotal of $10.00
    Then Mia's points balance is 430
    And Mia's tier is now "Basic"

  @AC-2
  Scenario: The tier discount is recalculated if the cart changes before payment
    Given Mia is a Silver member
    And Mia's cart has a subtotal of $100.00 with a tier discount of $5.00
    When Mia removes items so the subtotal is $40.00
    Then the tier discount is $2.00

  # ---------------------------------------------------------------
  # AC-3: Redeeming points
  # ---------------------------------------------------------------

  @AC-3
  Scenario: Redeeming more points than the balance is rejected
    Given Mia has a points balance of 300
    When Mia attempts to redeem 301 points at checkout
    Then the message "You don't have enough points." is displayed
    And no points are deducted
    And Mia's points balance remains 300
    And no discount is applied to the order

  @AC-3
  Scenario: Redeeming with a zero balance is rejected
    Given Mia has a points balance of 0
    When Mia attempts to redeem 1 point at checkout
    Then the message "You don't have enough points." is displayed
    And Mia's points balance remains 0

  @AC-3
  Scenario: Redeeming exactly the full balance succeeds
    Given Mia has a points balance of 300
    When Mia redeems 300 points on an order with a subtotal of $20.00
    Then a redemption discount of $3.00 is applied
    And Mia's points balance is 0 before this order's points are added

  @AC-3
  Scenario: Redeeming part of the balance deducts only the redeemed amount
    Given Mia has a points balance of 1000
    When Mia redeems 250 points on an order with a subtotal of $30.00
    Then a redemption discount of $2.50 is applied
    And 250 points are deducted from Mia's balance

  @AC-3
  Scenario: A rejected redemption can be corrected and resubmitted
    Given Mia has a points balance of 300
    And Mia attempted to redeem 301 points and saw "You don't have enough points."
    When Mia changes the amount to 300 points and resubmits
    Then the redemption succeeds
    And the error message is no longer displayed

  @AC-3 @assumption-A6
  Scenario Outline: Invalid redemption amounts are rejected without touching the balance
    Given Mia has a points balance of 300
    When Mia attempts to redeem <amount> points at checkout
    Then the redemption is rejected with a validation message
    And Mia's points balance remains 300

    Examples:
      | amount |
      | 0      |
      | -50    |
      | 10.5   |
      | abc    |

  @AC-3 @assumption-A6
  Scenario: Redemption cannot exceed the discounted order subtotal
    Given Mia has a points balance of 5000
    And Mia's cart has a subtotal of $20.00 after the tier discount
    When Mia attempts to redeem 2500 points
    Then the redemption is rejected
    And Mia is told the maximum redeemable on this order is 2000 points
    And Mia's points balance remains 5000

  @AC-3
  Scenario: Balance check uses the live balance, not a stale page
    Given Mia has a points balance of 300
    And Mia has the checkout page open showing 300 points
    When 200 of Mia's points are deducted by another order placed in a second session
    And Mia attempts to redeem 300 points from the open checkout page
    Then the message "You don't have enough points." is displayed
    And Mia's points balance remains 100

  @AC-3
  Scenario: Points are not deducted if payment fails after redemption
    Given Mia has a points balance of 300
    When Mia redeems 200 points on an order
    And the payment is declined
    Then Mia's points balance remains 300

  @AC-3
  Scenario: A guest shopper cannot redeem points
    Given a guest shopper who is not a loyalty member
    When the guest proceeds to checkout
    Then no option to redeem points is shown

  # ---------------------------------------------------------------
  # AC-4: Points page performance (assumption A7)
  # ---------------------------------------------------------------

  @AC-4 @non-functional @assumption-A7
  Scenario: The points page loads within the agreed threshold for a heavy account
    Given Mia has 1,000 points transactions in her history
    When the points page is requested 100 times on the reference test environment
    Then the 95th-percentile time to fully load the page is 2 seconds or less
    And every response returns the correct balance and tier

  @AC-4 @non-functional @assumption-A7
  Scenario: The points page loads within the threshold under concurrent load
    Given 200 members each request their points page concurrently
    Then the 95th-percentile time to fully load the page is 2 seconds or less
    And no request fails

  @AC-4
  Scenario: The points page shows the balance, tier and progress to the next tier
    Given Mia has a points balance of 1200
    When Mia views her points page
    Then the page shows a balance of 1200 points
    And the page shows the tier "Silver"
    And the page shows 800 points needed to reach "Gold"

  @AC-4
  Scenario: A Gold member sees no next-tier progress
    Given Mia has a points balance of 2000
    When Mia views her points page
    Then the page shows the tier "Gold"
    And no next-tier progress is shown
```

## Open questions for the product owner

1. Is tier based on current balance or lifetime points earned (assumption A3)? This changes whether redemption can demote a member.
2. What is the cash value of a point (assumption A6)? Without it, redemption discounts cannot be verified.
3. Are points earned on the subtotal before or after the tier discount and redemption (assumption A1)?
4. What happens to earned and redeemed points when an order is cancelled or refunded? Treated as out of scope here.
5. AC-4 needs a measurable target. Assumption A7 proposes one; please confirm or replace it.
