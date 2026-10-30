# Test Plan: Split Payment Feature (Release 5.3)

## 1. Context of Testing

**Scope**: Split Payment functionality enabling customers to pay a single order using two credit cards, with automatic refund of the first charge if the second charge is declined.

**Test Basis**: 
- Feature specification: split amount allocation (cents), two-card charge orchestration, 60-second refund SLA
- External PayGate payment gateway API
- Existing single-card checkout workflow (regression scope)

**Test Objectives**:
- Verify correct amount calculation and allocation (including remainder cent logic)
- Confirm both charges execute or fail safely
- Validate automatic refund completes within 60 seconds when second charge is declined
- Ensure single-card checkout remains functional (4,000 orders/day impact)
- Detect payment state machine defects (race conditions, incomplete transactions)

---

## 2. Assumptions and Constraints

| Assumption | Rationale |
|-----------|-----------|
| Release deadline is 2026-11-13 (10 working days from today, 2026-10-28) | Explicit constraint |
| PayGate sandbox available Tuesdays and Thursdays only; no production testing | Explicit constraint; all integration tests scheduled for Tue/Thu windows |
| One tester at 50% FTE = ~50 hours available before release | 10 working days × 5 hours/day |
| Feature code is merged and compiles with zero errors at QA intake | Standard entry criterion |
| Test environment is QA-stage with PayGate sandbox credentials pre-configured | Deployment responsibility of DevOps; testing assumes ready state |
| Single-card payment code paths are unchanged (no refactor of existing logic) | Minimizes regression scope; if violated, regression suite grows |
| External PayGate API behavior is deterministic (no flaky responses in sandbox) | PayGate SLA assumption; if violated, test results become unreliable |
| Two developers remain available part-time for pairing on integration test execution | Developer involvement needed for API mock/stub setup and debugging |
| Refund automation is triggered server-side within the 60-second window; no manual intervention | Feature requirement interpretation |
| PCI compliance review has been completed separately (not in QA scope) | Assumption: security review is out of scope here |

---

## 3. Stakeholders

| Role | Responsibility | Relevance to Testing |
|------|-----------------|---------------------|
| **Product Owner** | Acceptance of release gate; sign-off on payment correctness | Owns correctness definition; reviews test results; approves go/no-go |
| **QA Lead (1 tester, 50% FTE)** | Test analysis, design, execution, defect reporting, risk tracking | Performs all testing activities; creates test cases; reports metrics daily |
| **Development Team (2 engineers)** | Implementation; PayGate integration; refund automation code | Pair on integration tests; debug failures; fix defects; owner of release gate sign-off |
| **DevOps / Infra** | Environment setup, PayGate sandbox access, QA deployment | Ensures test environment is ready before QA intake (entry criterion) |
| **PayGate Support** | API documentation, sandbox stability, incident response | External; escalation point for API failures; no direct testing role |

---

## 4. Communication

| Forum | Frequency | Participants | Content |
|-------|-----------|--------------|---------|
| Daily standup | 9:30 AM, weekdays | QA + 2 developers | Test progress, blockers, PayGate availability window conflicts |
| Risk review meeting | Every 2 working days (Mon, Wed) | QA Lead + PO + dev lead | Re-score risk register, move cases into/out of release gate, escalate blockers |
| End-of-day summary | 5 PM, weekdays | QA + PO (async) | Test execution count, defects opened/closed, regression status |
| PayGate availability alert | Tue/Thu mornings | QA team | Confirm sandbox is live; schedule integration test windows |
| Final readiness review | Day before release (2026-11-12) | QA Lead, Dev Lead, PO | Release gate execution, defect status, sign-off decision |

**Document Templates**:
- Daily test log: test case ID, status (PASS/FAIL/BLOCKED), defect link, evidence (screenshots for failures)
- Defect report: severity (Critical/High/Medium/Low), reproducible steps, expected vs. actual, PayGate API response (if applicable)
- Risk register: updated in-place with dated corrections (no deletion of prior scores)

---

