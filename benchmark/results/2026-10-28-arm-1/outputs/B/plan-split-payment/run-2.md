# Split Payment Test Plan (Release 5.3)

## Executive Summary

This test plan prioritizes payment correctness, refund reliability, and regression prevention for the split payment feature given severe time and resource constraints (1 part-time tester, 10 working days, PayGate sandbox availability limited to Tuesdays/Thursdays). Focus is placed on high-risk scenarios that could cause revenue loss, customer dissatisfaction, or data integrity issues.

## Test Strategy

**Risk-Based Approach:** Testing prioritizes scenarios with the highest impact and probability of failure, given the complexity of payment logic and external gateway dependency.

**Key Constraint:** PayGate sandbox access is limited to Tuesday/Thursday windows (4 days within the 10-day window). All end-to-end integration tests requiring PayGate must be scheduled for these dates.

**Regression Priority:** The existing single-card checkout (4,000 orders/day) must remain fully functional; regression testing receives equal priority to new feature testing.

## Scope

**In Scope:**
- Split payment order flow (amount entry, validation, dual-charge logic)
- PayGate integration for both card charges
- Automatic refund on second charge decline
- Rounding logic (remainder cent placement)
- Refund timing (60-second SLA)
- Single-card checkout regression
- Payment state persistence (cart abandonment/return scenarios)
- Error handling and user-facing messaging

**Out of Scope:**
- PayGate internal processing logic (testing their sandbox responses only)
- UI/UX refinement beyond functional correctness
- Performance under production load
- Accessibility compliance (defer to post-release audit)
- Internationalization/multi-currency scenarios (assume single currency in scope)
- Recurring/subscription billing with split payments

## Risk Assessment & Test Prioritization

| Risk | Impact | Probability | Priority | Test Coverage |
|------|--------|-------------|----------|---|
| Second charge declined, first charge not refunded | Critical revenue loss + customer churn | Medium (payment failures ~2-5% industry baseline) | **Critical** | 15+ scenarios |
| Refund fails to process within 60 seconds | Regulatory/compliance violation, customer disputes | Medium (timing issues common in integration) | **Critical** | Automated monitoring + manual spot checks |
| Rounding error (remainder cent misplaced) | Financial liability, audit findings, customer complaints | Low (logic simple) but high impact | **Critical** | Unit + integration tests |
| First charge succeeds, second charge not attempted | Customer confusion, support load | Low (UI/flow issue unlikely) | **High** | 5+ scenarios |
| Single-card checkout breaks | 4,000 orders/day affected | Low (isolated feature) but catastrophic impact | **Critical** | Full regression suite |
| PayGate integration failure (wrong auth, bad request formatting) | Feature non-functional | Medium | **High** | 8+ scenarios |
| Split amount input validation fails (negative, decimal, over-balance) | Bad data enters system or UX confusion | Medium | **High** | 12+ scenarios |
| Payment state corruption (charged but order not created, or vice versa) | Revenue recognition issues, order/inventory mismatch | Low but high impact | **High** | 6+ scenarios |
| Concurrent split payment requests on same session | Data corruption, double-charging | Low (unlikely timing) but critical impact | **Medium** | 3-4 scenarios |
| User sees incorrect amount charged/refunded on receipt | Customer support burden, chargeback risk | Low (reporting only) | **Medium** | 4+ scenarios |

## Test Cases by Priority

### CRITICAL - High Risk, High Impact

#### CR-1: Second Charge Declined → First Charge Refunded (60 Seconds)
- **Setup:** Card 1 valid, Card 2 configured to decline in PayGate sandbox
- **Steps:** 
  1. Initiate split payment ($100 / $50 each)
  2. First charge succeeds
  3. Second charge submitted to PayGate, returns decline response
  4. Monitor refund queue
- **Expected:** First charge refunded within 60 seconds; customer sees "Payment declined - first charge refunded" message; order status = cancelled; cart remains valid for retry
- **Data Validation:** Verify refund record in database, PayGate refund request log, customer transaction history
- **Variations:** Test with different decline reasons (insufficient funds, expired, fraud block, etc.)
- **Environment:** PayGate sandbox (Tue/Thu only)

#### CR-2: Rounding - Remainder Cent on First Card
- **Setup:** Test amounts that don't divide evenly by 2
- **Test Cases:**
  - $100.01 → First card $50.01, second card $50.00
  - $1.00 → First card $0.51, second card $0.49
  - $0.03 → First card $0.02, second card $0.01
  - Large amount with odd cent: $9999.99 → $5000.00, $4999.99
- **Expected:** Charges match expected split exactly; no cent lost or duplicated
- **Data Validation:** Query orders table; verify sum of both charges equals total; audit logs
- **Test Method:** Automated (unit + integration tests)

#### CR-3: Single-Card Checkout Still Works (Regression)
- **Setup:** Use existing single-card checkout path
- **Test Cases:**
  - Standard $100 order, valid card → charges successfully
  - Order with existing promo codes → correct total
  - Abandoned cart / return to checkout → cart preserved, payment processes
  - Declined card → error message, no partial charge
