# Test Plan: Split Payment Feature (Release 5.3)

## 1. Context of Testing

**Scope**:
- New split-payment feature: customer selects split amount, two sequential charges via PayGate, automatic refund if second charge declines.
- Regression testing of single-card checkout (existing, ~4,000 orders/day).
- Integration with external PayGate API (sandbox only for testing).

**Out of Scope**:
- PayGate internal behavior and audit (boundary tested only).
- Refund UI or manual payment adjustment workflows.
- Load testing or performance optimization (not critical for single-payment-per-order model).

**Objectives**:
- Confirm split-payment logic calculates amounts correctly (including remainder-to-first-card rule).
- Confirm both charges execute and succeed when valid.
- Confirm automatic refund triggers within 60 seconds if second charge is declined.
- Confirm single-card checkout path is unaffected by split-payment code.
- Identify payment integrity defects before production release.

**Test Basis**:
- Feature specification (split amounts in cents, remainder rule, automatic refund).
- PayGate sandbox API documentation.
- Existing single-card checkout specification and regression suite.

---

## 2. Assumptions and Constraints

**Assumptions**:
- Feature implementation will be code-complete and merged to release branch by end of day 4 (Nov 3).
- PayGate API is stable during available sandbox windows (Tuesdays and Thursdays).
- Automatic refund is implemented via PayGate refund API call (not a manual process).
- Remainder-cent logic (to first card) is implemented at payment service layer.
- Test card tokens (success, decline, timeout scenarios) are available in PayGate sandbox.
- Existing single-card regression suite is automated and passes on release branch baseline.
- QA can access staging and sandbox environments without delay.
- Developers are available for defect triage and clarification.
- Product Owner can sign off on gate results within 1 business day of completion.

**Constraints**:
- PayGate sandbox available **only on Tuesdays and Thursdays**; no testing Mon, Wed, Fri, weekends.
- One tester, half-time (4 hours/day, ~20 hours/week).
- **Release deadline: 10 working days** (November 11, 2026).
- No production downtime; existing checkout must operate continuously.
- No PCI-DSS re-audit scope (assumption: no new data storage changes).

---

## 3. Stakeholders

| Role | Owner | Responsibility | Relevance |
|------|-------|-----------------|-----------|
| Product Owner | (assumed) | Feature acceptance, gate approval | Defines feature requirements; approves release gate |
| Backend Developers (2x) | (dev team) | Implement split logic, refund state machine, API integration | Code ownership; defect resolution; design clarification |
| QA / Test Manager | (half-time tester) | Test planning, design, execution, reporting | Executes gate, regression, analysis; defect reporting |
| DevOps / Infra | (assumed) | Sandbox/staging access, environment stability | Provides test environment access; monitors availability |
| Payments Team Lead | (assumed) | Payment system oversight | Approves high-risk payment changes; authorizes production cutover |

---

## 4. Communication

- **Daily standup**: 10 min, verbally; blockers noted in Slack #payments-releases.
- **Defect reporting**: Ticket per defect (title, repro steps, expected vs. actual, severity, PayGate API version, build hash).
- **Gate status**: End of day Thursday (Nov 6): gate cases pass/fail, release recommendation (Go/No-Go).
- **Completion report**: Friday EOD (Nov 7): all cases executed, metrics summary, QA and PO sign-off.
- **Escalation**: If critical blocker, notify Payments Team Lead and dev lead immediately.

---

