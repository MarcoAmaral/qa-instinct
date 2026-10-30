# Test Cases: Order Status Changes (ORD-4)

## Test Case 1: New order defaults to Placed status
**Acceptance Criteria:** AC-1 (Prerequisites)

| | |
| --- | --- |
| **Scenario** | Create a new order |
| **When** | An order is created in the system |
| **Then** | Its status is `Placed` |
| **Data** | Any valid order data |

## Test Case 2: Record payment on Placed order
**Acceptance Criteria:** AC-1

| | |
| --- | --- |
| **Scenario** | Payment recorded on Placed order |
| **Given** | An order with status `Placed` |
| **When** | Payment is recorded |
| **Then** | Order status changes to `Paid` |
| **Verify** | Status is `Paid` and is visible to staff immediately |

## Test Case 3: Mark Paid order as shipped
**Acceptance Criteria:** AC-2

| | |
| --- | --- |
| **Scenario** | Paid order marked shipped |
| **Given** | An order with status `Paid` |
| **When** | Order is marked as shipped |
| **Then** | Order status changes to `Shipped` |
| **Verify** | Status is `Shipped` and is visible to customers and staff |

## Test Case 4: Confirm delivery of Shipped order
**Acceptance Criteria:** AC-3

| | |
| --- | --- |
| **Scenario** | Delivery confirmed on Shipped order |
| **Given** | An order with status `Shipped` |
| **When** | Delivery is confirmed |
| **Then** | Order status changes to `Delivered` |
| **Verify** | Status is `Delivered` |

## Test Case 5: Cancel Placed order
**Acceptance Criteria:** AC-4

| | |
| --- | --- |
| **Scenario** | Placed order is cancelled |
| **Given** | An order with status `Placed` |
| **When** | Cancellation is requested |
| **Then** | Order status changes to `Cancelled` |

## Test Case 6: Cancel Paid order
**Acceptance Criteria:** AC-4

| | |
| --- | --- |
| **Scenario** | Paid order is cancelled |
| **Given** | An order with status `Paid` |
| **When** | Cancellation is requested |
| **Then** | Order status changes to `Cancelled` |

## Test Case 7: Attempt to cancel Shipped order (rejection)
**Acceptance Criteria:** AC-5

| | |
| --- | --- |
| **Scenario** | Shipped order cannot be cancelled |
| **Given** | An order with status `Shipped` |
| **When** | Cancellation is requested |
| **Then** | Cancellation is refused |
| **Error Message** | "Shipped orders cannot be cancelled." |
| **Verify** | Order status remains `Shipped` |

## Test Case 8: Attempt to cancel Delivered order (edge case)
**Scenario** | Delivered order cannot be cancelled (assumed: follows same rule as Shipped)
**Given** | An order with status `Delivered` |
**When** | Cancellation is requested |
**Then** | Cancellation is refused |
| **Error Message** | "Delivered orders cannot be cancelled." (assumed) |

## Assumptions

- A "store operator" can perform all state transitions (AC-1 through AC-5).
- The system prevents invalid state transitions with error messages.
- Status changes are applied and visible to all users immediately (no delay).
- No status can be reverted once changed (transitions are unidirectional).
- Cancelling a `Placed` or `Paid` order succeeds without additional confirmation.
- The error message for rejecting Shipped order cancellation is returned to the operator and logged.
- A `Delivered` order cannot be cancelled (extrapolated from AC-5).
