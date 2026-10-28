Assumptions (information not given in the story):

- Points are credited when an order is placed, calculated on the subtotal before tier discount, tax and shipping, and rounded down to the whole dollar.
- Tier is determined by the member's current points balance, so redeeming points can lower the tier. Tier is evaluated at the time the order is placed.
- The tier discount is applied to the order subtotal.
- Redemption rate is 100 points = $1.00 off, redeemed in whole-point amounts at checkout.
- "Load fast" means the points page is fully rendered within 2 seconds at the 95th percentile, including for a member with a large points history (1,000 transactions).

@LOY-3
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am signed in as a member of the loyalty programme

  @AC-1
  Scenario Outline: Points are earned for every whole dollar of the order subtotal
    Given my points balance is 0
    When I place an order with a subtotal of $<subtotal>
    Then <points> points are credited to my account
    And my points balance is <points>

    Examples:
      | subtotal | points |
      | 24.99    | 24     |
      | 24.00    | 24     |
      | 1.00     | 1      |
      | 0.99     | 0      |
      | 100.50   | 100    |

  @AC-1
  Scenario: Points are calculated on the subtotal before tax, shipping and tier discount
    Given my points balance is 600
    And my tier is Silver
    When I place an order with a subtotal of $100.00, tax of $8.00 and shipping of $5.00
    Then 100 points are credited to my account
    And my points balance is 700

  @AC-2
  Scenario Outline: Tier is determined by points balance
    Given my points balance is <balance>
    When I view my loyalty status
    Then my tier is shown as <tier>

    Examples:
      | balance | tier   |
      | 0       | Basic  |
      | 499     | Basic  |
      | 500     | Silver |
      | 1999    | Silver |
      | 2000    | Gold   |
      | 5000    | Gold   |

  @AC-2
  Scenario Outline: Tier discount is applied to every order
    Given my points balance is <balance>
    When I place an order with a subtotal of $100.00
    Then a tier discount of $<discount> is applied
    And the discounted subtotal is $<discounted_subtotal>

    Examples:
      | balance | tier   | discount | discounted_subtotal |
      | 499     | Basic  | 0.00     | 100.00              |
      | 500     | Silver | 5.00     | 95.00               |
      | 2000    | Gold   | 10.00    | 90.00               |

  @AC-2
  Scenario: Earning points on an order moves the member up a tier
    Given my points balance is 480
    And my tier is Basic
    When I place an order with a subtotal of $30.00
    Then my points balance is 510
    And my tier is Silver

  @AC-2
  Scenario: Redeeming points moves the member down a tier
    Given my points balance is 2000
    And my tier is Gold
    When I redeem 100 points on an order
    Then my points balance is 1900
    And my tier is Silver

  @AC-3
  Scenario: Redeeming more points than the balance is rejected
    Given my points balance is 300
    When I attempt to redeem 301 points on an order
    Then I see the message "You don't have enough points."
    And no points are redeemed
    And my points balance is still 300
    And no discount is applied to the order

  @AC-3
  Scenario: Redeeming exactly the balance succeeds
    Given my points balance is 300
    When I redeem 300 points on an order with a subtotal of $50.00
    Then a redemption discount of $3.00 is applied
    And my points balance is 0

  @AC-3
  Scenario: Redeeming fewer points than the balance succeeds
    Given my points balance is 300
    When I redeem 200 points on an order with a subtotal of $50.00
    Then a redemption discount of $2.00 is applied
    And my points balance is 100

  @AC-3
  Scenario: Redeeming from an empty balance is rejected
    Given my points balance is 0
    When I attempt to redeem 1 point on an order
    Then I see the message "You don't have enough points."
    And my points balance is still 0

  @AC-4
  Scenario: Points page loads quickly for a member with a small history
    Given I have 5 points transactions
    When I open the points page
    Then the page is fully rendered within 2 seconds

  @AC-4
  Scenario: Points page loads quickly for a member with a large history
    Given I have 1,000 points transactions
    When I open the points page
    Then the page is fully rendered within 2 seconds

  @AC-4
  Scenario: Points page load time meets the target under normal load
    Given 100 members open the points page within the same minute
    When the load times are measured
    Then the 95th percentile load time is at most 2 seconds
