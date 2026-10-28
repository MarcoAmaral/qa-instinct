─────────────────────────────────────────────────────────
**DEFECT REPORT**
─────────────────────────────────────────────────────────

- Defect ID : DR-CHK-001
- Title : Checkout gift card – `POST /api/checkout/gift-card` returns 500 `TypeError: Cannot read properties of undefined (reading 'currency')` when a EUR gift card is applied to a EUR order (intermittent, 3/10)
- Reported By : QA Analyst (name not given in the log; assumed to be the person filing from CI run #3318)
- Reporter Role : QA Analyst, product QA team
- Date Reported : 2026-10-24 (failure observed in CI on 2026-10-14 06:12 UTC)
- Assigned To : Checkout team (assumed owner of `/api/checkout/*`)

─── Classification ──────────────────────────────────────

- Severity : ✅ High — applying a gift card, a payment step in checkout, fails in 3 of 10 attempts on the same build with a server error. The only workaround is to retry, which the user is not guaranteed to succeed at and which a paying customer will not reliably do. Not Critical because the order is not corrupted (total stays €49.00) and the feature works in 7 of 10 attempts.
- Priority : ✅ P1 (Immediate) — proposed; PO to confirm. Justification: the build is release candidate 4.12.0-rc.2 and the defect is on the checkout payment path. Whether it blocks the release is decided by the release gate in the test plan, not here.
- Status : ✅ New
- Type : ✅ Functional / Integration

─── Environment ─────────────────────────────────────────

- Application : shop storefront 4.12.0-rc.2 (EUR store)
- Environment : ✅ Staging — https://staging.shop.example
- OS / Browser : Ubuntu 22.04 CI runner / Chromium 129.0.6668.29, driven by Playwright 1.48.1
- Build / Commit : 4.12.0-rc.2, commit 9f3c2ab, pipeline e2e-staging #3318
- Issue : N/A — no tracker issue created yet (create and link on filing)

─── Context ─────────────────────────────────────────────

- Test Case : `checkout.spec.ts` > gift card > "applies a gift card to an order in EUR". No TC-CODE-NNN id is recorded in the log; assumed not yet mapped to a formal test case.
- Test Activity : Automated end-to-end regression run in CI, re-run with `--repeat-each=10` on the same commit
- SDLC Phase : System testing of release candidate 4.12.0-rc.2 on staging
- Technique : Scripted end-to-end scenario (use case); repeat execution to measure reproducibility
- Test Data Used : User `buyer.eur@shop.example` (EUR store); product "Desk Lamp" at EUR 49.00; gift card `GC-TEST-0042` with EUR 20.00 balance

─── Reproduction ────────────────────────────────────────

Pre-conditions :

1. Staging is reachable and running build 4.12.0-rc.2 (commit 9f3c2ab)
2. Test user `buyer.eur@shop.example` exists and belongs to the EUR store; cart is empty
3. Gift card `GC-TEST-0042` is active with a EUR 20.00 balance

Steps to Reproduce :

1. Sign in as `buyer.eur@shop.example`
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout
3. Enter gift card `GC-TEST-0042` in the gift card field and press "Apply"
4. Repeat steps 1–3 up to 10 times on the same build (the failure is intermittent)

Expected Result :
The order summary shows "Gift card: -€20.00" and a total of €29.00 (as asserted by the spec; assumed to match the gift card acceptance criteria, which were not supplied).

Actual Result :
A toast "Something went wrong. Please try again." is shown and the total stays €49.00.
Network: `POST /api/checkout/gift-card` → HTTP 500
Response body: `{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}`
Observed on attempts 4, 7 and 9 of 10; attempts 1–3, 5, 6, 8 and 10 showed the expected summary.

- Reproducibility : ✅ Intermittent (3/10 attempts failed, same status and body each time)

─── Evidence ────────────────────────────────────────────

- Attachments : ✅ Log file (CI log of pipeline e2e-staging #3318, including the request/response above). Screenshot / video / trace: assumed available as Playwright's retained artifacts for the three failed attempts; attach them to the tracker issue, do not store a local path. HAR: none captured.
- Link/Path : pipeline e2e-staging #3318 (URL not given in the log)

─── Analysis ────────────────────────────────────────────

- Defect Location : N/A — not yet investigated. The response body places the failure in the server-side handler of `POST /api/checkout/gift-card`, where `.currency` is read on a value that is `undefined` in the failing requests; the file, function and line are not identified.
- Root Cause : N/A — not yet analysed
- Suspicions :
  - Unconfirmed: the developer on the team channel suspects the currency service cache ("probably the currency service cache again, it was flaky last sprint too").
  - Unconfirmed: the error text suggests that whichever object is expected to carry a `currency` (store, cart or gift card lookup result) is missing on the failing requests, while the same input succeeds on other attempts. Raised by QA from the response body.
  - Note for triage: the server returned a 500 with a TypeError, so this is a product defect, not test flakiness. Do not quarantine the spec under the flaky-test protocol on this evidence.

─── Resolution ──────────────────────────────────────────

- Fix Applied : N/A — not yet fixed
- Fixed In Build : N/A — not yet fixed
- Verified By : N/A — not yet fixed
- Verified On : N/A — not yet fixed

─── Linked Items ────────────────────────────────────────

- Issue / Bug : N/A — not yet created
- Related Defects : N/A — none found. The developer's remark that this "was flaky last sprint too" suggests an earlier record may exist; search the tracker for `gift-card` / `currency` 500s from the previous sprint and link it here if found.
- Test Case : `checkout.spec.ts` > gift card > "applies a gift card to an order in EUR"
─────────────────────────────────────────────────────────

**Retest criteria (once a fix is delivered)**

1. Confirmation test: rerun `checkout.spec.ts` > gift card > "applies a gift card to an order in EUR" against the fixed build with `--repeat-each=20` or more. Pass only if 0 failures and no 500 from `POST /api/checkout/gift-card`; a lower failure rate is not a pass.
2. Regression check around the fix: gift card apply in the other store currencies, a gift card whose currency differs from the order currency, applying and removing a gift card, a gift card with a balance larger than the order total, and the checkout totals after each.
3. If the currency service cache is confirmed as the location, also cover a cold cache (first request after a deploy or cache flush) and an expired cache entry.

**Secondary observation (not part of this defect)**
The 500 response body exposes an internal `TypeError` message to the client. Consider a separate Low/Security defect for error-message disclosure on `/api/checkout/gift-card`.

**Assumptions made**

- Project code `CHK` and defect number 001; adjust to the tracker's scheme.
- Reporter, assignee and tracker issue were not in the log and are placeholders.
- The expected result is taken from the spec's assertion; the acceptance criteria were not supplied.
- Playwright failure artifacts (screenshot, trace) are assumed retained by the pipeline; none were listed in the log.
- Step 0 (system info) and Step 1 (evidence capture) were not run locally: the failure occurred on the CI runner, the log already records the runtime and build, and you asked for no files to be created.

Rules not applied because they were not loaded and no `qa-rules` skill is installed: `context-discovery` (tracker schema derivation) and `test-evidence` (evidence capture conventions).
