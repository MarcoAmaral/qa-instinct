**Assumptions**

- Points are credited when an order is placed, based on the subtotal before tier discount, shipping and tax.
- Tier is based on lifetime points earned, not the current balance, so redeeming points never lowers a tier.
- Redemption rate: 100 points = $1.00 off, applied after the tier discount. The product has no stated rate, so an editor should confirm this.
- A member can redeem their full balance, and a redemption that fails leaves the balance unchanged.
- "Load fast" (AC-4) means the **Points** page shows the balance and tier within 2 seconds at the 95th percentile with 10,000 orders in the member's history.
- Interface labels assumed: **Points**, **Redeem points**, **Redeem**, **Checkout**.

---

Feature: Earn loyalty points (LOY-3, AC-1)
  As a loyalty programme member
  I want to earn 1 point per whole dollar of an order's subtotal
  So that I get discounts on later orders

  Background:
    Given I am signed in as a loyalty programme member
    And my points balance is 0

  Scenario Outline: Points are earned on each whole dollar of the subtotal
    When I place an order with a subtotal of <subtotal>
    Then my points balance is <points>

    Examples:
      | subtotal | points |
      | $24.99   | 24     |
      | $24.00   | 24     |
      | $0.99    | 0      |
      | $1.00    | 1      |
      | $100.50  | 100    |

  Scenario: Points are earned on the subtotal, not shipping or tax
    When I place an order with a subtotal of $40.00, shipping of $5.99 and tax of $3.60
    Then my points balance is 40

  Scenario: Points are earned on the subtotal before the tier discount
    Given my lifetime points earned is 600
    And my tier is Silver
    When I place an order with a subtotal of $100.00
    Then the order total before tax is $95.00
    And my points balance increases by 100

  Scenario: Points from several orders add up
    When I place an order with a subtotal of $30.50
    And I place an order with a subtotal of $19.99
    Then my points balance is 49

---

Feature: Loyalty tiers and tier discounts (LOY-3, AC-2)

  Background:
    Given I am signed in as a loyalty programme member

  Scenario Outline: Tier depends on lifetime points earned
    Given my lifetime points earned is <points>
    When I open the **Points** page
    Then my tier is shown as <tier>

    Examples:
      | points | tier   |
      | 0      | Basic  |
      | 499    | Basic  |
      | 500    | Silver |
      | 1999   | Silver |
      | 2000   | Gold   |
      | 5000   | Gold   |

  Scenario Outline: Tier discount is applied to every order
    Given my lifetime points earned is <points>
    When I place an order with a subtotal of $200.00
    Then a tier discount of <discount> is applied
    And the order total before tax is <total>

    Examples:
      | points | discount | total   |
      | 499    | $0.00    | $200.00 |
      | 500    | $10.00   | $190.00 |
      | 2000   | $20.00   | $180.00 |

  Scenario: Reaching Silver changes the tier for the next order only
    Given my lifetime points earned is 480
    When I place an order with a subtotal of $30.00
    Then no tier discount is applied to this order
    And my tier is Silver
    When I place an order with a subtotal of $100.00
    Then a tier discount of $5.00 is applied

  Scenario: Redeeming points does not lower the tier
    Given my lifetime points earned is 2,100
    And my points balance is 2,100
    When I redeem 2,000 points
    Then my points balance is 100
    And my tier is Gold

---

Feature: Redeem loyalty points (LOY-3, AC-3)

  Background:
    Given I am signed in as a loyalty programme member
    And I am on the **Checkout** page with an order subtotal of $50.00

  Scenario: Redeem fewer points than the balance
    Given my points balance is 300
    When I enter 200 in **Redeem points**
    And I select **Redeem**
    Then $2.00 is deducted from the order total
    And my points balance is 100

  Scenario: Redeem the full balance
    Given my points balance is 300
    When I enter 300 in **Redeem points**
    And I select **Redeem**
    Then $3.00 is deducted from the order total
    And my points balance is 0

  Scenario: Redeem more points than the balance
    Given my points balance is 300
    When I enter 301 in **Redeem points**
    And I select **Redeem**
    Then I see the message "You don't have enough points."
    And no discount is applied to the order total
    And my points balance is 300

  Scenario: Redeem with a zero balance
    Given my points balance is 0
    When I enter 1 in **Redeem points**
    And I select **Redeem**
    Then I see the message "You don't have enough points."
    And my points balance is 0

  Scenario: Failed redemption can be retried with a valid amount
    Given my points balance is 300
    And I have seen the message "You don't have enough points." after entering 500
    When I enter 250 in **Redeem points**
    And I select **Redeem**
    Then the message is no longer shown
    And $2.50 is deducted from the order total
    And my points balance is 50

---

Feature: Points page performance (LOY-3, AC-4)

  Scenario: Points page loads within the target time
    Given I am signed in as a loyalty programme member
    And my account has 10,000 orders in its history
    When I open the **Points** page 100 times
    Then the balance and tier are visible within 2 seconds on at least 95 of those loads

  Scenario: Points page shows the balance before the order history
    Given I am signed in as a loyalty programme member
    When I open the **Points** page
    Then my points balance and tier are visible before the order history finishes loading
