# Defect Report: Intermittent 500 on gift card apply in EUR checkout (`POST /api/checkout/gift-card`)

**ID:** (to be assigned)
**Reported:** 2026-10-24
**Reporter:** <account email, redacted>
**Component:** Checkout / Gift cards (backend API)
**Build:** 4.12.0-rc.2, commit 9f3c2ab
**Environment:** staging (https://staging.shop.example), EUR store
**Severity:** High. Intermittent failure of a payment step blocks order completion for affected users and is on the release candidate.
**Priority:** P1. Fix or decide on a release-blocker exception before 4.12.0 ships.
**Status:** New
**Reproducibility:** Intermittent, 3 of 10 runs on the same commit

## Summary

Applying a gift card at checkout in the EUR store intermittently fails with an HTTP 500. The response body contains an unhandled `TypeError` reading the `currency` property of an undefined object. The UI shows a generic error toast and the total is not reduced. The same steps succeed on other attempts with no code change.

## Steps to reproduce

1. Sign in on staging as `buyer.eur@shop.example` (EUR store).
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. Enter gift card `GC-TEST-0042` (balance EUR 20.00) and press "Apply".
4. Repeat the full flow several times. The failure appeared in roughly 3 of 10 runs.

Automated reproduction:

```text
checkout.spec.ts > gift card > applies a gift card to an order in EUR
npx playwright test checkout.spec.ts -g "applies a gift card to an order in EUR" --repeat-each=10
```

## Expected result

The order summary shows "Gift card: -€20.00" and a total of €29.00. The API returns a success status.

## Actual result

A toast "Something went wrong. Please try again." appears and the total stays €49.00.

Network:

```text
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

## Evidence

| Item | Value |
|---|---|
| CI run | e2e-staging #3318, 2026-10-14 06:12 UTC |
| Results on commit 9f3c2ab | 7 passed, 3 failed (attempts 4, 7, 9) |
| Failure signature | Identical status and body on all three failures |
| Browser / tooling | Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04 runner |

The failing and passing attempts used the same build, test user, product, and gift card. The failure is server-side. The browser and test harness only surface it.

## Analysis

The error is an unhandled exception in the gift card endpoint, not a validation or business-rule rejection. Some object the handler expects to carry a `currency` field is undefined on the failing requests. Candidates include the resolved store or session currency, the gift card record, or a currency-conversion lookup result.

A developer on the team channel suggested the currency service cache, noting it was flaky last sprint. That is a plausible lead but is unconfirmed. No server logs, trace IDs, or cache metrics were attached to the run. The report should not be closed on that hypothesis without evidence from the backend.

Two defects are visible regardless of root cause:

- **Primary:** the gift card endpoint intermittently fails to resolve a currency-bearing object and throws.
- **Secondary:** the endpoint leaks a raw `TypeError` message in the 500 response body instead of a structured error. The UI then shows a generic toast, so the user has no way to know whether the gift card balance was touched.

## Assumptions

- The three failed attempts did not change the balance of `GC-TEST-0042`. This was not verified. If the balance was debited without the discount being applied, severity rises to Critical.
- The failure is not EUR-specific. Only the EUR spec ran with repeats, so other currencies are untested.
- Staging shares the currency service and its cache with the configuration that will ship in 4.12.0.
- The test has no known history of flakiness on earlier builds. If it does, note the first affected build.

## Suggested investigation

1. Pull server logs for the three failing requests. Confirm the stack frame that reads `currency` and which object is undefined.
2. Check currency service cache behaviour around the failure timestamps: misses, evictions, timeouts, or a cold entry for EUR.
3. Run the same spec with `--repeat-each=10` against the USD and GBP stores to see whether the failure is currency-specific.
4. Verify the gift card balance before and after a failed apply.
5. Add a guard and a structured error on the endpoint so a missing currency returns a handled 4xx or 5xx with a correlation ID instead of a raw exception.

## Attachments

- CI log excerpt for e2e-staging #3318 (quoted above).
- Playwright trace and HAR for attempts 4, 7, and 9. Assumed to be retained by the runner. Attach if available.
