# Test Plan: Split Payment Feature (Release 5.3)

## 1. Context of Testing

**Scope**  
Split payment functionality allowing customers to divide a single order payment between two payment cards, with automatic refund processing if the second charge is declined.

**Objectives**
- Verify correct calculation and distribution of payment amounts between two cards (including remainder cent logic)
- Validate automatic refund of first card within 60-second SLA if second charge is declined
- Confirm both cards process through PayGate successfully
- Ensure existing single-card checkout flow remains unaffected and operational
- Detect regressions in the high-volume single-card checkout (≈4,000 orders/day)

**Test Basis**
- Feature brief: Split payment specification
- PayGate API documentation and sandbox contract
- Existing checkout flow and test suite (assumed ≈70% coverage)

---

## 2. Assumptions and Constraints

**Assumptions**
- Split payment is web-only for v5.3 (mobile deferred to v5.4)
- Staging environment is available and mirrors production PayGate integration
- Feature flag available for rollback if critical defect surfaces post-release
- Existing checkout test suite provides baseline regression coverage
- PayGate test card credentials and webhook signing keys are pre-provisioned
- Developer build will be ready for test handoff by EOD Wed Oct 30
- Single-card checkout is stable; changes are additive (payment orchestration layer only)

**Constraints**
- PayGate sandbox available **Tuesdays and Thursdays only** (limiting real gateway testing windows: Oct 29, Oct 31, Nov 4, Nov 6)
- Release date: 10 working days from today (Nov 10, 2026)
- Testing capacity: 1 tester @ 0.5 FTE (20 hrs/week) + 2 developers contributing ~10% test effort (estimated 8 hrs total)
- Total available test capacity: ≈48 hours
- Constraint: Sandbox-only testing constrains real PayGate API testing to 4 days across 2 weeks
- Single-card checkout SLA: must not degrade; regression suite must pass 100%

---

## 3. Stakeholders

| Role | Name/Title | Responsibilities | Relevance to Testing |
| --- | --- | --- | --- |
| **Product Owner** | Release Owner | Feature sign-off, priority decisions | Approves exit criteria, prioritizes defect fixes, gates release |
| **Test Lead** | QA (0.5 FTE) | Test planning, execution, defect triage, sign-off | Owns testing, monitors risk register, reports daily status |
| **Developers** | 2 × Backend Engineers | Build feature, code review, unit testing | Contribute integration tests; triage defects; support PayGate debugging |
| **DevOps** | Infrastructure Lead | Environment provisioning, deployment | Ensures Staging reflects production config; controls feature flag |
| **Support** | Ops Team Lead | Cutover planning, on-call readiness | Monitors split payment post-release; escalates defects |

---

## 4. Communication

**Forms and Frequency**
- **Daily standup** (10 min, sync): Test progress, blockers, PayGate sandbox outages
- **Test status report** (EOD, async): Cases run, pass rate, defects opened, risk register updates
- **Defect triage** (daily, 15 min, sync): Severity, root cause assignment, retest plan
- **Release gate review** (Thu Nov 6, 30 min, sync): All 6 gate cases verified passing, sign-off meeting scheduled
- **QA sign-off meeting** (Mon Nov 10, 1 hour, sync): Final report, exit criteria audit, Product Owner approval, release decision

**Document Templates**
- Test Plan: this document (living; revised with dated corrections)
- Test Result Sheet: per execution (case ID | expected | actual | pass/fail | defect ID | notes | timestamp)
- Defect Log: ticket system (linked to test case, severity, root cause, fix date)
- Risk Register: this document, Section 5 (re-assessed at each triage; corrections dated)

---