- **Expected:** Behavior identical to pre-release; no behavioral change
- **Data Validation:** Compare transaction logs to baseline; verify no double-charges
- **Environment:** Live or staging (no PayGate dependency required)
- **Regression Scope:** Run full single-card suite (existing test cases)

#### CR-4: Both Charges Succeed - Order Created
- **Setup:** Both cards valid in PayGate sandbox
- **Steps:**
  1. Enter split: $60 on Card 1, $40 on Card 2
  2. Submit payment
  3. Both charges processed in PayGate
- **Expected:** Order created once; both transactions recorded; customer receives order confirmation; receipt shows split details
- **Data Validation:** Verify order ID, payment table has 2 rows, no duplicate orders, inventory decremented once
- **Environment:** PayGate sandbox (Tue/Thu only)

#### CR-5: First Charge Fails - No Second Charge Attempted
- **Setup:** Card 1 configured to decline in PayGate sandbox, Card 2 valid
- **Steps:**
  1. Initiate split payment
  2. First charge submitted, returns decline
- **Expected:** Transaction stops; second card never charged; customer sees decline message; order not created; can retry with different card
- **Data Validation:** Verify only 1 failed transaction in logs, no 2nd transaction attempt
- **Environment:** PayGate sandbox (Tue/Thu only)

### HIGH - Medium-High Risk

#### H-1: Split Amount Input Validation
- **Test Cases:**
  - Valid: $50 on $100 order (leaves $50 for 2nd) ✓
  - Invalid: $0 on first card (must be > $0 if splitting)
  - Invalid: $100.01 on $100 order (exceeds order total)
  - Invalid: Negative amount entered
  - Invalid: Decimal to more than 2 places (e.g., $50.999)
  - Invalid: Non-numeric input
  - Edge: $0.01 on $0.02 order (leaves $0.01 for 2nd card) ✓
- **Expected:** Valid amounts accepted; invalid amounts rejected with specific error message (e.g., "Amount must be between $0.01 and $[max]"); user can correct and resubmit
- **Test Method:** Manual UI testing + automated input boundary testing

#### H-2: PayGate Integration Error Handling
- **Test Cases:**
  - PayGate timeout (1st or 2nd charge)
  - PayGate returns malformed response
  - Network error mid-payment
  - PayGate auth failure (bad API key scenario)
  - PayGate rate-limit hit
- **Expected:** User sees "Payment processing error. Please try again." or similar; no partial charges; order not created; retry is possible
- **Test Method:** Manual testing with sandbox error injection (or mock PayGate responses)

#### H-3: Refund Timing and Reliability
- **Setup:** Simulate second charge decline; monitor refund processing
- **Test Cases:**
  - Measure refund completion time (should be < 60 seconds)
  - Verify refund appears in customer's bank account (mock or staging bank)
  - Refund processes if second charge declines at different times (immediately vs. after 30-second delay in response)
  - Verify idempotency: if refund is triggered twice, only one refund processes
- **Expected:** All refunds within 60-second SLA; no double-refunds
- **Data Validation:** Refund timestamps, idempotency keys in logs
- **Test Method:** Automated monitoring + manual spot checks

#### H-4: Payment State Consistency
- **Test Cases:**
  - Browser refresh mid-payment (1st charge processed, 2nd pending)
  - Network disconnection after 1st charge succeeds
  - User navigates away and returns to payment page
  - Payment completes while customer has page in background
- **Expected:** Resume payment without re-charging first card; system correctly identifies payment state and either completes 2nd charge or refunds 1st charge (if 2nd declined)
- **Test Method:** Manual testing with network throttling/interruption simulation

### MEDIUM - Lower Risk but Important

#### M-1: Concurrent Payment Requests
- **Setup:** Same customer session, rapid split payment submissions
- **Test Cases:**
  - User clicks submit twice within 1 second
  - Two separate devices, same customer account, simultaneous split payments
- **Expected:** Only one payment processes; second request fails gracefully with "Payment already in progress" message
- **Test Method:** Manual stress testing or automated concurrency testing (if tooling available)

#### M-2: Receipt and Order History Accuracy
- **Setup:** Complete a split payment order
- **Test Cases:**
  - Receipt shows both card charges separately
  - Order history UI lists split payment correctly
  - Customer support dashboard shows correct split breakdown
  - Invoice generation includes both charges
- **Expected:** All displays match actual charges; no confusion or missing data
- **Test Method:** Manual verification + screenshot comparison

#### M-3: Edge Cases - Refund Partial Failures
- **Setup:** First refund fails, but system retries
- **Test Cases:**
  - PayGate refund endpoint temporarily unavailable (returns 503)
  - Refund request succeeds but confirmation is lost (re-attempt refund)
- **Expected:** Retry logic triggers; eventually refunds successfully; no customer charged twice
- **Test Method:** PayGate sandbox error injection

### LOW - Lower Risk

#### L-1: UI Copy and Messaging
- **Test Cases:**
  - Error messages are clear and actionable
  - Split amount display shows correct dollar and cent values
  - Confirmation page summarizes both charges
