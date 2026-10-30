# Test Plan: Split Payment Feature (Release 5.3)

## 1. Context of Testing

**Scope**: Release of split payment functionality enabling customers to pay a single order with two cards. Feature must integrate with external PayGate payment gateway and include automatic refund of the first charge if the second charge is declined. The existing single-card checkout must remain functional and unaffected.

**Objectives**:
- Verify split payment flow works correctly with two cards and accurate amount division
- Verify automatic refund logic triggers within 60 seconds when second charge is declined
- Verify remainder cent handling (odd amounts) places extra cent on first card
- Maintain zero regression on existing single-card checkout (4,000 orders/day volume)
- Confirm PayGate integration is stable and error handling is correct

**Test Basis**:
- Feature requirements: two-card split, amount division, remainder cent rule, 60-second refund SLA
- PayGate API documentation and sandbox contract
- Existing single-card checkout specification

---

## 2. Assumptions and Constraints

**Assumptions**:
- Release date is 2026-11-11 (10 working days from today, 2026-10-28)
- PayGate sandbox environment will be available and stable every Tuesday and Thursday as scheduled
- Split payment feature code is fully implemented and integrated with PayGate API by Day 1
- Refund API endpoint is implemented and available for testing by Day 2 (2026-10-30)
- Test environment mirrors production PayGate integration configuration
- Single-card checkout code is stable with no concurrent changes during this release cycle
- The one tester has 20 hours per week available (100 hours total over the 10-day cycle)
- Developers can provide test data, fixture reset, and API troubleshooting on demand
- No dedicated QA environment or DevOps support exists; coordination is through the developer team

**Constraints**:
- PayGate sandbox available only Tuesdays and Thursdays (2 days per week)
- One tester at 50% capacity + two developers (limited human resources)
- Must not disrupt or block the existing 4,000 daily single-card orders
- 10 working days to release (tight timeline with sandbox blackout windows)

---

## 3. Stakeholders

| Role | Name/Team | Responsibility | Independence |
| --- | --- | --- | --- |
| Product Owner | [PO] | Approve requirements, sign off exit criteria and defect exceptions | External to QA |
| Development Team | [2 Developers] | Implement feature, provide test data, debug PayGate API issues | Peers; some independence for QA review |
| QA Lead / Tester | [1 Tester] | Test planning, analysis, design, execution, reporting; gate sign-off | High independence (dedicated role) |
| DevOps / Environment | [Dev Team covering] | Environment setup, deployment, baseline management | External; on-demand support |

---

## 4. Communication

**Forms & Frequency**:
- **Daily standup** (15 min): Development team + tester; blockers, PayGate sandbox status, test progress
- **Progress report** (every 2–3 days): Brief status on gate case execution, open defects, timeline risk
- **Final sign-off** (Day 10): Gate results, regression status, defect summary, sign-off from QA and PO

**Document templates**:
- Test case template: ID | Title | Precondition | Steps | Expected Result | Status | Build/Env
- Defect template: ID | Title | Severity | Reproducible | Root Cause | Status | Linked Test Case
- Gate report: Case ID | Purpose | Result | Build/Env | Timestamp

---

