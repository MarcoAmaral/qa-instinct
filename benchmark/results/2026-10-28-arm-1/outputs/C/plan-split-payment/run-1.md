# Risk-Based Test Plan: Split Payment Feature (Release 5.3)

## Executive Summary

This test plan prioritizes validation by business and technical risk given tight constraints: 1 half-time tester, 10 working days to release, and a 4,000-order/day single-card checkout that must not regress. PayGate sandbox availability (Tue/Thu only) is a critical schedule blocker.

**Assumptions:**
- PayGate sandbox and production environments require separate credentials.
- "Refunded automatically within 60 seconds" means PayGate refund API latency + application processing.
- Release date is 2026-11-10 (10 working days from 2026-10-28).
- Single-card checkout uses the same payment form, now with an optional second-card section.

---

## Risk Assessment

| Risk | Impact | Likelihood | Priority | Mitigation |
|------|--------|------------|----------|-----------|
| Second-charge decline → refund fails or takes >60s | Financial loss, legal exposure | Medium (external API) | **CRITICAL** | Automated integration tests; timeout monitoring; manual retry |
| Regression on single-card flow | 4,000 orders/day fail; revenue impact | Medium (shared code path) | **CRITICAL** | Regression suite; canary deploy on live sandbox |
| Rounding error: remainder cent misallocated | Data integrity; customer disputes | Low (deterministic logic) | **HIGH** | Unit tests for all split combinations; boundary tests |
| PayGate rate limiting or outage during testing | Schedule slip | Medium (Tue/Thu window) | **HIGH** | Reserve Wed evening for Monday tests; use stubs for some flows |
| Concurrent refund requests (edge case) | Duplicate refunds or failed refund | Low (rare timing) | **MEDIUM** | Load test with 10 simultaneous refund triggers |
| Partial payment not visible in customer UI | Customer confusion; support load | Medium (UI integration) | **MEDIUM** | E2E test of order confirmation; screenshot comparison |

---

## Test Scope

### In Scope (Must Test)

1. **Payment split logic** (Unit)
   - Even split (e.g., $100 → $50 + $50)
   - Odd-cent split (e.g., $100.01 → $50.01 + $50.00)
   - Edge: $0.01 total (→ $0.01 + $0.00)
   - Edge: very large amounts ($999,999.99)

2. **PayGate integration** (Integration)
   - Both charges succeed → order placed
   - First charge succeeds, second declines → auto-refund first within 60s
   - First charge declines → no second charge attempted
   - Refund API timeout → retry logic or alert

3. **Single-card regression** (Integration + E2E)
   - Existing single-card flow still works
   - Payment form shows/hides second-card section correctly
   - No double-charging if form submitted twice

4. **UI and order flow** (E2E)
   - Customer enters split amounts; confirmation shows both charges
   - Post-payment: order details list both card endings and amounts
   - Customer receives one order confirmation (not two)

### Out of Scope (Defer or Stub)

- PayGate account creation or onboarding
- Refund processing time <60s (assumption: PayGate SLA met; monitor but do not test retry storms)
- Currencies other than the release currency (scope to one)
- Subscriptions or recurring payments (assume single order only)

---

## Test Schedule (10 Working Days)

**Weekly testing slots on PayGate sandbox: Tue 2026-10-29, Thu 2026-10-31, Tue 2026-11-05, Thu 2026-11-07**

| Week | Tue | Wed | Thu | Fri | Mon | Focus |
|------|-----|-----|-----|-----|-----|-------|
| **1** (Oct 29–Nov 2) | *Setup + unit tests* | Stub testing | *Integration setup* | Dev bug fixes | Code review | Foundation |
| **2** (Nov 5–Nov 9) | *Refund + regression* | Load test stubs | *Canary deploy test* | Final regression | Dev ready | Go/no-go |

---

## Test Cases by Priority

### Priority 1: Refund on Second-Charge Decline (CRITICAL)

| ID | Scenario | Method | Expected | Owner |
|----|----------|--------|----------|-------|
| P1-1 | Second charge declined, first auto-refunded | Integration (PayGate sandbox) | First refund initiated within 5s; status "refunded" within 60s | Tester |
| P1-2 | Refund API timeout | Integration (mock timeout) | Retry within 10s, alert logged | Dev (unit test) |
| P1-3 | Refund succeeds but order status not updated | Integration | Order status shows "refunded" after 60s | Tester |
| P1-4 | Customer sees refund in statement | E2E (live sandbox, manual check) | Refund appears on card statement within 1 business day (defer to day-after-go-live) | Post-release |

### Priority 2: Single-Card Regression (CRITICAL)

| ID | Scenario | Method | Expected | Owner |
|----|----------|--------|----------|-------|
| P2-1 | User pays with one card, no second card | E2E (live checkout) | Order placed, one charge only | Tester |
| P2-2 | Existing saved card (from pre-release) | E2E | Form loads; customer can still use old card | Tester |
| P2-3 | High volume: 50 orders/min single-card | Load test | No timeouts, no double-charges | Dev (load test) |

### Priority 3: Split Logic Correctness (HIGH)

