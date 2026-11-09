# Risk-Based Test Plan: Split Payment (Release 5.3)

## Executive Summary

This plan prioritizes testing of financial correctness, payment gateway integration reliability, and backward compatibility of the existing checkout flow. With one part-time tester, strategy focuses on high-risk paths via manual testing and automated regression coverage. PayGate sandbox availability (Tue/Thu only) constrains integration testing to 4 days during a 10-day release window.

## Risk Assessment & Priorities

### Critical Risks (Must Test)
1. **Incorrect amount splits** → financial loss or customer disputes
2. **Second charge declined without refund** → customer paid, money retained, compliance violation
3. **Existing single-card checkout breaks** → revenue interruption (~4,000 orders/day affected)
4. **Refund timeout failure** → 60-second SLA breach

### High Risks (Should Test)
5. Race conditions during concurrent split-payment attempts
6. Partial failures (first succeeds, PayGate unreachable on second)
7. Penny remainder handling in edge cases (odd cents)
8. Idempotency (duplicate charge prevention if requests retry)

### Medium Risks (Nice to Test)
9. UI validation (amounts must be > 0, first ≤ order total)
10. State consistency in database after failure
11. Audit trail logging for compliance

## Assumptions

- "Release 5.3" implies a staged rollout is not planned; feature launches to 100% of users.
- Single-card checkout code is unchanged; split payment is additive functionality.
- PayGate API supports both charges within a single request/transaction.
- "Automatically refund within 60 seconds" means synchronous logic, not a background job.
- Existing test suite covers single-card checkout; this plan focuses on split-specific paths.
- "Half time" tester can dedicate ~4 working days to split-payment testing.
- Two developers are available for debugging but not for manual test execution.
- The refund API call to PayGate has the same SLA as the charge call.

## Test Scope

**In Scope:**
- Split payment amount calculation and remainder logic
- PayGate integration: both charges, success and decline scenarios
- Automatic refund on second-charge decline
- 60-second refund SLA verification
- Single-card checkout regression (smoke tests only, due to time)
- Payment state stored correctly in database
- Error messages to end-user

**Out of Scope:**
- UI accessibility or visual design
- Load testing (infrastructure changes not in scope)
- PayGate API contract changes (assumed stable)
- Fraud detection rules
- Non-USD currencies or tax calculations

## Test Strategy

### Execution Timeline

**Days 1–2 (Tue–Wed):** 
- Environment setup, API mocking for non-Tue/Thu dates
- Unit test validation (developer-written)
- Single-card regression smoke tests (2 happy paths)

**Days 3–4 (Thu–Fri):**
- Live PayGate sandbox integration testing (Thu only; prepare Wed for Thu execution)
- Manual happy-path split payment end-to-end
- Manual second-charge-decline + refund verification

**Days 5–7 (Mon–Wed):**
- Automated split-payment unit and integration tests (mocked)
- Edge-case manual testing (penny remainder, boundary amounts)
- Single-card regression expansion (10–15 representative orders)

**Days 8–10 (Thu–Fri + Mon):**
- Final PayGate sandbox smoke test (Thu only)
- Exploratory testing (race conditions, error states)
- Regression test suite execution in CI
- Production deployment readiness sign-off

### Approach by Risk Level

**Critical (80% of tester effort):**
- Manual end-to-end testing with real PayGate sandbox (Thu sessions)
- Automated unit tests for amount calculation and refund logic
- Database state assertion tests (order records, charge records)

**High (15% of tester effort):**
- Manual testing of decline scenarios and timeout edge cases
- Mocked integration tests for concurrent request handling
- Idempotency verification via manual retry simulation

**Medium (5% of tester effort):**
- Exploratory testing of edge cases if time permits
- Checklist-based regression of 5–10 single-card orders

## Test Cases

### T1: Amount Splitting Logic
**Risk:** Incorrect arithmetic → revenue loss or overcharging  
**Test:** 
- Split $100 order: $60 on card 1, $40 on card 2 → verify both amounts in gateway request
- Split $10.01 order: $5.01 on card 1, $5.00 on card 2 (remainder to card 1)
- Boundary: $0.01 order split $0.01 / $0.00 → card 2 charge should fail or be skipped
- All amounts in cents; verify no float rounding errors

