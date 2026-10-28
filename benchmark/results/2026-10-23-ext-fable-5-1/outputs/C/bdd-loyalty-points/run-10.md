# LOY-3 Loyalty points: BDD scenarios

## Assumptions

The story leaves these points open. Each scenario below follows the assumption listed here. Change the assumption and the matching scenario changes with it.

1. **Tier follows the current balance**, not lifetime points earned. Redeeming points can therefore lower a tier.
2. **Tier discount uses the tier at the moment the order is placed.** An order that lifts a member into a new tier does not get the new discount itself.
3. **Points are earned on the subtotal before any discount, redemption, tax or shipping.** The subtotal is in US dollars.
4. **Redemption rate is 100 points for $1.00 off**, taken from the order total after the tier discount. The story does not give a rate.
5. **Points are credited when the order is placed.** Refunds and cancellations are out of scope for this story.
6. **"Fast" in AC-4 means the balance and tier are visible within 2 seconds** on the standard test connection, including a member with 1,000 points transactions. The product owner should set the real target.
7. **Interface labels assumed:** the page is **My points**, the checkout field is **Points to redeem**, the button is **Redeem**. The message text in AC-3 is used exactly as written.

## Feature file

```gherkin
Feature: Loyalty points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given "Ana" is a member of the loyalty programme
    And Ana is signed in

  Rule: A member earns 1 point for every whole dollar of an order's subtotal (AC-1)

    Scenario Outline: Points earned from an order subtotal
      Given Ana has a balance of 0 points
      When Ana places an order with a subtotal of <subtotal>
      Then Ana's balance is <points> points

      Examples:
        | subtotal | points |
        | $24.99   | 24     |
        | $25.00   | 25     |
        | $1.00    | 1      |
        | $0.99    | 0      |
        | $100.50  | 100    |

    Scenario: Points are earned on the subtotal before the tier discount
      Given Ana has a balance of 600 points
      And Ana's tier is Silver
      When Ana places an order with a subtotal of $40.00
      Then the order total is $38.00
      And Ana's balance is 640 points

    Scenario: Points are earned on the subtotal before redeemed points
      Given Ana has a balance of 300 points
      When Ana places an order with a subtotal of $20.00
      And Ana redeems 100 points on that order
      Then the order total is $19.00
      And Ana's balance is 220 points

  Rule: Tier is Basic below 500 points, Silver from 500 and Gold from 2,000 (AC-2)

    Scenario Outline: Tier shown for a balance
      Given Ana has a balance of <points> points
      When Ana opens the "My points" page
      Then Ana's tier is shown as "<tier>"

      Examples:
        | points | tier   |
        | 0      | Basic  |
        | 499    | Basic  |
        | 500    | Silver |
        | 1999   | Silver |
        | 2000   | Gold   |
        | 5000   | Gold   |

    Scenario Outline: Tier discount applied to an order
      Given Ana has a balance of <points> points
      When Ana places an order with a subtotal of $100.00
      Then the order shows a tier discount of <discount>
      And the order total is <total>

      Examples:
        | points | discount | total   |
        | 499    | $0.00    | $100.00 |
        | 500    | $5.00    | $95.00  |
        | 1999   | $5.00    | $95.00  |
        | 2000   | $10.00   | $90.00  |

    Scenario: An order that lifts a member to Silver does not get the Silver discount itself
      Given Ana has a balance of 480 points
      When Ana places an order with a subtotal of $30.00
      Then the order total is $30.00
      And Ana's balance is 510 points
      And Ana's tier is Silver

    Scenario: The next order after reaching Silver gets the Silver discount
      Given Ana has a balance of 510 points
      And Ana's tier is Silver
      When Ana places an order with a subtotal of $30.00
      Then the order total is $28.50

    Scenario: Redeeming points can lower the tier
      Given Ana has a balance of 2000 points
      And Ana's tier is Gold
      When Ana redeems 100 points on an order
      Then Ana's tier is Silver

  Rule: Redeeming more points than the balance shows a message and redeems nothing (AC-3)

    Scenario: Member tries to redeem more points than the balance
      Given Ana has a balance of 150 points
      And Ana is at checkout with an order total of $20.00
      When Ana enters 200 in "Points to redeem"
      And Ana selects "Redeem"
      Then the message "You don't have enough points." is shown
      And Ana's balance is still 150 points
      And the order total is still $20.00

    Scenario: Member tries to redeem points with a zero balance
      Given Ana has a balance of 0 points
      And Ana is at checkout with an order total of $20.00
      When Ana enters 1 in "Points to redeem"
      And Ana selects "Redeem"
      Then the message "You don't have enough points." is shown
      And the order total is still $20.00

    Scenario: Member redeems exactly the balance
      Given Ana has a balance of 150 points
      And Ana is at checkout with an order total of $20.00
      When Ana enters 150 in "Points to redeem"
      And Ana selects "Redeem"
      Then no message is shown
      And the order total is $18.50
      And Ana's balance is 0 points

    Scenario: Member redeems fewer points than the balance
      Given Ana has a balance of 150 points
      And Ana is at checkout with an order total of $20.00
      When Ana enters 100 in "Points to redeem"
      And Ana selects "Redeem"
      Then the order total is $19.00
      And Ana's balance is 50 points

  Rule: The points page loads fast (AC-4)

    @non-functional
    Scenario: Points page shows balance and tier within the target time
      Given Ana has a balance of 2500 points
      And Ana has 1000 points transactions in her history
      When Ana opens the "My points" page
      Then Ana's balance and tier are visible within 2 seconds
```

## Notes for review

- **AC-4 is not testable as written.** The 2-second target in the last scenario is a placeholder. Replace it with the agreed number and the percentile it applies to before the scenario is automated.
- **Assumptions 1, 2 and 4 change behaviour visibly to members.** Confirm them with the product owner before the scenarios are used as acceptance tests.
- **Out of scope:** refunds, cancellations, point expiry, and orders with a subtotal of $0.00.
