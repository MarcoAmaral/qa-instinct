# Test Cases for SHIP-9: Shipping Fee at Checkout

## Assumptions
- Tests are for a checkout page/system displaying shipping fees
- Two shipping methods available: Standard and Express
- User account has a membership status (Member or Non-member)
- Subtotal is calculated before shipping and tax fees
- All prices in USD
- System rounds prices to two decimal places
- Non-member is the default user status for tests without explicit member status

---

## Test Case 1: Standard Shipping - Non-member, Subtotal Below $50
**ID:** TC-SHIP-9-001  
**Description:** Verify standard shipping fee is $5.99 for non-members when order subtotal is below $50  
**Precondition:** User is non-member; standard shipping method selected  
**Test Steps:**
1. Add items to cart with subtotal $49.99
2. Proceed to checkout
3. Review shipping fee display

**Expected Result:** Standard shipping fee displays as $5.99

---

## Test Case 2: Standard Shipping - Non-member, Subtotal Equals $50
**ID:** TC-SHIP-9-002  
**Description:** Verify standard shipping is free for non-members when order subtotal equals exactly $50.00  
**Precondition:** User is non-member; standard shipping method selected  
**Test Steps:**
1. Add items to cart with subtotal $50.00
2. Proceed to checkout
3. Review shipping fee display

**Expected Result:** Standard shipping fee displays as $0.00

---

## Test Case 3: Standard Shipping - Non-member, Subtotal Above $50
**ID:** TC-SHIP-9-003  
**Description:** Verify standard shipping is free for non-members when order subtotal exceeds $50  
**Precondition:** User is non-member; standard shipping method selected  
**Test Steps:**
1. Add items to cart with subtotal $100.00
2. Proceed to checkout
3. Review shipping fee display

**Expected Result:** Standard shipping fee displays as $0.00

---

## Test Case 4: Standard Shipping - Non-member, Boundary (Just Below $50)
**ID:** TC-SHIP-9-004  
**Description:** Verify standard shipping fee is $5.99 when subtotal is $50.01 below threshold  
**Precondition:** User is non-member; standard shipping method selected  
**Test Steps:**
1. Add items to cart with subtotal $49.99
2. Proceed to checkout
3. Review shipping fee display

**Expected Result:** Standard shipping fee displays as $5.99

---

## Test Case 5: Standard Shipping - Member, Any Subtotal
**ID:** TC-SHIP-9-005  
**Description:** Verify standard shipping is free for members regardless of order subtotal  
**Precondition:** User is member; standard shipping method selected  
**Test Steps:**
1. Add items to cart with subtotal $10.00
2. Proceed to checkout
3. Review shipping fee display

**Expected Result:** Standard shipping fee displays as $0.00

---

## Test Case 6: Standard Shipping - Member, High Subtotal
**ID:** TC-SHIP-9-006  
**Description:** Verify standard shipping is free for members on large orders  
**Precondition:** User is member; standard shipping method selected  
**Test Steps:**
1. Add items to cart with subtotal $500.00
2. Proceed to checkout
3. Review shipping fee display

**Expected Result:** Standard shipping fee displays as $0.00

---

## Test Case 7: Express Shipping - Non-member, Any Subtotal
**ID:** TC-SHIP-9-007  
**Description:** Verify express shipping costs $12.99 for non-members regardless of order subtotal  
**Precondition:** User is non-member; express shipping method selected  
**Test Steps:**
1. Add items to cart with subtotal $25.00
2. Proceed to checkout
3. Select express shipping option
4. Review shipping fee display

**Expected Result:** Express shipping fee displays as $12.99

---

## Test Case 8: Express Shipping - Non-member, Large Order
**ID:** TC-SHIP-9-008  
**Description:** Verify express shipping costs $12.99 for non-members on large orders  
**Precondition:** User is non-member; express shipping method selected  
**Test Steps:**
1. Add items to cart with subtotal $1,000.00
2. Proceed to checkout
3. Select express shipping option
4. Review shipping fee display

**Expected Result:** Express shipping fee displays as $12.99

---

