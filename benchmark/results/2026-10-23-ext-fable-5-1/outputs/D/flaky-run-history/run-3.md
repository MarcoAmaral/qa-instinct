# Flaky test analysis — commit c0ffee1, main, 10 CI runs, Playwright, 4 workers, retries 0

**What was run and what was read.** Nothing was run for this analysis. Everything below is read from the 10-run history you supplied and from the two repeat runs your team reported (search alone 20/20, orders alone 3/50 failed). The `testing-guidelines` rule could not be loaded in this environment (no `qa-rules` skill installed), so the quarantine period and the escalation threshold below are stated as assumptions, not as the rule's numbers.

**Assumptions.** The 115 tests not listed passed in all 10 runs. The suite count of 120 comes from your message, not from `npx playwright test --list`; confirm it before computing the share. Sprint length is two weeks. Today is 2026-10-26.

## Summary

| Test | Runs | Failures | Verdict | Cause class | Action |
| --- | --- | --- | --- | --- | --- |
| cart > updates the total when the quantity changes | 10 | 3 | Flaky | Test timing (provisional, see below) | Fix the test; quarantine only if the fix does not land this sprint |
| profile > saves a new avatar | 10 | 10 | **Deterministic failure, not flaky** | n/a | Debug now, then defect report; the build is red |
| search > filters results by tag | 10 | 4 | Flaky | Order / shared state (data collision between specs) | Fix the data setup in both specs |
| orders > shows the latest order first | 10 | 2 | Flaky | **Product intermittent defect** (read-after-write / eventual consistency) | `/qa-defect` as product defect, then quarantine with a ledger row |
| login > signs in with valid credentials | 10 | 0 | 0 failures in 10 runs | n/a | No action; this bounds the rate, it does not prove zero |

## Per test

### 1. cart > updates the total when the quantity changes — flaky, 3/10

**Evidence.** Same message in all three failures: `Timeout 5000ms exceeded waiting for getByTestId('cart-total') to have text "€58.00"`. The test clicks "+", sleeps 300 ms, then asserts.

**Reading the message carefully.** `toHaveText` is already a web-first assertion that retried for 5 s. So the total did not reach "€58.00" within roughly 5.3 s of the click. The 300 ms sleep is a code-style defect and must go, but removing it alone will not fix this: the sleep is not what timed out. Two explanations fit the evidence and the history cannot separate them:

- **Lost click (test timing).** The "+" button was visible and clickable before its handler was attached (hydration race), so the click did nothing and the total never changed. Under 4 workers the page loads slower, which makes this more likely in CI than locally.
- **Slow or missing recalculation (product or environment).** The click fired, the request went out, and the total took more than 5 s or never arrived.

**What decides it.** Open the trace of a failed run and check two things: what the total read at timeout (unchanged old value points to a lost click; a different value points to a product issue), and whether the cart-update request was sent at all. Reproduce with:

```
npx playwright test cart.spec.ts --workers=4 --repeat-each=30 --trace on
```

**Fix in the test, regardless of outcome.** Remove `waitForTimeout(300)`. Wait for the cart-update response around the click and keep the web-first assertion:

```ts
await Promise.all([
  page.waitForResponse(r => r.url().includes('/cart') && r.ok()),
  page.getByRole('button', { name: '+' }).click(),
]);
await expect(page.getByTestId('cart-total')).toHaveText('€58.00');
```

If the lost-click reading is confirmed, also wait for the component to be ready before clicking (an assertion on something the client renders after hydration, not a sleep). If the fixed test still fails in the 30-repeat run at 4 workers, reclassify as product or environment and file it like orders below.

**Exit.** 0 failures in 30 repeats at 4 workers on the fix commit, plus red-green: change the expected text to "€57.00" and confirm the test fails.

### 2. profile > saves a new avatar — deterministic failure, 10/10

**Not flaky.** It fails every run with the same message: `Expected: "avatar.png", Received: undefined`. Listed apart on purpose. With retries 0, this means main has been red for all ten runs on this commit; the team has been shipping over a red build, which is a process issue in its own right.

**Likely causes (unknown until debugged, do not guess which).** Either the saved profile response or state no longer carries the avatar field under that name (product or API change), or the test reads a property that was renamed (test defect). ISTQB §5.5 applies: this report may turn out not to be a product defect. Find the first commit on main where it started failing (`git bisect` on this spec), read the response body in the trace, and then either fix the test or file it through `/qa-defect` with frequency "Always, 10/10".

**Do not quarantine it.** Quarantine is for verdicts that change on unchanged code. A test that always fails is either catching a real regression or is broken; both need an answer this week, not a tag.

### 3. search > filters results by tag — flaky, 4/10

**Evidence.** Expected 3 results, received 5. Alone with one worker it passed 20 of 20 (bounds the rate, does not prove zero). `tags.spec.ts` renames the seeded tag "summer" during its own run, and with 4 workers the two specs overlap.

