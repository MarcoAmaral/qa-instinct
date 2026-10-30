# Feature: Loyalty Points

As a member of the loyalty programme
I want to earn and redeem points
So that I get discounts on later orders

## Scenario: Earn points based on order subtotal
Given a member completes an order with a subtotal of $24.99
When the order is confirmed
Then the member earns 24 points

## Scenario: Earn points with dollar increments only
Given a member completes an order with a subtotal of $100.50
When the order is confirmed
Then the member earns 100 points

## Scenario: Member reaches Silver tier at 500 points
Given a member has 400 points
And completes an order with a subtotal of $100
When the order is confirmed
Then the member has 500 points
And the member's tier is Silver

## Scenario: Member reaches Gold tier at 2000 points
Given a member has 1900 points
And completes an order with a subtotal of $100
When the order is confirmed
Then the member has 2000 points
And the member's tier is Gold

## Scenario: Silver member receives 5% discount
Given a member is Silver tier with 500 points
And adds items totalling $100 to the cart
When proceeding to checkout
Then a 5% discount is applied to the order total
And the subtotal for points earning remains $100

## Scenario: Gold member receives 10% discount
Given a member is Gold tier with 2000 points
And adds items totalling $100 to the cart
When proceeding to checkout
Then a 10% discount is applied to the order total
And the subtotal for points earning remains $100

## Scenario: Basic member receives no discount
Given a member is Basic tier with 100 points
And adds items totalling $100 to the cart
When proceeding to checkout
Then no discount is applied

## Scenario: Redeem points with insufficient balance
Given a member has 50 points
When attempting to redeem 100 points
Then the redemption fails
And the message "You don't have enough points." is displayed
And the member retains 50 points

## Scenario: Redeem points with sufficient balance
Given a member has 100 points
When redeeming 50 points
Then the redemption succeeds
And the member has 50 points remaining

## Scenario: Points page loads within acceptable time
Given a member with 1500 loyalty points
When accessing the loyalty points page
Then the page loads within 2 seconds
And displays the current points balance
And displays the current tier
And displays redemption options
