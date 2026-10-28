# Loyalty Points BDD Scenarios

**Assumptions:**
- Points are calculated and awarded immediately after order completion
- Tier benefits (discounts) apply automatically at checkout based on current point balance
- "Load fast" means page loads in under 2 seconds
- Redeeming points instantly deducts them from the member's balance
- A member with insufficient points cannot partially redeem

---

## Feature: Earn Loyalty Points

### Scenario: Member earns points from order subtotal
Given a member with an empty loyalty account
When the member completes an order with a subtotal of $24.99
Then the member should have 24 points

### Scenario: Member earns points from different subtotals
Given a member with an empty loyalty account
When the member completes an order with a subtotal of $99.99
Then the member should have 99 points

### Scenario: Fractional dollars are not awarded as points
Given a member with 10 points
When the member completes an order with a subtotal of $10.50
Then the member should have 20 points

---

## Feature: Loyalty Tier Calculation

### Scenario: Member starts in Basic tier
Given a new loyalty member
Then the member's tier should be "Basic"

### Scenario: Member reaches Silver tier at 500 points
Given a member with 499 points
When the member earns 1 point
Then the member's tier should change to "Silver"

### Scenario: Member reaches Gold tier at 2000 points
Given a member with 1999 points
When the member earns 1 point
Then the member's tier should change to "Gold"

### Scenario: Member tier is determined by current balance
Given a member with 2500 points
When the member redeems 600 points
Then the member's tier should change to "Silver"

---

## Feature: Tier Benefits

### Scenario: Silver member receives 5% discount
Given a member with 500 points in Silver tier
When the member completes an order with a subtotal of $100
Then a 5% discount should be applied
And the order total should be $95

### Scenario: Gold member receives 10% discount
Given a member with 2000 points in Gold tier
When the member completes an order with a subtotal of $100
Then a 10% discount should be applied
And the order total should be $90

### Scenario: Basic member receives no discount
Given a member with 100 points in Basic tier
When the member completes an order with a subtotal of $100
Then no discount should be applied
And the order total should be $100

---

## Feature: Redeem Loyalty Points

### Scenario: Member redeems valid points
Given a member with 300 points
When the member redeems 100 points
Then the member should have 200 points remaining

### Scenario: Member cannot redeem more points than balance
Given a member with 100 points
When the member attempts to redeem 150 points
Then an error message "You don't have enough points." should be displayed
And the member should still have 100 points

### Scenario: Failed redemption does not deduct points
Given a member with 50 points
When the member attempts to redeem 75 points and the transaction fails
Then the member should have 50 points
And no points should be deducted

---

## Feature: Points Page Performance

### Scenario: Points page loads within acceptable time
Given a member with an active loyalty account
When the member navigates to the points page
Then the page should fully load in under 2 seconds

### Scenario: Points page loads fast with large point balance
Given a member with 10,000 points
When the member navigates to the points page
Then the page should fully load in under 2 seconds
