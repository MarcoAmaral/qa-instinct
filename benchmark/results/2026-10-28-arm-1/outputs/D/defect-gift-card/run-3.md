─────────────────────────────────────────────────────────
DEFECT REPORT
─────────────────────────────────────────────────────────
Defect ID      : DR-CHECKOUT-001
Title          : Checkout – Gift Card – Gift card application fails with 500 error when applying to EUR order
Reported By    : Automated CI Pipeline (e2e-staging)
Reporter Role  : QA Automation / CI System
Date Reported  : 2026-10-14
Assigned To    : Backend / Payment Team

─── Classification ──────────────────────────────────────
Severity       : ☑ High  □ Critical  □ Medium  □ Low
Priority       : ☑ P2 (High)  □ P1 (Immediate)  □ P3 (Medium)  □ P4 (Low)
Status         : ☑ New  □ Assigned  □ Open  □ Deferred  □ Duplicate  □ Fixed  □ Retest  □ Closed
                 □ Rejected  □ Reopened
Type           : ☑ Functional  □ UI  □ Performance  □ Security  □ Data  □ Integration

─── Environment ─────────────────────────────────────────
Application    : Shop v4.12.0-rc.2
Environment    : ☑ Staging  □ Local  □ Dev  □ Production
OS / Browser   : Ubuntu 22.04 / Chromium 129.0.6668.29
Build / Commit : 4.12.0-rc.2 (commit 9f3c2ab)
Issue          : (To be linked to tracker)

─── Context ─────────────────────────────────────────────
Test Case      : checkout.spec.ts › gift card › applies a gift card to an order in EUR
Test Activity  : Automated e2e test execution in CI pipeline (e2e-staging #3318)
SDLC Phase     : System testing, pre-release candidate validation
Technique      : End-to-end test automation (--repeat-each=10)
Test Data Used : EUR store; test user buyer.eur@shop.example; gift card GC-TEST-0042 (EUR 20.00 balance); product "Desk Lamp" (EUR 49.00)

─── Reproduction ────────────────────────────────────────
Pre-conditions :

1. Signed in as test user buyer.eur@shop.example (EUR currency store)
2. "Desk Lamp" (EUR 49.00) added to cart
3. Checkout page opened and gift card input field is visible

Steps to Reproduce :

1. Enter gift card code GC-TEST-0042 in the gift card input field
2. Click "Apply" button

Expected Result :

Order summary displays "Gift card: -€20.00" deduction and order total updates to €29.00

Actual Result :

Toast notification "Something went wrong. Please try again." is displayed. Order total remains unchanged at €49.00. Server responds with HTTP 500 error. Response body: `{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}`

Reproducibility : ☑ Intermittent (3/10 attempts)  □ Always  □ Could Not Reproduce

─── Evidence ────────────────────────────────────────────
Attachments    : ☑ CI log file  ☑ Network trace  □ Screenshot  □ Video  □ None
Link/Path      : CI pipeline e2e-staging #3318, run 2026-10-14 06:12 UTC; POST /api/checkout/gift-card network trace

─── Analysis ────────────────────────────────────────────
Defect Location: Backend endpoint `/api/checkout/gift-card` (POST handler); code attempting to access `.currency` property on an undefined object (likely missing or null currency context in request or currency service response)
Root Cause     : N/A — not yet analysed
Suspicions     : Unconfirmed: backend developer suspects currency service cache issue related to EUR store context; noted in team channel as "flaky last sprint too", suggesting a known intermittent condition with the currency service integration

─── Resolution ──────────────────────────────────────────
Fix Applied    : N/A — not yet fixed
Fixed In Build : N/A — not yet fixed
Verified By    : N/A — not yet fixed
Verified On    : N/A — not yet fixed

─── Linked Items ────────────────────────────────────────
Issue / Bug    : (To be created in tracker)
Related Defects: N/A — none identified; however, note prior intermittent currency service issues last sprint
Test Case      : checkout.spec.ts › gift card › applies a gift card to an order in EUR
─────────────────────────────────────────────────────────
