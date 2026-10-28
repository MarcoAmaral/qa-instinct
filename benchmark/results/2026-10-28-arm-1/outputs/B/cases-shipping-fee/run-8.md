# Test Cases for SHIP-9: Shipping Fee at Checkout

## Assumptions
- Shipping fees are calculated based on order subtotal (excluding taxes and shipping)
- "Member" status is determined at checkout time based on logged-in user account
- Shipping method selection occurs before payment
- Standard shipping is the default option
- Currency is USD
- Checkout page displays the calculated shipping fee before order confirmation
- Non-members are users without active membership status
- Express shipping is an optional upgrade available to all users

---

## Test Case 1: Standard Shipping - Non-Member with Subtotal Below $50
**ID:** SHIP-9-TC-001  
**Title:** Verify $5.99 standard shipping fee for non-member with subtotal under $50  
**Preconditions:**
- User is not a member
- User is at checkout with an order subtotal of $40.00

**Steps:**
1. Proceed to checkout
2. Review shipping options
3. Confirm standard shipping is selected

**Expected Result:**
- Standard shipping fee displays as $5.99
- Order total = $40.00 + $5.99 = $45.99

---

## Test Case 2: Standard Shipping - Non-Member with Subtotal Exactly $50.00
**ID:** SHIP-9-TC-002  
**Title:** Verify free standard shipping for non-member when subtotal equals $50.00  
**Preconditions:**
- User is not a member
- User is at checkout with an order subtotal of $50.00

**Steps:**
1. Proceed to checkout
2. Review shipping options
3. Confirm standard shipping is selected

**Expected Result:**
- Standard shipping fee displays as $0.00 (free)
- Order total = $50.00

---

## Test Case 3: Standard Shipping - Non-Member with Subtotal Above $50
**ID:** SHIP-9-TC-003  
**Title:** Verify free standard shipping for non-member with subtotal over $50.00  
**Preconditions:**
- User is not a member
- User is at checkout with an order subtotal of $75.50

**Steps:**
1. Proceed to checkout
2. Review shipping options
3. Confirm standard shipping is selected

**Expected Result:**
- Standard shipping fee displays as $0.00 (free)
- Order total = $75.50

---

## Test Case 4: Standard Shipping - Member with Low Subtotal
**ID:** SHIP-9-TC-004  
**Title:** Verify free standard shipping for member regardless of subtotal  
**Preconditions:**
- User is a member
- User is at checkout with an order subtotal of $15.00

**Steps:**
1. Proceed to checkout
2. Review shipping options
3. Confirm standard shipping is selected

**Expected Result:**
- Standard shipping fee displays as $0.00 (free)
- Order total = $15.00

---

## Test Case 5: Standard Shipping - Member with High Subtotal
**ID:** SHIP-9-TC-005  
**Title:** Verify free standard shipping for member at any subtotal  
**Preconditions:**
- User is a member
- User is at checkout with an order subtotal of $200.00

**Steps:**
1. Proceed to checkout
2. Review shipping options
3. Confirm standard shipping is selected

**Expected Result:**
- Standard shipping fee displays as $0.00 (free)
- Order total = $200.00

---

## Test Case 6: Express Shipping - Non-Member
**ID:** SHIP-9-TC-006  
**Title:** Verify $12.99 express shipping fee for non-member  
**Preconditions:**
- User is not a member
- User is at checkout with an order subtotal of $30.00

**Steps:**
1. Proceed to checkout
2. Select express shipping option
3. Review shipping fee

**Expected Result:**
- Express shipping fee displays as $12.99
- Order total = $30.00 + $12.99 = $42.99

---

## Test Case 7: Express Shipping - Member
**ID:** SHIP-9-TC-007  
**Title:** Verify $7.99 express shipping fee for member  
**Preconditions:**
- User is a member
- User is at checkout with an order subtotal of $60.00

**Steps:**
1. Proceed to checkout
2. Select express shipping option
3. Review shipping fee

**Expected Result:**
- Express shipping fee displays as $7.99
- Order total = $60.00 + $7.99 = $67.99

---

