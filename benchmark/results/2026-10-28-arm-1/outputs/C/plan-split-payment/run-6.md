I notice you invoked the help-articles skill but are asking for a test plan. The help-articles skill is for writing end-user documentation, not QA test plans. I'll write the test plan you requested instead.

---

# Risk-Based Test Plan: Split Payment (Release 5.3)

**Release date:** 10 working days (2026-11-07)  
**Resources:** 1 half-time tester, 2 developers  
**Testing window:** PayGate sandbox available Tuesdays and Thursdays only

## Risk Assessment

| Risk | Likelihood | Impact | Priority |
|------|-----------|--------|----------|
| Second charge declined; first charge not refunded within 60s | Medium | Critical (financial liability, customer trust) | **P0** |
| Money split incorrectly (rounding, cent remainder logic) | Medium | Critical (revenue loss or customer overcharge) | **P0** |
| Both charges succeed but recorded as one transaction | Low | Critical (accounting reconciliation, customer confusion) | **P0** |
| First charge declined; second charge succeeds | Low | High (customer funds stuck, support burden) | **P1** |
| Existing single-card checkout broken | High | Critical (4,000 orders/day, revenue impact) | **P0** |
| Remainder cent logic fails for edge cases ($0.01, $999,999.99) | Low | Medium (rare, but data quality) | **P2** |
| PayGate timeout or network error during split | Medium | High (unclear state, manual reconciliation needed) | **P1** |
| Concurrent requests on same order cause race condition | Low | High (duplicate charges, refunds) | **P1** |

## Test Scope (Priority Order)

### P0: Regression and Critical Path (Days 1–5)

**Goal:** Ensure single-card checkout still works and split payment core logic is sound.

**Test cases:**

1. **Regression: Single-card checkout** (manual; 2 hours)
   - Place 10 orders with one card.
   - Verify charges appear in PayGate and order records match.
   - Assumption: Use staging environment, PayGate test cards.

2. **Split payment: Amount division with remainder** (automated; 4 hours)
   - First card $50.01, second card remainder: verify first card charged $50.01, second $0.00.
   - First card $33.33 of $100: verify split is $33.33 and $66.67.
   - Edge cases: $0.01 total (first card $0.01, second $0.00); $1,000,000 (first $500,000.01, second $499,999.99).
   - Assumption: Test amounts in cents; no currency conversion needed in scope.

3. **Split payment: Both charges succeed** (manual via PayGate sandbox; 3 hours)
   - Place order, split evenly (e.g., $50 / $50 of $100).
   - Verify both charges complete in PayGate and order shows two line items.
   - Verify customer sees correct total on receipt.

### P0: Refund on Decline (Days 6–7)

**Goal:** Verify automatic refund within 60s SLA if second charge declines.

**Test cases:**

4. **Second charge declined; first refunded automatically** (manual sandbox; 3 hours)
   - Use PayGate test card that declines on first use.
   - Place split-payment order: first charge succeeds, second declines.
   - Poll PayGate and order system; verify refund appears within 60s.
   - Verify customer notification (email/dashboard).
   - Assumption: Refund is full amount of first charge; no partial refunds in scope.

5. **Refund idempotency** (automated; 2 hours)
   - Simulate refund API called twice due to network retry.
   - Verify only one refund processed; no duplicate refunds.

### P1: Declined First Charge and Timeouts (Days 8–9)

**Goal:** Handle failure modes outside happy path.

**Test cases:**

6. **First charge declined** (manual sandbox; 1 hour)
   - Place order; first charge fails.
   - Verify second charge is not attempted.
   - Verify customer sees error and can retry.

7. **PayGate timeout during second charge** (manual; 1.5 hours)
   - Simulate network delay; second charge times out.
   - Verify order is marked as "pending" (not "failed" or "succeeded").
   - Verify manual recovery process exists (assumption: support can retry via admin panel).

### P2: Edge Cases (Day 10, if time permits)

**Goal:** Data quality for rare scenarios.

**Test cases:**

8. **Cent remainder with many decimal places** (automated; 1 hour)
   - Split $10.005 (invalid currency): verify system rejects before split logic runs.
   - Assumption: Input validation prevents non-cent amounts.

## Test Environment & Constraints

- **PayGate sandbox access:** Tue 2026-10-29, Thu 2026-10-31, Tue 2026-11-05, Thu 2026-11-07.
  - *Allocation:* Day 1 smoke test (2 hrs), Day 4 full refund test (3 hrs), Day 9 timeout test (1.5 hrs).
- **Automated tests:** Run on dev/staging, not sandbox (no PayGate dependency).
- **Manual testing:** Coordinate with developers; 2 devs can assist with test-card setup.
- **Regression (single-card):** Run after each developer commit; automated CI test preferred.

## Out of Scope

- Internationalization (multi-currency split).
- Partial refunds or refund failure recovery.
- PayGate downtime scenarios (assume sandbox stability).
- Mobile app UI (assume web only, or test separately if app is in scope).

## Sign-Off Criteria

- ✅ P0 tests pass (refund timing verified with timestamps).
- ✅ Regression test: single-card checkout shows zero defects.
- ✅ P1 tests pass or have documented workarounds.
- ✅ Release notes document refund SLA and failure modes.

## Assumptions

- "Charge" means authorization + capture (not held-only).
- Remainder cent logic applies to USD cents; exchange-rate rounding is out of scope.
- Automated refund uses PayGate API; no manual intervention required.
- Development is complete by Day 9 to allow testing on release day.
- Single-card checkout code is not touched; regression risk is low.
