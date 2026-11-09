─────────────────────────────────────────────────────────
DEFECT REPORT
─────────────────────────────────────────────────────────
Defect ID      : DR-CHECKOUT-001
Title          : Checkout – Gift card fails to apply with 500 error when currency data is missing
Reported By    : QA Automation (CI pipeline)
Reporter Role  : QA Engineer, Automation Team
Date Reported  : 2026-10-14
Assigned To    : Backend Team / Gift Card Service

─── Classification ──────────────────────────────────────
Severity       : ☑ High
Priority       : ☑ P1 (Immediate)
Status         : ☑ New
Type           : ☑ Functional / Integration

─── Environment ─────────────────────────────────────────
Application    : Shop Platform v4.12.0-rc.2
Environment    : ☑ Staging
OS / Browser   : Ubuntu 22.04 / Chromium 129.0.6668.29, Playwright 1.48.1
Build / Commit : commit 9f3c2ab
Issue          : CHECKOUT-TBD

─── Context ─────────────────────────────────────────────
Test Case      : checkout.spec.ts – gift card – applies a gift card to an order in EUR
Test Activity  : Automated end-to-end regression suite (--repeat-each=10)
SDLC Phase     : System testing, RC candidate build
Technique      : Functional testing, currency-specific validation
Test Data Used : Test user: buyer.eur@shop.example (EUR store); Product: Desk Lamp EUR 49.00; Test gift card: GC-TEST-0042 (balance EUR 20.00)

─── Reproduction ────────────────────────────────────────
Pre-conditions :
  1. Staging environment accessible at https://staging.shop.example
  2. Test user buyer.eur@shop.example registered with EUR store access
  3. Test gift card GC-TEST-0042 exists with EUR 20.00 balance
  4. Desk Lamp product available for EUR 49.00

Steps to Reproduce :
  1. Sign in as buyer.eur@shop.example
  2. Add Desk Lamp (EUR 49.00) to cart
  3. Open checkout
  4. Enter gift card code GC-TEST-0042
  5. Press "Apply"

Expected Result :
Gift card is successfully applied. Order summary displays:
  - "Gift card: -€20.00"
  - Order total: €29.00

Actual Result :
Toast notification displays: "Something went wrong. Please try again."
Order total remains €49.00; gift card not applied.
POST /api/checkout/gift-card endpoint returns HTTP 500 with error:
  `{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}`

Reproducibility : ☑ Intermittent (3/10 attempts)

─── Evidence ────────────────────────────────────────────
Attachments    : ☑ CI log output and network trace
Link/Path      : CI pipeline e2e-staging #3318, run 2026-10-14 06:12 UTC

─── Analysis ────────────────────────────────────────────
Defect Location: Backend — POST /api/checkout/gift-card endpoint; error originates in code attempting to access `currency` property on undefined object
Root Cause     : N/A — not yet analysed
Suspicions     : Unconfirmed: developer suspects currency service cache is flaky; similar intermittent failures reported in previous sprint (team channel)

─── Resolution ──────────────────────────────────────────
Fix Applied    : N/A — not yet fixed
Fixed In Build : N/A — not yet fixed
Verified By    : N/A — not yet fixed
Verified On    : N/A — not yet fixed

─── Linked Items ────────────────────────────────────────
Issue / Bug    : CHECKOUT-TBD
Related Defects: N/A — check sprint backlog for prior currency cache incidents
Test Case      : checkout.spec.ts
─────────────────────────────────────────────────────────
