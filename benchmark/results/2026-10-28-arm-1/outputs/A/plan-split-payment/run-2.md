# Risk-Based Test Plan: Split Payment Feature (Release 5.3)

## Risk Assessment

### Critical Risks (Direct Revenue/Compliance Impact)
1. **Refund failure**: If second charge declines and first charge is not refunded within 60 seconds, customer loses money and triggers chargebacks.
2. **Regression in single-card checkout**: 4,000 orders/day must continue working; any outage is immediate revenue loss.
3. **PayGate integration failure**: External dependency; API changes or unexpected decline responses cause payment processing to fail.
4. **Amount split arithmetic errors**: Incorrect cent allocation or rounding results in over/undercharging customers.

### Medium Risks
5. Concurrent refund requests triggering duplicate refunds or race conditions.
6. Order state mismatch between payment gateway and our database (payment recorded but charge actually failed).

### Low Risks
7. UI/UX flow validation (covered by developer code review).

---

## Test Plan by Phase

### Phase 1: Pre-Sandbox (Days 1–3) — Unit & Mock Testing
**Goal**: Validate logic without external dependency

| Risk | Test Case | Method | Owner |
|------|-----------|--------|-------|
| Amount split arithmetic | Cent remainder logic; test $50.01 → $25.00 + $25.01 | Unit tests | Dev 1 |
| Amount split edges | $0.01, $1.00, max transaction limit | Unit tests | Dev 1 |
| Refund on decline | Mock second charge decline → first charge refund triggered | Mocked PayGate unit tests | Dev 2 |
| Concurrent refunds | Two refund requests simultaneously with mocked PayGate | Mocked unit test | Dev 2 |
| Happy path | Both charges succeed, order confirmed | Mocked integration test | Dev 2 |

**Assumption**: Developers use PayGate's SDK mocks or HTTP stubs for all unit tests.

---

### Phase 2: Sandbox Integration (Days 4–6)
**When**: Thursday Week 1 + Tuesday Week 2 (PayGate sandbox availability Tue/Thu only)
**Goal**: Validate real PayGate integration; focus on critical paths

| Risk | Test Case | Validation | Owner | Stop-Ship? |
|------|-----------|-----------|-------|-----------|
| **Refund failure** | Second charge declines; measure time to first charge refund | Manual; use PayGate decline code; monitor refund within 60s via logs/dashboard | Tester | YES |
| **Both charges succeed** | Split $100: first $60, second $40; both clear to PayGate; order confirmed | Manual sandbox payment; verify both amounts in PayGate reports | Tester | YES |
| **Cent remainder** | Odd amount split ($50.01 → $25.01 + $25.00); verify remainder on first card | Manual; check PayGate charge amounts | Tester | YES |
| **First charge declines** | No second charge attempted; customer re-enters second card | Manual; use PayGate decline code for first | Tester | YES |
| PayGate timeout | Request to PayGate times out; graceful error returned | Manual; simulate network latency; check error handling | Tester | NO |
| Invalid amounts | $0 or negative amount rejected | Manual; attempt $0 split | Tester | NO |

**Critical Validation**: Refund latency measured 3 times; all ≤60 seconds.

**Assumption**: PayGate sandbox supports test decline codes (standard); first and second charge amounts are visible in transaction records.

---

### Phase 3: Regression & Load Testing (Days 7–9)
**Goal**: Ensure no impact on existing checkout; production-readiness

| Risk | Test Case | Method | Owner |
|------|-----------|--------|-------|
| **Single-card regression** | 4,000 orders/day baseline unchanged | Run existing regression suite; compare latency/error rate vs. baseline | Dev 1 |
| **Single-card under load** | Staging: 5x volume (20,000 orders/hour) for 1 hour | Load test (k6 or JMeter); measure checkout latency and error rate | Dev 1 |
| **Split payments under load** | Staging: 50 concurrent split payments | Load test; measure charge success rate and refund timing | Tester |
| **Database consistency** | After 100 split payments, verify order records match PayGate charges | SQL query: count split orders, verify both charges recorded per order | Dev 2 |

**Assumption**: Staging environment is production-identical; regression test suite for single-card exists.

---

### Phase 4: Pre-Release (Day 10)
**Goal**: Final validation before go-live

| Test | Method |
|------|--------|
| End-to-end split payment smoke test | Manual: $100 split 60/40 from UI → confirmation page |
| PayGate sandbox connectivity final check | Automated connectivity test |
| Rollback procedure validated | Developers execute rollback steps; database reverts cleanly |

---

## Resource Allocation

- **Dev 1 (full-time, Days 1–10)**: Unit tests (Days 1–3), regression suite execution (Days 7–9), load test setup/analysis (Days 7–9).
- **Dev 2 (full-time, Days 1–10)**: PayGate integration mocks (Days 1–3), sandbox bug fixes (Days 4–6), database/refund logic validation (Days 7–9).
- **Tester (half-time, Days 1–10)**: Test case design (Day 1), sandbox manual testing (Days 4–6 focusing Tue/Thu), load test execution (Days 7–9), smoke test (Day 10).

**Total test execution time**: ~20 hours manual, ~15 hours automated (within 0.5 FTE capacity across 10 days).

---

## Must-Pass Criteria (Go/No-Go)

1. ✓ Second charge decline → first charge refunded within 60 seconds (3/3 test runs).
2. ✓ Both charges succeed → order confirmed and charges visible in PayGate.
3. ✓ Cent remainder logic correct for 10 varied amounts.
4. ✓ Existing single-card checkout error rate unchanged.
5. ✓ No database inconsistencies (order state = PayGate state).

---

## Should-Pass (If Time Allows)

- PayGate timeout handling validated.
- Load test at 5x volume passes.
- Concurrent refund race condition tested.

---

## Can-Defer (Post-Release or Code Review)

- UI/UX polish.
- Abandoned checkout scenarios (no payment initiated).
- Custom error message wording.

---

## Monitoring Post-Release

**First 48 hours**:
- Split payment error rate (target: <0.1%).
- Refund success rate (target: 100% of declines).
- Refund latency P95 (target: <60 seconds).
- Single-card order volume/latency (no change from baseline).

**Rollback trigger**: Error rate >1% or refund latency >120 seconds → immediate rollback.
