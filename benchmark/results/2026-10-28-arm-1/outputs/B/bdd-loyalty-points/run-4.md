# Loyalty Points Program

**Assumptions:**
- Points are calculated on order subtotal only (before tax/shipping)
- Tier discounts apply to the current order once the tier is achieved
- Currency is USD with standard 2 decimal place formatting
- "Fast" means points page loads within 2 seconds
- Points do not expire and have no maximum limit
- Basic tier includes members with 0-499 points

---

## Feature: Earn Loyalty Points

```gherkin
Scenario: Member earns 1 point per whole dollar
  Given a member with 0 points
  When they place an order with subtotal $24.99
  Then they earn 24 points
  And their points balance is 24

Scenario: Points ignore decimal amounts
  Given a member with 0 points
  When they place an order with subtotal $99.99
  Then they earn 99 points
  And not 100 points

Scenario: Multiple orders accumulate points
  Given a member with 24 points
  When they place an order with subtotal $76.50
  Then they earn 76 points
  And their total points balance is 100

Scenario: Large order earns proportional points
  Given a member with 0 points
  When they place an order with subtotal $500.00
  Then they earn 500 points
```

## Feature: Loyalty Tier System

```gherkin
Scenario: New member starts at Basic tier
  Given a new member
  Then their tier is Basic
  And they receive no discount

Scenario: Member reaches Silver tier at 500 points
  Given a member with 499 points
  When they place an order with subtotal $10.00
  Then they earn 10 points
  And their tier is Silver

Scenario: Member reaches Gold tier at 2000 points
  Given a member with 1999 points
  When they place an order with subtotal $5.00
  Then they earn 5 points
  And their tier is Gold

Scenario: Silver member tier discount is maintained
  Given a member with Silver tier (500 points)
  When they place an order with subtotal $100.00
  Then they receive 5% discount
  And the discount amount is $5.00
  And their total to pay is $95.00

Scenario: Gold member receives higher discount
  Given a member with Gold tier (2000 points)
  When they place an order with subtotal $100.00
  Then they receive 10% discount
  And the discount amount is $10.00
  And their total to pay is $90.00
```

## Feature: Redeem Loyalty Points

```gherkin
Scenario: Cannot redeem more points than available balance
  Given a member with 100 points
  When they attempt to redeem 150 points
  Then the system displays "You don't have enough points."
  And no points are deducted
  And their balance remains 100 points

Scenario: Cannot redeem more points with large balance
  Given a member with 1000 points
  When they attempt to redeem 2000 points
  Then the system displays "You don't have enough points."
  And no points are redeemed
  And their balance remains 1000 points

Scenario: Exact points redemption succeeds
  Given a member with exactly 200 points
  When they redeem 200 points
  Then the redemption succeeds
  And their balance becomes 0 points

Scenario: Partial redemption succeeds
  Given a member with 500 points
  When they redeem 300 points
  Then the redemption succeeds
  And their balance becomes 200 points
```

## Feature: Loyalty Points Page Performance

```gherkin
Scenario: Points page loads within acceptable time
  Given a member with 5000 points and Silver tier status
  When they navigate to the loyalty points page
  Then the page loads in less than 2 seconds
  And their current points balance is displayed
  And their tier level is displayed
  And redemption options are visible

Scenario: Points page displays accurate information
  Given a member with 750 points in Silver tier
  When they view the loyalty points page
  Then the balance shows exactly 750 points
  And the tier displays as Silver
  And the discount percentage shows as 5%

Scenario: Points page loads for new members
  Given a new member with 0 points
  When they navigate to the loyalty points page
  Then the page loads in less than 2 seconds
  And the tier displays as Basic
  And the balance shows 0 points
```
