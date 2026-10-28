# Test Plan: Split Payment Feature (Release 5.3)

## 1. Context of Testing

### Scope
- **In Scope**: Split payment feature enabling customers to pay for a single order using two cards, with automated refund of the first charge if the second charge is declined within 60 seconds.
- **Out of Scope**: Changes to single-card checkout flow (tested as regression); PayGate API implementation (owned by PayGate team); PCI compliance certification (assumed pre-existing); multi-currency support beyond current scope.
- **Test Basis**: Feature brief provided; existing single-card checkout test suite; PayGate API documentation (assumed available).

### Objectives
1. Validate split payment logic correctly distributes amount across two cards, including cent remainder handling.
2. Verify automatic refund of charge 1 occurs within 60 seconds when charge 2 is declined.
3. Ensure single-card checkout continues to function without regression on production traffic (4,000 orders/day).
4. Identify and document edge cases and integration risks with PayGate sandbox.

---

## 2. Assumptions and Constraints

| Assumption | Rationale |
| :--------- | :-------- |
| Feature implemented in a full-stack web app (React frontend + API backend). | Drives test pyramid distribution; absence of stated architecture assumed based on checkout pattern. |
| Test environment mirrors production PayGate integration. | Integration testing requires realistic payment gateway behavior. |
| Staging environment available for full testing; sandbox/dev for isolated unit tests. | PayGate sandbox available only Tues/Thurs (see constraint below). |
| Current single-card checkout has passing automated test suite covering happy path and major error cases. | Baseline for regression scope; prevents testing single-card as a new feature. |
| Refund latency of 60 seconds is a hard business requirement, not guidance. | Drives test case rigor and monitoring metrics. |
| No PCI compliance re-certification required for this change. | Assumed based on integration pattern; if incorrect, balloons effort. |

| Constraint | Impact | Mitigation |
| :---------- | :----- | :--------- |
| **PayGate sandbox available Tues/Thurs only.** | Limits integration test execution to 2 days/week; cannot run full E2E suite on Fri–Mon. | Pre-write and stage all integration & E2E cases by Mon EOD; execute Tues/Thurs; use unit & component tests for rapid iteration Mon/Fri/Wed. Batch related tests to maximize sandbox availability. |
| **10 working days to release** (approx. 2026-11-13). | ~50 working hours available (1 tester × 50%); parallel developer testing helps but does not replace depth. | Risk-based testing: prioritize critical & high-level risks in first half; accept exploratory testing as "nice to have" deferred to post-release. Release gate defined to answer "ship or hold" by day 8. |
| **Half-time tester + 2 developers.** | No dedicated QA resource during dev sprints; testing partially overlaps with development. | Developers execute unit tests; tester focuses on integration & E2E. Clear handoff: code "Ready for QA" means unit tests passing. Pair testing on critical scenarios. |
| **Single-card checkout must not regress** (4,000 orders/day). | High business impact if broken; any regression failure blocks release. | Regression suite (existing single-card test suite) runs on every merge; included in release gate gate. Parallel testing: split payment tests and regression suite run concurrently when possible. |

---

## 3. Stakeholders

| Role | Name | Responsibilities | Relevance to Testing |
| :--- | :--- | :--------------- | :------------------ |
| **Product Owner** | `[Assume: assigned to feature]` | Acceptance criteria, business rules, go/no-go decision. | Confirms test scope, verifies refund timeline requirement, signs off release gate. |
| **Development Lead** | `[Assume: one of two devs]` | Feature implementation, unit testing, integration with PayGate. | Provides test data setup scripts, clarifies ambiguous requirements, debugs integration failures. |
| **QA Lead / Tester** | `[You; half-time on this feature]` | Test planning, analysis, design, execution, defect reporting, final readiness assessment. | Owns release gate execution, monitors metrics, controls test schedule. |
| **DevOps / Infra** | `[Assume: exists]` | Staging deployment, environment reset between tests, logs & observability. | Ensures test environment stability; provides build/deploy info for result traceability. |
| **PayGate Integration Lead** | `[External or internal]` | Sandbox credentials, rate limits, error codes, refund API behavior. | Clarifies PayGate API contract; validates test scenarios against real-world responses. |

---

## 4. Communication

