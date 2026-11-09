─────────────────────────────────────────────────────────
DEFECT REPORT
─────────────────────────────────────────────────────────
Defect ID      : DR-CHECKOUT-0001
Title          : Checkout – Gift card application fails with 500 error when processing EUR currency
Reported By    : QA (Automated E2E Test)
Reporter Role  : QA Engineer, automation pipeline
Date Reported  : 2026-10-14
Assigned To    : Backend / Payment Team

─── Classification ──────────────────────────────────────
Severity       : ☑ High  □ Critical  □ Medium  □ Low
Priority       : ☑ P2 (High)  □ P1 (Immediate)  □ P3 (Medium)  □ P4 (Low)
Status         : ☑ New  □ Assigned  □ Open  □ Deferred  □ Duplicate  □ Fixed  □ Retest  □ Closed
                 □ Rejected  □ Reopened
Type           : ☑ Functional  ☑ Integration  □ UI  □ Performance  □ Security  □ Data

─── Environment ─────────────────────────────────────────
Application    : v4.12.0-rc.2
Environment    : ☑ Staging  □ Local  □ Dev  □ Production
OS / Browser   : Ubuntu 22.04 / Chromium 129.0.6668.29, Playwright 1.48.1
Build / Commit : commit 9f3c2ab
Issue          : N/A — not yet linked

─── Context ─────────────────────────────────────────────
Test Case      : N/A — checkout.spec.ts > gift card > applies a gift card to an order in EUR
Test Activity  : E2E release candidate regression run (--repeat-each=10)
SDLC Phase     : Release candidate testing, pre-release validation
Technique      : End-to-end test (automated checkout flow)
Test Data Used : Test user: buyer.eur@shop.example; Gift card: GC-TEST-0042 (EUR 20.00 balance); Product: Desk Lamp (EUR 49.00)

─── Reproduction ────────────────────────────────────────
Pre-conditions :
  1. User is signed in as buyer.eur@shop.example (EUR store)
  2. Desk Lamp (EUR 49.00) is in the cart
  3. Checkout page is open with order summary visible
  4. Gift card GC-TEST-0042 (EUR 20.00 balance) is available

Steps to Reproduce :
  1. Open checkout with EUR product in cart
  2. Scroll to gift card section
  3. Enter gift card code GC-TEST-0042
  4. Click Apply button
  5. Observe order summary update (should apply discount)

Expected Result :
Gift card discount is applied to the order. Order summary displays "Gift card: -€20.00" and total updates from €49.00 to €29.00.

Actual Result :
Toast notification appears with message "Something went wrong. Please try again." Gift card is not applied. Order total remains €49.00. Server logs show POST /api/checkout/gift-card returns HTTP 500 with error body: {"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}

Reproducibility : ☑ Intermittent (3/10 attempts)  □ Always  □ Could Not Reproduce
                  Failed attempts: 4, 7, 9 (same error each time; 7 attempts succeeded)

─── Evidence ────────────────────────────────────────────
Attachments    : ☑ CI Log  □ Screenshot  □ Video  □ HAR file  □ None
Link/Path      : CI run e2e-staging #3318 (2026-10-14 06:12 UTC); Network error: POST /api/checkout/gift-card -> 500 {"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}

─── Analysis ────────────────────────────────────────────
Defect Location: Gift card API endpoint (POST /api/checkout/gift-card) or currency service integration; error indicates missing/undefined currency property during EUR order processing
Root Cause     : N/A — not yet analysed
Suspicions     : Unconfirmed: Developer suspects intermittent currency service cache issue (team channel note: "probably the currency service cache again, it was flaky last sprint too"). Hypothesis: currency data for EUR may be missing or stale in cache on certain requests.

─── Resolution ──────────────────────────────────────────
Fix Applied    : N/A — not yet fixed
Fixed In Build : N/A — not yet fixed
Verified By    : N/A — awaiting fix
Verified On    : N/A — awaiting fix

─── Linked Items ────────────────────────────────────────
Issue / Bug    : N/A — not yet created
Related Defects: N/A — none identified
─────────────────────────────────────────────────────────

**Retest Criteria (once fix is applied):**
1. Rerun checkout.spec.ts with --repeat-each=10 on staging to verify no intermittent failures
2. Verify gift card applies correctly for all supported currencies (EUR, USD, GBP minimum)
3. Regression check: verify gift card caching does not affect subsequent orders with different currencies
4. Monitor POST /api/checkout/gift-card response times and cache hit rates during retest
