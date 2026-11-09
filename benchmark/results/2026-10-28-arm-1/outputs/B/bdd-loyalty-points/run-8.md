# Feature: Loyalty Points Earning and Redemption

As a member of the loyalty programme
I want to earn and redeem points
So that I get discounts on later orders

## Scenario: Member earns points from order subtotal (AC-1)
Given a loyalty programme member with 0 points
When the member places an order with subtotal $24.99
Then the member should earn 24 points
And the member's total points balance should be 24

## Scenario: Member earns points rounded down for partial dollars (AC-1)
Given a loyalty programme member with 0 points
When the member places an order with subtotal $49.87
Then the member should earn 49 points
And the member's total points balance should be 49

## Scenario: Member maintains Basic tier below 500 points (AC-2)
Given a loyalty programme member with 400 points
When the member views their loyalty tier
Then the loyalty tier should be "Basic"
And the discount rate should be 0%

## Scenario: Member achieves Silver tier at 500 points (AC-2)
Given a loyalty programme member with 500 points
When the member places an order with subtotal $100.00
Then the order subtotal should be discounted by 5%
And the final order total should be $95.00

## Scenario: Member achieves Gold tier at 2000 points (AC-2)
Given a loyalty programme member with 2000 points
When the member places an order with subtotal $100.00
Then the order subtotal should be discounted by 10%
And the final order total should be $90.00

## Scenario: Silver tier discount applied on subsequent orders (AC-2)
Given a loyalty programme member with 500 points
When the member places multiple orders while Silver tier
Then each order should receive the 5% discount
And the tier should not change if points remain above 500

## Scenario: Member cannot redeem more points than balance (AC-3)
Given a loyalty programme member with 100 points
When the member attempts to redeem 150 points
Then an error message should display "You don't have enough points."
And the member's points balance should remain 100
And no redemption should be applied

## Scenario: Member can redeem points within balance (AC-3)
Given a loyalty programme member with 100 points
When the member redeems 50 points
Then the redemption should succeed
And the member's points balance should be 50

## Scenario: Points page loads within acceptable time (AC-4)
Given a loyalty programme member is logged in
When the member navigates to the points page
Then the page should load within 3 seconds
And all loyalty information should be fully displayed

## Scenario: Points page displays accurate balance (AC-4)
Given a loyalty programme member with 750 points
When the member views the points page
Then the displayed balance should be 750 points
And the current tier should be displayed as "Silver"
And the available discount should be shown as 5%
