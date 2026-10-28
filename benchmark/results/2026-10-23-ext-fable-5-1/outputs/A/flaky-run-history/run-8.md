**Summary**

Of the five tests, three are flaky and one is broken outright. The suite's overall flake rate is high enough that most runs on a green commit go red.

| Test | Failures | Verdict | Root cause class |
| --- | --- | --- | --- |
| cart > updates the total when the quantity changes | 3 of 10 | Flaky | Sleep-based sync, click raced against page readiness |
| profile > saves a new avatar | 10 of 10 | Not flaky, consistently broken | Real regression or wrong assertion |
| search > filters results by tag | 4 of 10 | Flaky | Shared seed data mutated by another spec |
| orders > shows the latest order first | 2 of 10 (3 of 50 isolated) | Flaky in the test, bug in the product | Read-after-write lag in GET /orders |
| login > signs in with valid credentials | 0 of 10 | Stable | None |

Probability that a run passes, given these rates and ignoring profile, is about 34 percent. That is why main looks red most of the time even though only one test is actually broken.

**cart > updates the total when the quantity changes**

The timeout message comes from a web-first assertion, so the assertion itself waits up to five seconds. A cart total that takes more than five seconds to update is implausible. The more likely story is that the click is lost. The test clicks "+" right after navigation, sleeps a fixed 300 ms, then asserts. Under four parallel workers the page is sometimes not hydrated when the click fires, so the handler never runs and the total stays at the old value forever. The fixed sleep is the tell: it is tuned to a fast machine and has no relationship to the state it is supposed to wait for.

Assumption: the app is a client-rendered or hydrated page and the quantity button exists in the DOM before its handler is attached. If the total is instead updated by a server round trip, the same fix applies but the API call should be awaited explicitly.

What to do:

- Delete the fixed sleep. Before clicking, wait for a signal that the page is interactive, for example the button being enabled, or an initial total being rendered.
- Keep the web-first assertion on the total. Do not raise its timeout, since a longer wait would only hide the lost click.
- Owner: the cart feature team. Priority: fix this week, it is the easiest of the four.

**profile > saves a new avatar**

This test failed in every run with the same message, so it is deterministic, not flaky. Something on commit c0ffee1 returns no avatar filename where the test expects one. Either the save endpoint or the profile read stopped populating that field, or the test is reading the wrong property after a shape change.

Assumption: the test passed on the parent commit, which would make this a regression introduced on c0ffee1. If it also fails on the parent, it is a stale assertion.

What to do:

- Treat it as a red build, not a flake. Do not quarantine it and do not add retries.
- Bisect against the parent commit to decide whether the product or the test changed. Fix whichever one is wrong.
- Owner: whoever authored c0ffee1. Priority: blocking.

**search > filters results by tag**

The test passed 20 of 20 in isolation and fails about 40 percent of the time in the full suite. The cause is stated in the report: it filters on the seeded tag "summer", and tags.spec.ts renames that tag during its own run. With four workers the two specs interleave differently each run. When the rename lands first, the filter matches nothing meaningful and the page shows all five results instead of three.

This is a test-isolation defect, not a product defect. Both specs are correct on their own and wrong together.

What to do:

- Give each spec its own data. The search test should create a uniquely named tag in a fixture and filter on that. The tags test should rename a tag it created, not the shared seed.
- Do not fix it by forcing a single worker or serialising the two files. That hides the coupling and will return when a third spec touches the seed.
- Audit other specs for the same pattern, since shared seed mutation rarely stops at one tag.
- Owner: the test infrastructure owner for the fixture, the search team for the spec. Priority: this week.

**orders > shows the latest order first**

This one is different. The test already uses web-first assertions and a fresh user per run, and it still fails about 6 percent of the time in isolation. The report shows why: for up to two seconds after an order is created, GET /orders returns a list that does not contain it. The orders page fetches the list once on load, so the assertion retries against a DOM that never changes.

That is a product behaviour a real user would hit. Place an order, land on the orders page, and the order is missing. The test is reporting it correctly.

Assumption: the lag comes from a read replica, a cache, or an asynchronous indexing step between the write path and the list endpoint. The fix depends on which, but the bug report is the same either way: the list endpoint does not offer read-your-writes for the user who just wrote.

What to do:

- File a product bug against the orders API with the 2 second figure and the repeat-each reproduction. The fix belongs on the server: read from the primary for the writing user, invalidate the cache on create, or have the create endpoint return only once the order is visible.
- Until that ships, annotate the test as a known failure linked to the bug ticket, so it reports without blocking merges. Do not loosen the assertion or poll the API from the test to paper over the lag, because the test would then pass while users still see the wrong list.
- Owner: the orders backend team. Priority: high, this is user-visible.

**Suite-wide actions**

- Keep retries at zero for now. Enabling retries globally would hide the cart and search problems and would make the orders bug invisible. Revisit retries only after those are fixed, and if enabled, report retried tests as flaky in CI output rather than silently green.
- Add a lint or review rule against fixed sleeps in e2e tests. The cart test is the only one here that uses one, but it is the kind of thing that spreads.
- Run the isolation command below on any test suspected of a cross-spec interaction before investigating the test itself. It separates "my test is wrong" from "another test is interfering" in a few minutes.

```
npx playwright test <spec> --workers=1 --repeat-each=20
```

- Login is stable across all ten runs and needs no action.
