# Defect Report DR-CHK-001

```text
─────────────────────────────────────────────────────────
DEFECT REPORT
─────────────────────────────────────────────────────────
Defect ID      : DR-CHK-001
Title          : Checkout gift card – Apply fails with HTTP 500 "Cannot read properties of
                 undefined (reading 'currency')" when a EUR gift card is applied to a EUR order
                 (intermittent, 3/10)
Reported By    : Marco (<account email, redacted>)
Reporter Role  : QA Engineer, product QA team (assumed)
Date Reported  : 2026-10-24
Assigned To    : Checkout team (assumed; owner of /api/checkout/gift-card)

─── Classification ──────────────────────────────────────
Severity       : ✅ High
                 Justification: gift card redemption, a checkout payment step, fails on
                 roughly 3 in 10 attempts with an unhandled server error. The only
                 "workaround" is retrying, which is unreliable and not guaranteed to the
                 shopper. No data loss observed (total stays €49.00, no partial debit seen).
Priority       : ✅ P2 (High) — proposed; PO to confirm
                 Justification: found on release candidate 4.12.0-rc.2; fix should land in
                 the current sprint. The PO may raise to P1 if the RC is due to ship before
                 the sprint ends.
Status         : ✅ New
Type           : ✅ Functional  ✅ Integration

─── Environment ─────────────────────────────────────────
Application    : shop web checkout 4.12.0-rc.2
Environment    : ✅ Staging (https://staging.shop.example)
OS / Browser   : Ubuntu 22.04 (CI runner) / Chromium 129.0.6668.29 via Playwright 1.48.1
Build / Commit : 4.12.0-rc.2, commit 9f3c2ab
Issue          : N/A — tracker issue not yet created

─── Context ─────────────────────────────────────────────
Test Case      : TC-CHK-NNN (assumed; automated as checkout.spec.ts > gift card >
                 "applies a gift card to an order in EUR")
Test Activity  : Automated end-to-end regression run, CI pipeline e2e-staging #3318,
                 2026-10-14 06:12 UTC, rerun with --repeat-each=10 on the same commit
SDLC Phase     : System testing of release candidate 4.12.0-rc.2 on staging
Technique      : Scripted E2E scenario (happy path); repeat run to measure reproducibility
Test Data Used : Account buyer.eur@shop.example (EUR store); product "Desk Lamp" EUR 49.00;
                 gift card GC-TEST-0042, balance EUR 20.00

─── Reproduction ────────────────────────────────────────
Pre-conditions :
  1. Staging deployed with build 4.12.0-rc.2 (commit 9f3c2ab)
  2. Test user buyer.eur@shop.example exists and is assigned to the EUR store
  3. Gift card GC-TEST-0042 is active with a EUR 20.00 balance
  4. Cart is empty before the run

Steps to Reproduce :
  1. Sign in as buyer.eur@shop.example
  2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout
  3. Enter gift card code GC-TEST-0042 and press "Apply"
  4. Repeat steps 1–3 up to 10 times (failure is intermittent)

Expected Result :
  The order summary shows "Gift card: -€20.00" and the total €29.00.
  (As asserted by the spec; assumed to match the gift card acceptance criteria.)

Actual Result :
  Toast displayed: "Something went wrong. Please try again."
  Order total remains €49.00; no gift card line is shown.
  Network: POST /api/checkout/gift-card -> 500
  Response body:
  {"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}

Reproducibility : ✅ Intermittent (3/10 attempts: attempts 4, 7 and 9 failed with the same
                  status and body; attempts 1–3, 5, 6, 8, 10 passed)

─── Evidence ────────────────────────────────────────────
Attachments    : ✅ Log file (CI log, pipeline e2e-staging #3318)
                 ✅ Screenshot / trace (assumed: Playwright failure screenshots and traces
                 retained as CI artifacts for attempts 4, 7 and 9; to be attached to the
                 tracker issue on creation)
Link/Path      : CI pipeline e2e-staging, run #3318, 2026-10-14 06:12 UTC
                 (artifact URL not in the log; attach from the run page)

─── Analysis ────────────────────────────────────────────
Defect Location: Server-side handler of POST /api/checkout/gift-card (file and line not yet
                 identified). The error text indicates the handler dereferences `.currency`
                 on a value that is undefined in the failing requests, and the resulting
                 exception is not caught, so a raw TypeError reaches the client as a 500.
Root Cause     : N/A — not yet analysed
Suspicions     : Unconfirmed: the developer suspects the currency service cache, noting it
                 "was flaky last sprint too" (team channel, 2026-10-14).
                 Unconfirmed: the error message suggests a lookup of the store, cart or gift
                 card currency returned undefined on the failing requests only; the input
                 was identical across all 10 attempts, so the variation is on the server
                 side (QA, from the CI log).

─── Resolution ──────────────────────────────────────────
Fix Applied    : N/A — not yet fixed
Fixed In Build : N/A — not yet fixed
Verified By    : N/A — not yet fixed
Verified On    : N/A — not yet fixed

─── Linked Items ────────────────────────────────────────
Issue / Bug    : N/A — tracker issue not yet created
Related Defects: N/A — none found (the "last sprint" incident the developer mentions has no
                 defect ID in the log; link it here if one exists)
Test Case      : TC-CHK-NNN (assumed) / checkout.spec.ts > gift card > applies a gift card
                 to an order in EUR
─────────────────────────────────────────────────────────
```

## Retest criteria

**Confirmation test.** Rerun the spec `checkout.spec.ts > gift card > applies a gift card to an order in EUR` on the fixed build with `--repeat-each=20` or more. Pass criterion: 0 failures, and no 500 from POST /api/checkout/gift-card in any attempt. A 10-run sample is too small to confirm a fix for a 30% failure rate.

**Regression around the fix.**
- Gift card applied to a non-EUR store order (for example USD and GBP accounts), and a gift card whose currency does not match the store currency.
- Gift card balance greater than, equal to and less than the order total.
- Removing an applied gift card and applying a second one.
- Any other checkout endpoint that reads a currency from the same service or cache (shipping quotes, tax, promo codes).
- Error handling: a deliberately invalid gift card code must return a handled 4xx, not a 500.

## Notes and assumptions

- **Not a flaky test.** The product returned a 500 with identical input on the same commit. This is an intermittent product defect, not test timing, and the spec should not be quarantined or retried away.
- **Information disclosure.** The 500 body exposes an internal TypeError message to the client. Recommend a separate Low-severity Security defect so it is not lost when this one is fixed.
- **Assumptions made:** project code CHK, reporter name from the email, reporter role, assignee team, application name, test case ID, and the existence of Playwright screenshots and traces as CI artifacts. Replace these where the tracker has the real values.
- **Rules not applied:** the `context-discovery` and `test-evidence` rules were not loaded and no `qa-rules` skill is installed, so the report uses this template rather than a tracker-derived schema. Step 0 (system info) and Step 1 (evidence capture) were not run because the instruction was to create no files and the failure is in a remote CI run.
