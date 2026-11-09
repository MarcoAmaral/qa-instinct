# Test Cases: SHIP-9 Shipping Fee at Checkout

## Assumptions
- Shipping fees are calculated based on order subtotal (before tax)
- "Members" are authenticated users with active membership status
- Shipping method must be selected before fee calculation
- System maintains accurate membership status for logged-in users
- No promotional codes or discounts affect base shipping fees
- Non-members are unauthenticated users or users without active membership

---

## Test Case 1: Standard Shipping - Non-Member Below $50 Threshold

**Preconditions:**
- User is not logged in or has no active membership
- Standard shipping is selected

**Steps:**
1. Add item(s) to cart with subtotal $49.99
2. Proceed to checkout
3. Verify shipping method is set to "Standard"
4. Observe shipping fee display

**Expected Result:**
- Shipping fee displays as $5.99
- Order total includes $5.99 shipping charge

---

## Test Case 2: Standard Shipping - Non-Member At $50 Threshold

**Preconditions:**
- User is not logged in or has no active membership
- Standard shipping is selected

**Steps:**
1. Add item(s) to cart with subtotal exactly $50.00
2. Proceed to checkout
3. Verify shipping method is set to "Standard"
4. Observe shipping fee display

**Expected Result:**
- Shipping fee displays as $0.00 (free)
- Order total equals subtotal with no shipping charge

---

## Test Case 3: Standard Shipping - Non-Member Above $50 Threshold

**Preconditions:**
- User is not logged in or has no active membership
- Standard shipping is selected

**Steps:**
1. Add item(s) to cart with subtotal $50.01 or more
2. Proceed to checkout
3. Verify shipping method is set to "Standard"
4. Observe shipping fee display

**Expected Result:**
- Shipping fee displays as $0.00 (free)
- Order total equals subtotal with no shipping charge

---

## Test Case 4: Standard Shipping - Member at Any Subtotal (Low)

**Preconditions:**
- User is logged in with active membership
- Standard shipping is selected

**Steps:**
1. Add item(s) to cart with subtotal $25.00
2. Proceed to checkout
3. Verify shipping method is set to "Standard"
4. Observe shipping fee display

**Expected Result:**
- Shipping fee displays as $0.00 (free)
- Order total equals subtotal with no shipping charge

---

## Test Case 5: Standard Shipping - Member at Any Subtotal (High)

**Preconditions:**
- User is logged in with active membership
- Standard shipping is selected

**Steps:**
1. Add item(s) to cart with subtotal $150.00
2. Proceed to checkout
3. Verify shipping method is set to "Standard"
4. Observe shipping fee display

**Expected Result:**
- Shipping fee displays as $0.00 (free)
- Order total equals subtotal with no shipping charge

---

## Test Case 6: Express Shipping - Non-Member

**Preconditions:**
- User is not logged in or has no active membership
- Express shipping is selected

**Steps:**
1. Add item(s) to cart with any subtotal (e.g., $30.00)
2. Proceed to checkout
3. Change shipping method to "Express"
4. Observe shipping fee display

**Expected Result:**
- Shipping fee displays as $12.99
- Order total includes $12.99 shipping charge

---

## Test Case 7: Express Shipping - Member

**Preconditions:**
- User is logged in with active membership
- Express shipping is selected

**Steps:**
1. Add item(s) to cart with any subtotal (e.g., $30.00)
2. Proceed to checkout
3. Change shipping method to "Express"
4. Observe shipping fee display

**Expected Result:**
- Shipping fee displays as $7.99
- Order total includes $7.99 shipping charge

---

## Test Case 8: Shipping Fee Update on Method Change - Non-Member

**Preconditions:**
- User is not logged in or has no active membership
- Subtotal is $40.00 (below $50 threshold)

**Steps:**
1. Add item(s) to cart with subtotal $40.00
2. Proceed to checkout
3. Verify Standard shipping fee shows $5.99
4. Switch to Express shipping
5. Observe updated fee
6. Switch back to Standard shipping
7. Observe fee reverts

**Expected Result:**
- Standard shipping: $5.99
- Express shipping: $12.99
- Standard shipping after switch back: $5.99

---

## Test Case 9: Shipping Fee Update on Method Change - Member

**Preconditions:**
- User is logged in with active membership
- Subtotal is $40.00

**Steps:**
1. Add item(s) to cart with subtotal $40.00
2. Proceed to checkout
3. Verify Standard shipping fee shows $0.00
4. Switch to Express shipping
5. Observe updated fee
6. Switch back to Standard shipping
7. Observe fee reverts

**Expected Result:**
- Standard shipping: $0.00
- Express shipping: $7.99
- Standard shipping after switch back: $0.00

---

## Test Case 10: Membership Status Change - Mid-Session

**Preconditions:**
- User starts as non-member with Standard shipping selected
- Subtotal is $45.00

**Steps:**
1. Non-member user adds items with subtotal $45.00
2. Observe shipping fee ($5.99 Standard)
3. User logs in with membership credentials
4. Refresh or navigate back to checkout
5. Observe shipping fee update

**Expected Result:**
- Before login: Shipping fee is $5.99
- After login: Shipping fee updates to $0.00

---

## Test Case 11: Edge Case - Order at $49.99 vs $50.00 Boundary (Non-Member, Standard)

**Preconditions:**
- User is not logged in
- Standard shipping is selected

**Steps:**
1. Test Case A: Add items totaling exactly $49.99, verify shipping
2. Test Case B: Add items totaling exactly $50.00, verify shipping
3. Test Case C: Add items totaling exactly $50.01, verify shipping

**Expected Result:**
- Test Case A: $5.99 shipping
- Test Case B: $0.00 shipping
- Test Case C: $0.00 shipping

---

## Test Case 12: Multiple Shipping Options Display (Non-Member Below Threshold)

**Preconditions:**
- User is not logged in
- Subtotal is $30.00

**Steps:**
1. Add items with subtotal $30.00
2. Proceed to checkout
3. Review all shipping method options displayed

**Expected Result:**
- Standard Shipping option shows: "$5.99"
- Express Shipping option shows: "$12.99"
- Both options accurately reflect pricing for this user segment

---

## Test Case 13: Multiple Shipping Options Display (Member)

**Preconditions:**
- User is logged in with active membership
- Subtotal is $30.00

**Steps:**
1. Add items with subtotal $30.00
2. Proceed to checkout
3. Review all shipping method options displayed

**Expected Result:**
- Standard Shipping option shows: "FREE"
- Express Shipping option shows: "$7.99"
- Both options accurately reflect member pricing
