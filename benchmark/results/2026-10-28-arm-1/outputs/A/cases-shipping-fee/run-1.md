# Test Cases for SHIP-9: Shipping Fee at Checkout

## Assumptions
- Subtotal refers to the total price of items before shipping and taxes
- Member status is determined by account login status
- Standard shipping is the default option
- Express shipping is user-selectable at checkout
- All prices are in USD

---

## Test Case 1: Standard Shipping - Non-Member, Subtotal Below $50
**ID:** TC-SHIP-9-001  
**Scenario:** Non-member customer with order subtotal below minimum  
**Preconditions:** Customer is not logged in/not a member; shopping cart contains items totaling $49.99  
**Steps:**
1. Navigate to checkout
2. Select standard shipping
3. Review shipping fee

**Expected Result:** Shipping fee displays as $5.99

---

## Test Case 2: Standard Shipping - Non-Member, Subtotal Exactly $50
**ID:** TC-SHIP-9-002  
**Scenario:** Non-member customer with order subtotal at threshold  
**Preconditions:** Customer is not logged in/not a member; shopping cart contains items totaling $50.00  
**Steps:**
1. Navigate to checkout
2. Select standard shipping
3. Review shipping fee

**Expected Result:** Shipping fee displays as $0.00 (free)

---

## Test Case 3: Standard Shipping - Non-Member, Subtotal Above $50
**ID:** TC-SHIP-9-003  
**Scenario:** Non-member customer with order subtotal above threshold  
**Preconditions:** Customer is not logged in/not a member; shopping cart contains items totaling $75.00  
**Steps:**
1. Navigate to checkout
2. Select standard shipping
3. Review shipping fee

**Expected Result:** Shipping fee displays as $0.00 (free)

---

## Test Case 4: Standard Shipping - Member, Low Subtotal
**ID:** TC-SHIP-9-004  
**Scenario:** Member customer with order subtotal below $50  
**Preconditions:** Customer is logged in as a member; shopping cart contains items totaling $25.00  
**Steps:**
1. Navigate to checkout
2. Select standard shipping
3. Review shipping fee

**Expected Result:** Shipping fee displays as $0.00 (free)

---

## Test Case 5: Standard Shipping - Member, High Subtotal
**ID:** TC-SHIP-9-005  
**Scenario:** Member customer with order subtotal above $50  
**Preconditions:** Customer is logged in as a member; shopping cart contains items totaling $100.00  
**Steps:**
1. Navigate to checkout
2. Select standard shipping
3. Review shipping fee

**Expected Result:** Shipping fee displays as $0.00 (free)

---

## Test Case 6: Express Shipping - Non-Member, Low Subtotal
**ID:** TC-SHIP-9-006  
**Scenario:** Non-member customer selects express shipping  
**Preconditions:** Customer is not logged in/not a member; shopping cart contains items totaling $30.00  
**Steps:**
1. Navigate to checkout
2. Select express shipping
3. Review shipping fee

**Expected Result:** Shipping fee displays as $12.99

---

## Test Case 7: Express Shipping - Non-Member, High Subtotal
**ID:** TC-SHIP-9-007  
**Scenario:** Non-member customer with high subtotal selects express shipping  
**Preconditions:** Customer is not logged in/not a member; shopping cart contains items totaling $200.00  
**Steps:**
1. Navigate to checkout
2. Select express shipping
3. Review shipping fee

**Expected Result:** Shipping fee displays as $12.99

---

## Test Case 8: Express Shipping - Member, Low Subtotal
**ID:** TC-SHIP-9-008  
**Scenario:** Member customer with low subtotal selects express shipping  
**Preconditions:** Customer is logged in as a member; shopping cart contains items totaling $10.00  
**Steps:**
1. Navigate to checkout
2. Select express shipping
3. Review shipping fee

**Expected Result:** Shipping fee displays as $7.99

---

## Test Case 9: Express Shipping - Member, High Subtotal
**ID:** TC-SHIP-9-009  
**Scenario:** Member customer with high subtotal selects express shipping  
**Preconditions:** Customer is logged in as a member; shopping cart contains items totaling $150.00  
**Steps:**
1. Navigate to checkout
2. Select express shipping
3. Review shipping fee

**Expected Result:** Shipping fee displays as $7.99

---

## Test Case 10: Shipping Fee Persists on Order Review
**ID:** TC-SHIP-9-010  
**Scenario:** Verify shipping fee calculation remains consistent through checkout flow  
**Preconditions:** Non-member customer; shopping cart contains items totaling $60.00; standard shipping selected  
**Steps:**
1. Navigate to checkout
2. Select standard shipping (displays $0.00)
3. Review order summary
4. Proceed to payment page
5. Review shipping fee

**Expected Result:** Shipping fee remains $0.00 throughout checkout flow

---

## Test Case 11: Switching Shipping Methods Updates Fee
**ID:** TC-SHIP-9-011  
**Scenario:** Non-member customer switches from standard to express shipping  
**Preconditions:** Non-member customer; shopping cart contains items totaling $60.00; standard shipping initially selected  
**Steps:**
1. Navigate to checkout
2. Standard shipping is selected, displays $0.00
3. Switch to express shipping
4. Review updated shipping fee

**Expected Result:** Shipping fee updates to $12.99

---

## Test Case 12: Member Status Discount Applied
**ID:** TC-SHIP-9-012  
**Scenario:** Verify member discount applies to express shipping  
**Preconditions:** Customer logs in as a member; shopping cart contains items totaling $30.00; express shipping selected  
**Steps:**
1. Navigate to checkout while logged in as member
2. Select express shipping
3. Review shipping fee

**Expected Result:** Shipping fee displays as $7.99 (member discount applied, not $12.99)

---

## Test Case 13: Boundary - Subtotal $49.99 vs $50.00
**ID:** TC-SHIP-9-013  
**Scenario:** Non-member comparing shipping costs at the $50 threshold  
**Preconditions:** Create two scenarios with subtotals $49.99 and $50.00; non-member; standard shipping  
**Steps:**
1. Order 1: Checkout with $49.99 subtotal, standard shipping
2. Order 2: Checkout with $50.00 subtotal, standard shipping
3. Compare shipping fees

**Expected Result:** Order 1 shows $5.99; Order 2 shows $0.00

---

## Test Case 14: Member Membership Verification Required
**ID:** TC-SHIP-9-014  
**Scenario:** Non-member attempting to use member pricing  
**Preconditions:** Customer not logged in; shopping cart contains items totaling $25.00  
**Steps:**
1. Navigate to checkout without logging in
2. Select standard shipping
3. Attempt to apply member discount manually (if UI allows)

**Expected Result:** Shipping fee displays as $5.99; member discounts not applied