| Item | Form | Frequency | Owner | Audience |
| :--- | :--- | :--------- | :---- | :-------- |
| **Daily standby** | Slack #qa or all-hands | Daily 9:15 AM | QA Tester | Dev, PO, Infra |
| **Test readiness** | Jira status update | EOD before test day | QA Tester | Dev, PO |
| **Blocking issues** | GitHub issue + comment | Ad-hoc within 2 hours | QA Tester | Dev, DevOps |
| **Weekly progress report** | Markdown in ticket | End of week (Fri) | QA Tester | Dev, PO, Stakeholders |
| **Release gate result** | Signed table in ticket | Day 8 or earlier | QA Tester + PO | Steering, DevOps |
| **Completion report** | Markdown post-release | Day 1 after go-live | QA Tester | Dev, PO, retrospective |

---

## 5. Risk Register

### 5.1 Risk Analysis (5×5 Matrix)

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner | Status |
| :-- | :--- | :---------------------------------------- | :--------- | :--- | :--- | :----- | :----- | :-------------------------------------------------------- | :----- | :----- |
| 1 | R01 | Automatic refund of charge 1 fails or exceeds 60-second SLA if charge 2 is declined. | Product | 4 | 5 | **20** | 🔴 CRITICAL | Unit test refund trigger logic + integration test with PayGate decline responses + end-to-end timer validation; monitor PayGate refund latency in staging. | Dev + QA | Open |
| 2 | R02 | Cent remainder distribution logic (odd cents go to card 1) fails; charge totals do not match order amount. | Product | 3 | 5 | **15** | 🔴 CRITICAL | Decision table test cases for remainder scenarios (0–99 cent remainders); property-based tests on total = card1 + card2; integration tests with realistic order amounts. | Dev + QA | Open |
| 3 | R03 | Single-card checkout regression: existing flow broken after changes to payment module. | Product | 2 | 5 | **10** | 🟠 HIGH | Execute existing single-card test suite (full regression) on staging after every merge; include in release gate; smoke test on production-like data. | QA | Open |
| 4 | R04 | PayGate sandbox unavailability outside Tues/Thurs blocks integration & E2E testing mid-week; late discovery of critical bugs. | Project | 5 | 4 | **20** | 🔴 CRITICAL | All integration test cases staged & ready by Mon EOD; Tues/Thurs reserved for execution only (batched runs); Fri–Mon testing limited to unit & component tests. Use mocked PayGate responses for Wed/Fri/Mon rapid iteration; keep mock scenarios aligned with latest sandbox behavior. | QA + Dev | Open |
| 5 | R05 | Half-time tester + 2 developers insufficient to complete full test scope in 10 working days. | Project | 4 | 4 | **16** | 🔴 CRITICAL | Risk-based prioritization: critical & high risks first; release gate defined by day 2; exploratory testing deferred post-release; developers contribute to automation (unit tests, mock-based component tests). Daily triage of blockers. | QA + Dev Lead | Open |
| 6 | R06 | Race conditions or payment state corruption if multiple concurrent split-payment requests on same order. | Product | 3 | 4 | **12** | 🟠 HIGH | Concurrency test: simulate 3–5 simultaneous split-payment attempts on same order ID; verify payment state consistency (database locks, idempotency keys); include in integration suite. | Dev + QA | Open |
| 7 | R07 | Edge case: customer selects $0 on card 1 or card 2 (all amount on second card); feature rejects or behaves unexpectedly. | Product | 3 | 3 | **9** | 🟠 HIGH | Boundary-value test cases: $0.01 to $0.99, exactly $0, negative amounts (input validation); UI validation tests. Include in release gate if UX allows $0 input. | QA | Open |
| 8 | R08 | PayGate API timeout during charge 2; first charge succeeds but refund never initiated; customer charged twice. | Product | 2 | 5 | **10** | 🟠 HIGH | Timeout test case: simulate PayGate charge 2 timeout; verify refund is queued/retried; test recovery workflow (manual refund fallback if auto-refund fails after 90 seconds). Integration test. | Dev + QA | Open |
| 9 | R09 | Incorrect error messages shown to customer (e.g., "both charges declined" when actually only one); poor UX. | Product | 2 | 3 | **6** | 🟡 MEDIUM | Error scenario matrix: charge 1 success/decline + charge 2 success/decline = 4 paths; verify correct message for each; include in E2E test suite. | QA | Open |
| 10 | R10 | Refund initiated but database transaction rolls back; inconsistent state (payment record says charged, customer not charged). | Product | 2 | 4 | **8** | 🟠 HIGH | Integration test: inject transaction failure mid-refund; verify payment state and audit log correctly reflect attempt; recovery process tested. | Dev + QA | Open |
| 11 | R11 | Poor test data availability (e.g., no test card numbers for split payments in PayGate sandbox). | Project | 3 | 3 | **9** | 🟠 HIGH | Coordinate with PayGate Integration Lead by day 1; obtain test card list, known decline scenarios, refund response formats. Build fixture set before integration testing begins. | Dev + QA | Open |
| 12 | R12 | Code review or security review uncovers critical flaw post-gate; release delayed. | Project | 2 | 4 | **8** | 🟠 HIGH | Static code review (dev peer) and security review (payment logic, PCI considerations) mandatory before merge; flagged in code-review checklist. Parallel with test execution. | Dev | Open |

