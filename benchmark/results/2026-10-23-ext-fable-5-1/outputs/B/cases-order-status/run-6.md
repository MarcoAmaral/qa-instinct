# Test Cases: ORD-4 Order status changes

## Assumptions

1. Status changes are triggered by four distinct operations: record payment, mark shipped, confirm delivery, cancel. Each is available to a store operator through the same interface (UI or API). Tests are written interface-neutral.
2. The valid status set is exactly: Placed, Paid, Shipped, Delivered, Cancelled. No other values exist.
3. Any transition not listed in the acceptance criteria is invalid. An invalid transition is refused, the status is unchanged, and an error is returned. Only the AC-5 message text is specified. For other refusals, the test checks that an error is returned and the status is unchanged, without asserting message text.
4. Delivered and Cancelled are terminal. No operation changes a terminal order's status.
5. The refusal message in AC-5 is matched exactly, including capitalisation and the trailing full stop.
6. A refused operation has no side effects: no status change, no new history entry, no notification.
7. Status is persisted and the same value is visible to both staff and customer views after a page reload or fresh read.
8. Payment recording, shipping, and delivery confirmation take no additional required inputs for the purpose of these tests. Amount validation, carrier data, and similar are out of scope for ORD-4.

## Traceability

| AC | Test cases |
|----|-----------|
| Creation (Placed) | TC-01, TC-02 |
| AC-1 | TC-03, TC-10, TC-11, TC-12 |
| AC-2 | TC-04, TC-13, TC-14, TC-15 |
| AC-3 | TC-05, TC-16, TC-17, TC-18 |
| AC-4 | TC-06, TC-07, TC-19, TC-20 |
| AC-5 | TC-08, TC-09 |
| Cross-cutting | TC-21 to TC-27 |

## Positive path

**TC-01 New order starts as Placed**
Priority: High
Preconditions: Operator can create an order.
Steps:
1. Create a new order.
2. Read the order's status.
Expected: Status is Placed. No other status is shown anywhere for the order.

**TC-02 Placed status is persisted**
Priority: Medium
Preconditions: TC-01 passed.
Steps:
1. Create a new order.
2. Reload or fetch the order from storage in a new session.
Expected: Status is still Placed.

**TC-03 Placed to Paid on payment**
Priority: High
Preconditions: Order in Placed.
Steps:
1. Record a payment on the order.
2. Read the status.
Expected: Status is Paid. Operation reports success.

**TC-04 Paid to Shipped on ship**
Priority: High
Preconditions: Order in Paid.
Steps:
1. Mark the order as shipped.
2. Read the status.
Expected: Status is Shipped. Operation reports success.

**TC-05 Shipped to Delivered on delivery confirmation**
Priority: High
Preconditions: Order in Shipped.
Steps:
1. Confirm delivery.
2. Read the status.
Expected: Status is Delivered. Operation reports success.

**TC-06 Placed order can be cancelled**
Priority: High
Preconditions: Order in Placed.
Steps:
1. Cancel the order.
2. Read the status.
Expected: Status is Cancelled. Operation reports success.

**TC-07 Paid order can be cancelled**
Priority: High
Preconditions: Order in Paid.
Steps:
1. Cancel the order.
2. Read the status.
Expected: Status is Cancelled. Operation reports success.

**TC-08 Shipped order cannot be cancelled**
Priority: High
Preconditions: Order in Shipped.
Steps:
1. Cancel the order.
2. Read the status.
Expected: Operation is refused with the exact message below. Status remains Shipped.
```
Shipped orders cannot be cancelled.
```

**TC-09 Refused cancellation has no side effects**
Priority: Medium
Preconditions: Order in Shipped. Status history and notifications are observable.
Steps:
1. Note the status history entry count and last-modified timestamp.
2. Attempt to cancel the order.
3. Re-read history, timestamp, and any outbound notifications.
Expected: No new history entry, no timestamp change, no customer notification sent.

## Invalid transitions

**TC-10 Payment on a Paid order is refused**
Priority: Medium
Preconditions: Order in Paid.
Steps: Record a payment.
Expected: Operation refused. Status remains Paid.

**TC-11 Payment on a Shipped or Delivered order is refused**
Priority: Medium
Preconditions: One order in Shipped, one in Delivered.
Steps: Record a payment on each.
Expected: Both refused. Statuses unchanged.

