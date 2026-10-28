# Risk-Based Test Plan: Split Payment (Release 5.3)

## Executive Summary

This plan prioritizes testing by financial and operational risk within resource constraints. The critical path focuses on payment processing correctness, refund guarantee compliance, and regression protection for the existing 4,000 daily single-card orders. Testing runs in two phases: dev-environment core logic (Weeks 1–1.5), then external PayGate integration (Week 2, constrained to Tue/Thu sandbox availability).

---

## Risk Assessment

| Risk | Impact | Probability | Priority | Mitigation Strategy |
|------|--------|-------------|----------|---------------------|
| Split amount calculation error (including cent-remainder logic) | Revenue loss, customer disputes, compliance issues | Medium | **CRITICAL** | Unit tests + parametric test cases + manual verification |
| Refund fails or exceeds 60-second SLA | Customer money at risk, regulatory/compliance exposure | Medium | **CRITICAL** | Integration testing, timeout simulation, refund logs verification |
| Second charge succeeds after first fails (inconsistent state) | Double-charging or revenue loss | Low | **CRITICAL** | State machine testing, idempotency verification |
| Single-card checkout regression | 4,000 daily orders at risk | Medium | **HIGH** | Regression test suite, production traffic simulation |
| PayGate integration misconfiguration | Feature blocked or non-functional in production | Medium | **HIGH** | Sandbox integration testing, API contract validation |
| Race conditions in concurrent payment processing | Duplicate charges, orphaned refunds | Low | **HIGH** | Load testing, transaction log analysis |
| Incorrect amount passed to PayGate | Charge mismatch with customer intent | Medium | **HIGH** | Boundary testing, audit trail verification |
| Error handling / user messaging failure | Poor customer experience, support burden | Medium | **MEDIUM** | Negative path testing, error scenario walkthroughs |
| Partial failure in refund retry loop | Stuck refunds, incomplete rollback | Low | **MEDIUM** | State recovery testing, idempotency confirmation |

---

## Test Strategy

### Phase 1: Core Logic & Dev Environment (Days 1–6)
*Focus: Payment calculation, refund logic, and single-card regression*

**Responsible:** Developers (unit/integration), part-time tester (manual validation)

- **Unit tests** for split amount calculation:
  - Even splits (e.g., $100 → $50/$50)
  - Uneven splits with remainder (e.g., $101 → $51/$50, $1.01 → $0.51/$0.50)
  - Edge cases: $0.01, $0.99, large amounts ($99,999.99)
  - Negative/invalid inputs (reject gracefully)

- **Integration tests** (mock PayGate):
  - Both charges succeed → payment recorded, no refund triggered
  - First charge fails → no second charge attempted
  - Second charge fails → first charge refunded within 60 seconds
  - Concurrent split-payment requests → no race condition
  - Idempotent refund retry (refund called twice → same result)

- **Regression tests**:
  - Single-card checkout flow unchanged
  - Existing payment states (pending, succeeded, failed) unchanged
  - Admin/reporting views show split payments correctly

### Phase 2: PayGate Integration & Live Testing (Days 7–10)
*Focus: Real payment gateway behavior and end-to-end validation*

**Responsible:** Part-time tester (primary), developer support

- **Sandbox integration** (Tue/Thu availability: 4 sessions across 10 days):
  - Tue of Week 1: Full happy path (both charges succeed)
  - Thu of Week 1: Decline second charge; verify refund within 60s
  - Tue of Week 2: Decline first charge; verify no second charge
  - Thu of Week 2: PayGate timeout simulation; verify retry behavior

- **Production readiness**:
  - Audit trail logging (all charges and refunds logged with timestamps)
  - State consistency checks (no orphaned transactions)
  - Refund timeout monitoring (alert if refund exceeds 60s)

---

## Test Cases by Priority

### CRITICAL – Must Pass Before Release

| Test ID | Scenario | Input | Expected Result | Acceptance Criteria |
|---------|----------|-------|-----------------|-------------------|
| TC-101 | Split $100 evenly | Card 1: $50, Card 2: $50 | Both charges succeed, payment recorded | Transaction log shows two $50 charges |
| TC-102 | Split $1.01 with remainder | Card 1: $0.51, Card 2: $0.50 | Both charges succeed, remainder on Card 1 | Transaction log: $0.51 and $0.50 |
| TC-103 | Second charge declined | Card 1: $50, Card 2 (decline card): $50 | Charge 1 succeeds, Charge 2 fails, Charge 1 refunded | Refund initiated within 5s, completed within 60s |
| TC-104 | First charge declined | Card 1 (decline card): $50, Card 2: $50 | Charge 1 fails, no Charge 2 attempted | Only one failed charge in log, no refund needed |
| TC-105 | Single-card checkout still works | Existing single-card flow | Order processes normally | No regression; 4,000/day throughput unchanged |
| TC-106 | Refund idempotency | Refund triggered twice for same failed charge | Second refund call has no effect | Only one refund in logs, same timestamp |

