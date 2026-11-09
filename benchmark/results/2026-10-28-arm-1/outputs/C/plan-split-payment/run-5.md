I notice you've invoked the help-articles skill, which is designed for writing end-user help center content. A test plan is an internal QA document, not a help article, so I'll write it directly instead.

---

# Split Payment (Release 5.3) — Risk-Based Test Plan

## Executive Summary

This plan focuses testing effort on the highest-risk areas of split payment: the refund automation (60-second deadline with external dependency), cent remainder handling, and regression of the single-card flow. Resource constraints (1 half-time tester, 10 working days, PayGate sandbox on Tue/Thu only) require serial testing windows and parallel development integration.

## Scope

**In scope:**
- Two-card payment split and authorization flow
- Cent remainder allocation to first card
- PayGate integration for both charges
- Automatic refund when second charge declines
- Refund timing compliance (60 seconds)
- Single-card checkout regression

**Out of scope:**
- Single-card payment improvements or new features
- PayGate sandbox infrastructure or uptime
- Payment methods other than cards (ACH, digital wallets)
- Partial refunds or manual refund flow
- Fraud detection or 3D Secure workflows

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| Refund fails to trigger or exceeds 60-second deadline | High | Critical: customer charged twice, support escalation | Unit test refund service in isolation; load test with concurrent declined charges; time refund execution end-to-end |
| First charge succeeds, second charge declines → refund does not reverse the first charge | High | Critical: customer charged without authorization | Negative-case testing: force decline on second charge in sandbox; verify refund appears in PayGate ledger |
| Cent remainder logic fails (rounds wrong direction or drops the cent) | High | Medium: accounting discrepancy, fraud investigation | Property-based testing of split amounts ($0.01 to $999,999.99); verify math in both directions |
| Single-card checkout broken by new payment code | Medium | Critical: 4,000 orders/day affected | Regression test suite (existing or new); run against staging before merge |
| PayGate sandbox unavailable on release date | Medium | High: unable to verify fix after dev | Test on last available Tue/Thu before release; automate happy-path tests to run Wed/Fri against mock |
| Race condition: refund initiated while second charge still processing | Medium | High: duplicate refunds or orphaned charges | Functional test with 100ms delays; lock-based unit test of refund service |

## Test Strategy

### Critical Path (Must Complete)

1. **Refund automation** (40% of test time)
   - Happy path: charge 1 succeeds, charge 2 declines → refund within 60s
   - Timing: measure elapsed time from decline to refund initiation
   - PayGate ledger: verify refund appears with correct amount and order ID
   - Test data: use PayGate sandbox decline card (assumed: `4000000000000002` or similar)

2. **Cent remainder** (20% of test time)
   - Split $1.00 as $0.50 / $0.51 → first card charged $0.51
   - Split $10.01 three ways (order total split uneven) → remainder on first card
   - Split $0.01 (edge case, first card gets all) → second card gets $0.00 or fails gracefully
   - Boundary: $999,999.99 split, verify no overflow or rounding error

3. **Single-card checkout** (20% of test time)
   - Existing happy path: one card, full amount charged, order completes
   - Existing error path: card declined, order not charged
   - Regression: run 10 representative transactions (mix of amounts)

4. **Integration** (20% of test time)
   - Staging environment: split and single-card flows both active
   - Smoke test: 5 split, 5 single-card charges complete end-to-end
   - Database: verify order, charge, and refund records correct

### Lower Priority (If Time Permits)

- Concurrent splits on same order (race condition)
- Refund timeout: what happens if second charge takes > 60s to decline
- Customer-facing messaging: error messages for declined charges

## Test Execution Schedule

**Assumption:** Today is 2026-10-28; release is 2026-11-11 (10 working days).

| Week | Tue/Thu | Available Testing Window | Focus |
| --- | --- | --- | --- |
| W1 (Oct 28–Nov 1) | Oct 29, 31 | 2 days | Unit tests (dev team); cent remainder logic |
| W2 (Nov 4–8) | Nov 5, 7 | 2 days | Integration tests (dev + tester); refund timing; regression suite |
| W3 (Nov 11–15) | Nov 11 | 0 days (release day) | — |

**Fallback:** If PayGate unavailable (Tue/Thu), tester runs existing regression suite and mock-based happy-path tests Wed/Fri.

