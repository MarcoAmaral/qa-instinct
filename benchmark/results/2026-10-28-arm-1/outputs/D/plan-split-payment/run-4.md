# Test Plan: Split Payment Feature (Release 5.3)

## 1. Context of Testing

### Scope
- **Feature**: Split Payment functionality enabling customers to pay a single order with two cards
- **In Scope**: Split amount selection (UI), amount calculation logic (backend), dual-charge orchestration (PayGate integration), automatic refund workflow (on second-charge decline), data persistence and reconciliation
- **Out of Scope**: Single-card payment flow (regression testing only, not new feature testing); PayGate infrastructure or sandboxing; fraud detection; subscription/recurring payments; loyalty or discount logic

### Objectives
1. Verify split payment calculation is mathematically correct, especially rounding (remainder cent to first card)
2. Verify both charges execute in correct sequence through PayGate
3. Verify automatic refund triggers and completes within 60 seconds if second charge declines
4. Verify existing single-card payment flow remains unbroken (4,000 orders/day baseline)
5. Verify system remains performant under normal load during split payment transactions
6. Identify security, data-integrity, or integration defects before release

### Test Basis
- Feature requirements document (split payment functional spec)
- PayGate API documentation (charge and refund endpoints)
- Existing single-card payment specification
- Payment PCI/security standards (as applicable)

---

## 2. Assumptions and Constraints

| Assumption | Rationale |
|-----------|-----------|
| PayGate mock API is complete and available by day 2 of testing; sandbox is accessible Tuesdays and Thursdays only as stated | Required to parallelize test execution without blocking on sandbox availability |
| Split payment feature is built in the backend (API) and frontend (checkout form); both are merged to the release branch by day 5 | Drives test schedule and phasing |
| Automatic refund is triggered via a separate PayGate refund API call, not a native "split charge" reversal | Affects test design for refund verification |
| Development team has capacity to fix defects within 24 hours during the test window | Enables re-test cycles before release |
| Production PayGate account and sandbox credentials are configured in staging environment | Required for sandbox testing on Tues/Thu |
| Test data can be seeded into dev/staging without PayGate; production test cards are available | Allows mock-based testing before integration |
| Single-card payment code path is isolated from split-payment changes (no shared refactoring) | Reduces regression scope and risk |
| PO and stakeholders accept testing and release proceeding based on release-gate cases + sandbox verification | Defines exit criteria |
| No major PayGate downtime or service issues during the 10-day window | Outside team's control; monitoring plan in place to detect early |

| Constraint | Impact |
|-----------|--------|
| One QA tester @ 50% allocation (4 hrs/day for 10 days) | ~40 hours available; prioritizes test design and release-gate execution over exhaustive edge-case testing |
| PayGate sandbox open only Tuesdays and Thursdays | 4 sandbox windows (10/29, 11/4, 11/6, 11/11); integration testing must batch into these slots; mock testing runs on other days |
| Release date: 10 working days from 2026-10-28 → 2026-11-11 | Tight timeline; no extension buffer; dev work must complete by day 5 to allow 5 days for test execution and sign-off |
| Existing single-card payment handles ~4,000 orders/day | System must remain stable; regression testing is smoke-level, not exhaustive |

---

## 3. Stakeholders

| Role | Person/Team | Responsibility | Involvement |
|------|-------------|-----------------|-------------|
| **Product Owner** | [PO Name] | Define acceptance criteria, approve feature, sign off on test results and release risk | Weekly status, gate approval, final sign-off |
| **Development Team** | 2 engineers | Implement feature, fix defects, provide PayGate mock, support environment setup | Daily standup, defect triage, code review of test feedback |
| **QA / Test Lead** | 1 tester @ 50% | Write test cases, execute tests, log defects, track metrics, report progress | Daily execution, results reporting, gate verification |
| **DevOps / Platform** | [Platform team] | Provide dev/staging environments, manage PayGate credentials, seed test data | Setup (day 1–2), on-call for environment issues |
| **Payment Systems Owner** | [Payment team] | Advise on PayGate integration, refund orchestration, compliance | Available for consultation, review integration test results |

---

## 4. Communication

| Communication | Frequency | Format | Attendees |
|---------------|-----------|--------|-----------|
| Daily Standup | Every morning (async) | Slack thread or brief call | Dev (2), QA (1), PO (optional) |
| Defect Triage | 2x per week (Mon/Wed) | Ticket review + Slack | Dev lead (1), QA (1), PO (optional) |
| Weekly Status | End of week (Fri) | Email + chart (cases run/passed/failed/blocked) | PO, Dev lead, QA, Platform |
| Blockers / Escalation | As needed | Slack immediate + email summary | PO, Dev lead, QA |
| Test Completion / Sign-off | Day 10 (release eve) | Formal sign-off document (email + ticket comment) | PO, QA lead, Dev lead |

**Document Templates**: Test cases stored in Jira/ADO with format `[TC-NNN]: Title | Expected Result | Actual Result | Pass/Fail/Blocked | Notes | Build Hash | Env Version`

---

## 5. Risk Register (5×5 Product & Project Risk Matrix)

