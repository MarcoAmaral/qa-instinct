# Test Cases for ORD-4: Order Status Changes

## Test Case 1: Order Creation
**Given:** A new order is created  
**When:** The order is persisted  
**Then:** The order status is "Placed"

## Test Case 2: Record Payment - Happy Path (AC-1)
**Given:** An order with status "Placed"  
**When:** A payment is recorded on the order  
**Then:** The order status changes to "Paid"

## Test Case 3: Record Payment - Already Paid
**Given:** An order with status "Paid"  
**When:** A payment is recorded on the order  
**Then:** The operation fails or the status remains "Paid"

## Test Case 4: Mark Shipped - Happy Path (AC-2)
**Given:** An order with status "Paid"  
**When:** The order is marked as shipped  
**Then:** The order status changes to "Shipped"

## Test Case 5: Mark Shipped - Not Ready
**Given:** An order with status "Placed" (payment not recorded)  
**When:** The order is marked as shipped  
**Then:** The operation fails or the status remains "Placed"

## Test Case 6: Confirm Delivery - Happy Path (AC-3)
**Given:** An order with status "Shipped"  
**When:** Delivery is confirmed on the order  
**Then:** The order status changes to "Delivered"

## Test Case 7: Cancel Placed Order (AC-4)
**Given:** An order with status "Placed"  
**When:** The order is cancelled  
**Then:** The order status changes to "Cancelled"

## Test Case 8: Cancel Paid Order (AC-4)
**Given:** An order with status "Paid"  
**When:** The order is cancelled  
**Then:** The order status changes to "Cancelled"

## Test Case 9: Cancel Shipped Order - Refused (AC-5)
**Given:** An order with status "Shipped"  
**When:** A cancellation is attempted  
**Then:** The cancellation is refused with error message "Shipped orders cannot be cancelled." and status remains "Shipped"

## Test Case 10: Cancel Delivered Order
**Given:** An order with status "Delivered"  
**When:** A cancellation is attempted  
**Then:** The operation fails or is refused (order is already delivered)

## Test Case 11: Cancel Cancelled Order
**Given:** An order with status "Cancelled"  
**When:** A cancellation is attempted  
**Then:** The operation fails or the status remains "Cancelled"

## Test Case 12: Multiple Orders Independence
**Given:** Two orders, Order A in "Placed" and Order B in "Paid"  
**When:** A payment is recorded on Order A  
**Then:** Order A transitions to "Paid" and Order B status remains unchanged

## Test Case 13: Confirm Delivery - Wrong State
**Given:** An order with status "Placed"  
**When:** Delivery confirmation is attempted  
**Then:** The operation fails or the status remains "Placed"

## Test Case 14: Mark Shipped - Cancelled Order
**Given:** An order with status "Cancelled"  
**When:** Mark shipped is attempted  
**Then:** The operation fails or the status remains "Cancelled"