## 5. Risk Register (5×5 Product & Project Risks)

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | R01 | Second charge declined; first charge not refunded within 60s SLA | Product | 3 | 5 | **15** | 🔴 CRITICAL | Automated refund with exponential retry; E2E + unit tests for retry logic; monitoring alerts on PayGate timeout; rollback plan | Dev + QA |
| 2 | R02 | First charge succeeds, second charge declines, resulting in inconsistent payment state (customer charged but order incomplete) | Product | 2 | 5 | **10** | 🟠 HIGH | Idempotent charge requests; webhook-driven state machine; TC-002 with full state audit; defect tracking for partial refunds | Dev + QA |
| 3 | R03 | Remainder cent logic incorrect (e.g., $100.01 → $50.00 + $50.01 instead of $50.01 + $50.00) | Product | 2 | 4 | **8** | 🟠 HIGH | Unit tests for all edge cases (odd cents, zero, max amount); TC-003 with decision table; code review checklist | Dev + QA |
| 4 | R04 | Single-card checkout broken by split payment changes (invasive payment orchestration refactor) | Product | 2 | 5 | **10** | 🟠 HIGH | Isolation layer (split payment handler ≠ existing checkout path); regression test suite for single-card (50+ existing cases); smoke test pre-deployment | Dev + QA |
| 5 | R05 | Race condition: two concurrent split payment requests race for refund processing | Product | 2 | 4 | **8** | 🟠 HIGH | Database-level transaction locks; TC-005 with concurrent load testing; PayGate idempotency keys | Dev + QA |
| 6 | R06 | PayGate sandbox unavailable during critical test window (server outage, not tue/thu) | Project | 2 | 4 | **8** | 🟠 HIGH | Mock-based integration tests as primary; real sandbox testing deferred to tue/thu windows; contingency: 2x testing hours Thu Nov 6 if Tue Nov 4 fails | QA |
| 7 | R07 | Edge cases in split logic (zero-dollar card, amounts >order total, negative amounts) | Product | 2 | 3 | **6** | 🟡 MEDIUM | Input validation unit tests; whitebox TC-007; exploratory testing on boundary values | Dev + QA |
| 8 | R08 | PayGate webhook for second charge fails to arrive or arrives twice (idempotency failure) | Product | 2 | 3 | **6** | 🟡 MEDIUM | Webhook signature verification; retry with exponential backoff; TC-006 webhook test; monitoring/alerting | Dev + QA |
| 9 | R09 | Insufficient test coverage due to sandbox-only testing window constraint (4 tue/thu slots across 10 days) | Project | 3 | 4 | **12** | 🟠 HIGH | Mock-based integration tests + real sandbox burst testing; prioritize gate cases in real windows; accept exploratory testing risk if time runs short | QA |
| 10 | R10 | Single tester becomes unavailable mid-sprint (illness, urgent production issue) | Project | 2 | 4 | **8** | 🟠 HIGH | Cross-train one developer on test execution; test case documentation is self-explanatory; runbooks for gate execution | Dev Lead + QA |
| 11 | R11 | Developer build delayed past Wed Oct 30, compressing test time | Project | 2 | 3 | **6** | 🟡 MEDIUM | Daily build readiness check at standup; parallel test design while dev works (mocked PayGate initially) | QA + Dev Lead |
| 12 | R12 | Inadequate test data (PayGate test card limits, insufficient seed data for concurrent testing) | Project | 2 | 3 | **6** | 🟡 MEDIUM | Confirm test card provisioning with PayGate by Oct 28; data fixture script (SQL seed) prepared by Oct 29 | QA + DevOps |

**Risk Responses**
- **Accepted**: R07 (low-impact edge cases); R11 (dev delay low probability, mitigation in place)
- **Mitigated**: All CRITICAL and HIGH risks via test coverage, mocking, and contingency windows
- **Monitored**: Re-score daily at triage; update if sandbox outage confirmed or tester availability changes

---

## 6. Test Approach

### Test Levels & Architecture

**Diagnostic Question**: "Where does the business logic live?"  
Payment split logic, refund automation, and state consistency all live in the backend (Java/Go service calling PayGate API). Proposed test pyramid:

- **Unit Tests** (60%): Split calculation, refund retry logic, edge cases, state machine transitions
- **Integration Tests** (25%): PayGate API mocking (VCR/Testcontainers), webhook handling, database transactions
- **E2E Tests** (15%): Full customer journey (UI → checkout → split payment → confirmation); regression smoke on single-card

