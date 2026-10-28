# Flaky test analysis: e2e suite on c0ffee1, 10 runs

Only three of the five tests are actually flaky. One is a hard failure, one is healthy. The suite was red in 10 of 10 runs, and even with the hard failure removed it would have been green in only 2 of 10.

| Test | Failed | Verdict | Root cause | Decision |
| --- | --- | --- | --- | --- |
| profile > saves a new avatar | 10/10 | Broken, not flaky | Deterministic regression in app or test | Fix now, keep blocking |
| search > filters results by tag | 4/10 | Flaky, test-side | Shared seed data mutated by tags.spec.ts | Fix test isolation now, no quarantine |
| cart > updates the total when the quantity changes | 3/10 | Flaky, cause unconfirmed | Likely lost click before hydration, or slow recompute under load | Investigate with trace, quarantine with expiry |
| orders > shows the latest order first | 2/10 | Flaky, product-side | Read-after-write lag on GET /orders | File product bug, move to non-blocking lane |
| login > signs in with valid credentials | 0/10 | Stable | None | Nothing |

## Per-test findings

**profile > saves a new avatar.** A test that fails identically on every run has no randomness in it. The received value is undefined, which means the avatar field is missing from whatever the test reads back, not merely wrong. That points to either the upload not being persisted or an API or DOM shape change the test was not updated for. Either way this is a real defect on the commit and should block. Bisect against the last green commit to find out whether the app or the test regressed. Do not quarantine it, and do not count it in flake metrics.

**search > filters results by tag.** The evidence is complete. It passes 20 of 20 alone and fails only in the parallel suite, and we know tags.spec.ts renames the "summer" tag it depends on. With 4 workers the relative order of the two specs is nondeterministic, so the failure appears whenever the rename lands first. The fix is ownership of test data: each spec should create its own tag with a unique name, or use a fixture that seeds and tears down per test. The tags spec should never rename a shared seed. This is a small change and should land this week instead of being quarantined.

One product question falls out of this. When the tag no longer exists, the search returned 5 results rather than 0. If filtering by an unknown tag silently drops the filter, that is user-visible and worth a ticket of its own.

**cart > updates the total when the quantity changes.** This one needs one more data point before anyone touches it. The assertion that times out is a web-first toHaveText with a 5 second budget, so the 300 ms sleep is a smell but is not the cause. Deleting it alone will not fix anything. After 5 seconds the total is still not €58.00, which fits two different stories:

- The "+" click fired before the handler was attached and was lost. The total then stays at the old value and the sleep was probably an earlier attempt to paper over exactly this.
- The recompute request is genuinely slow under 4-worker load and lands after the budget.

The received text in the Playwright trace distinguishes them. The old total means a lost click. A spinner or intermediate value means latency. Run the spec alone with repeat-each 50, as was done for orders, and pull the trace from a failing CI run. If it is a lost click, wait for a hydration signal such as a button that is disabled until the handler mounts, or retry the click inside expect.toPass until the quantity changes. If it is latency, that is a performance finding, not a test problem, and raising the timeout would only hide it. Quarantine it with an owner and a two-week expiry, because at this rate it is the single biggest cause of red runs alongside search.

**orders > shows the latest order first.** The test is correct and is catching a real bug. The diagnostic work was already done properly: web-first assertions, a fresh user per run, and still 3 failures in 50 when run alone. GET /orders returns a list without the just-created order for up to 2 seconds. That is a read-after-write consistency gap, typically a read replica, a cache, or an asynchronous index. Do not add polling to the test, because that would encode the bug as acceptable behaviour without anyone deciding so. File it against the orders service with the repro steps and the 2 second figure. Then move the test to a non-blocking lane linked to the ticket so it keeps reporting without training people to re-run. If product decides eventual consistency is the contract, the UI must handle it and the test can then poll up to the agreed bound.

**login > signs in with valid credentials.** Passed every run. No action. It is a good candidate for the smoke set.

## What this means for the suite

**The three flaky tests fail independently.** Their failing runs overlap only once, in run 2, which is what chance predicts. There is no sign of one shared trigger such as a bad worker or a slow runner, so each needs its own fix.

**Red CI is currently carrying no information.** With failures at these rates, a fully correct commit passes only about 4 times in 10 once profile is fixed. Until search and cart are addressed, engineers cannot distinguish their own breakage from noise.

**Keep retries at 0 on this diagnostic job.** Retries would have hidden all three flaky tests and the orders bug with them. Use retries, if at all, only on the gating job and only after the causes above are fixed. Consider a nightly job that runs the suite several times on the same commit, since this 10-run exercise is what made the diagnosis possible.

**Ten runs is a small sample.** The 10 of 10 and 0 of 10 results are conclusive. The 2 to 4 of 10 rates are rough and should not be quoted as precise percentages.

**Assumptions made.** The other 115 tests passed in all 10 runs, since only these five were reported. The profile test was green on some earlier commit, so a bisect is possible. The cart test has not yet been run alone, so its cause is stated as a hypothesis rather than a finding. No trace or received-text was available for cart, and the Playwright message would normally include it.
