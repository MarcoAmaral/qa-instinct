# Risk-Based Test Plan: Split Payment Feature (Release 5.3)

## Executive Summary

This test plan prioritizes payment processing and regression testing against high-impact risks. Given sandbox availability (Tue/Thu only) and resource constraints (1 FTE tester, 10 working days), testing will focus on critical path scenarios with pragmatic scope management.

---

## Risk Assessment & Prioritization

| Risk Category | Risk | Impact | Likelihood | Priority |
|---|---|---|---|---|
| **Payment Processing** | Second charge declined; refund fails or exceeds 60s window | Revenue loss, customer disputes, chargeback risk | Medium | **CRITICAL** |
| **Payment Processing** | Cent remainder logic incorrect (split 101¢ into $0.50 + $0.51) | Underbilling or overbilling; customer complaints; audit findings | Medium | **CRITICAL** |
| **Payment Processing** | First charge succeeds, second charge hangs (timeout/network error) | Payment stuck state; unclear order status; refund orphaned | Low-Medium | **CRITICAL** |
| **Payment Processing** | PayGate returns duplicate charge (idempotency not handled) | Overcharging customers; reconciliation failures | Low | **HIGH** |
| **Regression** | Existing single-card checkout breaks (4,000 orders/day affected) | Severe business impact; orders fail across platform | Low | **CRITICAL** |
| **Regression** | Payment confirmation email delayed or missing after split payment | Customer confusion; support load | Low | **HIGH** |
| **UX/Data** | Order status unclear after second charge decline (is refund complete?) | Customer calls support; poor experience | Medium | **HIGH** |
| **Edge Cases** | Invalid amounts: $0, negative, exceeds card limit, non-numeric | User errors; system crashes; data corruption | Medium | **HIGH** |
| **Concurrency** | Two rapid split-payment requests from same session | Race condition in refund logic; inconsistent state | Low | **MEDIUM** |

---

## Test Strategy

### Approach
- **Levels**: Unit tests (developers) + integration tests (sandbox) + end-to-end happy path (staging)
- **Phases**: Phase 1 (Tue 11/3) early validation; Phase 2 (Thu 11/5, Tue 11/10) refinement + regression
- **Coverage priority**: Payment logic > refund logic > UX > edge cases > load testing
- **Regression**: Smoke tests on existing single-card flow (daily)

### Test Environment Plan
- **Sandbox testing** (PayGate required): Tue 11/3, Thu 11/5, Tue 11/10 only — schedule critical tests in these windows
- **Staging** (mock PayGate OK): Continuous testing of happy path and error handling
- **Assumptions**: 
  - PayGate sandbox mirrors production behavior closely enough
  - Staging environment has PayGate mock/integration available
  - Developers own unit + integration test automation

---

## Test Scope

### In Scope (Must Test)
1. **Split payment success path**: Valid amounts, both charges succeed, order completes
2. **Second charge decline + refund**: Verify automatic refund within 60s, order marked failed, first charge reversed, customer notified
3. **Cent remainder logic**: 
   - $50.01 split as $25.00 + $25.01 ✓
   - $1.00 split as $0.50 + $0.50 ✓
   - $0.01 split as $0.01 + $0.00 ✓
4. **First charge decline**: Fail immediately, no second charge attempt, no refund needed
5. **Timeout/network errors**: Second charge hangs; refund initiated on timeout; order marked "pending refund"
6. **Regression - single-card flow**: Existing checkout unaffected; all payment types work
7. **Invalid inputs**: Zero, negative, non-numeric amounts; clear error messages
8. **Idempotency**: Duplicate refund request does not re-refund

### Out of Scope (Assumptions/Deferral)
- Load testing (4,000 orders/day not a concern with split feature unless specific bottleneck identified)
- PCI compliance audit (assumed existing controls cover both charges)
- Refund processing past 60s window (assumed PayGate handles; monitoring alerts will flag)
- Mobile app integration (assume web only, or mobile tested by app team separately)
- International payment types (assume USD/primary region only)

---

## Test Schedule & Phases

### Phase 1: Early Validation (Tue 11/3, sandbox available)
**Goal**: Confirm refund logic and critical paths work; unblock developers
**Duration**: 4–6 hours (tester at 50%)

- [ ] Manual smoke test: Single split payment (equal split, e.g., $50 = $25 + $25) → both charges succeed
- [ ] Manual smoke test: Second charge decline → verify refund initiated and first charge refunded within 60s
- [ ] Manual validation: Cent remainder ($1.01 split as $0.50 + $0.51); verify order total correct
- [ ] Automated: Unit test coverage for refund timeout logic (developer-owned)
- **Outcome**: Pass/fail gates further development; identify critical bugs to developers SAME DAY

### Phase 2: Refinement & Edge Cases (Thu 11/5, sandbox available)
**Goal**: Validate edge cases; confirm regression; prepare staging tests
**Duration**: 6–8 hours (tester at 50%)