### Test Types

| Type | Coverage | Techniques |
| --- | --- | --- |
| **Functional** | Split amount calculation, refund automation, error handling | Decision table (T/F/B/BV for amounts), state transition, workflow testing |
| **Non-functional** | Performance, load (4,000 single-card baseline) | Load test during regression (baseline established); PayGate latency monitoring |
| **Security** | PCI compliance, card data handling | Code review (no card data logging); test that PCI-sensitive data is not exposed in logs/error messages; third-party compliance audit (assumed handled separately) |

### Test Design Techniques

1. **Decision Table** (remainder cent logic):  
   Amount | Split A | Split B | Remainder | Result | Status
   --- | --- | --- | --- | --- | ---
   $100.00 | $50 | $50 | $0 | Both $50 | ✓
   $100.01 | $50 | $50 | $0.01 | A=$50.01, B=$50 | ✓
   $50.99 | $25 | $25 | $0.01 | A=$25.50, B=$25.49 | ✓ (remainder to A)

2. **State Transition Diagram**:  
   - Idle → Charge1Pending → Charge1Done → Charge2Pending → Complete / RefundPending → RefundDone / Declined
   - Tests cover all transitions; test TC-002 covers Charge2Pending → RefundPending → RefundDone path

3. **Boundary Value Analysis**:  
   - Zero amounts, single-cent amounts, max order value, amounts ≤$0.01 (invalid)

### Entry Criteria (When to START System Testing)

- [ ] Feature code merged to Staging branch; build passes compilation and linting
- [ ] Code review completed and approved (>1 reviewer)
- [ ] PayGate test card credentials provisioned and verified in Staging
- [ ] Test data seed script ready and tested (reproducible data state)
- [ ] Test cases (TC-001–TC-007) finalized and reviewed
- [ ] Staging environment deployed and PayGate sandbox connectivity verified
- [ ] All test tools (test runners, mocking frameworks, result tracking) configured

### Exit Criteria (When to STOP Testing & Release)

- [ ] **Release gate**: All 6 gate cases (TC-001, TC-002, TC-003, TC-004, TC-005, TC-006) executed and PASSED
- [ ] **P0 coverage**: 100% of P0 cases executed and PASSED (or documented Product Owner exception)
- [ ] **P1 coverage**: 100% of P1 cases executed and PASSED (or documented Product Owner exception)
- [ ] **Defect severity**: Zero open Critical-severity defects; zero open High-severity defects (or documented exceptions)
- [ ] **Regression**: Single-card checkout regression suite passes 100% on target browsers (Chrome, Firefox, Safari, Edge)
- [ ] **Code coverage**: ≥80% line coverage on split payment service module
- [ ] **Risk register**: All CRITICAL/HIGH risks have confirmed mitigations in place and tested
- [ ] **Sign-off**: QA Lead and Product Owner sign-off on test summary (form: Test Result Sheet, one row per case)

### Release Gate (6 Cases - Minimum Viable Coverage)

| # | Case ID | Description | What It Proves | Target Status |
| --- | --- | --- | --- | --- |
| 1 | TC-001 | Split $100.00 → Card A $60, Card B $40; both succeed | Happy path: split distribution, dual charge success | PASS |
| 2 | TC-002 | Split $100.00 → Card A $60, Card B $40; Card B declined; verify refund within 60s | Refund automation & SLA compliance (critical business rule) | PASS |
| 3 | TC-003 | Split $100.01 → Card A $50.01, Card B $50.00 (remainder to A) | Remainder cent logic correctness (pricing integrity) | PASS |
| 4 | TC-004 | Single-card checkout $100 → Card A $100 (existing flow unchanged) | Backward compatibility; no regression in stable checkout | PASS |
| 5 | TC-005 | Two concurrent split payment requests on same order (race condition test) | State isolation & idempotency under concurrency | PASS |
| 6 | TC-006 | PayGate webhook notifications received for both charges; order state consistent | Webhook handling & final state integrity | PASS |

