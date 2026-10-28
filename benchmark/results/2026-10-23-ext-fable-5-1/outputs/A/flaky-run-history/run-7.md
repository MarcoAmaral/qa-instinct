## Flakiness analysis: e2e suite, commit c0ffee1, 10 runs

**Assumptions.** The 115 tests not listed passed in all ten runs. Worker scheduling is Playwright's default, so spec order differs between runs. "Flaky" means it both passed and failed on the same commit with no code change.

| Test | Failed | Verdict | Root cause | Action |
| --- | --- | --- | --- | --- |
| cart > updates the total when the quantity changes | 3 of 10 | Flaky | Click/update race; the 300 ms sleep hides it rather than fixing it | Fix the test now |
| profile > saves a new avatar | 10 of 10 | Not flaky, a real failure | Avatar field is missing from the saved profile | Treat as a bug on main |
| search > filters results by tag | 4 of 10 | Flaky | Shared seed data mutated by tags.spec.ts in another worker | Fix test isolation now |
| orders > shows the latest order first | 2 of 10 | Flaky, but the product is at fault | Read-after-write lag of up to 2 s in GET /orders | File a backend bug, quarantine with a link |
| login > signs in with valid credentials | 0 of 10 | Stable | None | None |

### cart > updates the total when the quantity changes

**Why it fails.** The error comes from a web-first assertion that already retries for 5 s. So the fixed 300 ms sleep is not what fails. The sleep is dead weight. The real problem is that the total never reaches the expected value in those runs. Two explanations fit a 30% rate under 4 workers. The "+" click can land before the handler is attached, so it is dropped and the total stays at the old value. Or the cart update takes longer than 5 s under load. The stale-click case is more likely because the message is identical every time and never a near miss.

**What to do.**
- Delete the waitForTimeout call. It adds nothing and signals that the author was fighting a race.
- Make the click observable. After clicking, assert the quantity field shows 2, or wait for the cart update response, before asserting the total.
- Keep the 5 s expect timeout. Raising it would paper over a lost click.
- Rerun with trace on first retry locally using repeat-each 30 to confirm the fix. The trace will show whether the click was dropped or the response was slow.

### profile > saves a new avatar

**Why it fails.** Ten failures out of ten is deterministic. Received undefined means the field the test reads is absent from the response or the saved profile. Either the avatar upload is broken on main, or the API renamed the field and the test was not updated.

**What to do.**
- Do not label this flaky and do not quarantine it. It is a consistent signal.
- Check whether the avatar is actually saved by calling the profile endpoint by hand. If it is missing, bisect the regression on main and fix the product. If it is present under another key, update the test.
- Until resolved, main is red for a reason. Block merges on it rather than skipping it.

### search > filters results by tag

**Why it fails.** The test depends on the seeded tag "summer". tags.spec.ts renames that tag during its run. With 4 workers the two specs interleave differently each run, so the search test fails whenever the rename lands first. Alone it passes 20 of 20, which confirms the cause is cross-test interference and not the search feature. The count of 5 instead of 3 suggests the filter falls through to an unfiltered list when the tag is missing.

**What to do.**
- Give each spec its own data. The search test should create a uniquely named tag in a beforeEach and filter on that. tags.spec.ts should rename a tag it created itself.
- Never mutate shared seed data in a test. Audit tags.spec.ts for other seeded rows it edits.
- Do not serialise the two specs or pin worker order. That hides the coupling and slows the suite.
- Consider a separate finding: if a missing tag returns all results instead of none, that may be a product bug worth a ticket.

### orders > shows the latest order first

**Why it fails.** The test is already well written. It uses web-first assertions and a fresh user, and it still fails about 6% of the time when run alone. In those runs GET /orders returns a list without the new order for up to 2 s after creation. The page loads the stale list once and does not refetch, so retrying the DOM assertion cannot help. A real user would see the same thing: place an order, open the orders page, and not find it. Likely causes are a read replica, a cache, or an asynchronous index that lags writes.

**What to do.**
- File a backend bug for the read-after-write gap. This assumes the product intends a new order to be visible immediately, which the test encodes.
- Quarantine the test with a link to that ticket, using fixme or a quarantine tag, so main stays green without losing the record. Set a review date.
- Do not fix it in the test by polling the API before navigating or by widening the timeout. Both would make the suite pass while the user-visible problem stays.
- If the team decides eventual consistency is acceptable, change the product so the orders page refetches or shows the new order optimistically, then unquarantine.

### Suite-level notes

- Keep retries at 0 on main. The zero-retry setting is why this data is clean. Adding retries would have hidden all three flaky tests.
- Three of the five failures are caused by shared state across workers or against the backend. Add a lint or review rule that tests create the data they need and never edit seed rows.
- Rerun the same ten-run exercise after the cart and search fixes land. Expect cart and search at 0 failures, orders quarantined, and profile red until the bug is fixed.