## 5. Risk Register (5×5 Product & Project Risk Matrix)

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner | Status |
|---|----|--------------------|----------|---|---|-------|---------|----------------------|-------|--------|
| 1 | R01 | Amount split calculation error (e.g., remainder cent logic inverted) | Product | 2 | 5 | 10 | 🟠 HIGH | Unit test 100% of split scenarios; code review by 2nd developer; table-driven tests for edge cases (0.01 split) | Dev + QA | To do |
| 2 | R02 | First charge succeeds, second charge fails → no automatic refund or delayed refund | Product | 3 | 5 | 15 | 🔴 CRITICAL | Automate refund flow with E2E test; monitor server logs for refund completion time; set PayGate webhook timeout to 30s (half of 60s SLA); integration test with PayGate sandbox (Tue/Thu only) | Dev + QA | To do |
| 3 | R03 | Both charges fail silently or user is not notified of payment status | Product | 2 | 4 | 8 | 🟠 HIGH | Test error handling for all PayGate decline codes; verify UI shows error message for each scenario; integration test with PayGate sandbox | QA | To do |
| 4 | R04 | Single-card checkout regression: new code breaks existing 4,000 orders/day flow | Product | 2 | 5 | 10 | 🟠 HIGH | Run existing single-card regression suite (all 30+ cases); smoke test on QA after deployment; monitor UAT for anomalies | QA | To do |
| 5 | R05 | Race condition: user submits refund request while first charge refund is in-flight | Product | 1 | 4 | 4 | 🟡 MEDIUM | Idempotency testing: submit same refund request twice, verify refund happens only once; integration test with stubs for timing control | Dev | To do |
| 6 | R06 | PayGate sandbox unavailable or returns unexpected API responses | Project | 3 | 4 | 12 | 🟠 HIGH | PayGate sandbox confirmed available Tue/Thu only (hard constraint); schedule all integration tests within windows; fallback: use PayGate API mocks/stubs for non-Tue/Thu testing | Dev + QA | To do |
| 7 | R07 | Test execution time overruns 50 available hours; release gate cases not completed in time | Project | 3 | 4 | 12 | 🟠 HIGH | Prioritize release gate first; automate regression suite to run in parallel (single-card tests); defer exploratory testing to post-release if time is tight; daily stand-up tracking | QA | To do |
| 8 | R08 | Payment state machine in inconsistent state (e.g., first charge marked refunded but second charge never attempted) | Product | 2 | 4 | 8 | 🟠 HIGH | State transition testing: verify all state paths through decision table (success, fail card1, fail card2, timeout); integration test with controlled PayGate delays | Dev + QA | To do |
| 9 | R09 | Refund completes outside 60-second SLA (e.g., PayGate is slow or network latency) | Product | 2 | 3 | 6 | 🟡 MEDIUM | Measure refund completion time in integration tests; set PayGate sandbox timeout to 30s; log timestamps at each stage (charge1, charge2, refund start, refund end) | QA | To do |
| 10 | R10 | PCI compliance issue in new payment code paths (credential storage, logging) | Product | 1 | 5 | 5 | 🟡 MEDIUM | Code review checklist for PCI DSS compliance (no card data in logs, no storage); security team sign-off (out of QA scope but logged here for traceability) | Security + Dev | To do |

---

## 6. Test Approach

### Test Levels & Types

**Unit Testing (40% of effort)**
- **Scope**: Amount calculation logic, validation, edge cases
- **Techniques**: Equivalence partitioning (valid splits, edge amounts), boundary value analysis (0.01 splits, integer + remainder), decision tables (all paths through split logic)
- **Independence**: Developer (author) with peer review; QA reviews test cases post-writing
- **Deliverables**: Test cases for split amount calculation, remainder cent logic, validation errors
- **Entry Criteria**: Feature code merged, compiles, zero lint errors
- **Exit Criteria**: 100% coverage of split logic paths; all cases passing

**Integration Testing (35% of effort)**
- **Scope**: Payment orchestration, PayGate API calls, refund automation, state machine
- **Techniques**: State transition testing (all charge/refund sequences), API contract testing (PayGate request/response validation), error injection (declined cards, timeouts)
- **Independence**: Developers with QA pairing; QA designs and executes test cases
- **Deliverables**: Test cases for refund flow, charge sequences, PayGate API interactions, error scenarios
- **Entry Criteria**: Unit tests passing; PayGate sandbox credentials configured; test data seeded
- **Exit Criteria**: Release gate cases passing; all charge/refund scenarios validated