## Test Cases

### Refund Automation

| Case | Setup | Action | Expected Result | Notes |
| --- | --- | --- | --- | --- |
| RF-001 | Order $100, split $60 / $40 | Force decline on card 2 in PayGate | Refund $60 to card 1 within 60s; order state = "refunded" | Measure time from decline API response to refund POST |
| RF-002 | Order $100, split $50 / $50 | Decline card 2; check PayGate ledger every 5s | Refund appears in ledger with order ID within 60s | Verify idempotency: refund called twice = one refund |
| RF-003 | Refund in progress; customer refreshes order page | Observe UI state | Order shows "refunding"; after 60s, "refunded" | UI does not allow customer action during refund window |

### Cent Remainder

| Case | Setup | Action | Expected Result | Notes |
| --- | --- | --- | --- | --- |
| CR-001 | Split $1.00 as card1 / card2 | User enters $0.50 for card 1 | Card 1 charged $0.51; card 2 charged $0.49 | Remainder cent always to card 1 |
| CR-002 | Split $10.01 | User enters $5.00 for card 1 | Card 1 charged $5.01; card 2 charged $5.00 | Handles common rounding case |
| CR-003 | Split $0.01 | User enters $0.01 for card 1 | Card 1 charged $0.01; card 2 charged $0.00 or rejected with clear error | Edge case: does card 2 accept $0 charge? Assumption: no; error message clear |
| CR-004 | Split $999,999.99 | User enters $500,000.00 for card 1 | Card 1 charged $500,000.00; card 2 charged $499,999.99; no overflow | Large amount boundary |

### Single-Card Regression

| Case | Setup | Action | Expected Result | Notes |
| --- | --- | --- | --- | --- |
| SC-001 | Single-card flow enabled | User pays with one card, full order amount | Charge succeeds; order marked "paid" | Baseline: existing behavior unchanged |
| SC-002 | Card declined | User pays with PayGate decline card | Charge fails; order state "payment failed"; no refund flow triggered | Verify new split logic does not interfere |
| SC-003 | Mix of 5 split + 5 single-card orders in staging | Run both flows concurrently | All 10 orders complete with correct charges | Database consistency check |

## Regression Test Coverage

Assumption: Existing regression suite covers single-card happy path and error cases. If not, create minimal suite (5–10 test cases):
- Successful single-card charge
- Declined card
- Timeout or PayGate error
- Order state transitions
- Invoice generation post-charge

Run suite on **every merge** to `main` and **before release** against staging.

## Entry / Exit Criteria

**Entry:**
- Split payment code merged to dev/staging branch
- PayGate sandbox credentials and decline card list available
- Test data (orders, cards) populated in sandbox

**Exit:**
- All critical-path test cases pass (RF, CR, SC)
- Refund timing logged and < 60s for 10 consecutive test runs
- Regression suite passes
- No known blockers for release
- Tester sign-off documented

## Resource Allocation

- **Tester (1 FTE @ 50%):** 20 hours over 10 working days
  - PayGate sandbox testing (Tue/Thu only): 10 hours
  - Regression and mock testing (Wed/Fri): 8 hours
  - Documentation and sign-off: 2 hours

- **Developers (2 FTE):** Parallel feature work + integration support
  - Unit tests: refund service, cent logic (owned by devs)
  - Staging integration: devs run integration tests; tester verifies

**Assumption:** Devs will unit-test their own code; tester focuses on integration and PayGate sandbox scenarios.

## Known Constraints & Assumptions

| Item | Assumption |
| --- | --- |
| PayGate sandbox decline behavior | Declining second charge uses PayGate sandbox decline card (e.g., `4000000000000002`); refund endpoint available in sandbox |
| Refund timing | 60-second deadline starts from when PayGate API returns "declined"; system refund completion, not customer account credit |
| Order state model | Orders have states: pending → processing → charged / refunding → refunded / failed |
| Split is once per order | Customer chooses split once at checkout; cannot split a single card charge across more cards after authorization |
| No concurrent splits | Test does not cover multiple splits initiated on one order simultaneously |

## Sign-Off

Test plan complete: 2026-10-28  
Ready for execution: 2026-10-29 (first Tue/Thu window)
