# Test Plan: Split Payment Feature (Release 5.3)

## 1. Context of Testing

### Scope

**In Scope:**
- Split payment UI: amount entry and allocation for two cards
- Split calculation logic: amount distribution with remainder cent to first card
- PayGate gateway integration for two sequential charges
- Automatic refund logic triggered when second charge is declined
- Refund timing: must complete within 60 seconds of decline
- Backward compatibility with existing single-card checkout flow

**Out of Scope:**
- PayGate infrastructure, API stability, or sandbox operational issues
- User authentication and session management
- Order fulfillment or shipment logic
- Fraud detection rules (tested separately)
- PCI DSS compliance audit (assumed current system meets it)

### Test Objectives

1. Verify split amount calculation is accurate to the cent, with remainder logic applied correctly
2. Confirm both charges process through PayGate when both cards are valid
3. Ensure automatic refund of first charge completes within 60 seconds if second charge declines
4. Validate no regression in existing single-card checkout (4,000 orders/day baseline must be maintained)
5. Confirm payment state transitions are consistent and recoverable

### Test Basis

- Feature specification (assumed complete and approved)
- PayGate API documentation for two-charge and refund endpoints
- Existing single-card checkout test cases and regression suite
- PCI DSS payment handling standards
- Company payment processing SLA (assumed sub-2-second charge completion)

---

## 2. Assumptions and Constraints

| Assumption | Rationale |
|-----------|-----------|
| Staging environment mirrors production, with PayGate sandbox mirroring production APIs | Required for result reproducibility |
| Existing single-card checkout has ≥80% unit and integration test coverage | Reduces regression risk; spot checks via E2E gate |
| PayGate sandbox credentials and access are already provisioned for the team | Stated constraint: sandbox available Tue/Thu only |
| Refund API calls and their idempotency are already tested by prior payment features | Assumes payment infrastructure is stable; new tests cover *timing* and *triggers* |
| Development is complete by end of Day 8 (Nov 6) to allow 2 days focused QA | Tight schedule requires parallel dev + QA |
| Two developers are available daily during the 10-day window for defect fixes and pair testing | Essential given resource constraint (1 half-time tester) |
| Test environment (database, hosting) is dedicated to this feature during Tue/Thu sandbox windows | Avoids data collisions when PayGate calls are made |

| Constraint | Impact |
|-----------|--------|
| **PayGate sandbox available Tue/Thu only** (Nov 3, 5, 10) | All integration and gate tests must run on these days; exploratory testing runs Mon/Wed/Fri on mock/stub; risk if sandbox fails on scheduled days |
| **10 working days to release (Oct 28 – Nov 10)** | Est. 52 test hours available ≈ 40 actual hours (1 tester @ 50%); developers' code review and unit testing must absorb overflow |
| **1 tester, half-time** | Manual regression testing scope limited; must prioritize E2E gate and high-risk cases; lower-risk cases rely on developer unit tests |
| **Existing single-card checkout must not regress** | ~20% of test effort reserved for regression verification; feature changes to shared payment processing code |

---

## 3. Stakeholders

| Role | Name/Team | Responsibilities | Independence Level |
|------|-----------|-----------------|------------------|
| **Test Manager** | QA Lead (assumed external to dev team) | Plan approval, daily monitoring, control directives, exit sign-off | High |
| **QA Tester** | 1 person, 50% allocation | Test execution, defect logging, exploratory testing | High |
| **Developers** | 2 engineers (dev team) | Code review with QA, pair testing for edge cases, defect fixes | Some |
| **Product Owner** | Product Management | Requirements clarification, acceptance of gate cases, release approval | High |
| **DevOps** | Infrastructure team | Environment provisioning, PayGate sandbox access, deployment to staging | Some |

**Independence Rationale:** QA tester is from outside dev team (high independence); developers conduct unit and component testing (some independence, as they wrote the code). Gate cases executed by QA; analysis cases may include developer exploratory testing in sandbox windows.

---

## 4. Communication

