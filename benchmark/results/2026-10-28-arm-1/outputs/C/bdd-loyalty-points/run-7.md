Feature: Loyalty points

Scenario: Earn 1 point per whole dollar of order subtotal
  Given a member has 0 points
  When the member places an order with subtotal $24.99
  Then the member earns 24 points
  And the member has 24 points

Scenario: Order with multiple whole dollars earns proportional points
  Given a member has 0 points
  When the member places an order with subtotal $100.50
  Then the member earns 100 points

Scenario: Member qualifies for Basic tier below 500 points
  Given a member has 499 points
  Then the member's tier is Basic
  And the member receives 0% discount on orders

Scenario: Member qualifies for Silver tier at 500 points
  Given a member has 500 points
  Then the member's tier is Silver
  And the member receives 5% discount on orders

Scenario: Member qualifies for Gold tier at 2000 points
  Given a member has 2000 points
  Then the member's tier is Gold
  And the member receives 10% discount on orders

Scenario: Silver tier discount applies to order total
  Given a member with tier Silver placing an order with subtotal $100
  When the order is finalized
  Then a 5% discount is applied to the order

Scenario: Gold tier discount applies to order total
  Given a member with tier Gold placing an order with subtotal $100
  When the order is finalized
  Then a 10% discount is applied to the order

Scenario: Cannot redeem points exceeding balance
  Given a member has 100 points
  When the member attempts to redeem 150 points
  Then the redemption is rejected
  And the message "You don't have enough points." is displayed
  And the member's balance remains 100 points

Scenario: Successful redemption deducts points
  Given a member has 100 points
  When the member redeems 50 points
  Then the redemption succeeds
  And the member's balance becomes 50 points

Scenario: Points page load time meets performance requirement
  Given a member is logged in
  When the member navigates to the points page
  Then the page loads in under 1 second
