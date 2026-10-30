# Risk-Based Test Plan: Split Payment (Release 5.3)

## Assumptions

- "Half time" = 20 testing hours per week, starting immediately
- Release date is 10 working days from today (2026-11-11)
- PayGate sandbox is available for testing on Tuesdays (2026-10-29, 2026-11-05) and Thursdays (2026-10-31, 2026-11-07)
- The two developers can support testing on test environments but cannot redirect production traffic
- "Existing checkout" uses a separate code path; changes to split-payment code do not affect it unless explicitly shared
- Refund automation uses PayGate's API; manual intervention is not the fallback
- The payment gateway is deterministic in its sandbox (same input always produces same result)

## Risk Assessment and Test Priority

| Risk | Impact | Likelihood | Mitigation | Test Priority |
|------|--------|-----------|------------|---|
| Second charge fails; first charge not refunded within 60s | Compliance violation, chargebacks, customer trust | Medium | Automated refund with timeout and retry | **Critical** |
| Regression in single-card checkout (4,000 orders/day) | Revenue impact, production incident | Medium | Regression suite, production-like volume | **Critical** |
| Amount split logic incorrect (remainder handling) | Billing disputes, customer confusion | High | Unit tests, edge-case table-driven tests | **High** |
| Race condition in refund logic (concurrent requests) | Some refunds skip or execute twice | Low-Medium | Concurrency stress tests, idempotency checks | **High** |
| PayGate integration returns unexpected responses | Feature partially broken in sandbox/prod | Medium | Response catalog, error-case handling | **High** |
| Customer selects invalid split amounts (e.g., 0, negative, > total) | UI allows bad states or API rejects valid input | Low | Input validation tests, boundary checks | **Medium** |
| Feature fails on first attempt after go-live | Immediate rollback, customer anger | Low | Smoke test, canary metrics | **High** |

## Test Strategy

### 1. Critical-Path Tests (Refund Automation)

**Assumption:** PayGate's sandbox simulates both approval and decline scenarios deterministically.

