# Test Cases for SHIP-9: Shipping Fee at Checkout

**Assumptions:**
- Non-members and members are the two user types
- Standard and Express are the two available shipping methods
- Order subtotal is the sum of items before shipping fees
- A subtotal of exactly $50.00 qualifies for free standard shipping
- Prices are displayed in USD
- Shipping is calculated and displayed at checkout before order confirmation

## Test Case 1: Standard Shipping for Non-Member, Subtotal Below Threshold
**Given:** Non-member shopper with order subtotal of $30.00  
**When:** Shopper selects standard shipping at checkout  
**Then:** Shipping fee of $5.99 is displayed  

## Test Case 2: Standard Shipping for Non-Member, Subtotal At Threshold
**Given:** Non-member shopper with order subtotal of $50.00  
**When:** Shopper selects standard shipping at checkout  
**Then:** Shipping fee of $0.00 is displayed  

## Test Case 3: Standard Shipping for Non-Member, Subtotal Above Threshold
**Given:** Non-member shopper with order subtotal of $75.50  
**When:** Shopper selects standard shipping at checkout  
**Then:** Shipping fee of $0.00 is displayed  

## Test Case 4: Standard Shipping for Member, Low Subtotal
**Given:** Member shopper with order subtotal of $20.00  
**When:** Shopper selects standard shipping at checkout  
**Then:** Shipping fee of $0.00 is displayed  

## Test Case 5: Standard Shipping for Member, High Subtotal
**Given:** Member shopper with order subtotal of $100.00  
**When:** Shopper selects standard shipping at checkout  
**Then:** Shipping fee of $0.00 is displayed  

## Test Case 6: Express Shipping for Non-Member, Any Subtotal
**Given:** Non-member shopper with order subtotal of $25.00  
**When:** Shopper selects express shipping at checkout  
**Then:** Shipping fee of $12.99 is displayed  

## Test Case 7: Express Shipping for Non-Member, High Subtotal
**Given:** Non-member shopper with order subtotal of $200.00  
**When:** Shopper selects express shipping at checkout  
**Then:** Shipping fee of $12.99 is displayed  

## Test Case 8: Express Shipping for Member, Low Subtotal
**Given:** Member shopper with order subtotal of $10.00  
**When:** Shopper selects express shipping at checkout  
**Then:** Shipping fee of $7.99 is displayed  

## Test Case 9: Express Shipping for Member, High Subtotal
**Given:** Member shopper with order subtotal of $150.00  
**When:** Shopper selects express shipping at checkout  
**Then:** Shipping fee of $7.99 is displayed  

## Test Case 10: Shipping Fee Update on Subtotal Change
**Given:** Non-member shopper at checkout with express shipping selected and initial subtotal of $40.00  
**When:** Shopper adds item that brings subtotal to $50.00 and switches to standard shipping  
**Then:** Shipping fee updates to $0.00  

## Test Case 11: Shipping Method Comparison for Non-Member at Threshold
**Given:** Non-member shopper with order subtotal of $50.00  
**When:** Shopper compares standard ($0.00) vs. express ($12.99) shipping options  
**Then:** Both fees are correctly displayed at checkout  

## Test Case 12: Total Cost Calculation Includes Shipping
**Given:** Member shopper with order subtotal of $60.00 and express shipping selected  
**When:** Shopper views total cost at checkout  
**Then:** Total reflects subtotal ($60.00) + express shipping ($7.99) = $67.99
