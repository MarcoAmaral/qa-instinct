# Risk-Based Test Plan: Split Payment Feature (Release 5.3)

## Executive Summary

This test plan prioritizes validation of the split payment feature within resource and sandbox availability constraints. Testing focuses on payment processing integrity, refund automation, and regression protection for the existing 4,000 daily single-card orders. Release date: November 11, 2026 (10 working days from October 28).

## Risk Assessment & Prioritization

| Risk | Impact | Likelihood | Priority | Mitigation |
|------|--------|-----------|----------|-----------|
| Second charge declines; first charge not refunded within 60s | Critical—revenue loss, customer disputes, chargeback fees | High—external gateway failures common | **P0** | Automated refund verification; timeout testing |
| Amounts split incorrectly (cents rounding error) | High—revenue discrepancy, customer complaints, reconciliation issues | Medium—off-by-one logic common | **P0** | Unit tests + end-to-end charge validation |
| First charge succeeds but second charge never processes | High—order incomplete, customer confused | Medium—integration timing issues | **P0** | Payment state verification; idempotency checks |
| Regression: existing single-card checkout breaks | Critical—4,000 orders/day affected, major incident | Medium—shared payment code path | **P0** | Smoke test on existing flow; production-like load testing |
| Split payment UI allows invalid splits (negative, >100%, non-numeric) | Medium—user confusion, support tickets | Medium—frontend validation gaps | **P1** | Input boundary testing; accessibility review |
| PayGate rate limits or sandbox errors prevent testing | Medium—schedule impact | High—sandbox availability Tue/Thu only | **P1** | Offline mock testing; backup dev environment |
| Refund initiated but PayGate confirms charge not actually refunded | High—customer charged twice effectively | Low—PayGate stable, but high impact if occurs | **P0** | Refund state reconciliation; idempotent retry logic |
| Race condition: duplicate charges if split request submitted twice | High—customer charged multiple times | Low—unlikely if UI/frontend prevents, but high impact | **P1** | Idempotency key validation; concurrent submission testing |
| Refund succeeds in system but fails at PayGate silently | High—accounting error, false refund | Low—if logging present | **P1** | Webhook validation; refund confirmation tracking |

## Test Strategy

### Phase 1: Offline & Unit Testing (Mon 10/28–Wed 10/30)
**Goal:** Validate logic before sandbox availability; maximize asynchronous progress.
- Unit tests: rounding logic, state transitions, refund timing
- Mock PayGate integration; test failure paths
- UI input validation (boundary cases: $0.00, $0.01, max order value)
- Regression unit tests on single-card checkout paths

**Effort:** Developers + tester (async code review); 1 tester day

### Phase 2: Sandbox Testing (Thu 11/31–Fri 11/1, Tue 11/5–Wed 11/6)
**Goal:** Full end-to-end validation on PayGate sandbox; respect Tue/Thu availability.
- Happy path: split payment, both charges succeed, correct amounts charged
- Failure scenarios:
  - Second charge declined → first refund within 60s, verify state
  - Second charge timeout → verify retry + eventual refund
  - First charge declined → no second charge attempted
  - Partial refund rejection (PayGate returns error) → retry logic + alert
- Idempotency: submit split payment twice, verify only one charge pair
- Refund webhook validation: PayGate confirms refund → verify system state update

**Effort:** 1 tester (half-time = 2 full days across 4 calendar days)

### Phase 3: Load & Regression Testing (Mon 11/4, Thu 11/7–Fri 11/8)
**Goal:** Ensure existing checkout unaffected; handle baseline load.
- Smoke test: 10 single-card transactions end-to-end
- Concurrent split payment requests (20–50 concurrent) to detect race conditions
- Mixed workload: 80% single-card / 20% split-payment simulation

**Effort:** Developers (automation); 0.5 tester days

### Phase 4: UAT & Manual Edge Cases (Mon 11/10–Tue 11/11)
**Goal:** Customer-facing validation; final sign-off.
- Happy path walk-through (tester + 1 developer)
- Edge cases: very small splits ($0.01/$X), large orders, multiple retries
- PayGate webhook resilience: manually delay webhook, verify eventual consistency

**Effort:** 1 tester (0.5 days) + 1 developer (0.5 days)

---

## Test Cases (Priority Order)

### P0: Payment Integrity & Refunds

**TC-001: Successful Split Payment**
- Pre: Customer has valid order for $10.00
- Action: Split: $6.00 on Card A, $4.00 on Card B; submit
- Expect: Both charges succeed; order marked complete; receipts show correct amounts per card
- Evidence: PayGate transaction log, order ledger, customer email receipts

