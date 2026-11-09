# Test Plan: Split Payment Feature (Release 5.3)

## 1. Context of Testing

### Scope

**In Scope:**
- New split payment feature: two-card checkout with customer-controlled split amount
- Cent-level amount splitting with remainder-to-first-card logic
- PayGate integration for both charges
- Automatic refund of first charge if second charge declines (60-second SLA)
- Regression testing of existing single-card checkout

**Out of Scope:**
- PayGate gateway infrastructure (assumed stable)
- Payment authorization rules or fraud detection (PayGate-owned)
- Multi-currency support (assumed single currency, or deferred to future release)
- Browser compatibility beyond Chrome/Firefox (assumed standard testing scope)

### Objectives

1. **Verification**: Split payment charges, split calculation, and refund automation work correctly
2. **Regression**: Existing single-card checkout remains functional; no breaks to 4,000 daily orders
3. **Risk mitigation**: Detect financial data loss, duplicate charges, failed refunds, and payment state inconsistencies before release
4. **Release gate**: Confirm changes are safe to deploy

### Test Basis

- Feature specification (split payment requirements)
- PayGate API documentation (charge and refund endpoints)
- Existing single-card checkout test cases
- Financial transaction integrity requirements

---

## 2. Assumptions and Constraints

### Assumptions

- PayGate integration (charge and refund endpoints) is already implemented and stable
- Single-card checkout baseline is fully tested and working
- Test data (merchant account, test card numbers) is available in PayGate sandbox
- Environment deployments can be done on demand to staging; sandbox deployments depend on PayGate availability (Tues/Thurs only)
- 10 working days includes development, code review, and QA; actual QA window is 6–8 working days
- No partial refunds or multi-payment-method splits are in scope for this release
- Team has no blockers on development; feature is testable by day 8

### Constraints

- **PayGate sandbox availability**: Tuesday and Thursday only; limits hands-on testing to 4 days per 2-week cycle
- **Team capacity**: One tester at 50% (approximately 20 working hours per 10-day period), two developers for support
- **Release deadline**: 10 working days (hard constraint; testing ends when development must stop for release)
- **Environment dependency**: Staging can be used for dry runs, but PayGate integration requires sandbox or production-like test environment
- **Regression baseline**: 4,000 single-card orders per day in production; regression suite must be fast (<30 min) to fit daily run schedule

---

## 3. Stakeholders

| Role | Name / Team | Responsibility | Relevance to Testing |
| :--- | :--- | :--- | :--- |
| Product Owner | Product Team | Approve scope, accept risk and sign-off | Gate pass/fail decisions, risk acceptance on non-critical findings |
| QA Lead / Tester | QA (1 FTE × 50%) | Test planning, design, execution, defect reporting, gate sign-off | Owns all test activities, monitoring, and completion |
| Development Lead | Dev Team (2 FTE) | Implement feature, support test environment setup, fix defects | Provides code review support, environment stability, data for testing |
| Release Manager | Ops / Release | Coordinates deployment timing and rollback | Consumes gate pass/fail status; stops release if gate fails |

---

## 4. Communication

| Channel | Audience | Frequency | Content |
| :--- | :--- | :--- | :--- |
| Daily standup | Dev + QA | 9:00 AM, 15 min | Blockers, environment status, test progress (% of gate cases run) |
| Test result sheet | Product Owner + Release Manager | Every execution run (typically end of day) | Gate cases status, new defects (ID, severity, blocker status) |
| Weekly progress report | Product Owner + Dev Lead | Friday EOD | Test coverage achieved, cumulative defect count, risk re-assessment, any gate delays or mitigation actions |
| Defect notifications | Dev + QA | As filed | Slack notification + linked ticket (P0/P1 defects within 1 hour; others by EOD) |

**Document templates:**
- Test result: one-line per case (ID, status, evidence/screenshot, defect link if failed)
- Defect ticket: title, severity, reproducible steps, PayGate response (if applicable), financial impact (if any)
- Weekly report: format in Configuration Management section (9) below

---

## 5. Risk Register (5×5 Matrix)