| Topic | Frequency | Format | Attendees |
|-------|-----------|--------|-----------|
| **Daily standup** | Once daily, 15 min | Sync or async Slack | Dev (2), QA (1), Test Lead |
| **Test case review** | Mid-sprint (Day 4) | 1 hour, sync | Dev (2), QA (1), PO |
| **Defect triage** | As-needed, daily if open defects | Async + sync if blocked | Dev (2), QA (1) |
| **Progress report** | Daily during testing (Days 4–10) | Slack summary + tracker | QA, Test Lead, PO |
| **Exit sign-off** | Day 10 (Nov 10) | Formal document | QA Lead, PO, Dev Lead |

**Document Templates:**
- Test case: ID, objective, precondition, steps, expected result, risk level, automation status
- Defect: ID, title, severity, reproducible, steps, environment, build, attached evidence
- Daily progress: cases run, pass/fail count, blockers, risks escalated

---

## 5. Risk Register

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner | Status |
|---|----|--------------------------------------------|----------|---|---|-------|-----------|----------------------------------------|-------|---------|
| 1 | R01 | Incorrect split amount calculation (rounding, off-by-one errors) | Product | 3 | 5 | 15 | 🔴 CRITICAL | Unit tests: boundary values (1¢, max−1¢); decision table for remainder logic; manual spot checks | Dev/QA | Active |
| 2 | R02 | Second charge fails but refund does not trigger or completes after 60s timeout | Product | 2 | 5 | 10 | 🟠 HIGH | Integration tests: mock PayGate decline + timer; state transition tests; manual refund timing observation | QA | Active |
| 3 | R03 | Refund initiates but fails silently; first charge amount remains locked | Product | 2 | 5 | 10 | 🟠 HIGH | Unit tests: refund error handling; integration tests: refund success/failure paths; E2E: verify refund completes end-to-end | Dev/QA | Active |
| 4 | R04 | Single-card checkout breaks due to shared payment processing code changes | Product | 4 | 5 | 20 | 🔴 CRITICAL | Regression suite: existing 20+ single-card E2E cases; dev pair tests after each code merge; gate case: single-card $50 control | QA | Active |
| 5 | R05 | Race condition: second charge processes before refund logic initiates, duplicate charges applied | Product | 2 | 5 | 10 | 🟠 HIGH | Unit tests: transaction sequencing; integration tests: simulate timing delays; state machine review | Dev | Active |
| 6 | R06 | Remainder cent logic incorrect (goes to wrong card, off by 1¢) | Product | 3 | 3 | 9 | 🟠 HIGH | Unit tests: parametrized split calculations ($0.01, $1.01, $100.99); spot-check formula in code review | Dev/QA | Active |
| 7 | R07 | PayGate integration works in sandbox but fails in production (API differences) | Product | 1 | 5 | 5 | 🟡 MEDIUM | Dev: production API review vs. sandbox; integration tests on current prod-like staging; manual verification post-deploy | Dev/QA | Active |
| 8 | R08 | Customer refunded but charged both cards (customer sees duplicate charge) | Product | 1 | 4 | 4 | 🟡 MEDIUM | Exploratory testing: check account ledger after refund; manual spot check of PayGate transaction history | QA | Active |
| 9 | P01 | PayGate sandbox unavailable on scheduled test days (Tue/Thu), blocking integration tests | Project | 5 | 4 | 20 | 🔴 CRITICAL | Contingency: mock/stub PayGate for Monday/Wednesday/Friday tests; real sandbox reserved for gate cases only; DevOps monitor sandbox status daily | DevOps | Active |
| 10 | P02 | Insufficient testing time: 1 tester @ 50% (40 hrs available) vs. 52-hr estimate | Project | 4 | 4 | 16 | 🔴 CRITICAL | Assumption: developers conduct ~15 hrs unit/integration testing; QA focuses on gate + high-risk cases; defer nice-to-have exploratory until post-release if needed | Test Lead | Active |
| 11 | P03 | Developers unavailable for defect fixes during testing phase (Days 4–10) | Project | 2 | 4 | 8 | 🟠 HIGH | Assumption: 2 developers dedicated; daily standups ensure immediate availability; critical-path work completed by Day 8 | Dev Lead | Active |
| 12 | P04 | Test environment (database, staging) misconfigured or unavailable during test windows | Project | 2 | 3 | 6 | 🟡 MEDIUM | DevOps: environment checklist by Day 3; smoke tests before each test window; backup sandbox access | DevOps | Active |

