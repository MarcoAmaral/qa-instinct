# Test Plan: Split Payment Feature (Release 5.3)

## 1. Context of Testing

**Scope**: Addition of two-card split-payment capability to the existing single-card checkout flow. Customers select a primary card amount; the remainder goes to a secondary card. Both charges route through PayGate. Automatic refund of the primary charge if the secondary charge is declined within 60 seconds.

**Test Basis**: Feature specification (split payment feature brief); existing single-card checkout specification; PayGate API documentation; PCI-DSS and payment processing compliance requirements.

**Objectives**:
- Verify split-payment calculation logic (cent remainder handling) is correct.
- Confirm both charges execute through PayGate as intended.
- Validate automatic refund mechanism completes within 60-second SLA.
- Ensure zero regression in existing single-card checkout (4,000 orders/day volume must remain stable).
- Identify integration issues with PayGate sandbox before production release.

**Test Levels**: Unit, Integration, System (E2E), Regression.

---

## 2. Assumptions and Constraints

| Assumption | Rationale |
| --- | --- |
| Checkout system is API-driven (REST/GraphQL backend, web frontend) | Standard modern e-commerce architecture. Informs test pyramid and automation approach. |
| Single-card checkout exists as stable, tested baseline | Stated in feature brief; used to scope regression suite. |
| PayGate sandbox mirrors production behavior | Required for confidence in release candidate; test against sandbox only due to availability window. |
| "Release date: 10 working days" means go-live, all testing complete by 2026-11-11 | Starting from 2026-10-28; excludes weekends and typical org holidays (none assumed in this 2-week window). |
| Test environment is independent of production; orders do not leak to live systems | Standard practice; no test-to-production pollution. |
| Existing single-card regression suite is runnable and maintainable | If not, effort estimate adjusts upward; plan assumes it exists. |
| Developer availability: 2 developers can contribute 20–30% effort to test automation | Release-critical feature; devs expected to help scaffold and maintain test infrastructure. |
| Refund latency is measurable in test (timestamps logged; PayGate refund state queryable) | Required to verify 60-second SLA; absence of this raises a HIGH-risk project issue. |
| Browser support: Chrome, Firefox, Safari (or whatever current checkout supports) | No new browser matrix for this feature; use existing single-card scope. |

**Constraints**:
- **PayGate sandbox available Tuesdays and Thursdays only**: Integration and E2E test windows are 2 days/week; impacts scheduling and test-execution order (see Section 8, Schedule).
- **One tester, half time (~20 hrs/week effective)**: Limits manual exploratory and regression scope; automation and developer support are mandatory.
- **10 working days to release**: ~40 effective hours from the tester; devs must automate the majority of suite.
- **Regression on 4,000 daily orders**: Failure in single-card flow is high-visibility; regression suite must be small, fast, and high-confidence.

---

## 3. Stakeholders

| Role | Name | Responsibility | Test Relevance |
| --- | --- | --- | --- |
| **Product Owner** | Not named; assumed assigned | Feature approval, definition, acceptance | Sign-off on release gate pass/fail; exception authority for P1+ failures |
| **Dev Lead** | Not named; one of two developers | Feature implementation, code review | Code walkthrough for test design; test-automation pairing |
| **QA Lead / Test Manager** | This plan's author | Test planning, scheduling, monitoring, sign-off | Owns plan execution, daily standups, risk mitigation, completion report |
| **Test Engineer** | One tester, half time | Test analysis, design, execution, defect reporting | Executes manual E2E and exploratory tests; co-authors automation with devs |
| **DevOps / Deployment** | Not named; assumed assigned | Environment setup, PayGate sandbox access, build promotion | Ensures test and staging environments mirror prod config; gates production release |
| **Compliance / Legal** | Not named; assumed assigned | PCI-DSS audit trail, payment regulations | Non-functional tests (audit logging, data handling) may be in scope; confirm with stakeholder |

**Independence Degree**: Test Engineer is independent (not a developer on the feature) → **Some independence**. Rationale: One dedicated tester reduces author-bias in single-card regression; developers assist automation to meet timeline, maintaining separation of concerns.

---

## 4. Communication

