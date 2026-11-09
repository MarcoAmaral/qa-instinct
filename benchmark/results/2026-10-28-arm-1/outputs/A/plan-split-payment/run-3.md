# Split Payment Feature Test Plan (Release 5.3)

## Executive Summary

This test plan addresses the high-risk split payment feature launching in 10 working days with constrained resources. Financial accuracy, refund timing, and regression risk on the high-volume single-card flow are prioritized. PayGate sandbox availability (Tue/Thu only) limits integration testing windows and requires early coordination.

## Scope

**In Scope:**
- Split payment amount allocation and cent remainder handling
- PayGate authorization and capture for both charges
- Refund initiation and timing when second charge declines
- Single-card checkout regression (critical for 4,000 daily orders)
- Error states and customer-facing messaging
- Database transaction consistency

**Out of Scope:**
- PayGate internal processing logic or fraud detection
- UI/UX design validation beyond payment flow
- Performance tuning (load testing deferred to post-release monitoring)
- Accessibility compliance (assume covered by design review)

## Risk Matrix & Test Prioritization

| Risk | Severity | Probability | Test Priority | Effort |
|------|----------|-------------|---|---|
| Incorrect split calculation or cent allocation | Critical | Medium | 1 | Low |
| Refund not initiated or exceeds 60-sec SLA | Critical | Medium | 2 | Medium |
| First charge succeeds but second declines without rollback | Critical | High | 3 | Medium |
| Regression: single-card checkout fails | Critical | Low | 4 | Low |
| PayGate authorization rejection handling | High | Medium | 5 | Low |
| Idempotency: duplicate split charges on retry | High | Medium | 6 | Medium |
| Payment state inconsistency after network failure | High | High | 7 | High |
| Insufficient funds on first card after split | High | Low | 8 | Low |

## Test Strategy

### Phase 1: Unit & Integration (Days 1–4)

**Objective:** Validate split logic and PayGate integration without live sandbox.

**Tests (16 hours, half-time tester + developers):**
- Amount splitting algorithm: 100 scenarios (multiple/odd values, edge cases: $0.01, $0.99, $999.99)
- Cent remainder allocation: first card always gets remainder
- Payment state machine: transitions for pending → authorized → captured → declined → refunded
- Refund trigger logic: second charge decline → refund initiation within 1 second (code path)
- Single-card flow unchanged: 5 core transaction paths
- Database transaction rollback on failure: dirty-read prevention

**Assumptions:**
- Developers provide API mocks for PayGate before testing starts
- Test data setup script prepared for rapid iteration
- Unit tests run locally; no PayGate sandbox needed yet

**Exit Criteria:** 100% code coverage of split logic; zero failures on regression scenarios.

---

### Phase 2: PayGate Sandbox Integration (Days 5–6, targeting Tuesday & Thursday)

**Objective:** End-to-end validation with live sandbox.

**Tests (8–10 hours, in two windows: Tue 10/29, Thu 10/31):**
- Happy path: $10 split $3/$7 → both charges authorized and captured
- Second charge decline → first charge refund within 60 seconds (measure wall-clock time)
- First charge decline → user error message, second charge never attempted
- Partial refund edge case: first charge $5, second charge $3 (total $8); second declines → refund $5 only
- Idempotency: replay split payment request → no duplicate charges (PayGate idempotency key validation)
- Network retry: timeout on second charge → auto-retry within 30 seconds, then proceed to refund if final decline
- Verification: both charges visible in PayGate transaction history under one order ID

**Assumptions:**
- PayGate sandbox credentials pre-provisioned
- Test merchant account configured; payment method tokens ready
- Refund SLA clock starts when second charge response received (not when refund API called)

**Exit Criteria:** All scenarios pass; refund timing logs <60 sec in 10/10 trials.

---

### Phase 3: Regression & Load Simulation (Days 7–9)

**Objective:** Confirm single-card checkout stability; simulate daily volume.

**Tests (6–8 hours):**
- Single-card flow: 50 transactions via PayGate sandbox (verify no latency increase)
- Concurrency: 5 simultaneous split payments + 5 single-card → no race conditions (database row locks)
- Volume simulation: replay log of 100 real single-card orders at 2× speed (4,000/day → 200/sec peak)
- Mixed payment methods: split + single-card interleaved in order pipeline
- Error recovery: disconnect after first charge, then retry → correct refund state without double-charge
- Monitoring: error rates, latency percentiles (p50, p95, p99) for single-card vs. split

