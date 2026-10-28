─────────────────────────────────────────────────────────
DEFECT REPORT
─────────────────────────────────────────────────────────
Defect ID      : DR-CHK-001
Title          : Checkout gift card – "Apply" returns HTTP 500 (TypeError reading 'currency') when a gift card is applied to an EUR order
Reported By    : QA Engineer (assumption: name not in the CI log; replace on filing)
Reporter Role  : QA Engineer, product QA team
Date Reported  : 2026-10-24 (failure observed 2026-10-14 06:12 UTC in CI)
Assigned To    : Checkout team (assumption: owner of `/api/checkout/*`; the developer who posted the cache note in the team channel is the first contact)

─── Classification ──────────────────────────────────────
Severity       : ✅ High
                 Justification: a money-affecting step of checkout fails in roughly 3 of 10 attempts on a release candidate; the server answers 500 with an unhandled TypeError and the discount is not applied. Retrying is not a dependable workaround for a customer at checkout, and nothing in the UI tells them what went wrong. Not Critical: the order can still be placed at full price and no data loss was observed.
Priority       : ✅ P1 (Immediate) — proposed; the PO confirms
                 Justification: build 4.12.0-rc.2 is a release candidate and checkout is on the revenue path. The team should also decide whether the gift-card e2e test is a release gate for this RC.
Status         : ✅ New
Type           : ✅ Functional / Integration

─── Environment ─────────────────────────────────────────
Application    : shop web (checkout) 4.12.0-rc.2
Environment    : ✅ Staging (https://staging.shop.example, EUR store)
OS / Browser   : Ubuntu 22.04 CI runner / Chromium 129.0.6668.29 (Playwright 1.48.1)
Build / Commit : 4.12.0-rc.2, commit 9f3c2ab, pipeline e2e-staging #3318
Issue          : N/A — tracker issue not yet created (create on filing and link here)

─── Context ─────────────────────────────────────────────
Test Case      : TC-CHK-NNN (assumption: no TC id in the log; the automated spec is `checkout.spec.ts > gift card > applies a gift card to an order in EUR`)
Test Activity  : Automated end-to-end run of the checkout suite in CI, repeated 10× on the same commit (`--repeat-each=10`)
SDLC Phase     : System testing of release candidate 4.12.0-rc.2 on staging
Technique      : Scripted happy-path test (EP, valid partition: gift card balance below order total, same currency); repeat run used to measure reproducibility
Test Data Used : User buyer.eur@shop.example (EUR store); product "Desk Lamp" EUR 49.00; gift card GC-TEST-0042, balance EUR 20.00

─── Reproduction ────────────────────────────────────────
Pre-conditions :
  1. Staging is running build 4.12.0-rc.2 (commit 9f3c2ab)
  2. Test user buyer.eur@shop.example exists and is attached to the EUR store
  3. Gift card GC-TEST-0042 exists with a balance of EUR 20.00
  4. Cart is empty at the start of the attempt

Steps to Reproduce :
  1. Sign in as buyer.eur@shop.example
  2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout
  3. Enter gift card GC-TEST-0042 in the gift card field and press "Apply"
  4. If the summary updates correctly, repeat steps 1–3; the failure appeared on attempts 4, 7 and 9 of 10

Expected Result :
  The order summary shows "Gift card: -€20.00" and a total of €29.00 (as asserted by the spec; assumption: the spec assertion reflects the acceptance criteria of the gift-card story, which are not in the log).

Actual Result :
  Toast "Something went wrong. Please try again." is shown and the total stays €49.00.
  Network: `POST /api/checkout/gift-card` -> 500
  Response body:
  `{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}`
  Attempts 7 and 9 failed with the same status and body. The 7 passing attempts showed the expected summary.

Reproducibility : ✅ Intermittent (3/10 attempts, same commit, same data)
  This is a product failure, not a test flake: every failed attempt carries a server-side 500 with an identical error body, and the passing attempts show the correct summary. The test should not be quarantined as flaky.

─── Evidence ────────────────────────────────────────────
Attachments    : ✅ Log file (CI log of e2e-staging #3318, quoted above)  ✅ Screenshot / Video / HAR (assumption: Playwright trace, screenshot and video of attempts 4, 7 and 9 are retained as run artifacts; attach them to the tracker issue, do not store a local path)
Link/Path      : Pipeline e2e-staging #3318 artifacts (Playwright report and traces for attempts 4, 7, 9); server logs for `POST /api/checkout/gift-card` around 2026-10-14 06:12 UTC still to be pulled by the Checkout team

─── Analysis ────────────────────────────────────────────
Defect Location: Not yet confirmed. The error is server-side, in the handler of `POST /api/checkout/gift-card` or a service it calls: the response body is an unhandled TypeError, so the handler dereferences `.currency` on a value that is sometimes undefined and has no guard for that case. The exact file and line are not available from the CI log.
Root Cause     : N/A — not yet analysed
Suspicions     :
  - Unconfirmed: the developer on the team channel suspects the currency service cache ("probably the currency service cache again, it was flaky last sprint too").
  - Unconfirmed (reporter, from the error text): the undefined value is the resolved currency context (store, cart or gift card currency) rather than the gift card itself, since the card was found in the 7 passing attempts with the same code.
  - Unconfirmed (reporter): the "last sprint" remark suggests a prior occurrence that may already have a report; check the tracker before triage (see Related Defects).

─── Resolution ──────────────────────────────────────────
Fix Applied    : N/A — not yet fixed
Fixed In Build : N/A — not yet fixed
Verified By    : N/A — not yet fixed
Verified On    : N/A — not yet fixed

Retest criteria (for QA once a fix lands):
  1. Confirmation test: rerun `checkout.spec.ts > gift card > applies a gift card to an order in EUR` on the fixed build with `--repeat-each=20` or more against staging; 0 failures required, since a 3/10 failure rate would be expected to show in 20 runs.
  2. Check that `POST /api/checkout/gift-card` never returns 500 for this scenario; a controlled failure, if any, must return a 4xx with a user-readable message rather than a TypeError in the body.
  3. Regression around the fix: gift card applied in the other store currencies (e.g. USD, GBP); gift card with a balance above the order total; gift card in a currency different from the store; removing an applied gift card; placing the order and checking the remaining balance; full checkout suite.

─── Linked Items ────────────────────────────────────────
Issue / Bug    : N/A — tracker issue to be created on filing
Related Defects: N/A — none found in the CI log; search the tracker for a gift-card or currency-cache defect from last sprint (developer's note); if one exists, set this report to Duplicate and link it here
Test Case      : TC-CHK-NNN (assumption, see Context) — `checkout.spec.ts > gift card > applies a gift card to an order in EUR`
─────────────────────────────────────────────────────────

Assumptions made where the log was silent: reporter name and test case id are placeholders; Assigned To is the Checkout team; CI run artifacts (trace, screenshot, video) are assumed retained for the failed attempts; the spec's assertion is taken as the acceptance criterion; Priority is a QA proposal pending the PO. Step 0 (system info commands) and Step 1 (evidence capture to `docs/qa/evidence/`) were not run because no files were to be created and the environment data comes from the CI log. Rules not applied because the `qa-rules` skill is not installed: `context-discovery` (no tracker schema could be derived, so the package template is used) and `test-evidence`.