| Cadence | Form | Audience | Content |
| --- | --- | --- | --- |
| **Daily** (async) | Slack message or stand-up 15 min | Dev lead, test engineer, devops | Blockers, PayGate sandbox availability status, test-execution progress, defect count |
| **Every execution cycle** (Tues/Thurs) | Test execution log + screenshot evidence | QA lead, product owner | Cases run, pass/fail count, gateway response times, any manual findings |
| **Weekly** (Wed or Fri) | Progress report: test metrics, risk register review, schedule confidence | Product owner, dev lead, QA lead | Test coverage %, defect severity distribution, timeline risk (stay green/yellow/red), forecast for gate pass |
| **At release** | Test completion report + sign-off | Product owner, DevOps, Compliance | All cases logged with results, test summary (coverage, defect closure), gate sign-off, deployment readiness |

**Document Templates**: Use existing org templates if available; else store all case results (ID, name, steps, result, evidence) in a shared sheet or test-management tool (e.g., ADO/JIRA/TestRail); version control for non-live artifacts (test scripts, fixtures).

---

## 5. Risk Register (5×5 Matrix)

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | R01 | Split amount calculation is incorrect (e.g., off-by-one on cent remainder, rounding errors, total != original amount) | Product | 4 | 5 | **20** | 🔴 CRITICAL | Unit test decision table for boundary splits (0¢, 1¢, 50¢, 99¢ remainder); automated regression on 20+ split amounts. Dev code review. | Dev + QA |
| 2 | R02 | Secondary charge is declined; primary charge is NOT refunded, or refund is delayed >60s, leaving customer charged and angry | Product | 3 | 5 | **15** | 🔴 CRITICAL | E2E test: force secondary decline, verify refund in PayGate within 60s; mock PayGate delays to verify SLA under stress; log timestamps; set up monitoring alert on refund lag. | Dev + QA |
| 3 | R03 | Both charges execute, but first charge is refunded even when second charge succeeds (logic inverted or race condition) | Product | 3 | 5 | **15** | 🔴 CRITICAL | E2E happy path (both succeed) + exploratory async-order testing; state transition test (charge 1 → charge 2 → no refund); code review of refund trigger logic. | Dev + QA |
| 4 | R04 | Existing single-card checkout is broken by split-payment code (e.g., shared payment path, regression in middleware) | Product | 3 | 5 | **15** | 🔴 CRITICAL | Regression suite: 8 single-card cases (happy path, card decline, timeout, 3DS, etc.) run on every build; smoke test before release gate. | QA |
| 5 | R05 | PayGate sandbox is unavailable outside Tue/Thu, delaying integration testing and blocking release candidate validation | Project | 4 | 4 | **16** | 🔴 CRITICAL | Schedule all integration & E2E execution on Tue/Thu only (see Section 8); pre-stage test data and mock PayGate responses for unit & design phases; dev local mocks for offline design. Escalate to DevOps if sandbox down on scheduled day. | DevOps + QA |
| 6 | R06 | Test harness or automation framework is not ready; half-time tester cannot execute full suite manually in time | Project | 3 | 4 | **12** | 🟠 HIGH | Dev 1 owns test automation scaffold (API client, assertion library, retry logic); test engineer pairs for case scripting. Automated cases prioritized: split calculation, refund SLA, regression. Exploratory scripted locally by Wed. Resume point documented daily. | Dev + QA |
| 7 | R07 | Defect discovered late (day 8–9) in refund logic; refactor and re-test takes >2 days, missing release window | Product | 2 | 5 | **10** | 🟠 HIGH | Refund logic tested first, in parallel with split-calculation unit tests (risk-based execution order). Early E2E smoke on day 3. Code review by Dev 2 before integration testing. | Dev + QA |
| 8 | R08 | Split-payment feature leaks sensitive card data (PAN, CVV) in logs, audit trail, or error messages, violating PCI-DSS | Product | 2 | 5 | **10** | 🟠 HIGH | Security code review by Dev 2 (card data handling); log analysis test (grep for unmasked PAN/CVV); automated check in CI. Compliance sign-off before release. | Dev + Compliance |
| 9 | R09 | Concurrent orders or race conditions: two split payments on same card at same second; one succeeds, one hangs or double-charges | Product | 2 | 4 | **8** | 🟠 HIGH | Load/concurrency E2E test (10 concurrent split orders); state transition test; PayGate idempotency key handling verified in code review. | Dev + QA |
| 10 | R10 | PayGate API response times slow down under test volume; SLA monitoring is not instrumented, so refund delay is not caught | Product | 2 | 4 | **8** | 🟠 HIGH | E2E test records timestamps; refund SLA assertion built into case logic (automated fail if >60s). Devops instruments PayGate call latency in staging logs. | Dev + QA + DevOps |
| 11 | R11 | Tester is unavailable mid-week (illness, vacation); no backup, manual testing stalls | Project | 2 | 4 | **8** | 🟠 HIGH | Prioritize automated cases; document resume points daily by EOD Thu. If tester unavailable, defer non-critical exploratory tests (R12, R13) to post-release. | QA |
| 12 | R12 | Edge cases not explored: $0.01 split, negative amount attempted, invalid card combinations, concurrent decline+timeout | Product | 2 | 3 | **6** | 🟡 MEDIUM | Exploratory testing session (2–3 hrs, test engineer) after gate cases pass; log findings as tickets, not gate-blockers. Scripted positive cases before release. | QA |
| 13 | R13 | Documentation for split-payment checkout UX is missing or unclear; customers confused, support load spikes | Product | 2 | 3 | **6** | 🟡 MEDIUM | UX acceptance test (does UI clearly show the two amounts?); user journey walkthrough with PO. Post-release support plan in place. | PO + QA |
| 14 | R14 | Staging environment PayGate credentials are wrong or expired; cannot test integration | Project | 2 | 3 | **6** | 🟡 MEDIUM | Verify PayGate creds & sandbox access by EOD Thu of week 1. Store securely (no repo); alert DevOps if timeout occurs. | DevOps |
| 15 | R15 | Single-card regression suite is flaky; false fails waste tester time and delay release gate sign-off | Project | 3 | 2 | **6** | 🟡 MEDIUM | Smoke single-card suite on each build; isolate & fix flaky cases before feature testing starts (day 1 activity). | Dev + QA |

