I can see you've invoked the help-articles skill, but that's designed for writing help-center articles (how-to, concept, troubleshooting, reference). A risk-based test plan is a QA deliverable, not an article type.

I'll write the test plan directly as Markdown instead. Here it is:

---

# Risk-Based Test Plan: Split Payment (Release 5.3)

**Release Date:** 2026-11-11 (10 working days from 2026-10-28)  
**Team:** 1 tester (0.5 FTE), 2 developers  
**Testing Window:** Tuesdays and Thursdays only (PayGate sandbox availability)

## Feature Summary
Customers pay for one order with two cards, choosing the split amount. Remainder cents go to the first card. Both charges route through PayGate. If charge 2 declines, charge 1 refunds automatically within 60 seconds.

## Risk Assessment

| Risk | Impact | Likelihood | Priority |
|------|--------|-----------|----------|
| Charge 1 succeeds, charge 2 declines; refund fails or exceeds 60s | High (revenue loss, customer dispute) | Medium | **Critical** |
| Arithmetic error in split (rounding, remainder handling) | High (payment discrepancy) | Medium | **Critical** |
| Regression in single-card checkout (4,000 orders/day affected) | High (business continuity) | Low | **Critical** |
| Partial refund (both charges fail or charge 1 fails after charge 2 succeeds) | High (customer loss of funds) | Low | **High** |
| Concurrency issue (duplicate charges, race conditions during refund) | High (financial audit risk) | Low | **High** |
| Split amounts outside valid range (negative, exceeds total, non-integer cents) | Medium (UX break) | Medium | **High** |
| PayGate API timeout or connection failure mid-transaction | Medium (checkout blocked) | Low | **Medium** |

## Test Strategy

**Effort allocation (40 testing hours over ~6 working days):**
- Regression (single-card): 8 hours
- Happy path (split payment, both charges succeed): 6 hours
- Failure scenarios (charge 2 decline, refunds, concurrency): 16 hours
- Input validation & edge cases: 6 hours
- End-to-end on staging: 4 hours

### Test Levels

#### 1. Unit Tests (Developers own; tester validates)
- **Rounding logic:** split amounts with remainders (e.g., $10.01 → $5.00 + $5.01)
- **Amount validation:** negative, zero, exceeds order total, non-integer cents
- **State machine:** charge 1 success → charge 2 → refund path

#### 2. Integration Tests (Tester + 1 developer)
- PayGate sandbox: both charges succeed (happy path)
- Charge 2 declined: charge 1 refund triggered, completes within 60s (run 10 times to catch timing issues)
- Charge 1 success → charge 2 success → payment gateway timeout during confirmation (test idempotency)
- Concurrent checkout attempts with same card (check for duplicate charges)

#### 3. Regression Tests (Tester)
- **Existing single-card checkout:** place 20 orders with various amounts; confirm all succeed and appear in order history
- **Payment history UI:** single-card and split-payment orders both display correctly
- **Refund processing:** manual refunds on single-card orders still work

#### 4. End-to-End (Tester on staging)
- Full split-payment flow: add to cart → checkout → enter two cards → confirm → order confirmation email → payment appears in dashboard
- Edge case: split $0.01 between two cards (minimum possible split)
- Edge case: split large order ($9,999.99) across two cards

### Critical Refund Scenario (60-second SLA)
- **Test approach:** Charge 2 decline must be tested on **every Tuesday/Thursday** available before release
- **Procedure:** 
  1. Use PayGate sandbox "decline on charge 2" test card
  2. Initiate split payment; charge 1 succeeds, charge 2 declines
  3. Start timer; monitor payment records and customer account
  4. Verify charge 1 appears refunded within 60s
  5. Verify customer receives refund confirmation email
- **Repeat:** 5 separate attempts to account for timing variance
- **Assumption:** PayGate test cards support forced decline on second charge; if not, tester escalates immediately (critical blocker)

### Testing Schedule

| Week | Available Days | Tests |
|------|---|---|
| Week 1 (Nov 4) | Tue 5, Thu 7 | Unit tests + integration happy path |
| Week 2 (Nov 11) | Tue 12, Thu 14 | Refund scenario (critical), edge cases, regression |
| Week 2 (Nov 11) | Before release | Staging end-to-end (if time) |

**Assumption:** Release date is 2026-11-11; only 2 PayGate availability windows before release (Nov 5, 7, and possibly one more). If refund SLA cannot be validated by Nov 7, feature is delayed.

### Out of Scope (Post-Release)
- Mobile app split-payment UI (assumed separate release)
- Loyalty points or discounts applied across split charges (assumed handled by single-card flow)
- Partial refunds (e.g., refund only half of charge 1; assumed not required for 5.3)

### Assumptions
- PayGate sandbox provides test cards for forced decline on any charge
- Refund is automatic via PayGate API; tester can only observe, not trigger manually
- Rounding rule (remainder to first card) is final; no business logic change mid-cycle
- "60 seconds" is a hard SLA; no tolerance range
- Single-card checkout is well-covered by existing test suite; regression testing validates only that it still works post-merge

### Known Blockers & Mitigations
| Blocker | Mitigation |
|---------|-----------|
| Only 2–3 PayGate sandbox windows before release | Start refund validation immediately; if blocked, escalate for API documentation or sandbox extension |
| One tester, half-time = 20 hours/week | Prioritize critical path: refund SLA, rounding, regression |
| If PayGate returns errors instead of decline, refund can't be tested | Use developer to mock PayGate behavior locally; run full integration on staging only |

### Pass/Fail Criteria
- **PASS:** Single-card checkout regression: 20/20 orders succeed
- **PASS:** Refund SLA: 5/5 decline scenarios refund within 60s
- **PASS:** Rounding: 10/10 odd-cent splits calculated correctly
- **PASS:** No duplicate charges, concurrency issues, or partial payment states in logs
- **FAIL:** Any refund exceeds 60s; any regression failure; any rounding error

---
