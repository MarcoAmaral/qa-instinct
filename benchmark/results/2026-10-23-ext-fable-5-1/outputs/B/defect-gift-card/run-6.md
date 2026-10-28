# Defect Report: Intermittent 500 on gift card apply in EUR checkout (TypeError reading 'currency')

**ID:** DR-2026-10-14-001 (assumed; replace with tracker ID)
**Reported:** 2026-10-14
**Reporter:** QA
**Build:** 4.12.0-rc.2 (commit 9f3c2ab)
**Environment:** staging, `https://staging.shop.example`
**Pipeline:** e2e-staging #3318, 2026-10-14 06:12 UTC
**Component:** Checkout / Gift card API (`POST /api/checkout/gift-card`)
**Severity:** High. A customer-facing payment step fails and the order total is not adjusted. Money is involved and the failure is silent on the server side from the customer's point of view.
**Priority:** P1 for the 4.12.0 release. This is a release-candidate build and the failure is in a core purchase flow.
**Status:** New
**Blocks release:** Recommended yes until root cause is identified. See "Release recommendation" below.

## Summary

Applying a valid gift card during checkout in the EUR store intermittently fails with an HTTP 500. The response body contains an unhandled `TypeError: Cannot read properties of undefined (reading 'currency')`. The UI shows a generic error toast and the order total is not reduced. On the same commit, the test failed 3 out of 10 runs (30%) with the identical status and body each time. This is not a test-side flake. Each failure is a real server error on a real request.

## Steps to reproduce

1. Sign in to the EUR store as `buyer.eur@shop.example`.
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. Enter gift card `GC-TEST-0042` (balance EUR 20.00) and press "Apply".
4. Repeat steps 1 to 3 (or run the spec with `--repeat-each=10`).

Automated reproduction: `checkout.spec.ts > gift card > applies a gift card to an order in EUR`, run with `--repeat-each=10` against commit 9f3c2ab.

## Expected result

- Order summary shows "Gift card: -€20.00".
- Total shows €29.00.
- `POST /api/checkout/gift-card` returns a success status.

## Actual result

- Toast: "Something went wrong. Please try again."
- Total remains €49.00. Gift card line is not shown.
- `POST /api/checkout/gift-card` returns **500**.
- Response body:

```json
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

## Frequency

| Attempts | Passed | Failed | Failing attempts |
|---|---|---|---|
| 10 | 7 | 3 | 4, 7, 9 |

All three failures have the same status code and the same response body. The passing attempts rendered the correct summary. Failures do not cluster at the start or the end of the run, so warm-up or teardown effects are unlikely to be the sole explanation.

## Evidence

- CI log for e2e-staging #3318 (attempt 4 shown in full; attempts 7 and 9 recorded with matching status and body).
- Playwright trace and network HAR for the failing attempts should be attached from the run artifacts (assumed to be retained by the pipeline; if not, re-run with `--trace on` to capture).

## Analysis

**Where the failure is.** The error is produced by the server, not the browser or the test. The test receives a 500 with an unhandled JavaScript TypeError in the body. The UI toast is the client correctly surfacing a backend failure. Any fix must be on the server side of `POST /api/checkout/gift-card` or one of its dependencies.

**What the error says.** Some object the handler expects to be populated is `undefined` at the moment `.currency` is read. Likely candidates, in no particular order:

- The store or locale context for the request (EUR store resolution returning nothing).
- The gift card record (lookup returning `undefined` rather than a card object).
- The cart or order object (currency read from an order that has not been fully loaded).
- A response from an upstream currency or pricing service that is missing or malformed.

**On the developer's hypothesis.** The note on the team channel ("probably the currency service cache again, it was flaky last sprint too") is plausible and consistent with the symptom, but it is unverified. It should be treated as a lead, not a diagnosis, for three reasons:

1. No server-side log, trace, or cache metric from this run has been checked yet.
2. "It was flaky last sprint too" means the same or a similar failure was already observed and not resolved. That is evidence of a recurring defect, not evidence that it is benign.
3. Even if a cache miss or stale cache entry is the trigger, the handler still crashes on an `undefined` value instead of handling the missing data. That is a defect in the handler regardless of the cache behaviour.

I recommend the report is not closed as "flaky test" or "known cache issue" without a root cause and a fix or a documented mitigation.

**Why this is not a test flake.** The test assertions are deterministic and the passing attempts show the correct output. The failing attempts fail at the network layer with an identical server error. Retrying the spec would hide a 30% server failure rate on a purchase step.

## Impact

- **Customer:** In roughly 3 of 10 attempts, a customer with a valid gift card cannot apply it. The message gives no useful guidance. A retry may succeed, which will look like random behaviour to the customer and will generate support contacts.
- **Business:** Gift card redemptions fail at checkout. Orders may be abandoned or completed at full price without the gift card, leading to refund and support cost.
- **Security / hygiene (secondary):** The raw TypeError message is returned to the client in the response body. Internal error details should not be exposed on a public API. This should be fixed alongside the main defect or tracked separately. Assumed to be lower priority than the functional failure.

## Scope not yet tested (assumptions and open questions)

The following were not covered by this run. I am assuming none of them are known to be affected, and each is listed as a follow-up check:

- Other currencies and stores (USD, GBP, etc.). Unknown whether the failure is EUR-specific or affects all stores.
- Other gift cards. Unknown whether `GC-TEST-0042` specifically is involved.
- Other checkout operations that read currency (promo codes, shipping quotes, tax). If a shared currency lookup is the cause, these may fail at a similar rate.
- Production. Unknown whether the same failure rate is present in production. If the currency cache hypothesis is correct and the same cache configuration is live, it may be.
- Earlier builds. Unknown whether 4.12.0-rc.1 or the last released build shows the same rate. A bisect would establish whether this is a regression in rc.2.

## Suggested investigation steps for the assignee

1. Pull server logs for `POST /api/checkout/gift-card` around 06:12 UTC on 2026-10-14 for the three failing requests and capture the full stack trace. Identify the exact line reading `.currency`.
2. Correlate with currency service and cache metrics (hit/miss, eviction, upstream errors, timeouts) for the same window.
3. Check whether the handler has a guard for a missing store, cart, gift card, or currency lookup result. If not, add one so that a missing dependency returns a controlled 4xx or 503 with a retry hint instead of a 500.
4. Run the spec with `--repeat-each=50` against rc.2 and the previous build to confirm the rate and determine whether this is a regression.
5. Run the equivalent test in at least one non-EUR store and with at least one other gift card.
6. Confirm the response body no longer exposes internal error text.

## Release recommendation

Do not promote 4.12.0-rc.2 while this is open. A 30% failure rate on gift card redemption in a release candidate is not acceptable for a core checkout flow. If a fix cannot land in time, the release owner should make an explicit, recorded decision with a mitigation (for example, retry logic in the handler or client, or a feature flag on gift card redemption).

## Acceptance criteria for closure

- Root cause identified and documented, not inferred.
- Fix merged and `checkout.spec.ts > gift card > applies a gift card to an order in EUR` passes 50/50 on `--repeat-each=50` against the fixed build.
- Equivalent spec passes at the same rate in at least one non-EUR store.
- Internal error text no longer appears in the API response body.
- If the currency cache is the trigger, a regression test or monitor exists for the cache failure mode so that "flaky last sprint" does not recur as "flaky next sprint".