## 5. Risk Register (Product & Project Risks)

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | R01 | Remainder cent logic incorrect; odd amounts not split per spec (e.g. $100.01 splits to $60.00 & $40.01 instead of $60.01 & $40.00) | Product | 3 | 5 | 15 | 🔴 CRITICAL | Unit tests on split logic + boundary value test cases; manual verification of edge amounts | Dev / QA |
| 2 | R02 | First charge succeeds, second charge declined, but refund does not trigger or exceeds 60s SLA | Product | 2 | 5 | 10 | 🟠 HIGH | Integration test with PayGate mock decline scenario; timer test; refund API contract review | Dev / QA |
| 3 | R03 | PayGate API timeout, error response, or rate limiting not handled; feature fails silently or crashes | Product | 3 | 4 | 12 | 🟠 HIGH | Error path tests; timeout simulation; API mock for degraded scenarios; decision table for all PayGate response codes | Dev / QA |
| 4 | R04 | Single-card checkout regression; existing functionality broken by split payment changes | Product | 2 | 5 | 10 | 🟠 HIGH | Regression suite on single-card flow; canary test on sample of daily orders; code review of shared paths | QA / Dev |
| 5 | R05 | Race condition: user cancels order or closes browser during refund processing; refund state corrupted | Product | 2 | 4 | 8 | 🟠 HIGH | State transition tests; concurrent operation scenarios (manual + automation); session timeout handling | Dev / QA |
| 6 | R06 | Edge case coverage gaps; decimal rounding, validation, boundary amounts not tested | Product | 3 | 3 | 9 | 🟠 HIGH | Equivalence partitioning (small/medium/large amounts); decision table for card combinations; boundary value analysis | QA |
| 7 | P01 | Insufficient test time due to 10-day cycle + PayGate sandbox 2-day-per-week availability window | Project | 4 | 3 | 12 | 🟠 HIGH | Front-load unit & mock integration tests (Days 1–4); defer exploratory to Days 5–8 if sandbox delayed; define minimum gate-only scope for Day 10 | QA / PO |
| 8 | P02 | Tester's 50% capacity (20 hrs/week) insufficient; estimate 83 hours; risk of incomplete coverage or late nights | Project | 3 | 3 | 9 | 🟠 HIGH | Involve developers in test execution (smoke + edge cases); automate repetitive sandbox tests; time-box exploratory to 10 hours | QA / Dev |
| 9 | P03 | Late discovery of PayGate API incompatibility or undocumented behavior; rework required | Project | 2 | 4 | 8 | 🟠 HIGH | Early API integration test (Day 2); API contract review with PayGate docs before Day 3; mock fallback for sandbox delays | Dev |
| 10 | P04 | Refund API not implemented or unstable by test start; blocks 50% of test scenarios | Project | 2 | 5 | 10 | 🟠 HIGH | Refund API ready by Day 2, EOD (gate criteria); fallback: mock refund endpoint to proceed with design; track API stability in daily standup | Dev |
| 11 | R07 | PayGate sandbox unavailable or unstable on scheduled Tues/Thurs; cannot test against real API | Project | 2 | 3 | 6 | 🟡 MEDIUM | Mock PayGate API with comprehensive error scenarios; run happy-path sandbox tests on both Tues & Thurs; fallback to staging if available | Dev / QA |
| 12 | R08 | Manual testing of concurrent multi-card payments misses race conditions or timing issues | Product | 2 | 3 | 6 | 🟡 MEDIUM | State machine tests (automation); load test with concurrent orders (if capacity allows); focus manual on refund race scenarios | QA / Dev |
| 13 | R09 | Test data contamination or insufficient test card fixtures; unable to run repeat cycles | Project | 2 | 2 | 4 | 🟡 MEDIUM | Document fixture set (test card numbers, states, reset procedures); use PayGate sandbox test cards only; restore fixtures between test cycles | QA / Dev |

---

## 6. Test Approach

**Test Levels & Distribution** (Payment processing feature—financial criticality):
- **Unit Tests (50%)**: Split logic, rounding, validation, refund calculation
- **Integration Tests (30%)**: PayGate API calls (mock + sandbox), refund endpoint, order state transitions
- **System/E2E Tests (20%)**: Full checkout flow, two-card flow, decline + refund, regression on single-card

**Test Types**:
- **Functional**: Amount split correctness, remainder cent rule, refund trigger, payment flow
- **Integration**: PayGate API contract compliance, error responses, refund API
- **Regression**: Single-card checkout; existing checkout flows; order history
- **Non-functional**: Refund SLA (60s timer), error message clarity, API timeout handling
- **Exploratory**: Edge cases, unusual card combinations, network degradation, user cancellation scenarios

**Test Techniques**:
- **Boundary Value Analysis**: Split amounts at boundaries ($0.01, $99.99, $100, $999.99), remainder cent cases
- **Equivalence Partitioning**: Small amounts ($1–$10), medium ($10–$100), large ($100–$999.99); split ratios (50/50, 30/70, 1/99)
- **Decision Tables**: First card success/decline × Second card success/decline → 4 scenarios (gate: 2 of 4)
- **State Transition**: Payment states (pending → charged → completed/refunded); refund state (pending → refunded/failed)
- **Error Guessing**: PayGate timeouts, invalid card, network errors, duplicate requests, race conditions

