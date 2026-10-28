# Feature: Loyalty Points Management

## Scenario: Member earns points from order subtotal
**Given** a member has 0 loyalty points  
**When** they complete an order with a subtotal of $24.99  
**Then** they should earn 24 loyalty points  
**And** their total points balance should be 24

## Scenario: Points earned only from whole dollar amounts
**Given** a member has 100 loyalty points  
**When** they complete an order with a subtotal of $49.99  
**Then** they should earn 49 loyalty points  
**And** their total points balance should be 149

## Scenario: Member with Basic tier (under 500 points)
**Given** a member has 250 loyalty points  
**When** they view their account status  
**Then** their tier should be Basic  
**And** no discount should apply to their orders

## Scenario: Member qualifies for Silver tier at 500 points
**Given** a member has 500 loyalty points  
**When** they complete an order with a subtotal of $100  
**Then** their tier should be Silver  
**And** a 5% discount should be applied  
**And** the discounted subtotal should be $95

## Scenario: Member qualifies for Gold tier at 2000 points
**Given** a member has 2,000 loyalty points  
**When** they complete an order with a subtotal of $100  
**Then** their tier should be Gold  
**And** a 10% discount should be applied  
**And** the discounted subtotal should be $90

## Scenario: Member tier promotion applies immediately
**Given** a member has 499 loyalty points (Basic tier)  
**When** they earn 1,501 points from an order  
**Then** their tier should be Gold  
**And** the 10% discount should apply to subsequent orders

## Scenario: Redeem loyalty points successfully
**Given** a member has 150 loyalty points  
**When** they redeem 75 loyalty points  
**Then** the redemption should succeed  
**And** their points balance should be 75  
**And** the redemption value should be applied to their order

## Scenario: Insufficient points for redemption
**Given** a member has 50 loyalty points  
**When** they attempt to redeem 100 loyalty points  
**Then** the system should display "You don't have enough points."  
**And** their points balance should remain 50  
**And** no points should be deducted

## Scenario: Partial redemption attempt with exact balance
**Given** a member has 100 loyalty points  
**When** they redeem 100 loyalty points  
**Then** the redemption should succeed  
**And** their points balance should be 0

## Scenario: Points page loads within performance threshold
**When** a member navigates to their loyalty points page  
**Then** the page should fully load within 2 seconds  
**And** all account information including points balance and tier should be visible
