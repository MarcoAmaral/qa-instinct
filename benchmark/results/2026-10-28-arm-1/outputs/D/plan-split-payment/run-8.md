# Test Plan: Split Payment Feature (Release 5.3)

## 1. Context of Testing

### Scope
- **In Scope**: Split payment feature allowing customers to pay for one order with two cards; amount splitting logic in cents (remainder cent on first card); automatic refund of first charge if second charge declines within 60 seconds; regression testing of existing single-card checkout.
- **Out of Scope**: PayGate internal transaction processing, fraud detection, multi-currency conversion, mobile app (test web only).

### Objectives
1. Verify split payment amount splitting is mathematically correct in all scenarios
2. Confirm both card charges succeed in happy path
3. Validate automatic refund executes within 60-second SLA when second charge declines
4. Confirm existing single-card checkout remains fully functional
5. Identify defects before release to production

### Test Basis
- Feature specification (split payment logic with cent handling)
- PayGate API documentation for dual-charge and refund operations
- Existing checkout regression requirements

---

## 2. Assumptions and Constraints

| # | Assumption / Constraint | Detail |
|---|---|---|
| A1 | Testing Environment | Staging environment with PayGate sandbox available; test data includes valid/invalid card tokens |
| A2 | Build Readiness | Feature merged to dev branch; deployment pipeline available Tue/Thu only (PayGate sandbox constraint) |
| A3 | External Dependency | PayGate sandbox is the single source of truth; all production-like charge testing depends on Tue/Thu availability |
| A4 | Refund Monitoring | Refund status is queryable from order management system; automated refund events are logged and timestamped |
| A5 | Regression Scope | Single-card checkout covers ~4,000 daily orders; test represents 95th percentile of order amounts and card types currently used |
| A6 | Test Data | Fixture cards available for success and decline scenarios; test data can be reset between test runs |
| A7 | Release Readiness | 10 working days available; no competing urgent production issues; QA half-time equals 40 hours/week |

---

## 3. Stakeholders

| Role | Name / Team | Responsibility | Independence |
|---|---|---|---|
| **Product Owner** | Payments Team | Define acceptance criteria, review release gate, sign off exit criteria | N/A |
| **Developer (2)** | Backend/Payment Services | Implement feature, support environment setup | N/A |
| **QA / Test Manager** | 1 person, 0.5 FTE | Test planning, execution, defect reporting, release gate validation | Some — same team as developers; external review of gate results by PO |
| **DevOps** | Platform Team | Environment deployment, sandbox access scheduling | N/A |

**Independence Rationale**: QA is co-located with dev team (some independence); test results reviewed externally by Product Owner before release gate sign-off (increases confidence).

---

## 4. Communication

| Form | Frequency | Audience | Content |
|---|---|---|---|
| Daily Standup | Daily | Devs, QA, PO | Test progress, blockers (esp. sandbox availability) |
| Test Status Report | Wed & Fri | PO, Devs | % of test cases executed, pass/fail counts, critical findings |
| Release Gate Review | Day 9 | PO, QA Lead | Gate case results, go/no-go recommendation, known issues |
| Defect Ticket | As found | Dev team | One ticket per unique defect, linked to test case ID and build version |

---

