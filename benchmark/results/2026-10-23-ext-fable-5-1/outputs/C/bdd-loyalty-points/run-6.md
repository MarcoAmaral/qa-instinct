# LOY-3 Loyalty points: BDD scenarios

```gherkin
@LOY-3
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am signed in as a member of the loyalty programme

  # ---------------------------------------------------------------
  # AC-1: Earning points
  # ---------------------------------------------------------------

  @AC-1
  Scenario Outline: A member earns 1 point for every whole dollar of the subtotal
    Given my points balance is 0
    When I pay for an order with a subtotal of <subtotal>
    Then my points balance is <points>

    Examples:
      | subtotal   | points |
      | $24.99     | 24     |
      | $25.00     | 25     |
      | $0.99      | 0      |
      | $0.00      | 0      |
      | $1,000.01  | 1000   |

  @AC-1
  Scenario: Points are earned on the subtotal, not on tax or shipping
    Given my points balance is 0
    When I pay for an order with a subtotal of $40.00, tax of $3.20 and shipping of $5.99
    Then my points balance is 40

  @AC-1
  Scenario: Points are earned on the subtotal before any discount
    Given I have earned 500 points in total
    And my points balance is 500
    When I pay for an order with a subtotal of $100.00
    Then a tier discount of $5.00 is applied to that order
    And my points balance is 600

  @AC-1
  Scenario: Earned points are added to the existing balance
    Given my points balance is 100
    When I pay for an order with a subtotal of $24.99
    Then my points balance is 124

  @AC-1
  Scenario: Points are not credited until the order is paid
    Given my points balance is 0
    When I place an order with a subtotal of $30.00 and payment is still pending
    Then my points balance is 0
    When the payment is confirmed
    Then my points balance is 30

  # ---------------------------------------------------------------
  # AC-2: Tiers and tier discounts
  # ---------------------------------------------------------------

  @AC-2
  Scenario Outline: Tier is set by the total points earned
    Given I have earned <lifetime> points in total
    When I open the Points page
    Then my tier is shown as "<tier>"

    Examples:
      | lifetime | tier   |
      | 0        | Basic  |
      | 499      | Basic  |
      | 500      | Silver |
      | 1999     | Silver |
      | 2000     | Gold   |
      | 5000     | Gold   |

  @AC-2
  Scenario Outline: Tier discount is applied to the order subtotal at checkout
    Given I have earned <lifetime> points in total
    When I go to checkout with a subtotal of $80.00
    Then a tier discount of <discount> is shown
    And the subtotal after discount is <after>

    Examples:
      | lifetime | discount | after  |
      | 499      | $0.00    | $80.00 |
      | 500      | $4.00    | $76.00 |
      | 1999     | $4.00    | $76.00 |
      | 2000     | $8.00    | $72.00 |

  @AC-2
  Scenario: Reaching a new tier with an order applies the discount to the next order
    Given I have earned 480 points in total
    When I pay for an order with a subtotal of $30.00
    Then no tier discount is applied to that order
    And my tier is shown as "Silver"
    When I go to checkout with a subtotal of $80.00
    Then a tier discount of $4.00 is shown

  @AC-2
  Scenario: Redeeming points does not lower the tier
    Given I have earned 2000 points in total
    And my points balance is 2000
    When I redeem 1500 points on an order
    Then my points balance is 500
    And my tier is shown as "Gold"

  @AC-2 @AC-3
  Scenario: Tier discount is applied before a points discount
    Given I have earned 2000 points in total
    And my points balance is 2000
    When I go to checkout with a subtotal of $100.00
    And I enter 500 in Points to redeem and select Apply
    Then a tier discount of $10.00 is shown
    And a points discount of $5.00 is shown
    And the subtotal after discounts is $85.00

  # ---------------------------------------------------------------
  # AC-3: Redeeming points
  # ---------------------------------------------------------------

  @AC-3
  Scenario Outline: Redeeming points within the balance reduces the order total
    Given my points balance is 1000
    When I go to checkout with a subtotal of $50.00
    And I enter <redeem> in Points to redeem and select Apply
    Then a points discount of <discount> is shown
    When I pay for the order
    Then my points balance is <balance>

    # balance = 1000 - redeemed + 50 earned on the $50.00 subtotal
    Examples:
      | redeem | discount | balance |
      | 100    | $1.00    | 950     |
      | 999    | $9.99    | 51      |
      | 1000   | $10.00   | 50      |

  @AC-3
  Scenario Outline: Redeeming more points than the balance is refused
    Given my points balance is <balance>
    When I go to checkout with a subtotal of $50.00
    And I enter <redeem> in Points to redeem and select Apply
    Then the message "You don't have enough points." is shown
    And no points discount is applied
    And my points balance is still <balance>

    Examples:
      | balance | redeem |
      | 300     | 301    |
      | 300     | 1000   |
      | 0       | 1      |

  @AC-3
  Scenario: A refused redemption does not block the order
    Given my points balance is 300
    When I go to checkout with a subtotal of $50.00
    And I enter 500 in Points to redeem and select Apply
    Then the message "You don't have enough points." is shown
    When I pay for the order without redeeming points
    Then the order is placed at the full price
    And my points balance is 350

  @AC-3
  Scenario: Correcting a refused amount lets the member redeem
    Given my points balance is 300
    When I go to checkout with a subtotal of $50.00
    And I enter 500 in Points to redeem and select Apply
    Then the message "You don't have enough points." is shown
    When I enter 300 in Points to redeem and select Apply
    Then the message is no longer shown
    And a points discount of $3.00 is shown

  # ---------------------------------------------------------------
  # AC-4: Points page performance
  # ---------------------------------------------------------------

  @AC-4 @non-functional
  Scenario: The Points page loads within the agreed time
    Given I have a points history of 10,000 entries
    When I open the Points page
    Then my balance and tier are visible within 2 seconds
    And the 95th percentile load time over 100 requests is 2 seconds or less

  @AC-4
  Scenario: The Points page shows the current balance and tier
    Given I have earned 750 points in total
    And my points balance is 600
    When I open the Points page
    Then my points balance is shown as 600
    And my tier is shown as "Silver"
```

## Assumptions

The story leaves these points open. Each scenario above follows the assumption listed here. Change the scenario if the product owner decides otherwise.

- **Subtotal** means the item total before tax, shipping, tier discounts and points discounts. Points are earned on that amount and rounded down to a whole dollar.
- **Points are credited** when the order is paid, not when it is placed. Refunds and cancellations are out of scope for this story.
- **Tier is based on total points earned** over the member's lifetime, not on the current balance. Redeeming points therefore never lowers a tier.
- **Tier takes effect on the next order.** The order that pushes a member over a threshold does not itself get the new discount.
- **Redemption rate** is 100 points for $1.00 off, so 1 point is worth $0.01. The story does not state a rate.
- **Discount order** at checkout is tier discount first, then points discount.
- **Checkout labels** are assumed to be **Points to redeem** and **Apply**. The page is assumed to be called **Points**. An editor should check these against the real interface.
- **"Load fast" is not testable as written.** The scenarios assume 2 seconds at the 95th percentile for a member with 10,000 history entries. The product owner must confirm the number before this scenario is automated.
- **Redemption cap** is not defined. The scenarios do not cover whether a member can redeem more points than the order is worth. This needs a decision before AC-3 is complete.