**Assumptions:**
- Staging environment mirrors production data schema and volume
- Load test generates representative transaction mix (amounts, decline rates ~2%)
- No performance regression means <10% increase in p95 latency for single-card

**Exit Criteria:** Zero data corruption; single-card latency unchanged; split refund SLA met in all decline scenarios.

---

### Phase 4: UAT & Production Readiness (Day 10)

**Objective:** Final sign-off and runbook validation.

**Tests (2–4 hours):**
- Happy path walkthrough: QA tester performs 5 split payments end-to-end in staging
- Refund scenario: manually trigger second-charge decline in sandbox, observe refund initiation
- Rollback plan: disable split payment feature flag; verify single-card checkout stable
- Monitoring alerts: confirm split-payment-decline and refund-failure alerts fire correctly
- Runbook: on-call engineer walks through refund recovery steps if 60-sec SLA missed

**Exit Criteria:** No blockers; incident response documented.

---

## Test Scenarios by Risk

### Critical: Payment Accuracy

| Scenario | Test Data | Expected Outcome | Risk Mitigated |
|----------|-----------|------------------|---|
| Split $10.00 → first $3.33, second $6.67 | Amount=$1000 cents, split_pct=33% | First=$333 cents, Second=$667 cents | Calculation correctness |
| Split $10.01 → first $3.34, second $6.67 | Amount=1001 cents, split_pct=33% | First=$334 cents, Second=$667 cents (remainder on first) | Cent remainder allocation |
| Split $0.01 → first $0.01, second $0.00 | Amount=1 cent, split_pct=50% | First=$1 cent, Second=$0 cents | Minimum split edge case |
| Split $999.99 → first $499.99, second $500.00 | Amount=99999 cents, split_pct=50% | Both authorized; order total verified | Large amount correctness |

### Critical: Refund Mechanism & Timing

| Scenario | Test Data | Expected Outcome | Validation Method |
|----------|-----------|------------------|---|
| Second charge declined immediately | PayGate test card: 4532015112830366 (decline) | Refund initiated <1 sec after decline API response; customer sees "Refund processing" message | Log timestamp: decline_response_time → refund_call_time |
| Second charge timeout after 30 sec | Simulate 30-sec network delay | Auto-retry triggered; if retried decline, refund initiated <60 sec from initial second-charge call | Elapsed time from second-charge POST to refund POST |
| First charge succeeded, second charge declined, then refund fails | Simulate refund API error | Alert triggered; on-call notified; retry loop logs evidence | Monitoring dashboard shows refund_failure alert; logs show 3 retry attempts |
| Duplicate refund request (idempotency) | Call refund API twice with same split_payment_id | Only one refund issued; duplicate rejected with idempotency_key conflict | PayGate transaction history shows 1 refund; API response logs show 409 Conflict on second call |

### Critical: Regression & Data Integrity

| Scenario | Test Data | Expected Outcome | Key Assertion |
|----------|-----------|------------------|---|
| Single-card checkout: $50 charge | Existing checkout flow, no split selected | Charge authorized and captured; order marked paid | order.status = 'paid'; order.payment_method = 'card' (not 'split') |
| 4,000 single-card orders in 1 hour | Replay production traffic sample | <10% increase in p95 latency vs. baseline | p95_latency_split_feature ≤ baseline × 1.1 |
| Split payment: rollback on database constraint violation | Corrupt payment_id in second charge payload | First charge captured, second charge rejected before API call, refund initiated | Database commit prevented; no orphaned payment records |

### High: PayGate Integration Failures

| Scenario | Test Data | Expected Outcome |
|----------|-----------|------------------|
| PayGate auth API returns 502 Bad Gateway | Retry logic configured for 3 attempts with 1-sec backoff | Third retry logged; customer error: "Payment service unavailable; please try again" |
| First charge authorized, PayGate session expires before second charge | Simulate 5-min delay between charges | Second charge fails with auth_expired; manual intervention required; alert to ops |
| Duplicate charge prevention (idempotency key) | Retry same split payment twice within 30 sec | PayGate returns 409 Conflict on retry; no double-charge |

