```markdown
─────────────────────────────────────────────────────────
DEFECT REPORT
─────────────────────────────────────────────────────────
Defect ID      : DR-CHECKOUT-001
Title          : Checkout – Gift card application fails with 500 error when applied in EUR currency
Reported By    : QA Automation
Reporter Role  : QA Engineer, CI/E2E pipeline
Date Reported  : 2026-10-14
Assigned To    : Backend / Checkout Team

─── Classification ──────────────────────────────────────
Severity       : ☑ High  □ Critical  □ Medium  □ Low
Priority       : □ P1 (Immediate)  ☑ P2 (High)  □ P3 (Medium)  □ P4 (Low)
Status         : ☑ New  □ Assigned  □ Open  □ Deferred  □ Duplicate  □ Fixed  □ Retest  □ Closed
                 □ Rejected  □ Reopened
Type           : ☑ Functional  □ UI  □ Performance  □ Security  □ Data  ☑ Integration

─── Environment ─────────────────────────────────────────
Application    : Shop v4.12.0-rc.2
Environment    : ☑ Staging  □ Dev  □ Local  □ Production
OS / Browser   : Ubuntu 22.04 / Chromium 129.0.6668.29, Playwright 1.48.1
Build / Commit : commit 9f3c2ab
Issue          : N/A — not yet created in tracker

─── Context ─────────────────────────────────────────────
Test Case      : TC-CHECKOUT-EUR-001 (checkout.spec.ts > gift card)
Test Activity  : E2E regression suite (CI pipeline e2e-staging #3318)
SDLC Phase     : Release candidate testing, build 4.12.0-rc.2
Technique      : Functional testing, EUR store scenario
Test Data Used : Gift card GC-TEST-0042 (EUR 20.00 balance); Desk Lamp (EUR 49.00)

─── Reproduction ────────────────────────────────────────
Pre-conditions :

  1. User signed in as buyer.eur@shop.example (EUR store)
  2. "Desk Lamp" (EUR 49.00) is in the cart

Steps to Reproduce :

  1. Open checkout
  2. Enter gift card code GC-TEST-0042 in the gift card field
  3. Click Apply button

Expected Result :

Order summary is updated to show the gift card deduction:
- Gift card: -€20.00
- Total: €29.00

Actual Result :

Error toast appears: "Something went wrong. Please try again."
Order total remains €49.00 (gift card is not applied).
POST /api/checkout/gift-card returns HTTP 500 with error:
  {"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}

Reproducibility : ☑ Intermittent (3/10 attempts)  □ Always  □ Could Not Reproduce

Failure Attempts : 4, 7, 9 (of 10 repeats); 7 attempts passed on same commit

─── Evidence ────────────────────────────────────────────
Attachments    : ☑ CI Log  ☑ Network Response  □ Screenshot  □ Video  □ HAR file
Link/Path      : CI pipeline e2e-staging #3318, run 2026-10-14 06:12 UTC
                 Error response: {"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}

─── Analysis ────────────────────────────────────────────
Defect Location: POST /api/checkout/gift-card endpoint, currency property handling
Root Cause     : N/A — not yet analysed
Suspicions     : Unconfirmed: Backend developer suspects currency service cache is intermittently failing to load or hydrate the currency object, causing undefined reference on gift card calculation (team channel); similar flakiness observed last sprint

─── Resolution ──────────────────────────────────────────
Fix Applied    : N/A — not yet fixed
Fixed In Build : N/A — not yet fixed
Verified By    : N/A — awaiting retest
Verified On    : N/A — awaiting retest

─── Linked Items ────────────────────────────────────────
Issue / Bug    : N/A — to be created
Related Defects: N/A — none found
Test Case      : TC-CHECKOUT-EUR-001
─────────────────────────────────────────────────────────
```

---

**Retest Criteria (Post-Fix):**
1. Re-run the same scenario 10 times across multiple EUR and non-EUR store accounts
2. Verify the gift card deduction displays correctly and the total is recalculated
3. Confirm POST /api/checkout/gift-card returns 200 with the discounted order details
4. Regression check: Apply multiple gift cards, partial-amount gifts, and edge cases (expired, zero-balance, currency mismatch)
5. Monitor staging environment logs for currency service cache errors
