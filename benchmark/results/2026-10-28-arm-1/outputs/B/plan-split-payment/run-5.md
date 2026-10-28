# Risk-Based Test Plan: Split Payment Feature (Release 5.3)

## Assumptions

- **Definition of working days:** Calendar weeks Mon–Fri; 10 working days = 2 calendar weeks (testing window: Oct 30 – Nov 12, 2026)
- **PayGate sandbox availability:** Testing restricted to Tuesdays (Oct 29, Nov 5, Nov 12) and Thursdays (Oct 31, Nov 7) during the sprint; one team member available each testing day
- **"Within 60 seconds" refund:** Strict SLA; timeout longer than 60s counts as a failure
- **Existing single-card checkout:** Already tested and stable; regressions are the primary concern
- **Deployment model:** Feature flag available to enable/disable split payment without code rollback
- **Development environment:** Unit tests and happy-path integration tests completed by dev team before QA handoff
- **PayGate API:** Supports test modes for both charge success and decline scenarios
- **Database access:** QA can query transaction logs and refund records

---

## Risk Assessment & Prioritization

| Risk | Impact | Likelihood | Priority | Mitigation |
|------|--------|-----------|----------|-----------|
| Second charge declines; refund logic fails or times out | **Critical** – customer double-charged, brand reputation damage, compliance issues | Moderate | **P0** | Automated refund verification tests; monitor refund SLA in logs; manual end-to-end with forced decline |
| Rounding error on cent split (e.g., $10.01 split 50/50) | **High** – either undercharge, overcharge, or payment mismatch | High | **P0** | Boundary-value tests for all odd-cent amounts; automated assertion on sum of charges |
| Regression in single-card checkout (4,000 orders/day at risk) | **High** – service outage for existing customers | Moderate | **P0** | Smoke tests on single-card flow; checkout analytics baseline before/after |
| PayGate sandbox unavailable (Tue/Thu only) | **Medium** – compressed testing window, cascading delays | High | **P1** | Pre-stage all test data by Mon; schedule sandbox testing sessions back-to-back |
| Session/state loss between card entries | **Medium** – confusing UX, abandoned carts | Low | **P1** | Test session persistence across page reloads, timeout scenarios |
| First charge succeeds, second charge succeeds, but order marked failed | **High** – customer appears to pay twice, reconciliation nightmare | Low | **P1** | Idempotency tests; verify transaction state after each charge; audit log review |
| Security: card data exposure or PCI non-compliance during split flow | **Critical** – legal/regulatory breach | Very Low | **P0** | Verify card data never logged; no split amounts in error messages; dev code review for secrets |

---

## Test Strategy

### Scope
- **In Scope:**
  - Split payment happy path (even and odd amounts, various splits)
  - Second charge decline + refund flow
  - Rounding and cent allocation logic
  - Single-card checkout regression (smoke tests)
  - PayGate integration (success and decline responses)
  - Session management and error states
  - Refund timing and verification

- **Out of Scope:**
  - Load testing (no resource allocation; ensure single-threaded checkout remains stable)
  - Advanced fraud detection (defer to PayGate)
  - Multi-currency support (assume USD only per brief)
  - Partial refunds (assume full refund only)

### Test Execution Approach
1. **Unit/Integration** (Dev team, before QA): Core payment logic, rounding, refund trigger (gating criterion for QA)
2. **Functional API Testing** (QA, async with dev): PayGate integration using sandbox credentials (Tue/Thu only)
3. **E2E/UI Testing** (QA, half-time): Checkout flow, payment flow, confirmation
4. **Regression Smoke** (QA, continuous): Single-card checkout before/after; monitoring dashboard

---

## Test Cases by Risk Priority

### P0: Refund Logic & Decline Scenarios

| ID | Test Case | Expected Outcome | Method | Automation |
|----|-----------|------------------|--------|-----------|
| **SplitPay-001** | Second charge declines; refund SLA | First charge refunded within 60s; order status = cancelled; customer notified | E2E (UI or API stub) with PayGate decline response | Automated (timer assertion + log verification) |
| **SplitPay-002** | Second charge declines; first charge already settled | Refund initiated within 60s of decline; audit log shows reason and timestamp | API integration test with 30-min settlement delay simulation | Automated (async refund job verification) |
| **SplitPay-003** | Refund fails (e.g., card issuer rejects reversal); escalation | Order marked for manual review; support ticket auto-generated; customer contacted | Manual verification + log review | Semi-automated (alert trigger + ticket creation check) |
| **SplitPay-004** | Both charges succeed; verify no phantom refund | Transaction count = 2, refund count = 0; order status = complete | API integration test | Automated |

### P0: Rounding & Cent Allocation

| ID | Test Case | Expected Outcome | Method | Automation |
|----|-----------|------------------|--------|-----------|
| **SplitPay-005** | Odd-cent amount: $10.01 split 50/50 | Card1: $5.01, Card2: $5.00 | Boundary-value API test | Automated |
| **SplitPay-006** | Odd-cent amount: $1.01 split 33/67 | Card1: $0.34, Card2: $0.67 | Boundary-value API test | Automated |
| **SplitPay-007** | Large amount with odd cents: $1234.56 split 60/40 | Card1: $740.74, Card2: $493.82 | Boundary-value API test | Automated |
| **SplitPay-008** | Sum of charges = order amount (no phantom cents) | sum(charges) = order_amount for 1000 random splits | Fuzz test (random order amounts 1–100,000 cents) | Automated |

### P0: Single-Card Regression