### HIGH – Should Pass Before Release

| Test ID | Scenario | Input | Expected Result | Acceptance Criteria |
|---------|----------|-------|-----------------|-------------------|
| TC-201 | Edge case: $0.01 split | $0.01 total | Allocation logic handles minimal amount | Charge routing correct, no rounding errors |
| TC-202 | Large amount split | $99,999.99 | Splits correctly, both charges accepted | No precision loss in calculation |
| TC-203 | Concurrent split payments | 10 simultaneous orders | All succeed or fail consistently | No duplicate charges, no orphaned transactions |
| TC-204 | Negative/invalid input | Negative amount or amount > order total | Request rejected before PayGate call | Clear error message, no charge attempted |
| TC-205 | PayGate timeout on second charge | Second charge times out after 30s | Refund triggered after timeout threshold | Refund initiated, customer notified |
| TC-206 | Admin dashboard shows split payments | View order details | Split breakdown visible with amounts & card endings | Audit trail shows both charges |

### MEDIUM – Time Permitting

| Test ID | Scenario | Input | Expected Result | Acceptance Criteria |
|---------|----------|-------|-----------------|-------------------|
| TC-301 | Refund retry after failure | Refund API call fails once, succeeds on retry | Transaction eventually consistent | Automatic retry within 5 attempts or manual intervention alert |
| TC-302 | Customer receives both receipt emails | Both charges succeed | Customer notified of both charges | Email timestamps show both charges |
| TC-303 | Reporting reconciliation | Run financial report post-split orders | Reported amounts match transaction log | No discrepancies in split vs. total |

---

## Regression Testing

**Scope:** Existing single-card checkout (4,000 orders/day baseline)

- Run existing checkout test suite against integration environment
- Smoke test: 50 single-card transactions end-to-end
- Verify payment states (pending → succeeded/failed) unchanged
- Confirm refund logic for single-card still works (if applicable)
- Check database schema compatibility (no breaking changes to payment tables)

**Estimate:** 4 developer-hours + 2 tester-hours

---

## Resource Allocation & Schedule

| Phase | Week | Days | Tester | Developer(s) | Deliverable |
|-------|------|------|--------|--------------|-------------|
| 1 | 1 | 1–3 | Code review, manual edge cases | Unit/integration tests | Test suite, 40+ test cases |
| 1 | 1 | 4–6 | Regression smoke tests | Refactor/fixes from test results | Regression sign-off |
| 2 | 2 | 7–8 (Tue/Thu) | PayGate sandbox testing (live) | On-call for support | Sandbox validation report |
| 2 | 2 | 9–10 | Final pass, documentation | Deployment prep | Release readiness checklist |

**Tester Capacity:** ~5 dev-days across 10 working days (0.5 FTE). Prioritize: TC-101 through TC-106, regression suite, then TC-2xx as time allows.

---

## Entry & Exit Criteria

### Entry Criteria (Ready to Test)
- Split payment feature code complete and merged to dev branch
- Mock PayGate integration available in dev environment
- Unit tests pass (>90% coverage on payment logic)
- Test environment has realistic data set (500+ test accounts)

### Exit Criteria (Ready to Release)
- All CRITICAL test cases pass (TC-101–TC-106)
- Regression test suite passes (no single-card regressions)
- PayGate sandbox integration validated (Tue/Thu session)
- Refund SLA timing verified (60-second guarantee documented)
- Audit trail logging confirmed in production config
- Deployment plan reviewed; rollback procedure documented

---

## Key Assumptions

1. **Dev environment equivalence:** Dev environment mirrors production payment flow (e.g., PCI compliance, encryption, logging).
2. **PayGate sandbox parity:** Sandbox API behaves identically to production (response codes, decline rules, idempotence).
3. **Test data available:** Test cards (success, decline scenarios) provided by PayGate for Tue/Thu sandbox sessions.
4. **Existing tests maintainable:** Current single-card checkout test suite can run without modification.
5. **Developers embed testing:** Developers write and maintain unit/integration tests; tester focuses on end-to-end and edge cases.
6. **Tue/Thu sandbox slots:** At least 2 productive Tue/Thu sandbox sessions available within the 10-day window (e.g., Oct 29, 31, Nov 5, 7).
7. **60-second refund SLA is achievable:** PayGate refund API responds within typical latency; no architectural redesign needed.
8. **No database schema migration:** Split payment feature fits existing payment/order schema without breaking changes.
9. **Manual refund fallback:** If automatic refund fails, support team can manually refund via PayGate admin console (documented procedure).

---

## Risk Mitigation Post-Release

- **Monitoring:** Alert if refunds exceed 60-second SLA; log all split-payment transactions for 30 days.
- **Support playbook:** Document how to handle refund failures; escalation path to PayGate support.
- **Rollback plan:** Feature flag to disable split payment; fallback to single-card checkout if PayGate integration degrades.
