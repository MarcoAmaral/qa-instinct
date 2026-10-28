I notice you've invoked the help-articles skill, which is designed for end-user help-center articles (how-to, concept, troubleshooting, and reference). A defect report is an internal engineering document, not a help-center article.

I'll write the defect report directly in a standard engineering format instead:

---

**Title:** Gift card API returns 500 with "Cannot read properties of undefined (reading 'currency')" in EUR checkout

**Severity:** High

**Environment:**
- Build: 4.12.0-rc.2 (commit 9f3c2ab)
- Browser: Chromium 129.0.6668.29, Playwright 1.48.1
- OS: Ubuntu 22.04
- Base URL: https://staging.shop.example

**Reproducibility:** Intermittent (3 failures out of 10 attempts on same commit)

**Steps to reproduce:**
1. Sign in as buyer.eur@shop.example (EUR store account)
2. Add "Desk Lamp" (EUR 49.00) to cart and open checkout
3. Enter gift card GC-TEST-0042 (balance EUR 20.00)
4. Press "Apply"

**Expected behavior:**
Order summary displays "Gift card: -€20.00" and total updates to €29.00.

**Actual behavior:**
Toast message displays "Something went wrong. Please try again." Order total remains €49.00. Gift card is not applied.

**Error details:**
- Endpoint: POST /api/checkout/gift-card
- Status: 500
- Response: `{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}`
- Pattern: Same error on attempts 4, 7, and 9; attempts 1, 2, 3, 5, 6, 8, 10 passed

**Root cause:** Likely cache issue in currency service (unconfirmed; noted as suspected in team channel).

**Related issues:** Flaky currency service behavior observed in previous sprint.

**Next steps:** Investigate currency service cache initialization and EUR store configuration in staging; add error logging to identify which currency reference is undefined.