| ID | Test Case | Expected Outcome | Method | Automation |
|----|-----------|------------------|--------|-----------|
| **SplitPay-009** | Single-card checkout (existing flow) still works | Order completes; single charge only; no split dialog shown | E2E smoke test (checkout UI) | Automated (daily) |
| **SplitPay-010** | Single-card checkout analytics/logging unchanged | Conversion rate, payment success rate within 0.5% of baseline | Analytics dashboard comparison (before/after deploy) | Manual review (by QA + analytics team) |

### P1: Session & State Management

| ID | Test Case | Expected Outcome | Method | Automation |
|----|-----------|------------------|--------|-----------|
| **SplitPay-011** | Browser refresh after entering first card amount | Split amount persisted; page reloads without data loss | E2E UI test (Selenium or Cypress) | Automated |
| **SplitPay-012** | Session timeout during split flow | User redirected to checkout start; no orphaned transactions | E2E UI test (simulate 15-min idle) | Automated |
| **SplitPay-013** | Back button after first card declined | User can retry with same or different card without restarting | E2E UI test | Automated |

### P1: Idempotency & Data Consistency

| ID | Test Case | Expected Outcome | Method | Automation |
|----|-----------|------------------|--------|-----------|
| **SplitPay-014** | Duplicate refund API call (network retry) | Second refund rejected or idempotent; only one refund issued | API integration test (replay POST) | Automated |
| **SplitPay-015** | Both charges succeed, then second charge chargebacked | First charge refund issued; audit trail intact | Database query + manual review | Manual (run after chargeback simulation if supported by PayGate) |

### P1: Security (Dev Review + Spot Checks)

| ID | Test Case | Expected Outcome | Method | Automation |
|----|-----------|------------------|--------|-----------|
| **SplitPay-016** | Card data never logged (split amounts only) | Logs contain amounts, not card numbers; error messages don't leak card details | Code review + log inspection | Manual (dev code review + QA log audit) |
| **SplitPay-017** | Split payment endpoint requires authentication | Unauthenticated request rejected with 401 | API security test | Automated |

---

## Test Execution Timeline

| Week | Dates | Activities | Ownership |
|------|-------|-----------|-----------|
| **1** | Oct 28 – Nov 1 | Dev completes feature + unit tests (gating); QA preps test data, PayGate sandbox credentials, automation framework | Dev + QA |
| | **Tue Oct 29, Thu Oct 31** | QA executes API integration tests (P0 refund, rounding) on PayGate sandbox | QA (2 sessions, ~8 hrs) |
| **2** | Nov 4 – Nov 8 | QA runs E2E/UI tests; single-card regression smoke tests; dev fixes bugs from QA findings | QA + Dev |
| | **Tue Nov 5, Thu Nov 7** | QA executes additional sandbox tests (decline scenarios, edge cases) | QA (2 sessions, ~8 hrs) |
| **3** | Nov 11 – Nov 12 | Retesting of fixed bugs; final regression smoke test; UAT coordination with product | QA + Dev |
| | **Tue Nov 12** | Final sandbox validation; sign-off for staging deployment | QA |
| **Post-Deploy** | Nov 13+ | Monitor production metrics (conversion rate, refund latency) for 48 hrs; on-call escalation plan | QA + Ops |

---

## Resource Allocation (10 Working Days)

| Resource | Allocation | Hours | Breakdown |
|----------|-----------|-------|-----------|
| **QA (1 FTE @ 50%)** | 25 hrs | 200 mins test execution (Tue/Thu sandbox); 400 mins E2E/UI tests; 100 mins regression; 200 mins log review & bug verification | Sandbox test windows + async execution |
| **Dev (2 FTE)** | Feature build + support | Includes unit test writing, code review for P0 security, bug fixes from QA | Daily standup with QA |

---

## Entry & Exit Criteria

### Entry Criteria (QA Handoff)
- [ ] Feature branch code reviewed and approved
- [ ] Unit tests pass (≥80% coverage on payment logic)
- [ ] Happy-path integration test (single charge success) passes on PayGate sandbox
- [ ] Deployment runbook and rollback plan documented

### Exit Criteria (Ready for Production)
- [ ] All P0 test cases passed (refund SLA, rounding, regression)
- [ ] All P1 test cases passed or deferred with signed-off risk acceptance
- [ ] Zero critical security findings from code review
- [ ] Single-card checkout regression smoke test passes
- [ ] Refund SLA (60s) verified in production-like environment
- [ ] Runbook reviewed by on-call engineer; escalation plan clear
- [ ] Feature flag can toggle on/off without code deployment

---

## Risks & Constraints

| Constraint | Mitigation |
|-----------|-----------|
| **PayGate sandbox only Tue/Thu** | Pre-stage all test data and test cases by Mon; execute two focused sandbox sessions per week; mock PayGate responses for async E2E testing |
| **One half-time QA tester** | Prioritize P0 tests first; automate as many tests as possible; parallelize API tests and UI tests across two Tue/Thu sandbox windows |
| **10 working days** | No buffer for major rework; gate QA entry on dev completing unit tests by EOD Oct 28; daily standup to catch issues early |
| **4,000 single-card orders/day at risk** | Deploy feature behind flag; single-card flow must be untouched; smoke test on regression daily |

---

## Success Metrics

- **Payment success rate (split payment):** ≥99% for valid inputs
- **Refund SLA compliance:** 100% of refunds within 60 seconds for declined second charge
- **Rounding accuracy:** 0 errors across 10,000 test transactions
- **Single-card checkout regression:** <0.1% variance in daily order count and conversion rate before/after deploy
- **Bug escape rate:** ≤1 customer-impacting bug discovered in production in first week

---

## Sign-Off

**QA Lead (You):** ________________________  **Date:** __________

**Dev Lead:** ________________________  **Date:** __________

**Product:** ________________________  **Date:** __________
