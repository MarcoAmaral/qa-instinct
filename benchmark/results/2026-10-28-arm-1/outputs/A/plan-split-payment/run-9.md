# Risk-Based Test Plan: Split Payment (Release 5.3)

## Assumptions

- "10 working days" = release by 2026-11-10 (excludes weekends; today is Wed 2026-10-28)
- PayGate sandbox access is required for integration testing; production cannot be used
- "Half time" tester = 20 hrs/week; developers contribute 10% to testing
- Existing single-card checkout is stable; no known defects
- Refund timing ("within 60 seconds") is a hard requirement and auditable
- Split payment only applies to online checkout, not phone orders or invoices
- Second card charge attempt occurs only after first succeeds
- Maximum order value is within PayGate daily limits
- Database rollback capability exists for failed test transactions

## Risk Assessment & Priorities

| Risk | Likelihood | Impact | Strategy |
|------|-----------|--------|----------|
| **Second charge fails; first charge not refunded** | High | Critical | Automated testing + manual verification; production monitoring |
| **Regression in existing checkout** | Medium | Critical | Daily smoke tests on production-like data; run before release |
| **Remainder cent allocation logic incorrect** | Medium | High | Unit + integration tests; edge case table-driven tests |
| **PayGate integration fails** | Medium | High | Sandbox-first testing; mock PayGate for early unit tests |
| **Race condition: user navigates away before refund triggers** | Low | High | Timeout/retry logic testing; session persistence tests |
| **Amount parsing or rounding errors** | Low | High | Boundary value analysis; test in cents, not decimals |
| **Sandbox-only testing coverage gap** | Medium | Medium | Manual testing plan for prod-like scenarios post-release |

## Test Scope

### In Scope
1. Split payment flow: card selection, amount split, validation
2. PayGate integration: charge sequencing, decline scenarios
3. Automatic refund: timing, idempotency, audit trail
4. Remainder cent allocation (e.g., $10.01 split = $5.01 + $5.00)
5. Regression: existing single-card checkout on high-volume data
6. Edge cases: minimum/maximum amounts, zero splits, same card used twice

### Out of Scope
- Multi-card payment for orders split across multiple shipments (future feature)
- Refund processing timelines beyond 60-second auto-trigger
- Third-party payment methods (Apple Pay, etc.) in this release

## Test Strategy

### Layer 1: Unit Tests (Developers, Days 1–3)
- Amount split logic (remainder handling, edge cases)
- Validation: card data, amount ranges, user inputs
- Refund idempotency (second refund attempt doesn't duplicate)
- Target: 90%+ code coverage for split payment module

### Layer 2: Integration Tests (Developers + Tester, Days 3–6)
- **PayGate sandbox (Tue–Thu only)**
  - Successful split charge (both cards approved)
  - First card approved, second declined → auto-refund within 60 sec
  - First card declined → second card not charged
  - Timeout/retry scenarios
  - Idempotency: duplicate requests don't double-charge
  
- **Regression suite (nightly, any environment)**
  - Single-card checkout with 100 synthetic orders
  - Order history retrieval
  - Invoice generation
  - Refund processing (existing flow)

### Layer 3: Manual Testing (Tester, Days 6–9)
- **Sandbox environment (Tue–Thu windows)**
  - End-to-end split payment happy path
  - UI state after second charge decline (error message, retry option)
  - Payment method editing mid-flow
  - Network latency / interruption scenarios (refresh page, close browser)
  
- **Staging environment (any day)**
  - Regression: place 50 test orders via single-card checkout
  - Verify refund audit trail in admin dashboard
  - Verify customer email confirmations (single vs. split)
  - Concurrency: 5 simultaneous split-payment attempts

### Layer 4: Production Readiness (Days 9–10)
- Smoke test: 10 live split payments (if pre-release window available)
- Fallback plan: feature flag to disable split payment if critical bug discovered
- Monitoring: alert on refund latency >60 sec, PayGate API errors

## Test Cases: High-Risk Scenarios

### Critical Path: Refund on Second-Card Decline
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Order $50; split $30 / $20 | Split accepted |
| 2 | First card charged $30 | Success; transaction logged |
| 3 | Second card declined | Decline detected; refund triggered |
| 4 | Verify first charge refunded | Refund processed in <60 sec; audit log shows timestamp |
| 5 | Verify customer notification | Email sent; order marked "payment failed" |

### Boundary: Remainder Cent Allocation
- $0.01 split as $0.01 / $0.00 → first card charged $0.01 ✓
- $1.00 split as $0.50 / $0.50 → even split ✓
- $99.99 split as $50.00 / $49.99 → remainder on first ✓

### Regression: Existing Single-Card Checkout
- Order $100 single card → charge once, no splits ✓
- Decline on single card → no refund needed ✓
- Refund request on legacy order → existing flow unchanged ✓

## Test Schedule

| Phase | Dates | Owner | PayGate Window |
|-------|-------|-------|---|
| Unit + early integration | Wed 10/28–Fri 10/30 | Developers | Sandbox Tue 11/5, Thu 11/7 (off-cycle testing begins) |
| Sandbox integration testing | Tue 11/5, Thu 11/7 | Dev + Tester | Scheduled sandbox access |
| Staging regression + manual | Mon 11/10–Tue 11/11 | Tester (full FTE) | N/A (mocked PayGate in staging) |
| Production smoke test (if window) | Tue 11/11–Wed 11/12 | Tester | Live PayGate (post-approval) |
| Release ready | Wed 11/12 | All | — |

## Entry & Exit Criteria

### Entry Criteria
- Feature code complete and reviewed
- Unit test suite passes (90%+ coverage)
- Test environments ready (staging + sandbox access confirmed)

### Exit Criteria (All Required)
- ✓ Integration tests pass on sandbox (both charge scenarios)
- ✓ Refund latency measured <60 sec in ≥5 test runs
- ✓ Regression: 100 single-card test orders completed without errors
- ✓ Manual smoke test: ≥10 end-to-end split payments succeed
- ✓ No critical bugs (P1); blockers resolved or feature flagged off
- ✓ Monitoring alerts configured for refund latency & API errors

## Resource Plan

| Role | Allocation | Responsibilities |
|------|-----------|---|
| Tester (0.5 FTE, full-time weeks 11/10–11/12) | 10 hrs/wk then 40 hrs/wk | Integration test execution, manual testing, regression validation |
| Developer 1 | 10% testing time | Unit tests, sandbox integration, refund logic verification |
| Developer 2 | 10% testing time | PayGate API integration tests, edge-case debugging |

## Risks to Plan Itself

1. **PayGate sandbox downtime**: Contingency: mock PayGate for 80% of tests; accept single real-sandbox validation run.
2. **Tester unavailability**: Contingency: developers run manual test cases with checklist.
3. **Regression discovery late**: Mitigation: run single-card regression daily starting Day 1.

## Monitoring & Rollback

- **Post-release monitoring (Week 1)**
  - Alert: refund processing latency >60 sec
  - Alert: PayGate decline rate >2% above baseline
  - Alert: refund processing errors or duplicates
  
- **Rollback plan**
  - Feature flag to disable split payment for new orders
  - Existing split transactions complete; no mid-flight cancellation
  - Refund any orphaned first charges within 24 hours