### Risk Scoring Guidance
- **Likelihood (L)**: 1 = Remote, 2 = Low, 3 = Medium, 4 = High, 5 = Very High
- **Impact (I)**: 1 = Trivial, 2 = Minor, 3 = Moderate, 4 = Major, 5 = Critical
- **Score = L × I**: 15–25 = 🔴 CRITICAL | 8–14 = 🟠 HIGH | 4–7 = 🟡 MEDIUM | 1–3 = 🟢 LOW

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner | Status |
|---|----|--------------------|----------|---|---|-------|--------|---------------------|-------|--------|
| 1 | R01 | Split amount calculation incorrect (wrong card debits, remainder logic fails) | Product | 3 | 5 | **15** | 🔴 CRITICAL | Unit test every split scenario (100, 101, 1000, 10001 cents); boundary value analysis; manual review of calculation logic before day 3 | Dev/QA | Active |
| 2 | R02 | Refund does not trigger or exceeds 60-second window when second charge declines | Product | 2 | 5 | **10** | 🟠 HIGH | Implement refund timer with explicit logging; mock PayGate refund API to return configurable latencies; E2E test with 3-second, 30-second, 59-second delays; code review of refund state machine | Dev/QA | Active |
| 3 | R03 | Single-card payment broken by split-payment changes (regression failure affecting 4,000/day baseline) | Product | 2 | 5 | **10** | 🟠 HIGH | Isolate split logic to new code path; run existing single-card payment unit + E2E smoke tests before and after merge; mock PayGate and execute happy-path single-card flow as part of release gate | QA/Dev | Active |
| 4 | R04 | Race condition: both charges decline, both succeed, or only first charges when network splits | Product | 2 | 4 | **8** | 🟠 HIGH | Implement idempotency keys per charge; design state machine to handle all outcomes (first-only, both, second-only); mock PayGate timeout scenarios; integration test with artificial latency/failures | Dev/QA | Active |
| 5 | R05 | Rounding or remainder-cent logic assigns wrong amount to first or second card | Product | 3 | 3 | **9** | 🟠 HIGH | Decision table: test splits of 100, 101, 1000, 10001, 123456 cents; verify each cent is assigned exactly once and total equals original amount; automate in unit tests | QA/Dev | Active |
| 6 | R06 | UI allows invalid split amounts (negative, zero, exceeds total, non-integer) | Product | 3 | 3 | **9** | 🟠 HIGH | Equivalence partitioning: valid (1–total-1), boundary (0, 1, total, total+1), invalid (negative, decimal, string); input validation automation in UI + backend | Dev/QA | Active |
| 7 | R07 | PayGate integration error (wrong endpoint, missing fields, auth failure) on first or second charge | Product | 2 | 4 | **8** | 🟠 HIGH | Integration test with PayGate mock covering: both charges succeed, first succeeds/second declines, both decline; verify request payload (amount, card, idempotency key); sandbox testing Tues/Thu for real PayGate | QA/Dev | Active |
| 8 | R08 | Payment data not persisted or reconciliation fails (charges recorded in DB but refund not logged) | Product | 2 | 4 | **8** | 🟠 HIGH | Verify order record contains both charge IDs and refund ID; query DB to confirm state transitions; reconciliation query after each test scenario | QA/Dev | Active |
| 9 | R09 | Sensitive payment data (card tokens, amounts, refund status) logged or exposed in error messages | Product | 1 | 5 | **5** | 🟡 MEDIUM | Scan logs for PII; verify error messages do not expose card details or amounts; security code review of logging statements | Dev | Active |
| 10 | R10 | Performance degradation: split-payment flow adds latency to checkout (impacts 4,000/day throughput) | Product | 2 | 3 | **6** | 🟡 MEDIUM | Baseline single-card checkout latency (e.g., 500ms); measure split-payment latency (should be ≤ 800ms, one extra API call); load test 50 concurrent split transactions | QA/Dev | Active |
| 11 | PR01 | PayGate sandbox unavailable or down during testing window (Tues/Thu only) | Project | 2 | 4 | **8** | 🟠 HIGH | Proceed with mock-based testing Mon–Fri; batch sandbox tests into 2-hour windows on 10/29, 11/4, 11/6, 11/11; contact PayGate support if unexpected downtime; fallback: defer sandbox tests if unavailable | QA/Platform | Active |
| 12 | PR02 | Development not ready for testing by day 5; code merged with compilation errors or incomplete payGate mock | Project | 2 | 4 | **8** | 🟠 HIGH | Daily standup tracking dev progress; code review before merge to release branch; PayGate mock acceptance criteria defined by day 2; escalate blockers immediately | Dev Lead | Active |
| 13 | PR03 | Defects found late (day 8–10) requiring rework; one QA tester @ 50% insufficient to re-test in time | Project | 3 | 3 | **9** | 🟠 HIGH | Release-gate approach: test critical paths early (day 4–5); prioritize defects by severity; devs fix in parallel with QA testing day 6–7; retest must complete by day 9 | QA/Dev Lead | Active |
| 14 | PR04 | Refund API endpoint not available or documented late; delays integration test design | Project | 2 | 3 | **6** | 🟡 MEDIUM | Confirm refund API spec by end of day 1; mock it if not ready; design integration test cases day 2–3 independent of API availability; integration testing unblocked by day 4 | Payment Owner/Dev | Active |
| 15 | PR05 | Test data setup incomplete; PayGate mock does not support all scenarios (e.g., timeout, partial decline) | Project | 2 | 3 | **6** | 🟡 MEDIUM | Fixture document by day 2: test accounts, card numbers, decline triggers; mock API behavior checklist (success, decline, timeout); validate with dev by day 3 | QA/Dev | Active |

### Risk Monitoring & Control
- **Weekly Review**: Every Friday, re-score active risks and note any changes in likelihood or impact
- **Escalation**: CRITICAL or HIGH risks escalated to PO if mitigation not on track
- **Control Action**: If a risk score increases or new defects indicate overlooked risk, update register with date and revised score
- **Completed Mitigation**: Mark risk as "Mitigated" when testing confirms defect not present; mark "Accepted" if risk accepted by PO despite testing

---

## 6. Test Approach

### 6.1 Test Levels and Distribution (Adaptive Pyramid)

This feature is **full-stack** (backend logic + frontend form + external API integration). Test distribution:

- **40% Unit Tests** (calculation, validation, state logic) → Developers + QA
- **40% Integration Tests** (PayGate mock, refund orchestration, data persistence) → QA + Developers  
- **20% E2E Tests** (full checkout flow in browser) → QA

### 6.2 Test Types and Techniques

| Test Type | Technique | Example Cases | Ownership |
|-----------|-----------|----------------|-----------|
| **Functional** | Boundary Value Analysis, Equivalence Partitioning, Decision Tables | TC-001: Split 100¢ (50/50); TC-002: Split 101¢ (51/50); TC-005: Split 10000¢ (9999/1) | QA |
| **Calculation / Business Logic** | Equivalence + State Transition | TC-003: Remainder cent always to first card; TC-004: Both splits sum to original amount | Dev/QA |
| **Integration** | State Transition, Error Guessing | TC-006: First succeeds/second declines; TC-007: Both succeed; TC-008: Both decline; TC-009: Timeout on second charge | QA |
| **Refund Workflow** | State Transition + Timing | TC-010: Refund triggers within 2 seconds; TC-011: Refund triggers within 60 seconds; TC-012: Refund completes successfully | QA |
| **Validation / Input** | Equivalence Partitioning, Boundary Values | TC-013: Negative amount rejected; TC-014: Zero rejected; TC-015: Amount > total rejected | QA |
| **Regression (Single-Card)** | Happy-Path Smoke Test | TC-016: Single-card payment succeeds (existing flow); TC-017: Single-card decline handled | QA |
| **Performance** | Load Testing (light) | TC-018: 50 concurrent split transactions complete in < 5 min; no timeout/error spike | QA |
| **Data Integrity** | Query Validation | TC-019: Order record contains both charge IDs; TC-020: Refund ID linked to declined charge | QA/DB |

