# Test Cases for SHIP-9: Shipping fee at checkout

## Test Case 1: Standard Shipping - Non-member with subtotal below threshold
**Preconditions:** Customer is not a member, Standard shipping selected
**Steps:**
1. Add items to cart with subtotal of $49.99
2. Proceed to checkout
3. Verify shipping fee display

**Expected Result:** Standard shipping fee displays as $5.99

---

## Test Case 2: Standard Shipping - Non-member with subtotal at threshold
**Preconditions:** Customer is not a member, Standard shipping selected
**Steps:**
1. Add items to cart with subtotal of exactly $50.00
2. Proceed to checkout
3. Verify shipping fee display

**Expected Result:** Standard shipping fee displays as $0.00 (free)

---

## Test Case 3: Standard Shipping - Non-member with subtotal above threshold
**Preconditions:** Customer is not a member, Standard shipping selected
**Steps:**
1. Add items to cart with subtotal of $75.00
2. Proceed to checkout
3. Verify shipping fee display

**Expected Result:** Standard shipping fee displays as $0.00 (free)

---

## Test Case 4: Standard Shipping - Member with low subtotal
**Preconditions:** Customer is a member, Standard shipping selected
**Steps:**
1. Add items to cart with subtotal of $25.00
2. Proceed to checkout while logged in as member
3. Verify shipping fee display

**Expected Result:** Standard shipping fee displays as $0.00 (free)

---

## Test Case 5: Standard Shipping - Member with high subtotal
**Preconditions:** Customer is a member, Standard shipping selected
**Steps:**
1. Add items to cart with subtotal of $150.00
2. Proceed to checkout while logged in as member
3. Verify shipping fee display

**Expected Result:** Standard shipping fee displays as $0.00 (free)

---

## Test Case 6: Express Shipping - Non-member
**Preconditions:** Customer is not a member, Express shipping selected
**Steps:**
1. Add items to cart with any subtotal
2. Select Express shipping at checkout
3. Verify shipping fee display

**Expected Result:** Express shipping fee displays as $12.99

---

## Test Case 7: Express Shipping - Non-member with high subtotal
**Preconditions:** Customer is not a member, Express shipping selected
**Steps:**
1. Add items to cart with subtotal of $1,000.00
2. Select Express shipping at checkout
3. Verify shipping fee display

**Expected Result:** Express shipping fee displays as $12.99 (subtotal does not affect express shipping for non-members)

---

## Test Case 8: Express Shipping - Member
**Preconditions:** Customer is a member, Express shipping selected
**Steps:**
1. Add items to cart with any subtotal
2. Select Express shipping at checkout while logged in as member
3. Verify shipping fee display

**Expected Result:** Express shipping fee displays as $7.99

---

## Test Case 9: Express Shipping - Member with low subtotal
**Preconditions:** Customer is a member, Express shipping selected
**Steps:**
1. Add items to cart with subtotal of $10.00
2. Select Express shipping at checkout while logged in as member
3. Verify shipping fee display

**Expected Result:** Express shipping fee displays as $7.99 (member discount applies regardless of subtotal)

---

## Test Case 10: Switching shipping methods at checkout - Non-member
**Preconditions:** Customer is not a member, subtotal is $45.00
**Steps:**
1. Add items to cart with subtotal of $45.00
2. Proceed to checkout
3. Select Standard shipping, verify fee
4. Switch to Express shipping, verify fee
5. Switch back to Standard shipping, verify fee

**Expected Result:** 
- Standard shipping: $5.99
- Express shipping: $12.99
- Standard shipping (again): $5.99

---

## Test Case 11: Switching shipping methods at checkout - Member
**Preconditions:** Customer is a member, subtotal is $35.00
**Steps:**
1. Add items to cart with subtotal of $35.00
2. Proceed to checkout while logged in as member
3. Select Standard shipping, verify fee
4. Switch to Express shipping, verify fee
5. Switch back to Standard shipping, verify fee

**Expected Result:**
- Standard shipping: $0.00 (free)
- Express shipping: $7.99
- Standard shipping (again): $0.00 (free)

---

## Test Case 12: Boundary condition - $49.99 non-member
**Preconditions:** Customer is not a member, Standard shipping selected
**Steps:**
1. Add items to cart with subtotal of $49.99
2. Proceed to checkout
3. Verify shipping fee display

**Expected Result:** Standard shipping fee displays as $5.99 (one cent below threshold)

---

## Test Case 13: Boundary condition - $50.01 non-member
**Preconditions:** Customer is not a member, Standard shipping selected
**Steps:**
1. Add items to cart with subtotal of $50.01
2. Proceed to checkout
3. Verify shipping fee display

**Expected Result:** Standard shipping fee displays as $0.00 (free, one cent above threshold)

---

## Test Case 14: Edge case - Zero subtotal non-member
**Preconditions:** Customer is not a member, cart contains free items, Standard shipping selected
**Steps:**
1. Add free items to cart (subtotal $0.00)
2. Proceed to checkout
3. Verify shipping fee display

**Expected Result:** Standard shipping fee displays as $5.99

---

## Test Case 15: Member membership status verification
**Preconditions:** Customer upgrades from non-member to member status
**Steps:**
1. Add items to cart with subtotal of $40.00 as non-member
2. Proceed to checkout, verify standard shipping fee is $5.99
3. Log out and log in as member
4. View same cart at checkout
5. Verify standard shipping fee

**Expected Result:** Standard shipping fee displays as $0.00 (free) after member login
