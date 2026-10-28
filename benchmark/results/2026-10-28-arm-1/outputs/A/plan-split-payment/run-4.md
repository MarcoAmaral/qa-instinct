# Risk-Based Test Plan: Split Payment Feature (Release 5.3)

## Executive Summary

This plan prioritizes testing efforts on high-impact payment processing logic and critical system integrations given resource constraints (1 half-time tester, 10 working days until release, PayGate sandbox availability limited to Tuesdays/Thursdays). The strategy emphasizes automated and regression testing to protect the existing 4,000 daily single-card orders while validating split payment correctness and the refund safety net.

## Risk Assessment

| Risk | Severity | Impact | Mitigation Priority |
|------|----------|--------|---------------------|
| Second charge decline + refund failure (race condition, timeout) | Critical | Financial loss, customer dispute, PCI compliance | **Highest** |
| Amount split logic errors (rounding, cent remainder) | High | Underbilled/overbilled customers, reconciliation issues | **Highest** |
| PayGate integration failures (timeouts, malformed requests) | High | Payment gateway errors, customer checkout abort | **High** |
| Regression in single-card checkout | High | 4,000 orders/day at risk, revenue impact | **High** |
| Edge cases: zero amounts, same card twice, extreme values | Medium | Rare but high-impact user scenarios | **Medium** |
| PCI compliance (card data handling during split) | High | Regulatory violation, audit failure | **High** |
| Concurrent split payment requests | Medium | Race conditions in refund/reconciliation | **Medium** |

## Test Strategy

### Phase 1: Unit & Integration Testing (Weeks 1–1.5, Continuous)
**Owner:** Developers + QA (async)  
**Environment:** Local dev + CI/CD pipeline

- **Amount split logic** (0 tests → 100% coverage):
  - Exact halves (e.g., $100 → $50/$50)
  - Odd amounts with remainder (e.g., $51 → $25.51/$25.00, $25.01/$25.99)
  - Edge cases: $0.01, $0.02, $99.99, $1,000.00
  - Assertion: first card always absorbs remainder cent
  - Automate; run on every commit
  
- **Refund retry logic** (deterministic):
  - Mock PayGate decline; verify refund triggered within 1 second
  - Verify refund idempotency (safe to retry)
  - Verify first charge amount matches refund amount
  - Verify status state machine (pending → charged → refunding → refunded/failed)

- **Single-card checkout regression** (existing test suite):
  - Run full regression suite; zero new failures allowed
  - Add 10 new tests for card-type boundary cases (Visa, Mastercard, Amex)

### Phase 2: PayGate Sandbox Testing (Weeks 1.5–2.5, Tues/Thurs only)
**Owner:** QA (half-time tester, ~8 hours per sandbox day)  
**Environment:** PayGate sandbox  
**Availability:** 4 sandbox days total (Tues 10/29, Thurs 10/31, Tues 11/5, Thurs 11/7; Friday 11/8 is blackout before release)

**High-priority scenarios (mandatory):**
- [Tues 10/29] **Happy path & decline scenarios** (2 hours):
  - Both charges succeed; verify settlement
  - First charge succeeds, second declined; verify refund auto-triggers and completes
  - First charge fails; verify second card not charged
  
- [Thurs 10/31] **Refund timing and race conditions** (2 hours):
  - Measure refund latency from decline to completion (target: <60s)
  - Simulate network delay; confirm refund still triggers
  - Charge succeeds but webhook delayed; verify idempotent handling
  
- [Tues 11/5] **Boundary amounts & rounding** (1.5 hours):
  - Amounts ending in .01, .99, .50
  - Verify PayGate receives correct split (both must sum to order total in cents)
  
- [Thurs 11/7] **Regression on single-card** (1.5 hours):
  - 5 live transactions via existing checkout path
  - Verify PayGate integration unchanged

**Lower-priority scenarios (if time permits):**
- Concurrent requests (2 simultaneous splits)
- Same card used twice (if permitted by business logic)

### Phase 3: Staging/Pre-Production (Week 2.5, optional shadow traffic)
**Owner:** Developers + QA  
**Condition:** Only if time permits and sandbox testing passes

- Deploy to staging with shadow traffic mirroring 5% of production
- Monitor for PayGate API errors, timeout patterns, refund completion
- Verify PCI compliance: no card data logged, no unauthorized persistence

### Phase 4: Production Validation (Day 1 post-release)
**Owner:** Developers on-call  
**Duration:** First 2 hours post-launch

- Monitor: first 50 split payments for success rate, refund triggers, settlement
- Verify: no increase in payment errors vs. single-card baseline
- Rollback plan: feature flag to disable split payments; allow single-card fallback

