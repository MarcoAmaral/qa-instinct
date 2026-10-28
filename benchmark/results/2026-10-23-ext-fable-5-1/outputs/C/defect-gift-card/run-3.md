# Applying a EUR gift card at checkout intermittently fails with a 500 error

**Summary:** On build 4.12.0-rc.2, applying gift card GC-TEST-0042 to a EUR order fails about 3 times in 10. The checkout page shows a generic error toast and the total does not change. The gift card endpoint returns HTTP 500 with a TypeError about a missing `currency` property.

## Details

| Field | Value |
| --- | --- |
| Build | 4.12.0-rc.2 (commit 9f3c2ab) |
| Environment | Staging, https://staging.shop.example |
| Pipeline | e2e-staging #3318, 2026-10-14 06:12 UTC |
| Test | checkout.spec.ts > gift card > applies a gift card to an order in EUR |
| Browser and tooling | Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04 runner |
| Frequency | 3 of 10 attempts failed (attempts 4, 7 and 9) with `--repeat-each=10` on the same commit |
| Severity | High: a customer cannot apply a gift card and gets no usable error message |
| Priority | Blocks release candidate sign-off (assumed, see Assumptions) |
| Reporter | <account email, redacted> |

## Steps to reproduce

1. Sign in to the EUR store as the test user buyer.eur@shop.example.
2. Add **Desk Lamp** (EUR 49.00) to the cart and open checkout.
3. Enter gift card GC-TEST-0042 (balance EUR 20.00) and select **Apply**.
4. Repeat steps 1 to 3 up to 10 times. The failure is intermittent.

## Expected result

The order summary shows **Gift card: -€20.00** and a total of **€29.00**.

## Actual result

A toast appears with the text **Something went wrong. Please try again.** The total stays at €49.00. No gift card line is added to the summary.

## Evidence

Network request during the failing attempts:

```text
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

All 3 failing attempts returned the same status and body. All 7 passing attempts showed the expected summary, so the test steps and test data are valid on this build.

## Observations

- **The failure is server-side.** The browser receives a 500 before any UI update, so the client is behaving correctly by showing the generic toast.
- **The error message leaks internals.** The response body contains a raw JavaScript TypeError. Even after the root cause is fixed, the API should return a structured error.
- **The failure is intermittent on a single commit.** This points to state that varies between requests, such as a cache, a timing condition or a dependency response, rather than a code path that always fails.
- **Unverified hypothesis.** A developer wrote on the team channel: "probably the currency service cache again, it was flaky last sprint too." This has not been confirmed on this build and is recorded here as a lead, not a cause. The report does not assign a root cause.

## Suggested next steps for triage

1. Pull the server logs for `POST /api/checkout/gift-card` around 2026-10-14 06:12 UTC and find the stack trace for the TypeError.
2. Check whether the object missing `currency` comes from the currency service, the cart, or the gift card record, and whether that lookup can return undefined on a cache miss or timeout.
3. Add a guard that returns a 4xx or a retryable error with a clear message when currency data is unavailable, so a customer sees an actionable message instead of a generic toast.
4. Link this report to the flakiness ticket from last sprint, if one exists, to confirm or rule out the same cause.

## Assumptions

- No other spec in this run failed. The log only shows this test, so the scope is limited to gift card application in EUR until proven otherwise.
- The test is treated as a release blocker because a 30 percent failure rate on a payment-adjacent action is not acceptable for a release candidate. Adjust the priority if the gift card feature is not in scope for 4.12.0.
- The test user, product and gift card are stable fixtures that are reset between attempts. If the gift card balance is consumed by passing attempts, the failure pattern would look different, so this is assumed not to be the case.
- The same behaviour would affect a real customer, since the failing call is the production checkout endpoint on staging, not a test-only route.
- No retry was attempted on the failing requests. If the test or the client retries automatically, the real failure rate per request may be higher than 3 in 10.