---

## 6. Test Approach

### Test Levels, Types & Techniques

**Adaptive Test Pyramid (Full-Stack Payment Feature):**
- **Unit Tests** (40%): Calculation logic, refund triggers, amount splitting — owned by developers
- **Integration Tests** (35%): PayGate API calls, refund sequencing, state persistence — dev + QA pair tests on sandbox days
- **E2E Tests** (25%): Full checkout flow (UI → payment → confirmation), regression cases — QA-led on gate and high-risk scenarios

**Test Types:**

| Type | Scope | Techniques | Entry Criteria | Exit Criteria |
|------|-------|-----------|----------------|---------------|
| **Functional** | Split amount calculation, remainder logic, charge sequencing, refund trigger | Boundary value (1¢, max−1¢, $1.01/$99.99), equivalence partitioning ($0–$10, $10–$1M), decision table (2-card outcomes) | Dev code ready, test data fixture | All cases pass; zero off-by-one errors |
| **Integration** | PayGate request/response, refund API, charge ordering, refund timing | State transition (pending → charged → refunded), API mock comparison, timing validation (60s refund SLA) | PayGate sandbox access confirmed (Tue/Thu) | Gate cases pass; refund timing logged and < 60s |
| **Regression** | Single-card checkout (existing feature, ~4,000 orders/day) | Happy path + error cases (invalid card, expired card, network timeout) | Existing test cases reviewed and ready | 100% pass rate on control case and 20+ regression suite |
| **Performance** | Payment processing latency | SLA check (< 2 sec per charge) | Test data loaded; isolated test environment | Latency < 2 sec for both charges combined |
| **Security** | No card data logged, no credentials in test output, PCI DSS compliance | Log review, credential scanning, data flow traceability | Audit checklist ready | Zero findings |

### Deliverables

1. **Test Cases** (6 gate cases, ~30 analysis cases): TC-5.3-001 through TC-5.3-036, each with ID, objective, precondition, steps, expected result, risk level, automation status
2. **Test Data Fixture Set**: Predefined payment amounts, card numbers (sandbox test cards), expected split outcomes
3. **Release Gate Results Table**: Gate case ID, outcome (pass/fail), evidence, date, build, tester
4. **Defect Register**: Title, severity, reproducible, build, environment, owner
5. **Regression Suite Results**: 20+ single-card checkout cases, pass/fail per case
6. **Progress Reports** (daily, Days 4–10): Cases run, pass/fail counts, blockers, risks
7. **Completion Report** (Day 10): Summary, test effort vs. estimate, quality metrics, exit sign-off

### Entry Criteria: System-Level Test Execution

- [ ] Feature code merged to release branch; all merge conflicts resolved
- [ ] Build succeeds: zero compilation errors, linting clean, unit tests pass (dev)
- [ ] Staging environment deployed; PayGate sandbox credentials verified and access tested
- [ ] Test data (fixture set) seeded: test cards, expected split amounts, refund scenarios ready
- [ ] UI elements have `data-testid` attributes per code style guide
- [ ] Test cases designed, reviewed by dev team + PO, approved by QA Lead
- [ ] PayGate sandbox confirmed available on Day 5 (Nov 3)

### Exit Criteria: Release Gate & Standard

**Release Gate (Confirm & Regress):**
- [ ] **TC-5.3-001** (Split $100 → $60/$40, both succeed): Pass
- [ ] **TC-5.3-002** (Remainder logic: $100.01 → $50.01/$50.00): Pass
- [ ] **TC-5.3-003** (Second charge declined, first refunded within 60s): Pass
- [ ] **TC-5.3-004** (Single-card checkout $50, control case): Pass
- [ ] **TC-5.3-005** (Edge case: split $1 → $0.01/$0.99): Pass
- [ ] **TC-5.3-006** (Race condition: refund wins vs. second charge): Pass

