# Feature: Loyalty Points

## Background
Given a member is logged into their loyalty account

## Scenario: Earn points from order subtotal (whole dollars only)
When a member completes an order with subtotal $24.99
Then the member earns 24 loyalty points

When a member completes an order with subtotal $100.50
Then the member earns 100 loyalty points

## Scenario: Member tier is Basic below 500 points
Given a member has 499 loyalty points
When they view their account
Then their tier displays as "Basic"
And no discount applies to orders

## Scenario: Member tier is Silver at 500 points
Given a member has 500 loyalty points
When they view their account
Then their tier displays as "Silver"
And a 5% discount applies to all future orders

## Scenario: Member tier is Gold at 2000 points
Given a member has 2000 loyalty points
When they view their account
Then their tier displays as "Gold"
And a 10% discount applies to all future orders

## Scenario: Silver member 5% discount at checkout
Given a member with Silver tier
And an order subtotal of $100
When they reach checkout
Then the discount of $5 is applied
And the total is $95

## Scenario: Gold member 10% discount at checkout
Given a member with Gold tier
And an order subtotal of $100
When they reach checkout
Then the discount of $10 is applied
And the total is $90

## Scenario: Cannot redeem more points than available
Given a member has 100 loyalty points
When they attempt to redeem 150 points
Then the message "You don't have enough points." appears
And their balance remains 100 points
And the redemption is cancelled

## Scenario: Points page loads fast
Given a member navigates to the points page
When the page loads
Then the page displays within 3 seconds
And all tier information and balance is visible

**Assumed labels and behavior:**
- Tier labels: "Basic", "Silver", "Gold" (as shown in AC-2)
- Discount applied automatically at checkout
- "Fast" load = 3 seconds or less
- Points earned on subtotal only (before tax/shipping)
- Redemption applies to future order discounts rather than a separate reward
