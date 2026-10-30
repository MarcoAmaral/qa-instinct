@loyalty @points
Feature: Loyalty Programme Points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am logged in as an active loyalty programme member

  @smoke @p0
  Scenario: Member earns 1 point per whole dollar spent
    Given my current points balance is 0
    When I complete an order with a subtotal of $50.00
    Then I should earn 50 points
    And my new points balance should be 50

  @p1
  Scenario Outline: Points earned ignore fractional dollars
    Given my current points balance is 0
    When I complete an order with a subtotal of "<subtotal>"
    Then I should earn <points> points

    Examples:
      | subtotal | points |
      | $10.00   | 10     |
      | $24.99   | 24     |
      | $99.99   | 99     |
      | $100.50  | 100    |
      | $1.50    | 1      |

  @smoke @p0
  Scenario: Silver tier unlocks at 500 points with 5% discount
    Given my current points balance is 499
    And I am a Basic member
    When I complete an order with a subtotal of $10.00
    Then my points balance should be 509
    And I should advance to Silver tier
    And I should receive a tier upgrade notification

  @smoke @p0
  Scenario: Gold tier unlocks at 2000 points with 10% discount
    Given my current points balance is 1999
    And I am a Silver member
    When I complete an order with a subtotal of $1.00
    Then my points balance should be 2000
    And I should advance to Gold tier

  @p1
  Scenario Outline: Discount is applied by tier on every order
    Given I am a "<tier>" member
    And my cart subtotal is $100.00
    When I proceed to checkout
    Then my discount should be "<discount>"
    And my final subtotal should be "<final>"

    Examples:
      | tier  | discount | final |
      | Basic | $0.00    | $100.00 |
      | Silver | $5.00   | $95.00  |
      | Gold  | $10.00   | $90.00  |

  @smoke @p0
  Scenario: Redemption fails when insufficient points available
    Given my current points balance is 50
    When I attempt to redeem 100 points
    Then the redemption is rejected
    And I should see the message "You don't have enough points."
    And my points balance should remain 50

  @p1
  Scenario: Redemption succeeds and deducts points when balance is sufficient
    Given my current points balance is 100
    When I redeem 50 points
    Then the redemption succeeds
    And my new points balance should be 50

  @p0
  Scenario: Points page loads fast
    Given I navigate to my points dashboard
    When the page loads
    Then all content should be visible within 2 seconds
    And my current points balance should be displayed
    And my current tier should be displayed

  # Added by QA, explicit tier assignment for exact boundary values
  @p1
  Scenario Outline: Tier classification at boundary points
    Given I have exactly <points> lifetime points
    Then my tier should be "<tier>"

    Examples:
      | points | tier   |
      | 0      | Basic  |
      | 499    | Basic  |
      | 500    | Silver |
      | 1999   | Silver |
      | 2000   | Gold   |

  # Added by QA, clarification on discount scope (redemption vs automatic tier discount)
  @p2
  Scenario: Tier discount and redemption are separate benefits
    Given I am a Silver member with 100 points
    And an item costs $100.00
    When I check out
    Then I receive the Silver tier discount of $5.00
    And I can optionally redeem points for an additional benefit

**Assumptions:**
- Points are earned immediately upon order completion
- Tier status is calculated from cumulative lifetime points and applied instantly
- Tier discounts are automatic at checkout; no separate redemption needed for tier benefit
- Points may be redeemed for additional rewards (separate from automatic tier discounts)
- "Fast" page load is defined as all content rendering within 2 seconds
- Members can view their balance, tier, and redemption options on a dedicated points dashboard
