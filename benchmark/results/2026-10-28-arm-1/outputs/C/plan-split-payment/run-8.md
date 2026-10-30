# Split Payment (Release 5.3) — Risk-Based Test Plan

## Overview

| Aspect | Details |
|--------|---------|
| Feature | Two-card payment splitting for single orders |
| Release | 5.3 (10 working days) |
| Team | 1 QA (0.5 FTE), 2 developers |
| Sandbox availability | Tuesdays, Thursdays only |
| Assumption: "10 working days" = 2 weeks with 2 available test days | — |

---

## High-Risk Areas (Test First)

### Risk 1: Refund Logic Fails → Uncaptured Charges

**Scenario:** First charge succeeds; second charge declines. Refund must execute within 60 seconds or customer is charged and has no order.

**Tests (priority order):**
1. Second charge declines → first charge automatically refunds within 60 seconds (use PayGate sandbox decline simulator). Verify refund appears in both PayGate and order status within 2 minutes.
2. Refund API call fails (simulate timeout) → order enters "refund_pending" state, admin can manually retry. Verify retry refunds the full first charge amount.
3. Refund call times out mid-execution → no duplicate refunds issued. Verify order shows only one refund in ledger.

**Test on:** Tuesday or Thursday with PayGate sandbox. Estimated: 2 hours.

---

### Risk 2: Cent Rounding → Financial Mismatch

**Scenario:** Amounts in cents; odd-cent remainder goes to first card. If implemented wrong, total charge ≠ order total.

**Tests:**
1. Order total $10.01 (1001 cents); customer chooses $5.00 (500 cents) on card 1 → card 1 charged 501 cents, card 2 charged 500 cents. Verify ledger shows 1001 total, no off-by-one errors.
2. Order $0.01 (1 cent) → card 1 charged 1 cent, card 2 charged 0 cents. Verify PayGate processes 0-cent charge as no-op (not an error).
3. Bulk test: 50 random splits across orders $0.50 to $999.99. Verify ledger reconciles to 100% accuracy.

**Test on:** Tuesday or Thursday. Estimated: 1.5 hours.

---

### Risk 3: Regression in Single-Card Checkout

**Scenario:** 4,000 orders/day use single-card flow. A bug in split logic corrupts the checkout for everyone.

**Tests:**
1. Smoke: Place 20 single-card orders end-to-end (no card 2 supplied). Verify all succeed, charges are correct, no split logic runs.
2. Load: Simulate 100 concurrent single-card checkouts. Verify < 1% error rate (PayGate SLA baseline).
3. Backward compatibility: Verify old orders (pre-release) still appear correctly in customer dashboard; no data migration errors.

**Test on:** Any day (uses dev/stage, not PayGate sandbox). Estimated: 2 hours.

---

## Medium-Risk Areas (Test Second)

### Risk 4: Payment Gateway Integration Failures
- **Card 1 succeeds, Card 2 timeout (not declined):** Order hangs. Verify timeout is retried or escalated to admin dashboard within 5 minutes.
- **PayGate API rejected due to rate limit:** Both charges fail. Verify order shows "payment_failed", customer can retry.

**Tests:** 1 hour. (Simulate via dev mocks if PayGate sandbox unavailable; confirm on sandbox Tue/Thu.)

### Risk 5: Amount Validation
- **Customer tries to split $100 as $50 on card 1, $55 on card 2:** Backend rejects (total mismatch). Verify user-facing error message.
- **Customer chooses $0 on card 1:** Verify UI blocks this (single-card flow should be used instead).
- **Customer chooses negative amount:** Verify validation rejects it before hitting PayGate.

**Tests:** 0.5 hour. (UI + backend unit tests; no PayGate needed.)

### Risk 6: Order State & Idempotency
- **User submits twice in rapid succession:** Only one pair of charges issued. Verify idempotency key or duplicate detection works.
- **Refund is issued, then customer refreshes page:** Refund appears instantly (cached state vs. fresh lookup).

**Tests:** 1 hour.

---

## Lower-Risk Areas (Spot-Check)

- Customer sees correct split amounts on order confirmation.
- Email receipt shows both cards and amounts.
- Admin dashboard displays split details (2 charge lines, 1 refund if applicable).
- Split payment appears in billing reports (reconciliation view).

**Estimated:** 1 hour.

---

## Test Schedule (10 Working Days)

| Week | Mon | Tue | Wed | Thu | Fri |
|------|-----|-----|-----|-----|-----|
| 1 | Regression smoke (2h) | **Risk 1: Refund** (2h) + Risk 2: Rounding (1h) | Unit tests for validation | **Risk 1 retest + Risk 4 sandbox** (2h) | Risk 2 bulk test (1h) + Risk 3 load (2h) |
| 2 | Risk 5 validation + Risk 6 idempotency (2h) | **Final PayGate regression** (2h) | Spot-checks + bug fix verification | **Release readiness** | Release |

**Assumptions:**
- PayGate sandbox is ready Tue/Thu from day 1.
- Developers finish core implementation by day 3 (Wednesday).
- One bug cycle for regressions discovered in week 1.
- Admin dashboard and reporting features are already built (not new in this release).

---

## Test Environment & Data

| Item | Assumption |
|------|-----------|
| **PayGate test cards** | Use PayGate sandbox decline, success, timeout simulators (standard test suite). |
| **Test amounts** | Amounts $0.01 to $9,999.99 in increments of $0.01 (cover rounding edge cases). |
| **Test data cleanup** | All PayGate sandbox charges/refunds are ephemeral; no cleanup needed. |
| **Metrics to track** | Refund latency (target: < 5 sec, must be < 60 sec); checkout error rate (target: < 0.1%); ledger reconciliation (target: 100% within 24h). |

---

## Exit Criteria (Pass/Fail)

**Must pass to release:**
1. ✓ Second charge decline triggers refund of first charge within 60 seconds (100% of 10 test cases).
2. ✓ Cent rounding: ledger reconciles to exact order total (50-case bulk test passes).
3. ✓ Single-card checkout: no regression (20 end-to-end orders succeed; 100-concurrent load test < 1% error).
4. ✓ No duplicate charges or refunds in any scenario.

**May defer (document for 5.4):**
- Advanced admin dashboard features (if not required for payment processing).
- Invoice line-item formatting for split payments (cosmetic).

---

## Risk Mitigation

| Risk | If Fails | Mitigation |
|------|----------|-----------|
| Refund doesn't execute in 60s | Customer charged, no order; support escalation required | Implement admin manual-refund UI; deploy kill switch to disable feature; add alerting for failed refunds. |
| Rounding error in amounts | Financial reconciliation fails; audit required | Pre-release: reconcile 1 week of sandbox test data against PayGate export (manual audit). Post-release: daily reconciliation report in admin dashboard for first month. |
| Single-card regression | 4,000 orders/day fail | Automated regression test in CI; feature flag to disable split payment instantly if error rate spikes. |

---

## Dependencies & Unknowns

- **Assumption:** PayGate's decline simulator and timeout simulator are in the sandbox docs or exposed via test endpoints.
- **Assumption:** Developers can provide a feature flag or kill switch (no code change needed to disable split payment in prod).
- **Assumption:** Admin dashboard and reconciliation reports already exist for single-card payments; split payment data only needs to fit into existing schemas.
- **Unknown:** Does PayGate charge for sandbox test transactions? (Affects test budget.) *Assumption: No cost; used for qualification only.*
