# Defect Report: Intermittent 500 on gift card apply (EUR checkout)

| Field | Value |
|---|---|
| Title | `POST /api/checkout/gift-card` intermittently returns 500 `TypeError ... reading 'currency'`; gift card not applied |
| Build | 4.12.0-rc.2 (commit 9f3c2ab) |
| Environment | staging (https://staging.shop.example), EUR store |
| Pipeline | e2e-staging #3318, 2026-10-14 06:12 UTC |
| Client | Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04 runner |
| Component | Checkout / Gift card API |
| Severity | Major (core checkout function fails; no data corruption observed) |
| Priority | High (release candidate; affects revenue-path) |
| Reproducibility | Intermittent: 3 of 10 attempts failed on the same commit (30%) |
| Status | New |

## Summary

Applying a valid gift card at checkout in the EUR store intermittently fails. The backend responds with HTTP 500 and an unhandled `TypeError` complaining that `currency` is read from `undefined`. The UI shows a generic error toast and the order total is left unchanged. The same steps succeed on other attempts with no change in input, build, or environment.

## Steps to reproduce

1. Sign in on staging as `buyer.eur@shop.example` (EUR store).
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. Enter gift card `GC-TEST-0042` (balance EUR 20.00) and press "Apply".
4. Repeat steps 1 to 3 several times (the CI run used `--repeat-each=10`).

Spec: `checkout.spec.ts > gift card > applies a gift card to an order in EUR`

## Expected result

- Order summary shows a line "Gift card: -€20.00".
- Order total is €29.00.
- `POST /api/checkout/gift-card` returns a success status with the updated totals.

## Actual result

- Toast: "Something went wrong. Please try again."
- Order total remains €49.00. No gift card line is shown.
- Network: `POST /api/checkout/gift-card` returns **500**.
- Response body:

```json
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

Failures occurred on attempts 4, 7 and 9 with identical status and body. Attempts 1, 2, 3, 5, 6, 8 and 10 passed with the expected summary.

## Evidence

- CI log for e2e-staging #3318 (excerpt reproduced above).
- Spec file: `checkout.spec.ts`, test "applies a gift card to an order in EUR".
- Assumed available from the runner but not attached to the log: Playwright trace, screenshot and HAR for the failing attempts. Please attach these to the ticket from the pipeline artifacts.

## Analysis

- **Server-side defect, not a test flake.** The failing response is a 500 with an unhandled exception, so the backend is throwing rather than the test timing out or mis-selecting an element. A retry-based "fix" in the test would hide the bug.
- **Nondeterministic with fixed inputs.** The same user, cart, card and commit succeed 70% of the time. This points to state that varies between requests: a cache that is sometimes cold or expired, a race between requests that run during checkout load, a connection-pool or replica that returns an incomplete record, or a load-balanced instance with different state.
- **The exception shape is informative.** The code reads `.currency` on an object that is sometimes undefined. Likely candidates are the cart/order record, the store or locale record, or the gift card record as returned by a currency or pricing lookup. The handler has no guard for that missing object.
- **Developer hypothesis is unverified.** A team member suggested on the channel that this is "probably the currency service cache again" and that it was flaky last sprint. That is plausible and consistent with the symptom, but it has not been confirmed with server logs. It should be treated as a lead, not a root cause. If this is a recurrence, the earlier ticket should be linked and the previous fix reviewed for why it did not hold.
- **Secondary issue: error detail leaks to the client.** The response body contains the raw exception message. The API should return a generic error body and log the stack server-side. This is a separate, lower-severity finding and can be split into its own ticket.

## Impact

- Customers in the EUR store intermittently cannot apply a gift card. On a failure they see a generic error and may abandon the purchase or retry and double-apply if the server-side state is partially updated (not observed, but not ruled out).
- The failure rate of roughly 30% on a release candidate blocks a reliable 4.12.0 sign-off for checkout.
- The e2e suite will remain red or flaky until the server defect is fixed, reducing trust in the pipeline.

## Scope and open questions

- Not yet known whether other currencies (USD, GBP) are affected. The failing test is EUR-only.
- Not yet known whether the failure is specific to gift cards or also affects promo codes and other endpoints that resolve currency.
- Not yet known whether a client retry succeeds immediately or whether a failing request keeps failing for a window of time. This would distinguish a cache-expiry race from a bad instance.
- Not yet known whether any partial state is written before the exception (e.g. gift card balance reserved but not applied).

## Assumptions made

- The 500 originates from the application server for the gift-card endpoint, not from a gateway or proxy, because the body is an application-level `TypeError`.
- The test data (user, product, gift card balance) is stable across attempts and was not modified by a parallel run. The log shows the same balance on every attempt.
- The seven passing attempts prove the test logic and selectors are correct, so the failure is not a test-authoring error.
- The developer's cache comment refers to a prior incident with a ticket; the ID was not provided.
- Playwright traces and server logs for the failing attempts exist in the runner artifacts even though they were not included in the log excerpt.

## Recommended next steps

1. **Backend:** pull server logs for staging between 06:12 and the end of the run, filtered to `/api/checkout/gift-card` with status 500, and capture the full stack trace to identify which object is undefined.
2. **Backend:** add a guard and a meaningful 4xx/5xx response for the missing object, and fix the underlying source (cache miss handling, race, or incomplete lookup).
3. **Backend:** stop returning raw exception text in API error bodies.
4. **QA:** once a fix is deployed, rerun the spec with `--repeat-each=50` and confirm zero 500s. Extend coverage to USD and GBP stores and to the promo-code path.
5. **QA:** add an API-level test that applies a gift card immediately after a cold start or cache flush to reproduce the suspected condition deterministically.
6. **Process:** link the prior "flaky last sprint" ticket if it exists and record why the earlier mitigation did not prevent this recurrence.

## Acceptance criteria for closure

- 50 consecutive runs of the EUR gift card test pass on the fixed build with no 500 responses.
- `POST /api/checkout/gift-card` never returns a raw exception message in the response body.
- Root cause is documented in the ticket, not only the symptom fix.
