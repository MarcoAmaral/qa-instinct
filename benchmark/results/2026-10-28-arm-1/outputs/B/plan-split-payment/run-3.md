# Split Payment Feature (v5.3) — Risk-Based Test Plan

## Assumptions

- PayGate sandbox maintenance windows: Tuesdays and Thursdays; next available windows are 2026-10-29, 2026-10-31, 2026-11-05, 2026-11-07 within the release window.
- "10 working days" = 50 calendar hours. Tester allocation: ~20 hours available; developers contribute ~30 hours to testing (test environment setup, ad-hoc validation).
- Release date: ~2026-11-11 (10 working days from 2026-10-28).
- Single-card checkout is the regression baseline; must maintain ≥99% functional parity.
- PayGate API behavior: standard payment gateway patterns (decline reasons, idempotency, refund latency).
- "Automatic refund within 60 seconds" is a hard requirement enforced by application logic, not PayGate SLA.

---

## Risk Assessment

| Risk | Impact | Likelihood | Priority |
|------|--------|-----------|----------|
| Second charge fails; first charge not refunded or refunded late | Revenue loss, customer frustration, compliance breach | Medium | **Critical** |
| Amount splitting logic error (remainder cent, rounding) | Under/overcharging customers, revenue leakage | Medium | **Critical** |
| Split payment blocks or crashes single-card checkout | 4,000 orders/day fail; revenue impact | Low | **Critical** |
| First charge succeeds but second charge stuck in processing | Double charge to customer, support burden | Medium | **High** |
| PayGate integration fails under load or concurrency | Unpredictable failures in production | Medium | **High** |
| Idempotency/duplicate prevention (retry scenarios) | Duplicate charges if payment request retried | Medium | **High** |
| UI/flow validation (customer selects invalid split) | Confusing UX or impossible payment states | Low | **Medium** |

---

## Testing Strategy

### Phase 1: Unit & Logic (Days 1–3)
**Focus:** Amount splitting, refund logic, edge cases.  
**Effort:** ~8 hours (developers + tester).  
**Environment:** Local / CI.

- Amount splitting correctness (remainder cent placement).
- Refund trigger conditions and 60-second timeout logic.
- Rollback scenarios (charge 1 succeeds → charge 2 fails → refund).

### Phase 2: Integration with PayGate (Days 4–6)
**Focus:** PayGate sandbox interaction, charge sequencing, decline handling.  
**Effort:** ~10 hours (tester, sandbox windows: Tue 29th, Thu 31st).  
**Environment:** PayGate sandbox.

- Successful two-card charge flow (both cards approved).
- Second charge declined → automatic refund within 60 seconds.
- First charge declined → no second charge attempted.
- Partial refund scenarios (if second charge is partial).

### Phase 3: Regression & Edge Cases (Days 7–9)
**Focus:** Single-card checkout still works; edge cases and error states.  
**Effort:** ~8 hours (tester).  
**Environment:** Staging + PayGate sandbox (Thu 7th if available).

- Single-card flow untouched.
- Split payment: customer aborts mid-flow.
- Split payment: timeout during second charge.
- Network errors, PayGate unavailability.

### Phase 4: Load & Stability (Day 10)
**Focus:** Regression testing in staging; readiness sign-off.  
**Effort:** ~2 hours (tester).  
**Environment:** Staging.

---

## Test Scope

### In Scope (High Priority)

1. **Amount Splitting Logic**
   - Split $99.99 (9999 cents) as $50 first card, $49.99 second card.
   - Split $0.01 (1 cent) — both on first card.
   - Split $100.00 — remainder cent rule: $50.01 first, $49.99 second.
   - Negative amounts, zero amounts, amounts > order total (validation).

2. **Charge & Refund Flow**
   - Both charges approved → order complete.
   - First charge approved, second declined → first charge refunded within 60 seconds.
   - First charge declined → no second charge attempted, order cancelled.
   - Refund idempotency (retry refund → same result, no double-refund).