**Test Deliverables**:
- Test plan (this document)
- Test case suite (gate cases + P0/P1 cases, tracked in issue system)
- Fixture set document (test cards, reset procedures, fixture states)
- Regression suite baseline (single-card checkout critical paths)
- Daily progress reports (gate case status, blockers, defect summary)
- Completion report (all case results, coverage metrics, defect summary)

**Entry Criteria (When to START Testing)**:
- [ ] Split payment feature code merged to release branch, compiling with zero errors
- [ ] PayGate API integration implemented and code-reviewed
- [ ] Refund API endpoint implemented and accessible in test environment
- [ ] Test environment deployed and verified accessible
- [ ] PayGate sandbox credentials configured and sandbox connectivity confirmed
- [ ] Test card fixtures available and reset procedure documented
- [ ] Single-card checkout passing smoke test (sanity check for regression risk)

**Exit Criteria (When to STOP & RELEASE)**:
- [ ] All release gate cases (7 cases below) executed and passing on final build
- [ ] 100% of P0 test cases executed and passing (split flow, refund flow, remainder cent)
- [ ] 100% of P1 test cases executed or each failure has documented Product Owner exception
- [ ] Zero open 🔴 CRITICAL defects
- [ ] Zero open 🟠 HIGH defects (or documented PO exception)
- [ ] Single-card checkout regression suite passing (sample of 50+ daily orders)
- [ ] Final build deployed to staging; gate re-run passing on staging build
- [ ] Test summary report signed off by QA Lead and Product Owner

---

## 7. Release Gate

**Purpose**: Confirm split payment feature works correctly, refund logic is reliable, and single-card checkout regression is acceptable.

| Gate Case | ID | Purpose | Expected Result | Status | Build | Env |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | G01 | Even split, both cards succeed | Two charges processed, both amounts correct, order complete | ⬜ | — | — |
| 2 | G02 | Odd amount ($100.01), remainder on first card | First card: $60.01, Second card: $40.00, both succeed | ⬜ | — | — |
| 3 | G03 | Second card declined, auto-refund within 60s | First charge reversed; refund confirmed in PayGate within 60 seconds; order marked refunded | ⬜ | — | — |
| 4 | G04 | Single-card checkout still works ($100 charge) | Single-card flow executes without error; amount matches; no regression | ⬜ | — | — |
| 5 | G05 | Validation: cannot split to $0 on either card | Error message displays; order not charged; validation prevents invalid split | ⬜ | — | — |
| 6 | G06 | Large amount ($999.99) split correctly | Split calculated accurately; both charges succeed; amounts sum to total | ⬜ | — | — |
| 7 | G07 | Regression: sample daily volume (50 single-card orders) | All orders process without error; no latency regression vs. baseline | ⬜ | — | — |

**Test Execution Order**: Risk-based (gate cases in order 1→7; 🔴 CRITICAL risks first). Days 5–8 (sandbox available Tue 11/05 and Thu 11/07) prioritized for PayGate-dependent cases (G01–G03). Regression case (G07) runs last on final build to confirm no regressions on Day 9–10.

---

## 8. Estimate

**Estimation Technique**: Three-point estimation (expert-based)

**Breakdown**:
- Test planning, analysis, design: 8 hours
- Unit & integration test setup (mocks, fixtures): 12 hours
- Test execution (gate + P0 + P1 cases): 45 hours
- Sandbox-dependent testing (PayGate live API): 12 hours
- Regression suite execution: 8 hours
- Defect triage, retesting, sign-off: 10 hours

**Three-Point Estimate**:
- Optimistic (a): 60 hours (PayGate stable, no major defects, mocks reusable)
- Realistic (m): 83 hours (typical sandbox delays, 2–3 high defects requiring retest)
- Pessimistic (b): 110 hours (PayGate API incompatibility, refund logic rework, tight deadline pressure)

**E = (a + 4m + b) / 6 = (60 + 4(83) + 110) / 6 = 560 / 6 ≈ 93 hours**
**SD = (b − a) / 6 = (110 − 60) / 6 ≈ 8 hours**

**Estimate Range**: **85–101 hours (68% confidence interval)**

**Assumptions for Estimate**:
- Tester available 20 hours/week = ~100 hours total capacity over 10 days
- Developers available 4–6 hours/week for support (test data, API fixes, troubleshooting)
- PayGate sandbox available as scheduled (Tues & Thurs)
- Refund API stable by Day 2; no mid-cycle architectural changes
- Single-card checkout regression suite already exists (reuse, no build from scratch)
- No show-stopping defects requiring feature redesign

