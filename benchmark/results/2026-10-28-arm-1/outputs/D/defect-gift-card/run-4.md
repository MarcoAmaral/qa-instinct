```markdown
─────────────────────────────────────────────────────────
DEFECT REPORT
─────────────────────────────────────────────────────────
Defect ID      : DR-SHOP-001
Title          : Checkout – Gift card not applied when applying EUR gift card; API returns 500 with "Cannot read properties of undefined (reading 'currency')"
Reported By    : CI Pipeline (Automated E2E Test)
Reporter Role  : QA Automation System
Date Reported  : 2026-10-14
Assigned To    : Backend / Currency Service Team

─── Classification ──────────────────────────────────────
Severity       : ☑ High
Priority       : ☑ P1 (Immediate)
Status         : ☑ New
Type           : ☑ Functional  ☑ Integration

─── Environment ─────────────────────────────────────────
Application    : Shop v4.12.0-rc.2
Environment    : ☑ Staging
OS / Browser   : Ubuntu 22.04 / Chromium 129.0.6668.29
Build / Commit : 4.12.0-rc.2 (commit 9f3c2ab)
Issue          : N/A — not yet filed to tracker

─── Context ─────────────────────────────────────────────
Test Case      : checkout.spec.ts > gift card > applies a gift card to an order in EUR
Test Activity  : Automated E2E test execution, CI pre-release validation (--repeat-each=10)
SDLC Phase     : System testing, release candidate validation
Technique      : Boundary value analysis (multiple currency stores), flakiness detection (repeat-each)
Test Data Used : Gift card GC-TEST-0042 (balance EUR 20.00); user buyer.eur@shop.example (EUR store); product "Desk Lamp" (EUR 49.00)

─── Reproduction ────────────────────────────────────────
Pre-conditions :
  1. Signed in as buyer.eur@shop.example (EUR store account)
  2. "Desk Lamp" (EUR 49.00) added to cart
  3. Checkout page opened

Steps to Reproduce :
  1. Enter gift card code GC-TEST-0042 in the gift card field
  2. Press "Apply" button
  3. Observe order summary

Expected Result :
The order summary displays "Gift card: -€20.00" and the total is recalculated to €29.00 (EUR 49.00 − EUR 20.00). No error is shown.

Actual Result :
A toast notification displays "Something went wrong. Please try again." The gift card is not applied, and the order total remains EUR 49.00. The backend API responds with HTTP 500 and error: `{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}`

Reproducibility : ☑ Intermittent (3 failures out of 10 attempts; 30% failure rate)
   Attempts 4, 7, and 9 failed; attempts 1–3, 5–6, 8, 10 passed.

─── Evidence ────────────────────────────────────────────
Attachments    : ☑ Network Log
Link/Path      : CI log 2026-10-14 06:12 UTC, pipeline e2e-staging #3318

   Network capture (POST /api/checkout/gift-card):
   Status: 500 Internal Server Error
   Response body:
   {
     "error": "TypeError: Cannot read properties of undefined (reading 'currency')"
   }

─── Analysis ────────────────────────────────────────────
Defect Location: Backend API endpoint POST /api/checkout/gift-card; currency object is undefined when reading the 'currency' property (likely in currency service or cache initialization)
Root Cause     : N/A — not yet analysed
Suspicions     : Unconfirmed: Developer suspects currency service cache initialization issue (team channel); observed as flaky in prior sprint. Cache may not have been warmed or may have expired between requests, causing the undefined currency property on gift card apply.

─── Resolution ──────────────────────────────────────────
Fix Applied    : N/A — not yet fixed
Fixed In Build : N/A — not yet fixed
Verified By    : N/A — not yet fixed
Verified On    : N/A — not yet fixed

─── Linked Items ────────────────────────────────────────
Issue / Bug    : N/A — not yet filed
Related Defects: N/A — none identified
Test Case      : checkout.spec.ts > gift card > applies a gift card to an order in EUR
─────────────────────────────────────────────────────────
```

**Retest criteria (once fix is applied):**
1. Re-run the same test case (applies a gift card to an order in EUR) 10 times (--repeat-each=10) and confirm all 10 attempts pass.
2. Test gift card application across all currency stores (EUR, USD, GBP, etc.) to verify the fix is not currency-specific.
3. Regression check: Verify the gift card apply flow for USD and GBP stores, and confirm order totals recalculate correctly.
4. Verify POST /api/checkout/gift-card returns HTTP 200 with correct response body (gift card discount and new total).
