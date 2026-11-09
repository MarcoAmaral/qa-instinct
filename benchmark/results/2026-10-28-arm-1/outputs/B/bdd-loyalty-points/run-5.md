# Feature: Loyalty Points Program

**Assumptions:**
- Points are awarded immediately upon order completion
- Tier changes apply immediately upon reaching threshold
- Discounts are applied at checkout for members' current tier
- "Fast loading" = page loads within 2 seconds
- The member is already logged into their account
- Points are displayed as integers

---

## Scenario: Earn points for whole dollars spent

Given a member has 0 points  
When the member completes an order with subtotal $24.99  
Then the member's points balance should be 24

## Scenario: Earn points with multiple orders

Given a member has 0 points  
When the member completes an order with subtotal $100.00  
And the member completes another order with subtotal $50.50  
Then the member's points balance should be 150

## Scenario: Cents are not counted toward points

Given a member has 0 points  
When the member completes an order with subtotal $10.99  
Then the member should earn 10 points, not 11

## Scenario: Member reaches Silver tier at exactly 500 points

Given a member has 499 points  
When the member completes an order with subtotal $1.00  
Then the member's points balance should be 500  
And the member's tier should be Silver

## Scenario: Member reaches Gold tier at 2000 points

Given a member has 1,900 points  
When the member completes an order with subtotal $100.00  
Then the member's points balance should be 2000  
And the member's tier should be Gold

## Scenario: Silver member receives 5% discount

Given a member has 500 points and tier is Silver  
When the member proceeds to checkout with subtotal $100.00  
Then the discount applied should be $5.00  
And the final total should be $95.00

## Scenario: Gold member receives 10% discount

Given a member has 2,000 points and tier is Gold  
When the member proceeds to checkout with subtotal $100.00  
Then the discount applied should be $10.00  
And the final total should be $90.00

## Scenario: Basic tier member receives no discount

Given a member has 100 points and tier is Basic  
When the member proceeds to checkout with subtotal $100.00  
Then no discount should be applied  
And the final total should be $100.00

## Scenario: Redeem points with insufficient balance

Given a member has 50 points  
When the member attempts to redeem 100 points  
Then the error message should display "You don't have enough points."  
And the points balance should remain 50

## Scenario: Redeem points with exact balance

Given a member has 100 points  
When the member redeems 100 points  
Then the points balance should be 0  
And the redemption should be successful

## Scenario: Redeem partial points

Given a member has 500 points  
When the member redeems 250 points  
Then the points balance should be 250  
And the redemption should be successful

## Scenario: Points page loads within performance threshold

Given a member is on the loyalty points page  
When the page begins to load  
Then the page should be fully loaded and interactive within 2 seconds  
And all member information (points balance, tier, transaction history) should be displayed