## 5. Risk Register

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner |
|---|----|----|----------|---|---|-------|---------|--------------|-------|
| 1 | R01 | Remainder cent calculation error (off-by-one on split) | Product | 3 | 4 | 12 | 🟠 HIGH | Code review of split-logic function + boundary-value decision table tests (0, 1¢, max-1, max) | Dev/QA |
| 2 | R02 | Refund does not trigger when second charge declined | Product | 2 | 5 | 10 | 🟠 HIGH | Implement state-transition test matrix for all decline scenarios + automated E2E test; verify via PayGate API logs | QA/Dev |
| 3 | R03 | Refund takes >60 seconds to complete (timeout/latency issue) | Product | 3 | 4 | 12 | 🟠 HIGH | Measure refund latency in sandbox (10+ iterations); set monitoring alert in staging; establish SLA verification gate case | QA |
| 4 | R04 | Single-card checkout broken by split-payment code changes | Product | 2 | 5 | 10 | 🟠 HIGH | Run full automated single-card regression suite before release gate; must pass 100% | QA |
| 5 | R05 | Race condition: both charges fail, refund still attempts (double refund) | Product | 2 | 3 | 6 | 🟡 MEDIUM | Test idempotent refund API (refund same transaction ID twice); verify only one refund appears in ledger | Dev/QA |
| 6 | R06 | PayGate timeout/transient error during second charge → unclear payment state | Product | 3 | 3 | 9 | 🟠 HIGH | Test error cases (timeout, 5xx, rate-limit); verify customer sees clear error msg; verify first charge refunded if applicable | QA |
| 7 | R07 | First charge succeeds, second charge API call never sent (implementation bug) | Product | 2 | 4 | 8 | 🟠 HIGH | Trace API calls in logs for each split transaction; verify both POST requests sent to PayGate | QA |
| 8 | P01 | PayGate sandbox unavailable outside Tues/Thurs; can't execute live tests on schedule | Project | 4 | 4 | 16 | 🔴 CRITICAL | Schedule test execution for Tues (Nov 3, 11, 18) and Thu (Nov 5, 7) only; move test-design and gap-review work to non-sandbox days; request PayGate support for extended sandbox access if slipping | QA/DevOps |
| 9 | P02 | Feature implementation incomplete by day 4 (code not merged to release branch) | Project | 3 | 5 | 15 | 🔴 CRITICAL | Daily dev standup checkin; code review sign-off by EOD day 4; dev lead escalates if slipping by >4 hours | Dev Lead |
| 10 | P03 | Half-time tester cannot complete all cases within 10-day window | Project | 3 | 4 | 12 | 🟠 HIGH | Prioritize by risk (gate → CRITICAL → HIGH); automate single-card regression (already done); defer non-blocking exploratory edge cases to post-release if needed | QA |

**Risk Control Actions**:
- **R01, R02, R03, R04, R06, R07**: Mitigated by release gate (see Section 6).
- **R05**: Idempotency test designed into case set (Section 6).
- **P01**: Test schedule aligned to Tues/Thurs windows (Section 8); request PayGate support escalation if sandbox down.
- **P02**: Daily sync with dev team; if slipping, escalate to payments and dev leads by Nov 2 EOD.
- **P03**: Prioritize gate + regression; defer exploratory beyond gate to post-release patch cycle.

---

## 6. Test Approach

**Test Levels**:
- **Unit Testing** (Developer-owned): Split-logic calculation, state machine transitions. QA reviews test coverage, not re-tests.
- **Integration Testing** (QA-owned): Split + PayGate API, refund-trigger + PayGate refund API, error handling.
- **System/E2E Testing** (QA-owned): Full split-payment checkout flow, single-card regression, end-to-end via UI or API.
- **UAT** (Product Owner): Manual spot-check of happy path on staging.

**Test Types**:
- Functional: split amounts correct, both charges, refund on decline, remainder rule.
- Regression: single-card checkout unchanged.
- Integration: PayGate API (sandbox) integration, refund latency.
- Exploratory: error cases (network timeout, API errors, rate limits, card declines).
- Performance/Reliability: refund latency measurement (<60s confirmation).

**Test Techniques**:
- Boundary value analysis: split amounts ($0.00, $0.01, 50% even, 50% + remainder, max order total).
- Equivalence partitioning: decline on first vs. second charge, success on both.
- State-transition testing: charge states (pending, approved, declined, refunded, refund-failed).
- Decision table: split scenarios (even, uneven, zero first card, zero second card).
- Error guessing: PayGate timeout, 5xx error, rate limit, invalid card, network disconnect.