---

## 6. Test Approach

### 6.1 Test Levels & Pyramid Distribution

**Architecture assumed: Full-stack web app (React frontend + Node/Python API backend).**

| Level | % of Suite | Focus | Owner | Techniques |
| :---- | :--------- | :---- | :---- | :--------- |
| **Unit (40%)** | 40 | Payment logic (split calc, remainder, validation), refund trigger, state management. | Developers | Decision tables (remainder scenarios), property-based tests (amt1 + amt2 = total), boundary-value analysis. |
| **Integration (40%)** | 40 | PayGate API integration, refund workflow, database state consistency, error handling, timeouts. | Dev + QA pair | API contract tests, state transition tests, concurrency tests, fault injection (timeout, decline). |
| **E2E (20%)** | 20 | Customer checkout flow with split payment, happy path, error paths (decline card 2, timeout), confirmation email. | QA (with dev support) | User journey tests, critical path, error recovery; run on staging with real PayGate sandbox. |

### 6.2 Test Types

| Type | Scope | Automation | Frequency |
| :--- | :----- | :--------- | :---------- |
| **Functional** | Split payment logic, refund trigger, error messages, state transitions. | Automated (unit + integration + E2E). | On every merge (unit), Tues/Thurs (integration/E2E). |
| **Regression** | Existing single-card checkout flow. | Automated (run existing suite). | On every merge affecting payment module. |
| **Performance** | Refund latency < 60 seconds under typical load; checkout response time stable. | Automated (integration); manual monitoring (E2E). | Weekly on staging; production monitoring post-release. |
| **Reliability** | Concurrency, state consistency, idempotency, recovery from failures (timeout, decline). | Automated (integration test suite). | Tues/Thurs. |
| **Exploratory** | Boundary cases, UX edge cases, unexpected input combinations. | Manual. | Post-release or final 2 days if capacity permits. |
| **Security** | Input validation (malicious amount values), idempotency key verification, no token leaks in logs. | Automated (static analysis + integration test). | Pre-merge code review. |

### 6.3 Test Techniques

- **Decision table**: Remainder distribution scenarios (0–99 cents, examples: $5.00, $5.01, $5.99, $100.00).
- **Boundary-value analysis**: Amount edge cases ($0.01, max order amount, single-cent orders).
- **State transition**: Payment states (pending card 1, card 1 success, pending card 2, card 2 success/decline, refund pending, refund complete, error).
- **Pairwise testing**: Card 1 result (success/decline) × Card 2 result (success/decline/timeout) = 6 scenarios.
- **Error guessing**: PayGate API errors (rate limit, temporary outage, malformed response).
- **Property-based testing (unit)**: For all splits of an amount, card1 + card2 = order total.

### 6.4 Test Independence

| Level | Who Tests | Degree | Rationale |
| :----- | :--------- | :------ | :--------- |
| Unit | Developers (author peers review) | Some | Author writes tests; peer reviews before merge to catch obvious gaps. |
| Integration | Dev + QA pair | High | QA brings test mindset; dev understands implementation; together they design API contract & state scenarios. |
| E2E | QA (tester independent of dev) | High | QA executes customer scenarios from outside; not authored by feature dev; finds UX & flow issues devs may miss. |
| Regression | QA + automated CI | Very high | Regression suite owned by test team, independent of current feature; runs in CI on every change. |

### 6.5 Testing Quadrants (Brian Marick)

