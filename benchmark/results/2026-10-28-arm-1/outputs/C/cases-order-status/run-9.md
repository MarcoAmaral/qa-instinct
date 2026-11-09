# Test Cases for Story ORD-4: Order Status Changes

## TC-1: Order created with Placed status
**Given:** A new order is created  
**When:** The order is saved  
**Then:** The order status is Placed

## TC-2: Payment recorded on Placed order (AC-1)
**Given:** An order with status Placed  
**When:** A payment is recorded  
**Then:** The order status changes to Paid

## TC-3: Order marked as shipped with Paid status (AC-2)
**Given:** An order with status Paid  
**When:** The order is marked as shipped  
**Then:** The order status changes to Shipped

## TC-4: Delivery confirmed on Shipped order (AC-3)
**Given:** An order with status Shipped  
**When:** Delivery is confirmed  
**Then:** The order status changes to Delivered

## TC-5: Placed order cancelled (AC-4)
**Given:** An order with status Placed  
**When:** The order is cancelled  
**Then:** The order status changes to Cancelled

## TC-6: Paid order cancelled (AC-4)
**Given:** An order with status Paid  
**When:** The order is cancelled  
**Then:** The order status changes to Cancelled

## TC-7: Shipped order cancellation rejected (AC-5)
**Given:** An order with status Shipped  
**When:** A cancellation is attempted  
**Then:** The system rejects the request with message "Shipped orders cannot be cancelled."  
**And:** The order status remains Shipped

## TC-8: Delivered order cannot be cancelled
**Given:** An order with status Delivered  
**When:** A cancellation is attempted  
**Then:** The system rejects the request  
**And:** The order status remains Delivered

## TC-9: Invalid transition from Placed to Shipped
**Given:** An order with status Placed  
**When:** An attempt is made to mark the order as shipped without recording payment first  
**Then:** The system rejects the request  
**And:** The order status remains Placed

## TC-10: Invalid transition from Placed to Delivered
**Given:** An order with status Placed  
**When:** An attempt is made to confirm delivery without transitioning through Paid and Shipped  
**Then:** The system rejects the request  
**And:** The order status remains Placed

## TC-11: Cancelled order cannot transition
**Given:** An order with status Cancelled  
**When:** Any status change action is attempted  
**Then:** The system rejects the request  
**And:** The order status remains Cancelled

**Assumptions:**
- Orders follow a linear state machine: Placed → Paid → Shipped → Delivered or Placed/Paid → Cancelled
- Cancelled is a terminal state
- Each state transition requires explicit action by a store operator
- The system enforces these transitions and prevents invalid ones