**TC-002: Second Charge Declined—Refund Within 60s**
- Pre: Both cards valid; PayGate configured to decline Card B
- Action: Submit split ($7.00 / $3.00)
- Expect: First charge succeeds; second declines; first refund initiated within 60s; both cards show $0 net charge after 90s; order marked failed; customer notified
- Evidence: PayGate logs, system audit log, customer notification email timestamp

**TC-003: Refund Verification Resilience**
- Pre: First charge succeeded, second charge declined; refund initiated
- Action: PayGate webhook delivery delayed/missing for first refund confirmation
- Expect: System retries refund status check; eventual reconciliation within 5 min; no "orphaned" successful charges
- Evidence: System logs show retry attempts, final state consistent

**TC-004: Rounding—Remainder Cent to First Card**
- Pre: Order $10.01; split $5.00 / $5.01
- Action: Submit split
- Expect: PayGate charged $5.00 Card A, $5.01 Card B (remainder on first card)
- Evidence: PayGate transaction details; order ledger shows amounts correctly attributed
- Repeat: $0.03, $0.02 splits; $99.99 order split $50/$49.99

**TC-005: First Charge Fails**
- Pre: PayGate configured to decline Card A
- Action: Submit split ($6/$4)
- Expect: First charge fails; second charge not attempted; no charges appear on either card; customer sees single error; order marked failed
- Evidence: PayGate logs, system audit (only one attempted charge)

### P0: Idempotency & Race Conditions

**TC-006: Duplicate Submission—Same Split**
- Pre: Split payment form submitted
- Action: User double-clicks submit; two identical requests sent <100ms apart
- Expect: Only one charge pair created; second request rejected or returns same transaction ID; no duplicate charges
- Evidence: PayGate logs show one transaction; order ledger single entry

**TC-007: Concurrent Splits—Different Orders**
- Pre: 50 split payment requests in parallel
- Action: Load test tool submits 50 distinct split payments
- Expect: All process without deadlock; charge counts match submission count; no missing or orphaned charges
- Evidence: PayGate transaction count = 50 order count × 2 charges; audit log sequential

### P0: Regression—Existing Single-Card Checkout

**TC-008: Single-Card Checkout Unaffected**
- Pre: Release deployed; single-card checkout code path shared with split payment
- Action: Process 10 single-card transactions across multiple browsers (Chrome, Safari, Firefox)
- Expect: All succeed as before; same processing time; customer emails sent; no errors in logs
- Evidence: Order history shows normal completion; no increase in error rate

**TC-009: Single-Card Under Load**
- Pre: Baseline established (4,000 orders/day = ~3 orders/min average)
- Action: Simulate 20 concurrent single-card orders
- Expect: No timeout errors; latency ±10% vs. pre-release baseline; no failed charges
- Evidence: Performance metrics; error rate <0.1%

### P1: Input Validation & UX

**TC-010: Invalid Split—Amounts**
- Pre: Split payment form displayed
- Action: Attempt: $0 on Card A, all on Card B
- Expect: Form validation error; submit button disabled; helpful message
- Repeat: negative amount, non-numeric input, total > order amount

**TC-011: Boundary: Minimum Split**
- Pre: Order $0.01
- Action: Attempt split $0.00 / $0.01
- Expect: UI prevents $0.00 entry OR system accepts and charges $0 / $0.01 (clarify assumption: minimum per-card charge is $0.01)
- Evidence: Order processes or form rejects with reason

**TC-012: Very Large Order Split**
- Pre: Order $9,999.99
- Action: Split $5,000.00 / $4,999.99
- Expect: Both charges succeed; no amount truncation; exact cents honored
- Evidence: PayGate ledger matches order exactly

### P1: Refund Edge Cases

**TC-013: Refund Retry After Transient Failure**
- Pre: First charge succeeded; second declined; refund initiated but PayGate API returns 503
- Action: Wait 2 minutes; system retries refund
- Expect: Refund succeeds on retry; order eventually marked refunded; no alert to ops
- Evidence: Audit log shows retry; final state = refunded

**TC-014: Manual Refund if Automatic Fails**
- Pre: Automatic refund did not complete within 60s (e.g., PayGate offline)
- Action: Tester manually triggers refund via admin panel or API
- Expect: Refund succeeds; order updated; customer notified via email; no double refund
- Evidence: Customer account + PayGate show single refund credit

### P1: Webhooks & Async Confirmation

**TC-015: PayGate Refund Webhook**
- Pre: First charge succeeded; second declined; refund issued
- Action: PayGate sends refund confirmation webhook (mocked or delayed)
- Expect: System receives webhook; order state updated to "refunded"; no duplicate processing if webhook retried
- Evidence: Webhook processed once; order ledger final state = refunded

### P2: Documentation & Compliance

**TC-016: Split Payment Recorded in Customer Invoice**
- Pre: Split payment completed
- Action: Customer views order detail / invoice
- Expect: Invoice shows "Split Payment: $X on Card A (last 4 digits), $Y on Card B (last 4 digits)"
- Evidence: PDF invoice, order history page