**System & E2E Testing (25% of effort)**
- **Scope**: Full split payment user journey (UI → checkout → two-card entry → charges → success/error display), regression on single-card flow
- **Techniques**: User scenario testing (happy path, error path), exploratory testing (UI edge cases, back-button behavior), regression testing (existing checkout)
- **Independence**: QA (high independence); developers available for debugging
- **Deliverables**: Test cases for split payment UX, regression suite for single-card, exploratory findings log
- **Entry Criteria**: Integration tests passing; QA environment deployed; test users configured
- **Exit Criteria**: Release gate cases passing; single-card regression suite 100% passing

### Test Execution Order (Risk-Based)

1. **Release gate cases** (first): 8 critical cases (see Release Gate table below) → must pass before release
2. **High-risk integration tests** (parallel with gate): R02 (refund automation) and R04 (single-card regression) cases
3. **Unit tests** (as needed): Support for gate case failures
4. **Exploratory testing** (if time permits): Edge cases, boundary conditions
5. **Post-release retesting** (if defects found): Confirmation on fixed defects

**Constraints overriding order**:
- PayGate sandbox available Tue/Thu only → integration tests scheduled within these windows
- Developers' availability for pairing → schedule integration test sessions with both devs confirmed

### Test Basis & Traceability

- Feature specification (split amount logic, refund SLA)
- PayGate API documentation (charge, refund endpoints)
- Single-card checkout regression suite (existing test cases)
- Risk register (R01–R10 drive test case selection)

### Release Gate (Go/No-Go Criteria)

**Definition**: Minimum set of 8 cases that answer "do the fixes work?" and "did the change break existing checkout?"

| # | Gate Case ID | Test Scenario | Expected Result | Automation | Owner |
|---|---------------|--------|-----------------|------------|-------|
| G1 | TC-SP-001 | Split $100.00: $60 on card 1, $40 on card 2; both cards valid | Both charges succeed; order total matches | E2E automated | QA |
| G2 | TC-SP-002 | Split $100.01: $60 on card 1, $40.01 on card 2; remainder cent on card 1 (validates logic) | First charge $60.01, second $40; order total $100.01 | Integration (PayGate API) | Dev + QA |
| G3 | TC-SP-003 | Split $50.00: card 1 valid, card 2 declined | First charge succeeds, refund initiated; order marked failed; customer sees error | Integration + E2E | QA |
| G4 | TC-SP-004 | Refund on G3 completes within 60 seconds | Refund timestamp − charge1 timestamp ≤ 60s; PayGate returns refund success | Integration (mocked PayGate delay testing) | Dev + QA |
| G5 | TC-SP-005 | Single-card payment $100 (regression): existing checkout not broken | Charge succeeds; order placed; same behavior as pre-release | E2E automated (existing test) | QA |
| G6 | TC-SP-006 | Split UI displays: split amount inputs, currency, card selector | Both card fields visible, placeholders correct, no UI errors | E2E automated | QA |
| G7 | TC-SP-007 | Both cards declined: card 1 and card 2 both fail | Error shown; no charges made; no refund attempted | Integration + E2E | QA |
| G8 | TC-SP-008 | Edge case: split $0.01 (1¢ on card 1, $0 on card 2) | Card 1 charged $0.01, card 2 not charged; order succeeds | Unit + Integration | Dev |

**Gate Pass/Fail Decision**: Release approved only if ALL 8 cases PASS and zero Critical-severity defects open. If any gate case fails, defect is logged, fixed, and case re-executed before release decision.

### Entry & Exit Criteria

**Entry Criteria for System Testing** (when to START):
- [ ] Split payment feature code merged to QA branch with zero compilation/linting errors
- [ ] All unit tests passing locally (developer verification)
- [ ] QA environment deployed and accessible
- [ ] PayGate sandbox credentials configured and verified (test charge succeeds)
- [ ] Test data (test card numbers, amounts) prepared and seeded
- [ ] Single-card checkout regression test suite extracted and ready to run
- [ ] Risk register reviewed and signed by QA Lead and Dev Lead