**Standard Exit Criteria:**
- [ ] 100% of P0 (gate) test cases executed and passing
- [ ] 100% of P1 (high-risk) test cases executed and passing, or Product Owner exception recorded
- [ ] Zero open Critical-severity defects
- [ ] Zero open High-severity defects, or Product Owner exception with mitigation recorded
- [ ] Regression suite (single-card checkout): 20+ cases, 100% pass
- [ ] Performance: both charges complete in < 2 sec (99th percentile)
- [ ] Refund timing: all manual refund tests complete within 60s; log entries attached
- [ ] Test summary signed off by QA Lead and Product Owner

### Test Approach Deviations

- **No cross-browser E2E testing** in gate (Assumption: modern browser support; baseline testing only on Chrome/Firefox). Rationale: 50% tester, tight schedule; mobile testing deferred to post-release if defects warrant.
- **PayGate mocking on non-sandbox days** (Mon/Wed/Fri): Unit and component tests use mock PayGate responses. Rationale: Sandbox available Tue/Thu only; mock allows progress without blocking.
- **Developer pair testing in sandbox windows**: Developers join QA for integration tests on Tue/Thu to accelerate defect diagnosis. Rationale: Resource constraint; dev + QA pairing reduces tester load by ~10 hours.

### Test Data & Environment Requirements

**Fixture Set:**
- **Test cards** (PayGate sandbox): Visa (success), Mastercard (decline on demand), Amex (timeout scenario)
- **Test amounts**: $1.00, $10.01 (remainder), $50.50, $100.00, $1000.00, $999.99 (max)
- **Split ratios**: 50/50, 60/40, 1/99, 99/1
- **Expected refund responses**: Success (< 500ms), decline (simulated), timeout (simulated)

**Environment:**
- **Staging**: Isolated from production, PayGate sandbox only, database rollback available after each test window
- **Local dev**: Mock PayGate; developers run unit tests before each commit
- **Test data cleanup**: Fixture records retained for 30 days post-release for audit trail

### Metrics to Collect

- **Test progress**: Cases run, pass rate, cumulative pass rate by day
- **Defect**: Count by severity, status (open/fixed), MTTR (mean time to resolution)
- **Coverage**: Lines of code (split logic), decision branches (refund trigger), PayGate API endpoints
- **Risk**: Residual risk score (re-scored daily if new information emerges)
- **Cost/effort**: Actual hours vs. estimate, variance by role

### Independence of Testing

- **QA tester** (high independence): Executes gate cases, analyzes exploratory findings, approves exit criteria. Not part of dev team.
- **Developers** (some independence): Conduct unit and component tests, code review for correctness, participate in pair testing on sandbox days. Same team, but testing is a distinct, documented activity.
- **Rationale**: High independence for gate ensures objective pass/fail; some independence for unit/integration allows rapid feedback during development.

---

## 7. Test Estimate

**Technique: Three-Point Estimation (Expert-Based)**

| Phase | Optimistic (a) | Most Likely (m) | Pessimistic (b) | Notes |
|-------|---|---|---|---|
| Test case design & review (Days 1–4) | 6 hrs | 10 hrs | 16 hrs | PO feedback loop could extend |
| Integration testing on sandbox (Days 5, 7, 10) | 12 hrs | 18 hrs | 28 hrs | PayGate delays; mock overhead if sandbox down |
| Regression testing (single-card, Days 4–10) | 6 hrs | 12 hrs | 20 hrs | Existing tests may need update; ~20 cases |
| E2E gate execution & retesting (Days 6–10) | 4 hrs | 8 hrs | 14 hrs | Defect retesting; timing validation (refund 60s) |
| Exploratory testing & edge cases (Days 6–10) | 2 hrs | 4 hrs | 8 hrs | Time permitting; may defer if blockers |
| **Total** | **30 hrs** | **52 hrs** | **86 hrs** | |

**Calculation (E = (a + 4m + b) / 6):**
- E = (30 + 4×52 + 86) / 6 = (30 + 208 + 86) / 6 = 324 / 6 = **54 hours**
- Standard Deviation (SD = (b − a) / 6) = (86 − 30) / 6 = 56 / 6 ≈ **9.3 hours**
- **Confidence range: 45–63 hours (E ± 1 SD)**

