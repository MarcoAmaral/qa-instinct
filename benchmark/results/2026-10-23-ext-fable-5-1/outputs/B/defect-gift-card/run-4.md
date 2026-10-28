# Defect Report: Intermittent 500 on gift card apply in EUR checkout (TypeError reading 'currency')

**ID:** to be assigned
**Reported:** 2026-10-24
**Reporter:** <account email, redacted> (QA)
**Build:** 4.12.0-rc.2, commit 9f3c2ab
**Environment:** staging, https://staging.shop.example
**Source:** pipeline e2e-staging #3318, run 2026-10-14 06:12 UTC
**Component:** Checkout API, gift card endpoint
**Severity:** High. Breaks a revenue path in checkout for roughly a third of attempts and blocks the RC pipeline intermittently.
**Priority:** P1 for the 4.12.0 release. Recommend treating as a release blocker until root cause is confirmed.
**Reproducibility:** Intermittent, 3 of 10 on the same commit.

## Summary

Applying gift card GC-TEST-0042 to a EUR order intermittently fails. The endpoint `POST /api/checkout/gift-card` returns HTTP 500 with a server-side TypeError, the UI shows a generic error toast, and the order total is not reduced. The same steps on the same build and the same card succeed in 7 of 10 attempts, so this is a non-deterministic server fault, not a test-data or assertion problem.

## Steps to reproduce

1. Sign in as `buyer.eur@shop.example` on the EUR store.
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. In the gift card field enter `GC-TEST-0042` (balance EUR 20.00) and press "Apply".
4. Repeat steps 1 to 3 at least 10 times. The CI run used `--repeat-each=10` on `checkout.spec.ts > gift card > applies a gift card to an order in EUR`.

## Expected result

The order summary shows "Gift card: -€20.00" and the total shows €29.00. The API responds with a 2xx status.

## Actual result

On attempts 4, 7 and 9 of 10:

- The UI shows the toast "Something went wrong. Please try again."
- The total stays at €49.00 and no gift card line appears.
- The API responds with HTTP 500 and this body:

```
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

Attempts 1 to 3, 5, 6, 8 and 10 passed with the expected summary.

## Observations and analysis

- **Server-side fault, not client.** The failure is a 500 with an unhandled TypeError. The client behaved correctly given the response.
- **Something the handler dereferences is intermittently undefined.** The error says `.currency` was read on `undefined`. Candidates include the gift card record, the cart or order object, the store or locale context, or a response from a downstream currency or pricing service. The log does not identify which. A server stack trace for the failing requests is needed.
- **State recovers between attempts.** Attempt 4 failed, attempts 5 and 6 passed, then 7 failed. Whatever is undefined is transient, which points to a race, cache miss, timeout, or load-balanced instance with different state, rather than corrupted persistent data.
- **The failure rate is high enough to be user-facing.** Three in ten is not a rare edge case. Real customers on this build would hit it.
- **Developer hypothesis is unverified.** The team channel suggests "the currency service cache again, flaky last sprint". This is plausible and should be the first thing checked, but it is a guess. If a known flaky cache was left unfixed, that prior issue should be linked and this report should not be closed as a duplicate without a confirmed shared root cause.
- **Secondary issue: error detail leaks to the client.** The response body exposes the raw exception message. That is an information disclosure and inconsistent error contract. Recommend a separate low-severity ticket.
- **Secondary issue: generic toast.** "Something went wrong. Please try again." gives the customer no indication whether the card was consumed or whether retrying is safe. Recommend a UX follow-up once the main fault is fixed.

## Impact

- Customers on the EUR store cannot reliably redeem gift cards at checkout. Some will abandon the purchase.
- Risk that a failed apply leaves partial state, for example a reserved or debited balance with no discount on the order. Not observed in this run but not ruled out.
- The e2e-staging pipeline for 4.12.0-rc.2 is red intermittently, which hides other regressions and erodes trust in the suite.

## Assumptions

- The three failures share one root cause, since status, body and user-visible behavior were identical.
- The test ran with a single worker and no other test used `GC-TEST-0042` or the same account concurrently. If the suite runs in parallel, a shared-fixture race becomes a stronger candidate and should be checked first.
- The gift card balance was not changed by the failed attempts, since later attempts passed with the same card. This should be confirmed directly in the backend.
- The problem is not specific to EUR. Only the EUR test was reported, so other currencies and the USD store are untested here.
- The issue is new or newly visible in 4.12.0-rc.2. No earlier passing run on the same spec was included in the log to confirm a regression.

## Requested information from engineering

1. Server logs with full stack trace and request ID for the three 500 responses in run #3318, including which instance served each request.
2. Confirmation of which object was undefined in the failing handler.
3. Whether the currency service cache incident from last sprint has a ticket, and whether it was closed as fixed.
4. Whether gift card balance or reservation was touched by the failed requests.

## Suggested next steps

- Reproduce locally or on staging with `--repeat-each=50` and capture server logs alongside the Playwright trace to correlate failures with backend events.
- Run the same spec against a non-EUR store to confirm or rule out currency-specific behavior.
- Add a guard and a meaningful error in the handler so a missing currency context returns a controlled 4xx or 503 with a retry hint instead of a 500.
- Add a server-side metric or alert on 5xx responses from `POST /api/checkout/gift-card`.
- Until a fix is confirmed, do not quarantine or add retries to the test. The test is correctly reporting a real intermittent production-path failure.

## Attachments

- CI log excerpt from e2e-staging #3318 (quoted above).
- Playwright trace and HAR for attempts 4, 7 and 9: not included in the log provided. Assumed to be available as run artifacts and should be attached by whoever has pipeline access.
