# Defect Report: Intermittent 500 on gift card apply in EUR checkout (TypeError reading 'currency')

| Field | Value |
|---|---|
| ID | Suggested: CHK-GC-EUR-500 (assumption: tracker ID assigned on filing) |
| Title | POST /api/checkout/gift-card intermittently returns 500 "Cannot read properties of undefined (reading 'currency')" when applying a gift card in the EUR store |
| Severity | High. Core checkout function fails for roughly 3 in 10 attempts; customer cannot redeem a gift card and sees a generic error. |
| Priority | P1. Build is a release candidate (4.12.0-rc.2); recommend treating as a release blocker until root cause is confirmed. |
| Status | New |
| Component | Checkout API, gift card endpoint. Suspected dependency: currency service or its cache (unconfirmed). |
| Build | 4.12.0-rc.2, commit 9f3c2ab |
| Environment | staging, https://staging.shop.example, Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04 runner |
| Detected by | CI pipeline e2e-staging #3318, 2026-10-14 06:12 UTC, spec checkout.spec.ts > gift card > applies a gift card to an order in EUR |
| Reproducibility | Intermittent. 3 of 10 attempts failed on the same commit with --repeat-each=10 (attempts 4, 7, 9). Identical status and response body in all three failures. |
| Reporter | <account email, redacted> |

## Summary

Applying a valid gift card during checkout in the EUR store intermittently fails server-side. The API returns HTTP 500 with an unhandled JavaScript TypeError in the response body, the UI shows a generic "Something went wrong" toast, and the order total is not reduced. The failure is deterministic in its signature (same status, same message, same step) but intermittent in occurrence, which points to a state or timing dependency on the server rather than test instability.

## Steps to reproduce

1. Sign in to https://staging.shop.example as buyer.eur@shop.example (EUR store account).
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. In the gift card field, enter GC-TEST-0042 (balance EUR 20.00) and press "Apply".
4. Repeat steps 1 to 3 at least 10 times on a fresh session each time. Observe the network response for POST /api/checkout/gift-card.

## Expected result

- The order summary shows "Gift card: -€20.00" and a total of €29.00.
- POST /api/checkout/gift-card returns a 2xx response.

## Actual result

- A toast reads "Something went wrong. Please try again." The total stays at €49.00.
- POST /api/checkout/gift-card returns 500 with body:

```json
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

- Observed on attempts 4, 7 and 9 of 10. Attempts 1, 2, 3, 5, 6, 8 and 10 passed with the expected summary.

## Evidence

- CI log for e2e-staging #3318 (attempt 4 of 10 shown in full; attempts 7 and 9 recorded with the same status and body).
- Playwright trace, screenshot and HAR for the failed attempts. Assumption: these artifacts are retained by the pipeline; attach them to the ticket on filing.

## Analysis and observations

- **This is a product defect, not a flaky test.** The failing step receives a server-side 500 with a stack-level error message. The test correctly reports what the user would see. Retrying the spec until it passes would hide a real customer-facing failure.
- **The error indicates a missing object on the server.** Some object the handler expects (store context, cart, gift card record, or a currency lookup result) is undefined at the point where `.currency` is read. The handler does not guard against that case.
- **Intermittency suggests a dependency on state or timing.** Three failures spread across a run on one commit is consistent with a cache miss, a cold or evicted cache entry, a race between session setup and the request, or a load-balanced instance that is in a bad state. The developer's remark on the team channel that it is "probably the currency service cache again, it was flaky last sprint too" is a plausible hypothesis but is unverified. It should not be recorded as the root cause until server logs confirm it.
- **The recurrence claim raises a process concern.** If the same behaviour was seen last sprint and no fix landed, the earlier ticket should be linked and this report should supersede or reopen it.

## Secondary defects observed in the same failure

These are separate issues and should be tracked, but they are visible in this reproduction:

1. **Internal error detail leaks to the client.** The response body contains the raw runtime exception text. The API should return a structured error without exposing stack or runtime details.
2. **Unhandled exception returns 500 instead of a controlled error.** A missing currency or store context should be handled explicitly, either with a retry against the upstream service or a specific 4xx/5xx error code and message.
3. **Generic user messaging.** The toast gives the customer no indication of whether the gift card was rejected, whether to retry, or whether their balance was affected.

## Open questions to verify during triage

- Was the gift card balance for GC-TEST-0042 decremented or placed on hold on any of the failed attempts? Assumption: it was not, since the total did not change, but this must be confirmed against the gift card ledger. If a hold was taken without the discount being applied, this is a data integrity issue and the severity should be raised to Critical.
- Does the same failure occur in other currency stores, or only EUR? Assumption: only the EUR spec was repeated in this run.
- Do the server logs for the three failing requests show a currency service timeout, cache miss, or eviction at the matching timestamps? Request IDs for attempts 4, 7 and 9 should be pulled from the HAR.
- Is the failure correlated with a specific backend instance or pod?
- Did the same spec pass cleanly on earlier builds on this pipeline? Assumption: yes, since the test is established and the developer refers to the issue as a return of earlier behaviour, but a bisect against recent commits to the gift card handler and the currency service client is recommended.

## Assumptions made in this report

- The test user and gift card are reset to a clean state between attempts, so the 20.00 balance was available on every attempt.
- All 10 attempts ran against the same staging deployment, with no deploy in between.
- The CI run was the only traffic to the test account at the time, so no concurrent session consumed the gift card.
- Staging data for the EUR store and the currency service was not modified during the run.

## Suggested next steps

1. Pull server logs for POST /api/checkout/gift-card at 2026-10-14 06:12 UTC and correlate the three 500s with currency service calls and cache state.
2. Add a null guard and explicit error handling where `.currency` is read in the gift card handler, and return a structured error response.
3. Confirm the gift card ledger shows no hold or deduction for the failed attempts.
4. Link or reopen the previous sprint's ticket if one exists.
5. Keep the spec non-retried in CI so that recurrence stays visible, and do not mark it as flaky.
