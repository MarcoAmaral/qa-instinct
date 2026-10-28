# Defect: Gift card apply in EUR checkout intermittently returns HTTP 500 with "Cannot read properties of undefined (reading 'currency')"

| Field | Value |
|---|---|
| Component | Checkout, gift card redemption, `POST /api/checkout/gift-card` |
| Build | 4.12.0-rc.2, commit 9f3c2ab |
| Environment | staging.shop.example, EUR store |
| Pipeline | e2e-staging #3318, 2026-10-14 06:12 UTC |
| Runner | Ubuntu 22.04, Chromium 129.0.6668.29, Playwright 1.48.1 |
| Spec | `checkout.spec.ts > gift card > applies a gift card to an order in EUR` |
| Failure rate | 3 of 10 identical attempts on one commit, attempts 4, 7 and 9 |
| Severity | High. The customer cannot redeem a gift card and sees a generic error. Payment is blocked for that session. |
| Priority | High. This is a release candidate and the failure is in a core checkout flow. It should block promotion of 4.12.0-rc.2 until it is understood. |
| Type | Intermittent server-side defect surfaced by E2E. Not a flaky test. See analysis. |
| Reported by | QA, 2026-10-24 |

**Summary.** Applying a valid gift card during EUR checkout fails roughly a third of the time. The backend responds with HTTP 500 and an unhandled TypeError, and the storefront shows a generic retry toast with the total unchanged. The remaining attempts succeed with the correct discount, so the failure is non-deterministic across identical inputs on the same build.

## Reproduction

Preconditions:

- Test account `buyer.eur@shop.example` exists on the EUR store and is signed in.
- Gift card `GC-TEST-0042` exists with a balance of EUR 20.00 and is redeemable.
- Product "Desk Lamp" is purchasable at EUR 49.00.

Steps:

1. Sign in as the EUR test user.
2. Add "Desk Lamp" to the cart and open checkout.
3. Enter gift card code `GC-TEST-0042` in the gift card field and press "Apply".
4. Repeat steps 1 to 3 from a fresh session until the failure appears. On the CI run it took at most 4 attempts.

Expected result:

- Order summary shows a line "Gift card: -€20.00".
- Order total shows €29.00.
- `POST /api/checkout/gift-card` returns a 2xx response.

Actual result on failing attempts:

- Toast "Something went wrong. Please try again." is shown.
- Order total remains €49.00 and no gift card line is added.
- The API call fails:

```text
POST /api/checkout/gift-card -> 500
{"error":"TypeError: Cannot read properties of undefined (reading 'currency')"}
```

Actual result on passing attempts: identical to the expected result.

Reproduction command used by CI:

```text
npx playwright test checkout.spec.ts -g "applies a gift card to an order in EUR" --repeat-each=10
```

## Analysis and evidence

**Why this is a product defect and not test flakiness.** The test performs the same three steps with the same data on the same commit, and the server itself returns a 500 on 3 of 10 attempts. The assertion that fails is a direct consequence of that 500. Nothing in the log points to timing in the test, selector instability, or test data drift, because the same gift card and product succeed on the other seven attempts. A 30 percent failure rate on identical input is a server-side race or state dependency, and marking the test as flaky or adding retries would hide a real customer-facing failure.

**What the error tells us.** The message indicates that some object the handler expects to carry a `currency` field was `undefined` at the moment of the read. The two most likely candidates are the resolved store or cart currency context and the gift card's own currency record. The handler is also not guarding this path, so the exception escapes as a raw 500 with a stack-style message leaked into the response body rather than a structured validation error. That leak is a secondary, lower-severity issue noted below.

**On the developer's hypothesis.** The team channel note suggests the currency service cache, referencing similar flakiness last sprint. This is plausible and consistent with the symptom, since a cache miss or an expired entry returning `undefined` would produce exactly this error on an intermittent basis. However, it is unverified. Nothing in the CI log identifies which object was undefined, and the previous incident was apparently never closed with a root cause, since it is being described as recurring. This report does not assume the cache is the cause. It should be confirmed or ruled out with server logs before any fix is accepted.

**Assumptions made in this report.**

- The gift card `GC-TEST-0042` is denominated in EUR, matching the store. If it is denominated in another currency, the failure mode may be a missing conversion rate rather than a missing currency context, and the severity would change.
- The 3 failures and 7 passes hit the same staging backend instance or pool, with no deployment in progress during the run. If staging was mid-rollout, the mixed results could reflect two code versions and the run should be repeated.
- No other specs in pipeline #3318 reported currency-related 500s. If they did, the scope is wider than the gift card endpoint.
- The frontend's generic toast is the intended handling for any 5xx. The message is acceptable, but the frontend is not under investigation here.
- Previous sprint's "flaky" currency service incident has no closed ticket with a root cause. If one exists, link it to this report and compare stack traces.

**Suggested investigation for the assignee.**

1. Pull server logs for `POST /api/checkout/gift-card` on staging between 06:12 and 06:20 UTC on 2026-10-14 and capture the full stack trace for the three 500s. The line number will show which object was undefined.
2. Compare request headers and session or cart identifiers between a failing and a passing attempt to see whether the cart currency context was present on the request.
3. If the currency service cache is involved, check cache hit and miss metrics and TTL expiry timing during the run, and check whether a miss falls through to a lookup or returns `undefined` directly.
4. Run the endpoint under a tight loop with the cache deliberately cleared between calls to see whether the failure becomes deterministic.
5. Check whether the same endpoint fails for the USD and GBP stores, or only EUR.

**Secondary issues observed.**

- The API returns an internal exception message in the response body. This should be replaced with a structured error code and the detail kept in server logs.
- The handler has no guard for a missing currency context. Even once the root cause is fixed, a missing context should produce a 4xx or a logged 5xx with a stable error shape, not an unhandled TypeError.

**Acceptance criteria for closure.**

- Root cause is identified from a server-side stack trace, not inferred.
- `--repeat-each=50` on the fixed build passes with zero 500s on the EUR gift card spec.
- The endpoint returns a structured error rather than a raw TypeError when currency context cannot be resolved, with a unit test covering that branch.
- If the cause is the currency service cache, the ticket from last sprint is linked and closed against the same fix.

**Attachments to collect from CI.** Playwright trace and video for attempts 4, 7 and 9, the HAR for the failing `POST /api/checkout/gift-card` requests, and the full pipeline #3318 log. These were not included in the excerpt above and should be retained before the runner artifacts expire.
