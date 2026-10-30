# Loyalty Points (LOY-3)

## Assumptions
- Points are earned and credited immediately upon order completion
- Redeeming points means applying accumulated points as a discount to a new order
- "Fast" performance threshold: points page loads within 2 seconds
- A member's tier is determined by their lifetime points balance
- Tier discounts apply automatically at checkout if member qualifies
- Points are rounded down (only whole dollars count)

---

## Feature: Earning Loyalty Points

```gherkin
Feature: Members earn loyalty points on purchases
  As a member of the loyalty programme
  I want to earn points based on my purchase amount
  So that I can accumulate rewards

  Scenario Outline: Member earns 1 point per whole dollar of order subtotal
    Given I am a loyalty member
    When I complete an order with subtotal <subtotal>
    Then I earn <points> loyalty points

    Examples:
      | subtotal | points |
      | $24.99   | 24     |
      | $25.00   | 25     |
      | $99.99   | 99     |
      | $100.00  | 100    |
      | $1,234.56| 1234   |
      | $0.99    | 0      |
```

---

## Feature: Loyalty Tier System and Discounts

```gherkin
Feature: Members are assigned tiers based on loyalty points
  As a member of the loyalty programme
  I want my tier to grant automatic discounts
  So that I receive rewards for my continued loyalty

  Scenario: New member starts at Basic tier
    Given I am a new loyalty member
    When I check my account
    Then my tier is Basic
    And I have 0 loyalty points

  Scenario: Member reaches Silver tier at 500 points
    Given I am a Basic tier member with 499 points
    When I complete an order with subtotal $100.00
    Then I earn 100 points
    And my total points are 599
    And my tier changes to Silver

  Scenario: Silver tier member receives 5% discount
    Given I am a Silver tier member with 500 points
    When I place an order with subtotal $100.00
    Then a 5% discount ($5.00) is automatically applied
    And I pay $95.00

  Scenario: Member reaches Gold tier at 2000 points
    Given I am a Silver tier member with 1,999 points
    When I complete an order with subtotal $100.00
    Then I earn 100 points
    And my total points are 2,099
    And my tier changes to Gold

  Scenario: Gold tier member receives 10% discount
    Given I am a Gold tier member with 2000 points
    When I place an order with subtotal $100.00
    Then a 10% discount ($10.00) is automatically applied
    And I pay $90.00
```

---

## Feature: Redeeming Loyalty Points

```gherkin
Feature: Members redeem loyalty points for discounts
  As a member of the loyalty programme
  I want to redeem my accumulated points
  So that I can use them as a discount on future orders

  Scenario: Member redeems points successfully
    Given I am a loyalty member with 500 points
    When I redeem 200 points at checkout
    Then my point balance is reduced to 300 points
    And a discount is applied to my order

  Scenario: Member attempts to redeem more points than available
    Given I am a loyalty member with 100 points
    When I attempt to redeem 150 points
    Then the system shows "You don't have enough points."
    And my point balance remains 100 points
    And the order is not completed

  Scenario: Member redeems exact balance
    Given I am a loyalty member with 250 points
    When I redeem 250 points at checkout
    Then my point balance is 0
    And the redemption is successful
```

---

## Feature: Points Page Performance

```gherkin
Feature: Points page loads with acceptable performance
  As a member of the loyalty programme
  I want the points page to load quickly
  So that I can check my balance without delay

  Scenario: Points page loads within performance threshold
    Given I am a loyalty member
    When I navigate to the points page
    Then the page loads completely within 2 seconds
    And my current points balance is displayed
    And my tier information is displayed
    And redemption options are available

  Scenario: Points page displays current information
    Given I am a loyalty member with 750 points
    When I navigate to the points page
    Then I see my points balance as 750
    And I see my tier as Silver
    And I can see my points history
```
