# Split Payment (Release 5.3) – Risk-Based Test Plan

## Executive Summary

This plan prioritizes testing based on financial impact, integration complexity, and regression risk. With one half-time tester and PayGate sandbox availability limited to Tuesdays and Thursdays, testing windows are constrained to 4 available days before release. Focus is on charge/refund correctness and existing checkout stability.

---

## Risk Assessment & Prioritization

| Risk | Severity | Likelihood | Priority | Impact |
|------|----------|-----------|----------|--------|
| Second charge declined; first charge not refunded within 60s | Critical | Medium | **P0** | Customer loses money; compliance/fraud risk |
| Remainder cent misallocated | High | High | **P0** | Systematic financial discrepancies |
| Split payment fails; falls back to single card without user awareness | High | Medium | **P0** | Wrong amount charged; customer confusion |
| Existing single-card checkout broken | High | Medium | **P0** | 4,000 orders/day lost; revenue impact |
| Race condition during concurrent split payments on same order | High | Low | **P1** | Potential double-charge or partial refund |
| PayGate timeout or network error during first or second charge | Medium | Medium | **P1** | Incomplete payment state; manual recovery needed |
| Customer enters invalid split amounts (e.g., negative, exceeds total) | Medium | High | **P1** | UX failure; checkout abandonment |
| Split payment works in sandbox but fails in production | Medium | Medium | **P1** | Post-release production incident |

---

## Test Strategy

### Approach
1. **Integration-first:** Prioritize PayGate integration scenarios over UI flows.
2. **Happy path + critical fails:** Test successful split charges and mandatory refund scenario.
3. **Regression protection:** Smoke test single-card checkout on each sandbox window.
4. **Boundary focus:** Remainder cent handling and edge-case amount splits.

### Assumptions (Where Unspecified)
- **Existing checkout code:** No changes required beyond split-payment feature addition; can be tested in isolation.
- **Refund trigger:** Automatic refund is triggered by PayGate decline response, not manually.
- **Card data:** Both cards are provided by customer in same checkout flow; no tokenization complexity.
- **Order state:** Split payment state is tracked in database; no third-party ledger dependency.
- **Production mirrors sandbox:** PayGate production environment behaves identically to sandbox for test scenarios.
- **Tester access:** Tester has PayGate sandbox credentials and test card list.
- **Monitoring:** Payment system logs and refund audit trail are available post-release.

---

## Test Coverage by Risk

### P0: Refund Completeness & Timing (Critical Path)

**Test Case 1: Happy path – both charges succeed**
- Order total: $100.00
- First card: $60.00 | Second card: $40.00
- Expected: Both charges succeed; no refund triggered; order status = completed
- Validation: PayGate logs confirm two separate transactions; order record shows split amounts
- Run on: Sandbox (Tue/Thu)

**Test Case 2: Second charge declined – first charge refunded within 60s**
- Order total: $100.00
- First card: $60.00 (succeeds) | Second card: $40.00 (declined)
- Expected: First charge refunded within 60 seconds; order status = payment_failed; customer receives refund notification
- Validation: PayGate logs show refund initiated within 60s of decline; payment record shows refund_timestamp; customer email/notification sent
- Run on: Sandbox (Tue/Thu); use PayGate's decline test card
- **Critical observation:** Monitor refund queue logs and timing; confirm no manual intervention required

**Test Case 3: First charge declined – second charge never attempted**
- Order total: $100.00
- First card: $60.00 (declined) | Second card: $40.00 (not charged)
- Expected: No refund needed; order status = payment_failed; second card not charged
- Validation: PayGate logs confirm only one transaction attempt; second card shows zero charge; customer notified

### P0: Remainder Cent Allocation

**Test Case 4: Odd-cent split**
- Order total: $100.01
- Customer chooses: $60 on first card
- Expected: First card: $60.01 (remainder cent) | Second card: $40.00
- Validation: Check payment database and PayGate ledger; confirm amounts match
- Test amounts: $1.01 (split 50/50 = $0.51/$0.50), $99.99 (split $49.99/$50.00)

**Test Case 5: Single-cent orders**
- Order total: $0.01
- Expected: First card: $0.01 | Second card: $0.00 (customer attempts to split; system prevents or allocates all to first)
- Validation: Confirm no split occurs or system warns customer

### P0: Existing Checkout Regression

