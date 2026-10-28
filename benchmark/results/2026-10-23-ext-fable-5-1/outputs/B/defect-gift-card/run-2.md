# Defect Report: Gift card application intermittently fails with HTTP 500 at EUR checkout

**ID:** DR-CHECKOUT-GC-500 (assumed; replace with tracker ID)
**Reported:** 2026-10-24
**Reporter:** QA (<account email, redacted>)
**Build:** 4.12.0-rc.2, commit 9f3c2ab
**Environment:** staging (https://staging.shop.example), Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04 CI runner
**Source:** pipeline e2e-staging #3318, 2026-10-14 06:12 UTC
**Spec:** `checkout.spec.ts > gift card > applies a gift card to an order in EUR`

## Summary

Applying a gift card at checkout in the EUR store intermittently returns HTTP 500 from `POST /api/checkout/gift-card`. The response body exposes an unhandled server-side `TypeError` (`Cannot read properties of undefined (reading 'currency')`). The UI shows a generic error toast and the order total is not reduced. The failure reproduced in 3 of 10 identical runs on the same commit.

## Severity and priority

| Field | Value | Rationale |
|---|---|---|
| Severity | **High** | Core checkout feature fails for real users roughly 30% of the time. Customers cannot redeem a gift card and may abandon the order or pay full price. |
| Priority | **P1 for 4.12.0** | The build is a release candidate. Recommend treating as a release blocker until root cause is confirmed. |
| Type | Functional defect, intermittent | |
| Area | Checkout / Payments / Gift cards | |

## Steps to reproduce

Precondition: test user `buyer.eur@shop.example` exists in the EUR store, gift card `GC-TEST-0042` has a balance of EUR 20.00, product "Desk Lamp" is priced at EUR 49.00.

1. Sign in as `buyer.eur@shop.example`.
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. Enter gift card code `GC-TEST-0042` and press "Apply".
4. Repeat steps 1 to 3 up to 10 times on a fresh session. The automated reproduction uses `--repeat-each=10`.

## Expected result

- Order summary shows the line "Gift card: -€20.00".
- Order total shows €29.00.
- `POST /api/checkout/gift-card` returns a 2xx response.

## Actual result

- A toast appears: "Something went wrong. Please try again."
- Order total remains €49.00. No gift card line is shown.
- Network: `POST /api/checkout/gift-card` returns **500**.
- Response body:

```
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

## Reproducibility

| Metric | Value |
|---|---|
| Attempts (same commit) | 10 |
| Passed | 7 (attempts 1, 2, 3, 5, 6, 8, 10) |
| Failed | 3 (attempts 4, 7, 9) |
| Failure rate | 30% |

All three failures returned the identical status and response body. All seven passes showed the correct summary. The failure is intermittent, not deterministic, and is not tied to a single cold-start attempt since it occurred mid-run and late-run.

## Analysis and observations

1. **The 500 is a server defect regardless of the trigger.** The handler for `/api/checkout/gift-card` dereferences `.currency` on an object that can be `undefined`. Even if an upstream dependency fails or returns an empty result, the endpoint should return a controlled error (for example 502 or 503 with a retryable message), not an unhandled `TypeError`.
2. **Raw exception text is leaked to the client.** The response body contains the internal error message. This is an information-disclosure issue in its own right and should be fixed independently of the root cause.
3. **The client does not distinguish retryable from permanent failures.** The UI shows a generic toast. This is acceptable as a fallback, but it masks the actual problem for support and for users.
4. **The developer's hypothesis is unverified.** A team-channel note suggests "probably the currency service cache again, it was flaky last sprint too." This is plausible and consistent with the error text, but no evidence from this run confirms it. The report records it as a lead, not as root cause. Points that need confirmation:
   - Whether the currency lookup for the order, the gift card, or the user's store is the one returning `undefined`.
   - Whether the cache miss or stale entry is the cause, or whether the lookup fails for another reason (for example a race between session creation and store resolution, or a missing currency on the test gift card record).
   - Whether the issue affects only EUR or all non-default currencies. Only the EUR spec ran here.
5. **A prior "flaky" classification should not be carried forward.** The error is a reproducible server crash with a clear stack signature. Marking the test as flaky or adding retries would hide a user-facing bug.

## Assumptions

- The `--repeat-each=10` runs executed sequentially against the same staging deployment and no deploy occurred during the run.
- The gift card `GC-TEST-0042` balance was not consumed by earlier attempts. If the test does not reset the balance between attempts, that is a separate test hygiene issue, but it would not produce this particular `TypeError`.
- No server-side logs or request IDs were captured in the CI artifact. Server logs for the three failing timestamps are assumed to be available to the owning team.
- The test user and store configuration are correct, since the same steps passed 7 times.

## Requested actions

1. **Backend owner:** Pull server logs and traces for the three failing requests from run #3318 around 06:12 UTC on 2026-10-14. Identify which object is `undefined` at the `.currency` access.
2. **Backend owner:** Add a null guard and return a controlled, non-500 error with a user-safe message. Stop returning raw exception text in the response body.
3. **Backend owner:** If the currency service cache is confirmed as the cause, fix or instrument it so the failure mode is observable (cache miss metrics, alerting) rather than silently inconsistent.
4. **QA:** Extend the gift card spec to assert the response status and body on the gift card request, so the failure is attributed to the API rather than to the UI toast.
5. **QA:** Run the equivalent gift card scenario in at least one other non-EUR store and in the default store to confirm scope.
6. **Release management:** Hold 4.12.0 until the fix is verified with at least 20 consecutive passing attempts on staging.

## Attachments and references

- CI run: e2e-staging #3318 (2026-10-14 06:12 UTC)
- Playwright trace and HAR for attempts 4, 7, and 9 (assumed retained by the pipeline; attach to the ticket)
- Related history: currency service cache instability noted by development during the previous sprint. No ticket ID provided; link once identified.
