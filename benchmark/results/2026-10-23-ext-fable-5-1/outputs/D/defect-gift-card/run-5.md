**DEFECT REPORT**

- **Defect ID**: DR-CHECKOUT-001 (assumption: no tracker numbering was given; renumber to the tracker's next id when filed)
- **Title**: Checkout gift card – Apply returns HTTP 500 "Cannot read properties of undefined (reading 'currency')" when a gift card is applied to an EUR order
- **Reported By**: Marco (<account email, redacted>)
- **Reporter Role**: QA Analyst, product QA team (assumption)
- **Date Reported**: 2026-10-24 (failure observed in CI on 2026-10-14 06:12 UTC)
- **Assigned To**: Checkout team (assumption: owner of the `/api/checkout/*` endpoints)

**─── Classification ───**

- **Severity**: ✅ High. A server error in the checkout payment path on a release candidate. The customer sees a generic error and the gift card is not applied. The only "workaround" is to retry, which the customer is not told to do and which fails again 3 times in 10.
- **Priority**: ✅ P1 (Immediate), proposed. The build is a release candidate and the defect is in checkout. Final priority is the Product Owner's call. Whether it blocks the release is decided by the release gate, not here.
- **Status**: ✅ New
- **Type**: ✅ Functional (Integration suspected, see Suspicions; not confirmed)

**─── Environment ───**

- **Application**: shop web app, 4.12.0-rc.2
- **Environment**: ✅ Staging (https://staging.shop.example)
- **OS / Browser**: Ubuntu 22.04 CI runner / Chromium 129.0.6668.29, Playwright 1.48.1
- **Build / Commit**: 4.12.0-rc.2, commit 9f3c2ab
- **Issue**: N/A — no tracker issue exists yet; create one and link it when filing

**─── Context ───**

- **Test Case**: N/A — no TC id in the CI log. Automated spec: `checkout.spec.ts` > gift card > "applies a gift card to an order in EUR"
- **Test Activity**: Automated end-to-end regression, pipeline e2e-staging #3318, run with `--repeat-each=10` on a single commit
- **SDLC Phase**: System testing of release candidate 4.12.0-rc.2 on staging, before release (assumption)
- **Technique**: Scripted end-to-end scenario (happy path, partial gift card redemption); repeated execution used to measure the failure rate
- **Test Data Used**: User buyer.eur@shop.example (EUR store); product "Desk Lamp", EUR 49.00; gift card GC-TEST-0042, balance EUR 20.00

**─── Reproduction ───**

Pre-conditions:

1. Staging build 4.12.0-rc.2 (commit 9f3c2ab) deployed and reachable at https://staging.shop.example
2. Test user buyer.eur@shop.example exists in the EUR store and can sign in
3. Gift card GC-TEST-0042 is active with a balance of EUR 20.00 (assumption: the balance is not consumed by the passing attempts, or the fixture restores it between attempts)
4. Cart is empty at the start of each attempt (assumption)

Steps to Reproduce:

1. Sign in as buyer.eur@shop.example
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout
3. Enter gift card GC-TEST-0042 in the gift card field and press "Apply"
4. Observe the order summary and the response of `POST /api/checkout/gift-card`

Expected Result:
The order summary shows "Gift card: -€20.00" and a total of €29.00 (as asserted by the spec). `POST /api/checkout/gift-card` responds with a success status.

Actual Result:
A toast reads "Something went wrong. Please try again." The total stays €49.00 and no gift card line is shown.

```text
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

- **Reproducibility**: ✅ Intermittent (3/10 attempts): attempts 4, 7 and 9 failed with the same status and body; attempts 1–3, 5–6, 8 and 10 passed with the expected summary. Same commit, same runner, same data.

**─── Evidence ───**

- **Attachments**: ✅ Log file (CI log of pipeline e2e-staging #3318, attempts 4, 7, 9). Screenshot / trace / video: assumption that the Playwright runner retained the trace and screenshot on failure; attach them from the pipeline artifacts when filing. ✅ HAR file: not captured; the response body above is from the Playwright network log.
- **Link/Path**: pipeline e2e-staging #3318 (URL not given in the log; add the run URL when filing)

**─── Analysis ───**

- **Defect Location**: Not confirmed. The error is raised server-side in the handler for `POST /api/checkout/gift-card`: something reads `.currency` on a value that is `undefined`. Start there, at the point where the handler resolves the currency of the order, the store or the gift card.
- **Root Cause**: N/A — not yet analysed
- **Suspicions**:
  - Unconfirmed: the developer on the team channel suspects the currency service cache ("probably the currency service cache again, it was flaky last sprint too").
  - Unconfirmed: reporter's reading of the message. The TypeError is consistent with a lookup that sometimes returns nothing (for example a cache miss or an empty response) being dereferenced without a guard. The guard would only mask the symptom; what makes the lookup empty is the thing to find.
  - Note for triage: this is a product defect, not a test-side flake. The same commit returns a server 500 with a stack message, which test timing or ordering cannot produce. Do not quarantine the spec as flaky.

**─── Resolution ───**

- **Fix Applied**: N/A — not yet fixed
- **Fixed In Build**: N/A — not yet fixed
- **Verified By**: N/A — not yet fixed
- **Verified On**: N/A — not yet fixed

**─── Linked Items ───**

- **Issue / Bug**: N/A — tracker issue to be created
- **Related Defects**: N/A — none identified. The developer's "flaky last sprint too" suggests an earlier report may exist; search the tracker for currency service incidents from the previous sprint and link it if found.
- **Test Case**: N/A — see Context; spec `checkout.spec.ts` > gift card > "applies a gift card to an order in EUR"

**Retest criteria (for the Retest state)**

- Confirmation test: run the same spec on the fix build with `--repeat-each=20` on staging. Pass condition: 20/20 pass, every `POST /api/checkout/gift-card` returns a success status, no 500 in the server log for that endpoint during the run.
- Regression check around the fix: gift card applied in a non-EUR store (USD); gift card with balance above the order total; invalid or exhausted gift card (expect a 4xx with a user-facing message, not a 500); gift card combined with a promo code; and any other checkout call that resolves currency (price display, totals, currency conversion), since the suspected area is shared.

**Assumptions and rules not applied**

- Reporter name, role, assigned team, SDLC phase, defect id and cart/balance pre-conditions are assumptions, marked inline.
- The `context-discovery` and `test-evidence` rules could not be loaded: no `qa-rules` skill is installed. Step 0 (system info from the repository) and Step 1 (evidence capture to `docs/qa/evidence/`) were not performed because a reply-only deliverable with no file changes was requested. Environment data is taken from the CI log instead.