| # | ID | Risk Description | Category | L | I | Score | Level | Mitigation Strategy | Owner | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | R01 | Refund fails or times out; first charge stays deducted after second charge declines | Product | 3 | 5 | 15 | 🔴 CRITICAL | Automated refund with timeout handler; state machine test covering decline + refund path; monitoring alert on refund failures post-release | QA + Dev | New |
| 2 | R02 | Duplicate charge: second charge succeeds but is recorded twice in payment records | Product | 2 | 5 | 10 | 🟠 HIGH | Idempotency key validation on PayGate; test for idempotent re-submit after network timeout; database row-level uniqueness constraint | Dev + QA | New |
| 3 | R03 | Split calculation error: remainder cent logic or rounding causes total ≠ order amount | Product | 2 | 5 | 10 | 🟠 HIGH | Decision table test (10+ split scenarios, edge amounts); edge-case-focused unit tests by dev team; automated regression check on every deploy | QA + Dev | New |
| 4 | R04 | Regression: existing single-card checkout breaks; customer orders fail | Product | 2 | 5 | 10 | 🟠 HIGH | Run single-card smoke suite before and after merge; 2 regression cases in gate; one end-to-end single-card case in daily regression run | QA | New |
| 5 | R05 | PayGate API integration: new split endpoint fails, times out, or returns unexpected error | Product | 2 | 4 | 8 | 🟠 HIGH | PayGate integration test (mock + sandbox); error handling test (timeout, 4xx, 5xx responses); fallback behavior documented | Dev + QA | New |
| 6 | R06 | Payment data loss: charge succeeds but order record is not created or is corrupted | Product | 1 | 5 | 5 | 🟡 MEDIUM | Transaction boundary test (commit order record and PayGate charge atomically, or rollback both); database integrity check post-test | Dev + QA | New |
| 7 | R07 | Performance regression: split payment doubles checkout latency; impacts 4,000 daily orders | Product | 2 | 3 | 6 | 🟡 MEDIUM | Load test single-card + split-card under 4,000 req/day baseline; measure P95 latency; alert if split is >10% slower than single | Dev + QA | New |
| 8 | R08 | User experience: confusing split UI, validation errors not clear, money left on first card unintentionally | Product | 2 | 3 | 6 | 🟡 MEDIUM | Exploratory test of split UI flow; error message clarity check; 1 user acceptance case in gate | QA | New |
| 9 | R09 | PayGate sandbox unavailable beyond Tues/Thurs; test execution window blocked | Project | 3 | 3 | 9 | 🟠 HIGH | Use staging environment for dry runs and refund-decline scenario setup; execute core gate cases on Tues, retry Thu if needed; request emergency sandbox access if needed | QA + Ops | New |
| 10 | R10 | Timeline risk: 10-day release window + half-time tester not enough for full analysis; defects found post-release | Project | 3 | 4 | 12 | 🟠 HIGH | Prioritize risk-based gate cases (refund SLA, duplicate charge, rounding); run smoke regression daily; defer exploratory and edge-case analysis to post-release hotfix cycle if needed | QA + PO | New |
| 11 | R11 | Developers finish late; QA window compressed from 6 days to 2–3 days | Project | 2 | 3 | 6 | 🟡 MEDIUM | Reserve Tues/Wed for testing; if code lands Friday, gate execution pushed to next Tues (slip release date or accept risk on PO approval) | PO + Release | New |
| 12 | R12 | Defect found in gate; retesting and fix deployment delays release by 1–2 days | Project | 2 | 2 | 4 | 🟡 MEDIUM | Defect triage SLA: critical fixes within 4 hours; retest within 2 hours of fix; maintain 1-day buffer before final go-live decision | Dev + QA | New |

**Register Review Cadence**: Reviewed and re-scored at each weekly status report (Friday); escalated to PO if any score changes.

---

## 6. Test Approach

### 6.1 Test Levels, Types, and Techniques

| Level | Owner | Type | Technique | Coverage Target | Independence |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Unit** | Dev | Functional, boundary | Decision table (split calculation), equivalence classes (amount ranges) | 90%+ code paths in split logic, PayGate wrapper | None (author) |
| **Integration** | Dev + QA | Functional, error handling | State transition (charge → decline → refund); API mock testing (PayGate responses); database state validation | PayGate endpoint mocking, order record consistency, timeout handling | Some (peer review) |
| **System** | QA | Functional, regression, smoke | End-to-end scenario (split checkout flow), exploratory (UI edge cases), decision table (split amounts), single-card regression smoke | Full happy-path split flow, refund automation, single-card regression baseline | High (QA independent; no dev in room during test) |

