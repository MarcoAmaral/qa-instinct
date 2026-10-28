# Risk-Based Test Plan: Split Payment (Release 5.3)

## Executive Summary

This test plan addresses a new split-payment feature allowing customers to distribute a single order across two payment cards. The release carries significant financial and revenue risks: failed refund automation could strand customer funds; incorrect cent allocation could cause recurring revenue leakage; regression in the existing single-card path could disrupt ~4,000 daily orders. Testing is resource-constrained (0.5 FTE tester, 10 working days, PayGate sandbox access only Tuesdays/Thursdays). Strategy prioritizes automated validation of financial logic and critical payment workflows, with manual testing focused on high-risk user journeys and the single-card regression surface.

---

## Test Objectives

1. Validate that split amounts are calculated correctly, including proper handling of remainder cents (all to first card).
2. Verify that both charges process through PayGate in the correct sequence and state.
3. Confirm automatic refund of the first charge within 60 seconds if the second charge declines.
4. Ensure the existing single-card checkout path remains functional and performance-neutral.
5. Validate payment state consistency and idempotency under failure scenarios.

---

## Risk Assessment

### Critical Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|-----------|
| Refund automation fails; first charge stranded in customer account | Financial liability, customer escalations, potential regulatory exposure | Medium | Automated tests validating refund trigger and timing; manual tests on PayGate sandbox; monitoring alerts post-release |
| Cent allocation logic produces incorrect splits or cumulative rounding errors | Revenue leakage, compliance audit finding, customer disputes | Medium | Unit tests on allocation algorithm; boundary-case data-driven tests (0–999 cents, evenly divisible, remainder scenarios) |
| Single-card checkout regression under load or edge cases | 4,000 orders/day disrupted; high revenue impact | Medium-High | Regression test suite covering all existing single-card paths; load/smoke tests before release |
| PayGate integration misconfiguration (incorrect charge sequencing, missing idempotency keys) | Double-charging, stuck payments, customer harm | Low-Medium | Integration tests using PayGate sandbox; verification of idempotency and charge order |

### High Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|-----------|
| Second charge declined in production; refund loop fails or times out | Partial payment without customer awareness | Low-Medium | Sandbox testing of decline scenarios; timeout and retry logic validation |
| Concurrent payment attempts or race conditions in state machine | Duplicate charges, inconsistent order state | Low | Concurrent request tests; database transaction validation |
| Insufficient PayGate sandbox availability blocks testing | Test gaps discovered post-release | High | Schedule all PayGate-dependent testing for available windows (Tue/Thu); prepare mock-based tests for other days |

---

## Assumptions

1. **PayGate API stability**: PayGate sandbox and production APIs are stable; no unplanned outages. If unavailable, testing falls back to mocked PayGate responses for non-integration tests.
2. **Code freeze and deployment**: Code is feature-complete and ready for testing by day 1 of this plan. No scope changes mid-cycle.
3. **Test environment parity**: Test environment mirrors production PayGate configuration (API endpoints, auth, rate limits).
4. **Single-card checkout stability**: Current single-card checkout has no known defects; regression testing assumes baseline functionality.
5. **Refund SLA**: "Within 60 seconds" refers to the backend initiation of the refund request, not PayGate processing time.
6. **Transaction logging**: All payment transactions are logged with sufficient detail for post-release audit and troubleshooting.
7. **Team collaboration**: Developers are available for rapid bug triage and fixes during testing windows.

---

## Test Scope

### In Scope

- **Amount calculation and allocation**: All cent-splitting logic, including remainder-to-first-card handling.
- **Two-card checkout workflow**: Happy path, decline scenarios, and state transitions.
- **Refund automation**: Triggering, timing, and idempotency on second-charge decline.
- **PayGate integration**: Charge sequencing, idempotency keys, error handling.
- **Single-card regression**: Full existing checkout flow; smoke tests on key user journeys.
- **Payment state consistency**: Database state after each payment step; handling of incomplete transactions.
- **Boundary and edge cases**: $0.01, $0.99, large amounts (e.g., $9999.99), split 50/50, split 1¢/rest.

### Out of Scope