3. **Timing & Failure Recovery**
   - Measure refund latency; alert if > 60 seconds.
   - Network timeout during second charge → retry logic + refund safety.
   - PayGate temporarily down during charge → graceful error, state preserved.

4. **Single-Card Regression**
   - Existing checkout path unmodified; end-to-end flow passes.
   - Performance: no regression in checkout latency.
   - Interoperability: split payment toggle does not appear unless explicitly enabled.

### Out of Scope (Lower Priority)

- PayGate API rate-limiting (rely on PayGate SLAs).
- UI/UX visual design (defer to product team).
- Multi-currency handling (assume single currency per order).
- Refund reversal scenarios (assume refund is terminal).

---

## Test Cases (Risk-Ranked)

### **CRITICAL – Charge & Refund**

| ID | Scenario | Steps | Expected Result | Notes |
|----|----------|-------|-----------------|-------|
| SP-C1 | Second charge declined; first refunded | 1. Split $100 ($60 / $40) 2. Card 1 charged 3. Card 2 declined 4. Wait 60s | Both cards show correct amounts; Card 1 fully refunded within 60s; order status = "Refunded" | Use PayGate decline simulator (test card: 4000000000000002) |
| SP-C2 | Both charges approved | Split $100 ($60 / $40); both cards approved | Order total charged correctly; two successful payment records; order status = "Complete" | Verify PayGate settlement batches both charges. |
| SP-C3 | First charge declined | Split $100 ($60 / $40); Card 1 declined | No charge to Card 2; order status = "Cancelled"; customer notified | Ensure Card 2 never contacted. |
| SP-C4 | Refund idempotency (retry) | Trigger second decline, initiate refund, immediately retry refund API | First refund succeeds; second refund call returns 200 (idempotent); only one debit reversed | Requires application refund idempotency token or PayGate request ID tracking. |

### **CRITICAL – Amount Splitting**

| ID | Scenario | Steps | Expected Result | Notes |
|----|----------|-------|-----------------|-------|
| SP-A1 | Uneven split (remainder cent) | Order $99.99; split as $50.00 / $49.99 | Card 1: $50.00, Card 2: $49.99 (remainder on first card per spec) | Verify database and PayGate transaction records. |
| SP-A2 | Penny split | Order $0.02; split as $0.01 / $0.01 | Card 1: $0.01, Card 2: $0.01 (no remainder) | Edge case with remainder rule. |
| SP-A3 | Single-cent order | Order $0.01; customer attempts split | Validation error or whole amount on Card 1 (design choice) | Clarify spec; assume whole amount on Card 1. |
| SP-A4 | Large order split | Order $10,000.00; split $5,000 / $5,000 | Both charges correct; order net = $10,000.00 | No rounding drift across large values. |

### **CRITICAL – Regression**

| ID | Scenario | Steps | Expected Result | Notes |
|----|----------|-------|-----------------|-------|
| SP-R1 | Single-card checkout | Standard checkout flow, one card | Order completes; no split UI shown | Ensure code path unchanged. |
| SP-R2 | Single-card decline | Standard checkout, card declined | Order cancelled; customer retries available | No regression. |
| SP-R3 | Concurrent orders | 10 single-card + 5 split orders in parallel | All 15 complete or cancel independently; no cross-talk | Stress single-card path. |

### **HIGH – Timing & Failure Modes**

| ID | Scenario | Steps | Expected Result | Notes |
|----|----------|-------|-----------------|-------|
| SP-H1 | Timeout during second charge | Simulate 30s delay on second charge at PayGate | Charge times out; application retries and refunds first charge within 60s | Use PayGate sandbox network simulation or mock. |
| SP-H2 | PayGate sandbox unavailable | Attempt split payment while sandbox is down | Clear error message; order preserved (no partial state); customer can retry | Validate error recovery (not a crash). |
| SP-H3 | Refund timeout (> 60s) | Measure refund latency under normal load | Refund completes in < 60s (target: < 5s). Alert if > 30s. | Acceptance criteria: p99 refund latency ≤ 60s. |