**Test Case 6: Single-card checkout – unaffected by feature**
- Order total: $50.00
- Checkout via existing flow (no split option)
- Expected: Charge succeeds; order status = completed; no split_payment flag set
- Validation: Order record contains no split_payment data; payment shows single transaction
- Run on: Both sandbox and staging environment
- **Critical:** Run against production data volume simulation (order throughput test)

---

## P1: Edge Cases & Integration Failure Modes

**Test Case 7: Customer-entered invalid split amounts**
- Test inputs: -$10, $150 (exceeds $100 total), $50.50 when total is $50.00
- Expected: Validation error; customer cannot proceed; helpful error message shown
- Validation: Form validation blocks submission; no PayGate call initiated

**Test Case 8: Timeout during second charge**
- First charge succeeds; second charge request times out (simulate network delay)
- Expected: System retries within timeout window or marks order as pending; alerts operations
- Validation: Order state logged as uncertain; manual reconciliation instructions available

**Test Case 9: Partial refund success**
- First charge refund succeeds; PayGate confirms; no network error
- Expected: Refund fully completes within 60s; order marked as refunded
- Validation: Payment record shows refund_status = succeeded and refund_timestamp

---

## Test Execution Plan

### Timeline (10 Working Days)
- **Week 1 (Days 1–5):**
  - Days 1–4: Sandbox availability Thu + next Tue (2 windows)
    - Test Cases 1, 2, 3 (refund critical path)
    - Test Case 6 (single-card regression smoke test)
  - Days 5: Prep Test Cases 4–5 (remainder cent); stage test data
- **Week 2 (Days 6–10):**
  - Days 6–7: Sandbox availability Tue + Thu (2 windows)
    - Test Cases 4, 5 (remainder cent)
    - Test Cases 7, 8, 9 (edge cases)
    - Re-run Test Case 6 (regression check)
  - Days 8–10: Staging environment validation; release readiness signoff

### Resource Allocation (1 Tester @ 50%, 2 Developers)
- **Tester:** 4 hours/day
  - 2 hours manual test execution (sandbox/staging)
  - 1.5 hours test data prep and validation
  - 0.5 hours bug triage and re-testing fixes
- **Developers:** On-call for bug fixes; assist with test environment setup

### Sandbox Windows Utilized
- **Tue, Oct 29** → Test Cases 1, 2, 3, 6
- **Thu, Oct 31** → Test Cases 1, 2, 3, 6 (verify fixes if bugs found)
- **Tue, Nov 5** → Test Cases 4, 5, 7, 8, 9
- **Thu, Nov 7** → Re-run P0 tests; final regression check before release

---

## Acceptance Criteria for Release

- [x] Test Cases 1–3 (refund/decline) pass 100% on sandbox
- [x] Test Case 6 (single-card checkout) passes with zero regression; daily order volume baseline maintained
- [x] Test Cases 4–5 (remainder cent) pass; financial accuracy verified
- [x] All P1 edge cases (7–9) documented; known limitations captured (if any)
- [x] PayGate integration logs reviewed; no unexpected errors in production readiness check
- [x] Tester sign-off on test plan completion

---

## Post-Release Monitoring

- Monitor PayGate refund API call latency and success rate for 48 hours post-release
- Track split-payment order volume vs. single-card (confirm feature adoption)
- Set alert on refund lag > 60 seconds
- Weekly audit of refund logs for first 2 weeks to catch timing anomalies
- Customer support on standby for split-payment payment failures

---

## Risks to This Plan

1. **PayGate sandbox downtime (unscheduled):** No alternative sandbox available. Mitigation: Use staging mock if production sandbox unavailable; coordinate with PayGate support for priority access.
2. **Bugs found in Week 2 sandbox window (Days 6–7):** Limited time to re-test fixes before release (Day 10). Mitigation: Prioritize refund logic fixes first; defer cosmetic/UX issues to hotfix post-release if necessary.
3. **Tester unavailable mid-week:** Reduces execution window. Mitigation: Pre-script test cases for developer hand-off; automate regression test case 6 if possible.

---

## Test Environment Checklist

- [ ] Sandbox PayGate credentials active and verified
- [ ] Test card list (success, decline, timeout) loaded in sandbox environment
- [ ] Payment database has staging/test schema with read/write access
- [ ] Refund audit logs and timestamps queryable
- [ ] Order management system logs accessible
- [ ] Email/notification system can be monitored for customer alerts
- [ ] Single-card checkout baseline throughput measured (orders/sec under current load)
