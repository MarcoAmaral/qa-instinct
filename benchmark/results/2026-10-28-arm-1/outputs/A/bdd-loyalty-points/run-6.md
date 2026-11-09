# Feature: Loyalty Points Programme

## Scenario: Earn points for order subtotal (whole dollars only)
**Given** a member with 0 points  
**When** they place an order with a subtotal of $24.99  
**Then** they should earn 24 points  
**And** their total points should be 24

## Scenario: Multiple orders accumulate points
**Given** a member with 100 points  
**When** they place an order with a subtotal of $50.75  
**Then** they should earn 50 points  
**And** their total points should be 150

## Scenario: Member automatically reaches Silver tier at 500 points
**Given** a member with 400 points  
**When** they place an order with a subtotal of $100.00  
**Then** they should earn 100 points  
**And** their tier should be Silver  
**And** they should receive 5% discount on this order

## Scenario: Silver tier member receives discount on subsequent orders
**Given** a Silver tier member with 600 points  
**When** they place an order with a subtotal of $100.00  
**Then** they should receive 5% discount  
**And** the final order total should be $95.00

## Scenario: Member automatically reaches Gold tier at 2000 points
**Given** a member with 1900 points  
**When** they place an order with a subtotal of $100.00  
**Then** they should earn 100 points  
**And** their tier should be Gold  
**And** they should receive 10% discount on this order

## Scenario: Gold tier member receives discount on subsequent orders
**Given** a Gold tier member with 2500 points  
**When** they place an order with a subtotal of $100.00  
**Then** they should receive 10% discount  
**And** the final order total should be $90.00

## Scenario: Member below 500 points stays in Basic tier
**Given** a member with 100 points  
**When** they place an order  
**Then** their tier should be Basic  
**And** they should receive no discount

## Scenario: Successfully redeem points within available balance
**Given** a member with 500 points  
**When** they redeem 100 points  
**Then** their points balance should be 400  
**And** the redemption should be successful

## Scenario: Redeem more points than available balance
**Given** a member with 100 points  
**When** they attempt to redeem 150 points  
**Then** the error message "You don't have enough points." should be displayed  
**And** their points balance should remain 100  
**And** no points should be redeemed

## Scenario: Points page renders quickly
**Given** a member with 1500 points  
**When** they navigate to their points page  
**Then** the page should fully load within 2 seconds  
**And** their current points balance should be displayed  
**And** their current tier should be displayed
