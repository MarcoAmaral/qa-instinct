# Feature: Loyalty Points Program

As a member of the loyalty programme
I want to earn and redeem points
So that I get discounts on later orders

## Scenario: Member earns 1 point per whole dollar spent

Given I am a loyalty programme member
When I complete an order with a subtotal of $24.99
Then I should earn 24 loyalty points

## Scenario: Large order earns points rounded down

Given I am a loyalty programme member
When I complete an order with a subtotal of $150.75
Then I should earn 150 loyalty points

## Scenario: New member starts at Basic tier

Given I am a new loyalty programme member with 0 points
When I check my membership tier
Then my tier should be "Basic"

## Scenario: Member advances to Silver tier at 500 points

Given I am a loyalty programme member with 500 points
When I check my membership tier
Then my tier should be "Silver"

## Scenario: Member advances to Gold tier at 2000 points

Given I am a loyalty programme member with 2000 points
When I check my membership tier
Then my tier should be "Gold"

## Scenario: Silver member receives 5% discount

Given I am a Silver tier member
When I proceed to checkout with an order subtotal of $100
Then a 5% discount should be applied
And my order total should be $95.00 before taxes

## Scenario: Gold member receives 10% discount

Given I am a Gold tier member
When I proceed to checkout with an order subtotal of $100
Then a 10% discount should be applied
And my order total should be $90.00 before taxes

## Scenario: Cannot redeem more points than balance

Given I am a loyalty programme member with 100 points
When I attempt to redeem 150 points
Then I should see the error message "You don't have enough points."
And my points balance should remain 100
And no redemption should occur

## Scenario: Redeem points equal to balance

Given I am a loyalty programme member with 150 points
When I redeem 150 points
Then my points balance should be 0
And the redemption should complete successfully

## Scenario: Points page loads quickly

Given I am a logged-in loyalty programme member
When I navigate to the points page
Then the page should load within 2 seconds
And my points balance should be displayed
And my membership tier should be displayed
And available redemption options should be visible

**Assumptions made:**
- Points earned from order subtotals are rounded down to the nearest whole number
- Tier discounts are applied automatically at checkout
- A "fast" page load is defined as completing within 2 seconds
- Redemption occurs at the points page or a dedicated redemption interface
- Basic tier members receive no discount (0%)
