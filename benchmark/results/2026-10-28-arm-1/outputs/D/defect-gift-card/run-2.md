─────────────────────────────────────────────────────────
DEFECT REPORT
─────────────────────────────────────────────────────────
Defect ID      : DR-SHOP-0847
Title          : Checkout – Gift card application fails with 500 when processing order in EUR store
Reported By    : QA Automation Pipeline
Reporter Role  : QA Automation / CI System
Date Reported  : 2026-10-14
Assigned To    : Development Team

─── Classification ──────────────────────────────────────
Severity       : ✅ High
Priority       : ✅ P1 (Immediate)
Status         : ✅ New
Type           : ✅ Functional / Integration

─── Environment ─────────────────────────────────────────
Application    : shop v4.12.0-rc.2
Environment    : ✅ Staging (https://staging.shop.example)
OS / Browser   : Ubuntu 22.04 / Chromium 129.0.6668.29 (Playwright 1.48.1)
Build / Commit : commit 9f3c2ab
Issue          : N/A — pending triage

─── Context ─────────────────────────────────────────────
Test Case      : checkout.spec.ts — applies a gift card to an order in EUR
Test Activity  : Automated e2e regression run, pre-release certification
SDLC Phase     : System testing, release candidate validation
Technique      : Repeated execution (--repeat-each=10) to detect flaky behavior
Test Data Used : Test user: buyer.eur@shop.example (EUR store); Gift card: GC-TEST-0042 (EUR 20.00 balance); Product: Desk Lamp (EUR 49.00)

─── Reproduction ────────────────────────────────────────
Pre-conditions :
  1. Logged in as buyer.eur@shop.example (EUR currency store)
  2. Cart contains Desk Lamp (EUR 49.00)
  3. Checkout page is open; order summary visible

Steps to Reproduce :
  1. Enter gift card code GC-TEST-0042 in the gift card field
  2. Press Apply button
  3. Observe order summary and API response

Expected Result :
  Order summary updates to show "Gift card: -€20.00" as a line item.
  Order total decreases from €49.00 to €29.00 (49.00 − 20.00).
  Toast notification confirms successful application (implied from passing attempts).

Actual Result :
  A toast notification appears: "Something went wrong. Please try again."
  Order summary does not update; total remains €49.00.
  POST /api/checkout/gift-card responds with HTTP 500.
  Response body: {"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}

Reproducibility : ✅ Intermittent (3/10 attempts; attempts 4, 7, and 9 failed; 7 passed on same build and commit)

─── Evidence ────────────────────────────────────────────
Attachments    : ✅ CI log (network response, error message, retry counts)
Link/Path      : CI run 2026-10-14 06:12 UTC, pipeline e2e-staging #3318

─── Analysis ────────────────────────────────────────────
Defect Location: Backend API endpoint POST /api/checkout/gift-card (error indicates missing null check on `currency` property; likely currency service integration layer)
Root Cause     : N/A — not yet analysed
Suspicions     : Unconfirmed: developer suspects the currency service cache is intermittently returning undefined or missing the `currency` property (team channel); cache flakiness was reported in the prior sprint

─── Resolution ──────────────────────────────────────────
Fix Applied    : N/A — not yet fixed
Fixed In Build : N/A — not yet fixed
Verified By    : N/A — awaiting confirmation testing
Verified On    : N/A — awaiting confirmation testing

─── Linked Items ────────────────────────────────────────
Issue / Bug    : N/A — pending creation in tracker
Related Defects: N/A — none identified; note: currency service cache flakiness noted in prior sprint — check for related incidents
Test Case      : checkout.spec.ts > gift card > applies a gift card to an order in EUR
─────────────────────────────────────────────────────────

**Retest criteria (for QA confirmation once fix is applied):**
1. Re-execute the failing test case 10 times in a row (same --repeat-each=10 configuration) to verify no 500 errors occur.
2. Verify gift card discount is applied correctly and order total is updated to €29.00.
3. Regression check: Run the full checkout suite with multiple currency stores (EUR, USD, GBP) and various gift card scenarios (full balance, partial balance, expired, invalid code).
4. Monitor API response logs for any null or undefined properties in the currency service response.