**Risk**: Estimate is at 93 hours with 100 hours capacity; margin of 7 hours. If sandbox becomes unavailable or refund API delayed, scope must be reduced to gate-only (≈40 hours core testing).

---

## 9. Budget and Schedule

**Timeline**:

| Phase | Days | Dates | Activities | Sandbox Status | Deliverable |
| --- | --- | --- | --- | --- | --- |
| Planning & Design | 1–2 | Wed 10/30, Thu 10/31 | Test plan, test cases, fixture design, PayGate API review | Available Thu 10/31 | Test case suite; fixture set document; sanity test on dev |
| Dev Integration & Mocks | 3–4 | Fri 11/01, Mon 11/04 | Unit test review, mock PayGate setup, integration tests, refund API contract verification | Unavailable | Integration tests passing on mocks; dev build confirmed |
| Sandbox Testing (1st cycle) | 5–6 | Tue 11/05, Wed 11/06 | Gate cases G01–G06 on sandbox; edge cases; error scenarios | Available Tue 11/05; unavailable Wed | Progress report: gate status, defects logged |
| Sandbox Testing (2nd cycle) & Regression | 7–8 | Thu 11/07, Fri 11/08 | Repeat gate cases (retest if defects fixed), regression suite, exploratory | Available Thu 11/07; unavailable Fri | Progress report: regression status, defect summary |
| Final Validation & Sign-Off | 9–10 | Mon 11/11, Tue 11/12 | Re-run gate on final build, PO walkthrough, defect review, sign-off | Unavailable (release day) | Completion report; gate pass/fail; sign-off by QA & PO |

**Resource Allocation**:
- **Tester (1 FTE @ 50%)**: 20 hrs/week; Days 1–10 allocated to this release (100 hours available vs. 93-hour estimate)
- **Developer 1 (2 FTE @ 25%)**: Feature implementation, PayGate integration, support testing
- **Developer 2 (2 FTE @ 25%)**: Refund API, test data setup, defect fixes
- **PO (on-call)**: Daily standup, defect triage, Day 10 sign-off

**Critical Path**:
1. Refund API ready by EOD Day 2 (2026-10-30) — blocks gate case G03
2. PayGate sandbox test on Day 5 (Tue 11/05) — only 1 of 2 sandbox days available before gate sign-off
3. Final build stable by EOD Day 9 (Mon 11/11) — gate re-run on Day 10

**Contingency**:
- If PayGate sandbox unavailable Day 5, defer to Day 7 (Thu 11/07) and compress regression to Day 9
- If refund API not ready Day 2, gate reduced to G01, G02, G04–G06 (defer G03 to Day 7)
- If defects found require >5 hours retest, exploratory cases deferred to post-release

---

## 10. Configuration Management of Testware

**Version Control & Identification**:
- Test cases tracked in [Jira/Azure ADO/GitHub Issues] with ID prefix TC-SPLIT-NNN
- Each test case links to feature requirement, risk register entry, and release notes
- Fixtures documented in dedicated fixture set file (e.g., `fixtures/split-payment-fixtures.md`); versioned with code

**Test Data & Fixture Management**:
- PayGate sandbox test cards listed in fixture set (card numbers, expiry, test scenarios they cover)
- Fixture states documented: e.g., "Test Card 4111-1111-1111-1111: Visa, always succeeds; reset required between cycles (no state retained)"
- Restore procedures: how to reset a contaminated fixture or recreate test data after a failed run
- Secure vault: PayGate sandbox credentials stored in env vars or secure vault; never in test scripts

**Test Environment Baseline**:
- Test environment version captured at sprint start: OS, database, PayGate sandbox configuration, build number
- Every test result records: build number, environment version, timestamp, tester name
- Example result row: `G01 | PASS | build-5.3.42 | test-staging-v2 | 2026-11-05 09:30 UTC | [Tester] | No defects`

**CI/CD Integration**:
- Unit & integration tests run on every PR merge (mocks, no sandbox)
- Gate cases re-run on release build before deployment (staging, with sandbox if available)
- Regression suite runs nightly on staging (single-card smoke tests)
- Results logged to test report and linked to release notes