**Gate Execution Order**: Risk-based (gate cases in order of risk level: TC-002 first [refund SLA], TC-001 [happy path], TC-003 [pricing], TC-005 [concurrency], TC-006 [webhooks], TC-004 [regression] last)  
**Dependency Override**: TC-006 depends on TC-001 or TC-002 webhook data; run TC-001/TC-002 first.  
**Resource Window Override**: TC-002 and TC-006 require real PayGate sandbox; execute on Thu Nov 6 if Tue Nov 4 sandbox is unavailable.

### Full Test Analysis (Beyond Gate)

**Additional P0 Cases** (≈8 cases):
- TC-007: Invalid input handling (negative amount, amount > order total, zero)
- TC-008: Refund retry logic (first refund attempt fails; verify retry succeeds within SLA)
- TC-009: PayGate timeout on second charge (customer experience, error messaging)
- TC-010: Partial refund scenario (refund request API fails; manual intervention process)
- TC-011: Database transaction rollback on payment failure (data consistency)
- TC-012: Card decline reasons (insufficient funds vs. card expired vs. 3D Secure) — each handled identically
- TC-013: Order state machine audit (verify no orphaned states after error)
- TC-014: Single-card checkout performance baseline (≥4,000 orders/day throughput)

**Additional P1 Cases** (≈6 cases, exploratory):
- TC-015: Split payment with discount codes / promotional amounts
- TC-016: Refund processing lag (verify no double-charge during retry window)
- TC-017: PayGate rate limit (verify graceful handling if 2+ concurrent splits hit rate limit)
- TC-018: Mobile device checkout (assumed out-of-scope for 5.3; mark as N/A)
- TC-019: Different currency test (if multi-currency supported; else N/A)
- TC-020: A/B testing flag toggle (feature flag on/off behavior)

**Regression** (≈50 cases, existing suite):
- All existing single-card checkout E2E cases
- Cart-to-confirmation flow
- Payment method selection
- Error recovery flows

### Test Independence & Roles

| Level | Who Tests | Degree | Why |
| --- | --- | --- | --- |
| Unit | Developer (author) | None | Fast feedback loop; safety net before integration |
| Integration | QA + Developer | Some | Dev writes mock tests; QA integrates with real PayGate sandbox |
| E2E | QA | High | Independent of dev; manual and automated; user perspective |
| Regression | QA | High | Third-party validation; no author bias |

### Test Data & Environment Requirements

**Test Data Fixtures** (Staging environment):
- **PayGate Test Cards**: 4 cards provided by PayGate (success, decline, 3DS, low-balance scenarios)
- **Test Orders**: Pre-seeded in database with realistic amounts ($50, $100, $150, $100.01, $50.99)
- **Test Customers**: Dummy customer accounts with confirmed payment methods
- **Cleanup**: Each test execution must leave no orphaned orders; rollback fixture state post-test

**Environment**:
- **Target**: Staging (mirrors production PayGate sandbox config)
- **Browser targets**: Chrome (latest), Firefox (latest), Safari (latest), Edge (latest)
- **Database**: Staging MySQL replica; test data is non-persistent (seeded fresh per test cycle)
- **PayGate Integration**: Sandbox API keys pre-configured; webhook endpoints whitelisted

### Deviations from Standard Policy

**Deviation 1**: Sandbox-only testing constraint forces mock-based primary coverage + real gateway burst testing on tue/thu only.  
**Justification**: External dependency (PayGate sandbox availability) is outside team control; compensate with comprehensive mock-based integration and high-confidence unit test suite.

**Deviation 2**: Single-tester capacity may require deferral of exploratory P3 cases beyond release.  
**Justification**: Gate + P0 + P1 coverage is sufficient for release gate; P3 exploratory findings post-release can be tracked as separate tickets.

**Deviation 3**: Feature flag enabled for rollback; no formal dark-launch canary.  
**Justification**: Low-risk feature (payment split, additive, not invasive); feature flag + monitoring provide adequate rollback control.

### Deliverables

