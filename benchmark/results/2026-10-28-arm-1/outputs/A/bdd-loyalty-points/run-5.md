# Feature: Loyalty Points

## Background
Given a member with a loyalty account
And the member has a Basic tier status

## Scenario: Earn points based on order subtotal
When the member places an order with subtotal $24.99
Then the member earns 24 loyalty points
And the member's total points balance increases to 24

## Scenario: Earn points with fractional dollars
When the member places an order with subtotal $99.99
Then the member earns 99 loyalty points
And cents are not converted to points

## Scenario: Member maintains Basic tier below 500 points
Given the member has 499 loyalty points
When the member places an order
Then the member receives no tier discount on the order

## Scenario: Member upgrades to Silver tier at 500 points
Given the member has 499 loyalty points
When the member earns 1 more point
Then the member's tier changes to Silver
And the member receives 5% discount on future orders

## Scenario: Silver member receives discount on subsequent order
Given the member has Silver tier status
And the member has 500 loyalty points
When the member places an order with subtotal $100
Then the order subtotal is discounted by 5%
And the member earns 95 points (based on discounted subtotal)

## Scenario: Member upgrades to Gold tier at 2000 points
Given the member has Silver tier status
And the member has 1999 loyalty points
When the member earns 1 more point
Then the member's tier changes to Gold
And the member receives 10% discount on future orders

## Scenario: Gold member receives higher discount
Given the member has Gold tier status
And the member has 2000 loyalty points
When the member places an order with subtotal $100
Then the order subtotal is discounted by 10%
And the member earns 90 points (based on discounted subtotal)

## Scenario: Redeem points successfully
Given the member has 500 loyalty points
When the member redeems 100 points
Then 100 points are deducted from the balance
And the member receives a $1 credit (assuming 100 points = $1)
And the balance shows 400 remaining points

## Scenario: Redeem points with partial balance
Given the member has 50 loyalty points
When the member attempts to redeem 100 points
Then the redemption fails
And the error message displays "You don't have enough points."
And the points balance remains at 50

## Scenario: Redeem zero points
Given the member has 100 loyalty points
When the member attempts to redeem 0 points
Then the redemption fails
And the points balance remains at 100

## Scenario: Points page loads within acceptable time
When the member navigates to the loyalty points page
Then the page fully loads within 2 seconds
And all points balance and tier information is displayed