### 6.3 Test Levels, Independence & Deliverables

| Level | Test Focus | Execution Environment | Independence | Deliverables |
|-------|-----------|----------------------|--------------|--------------|
| **Unit** | Amount calculation, input validation, state transitions | Dev local + CI pipeline | Dev (author+peer review) | Unit test suite in code repo; pass/fail per build |
| **Integration** | PayGate API calls (mock), charge/refund sequences, DB persistence | Staging with mock PayGate | QA (independent of dev) | Test cases (TC-006 to TC-012); test results with build hash + mock version |
| **System / E2E** | Full checkout flow (UI → backend → PayGate mock) | Staging + PayGate sandbox (Tues/Thu) | QA (high independence) | E2E test cases (TC-016 to TC-020); recorded results with screenshots/logs; sandbox results on real PayGate |
| **Regression** | Single-card payment (existing flow) | Staging | QA (high independence) | Smoke-test suite (TC-016, TC-017); pass/fail matrix |

### 6.4 Entry Criteria for System-Level Test Execution (When to START Testing)

- [ ] Feature code is fully implemented and merged to release branch
- [ ] Build succeeds with zero compilation/linting errors
- [ ] Staging environment is deployed and accessible
- [ ] PayGate mock API is available and documented (at least: success, decline, timeout responses)
- [ ] Test data fixtures are seeded (test accounts, card numbers, test orders)
- [ ] Single-card payment smoke tests pass (regression baseline)
- [ ] QA has write access to test results tracker and has received credentials for staging

### 6.5 Exit Criteria (When to STOP Testing & Release)

- [ ] Every release-gate case (TC-001 through TC-006, see § 6.7 below) executed and passing
- [ ] Zero open CRITICAL-severity defects; all CRITICAL defects resolved and re-tested
- [ ] Zero open HIGH-severity defects on the critical path (R01–R08), or each HIGH defect has a recorded PO exception + rollback plan
- [ ] Single-card regression smoke tests (TC-016, TC-017) pass 100%
- [ ] Refund automation verified on PayGate sandbox (Tues 11/11)
- [ ] Test results signed off by QA Lead and Product Owner (sign-off document in Jira)
- [ ] No new defects discovered on final sanity check (day 9 evening)

### 6.6 Release Gate: Smallest Viable Proof (5–8 Cases)

The release gate is the minimal set of cases that must pass to declare the feature ready. It answers: *Do the fixes work?* and *Did the change break anything that already worked?*

**Release Gate Test Cases:**

| TC ID | Title | What It Proves | Acceptance | Pass/Fail | Build | Env | Notes |
|-------|-------|----------------|-----------|-----------|-------|-----|-------|
| TC-001 | Split 100¢ evenly (50/50) into two cards; both succeed | Core split logic + both charges succeed | Both cards charged 50¢; total 100¢; order state is "paid" | ⬜ | [commit] | mock | Happy path |
| TC-002 | Split 101¢ (51 first, 50 second); both succeed | Remainder-cent logic: extra cent goes to first card | First card 51¢, second 50¢; total 101¢; order state is "paid" | ⬜ | [commit] | mock | Rounding rule validated |
| TC-003 | Split 1000¢ (700 first, 300 second); second card **declines**; refund triggers | Refund automation on second-charge decline | First charge reversed in < 60 sec; order state is "failed"; refund logged in DB | ⬜ | [commit] | mock | Refund latency tracked |
| TC-004 | Invalid input: split amount = 0 or negative | Input validation rejects invalid splits | Error message displayed; no charges attempted; order remains "pending" | ⬜ | [commit] | mock | Data integrity |
| TC-005 | Invalid input: split amount > total order amount | Input validation rejects overage | Error message displayed; no charges; order remains "pending" | ⬜ | [commit] | mock | Boundary case |
| TC-006 | Single-card payment flow (existing) on same staging env | Regression: no regression in baseline payment flow | Card charged correct amount; order state is "paid"; same latency as pre-split baseline | ⬜ | [commit] | mock | Backward compat proof |

**Gate Verdict**: ✅ **RELEASE APPROVED** if all 6 cases pass + zero CRITICAL defects + PO sign-off. ❌ **HOLD RELEASE** if any gate case fails or CRITICAL defect remains open.

### 6.7 Test Data & Environment Requirements

**Test Data Fixtures (Seeded Before Testing):**

| Fixture ID | Description | State | Usage | Can Modify? |
|------------|-------------|-------|-------|------------|
| ORD-001 | Order: 100¢ total, no prior charges | "pending" | TC-001, TC-016 | Yes, reset after each test |
| ORD-002 | Order: 101¢ total, no prior charges | "pending" | TC-002, TC-003 | Yes, reset after each test |
| ORD-003 | Order: 10000¢ total, no prior charges | "pending" | Performance tests | Yes, reset after each test |
| CARD-VALID | Test card, always succeeds in mock | Valid in mock | All tests | No (read-only) |
| CARD-DECLINE | Test card, declines on second call in mock | Configured in mock | TC-003, TC-008 | No; config in mock API |
| CARD-TIMEOUT | Test card, times out after 5 sec in mock | Configured in mock | Timeout scenarios | No; config in mock API |

**Environment Configuration:**

| Environment | Purpose | PayGate Mock? | Real PayGate? | Access | Notes |
|-------------|---------|---------------|---------------|--------|-------|
| **Dev (Local)** | Unit test execution | N/A (mocked in code) | No | Developer machines | Fast feedback; no network calls |
| **Staging** | Integration & E2E tests (days 3–9) | Yes, configurable responses | No (most days) | QA + Devs; CI/CD pipeline | Mirrors prod schema; persistent test data |
| **Sandbox** | Real PayGate integration tests (Tues 10/29, 11/4, 11/6, 11/11) | No | Yes, PayGate sandbox | QA + Payment Owner | Limited windows; test cards provided by PayGate |

**Environment Sign-Off Checklist (Day 1–2):**
- [ ] Staging DB initialized with test fixtures
- [ ] PayGate mock API running and responding correctly (success, decline, timeout endpoints)
- [ ] PayGate sandbox credentials configured in staging deploy
- [ ] CI pipeline passing on release branch
- [ ] QA can execute test scripts and view logs
- [ ] Payment system logs are accessible (audit refund calls)