### **MEDIUM – Edge Cases & UX**

| ID | Scenario | Steps | Expected Result | Notes |
|----|----------|-------|-----------------|-------|
| SP-M1 | Customer cancels mid-flow | Select split, fill Card 1, abandon before Card 2 submission | No charge; order state = "Cancelled"; PCI: no Card 2 data retained | Check cleanup. |
| SP-M2 | Invalid split (> order total) | Order $100; customer enters $150 for Card 1 | Validation error ("Split amount exceeds order total") | UX/business rule; assume required. |
| SP-M3 | Same card for both splits | Customer enters same card for Card 1 and Card 2 | Warn or prevent (design choice); assume prevent. | Avoid double-charge risk. |
| SP-M4 | Declined card + retry | Card 1 declines; customer re-enters Card 1 same split | Retry flow clear; idempotency preserved if resubmit | No duplicate charge to Card 2. |

---

## Execution Schedule

| Date | Phase | Key Activities | Owner | Sandbox Access |
|------|-------|-----------------|-------|-----------------|
| 2026-10-28 (Tue) – 2026-10-30 (Thu) | Phase 1 | Unit tests, logic validation, dev sign-off | Developers + Tester | — |
| 2026-10-29 (Tue) | Phase 2 Start | First integration batch (SP-C1, SP-C2, SP-C3) | Tester | ✓ |
| 2026-10-31 (Thu) | Phase 2 Cont. | Refund idempotency, timing tests (SP-C4, SP-H1, SP-H3) | Tester | ✓ |
| 2026-11-04 (Tue) – 2026-11-06 (Wed) | Phase 3 | Edge cases, regression (SP-R1, SP-R2, SP-M1-M4) | Tester | — |
| 2026-11-07 (Thu) | Phase 3 Buffer | Additional sandbox tests if needed | Tester | ✓ |
| 2026-11-10 (Sun) – 2026-11-11 (Mon) | Phase 4 | Final regression, load test, staging sign-off | Tester | — |

---

## Success Criteria

- **Mandatory:**
  - All CRITICAL test cases pass (SP-C*, SP-A*, SP-R*).
  - Refund latency (second charge decline to full refund) ≤ 60 seconds (p99).
  - Single-card checkout: zero regression in daily volume or latency.
  - No double-charges observed in test or production for 1 week post-release.

- **Target:**
  - All HIGH test cases pass (SP-H1–H3).
  - Edge case coverage ≥ 80% (SP-M cases).
  - Load test: 50 concurrent split orders without errors.

---

## Resource Allocation

| Role | Hours | Activities |
|------|-------|-----------|
| Tester (50%) | 20 | Test design (~2h), execution (~16h), bug reporting (~2h) |
| Developer (QA support) | ~10 | Test environment, mocks, PayGate sandbox setup, ad-hoc debugging |
| Developer (Dev owner) | ~5 | Code review of refund logic, timing validation |

---

## Risk Mitigation

1. **Limited Sandbox Access (Tue/Thu only):**
   - Pre-test with mocks/local sandbox on other days.
   - Parallelize mock-based tests (refund logic, idempotency) with real integration tests on sandbox days.

2. **Tight Timeline (10 days):**
   - Prioritize CRITICAL tests first; defer nice-to-have edge cases if time runs short.
   - Use automated test harness for regression (single-card checkout) to save manual effort.

3. **Single Tester, Half-Time:**
   - Developers run smoke tests on builds daily (self-serve validation).
   - Minimize manual steps; favor automated checks where possible.
   - Clarify blockers daily to avoid idle time.

4. **60-Second Refund SLA Risk:**
   - Instrument refund latency in staging; build alerts pre-release.
   - If latency approaches 60s under stress, escalate to engineering before go-live.

---

## Post-Release Monitoring

- Refund latency dashboard (p50, p95, p99) for first week.
- Daily split payment volume and success rate.
- Monitor for duplicate charge complaints.
- Automated alert: any order with both charges and no refund after 90 seconds.