| Quadrant | Role | Included in Plan? | Notes |
| :-------- | :--- | :----------------- | :----- |
| **Q1: Technology-facing, Supports Team** | Unit tests, integration tests, static analysis. | ✅ Yes | Decision tables, property tests, API contract tests all support development & rapid iteration. |
| **Q2: Business-facing, Supports Team** | Acceptance criteria checklist, E2E smoke tests for PO sign-off. | ✅ Yes | Release gate cases (below) prove business requirements to PO. |
| **Q3: Business-facing, Critiques Product** | E2E functional tests, error scenarios, exploratory testing. | ✅ Yes | E2E suite & exploratory tests find real-user issues (UX, error messages, edge cases). |
| **Q4: Technology-facing, Critiques Product** | Performance monitoring, reliability tests (concurrency, failure recovery), security scanning. | ✅ Yes | Refund latency monitoring, timeout & decline handling, input validation. |

### 6.6 Entry Criteria (When to Start Testing)

- [ ] Feature branch code merged to main and deployed to staging.
- [ ] Unit tests passing (100% of new code paths covered by developer tests).
- [ ] Feature implementation marked "Ready for QA" in JIRA/ADO.
- [ ] PayGate test credentials & sandbox environment confirmed available & accessible.
- [ ] Test data fixture set prepared (test cards, decline scenarios, known PayGate responses).
- [ ] Staging database seeded with sample orders (various amounts, currencies if applicable).
- [ ] Test environment stable: no known infrastructure issues; DevOps confirms readiness.

### 6.7 Exit Criteria (When to Stop Testing & Release)

- [ ] Release gate cases (§6.10 below) **100% executed and passing**.
- [ ] All P0 critical test cases (R01, R02, R03, R04, R05 rows in risk register) **passing or waived by PO**.
- [ ] All P1 high-severity test cases (R06–R12 rows) **passing or recorded as known-issues with risk acceptance**.
- [ ] Regression test suite (single-card checkout) **passing on latest build**.
- [ ] Refund latency monitoring: **no cases exceed 70 seconds** (buffer above 60-second requirement); mean latency < 30 seconds.
- [ ] **Zero critical defects** open; zero high-severity defects that block customer checkout.
- [ ] Performance baseline: checkout response time **stable vs. pre-feature measurements**.
- [ ] Test summary (§9 below) **signed off by QA Tester and Product Owner**.

### 6.8 Release Gate

**Gate Objective**: Confirm split payment feature works as designed and single-card checkout has no regression.

| # | Case ID | Description | Acceptance Criteria | Risk Covered | Result | Notes |
| :- | :------ | :---------- | :------------------ | :----------- | :----- | :---- |
| 1 | RG-001 | Split payment: Customer pays $100.00 with $60.00 on card 1, $40.00 on card 2; both succeed. | Charge 1: $60.00 OK; Charge 2: $40.00 OK; Order marked "Paid"; Confirmation email sent. | R02 (logic correctness) | ❌ Pending | Happy path success. |
| 2 | RG-002 | Split payment with odd remainder: $50.01 split 50/50 → card 1: $25.01, card 2: $25.00 (cent on card 1). | Charge 1: $25.01 OK; Charge 2: $25.00 OK; Order marked "Paid"; Correct card amounts logged. | R02 (remainder logic) | ❌ Pending | Exercises cent-remainder rule. |
| 3 | RG-003 | Split payment: Charge 1 succeeds ($60.00), Charge 2 declined; refund of $60.00 triggered within 60 seconds. | Charge 1 refund initiated < 60 sec after charge 2 decline; refund confirmed in PayGate response; customer notified; order marked "Refunded". | R01 (refund SLA) | ❌ Pending | Critical: refund latency < 60 sec verified by logs. |
| 4 | RG-004 | Single-card checkout regression: Existing flow (1 card, full amount) continues to work. | Single card charge succeeds; order marked "Paid"; existing cart clearing & inventory logic unaffected; confirmation email sent. | R03 (regression) | ❌ Pending | Execute 1 existing test case from single-card suite. |
| 5 | RG-005 | Split payment: Charge 1 times out (PayGate no response > 30 sec); charge 2 not attempted; order marked "Pending" and recovery workflow initiates. | Order state = "Pending"; charge 2 not sent to PayGate; retry mechanism queued or manual review flagged; customer informed; no phantom charge. | R08 (timeout handling) | ❌ Pending | Integration test simulating timeout. |
| 6 | RG-006 | Split payment edge case: $0.01 order, split $0.01 card 1 / $0.00 card 2; charges succeed (or app rejects split if invalid). | If allowed: both charges OK; If rejected: validation error shown & order not created. Behavior matches spec. | R07 (edge case validation) | ❌ Pending | Boundary check. |
| 7 | RG-007 | Concurrent requests: Two split-payment attempts on same order ID simultaneously; system rejects duplicate or queues second; no double charge. | First request succeeds; second rejected with "Order already in payment" or queued as retry; final state unambiguous (1 or 2 charges, not 3+). | R06 (concurrency) | ❌ Pending | Concurrency test. |

