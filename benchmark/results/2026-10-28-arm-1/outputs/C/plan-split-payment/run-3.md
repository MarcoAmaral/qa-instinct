# Split Payment (Release 5.3) — Risk-Based Test Plan

## Overview

**Feature:** Customers pay for one order with two cards; the second charge auto-refunds if declined.

**Constraints:** 1 half-time tester, 2 developers, 10 working days, PayGate sandbox available Tues/Thurs only. Existing single-card checkout (4,000 orders/day) must remain stable.

**Assumption:** "Automatic refund within 60 seconds" means the system initiates refund processing within 60 seconds of decline; the refund may take longer to appear.

---

## Risk-Based Priorities

| Risk | Impact | Mitigation | Test Strategy |
| --- | --- | --- | --- |
| **CRITICAL: Second charge declined, first not refunded** | Direct financial loss + customer disputes | Automated refund logic before launch | Execute on live PayGate sandbox; monitor all decline scenarios |
| **CRITICAL: Existing checkout broken** | Revenue impact on 4,000/day orders | Regression suite before each release | Run single-card checkout tests daily starting day 1 |
| **HIGH: Remainder cent calculation wrong** | Revenue loss if systemic; customer disputes | Unit test + integration test on edge cases | Test: $1.01 split 50/50, $0.01 total, $X.99 splits |
| **HIGH: PayGate integration fails** | Feature unusable | Integration tests during sandbox windows only | Reserve all PayGate tests for Tues/Thurs |
| **MEDIUM: Refund race conditions** | Refunds delayed or duplicated | Timeout + idempotency checks in code | Test with concurrent declines; verify only one refund issued |

---

## Test Plan

### Phase 1: Unit & Calculation Tests (Days 1–3)
**Owner:** Tester + developers (no external dependency)

- Amount-split logic: 50/50, 80/20, $0.01 total, $X.99 amounts, $Y.00 amounts
- Remainder cent placement: verify cent goes to card 1 in all cases
- Edge cases: 1-cent orders, maxint values
- No PayGate calls; mock the gateway

**Completion gate:** All split calculations pass; no off-by-one errors.

### Phase 2: Integration Tests — PayGate Sandbox (Days 4, 8, 11–12)
**Owner:** Tester (Tuesday/Thursday slots, ~2 hours per window)

**Session 1 (Day 4, Tuesday or Thursday):**
- First charge succeeds, second charge succeeds → full order confirmed
- Verify both charges appear in PayGate sandbox account
- Verify order status transitions correctly

**Session 2 (Day 8, next Tues/Thurs):**
- First charge succeeds, second charge **declines** → verify automatic refund
- Measure refund initiation time (must be ≤60 seconds)
- Verify declined order marked as failed in system
- Verify customer receives notification
- Repeat 3 times to catch timing issues

**Session 3 (Days 11–12, final Tues/Thurs before release):**
- First charge declines → order fails before second attempt
- Concurrent orders (up to 5) with mixed outcomes
- Verify no refund requested when first charge failed

**Completion gate:** All PayGate scenarios pass; refund fires within 60 seconds in all decline cases.

### Phase 3: Regression Testing — Existing Checkout (Days 1–10, daily)
**Owner:** Tester (30 minutes/day)

- Single-card payment: success and decline paths
- Order confirmation, email, DB records unchanged
- Same checkout path used by 4,000/day orders
- Spot-check on staging daily; full regression suite on day 10

**Completion gate:** No breakage in single-card path.

### Phase 4: Load & Concurrency Tests (Days 9–10, if time permits)
**Owner:** Developers (tester assists)

- Simulate 50 concurrent split-payment orders (if staging supports it)
- Verify no duplicate refunds, lost charges, or DB inconsistencies
- Skip if staging environment is limited; focus on critical path instead

---

## Test Execution Schedule

| Day | Window | Activity | Owner |
| --- | --- | --- | --- |
| 1–3 | All weekdays | Unit tests, calculation tests, mock integration | Tester + devs |
| 4 | Tue or Thu | PayGate sandbox: happy path (both charges succeed) | Tester |
| 5–7 | All | Regression testing, code review, fix bugs | Tester + devs |
| 8 | Tue or Thu | PayGate sandbox: second charge decline, refund check | Tester |
| 9–10 | All | Load tests, final regression, fix last-minute issues | Tester + devs |
| 11–12 | Tue or Thu | Final sandbox validation, sign-off | Tester |

---

## Test Cases to Stop For (Release Blockers)

1. Automatic refund does not fire or fires after >60 seconds
2. Refund fires but customer still charged on first card
3. Single-card checkout fails or is slower than baseline
4. Remainder cent goes to wrong card
5. Duplicate refunds issued to customer

---

## Test Cases to Document But Not Block Release

- Refund takes 61–120 seconds (monitor in production, acceptable if within SLA)
- PayGate API timeout handled gracefully (error message shown, order queued for retry)
- Concurrent refund requests to PayGate handled correctly (depends on PayGate's idempotency)

---

## Assumptions Stated

1. **Automatic refund timing:** System initiates refund within 60 seconds; actual refund to customer's bank may take 2–5 business days.
2. **PayGate rate limits:** Sandbox supports ~10 requests/minute; test cases batched accordingly.
3. **Staging environment:** Supports up to 50 concurrent requests; production load testing happens post-release.
4. **Team capacity:** 1 tester at 50% = 20 hours/week (expected: 15–20 hours total for this plan); 2 devs assist with integration setup and fixes.
5. **Code quality:** Feature code reviewed before phase 2; no critical bugs expected in unit tests.

---

## Success Criteria

- ✓ All calculation tests pass
- ✓ Automatic refund fires ≤60 seconds in 3 sandbox decline scenarios
- ✓ Single-card checkout regression tests all pass
- ✓ No duplicate refunds issued
- ✓ Feature launches on schedule (day 10)