---

## Testing Schedule (Accounting for Sandbox Availability)

| Week | Mon | Tue | Wed | Thu | Fri |
|------|-----|-----|-----|-----|-----|
| Oct 28–Nov 1 | Unit tests | — | Unit tests | **Sandbox available** | **Sandbox available** (P0 cases) |
| Nov 4–8 | Load test | — | — | **Sandbox available** (P0 refund edge cases) | **Sandbox available** + regression |
| Nov 11–15 | UAT | **Release** | — | — | — |

**Sandbox Usage Notes:**
- Tue 10/29, Thu 10/31: Unavailable (assume sandbox down)
- Tue 11/5, Thu 11/7: Use for P0 happy path + critical refund scenarios
- Tue 11/11 (release day): No testing if release goes out; hold for rollback validation only

---

## Resource Allocation & Effort

| Phase | Tester | Dev 1 | Dev 2 | Notes |
|-------|--------|-------|-------|-------|
| Unit Testing (Mon–Wed) | 1 day async | 2 days mock setup | 1 day setup | Code review; no sandbox needed |
| Sandbox Testing (Thu–Fri, Tue) | 2 days (half-time = 1 day) | 0.5 days support | 0.5 days troubleshooting | Tight window; prioritize P0 |
| Load Testing (Mon, Thu–Fri) | 0.5 days | 1.5 days automation | 0.5 days | Async; developers own |
| UAT (Mon–Tue release week) | 0.5 days | 0.5 days | 0 days | Go/no-go sign-off |
| **Total** | **4 days** (2 FTE over 2 weeks) | **4.5 days** | **2 days** | Tester at 50% → 1 FTE equivalent |

---

## Acceptance Criteria for Release

✅ **Go/No-Go Checklist:**
- [ ] TC-001, TC-002, TC-003, TC-004, TC-005: P0 test cases PASSED
- [ ] TC-006, TC-007: No duplicate charges or race condition failures
- [ ] TC-008, TC-009: Single-card checkout smoke test PASSED; load test <0.5% error rate
- [ ] TC-014: Manual refund path documented and verified
- [ ] Security review: PCI DSS compliance for split payment data (card handling)
- [ ] PayGate integration: No outstanding critical issues in logs
- [ ] Refund timeout: Confirmed <60s on sandbox (representative of prod)

**If any P0 case fails:** Hold release; triage as bug vs. test assumption.

---

## Assumptions

1. **Sandbox availability:** PayGate sandbox down all days except Tue/Thu; no override available.
2. **Release window:** 10 working days = Oct 28 + 14 calendar days ≈ Nov 11 (accounting for weekends); release cuts Mon Nov 10, deploys Tue Nov 11.
3. **Minimum charge:** Each card must be charged at least $0.01 (UI prevents $0 splits).
4. **Refund automation:** System attempts refund for 60 seconds; if PayGate fails, ops alerted; manual override available.
5. **Single-card regression:** Existing checkout code must be exercised in regression tests; no code changes to single-card path, so low risk.
6. **Idempotency:** Frontend + backend idempotency keys implemented; duplicates rejected at gateway or app level.
7. **Webhook resilience:** PayGate webhooks may arrive out-of-order or be retried; system handles idempotently.
8. **Production readiness:** Load test at 20 concurrent orders is representative of peak load (<1% of 4,000/day traffic).
9. **Tester context:** Single tester new to feature; developers available for blocking issues same day.
10. **Failure rate baseline:** PayGate second-charge decline rate assumed ~2–5% (industry norm); test with synthetic decline configuration.

---

## Risk Mitigation & Contingencies

| Contingency | Trigger | Action |
|---|---|---|
| Sandbox unavailable on Thu 10/31 | Maintenance extends past Fri | Scale back P1 cases; defer to Tue 11/5; use mock integration for TC-002 |
| Refund logic broken and found late (Mon 11/10) | Sandbox test fails near release | Roll back feature; single-card checkout ships; split payment deferred to 5.4 |
| Load test shows regression (>0.5% error increase) | Error rate on single-card rises | Root cause in 2 days (2 developers); if unfixable, defer split payment release |
| Tester unavailable day-of | Unexpected absence | Developers run P0 scripted cases; prioritize TC-001, TC-002; defer UAT |

---

## Sign-Off & Traceability

- **Test Plan Owner:** QA Lead (signed off: [date])
- **Development Owner:** Tech Lead (signed off: [date])
- **Release Owner:** Product Manager (signed off: [date])

**Test Artifacts to Retain:**
- Sandbox test screenshots (happy path + refund within 60s timestamp)
- PayGate transaction log export (P0 cases)
- Load test results (concurrent order success rate)
- Refund audit trail (timestamps, webhook delivery confirmation)
