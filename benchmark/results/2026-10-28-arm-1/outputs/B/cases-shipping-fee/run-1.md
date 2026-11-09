# Test Cases for SHIP-9: Shipping Fee at Checkout

## Assumptions
- Subtotal is calculated before shipping and tax
- Boundary value for free standard shipping is exactly $50.00
- "Member" status is determined at checkout time
- Shipping methods are mutually exclusive (user selects one)
- Shipping costs are displayed before final purchase confirmation

---

## Test Case 1: Standard Shipping - Non-Member Below Threshold
**Preconditions:** User is not a member; order contains items totaling $49.99
**Steps:**
1. Select "Standard Shipping" at checkout
**Expected Result:** Shipping fee displays as $5.99

---

## Test Case 2: Standard Shipping - Non-Member At Threshold
**Preconditions:** User is not a member; order contains items totaling exactly $50.00
**Steps:**
1. Select "Standard Shipping" at checkout
**Expected Result:** Shipping fee displays as $0.00 (free)

---

## Test Case 3: Standard Shipping - Non-Member Above Threshold
**Preconditions:** User is not a member; order contains items totaling $150.00
**Steps:**
1. Select "Standard Shipping" at checkout
**Expected Result:** Shipping fee displays as $0.00 (free)

---

## Test Case 4: Standard Shipping - Member Below Threshold
**Preconditions:** User is a member; order contains items totaling $25.00
**Steps:**
1. Select "Standard Shipping" at checkout
**Expected Result:** Shipping fee displays as $0.00 (free)

---

## Test Case 5: Standard Shipping - Member Above Threshold
**Preconditions:** User is a member; order contains items totaling $75.00
**Steps:**
1. Select "Standard Shipping" at checkout
**Expected Result:** Shipping fee displays as $0.00 (free)

---

## Test Case 6: Express Shipping - Non-Member Low Subtotal
**Preconditions:** User is not a member; order contains items totaling $10.00
**Steps:**
1. Select "Express Shipping" at checkout
**Expected Result:** Shipping fee displays as $12.99

---

## Test Case 7: Express Shipping - Non-Member High Subtotal
**Preconditions:** User is not a member; order contains items totaling $500.00
**Steps:**
1. Select "Express Shipping" at checkout
**Expected Result:** Shipping fee displays as $12.99

---

## Test Case 8: Express Shipping - Member Low Subtotal
**Preconditions:** User is a member; order contains items totaling $10.00
**Steps:**
1. Select "Express Shipping" at checkout
**Expected Result:** Shipping fee displays as $7.99

---

## Test Case 9: Express Shipping - Member High Subtotal
**Preconditions:** User is a member; order contains items totaling $500.00
**Steps:**
1. Select "Express Shipping" at checkout
**Expected Result:** Shipping fee displays as $7.99

---

## Test Case 10: Shipping Fee Persists After Quantity Change
**Preconditions:** Non-member user at checkout with $45.00 subtotal; Standard Shipping selected ($5.99)
**Steps:**
1. Add item that increases subtotal to $55.00
2. Verify Standard Shipping selection remains
**Expected Result:** Shipping fee updates to $0.00 (free)

---

## Test Case 11: Switching Between Shipping Methods
**Preconditions:** Member user at checkout with $25.00 subtotal
**Steps:**
1. Select "Standard Shipping"
2. Verify fee displays as $0.00
3. Switch to "Express Shipping"
**Expected Result:** Fee updates to $7.99

---

## Test Case 12: Total Price Includes Correct Shipping Fee
**Preconditions:** Non-member user; order subtotal $45.00; Standard Shipping selected
**Steps:**
1. Verify shipping fee is $5.99
2. Verify order total = subtotal ($45.00) + shipping ($5.99)
**Expected Result:** Order total displays as $50.99

---

## Test Case 13: Zero Subtotal Edge Case
**Preconditions:** Cart is empty (subtotal $0.00); user is not a member
**Steps:**
1. Attempt to proceed to checkout with Standard Shipping selected
**Expected Result:** Either standard shipping fee of $5.99 applies OR checkout is blocked with error message

---

## Test Case 14: Membership Status Change at Checkout
**Preconditions:** Non-member user at checkout with $30.00 subtotal; Standard Shipping ($5.99) displayed
**Steps:**
1. Upgrade to membership during checkout session
2. Refresh or wait for checkout to update
**Expected Result:** Shipping fee updates to $0.00

---

## Test Case 15: Member Non-Standard Shipping Display
**Preconditions:** Member user at checkout
**Steps:**
1. View available shipping options and their associated fees
**Expected Result:** Standard Shipping shows $0.00; Express Shipping shows $7.99
