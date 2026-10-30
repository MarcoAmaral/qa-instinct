# Test Cases for ORD-4: Order Status Changes

## TC-1: Order Created with Placed Status
**Given:** A new order is created  
**When:** The order is initialized  
**Then:** The order status should be "Placed"

## TC-2: Payment Recording on Placed Order
**Given:** An order with status "Placed"  
**When:** A payment is recorded on the order  
**Then:** The order status should change to "Paid"

## TC-3: Shipping Paid Order
**Given:** An order with status "Paid"  
**When:** The order is marked as shipped  
**Then:** The order status should change to "Shipped"

## TC-4: Delivery Confirmation on Shipped Order
**Given:** An order with status "Shipped"  
**When:** Delivery is confirmed for the order  
**Then:** The order status should change to "Delivered"

## TC-5: Cancel Placed Order
**Given:** An order with status "Placed"  
**When:** The order is cancelled  
**Then:** The order status should change to "Cancelled"

## TC-6: Cancel Paid Order
**Given:** An order with status "Paid"  
**When:** The order is cancelled  
**Then:** The order status should change to "Cancelled"

## TC-7: Attempt to Cancel Shipped Order
**Given:** An order with status "Shipped"  
**When:** An attempt is made to cancel the order  
**Then:** The cancellation should be refused with error message "Shipped orders cannot be cancelled."

## TC-8: Status Transition Sequence (Happy Path)
**Given:** A new order  
**When:** The order progresses through all valid state transitions: Placed → Paid → Shipped → Delivered  
**Then:** Each transition should succeed and the final status should be "Delivered"

## TC-9: Attempt to Skip Status (Payment to Shipped)
**Given:** An order with status "Placed"  
**When:** An attempt is made to mark it as shipped without recording payment first  
**Then:** The action should be refused (status remains "Placed")  
**Assumption:** Only valid status transitions are allowed

## TC-10: Attempt to Record Payment on Already Paid Order
**Given:** An order with status "Paid"  
**When:** Another payment is recorded  
**Then:** The action should be refused or idempotent (status remains "Paid")  
**Assumption:** Duplicate payment recording is prevented

## TC-11: Attempt to Ship Placed Order
**Given:** An order with status "Placed"  
**When:** An attempt is made to mark it as shipped without payment  
**Then:** The action should be refused (status remains "Placed")

## TC-12: Attempt to Transition from Delivered Status
**Given:** An order with status "Delivered"  
**When:** Any state change is attempted (payment, shipping, or cancellation)  
**Then:** All actions should be refused (status remains "Delivered")  
**Assumption:** Delivered is a terminal state

## TC-13: Cancel Delivered Order
**Given:** An order with status "Delivered"  
**When:** An attempt is made to cancel the order  
**Then:** The cancellation should be refused  
**Assumption:** Only Placed and Paid orders can be cancelled per AC-4