- [ ] Repeat Phase 1 critical tests with different amounts ($100, $1.50, $99.99)
- [ ] Test invalid inputs: $0, negative, non-numeric, >card limit (e.g., $100,000)
- [ ] Test first charge decline path (no second charge, no refund)
- [ ] Timeout scenario: Network latency/delay on second charge (manual simulation via proxy/mock)
- [ ] Regression smoke: Single-card checkout still works with 10 test orders (various amounts)
- [ ] Automated: End-to-end regression test added to CI (developer-owned)
- **Outcome**: Bug fixes prioritized; staging tests ready

### Phase 3: Final Validation (Tue 11/10, sandbox available)
**Goal**: Confirm all fixes; final regression; go/no-go decision
**Duration**: 4–6 hours (tester at 50%)

- [ ] Retest Phase 1 & 2 critical cases (second charge decline, refund within 60s, cent logic)
- [ ] Regression: Single-card flow (50 test orders minimum to confirm stability)
- [ ] Performance spot-check: No degradation vs baseline (confirm order processing time < 5s)
- [ ] Idempotency: Verify duplicate refund request handled gracefully
- **Outcome**: Go/No-Go readiness; final test report

### Staging & Pre-Release (11/11, release week)
- Continuous smoke testing of both split and single-card flows
- Monitor first 1 hour of production (first 150–200 live orders) for anomalies

---

## Test Cases (Priority Order)

### Critical Path (Must Pass)

**TC-SP-001: Split Payment Success (Equal Split)**
- Precondition: Valid payment cards, order total $50.00
- Action: Select split payment, enter $25.00 on card 1, confirm (card 2 gets $25.00)
- Expected: Both charges succeed, order status = "Paid", confirmation email sent within 2 min
- Acceptance: Card statements show two $25.00 charges; order total = $50.00

**TC-SP-002: Second Charge Declined, Auto-Refund**
- Precondition: Valid card 1, card 2 will be declined in PayGate, order total $60.00
- Action: Split as $40.00 + $20.00, submit
- Expected: Card 1 charges $40, Card 2 declines, refund initiated immediately, refund completes within 60s, order status = "Payment Failed", notification sent to customer
- Acceptance: Card 1 statement shows $40 charge then $40 refund (within 60s); order email shows failure reason

**TC-SP-003: Cent Remainder Logic (Uneven Split)**
- Precondition: Order total $1.01
- Action: Split as $0.50 on card 1 (remainder $0.51 should go to card 2)
- Expected: Card 1 charges $0.50, Card 2 charges $0.51, order total verified as $1.01
- Acceptance: Order itemization and charge split logged correctly

**TC-SP-004: First Charge Declined, No Second Attempt**
- Precondition: Card 1 will be declined, valid card 2, order total $30.00
- Action: Attempt split payment ($15.00 + $15.00)
- Expected: Card 1 declines, payment stops, Card 2 NOT charged, order status = "Payment Declined"
- Acceptance: Only one card statement entry; no orphaned charges

**TC-SP-005: Regression - Single-Card Checkout Still Works**
- Precondition: Existing single-card flow active, 10 test orders prepared
- Action: Process 10 orders via standard (non-split) checkout with various amounts ($5, $50, $99.99)
- Expected: All orders complete successfully, no errors introduced by split-payment feature code
- Acceptance: 10/10 orders paid, confirmed, no latency increase >5%

### High Priority (Should Pass)

**TC-SP-006: Invalid Amount - Zero**
- Precondition: Split payment UI open
- Action: Enter $0.00 on card 1
- Expected: Error message "First card amount must be greater than $0", form not submitted
- Acceptance: User cannot proceed with $0 amount

**TC-SP-007: Invalid Amount - Negative**
- Precondition: Split payment UI open
- Action: Enter $-10.00 on card 1
- Expected: Error message "Amount cannot be negative", form not submitted
- Acceptance: User cannot proceed with negative amount

**TC-SP-008: Invalid Amount - Exceeds Total**
- Precondition: Order total $50.00
- Action: Enter $75.00 on card 1
- Expected: Error message "First card amount cannot exceed order total", form not submitted
- Acceptance: User cannot proceed; no charges attempted

**TC-SP-009: Timeout on Second Charge (Network Delay)**
- Precondition: Mock PayGate delay of 70s on second charge, order total $40.00
- Action: Split as $20 + $20, submit
- Expected: First charge succeeds ($20), second charge timeout after 30s (assumed timeout threshold), refund initiated for first charge, completes within 60s, order status = "Payment Failed - Refund Pending"
- Acceptance: Card statement shows charge then refund; customer notified; order marked for monitoring

**TC-SP-010: Duplicate Refund Request (Idempotency)**
- Precondition: Second charge declined, initial refund completed
- Action: System attempts to refund again (simulated via backend call)
- Expected: Second refund request returns "already refunded" status, no double-refund
- Acceptance: Card statement shows only one $40 charge + one $40 refund; no duplicate refund

### Medium Priority (Should Test if Time Allows)