---

## Test Scope & Scenarios

### In Scope (Must Test)
1. **Split logic**: 15 test cases (even/odd/edge amounts)
2. **Refund automation**: 8 test cases (decline scenarios, timing, idempotency)
3. **PayGate integration**: 6 live sandbox transactions
4. **Single-card regression**: Existing test suite + 10 new boundary cases
5. **PCI compliance check**: Manual code review of card data handling

### Out of Scope (Deferred or Assumed Safe)
- UI/UX testing (assume frontend dev team validates separately)
- Third-party card processor behavior beyond PayGate (assume PayGate handles Visa/Mastercard routing)
- Fraud detection rules (assume PayGate rules apply; no custom rules added)
- Mobile app (assume uses same backend; test backend only)

---

## Resource & Timeline Allocation

| Task | Owner | Hours | Timeline | Sandbox Days Used |
|------|-------|-------|----------|-------------------|
| Unit tests (split, refund, regression) | Dev + QA | 20 | Week 1, continuous | — |
| Happy path + decline sandbox | QA | 2 | Tues 10/29 | 1 |
| Refund timing sandbox | QA | 2 | Thurs 10/31 | 1 |
| Boundary amounts sandbox | QA | 1.5 | Tues 11/5 | 1 |
| Regression + single-card sandbox | QA | 1.5 | Thurs 11/7 | 1 |
| Staging/monitoring (optional) | Dev | 4 | Week 2.5 | — |
| Production validation (on-call) | Dev | 2 | Day 1 post-release | — |
| **Total** | | **32.5** | | **4 days** |

**Tester capacity:** 20 hours/week × 2 weeks = 40 hours available; plan allocates ~8 hours sandbox + ~6 hours async regression = well within capacity.

---

## Assumptions

1. **PayGate sandbox access:** Pre-approved; credentials configured before 10/29.
2. **"Within 60 seconds" refund:** Backend initiates refund immediately on decline webhook; PayGate processes within 60s (team owns trigger, not PayGate processing time).
3. **Release date:** 10 working days = Monday 11/10 to Tuesday 11/11 (Tue 10/29 → Fri 11/8 is 8 calendar days = ~6 working days; +4 days = 11/11 release assumed).
4. **Existing payment infrastructure:** Assume single-card flow is stable, PCI-compliant, and tested; no changes needed beyond split logic.
5. **Remainder handling:** Business rule (first card gets remainder cent) is non-negotiable and coded; no customer choice.
6. **Concurrency:** System handles concurrent requests for same customer; refund logic is transactional.
7. **Rollback capability:** Feature flag exists or code can be rolled back within 30 minutes.
8. **Developer availability:** 2 developers are primarily building; available for ad-hoc debugging/fixes during sandbox days.

---

## Acceptance Criteria

### To Ship
- [ ] All unit tests pass (split logic, refund, regression); 100% coverage on new split code
- [ ] 4 PayGate sandbox test days completed; zero critical failures
- [ ] Refund auto-triggers on second charge decline and completes in <60s (sampled 3+ times)
- [ ] Single-card checkout regression tests pass (0 new failures vs. baseline)
- [ ] PCI compliance review completed (card data handling sign-off)
- [ ] Rollback procedure documented and rehearsed

### Monitoring Post-Release (48 hours)
- [ ] Split payment success rate ≥98%
- [ ] Refund success rate ≥99% (of declined second charges)
- [ ] No increase in payment errors vs. pre-release baseline
- [ ] No PCI compliance alerts
- [ ] Customer support: zero reports of split payment failures (first 48 hours)

---

## Risk Acceptance & Trade-offs

**Accepted risks (given constraints):**
- No load/stress testing on PayGate integration (resource-limited; assume PayGate handles ~100 TPS easily)
- No mobile app testing (deferred; assume uses same backend)
- No fraud scenario testing (assume PayGate rules apply)
- Limited concurrent-request testing (1 half-time tester; developers will monitor live traffic)

**Mitigation for accepted risks:**
- Feature flag to disable split payments if production issues arise
- Developers on-call first 2 hours post-release
- Automated monitoring alerts for refund delays >120s or decline-without-refund patterns

---

## Deliverables

- [x] This test plan (shared with dev team, QA, product, ops)
- [ ] Unit test suite (developers; CI/CD integration)
- [ ] PayGate sandbox test runbook (QA; step-by-step scripts for 4 sandbox days)
- [ ] Single-card regression suite addendum (QA; 10 new test cases)
- [ ] Rollback runbook (developers; feature flag or revert procedure)
- [ ] PCI compliance sign-off checklist (QA; manual code review)
- [ ] Production monitoring dashboard (developers; first 48 hours)