### 6.8 Metrics to Collect & Monitor

| Metric | Target | Collection | Reporting | Decision Gate |
|--------|--------|-----------|-----------|----------------|
| **Test Progress** | 100% gate cases executed by day 7; 100% analysis cases by day 9 | Case-by-case status in Jira | Daily standup + weekly chart | Hold release if < 100% gate by day 7 |
| **Defect Escape Rate** | < 1 defect per 1,000 cases executed (CRITICAL = 0) | Count failures re-tested and passed | Completion report | Release blocked if any CRITICAL remains |
| **Defect Closure Rate** | 100% CRITICAL/HIGH resolved by day 9 | Time from logged to closed | Triage dashboard | Escalate if HIGH open > 24h |
| **Regression Pass Rate** | 100% single-card smoke tests pass | TC-016, TC-017 results | Before release gate, after release gate | Do not release if < 100% |
| **Coverage** | 100% of 6 gate cases; ≥ 80% of analysis cases | Case execution tracker | Weekly | Adjust design scope if falling behind |
| **Refund Latency** | Mean < 10 sec, 100th percentile < 60 sec | Timestamp refund logged − timestamp decline recorded | Acceptance test results + sandbox run | Defect if any refund > 60 sec |
| **PayGate Mock Uptime** | 100% during testing days | Polling mock availability | Incident log | Escalate to dev if downtime > 30 min |

### 6.9 Deviations from Testing Policy

**Deviation 1: Sandbox-Only Testing Window**
- *Policy Expectation*: Full integration testing on real external APIs throughout the cycle.
- *Reality*: PayGate sandbox open only Tues/Thu (4 days out of 10); would delay release if sandbox were the only testing venue.
- *Deviation*: Mock-based testing days 3–9; real sandbox verification on final gate execution (day 7, sandbox open Tues 11/4) and release validation (day 10, sandbox open Tues 11/11).
- *Rationale*: Allows parallel testing while respecting PayGate's availability constraints; mock API closely mirrors real behavior (configured by Payment Owner); defects in mock-real Delta caught day 11–12 if needed.
- *Mitigation*: Sandbox test cases (TC-006 in gate) are mandatory; payment team on standby for sandbox issues.

**Deviation 2: Light Regression Testing**
- *Policy Expectation*: Full regression test suite for single-card payment to ensure no regressions.
- *Reality*: Single-card payment is high-volume (4,000/day); exhaustive regression would exceed 0.5 QA @ 50% time budget.
- *Deviation*: Smoke-level regression only: TC-016 (normal charge), TC-017 (decline). Existing unit tests (built by dev) cover edge cases.
- *Rationale*: Split-payment code path is isolated (new files/new conditional); risk of regression to single-card is Low (R03 score = 10, HIGH but mitigated by code isolation + prior unit test suite).
- *Mitigation*: Confirmation: devs certify code path isolation by code review day 2; existing single-card unit tests pass on release branch (CI gate).

---

## 7. Estimate (Effort & Resource Allocation)

### 7.1 Estimation Technique: Three-Point Estimation

**Formula**: E (Expected) = (a + 4m + b) / 6; SD (Standard Deviation) = (b − a) / 6

**Parameters:**
- **a (Optimistic)**: Code ready day 4, no major defects, all tests pass on first run → 2.5 FTE days
- **m (Most Likely)**: Code ready day 5, 1–2 defect cycles, sandbox validation on day 7–8 → 4 FTE days
- **b (Pessimistic)**: Code ready day 6, 3+ defect cycles, sandbox unavailable one day, defects in refund logic → 5 FTE days

**Calculation:**
- E = (2.5 + 4×4 + 5) / 6 = (2.5 + 16 + 5) / 6 = 23.5 / 6 ≈ **3.9 FTE days**
- SD = (5 − 2.5) / 6 = 2.5 / 6 ≈ **0.42 days**
- **Range: 3.5 to 4.3 FTE days (68% confidence)**

### 7.2 Translation to Calendar Time

- **1 QA tester @ 50% allocation** = 4 hours available per business day
- **3.9 FTE days** = 3.9 × 8 hrs = 31.2 hours QA labor
- **Allocated time: 10 working days × 4 hrs = 40 hours** → Sufficient with 8.8 hours buffer (22% margin)

**Breakdown by Activity:**

| Activity | Effort (FTE hrs) | Dates | Notes |
|----------|-----------------|-------|-------|
| Test design + case writing (days 1–2) | 6–8 | Wed 10/28 – Thu 10/29 | Parallel with dev setup; review requirements, PayGate mock spec |
| Environment setup + fixtures (days 1–3) | 2–3 | Wed 10/28 – Fri 10/30 | Validate staging, seed test data, mock API ready |
| Test execution on mock (days 4–7) | 12–14 | Mon 11/2 – Thu 11/6 | TC-001 to TC-015; defect logging; daily status |
| Defect triage + re-test (days 6–8) | 4–6 | Wed 11/5 – Fri 11/7 | 2x per-week triage; retest fixed defects |
| Sandbox verification (days 5 & 7) | 2–3 | Tues 11/4, Thu 11/6 | Real PayGate testing; sandbox windows only |
| Regression + gate final run (day 9–10) | 2–4 | Fri 11/7 – Tue 11/11 | TC-016, TC-017, gate retest; sign-off prep |
| **Contingency (buffer)** | **~8** | **As needed** | Defect rework, environment issues, schedule slip |
| **Total** | **~40 hours** | **10 working days** | @ 50% = 20 hrs/week available; 10 days = 40 hrs |

### 7.3 Assumptions Behind Estimate

1. **Code incremental delivery**: Split-payment code delivered in phases (days 3, 4, 5); QA starts testing day 4 on what's ready; no waiting for 100% completion.
2. **PayGate mock ready by day 2**: Developers provide mock API (or spec) by end of day 2; no delays integrating mock responses.
3. **Defect fix latency < 24h**: Developers fix reported defects same day or next morning; re-test not delayed by long fix cycles.
4. **Test case density**: ~20–25 test cases total (gate + analysis); ~30 min per case execution (dev/mock + validation); 15 min per case re-test after fix.
5. **No major PayGate sandbox downtime**: Sandbox available as scheduled (Tues/Thu); if unavailable, analysis cases delay but gate cases proceed on mock.
6. **Single tester competence**: QA tester is experienced in payment flows, PayGate, SQL, and Jira; no ramp-up time.
7. **No scope creep**: Feature scope locked; no new requirements during the 10-day cycle.