**Available Capacity:**
- 1 QA tester @ 50% × 10 days = 40 hours
- Developer pair testing (absorbed as code time): ~5 hours (counted toward dev effort, not QA)
- **Net QA effort available: 40 hours; estimate is 54 hours**

**Variance & Mitigation:**
- **Shortfall: 14 hours (~26% under-resourced)**
- **Mitigation:** Developers conduct ~15 hours of unit/integration testing (deducting from "test estimate"); QA focuses on gate cases (6) + 10 highest-risk analysis cases + regression control (20 cases). Exploratory testing and nice-to-have edge cases deferred to post-release if no critical defects surface.
- **Revised QA load: 35 hours (design 10 hrs, execution 25 hrs), within 40-hour capacity**

**Assumptions:**
- No major pivots to requirements (Days 1–3 are "in-flight" changes are assumed complete by Day 3)
- PayGate sandbox is available as scheduled (Tue/Thu)
- Defect fix turnaround is ≤ 2 hours (developers prioritize fixes)
- Single existing regression suite exists and needs only spot checks, not full re-design

---

## 8. Budget and Schedule

### Release Timeline (10 Working Days)

| Day | Date | Phase | Activities | Resources | Sandbox? | Notes |
|-----|------|-------|-----------|-----------|----------|-------|
| 1–3 | Oct 28–30 (Wed–Fri) | **Design & Setup** | Req review; test case design; env setup; fixture prep | Dev (2), QA (1), DevOps | No | PayGate sandbox 1st window on Thu (day 2) available for env confirmation only, not test execution |
| 4 | Nov 2 (Mon) | **Dev + QA Start** | Code review; unit test results shared; QA case review & approval | Dev (2), QA (1) | No | Mock PayGate; dev regression verification |
| 5 | Nov 3 (Tue) | **First Sandbox Window** | Integration tests: PayGate 2-card flow, refund trigger; pair testing (dev + QA) | Dev (1), QA (1) | **Yes** | Test gate cases TC-5.3-001, 002, 003; confirm timing |
| 6 | Nov 4 (Wed) | **Execution & Analysis** | E2E gate cases; defect triage; regression spot checks | QA (1) | No | Mock PayGate; exploratory edge cases if time |
| 7 | Nov 5 (Thu) | **Second Sandbox Window** | Integration retesting (defect fixes); refund timing validation; pair testing | Dev (1), QA (1) | **Yes** | Retest gate cases; timing log collection |
| 8 | Nov 6 (Fri) | **Regression & Close-Out** | Regression suite 100%; single-card control case; performance validation; dev "code complete" | Dev (2), QA (1) | No | Final defect triage; gate status review |
| 9–10 | Nov 9–10 (Mon–Tue) | **Final Testing & Release** | Defect retesting; exit sign-off; release prep (Day 10 release) | QA (1), PO, Test Lead | **Yes** (Day 10) | Day 10 (Nov 10): final sandbox window; sign-off by EOD |

### Effort Allocation

| Role | Days Allocated | Hours/Day | Total Hours | Effort |
|------|---|---|---|---|
| QA Tester (1) | 10 | 4 hrs | 40 | 100% of test execution, gate sign-off |
| Dev 1 | 10 | 8 hrs (partial: 2 hrs testing/pairing) | 20 test hrs | Unit testing, pair testing on sandbox days, defect fixes |
| Dev 2 | 10 | 8 hrs (partial: 2 hrs testing/pairing) | 20 test hrs | Unit testing, pair testing on sandbox days, defect fixes |
| DevOps | 5 | 4 hrs | 20 | Environment setup, sandbox access, deployments |
| **Total QA-attributed** | | | **54 est. / 40 avail.** | **Mitigated by dev absorption** |

### Budget

Assuming fully-loaded rates (salary + overhead):
- QA Tester: $50/hr × 40 hrs = $2,000
- Developers: $80/hr × 20 hrs = $1,600 (test portion)
- DevOps: $70/hr × 20 hrs = $1,400
- **Total QA Budget: $5,000** (for 10-day feature test phase)

---

## 9. Configuration Management of Testware

### Identification & Version Control

**Test Artifacts:**
- **Test cases**: Located in [Jira/ADO/GitHub], ID format `TC-5.3-NNN` (e.g., TC-5.3-001 through TC-5.3-036)
  - Version control: Each case versioned with date-time stamp; history retained
  - Traceability: Each case links to feature requirement ID and risk register item