| ID | Scenario | Method | Expected | Owner |
|----|----------|--------|----------|-------|
| P3-1 | Split $100.00 (even) | Unit | $50.00 + $50.00 | Dev |
| P3-2 | Split $100.01 (odd cent) | Unit | $50.01 + $50.00 | Dev |
| P3-3 | Split $0.01 | Unit | $0.01 + $0.00 | Dev |
| P3-4 | Invalid input: negative amount | Unit | Validation error shown | Dev |
| P3-5 | Customer-entered split stored correctly | Integration (DB check) | Both amounts logged and charged | Tester |

### Priority 4: UI and Customer Experience (HIGH)

| ID | Scenario | Method | Expected | Owner |
|----|----------|--------|----------|-------|
| P4-1 | Confirmation page shows both cards | E2E | "Charge card ending 1234: $50.01" + "Charge card ending 5678: $50.00" | Tester |
| P4-2 | Error message if first card declined | E2E | Clear message; second card not charged | Tester |
| P4-3 | Order email lists both transactions | E2E | Customer receives one email with both charges | Tester |

### Priority 5: Edge Cases & Load (MEDIUM)

| ID | Scenario | Method | Expected | Owner |
|----|----------|--------|----------|-------|
| P5-1 | Concurrent refund requests (2+ for same order) | Load test (10 simultaneous) | Only one refund issued; no duplicate | Dev |
| P5-2 | Split with coupon/discount | E2E | Discount applied to total before split | Tester |
| P5-3 | Customer navigates back after first charge | E2E | Form state preserved; no double-charge on resubmit | Dev (unit test) |

---

## Execution Plan

### Week 1 (Oct 29–Nov 2)

**Tue 10/29 (PayGate available)**
- Tester: Run P1-1, P1-3 (sandbox refund scenario, manual) — 2 hrs
- Dev: Unit tests for P3-1 to P3-4 passing locally

**Wed 10/30 (PayGate offline)**
- Tester: P2-2 (single-card with saved card, stub PayGate) — 1 hr
- Dev: Refund API timeout mock test (P1-2)

**Thu 10/31 (PayGate available)**
- Tester: P2-1, P4-1 (single-card E2E, split order confirmation) — 3 hrs
- Dev: Regression test suite (P2 cases)

**Fri 11/1 & Mon 11/4 (no sandbox)**
- Tester: P4-2 (error handling, mock) — 1 hr
- Dev: Code review, bug fixes from testing

---

### Week 2 (Nov 5–Nov 9)

**Tue 11/5 (PayGate available)**
- Tester: P5-1 (concurrent refunds, load test) + P1-1 re-run (verification) — 2.5 hrs
- Dev: Load test P2-3 (high-volume single-card)

**Wed 11/6 (PayGate offline)**
- Tester: P4-3 (order email, if time allows) — 1 hr
- Dev: Final bug fixes, deploy staging

**Thu 11/7 (PayGate available)**
- Tester: Canary deploy test (live sandbox, 100 split + 100 single-card orders) — 3 hrs
- Pass/fail decision for release

**Fri 11/8 & Mon 11/9: Buffer**
- Fix any blocker bugs; sign off

---

## Test Data & Environments

- **Sandbox (PayGate Tue/Thu):** Credentials from Dev; use test cards provided by PayGate
- **Staging:** Deploy code; mock PayGate for regression tests on Wed/Fri
- **Test cards (assumed):** Visa success, Visa decline, Amex, Discover (from PayGate sandbox docs)
- **Amounts:** $10.00, $100.00, $100.01, $0.01, $9,999.99

---

## Exit Criteria

**Go/no-go check: Thu 11/7 end of day**

**Go-live approval requires:**
- ✅ All P1 and P2 tests pass (refund + regression)
- ✅ Zero regressions on single-card in load test
- ✅ Canary: 100 split + 100 single-card orders, zero failures
- ✅ Refund latency <60s for 95th percentile in sandbox

**No-go if:**
- Refund latency >60s
- Single-card regression observed
- Refund logic fails for any P1 case

---

## Assumptions & Unknowns

1. **Refund verification:** Manual check of card statement deferred to post-release (cannot automate within 60s window).
2. **Currencies:** Plan assumes USD; if multi-currency, duplicate P3 split tests for each currency.
3. **PayGate rate limits:** Assumed compatible with 1 tester running 50 manual transactions/day; if lower, use mocks more.
4. **Rollback plan:** Not specified; assume feature can be toggled off in code if critical bug found post-release.
5. **Canary deploy:** Assuming staging mirrors production; if not, adjust canary to production traffic replay.

---

## Reporting & Escalation

- **Daily standup (10 min):** Tester + 1 dev
- **BlockerAlert:** If P1/P2 test fails, stop and escalate same day
- **Sandbox downtime:** Reschedule to next Tue/Thu; do not attempt Wed/Fri live tests

---

## Post-Release Monitoring (First 48 Hours)

- Monitor PayGate refund success rate for split payments (target: 100%)
- Monitor single-card order latency and volume (regression baseline: 4,000 orders/day, no slowdown)
- Manual spot-check: 5 refunded orders appear on customer statements
