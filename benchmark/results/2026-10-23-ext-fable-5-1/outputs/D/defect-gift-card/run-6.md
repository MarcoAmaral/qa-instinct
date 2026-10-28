─────────────────────────────────────────────────────────
DEFECT REPORT
─────────────────────────────────────────────────────────
Defect ID      : DR-CHECKOUT-001
Title          : Checkout gift card – POST /api/checkout/gift-card returns 500 ("Cannot read properties of undefined (reading 'currency')") when a EUR gift card is applied to a EUR order
Reported By    : Marco (<account email, redacted>)
Reporter Role  : QA Analyst, product QA team (assumed)
Date Reported  : 2026-10-24
Assigned To    : Checkout team (assumed; no owner named in the log)

─── Classification ──────────────────────────────────────
Severity       : ✅ High
                 Justification: applying a gift card fails on roughly 3 of 10 attempts, the customer cannot
                 redeem the balance on that attempt, and the only workaround is to retry. Not Critical: the
                 order total stays correct (€49.00), no charge or balance change was observed, and checkout
                 without the gift card still works.
Priority       : ✅ P1 (Immediate)
                 Recommended to the PO: the failure is on build 4.12.0-rc.2, a release candidate, and it
                 affects payment in the EUR store. The PO sets the final value.
Status         : ✅ New
Type           : ✅ Functional / Integration

─── Environment ─────────────────────────────────────────
Application    : shop web (checkout) 4.12.0-rc.2
Environment    : ✅ Staging (https://staging.shop.example)
OS / Browser   : Ubuntu 22.04 CI runner / Chromium 129.0.6668.29 (Playwright 1.48.1)
Build / Commit : 4.12.0-rc.2, commit 9f3c2ab, pipeline e2e-staging #3318 (2026-10-14 06:12 UTC)
Issue          : N/A — no tracker issue exists yet; create one and link it here

─── Context ─────────────────────────────────────────────
Test Case      : TC-CHECKOUT-GC-001 (assumed ID for "checkout.spec.ts > gift card > applies a gift
                 card to an order in EUR"; replace with the team's real TC ID)
Test Activity  : Automated end-to-end run in CI (pipeline e2e-staging #3318), rerun with
                 --repeat-each=10 on the same commit
SDLC Phase     : System testing of release candidate 4.12.0-rc.2 on staging
Technique      : Scripted E2E scenario (happy path, EP: valid gift card with balance below order total)
Test Data Used : User buyer.eur@shop.example (EUR store); product "Desk Lamp" EUR 49.00;
                 gift card GC-TEST-0042, balance EUR 20.00

─── Reproduction ────────────────────────────────────────
Pre-conditions :
  1. Staging build 4.12.0-rc.2 (commit 9f3c2ab) deployed at https://staging.shop.example
  2. Test user buyer.eur@shop.example exists in the EUR store and can sign in
  3. Gift card GC-TEST-0042 exists with a balance of EUR 20.00 and has not been applied to another order
  4. Cart is empty before the test

Steps to Reproduce :
  1. Sign in as buyer.eur@shop.example
  2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout
  3. Enter gift card code GC-TEST-0042 and press "Apply"
  4. If the gift card applies, repeat steps 1 to 3 (the failure appeared on 3 of 10 repeats)

Expected Result :
  The order summary shows "Gift card: -€20.00" and a total of €29.00 (per the spec's assertion;
  assumed to match the acceptance criteria of the gift card story).

Actual Result :
  Toast "Something went wrong. Please try again." is shown and the total stays €49.00.
  Network: POST /api/checkout/gift-card -> 500
  Response body:
  {"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
  Identical status and body on attempts 4, 7 and 9. Attempts 1-3, 5, 6, 8 and 10 showed the
  expected summary.

Reproducibility : ✅ Intermittent (3/10 attempts, same commit, --repeat-each=10)

─── Evidence ────────────────────────────────────────────
Attachments    : ✅ Log file (CI log of pipeline e2e-staging #3318)
                 Assumed also available from the Playwright run: trace, screenshot and video for attempts
                 4, 7 and 9; attach them to the tracker issue once it exists. No HAR captured.
Link/Path      : CI pipeline e2e-staging, run #3318 (link to be added when the tracker issue is created)

─── Analysis ────────────────────────────────────────────
Defect Location: N/A — not yet investigated. The 500 and the TypeError text come from the handler
                 behind POST /api/checkout/gift-card, which dereferences `.currency` on an object
                 that is sometimes undefined. The raw TypeError also leaks into the response body
                 (a secondary error-handling gap to note on the same fix).
Root Cause     : N/A — not yet analysed
Suspicions     : Unconfirmed: the developer suspects the currency service cache, noting it "was
                 flaky last sprint too" (team channel, around 2026-10-14). Unconfirmed: the error
                 text suggests the handler reads `currency` from a lookup result (store, cart or
                 gift card currency) that is sometimes missing, which would fit a cache miss or a
                 race on first load.

─── Resolution ──────────────────────────────────────────
Fix Applied    : N/A — not yet fixed
Fixed In Build : N/A — not yet fixed
Verified By    : N/A — not yet fixed
Verified On    : N/A — not yet fixed

Retest criteria (for QA once a fix is delivered) :
  1. Confirmation test: run "applies a gift card to an order in EUR" with --repeat-each=30 on the
     fixed build; 30/30 must pass with no 500 from POST /api/checkout/gift-card.
  2. Regression check around the fix: gift card applied in a non-EUR store; gift card with balance
     above the order total; invalid or exhausted card code; removing an applied gift card; placing
     the order after the gift card is applied and checking the remaining balance.
  3. Error handling: force the failure path (for example, a missing currency entry) and confirm the API
     returns a structured error without a stack-trace message in the body, and the UI shows a
     meaningful message rather than the generic toast.

─── Linked Items ────────────────────────────────────────
Issue / Bug    : N/A — tracker issue to be created
Related Defects: N/A — none found. The developer's remark about last sprint suggests an earlier
                 report may exist; search the tracker for "currency service cache" and link it
                 here if found.
Test Case      : TC-CHECKOUT-GC-001 (assumed, see Context)
─────────────────────────────────────────────────────────

Assumptions made where the log gave no information: reporter role, assignee, test case ID, tracker issue, acceptance-criteria wording, availability of Playwright trace artefacts, and the approximate date of the developer's remark. Severity and priority are proposals for triage. Step 0 (system info commands) and Step 1 (evidence file generation) were not run because the working directory is empty and the request forbids creating files. The `context-discovery` and `test-evidence` rules could not be applied: no `qa-rules` skill is installed.