**Test Execution Order**: Risk-based. Run in sequence: RG-001, RG-002, RG-003 (highest risk) → RG-004, RG-005, RG-006, RG-007 (supporting cases). Dependencies: RG-003 requires PayGate sandbox available (Tues/Thurs). If Sandbox unavailable by day 8, RG-003 may be deferred pending urgent fix or escalated for PO decision.

---

## 7. Estimate

### 7.1 Estimation Technique
**Expert-based, Three-Point Estimation (E = (a + 4m + b) / 6; SD = (b − a) / 6).**

### 7.2 Effort Estimate

| Task | Optimistic (a) | Most Likely (m) | Pessimistic (b) | E (hours) | Std Dev | Risk-Adjusted |
| :--- | :------------ | :-------------- | :-------------- | :------- | :----- | :----------- |
| Test analysis & planning | 1 | 2 | 4 | 2.2 | 0.5 | 2.2 |
| Unit test design & review | 2 | 3 | 6 | 3.3 | 0.7 | 3.3 |
| Integration test design & build | 4 | 7 | 12 | 7.3 | 1.3 | 9.3 (↑ R04: sandbox availability) |
| E2E test design & build | 3 | 5 | 10 | 5.5 | 1.2 | 6.6 (↑ R04) |
| Regression suite execution | 2 | 2.5 | 4 | 2.7 | 0.3 | 2.7 |
| Release gate execution & troubleshooting | 2 | 4 | 8 | 4.3 | 1.0 | 5.3 (↑ R01, R03) |
| Defect analysis & re-test | 2 | 4 | 8 | 4.3 | 1.0 | 6.5 (↑ discovery risk) |
| Exploratory testing (if time permits) | 1 | 2 | 4 | 2.2 | 0.5 | Deferred |
| **TOTAL (without exploratory)** | **17** | **28** | **52** | **31.7** | **6.5** | **35.9** |

### 7.3 Assumptions
- Half-time tester: 25 working hours available over 10 working days (~2.5 hrs/day).
- Developers contribute unit test execution & pair on integration tests; QA leads test design & execution.
- Estimated total from table (35.9 hrs) assumes **parallel testing**: dev unit tests run in parallel with QA integration/E2E; effort is QA-focused effort.
- Sandbox availability (Tues/Thurs only) **adds 25–30% overhead** to integration/E2E due to batching and delay cycles (captured in risk-adjusted rows).
- No exploratory testing in main estimate; deferred post-release unless critical gaps emerge.
- Contingency built into "pessimistic" scenarios; does not double-estimate.

### 7.4 Scheduling Within 10 Working Days

| Phase | Days | Effort (QA) | Status | Notes |
| :----- | :--- | :---------- | :----- | :---- |
| Analysis, planning & risk register | Day 1 | 2 hrs | Sequential | Deliver by EOD day 1; gate approval for test kickoff. |
| Test design (unit, integration, E2E) | Days 1–3 | 8 hrs | Parallel with dev | Dev designs unit tests; QA designs integration/E2E; stakeholder review day 3 EOD. |
| Unit test execution & debugging | Days 2–4 | 2 hrs (QA review) | Parallel with dev | Developers execute; QA spot-checks & reviews. Must pass before integration begins (entry criteria). |
| Integration test execution (Tues/Thurs only) | Days 4, 6, 8 | 12 hrs | Batched | Sandbox available only Tues/Thurs; cases staged by Mon EOD each week; execute Tues/Thurs; debug Wed/Fri if needed. |
| E2E test execution | Days 5–7 | 6 hrs | Wed/Fri + Tues/Thurs | Mock-based component tests Wed/Fri; sandbox-based E2E Tues/Thurs. |
| Regression suite execution | Day 7 | 3 hrs | Final QA pass | Single-card checkout full regression; automation runs in CI; QA manually verifies critical paths. |
| Release gate execution | Day 8 | 3 hrs | Final gate | Execute RG-001–RG-007 in sequence; troubleshoot failures same day if possible. |
| Exploratory testing (optional) | Days 8–9 | 2 hrs | If time; else deferred | Post-gate; low priority. |
| Completion report & handover | Day 10 | 1 hr | Final report | Sign-off, metrics, lessons learned. |
| **TOTAL QA Effort** | **10 days** | **~37 hrs** | | Fits within half-time allocation (25 theoretical; parallel dev testing adds capacity). |

