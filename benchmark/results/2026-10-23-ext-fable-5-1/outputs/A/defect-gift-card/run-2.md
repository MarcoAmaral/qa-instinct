# Defect: Gift card apply fails intermittently with 500 (`TypeError ... reading 'currency'`) on EUR checkout

**Pipeline:** e2e-staging #3318, 2026-10-14 06:12 UTC
**Build:** 4.12.0-rc.2 (commit 9f3c2ab)
**Environment:** https://staging.shop.example, Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04 runner
**Spec:** `checkout.spec.ts > gift card > applies a gift card to an order in EUR`
**Severity:** High. Customer-facing payment flow fails with a generic error; the gift card is not applied and the customer is charged full price if they proceed.
**Priority:** Blocker for 4.12.0 release candidate until root cause is confirmed.
**Type:** Backend bug, intermittent (3 of 10 attempts on the same commit).

## Summary

Applying a gift card at checkout in the EUR store intermittently returns HTTP 500 from `POST /api/checkout/gift-card`. The server crashes with `TypeError: Cannot read properties of undefined (reading 'currency')`, and the UI shows a generic "Something went wrong" toast while the order total stays unchanged. The same request succeeds on the majority of attempts, so the failure depends on server state rather than the request payload.

## Steps to reproduce

1. Sign in as `buyer.eur@shop.example` (EUR store).
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. Enter gift card `GC-TEST-0042` (balance EUR 20.00) and press "Apply".
4. Repeat steps 1 to 3 several times. The test runner reproduced it with `--repeat-each=10`.

## Expected result

The order summary shows "Gift card: -€20.00" and a total of €29.00.

## Actual result

- A toast "Something went wrong. Please try again." appears.
- The total stays at €49.00.
- Network: `POST /api/checkout/gift-card` returns 500 with body:

```json
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

## Reproduction rate

| Build | Attempts | Passed | Failed | Failing attempts |
|---|---|---|---|---|
| 4.12.0-rc.2 (9f3c2ab) | 10 | 7 | 3 | 4, 7, 9 |

All three failures had the identical status code and response body. All seven passes showed the correct summary.

## Analysis

**The failure is server-side, not a test or browser issue.** The browser received a 500 with a stack-style error message, so the request reached the API and the handler threw. The UI behaved correctly for a 500. The test assertion is sound.

**The error indicates a missing object, not a wrong value.** The handler dereferences `.currency` on something that is `undefined`. Candidates are the cart, the gift card record, the store or locale context, or a currency lookup result. Because the same request passes most of the time, the missing object is most likely loaded from a cache, a lazily initialized service, or a race between parallel lookups.

**The "currency service cache" hypothesis is plausible but unconfirmed.** A developer noted on the team channel that this was flaky last sprint and may be the currency service cache again. That fits the symptom of an intermittent undefined lookup, but nothing in this log identifies which object is undefined. Treat it as the leading hypothesis, not the diagnosis.

**Internal errors are leaking to the client.** The response body contains the raw exception message. That is a separate hardening issue and should get its own ticket.

## Assumptions

- The ten attempts ran sequentially against a shared staging backend, so a shared cache or service state could differ between attempts.
- `GC-TEST-0042` is a seeded EUR gift card with sufficient balance on every attempt. The passing runs confirm this; the failures did not reach the balance check.
- No deploy or data reset occurred between attempts, since all ran against the same commit in one pipeline run.
- Server-side logs for the pipeline window were not included in the CI output.

## Information needed to confirm root cause

- Server logs for `POST /api/checkout/gift-card` around 06:12 UTC on 2026-10-14, including the full stack trace with file and line.
- Whether the currency service cache was cold, expired, or being refreshed when the failing requests arrived.
- Whether last sprint's flaky-test ticket was closed with a fix or just muted. If a fix landed, this is a regression or an incomplete fix.
- Whether the same spec fails in other currency stores, or only EUR.

## Suggested next steps

1. Pull the server stack trace and identify the exact undefined object.
2. If the cache is the cause, make the lookup fail safe: await initialization, fall back to a direct fetch on miss, or return a 4xx with a retryable error instead of crashing.
3. Add a unit or integration test that exercises the gift card endpoint with a cold or expired currency cache.
4. Stop returning raw exception messages in API error bodies.
5. Keep the e2e test unretried in CI so the intermittency remains visible until fixed.

## Attachments

- CI log excerpt (above).
- Playwright trace and screenshot for attempts 4, 7, and 9. Assumed to be available in the pipeline artifacts for run #3318.
