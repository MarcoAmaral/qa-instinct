# Defect: `POST /api/checkout/gift-card` intermittently returns 500 (`TypeError: ... reading 'currency'`) when applying a gift card in the EUR store

**Severity:** High (checkout blocker when it occurs)
**Priority:** P1 for 4.12.0 release
**Status:** Open
**Build:** 4.12.0-rc.2 (commit 9f3c2ab)
**Environment:** staging (`https://staging.shop.example`), EUR store
**Detected by:** pipeline e2e-staging #3318, 2026-10-14 06:12 UTC
**Spec:** `checkout.spec.ts > gift card > applies a gift card to an order in EUR`
**Reproducibility:** intermittent, 3 of 10 attempts on the same commit (`--repeat-each=10`: attempts 4, 7, 9 failed)
**Client:** Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04 runner

## Summary

Applying a gift card at checkout in the EUR store fails roughly 30% of the time on build 4.12.0-rc.2. The backend endpoint returns HTTP 500 with an unhandled `TypeError` complaining that it tried to read `currency` on `undefined`. The storefront surfaces a generic "Something went wrong" toast and the order total is left unchanged, so the customer cannot redeem the card.

The failure is on the server side, not in the test. The three failing attempts all returned the same status and body, and the seven passing attempts produced the correct summary, so the test's expectation is valid and the nondeterminism is in the application.

## Steps to reproduce

1. Sign in as `buyer.eur@shop.example` (EUR store test user).
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. Enter gift card `GC-TEST-0042` (balance EUR 20.00) and press "Apply".
4. Repeat steps 1-3 several times; the failure appears intermittently (3/10 in CI).

## Expected result

- Order summary shows `Gift card: -€20.00`.
- Total updates to `€29.00`.
- `POST /api/checkout/gift-card` returns 2xx.

## Actual result

- Toast: "Something went wrong. Please try again."
- Total remains `€49.00`.
- `POST /api/checkout/gift-card` returns **500** with body:

```json
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

## Evidence

- CI run e2e-staging #3318, 2026-10-14 06:12 UTC. Failing attempts: 4, 7, 9 of 10. All three had identical status code and response body.
- Passing attempts (1, 2, 3, 5, 6, 8, 10) showed the expected summary and total on the same commit, same runner, same test data.

## Analysis

**What the error tells us.** The handler for the gift-card endpoint dereferences `.currency` on an object that is sometimes `undefined`. Candidates are the gift card record, the cart or order's currency context, or a currency/exchange-rate lookup result. Whichever it is, the handler does not guard against the missing value, so a lookup miss escalates into an unhandled exception and a raw stack message leaks into the response body.

**Why it is intermittent.** Nothing in the test varies between attempts, so the nondeterminism is in a dependency: a cache that is sometimes cold or evicted, a race between two requests that populate the currency context, or a downstream service that occasionally times out and whose failure is swallowed into `undefined` rather than raised.

**On the "currency service cache" theory.** A developer on the team channel suggested this is the currency service cache being flaky again, as last sprint. That is plausible and consistent with the symptoms, but it is a hypothesis, not a confirmed cause. Two things need to be true for it to hold: the gift-card handler reads currency from that cache, and a cache miss yields `undefined` rather than an error or a fallback fetch. Neither is established by this log. Please verify against server logs before closing on it. If last sprint's flake was "fixed," that fix either did not cover this path or has regressed.

**Separately from the root cause,** the endpoint has a robustness bug: an internal lookup failure should produce a handled error (and ideally a retry or fallback), not a 500 with a `TypeError` string in the body. That hardening is worth doing regardless of what the underlying cause turns out to be.

## Assumptions

- The test is correct and the application is at fault. Basis: identical inputs produce both outcomes on the same commit, and the 500 originates server-side.
- The EUR store is the only one affected until shown otherwise. The log only covers the EUR case; other currencies were not exercised in this spec and should be checked.
- The three failing attempts were not caused by runner resource pressure. The failure mode is a server 500 with a specific application exception, not a timeout or a client-side crash.
- "Last sprint" refers to the sprint immediately preceding the current one; no ticket number for the earlier flake was given, so none is linked here.

## Impact

Any customer in the EUR store attempting to redeem a gift card at checkout has roughly a 30% chance of being blocked with an unhelpful error. Retrying may succeed, but the toast gives no indication that retrying is the fix. If this is reachable in production on 4.12.0, it is a direct revenue and support-load issue, and gift-card holders are typically customers who have already committed to purchasing.

## Suggested next steps

1. Pull server logs for `POST /api/checkout/gift-card` around 2026-10-14 06:12 UTC on staging and capture the full stack trace for the `TypeError`, identifying exactly which object is `undefined`.
2. Confirm or rule out the currency service cache: check cache hit/miss metrics and any error logs from the currency service in the same window. Compare with the prior sprint's incident.
3. Add a guard in the handler so a missing currency context returns a handled 4xx/5xx with a structured error, not an unhandled `TypeError`. Do not leak the exception message to the client.
4. If a cache miss is the trigger, make the miss path fall through to a fetch (or fail loudly) rather than returning `undefined`.
5. Re-run the spec with `--repeat-each=20` or higher on the fix, and extend coverage to at least one non-EUR store.
6. Consider marking the test as a release gate for 4.12.0 rather than tolerating it as flaky.

## Attachments / references

- CI run: e2e-staging #3318 (2026-10-14 06:12 UTC)
- Failing spec: `checkout.spec.ts`, `gift card > applies a gift card to an order in EUR`
- Team channel note (developer, 2026-10-14): "probably the currency service cache again, it was flaky last sprint too."