### 7.4 Resource Allocation

| Role | Time | Responsibility |
|------|------|-----------------|
| **QA Tester** | 50% (4 hrs/day for 10 days, 40 hrs total) | Test design, case execution, defect logging, progress reporting, release sign-off |
| **Dev 1** | 20% (2 hrs/day) | Build split-payment feature; provide/support PayGate mock; fix defects; code review of test findings |
| **Dev 2** | 20% (2 hrs/day) | Build refund automation; support integration tests; troubleshoot PayGate mock issues |
| **Dev Lead** | 10% (1 hr/day) | Defect triage, release readiness review, escalations |
| **Product Owner** | 5% (0.5 hrs/day) | Requirements clarification, gate approval, risk acceptance sign-offs |
| **Payment Systems Owner** | 5% (0.5 hrs/day) | PayGate integration advisory, sandbox credential management, incident response |
| **DevOps / Platform** | 5% (0.5 hrs/day) | Environment setup, test data seeding, incident response, credentials |

**Total Team Effort**: ~11.5 FTE days (0.5 tester × 10 + 0.2 dev × 10 × 2 + 0.1 lead × 10 + 0.05 × 10 × 4) ≈ **92 person-hours for the 10-day release cycle**

---

## 8. Budget & Schedule

### 8.1 Timeline (Release Candidate Delivery: Tues 2026-11-11)

| Phase | Dates | Milestone | Key Activities | Dependencies |
|-------|-------|-----------|-----------------|---------------|
| **Phase 1: Setup** | Wed–Thu 10/28–10/29 | QA ready; mock API spec confirmed | Test case outline draft; env setup start; dev begins feature build | Reqs locked |
| **Phase 2: Development + Early Test** | Fri–Mon 10/30–11/2 | Feature 70% complete; mock API available; first test cycles pass | Dev delivers split logic; QA executes unit & integration cases (mock-based); defect 1st wave | Feature code flow stable |
| **Phase 3: Integration + Sandbox Window 1** | Tues–Wed 11/4–11/5 | Gate cases 50% complete; sandbox available Tues 11/4; first-pass defects resolved | Sandbox test (real PayGate); TC-001–TC-006 execute 1st time; defect triage; rework begins | Sandbox access granted |
| **Phase 4: Regression + Defect Rework** | Thu–Fri 11/6–11/7 | Single-card regression 100% pass; sandbox available Thu 11/6; rework + retest | Gate re-execute; defect cycle 2–3; regression smoke (TC-016, TC-017) pass; final sandbox validation | Defects resolved < 24h |
| **Phase 5: Release Validation** | Mon–Tue 11/10–11/11 | Gate 100% pass; zero CRITICAL defects; sign-off complete | Final sanity check; sandbox gate re-run (sandbox open Tues 11/11); sign-off document; release GO/NO-GO call | All exit criteria met |

### 8.2 Resource Schedule (Gantt-Style)

```
Wed 10/28 ├─ QA Design + Plan
          ├─ Dev: Feature build start
Thu 10/29 ├─ QA: Env setup + fixtures
          ├─ Dev: Feature build (60%)
          └─ Sandbox window 1 (Thu): prep test accounts
Fri 10/30 ├─ QA: Case finalize + build first test suite
          ├─ Dev: Feature build (80%) + mock API spec
Mon 11/2  ├─ QA: Execute test cases (mock)
          ├─ Dev: Feature build complete (100%); code review; merge
Tues 11/4 ├─ QA: Sandbox test TC-001–TC-006 (SANDBOX WINDOW 1)
          ├─ Dev: Defect triage + fix cycle 1
          └─ Defect re-test (QA + Dev)
Wed 11/5  ├─ QA: Defect re-test; regression smoke test (TC-016, TC-017)
          ├─ Dev: Defect fixes continue
Thu 11/6  ├─ QA: Sandbox test re-run (SANDBOX WINDOW 2)
          ├─ Dev: Defect cycle 2 fix + merge
Fri 11/7  ├─ QA: Analysis cases (non-gate); final regression; prepare sign-off
          ├─ Dev: Defect rework final pass
Mon 11/10 ├─ QA: Sanity check; release readiness review
          ├─ Dev: Standby for last-minute issues
Tues 11/11 ├─ QA: Sandbox gate re-run (SANDBOX WINDOW 3)
          ├─ PO: Final approval
          └─ Release: SHIP or HOLD decision
```

### 8.3 Critical Path & Parallel Work

**Critical Path (dates cannot slip without delaying release):**
1. **Dev feature completion by day 5 (Mon 11/2)** → QA cannot test without code
2. **Mock API spec day 2 (end of Thu 10/29)** → Blocks QA test design day 3
3. **First test execution day 4 (Mon 11/2)** → Must start before day 5 to surface defects in time
4. **Sandbox validation by day 7 (Thu 11/6)** → Final confirmation on real PayGate before release

**Parallel Work** (can overlap, not on critical path):
- QA case design (day 1–2) parallels dev feature build
- Environment setup (day 1–3) parallels dev build
- Defect triage (day 5+) parallels ongoing dev fixes

**Slack / Flexibility:**
- Analysis cases (TC-007 to TC-020) are *not* on critical path; if time tight, defer to regression testing post-release
- Performance testing (load test) is optional if gate + regression pass; moved to day 9–10 only if time available

### 8.4 Budget Summary

| Category | Allocation | Rate / Cost | Notes |
|----------|-----------|-------------|-------|
| **QA Tester** | 40 hrs @ 50% | $X/hr | Full effort on split payment; no context switching |
| **Dev Labor** | ~40 hrs @ 20% + triage | $X/hr | Feature build (primary) + support (secondary) |
| **DevOps** | ~5 hrs | $X/hr | Env setup, credential management, incident response |
| **Mgmt / Triage** | ~10 hrs | $X/hr | PO, Dev Lead, Payment Owner oversight |
| **PayGate Sandbox** | N/A | No direct cost | Covered by existing contracts; no additional cost for this test window |
| **Total Estimated Cost** | ~95 person-hours | $X,XXX (organization-dependent) | Assumes fully loaded labor rate; no new tools or infrastructure needed |

---

## 9. Configuration Management of Testware

### 9.1 Artifact Identification & Storage