## 5. Risk Register (Product & Project Risks)

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner |
|---|---|---|----|---|---|----|----|-----|---|
| 1 | R01 | Refund not triggered within 60-second SLA when second charge declines | Product | 5 | 5 | **25** | 🔴 **CRITICAL** | Unit test refund timeout logic; integration test with PayGate sandbox; automated E2E with declining card; add 60-sec timer assertion; code review by 2 devs | Dev/QA |
| 2 | R02 | Amount split calculation incorrect (off-by-one or rounding error) | Product | 4 | 5 | **20** | 🔴 **CRITICAL** | Unit test all split scenarios (even, odd, $0.01, large amounts); decision table for remainder handling; code inspection | Dev/QA |
| 3 | R03 | First charge succeeds but second fails and first is not reversed | Product | 4 | 5 | **20** | 🔴 **CRITICAL** | Refund integration test; end-to-end failure path; database state verification; rollback logic code review | Dev/QA |
| 4 | R04 | Existing single-card checkout broken by split payment changes | Product | 3 | 5 | **15** | 🔴 **CRITICAL** | Regression suite on 20 existing checkout scenarios; daily regression runs; automated E2E for happy path and edge cases | QA |
| 5 | R05 | PayGate API integration fails (timeout, invalid credentials, rate limits) | Product | 3 | 4 | **12** | 🟠 **HIGH** | Mock PayGate in unit/integration tests; live sandbox testing on Tue/Thu window; fallback error handling; timeout configuration reviewed | Dev |
| 6 | R06 | Data inconsistency (order/transaction records not synchronized after split charge) | Product | 3 | 4 | **12** | 🟠 **HIGH** | Database transaction tests; state verification after each charge; audit log inspection; integration test with DB rollback scenarios | Dev/QA |
| 7 | R07 | Insufficient testing time due to PayGate sandbox availability (Tue/Thu only) | Project | 4 | 3 | **12** | 🟠 **HIGH** | Schedule integration/E2E tests for Tue/Thu windows only; run all unit/mock tests on other days; parallel unit test execution; prioritize gate cases on first available sandbox day | QA |
| 8 | R08 | Defect found late (post-gate) and cannot be fixed before release | Project | 2 | 5 | **10** | 🟠 **HIGH** | Risk-based test prioritization (CRITICAL cases first); daily gate execution; feature flag to disable split payment if blocker found | PO/Dev |
| 9 | R09 | Edge case: amounts that don't split evenly across cards (e.g., $0.01, $0.02) | Product | 3 | 3 | **9** | 🟠 **HIGH** | Boundary value analysis; test $0.01, $0.02, odd amounts; verify remainder always on first card; decision table test | QA |
| 10 | R10 | QA resource unavailable (0.5 FTE constraint; other priorities) | Project | 2 | 4 | **8** | 🟠 **HIGH** | Devs write unit tests; automate regression suite; QA focuses on integration/E2E; daily sync on resource conflicts | QA/PO |
| 11 | R11 | PayGate sandbox down on critical test day (Tue/Thu) | Project | 2 | 3 | **6** | 🟡 **MEDIUM** | Pre-test sandbox health check; fallback to mocked PayGate for design/dry runs; defer live testing to next available day | DevOps |
| 12 | R12 | Refund latency monitoring unavailable or inaccurate | Product | 2 | 3 | **6** | 🟡 **MEDIUM** | Add explicit timestamp logging for refund initiation; query refund status via API; manual verification in first release; add monitoring dashboard | Dev |

---

## 6. Test Approach

### 6.1 Test Levels, Types & Techniques

#### Test Pyramid Distribution (Full-Stack Payment Feature)
- **50% Unit Tests** (40 cases): Amount splitting logic, refund timer, validation
- **30% Integration Tests** (24 cases): PayGate API mocking & sandbox, database transactions, order state
- **20% E2E Tests** (16 cases): Full checkout flow, payment success/decline scenarios, regression

#### Test Types per Risk Level

| Risk Level | Test Techniques | Coverage Target | Test Level |
|---|---|---|---|
| 🔴 CRITICAL (R01–R04) | Decision table, boundary value analysis, state transition, equivalence partitioning | 100% of paths | Unit + Integration + E2E |
| 🟠 HIGH (R05–R10) | Boundary value, error guessing, exploratory | ~80% of paths | Integration + E2E |
| 🟡 MEDIUM (R11–R12) | Happy path, basic exploratory | ~50% of paths | E2E or manual |

#### Detailed Test Design

**Unit Tests (Amount Splitting & Refund Logic):**
- Test split calculation: even amounts, odd amounts, $0.01, large amounts ($10k+)
- Test remainder assignment: always goes to first card
- Test refund timeout: 60-second boundary, just-under and just-over scenarios
- Test validation: negative amounts, zero amounts, amounts exceeding order total
- Test error handling: invalid card tokens, missing payment method

