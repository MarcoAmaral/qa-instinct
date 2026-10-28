# Defect Report DR-CHECKOUT-001

- **Defect ID**: DR-CHECKOUT-001
- **Title**: Checkout – Gift card apply returns HTTP 500 (`TypeError ... reading 'currency'`) when a EUR gift card is applied to a EUR order (intermittent, 3/10)
- **Reported By**: QA (from CI pipeline e2e-staging #3318)
- **Reporter Role**: QA Engineer, product QA team
- **Date Reported**: 2026-10-24 (failure observed 2026-10-14 06:12 UTC)
- **Assigned To**: Checkout team (owner of `/api/checkout/gift-card`)

## Classification

- **Severity**: High. The gift card step of checkout fails on 3 of 10 identical attempts with an unhandled server error. The only workaround is to retry, and a retry can fail again at the same rate, so a customer can be unable to redeem a gift card and may abandon the order. Money handling in the release candidate is affected.
- **Priority**: P2 (High), proposed for PO confirmation. The failure is in the 4.12.0-rc.2 release candidate on staging and should be fixed in the current sprint before the candidate is promoted.
- **Status**: New
- **Type**: Functional, Integration (server-side failure of the gift card API; the UI only surfaces it)

## Environment

- **Application**: shop storefront 4.12.0-rc.2
- **Environment**: Staging (https://staging.shop.example)
- **OS / Browser**: Ubuntu 22.04 CI runner / Chromium 129.0.6668.29 via Playwright 1.48.1
- **Build / Commit**: 4.12.0-rc.2, commit 9f3c2ab, pipeline e2e-staging #3318
- **Issue**: N/A — tracker issue not yet created; create and link on filing

## Context

- **Test Case**: `checkout.spec.ts` > gift card > "applies a gift card to an order in EUR" (no TC-CODE-NNN mapped to this spec; N/A until the spec is traced to a test case)
- **Test Activity**: Automated end-to-end regression run in CI, executed with `--repeat-each=10` on the same commit
- **SDLC Phase**: System testing of release candidate 4.12.0-rc.2 on staging
- **Technique**: Scripted end-to-end scenario; partial redemption partition (gift card balance lower than order total); repeat run to establish reproducibility
- **Test Data Used**: User `buyer.eur@shop.example` (EUR store); product "Desk Lamp" at EUR 49.00; gift card `GC-TEST-0042` with balance EUR 20.00

## Reproduction

**Pre-conditions**

1. Staging environment at https://staging.shop.example is up and the EUR store is enabled.
2. Test user `buyer.eur@shop.example` exists and can sign in; cart is empty.
3. Gift card `GC-TEST-0042` is active with a balance of EUR 20.00.

**Steps to Reproduce**

1. Sign in as `buyer.eur@shop.example`.
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. Enter gift card `GC-TEST-0042` in the gift card field and press "Apply".
4. Observe the order summary and the response of `POST /api/checkout/gift-card`.
5. Repeat steps 1 to 4 ten times; the failure is intermittent.

**Expected Result**

The order summary shows "Gift card: -€20.00" and a total of €29.00. `POST /api/checkout/gift-card` returns a success status (quoted from the spec's assertion; no written acceptance criterion was available).

**Actual Result**

A toast "Something went wrong. Please try again." is shown and the total stays €49.00.

```text
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

The 7 passing attempts showed the expected summary with the same inputs and the same commit.

- **Reproducibility**: Intermittent (3/10 attempts: attempts 4, 7 and 9, same status and body each time)

## Evidence

- **Attachments**: Log file (CI log of pipeline e2e-staging #3318, quoted above). Screenshot and Playwright trace for the failed attempts: assumed to be in the pipeline's failure artifacts, not confirmed; attach to the tracker issue, do not store a local path in the work item.
- **Link/Path**: Pipeline e2e-staging #3318, 2026-10-14 06:12 UTC (artifact URL not provided)

## Analysis

- **Defect Location**: Server-side handler of `POST /api/checkout/gift-card`, at the point that reads `.currency` from an object that is undefined on the failing requests (order, gift card, store or currency lookup result). Exact file and line unknown: the response body carries the message but no stack trace; the server log for the three failing requests should hold it. Secondary observation: the raw `TypeError` text is returned to the client in the response body.
- **Root Cause**: N/A — not yet analysed
- **Suspicions**:
  - Unconfirmed: the developer on the team channel suspects the currency service cache ("probably the currency service cache again, it was flaky last sprint too").
  - Unconfirmed: the reporter notes that identical inputs pass 7 times and fail 3 times on one commit, which points at server-side state or a dependency rather than the input data. This is a product defect that returns a 500, not test flakiness; the spec should not be quarantined as flaky.

## Resolution

- **Fix Applied**: N/A — not yet fixed
- **Fixed In Build**: N/A — not yet fixed
- **Verified By**: N/A — not yet fixed
- **Verified On**: N/A — not yet fixed

## Linked Items

- **Issue / Bug**: N/A — tracker issue not yet created
- **Related Defects**: N/A — none identified. The developer's note refers to a similar failure "last sprint"; search the tracker for a prior gift card or currency service defect and link it if found.
- **Test Case**: `checkout.spec.ts` > gift card > "applies a gift card to an order in EUR"

## Retest Criteria

- **Confirmation test**: On the fixed build, rerun the spec with `--repeat-each=30` on staging. All attempts must show "Gift card: -€20.00" and €29.00, and every `POST /api/checkout/gift-card` must return a success status. Also run once with the currency service cache cold (after a restart or cache flush), since the suspicion names the cache.
- **Regression check**: Gift card applied in a non-EUR store; gift card balance greater than the order total; gift card with zero balance; removing an applied gift card; gift card combined with a promo code; and the error path, which should return a generic error without exposing the exception text.

## Assumptions

- Defect ID prefix CHECKOUT and the assignee are assumed; no tracker schema was given, so the package template is used.
- Reporter and role are assumed to be the QA engineer triaging the CI run.
- Date Reported is today's date; the failure date is recorded separately.
- The Expected Result is taken from the spec's assertion because no acceptance criterion was supplied.
- Failure screenshots and traces are assumed to exist as Playwright artifacts of the pipeline but were not verified.
- Step 0 (system info commands) was not run: the environment comes from the CI log, and the instruction was to reply with the deliverable only without touching files.

Rules not applied: `context-discovery` and `test-evidence` were not in context and no `qa-rules` skill is installed.