---

## 8. Budget and Schedule

### 8.1 Resource Allocation

| Resource | Role | Allocation | Effort | Cost (est.) |
| :--------- | :--- | :---------- | :------ | :--------- |
| **QA Tester** | Test lead, design, execution, gate sign-off. | 50% (0.5 FTE) | ~37 hours | $2,300 (assuming $62/hr loaded rate; 10 days × 5 hrs/day). |
| **Developer 1** | Unit test author, integration test pair, refund logic owner. | 100% | ~30 hours | $2,700 (est.). |
| **Developer 2** | Feature implementation, PayGate integration, unit test author. | 100% | ~30 hours | $2,700 (est.). |
| **DevOps / Infra** | Staging deployment, test data reset, logs. | 10% | ~5 hours | $300 (est.). |
| **PayGate Integration Lead** | Sandbox support, API clarification. | Ad-hoc | ~3 hours | Included in existing support contract. |
| **Total** | | | ~105 hours | ~$8,000 fully loaded (est.). |

### 8.2 Timeline (10 Working Days from 2026-10-28)

- **Day 1 (Wed 2026-10-29)**: Planning, risk register, test design kickoff. Entry criteria check.
- **Day 2 (Thu 2026-10-30)**: Unit test design; PayGate Integration Lead sandbox credential handoff.
- **Day 3 (Fri 2026-10-31)**: Test design complete; pair planning for integration suite.
- **Day 4 (Mon 2026-11-03)**: Unit tests by devs; QA integration test staging complete.
- **Day 5 (Tue 2026-11-04)**: **Sandbox available**. Integration test execution begins; E2E mock-based tests run.
- **Day 6 (Wed 2026-11-05)**: Integration test results analysis; E2E design finalized; quick unit test re-checks.
- **Day 7 (Thu 2026-11-06)**: **Sandbox available**. E2E sandbox execution; regression suite run.
- **Day 8 (Fri 2026-11-07)**: Release gate execution (RG-001–RG-007). Troubleshoot failures. Go/No-go decision by EOD.
- **Day 9 (Mon 2026-11-10)**: Exploratory testing (if gate passed & time permits); fix minor issues if any.
- **Day 10 (Tue 2026-11-11)**: **Sandbox available**. Final verification; completion report; stakeholder sign-off.
- **Release window**: After day 10 sign-off (approximate 2026-11-13 for 10 working days).

### 8.3 Critical Path

1. **Entry criteria met** (dev unit tests passing, code in staging).
2. **Integration tests staged & ready** by Mon EOD each week.
3. **Sandbox execution** on Tues/Thurs—no slip; blocker dependency.
4. **Release gate results** known by day 8 EOD—gates go/no-go decision.
5. **Risk R01 (refund SLA)** must pass gate; cannot be waived; critical business requirement.

---

## 9. Configuration Management of Testware

### 9.1 Identification & Version Control

- **Test artifacts** (plans, cases, scripts, results): Git repository branch `qa/split-payment-5.3`.
- **Test suite code** (Cypress, Vitest, Jest, pytest): Stored in `/tests/integration/split-payment/` and `/tests/e2e/split-payment/` directories.
- **Test data fixtures**: `/tests/fixtures/split-payment-data.json` (test cards, PayGate mock responses, sample orders).
- **Versioning**: Each test script tagged with feature version (e.g., `v5.3.1`, `v5.3.2`) on merge to main.

### 9.2 Configuration Items (CIs)