**Exit Criteria for Release** (when to STOP and release):
- [ ] All 8 release gate cases executed and PASSING
- [ ] Single-card regression suite (30+ cases) executed and 100% PASSING
- [ ] Zero Critical-severity defects open
- [ ] Zero High-severity defects open, OR each High defect has a documented Product Owner exception
- [ ] Refund automation tested and confirmed: refund completes ≤ 60 seconds in 3+ test runs
- [ ] Test summary report signed by QA Lead and Product Owner
- [ ] Configuration management checklist complete (see item 9 below)

---

## 7. Test Effort Estimation

**Technique**: Expert-based, three-point estimation (optimistic, most likely, pessimistic)

**Formula**: E = (a + 4m + b) / 6; SD = (b − a) / 6

### Breakdown by Activity

| Activity | a (opt, hrs) | m (likely, hrs) | b (pess, hrs) | E (hrs) | SD (hrs) | Risk Drivers |
|----------|--------|----------|---------|--------|---------|--------------|
| Unit test design & execution | 6 | 9 | 14 | 9.3 | 1.3 | Amount logic complexity, edge cases |
| Integration test design & execution | 10 | 16 | 22 | 16.0 | 2.0 | PayGate sandbox availability (Tue/Thu only), state machine paths |
| E2E & UI test design & execution | 8 | 12 | 16 | 12.0 | 1.3 | UI interaction flakiness, screenshot capture |
| Single-card regression execution | 6 | 9 | 12 | 9.0 | 1.0 | Existing test suite size, environment stability |
| Defect investigation & retesting | 4 | 5 | 8 | 5.3 | 0.7 | Defect complexity, fix turnaround time |
| **Total** | **34** | **51** | **72** | **51.6** | **6.3** | — |

**Estimate Summary**:
- **Point Estimate**: 51.6 hours
- **Range**: 34–72 hours (with 95% confidence: 51.6 ± 2×6.3 = 38.8–64.2 hours)
- **Available Time**: 50 hours (1 tester, 50% FTE, 10 working days × 5 hrs/day)
- **Slack**: −1.6 hours (tight; exploratory testing deferred if overrun)

**Assumptions underpinning estimate**:
- Developers available 4 hours/week for pairing on integration tests (already factored)
- PayGate sandbox is stable and available on all Tue/Thu windows within the release window
- No additional compliance or security reviews required by QA
- Single-card regression suite is already documented and does not require redesign
- Defect fix turnaround is 24 hours (same-day for Critical)

---

## 8. Budget & Schedule

**Timeline**:
- **Start Date**: Monday, 2026-10-28
- **Release Date**: Wednesday, 2026-11-13 (10 working days)
- **PayGate Sandbox Windows**: Tue 2026-10-29, Thu 2026-10-31, Tue 2026-11-05, Thu 2026-11-07, Tue 2026-11-12 (5 windows available)

**Schedule** (50 hours QA + dev pairing):

| Week | Day | Focus | Hours | Notes |
|------|-----|-------|-------|-------|
| W1 | Mon 10-28 | Test plan finalization, risk review, unit test case design | 5 | Parallel: dev starts coding |
| W1 | Tue 10-29 | Unit test execution (live PayGate window) | 5 | 1st integration test prep |
| W1 | Wed 10-30 | Unit test completion, integration test design | 4 | 1 hr buffer for overruns |
| W1 | Thu 10-31 | Integration tests on PayGate sandbox (live window) | 5 | 2 devs pair; test refund automation |
| W1 | Fri 11-01 | Defect investigation, single-card regression suite setup | 5 | Release gate case results review |
| W2 | Mon 11-04 | Single-card regression execution (start) | 5 | — |
| W2 | Tue 11-05 | Integration tests (live PayGate window), regression continuation | 5 | Refund E2E tests |
| W2 | Wed 11-06 | E2E split payment tests, exploratory testing (if time) | 4 | 1 hr buffer |
| W2 | Thu 11-07 | Release gate re-test if failures found (live PayGate window) | 5 | Final defect fix verification |
| W2 | Fri 11-08 | Regression completion, test summary report | 5 | — |
| W2 | Mon 11-11 | Final readiness review, risk re-scoring | 1 | Holiday consideration (Veterans Day in US; may affect availability) |
| W2 | Tue 11-12 | Final smoke testing (if live PayGate window available) | 1 | Day before release |
| | | **Total** | **50** | QA allocation only; dev pairing adds ~8 hrs |