- **UI/UX design review** (assumes design is final; QA validates functionality, not aesthetics).
- **Performance optimization** (load testing limited to regression validation; no capacity planning).
- **PayGate infrastructure** (PayGate's reliability, API design, and infrastructure are assumed stable).
- **Fraud detection and PCI compliance** (delegated to security and compliance teams; QA validates feature does not disable existing controls).
- **Multi-currency or tax scenarios** (assumes single currency; tax handling assumed unchanged).

---

## Test Strategy

### Approach

**Risk-driven prioritization**: Test execution prioritizes critical and high-risk scenarios. Given limited tester capacity (0.5 FTE × 10 days = 50 person-hours), effort is concentrated on:

1. **Automated, repeatable tests** (unit + integration) for financial logic and payment state.
2. **Sandbox-dependent tests** (integration with PayGate) scheduled for Tuesdays and Thursdays.
3. **Manual testing** for end-to-end user journeys, single-card regression, and exploratory testing of edge cases.
4. **Mocked testing** for non-PayGate scenarios to minimize sandbox dependency.

### Test Levels

| Level | Focus | Owner | Timing |
|-------|-------|-------|--------|
| **Unit** | Amount allocation logic, rounding, state transitions | Dev team | Days 1–3 (parallel with QA) |
| **Integration** | PayGate API calls, refund triggering, charge sequencing | QA + Dev | Days 4–6 (Tue/Thu sandbox windows) |
| **System** | End-to-end split-payment and single-card checkout flows | QA | Days 3–7 |
| **Regression** | Smoke tests on single-card checkout; load/performance | QA | Days 7–8 |
| **UAT (optional)** | Product/stakeholder validation on sandbox | Product | Day 8 (if time permits) |

---

## Test Cases

### Priority 1: Critical Functionality (14 test cases, ~20 hours)

#### 1.1 Amount Allocation

| ID | Test Case | Precondition | Steps | Expected Result | Risk Covered |
|----|-----------|--------------|-------|-----------------|--------------|
| CA-001 | Even split ($10 → $5 + $5) | Order total $10.00 | Select first card $5.00 | First card: $500¢, second card: $500¢ | Cent allocation |
| CA-002 | Odd split with remainder to first ($10.01 → $5.01 + $5.00) | Order total $10.01 | Select first card $5.00 | First card: $501¢, second card: $500¢ | Cent allocation (critical) |
| CA-003 | Minimum split ($0.01 + $0.00) | Order total $0.01 | Select first card $0.01 | First card: 1¢, second card: 0¢ | Edge case, boundary |
| CA-004 | Large amount split ($9999.99 → $4999.99 + $5000.00) | Order total $9999.99 | Select first card $4999.99 | First card: $499999¢, second card: $500000¢ | Financial precision, large values |
| CA-005 | One-cent remainder ($1.00 → $0.50 + $0.50 with $0.01 order) | Order total $1.01 | Select first card $0.50 | First card: 51¢, second card: 50¢ | Remainder handling (critical) |
| CA-006 | All funds on first card ($10 → $10 + $0) | Order total $10.00 | Select first card $10.00 | First card: $1000¢, second card: 0¢; second charge skipped or $0 | Edge case |
| CA-007 | All funds on second card ($10 → $0 + $10) | Order total $10.00 | Select first card $0.00 | First card: 0¢, second card: $1000¢; first charge skipped or $0 | Edge case |

#### 1.2 Two-Card Checkout (Happy Path)

| ID | Test Case | Precondition | Steps | Expected Result | Risk Covered |
|----|-----------|--------------|-------|-----------------|--------------|
| CC-001 | Both charges approved | Valid order, two cards, PayGate responses set to approve | Enter split amounts, submit payment | Order marked paid; both charges visible in transaction log with unique IDs; customer email sent | Happy path |
| CC-002 | Charge sequence order | Valid order, PayGate configured | Observe charge sequence in logs | First charge processed, then second charge (no parallel) | PayGate integration |
| CC-003 | Idempotency on duplicate submission | Valid order, initial payment submitted | Resubmit payment request with same idempotency key | Only one charge per card; no duplicate transactions | Idempotency, race conditions |

#### 1.3 Second Charge Decline + Refund (Critical)

| ID | Test Case | Precondition | Steps | Expected Result | Risk Covered |
|----|-----------|--------------|-------|-----------------|--------------|
| RF-001 | Second charge declined; first charge refunded within 60s | Valid order, first card approved, second card set to decline | Execute split payment | First charge refund initiated within 60 seconds; order status marked as "refunded"; customer notified; no funds retained | **CRITICAL: Refund automation** |
| RF-002 | Refund idempotency | Second charge already declined in RF-001 | Replay refund request | Refund only processed once; no duplicate refund attempts | Idempotency, financial correctness |
| RF-003 | Refund timeout handling | Refund takes >60 seconds (mocked delay) | Execute split payment with slow refund | Alert/log generated at 60s threshold; manual intervention documented | Refund SLA, monitoring |
| RF-004 | First charge approved, second charge error (non-decline) | Valid order, first card approved, second card returns technical error | Execute split payment | First charge refunded; order marked as failed; customer notified; no ambiguous state | Error handling |

#### 1.4 Single-Card Regression (Smoke)

| ID | Test Case | Precondition | Steps | Expected Result | Risk Covered |
|----|-----------|--------------|-------|-----------------|--------------|
| SR-001 | Single-card checkout still works | Existing customer, one card | Proceed through checkout as before | Order completes; charge processed; customer receives email | Regression on 4,000/day volume |
| SR-002 | Single-card decline path | Existing customer, one card, decline response | Attempt payment | Order marked declined; customer notified; no phantom refund attempted | Regression, refund logic isolation |
| SR-003 | Single-card checkout performance (smoke) | Existing customers | Run 10 concurrent single-card checkouts | All complete within baseline time; no timeout/error spike | Performance regression |

---

### Priority 2: High-Risk Scenarios (8 test cases, ~12 hours)

#### 2.1 Concurrent and Race Condition Tests

| ID | Test Case | Precondition | Steps | Expected Result | Risk Covered |
|----|-----------|--------------|-------|-----------------|--------------|
| RC-001 | Two concurrent split payments on same order (edge case) | Order with split payment config | Submit two split payments simultaneously | First payment processes; second rejected or queued; no duplicate charges | Race conditions, state consistency |
| RC-002 | Payment modification mid-flight | Order in "pending" state during first charge | Attempt to modify split amounts before second charge | Modification rejected; no state corruption | Concurrent access |

#### 2.2 PayGate Integration

| ID | Test Case | Precondition | Steps | Expected Result | Risk Covered |
|----|-----------|--------------|-------|-----------------|--------------|
| PG-001 | PayGate connection timeout on first charge | Network latency simulated | Execute split payment | Retry logic engages; customer notified; order not charged | Resilience |
| PG-002 | PayGate connection timeout on second charge | First charge approved, network latency on second | Execute split payment | First charge refunded within 60s; order marked failed | Refund on timeout (critical path) |
| PG-003 | PayGate returns unexpected response code | PayGate returns non-standard error | Execute split payment | Error logged; customer notified; order rolled back or marked for manual review | Error handling |

#### 2.3 Payment State Consistency

| ID | Test Case | Precondition | Steps | Expected Result | Risk Covered |
|----|-----------|--------------|-------|-----------------|--------------|
| PS-001 | Database state after successful split payment | Split payment completed | Query order and transaction tables | Order status = "paid"; two transactions recorded; amounts sum to order total; both idempotency keys stored | Data integrity |
| PS-002 | Database state after declined second charge + refund | Refund completed | Query order and transaction tables | Order status = "refunded"; refund transaction recorded with timestamp; first charge marked as "refunded"; no orphaned transactions | Data integrity (critical) |

---

### Priority 3: Edge Cases and Boundary Tests (6 test cases, ~8 hours)

#### 3.1 Amount Boundaries

| ID | Test Case | Precondition | Steps | Expected Result | Risk Covered |
|----|-----------|--------------|-------|-----------------|--------------|
| EB-001 | $0.01 total order (minimum) | Create $0.01 order | Execute split payment ($0.01 + $0.00) | Both charges processed or zero-value charge logic invoked correctly | Boundary |
| EB-002 | $99,999.99 total (practical maximum) | Create $99,999.99 order | Execute split payment at midpoint | Charges calculated correctly; no overflow; precision maintained | Boundary, large values |
| EB-003 | Split with $0.00 on second card | Order $10.00, select $10.00 on first card | Execute split payment | First charge for $10.00; second charge either skipped or $0.00; order completes | Edge case |
| EB-004 | Decimal edge case: $1.99 split to $1.00 + rest | Order $1.99, select $1.00 on first card | Execute split payment | First card: $100¢, second card: $99¢ | Decimal precision |

#### 3.2 User Input Validation

| ID | Test Case | Precondition | Steps | Expected Result | Risk Covered |
|----|-----------|--------------|-------|-----------------|--------------|
| IV-001 | First card amount > order total | Order $10.00, enter $10.01 for first card | Attempt submission | Form error; submission blocked | Input validation |
| IV-002 | First card amount is negative | Order $10.00, enter -$5.00 | Attempt submission | Form error; submission blocked | Input validation |

---

### Priority 4: Exploratory and Ad Hoc Testing (2 person-days, ~8 hours)

| Area | Focus |
|------|-------|
| **User experience** | Verify split-payment UI clearly indicates two separate charges; confirmation page shows both amounts; customer understands the flow. |
| **Customer communication** | Check that receipt/email details both charges separately; confirmation SMS/push (if applicable) is clear. |
| **Admin/reporting** | Verify split payments appear correctly in order reports; PayGate transaction IDs match; export/reconciliation logic works. |
| **Browser/device coverage** | Smoke test on Chrome, Safari, Firefox; responsive design on mobile. |

---

## Testing Timeline

### Week 1 (Days 1–5, 10/28–11/1)

| Day | Activity | Tester Hours | Notes |
|-----|----------|--------------|-------|
| Day 1 (Tue 10/29) | Kickoff; review feature spec and dev implementation; set up test environment | 2 | PayGate sandbox available |
| Day 2 (Wed 10/30) | Execute Priority 1 unit + non-PayGate tests (CA-001–007, CC-001 mocked) | 4 | |
| Day 3 (Thu 10/31) | Execute PayGate integration tests (CC-001, RF-001, PG-001–003) on sandbox | 4 | **PayGate available** |
| Day 4 (Fri 11/1) | Single-card regression smoke tests; execute Priority 2 state consistency tests | 4 | |
| **Week 1 Total** | | **14 hours** | |

### Week 2 (Days 6–10, 11/4–11/8)

| Day | Activity | Tester Hours | Notes |
|-----|----------|--------------|-------|
| Day 6 (Mon 11/4) | Execute Priority 3 edge-case tests (EB-001–004); document results | 3 | |
| Day 7 (Tue 11/5) | Re-test critical fixes; PayGate retest on sandbox if bugs found | 4 | **PayGate available** |
| Day 8 (Wed 11/6) | Exploratory testing; UAT prep | 3 | |
| Day 9 (Thu 11/7) | Final PayGate validation; load/performance smoke test | 3 | **PayGate available** |
| Day 10 (Fri 11/8) | Test summary; regression pack finalization; sign-off prep | 2 | |
| **Week 2 Total** | | **15 hours** | |

**Total: ~29 person-hours (within 0.5 FTE × 10 days = 40 hours available)**

---

## Entry and Exit Criteria

### Entry Criteria

- Feature code is committed to a testable branch and deployed to QA environment.
- PayGate sandbox credentials and test account are provisioned.
- Test environment has database reset capability.
- Development team has assigned a point person for rapid bug triage.

### Exit Criteria (Release Readiness)

- **All Priority 1 tests (CA, CC, RF, SR)**: Pass ✓
- **All Priority 2 tests (RC, PG, PS)**: Pass ✓ or documented risk acceptance
- **Critical refund scenario (RF-001)**: Pass ✓ with evidence of 60-second SLA
- **Single-card regression (SR-001–003)**: Pass ✓ with no performance degradation
- **PayGate integration**: Verified on sandbox ✓ (Tuesday/Thursday testing completed)
- **No critical or high bugs**: Open defects do not exceed approved risk register
- **Test summary report**: Completed and signed by QA lead and product owner

---

## Resource Plan

### Tester Responsibilities (0.5 FTE, ~25 hours/week)

- Execute test cases per timeline.
- Log bugs in issue tracker with PayGate transaction IDs and reproducible steps.
- Coordinate with developers on urgent fixes.
- Prepare test summary and sign-off report.

### Developer Responsibilities (2 FTE, supporting)

- Make code available for QA on day 1.
- Triage and fix critical bugs within 24 hours.
- Provide PayGate sandbox configuration and credentials.
- Pair with QA on one Priority 1 integration test (refund scenario) for validation.

### Product/Stakeholder Responsibilities

- Review and approve test plan assumptions.
- Participate in UAT on day 8 (if schedule permits).
- Sign off on exit criteria and risk acceptance.

---

## Known Constraints and Mitigations

| Constraint | Impact | Mitigation |
|-----------|--------|-----------|
| PayGate sandbox only Tue/Thu | Integration testing window limited | All PayGate-dependent tests scheduled for Tue (10/29, 11/5) and Thu (10/31, 11/7); mocked tests cover non-PayGate days |
| 0.5 FTE tester | Capacity risk; may not cover all edge cases | Prioritize by risk; developers support unit testing; exploratory testing deferred if critical path is at risk |
| 10-day timeline | Tight release window | Parallel dev + QA; no scope creep; bug triage SLA = 24 hours for critical |
| Single-card regression risk (4,000/day) | High blast radius if broken | Dedicate smoke tests to single-card path; day 3 regression validation required before moving to next phase |

---

## Success Metrics

- **Test execution rate**: ≥90% of test cases executed by release date.
- **Defect escape rate**: <2 critical defects in production post-release.
- **Refund SLA compliance**: 100% of refund scenarios complete within 60 seconds in sandbox testing.
- **Single-card regression**: Zero degradation in existing checkout performance or functionality.
- **Stakeholder confidence**: Product owner and developers sign off on exit criteria.

---

## Appendix: Assumptions Summary

1. Code is feature-complete and QA-ready by day 1.
2. PayGate sandbox is stable and available on scheduled Tue/Thu windows.
3. Test environment can be reset between test runs.
4. Refund SLA ("within 60 seconds") is measured from backend initiation, not PayGate settlement.
5. Single-card checkout baseline is known and stable.
6. Developers are available for same-day bug triage.
7. No other features or regressions are in flight during this release window.