**Risk Monitoring**: Review register on Friday of each week and after any major defect discovery. Re-score if facts change (e.g., PayGate sandbox outage confirmed for a specific day = L increases; test automation delivered early = Project risks drop). Mark date of any re-score.

---

## 6. Test Approach

### 6a. Test Levels & Types

| Test Level | Responsibility | Independence | Scope | Technique | Deliverable |
| --- | --- | --- | --- | --- | --- |
| **Unit** | Developer (Dev 1) | None (author) | Split-amount calculation logic; refund-trigger condition; input validation | Boundary-value analysis (split amounts: 0¢, 1¢, 50¢, 99¢ remainder, $0.01–$9999.99); decision table (both charges succeed, only 2nd declines, both decline, timeout, network error) | `test_split_payment.py` or equivalent; ≥20 cases; ≥90% branch coverage |
| **Integration** | Dev 2 + Test Engineer | High (independent test engineer validates) | Split payment API endpoint → PayGate sandbox; both charge calls; refund trigger; response parsing | API contract test (PayGate request/response shape); happy path (both succeed); secondary decline → refund; timeout & retry logic | `test_split_payment_api.py`; ≥8 cases; all PayGate paths exercised |
| **System (E2E)** | Test Engineer + Dev 1 | High (test engineer scripts; dev assists automation) | End-to-end checkout flow: select two cards, enter split amount, submit, both charges on PayGate, order state transitions, refund if needed | Happy path (order placed, both charged, order confirmed); secondary decline (primary refunded, order cancelled); single-card path still works; concurrent orders (stress) | Playwright or Selenium; ≥12 cases; includes regression on single-card flow |
| **Regression** | Test Engineer (manual smoke, automated runs) | High | Existing single-card checkout; no split involved | Happy path (card accepted, order placed); card declined; timeout; 3DS/2FA (if in original scope) | Automated regression suite; ≥8 cases; run on every build + release gate; <5 min duration |

### 6b. Test Pyramid (Architecture-Based)

**Diagnostic Question**: "Where does the business logic live?" → Payment processing is API-driven (backend); split-calculation and refund-timing logic is backend; checkout UI is frontend. **Preset: Full-stack web app (React + API)** → 40% Unit · 40% Integration · 20% E2E.

**Distribution** (25 total cases):
- **Unit (10 cases, 40%)**: Split-calculation boundary, decision-table, input validation.
- **Integration (10 cases, 40%)**: PayGate API contract, both-charge paths, refund logic, error responses.
- **E2E (5 cases, 20%)**: Happy path, secondary decline, concurrent, UI validation, UX clarity.