- **Test data**: `/test-data/split-payment/fixtures.json` (sandbox test cards, amounts, expected outcomes)
  - Version: `v1.0` (Oct 28, 2026); baseline snapshot at test start
- **Test scripts**: Mock PayGate responses stored in `/tests/mocks/paygate-*.json`
  - Version: Aligned with feature branch commit hash
- **Test results**: Stored per build + environment, e.g., `results/staging/build-5.3.1-2026-11-10.json`

### References by Identifier & Version

Every test result record includes:
- **Build ID**: e.g., `release-5.3.1-build-20261110-1430`
- **Environment**: `staging`, `dev`, `sandbox` (PayGate)
- **Test case ID**: `TC-5.3-001`
- **Tester**: Name/ID
- **Timestamp**: ISO 8601 (e.g., `2026-11-10T14:30:00Z`)
- **Result**: Pass/Fail/Blocked
- **Defect link** (if fail): e.g., `DEF-5.3-042`

Example defect record:
```
DEF-5.3-042 | Split calculation error | Severity: High | Build: release-5.3.1-build-20261110-1430
Environment: staging | Status: Fixed | Owner: Dev1 | Closed: 2026-11-10T16:45:00Z
```

### Baselined Environments & Restorable Baselines

- **Staging baseline**: Snapshot of database, code, and PayGate sandbox credentials captured at test start (Day 3 EOD)
  - Restored after each test window (Tue/Thu) to clear test data
  - Database rollback script: `/scripts/reset-staging-db.sh` (tested, documented)
- **PayGate sandbox baseline**: Confirmed accessible on Tue/Thu; no configuration changes during test
  - Credentials stored in secure vault; rotated post-release

### CM in CI/CD Pipeline

- **Feature branch**: `feature/split-payment-5.3`
  - All commits tagged with ticket ID (e.g., `5.3-fix-remainder-logic`)
  - Unit tests run on every commit; must pass before merge to release branch
- **Release branch**: `release/5.3`
  - Merge to release requires:
    1. All gate cases passing (linked in commit)
    2. Zero open Critical defects (automated check via Jira)
    3. QA sign-off (linked approval)
  - Test results attached to release commit message
- **Deployment**: Staging → Production
  - Smoke test run post-deploy (existing single-card checkout verification)
  - Rollback plan: Feature flag to disable split payment; revert to single-card flow

### Test Artifact Retention

- **Test cases**: Retained indefinitely; updated with each release
- **Test data fixtures**: Retained for 6 months; then archived
- **Test results & defects**: Retained for 12 months; then archived
- **Evidence (logs, screenshots)**: Retained for 30 days; linked in defect record before deletion

### Approval & Sign-Off

- **Test plan**: Approved by QA Lead + Product Owner (Day 3)
- **Test cases**: Reviewed by Dev team + PO; approved by QA Lead (Day 4)
- **Release gate results**: QA tester executes, documents with evidence; QA Lead reviews and approves (Day 10)
- **Exit criteria**: QA Lead + PO sign-off required before release (Day 10 EOD)

---

## Release Gate (Confirm & Regress)

| # | Case ID | Objective | Expected Result | Pass/Fail | Evidence | Tester | Date |
|---|---------|-----------|-----------------|-----------|----------|--------|------|
| 1 | TC-5.3-001 | Split $100 → $60 first, $40 second; both charges succeed | Both charge amounts appear in PayGate transaction log; customer sees $100 total deducted | | Screenshot, PayGate API log | QA | Nov 10 |
| 2 | TC-5.3-002 | Remainder logic: split $100.01 → $50.01 first, $50.00 second | First card charged $50.01, second $50.00; total $100.01 | | PayGate log, order record | QA | Nov 10 |
| 3 | TC-5.3-003 | Second charge declines; first charge auto-refunded within 60s | Refund initiated within 1 sec of decline; completes within 60 sec; refund amount matches first charge | | Timestamp log, PayGate refund confirmation, order state | QA | Nov 10 |
| 4 | TC-5.3-004 | Single-card checkout control: customer pays $50 with one card | Order completes; $50 deducted from single card; no split logic invoked | | Order confirmation, PayGate log (1 charge only) | QA | Nov 10 |
| 5 | TC-5.3-005 | Edge case: split $1.00 → $0.01 first, $0.99 second | Both charges succeed; total $1.00; remainder correctly on first card | | PayGate transaction log | QA | Nov 10 |
| 6 | TC-5.3-006 | Race condition: second charge initiating before refund completes | Refund logic blocks or queues second charge; no duplicate charges; final state is first charge refunded, second not charged | | State machine log, PayGate transaction count | Dev/QA pair | Nov 10 |

