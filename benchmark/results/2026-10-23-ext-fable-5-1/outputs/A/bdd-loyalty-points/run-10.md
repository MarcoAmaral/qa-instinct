**Assumptions** (the story leaves these open; each is tagged in the scenarios it affects):

1. Points are earned on the order subtotal before tier discount, tax and shipping, rounded down to the whole dollar, and credited when the order is placed.
2. Tier is determined by the member's current points balance at the moment the order is placed. Redeeming points can therefore lower a tier. If the product owner intends lifetime-earned points instead, only the Background balances in the tier scenarios change.
3. Redemption rate is 1 point = $0.01 (100 points = $1.00). Points are redeemed in whole points and the redemption is applied after the tier discount.
4. Redemption is attempted from the checkout page. The error in AC-3 is shown inline and the order total is unchanged.
5. "Load fast" is interpreted as a 95th-percentile page load of 2 seconds or less for a member with 10,000 points transactions in their history.
6. Non-members do not earn points, get no tier discount and cannot redeem.

```gherkin
@LOY-3
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given the loyalty programme is active
    And "Priya" is a registered loyalty member

  # ---------------------------------------------------------------
  # AC-1: Earning points
  # ---------------------------------------------------------------

  @AC-1
  Scenario Outline: A member earns one point per whole dollar of the subtotal
    Given Priya has a points balance of 0
    When Priya places an order with a subtotal of <subtotal>
    Then Priya's points balance is <points>

    Examples:
      | subtotal | points |
      | $24.99   | 24     |
      | $25.00   | 25     |
      | $0.99    | 0      |
      | $1.00    | 1      |
      | $100.01  | 100    |

  @AC-1
  Scenario: Earned points are added to the existing balance
    Given Priya has a points balance of 120
    When Priya places an order with a subtotal of $30.50
    Then Priya's points balance is 150

  @AC-1 @assumption-1
  Scenario: Points are earned on the subtotal before discounts, tax and shipping
    Given Priya has a points balance of 600
    And Priya is a Silver member
    When Priya places an order with a subtotal of $40.00, tax of $3.20 and shipping of $5.00
    Then the order total is $46.20
    And Priya earns 40 points for the order

  @AC-1 @assumption-6
  Scenario: A guest does not earn points
    Given a guest shopper who is not a loyalty member
    When the guest places an order with a subtotal of $50.00
    Then no points are awarded for the order

  # ---------------------------------------------------------------
  # AC-2: Tiers and tier discounts
  # ---------------------------------------------------------------

  @AC-2 @assumption-2
  Scenario Outline: Tier is determined by the points balance
    Given Priya has a points balance of <balance>
    When Priya views the points page
    Then Priya's tier is shown as <tier>

    Examples: Boundaries
      | balance | tier   |
      | 0       | Basic  |
      | 499     | Basic  |
      | 500     | Silver |
      | 1999    | Silver |
      | 2000    | Gold   |
      | 5000    | Gold   |

  @AC-2 @assumption-2
  Scenario Outline: Tier discount is applied to the order
    Given Priya has a points balance of <balance>
    When Priya places an order with a subtotal of $100.00
    Then a tier discount of <discount> is applied
    And the discounted subtotal is <discounted>

    Examples:
      | balance | discount | discounted |
      | 499     | $0.00    | $100.00    |
      | 500     | $5.00    | $95.00     |
      | 2000    | $10.00   | $90.00     |

  @AC-2 @assumption-2
  Scenario: An order that crosses a tier threshold is discounted at the tier held before the order
    Given Priya has a points balance of 480
    When Priya places an order with a subtotal of $50.00
    Then no tier discount is applied to the order
    And Priya's points balance is 530
    And Priya's tier is Silver

  @AC-2 @assumption-2
  Scenario: Redeeming points below a threshold lowers the tier
    Given Priya has a points balance of 520
    When Priya redeems 100 points
    Then Priya's points balance is 420
    And Priya's tier is Basic

  # ---------------------------------------------------------------
  # AC-3: Redeeming points
  # ---------------------------------------------------------------

  @AC-3 @assumption-3 @assumption-4
  Scenario: Redeeming points within the balance reduces the order total
    Given Priya has a points balance of 300
    And Priya is at checkout with a discounted subtotal of $20.00
    When Priya redeems 200 points
    Then the order total is reduced by $2.00
    And Priya's points balance is 100

  @AC-3
  Scenario: Redeeming the entire balance is allowed
    Given Priya has a points balance of 300
    And Priya is at checkout with a discounted subtotal of $20.00
    When Priya redeems 300 points
    Then the order total is reduced by $3.00
    And Priya's points balance is 0

  @AC-3 @assumption-4
  Scenario: Redeeming more points than the balance is rejected
    Given Priya has a points balance of 300
    And Priya is at checkout with an order total of $20.00
    When Priya attempts to redeem 301 points
    Then the message "You don't have enough points." is shown
    And the order total remains $20.00
    And Priya's points balance remains 300

  @AC-3 @assumption-4
  Scenario: A member with no points cannot redeem
    Given Priya has a points balance of 0
    And Priya is at checkout with an order total of $20.00
    When Priya attempts to redeem 1 point
    Then the message "You don't have enough points." is shown
    And the order total remains $20.00

  @AC-3 @assumption-2 @assumption-3
  Scenario: Redemption is applied after the tier discount
    Given Priya has a points balance of 1000
    And Priya is at checkout with a subtotal of $100.00
    When Priya redeems 500 points
    Then a tier discount of $5.00 is applied
    And a points redemption of $5.00 is applied
    And the order total is $90.00
    And Priya's points balance is 500

  # ---------------------------------------------------------------
  # AC-4: Points page performance (non-functional)
  # ---------------------------------------------------------------

  @AC-4 @non-functional @assumption-5
  Scenario: The points page loads quickly for a member with a long history
    Given Priya has 10,000 points transactions in her history
    When Priya opens the points page 100 times
    Then the 95th-percentile page load time is at most 2 seconds
    And the current balance and tier are shown on every load
```

**Open questions for the product owner** (scenarios above proceed on the stated assumptions):

- Is tier based on current balance or lifetime points earned?
- What is the cash value of one point, and is there a minimum redemption?
- Should points be reversed on cancellation or refund?
- What does "fast" mean numerically for AC-4?
