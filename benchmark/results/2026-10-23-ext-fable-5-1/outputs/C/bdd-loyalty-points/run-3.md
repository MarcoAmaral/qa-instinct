Feature: LOY-3 Loyalty points

Assumptions (the story does not say; confirm with the product owner before automating):

- Points are earned on the subtotal before tier discount, tax and shipping, rounded down to the whole dollar.
- Points are added when the order is placed. Refunds and cancellations are out of scope for this story.
- Tier is based on lifetime points earned, not the current balance, so redeeming points never lowers a tier.
- A tier change applies from the next order, not the order that crosses the threshold.
- Redemption rate is 100 points = $1.00 off, applied to the subtotal after the tier discount. The story gives no rate.
- The redeem control is a **Redeem points** field with a **Apply** button on the checkout page. The error text is shown exactly as "You don't have enough points."
- AC-4 "load fast" is not testable as written. The scenario below uses 2 seconds at the 95th percentile for a member with 1,000 point transactions. The product owner must set the real number.

```gherkin
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am signed in as a loyalty programme member

  # AC-1: earning points

  Scenario Outline: A member earns 1 point per whole dollar of the subtotal
    Given my points balance is 0
    When I place an order with a subtotal of <subtotal>
    Then my points balance is <points>

    Examples:
      | subtotal | points |
      | $24.99   | 24     |
      | $25.00   | 25     |
      | $0.99    | 0      |
      | $1.00    | 1      |
      | $100.50  | 100    |

  Scenario: Points are earned on the subtotal, not the discounted total
    Given my tier is Silver
    And my points balance is 500
    When I place an order with a subtotal of $100.00
    Then the order total is $95.00
    And my points balance is 600

  Scenario: Tax and shipping do not earn points
    Given my points balance is 0
    When I place an order with a subtotal of $20.00, tax of $2.00 and shipping of $5.99
    Then my points balance is 20

  # AC-2: tiers and tier discounts

  Scenario Outline: Tier is set by lifetime points earned
    Given I have earned <lifetime_points> points in total
    When I open the points page
    Then my tier is shown as <tier>

    Examples:
      | lifetime_points | tier   |
      | 0               | Basic  |
      | 499             | Basic  |
      | 500             | Silver |
      | 1999            | Silver |
      | 2000            | Gold   |
      | 5000            | Gold   |

  Scenario Outline: Tier discount is applied to every order
    Given my tier is <tier>
    When I place an order with a subtotal of $200.00
    Then a tier discount of <discount> is applied
    And the order total is <total>

    Examples:
      | tier   | discount | total   |
      | Basic  | $0.00    | $200.00 |
      | Silver | $10.00   | $190.00 |
      | Gold   | $20.00   | $180.00 |

  Scenario: The order that reaches a tier does not get that tier's discount
    Given I have earned 480 points in total
    And my tier is Basic
    When I place an order with a subtotal of $30.00
    Then no tier discount is applied to this order
    And my tier is Silver
    And the next order I place gets a 5% tier discount

  Scenario: Redeeming points does not lower the tier
    Given I have earned 2,100 points in total
    And my points balance is 2,100
    And my tier is Gold
    When I redeem 2,000 points
    Then my points balance is 100
    And my tier is still Gold

  # AC-3: redeeming points

  Scenario: Redeeming part of the balance reduces the order total
    Given my points balance is 1,000
    And I have an order with a subtotal of $50.00 in checkout
    When I enter 500 in Redeem points and select Apply
    Then a points discount of $5.00 is applied
    And the order total is $45.00
    And my points balance is 500

  Scenario: Redeeming the whole balance is allowed
    Given my points balance is 300
    And I have an order with a subtotal of $50.00 in checkout
    When I enter 300 in Redeem points and select Apply
    Then a points discount of $3.00 is applied
    And my points balance is 0

  Scenario: Redeeming more points than the balance redeems nothing
    Given my points balance is 300
    And I have an order with a subtotal of $50.00 in checkout
    When I enter 301 in Redeem points and select Apply
    Then I see the message "You don't have enough points."
    And no points discount is applied
    And the order total is $50.00
    And my points balance is still 300

  Scenario: Tier discount and redeemed points are combined on one order
    Given my tier is Silver
    And my points balance is 1,000
    And I have an order with a subtotal of $100.00 in checkout
    When I enter 1,000 in Redeem points and select Apply
    Then a tier discount of $5.00 is applied
    And a points discount of $10.00 is applied
    And the order total is $85.00

  # AC-4: points page performance

  @non-functional
  Scenario: The points page loads within the agreed time
    Given my account has 1,000 point transactions
    When I open the points page 100 times under normal load
    Then at least 95 of the 100 loads complete within 2 seconds
```

Open questions the product owner should answer before these scenarios are automated:

1. What is the redemption rate, and is there a minimum or maximum number of points per order?
2. Is tier based on lifetime points or current balance?
3. Does a tier discount apply to the order that crosses the threshold?
4. What is the target load time for AC-4, and under what load?
5. What happens to earned points when an order is refunded or cancelled?