1. **Test Plan** (this document)
2. **Test Case Specifications** (TC-001–TC-020, with preconditions, steps, expected results, defect links)
3. **Test Result Sheet** (signed off by QA Lead and Product Owner; one case per row; build/env version noted)
4. **Risk Register** (updated daily during triage; final version with re-scored risks)
5. **Defect Log** (all defects with severity, root cause, fix status, re-test result)
6. **Configuration Management Log** (testware versions, test data versions, environment configs)

### Metrics to Collect

| Metric | Target | Rationale |
| --- | --- | --- |
| Test case pass rate | ≥95% (gate 100%) | Measure feature quality and readiness for release |
| Defect density | <0.5 per 100 LOC | Baseline quality; flag if exceeded |
| Refund SLA compliance | 100% within 60s | Business-critical SLA; no exceptions |
| Code coverage (split module) | ≥80% line coverage | Confidence in untested code paths |
| Single-card regression pass rate | 100% | Zero regressions in stable feature |
| PayGate API integration latency | <500ms (p95) | Performance baseline; flag if PayGate latency increases |
| Defect retest pass rate | ≥90% | Fix quality; if <90%, request extended QA |

---

## 7. Estimate

### Estimation Technique: Three-Point (Expert Judgment)

Using the formula: **E = (a + 4m + b) / 6**, where a = optimistic, m = most likely, b = pessimistic.

| Task | a (hrs) | m (hrs) | b (hrs) | Estimate (hrs) | Std Dev | Assumptions |
| --- | --- | --- | --- | --- | --- | --- |
| Test design & requirements analysis | 4 | 6 | 10 | 6.3 | 1.0 | Feature brief is clear; no scope creep |
| Unit test development (split logic, retry logic, edge cases) | 8 | 12 | 18 | 12.7 | 1.7 | Dev provides test-friendly code; mocks available |
| Integration test development (PayGate API, webhooks, DB transactions) | 12 | 16 | 24 | 16.7 | 2.0 | Mock PayGate available; testcontainers work first try |
| E2E test development (UI → checkout → payment → confirmation) | 4 | 6 | 10 | 6.3 | 1.0 | Existing E2E framework reused; no new dependencies |
| Test execution & reporting (gate + P0 + P1 cases; 14 cases × 30 min per case) | 6 | 10 | 16 | 10.3 | 1.7 | Sandbox available as scheduled; PayGate responses fast |
| Defect triage & rework cycles (defect discovery, root cause, re-test) | 4 | 8 | 14 | 8.3 | 1.7 | Assume 3–5 defects found; 2–3 require rework |
| Documentation & sign-off (test summary, risk register finalization, release report) | 2 | 3 | 5 | 3.2 | 0.5 | Minimal new docs; existing templates reused |
| **TOTAL** | | | | **63.8 hrs** | **9.6 hrs** | |

### Confidence Range

- **Best case** (a): 34 hours (unlikely; everything works first try)
- **Realistic estimate (E)**: 64 hours (range: 54–74 hours at ±1 SD)
- **Worst case** (b): 97 hours (defects found late; rework extends into week 2)

### Capacity Analysis

**Available Capacity**:
- QA tester: 1.0 FTE × 10 working days × 8 hrs/day = 80 hours total (0.5 FTE allocated to this project = **40 hours**)
- Developer contribution (estimated 10% test effort): 2 devs × 10 working days × 8 hrs/day × 10% = **16 hours**
- **Total available: 56 hours**

**Variance**: Estimate (64 hrs) exceeds capacity (56 hrs) by **~8 hours (14%)**.

### Mitigation Strategy for Capacity Shortfall

