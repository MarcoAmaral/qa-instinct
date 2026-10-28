```markdown
─────────────────────────────────────────────────────────
DEFECT REPORT
─────────────────────────────────────────────────────────
Defect ID      : DR-SHOP-001
Title          : Checkout – Gift card application fails with 500 error when applying EUR gift card in EUR store
Reported By    : CI/CD Pipeline
Reporter Role  : QA Automation (e2e-staging)
Date Reported  : 2026-10-14
Assigned To    : Backend / Payments Team

─── Classification ──────────────────────────────────────
Severity       : ✅ Critical
Priority       : ✅ P1 (Immediate)
Status         : ✅ New
Type           : ✅ Functional / Integration

─── Environment ─────────────────────────────────────────
Application    : shop v4.12.0-rc.2
Environment    : ✅ Staging
OS / Browser   : Ubuntu 22.04 / Chromium 129.0.6668.29 (Playwright 1.48.1)
Build / Commit : commit 9f3c2ab
Issue          : N/A — link when triaged

─── Context ─────────────────────────────────────────────
Test Case      : checkout.spec.ts > gift card > applies a gift card to an order in EUR
Test Activity  : Automated regression suite execution, CI pipeline e2e-staging #3318
SDLC Phase     : Release candidate testing, pre-release validation (4.12.0-rc.2)
Technique      : End-to-end testing with Playwright, boundary value (multi-currency)
Test Data Used : EUR store; user buyer.eur@shop.example; product "Desk Lamp" EUR 49.00; gift card GC-TEST-0042 (balance EUR 20.00)

─── Reproduction ────────────────────────────────────────
Pre-conditions :

1. Signed in as buyer.eur@shop.example (EUR store user)
2. "Desk Lamp" (EUR 49.00) is in the shopping cart
3. Checkout flow is initiated
4. Gift card GC-TEST-0042 with EUR 20.00 balance is available and valid

Steps to Reproduce :

1. Navigate to checkout
2. In the order summary section, enter gift card code "GC-TEST-0042"
3. Click the "Apply" button
4. Observe the order summary and network response
5. Note: Failure is intermittent; repeat 5–10 times to observe the failure (approximately 30% failure rate)

Expected Result :

Order summary displays:
  - "Gift card: -€20.00"
  - Order total updates to €29.00

Actual Result :

A toast notification displays: "Something went wrong. Please try again."
Order total remains €49.00 (gift card is not applied).
Backend POST /api/checkout/gift-card endpoint returns HTTP 500.
Response body: {"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}

Reproducibility : ✅ Intermittent (3/10 attempts)

─── Evidence ────────────────────────────────────────────
Attachments    : ✅ CI logs (e2e-staging #3318, 2026-10-14 06:12 UTC)
Link/Path      : CI artifact logs; failed attempts: 4, 7, 9

─── Analysis ────────────────────────────────────────────
Defect Location : Backend: POST /api/checkout/gift-card endpoint; currency service integration
Root Cause     : N/A — not yet analysed
Suspicions     : Unconfirmed: Developer suspects currency service cache issue; noted as flaky in prior sprint (team channel communication)

─── Resolution ──────────────────────────────────────────
Fix Applied    : N/A — not yet fixed
Fixed In Build : N/A — not yet fixed
Verified By    : N/A — awaiting fix
Verified On    : N/A — awaiting fix

─── Linked Items ────────────────────────────────────────
Issue / Bug    : N/A — to be filed
Related Defects: N/A — check prior sprint logs for currency service cache incidents
Test Case      : checkout.spec.ts > gift card > applies a gift card to an order in EUR
─────────────────────────────────────────────────────────
```