| CI | Type | Location | Owner | Version Control | Baseline |
| :- | :--- | :------- | :---- | :-------------- | :---------- |
| Test Plan | Document | `/docs/qa/test-plan-5.3.md` | QA Lead | Git, dated edits section | Day 1 approval |
| Test Cases | Test Code | `/tests/integration/split-payment/` | QA + Dev | Git, CI/CD runs on commit | Day 3 design complete |
| Test Data | Fixture File | `/tests/fixtures/split-payment-data.json` | QA | Git | Day 4 updated post-PayGate clarification |
| Integration Suite | Test Code | `/tests/integration/split-payment/spec.js` | Dev + QA | Git, automated CI/CD | Day 5 first execution |
| E2E Suite | Test Code | `/tests/e2e/split-payment/checkout.spec.ts` | QA | Git, automated CI/CD | Day 5 first execution |
| Regression Suite | Test Code | `/tests/regression/checkout-single-card.spec.ts` | QA (existing) | Git, unchanged | Baseline pre-feature |
| Build Artifact | Application Build | CI/CD output (tag: `release/5.3.0-rc1`, etc.) | DevOps | Git tags, artifact store | Day 4 deployed to staging |
| Staging Environment | Infrastructure | AWS/GCP/etc. staging account | DevOps | Terraform / CloudFormation versioned | Day 1 confirmed ready |
| Test Results Log | Execution Report | `/test-results/split-payment-run-2026-11-06.json` | QA | Archived in results folder | Day 7 final gate run |

### 9.3 Traceability & References

- **Risk → Test Case**: Each test case ID links to one or more risk rows (e.g., RG-003 → R01, R08).
- **Test Case → Build Version**: Every result logged with `buildVersion` (e.g., `5.3.0-rc1`) and environment (staging).
- **Defect → Test Case**: Each bug ticket references the case ID that found it (e.g., "Found by RG-003").
- **Requirement → Test Case**: Feature brief statements mapped to risk register rows; rows map to test cases (traceability implicit via risk matrix).

### 9.4 Environment & Baseline Management

| Environment | Used For | Owner | Reset Frequency | Build Version |
| :---------- | :-------- | :---- | :------------- | :------------ |
| **Developer Local** | Unit test execution | Developers | Per-commit | Feature branch |
| **CI/CD Pipeline** | Automated unit & linting | DevOps | Per-commit | Feature branch |
| **Staging** | Integration & E2E tests | DevOps | Post-merge (day 4) | `5.3.0-rc1` + latest |
| **PayGate Sandbox** | Integration test (Tues/Thurs) | DevOps + PayGate partner | Daily reset (if needed) | Consistent test card list |
| **Production** | Post-release monitoring | DevOps | N/A (live) | `5.3.0` release tag |

**Reproducibility**: Every test result includes `{buildVersion, environment, timestamp, tester, sandbox-api-version}`. If a case fails, it can be re-run on the same build & environment within 7 days.

### 9.5 Handover & Continuity

- **Master test plan** (this document): Single source of truth; edits tracked with date & author in an "Edits" section (added below if needed).
- **Status matrix**: Maintained in `/docs/qa/split-payment-status.md`, updated daily; shows pass/fail/blocked status per case.
- **Resume point** (§9.6 below): If testing is interrupted, resume instructions are in the status matrix.
- **Post-release monitoring**: Refund latency metrics logged in production dashboard; OncAll paged if SLA breached; monitoring config checked into `/ops/monitoring/split-payment-alerts.yaml`.

---

## 9.6 Resume Point (If Testing Interrupted)

**If testing pauses and must resume:**

1. **Check current build version** in staging (ask DevOps for latest deployed version).
2. **Check test status matrix** at `/docs/qa/split-payment-status.md` to see which cases have passed, failed, or are blocked.
3. **If a case was in-progress**:
   - Read its "Notes" column to see what was being debugged.
   - Verify the failure root cause is still present (may have been fixed on main).
   - Re-run from entry point or from the specific assertion that failed.
4. **If sandbox was unavailable**:
   - Check PayGate status page (assume URL: `status.paygate.io`).
   - If still down, escalate to PayGate Integration Lead & PO; do not delay release beyond day 10 without approval.
5. **If a defect was found**:
   - Check if it's been fixed on main or marked as known-issue in risk register.
   - Re-test after fix is deployed to staging.

---

## 10. Deviations from Standard Test Policy