1. **Refund fires within 60 seconds of second charge decline**
   - Charge $100 split as $60 + $40
   - First charge succeeds, second charge is declined (use PayGate's decline code)
   - Verify first charge refunded within 60 seconds via PayGate API logs
   - Verify order state is "payment failed" or "refunded," not "partial paid"
   - **Evidence:** API timestamps, order record, customer notification

2. **First charge is not refunded if second charge succeeds**
   - Charge $100 split as $60 + $40
   - Both charges succeed
   - Verify neither charge is refunded
   - Verify order state is "paid"
   - **Evidence:** Order record, charge list from PayGate

3. **Refund idempotency: duplicate decline does not refund twice**
   - Trigger the refund scenario
   - Simulate a duplicate webhook from PayGate for the second charge decline
   - Verify only one refund is issued
   - **Evidence:** PayGate refund history, order refund count

### 2. Regression Tests (Existing Checkout)

**Assumption:** Existing single-card checkout is in a code path that does not share the split-payment logic.

1. **Single-card payment still works (happy path)**
   - Charge $100 on one card
   - Verify charge succeeds, order is "paid"
   - Verify no refund is triggered

2. **Single-card decline is handled as before**
   - Attempt a charge that PayGate declines
   - Verify order is "payment failed," not hung or partially charged

3. **High-volume regression: 4,000 orders in 1 hour**
   - Load test existing checkout with 4,000 concurrent single-card charges
   - Verify success rate matches baseline (assume 98% from 4,000/day baseline)
   - Verify no timeout, no queue buildup, no memory leak

### 3. Amount-Split Logic Tests

**Assumption:** Amounts are integers in cents; the feature never deals with floating-point.

| Test Case | Input | Expected Split | Assertion |
|-----------|-------|-----------------|-----------|
| Even split | $100.00 (10,000 cents) | $50 + $50 | Each card charged exactly 5,000 cents |
| Odd amount, remainder to first | $100.01 (10,001 cents) | $50.01 + $50 | First card 5,001 cents, second 5,000 cents |
| Tiny amount | $0.01 (1 cent) | $0.01 + $0 | First card 1 cent, second card 0 cents |
| Boundary: customer chooses exact half | $50 on each card for $100 | $50 + $50 | No remainder case |
| Boundary: customer chooses $0.01 for first card | $100, split $0.01 + $99.99 | $1 + $9,999 | First card 1 cent, second card 9,999 cents |
| **Evidence** | Order details, PayGate charge records | Both charges visible in PayGate API response | Amounts match exactly |

### 4. PayGate Integration Tests

1. **PayGate API errors do not hang the checkout**
   - Simulate PayGate timeout on first charge
   - Verify timeout is caught, error is shown to customer, order is not created
   - Verify second charge is never attempted

2. **Unexpected PayGate response (e.g., 500 error) is logged and handled**
   - Trigger a PayGate sandbox error scenario
   - Verify error is logged with enough detail for debugging
   - Verify customer sees a generic "try again later" message, not a crash

3. **PayGate webhook for refund is idempotent**
   - Simulate multiple webhooks for the same refund event
   - Verify order state and refund count are correct after each webhook

### 5. Concurrency and Edge Cases

1. **Race: customer double-submits the payment form**
   - Send two identical split-payment requests in rapid succession
   - Verify only one order and set of charges is created (duplicate detection)

2. **Race: refund completes while second charge is still in-flight**
   - Mock PayGate response timing so refund begins before second charge response arrives
   - Verify idempotency check prevents double-refund

3. **Customer tries to cancel after first charge succeeds but before second**
   - If cancellation is a feature: verify the first charge is still refunded
   - If not: document that cancellation is not available during split payment

### 6. Smoke Tests (Pre-Release)

1. Payment page loads and accepts input
2. Split amount selector works (select first-card amount, verify second is calculated)
3. Happy path: $50 split on a test order completes end-to-end
4. Decline path: second charge declined, first refunded within 60 seconds

## Testing Schedule

| Week | Availability | Tasks | Owner |
|------|--------------|-------|-------|
| Week 1 (Oct 28–Nov 1) | Tue 10/29, Thu 10/31 | Unit tests (amount logic) by devs; refund happy-path integration test on sandbox | Developers + Tester |
| Week 2 (Nov 4–8) | Tue 11/5, Thu 11/7 | Refund decline/idempotency tests; regression suite smoke; concurrency tests | Tester (+ dev support if needed) |
| Week 3 (Nov 11+) | Mon–Fri 11/11 onward | Final smoke, load test, documentation; release readiness review | Tester + Developers |

**Constraint:** PayGate sandbox is unavailable Mon, Wed, Fri. All integration tests must run Tue/Thu or use mocks.

## Test Coverage Goals

- Unit tests (amount logic, refund idempotency checks): 100% by developers
- Integration tests (PayGate happy + decline paths): 2 scenarios × 3 test runs on sandbox
- Regression (existing checkout): 100-order smoke + 4,000-order load test
- Concurrency (race conditions): 3 scenarios × 5 runs each

## Resource Allocation

- **Tester (half time, ~20 hours/week):** test case execution, results logging, regression suite
- **Developer 1:** unit tests, refund automation, error handling
- **Developer 2:** split-logic implementation, PayGate integration, support tester as needed

## Go/No-Go Criteria

**Ship only if:**

1. All critical-path tests pass (refund within 60s, idempotency verified)
2. Regression suite passes (single-card checkout unchanged)
3. Amount-split logic passes all boundary cases
4. Load test shows no regression in existing checkout
5. All PayGate API error paths are handled and logged
6. Pre-release smoke tests pass on Tuesday before release

**Hold release if:**

- Refund automation exceeds 60-second window
- Any regression test fails
- Concurrency issues found that cannot be fixed by release date

</main>