## Test Case 8: Express Shipping - Member with Low Subtotal
**ID:** SHIP-9-TC-008  
**Title:** Verify $7.99 express shipping for member at any subtotal  
**Preconditions:**
- User is a member
- User is at checkout with an order subtotal of $10.00

**Steps:**
1. Proceed to checkout
2. Select express shipping option
3. Review shipping fee

**Expected Result:**
- Express shipping fee displays as $7.99 (not affected by subtotal)
- Order total = $10.00 + $7.99 = $17.99

---

## Test Case 9: Shipping Fee Update on Subtotal Change (Non-Member)
**ID:** SHIP-9-TC-009  
**Title:** Verify shipping fee updates correctly when subtotal changes from below to above $50  
**Preconditions:**
- User is not a member
- User is at checkout with an initial order subtotal of $45.00
- Standard shipping is selected

**Steps:**
1. Verify shipping fee displays as $5.99
2. Add an item causing subtotal to reach $50.00
3. Observe shipping fee update

**Expected Result:**
- Initial shipping fee: $5.99
- After subtotal update: $0.00 (free)
- Order total updates accordingly

---

## Test Case 10: Membership Status Change During Checkout
**ID:** SHIP-9-TC-010  
**Title:** Verify shipping fee reflects membership status at calculation time  
**Preconditions:**
- User starts as non-member at checkout with $30.00 subtotal
- Standard shipping selected

**Steps:**
1. Verify initial shipping fee displays as $5.99
2. Apply membership during checkout
3. Observe shipping fee update

**Expected Result:**
- Initial fee (non-member): $5.99
- After membership applied: $0.00 (free)
- System correctly reflects member status for shipping calculation

---

## Test Case 11: Switch Between Shipping Methods
**ID:** SHIP-9-TC-011  
**Title:** Verify correct fee displays when switching between standard and express shipping  
**Preconditions:**
- User is not a member
- Order subtotal is $30.00

**Steps:**
1. Select standard shipping (observe fee)
2. Switch to express shipping (observe fee)
3. Switch back to standard shipping

**Expected Result:**
- Standard shipping: $5.99
- Express shipping: $12.99
- Back to standard: $5.99
- Fees update correctly with each selection

---

## Test Case 12: Free Shipping Threshold Edge Case - $49.99
**ID:** SHIP-9-TC-012  
**Title:** Verify $5.99 charge for non-member just below $50 threshold  
**Preconditions:**
- User is not a member
- Order subtotal is $49.99

**Steps:**
1. Proceed to checkout
2. Select standard shipping

**Expected Result:**
- Standard shipping fee displays as $5.99 (does not qualify for free shipping)
- Order total = $49.99 + $5.99 = $55.98

---

## Test Case 13: Express vs Standard Shipping Comparison - Member
**ID:** SHIP-9-TC-013  
**Title:** Verify member express shipping costs less than non-member express  
**Preconditions:**
- One member account and one non-member account
- Both at checkout with same $40.00 subtotal
- Both comparing express shipping

**Steps:**
1. Check non-member express shipping fee
2. Check member express shipping fee
3. Compare costs

**Expected Result:**
- Non-member express: $12.99
- Member express: $7.99
- Member savings: $5.00 per order on express shipping

---

## Test Case 14: Free Shipping Confirmation for Member (No Fees)
**ID:** SHIP-9-TC-014  
**Title:** Verify member with standard shipping shows zero shipping costs  
**Preconditions:**
- User is a member
- Order subtotal is $1.00 (any amount)
- Standard shipping selected

**Steps:**
1. Proceed to checkout
2. Verify standard shipping option
3. Check shipping fee display

**Expected Result:**
- Shipping fee displays as $0.00
- No shipping charge appears on order
- Member benefits applied correctly

---

## Test Case 15: Non-Member Large Order - Standard Shipping Free
**ID:** SHIP-9-TC-015  
**Title:** Verify free standard shipping for non-member on large order  
**Preconditions:**
- User is not a member
- Order subtotal is $500.00
- Standard shipping selected

**Steps:**
1. Proceed to checkout
2. Review standard shipping option

**Expected Result:**
- Standard shipping fee displays as $0.00 (free)
- Free shipping based on subtotal threshold, not membership
- Order total = $500.00