| Artifact | Format | Location | Version Control | Ownership |
|----------|--------|----------|-----------------|-----------|
| **Test Plan** | Markdown | Jira ticket / Wiki | Git (release branch) | QA Lead |
| **Test Cases** | Jira issues (type: Test Case) + Markdown detail | Jira project "QA" epic | Jira workflow | QA |
| **Test Scripts** (mock payGate interaction) | Python / JavaScript | Git repo `/tests/integration/split-payment/` | Git (release branch, tagged) | QA + Dev |
| **Test Results** | CSV export from Jira + screenshots | Shared drive + Jira links | Manual archival per release | QA |
| **Test Data Fixtures** | JSON + SQL scripts | Git repo `/tests/fixtures/split-payment.json` | Git (release branch) | QA + Dev |
| **Defect Log** | Jira issues (type: Bug) | Jira project "Release 5.3" | Jira workflow; linked to test case IDs | QA / Dev |
| **Sign-Off Log** | Email + Jira comment | Jira release ticket | Jira comments (timestamped) | QA Lead + PO |
| **Build Artifacts** | Docker images, binaries | Docker registry (staging tag) | Git commit SHA; Docker image tag | DevOps |

### 9.2 Traceability & Version Control

Every test result must include:

```
Result Record Format:
─────────────────────
Test Case ID: [TC-NNN]
Title: [Title]
Execution Date: [YYYY-MM-DD HH:MM:SS UTC]
Executed By: [QA name]
Build: [git commit SHA, or release-candidate-vNN]
Environment: staging | sandbox
Environment Version: [deployment timestamp, docker image tag]
PayGate Mock Version: [mock API version / commit]
Precondition Met: [Yes / No]
Expected Result: [from test case]
Actual Result: [observed behavior; include log snippets if failure]
Result: [PASS / FAIL / BLOCKED / NOT RUN]
Notes: [remarks, screenshots, linked defect ID if FAIL]
─────────────────────
```

### 9.3 Baseline Configuration Management

**Dev Environment Baseline:**
- OS: [Linux/macOS version]
- Node/Python/Language version: [e.g., Node 18.x]
- PayGate Mock API: commit [SHA] or version [v1.2.3]
- Local DB: [schema version, seeded fixtures]
- CI Pipeline: [GitHub Actions / Jenkins config; commit [SHA]]