### 6.2 Test Deliverables

1. Test cases (split payment feature, refund automation, edge cases)
2. Test data fixture set (seeded test cards, order fixtures)
3. Release gate results (signed-off by QA + PO)
4. Regression suite results (single-card smoke, daily runs)
5. Defect log (linked to tickets, severity tagged)
6. Test completion report (coverage achieved, findings, post-release monitoring plan)

### 6.3 Entry Criteria: When to START Testing

- [ ] Feature code is merged to release branch and compiled with no errors
- [ ] PayGate integration endpoints are implemented and reviewed
- [ ] Refund automation logic is code-reviewed
- [ ] Test environment (staging + sandbox access) is deployed and verified
- [ ] Single-card baseline regression suite passes in target environment
- [ ] Test data (seeded merchant account, test card numbers) is available in PayGate sandbox
- [ ] QA has reviewed feature spec and identified test cases

### 6.4 Release Gate (Go/No-Go Cases)

The gate comprises **7 cases** covering split logic, refund automation, and single-card regression. All must PASS to release.

| # | Case ID | What It Proves | Pass Criteria |
| :--- | :--- | :--- | :--- |
| 1 | TC-501 | Split 50/50: order for $100, split $50/$50, both charges succeed | Both charges recorded; order total = $100; both card statements show correct amounts |
| 2 | TC-502 | Uneven split (remainder to first card): order $100.01, split $50/$50.01 | First charge = $50.01, second = $50.00; PayGate shows both successful; order amount = $100.01 |
| 3 | TC-503 | Refund SLA: second charge declines, first charge auto-refunds within 60 sec | First charge refunded within 60 sec; refund status in order record = "refunded"; customer does not see money deducted on statement |
| 4 | TC-504 | Edge case (small amount): order $1.00, split $0.50/$0.50 | Both charges succeed; order total = $1.00; no errors or data loss |
| 5 | TC-505 | Single-card regression: customer uses existing single-card checkout (not split) | Order placed and charged successfully; single-card checkout is unaffected by split code deploy |
| 6 | TC-506 | Single-card under load: simulate ~100 concurrent single-card orders | All orders charged successfully; no failures introduced; latency within baseline ±10% |
| 7 | TC-507 | PayGate error handling: second charge returns 5xx error; first charge must refund | First charge refunded within 60 sec; order marked as "failed"; customer is notified |

**Gate Execution Order (Risk-Based):**
1. TC-501, TC-502, TC-503 (critical refund and split logic; highest financial risk)
2. TC-504 (edge case, must not crash)
3. TC-505, TC-506 (regression; protects 4,000 daily orders)
4. TC-507 (error path; guards against data loss)

### 6.5 Full Analysis (Beyond Gate)

After gate passes, run exploratory and edge-case scenarios (time permitting):
- Split with full order amount on one card (e.g., $100 / $100 / $0) — should fail validation
- Negative amounts — should fail validation
- Non-integer cents in input (e.g., $10.123) — should fail validation
- Timeout during refund attempt; retry — should succeed on retry
- Customer cancels order during refund pending state — behavior documented

### 6.6 Independence of Testing

- **QA Tester (High Independence)**: Executes all system-level and gate cases independently; no dev involvement in test execution room
- **Dev Team (Some Independence)**: Reviews and tests integration layer with mock PayGate; peer-reviews unit tests but does not execute gate cases
- **Cross-review**: QA reviews dev unit/integration tests for coverage; dev reviews QA gate cases before execution

### 6.7 Metrics to Collect

| Metric | Purpose | Target | How Often |
| :--- | :--- | :--- | :--- |
| Gate case pass rate | Go/no-go decision | 100% (all 7 pass) | Every run |
| Test case coverage (lines executed) | Functional completeness | ≥85% of split + refund code | End of execution |
| Defect density (defects / 1K lines of split code) | Quality benchmark | ≤1 critical, ≤2 high per 1K LOC | Weekly report |
| Regression suite pass rate | Baseline protection | 100% single-card cases | Daily run |
| Test execution progress (% of gate cases run) | Timeline tracking | 100% by day 8 | Daily standup |
| Refund SLA compliance (refunds ≤60 sec) | Critical path | 100% of refund cases | Every run |

