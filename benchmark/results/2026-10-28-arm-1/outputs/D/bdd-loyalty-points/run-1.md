## Assumptions

- Redeeming points is a deliberate action on a redemption page where members specify an amount
- "Fast" performance (AC-4) means full page render within 2 seconds, per web UX standards
- Tier discounts apply automatically to all subsequent orders once a member reaches that tier
- Member tier is determined by total accumulated points (monotonic unless points are redeemed)
- Order subtotal is pre-tax and pre-shipping
- The points page displays current balance, tier, and redemption interface

---

## Gherkin Scenarios

```
@loyalty @points
Feature: Loyalty Points Program
  As a loyalty programme member
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given the member is logged into their account
    And the member's points balance is current

  # AC-1: Points earning
  @smoke @p0 @earning
  Scenario: Member earns 1 point per whole dollar of order subtotal
    Given the member has 0 points
    When the member completes an order with subtotal $24.99
    Then 24 points are credited to the member's account

  @regression @p0 @earning
  Scenario Outline: Points earned equal only whole dollars of subtotal
    Given the member has 0 points
    When the member completes an order with subtotal <subtotal>
    Then <points> points are credited

    Examples:
      | subtotal | points |
      | $1.50    | 1      |
      | $24.99   | 24     |
      | $100.00  | 100    |
      | $500.00  | 500    |

  # AC-2: Tier system and automatic discounts
  @p0 @tier
  Scenario: Basic tier member (below 500 points) receives no discount
    Given the member has 100 points
    Then the member's tier is Basic
    When the member places an order with subtotal $100.00
    Then no discount is applied

  @p0 @tier
  Scenario: Silver tier member (500+ points) receives 5% discount
    Given the member has 500 points
    Then the member's tier is Silver
    When the member places an order with subtotal $100.00
    Then a 5% discount is applied
    And the member saves $5.00

  @p0 @tier
  Scenario: Gold tier member (2000+ points) receives 10% discount
    Given the member has 2000 points
    Then the member's tier is Gold
    When the member places an order with subtotal $100.00
    Then a 10% discount is applied
    And the member saves $10.00

  # Added by QA, promotion scenario from AC-2 behavior
  @regression @p1 @tier
  Scenario: Member is promoted to Silver tier upon reaching 500 points
    Given the member has 450 points and Basic tier
    When the member completes an order that earns 50 points
    Then the member's balance is 500 points
    And the member's tier becomes Silver

  # Added by QA, promotion scenario from AC-2 behavior
  @regression @p1 @tier
  Scenario: Member is promoted to Gold tier upon reaching 2000 points
    Given the member has 1950 points and Silver tier
    When the member completes an order that earns 50 points
    Then the member's balance is 2000 points
    And the member's tier becomes Gold

  # AC-3: Insufficient balance redemption
  @smoke @p0 @redemption
  Scenario: Redeeming more points than balance shows error message
    Given the member has 100 points
    And the member is on the redemption page
    When the member attempts to redeem 150 points
    Then the error "You don't have enough points." is displayed
    And the redemption is rejected
    And the member's balance remains 100 points

  # Added by QA, successful redemption is the happy path
  @smoke @p0 @redemption
  Scenario: Member successfully redeems points
    Given the member has 100 points
    And the member is on the redemption page
    When the member redeems 50 points
    Then the redemption succeeds
    And the member's balance becomes 50 points

  # Added by QA, boundary condition for redemption
  @regression @p2 @redemption
  Scenario: Member can redeem entire points balance
    Given the member has 100 points
    And the member is on the redemption page
    When the member redeems all 100 points
    Then the redemption succeeds
    And the member's balance becomes 0 points

  # AC-4: Performance requirement
  @performance @p0
  Scenario: Points page loads within performance threshold
    Given a member with 5000 points is logged in
    When the member navigates to their points page
    Then the page fully loads and renders within 2 seconds
    And the points balance is displayed
    And the tier information is visible
    And the redemption form is interactive
```
