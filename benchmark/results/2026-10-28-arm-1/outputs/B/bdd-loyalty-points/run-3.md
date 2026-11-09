# Feature: Loyalty Points Program

## Scenario: Member earns whole dollar points from order subtotal
**Given** a member places an order with subtotal $24.99
**When** the order is completed
**Then** the member should earn 24 points
**And** the member's total points increase by 24

## Scenario: Member earns no fractional points
**Given** a member places an order with subtotal $99.99
**When** the order is completed
**Then** the member should earn 99 points

## Scenario: Determine Basic tier below 500 points
**Given** a member has 0 points
**When** the member views their account
**Then** their tier should be "Basic"
**And** no discount should apply to their orders

## Scenario: Determine Silver tier at 500 points
**Given** a member earns enough points to reach 500
**When** the member's account is updated
**Then** their tier should be "Silver"

## Scenario: Silver members receive 5% discount on all orders
**Given** a member with Silver tier places an order with subtotal $100
**When** the order is being calculated
**Then** a 5% discount ($5) should be applied
**And** the final price should be $95

## Scenario: Determine Gold tier at 2000 points
**Given** a member earns enough points to reach 2000
**When** the member's account is updated
**Then** their tier should be "Gold"

## Scenario: Gold members receive 10% discount on all orders
**Given** a member with Gold tier places an order with subtotal $100
**When** the order is being calculated
**Then** a 10% discount ($10) should be applied
**And** the final price should be $90

## Scenario: Insufficient points error when redeeming
**Given** a member has a balance of 100 points
**When** the member attempts to redeem 150 points
**Then** the system displays "You don't have enough points."
**And** no points are deducted
**And** the member's balance remains 100 points

## Scenario: Cannot redeem more points than balance (boundary)
**Given** a member has exactly 500 points
**When** the member attempts to redeem 501 points
**Then** the system displays "You don't have enough points."
**And** the member's balance remains 500 points

## Scenario: Successful points redemption
**Given** a member has 300 points
**When** the member redeems 100 points
**Then** the redemption succeeds
**And** the member's balance becomes 200 points

## Scenario: Points page loads within performance threshold
**Given** a member is logged into their account
**When** the member navigates to the points page
**Then** the page should fully load within 2 seconds
**And** all account balance and tier information should be displayed

## Scenario: Points page load time under typical network conditions
**Given** a member on a standard internet connection (3G/4G minimum)
**When** the member loads the points page
**Then** the initial render should occur within 2 seconds
**And** all key information should be visible