**Staging Environment Baseline:**
- Deployment: [docker-compose or k8s manifest; git commit [SHA]]
- DB Schema: [migration #NNN]
- PayGate Mock: [image tag: `paygate-mock:vX.Y.Z`]
- PayGate Sandbox Creds: [stored in secrets manager; rotation date]
- Test Data: [fixtures seeded from `/tests/fixtures/split-payment.json`]

**Sandbox (Real PayGate) Baseline:**
- PayGate Account: [account ID]
- Test Cards: [provided by PayGate; valid until [date]]
- Endpoint: [https://sandbox.paygate.example.com/…]
- API Version: [v2.0 or per PayGate docs]

**Restoration & Rollback:**
- To restore staging: `docker-compose -f staging.yml down; docker-compose -f staging.yml up; ./scripts/seed-test-data.sh`
- To rollback release: [git revert [commit] or git tag v5.2.x; redeploy]
- To recreate fixture state: Run `/tests/fixtures/split-payment.reset.sql` to clear test orders; re-seed with `/tests/fixtures/split-payment.json`

### 9.4 Continuous Integration Checklist

Before every test execution:
- [ ] CI pipeline passes (unit tests, linting, build)
- [ ] Code merged to release branch, tag created (e.g., `release-5.3-rc1`)
- [ ] Staging environment deployed from release tag
- [ ] PayGate mock running and responding (health check endpoint)
- [ ] Test data seeded and verified (count orders in test schema)
- [ ] QA has pulled latest test cases from Jira
- [ ] Test results from prior run archived (moved to "Completed Cycles" folder)

---

## 10. Configuration Management of Testware (Continued)

### 9.5 Change & Defect Traceability

**Cross-Reference Matrix:**

| Requirement ID | Risk ID | Test Case ID | Defect ID (if found) | Status |
|----------------|---------|--------------|----------------------|--------|
| REQ-001: Split amount selection | R01, R06 | TC-001, TC-002, TC-004, TC-005 | DEF-0042 (fix verified day 6) | VERIFIED |
| REQ-002: Automatic refund on decline | R02, R04 | TC-003, TC-008, TC-009 | None | VERIFIED |
| REQ-003: Single-card pass-through | R03 | TC-016, TC-017 | None | VERIFIED |
| REQ-004: Amount totals correctly | R05 | TC-005, TC-020 | None | VERIFIED |

**Defect Lifecycle:**
1. **Found**: Logged in Jira with TC-NNN reference, build SHA, environment
2. **Triaged**: Severity assigned (CRITICAL, HIGH, MEDIUM, LOW); assigned to dev
3. **Fixed**: Dev marks Jira ticket, links to fix commit [SHA]
4. **Re-tested**: QA re-runs TC-NNN on new build; updates result record with "PASS" or "FAIL" (re-open if not fixed)
5. **Closed**: Ticket moved to "Done"; archived in release completion report

---

## 11. Test Execution Order & Prioritization

### Risk-Based Execution Order (Default)

Test suites execute in descending order of risk level (CRITICAL → HIGH → MEDIUM → LOW), to surface critical defects earliest:

| Day | Suite | Test Cases | Rationale |
|-----|-------|-----------|-----------|
| 4–5 | **CRITICAL Risk** | TC-001, TC-002, TC-003 | Core split logic & refund (R01, R02); must pass before proceeding |
| 5–6 | **HIGH Risk** | TC-004, TC-005, TC-006 | Input validation & regression (R03, R06); confirm no breakage |
| 6–7 | **Sandbox Validation** | TC-001–TC-006 re-run on real PayGate | CRITICAL gate; sandbox available Tues 11/4, Thu 11/6 |
| 7–8 | **HIGH Risk (edge cases)** | TC-007–TC-012 | Race conditions, edge scenarios (R04, R05, R08) |
| 8–9 | **MEDIUM Risk** | TC-013–TC-015 | Additional validation, performance smoke tests |
| 9–10 | **Final Regression** | TC-016, TC-017 | Single-card baseline; sanity check; GO/NO-GO decision |

### Overrides to Execution Order
- **Sandbox Window Constraint**: If Tues 11/4 sandbox becomes available before day 5 dev completion, advance sandbox validation to day 4 (Thu 10/29 is earliest; likely Thu 11/6 is more realistic given dev schedule).
- **Defect Cascade**: If TC-001 (core split logic) fails, hold TC-002–TC-005 and fast-track defect fix + re-test before proceeding.
- **Resource Contention**: If QA has only 4 hrs/day and dev is in blocking triage, defer MEDIUM risk cases (TC-013–TC-015) to day 9–10 (low impact; not on critical path).

---

## 12. Test Monitoring, Control & Reporting

### 12.1 Monitoring Metrics (Real-Time Dashboard)

| Metric | Frequency | Target | Alert Threshold |
|--------|-----------|--------|-----------------|
| **Test Execution Progress** | Daily | 25% by day 4, 50% by day 6, 100% by day 9 | < 25% by day 4 → escalate |
| **Pass Rate** | Daily | ≥ 95% by day 7; 100% by day 9 | < 90% on gate cases → hold release |
| **Defect Arrival Rate** | Daily | High (day 3–5), declining (day 6–9) | New CRITICAL on day 8+ → extend timeline |
| **Open CRITICAL Count** | Daily | 0 by day 8 | Any open CRITICAL on day 9 → escalate PO |
| **Open HIGH Count** | Daily | 0–2 by day 8; 0 by day 9 | > 3 open HIGH → review prioritization |
| **Sandbox Availability** | Per window | 100% uptime during Tues/Thu | Downtime > 30 min → incident log + plan delta test |
| **Build Stability** | Per merge | CI passes, no linting errors | Build fails → hold testing until fixed |

### 12.2 Control Actions (When Metrics Deviate)

| Deviation | Trigger | Control Action | Owner | Decision Gate |
|-----------|---------|-----------------|-------|---------------|
| Pass rate < 90% on gate by day 6 | Metric alert | Pause analysis cases; focus on gate defect resolution | Dev Lead | Continue testing only if gate reaches 90% by EOD day 6 |
| CRITICAL defect found day 8+ | Defect arrival | Assess fix complexity; if > 4 hrs dev work, escalate to PO for scope/timeline decision | PO + Dev Lead | Extend release window or accept risk + document exception |
| Sandbox unavailable > 1 hour | Incident notification | Log incident; activate fallback: proceed with mock-based gate validation; sandbox re-run on next available window | QA + Platform | Gate does not require real PayGate if mock passes; confirm with PO before release |
| < 20% test progress by end of day 5 | Metric alert | Review QA capacity; consider additional tester or reduce scope to gate only | QA Lead | If not resolved by EOD day 5, notify PO of delay risk |

### 12.3 Weekly Status Report (Every Friday)

**Format**: Email + Jira comment with the following:

```
Release 5.3 Split Payment — Test Status Report
Week of [Mon-Fri dates]
─────────────────────────────────

TEST EXECUTION PROGRESS:
  Gate Cases:        [X] / 6 passed  | [Y] / 6 failed  | [Z] / 6 blocked
  Analysis Cases:    [X] / [Total] passed | [Y] failed | [Z] blocked
  Regression Cases:  [X] / 2 passed  | [Y] / 2 failed
  Overall Pass Rate: [X]% (target: 100% by day 9)

DEFECT STATUS:
  CRITICAL:  [N] open, [N] resolved  [Risk: R01, R02, R04, R08]
  HIGH:      [N] open, [N] resolved  [Risk: R03, R05, R06, R07]
  MEDIUM:    [N] open, [N] resolved
  LOW:       [N] open, [N] resolved
  → Next Triage: [Date/Time]

RISK REGISTER UPDATES:
  [List any risk re-scores, new risks, or mitigations completed]

SCHEDULE ADHERENCE:
  On Track / At Risk / Behind
  [Explain any variance from Gantt; EOA to recover if behind]

BLOCKERS & ESCALATIONS:
  [List any blocking issues for dev/QA/platform; owners; target resolution]

SANDBOX WINDOW SUMMARY:
  Last Window: [Date], Result: [Pass / Partial / Issues]
  Next Window: [Date, time], Expected Tests: [TC list]

SIGN-OFF READINESS:
  [Days 8–10 only] Ready for Release / Hold for [reason]
  → Gate Cases Status: [6/6 pass required]
  → CRITICAL Defects: [0 required]
  → PO Acceptance: [Pending / Approved]

QA Lead: [Name] | Test Date: [Date] | Report Confidence: [High / Medium / Low]
```

### 12.4 Test Completion Report (Day 10 / Release Eve)

**Contents** (Markdown, filed in Jira release ticket):

```
# Test Completion Report: Release 5.3 Split Payment

## Executive Summary
✅ APPROVED FOR RELEASE | Status: [PASS / HOLD / CONDITIONAL]
→ [One sentence: gate passed, zero critical defects, risks reviewed and accepted]

## Test Execution Summary

### Release Gate Results (6 Cases)
| TC | Title | Result | Build | Env | Date | QA |
| TC-001 | Split 100¢ evenly | ✅ PASS | release-5.3-rc4 | staging | 2026-11-06 | [Name] |
| TC-002 | Split 101¢ (rounding) | ✅ PASS | release-5.3-rc4 | staging | 2026-11-06 | [Name] |
| TC-003 | Refund on second decline | ✅ PASS | release-5.3-rc4 | sandbox | 2026-11-11 | [Name] |
| TC-004 | Invalid input (zero) | ✅ PASS | release-5.3-rc4 | staging | 2026-11-06 | [Name] |
| TC-005 | Invalid input (overage) | ✅ PASS | release-5.3-rc4 | staging | 2026-11-06 | [Name] |
| TC-006 | Single-card regression | ✅ PASS | release-5.3-rc4 | staging | 2026-11-06 | [Name] |
→ **Gate Verdict**: ✅ PASS (6/6); Release gate is GREEN.

### Full Test Execution Summary
- **Scope**: 20 test cases (6 gate + 14 analysis)
- **Executed**: 20 / 20 (100%)
- **Passed**: 19 / 20 (95%)
- **Failed**: 1 / 20 → MEDIUM severity defect DEF-0087, resolved and re-tested ✅ PASS on 2026-11-07
- **Blocked**: 0 / 20
- **Not Run**: 0 / 20

### Defect Summary
| Severity | Opened | Closed | Re-Tested | Status |
| CRITICAL | 0 | 0 | 0 | ✅ Zero critical |
| HIGH | 2 | 2 | 2 | ✅ All resolved by day 8 |
| MEDIUM | 1 | 1 | 1 | ✅ Resolved, verified |
| LOW | 3 | 3 | 0 | ✅ All closed; post-release acceptable |
→ **No open defects blocking release.**

### Risk Assessment (Final)
- **R01 (Split Calculation)**: Mitigated. Boundary tests (100¢, 101¢) pass; rounding logic verified. **SCORE: 3 (LOW)**
- **R02 (Refund Latency)**: Mitigated. Mean refund latency 4.2 sec (target 60s). Sandbox test on 2026-11-11 confirmed. **SCORE: 3 (LOW)**
- **R03 (Single-Card Regression)**: Mitigated. TC-016, TC-017 pass 100%; existing unit tests pass. **SCORE: 2 (LOW)**
- **R04 (Race Condition)**: Mitigated. Idempotency tests (TC-009) pass; PayGate mock and sandbox both succeed. **SCORE: 4 (LOW)**
- **PR01 (Sandbox Availability)**: Mitigated. Sandbox available Thu 10/29 (prep), Tues 11/4, Thu 11/6, Tues 11/11. All gates executed. **SCORE: 2 (LOW)**
→ **No residual critical product or project risks.**

### Regression Test Results
| Test | Single-Card Payment (Baseline) | Split Payment (New Feature) |
| TC-016 | ✅ PASS (no latency change) | ✅ PASS |
| TC-017 | ✅ PASS (decline handled) | N/A |
→ **Regression Status**: ✅ GREEN (backward compatibility confirmed)

### Coverage & Traceability
- **Requirement Coverage**: 4 / 4 requirements traced to test cases; all tested and passed.
- **Risk Coverage**: 15 / 15 risks in register have mitigation cases; all executed.
- **Build Version**: release-5.3-rc4 (commit: abc123def456…)
- **Environment**: Staging (PayGate mock v1.2.1) + Sandbox (real PayGate, 2026-11-11)
- **Test Data**: 10 test orders seeded from `/tests/fixtures/split-payment.json` on 2026-11-02; all cleaned up post-test.

## Metrics

| Metric | Target | Actual | Status |
| Test Progress | 100% by day 9 | 100% by day 8 | ✅ Ahead |
| Pass Rate | 100% by day 9 | 95% on day 6, 100% by day 9 (after re-test) | ✅ Met |
| Defect Escape | < 1 per 1000 cases | 4 defects / 20 cases = 200 per 1000 | ⚠️ Expected (defect density normal for payment feature) |
| CRITICAL Count | 0 by day 8 | 0 from day 1 | ✅ Met |
| Refund Latency | Mean < 10s; P100 < 60s | Mean 4.2s; P100 8.7s | ✅ Exceeded target |
| Sandbox Uptime | 100% during test windows | 100% (4/4 windows available) | ✅ Met |

## Sign-Off

**QA Lead**: [Name] — ✅ Approved for Release
- All gate cases passed on 2026-11-06 (mock) and 2026-11-11 (sandbox).
- Zero critical defects; no open issues blocking release.
- Regression baseline green; single-card payment unaffected.
- Test artifacts archived in Git and Jira; traceability complete.

**Product Owner**: [Name] — ✅ Accepted
- Feature meets acceptance criteria.
- Risk register reviewed; residual risks are low and acceptable.
- Defects logged and tracked; no exceptions needed.
- Approved for production release.

**Release Date**: Tues 2026-11-11 (approved)

## Handover Notes

- Feature is production-ready; no known issues.
- Post-release monitoring: Watch for refund processing delays (target < 60s) and single-card payment latency (baseline: 500ms).
- Defect log for future sprints: Low-severity UX improvements (e.g., error message clarity) logged as future work.
- Test artifacts retained for regression suites in Release 5.4+.
```

### 12.5 Post-Release Monitoring (First Week)

**Metrics to Watch** (ops/monitoring dashboard):
- Refund latency (should be < 10s mean, < 60s p100)
- Split payment transaction success rate (should be ≥ 99.5%)
- Single-card payment success rate (should remain ≥ 99.8%, same as pre-release)
- PayGate API error rate (should not increase > 0.1% delta)

**Escalation Path**: If any metric falls outside bounds, page Payment Systems Owner; investigate; file post-release defect if needed.

---

## Appendix: Test Case Template (Detail View)

**Example: TC-001**

```
Test Case ID: TC-001
Title: Split 100¢ evenly between two cards; both charges succeed
Priority: P0 (Critical)
Risk Coverage: R01 (Split Calculation), R02 (Charge Sequencing)
Test Level: Integration (mock PayGate)
Test Type: Functional

Preconditions:
  - Order ORD-001 (100¢) is seeded in staging DB
  - Order state is "pending"
  - PayGate mock is running (success mode)
  - QA has staging credentials

Test Steps:
  1. Navigate to /checkout?order_id=ORD-001
  2. Verify "Split Payment" option is visible
  3. Click "Split Payment"
  4. Enter split amount: 50 (cents)
  5. Verify second amount auto-fills: 50 (cents)
  6. Click "Proceed to Payment"
  7. Enter card 1 details: CARD-VALID
  8. Click "Charge Card 1"
  9. Verify PayGate API called with: amount=50, idempotency_key=[UUID]
  10. Verify response: success, charge_id=ch_001
  11. Verify UI shows "Card 1 charged $0.50"
  12. Enter card 2 details: CARD-VALID
  13. Click "Charge Card 2"
  14. Verify PayGate API called with: amount=50, idempotency_key=[UUID]
  15. Verify response: success, charge_id=ch_002
  16. Verify order state in DB: "paid"
  17. Verify order.charges contains [ch_001, ch_002]
  18. Query DB: SELECT SUM(amount) FROM charges WHERE order_id=ORD-001 → expect 100

Expected Result:
  - Both cards charged 50¢ each
  - Total charged: 100¢
  - Order state: "paid"
  - No errors or timeouts
  - Payment latency < 2s per charge

Acceptance Criteria:
  - ✅ Both charges logged in DB
  - ✅ Order marked "paid"
  - ✅ UI reflects successful payment
  - ✅ No refund triggered (both succeeded)

Test Data:
  - Order: ORD-001 (100¢)
  - Card 1: CARD-VALID
  - Card 2: CARD-VALID
  - PayGate Mock: success mode

Automation:
  - Automated: Yes (Playwright E2E + API call mocking)
  - Script: `/tests/e2e/split-payment.spec.ts::should-split-evenly`
  - Run Command: `npm run test:e2e -- --grep "should-split-evenly"`

```

---

## End of Test Plan

**Status**: ✅ Ready for Execution (Approved by QA Lead on 2026-10-28)  
**Next Step**: Distribute to dev team, PO, and platform for feedback by EOD Thu 10/29; finalize by Fri 10/30; testing begins Mon 11/2.
