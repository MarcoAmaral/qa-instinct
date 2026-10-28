─────────────────────────────────────────────────────────
DEFECT REPORT
─────────────────────────────────────────────────────────
Defect ID      : DR-CHECKOUT-001
Title          : Checkout gift card – POST /api/checkout/gift-card returns 500 (`TypeError: Cannot read properties of undefined (reading 'currency')`) intermittently when a EUR gift card is applied to a EUR order
Reported By    : Marco (<account email, redacted>)
Reporter Role  : QA Analyst, product QA team (assumed: reporter role not stated in the log)
Date Reported  : 2026-10-24
Assigned To    : Checkout backend team (assumed: owner of `/api/checkout/gift-card`; not stated in the log)

─── Classification ──────────────────────────────────────
Severity       : ✅ High
                 Justification: the gift-card redemption step of checkout fails outright for the
                 customer (server error, toast, discount not applied). No workaround inside the
                 flow other than retrying. Not Critical: it is intermittent (3/10) and the order
                 can still be paid at full price, so checkout as a whole is not blocked and no
                 data is lost.
Priority       : ✅ P2 (High) — proposed; the PO sets priority
                 Justification: the failure is on release candidate 4.12.0-rc.2 in a payment
                 step, so it should be fixed in the current sprint before the release decision.
                 Whether it blocks the release is for the release gate in the test plan, not
                 this field.
Status         : ✅ New
Type           : ✅ Functional / Integration
                 (Integration: the error names a `currency` property on an undefined object,
                 which points at a dependency between the gift-card endpoint and whatever
                 supplies the currency object)

─── Environment ─────────────────────────────────────────
Application    : shop web checkout, 4.12.0-rc.2
Environment    : ✅ Staging (https://staging.shop.example)
OS / Browser   : Ubuntu 22.04 CI runner / Chromium 129.0.6668.29 (Playwright 1.48.1)
Build / Commit : 4.12.0-rc.2, commit 9f3c2ab — pipeline e2e-staging #3318, run 2026-10-14 06:12 UTC
Issue          : N/A — no tracker issue ID in the log; create one and link it here when filed

─── Context ─────────────────────────────────────────────
Test Case      : TC-CHECKOUT-GIFTCARD-001 (assumed ID; the automated spec is
                 `checkout.spec.ts > gift card > applies a gift card to an order in EUR`)
Test Activity  : Automated end-to-end run on the release candidate, pipeline e2e-staging #3318,
                 followed by a repeat run of the same spec (`--repeat-each=10`) on the same commit
SDLC Phase     : System testing of release candidate 4.12.0-rc.2 on staging
Technique      : Scripted end-to-end scenario (happy path, single currency); repeat execution to
                 measure reproducibility
Test Data Used : User `buyer.eur@shop.example` (EUR store); product "Desk Lamp", EUR 49.00;
                 gift card `GC-TEST-0042`, balance EUR 20.00

─── Reproduction ────────────────────────────────────────
Pre-conditions :
  1. Staging is deployed with build 4.12.0-rc.2 (commit 9f3c2ab)
  2. Test user `buyer.eur@shop.example` exists and is assigned to the EUR store
  3. Gift card `GC-TEST-0042` exists, is in EUR, and has a balance of EUR 20.00
  4. Cart is empty before the run

Steps to Reproduce :
  1. Sign in at https://staging.shop.example as `buyer.eur@shop.example`
  2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout
  3. In the gift card field enter `GC-TEST-0042` and press "Apply"
  4. Observe the order summary and the response of `POST /api/checkout/gift-card`
  5. Because the failure is intermittent, repeat steps 1–4 up to 10 times on the same build

Expected Result :
  The order summary shows "Gift card: -€20.00" and a total of €29.00 (as asserted by the spec;
  the acceptance criteria document was not available, so the spec's assertion is taken as the
  documented behaviour). `POST /api/checkout/gift-card` returns a success status.

Actual Result :
  On 3 of 10 attempts (attempts 4, 7 and 9) a toast reads:
    Something went wrong. Please try again.
  The total stays at €49.00 and no gift card line is shown.
  Network: `POST /api/checkout/gift-card` -> HTTP 500
  Response body:
    {"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
  The 7 other attempts showed the expected summary.

Reproducibility : ✅ Intermittent (3/10 attempts) — same commit, same test data, same runner

─── Evidence ────────────────────────────────────────────
Attachments    : ✅ Log file (CI run log, pipeline e2e-staging #3318, quoted above)
                 □ Screenshot  □ Video  □ HAR file — Playwright trace/screenshot for attempts
                 4, 7 and 9 should exist as run artifacts if `trace`/`screenshot` are enabled;
                 attach them to the tracker issue when it is created
Link/Path      : CI pipeline e2e-staging, run #3318 (URL not in the log; add the run URL when filing)

─── Analysis ────────────────────────────────────────────
Defect Location: N/A — not yet investigated. The response body indicates the handler for
                 `POST /api/checkout/gift-card` (or a function it calls) reads `.currency` on a
                 value that is `undefined` in the failing requests; the stack trace from the
                 server log for attempts 4, 7 and 9 is needed to name the file and line.
Root Cause     : N/A — not yet analysed
Suspicions     : Unconfirmed: the developer suspects the currency service cache, noting it "was
                 flaky last sprint too" (team channel, around 2026-10-14). Unconfirmed: QA notes
                 that the failing and passing attempts used identical input, so a non-deterministic
                 input to the handler (a cache miss, a timed-out or empty lookup for the store,
                 gift card or user currency) is consistent with the observation. Neither has been
                 verified.

─── Resolution ──────────────────────────────────────────
Fix Applied    : N/A — not yet fixed
Fixed In Build : N/A — not yet fixed
Verified By    : N/A — not yet fixed
Verified On    : N/A — not yet fixed

Retest criteria (for when a fix is delivered) :
  1. Confirmation test: run `checkout.spec.ts > gift card > applies a gift card to an order in EUR`
     with `--repeat-each=20` on the fixed build; expect 20/20 passes and no HTTP 500 from
     `POST /api/checkout/gift-card`.
  2. Regression check: gift card in a second currency store (e.g. USD user and USD card), gift
     card balance greater than the order total, card balance of zero, invalid card code, and
     removing an applied gift card. Also run the regression suite around checkout totals and
     the currency-dependent price display.
  3. If the fix touches the currency service or its cache, run the above once immediately after
     a service restart (cold cache) and once after a warm-up.

─── Linked Items ────────────────────────────────────────
Issue / Bug    : N/A — no tracker issue yet; add the ID when filed
Related Defects: N/A — none found. The developer's remark about flakiness "last sprint" suggests
                 an earlier report may exist; search the tracker for currency-service cache
                 defects and link it here if found.
Test Case      : TC-CHECKOUT-GIFTCARD-001 (`checkout.spec.ts > gift card > applies a gift card to an order in EUR`)
─────────────────────────────────────────────────────────

Note on rules: the `context-discovery` and `test-evidence` rules named by this skill were not loaded and no `qa-rules` skill is installed, so the report uses the skill's default template rather than a tracker-specific schema. System-info collection (Step 0) and local evidence capture (Step 1) were not run because the failure occurred on a CI runner and the instructions asked for no file creation.
