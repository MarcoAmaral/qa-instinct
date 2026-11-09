# Feature: Loyalty Points Program
  As a member of the loyalty programme
  I want to earn and redeem points
  So that I get discounts on later orders

  Background:
    Given a loyalty programme member is logged in

  Scenario: Member earns 1 point per whole dollar of order subtotal
    Given a member with 0 loyalty points
    When they complete an order with subtotal $24.99
    Then they should have 24 loyalty points
    And they should have 24 loyalty points when order with subtotal $100.55 completes
    Then they should have 124 loyalty points

  Scenario: Member earns no points for fractional dollars
    Given a member with 0 loyalty points
    When they complete an order with subtotal $0.99
    Then they should have 0 loyalty points

  Scenario: Member tier is Basic below 500 points
    Given a member with 499 loyalty points
    Then their tier should be "Basic"
    And they should receive 0% discount on orders

  Scenario: Member tier is Silver at 500 points
    Given a member with 500 loyalty points
    Then their tier should be "Silver"
    And they should receive 5% discount on orders

  Scenario: Member tier is Gold at 2000 points
    Given a member with 2000 loyalty points
    Then their tier should be "Gold"
    And they should receive 10% discount on orders

  Scenario: Silver member receives 5% discount
    Given a member with 500 loyalty points and "Silver" tier
    When they place an order with subtotal $100.00
    Then the discount applied should be $5.00
    And their total due should be $95.00

  Scenario: Gold member receives 10% discount
    Given a member with 2000 loyalty points and "Gold" tier
    When they place an order with subtotal $100.00
    Then the discount applied should be $10.00
    And their total due should be $90.00

  Scenario: Discount is applied at checkout
    Given a member with 500 loyalty points
    When they add $200.00 of items to cart
    And they proceed to checkout
    Then the system should apply 5% Silver discount to their order

  Scenario: Cannot redeem more points than balance
    Given a member with 100 loyalty points
    When they attempt to redeem 250 loyalty points
    Then the redemption should fail
    And they should see "You don't have enough points."
    And their balance should remain 100 loyalty points

  Scenario: Can redeem points within balance
    Given a member with 500 loyalty points
    When they redeem 250 loyalty points
    Then the redemption should succeed
    And their balance should be 250 loyalty points

  Scenario: Cannot redeem more than available but can redeem entire balance
    Given a member with 500 loyalty points
    When they redeem 500 loyalty points
    Then the redemption should succeed
    And their balance should be 0 loyalty points

  Scenario: Points page loads within acceptable time
    Given a member is logged in
    When they navigate to the loyalty points page
    Then the page should load within 2 seconds
    And they should see their current point balance
    And they should see their membership tier

  Scenario: Tier upgrade triggers when points threshold is reached
    Given a member with 499 loyalty points and "Basic" tier
    When they complete an order earning 1 loyalty point
    Then their balance should be 500 loyalty points
    And their tier should automatically upgrade to "Silver"

  Scenario: Tier upgrade to Gold occurs at 2000 points
    Given a member with 1999 loyalty points and "Silver" tier
    When they complete an order earning 1 loyalty point
    Then their balance should be 2000 loyalty points
    And their tier should automatically upgrade to "Gold"