*Note*: Regression (8 single-card cases) runs separately; scored as defensive, not part of feature pyramid. Release gate pulls 5–6 top cases across levels.

### 6c. Testing Quadrants Alignment

| Quadrant | Coverage | Technique | Automation |
| --- | --- | --- | --- |
| **Q1 (Technology-facing, Supports Team)** | Unit tests (split calc, refund logic); API contract tests (PayGate shape) | Boundary-value, decision table | ✅ Automated (CI) |
| **Q2 (Business-facing, Supports Team)** | Acceptance: "When I split $50.00 as $30 + $20, both charges succeed and I see split confirmation" | Happy-path scenario, UX walkthrough with PO | ✅ Automated (E2E) + Manual (PO walkthrough) |
| **Q3 (Business-facing, Critiques Product)** | Exploratory: edge cases (tiny splits, card limits, declined scenarios), UX confusion, support issues | Exploratory, user-journey testing | 🟡 Manual (post-gate, if time) |
| **Q4 (Technology-facing, Critiques Product)** | Non-functional: latency (refund SLA <60s), security (PAN/CVV not logged), concurrency (10 simultaneous orders) | Load test, security code review, log inspection | ✅ Automated (E2E load, CI security scan) |

### 6d. Entry & Exit Criteria

**Entry Criteria for System-Level Test Execution** (When to START Testing):
- [ ] Split-payment feature is implemented, code merged to `release/5.3` branch, zero linting/build errors.
- [ ] PayGate sandbox credentials loaded to staging environment; connectivity confirmed (test API call succeeds).
- [ ] Unit test suite passes (≥90% coverage on split calculation and refund logic).
- [ ] Test environment (staging) is deployed, orders do not leak to production.
- [ ] Existing single-card regression suite is confirmed runnable (smoke run passes <5 min).
- [ ] Test data: 10+ test cards in PayGate sandbox (mix of success/decline scenarios).

**Exit Criteria for Release** (When to STOP Testing & Release):
- [ ] All **Release Gate cases** (see below) passed and signed off by QA Lead and Product Owner.
- [ ] 100% of P0 cases (split calculation, refund SLA) executed and passing.
- [ ] 100% of P1 cases (both-charge paths, secondary decline, single-card regression) executed and passing, or PO-approved exceptions logged.
- [ ] Zero open **Critical** defects; zero open **High** defects (or PO exception with signed risk acceptance).
- [ ] Single-card smoke regression (8 cases) passes on latest build.
- [ ] Security code review completed; no unmasked card data in logs.
- [ ] Test completion report signed by QA Lead and Product Owner.
- [ ] **Gate sign-off blocks production release if not achieved.**

### 6e. Release Gate (5–6 Minimum Cases)

The release gate is the smallest set that answers "Does the fix work? Did we break anything?". Built from high-risk cases: split-calculation correctness, refund SLA, secondary-decline flow, single-card regression.

| Gate ID | Case Name | What It Proves | Priority | Automation | Expected Result | Status |
| --- | --- | --- | --- | --- | --- | --- |
| **G01** | Split $50.00 into $30.00 + $20.00 (even split) | Correct calculation, both charges succeed, order confirms | P0 | ✅ Automated E2E | Both PayGate charges logged; order state = `confirmed`; customer sees split confirmation | — |
| **G02** | Split $50.01 into $30.00 + $20.01 (remainder on first) | Remainder-cent logic correct; first card charged $30.01, second $20.00 | P0 | ✅ Automated Unit + E2E | First charge = $30.01, second = $20.00; total = $50.01; order confirmed | — |
| **G03** | Secondary card declined; primary refunded within 60s | Automatic refund SLA met; order cancelled; customer not double-charged | P0 | ✅ Automated E2E (mock decline, measure refund latency) | Primary charge refunded (PayGate refund log shows <60s delta); order state = `cancelled`; no error to customer | — |
| **G04** | Single-card checkout (existing flow) still works: charge $50.00, one card, order confirms | Zero regression on 4,000 daily orders | P1 | ✅ Automated Regression | Existing flow unchanged; order confirms with one charge; <100ms latency delta from baseline | — |
| **G05** | Both charges declined; order is not placed | Handles double-decline gracefully; no partial charge | P1 | ✅ Automated E2E (mock both declined) | Order creation fails; no charges logged in PayGate; customer sees error message; rollback clean | — |
| **G06** | Concurrent split orders (5 simultaneous): each order charges correctly on both cards, no cross-contamination | No race conditions or card mixing under load | P1 | ✅ Automated E2E (load test) | All 5 orders complete independently; each has correct two charges; no double-charges or dropped payments | — |