### 6.8 Test Data and Environment Requirements

**Test Data Fixture Set:**

| Fixture | ID | Description | State | Resetability |
| :--- | :--- | :--- | :--- | :--- |
| Merchant Account | MER-001 | PayGate sandbox merchant (test API key) | Active; charges and refunds enabled | N/A (static; provided by PayGate) |
| Test Card - Approve | CARD-001 | Card number always approves charges | Not charged yet | Run reset script after each test block |
| Test Card - Decline 2nd | CARD-002 | Card that declines on 2nd charge in a session | Not charged yet | Run reset script; contact PayGate support if needed |
| Test Order - Base | ORD-001 | Order record for $100.00 | Draft (not charged) | Inserted via seeded data script; reset via `DELETE WHERE test_order_id = ORD-001` |
| Test Order - Edge ($1) | ORD-002 | Order record for $1.00 (edge case) | Draft | Seeded data script reset |

**Environment:**

| Env | Purpose | Availability | Test Coverage |
| :--- | :--- | :--- | :--- |
| **Staging** | Dry-run split logic, UI, database state (no real PayGate calls) | Always | 80% of system tests (mock PayGate); refund SLA cannot be validated without real gateway |
| **PayGate Sandbox** | Real split charges, refunds, error scenarios | Tues, Thu only | Gate cases, refund SLA, error handling (20% of system tests) |
| **Production** (post-release) | Monitoring; no testing | After release gate passes | Smoke monitoring, real-world defect detection |

### 6.9 Deviations from Standard Test Policy

- **No multi-environment regression**: Single-card regression runs only in staging (faster feedback); full regression on release day targets production-equivalent sandbox
- **Exploratory deferred to post-release**: Due to half-time capacity and 10-day timeline, exploratory testing (edge cases, usability) is documented as recommendations for a hotfix cycle if high-priority defects emerge
- **PayGate mock for dev, real calls for QA gate**: Dev team uses PayGate mock SDK for unit/integration tests to avoid sandbox availability constraints; QA uses real sandbox for gate execution to ensure PayGate integration is correct

---

## 7. Estimate

### Estimation Technique: Three-Point Estimation

Given constraints (half-time tester, 10-day window, PayGate sandbox availability), I use three-point estimation (CTFL v4.0 §5.1.4):

**Formula**: E = (a + 4m + b) / 6, where:
- **a** = optimistic (best case)
- **m** = most likely (realistic)
- **b** = pessimistic (worst case)

**Standard Deviation**: SD = (b − a) / 6

### Effort Breakdown

| Task | a (Optimistic) | m (Most Likely) | b (Pessimistic) | E (Estimate) | SD | Risk Factor | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Analysis & Design** | 3 hrs | 5 hrs | 8 hrs | 5.2 hrs | 0.8 | Low | Review spec, identify edge cases, design test cases |
| **Test Implementation** (write cases, set up data) | 8 hrs | 14 hrs | 20 hrs | 14 hrs | 2 | Medium | Includes test data fixture setup, PayGate sandbox configuration, automation of smoke regression |
| **Execution (Core Gate)** | 4 hrs | 6 hrs | 10 hrs | 6.3 hrs | 1 | **HIGH** (R09: sandbox availability) | Hands-on gate execution; 2 execution blocks (Tues + Thu); 1.5 hrs per run × 2 + retests |
| **Execution (Exploratory & Edge Cases)** | 2 hrs | 5 hrs | 10 hrs | 5.3 hrs | 1.3 | **HIGH** (Timeline risk R10) | Deferred if gate passes quickly; time-boxed to day 9 if buffer exists |
| **Defect Triage & Retesting** | 2 hrs | 4 hrs | 8 hrs | 4.3 hrs | 1 | Medium | Assumes 1–2 defects found in gate; retests after dev fixes |
| **Reporting & Completion** | 1 hr | 2 hrs | 4 hrs | 2.3 hrs | 0.5 | Low | Final test summary, sign-off, post-release monitoring plan |
| **TOTAL** | **20 hrs** | **36 hrs** | **60 hrs** | **37.4 hrs** | **6.7** | — | Half-time capacity = ~20–25 hrs available; estimate exceeds capacity |

### Estimate with Confidence Intervals

