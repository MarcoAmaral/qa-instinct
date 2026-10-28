─────────────────────────────────────────────────────────
DEFECT REPORT
─────────────────────────────────────────────────────────
Defect ID      : DR-CHK-001
Title          : Checkout – Gift card apply fails with HTTP 500 `TypeError ... (reading 'currency')` when a EUR gift card is applied to a EUR order (intermittent)
Reported By    : <account email, redacted>
Reporter Role  : Senior QA Analyst, product QA team (assumed)
Date Reported  : 2026-10-24
Assigned To    : Checkout / Payments team (assumed owner of `/api/checkout/gift-card`)

─── Classification ──────────────────────────────────────
Severity       : ✅ High
                 Justification: a paying customer cannot redeem a gift card when the fault occurs;
                 no workaround inside the flow other than retrying. Not Critical: checkout itself
                 still completes without the gift card, and the fault is intermittent (3/10).
Priority       : ✅ P1 (Immediate)
                 Justification: proposed to the PO. The failure is on release candidate
                 4.12.0-rc.2 for the EUR store, in the payment step, with a 30% hit rate per
                 attempt; it should be fixed or explicitly accepted before 4.12.0 ships.
                 Final priority is the PO's call.
Status         : ✅ New
Type           : ✅ Functional / Integration

─── Environment ─────────────────────────────────────────
Application    : shop web app 4.12.0-rc.2 (EUR store)
Environment    : ✅ Staging (https://staging.shop.example)
OS / Browser   : Ubuntu 22.04 CI runner / Chromium 129.0.6668.29 (Playwright 1.48.1)
Build / Commit : 4.12.0-rc.2, commit 9f3c2ab, pipeline e2e-staging #3318 (2026-10-14 06:12 UTC)
Issue          : N/A — no tracker issue created yet (assumption: tracker is unknown; to be
                 linked by whoever files this)

─── Context ─────────────────────────────────────────────
Test Case      : TC-CHK-GC-001 (assumed ID for `checkout.spec.ts > gift card > applies a gift
                 card to an order in EUR`; no TC catalogue was available)
Test Activity  : Automated end-to-end regression run of the e2e-staging pipeline, executed
                 with `--repeat-each=10` on a single commit
SDLC Phase     : System testing of release candidate 4.12.0-rc.2 (sprint assumed; not given
                 in the log)
Technique      : Scripted E2E scenario (happy path), repeat-run to measure stability
Test Data Used : User buyer.eur@shop.example (EUR store); product "Desk Lamp" EUR 49.00;
                 gift card GC-TEST-0042 with balance EUR 20.00

─── Reproduction ────────────────────────────────────────
Pre-conditions :
  1. Staging deployed at 4.12.0-rc.2 (commit 9f3c2ab)
  2. Test user buyer.eur@shop.example exists in the EUR store and can sign in
  3. Gift card GC-TEST-0042 exists, is active, and has a EUR 20.00 balance
  4. Cart is empty before the run (assumption: the spec starts from a clean cart)

Steps to Reproduce :
  1. Sign in as buyer.eur@shop.example
  2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout
  3. Enter gift card code GC-TEST-0042 and press "Apply"
  4. If the step succeeds, repeat steps 1–3 (the fault is intermittent; 10 runs reproduced
     it 3 times)

Expected Result :
  The order summary shows "Gift card: -€20.00" and a total of €29.00
  (as asserted by the spec; no separate acceptance-criteria document was available).

Actual Result :
  Toast displayed: "Something went wrong. Please try again."
  Order total remains €49.00; no gift card line appears.
  Network: POST /api/checkout/gift-card -> 500
  Response body:
  {"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}

Reproducibility : ✅ Intermittent (3/10 attempts) — attempts 4, 7 and 9 failed with the same
                  status and body; attempts 1–3, 5, 6, 8 and 10 passed on the same commit.

─── Evidence ────────────────────────────────────────────
Attachments    : ✅ Log file (CI log, pipeline e2e-staging #3318)
                 Assumption: the Playwright run also produced a trace, screenshot and video for
                 the failed attempts; attach `trace.zip` and the screenshot for attempt 4 from
                 the pipeline artifacts. Not captured locally: the failure comes from a CI run
                 and this report was written without file creation.
Link/Path      : e2e-staging #3318 artifacts (URL not provided in the log; add the pipeline
                 link when filing)

─── Analysis ────────────────────────────────────────────
Defect Location: Server-side handler of POST /api/checkout/gift-card: some object the handler
                 reads `.currency` from is `undefined` on the failing requests. Exact file and
                 line not known; the stack trace is not in the response body and the server
                 log for the failing requests was not available.
Root Cause     : N/A — not yet analysed
Suspicions     : Unconfirmed: the developer on the team channel suspects the currency service
                 cache ("probably the currency service cache again, it was flaky last sprint
                 too").
                 Unconfirmed: reporter's observation from the error text: the handler
                 dereferences `.currency` on a lookup result without a guard, so whatever
                 returns `undefined` intermittently (cache miss, timeout, race) surfaces as a
                 500 instead of a handled error. A similar failure "last sprint" suggests a
                 prior defect or incident may exist; see Related Defects.

─── Resolution ──────────────────────────────────────────
Fix Applied    : N/A — not yet fixed
Fixed In Build : N/A — not yet fixed
Verified By    : N/A — not yet fixed
Verified On    : N/A — not yet fixed

Retest criteria (for the confirmation test once a fix is delivered):
  1. Re-run `checkout.spec.ts > gift card > applies a gift card to an order in EUR` on the
     fixed build with `--repeat-each=20` (at least twice the original sample): 20/20 must pass,
     with no 500 from POST /api/checkout/gift-card in the network log.
  2. Regression check around the fix: apply a gift card in the other store currencies
     (at minimum USD and GBP, or whatever the shop supports), apply a gift card whose currency
     does not match the order, apply an expired/zero-balance card, and remove an applied card.
     If the fix touches the currency service or its cache, also re-run the price display and
     tax calculation E2E specs that depend on it.
  3. Confirm the API returns a handled error (4xx with a message) rather than a 500 when the
     currency lookup fails, if the fix adds such handling.

─── Linked Items ────────────────────────────────────────
Issue / Bug    : N/A — not yet created in the tracker (link when filed)
Related Defects: N/A — none found. Search the tracker for last sprint's "currency service
                 cache" flakiness mentioned on the team channel; link it here if it exists.
Test Case      : TC-CHK-GC-001 (assumed; see Context)
─────────────────────────────────────────────────────────

Assumptions made: reporter role, team owning the endpoint, test case ID, sprint, clean-cart precondition, and the existence of Playwright trace/screenshot artifacts are all assumed as stated above. Steps 0 and 1 of the skill (local system info and evidence capture) were not run because the failure comes from a CI log and the request forbids creating files. Rules not applied because neither they nor a `qa-rules` skill were available: `context-discovery` and `test-evidence`.