**Gate Execution Order** (Risk-Based):
1. **G01 & G02** (calculation correctness) — day 2 or 3 (unit tests run first; E2E smoke as soon as integration ready).
2. **G03** (refund SLA, highest-risk product impact) — day 4 (depends on refund logic unit test passing).
3. **G04** (regression, protects daily revenue) — day 5 (runs on every build; final smoke before gate).
4. **G05 & G06** (error handling, load) — day 6–7 (exploratory paths; defects here are P1 but not gate-blockers if dev fixes available).

**Override of execution order**: PayGate sandbox available only Tue/Thu → all integration & E2E execution pushed to those days; unit tests run any day.

### 6f. Test Data & Environment

**Test Data Fixture Set**:

| Fixture ID | Card Description | Test Purpose | State | Read/Write |
| --- | --- | --- | --- | --- |
| **F01** | Visa 4111111111111111 (test success card) | Happy path: both charges succeed | Valid, no holds | Read-only (use per test; do not persist state) |
| **F02** | Visa 4000000000000002 (test decline card) | Secondary decline: force second charge to fail | Valid, auto-declines on transaction | Read-only |
| **F03** | Visa 5555555555554444 (Mastercard test) | Cross-brand validation | Valid, success | Read-only |
| **F04** | Amex 378282246310005 (test success) | 3-card type coverage | Valid, success | Read-only |

*Preconditions*: All cards are PayGate sandbox-only; zero real charges. Test-environment order state is isolated (does not affect production). Refund state queryable from PayGate sandbox API within 5s.

**Environment Requirements**:
- **Staging**: Checkout app, payment-processing service, database (test orders isolated by namespace or TTL).
- **PayGate Sandbox**: Credentials pre-loaded; accessible Tue/Thu only; refund polling available (<5s latency to see refund status).
- **Local Dev**: Mock PayGate responses for offline unit-test development; Docker Compose or equivalent.

### 6g. Non-Functional Test Focus

| Non-Functional Attribute | Technique | Threshold | Owner |
| --- | --- | --- | --- |
| **Performance (Refund SLA)** | E2E test with clock measurement; PayGate API latency logging | Refund initiated <60s after decline detection | QA + Dev |
| **Concurrency** | 10 simultaneous split orders; state isolation check | Zero cross-order charge contamination; all 10 complete within 30s | QA |
| **Security (PAN/CVV masking)** | Log file grep + code review | No unmasked card numbers in logs; test assertions | Dev + Compliance |
| **Backward compatibility** | Single-card regression suite | <100ms latency delta from baseline; same pass rate (>99%) | QA |

### 6h. Deviations from Standard Test Policy

**Deviation 1**: Integration testing is **compressed to Tue/Thu only** due to PayGate sandbox availability window. Mitigation: Unit tests and local mocks run daily; integration is scheduled, not ad hoc.

**Deviation 2**: **Exploratory testing is post-gate** (not pre-release) due to half-time tester and 10-day timeline. Rationale: Gate covers critical paths; exploratory findings logged as tickets, not release blockers. Post-release optional if timeline allows.

**Deviation 3**: **Code review substitutes for some integration testing** (refund-trigger logic, card-data masking). Rationale: Critical financial logic requires architectural review; testing alone cannot catch design flaws. Dev 2 assigned to code-review paired with test cases.

---

## 7. Effort Estimate

**Estimation Technique**: Expert-based (Wideband Delphi, three-point).

**Decomposition**:

| Task | Dev 1 (hrs) | Dev 2 (hrs) | Test Eng (hrs) | Total (hrs) |
| --- | --- | --- | --- | --- |
| **Test Planning & Analysis** | — | — | 3 | 3 |
| **Unit Test Suite (split calc, refund logic)** | 8 | — | 2 (review) | 10 |
| **Integration Test Suite (PayGate mocking, API)** | 6 | 2 (code review) | 3 | 11 |
| **E2E Test Automation (Playwright, happy + sad paths)** | 4 | — | 6 | 10 |
| **Regression Suite (single-card smoke, automated)** | 2 | — | 3 | 5 |
| **Manual Exploratory Testing** | — | — | 4 | 4 |
| **Defect Triage & Re-test** | 2 | 2 | 4 | 8 |
| **Security & Compliance Review** | — | 3 (code review, PAN/CVV masking) | 1 | 4 |
| **Test Execution & Monitoring** | — | — | 8 | 8 |
| **Documentation & Completion Report** | — | — | 2 | 2 |
| **Contingency (10% buffer)** | 2.4 | 0.7 | 3.6 | 6.7 |
| **TOTAL** | **24.4** | **7.7** | **39.6** | **71.7 hrs** |

**Three-Point Estimate (optimistic / most-likely / pessimistic)**:
- **Optimistic (a)**: 60 hrs (no defects, zero PayGate integration surprises, automation scaffold exists).
- **Most Likely (m)**: 72 hrs (1–2 defects found & fixed, 1 automation spike, normal surprises).
- **Pessimistic (b)**: 90 hrs (3+ defects requiring refactor, PayGate sandbox outage delays testing, test-harness rebuild).
- **Expected (E)**: E = (60 + 4×72 + 90) / 6 = **73.33 hrs**.
- **Standard Deviation**: SD = (90 − 60) / 6 = **5 hrs**.

**Range**: 68–78 hrs at 68% confidence; 63–83 hrs at 95% confidence.

**Assumptions**:
- Test automation scaffold (API client, assertion helpers, retry logic) is available by day 1 or can be scaffolded in <4 hrs by Dev 1.
- Single-card regression suite is runnable and maintainable (not broken; <2 hrs to fix if flaky).
- PayGate sandbox is up Tue & Thu; no outage >2 hrs (or test is rescheduled).
- No scope creep: split payment only; single-card checkout is in-scope for regression, not refactored.

**Resource Allocation**:
- **Dev 1**: ~24 hrs / 80 hrs in release cycle = **30% of dev capacity** (implementation is ~50 hrs; test automation is ~24 hrs).
- **Dev 2**: ~8 hrs / 80 hrs = **10% of dev capacity** (code review, security, support).
- **Test Engineer**: ~40 hrs / 40 hrs = **100% of half-time role** (per constraints).

**Feasibility Check**: 71.7 hrs fits in 10 working days (40 + 40 dev-hours from two devs + 40 half-time tester = 120 total capacity). Schedule is tight but achievable if PayGate sandbox is available and no major bugs emerge.

---

## 8. Budget & Schedule

**Budget**: Assumed cost model is internal headcount (no external tools or contractors).

| Resource | Rate (assumed) | Hours | Cost |
| --- | --- | --- | --- |
| Dev 1 @ $150/hr | $150/hr | 24.4 | $3,660 |
| Dev 2 @ $150/hr | $150/hr | 7.7 | $1,155 |
| Test Engineer @ $100/hr (half-time salary) | $50/hr (half-time rate) | 39.6 | $1,980 |
| **Test Tools, PayGate Sandbox (no cost)**  | $0 | — | $0 |
| **TOTAL** | — | **71.7** | **$6,795** |

---

**Schedule** (10 working days; 2026-10-28 to 2026-11-11, excluding weekends; assume no holidays):

| Week | Day | Activity | Owner | Blocker? | PayGate Availability |
| --- | --- | --- | --- | --- | --- |
| **Week 1** | **Wed 10/30** | Test planning, risk register finalized; unit test design kickoff | QA + Dev 1 | NO | N/A (local dev, no PayGate yet) |
| | **Thu 10/31** | Unit tests scaffold (split calc, decision table); local mock PayGate | Dev 1 + Test Eng | NO | ✅ Available |
| | **Fri 11/1** | Unit tests complete, ≥90% coverage; refund logic reviewed by Dev 2 | Dev 1 + Dev 2 | YES (gate on unit test pass) | N/A |
| **Week 2** | **Mon 11/4** | Integration test design (PayGate API contract); local mock refinement | Dev 2 + Test Eng | NO | N/A |
| | **Tue 11/5** | Integration tests run on PayGate sandbox; first E2E smoke (happy path) | Dev 2 + Test Eng | YES (PayGate availability) | ✅ Available |
| | **Wed 11/6** | Defect triage (if any from Tue); regression single-card suite automated | Dev 1 + Test Eng | NO | N/A |
| | **Thu 11/7** | E2E secondary-decline + refund SLA test (PayGate); gate cases G01–G04 run | Test Eng + Dev 1 | YES (PayGate availability) | ✅ Available |
| | **Fri 11/8** | Defect re-test, release gate review, gate sign-off prep | QA Lead + PO | YES (gate on pass) | N/A |
| **Week 3** | **Mon 11/11** | **Release** (if gate passes; else 1-day slip to Tue 11/12 for final re-test on PayGate) | DevOps | — | Conditional |