**Traceability**:
- Traceability matrix: Requirement ↔ Test Case ↔ Defect ↔ Fix
- Every P0/P1 case linked to feature requirement ID (from product spec or user story)
- Every defect linked to failed case ID
- Every fix linked to defect ID and re-test case ID

**Rollback & Recovery**:
- If release fails gate, version of testware (cases, fixtures, results) archived with release tag
- Fixtures can be restored from backup or rebuilt per fixture set restore procedure
- Post-release: lessons learned logged and fixture set updated for next release

---

## 11. Test Monitoring, Control & Completion

**Metrics** (collected daily during Days 3–10):
1. **Test Progress**: Case count (total, designed, executed, passed, failed) vs. plan
2. **Defect Metrics**: Count by severity (🔴 CRITICAL, 🟠 HIGH, 🟡 MEDIUM, 🟢 LOW), status (open, fixed, re-tested)
3. **Coverage**: % of gate cases completed, % of P0 cases completed, % of regression executed
4. **Schedule Health**: Days remaining vs. % gate cases complete (target: 100% by Day 9 EOD)
5. **Risk Status**: Re-assess risk scores if new info surfaces (e.g., PayGate API slow on specific card type → increase R03 likelihood)

**Control Directives** (if monitoring flags a deviation):
- If gate case blocked by defect: bump defect to developer's Day 1 priority; set re-test date
- If sandbox unavailable >1 day: defer PayGate-dependent cases to next sandbox window; activate mock-only fallback
- If defect count > 5 on Day 6: extend Day 8 testing, defer exploratory, or escalate to PO for scope cut
- If tester capacity overrun (>85 hours by Day 7): reduce P1 scope or loop in developer to help execute regression

**Progress Report** (issued every 2–3 days):
- Brief status (1 sentence): "Gate 2/7 passing as of Thu 10/31; R02 (refund timing) blocked on API delay; on track."
- Blockers: e.g., "Refund API not yet integrated; unable to run G03 until resolved (targeted Wed 10/30 EOD)"
- Defect summary: open critical/high counts, resolution status
- Timeline risk: "Estimate 93 hrs vs. 100 hrs available; schedule OK if sandbox stable"

**Completion Report** (issued Day 10, after gate sign-off):
- Every case result (one row per case): ID | Title | Result (PASS/FAIL/BLOCKED) | Build | Env | Notes
- Defect summary: All defects closed or with PO exception; severity distribution
- Coverage: % gate passing, % P0 passing, % P1 passing, regression status
- Metrics: Actual effort (tester hours logged), schedule variance, defect escape rates
- Lessons learned: What went well (e.g., "mock PayGate tests caught 2 edge cases early"), what didn't (e.g., "sandbox unavailable Day 5 compressed timeline")
- Sign-off: QA Lead approval, PO approval, date

**Post-Release Activities**:
- Archive test results and testware version with release tag
- Update fixture set with any new test card numbers or restore procedures learned
- Hold team retrospective (45 min): risks that materialized, estimate accuracy, process improvements
- Retire risks that were mitigated; carry forward risks that remain (e.g., PayGate sandbox availability) into next release cycle

---

## 12. Assumptions Summary

1. Split payment feature is fully implemented and compiling by start of test cycle.
2. Refund API is available and contract-documented by Day 2 (2026-10-30).
3. Single-card checkout code is stable with no concurrent changes.
4. Existing single-card regression test suite is available for reuse.
5. PayGate sandbox credentials and sandbox environment are configured and accessible.
6. One tester has 20 hours/week availability; two developers each have ~5 hours/week for QA support.
7. Test environment mirrors production PayGate integration without impacting live customer orders.
8. Defect severity classifications follow [Organization's] standard (CRITICAL = blocks release, HIGH = major feature impact, etc.).
9. Release decision made by Product Owner; QA can recommend but not unilaterally block release.
10. No additional regulatory (PCI-DSS, PSD2, etc.) compliance testing required beyond this scope; assumed covered by prior audits.

---

## 13. Deviations from Standard Test Policy

**N/A — No standard organization test policy cited.** This plan applies ISTQB CTFL v4.0 (Chapter 5) risk-based testing framework and follows payment industry best practices (financial transaction criticality, SLA enforcement, refund audit trail).

---

**Prepared by**: QA Lead  
**Date**: 2026-10-28  
**Version**: 1.0  
**Status**: Ready for Approval