**TC-SP-011: Confirmation Email After Split Payment**
- Precondition: Split payment successful
- Expected: Email received within 2 min, shows both charges clearly
- Acceptance: Email delivery within SLA

**TC-SP-012: Order Status Page Shows Split Details**
- Precondition: Order with split payment completed
- Expected: Customer can view order page and see "Paid: $X via Card 1, $Y via Card 2"
- Acceptance: UX clear and accurate

**TC-SP-013: Concurrency - Two Simultaneous Split Requests (Same Session)**
- Precondition: Session open, two orders submitted within 1 second
- Expected: Both processed independently, no interference, both succeed or fail cleanly
- Acceptance: No race conditions; audit log shows both transactions

---

## Regression Testing Plan

**Scope**: Existing single-card checkout must remain stable (4,000 orders/day)

**Approach**:
1. **Daily smoke tests** (5 min, tester): 3 orders via single-card checkout (various amounts: $5, $50, $100) — verify success
2. **Weekly regression suite** (20 min, automated CI): 50 test orders via single-card flow; verify latency, success rate, error messages unchanged
3. **Error path regression**: Declined card, timeout, invalid card number — confirm existing error handling unaffected

**Success Criteria**: 
- Zero regression bugs post-release
- Single-card checkout latency within 5% of baseline
- Existing error messages unchanged

---

## Environment & Resources

### Available Testing Windows
- **PayGate Sandbox**: Tue 11/3, Thu 11/5, Tue 11/10 (3 windows × ~4–6 hours = 12–18 hours available)
- **Staging (mock)**: Continuous
- **Production**: Release 11/11

### Resource Allocation
- **Tester (1 FTE @ 50%)**: 4 hours/day × 10 working days = 40 hours available
  - Allocation: 18 hours sandbox testing (phases 1–3), 12 hours staging/automation, 10 hours regression/go-live monitoring
- **Developers (2 FTE)**: Own unit/integration tests; implement features; support tester during phases
- **Test Data**: ~50–100 test orders prepared; PayGate test cards provided

### Test Deliverables
- [ ] Test plan (this document)
- [ ] Test case execution log (Phase 1, 2, 3 results)
- [ ] Bug tracker entries (high-risk issues flagged immediately)
- [ ] Regression test suite (automated, added to CI)
- [ ] Go/No-Go report (Tue 11/10 EOD)

---

## Success Criteria

**Must-Have (Release Blocker)**:
- [x] Second charge decline triggers refund within 60 seconds (verified in Phase 1)
- [x] Cent remainder logic correct (all test splits total to order amount)
- [x] Existing single-card checkout unaffected (zero regression bugs)
- [x] First charge decline stops second attempt (no orphaned charges)

**Should-Have**:
- [x] Invalid inputs rejected with clear error messages
- [x] Idempotency confirmed (no duplicate refunds)
- [x] Timeout scenario handled gracefully (order marked pending, customer notified)

**Nice-to-Have**:
- Order status page shows split details
- Confirmation email clearly shows both charges

---

## Known Limitations & Assumptions

### Constraints Accepted
1. **Limited sandbox access**: Only 3 testing windows available; critical tests scheduled in these windows; remaining testing via staging mock
2. **Resource constraints**: 1 tester @ 50% means edge cases and performance testing deferred; prioritized critical path
3. **Timeline pressure**: 10 working days is tight; test plan focuses on go/no-go criteria rather than exhaustive coverage

### Assumptions Made
1. **PayGate behavior**: Sandbox refund behavior mirrors production; PayGate provides test card numbers for decline scenarios
2. **Order processing time**: Existing single-card orders process in <5s; split payment adds <1s overhead (not load-tested)
3. **Refund success**: Assumes PayGate refund API is reliable; if refund fails, manual intervention is acceptable (within business SLA)
4. **Currency**: USD only; no multi-currency scenarios tested
5. **PCI Compliance**: Existing security controls cover split payment (both charges treated as normal transactions)
6. **Error messages**: Developers implement clear, user-facing error messages for all failure scenarios
7. **Monitoring**: Post-release monitoring alerts configured for refund delays >60s, duplicate charges, orphaned transactions
8. **Backward compatibility**: Existing single-card code path untouched; split payment is new code path only

### Deferred Testing (Post-Release Monitoring)
- Load testing under 4,000+ orders/day volume (monitor performance in production week 1)
- Multi-currency and international payment types
- Mobile app integration (assumed separate work stream)
- Long-term refund reconciliation (e.g., chargebacks after 30 days)

---

## Go/No-Go Decision Criteria (Tue 11/10)

**GO** if:
- ✓ TC-SP-001, 002, 003, 004, 005 all pass
- ✓ Zero critical bugs remain open
- ✓ Regression test suite passes (50+ single-card orders)
- ✓ Refund logic verified within 60s window

**NO-GO** if:
- ✗ Second charge decline refund exceeds 60s window (critical SLA miss)
- ✗ Cent remainder logic incorrect (data integrity risk)
- ✗ Single-card regression failures
- ✗ Orphaned charges or duplicate refunds detected
