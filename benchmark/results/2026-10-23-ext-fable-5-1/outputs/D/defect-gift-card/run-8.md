**DEFECT REPORT**

- **Defect ID**: DR-CHK-001
- **Title**: Checkout – Gift card apply fails with HTTP 500 `TypeError: Cannot read properties of undefined (reading 'currency')` when a EUR gift card is applied to a EUR order (intermittent, 3/10)
- **Reported By**: QA Engineer (assumption: author of this report; the failure was recorded by pipeline e2e-staging #3318)
- **Reporter Role**: QA Engineer, product QA team
- **Date Reported**: 2026-10-24 (failure observed in CI on 2026-10-14 06:12 UTC)
- **Assigned To**: Checkout team (assumption: owner of `/api/checkout/*`)

**─── Classification ───**

- **Severity**: ✅ High. A payment step in checkout fails on roughly a third of attempts with the same data and the order total is left unreduced. The only workaround is a blind retry prompted by a generic toast, which the customer has no reason to trust. Not Critical: checkout itself still completes without the gift card, and no data loss was observed.
- **Priority**: ✅ P1 (Immediate), proposed for PO confirmation. The build is release candidate 4.12.0-rc.2 and the failure sits on the money path of checkout.
- **Status**: ✅ New
- **Type**: ✅ Functional / Integration (server-side error on a checkout API call)

**─── Environment ───**

- **Application**: shop storefront 4.12.0-rc.2 (assumption: product name taken from the base URL)
- **Environment**: ✅ Staging (https://staging.shop.example)
- **OS / Browser**: Ubuntu 22.04 CI runner / Chromium 129.0.6668.29 via Playwright 1.48.1
- **Build / Commit**: 4.12.0-rc.2, commit 9f3c2ab, pipeline e2e-staging #3318
- **Issue**: N/A — no tracker issue exists yet; create one and link it here on filing

**─── Context ───**

- **Test Case**: `checkout.spec.ts` > gift card > applies a gift card to an order in EUR. N/A for a TC-CODE-NNN ID — the spec is not mapped to a formal test case; assumption: it covers the gift-card acceptance criterion of the checkout feature
- **Test Activity**: Automated end-to-end regression run in CI, executed with `--repeat-each=10` on a single commit
- **SDLC Phase**: System testing of release candidate 4.12.0-rc.2 on staging
- **Technique**: Scripted E2E, valid equivalence partition (gift card balance lower than order total, same currency as the store)
- **Test Data Used**: user `buyer.eur@shop.example` (EUR store); product "Desk Lamp" at EUR 49.00; gift card `GC-TEST-0042` with balance EUR 20.00

**─── Reproduction ───**

Pre-conditions:

1. Staging deployed at commit 9f3c2ab (build 4.12.0-rc.2)
2. Test user `buyer.eur@shop.example` exists in the EUR store and has an empty cart
3. Gift card `GC-TEST-0042` is active with a balance of EUR 20.00 (assumption: the card is reset between attempts, since passing attempts used the same card)

Steps to Reproduce:

1. Sign in as `buyer.eur@shop.example`
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout
3. Enter gift card `GC-TEST-0042` and press "Apply"
4. Repeat steps 1–3 up to 10 times on the same build; the failure is intermittent

Expected Result:
The order summary shows "Gift card: -€20.00" and a total of €29.00 (quoted from the spec's assertion, which stands in for the acceptance criterion).

Actual Result:
A toast "Something went wrong. Please try again." is shown and the total stays €49.00.

Network:

```text
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

Reproducibility: ✅ Intermittent (3/10 attempts: 4, 7 and 9 failed with the identical status and body; the 7 passing attempts showed the expected summary). The failing requests carry the same user, cart and card as the passing ones, so the variation is on the server side, not in the test data. Not yet reproduced by hand.

**─── Evidence ───**

- **Attachments**: ✅ Log file (CI output of pipeline e2e-staging #3318, quoted above). Screenshot / video / trace: assumption that Playwright retained its failure artifacts for attempts 4, 7 and 9; attach them to the tracker issue on filing. HAR: none captured.
- **Link/Path**: pipeline e2e-staging #3318, run of 2026-10-14 06:12 UTC (pipeline URL not present in the log; add it on filing)

**─── Analysis ───**

- **Defect Location**: Server-side handler of `POST /api/checkout/gift-card`. The handler reads `.currency` on a value that is `undefined` at request time. Exact file and line not yet identified.
- **Root Cause**: N/A — not yet analysed
- **Suspicions**:
  - Unconfirmed: the developer on the team channel suspects the currency service cache ("probably the currency service cache again, it was flaky last sprint too").
  - Unconfirmed (reporter): the intermittency with identical input points to a value that is sometimes not yet populated when the handler runs (a cache miss, a race or a cold dependency) rather than to the gift card or the order data. Either way the handler lacks a guard for the missing object, which turns the condition into an unhandled 500.
  - Observation, secondary: the response body exposes the raw server exception text to the client. Consider filing this separately as a Security/error-handling defect.

**─── Resolution ───**

- **Fix Applied**: N/A — not yet fixed
- **Fixed In Build**: N/A — not yet fixed
- **Verified By**: N/A — not yet fixed
- **Verified On**: N/A — not yet fixed

Retest criteria (for the confirmation test once a fix lands):

1. Rerun `checkout.spec.ts` > gift card > applies a gift card to an order in EUR with `--repeat-each=20` on the fix build. Pass condition: 20/20 pass and every `POST /api/checkout/gift-card` returns 200.
2. Repeat the run against a freshly restarted currency service (cold cache) to cover the suspected condition.
3. Regression around the fix: gift card in a non-EUR store (USD), gift card balance greater than the order total, zero-balance and invalid card codes, removing an applied gift card, and the error response for a genuine failure (should be a structured message, not an exception string).

**─── Linked Items ───**

- **Issue / Bug**: N/A — to be created on filing
- **Related Defects**: N/A — none found. Unconfirmed: the developer refers to a similar flakiness last sprint; no defect ID was given, so link it if one exists.
- **Test Case**: `checkout.spec.ts` > gift card > applies a gift card to an order in EUR

**Assumptions and notes**

- Project code CHK, reporter, assignee and product name are assumptions, marked above.
- This is a product defect, not test flakiness: the failure is a server 500 with the same input that passes on other attempts. Do not quarantine the test under the flaky-test protocol.
- Step 0 (system info) and Step 1 (evidence capture) were not executed. The failure occurred on a CI runner, not locally, and no files were to be created. Environment data comes from the CI log.
- Rules not applied: `context-discovery` and `test-evidence` are not in context and no `qa-rules` skill is installed. The working directory contains no tracker schema or QA evidence folder, so the package template was used as is.
