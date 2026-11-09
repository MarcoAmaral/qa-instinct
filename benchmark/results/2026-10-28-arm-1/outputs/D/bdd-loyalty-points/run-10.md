@loyalty
Feature: Loyalty Programme — Earn and Redeem Points
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given I am a logged-in loyalty programme member
    And my account is in good standing

  # AC-1: Points earning
  @smoke @p0 @points-earning
  Scenario: Member earns 1 point per whole dollar of order subtotal
    Given my current points balance is 0
    When I complete an order with subtotal $24.99
    Then I earn 24 points
    And my points balance becomes 24

  # Added by QA, AC-1 does not specify how fractional dollars are handled
  @regression @p1 @points-earning
  Scenario: Points earned are truncated at the dollar — cents are ignored
    Given my current points balance is 0
    When I complete an order with subtotal $99.95
    Then I earn 99 points
    And my points balance becomes 99

  # Added by QA, multiple orders should accumulate points
  @regression @p1 @points-earning
  Scenario: Points accumulate across multiple orders
    Given my current points balance is 100
    When I complete an order with subtotal $50.00
    Then I earn 50 points
    And my points balance becomes 150

  # AC-2: Tier determination (Basic)
  @smoke @p0 @tiers
  Scenario: Member with fewer than 500 points is Basic tier
    Given my current points balance is 250
    When I place an order with subtotal $100.00
    Then my tier is Basic
    And no tier discount is applied
    And the order subtotal is $100.00

  # AC-2: Tier determination (Silver)
  @smoke @p0 @tiers
  Scenario: Member with 500+ points qualifies for Silver tier and receives 5% discount
    Given my current points balance is 500
    When I place an order with subtotal $100.00
    Then my tier is Silver
    And a 5% tier discount is applied
    And the order subtotal after discount is $95.00

  # AC-2: Tier determination (Gold)
  @smoke @p0 @tiers
  Scenario: Member with 2000+ points qualifies for Gold tier and receives 10% discount
    Given my current points balance is 2000
    When I place an order with subtotal $100.00
    Then my tier is Gold
    And a 10% tier discount is applied
    And the order subtotal after discount is $90.00

  # Added by QA, AC-2 does not define tier boundary behavior
  @regression @p1 @tiers
  Scenario: Member at Silver/Gold boundary (1999 points) remains Silver tier
    Given my current points balance is 1999
    When I view my tier information
    Then my tier is Silver
    And I am 1 point away from Gold

  # Added by QA, tier should change when points cross into new range
  @regression @p1 @tiers
  Scenario: Member tier downgrades when points fall below tier threshold
    Given my current points balance is 500 (Silver tier)
    When I redeem 50 points
    Then my points balance becomes 450
    And my tier reverts to Basic
    And the tier discount no longer applies to subsequent orders

  # AC-3: Redemption validation
  @smoke @p0 @redemption
  Scenario: Redemption request fails when points are insufficient
    Given my current points balance is 100
    When I attempt to redeem 150 points
    Then the system shows "You don't have enough points."
    And my points balance remains 100
    And the redemption is not processed

  # Added by QA, AC-3 does not specify success case; assuming member can redeem up to their balance
  @regression @p1 @redemption
  Scenario: Member can redeem points up to their current balance
    Given my current points balance is 100
    When I redeem 100 points
    Then my points balance becomes 0
    And the redemption succeeds

  # Added by QA, AC-3 implies partial redemption is allowed
  @regression @p1 @redemption
  Scenario: Member can redeem a partial amount of their points balance
    Given my current points balance is 500
    When I redeem 200 points
    Then my points balance becomes 300
    And the redemption succeeds

  # AC-4: Performance requirement for points page
  # Added by QA, AC-4 specifies load time but no target threshold; assuming <2 seconds is acceptable industry standard
  @regression @p2 @performance @non-functional
  Scenario: Points page loads within acceptable performance threshold
    Given I navigate to my loyalty points page
    When the page is fully loaded and interactive
    Then the page load time is under 2000 milliseconds
    And my current points balance is displayed
    And my current tier is displayed
    And my points history is visible

  # Added by QA, edge case for performance with large transaction history
  @regression @p2 @performance @non-functional
  Scenario: Points page maintains performance threshold even with extensive transaction history
    Given I am a member with 50+ historical transactions
    When I navigate to my loyalty points page
    And the full points history is rendered
    Then the page load time is under 2000 milliseconds