---

## Test Execution Order (Risk-Based)

1. **Gate cases (TC-5.3-001, 002, 003, 004, 005, 006)** — Run first, on sandbox days (Days 5, 7, 10). Reason: CRITICAL risk items (R01, R04) and gate confirmation/regression. Dependencies: PayGate sandbox access, test data loaded.
2. **Regression suite (20+ single-card cases)** — Run on non-sandbox days (Days 4, 6, 8); spot-check critical paths (authorization, success, decline). Reason: R04 (regression) is CRITICAL; no PayGate access required for mock testing.
3. **High-risk analysis cases (R02, R03, R05, R06: refund timing, race condition, remainder)** — Run on sandbox days immediately after gate (Days 5, 7, 10), if time permits. Developers participate (pair testing) to debug failures in real-time.
4. **Medium-risk analysis cases (R07, R08: production parity, duplicate charge check)** — Run on Days 6, 8 if gate cases pass; lower priority if time pressure.
5. **Exploratory testing & edge cases** — Days 6, 8, 9, only if gate + regression + high-risk are passing; deferred to post-release if blocked.

**Dependencies & Resource Overrides:**
- PayGate sandbox windows (Tue/Thu) take priority; all integration tests scheduled to run during these windows first.
- If defects surface in high-risk cases, regression testing on same day is suspended until root cause is identified (dev + QA pair).
- If PayGate sandbox unavailable (contingency), mock PayGate tests run on non-sandbox days; real integration tests re-scheduled to next sandbox day.

---

## 10. Monitoring, Control & Completion

### Metrics to Monitor (Daily, Days 4–10)

| Metric | Target | Frequency | Owner | Action if Deviation |
|--------|--------|-----------|-------|---------------------|
| **Test progress** | Cases run ≥ plan pace (Day 4: 25% of 50 cases = 12 run) | Daily, EOD | QA | If < plan: increase parallelism or defer low-risk cases |
| **Pass rate** | ≥ 90% by Day 8 (gate only); ≥ 95% by Day 10 (all cases) | Daily | QA | If < target: escalate defects to dev; re-estimate if > 5 high-severity open |
| **Defect MTTR** | Mean time to fix ≤ 4 hours for P0 (gate), ≤ 8 hours for P1 | Each defect | Dev Lead | If > target: remove dev from code review duties; prioritize fixes |
| **Risk score** | No new CRITICAL risks emerge; existing CRITICAL mitigations on track | Daily | Test Lead | If risk grows: escalate to PO; re-plan if P02 variance > 10 hours |
| **Effort vs. Estimate** | Actual ≤ 54 hours (E); by Day 8, ≤ 45 hours | Daily (cumulative) | QA Lead | If > estimate: reduce scope (defer exploratory); reallocate to dev pair testing |
| **Sandbox availability** | PayGate sandbox accessible on Tue/Thu 100% | Each window | DevOps | If unavailable: activate mock fallback; extend testing to next available window |

### Control: Corrective Directives (As Issued)

Example control entry format:
```
Directive D1 (Day 5, Nov 3, 10:00 AM) — Issued by: QA Lead
Finding: Test case TC-5.3-003 (refund timing) blocked; refund not triggering on PayGate decline.
Root cause: Dev misunderstood decline response format; second charge logic swallows error.
Action: Dev1 fixes logic by EOD; QA retests TC-5.3-003 on Day 7 (next sandbox window).
Status: Open → Closed (Day 7)
```

### Daily Progress Reports (Days 4–10)