**Most Likely Scenario**: 36 hours (range: 29.7–42.3 hrs at ±1 SD)

**Available Capacity**: 
- 10 working days × 4 hours/day (50% FTE) = 40 hours
- Less daily standups, blockers (~2 hrs) = ~38 productive hours
- **Shortfall risk**: ~1–2 hours if anything slips

### Critical Path & Assumptions

1. **PayGate sandbox windows (Tues/Thu)** limit execution to 4 days in 10; gate execution must fit into one 6-hour window on Tues, with Thu reserved for retests
2. **Dev finishes feature by day 6** to allow 4 days of QA; if slips to day 8, timeline becomes critical
3. **No P0 defects in gate** (1-2 retests assume P1/P2 defects only)
4. **Single-card regression suite runs in <20 min** to fit daily smoke
5. **Exploratory testing is deferrable** if gate takes longer than expected

### Recommendations for Timeline Mitigation

- **Parallel testing**: Staging environment dry-runs (day 5–6) overlap dev coding, reducing gate execution to ~4 hours
- **Prioritize gate**, defer exploratory to post-release analysis phase if needed
- **Pre-execution**: Prepare test data and merchant account setup on day 3–4 (before gate day)

---

## 8. Budget and Schedule

### Effort Budget

| Role | Capacity | Allocation | Hours |
| :--- | :--- | :--- | :--- |
| QA Tester | 1 FTE × 50% | Test planning (2 hrs), design (5 hrs), execution (18 hrs), retesting (4 hrs), reporting (2 hrs) | **31 hrs** |
| Dev Team | 2 FTE | Support test environment (4 hrs), defect triage/fix (assume 5 hrs based on typical P1/P2 turnaround), code review (2 hrs) | **11 hrs** (QA-adjacent; not full cost) |
| **Total QA Effort** | — | — | **31 hrs** |

### Schedule

| Phase | Dates | Owner | Deliverable | Blocker Dependency |
| :--- | :--- | :--- | :--- | :--- |
| **Planning & Analysis** | Day 1–2 | QA + PO | Test plan, risk register, test case list | Spec finalized |
| **Test Design & Setup** | Day 3–4 | QA + Dev | Test cases written, test data fixtures created, merchant account setup in PayGate sandbox | Feature branch available |
| **Dev Finish & Merge** | Day 5–6 | Dev | Feature code merged to release branch, integration tests pass | No hard blocker; QA can start staging dry-runs meanwhile |
| **Staging Dry-Run** | Day 5–7 | QA | Gate cases executed against staging (mocked PayGate), regression smoke runs, issues identified | Staging environment deployed |
| **Gate Execution (PayGate Sandbox)** | Day 8 (Tues) | QA | Core 7 gate cases executed, signed off | All entry criteria met; PayGate sandbox available |
| **Retest & Retriage** | Day 9 (Thu) | QA + Dev | Defect retests, final sign-off | Defects fixed by dev (SLA: 4 hrs) |
| **Go-Live Decision** | Day 9 EOD | PO + Release | Release approved or rolled back | Gate pass, no critical open defects |
| **Release** | Day 10 | Ops | Deploy to production | PO sign-off |
| **Post-Release Monitoring** | Day 10+ | QA + Ops | Daily refund SLA checks, defect triage for issues (escalate critical within 1 hr) | Monitoring dashboard set up |

### Critical Path Dates

Assuming today is **2026-10-28** (Wednesday):

| Milestone | Target Date | Day | Notes |
| :--- | :--- | :--- | :--- |
| Planning complete | 2026-10-29 | Thu | Today + 1 |
| Dev feature merge | 2026-11-05 | Thu | Day 6 (assuming dev on track) |
| Gate execution (Sandbox) | 2026-11-10 | Tue | Day 8 (PayGate Sandbox available) |
| Retest & approval | 2026-11-11 | Wed | Day 9 (if Sandbox available again, or use staging + spot-checks) |
| Go-live | 2026-11-12 | Thu | Day 10 |

**If PayGate sandbox is unavailable Tue 2026-11-10**, defer gate to Thu 2026-11-12 (same-day release decision, very high risk). Mitigation: Request emergency sandbox access from PayGate support by day 6.

---

## 9. Configuration Management of Testware

### Identification and Version Control