**Execution:** Automated unit tests + mocked integration test  
**Pass Criteria:** Request payloads match expected cent values; database records match

---

### T2: Successful Split Payment End-to-End
**Risk:** Integration failure, state corruption  
**Test:**
- Place order for $100 with two cards
- Select $60 on card 1, $40 on card 2
- Complete both charges through PayGate sandbox
- Verify order status = "paid", both charges marked successful in database
- Verify no refund attempt

**Execution:** Manual via UI + PayGate sandbox (Thu only)  
**Pass Criteria:** 
- Both charges appear in PayGate dashboard
- Order record shows split payment detail
- No spurious refund calls

---

### T3: Second Charge Declined, Auto-Refund
**Risk:** Customer charged but order marked failed; compliance violation  
**Test:**
- Place $100 order: $60 on card 1 (valid), $40 on card 2 (use declined test card)
- First charge succeeds
- Second charge fails with "declined" response
- Verify refund of $60 is initiated within 60 seconds
- Verify order status = "payment failed" or "refunded"
- Verify both charges and refund logged

**Execution:** Manual + mocked decline response (sandbox limitations) or live sandbox if available  
**Pass Criteria:**
- Refund API called within 60 sec
- Refund appears in PayGate dashboard
- Customer not charged net amount
- Audit log shows refund reason

---

### T4: First Charge Declined
**Risk:** Partial failure, unclear user experience  
**Test:**
- Use declined test card for first $60, valid card for second $40
- Verify first charge fails
- Verify second charge is not attempted
- Verify order status reflects failure
- Verify no refund call

**Execution:** Manual via UI (mocked or sandbox)  
**Pass Criteria:**
- Only one charge attempt in gateway logs
- Clear error message to user
- No orphaned charges

---

### T5: Refund SLA (60-Second Window)
**Risk:** Slow refund → customer service escalation, compliance issue  
**Test:**
- Instrument refund code with timestamps
- Simulate second charge decline; measure time to refund API call
- Verify < 60 seconds in 10 repeated test runs
- Test with simulated gateway latency (100ms response time)

**Execution:** Automated test with time assertions + manual spot-check  
**Pass Criteria:**
- 100% of test runs complete refund within 59 seconds
- No timeout exceptions in logs

---

### T6: Idempotency (Duplicate Charge Prevention)
**Risk:** Network retry → customer charged twice  
**Test:**
- Mock PayGate to simulate timeout on second charge (customer does not see success)
- Application automatically retries second charge
- Verify only one $40 charge posted to customer account
- Verify idempotency key or transaction ID prevents duplicates

**Execution:** Automated test with mocked timeout + manual verification  
**Pass Criteria:**
- PayGate receives both requests, but database reflects one charge
- No duplicate line items

---

### T7: Penny Remainder Edge Cases
**Risk:** Off-by-one cent; accumulates across orders  
**Test:**
- $10.01 split: $5.01 card 1, $5.00 card 2
- $100.03 split: $50.02 card 1, $50.01 card 2
- $0.01 split: $0.01 card 1, $0.00 card 2
- Verify total == order amount and remainder always on card 1

**Execution:** Automated unit test + spot-check one manual order  
**Pass Criteria:**
- Total cents match order total across all test cases
- Remainder never lost

---

### T8: Single-Card Checkout Regression
**Risk:** Backward compatibility break → existing revenue interruption  
**Test:**
- Smoke test: successful single-card payment (UI path unchanged)
- Smoke test: single-card payment decline and retry
- Sanity check: 10–15 real single-card orders processed correctly
- Verify no performance regression (payment time < baseline + 5%)

**Execution:** Manual UI testing + automated regression suite  
**Pass Criteria:**
- Single-card orders complete without new errors
- Order totals and charges match expectations
- No latency increase

---

### T9: Concurrent Split Payments
**Risk:** Race condition in refund logic or state updates  
**Test:**
- Simulate 5 concurrent split-payment orders on same account
- Vary scenarios: all succeed, one declines, multiple decline
- Verify each order's charges and refunds are independent
- Check for DB lock contention or lost updates

