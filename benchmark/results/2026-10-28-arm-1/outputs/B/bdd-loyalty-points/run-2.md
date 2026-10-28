# Feature: Loyalty Points

## Scenario: Member earns points on order completion
Given a loyalty programme member with a current balance of 0 points
When they complete an order with a subtotal of $24.99
Then they should earn 24 points
And their new balance should be 24 points

## Scenario: Member earns points for each whole dollar
Given a loyalty programme member with a current balance of 100 points
When they complete an order with a subtotal of $99.75
Then they should earn 99 points
And their new balance should be 199 points

## Scenario: Zero points earned on subtotal under one dollar
Given a loyalty programme member with a current balance of 50 points
When they complete an order with a subtotal of $0.50
Then they should earn 0 points
And their new balance should be 50 points

## Scenario: Member is classified as Basic tier
Given a loyalty programme member with a current balance of 499 points
Then their tier should be "Basic"

## Scenario: Member is classified as Silver tier
Given a loyalty programme member with a current balance of 500 points
Then their tier should be "Silver"

## Scenario: Member is classified as Gold tier
Given a loyalty programme member with a current balance of 2000 points
Then their tier should be "Gold"

## Scenario: Silver member receives automatic discount
Given a Silver tier member with 500 points
When they complete an order with a subtotal of $100
Then a 5% discount ($5.00) should be automatically applied
And the final total should be $95.00

## Scenario: Gold member receives automatic discount
Given a Gold tier member with 2000 points
When they complete an order with a subtotal of $100
Then a 10% discount ($10.00) should be automatically applied
And the final total should be $90.00

## Scenario: Basic member receives no automatic discount
Given a Basic tier member with 100 points
When they complete an order with a subtotal of $100
Then no automatic discount should be applied
And the final total should be $100.00

## Scenario: Member cannot redeem more points than available balance
Given a loyalty programme member with a balance of 50 points
When they attempt to redeem 60 points
Then the redemption should fail
And the error message should display "You don't have enough points."
And their balance should remain 50 points

## Scenario: Member can redeem up to their available balance
Given a loyalty programme member with a balance of 100 points
When they redeem 100 points
Then the redemption should succeed
And their new balance should be 0 points

## Scenario: Points page loads within acceptable time
Given a loyalty programme member on the points page
When the page initializes
Then the page should fully load in under 2 seconds
And all point balance, tier status, and redemption options should be displayed

---

**Assumptions Made:**
- Points are earned and credited immediately upon order completion
- Tier status updates automatically based on current point balance
- Silver tier discount threshold is 500-1999 points (Gold starts at 2000)
- Automatic tier discounts are applied at checkout before redeeming points
- Redemption is a separate action from earning and tier discounts
- Page load time acceptable threshold is under 2 seconds (measured from navigation initiation to full DOM readiness)
- Point redemption amounts are assumed to be in whole numbers with no fractional points
- The 1 point per dollar rule applies to the subtotal before any taxes or fees