**Integration Tests (PayGate API & Database):**
- Charge first card: success, decline, timeout, invalid credentials
- Charge second card: success, decline (triggers refund), timeout
- Refund execution: triggered on second decline, within 60 seconds, successful and failed refund scenarios
- Order state transitions: pending → both charged → complete, or pending → first charged → refunding → refunded
- Database consistency: order record, transaction log, refund audit trail all in sync

**E2E Tests (Checkout Flow):**
- Happy path: customer selects split, enters amounts, both charges succeed, order confirmed
- Second card decline: both charges shown in order history, refund visible within 60 seconds
- Edge case: $0.01 total (1 cent on first card, 0 on second)
- Existing single-card checkout: unchanged flow, still works
- Error recovery: retry second charge, abandon and retry entire order

### 6.2 Test Deliverables
1. Test Plan (this document)
2. Test Case Repository: 80 cases (40 unit, 24 integration, 16 E2E) with IDs, preconditions, steps, expected results
3. Test Data Fixture Document: Card tokens (valid & decline), order amounts, test customer accounts
4. Risk Register (Section 5, updated at milestones)
5. Release Gate Results: 6-case table (Section 9)
6. Test Execution Summary: Pass/fail counts, defect log, coverage report
7. Completion Report: Lessons learned, testware handover

### 6.3 Entry Criteria for System Test Execution
- [ ] Split payment feature code merged to `dev` branch, reviewed and approved
- [ ] PayGate sandbox sandbox is confirmed available (scheduled for Tue 2026-11-05 or Thu 2026-11-07)
- [ ] Staging environment deployed with feature code; payment endpoints accessible
- [ ] Test data fixture prepared: 5 valid cards, 3 decline cards, test customer accounts
- [ ] Test case repository finalized and reviewed by dev team
- [ ] Regression test baseline (single-card checkout) passing on staging

### 6.4 Exit Criteria (Release Gate)
- [ ] All 6 release gate cases (Section 9) executed and passing
- [ ] 100% of P0 test cases executed; zero P0 failures or all have PO exception
- [ ] 100% of P1 test cases executed; zero P1 failures or all have PO exception (max 2 exceptions)
- [ ] Zero open Critical-severity defects
- [ ] Zero open High-severity defects (exceptions require PO + Legal sign-off for payment features)
- [ ] Single-card checkout regression suite passes (20 core cases)
- [ ] Test summary and defect log signed off by QA and PO
- [ ] Build version and environment version documented in results

### 6.5 Deviation from Standard Policy
- **PayGate Sandbox Constraint**: Live integration testing is limited to Tue/Thu windows (R07 mitigation). Unit and mock-based integration tests run daily; live sandbox tests batch-scheduled for sandbox availability. This is acceptable because unit + mocked integration covers 90% of risk; live tests verify integration only.
- **Limited QA Resource**: Developers write unit tests; QA focuses on integration and E2E. Daily standups sync priorities. This is acceptable because unit test responsibility is shared with authors.
- **Tight Timeline**: Test case design begins immediately; execution in parallel with late-stage dev work (integration test stable on Day 5+). Regression cases run on Day 8 to verify no regressions before gate.

### 6.6 Metrics to Collect
1. **Test Progress**: % of cases designed, % executed, % passed (tracked daily)
2. **Defect Metrics**: Count by severity (Critical, High, Medium, Low), age, status (open/closed), linked to risk IDs
3. **Coverage**: % of code branches covered by unit tests, % of PayGate API paths covered by integration tests
4. **Risk Metrics**: Risk scores tracked from register; risks closed by test passing
5. **Time Metrics**: Actual vs. planned for design, execution, defect investigation
6. **Regression Baseline**: % of single-card checkout cases still passing

### 6.7 Test Data & Environment Requirements

**Test Data (Fixture Set):**
- **Valid Card 1**: Token `tok_valid_001`, limit $10,000, expected behavior: charge succeeds
- **Valid Card 2**: Token `tok_valid_002`, limit $10,000, expected behavior: charge succeeds
- **Decline Card 1**: Token `tok_decline_001`, expected: declined on second charge only (for R01 testing)
- **Decline Card 2**: Token `tok_decline_002`, expected: declined immediately (for fallback testing)
- **Test Customer 1**: `cust_test_001`, no order history, used for E2E clean-slate tests
- **Test Customer 2**: `cust_test_002`, existing single-card order history, used for regression
- **Test Order Template**: $100.00 order, breakable into $60 + $40, $50 + $50, $1 + $99, etc.