**Deliverables**:
- Release gate cases (5 cases, below).
- Functional test cases: split-payment scenarios (12 cases).
- Refund test cases: decline and recovery scenarios (8 cases).
- Regression suite: automated single-card tests (existing; run pre-gate).
- Defect log: each defect with title, repro, severity, status.
- Test execution log: per-case results, defect links, build version, date.
- Completion report: case summary, metrics, sign-off.

**Entry Criteria** (When to START Testing):
- [ ] Feature code complete, reviewed, and merged to release branch.
- [ ] PayGate sandbox endpoint accessible and verified from test environment.
- [ ] Test card tokens (success, decline, timeout) provisioned and confirmed in sandbox.
- [ ] Existing single-card test suite passing on release branch baseline.
- [ ] Feature specification and PayGate API docs available to QA.
- [ ] Staging environment deployed with split-payment code.

**Exit Criteria** (When to STOP Testing & Release):
- [ ] Every release gate case executed and passing.
- [ ] Single-card regression suite passing (100%).
- [ ] Zero open Critical-severity defects.
- [ ] Zero open High-severity defects (or documented Product Owner exception per defect).
- [ ] Refund latency confirmed <60 seconds on sandbox (min 3 test iterations).
- [ ] Test execution log and defect log complete and linked to all cases.
- [ ] Test summary signed off by QA Lead and Product Owner.

**Release Gate** (5 cases — minimal set covering changed and highest-risk behavior):

| ID | Case Title | What It Proves | Expected Result | Status | Notes |
|----|-----------|----------------|-----------------|--------|-------|
| **G01** | Split $100.00 evenly: $50.00 card 1, $50.00 card 2; both succeed | Both charges execute and succeed with correct split amounts | Two PayGate transactions: $50.00 and $50.00; both approved; ledger total = $100.00 | ☐ | Core feature happy path |
| **G02** | Split $100.01 with remainder: $50.00 card 1, $50.01 card 2 | Remainder cent (1¢) correctly goes to first card | Two charges: $50.01 (card 1) and $50.00 (card 2); both approved in PayGate | ☐ | Remainder rule verification |
| **G03** | First charge approved; second charge declined (insufficient funds) | Refund auto-triggers within 60s when second charge fails | First charge refunded in <60 sec; refund confirmed in PayGate audit log; no duplicate charges; customer sees single $0 net charge | ☐ | Critical: automatic refund SLA |
| **G04** | Single-card checkout: $100.00 on one card (regression check) | Regression: single-card path unaffected by split-payment code | Single transaction: $100.00; approved; no split logic triggered; checkout completes normally | ☐ | Regression gate |
| **G05** | Split $0.01 (minimum): $0.00 card 1, $0.01 card 2 | Edge case: zero amount on first card handled correctly | Card 1: $0.00 (charge skipped or $0 charge succeeds); card 2: $0.01; refund process handles zero-charge state | ☐ | Boundary condition |

**Test Independence**:
- QA tester is independent from development team (separate role, different person).
- Degree of independence: **Some** (QA from product team, but not external auditor). Rationale: payment feature is critical, but team is small and agile; external independent test would delay 10-day timeline.

**Test Data & Environment**:
- **Test environment**: Staging with split-payment feature code.
- **PayGate sandbox**: Card tokens for success scenario, decline (insufficient funds), decline (expired), timeout.
- **Fixture set**: See test-data/split-payment-fixtures.md (maintained in repo).
  - Test card tokens (no real PII stored; tokens provided by PayGate sandbox).
  - Expected outcomes per card type (success, decline, timeout).
  - Test order records with known user IDs for traceability.
- **Database state**: Orders seeded with test customer accounts; no shared state pollution; rollback after test cycle.