**Critical Dependency**: Gate execution requires PayGate sandbox access on Tue 11/5 and Thu 11/7. If either day is unavailable, schedule slips to next Tue/Thu or production release is delayed (risk accepted by PO).

**Resume Point** (if tester becomes unavailable mid-week):
- EOD Thu 11/7: If gate cases G01–G04 pass, defects are documented. If unfinished, priority order is G01 (calc), G03 (refund SLA), G04 (regression), G02–G05–G06 (exploratory). Exploratory and non-gate cases (R12, R13) are deferred post-release.

---

## 9. Configuration Management of Testware

| Item | Storage | Versioning | Baseline | CI/CD Integration | Restorability |
| --- | --- | --- | --- | --- | --- |
| **Test Plan (this document)** | Wiki or shared doc (not in code repo) | Dated version; corrections are in-place with timestamps | Latest approved by PO & QA Lead | N/A (reference only) | Yes; prior versions archived |
| **Risk Register** | Shared sheet or test-management tool (e.g., ADO/JIRA) | Live; re-scored on Fri of each week | Baseline established by day 1; refreshed at each milestone | Linked to defect backlog (defects auto-scored by severity) | Yes; audit trail of score changes |
| **Unit Test Cases** | `git` repo (`tests/unit/test_split_payment.py`) | Git commit SHAs; tagged at each test-suite update | Baseline = all cases passing on `release/5.3` merge commit | ✅ Run on every commit (CI); gate on ≥90% coverage | Yes; git checkout to any commit |
| **Integration Test Cases** | `git` repo (`tests/integration/test_split_payment_api.py`) | Git commit SHAs; tagged at integration-ready | Baseline = all cases passing on Tue/Thu sandbox day | ✅ Run on Tue/Thu only (scheduled CI job); gate on all pass before release | Yes; git history |
| **E2E Test Cases** | `git` repo (`tests/e2e/split_payment.spec.js` or `.ts`, Playwright) | Git commit SHAs | Baseline = gate cases (G01–G06) passing on latest build | ✅ Run nightly on staging; gate cases run Tue/Thu on sandbox | Yes; git history |
| **Regression Suite** | `git` repo (`tests/regression/single_card.spec.js`) | Git commit SHAs; version locked to baseline single-card build | Baseline = 100% pass on current prod-equivalent environment | ✅ Smoke run on every build; full run before release | Yes; git + environment snapshot |
| **Test Data Fixtures** | Test-data generator script (`scripts/seed_test_data.sh`) or inline (PayGate sandbox cards are well-known) | Git; fixtures are static (no sensitivity data stored) | Initial seed on day 1; re-seeded if corrupted | ✅ CI: confirm fixture availability before test run | Yes; script is reproducible; PayGate sandbox resets nightly |
| **Test Results & Evidence** | Shared sheet or test-management tool (e.g., TestRail, ADO); screenshots in artifact storage (S3, Azure Blob) | Result logged per case per execution (date, build #, env, pass/fail, screenshot if fail) | No standing baseline; results are individual records | ✅ Linked from CI logs; build badge shows gate status | Yes; timestamped logs retained 90 days |
| **Defect Tickets** | Tracking system (ADO/JIRA) | Issue IDs auto-generated; linked to test cases that found them | Baseline = zero open Critical/High at release gate | ✅ Defect count widget in CI dashboard; gate blocks on any Critical | Yes; issue history & audit trail |
| **Completion Report** | Wiki or shared doc; archive copy in git (`docs/release-5.3-completion.md`) | Dated; filed after release; archived | Final report is sign-off; locked after release | N/A | Yes; archived version-tagged |

**Versioning Strategy**: All test code (`*.py`, `*.js`, `*.sh`) is in git on `release/5.3` branch. Configuration (PayGate creds, environment URLs) is in a **secrets manager** (not git). Build artifacts (test results, screenshots) are logged with build number and timestamp; retained 90 days or per org retention policy.

**Baselined Environments**: Staging and PayGate sandbox each have a known-good baseline snapshot (git commit + environment config version). If an environment is corrupted, restore from baseline snapshot and re-run test suite.

**CI/CD Integration**:
- **Unit tests**: Run on every commit; block merge if coverage <90%.
- **Integration tests**: Scheduled Tue/Thu 9am; block release if any fail.
- **E2E tests**: Run nightly; gate cases run Tue/Thu before release gate sign-off.
- **Regression suite**: Run on every build; smoke (fast subset) before every release candidate.

---

## Summary Table: Test Plan at a Glance

| Section | Status |
| --- | --- |
| **Scope & Objectives** | Split payment feature, zero regression on single-card flow, automatic refund SLA <60s, integration with PayGate sandbox |
| **Assumptions** | 15 key project assumptions documented (API architecture, sandbox mirroring prod, defect in 60s measurable, etc.) |
| **Constraints** | PayGate Tue/Thu only, 10 working days, 1 half-time tester + 2 devs, 4,000 daily single-card orders at risk |
| **Stakeholders** | PO, Dev Lead, QA Lead, Test Engineer (half-time, independent), DevOps, Compliance. Roles & independence documented. |
| **Communication** | Daily async (Slack), per-execution (test log), weekly (progress report), at release (completion report + sign-off). |
| **Risk Register** | 15 risks, 4 CRITICAL (split calc, refund SLA, secondary decline handling, single-card regression), 5 HIGH (PayGate sandbox, automation readiness, late defects, security, concurrency). Mitigation strategies assigned. |
| **Test Approach** | 4 levels (Unit, Integration, E2E, Regression). 40% Unit / 40% Integration / 20% E2E pyramid. All 4 ISTQB quadrants covered. Entry & exit criteria defined. **Release gate: 6 cases** (calculation × 2, refund SLA, secondary decline, single-card regression, concurrency). |
| **Estimate** | 73.3 hrs (range 68–78 at 68% confidence). Dev 1 ~30%, Dev 2 ~10%, Test Eng 100% of half-time. Feasible within 10-day window if no major surprises. |
| **Schedule** | Week 1: Unit tests (Wed–Fri). Week 2: Integration & E2E on Tue 11/5 & Thu 11/7; gate sign-off by Fri 11/8. Week 3: Release on Mon 11/11 or slip to next Tue/Thu if gate fails. Critical dependency: PayGate sandbox availability Tue & Thu. |
| **Configuration Management** | All test code in git (unit, integration, E2E, regression); versioned by commit SHA. Secrets in secrets manager. Results logged with build # & timestamp. CI/CD gates on unit coverage, integration pass, gate case pass. Environment snapshots for restore. |

---

## Handover-Ready State

**Index of Deliverables**:
- [ ] Test plan (this document) approved by PO & QA Lead.
- [ ] Risk register finalized (Section 5); monitored weekly.
- [ ] Release gate cases (G01–G06) documented and automated (Section 6e).
- [ ] Test suites scaffolded in git: unit, integration, E2E, regression.
- [ ] Test data fixtures loaded in PayGate sandbox by day 1.
- [ ] PayGate credentials & sandbox access confirmed with DevOps by EOD Thu 10/31.
- [ ] Automation harness (API client, assertions, retry logic) ready for Dev 1 pairing.
- [ ] Resume point documented daily EOD (focus: gate cases first, exploratory deferred if needed).
- [ ] Completion report filed post-release; archived in git.

**Next Steps**:
1. **Day 1 (Wed 10/30)**: Kick-off; PO & QA sign off on plan; Dev 1 begins unit test scaffold.
2. **Day 2–3 (Thu–Fri)**: Unit tests complete; Dev 2 code review of refund logic.
3. **Day 4–5 (Tue 11/5)**: Integration & E2E smoke on PayGate sandbox; gate cases G01–G02 pass.
4. **Day 6–7 (Wed–Thu 11/6–11/7)**: Regression + gate cases G03–G06; defect triage & re-test.
5. **Day 8–9 (Fri–Mon 11/8–11/11)**: Gate sign-off by PO & QA Lead; production release.

---