- **Expected:** No confusion; professional tone; culturally appropriate
- **Test Method:** Manual review (can be rapid)

#### L-2: Browser Compatibility
- **Test Cases:**
  - Chrome, Firefox, Safari (latest versions)
  - Mobile browser (iOS Safari, Chrome mobile)
- **Expected:** Payment flow works without layout breaks
- **Test Method:** Quick smoke testing on 2-3 browsers

## Testing Timeline & Resource Allocation

**Total Available Hours:** 1 part-time tester × 10 working days × 4 hours/day ≈ 40 hours
**Overhead (planning, reporting, debugging):** ~8 hours
**Actual Testing Hours:** ~32 hours

**PayGate Sandbox Availability:** Tuesdays and Thursdays (Days 2, 3, 5, 9 of the 10-day window)

### Week 1 (Days 1-5)
- **Day 1 (Mon):** Test planning, environment setup, manual test case development (4 hours)
- **Day 2 (Tue):** PayGate sandbox available
  - Critical refund scenarios (CR-1): 3 hours
  - Both charges success (CR-4): 2 hours
- **Day 3 (Wed):** Single-card checkout regression (CR-3): 4 hours (no sandbox needed)
- **Day 4 (Thu):** PayGate sandbox available
  - First charge fail (CR-5): 2 hours
  - Input validation (H-1): 2 hours
- **Day 5 (Fri):** Rounding logic verification (CR-2, automated): 2 hours; quick smoke tests: 1 hour

### Week 2 (Days 6-10)
- **Day 6 (Mon):** PayGate error handling (H-2): 3 hours; refund timing spot-checks (H-3): 1 hour
- **Day 7 (Tue):** PayGate sandbox available
  - Payment state consistency edge cases (H-4): 2 hours
  - Concurrent requests (M-1): 1 hour
- **Day 8 (Wed):** Receipt accuracy (M-2): 2 hours; browser compatibility (L-2): 1 hour
- **Day 9 (Thu):** PayGate sandbox available
  - Final integration smoke tests + edge cases: 3 hours
- **Day 10 (Fri):** Regression verification, bug triage, test report: 4 hours

## Test Environment Requirements

- **Staging Environment:** Full replica of production (payment flow, but not real money)
- **PayGate Sandbox Account:** Credentials configured; test card numbers provided
- **Test Cards Provided By PayGate:**
  - Valid card (success)
  - Decline on all charges
  - Decline on subsequent charges
  - Timeout/slow response card
- **Database Access:** Ability to query orders, payments, refunds tables; reset test data between runs
- **Logging:** Full payment request/response logs available for debugging
- **Monitoring:** Real-time refund processing status dashboard (or query method)

## Pass/Fail Criteria

### Must Pass (Blockers to Release)
1. All CR-1 scenarios: Refunds process within 60 seconds with 100% success rate in 10 test runs
2. All CR-2 scenarios: Rounding is correct in all test cases (automated test passes)
3. All CR-3 scenarios: Single-card checkout shows no regressions in baseline test suite
4. CR-4: Both charges succeed, order created exactly once, in 10 test runs
5. CR-5: First charge failure prevents second charge attempt, in 5 test runs

### Should Pass (High Priority, release conditional on fix)
- H-1: All input validation errors caught and reported correctly
- H-2: PayGate integration errors handled gracefully (no partial charges)
- H-3: Refund timing verified in at least 3 test runs (< 60 seconds)

### Nice to Pass (Post-Release OK)
- M-1, M-2, L-1, L-2: If time allows; otherwise defer to post-release regression or customer feedback

## Assumptions

1. **Single Currency:** Feature operates in USD only (no multi-currency logic required).
2. **Payment Gateway API:** PayGate SDK/API is stable and documented; test cards are available.
3. **Database Schema:** Split payment data model is finalized and accessible for queries.
4. **Refund Automation:** Backend refund logic is implemented and available for testing (not manual refund process).
5. **Development Complete:** Feature code is stable and available for testing by Day 2 of the 10-day window.
6. **Cart Integrity:** Existing cart/order creation logic does not conflict with split payment; no changes to single-card flow required beyond feature flag.
7. **Customer Communication:** Customer-facing error messages are provided by development team; tester verifies display only.
8. **Sandbox Limitations:** PayGate sandbox behaves identically to production for payment/refund logic (no data inconsistencies); tester does not validate PayGate's internal reconciliation.
9. **Regulatory Compliance:** Legal/compliance sign-off on refund SLA (60 seconds) is obtained before testing; tester does not validate compliance applicability.
10. **Post-Release Monitoring:** Production monitoring and support escalation procedures are in place (testing does not include live production validation).

## Test Deliverables

- Test case repository (documented in test management tool or spreadsheet)
- Execution report (pass/fail by category, blockers identified)
- Defect log (with severity, steps to reproduce, environment)
- Regression test baseline (single-card checkout pre/post comparison)
- PayGate integration test credentials and setup guide (for future regression)

---

**Plan Owner:** QA  
**Approval Date:** [Day 1 of release window]  
**Review Date:** [Day 5 — mid-window checkpoint; adjust plan if blockers found]