**TC-12 Payment on a Cancelled order is refused**
Priority: High
Preconditions: Order in Cancelled.
Steps: Record a payment.
Expected: Refused. Status remains Cancelled. Order does not reopen.

**TC-13 Shipping a Placed order is refused**
Priority: High
Preconditions: Order in Placed, no payment recorded.
Steps: Mark as shipped.
Expected: Refused. Status remains Placed. Unpaid goods are not shipped.

**TC-14 Shipping a Shipped or Delivered order is refused**
Priority: Low
Preconditions: One order in Shipped, one in Delivered.
Steps: Mark each as shipped.
Expected: Both refused. Statuses unchanged.

**TC-15 Shipping a Cancelled order is refused**
Priority: High
Preconditions: Order in Cancelled.
Steps: Mark as shipped.
Expected: Refused. Status remains Cancelled.

**TC-16 Confirming delivery on a Placed order is refused**
Priority: Medium
Preconditions: Order in Placed.
Steps: Confirm delivery.
Expected: Refused. Status remains Placed.

**TC-17 Confirming delivery on a Paid order is refused**
Priority: Medium
Preconditions: Order in Paid.
Steps: Confirm delivery.
Expected: Refused. Status remains Paid. Order cannot skip Shipped.

**TC-18 Confirming delivery on a Delivered or Cancelled order is refused**
Priority: Low
Preconditions: One order in Delivered, one in Cancelled.
Steps: Confirm delivery on each.
Expected: Both refused. Statuses unchanged.

**TC-19 Cancelling a Delivered order is refused**
Priority: High
Preconditions: Order in Delivered.
Steps: Cancel the order.
Expected: Refused. Status remains Delivered. Note: the story only specifies the message for Shipped orders. Record the actual message returned and raise a clarification if it reuses the Shipped wording.

**TC-20 Cancelling a Cancelled order is refused or is a no-op**
Priority: Medium
Preconditions: Order in Cancelled.
Steps: Cancel the order again.
Expected: Status remains Cancelled. No duplicate cancellation record. Acceptable outcomes are a refusal or an idempotent success. Record which behaviour is implemented.

## Cross-cutting

**TC-21 Full happy-path lifecycle**
Priority: High
Preconditions: None.
Steps:
1. Create order. Verify Placed.
2. Record payment. Verify Paid.
3. Mark shipped. Verify Shipped.
4. Confirm delivery. Verify Delivered.
Expected: Each step succeeds and each intermediate status is observed in order. No step is skipped.

**TC-22 Status change is visible to both staff and customer**
Priority: High
Preconditions: Order in Placed. A customer view and a staff view exist.
Steps:
1. Record payment as operator.
2. Open the order in the staff view.
3. Open the same order in the customer view.
Expected: Both views show Paid. Repeat once for Shipped and once for Cancelled.

**TC-23 Status change survives reload**
Priority: Medium
Preconditions: Order in Paid.
Steps:
1. Mark shipped.
2. Fetch the order in a fresh session or direct from storage.
Expected: Status is Shipped.

**TC-24 Status change on one order does not affect another**
Priority: Medium
Preconditions: Two orders A and B, both Placed.
Steps:
1. Record payment on A.
2. Read status of B.
Expected: A is Paid. B is still Placed.

**TC-25 Concurrent conflicting operations on the same order**
Priority: Medium
Preconditions: Order in Paid. Ability to issue two requests near-simultaneously.
Steps:
1. Send "mark shipped" and "cancel" at the same time.
2. Read the final status.
Expected: Exactly one operation succeeds. Final status is either Shipped or Cancelled, never both recorded and never an intermediate or corrupt value. The losing operation is refused.

**TC-26 Double submission of the same operation**
Priority: Medium
Preconditions: Order in Placed.
Steps:
1. Send "record payment" twice in quick succession.
2. Read the status and status history.
Expected: Status is Paid. Only one Placed-to-Paid transition is recorded.

**TC-27 Operation on a non-existent order**
Priority: Low
Preconditions: An order ID that does not exist.
Steps: Attempt each of the four operations against the ID.
Expected: Each is refused with a not-found style error. No order is created as a side effect.

## Open questions for the product owner

These do not block testing but should be settled before sign-off.

- What message is returned when cancelling a Delivered order, and for other invalid transitions?
- Is cancelling an already Cancelled order a refusal or an idempotent success?
- Does cancelling a Paid order trigger a refund, or is that handled by a separate story?
- Is there a status history or audit trail required, or is only the current status in scope?