**Execution:** Automated test or manual via load tool  
**Pass Criteria:**
- All orders reach correct final state
- No stuck transactions
- Refund counts match decline counts

---

### T10: User Input Validation
**Risk:** Invalid split amounts lead to confusing errors or server crashes  
**Test:**
- Enter first amount > order total → error shown
- Enter first amount = 0 → error shown
- Enter first amount = order total → second card amount = 0, decide expected behavior (skip second charge or error)
- Negative amounts → blocked at input level
- Non-numeric input → rejected

**Execution:** Manual UI testing  
**Pass Criteria:**
- All invalid inputs rejected before PayGate API call
- Error messages are clear
- No server-side crashes

---

### T11: Error Messages & Logging
**Risk:** Debugging production issues without visibility  
**Test:**
- Verify all charge/refund responses logged with full PayGate response
- Error messages to customer are actionable (not raw gateway errors)
- Internal logs include order ID, customer ID, amounts, timestamps
- Sensitive data (card numbers) never logged

**Execution:** Code review + manual log inspection  
**Pass Criteria:**
- Logs contain all required fields
- No sensitive data exposure
- Support team can troubleshoot with logs

---

### T12: Database Consistency After Failure
**Risk:** Order state out of sync with payment reality  
**Test:**
- Force a crash mid-refund (e.g., shut down service during refund call)
- Restart service; verify order state is recoverable
- Verify no orphaned charge records without order reference

**Execution:** Automated or manual chaos test (if environment allows)  
**Pass Criteria:**
- Recovery logic in place; order can be retried or marked failed safely
- No broken foreign keys

---

## Resource Allocation

| Role | Task | Effort | Timeline |
|------|------|--------|----------|
| Tester (0.5 FTE) | Manual E2E (sandbox), edge cases, regression smoke | 4 days | Days 1–10 (concentrated Thu testing) |
| Dev 1 | Unit/integration tests, PayGate mocking | 2–3 days | Days 1–4 |
| Dev 2 | Refund logic, error handling, logging | 2–3 days | Days 1–4 |
| Tester | Test case documentation, execution, sign-off | 1 day | Day 10 |

## PayGate Sandbox Availability Constraint

- **Available:** Tue, Thu only
- **Test windows:** Days 1 (Tue), 4 (Thu), 10 (Thu)
- **Mitigation:** 
  - Use mocked PayGate responses for Wed/Fri/Mon testing
  - Prioritize critical E2E tests (T2, T3, T5) for Thu sessions
  - Automate repeated sandbox calls to maximize Thu capacity
  - Have full test suite ready to run Thu morning; no debugging that day

## Deployment Readiness Checklist

Before release:
- [ ] All critical test cases (T1–T5) passed on PayGate sandbox
- [ ] Refund SLA (60s) verified in production-like environment
- [ ] Single-card regression suite passed; no performance degradation
- [ ] Idempotency logic verified (T6)
- [ ] Logging and error messages reviewed for completeness and security
- [ ] Database schema reviewed (no orphaned records possible)
- [ ] Rollback plan documented (how to disable split payment if live issue)
- [ ] On-call playbook includes "second charge declined" scenarios

## Risk Mitigation for Time Constraints

1. **Sandbox bottleneck:** Use API mocks for 75% of testing; reserve Tue/Thu for critical E2E only.
2. **Single tester, half-time:** Prioritize automated over manual; developers write unit tests.
3. **10-day window:** Accept medium-risk exploratory tests as "defer if time runs out"; focus on critical paths.
4. **High-order volume (4K/day):** Single-card regression is smoke-level; scale up post-launch if no issues in first 48 hours.

## Assumptions for Missing Information

- No A/B testing or staged rollout; feature launches to all users simultaneously.
- PayGate sandbox accepts standard test card numbers (Visa 4111 1111 1111 1111, etc.).
- Refund is automatic in application logic, not a manual or async process.
- No custom payment methods (ACH, PayPal) in scope; PayGate only.
- Support team has documented runbook for split-payment troubleshooting.