1. **Prioritization**: Execute gate cases + P0 cases in week 1 (Tue–Thu windows); defer P1 exploratory to week 2 or post-release tickets
2. **Parallelization**: Test design overlaps with dev build (start designing Thu Oct 28 on feature brief; don't wait for code)
3. **Automation reuse**: Leverage existing checkout E2E framework; write minimal new fixtures
4. **Scope trade-off**: Accept reduced exploratory testing (P3) if time runs short; log findings as "notes for monitoring" post-release
5. **Extended cutover**: If exit criteria not met by Nov 9 EOD, recommend 1-day release delay (Nov 11) for final rework; escalate to Product Owner

### Assumptions Underlying Estimate

- Feature brief is stable (no mid-stream scope changes)
- Dev code is ready by Wed Oct 30; no major refactors during test execution
- PayGate sandbox is available as scheduled (2 windows week 1, 2 windows week 2)
- No parallel production incidents requiring tester context-switch
- Mock PayGate integration is already available (from existing payment infrastructure)
- Test environment (database, deployment pipeline) is stable

---

## 8. Budget and Schedule

### Release Timeline

| Date | Day | Phase | Key Activities | Resources | Sandbox Available |
| --- | --- | --- | --- | --- | --- |
| **Oct 28** | Mon | Kickoff | Test plan finalized; test design starts (mocked PayGate); build kickoff | Dev (2), QA (0.5) | — |
| **Oct 29** | Tue | Dev build + smoke | Dev build handed to QA; unit tests run; smoke test on PayGate sandbox if code ready | Dev (2), QA (0.5) | ✓ Sandbox |
| **Oct 30** | Wed | Integration test build | Integration tests developed against mocked PayGate; PayGate test cards verified | Dev (1), QA (0.5) | — |
| **Oct 31** | Thu | Real PayGate burst | Real PayGate sandbox testing (gate cases TC-001, TC-002, TC-006); webhook verification | QA (0.5) | ✓ Sandbox |
| **Nov 1** | Fri | Defect triage + rework | Defects from Thu testing triaged; dev begins fixes; QA plans rework tests | Dev (2), QA (0.5) | — |
| **Nov 4** | Mon | E2E testing + gate replay | Full E2E suite runs on Staging; gate cases TC-003, TC-004, TC-005 replayed | QA (0.5) | — |
| **Nov 5** | Tue | PayGate burst 2 | Real sandbox: defect rework verification; P0 cases | QA (0.5) | ✓ Sandbox |
| **Nov 6** | Wed | Release gate audit | All 6 gate cases verified PASSED; defect re-test completed; risk register final | QA (0.5), PO (1) | — |
| **Nov 6** | Wed | Go/No-Go review | QA + PO sign-off meeting; release gate approval; rollback plan reviewed | Dev (1), QA (0.5), PO (1) | — |
| **Nov 7–9** | Thu–Fri | Staged rollout prep | Feature flag finalized; monitoring dashboards; support runbook; hotfix cherry-picks ready | Dev (2), Ops (0.5) | — |
| **Nov 10** | Mon | **RELEASE** | Feature flag enabled; monitoring 24/7; support on-call | Ops (1), Support (1) | — |

### Resource Allocation

| Role | Days | Hours/Day | Total Hours | Allocated to Split Payment |
| --- | --- | --- | --- | --- |
| QA Lead | 10 | 4 | 40 | 40 (100%) |
| Developer 1 | 10 | 8 | 80 | 8 (10%) |
| Developer 2 | 10 | 8 | 80 | 8 (10%) |
| Product Owner | 10 | 1 | 10 | 2 (sign-off meetings) |
| DevOps | 10 | 0.5 | 5 | 1 (environment setup) |
| **Total Test Effort** | | | | **56 hours** |

### Sandbox Test Windows (External Constraint)

| Window | Date | Day | Availability | Planned Activity | Backup Plan |
| --- | --- | --- | --- | --- | --- |
| 1 | Oct 29 | Tue | Assumed available | Smoke test (if dev code ready) | Skip; no blocker |
| 2 | Oct 31 | Thu | Assumed available | Gate cases TC-001, TC-002, TC-006 | Retry Nov 4 Tue if outage |
| 3 | Nov 4 | Tue | Assumed available | P0 rework verification | None; escalate to Product Owner |
| 4 | Nov 6 | Thu | Assumed available | Final gate replay + P0 completion | Release decision made on Nov 5 based on mock+previous real tests |

**Contingency**: If sandbox unavailable for 2+ consecutive windows, recommend 2-day release delay to Nov 12 for extended real-gateway testing. Escalate by Nov 5 EOD.

### Budget (Test Only, No Fringe)

| Line Item | Hours | Rate (Assumed) | Cost | Notes |
| --- | --- | --- | --- | --- |
| QA Lead (test execution, triage, sign-off) | 40 | $75/hr | $3,000 | 0.5 FTE × 10 days |
| Developer contribution (unit + integration + rework support) | 16 | $85/hr | $1,360 | 10% of 2 devs, 10 days |
| **Subtotal (Labor)** | 56 | | **$4,360** | |
| PayGate sandbox testing (API calls, webhook ingestion) | — | Included in PayGate SaaS contract | $0 | No overage expected |
| Test environment (Staging DB, server time) | — | Included in Staging cost | $0 | No dedicated infra |
| Test tools & licenses | — | Existing (Jest, Testcontainers, Playwright) | $0 | No new tools |
| **Total Test Budget** | | | **$4,360** | Estimate range: $3,600–$5,200 |

---

## 9. Configuration Management of Testware

### Identification & Version Control

**Repository Path**: `qa/split-payment-release-5.3/`

**Artifacts Tracked**:
```
qa/split-payment-release-5.3/
├── test-plan.md                          (v1.0, dated 2026-10-28)
├── test-cases/
│   ├── tc-001-split-happy-path.md        (v1.0)
│   ├── tc-002-refund-sla.md              (v1.0)
│   ├── tc-003-remainder-cent.md          (v1.0)
│   ├── tc-004-single-card-regression.md  (v1.0)
│   ├── tc-005-concurrent-split.md        (v1.0)
│   ├── tc-006-webhook-handling.md        (v1.0)
│   ├── tc-007-tc-020-additional.md       (v1.0)
├── test-data/
│   ├── paygate-test-cards.sql            (v1.0, confidential; credentials in vault)
│   ├── test-orders-seed.sql              (v1.0)
│   └── fixture-state-schema.md           (v1.0, describes fixture preconditions & cleanup)
├── test-scripts/
│   ├── run-gate.sh                       (v1.0, executes 6 gate cases)
│   ├── run-regression.sh                 (v1.0, executes single-card checkout suite)
│   └── paygate-mock-server.js            (v1.0, Testcontainers mock)
├── results/
│   ├── 2026-10-29-smoke-test.md          (timestamped, build tag attached)
│   ├── 2026-10-31-gate-real-paygate.md   (timestamped, sandbox config noted)
│   ├── 2026-11-06-final-gate.md          (timestamped, final result sheet)
│   └── defect-log.md                     (v1.0, defect ID, severity, retest status)
├── risk-register-updates.md              (dated entries: 2026-10-28, 2026-10-31, 2026-11-05, 2026-11-06)
└── README.md                             (index of all above; how to run tests; resume point if testing interrupted)
```

### Versioning Scheme

- **Test Plan**: `v1.0` (2026-10-28 initial); `v1.1+` for corrections (dated; no deletion, append corrections)
- **Test Cases**: `v1.0` (baseline at Oct 28); `v1.1+` if requirements change (rare mid-sprint)
- **Test Scripts**: Git commit hash + tag (e.g., `run-gate.sh@a3f7d9e`)
- **Test Results**: Timestamped filename + attached build/environment version (e.g., `2026-11-06-final-gate.md — build 5.3.0-rc2, Staging`)
- **Defect Log**: Ticket IDs (JIRA/ADO); linked to test case ID and result sheet line number

### References by Identifier & Version

All test result sheets, defect reports, and risk updates reference testware by identifier and version:

- Example: "TC-001 v1.0 executed on 2026-10-31, PayGate sandbox, result: PASS (build 5.3.0-rc2)"
- Example: "Defect D-0042 (CRITICAL) found in TC-002 v1.0 re-test 2026-11-05, fix verified by TC-002 v1.0 2026-11-06"

### Baselined Environments

**Staging Environment Baseline** (frozen at release date):
- **Database**: SQL Server version X, schema version Y (seed data locked to test-orders-seed.sql v1.0)
- **PayGate Integration**: Sandbox API keys `paygate-staging-key-v1.0`, webhook signing secret committed to (encrypted) config
- **Browser drivers**: Chrome v123, Firefox v120, Safari v17, Edge v123 (pinned in `package.json`)
- **Test framework versions**: Jest v29.7, Testcontainers v3.1, Playwright v1.40 (locked in `package-lock.json`)

### Restorable Baselines

**Restore Procedure** (if Staging drifts):
1. Checkout commit `5.3.0-release-gate` from main branch (tagged in git)
2. Run `./qa/split-payment-release-5.3/test-data/reset-staging.sh` (idempotent; drops test data, re-seeds, checks PayGate connectivity)
3. Deploy Staging: `./deploy.sh staging --build 5.3.0-rc2` (ensures correct service version)
4. Verify: Run smoke test (first 2 gate cases) to confirm environment is ready

### Configuration Management in CI/CD

- **Pre-merge**: Unit + integration tests run in CI (mock PayGate); must pass before code review
- **Pre-deployment to Staging**: Regression suite runs in CI (mocked); must pass before Staging deployment
- **Post-deployment to Staging**: QA manually triggers gate execution against real PayGate (sandbox) via runbook
- **Pre-release**: Gate result sheet signed off; defect log reviewed; risk register finalized; release decision made in Jira/ADO workflow

### Artifacts Ownership & Handover

| Artifact | Owner | Handover Trigger | Recipient |
| --- | --- | --- | --- |
| Test Plan | QA Lead | Day 1 (Oct 28) | Dev, PO, Support |
| Test Cases | QA Lead | Day 2 (Oct 29) | Dev (code review reference) |
| Test Results | QA Lead | Daily (Oct 29–Nov 6) | Dev (for defect triage), PO (for status) |
| Defect Log | QA Lead | Daily during defect triage | Dev (for fix assignment), Support (for cutover prep) |
| Risk Register | QA Lead | Daily re-assessment | Stakeholders (risk awareness) |
| Release Gate Sign-Off | QA Lead + PO | Nov 6 EOD | Release Management (for go/no-go decision) |

### Resume Point (If Testing Interrupted)

If QA tester becomes unavailable mid-sprint:

1. **Handover artifact**: `qa/split-payment-release-5.3/README.md` lists all completed and pending work
2. **Test Results Sheet**: Latest result sheet shows which cases are PASSED, which are IN PROGRESS (resumable), which are NOT RUN
3. **Defect Log**: All open defects assigned; known root causes; steps to re-test
4. **Risk Register**: Current scores and mitigations; which risks are actively being tested
5. **Runbook**: `qa/split-payment-release-5.3/run-gate.sh` can be executed by a developer with test knowledge; results are recorded in standard format

**Example Resume Scenario** (if tester falls ill Nov 4):
- Completed: TC-001, TC-002, TC-003, TC-006 (gate cases); 3 defects found and assigned to Dev
- In Progress: TC-004, TC-005 (regression & concurrency); Dev can run the scripts and report results
- Not Run: TC-007–TC-020 (P0/P1 cases); deferred to Nov 7 or post-release ticket
- Handover: Dev Lead takes test script (`run-gate.sh`, `run-regression.sh`); QA documents findings in result sheet; QA+PO decide go/no-go based on completed gate + highest-risk cases

---

## Summary

This test plan prioritizes the split payment feature's critical business rule (refund SLA) and backward compatibility (single-card checkout) through a risk-based approach. The 6-case release gate and extended P0/P1 analysis provide confidence within a constrained testing window (PayGate sandbox tue/thu only). The 64-hour estimate exceeds available capacity (56 hours) by 14%; mitigation relies on parallelized design, scope prioritization, and contingency re-baseline on Nov 11 if needed. QA sign-off is the release gate, with daily risk monitoring and defect triage informing go/no-go decisions through Nov 10.