## Test Case 9: Express Shipping - Member, Any Subtotal
**ID:** TC-SHIP-9-009  
**Description:** Verify express shipping costs $7.99 for members regardless of order subtotal  
**Precondition:** User is member; express shipping method selected  
**Test Steps:**
1. Add items to cart with subtotal $10.00
2. Proceed to checkout
3. Select express shipping option
4. Review shipping fee display

**Expected Result:** Express shipping fee displays as $7.99

---

## Test Case 10: Express Shipping - Member, Large Order
**ID:** TC-SHIP-9-010  
**Description:** Verify express shipping costs $7.99 for members on large orders  
**Precondition:** User is member; express shipping method selected  
**Test Steps:**
1. Add items to cart with subtotal $500.00
2. Proceed to checkout
3. Select express shipping option
4. Review shipping fee display

**Expected Result:** Express shipping fee displays as $7.99

---

## Test Case 11: Shipping Method Switch - Non-member
**ID:** TC-SHIP-9-011  
**Description:** Verify shipping fee updates correctly when switching between standard and express  
**Precondition:** User is non-member with subtotal $30.00 at checkout  
**Test Steps:**
1. Select standard shipping
2. Verify shipping fee is $5.99
3. Switch to express shipping
4. Verify shipping fee is $12.99
5. Switch back to standard shipping
6. Verify shipping fee is $5.99

**Expected Result:** Shipping fee updates to correct amount each time method is switched

---

## Test Case 12: Shipping Method Switch - Member
**ID:** TC-SHIP-9-012  
**Description:** Verify shipping fee updates correctly when member switches between standard and express  
**Precondition:** User is member at checkout  
**Test Steps:**
1. Select standard shipping
2. Verify shipping fee is $0.00
3. Switch to express shipping
4. Verify shipping fee is $7.99
5. Switch back to standard shipping
6. Verify shipping fee is $0.00

**Expected Result:** Shipping fee updates to correct amount each time method is switched

---

## Test Case 13: Membership Status Change Impact
**ID:** TC-SHIP-9-013  
**Description:** Verify shipping fees update when user membership status changes during checkout  
**Precondition:** Non-member user at checkout with subtotal $30.00; express shipping selected  
**Test Steps:**
1. Verify express shipping fee displays as $12.99
2. Apply membership to account (simulated or real upgrade)
3. Refresh checkout or refresh shipping fees
4. Verify express shipping fee now displays as $7.99

**Expected Result:** Shipping fee updates to member pricing after membership is applied

---

## Test Case 14: Subtotal Change Impact - Non-member Standard Shipping
**ID:** TC-SHIP-9-014  
**Description:** Verify shipping fee updates when cart subtotal crosses $50 threshold  
**Precondition:** Non-member user with subtotal $40.00; standard shipping selected  
**Test Steps:**
1. Verify standard shipping fee is $5.99
2. Add item to cart that brings subtotal to $50.00
3. Verify standard shipping fee updates to $0.00
4. Add another item bringing subtotal to $51.00
5. Verify standard shipping fee remains $0.00

**Expected Result:** Shipping fee changes from $5.99 to $0.00 when subtotal reaches $50.00

---

## Test Case 15: Total Price Calculation Including Shipping
**ID:** TC-SHIP-9-015  
**Description:** Verify total price displays correctly with shipping fee included  
**Precondition:** Non-member user with subtotal $45.00; standard shipping selected  
**Test Steps:**
1. Navigate to checkout
2. Verify subtotal displays as $45.00
3. Verify shipping fee displays as $5.99
4. Verify total displays as $50.99

**Expected Result:** Total price correctly sums subtotal plus applicable shipping fee

---

## Test Case 16: Zero Subtotal Edge Case
**ID:** TC-SHIP-9-016  
**Description:** Verify shipping fee behavior with empty or zero subtotal cart  
**Precondition:** User cart is empty (subtotal $0.00)  
**Test Steps:**
1. Proceed to checkout with empty cart
2. Select standard shipping
3. Review shipping fee display

**Expected Result:** Standard shipping fee displays as $5.99 (subtotal below $50 threshold)