**Resources**:
- QA Lead (tester): 1 FTE at 50% = 5 hrs/day, 10 working days = **50 hours**
- Dev Team (2 engineers): Pairing for ~2 hrs/session, 4 sessions = **8 hours** (shared with implementation)
- DevOps: Environment deployment (pre-QA intake), PayGate sandbox access (assumed pre-configured)
- PayGate Support: Escalation only; no billable time expected

**Budget Allocation** (if hourly):
- QA hours: 50 @ \$75/hr = \$3,750
- Dev pairing: 8 @ \$100/hr = \$800
- **Total QA+Dev**: \$4,550
- **Contingency** (10%): \$455
- **Total Budget**: ~\$5,000

---

## 9. Configuration Management of Testware

**Identification & Version Control**:
- Test plan, test cases, test results, and risk register stored in project repository at `/qa/split-payment/`
- Naming convention: `TC-SP-NNN` (test case ID), `RG-SP-NNN` (risk ID), `DEF-SP-NNN` (defect ID)
- All artifacts versioned in Git with commit messages referencing issue tracker IDs (e.g., `JIRA-1234`)
- Test case changes require Pull Request with dev + QA sign-off

**Baseline Environments** (reproducibility):
- **QA-Stage**: PayGate sandbox (Tue/Thu only); QA database snapshot taken at test start; tagged in environment config
- **All test results must include**:
  - Build version (commit hash)
  - Environment name and timestamp
  - PayGate sandbox API version used
  - Screenshots or video (for E2E failures)
  - PayGate API request/response logs (truncated for security; no card data)

**Restoring Baselines**:
- QA database reset script: `qa/scripts/reset-test-db.sql` (idempotent; can be re-run)
- Test data (test card numbers): loaded from secure config file (not in repo; reference only)
- PayGate sandbox state: reset via PayGate API call before each test session

**CI/CD Integration**:
- Unit and integration test suites run in GitHub Actions on every push to QA branch (pass/fail gate)
- E2E tests run nightly on QA-Stage environment (not in-PR, due to PayGate sandbox availability)
- Release gate cases tagged `@release-gate` in test framework; separate CI job reports status

**Traceability Matrix**:
- Risk → Test Case: Each risk (R01–R10) linked to 1+ test case(s); see Risk Register column "Mitigation Strategy"
- Test Case → Test Result: Each TC linked to its execution result (PASS/FAIL/BLOCKED with defect ID if failed)
- Defect → Fix: Each DEF linked to code commit(s) that fix it, and linked back to TC that caught it

**Test Data Management**:
- Fixture set document at `/qa/split-payment/test-data.md`:
  - Test card numbers (valid, declined, timeout scenarios) — reference only, no card data in plaintext
  - Test amounts ($0.01, $100.00, $100.01 edge cases)
  - PayGate sandbox merchant ID and API keys (stored in secure config, not in repo)
  - Refund test scenarios (card1 success + card2 decline → refund expected)

**Handover & Resumption**:
- If testing is paused/resumed, mark the stopping point in test log: "Last executed: TC-SP-005 on 2026-11-06 14:30. Next: TC-SP-006 (E2E UI test)."
- All open defects remain in tracker (not deleted); each linked to the test case that found it and the commit that fixes it
- Risk register corrections dated in-place: "Updated R02 likelihood 3→2 on 2026-11-05 per dev confirmation of refund timeout margin."

---

## Key Dependencies & Risks Summary

**Critical Path** (items that can delay release if not met):
1. PayGate sandbox availability (Tue/Thu only) — 5 windows in the release window
2. Developers' availability for integration test pairing (4 hrs/week committed)
3. Refund automation completion time < 60s (functional requirement; must pass gate)
4. Single-card regression suite execution time (must fit in 50-hour budget)

**Escalation Triggers**:
- Any Critical defect found after Wed 2026-11-06 → stop release and re-plan
- PayGate sandbox unavailable on any Tue/Thu → escalate to dev team for mock/stub solution
- Test execution time exceeds 50 hours by end of Fri 2026-11-08 → defer exploratory testing, release on gate cases only
- Defect fix turnaround > 24 hours → assign additional dev resource or de-scope feature from this release
