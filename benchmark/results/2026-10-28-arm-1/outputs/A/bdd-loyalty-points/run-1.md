# Feature: Loyalty Points Programme

## Scenario: Earn points from order subtotal
Given I am a loyalty programme member
When I complete an order with a subtotal of $24.99
Then I should earn 24 points

## Scenario: Points calculation uses whole dollars only
Given I am a loyalty programme member
When I complete an order with a subtotal of $99.87
Then I should earn 99 points

## Scenario: Member starts at Basic tier
Given I am a new loyalty programme member
When I view my profile
Then my tier should be Basic
And I should receive no automatic discount

## Scenario: Advance to Silver tier
Given I am a Basic tier member with 499 points
When I complete an order earning 5 points
Then my tier should change to Silver
And my account should show 504 points
And future orders should include a 5% discount

## Scenario: Silver member receives discount
Given I am a Silver tier member
When I place an order with a subtotal of $100
Then a 5% discount should be applied
And my final total should be $95 before tax

## Scenario: Advance to Gold tier
Given I am a Silver tier member with 1,999 points
When I complete an order earning 5 points
Then my tier should change to Gold
And my account should show 2,004 points
And future orders should include a 10% discount

## Scenario: Gold member receives discount
Given I am a Gold tier member
When I place an order with a subtotal of $100
Then a 10% discount should be applied
And my final total should be $90 before tax

## Scenario: Prevent redemption exceeding balance
Given I am a loyalty programme member with 50 points
When I attempt to redeem 75 points
Then the system should display "You don't have enough points."
And my point balance should remain 50

## Scenario: Successful points redemption
Given I am a loyalty programme member with 500 points
When I redeem 100 points
Then my balance should be 400 points
And the redemption should be applied to my next purchase

## Scenario: Points page loads within acceptable time
Given I am a loyalty programme member
When I navigate to the points page
Then the page should display my current balance, tier, and redemption options
And the page should load within 1 second
