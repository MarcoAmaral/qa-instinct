─────────────────────────────────────────────────────────
DEFECT REPORT
─────────────────────────────────────────────────────────
Defect ID      : DR-SHOP-001
Title          : Checkout – Gift card application fails with 500 error when applying a gift card to a EUR order
Reported By    : QA CI Pipeline
Reporter Role  : QA Automation Engineer, CI/CD
Date Reported  : 2026-10-14
Assigned To    : Development Team (Checkout Service)

─── Classification ──────────────────────────────────────
Severity       : ✅ Critical
Priority       : ✅ P1 (Immediate)
Status         : ✅ New
Type           : ✅ Functional / Integration

─── Environment ─────────────────────────────────────────
Application    : Shop v4.12.0-rc.2
Environment    : ✅ Staging
OS / Browser   : Ubuntu 22.04 / Chromium 129.0.6668.29
Build / Commit : 4.12.0-rc.2 (commit 9f3c2ab), Playwright 1.48.1
Issue          : TBD (awaiting triage)

─── Context ─────────────────────────────────────────────
Test Case      : checkout.spec.ts > gift card > applies a gift card to an order in EUR
Test Activity  : CI e2e regression test execution (pipeline e2e-staging #3318)
SDLC Phase     : Pre-release testing, staging environment
Technique      : End-to-end functional testing with automated Playwright (--repeat-each=10)
Test Data Used : EUR store (buyer.eur@shop.example), product "Desk Lamp" (€49.00), gift card GC-TEST-0042 (€20.00 balance)

─── Reproduction ────────────────────────────────────────
Pre-conditions :
  1. User is logged in as buyer.eur@shop.example (EUR store)
  2. Cart contains "Desk Lamp" (EUR 49.00)
  3. Checkout page is open

Steps to Reproduce :
  1. From checkout page, locate the gift card input field
  2. Enter gift card code "GC-TEST-0042"
  3. Click "Apply"

Expected Result :
Order summary displays "Gift card: -€20.00". Order total updates to €29.00. No error message.

Actual Result :
Toast notification displays: "Something went wrong. Please try again."
Order summary unchanged. Order total remains €49.00.
POST /api/checkout/gift-card returns HTTP 500.
Response body: `{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}`

Reproducibility : ✅ Intermittent (3 failed, 7 passed out of 10 attempts on same commit; failures in attempts 4, 7, 9)

─── Evidence ────────────────────────────────────────────
Attachments    : ✅ Network response log
Link/Path      : CI pipeline e2e-staging #3318, 2026-10-14 06:12:00 UTC run log

─── Analysis ────────────────────────────────────────────
Defect Location: API endpoint `/api/checkout/gift-card` (server-side error in currency property access)
Root Cause     : N/A — not yet analysed
Suspicions     : Unconfirmed: Developer suspects the currency service cache is not properly initialized or returning undefined; noted as "probably the currency service cache again, it was flaky last sprint too" (team channel)

─── Resolution ──────────────────────────────────────────
Fix Applied    : N/A — not yet fixed
Fixed In Build : N/A — not yet fixed
Verified By    : N/A — pending fix
Verified On    : N/A — pending fix

─── Linked Items ────────────────────────────────────────
Issue / Bug     : TBD (awaiting triage)
Related Defects : TBD (check if prior cache-related defects exist from last sprint)
Test Case      : checkout.spec.ts > gift card > applies a gift card to an order in EUR
─────────────────────────────────────────────────────────

**Retest Criteria (once fix is applied):**
1. Re-run the failing test case 10 times with --repeat-each=10 to confirm 100% pass rate
2. Verify gift card application in EUR, USD, and GBP stores
3. Regression check: verify checkout flow for non-gift-card orders (normal order total calculation)
4. Verify currency service initialization and cache behavior under load
