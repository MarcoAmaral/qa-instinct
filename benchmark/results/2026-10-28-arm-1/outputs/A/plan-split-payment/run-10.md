# Risk-Based Test Plan: Split Payment (Release 5.3)

## Executive Summary
This plan prioritizes testing to protect payment integrity and refund automation—the highest-impact, highest-probability failure modes. With one half-time tester and 10 working days (but only 4 PayGate sandbox days available), we focus automated regression testing on the stable code path, reserve manual testing for new split-payment logic, and front-load PayGate integration testing into the next available sandbox window.

## Assumptions
- **Current state**: Existing single-card checkout has automated test coverage (unit + integration); we inherit it.
- **Developer testing**: The two developers handle unit tests and initial integration; the tester focuses on end-to-end and regression.
- **Environments**: Dev, staging with mock PayGate, and PayGate sandbox (available Tue/Thu only).
- **Release readiness**: Go/no-go decision happens by day 8 to leave 2 days for critical fixes.
- **"Working" single-card checkout**: Current throughput and error rates sustained; no degradation in checkout flow or refund latency.

## Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|-----------|
| Partial refund fails; customer loses money | Catastrophic | Medium | Automated refund logic tested extensively; monitor PayGate response codes |
| Split amount logic error (rounding, decimal handling) | High | Medium | Unit tests on rounding edge cases; manual verification of 10+ splits |
| Second charge succeeds after first is refunded | Catastrophic | Low | Atomic transaction logic + idempotency keys; code review focus |
| PayGate integration breaks on split (new payload format) | High | Medium | Mock-first, then sandbox validation; sandbox time is bottleneck |
| Existing checkout regresses (slower, 1% error rate increase) | High | Medium | Automated regression suite; load test on current throughput (4k/day baseline) |
| Sandbox unavailable when needed | Medium | High | Test prep complete before Tue/Thu windows; async mock testing in Dev |
| Tester capacity (half-time) insufficient | Medium | High | Automate regression; developers own split-payment unit tests; tester owns E2E |

## Test Strategy

### Tier 1: Critical Path (Days 1–4, must complete before first PayGate window)
**Risk**: Refund automation, split logic, PayGate integration fault.  
**Owner**: Developers (unit + mock integration) + Tester (E2E mock validation).

**In scope**:
- Split amount calculation: 10 scenarios (even splits, odd-cent remainder, edge amounts like 1¢/999¢, $0.01/$999.99)
- Mock PayGate flow: first charge succeeds → second succeeds → order complete (happy path)
- Mock PayGate flow: first succeeds → second declined → first charge refunded within 60s
- Idempotency: retry second charge after decline; no double-refund
- Regression: single-card checkout still works (mock PayGate), no latency increase

**Exit criteria**: 
- All split-logic unit tests pass.
- Mock E2E passes happy path and refund path.
- No regression in single-card mock flow.

### Tier 2: Sandbox Integration (Tue/Thu, Days 5–7, ~12 hours available)
**Risk**: PayGate API contract mismatch, real decline handling, timing edge cases.  
**Owner**: Tester (primary) + 1 developer (support).

**In scope**:
- Real split payment (first and second charge) with test cards (success scenarios).
- Decline scenario on second card; verify automatic refund within 60s.
- Network latency and timeout handling on second charge.
- Declined-refund idempotency: replay second decline; no duplicate refund.

**Out of scope** (time-limited):
- Load testing (4k orders/day) on sandbox—not representative; defer to staging/prod monitoring.
- Multi-card retry strategies (out of scope for 5.3).

**Exit criteria**:
- Real split charges complete end-to-end.
- Refund on second-charge decline confirmed.
- No API errors; PayGate response codes logged.

### Tier 3: Regression & Stability (Days 4–9, ongoing)
**Risk**: Existing checkout breaks or slows under concurrent traffic.  
**Owner**: Tester + automated suite.

**In scope**:
- Automated regression: run existing single-card tests after each developer commit.
- Manual spot-check: 5 single-card orders at day 5, day 7, day 9 (capture latency, error rates).
- Staging smoke test: 50 orders (mix of single/split) at day 8 before go/no-go.

**Exit criteria**:
- Zero regression in single-card flow.
- Existing error rate ≤ current baseline.

### Tier 4: Edge Cases & Manual Validation (Days 5–8, if capacity allows)
**Risk**: Unexpected payment states, UI/UX clarity.  
**Owner**: Tester.

**In scope** (ordered by priority):
1. Split amount = order total (all on card 1, card 2 charge = $0; should be rejected at form level).
2. Split amount > order total (form validation).
3. Concurrent split attempts (same order); verify no duplicate charges.
4. Customer closes browser mid-split; verify no orphaned charges.
5. Split with different currencies (if multi-currency supported; otherwise N/A).

**Exit criteria**: No unhandled edge cases; form validation clear.

---

## Test Coverage Matrix

| Area | Type | Owner | Coverage |
|------|------|-------|----------|
| Split logic (rounding, remainder) | Unit | Dev | 100% (10 cases) |
| Refund automation | Unit + Mock | Dev | Happy path + 3 decline scenarios |
| PayGate integration (mock) | Integration | Dev | 100% split scenarios |
| PayGate integration (sandbox) | E2E | Tester | Happy path + decline |
| Single-card regression | Automated + Manual | Tester | Existing test suite + spot-checks |
| UI/form validation | Manual | Tester | 5 edge cases (if time allows) |

---

## Resource Plan

| Role | Effort | Allocation |
|------|--------|------------|
| Developer A | Full-time | Split logic + refund logic + PayGate mock integration |
| Developer B | Full-time | PayGate API contract + idempotency keys + regression review |
| Tester | 50% (~20 hrs/wk) | Day 1–4: mock E2E setup; Day 5–7: sandbox testing; Day 8–10: regression + smoke tests |

---

## Timeline

| Phase | Dates | Activity | Owner |
|-------|-------|----------|-------|
| Dev & Mock Testing | Days 1–4 | Unit tests, mock E2E, form validation | Devs + Tester |
| First Sandbox Window | Tue/Thu (Days 5–6) | Real split & refund validation | Tester + Dev B |
| Regression Surge | Days 5–9 | Automated regression + spot-checks | Tester |
| Go/No-Go Review | Day 8 | Staging smoke test; release readiness decision | All |
| Contingency & Fixes | Days 9–10 | Fix critical bugs; final validation if gate fails | Devs |

---

## Exit Criteria (Definition of Done)

- ✓ All Tier 1 tests pass (split logic, mock refund, regression baseline).
- ✓ Sandbox window test results: real split charge + refund automation verified.
- ✓ Zero critical bugs (payment loss, unrefunded transactions).
- ✓ Single-card checkout: error rate unchanged; latency within 5% of baseline.
- ✓ Regression suite passes 100%.
- ✓ Go/no-go decision made by day 8; release by day 10.

---

## Monitoring & Contingency

**Post-release monitoring** (first 48 hours):
- PayGate error rates on split charges (target: <0.5%).
- Refund automation SLA (target: 100% within 60s; alert if any take >70s).
- Single-card checkout throughput (target: 4k/day baseline ±2%).

**Kill-switch**: If any day-1 split charge fails to refund or refunds a second time, rollback split-payment feature flag and issue single-card-only orders.
