# Risk-Based Test Plan: Split Payment (Release 5.3)

**Release date:** 2026-11-11  
**Test window:** 2026-10-29 to 2026-11-08  
**Testing resources:** 1 tester (20 hours), 2 developers (code review, dev testing)

---

## Risk Assessment & Testing Priority

| Risk | Impact | Likelihood | Mitigation | Test Type |
|------|--------|------------|-----------|-----------|
| Second charge declined; first charge not refunded | Revenue loss + customer friction | Medium | Automated refund logic; timeout handling | **Critical path** |
| Payment split calculation error (especially odd cents) | Charge mismatch; reconciliation effort | Low | Unit tests; sample data with $X.X1–$X.X9 amounts | Unit + integration |
| Existing single-card checkout breaks | 4,000/day orders interrupted | Medium | Regression suite; run on staging before release | Regression |
| PayGate integration point fails | No payments possible | Medium | Sandbox tests Tue/Thu only; dev environment fallback | Integration |
| Duplicate charges on network timeout | Financial liability | Low | Idempotency key validation; timeout behavior | Integration |

---

## Test Plan by Priority

### Tier 1: Critical Path (Must Pass Before Release)

**Goal:** Verify split payment end-to-end and refund automation.

| Test Case | Scenario | Steps | Expected Result | Notes |
|-----------|----------|-------|-----------------|-------|
| SP-01 | Split amount exactly 50/50 | Pay $50: $25 + $25 | Both charges succeed; order completes | Use PayGate sandbox; Tuesday or Thursday only |
| SP-02 | Split amount with remainder cent | Pay $100.01: $50.01 + $50 | First card charged $50.01; second $50 | Verify correct distribution of remainder |
| SP-03 | Second charge declined | Pay $50: first succeeds, second intentionally declined | First charge refunded within 60 seconds; order fails; customer notified | Test timeout edge case (just under 60s, just over 60s) |
| SP-04 | Refund API call fails | Simulate PayGate refund endpoint timeout | Refund retried automatically; alert logged | Manual verification of retry logic in logs |
| SG-01 | Single-card checkout works | Pay $50 with one card (existing flow) | Charge succeeds; order completes | Regression: run daily on staging |
| SG-02 | Single-card payment decline | Existing decline handling | Order fails; customer can retry | Regression: verify no new side effects |

### Tier 2: Boundary & Integration (High Priority)

| Test Case | Scenario | Steps | Expected Result | Notes |
|-----------|----------|-------|-----------------|-------|
| SP-05 | Split $0.01 (minimum) | Pay $0.01: $0.01 + $0 | First card charged $0.01; second skipped or charged $0 | Clarify product intent; may reject split under $X |
| SP-06 | Split large amount | Pay $10,000: $5,000 + $5,000 | Both charges succeed; order completes | Verify no gateway limits breached |
| SP-07 | User navigates away during payment | Close browser mid-second charge | Timeout handling; refund or manual reconciliation | Document expected behavior |
| SP-08 | Network delay on first charge | Inject 5-second latency; second charge fires immediately | First charge completes; no duplicate charges | Idempotency key prevents double-charging |
| SP-09 | PayGate rate limit hit | Rapid successive split payments (e.g., load test mode off) | Graceful backoff; clear error to user | Document PayGate limits; inform support |

### Tier 3: Usability & Edge Cases (Medium Priority)

| Test Case | Scenario | Steps | Expected Result | Notes |
|-----------|----------|-------|-----------------|-------|
| SP-10 | User enters split amount > total | Input $60 split on $50 order | Input validation rejects; error message shown | Front-end validation; back-end validation |
| SP-11 | Decimal places in split input | Input $50.556 split | Rounded to cents (assumes $50.56) or rejected | Clarify UX; test all locales using . and , |
| SG-03 | Checkout page load time | Measure time to payment screen | Stays within SLA (assume <2s) | Regression: no new JS blocking load |

---

## Testing Schedule

**Week 1 (Oct 29–Nov 1)**
- Dev environment: unit tests + local PayGate sandbox tests (Wed, Thu)
- Tester: regression suite on staging (all days); prepare test data

**Week 2 (Nov 4–8)**
- PayGate sandbox: Tier 1 critical path (Tue, Thu); parallel Tier 2 on dev
- Tester: manual usability tests + edge cases on staging
- Developers: code review during test runs; fix blockers same day

**Release week (Nov 11)**
- Final regression run (Nov 10, morning)
- Rollout plan: canary 10% of orders; monitor for refund timeouts, duplicate charges

---

## Assumptions

1. **Split payment UI:** Customers enter amount for card 1; card 2 gets the remainder (no manual entry for card 2).
2. **Refund triggers:** Automatic refund only on second-charge decline; first-charge failures handled by existing flow.
3. **PayGate testing:** Sandbox credentials provided; no production testing before release.
4. **Rejection threshold:** Split amounts under $0.01 are rejected (product decision assumed).
5. **Logging:** PayGate request/response and refund automation logged to audit trail for reconciliation.
6. **Tester access:** Full staging environment + PayGate sandbox credentials; no production access.

---

## Acceptance Criteria (Go/No-Go)

**Go to production if:**
- ✓ All Tier 1 tests pass on PayGate sandbox
- ✓ Refund automation tested and timing verified (< 60s)
- ✓ Single-card regression suite passes
- ✓ No duplicate-charge scenarios observed
- ✓ Load test: 10 concurrent split payments succeed

**No-go if:**
- ✗ Refund automation fails or exceeds 60-second timeout
- ✗ Single-card checkout breaks
- ✗ PayGate integration error not understood

---

## Post-Release Monitoring

- Alert on: refund failures, charges > 60s apart, duplicate transaction IDs
- Dashboard: split-payment success rate, average refund latency, second-charge decline rate
- Support escalation: any manual refund needed within 24 hours of release
