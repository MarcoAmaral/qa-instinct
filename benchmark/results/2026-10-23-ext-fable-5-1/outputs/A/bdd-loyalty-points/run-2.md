# Feature: Loyalty points (LOY-3)

**Assumptions** (not stated in the story; confirm with product):

1. "Subtotal" is the sum of item prices before the tier discount, point redemption, tax and shipping. Points are earned on that figure and credited when the order is placed.
2. Tier is determined by the member's current points balance at the moment an order is placed, so redeeming points can lower a tier. Points earned by an order do not count towards that order's tier.
3. Points redeem at 100 points = $1.00 off, in whole points, applied after the tier discount. Points earned by an order cannot be redeemed on that same order.
4. Only logged-in members earn, redeem or receive tier discounts.
5. "Fast" for AC-4 means the points page is fully rendered within 2 seconds at the 95th percentile for a member with up to 1,000 points transactions, under normal production load.

---

Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am logged in as a loyalty programme member

  Rule: AC-1 A member earns 1 point for every whole dollar of an order's subtotal

    Scenario Outline: Points earned equal the subtotal rounded down to whole dollars
      Given my points balance is 0
      When I place an order with a subtotal of $<subtotal>
      Then my points balance is <points>

      Examples:
        | subtotal | points |
        | 24.99    | 24     |
        | 25.00    | 25     |
        | 0.99     | 0      |
        | 100.01   | 100    |

    Scenario: Points are added to the existing balance
      Given my points balance is 150
      When I place an order with a subtotal of $40.50
      Then my points balance is 190

    Scenario: Points are calculated on the subtotal before discount, tax and shipping
      Given my points balance is 600
      And my tier is Silver
      When I place an order with a subtotal of $100.00, tax of $8.00 and shipping of $5.00
      Then the order total is $108.00
      And my points balance is 700

  Rule: AC-2 Tier is Basic below 500 points, Silver from 500 and Gold from 2,000, with 5% and 10% discounts

    Scenario Outline: Tier and discount at the boundaries
      Given my points balance is <balance>
      When I place an order with a subtotal of $100.00
      Then my tier is shown as <tier>
      And a discount of <discount> is applied
      And the order total is $<total>

      Examples:
        | balance | tier   | discount | total  |
        | 0       | Basic  | 0%       | 100.00 |
        | 499     | Basic  | 0%       | 100.00 |
        | 500     | Silver | 5%       | 95.00  |
        | 1999    | Silver | 5%       | 95.00  |
        | 2000    | Gold   | 10%      | 90.00  |
        | 5000    | Gold   | 10%      | 90.00  |

    Scenario: Points earned by an order do not count towards that order's tier
      Given my points balance is 450
      When I place an order with a subtotal of $100.00
      Then no discount is applied
      And the order total is $100.00
      And my points balance is 550
      And my tier is now Silver

    Scenario: Tier is re-evaluated after points are redeemed
      Given my points balance is 520
      And my tier is Silver
      When I redeem 100 points
      Then my points balance is 420
      And my tier is now Basic

  Rule: AC-3 Redeeming more points than the balance shows an error and redeems nothing

    Scenario: Redeeming fewer points than the balance
      Given my points balance is 300
      And I have an order with a subtotal of $50.00
      When I redeem 200 points against the order
      Then $2.00 is deducted from the order
      And the order total is $48.00
      And after the order is placed my points balance is 150

    Scenario: Redeeming exactly the balance
      Given my points balance is 300
      And I have an order with a subtotal of $50.00
      When I redeem 300 points against the order
      Then $3.00 is deducted from the order
      And my points balance is 0

    Scenario: Redeeming one point more than the balance
      Given my points balance is 300
      And I have an order with a subtotal of $50.00
      When I try to redeem 301 points against the order
      Then I see the message "You don't have enough points."
      And my points balance is still 300
      And the order total is still $50.00

    Scenario: Redeeming with a zero balance
      Given my points balance is 0
      And I have an order with a subtotal of $50.00
      When I try to redeem 1 point against the order
      Then I see the message "You don't have enough points."
      And my points balance is still 0
      And the order total is still $50.00

  Rule: AC-4 The points page should load fast

    Scenario: Points page shows balance and tier
      Given my points balance is 1,250
      When I open the points page
      Then I see a balance of 1,250 points
      And I see my tier as Silver

    Scenario: Points page loads within the agreed threshold
      Given I have 1,000 points transactions in my history
      And the system is under normal production load
      When the points page is loaded 100 times
      Then at least 95 of those loads are fully rendered within 2 seconds