**Deviations from Standard Policy**:
- Unit test coverage (split-logic calculation) developed and owned by dev team; QA validates via integration/system tests, not isolated unit re-test (follows team's standard dev practice).
- Refund verification done via PayGate API audit logs and database state, not UI-only assertion (backend-driven feature).
- Load testing deferred (out of scope; single split per order is not high-volume concern within this release).
- No penetration testing (out of scope; handled by AppSec team in separate cycle).

**Metrics to Collect**:
- Test progress: % cases executed, % cases passed.
- Defect density: count by severity (Critical, High, Medium, Low); defects per test case (target: ≤0.2 defects/case).
- Coverage: decision-table cases completed, boundary values tested, error paths covered.
- Risk mitigation: # CRITICAL risks mitigated (target: 2/2), # HIGH risks still open (target: 0).
- Project: actual hours spent vs. estimate (target: 19 ± 3 hours); days elapsed vs. 10-day window.
- PayGate availability: sandbox uptime during test windows (target: 100% Tues/Thurs).

---

## 7. Estimate

**Estimation Technique**: Three-point (expert-based PERT).

- **Optimistic (a)**: 12 hours
  - No implementation delays, sandbox available all scheduled days, zero defects on first run.
- **Most likely (m)**: 18 hours
  - One blocker day (sandbox down or code late 1 day), one defect found and re-tested, normal progress.
- **Pessimistic (b)**: 28 hours
  - Multiple sandbox outages, implementation slips 2+ days, 3+ defects requiring investigation and re-test.

**Expected Value (E)**:
$$E = \frac{a + 4m + b}{6} = \frac{12 + 4(18) + 28}{6} = \frac{112}{6} = 18.67 \text{ hours}$$

**Standard Deviation (SD)**:
$$SD = \frac{b - a}{6} = \frac{28 - 12}{6} = 2.67 \text{ hours}$$

**Final Estimate**: **19 ± 3 hours** (range: 16–22 hours)

**Confidence**: 68% (one standard deviation; 90% confidence = 19 ± 5.3 hours, range 13.7–24.3).

**Assumptions Behind Estimate**:
- Test case design (this plan) complete by EOD day 3 (Oct 31).
- Environment and PayGate sandbox access confirmed by EOD day 4 (Nov 3).
- Feature code complete and merged by EOD day 4 (Nov 3).
- Tester has 4 hours/day continuous availability on sandbox days (Tues, Thu).
- No multi-day defects requiring reimplementation (assume defects are one-off fixes, <4 hours each).
- Regression suite is automated and runs in <30 min.
- No scope creep or out-of-band feature requests during test window.

---

## 8. Budget and Schedule

**Test Timeline** (10 working days: Oct 28 – Nov 10, 2026):

| Phase | Days | Dates | Activity | Effort | Sandbox |
|-------|------|-------|----------|--------|---------|
| **Plan & Design** | 1–3 | Wed 10/29, Thu 10/30, Fri 10/31 | Test plan finalization, test case design (split, refund, regression), environment setup | 5 hrs | N/A (no live testing) |
| **1st Execution** | 4–5 | Mon 11/2, **Tue 11/3** | Test execution on sandbox (gate + functional); defect triage | 6 hrs | Tue only |
| **Gap & Investigation** | 6 | Wed 11/4 | Defect investigation, gap analysis, re-test prep (no sandbox) | 2 hrs | N/A |
| **Regression & Retest** | 7–8 | **Thu 11/5**, Fri 11/6 | Automated single-card regression; re-test any defects (Thu sandbox available) | 5 hrs | Thu only |
| **Final Verification** | 9–10 | Mon 11/9, **Tue 11/10** | Final gate case verification, completion report, sign-off (Tue sandbox for final confirmation) | 3 hrs | Tue only |
| **TOTAL** | — | — | — | **21 hrs** | Tues/Thu 4 days |

**Resource Allocation**:
- **QA Tester**: 0.5 FTE (4 hrs/day available; Tues/Thu prioritized for sandbox work).
- **Dev Team**: 2 developers (available for defect clarification, not continuous testing).
- **DevOps**: On-call for environment access and PayGate sandbox coordination.
- **Product Owner**: Review and sign-off at gate completion (1–2 hrs).

**Budget Justification**:
- 21 hours QA @ 0.5 FTE spans 10 working days (40 hrs/week ÷ 2 testers = 20 hrs/tester; 1 tester = up to 20 hrs/week available).
- 21 hours fits within available 20 hrs/week (slight overage acceptable if defects are light).
- Contingency: if defects spike, defer exploratory edge-case tests to post-release patch (gate + regression prioritized).

---

## 9. Configuration Management of Testware

**Test Case Versioning**:
- Test cases stored in repo: `docs/test-cases/split-payment-release-5.3.md`.
- Version control: Git; tagged to release branch (`release/5.3`).
- Case ID format: `G##` (gate), `S##` (split functional), `R##` (refund), `T##` (regression).

**Test Data Management**:
- Fixture set: `docs/test-data/split-payment-fixtures.md`.
  - Card tokens (no real PII; sandbox-only identifiers).
  - Expected outcomes per card type.
  - Test order IDs and user accounts.
- Sensitive data (PayGate credentials): managed via secure config (not in repo); accessible to QA only.

**Test Environment Tracking**:
- Staging environment version: linked to release branch commit hash (noted in test log).
- PayGate sandbox version: noted in execution log (API version, region).
- Database baseline: snapshot taken at start of test cycle; restored after (no state leakage).

**Test Execution & Results**:
- Execution log: `docs/test-results/split-payment-execution-log.md`.
  - Per-case result (Pass/Fail), defect link, build hash, date, tester name.
  - PayGate API logs referenced for refund latency verification.
  - Screenshot or error trace for each failed case.
- Defect tracking: Each defect is a ticket (GitHub Issue or equivalent) with:
  - Title, repro steps, expected vs. actual, severity, PayGate API version, build hash.
  - Link to failing test case (by case ID).

**Release Artifacts**:
- Gate results table: signed-off by QA and PO; included in release notes.
- Completion report: final test summary, metrics, lessons learned.
- Traceability: case ID → requirement mapping; requirement → risk register.
- Baseline: release branch commit tagged as `v5.3` with test artifacts attached.

**Post-Release**:
- All test cases and results archived to release tag (`v5.3`).
- Regression suite baseline: single-card cases frozen as regression pack for future releases.
- Lessons learned: documented in retrospective (to be held post-release).

---

## Sign-Off

**Test Plan Owner**: QA Lead (half-time tester)  
**Stakeholder Review**: Product Owner, Development Lead  
**Approval Date**: [To be filled on plan acceptance]  
**Plan Last Updated**: 2026-10-28

---

## Appendices (if needed)

### A. PayGate Sandbox Availability Constraint Mitigation

Due to PayGate sandbox being available only Tues/Thurs, testing window is compressed. Mitigation:

1. Prioritize case design and environment setup Mon/Wed/Fri.
2. Schedule all live API tests for Tues/Thu only.
3. Prepare gap analysis and defect investigation for non-sandbox days.
4. Escalate to PayGate support if sandbox is down on scheduled days; request emergency extended access for release-critical testing.

### B. Assumptions Dependency Map

| Assumption | Risk if Invalid | Mitigation |
|-----------|-----------------|-----------|
| Impl. complete by Nov 3 | 5-day test window compressed to 2 days | Daily dev standup; escalate by Nov 2 EOD if slipping |
| Sandbox available Tues/Thu | Can't execute live tests; regression suite alone insufficient | Request PayGate support for extended sandbox or prod sandbox slot |
| Test card tokens provisioned | Can't test PayGate integration | Request provisioning by Nov 2; test dummy scenarios offline if needed |
| Single-card suite automated | Can't run 100-case regression in 4 hrs | Pre-agreed with dev team; regression suite is existing, maintained |
| PO available for sign-off | Gate cannot be approved; release blocked | Identify backup approver (dev lead or payments team lead) by Nov 2 |