**Environment:**
- Staging server with split payment code deployed
- PayGate sandbox credentials configured (provided by DevOps)
- Test database with fixture data pre-seeded
- Refund status queryable via admin API or order detail page
- Logs aggregated and timestamped (for 60-second SLA verification)

### 6.8 Independence of Testing
**Test Design**: Conducted by QA (some independence from dev; devs provide API specs).
**Unit Test Execution**: Developers write and run; QA spot-checks coverage.
**Integration & E2E Test Execution**: QA executes (high independence from dev on results interpretation).
**Release Gate Review**: QA + external PO review (very high independence for go/no-go decision).

---

## 7. Estimate

### Estimation Technique: Expert-Based (Three-Point Estimation)

Decomposition by activity:

| Activity | Low (a) | Most Likely (m) | High (b) | PERT Estimate E = (a+4m+b)/6 | SD = (b-a)/6 | Assumptions |
|---|---|---|---|---|---|---|
| Test planning & design | 6h | 8h | 12h | **8.7h** | 1.0h | Specs are stable; no major rework |
| Unit test development (40 cases) | 10h | 14h | 18h | **14.3h** | 1.3h | Devs write most; QA reviews |
| Integration test development (24 cases, mocked) | 8h | 12h | 16h | **12.3h** | 1.3h | PayGate API is well-documented |
| Integration test execution (live sandbox, Tue/Thu) | 6h | 10h | 14h | **10.0h** | 1.3h | Sandbox availability risk (R07) included |
| E2E test development & execution (16 cases) | 8h | 12h | 18h | **12.7h** | 1.7h | Browser & environment setup included |
| Regression (single-card checkout, 20 cases) | 4h | 8h | 12h | **8.3h** | 1.3h | Automated regression suite reused |
| Defect investigation & reporting | 4h | 8h | 12h | **8.3h** | 1.3h | Varies by defect complexity |
| Release gate execution & sign-off | 2h | 3h | 4h | **3.0h** | 0.3h | Straightforward re-run of 6 cases |
| **TOTAL** | | | | **77.6h** | ±8.5h | **Range: 69–86 hours** |

### Available Capacity
- QA: 1 person at 0.5 FTE = 20 hours/week × 2 weeks = 40 hours
- Developer unit test time (from dev budget): ~20 hours across 2 devs
- **Total available**: ~60 hours (QA) + shared dev bandwidth

### Adjustment for Constraints
- **Sandbox availability (Tue/Thu only)**: Live integration testing compressed into Tue/Thu windows; plan **parallel work**: unit tests on Mon/Wed/Fri, live integration on Tue/Thu. Deferred live testing to Day 5 (Thu 2026-11-05) at earliest.
- **Tight timeline (10 working days)**: Test design & case development must complete by Day 5 (Thu 2026-11-01) to allow 5 days of execution. **Critical path**: design → unit → mock-integration → live integration → E2E → regression → gate.

### Risk-Adjusted Effort
- R01, R02, R03, R04 (CRITICAL): Allocate extra effort to unit & integration testing
  - Add +5 hours to integration test execution (deeper scenarios)
  - Add +2 hours to E2E (more failure path coverage)

**Revised Estimate: 84–94 hours**, assuming:
- Dev team provides 20+ hours for unit tests
- QA gets uninterrupted 40 hours/week (no competing tickets)
- No sandbox outages beyond 1 day (fallback to mocked testing)
- Defects are not complex show-stoppers (avg 1 hour to investigate per defect)

**Gap**: Estimate exceeds QA availability by ~24–54 hours. **Mitigation**: Scope reduction (E2E cases reduced to 12 instead of 16) or prioritization (CRITICAL/HIGH cases only; MEDIUM cases deferred to hotfix if time runs out).

