# Defect Report: POST /api/checkout/gift-card intermittently returns 500 (TypeError on 'currency') when applying a gift card in the EUR store

| Field | Value |
|---|---|
| ID | Proposed: CHK-GC-EUR-500 (assumed: no tracker ID assigned yet) |
| Reported | 2026-10-24, from CI run 2026-10-14 06:12 UTC, pipeline e2e-staging #3318 |
| Build | 4.12.0-rc.2, commit 9f3c2ab |
| Environment | https://staging.shop.example, Chromium 129.0.6668.29, Playwright 1.48.1, Ubuntu 22.04 runner |
| Component | Checkout API, gift card endpoint (server side) |
| Severity | High. Money-affecting checkout feature fails for real user flows and no user-facing recovery guidance is given. |
| Priority | P1. Recommend treating as a blocker for the 4.12.0 release until root cause is confirmed. |
| Reproducibility | Intermittent, 3 of 10 attempts on the same commit (attempts 4, 7, 9) |
| Failing spec | checkout.spec.ts > gift card > applies a gift card to an order in EUR |
| Status | New |

## Summary

Applying a valid gift card at checkout in the EUR store intermittently fails with an HTTP 500 from the gift card endpoint. The response body exposes a server-side TypeError that reads the property `currency` from an undefined value. The UI shows a generic "Something went wrong" toast and the order total stays unchanged. The same request succeeds on other attempts against the same build, so the fault is state-dependent on the server rather than a defect in the test.

**Expected.** After pressing "Apply", the order summary shows "Gift card: -€20.00" and the total becomes €29.00.

**Actual.** A toast reads "Something went wrong. Please try again." and the total remains €49.00. The network tab shows the following.

```text
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

## Steps to reproduce

1. Sign in as buyer.eur@shop.example on the EUR store at https://staging.shop.example.
2. Add "Desk Lamp" (EUR 49.00) to the cart and open checkout.
3. Enter gift card GC-TEST-0042 (balance EUR 20.00) and press "Apply".
4. Repeat the full flow. The CI run reproduced the failure on roughly 3 in 10 attempts with `--repeat-each=10`.

A manual single attempt may pass. To reproduce reliably, run the spec with repeat-each set to 10 or higher, or loop the API call directly with a fresh checkout session each time.

**Evidence available.** CI log for pipeline e2e-staging #3318 with the three failing attempts. Playwright trace, screenshot and HAR for attempts 4, 7 and 9 are assumed to be attached to the run as standard artifacts. No server request ID was captured in the log, so backend correlation is pending.

## Analysis, assumptions and recommendations

**This is a server defect, not a flaky test.** All seven passing attempts and all three failing attempts ran the same steps against the same commit. The failure signal is a deterministic 500 with a specific TypeError, not a timeout or a selector race. The test should not be quarantined or marked flaky. It is correctly detecting a backend fault that would hit real customers at the same rate.

**The TypeError is a missing null guard.** Somewhere in the gift card handler, code reads `.currency` from an object that is sometimes undefined. Candidates are the resolved store or cart currency, the gift card record, or a currency-lookup result. Whichever it is, the handler should fail with a controlled 4xx or 503 and a logged reason, never an unhandled TypeError.

**The developer's cache hypothesis is unverified.** The team channel comment that this is "probably the currency service cache again" is plausible and consistent with an intermittent undefined lookup. It is recorded here as a hypothesis only. No cache miss, eviction or timeout has been shown in logs for this run. If it was already flaky last sprint, the earlier incident was not fixed and this report should be linked to it.

**Two secondary defects were observed in the same failure.**

- The API response leaks a raw runtime error message to the client. This is an information disclosure issue and should be replaced with a stable error code and message.
- The UI toast gives the user no way to tell whether the gift card was partially applied or whether retrying is safe. The total is unchanged, so no money was moved, but the message should state that the gift card was not applied.

**Assumptions made in writing this report.**

- GC-TEST-0042 is a non-consumable fixture or is reset between attempts, since the balance was still EUR 20.00 on later passing attempts.
- Each repeat starts a fresh checkout session, so a stale cart from a previous attempt is not the cause.
- Only the EUR store was exercised. Whether other currency stores are affected is unknown.
- The spec passed on previous builds. The last known good build was not stated in the log and should be confirmed from pipeline history.
- Staging runs more than one backend instance. Instance-level correlation of the three failures has not been done.

**Requested from the development team.**

1. Pull server logs for the three failing requests, using timestamps from the trace files, and confirm which object was undefined when `.currency` was read.
2. Confirm or rule out the currency service cache by checking cache hit and miss metrics around the failure timestamps, and check whether all three failures landed on the same instance.
3. Add a null guard and a controlled error response in the gift card handler regardless of the root cause.
4. Stop returning raw exception text in API error bodies.
5. Add a regression test that forces the currency lookup to return undefined and asserts a controlled error.
6. Run the spec with `--repeat-each=50` on the fix branch before closing, since a single pass does not prove the fix for an intermittent fault.

**Workaround.** Pressing "Apply" again generally succeeds. This is acceptable for internal testing only and is not an acceptable customer experience.

**Exit criteria.** Zero failures in at least 50 consecutive repeat runs of the spec on staging, server logs showing no TypeError on the gift card endpoint during that window, and the API returning a structured error body on induced lookup failure.
