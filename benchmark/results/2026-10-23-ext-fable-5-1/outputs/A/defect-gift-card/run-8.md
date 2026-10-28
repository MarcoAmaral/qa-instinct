# Defect report: Gift card application fails intermittently with 500 on EUR checkout

**Summary:** Applying a gift card at checkout in the EUR store intermittently returns HTTP 500 from `POST /api/checkout/gift-card`, with a `TypeError` about reading `currency` from `undefined`. The customer sees a generic error toast and the discount is not applied.

**Severity:** High. The failure blocks a checkout step on a payment-related endpoint, affects real money, and reproduces in roughly 30% of attempts on the release candidate.

**Priority:** High. Recommend treating as a release blocker for 4.12.0.

## Environment

| Field | Value |
|---|---|
| Build | 4.12.0-rc.2, commit 9f3c2ab |
| Pipeline | e2e-staging #3318, 2026-10-14 06:12 UTC |
| Base URL | https://staging.shop.example |
| Browser | Chromium 129.0.6668.29 |
| Test runner | Playwright 1.48.1 on Ubuntu 22.04 |
| Spec | checkout.spec.ts > gift card > applies a gift card to an order in EUR |

## Steps to reproduce

1. Sign in as `buyer.eur@shop.example` in the EUR store.
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. Enter gift card `GC-TEST-0042` (balance EUR 20.00) and press "Apply".
4. Repeat the scenario several times. The failure is intermittent.

## Expected result

The order summary shows "Gift card: -€20.00" and the total updates to €29.00.

## Actual result

A toast reads "Something went wrong. Please try again." The total stays at €49.00.

Network request and response:

```text
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

## Reproducibility

Intermittent. With `--repeat-each=10` on the same commit, 3 of 10 attempts failed (attempts 4, 7, and 9), all with the same status and response body. The 7 passing attempts showed the correct summary.

## Analysis and notes

- **Server-side failure, not a test flake.** The browser received a 500 with an unhandled `TypeError` in the response body. The test correctly reported what the application returned. Retrying the test would hide a real defect.
- **Error leaks internals.** The raw exception message is returned to the client. The API should return a sanitized error and log the stack trace server-side.
- **Likely cause is unverified.** The developer's comment on the team channel suggested the currency service cache, noting it was flaky last sprint. This is a plausible lead given the `currency` property in the error, but no evidence in the log confirms it. Investigation should start by checking server logs for the stack trace at the failing timestamps and confirming whether the object missing `currency` comes from the cache, the cart, or the gift card record.
- **Scope unknown.** Only the EUR scenario was reported. It is not known whether other currencies or the non-gift-card path are affected.

## Assumptions

- The 7 passing and 3 failing attempts ran against the same staging backend with no deployments in between.
- The gift card `GC-TEST-0042` had a valid EUR 20.00 balance throughout the run and was not consumed by earlier attempts.
- The error message in the response body is the unmodified server exception rather than text added by a client-side handler.
- No related issue is already open for the earlier cache flakiness. If one exists, this report should be linked to it rather than duplicated.

## Suggested next steps

1. Pull server logs and stack traces for the three failing requests to identify the object that was `undefined`.
2. Reproduce against staging with the currency service cache cleared and warmed to test the stated hypothesis.
3. Add a null check and a meaningful error response in the gift card handler, and stop returning raw exception text to clients.
4. Extend the e2e run to other currency stores to establish scope.
5. Keep `--repeat-each=10` on this spec until the failure rate is zero across several builds.

## Attachments

Playwright trace and HAR for attempts 4, 7, and 9 should be attached from the pipeline artifacts. The CI log excerpt above is the source for this report.