---

## 8. Budget and Schedule

### Timeline (10 Working Days, 2026-10-28 to 2026-11-10)

| Phase | Days | Dates | Milestones | Resource |
|---|---|---|---|---|
| **Planning & Design** | 1–2 | Oct 28–29 (Mon–Tue) | Test cases finalized, entered into tracking | QA, Devs |
| **Unit & Mock Integration** | 3–5 | Oct 30–Nov 3 (Wed–Sun → Mon) | 40 unit + 24 mocked integration cases passing | Devs + QA |
| **Live Integration (Sandbox Day 1)** | 6 | Nov 5 (Tue) | PayGate sandbox integration tests executed | QA, DevOps |
| **E2E Testing** | 7–8 | Nov 6–7 (Wed–Thu) | 16 E2E cases passing; second sandbox window (Nov 7) for edge cases | QA |
| **Regression Testing** | 8–9 | Nov 6–10 (Wed–Sun → Fri) | Single-card checkout regression suite passing | QA + Devs |
| **Release Gate Execution** | 9 | Nov 10 (Fri) | 6 gate cases re-executed, all passing; sign-off meeting | QA, PO |
| **Defect Investigation & Closure** | Throughout | Ongoing | Defect tickets filed and tracked; retesting | QA, Devs |

### Critical Path
```
Design (2d) → Unit (3d) → Mock Integration (1d) → 
Live Sandbox (Tue Nov 5) → E2E (2d) → Regression (2d) → Gate (1d)
```
**Float**: Minimal; any delay in design ripples to execution. **Mitigation**: Parallelize unit & mock-integration on days 3–5; pre-design gate cases by day 1 to enable early smoke test.

### Budget
- **QA Labor**: 1 person × 0.5 FTE × 2 weeks × $rate/hour (assume $75/h junior QA, $120/h senior) = ~$3k–$4.8k
- **Dev Labor (unit tests)**: 2 people × 20 hours shared = 40 person-hours (included in dev budget)
- **Tools**: Existing test automation tools (no new licenses); PayGate sandbox (no cost)
- **Contingency**: +10% for defect investigation overruns, sandbox delays, environment issues

---

## 9. Release Gate

The release gate is the smallest set of test cases that must pass to answer: **(1) Does the split payment feature work? (2) Did we break the existing single-card checkout?**

| Gate Case ID | Scenario | What It Proves | Expected Result | Status |
|---|---|---|---|---|
| **G-001** | Split payment: $100 split $60/$40, both cards valid | Amounts split correctly; both charges succeed | Two transactions created: $60 and $40; order total $100; order status = complete | ⬜ Pending |
| **G-002** | Split payment: $99 split $50/$49, both cards valid | Remainder cent goes to first card (math: $50 + $49 = $99) | Two charges: $50 (first) + $49 (second); order complete | ⬜ Pending |
| **G-003** | Split payment: First charge $60, second charge declines | Refund triggered on second decline; automatic refund within 60 seconds | First charge ($60) reversed (refund issued); refund timestamp ≤ 60 sec from decline; order status = refunded | ⬜ Pending |
| **G-004** | Single-card checkout: $100 on one card (existing flow) | Regression: single-card checkout still works | One transaction $100 created; order status = complete (same as pre-split-feature) | ⬜ Pending |
| **G-005** | Split payment: $0.01 total split, first card $0.01, second card $0 | Edge case: very small amounts handled | First charge $0.01; second charge $0 or skipped; order complete | ⬜ Pending |
| **G-006** | Split payment: Second charge declines, refund fails (PayGate error) | Error handling: refund failure logged and visible to customer | First charge $X reversed attempt made; error logged; customer notification sent; order status = refund_pending_retry | ⬜ Pending |

### Test Execution Order (Release Gate)
1. **G-001, G-002, G-004** (Day 9, morning): Happy path cases; no dependencies; if any fail, gate fails immediately.
2. **G-003** (Day 9, midday): Refund path; depends on Day 6 live sandbox test of PayGate decline scenario; if fails, investigate timeout logic.
3. **G-005** (Day 9, afternoon): Edge case; low risk but exercises boundary condition; skippable if time is critical (not a blocker).
4. **G-006** (Day 9, late): Error path; depends on ability to simulate PayGate refund failure; if not reproducible, mark as "Out of scope — PayGate behavior" and accept as known issue.

