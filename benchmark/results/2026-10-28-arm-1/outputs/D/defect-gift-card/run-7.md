─────────────────────────────────────────────────────────
Defect ID      : DR-SHOP-001
Title          : Checkout – Gift card application fails with HTTP 500 when applying valid gift card in EUR store
Reported By    : QA Automation Pipeline
Reporter Role  : QA Automation, CI/CD System
Date Reported  : 2026-10-14
Assigned To    : Backend / Checkout Service Team

─── Classification ──────────────────────────────────────
Severity       : ☑ High
Priority       : ☑ P2 (High)
Status         : ☑ New
Type           : ☑ Functional / Integration

─── Environment ─────────────────────────────────────────
Application    : 4.12.0-rc.2
Environment    : ☑ Staging
OS / Browser   : Ubuntu 22.04 / Chromium 129.0.6668.29, Playwright 1.48.1
Build / Commit : commit 9f3c2ab
Issue          : [SHOP-###] (create in tracker)

─── Context ─────────────────────────────────────────────
Test Case      : TC-CHECKOUT-015 (applies a gift card to an order in EUR)
Test Activity  : Automated e2e regression suite execution
SDLC Phase     : System testing, RC validation (release candidate 4.12.0)
Technique      : Boundary value analysis (multi-currency, gift card balances)
Test Data Used : Test user buyer.eur@shop.example (EUR store), gift card GC-TEST-0042 (EUR 20.00 balance), product "Desk Lamp" (EUR 49.00)

─── Reproduction ────────────────────────────────────────
Pre-conditions :

  1. Test user buyer.eur@shop.example is authenticated and viewing the EUR store
  2. Gift card GC-TEST-0042 with EUR 20.00 balance exists in the staging system
  3. "Desk Lamp" product (EUR 49.00) is available in inventory

Steps to Reproduce :

  1. Add "Desk Lamp" (EUR 49.00) to the shopping cart
  2. Navigate to checkout
  3. Enter gift card code GC-TEST-0042 in the gift card input field
  4. Click the "Apply" button

Expected Result :

Order summary displays the gift card deduction "Gift card: -€20.00" and the order total updates to EUR 29.00 (EUR 49.00 − EUR 20.00).

Actual Result :

A toast notification displays "Something went wrong. Please try again." The gift card is not applied, and the order total remains EUR 49.00. The network request POST /api/checkout/gift-card returns HTTP 500 with error body: `{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}`

Reproducibility : ☑ Intermittent (3/10 attempts)

─── Evidence ────────────────────────────────────────────
Attachments    : ☑ CI log file / Network trace
Link/Path      : CI pipeline e2e-staging #3318, run 2026-10-14 06:12 UTC; failed attempts: 4, 7, 9

─── Analysis ────────────────────────────────────────────
Defect Location: Backend endpoint POST /api/checkout/gift-card; error indicates missing null check on `currency` property during gift card validation or amount calculation
Root Cause     : N/A — not yet analysed
Suspicions     : Unconfirmed: developer suspects the currency service cache is returning incomplete objects or becoming transiently unavailable (team channel); this issue exhibited similar flakiness in the prior sprint

─── Resolution ──────────────────────────────────────────
Fix Applied    : N/A — not yet fixed
Fixed In Build : N/A — not yet fixed
Verified By    : N/A — awaiting fix and retest
Verified On    : N/A — awaiting fix and retest

─── Linked Items ────────────────────────────────────────
Issue / Bug    : [SHOP-###] (to be created in tracker)
Related Defects: N/A — none at this time
Test Case      : TC-CHECKOUT-015
─────────────────────────────────────────────────────────

**Retest Recommendation (once fix is applied):**

1. **Confirmation test**: Repeat steps to apply a valid EUR gift card (GC-TEST-0042) to a EUR store order; verify the order summary correctly deducts the gift card balance and calculates the correct total.
2. **Regression scope**: Run the full checkout gift card suite across all supported currencies (EUR, GBP, USD) and gift card balances (0, partial, full cover) to ensure the fix does not introduce new failures in currency handling.
3. **Flakiness check**: Execute the test 10+ times on the same commit to confirm the intermittent failure is resolved.
