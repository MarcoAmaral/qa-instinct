─────────────────────────────────────────────────────────
DEFECT REPORT
─────────────────────────────────────────────────────────
Defect ID      : DR-SHOP-001
Title          : Checkout – Gift card application fails with 500 error when currency service cache is stale
Reported By    : QA Automation
Reporter Role  : QA Engineer, automation test execution
Date Reported  : 2026-10-14
Assigned To    : Backend Team

─── Classification ──────────────────────────────────────
Severity       : ☑ High
Priority       : ☑ P2 (High)
Status         : ☑ New
Type           : ☑ Integration / Functional

─── Environment ─────────────────────────────────────────
Application    : Shop Checkout v4.12.0-rc.2
Environment    : ☑ Staging
OS / Browser   : Ubuntu 22.04 LTS / Chromium 129.0.6668.29
Build / Commit : commit 9f3c2ab, Playwright 1.48.1
Issue          : [TICKET-ID] (assumed: pending tracker assignment)

─── Context ─────────────────────────────────────────────
Test Case      : checkout.spec.ts > gift card > applies a gift card to an order in EUR
Test Activity  : Automated regression testing, e2e-staging pipeline #3318
SDLC Phase     : System testing, pre-release validation
Technique      : Automated end-to-end test, gift card integration path
Test Data Used : Test user buyer.eur@shop.example (EUR store); gift card GC-TEST-0042 (EUR 20.00 balance); product "Desk Lamp" (EUR 49.00)

─── Reproduction ────────────────────────────────────────
Pre-conditions :

1. Signed in as test user buyer.eur@shop.example with EUR store context
2. "Desk Lamp" product (EUR 49.00) is in the shopping cart
3. Checkout page is open and the order summary is visible
4. Gift card GC-TEST-0042 with balance EUR 20.00 is valid and active

Steps to Reproduce :

1. On the checkout page, locate the gift card input field
2. Enter gift card code "GC-TEST-0042"
3. Click the "Apply" button
4. Observe the order summary and network response

Expected Result :

The gift card is successfully applied. The order summary displays:
- "Gift card: -€20.00" as a line item
- Order total updates from €49.00 to €29.00
- No error messages are shown

Actual Result :

A toast notification appears: "Something went wrong. Please try again."
The order summary does not update. The total remains €49.00.
The network response shows: POST /api/checkout/gift-card → HTTP 500
Error body: {"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}

Reproducibility : ☑ Intermittent (3 out of 10 attempts)
(Attempts 4, 7, and 9 failed; attempts 1, 2, 3, 5, 6, 8, 10 passed within the same build and commit)

─── Evidence ────────────────────────────────────────────
Attachments    : ☑ Network response (HAR data)
Link/Path      : CI run logs: https://staging.shop.example/ci/e2e-staging/#3318 (assumed — actual URL to be updated)
Console Output : TypeError: Cannot read properties of undefined (reading 'currency')
HTTP Status    : 500
Response Time  : [Not captured in log — assumed to be 500ms+]

─── Analysis ────────────────────────────────────────────
Defect Location : Backend endpoint `/api/checkout/gift-card`, missing null check or type guard on currency property before access
Root Cause     : N/A — not yet analysed
Suspicions     : Unconfirmed: currency service cache returns incomplete or null object on stale cache hit, causing the backend to fail when accessing `currency` property without validation. Developer noted flakiness in same area last sprint (team channel).

─── Resolution ──────────────────────────────────────────
Fix Applied    : N/A — not yet fixed
Fixed In Build : N/A — not yet fixed
Verified By    : N/A — awaiting retest
Verified On    : N/A — awaiting retest

─── Retest Criteria ─────────────────────────────────────
When marked Fixed, QA should:

1. **Confirmation test**: Repeat gift card application (attempt 5+ times against same build) to verify the 500 error no longer occurs
2. **Regression check**:
   - Apply gift cards in both EUR and USD stores
   - Test edge cases: expired gift cards, zero-balance cards, invalid codes
   - Verify order summary calculation accuracy after gift card deduction
   - Check that currency symbol and formatting are correct in all locales
3. **Load test note**: Intermittent failures suggest potential race condition under concurrent requests; monitor backend logs during retest for timing-related issues

─── Linked Items ────────────────────────────────────────
Issue / Bug    : [TICKET-ID] (pending — create in tracker)
Related Defects: N/A — none identified
Test Case      : checkout.spec.ts > gift card > applies a gift card to an order in EUR
─────────────────────────────────────────────────────────