| Standard Practice | Deviation | Reason | Impact |
| :----------------- | :--------- | :----- | :----- |
| Full E2E suite before release. | E2E suite limited to critical & high-risk paths; exploratory testing deferred post-release. | Time constraint (10 days, half-time tester); sandbox availability (Tues/Thurs only) limits execution windows. | Risk accepted by PO; post-release exploratory testing planned for days 11–15. |
| 100% code coverage by unit tests. | Target 80% code coverage for new code; payment logic (highest risk) at 90%+; utility functions at 70%+. | Developer capacity; 90% on critical path sufficient to detect major bugs. | Monitored post-release; coverage gaps tracked in retrospective. |
| Integrated environment for all tests. | Unit tests run in isolation (mocked PayGate); integration tests use staging + sandbox; E2E uses staging + sandbox. | Sandbox limited availability; parallel testing requires mix of mocked & real. | Mocked tests run fast & frequently (Mon/Wed/Fri); real sandbox tests (Tues/Thurs) are final verification. |
| Manual regression testing. | Regression suite fully automated; QA manually spot-checks critical paths on final build. | Time constraint; automation faster & more reliable at scale (4,000 orders/day impact). | Critical single-card paths spot-checked manually day 7; full automation suite in CI/CD. |

---

## 11. Metrics to Collect

### 11.1 Test Progress Metrics

Collected daily by QA; reported weekly.

| Metric | Goal | Baseline | Tracking |
| :----- | :--- | :-------- | :------- |
| **Test cases designed** | 100% by day 3. | 0 | Count of cases in test suite (target: ~30 cases total: 10 unit, 12 integration, 8 E2E). |
| **Test cases automated** | 100% by day 7. | 0 | Count of runnable case scripts. |
| **Cases passed** | 100% by day 8 (release gate). | 0 | % of gate cases (RG-001–RG-007) passing. |
| **Cases blocked** | ≤ 1 at any time (escalate if more). | 0 | Count of cases waiting on external dependency (PayGate, dev fix, env issue). |
| **Test execution time (per run)** | Unit: < 5 min; Integration: < 20 min; E2E: < 15 min. | TBD (day 1 baseline) | Record wall-clock time per suite per day. |

### 11.2 Defect Metrics

Collected per test cycle; helps assess quality.

| Metric | Goal | Tracking |
| :----- | :--- | :------- |
| **Critical defects found** | ≤ 3 (higher = insufficient dev unit testing). | Count & severity per day. |
| **High-severity defects found** | ≤ 5 (minor issues, easily fixed). | Count & severity per day. |
| **Defect fix rate** | ≥ 80% closed by day 9 (before release). | Closed count / Total found. |
| **Defect escape rate (post-release)** | ≤ 1 production defect in week 1 (from pre-release testing). | Jira query: `project = "Prod Issues" AND labels = "5.3" AND created >= 2026-11-13`. |

### 11.3 Coverage Metrics

| Metric | Goal | Tracking |
| :----- | :--- | :------- |
| **Code coverage** (new payment logic) | ≥ 85% (ideally 90% on refund logic). | Tool: Istanbul/JaCoCo; report day 7. |
| **Risk coverage** (test cases per risk row) | 100% of critical/high risks have ≥1 dedicated test case. | Matrix: Risk ID → Test Case ID. |
| **Requirement coverage** (feature brief → test cases) | 100% of brief statements covered. | Traceability matrix review day 3. |

### 11.4 Risk Monitoring Metrics

| Metric | Goal | Tracking |
| :----- | :--- | :------- |
| **R01 refund latency** | Mean < 30 sec, p95 < 60 sec (no case exceeds SLA). | Log every refund request → confirmation time in test results. |
| **R03 regression pass rate** | 100% of existing single-card cases pass. | Run full regression suite day 7; report % passing. |
| **R04 sandbox availability** | Tues/Thurs accessible; no planned downtime. | Manual check Tues/Thu mornings (7 AM); escalate if down. |
| **R05 test progress vs. schedule** | On track by day 4 (test design 50%+, case count ≥ 15). | % of test plan milestones met per day. |

---

## 12. Test Summary & Sign-Off

**To be completed day 10:**

```
# Release 5.3 Split Payment — Test Summary

## Overall Result: [PASS / HOLD / FAIL]

### Metrics
- Cases executed: X / Z (% pass rate)
- Defects found: X critical, Y high, Z medium
- Release gate: [PASS / HOLD]
- Coverage: X% code, 100% risk

### Sign-Off
- QA Tester: _____________________ Date: __________
- Product Owner: _________________ Date: __________
- DevOps (deployment): __________ Date: __________
```

---

## 13. Edits & Corrections

*(Added as review feedback is incorporated pre-release.)*

| Date | Section | Change | Reason | Reviewer |
| :--- | :------ | :----- | :----- | :------- |
| TBD | TBD | TBD | TBD | TBD |

---

**End of Test Plan.**
