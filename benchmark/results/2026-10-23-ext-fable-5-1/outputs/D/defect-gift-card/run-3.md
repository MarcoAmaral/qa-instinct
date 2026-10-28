─────────────────────────────────────────────────────────
**DEFECT REPORT**
─────────────────────────────────────────────────────────

**Defect ID:** DR-CHK-001
**Title:** Checkout gift card – POST /api/checkout/gift-card returns 500 (TypeError reading 'currency') when a EUR gift card is applied to a EUR order (intermittent)
**Reported By:** Marco (<account email, redacted>)
**Reporter Role:** QA Analyst, Swareco QA team
**Date Reported:** 2026-10-24 (failure observed in CI on 2026-10-14 06:12 UTC)
**Assigned To:** Checkout team (backend owner of `/api/checkout/gift-card`)

### Classification

**Severity:** ✅ High
Justification: a core checkout payment step fails with a server error and a generic toast; the gift card is not applied and the customer is charged the full amount if they continue. The only workaround is to press "Apply" again, which the UI does not suggest, and the failure rate on identical input is 3 in 10. Not Critical: checkout itself still completes and no data is lost.

**Priority:** ✅ P1 (Immediate) — proposed; PO to confirm
Justification: the failure sits on the money path of release candidate 4.12.0-rc.2 and reproduces on staging at 30 %. The gate decision for the release belongs to the release gate in the test plan, not to this field.

**Status:** ✅ New
**Type:** ✅ Functional / ✅ Integration (server-side 500; developer suspects an upstream currency service)

### Environment

**Application:** shop.example storefront, 4.12.0-rc.2
**Environment:** ✅ Staging (https://staging.shop.example)
**OS / Browser:** Ubuntu 22.04 CI runner / Chromium 129.0.6668.29 via Playwright 1.48.1
**Build / Commit:** 4.12.0-rc.2, commit 9f3c2ab, pipeline e2e-staging #3318
**Issue:** N/A — no tracker issue exists yet; create one and link it here

### Context

**Test Case:** N/A — no TC id; automated spec `checkout.spec.ts` > gift card > "applies a gift card to an order in EUR"
**Test Activity:** Automated end-to-end regression run in CI, rerun with `--repeat-each=10` on the same commit
**SDLC Phase:** Release candidate testing of 4.12.0 on staging (assumed: system/regression testing before release)
**Technique:** Scenario-based end-to-end test, positive partition (valid, active gift card with balance below the order total)
**Test Data Used:**
- User `buyer.eur@shop.example` (EUR store)
- Product "Desk Lamp", EUR 49.00
- Gift card `GC-TEST-0042`, balance EUR 20.00

### Reproduction

**Pre-conditions:**
1. Test user `buyer.eur@shop.example` exists in the EUR store and can sign in
2. Gift card `GC-TEST-0042` is active with a balance of EUR 20.00
3. "Desk Lamp" is purchasable at EUR 49.00
4. Cart is empty before the run

**Steps to Reproduce:**
1. Sign in as `buyer.eur@shop.example` on https://staging.shop.example
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout
3. Enter gift card `GC-TEST-0042` in the gift card field and press "Apply"
4. Repeat steps 1–3 at least 10 times on the same build (the failure is intermittent)

**Expected Result:**
The order summary shows "Gift card: -€20.00" and a total of €29.00 (from the spec's assertion; no acceptance criteria text was supplied, assumed to match).

**Actual Result:**
On 3 of 10 attempts (attempts 4, 7, 9) a toast appears: "Something went wrong. Please try again." The total stays €49.00 and no gift card line is shown.

Network:

```text
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

The 7 passing attempts showed the expected summary. All attempts ran on the same commit with the same data.

**Reproducibility:** ✅ Intermittent (3/10 attempts)

### Evidence

**Attachments:** ✅ Log file (CI log of pipeline e2e-staging #3318, including the request/response above)
Assumed: the Playwright run keeps a trace, screenshot and video per failed attempt; attach those for attempts 4, 7 and 9 if present. A HAR file was not captured.
**Link/Path:** Pipeline e2e-staging #3318 (CI artifacts); exact artifact URL unknown. Upload to the tracker issue once created; do not store a local path in the work item.

### Analysis

**Defect Location:** Server-side handler of `POST /api/checkout/gift-card`: something reads `.currency` on a value that is `undefined` on the failing requests (the gift card record, the store/order currency lookup, or a service response). File, function and line not identified; the stack trace is not in the response body and needs to be pulled from the API logs for the 06:12 UTC run.
**Root Cause:** N/A — not yet analysed
**Suspicions:**
- Unconfirmed: the developer suspects the currency service cache, noting "it was flaky last sprint too" (team channel, 2026-10-14).
- Unconfirmed: the same input succeeds 7 times and fails 3 times on one commit, which points at state that varies between requests (cache miss or expiry, upstream timeout, race) rather than at the test data — reporter's observation from the repeat run.

### Resolution

**Fix Applied:** N/A — not yet fixed
**Fixed In Build:** N/A — not yet fixed
**Verified By:** N/A — not yet fixed
**Verified On:** N/A — not yet fixed

### Linked Items

**Issue / Bug:** N/A — to be created in the tracker
**Related Defects:** N/A — none found; the "last sprint" flakiness the developer mentions has no defect id. Search the tracker for it and link it here if one exists.
**Test Case:** `checkout.spec.ts` > gift card > "applies a gift card to an order in EUR"

─────────────────────────────────────────────────────────

### Retest Criteria (for the Retest state)

**Confirmation test:** rerun the same spec against the fixed build with `--repeat-each=30` on staging. Pass criterion: 30/30 green, no 500 from `/api/checkout/gift-card`, and the API logs show no `TypeError` for the run. One pass is not enough for a 30 % intermittent failure.

**Regression check around the fix:**
- Gift card applied in the other store currencies (for example USD, GBP), and a gift card whose currency differs from the order's
- Gift card with balance greater than or equal to the order total (total goes to €0.00)
- Removing an applied gift card and re-applying it; applying two gift cards in sequence
- Whatever the fix touches in the currency service cache: cold start, expiry and refresh paths

**Do not mask this test as flaky.** The server returns a 500 with a TypeError, so this is a product defect, not test timing. Retries or quarantine in CI would hide it.

### Assumptions and Notes

- Reporter identity taken from the session account; defect prefix `CHK` assumed for the checkout component.
- Step 0 (system info commands) and Step 1 (local evidence capture) were not run: the failure comes from a CI log, not a local reproduction, and no files were to be created.
- Rules not applied because the `qa-rules` skill is not installed: `context-discovery` (tracker schema derivation) and `test-evidence` (evidence capture format).
