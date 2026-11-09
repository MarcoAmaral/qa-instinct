# Risk-Based Test Plan: Split Payment (Release 5.3)

## Test Strategy

**Assumptions:**
- Release date is 2026-11-11 (10 working days from today)
- PayGate sandbox testing possible 2026-11-03, 2026-11-05, 2026-11-10
- Manual testing on staging environment; developer-owned unit/integration tests
- Tester has 50 hours available (5 days × 8 hours × 50%)
- Refund automation tested in staging with mocked PayGate delays
- Single-card checkout regression testing can use production-like data without hitting PayGate

**Risk Tiers:**

| Risk | Impact | Likelihood | Approach |
|------|--------|-----------|----------|
| **Critical** | Revenue loss, chargebacks, financial liability | Medium | Test exhaustively; automate regression suite; run on PayGate sandbox |
| **High** | Customer impact, data corruption, manual remediation required | Medium-High | Scripted manual test cases; edge case coverage |
| **Medium** | Degraded UX, confusion, support load | Low-Medium | Smoke test with representative data |

---

## Critical-Risk Test Cases (16 hours)

**1. Payment Split Calculation**
- Split $10.00 as $5.00 + $5.00 (exact split)
- Split $10.01 as $5.01 + $5.00 (remainder cent on first card)
- Split $0.01 as $0.01 + $0.00 (minimum first card)
- Split $99.99 as $1.00 + $98.99 (large second card)
- **Verify:** Order total = sum of both charges; cent remainder always on first card

**2. Both Charges Succeed**
- Charge 1 authorizes → Charge 2 authorizes
- **Verify:** Both payments recorded in PayGate; order marked paid; no duplicate charges; customer email sent once; order proceeds to fulfillment

**3. Second Charge Declined**
- Charge 1 succeeds → Charge 2 is declined by PayGate
- **Verify:** Refund initiated within 60 seconds; first card refunded; order state reverted to unpaid; customer notified of declined second card; order does NOT proceed to fulfillment

**4. Second Charge Times Out**
- Charge 1 succeeds → Charge 2 times out (PayGate unresponsive)
- **Verify:** Refund triggered; order state consistent; no orphaned payments; no retry loops

**5. First Charge Declined**
- Charge 1 declined
- **Verify:** Order never charged; no refund triggered; second charge never attempted; customer can retry

**6. Database Consistency After Failure**
- Run all failure scenarios; verify no orphaned records, no duplicate order entries, payment ledger complete

---

## High-Risk Test Cases (12 hours)

**7. Regression: Single-Card Checkout**
- Existing flow must work unchanged
- **Verify:** 10 transactions through single-card (PayGate sandbox on 2026-11-03)
- **Success Criteria:** All succeed without interference from new code; zero regressions in payment recording

**8. Edge Cases: Amounts**
- $0.00 order with $0.00 split (free order)
- Amounts exceeding card limits (test with realistic max $5,000+)
- Fractional cent (system rejects or handles gracefully)
- **Verify:** Clear error messages; orders rejected safely; no partial charges

**9. Split Amount Validation**
- User enters split exceeding order total
- User enters negative amount
- User enters non-numeric values
- **Verify:** Client-side validation prevents submission; server-side validation rejects if bypassed

**10. Refund Timing (Sandbox: 2026-11-05)**
- Measure actual refund latency; verify it stays under 60 seconds
- Test with Charge 1 = $50 (large refund)
- **Success Criteria:** Refund completes in ≤59 seconds; customer sees credit within expected bank processing time

**11. Concurrent Split Payments**
- Two split orders submitted simultaneously by same customer
- **Verify:** No card state conflicts; both process independently; correct refund if either Charge 2 fails

**12. Payment Method Validation**
- Both cards must be valid; test with expired card on Charge 2
- **Verify:** Decline handled same as other failures; refund triggered

---

## Medium-Risk Test Cases (8 hours)

**13. UI/UX Smoke Test**
- Split amount selector usable and clear
- Real-time fee/total preview if applicable
- Success/failure messages understandable
- **Environment:** Staging; use test cards (no live charges)

**14. Order State Transitions**
- Verify order progresses: pending → processing → charged → fulfilled
- Verify rollback: pending → processing → refunding → unpaid
- Check state visible in admin panel

**15. Notification Flows**
- Customer receives email on success
- Customer receives email on Charge 2 decline (with next steps)
- Admin notified if refund fails

**16. Compliance/Audit**
- PayGate transaction IDs logged and retrievable
- Refund reason recorded ("Charge 2 declined")
- No PII stored locally; PCI-DSS requirements maintained

---

## Regression Test Suite (Automated, Run Before Release)

- Single-card checkout: 50 test cases (mock PayGate)
- Order state machine: 20 cases
- Existing refund flows (non-split): 10 cases
- **Run:** Every commit; full run on 2026-11-10

---

## Testing Timeline

| Week | Dates | Activity | Resources |
|------|-------|----------|-----------|
| **Week 1** | 10/28–11/01 | Developers: code; Tester: setup staging, write test cases | Tester 4 hours |
| **Week 2** | 11/02–11/08 | Sandbox testing (Tue 11/3, Thu 11/5): Tester 8 hours each; Devs fix bugs | Tester 16 hours |
| **Week 3** | 11/09–11/11 | Final regression (Tue 11/10 sandbox); release prep (Wed 11/11) | Tester 8 hours |

**Tester Allocation:** 4 + 16 + 8 = 28 hours (within 50-hour budget; 22 hours buffer for retesting)

---

## Release Readiness Criteria

- [ ] All Critical-Risk cases pass on PayGate sandbox
- [ ] Regression suite passes (single-card checkout 100% pass rate)
- [ ] Refund latency ≤60 seconds (verified on sandbox)
- [ ] No data corruption in test orders
- [ ] Admin audit log complete for all test transactions
- [ ] No merge conflicts with in-flight single-card changes
- [ ] Runbook for manual refund created (failsafe if automation fails)

---

## Known Gaps & Residual Risks

| Gap | Rationale | Mitigation |
|-----|-----------|-----------|
| Network failure during refund | Low likelihood; rare in sandbox | Manual refund runbook; daily refund report audit for first week post-release |
| PayGate sandbox unavailable Wed 11/4 or Mon 11/9 | Testing window compressed | Pre-stage all test scenarios; mock PayGate for non-critical cases |
| Load testing (4,000 orders/day spike) | Out of scope for 1 tester | Staging environment; monitoring dashboards ready; escalation procedure documented |
| International payment methods (multi-currency) | Assume USD only for 5.3 | Defer to 5.4 if scope expands |

---

## Success Metrics (Post-Release)

- Zero PayGate reconciliation errors week-of-release
- Zero customer complaints about duplicate charges
- Refund completion rate ≥99% within 60 seconds
- Single-card checkout: <0.1% regression in success rate