All testware is version-controlled in the project repository under `qa/split-payment-5.3/`:

```
qa/split-payment-5.3/
├── test-cases.md          (v1.0; versioned by date and author)
├── test-data-fixtures.sql (v1.0; seeded data, reset script)
├── test-results.md        (v1.0; filled in during execution)
├── risk-register.md       (v1.0; updated weekly)
└── completion-report.md   (v1.0; filled at end of testing)
```

### References by Identifier and Version

- **Test Case ID Format**: `TC-5XX` (split payment feature, v5.3). Each case includes test data fixture ID (e.g., ORD-001) and PayGate sandbox merchant ID (MER-001)
- **Defect ID Format**: `DEF-SSSSS` (issue tracker auto-generated); linked in test result and risk register
- **Build Version**: Every result includes build number (e.g., `split-payment-v5.3-build-042`) and environment (staging / PayGate sandbox / production)
- **Test Result Traceability**: Each row in `test-results.md` includes `[TC-XXX] | [Build] | [Env] | [Status] | [Evidence]`

### Baselined Environments

| Environment | Baseline Version | How Established | Restoration |
| :--- | :--- | :--- | :--- |
| **Staging** | Locked to release branch commit SHA | Deployed via CI/CD pipeline before QA starts | Redeploy from git tag `release-5.3-baseline` |
| **PayGate Sandbox** | Merchant account + test card fixtures | Provided by PayGate; fixture setup script run before each test block | Run `reset-fixtures.sh` (clears previous test order records, re-seeds cards) |
| **Production** (post-release) | Release branch commit SHA | Deployed by Ops after gate passes | Git tag `release-5.3` for rollback |

### Restorable Baselines

- **Before each gate execution**: Run `qa/split-payment-5.3/test-data-fixtures.sql` to reset test order records and merchant account state in PayGate sandbox
- **After each execution run**: Snapshot test results in `test-results.md` with timestamp and build number; archive to `qa/split-payment-5.3/results-archive/` with date prefix
- **If defect found and fixed**: Record defect ID and retest date in result row; do not delete or overwrite

### CI/CD Integration

- **Pre-merge**: Dev team runs unit + integration tests (mock PayGate) in CI; gate does not run until merged
- **Pre-release**: QA gate cases are NOT automated (real PayGate charges; manual verification required); staging smoke suite runs daily post-merge
- **Post-release**: Automated smoke regression suite (single-card + split happy-path; mocked PayGate) runs every hour for 24 hrs; alerts on failure

### Configuration Management in Delivery

- **Build artifacts**: Staging and sandbox deployments pin split-payment code to release branch commit; production uses git tag `release-5.3`
- **Rollback plan**: If critical defect found in production (P0), revert to previous single-card-only build; new split-payment release deferred to next sprint
- **Test result retention**: Archive results for 12 months (compliance); link all defects to git commit and build number for traceability

---

## 10. Summary Table (Quick Reference)

| Item | Value |
| :--- | :--- |
| **Feature** | Split payment (two cards, customer-controlled split, auto-refund on decline) |
| **Release Date** | 2026-11-12 (10 working days) |
| **Test Team** | 1 tester (50% FTE); 2 developers (support) |
| **Gate Cases** | 7 (split logic, refund SLA, single-card regression) |
| **Estimated Effort** | 31 hrs QA; 11 hrs dev-adjacent (within 38 productive hours available) |
| **Sandbox Test Windows** | Tue 2026-11-10, Thu 2026-11-12 |
| **Critical Risks** | Refund timeout (R01), duplicate charges (R02), split calculation error (R03), regression (R04), sandbox availability (R09), timeline compression (R10) |
| **Mitigation Priority** | Gate execution on Tues; staging dry-run day 5–6; exploratory deferred post-release if needed |
| **Exit Criteria** | All 7 gate cases pass; zero open critical defects; single-card regression passes; PO sign-off |
| **Metrics to Monitor** | Gate pass rate, test coverage, defect density, refund SLA compliance, regression pass rate, timeline burn-down |
| **Post-Release Monitoring** | Refund SLA checks (daily), real-world defect triage, rollback trigger (P0 defects within 24 hrs of launch) |

---

## Corrections & Updates

(None at time of plan creation; updates will be dated and logged here when baseline assumptions change.)