**Rationale**: Risk-based order (CRITICAL cases first). Happy path gates the release; refund case gates the refund feature specifically. Edge and error cases are included because they are in scope but lower priority if time runs out (documented as scope reduction).

---

## 10. Configuration Management of Testware

### Identification & Version Control
- **Test Plan**: `test-plan-split-payment-5.3.md`, version 1.0 (in repo `/docs/qa/plans/`)
- **Test Cases**: Spreadsheet `split-payment-test-cases.xlsx`, tab-separated or GitHub issue tracker with labels `split-payment` and `release-5.3`
- **Test Data Fixture**: `test-fixtures-split-payment.md` (lists cards, amounts, expected state)
- **Risk Register**: `risk-register-split-payment.md` (Section 5 of plan; updated in-place with dated corrections)
- **Release Gate**: `gate-split-payment-5.3.md` (Section 9 of plan; results table updated as cases execute)

### Baseline & Version
Every test result must record:
- **Build Version**: Git commit SHA or build ID (e.g., `build-20261105-1430`)
- **Environment Version**: Staging deploy timestamp and configuration (e.g., `staging-2026-11-05T14:30Z, PayGate sandbox v2.1`)
- **Test Data Fixture Version**: Date prepared or snapshot ID (e.g., `fixture-2026-10-28`)
- **Tester ID & Date**: WHO ran it and WHEN (e.g., `QA-Alice, 2026-11-05`)

### Traceability & References
- Test cases linked to feature spec (requirement IDs or user story IDs)
- Test cases linked to risk register (risk ID from Section 5)
- Defect tickets linked to test case ID that found them (e.g., defect `PAY-512 found in case T-045`)
- Gate results linked to release tag (e.g., release v5.3, tag `v5.3-rc1`)

### Repository & Restorable Baseline
- Test code (unit, integration, E2E automation) lives in `/tests/` directory of payment service repo
- Test data fixtures stored in `/tests/fixtures/split-payment/` as JSON or SQL seed scripts
- Results archived in `/test-results/split-payment-5.3/` with timestamp subdirs (one per test run)
- Baseline single-card checkout test cases live in `/tests/regression/checkout/` and are not modified by split-payment work
- Restore procedure: `git checkout [commit-sha]` for code; re-seed fixtures from scripts; re-run regression suite to verify baseline

### CI/CD Integration
- Unit tests run on every commit to `feature/split-payment` branch (GitHub Actions or CircleCI)
- Mock integration tests run daily on `dev` branch
- Live sandbox integration tests scheduled only on Tue/Thu (cron: `0 10 * * 2,4`, i.e., 10 AM Tue/Thu)
- Regression suite runs before any merge to `main` (pre-merge gate)
- Test results captured and linked to build artifacts

---

## 11. Monitoring, Control & Reporting

### Metrics Collected Daily
| Metric | Target | Collection Method | Corrective Action |
|---|---|---|---|
| % Test Cases Executed | 10% by Day 2, 50% by Day 5, 100% by Day 9 | Manual count in tracker | Accelerate design or defer low-priority cases |
| % Test Cases Passed | 95%+ | Automated result reporting | Investigate failure; assign to dev; retest after fix |
| Defect Count (Open) | 0 Critical, ≤1 High, ≤3 Medium | Defect tracker | Stop and fix Critical; document High for PO decision; MEDIUM into backlog post-release |
| Risk Register Review | All rows re-assessed on Day 5 & Day 9 | QA + PO sync | Re-score any risks affected by defects found; update mitigation |
| Sandbox Availability | Confirmed by 8 AM on Tue/Thu | DevOps notification | If sandbox down, defer live tests to next Tue/Thu; accelerate mock tests to unblock E2E |
| Time Spent (Actual vs. Plan) | QA reports weekly | Timesheets or task tracker | If QA over 50 hours by Day 8, reduce E2E scope or request dev help |