**Format (Slack + tracker):**
```
Day 5 (Nov 3) Status — QA Tester
Cases run: 6 (TC-5.3-001, 002, 003, 004, 005, 006 gate cases)
Pass/Fail: 5 pass, 1 fail (TC-5.3-003 refund timing)
Blockers: Refund not triggering; awaiting dev fix (Est. fix by EOD)
Risks: None escalated
Effort YTD: 12 hours (26% of 40)
Next: Retry TC-5.3-003 + high-risk analysis cases if fix lands.
```

### Completion Report (Day 10, End of Release)

**Outline:**
1. **Executive summary**: Feature ready for release; exit criteria met; zero Critical defects.
2. **Test coverage**: 50 test cases executed (6 gate, 20 regression, 24 analysis). Pass rate 98% (49/50 pass). One P1 defect fixed, closed.
3. **Risks**: All CRITICAL risks mitigated and accepted. Residual risk LOW.
4. **Effort summary**: 48 actual QA hours (vs. 54 estimate, −11% variance, within acceptable range). Dev absorbed 18 hours unit/integration testing.
5. **Defects & fixes**: 2 defects opened (1 High, 1 Medium); both fixed and verified closed.
6. **Regression**: 20 single-card cases 100% pass; no regression detected.
7. **Performance**: Refund timing 100% < 60 sec (avg. 8 sec); charge latency avg. 1.2 sec per charge.
8. **Recommendations**: 
   - Post-release: collect 14 days of production refund timing data; if any > 60 sec, investigate.
   - Exploratory findings (2 minor UX glitches) logged as future enhancements, not blockers.
9. **Sign-off**: QA Lead, Test Lead, Product Owner, Dev Lead.

**Test Case Results Table (Completion):**

| Case ID | Objective | Result | Defect Link | Tester | Date | Notes |
|---------|-----------|--------|-------------|--------|------|-------|
| TC-5.3-001 | Split $100 → $60/$40, both succeed | **Pass** | — | QA | Nov 10 | — |
| TC-5.3-002 | Remainder logic $100.01 → $50.01/$50.00 | **Pass** | — | QA | Nov 10 | — |
| TC-5.3-003 | Second charge declines, refund < 60s | **Pass** | DEF-5.3-042 (fixed Nov 5) | QA | Nov 10 | Retested after fix; now compliant |
| TC-5.3-004 | Single-card control $50 | **Pass** | — | QA | Nov 10 | Regression verified |
| TC-5.3-005 | Edge case $1 → $0.01/$0.99 | **Pass** | — | QA | Nov 10 | — |
| TC-5.3-006 | Race condition: refund vs. second charge | **Pass** | — | Dev/QA | Nov 10 | Pair test; timing validated |
| TC-5.3-007 | Split with network latency | **Pass** | — | QA | Nov 6 | Analysis case; timeout handled correctly |
| ... (24 more analysis + regression cases) | ... | **Pass (23/24)** | One P1: DEF-5.3-055 (closed Nov 9) | QA | Nov 6–10 | 1 case deferred (exploratory edge case, low risk) |

**Not Run — Resume Point:**
- TC-5.3-031 (Exploratory: concurrent split payments, same order) — Low risk; data collision edge case. Deferred to 5.4 or post-release exploration. Owner: QA. Next action: Reprioritize in future release or close as "won't fix" with stakeholder approval.

---

## 11. Retrospective & Lessons Learned (Post-Release)

**Conducted:** 1 week post-release (Nov 17, 2026)

**Attendees:** Dev team (2), QA (1), Test Lead, Product Owner

**Topics:**
1. **What went well:** PayGate sandbox windows scheduled optimally; pair testing (dev + QA) caught race condition early; risk register helped prioritize work.
2. **What was challenging:** 54-hour estimate vs. 40-hour capacity required scope trade-offs; exploratory testing cut short.
3. **What to improve next time:** Allocate 1.5x QA hours for payment features (56 hrs suggested for next release); sandbox access window could be Tue/Thu/Sat if possible.
4. **Action items:** (1) Automate single-card regression suite to reduce manual test burden by 50%. (2) Document PayGate sandbox quirks in runbook for next team.

---

**End of Test Plan**