### High: Idempotency & Retry Safety

| Scenario | Test Data | Expected Outcome |
|----------|-----------|------------------|
| Network drops after first charge, before second charge attempt | Kill connection between charges | Retry logic resumes with second charge; order state consistent |
| Webhook delay: first charge webhook arrives after timeout | Webhook delayed 2 min | Payment state corrected from webhook; no refund triggered if second charge succeeded |

### Medium: Error Handling & Edge Cases

| Scenario | Test Data | Expected Outcome |
|----------|-----------|------------------|
| User inputs split > total amount | First=$100, Second=$50, Order=$120 | Backend validation: error "Split amounts exceed order total" |
| Insufficient funds on first card, second card has funds | First card: $0 balance, Second card: $100 | First charge declines; second never attempted; customer sees "First payment failed" |
| Zero split attempt | First=$0, Second=$X | Validation error: "First card amount must be > $0" |

---

## Timeline & Resource Allocation

| Phase | Days | Tester Hours | Dev Hours | PayGate Access |
|-------|------|--------------|-----------|---|
| Phase 1: Unit & Integration | 1–4 | 16 | 32 | Mocked |
| Phase 2: Sandbox Integration | 5–6 | 8 | 8 | Tue 10/29, Thu 10/31 |
| Phase 3: Regression | 7–9 | 8 | 4 | Limited (Thu 10/31 only) |
| Phase 4: UAT & Readiness | 10 | 4 | 2 | Staging only |
| **Total** | 10 | **36 hours** | **46 hours** | — |

**Tester capacity:** 0.5 FTE = 20 hrs/week; 10 working days = 36 hours (sufficient with priority focus).

**Developer capacity:** Includes feature build, test support, and refund/retry logic hardening.

---

## Known Constraints & Mitigation

| Constraint | Impact | Mitigation |
|-----------|--------|-----------|
| PayGate sandbox Tue/Thu only | Limited integration test windows | Pre-stage test data Mon; run Phase 2 split across two sandbox days (Tue & Thu); use mocks for iteration |
| One half-time tester | Test coverage risk if complex issues found | Automate all Phase 1 unit tests; prioritize critical scenarios (split calc, refund timing); developers run regression tests |
| 10-day timeline | Pressure to skip edge cases | Risk-based prioritization; defer load testing to post-release monitoring; release with feature flag off by default |
| 4,000 daily orders on single-card | Regression risk high | Separate single-card test suite; run Phase 3 regression before any production deployment; monitor error rates live |

---

## Acceptance Criteria for Release

1. ✓ Split payment calculation: 100/100 test scenarios pass (unit + sandbox).
2. ✓ Refund SLA: <60 sec refund initiated in 10/10 sandbox decline tests.
3. ✓ Single-card regression: zero failures on 50 sandbox transactions; p95 latency <10% increase.
4. ✓ Data integrity: zero orphaned payments or duplicate charges across all phases.
5. ✓ Error handling: all invalid inputs rejected gracefully; customer messages accurate.
6. ✓ Idempotency: PayGate idempotency keys working; no double-charges on retries.
7. ✓ Monitoring: alerts configured for split-decline and refund-failure; on-call runbook signed off.
8. ✓ Feature flag: split payment disabled in production by default; rollback procedure tested.

---

## Post-Release Monitoring (Critical)

- **First 24 hours:** Manual review of all split transactions and refunds; alert on any refund >60 sec.
- **Week 1:** Error rate and latency dashboard; single-card p95 latency baseline vs. pre-launch.
- **Ongoing:** Refund SLA metric in ops dashboard; escalation if any breach occurs.

---

## Assumptions

- Developers will have split payment API code ready by Day 4 for Phase 2 integration testing.
- PayGate sandbox credentials and test payment methods will be pre-provisioned before Phase 2.
- Staging environment is a full mirror of production with same PayGate merchant account (test mode).
- Single-card checkout has automated regression tests already in CI; we rerun them before release.
- Refund SLA clock defined as: time from second-charge decline response received to refund API call initiated.
- No additional features or scope changes will be added during the 10-day window.
- On-call support is available Day 10 (release day) and Day 11 for live incident response.