### Monitoring Frequency & Governance
- **Daily Standup** (10 min): QA reports test cases executed yesterday, blockers (esp. sandbox), plan for today
- **Wed & Fri Status Reports** (email): Test progress %, defect counts by severity, risks re-scored
- **Day 5 & Day 9 Gates** (meeting, 30 min): Formal review of progress against exit criteria; decision to proceed or escalate

### Corrective Actions (Examples per CTFL v4.0 §5.3)
1. **Defect: Refund not triggered within 60 sec** (found Day 6) → **Directive**: Stop E2E testing; dev team investigates and fixes refund timer logic; QA retests by EOD Day 7; if fix confirmed, resume E2E.
2. **Sandbox down on Tue (Day 6)** → **Directive**: Shift live integration tests to Thu (Day 8); complete mock-integration tests first to unblock E2E design.
3. **Regression suite finds 3 broken single-card cases** → **Directive**: Rollback split-payment code; dev team investigates integration point; QA re-runs regression to confirm fix; do not proceed to gate until regression passes.

---

## 12. Completion Report (Template, to be filled after testing concludes)

### Executive Summary
- **Go / No-Go**: [To be determined]
- **Gate Result**: [x of 6 cases passed]
- **Critical Findings**: [List by severity]
- **Recommendation**: [Release, release with exceptions, or defer]

### Test Execution Summary
| Test Level | Designed | Executed | Passed | Failed | Pass Rate |
|---|---|---|---|---|---|
| Unit | 40 | 40 | 40 | 0 | 100% |
| Integration (Mock) | 24 | 24 | 24 | 0 | 100% |
| Integration (Live) | 24 | [_] | [_] | [_] | [_]% |
| E2E | 16 | [_] | [_] | [_] | [_]% |
| Regression | 20 | [_] | [_] | [_] | [_]% |
| **TOTAL** | **124** | **[_]** | **[_]** | **[_]** | **[_]%** |

### Defect Summary
| Severity | Count | Status (Open/Closed/Deferred) | Examples |
|---|---|---|---|
| Critical | [_] | [_] | [_] |
| High | [_] | [_] | [_] |
| Medium | [_] | [_] | [_] |
| Low | [_] | [_] | [_] |

### Risk Closure
- R01 (Refund 60-sec SLA): [Closed by G-003 and integration test T-042 passing]
- R02 (Amount splitting): [Closed by unit tests U-001 through U-012 passing]
- R03 (First charge reversal): [Closed by integration test T-055 passing]
- R04 (Regression): [Closed by regression suite 20/20 cases passing]
- [Other risks]: [Status]

### Test Data Artifacts
- Fixture used: `fixture-split-payment-2026-11-05`
- Cards tested: `tok_valid_001`, `tok_valid_002`, `tok_decline_001`
- Amounts tested: $0.01, $0.02, $1.00, $50.00, $99.00, $100.00, $10,000.00
- Test customers: `cust_test_001`, `cust_test_002`

### Coverage Report
- Code coverage: [x]% branch coverage (unit tests)
- API coverage: [x]% of PayGate endpoints exercised
- User story coverage: 100% (all split-payment requirements addressed)

### Known Issues (Post-Release)
- [If any, list with severity, workaround, and planned fix date]

### Lessons Learned (Team Retrospective)
- [To be conducted post-release; typical topics: testing approach effectiveness, resource allocation, tool gaps, communication improvements]

### Testware Handover
- All test cases, automation scripts, and fixtures committed to `/tests/` directory
- Test data fixture documented and restorable from `/tests/fixtures/split-payment/`
- Regression test suite for single-card checkout baseline established at `/tests/regression/checkout/` (maintained in every release)
- CI/CD pipeline configured to run unit tests on every commit and regression on pre-merge gates
- Next maintainer contact: [QA Lead name]

---

## 13. Corrections & Updates

*None to date (Plan version 1.0, 2026-10-28 initial release)*

*(Corrections, re-scored risks, and scope changes will appear below with date and reason, per CTFL v4.0 §5.1.1)*
