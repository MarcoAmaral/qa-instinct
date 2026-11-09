# Risk-Based Test Plan: Split Payment Feature (Release 5.3)

## Assumptions

- PayGate sandbox credentials and test card data are available; API error responses are documented
- Current test infrastructure supports automated API testing and database state verification
- Staging environment mirrors production configuration; production payment processors are unavailable for testing
- Development builds are stable by day 5 of the 10-day window
- No additional payment compliance scope (PCI-DSS, 3D Secure) is required
- Existing single-card checkout has baseline test coverage; regression bugs are in-scope
- "Half-time tester" = 20 hours per week over 2 weeks = ~40 hours total effort

---

## Risk Assessment & Test Scope

### Critical Risks (Must Test)

| Risk | Impact | Mitigation Strategy |
|------|--------|---------------------|
| Second charge declined; first charge not refunded or refund delayed >60s | Financial loss, customer dispute, legal exposure | Automated tests for decline scenario; timing validation |
| Remainder cent logic fails (wrong amount on first/second card) | Customer overcharge/undercharge, regulatory audit flag | Unit + integration tests for edge cases (odd-cent amounts) |
| Split payment breaks backward compatibility with single-card flow | 4,000 orders/day fail silently or degrade | Regression tests on existing checkout; side-by-side comparison |
| PayGate integration failure (sandbox downtime, API changes) | Cannot verify feature works before release | Manual smoke test on available sandbox windows; API contract tests |
| Race condition on partial payment (two concurrent split orders hit same payment state) | Charge duplicates, refund targets wrong charge, DB corruption | Concurrency tests with payment state locks; audit logs |

### High Priority Risks (Should Test)

| Risk | Impact | Mitigation Strategy |
|------|--------|---------------------|
| Split amount validation (negative, zero, >order total, non-integer cents) | Invalid order state, customer confusion | Boundary + invalid-input tests |
| Refund logic targets wrong charge or wrong order | Customer refunded wrong amount or wrong person | Refund verification tests (check PayGate + DB state) |
| UI/UX error messaging during split flow | Customer abandonment, support burden | Manual UAT; error path walkthrough |
| Timeout or network error mid-transaction | Charge pending forever, unclear to customer | Timeout injection tests; customer-facing status clarity |

---

## Test Plan

### Phase 1: Unit & Component Testing (Days 1–4)

**Effort: 16 hours**

1. **Amount Splitting Logic**
   - Remainder cent assignment (test even/odd cent splits: $10.00 → $5.00/$5.00; $10.01 → $5.01/$5.00; $0.01 → $0.01/$0.00)
   - Validation (reject negative, zero, non-integer cents, >order total)
   - Math precision (no float rounding errors)

2. **Refund Trigger & Timing**
   - Unit tests: Refund fires when second charge status = declined
   - Verify 60-second window logic (mock time; test at 59s and 61s)
   - Verify refund amount = first charge amount (no off-by-one errors)

3. **PayGate Integration Stub**
   - Mock PayGate API for both success and decline scenarios
   - Verify request payloads (charge 1, charge 2, refund request)
   - Error code handling (timeout, auth fail, server error)

4. **Database Schema**
   - Verify new columns/tables (split_payment record, refund_reference)
   - Verify constraints (foreign keys, NOT NULL on critical fields)
   - Verify indexes on payment_status, refund_status for query performance

---

### Phase 2: Integration Testing (Days 5–7)

**Effort: 16 hours**

**Sandbox Windows: Use Tuesday & Thursday slots only (2 slots available in 10-day window)**

1. **Happy Path (PayGate Sandbox)**
   - Complete split payment flow: split amount entry → charge 1 → charge 2 → order confirmation
   - Verify both charges appear in PayGate dashboard with correct amounts
   - Verify DB order record reflects both charges and split logic

2. **Decline Scenario (PayGate Sandbox)**
   - Charge 1 succeeds; charge 2 declined (use PayGate test card that triggers decline)
   - Verify refund is initiated immediately
   - Wait 61 seconds; verify refund completed in PayGate + DB shows refund_status = "completed"
   - Verify customer sees clear error and retry option

3. **Timeout/Network Error (Staging with chaos injection)**
   - Network timeout during charge 2 request
   - Verify system enters recovery state (does not auto-refund prematurely, waits for async callback)
   - Manually trigger callback; verify order settles correctly

4. **Single-Card Regression (Staging)**
   - Existing checkout still works (no split, single charge)
   - Order confirmation, receipt email, order history all function
   - Performance baseline (response time vs. pre-split code)

5. **Concurrency (Staging with load test)**
   - Two split-payment orders submitted simultaneously for same customer
   - Verify no charge duplication, no refund cross-contamination
   - Verify payment state is properly isolated per order

---

### Phase 3: Manual UAT & Edge Cases (Days 8–9)

**Effort: 8 hours**

1. **User Experience**
   - Split amount entry: can I enter $0 on second card? (should auto-close split, become single-card)
   - Error messages: are decline messages clear? Do they suggest retry?
   - Mobile responsiveness (if applicable)

2. **Edge Cases**
   - Order total = $0.01 (force remainder behavior: $0.01 on card 1, $0.00 on card 2)
   - Order total = $999,999.99 (max amount handling)
   - Split at 1 cent / 99.99 (asymmetric split)
   - Refund with partial amount already captured (if applicable to PayGate's async model)

3. **Rollback Scenario**
   - Verify if feature flag is disabled, all orders revert to single-card path
   - No orphaned split_payment records

---

### Phase 4: Smoke & Regression (Day 10, pre-release)

**Effort: 5 hours**

1. **Production-Like Environment**
   - Sanity check: single charge, split payment happy path
   - Verify monitoring/alerting is active (refund latency, charge decline rate, failed refunds)
   - Check logs for errors or warnings in payment flow

2. **Regression Confirmation**
   - Run existing checkout tests on production environment
   - Spot-check 10–20 real orders from staging (sample of single-card + split-card)

---

## Test Data & Fixtures

- PayGate sandbox test cards: success card (e.g., 4111 1111 1111 1111), decline card (provided by PayGate)
- Test orders: $10.00 (even), $10.01 (odd), $0.01 (minimum)
- Mock refund callback delays: 1s (success), 61s (timeout boundary)

---

## Known Limitations & Risk Acceptance

- **Limited PayGate sandbox availability** (2 windows): Live integration testing is compressed into 4 hours total. Post-release monitoring is essential; if issues arise, they will surface in production.
- **Single tester on half-time**: Concurrency & load testing will be light. Rely on developer unit tests and production telemetry for confidence in high-concurrency scenarios (e.g., flash sales).
- **No 3D Secure testing**: Assume feature does not require 3D Secure flow; if it does, scope expands significantly.
- **Async refund assumed**: Test plan assumes PayGate refunds are asynchronous and callback-driven. If synchronous, adjust refund timing tests.

---

## Exit Criteria

- [ ] All critical-risk tests pass
- [ ] Remainder cent logic verified for ≥5 amounts (even, odd, minimum)
- [ ] Decline + refund flow validated on PayGate sandbox (refund ≤60s)
- [ ] Single-card regression tests all pass
- [ ] Error messages reviewed and approved by product
- [ ] Monitoring/alerting for refund latency and decline rate confirmed active
- [ ] No high-severity defects open

---

## Post-Release Monitoring

- **Alert on**: Refunds not completed within 120s (2× SLA buffer), charge-without-matching-refund patterns, PayGate API errors
- **Daily report**: Split payment volume, decline rate, manual refund count (should be zero)
- **First week review**: Customer support tickets mentioning split payment; any refund disputes