**Cause: order or shared state.** The mechanism is a data collision: both specs share one seeded record and one mutates it. When the rename lands before the search runs, "summer" no longer matches the 3 seeded items, and the search returns the 5 unfiltered items (or whatever the renamed state yields). The timing of the overlap decides the verdict, which is why it is intermittent.

**Fix the isolation in both specs, not the schedule.**

- `tags.spec.ts` creates its own tag with a unique name per test (test id or a random suffix) and renames that, never the seed.
- `search.spec.ts` either does the same (creates its own tag and items in a `beforeEach`) or asserts against seed data that no spec mutates. Prefer the former: a test that owns its data cannot be broken by a neighbour.
- Do not fix this with `--workers=1`, `test.describe.configure({ mode: 'serial' })`, or an ordering dependency. Those hide the coupling and slow CI.

**Exit.** 0 failures in 30 repeats at 4 workers with `tags.spec.ts` in the same run (`npx playwright test search.spec.ts tags.spec.ts --workers=4 --repeat-each=30`), plus red-green: break the tag filter and confirm the search test fails. If the fix lands within the sprint, no quarantine is needed.

### 4. orders > shows the latest order first — flaky, 2/10, **product defect**

**Evidence.** Expected "Order #1043", received "Order #1042". Your team's repeat run removed every test-side explanation: web-first assertions, a new user per run, the spec alone, and it still failed 3 of 50. In those failures `GET /orders` returned the list without the new order for up to 2 s after the order was created.

**Cause: product intermittent defect.** The list endpoint does not read its own write. That is eventual consistency between write and read paths, or a cache serving a stale list. A real customer who places an order and opens their orders page can see it missing. The test is doing its job.

**Observed frequency.** 2/10 in CI and 3/50 alone, so roughly 5 to 20 percent of attempts. Put both counts in the report.

**What to do.**

- File it with `/qa-defect` as a product defect, not a test defect. Severity: customer-visible wrong data after a successful action. Include the trace with the request timing and the stale response body.
- Quarantine the test with the ledger row below so the regression job stays green while the defect is open, and keep it running in the non-blocking quarantine job so the fix is visible when it lands.
- **Do not** "fix" the test with `expect.poll`, a 2 s wait, a page reload loop, or `retries`. Each of those makes the test pass by tolerating the defect, and the next release ships it.

**Exit.** Only after the product fix: 0 failures in 50 repeats of this spec on the fix commit, plus red-green: have the order creation stub return an older id and confirm the test fails. Then remove the tags and mark the row `retired (fixed)`.

### 5. login > signs in with valid credentials — 0 failures in 10 runs

Not a suspect on this evidence. Ten runs bound the failure rate; they do not prove zero.

## Quarantine proposal and ledger

The skill proposes, the team decides. Rows need an owner and a deadline before the `@quarantine` tag goes on; the placeholders below are not a quarantine until filled.

| Test ID | Cause class | Defect report | Owner | Quarantined on | Deadline | Status |
| --- | --- | --- | --- | --- | --- | --- |
| orders > shows the latest order first | Product intermittent defect | DR to be filed via `/qa-defect` (frequency 2/10 CI, 3/50 alone) | to assign (backend owner of /orders) | 2026-10-26 | 2026-11-09 (assumed one sprint) | quarantined, awaiting product fix |
| cart > updates the total when the quantity changes | Test timing (provisional) | none yet; file only if the fixed test still fails | to assign (e2e owner) | only if the fix misses this sprint | 2026-11-09 | fix in progress, not quarantined |
| search > filters results by tag | Order / shared state | none; test defect | to assign (e2e owner) | only if the fix misses this sprint | 2026-11-09 | fix in progress, not quarantined |

**Share.** With orders alone quarantined: 1 of 120, 0.8 percent. If cart and search also go in: 3 of 120, 2.5 percent. Both figures assume the 120 count; recompute from `npx playwright test --list`. I could not compare these against the rule's threshold because the rule was not available; if the rule's threshold is lower than 2.5 percent, the second scenario triggers escalation to whoever the rule names.

**Exclusion.** Add `--grep-invert @quarantine` to the `@smoke` and `@regression` jobs, and add one non-blocking job that runs `--grep @quarantine` so a fix shows up as green without anyone remembering to look.

**Retries.** Keep `retries: 0` on main for now. It is what made this history readable. Raising it would have hidden the orders defect behind a green run.

## What this history cannot show

- Whether any of the other 115 tests is flaky; only five rows were supplied.
- Runs before c0ffee1, so when profile started failing and whether cart or search were flaky on earlier commits.
- For cart, what the total actually read at timeout and whether the click fired; only a trace answers that.
- For profile, whether the cause is in the product or in the test.
- Whether the orders stale read also happens in production, and its real rate there; the CI and repeat-run rates are from a test environment under load.
- Any run whose artefacts were not kept; if CI does not retain traces for failed runs, turn on `trace: 'retain-on-failure'` before the next hunt.

**Rule not applied.** The `testing-guidelines` rule (quarantine period, escalation threshold, named escalation contact) could not be loaded because no `qa-rules` skill is installed here. The deadline and threshold handling above are stated assumptions and should be replaced with the rule's values.
