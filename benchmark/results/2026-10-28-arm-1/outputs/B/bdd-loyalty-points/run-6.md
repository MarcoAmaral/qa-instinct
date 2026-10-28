# Feature: Loyalty Points System
As a member of the loyalty programme
I want to earn and redeem points
So that I get discounts on later orders

## Scenario: Member earns points based on order subtotal (whole dollars only)
Given I am a loyalty programme member
And my current points balance is 0
When I complete an order with a subtotal of $24.99
Then I should earn 24 points
And my total points balance should be 24

## Scenario: Multiple orders accumulate points correctly
Given I am a loyalty programme member
And my current points balance is 100
When I complete an order with a subtotal of $50.75
Then I should earn 50 points
And my total points balance should be 150

## Scenario: Member maintains Basic tier below 500 points
Given I am a loyalty programme member
And my points balance is 450
When I view my account
Then my tier should be Basic
And I should receive 0% discount on orders

## Scenario: Member reaches Silver tier at 500 points
Given I am a loyalty programme member
And my points balance is 500
When I view my account
Then my tier should be Silver
And I should be eligible for a 5% discount

## Scenario: Member reaches Gold tier at 2,000 points
Given I am a loyalty programme member
And my points balance is 2,000
When I view my account
Then my tier should be Gold
And I should be eligible for a 10% discount

## Scenario: Tier automatically updates when threshold is reached
Given I am a loyalty programme member with Basic tier
And my current points balance is 480
When I complete an order with a subtotal of $25
Then my points balance should be 505
And my tier should automatically update to Silver

## Scenario: Silver tier discount applies to order total
Given I am a Silver tier member
And my order subtotal is $100.00
When the discount is applied at checkout
Then the discount amount should be $5.00
And my final order total should be $95.00

## Scenario: Gold tier discount applies to order total
Given I am a Gold tier member
And my order subtotal is $100.00
When the discount is applied at checkout
Then the discount amount should be $10.00
And my final order total should be $90.00

## Scenario: Member successfully redeems available points
Given I am a loyalty programme member
And my points balance is 100
When I redeem 60 points
Then my points balance should be 40
And the redemption should complete successfully

## Scenario: Redemption fails when balance is insufficient
Given I am a loyalty programme member
And my points balance is 40
When I attempt to redeem 100 points
Then the system should display "You don't have enough points."
And my points balance should remain 40
And no points should be deducted

## Scenario: Redeeming exactly available balance
Given I am a loyalty programme member
And my points balance is 100
When I redeem 100 points
Then my points balance should be 0
And the redemption should complete successfully

## Scenario: Points page performance meets requirements
Given I am a loyalty programme member
And the system is operating normally
When I navigate to the loyalty points page
Then the page should fully load and be interactive within 2 seconds
