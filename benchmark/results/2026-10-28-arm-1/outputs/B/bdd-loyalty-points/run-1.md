# Loyalty Points Feature

## Feature: Earn and Redeem Loyalty Points
As a member of the loyalty programme
I want to earn and redeem points
So that I get discounts on later orders

### Scenario: Member earns 1 point per whole dollar of order subtotal
Given I am a loyalty programme member
When I place an order with a subtotal of $24.99
Then I should earn 24 points

### Scenario: Member earns points for orders with whole dollar amounts
Given I am a loyalty programme member
When I place an order with a subtotal of $100.00
Then I should earn 100 points

### Scenario: Member earns no points for fractional dollar amounts below 1 dollar
Given I am a loyalty programme member
When I place an order with a subtotal of $0.99
Then I should earn 0 points

### Scenario: Member earns points for multiple orders
Given I am a loyalty programme member with 50 earned points
When I place an order with a subtotal of $30.00
Then my total points should be 80

### Scenario: New member has Basic tier by default
Given I am a newly registered loyalty programme member
When I check my tier
Then my tier should be Basic

### Scenario: Member advances to Silver tier at 500 points
Given I am a loyalty programme member with 499 points
When I place an order with a subtotal of $1.00
Then my tier should be Silver

### Scenario: Silver member receives 5% discount on orders
Given I am a loyalty programme member with Silver tier (500+ points)
When I place an order with a subtotal of $100.00
Then the discount applied should be $5.00

### Scenario: Member advances to Gold tier at 2000 points
Given I am a loyalty programme member with 1999 points
When I place an order with a subtotal of $1.00
Then my tier should be Gold

### Scenario: Gold member receives 10% discount on orders
Given I am a loyalty programme member with Gold tier (2000+ points)
When I place an order with a subtotal of $100.00
Then the discount applied should be $10.00

### Scenario: Member cannot redeem more points than balance
Given I am a loyalty programme member with 100 points
When I attempt to redeem 150 points
Then I should see the message "You don't have enough points."
And no points should be redeemed

### Scenario: Member can redeem points equal to current balance
Given I am a loyalty programme member with 100 points
When I redeem 100 points
Then my points balance should be 0
And the redemption should be successful

### Scenario: Member can redeem fewer points than balance
Given I am a loyalty programme member with 500 points
When I redeem 250 points
Then my points balance should be 250
And the redemption should be successful

### Scenario: Points page loads within acceptable time
Given I am viewing the loyalty points page
When the page loads
Then it should load in under 2 seconds

### Scenario: Points page displays current balance and tier
Given I am a loyalty programme member with 750 points and Silver tier
When I view the points page
Then I should see my current balance of 750 points
And I should see my tier is Silver
