I notice you've invoked the help-articles skill, but you're asking for a risk-based test plan—an internal QA document, not a help-center article. I'll write the test plan directly as Markdown instead.

---

# Risk-Based Test Plan: Split Payment (Release 5.3)

**Release Date:** 2026-11-11 (10 working days from 2026-10-28)  
**Test Resources:** 1 half-time tester + 2 developers  
**Assumption:** Testing will occur Tuesday 2026-11-05 and Thursday 2026-11-07 (PayGate sandbox availability); production testing begins Friday 2026-11-08 using staging environment.

## Risk Summary

| Risk | Impact | Likelihood | Priority |
|------|--------|-----------|----------|
| Refund fails; customer charged twice | Financial loss + churn | Medium | **Critical** |
| Remainder cent logic fails (e.g., $10.01 split incorrectly) | Billing errors, support escalation | Medium | **Critical** |
| Second card decline not detected; charge hangs | Customer confusion, payment stuck | Medium | **Critical** |
| Existing single-card flow breaks | 4,000 orders/day affected | Medium | **Critical** |
| PayGate integration timeout | Checkout fails silently | Medium | **High** |
| Split payment UI not intuitive | Wrong amounts entered | Medium | **High** |

## Test Scope

### In Scope (Risk-Based Priority)

1. **Refund Logic (Critical)**
   - Second charge declined → first charge refunds within 60 seconds
   - Verify refund status in PayGate sandbox logs
   - Verify customer receives refund notification
   - Verify no duplicate refunds if refund is triggered twice
   - Test with various first-charge amounts ($5, $50, $500)

2. **Split Amount Calculation (Critical)**
   - Remainder cent goes to first card: $10.01 split 50/50 → first $5.01, second $5.00
   - Edge cases: $0.01, $0.99, $1.00, $999.99
   - Verify amounts match PayGate transaction records

3. **Both Charges Succeed (Critical)**
   - Two separate charges appear in PayGate logs
   - Customer receives two receipts or one combined receipt
   - Order marked "paid" only after both charges clear

4. **Regression: Existing Single-Card Checkout (Critical)**
   - Single-card payment still works (smoke test: 5 transactions)
   - No performance degradation
   - Existing order history unaffected

5. **Second Charge Failure Scenarios (High)**
   - Insufficient funds
   - Card expired
   - CVV mismatch
   - PayGate timeout on second charge

6. **UI/UX (High)**
   - Split amount input validation (no negative, no exceeding total)
   - Error messages clear when either charge fails
   - Progress indicator shows both charges pending

### Out of Scope

- First charge failure (covered by existing checkout tests)
- PayGate API changes or new features
- Refund timing beyond 60-second requirement
- Promotional codes or discounts applied to splits

## Test Environment & Timeline

| Date | Day | Activity | Constraint |
|------|-----|----------|-----------|
| Tue 2026-11-05 | Unit + sandbox refund logic | PayGate sandbox open | 1 tester + devs |
| Thu 2026-11-07 | Sandbox integration tests (both charges, splits, edge cases) | PayGate sandbox open | 1 tester + devs |
| Fri 2026-11-08–Mon 2026-11-11 | Staging: regression (single-card), smoke (split), UI/UX | Staging available | 1 tester (half-time) |

## Test Cases (Risk-Ordered)

### P0: Refund on Second Decline
- **Setup:** Test account, PayGate sandbox
- **Action:** Initiate split payment; second card has insufficient funds
- **Expected:** First charge succeeds → second declines → first charge refunds within 60s
- **Verify:** PayGate refund transaction exists; customer's account reflects refund

### P0: Remainder Cent Assignment
- **Setup:** Test amounts: $1.01, $10.99, $100.00
- **Action:** Split each 50/50
- **Expected:** $1.01 → $0.51 + $0.50; $10.99 → $5.50 + $5.49; $100.00 → $50.00 + $50.00
- **Verify:** Exact amounts in PayGate logs match

### P0: Both Charges Succeed
- **Setup:** Two valid test cards (PayGate sandbox)
- **Action:** Split $50 → $30 card A, $20 card B
- **Expected:** Both charges succeed; order moves to "fulfillment"
- **Verify:** Two transactions in PayGate; customer receives email confirmation

### P0: Single-Card Checkout Unbroken
- **Setup:** Existing checkout flow
- **Action:** Complete 5 single-card orders (various amounts)
- **Expected:** All succeed as before
- **Verify:** No latency increase; orders appear in admin dashboard

### P1: Refund Idempotency
- **Setup:** Trigger refund via UI twice rapidly
- **Expected:** Only one refund processed
- **Verify:** PayGate logs show one refund transaction, not duplicates

### P1: UI Input Validation
- **Setup:** Split payment form
- **Action:** Enter invalid amounts (-$5, $150 when total is $100, non-numeric)
- **Expected:** Error messages; form does not submit
- **Verify:** Error text matches product tone

### P1: PayGate Timeout on Second Charge
- **Setup:** PayGate sandbox, simulate latency
- **Action:** Initiate split payment; second charge times out
- **Expected:** User sees "payment pending" or "retry" option (per product design)
- **Verify:** First charge not double-refunded if retry succeeds

### P2: Various Decline Codes
- **Setup:** PayGate sandbox test cards for declined, expired, CVV fail
- **Action:** Use each as second card in split
- **Expected:** Appropriate error for each; first charge refunds
- **Verify:** Error messages map correctly to decline reasons

## Assumptions

1. **Refund API:** PayGate supports refunds via REST API within 60 seconds of charge.
2. **UI Design:** Split amount input is a text field or number input (not assumed complex UX).
3. **Notification:** Customers receive at least one confirmation (email or in-app) per charge.
4. **Release Criteria:** Must pass P0 and P1 test cases; P2 can defer to patch if time-boxed.
5. **Staging Environment:** Staging database and PayGate sandbox account available from 2026-11-05.

## Sign-Off

- **Tester:** Confirms P0 and P1 tests pass before Friday EOD.
- **Dev Lead:** Verifies PayGate refund callback integration and error handling.
- **Product:** Approves error messages and UI copy before UAT.
