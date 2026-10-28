# Flaky-test analysis: e2e suite on c0ffee1

**Bottom line.** Three of the five tests are flaky, one is a deterministic failure that is not flaky, and one is healthy. Even with the deterministic failure fixed, only 2 of the 10 runs would have been green. The suite cannot gate merges until the three flaky tests are fixed at the root. Do not turn retries on to hide them.

| Test | Failures | Verdict | Root cause | Owner of the fix |
| --- | --- | --- | --- | --- |
| cart > updates the total when the quantity changes | 3/10 | Flaky | Fixed sleep plus an unverified click; the click is lost or the update outruns the 5 s expect timeout under load | Test |
| profile > saves a new avatar | 10/10 | Broken, not flaky | Deterministic regression or environment gap | App or test setup |
| search > filters results by tag | 4/10 | Flaky | Shared seed data mutated by another spec running in parallel | Test (tags.spec.ts) |
| orders > shows the latest order first | 2/10, 3/50 alone | Flaky | Backend returns stale order list for up to 2 s after a write | App, with a test-side guard |
| login > signs in with valid credentials | 0/10 | Stable | None | None |

## Assumptions

- Each test gets its own user and cart unless the message says otherwise. All workers share one database and one seed dataset.
- The profile test fails identically on a developer machine. If it passes locally, the cause is environmental rather than a code regression. The actions below cover both cases.
- "Flaky" means the same commit gives different results across runs. A test that fails every time is a bug, not flakiness, and is treated separately.

## 1. cart > updates the total when the quantity changes

**What happens.** Passes 7 of 10. The failing runs all time out waiting for the total to read "€58.00".

**Why.** The test clicks "+", sleeps 300 ms, then asserts the total. The assertion itself retries for 5 s, so the sleep is not the direct cause. The total never reaches the expected value within roughly 5.3 s. Two causes fit a 30 percent failure rate under 4 parallel workers:

- The click fires before the handler is attached. Playwright considers the button actionable once it is visible and enabled, which can be before the framework has hydrated it. The click is swallowed and the total never changes.
- The quantity update round-trips to the server and, under load from the other workers, takes longer than the 5 s expect timeout.

The failure message does not include the received text, so the two cannot be told apart from this evidence alone. If the received text equals the starting total, the click was lost. If it is a different value such as a doubled increment, the click registered twice.

**What to do.**

1. Delete the fixed sleep. Sleeps add time to the fast path and do not help the slow path.
2. Assert the starting state before clicking, for example that the quantity shows 1 and the total shows the pre-click value. This proves the page is ready and makes the failure readable.
3. Make the click observable. Wait for the quantity field to show 2, or wait for the response to the quantity-update request, before asserting the total.
4. Record the received value when it fails. Run the spec alone with a high repeat count, as was done for search and orders, and check whether it still fails. If it only fails in parallel, the cause is server load and the expect timeout for this assertion should be raised to a realistic bound while the slow endpoint is profiled.
5. Until the fix lands, mark it with `test.fixme` so main can go green. Do not delete it.

## 2. profile > saves a new avatar

**What happens.** Fails 10 of 10 with the same assertion: expected "avatar.png", received undefined.

**Why.** This is not flaky. The field the test reads does not exist in the response or the DOM. Likely causes, in order:

- The commit renamed or moved the avatar field, for example from a filename to a URL object, and the test still reads the old path.
- The upload never happens in CI because the fixture file is missing from the checkout or the upload is blocked, so the profile has no avatar.

**What to do.**

1. Run the test on the parent of c0ffee1. If it passes there, this commit broke it and the author should fix the app or update the assertion to the new shape. If it fails there too, it is a CI environment gap. Check that the fixture image is committed and that the path is resolved relative to the spec file, not the working directory.
2. Add an assertion that the upload request returned success before asserting on the saved value, so future failures point at the right layer.
3. Treat this as a blocking failure, not a candidate for quarantine.

## 3. search > filters results by tag

**What happens.** Passes 6 of 10. Fails with "expected 3 results, received 5". Passes 20 of 20 when run alone.

**Why.** Test pollution. The spec filters by the seeded tag "summer". The tags spec renames that same tag during its own run. With 4 workers and no fixed ordering, whether the rename lands before the search assertion is a race. "Received 5" rather than 0 suggests the search either falls back to unfiltered results when the tag is not found, or the tags spec renames a different tag to "summer" and the filter matches extra items. Either way the trigger is the same.

**What to do.**

1. Fix the tags spec, not the search spec. It should create its own tag in a fixture and rename that, leaving the seed data untouched. Tests that mutate shared seed data will keep producing failures like this in other specs.
2. Harden the search spec as well. Create the tag and the three tagged items in a fixture so the test owns every row it depends on.
3. Do not serialize the suite or add a global lock. That hides the dependency and slows every run.
4. Check the fallback behaviour. If filtering by a tag that no longer exists shows all results, that is a product question worth raising, since a user following a stale link would see the same thing.

## 4. orders > shows the latest order first

**What happens.** Fails 2 of 10 in CI and 3 of 50 when run alone with web-first assertions and a fresh user per run. In the failing runs the orders endpoint returned the list without the new order for up to 2 s after creation.

**Why.** The flakiness is in the system under test, not the test. Reading your own write is not guaranteed for up to 2 s. Typical causes are a read replica behind the primary, a cached list response, or an asynchronous projection or index that the list query reads from. The web-first assertion cannot rescue this, because the page fetches the list once on navigation and the stale response is already rendered. Retrying the DOM check does not refetch the data.

**What to do.**

1. Decide whether this is acceptable product behaviour. If the app sends the user to the orders page right after placing an order, real users will hit the same stale list. Treat that as a backend bug: file it, and have the owners either read from the primary after a write, invalidate the cache on create, or return the created order in the response and merge it client side.
2. Guard the test against it in the meantime, without hiding the bug. Poll the orders endpoint with `expect.poll` until the new order appears, then navigate and assert. Keep a separate test, marked as expected to fail against the known bug, that navigates immediately. It will start passing when the backend is fixed and tell you the guard can be removed.
3. Do not add retries or raise the expect timeout for this test. Neither changes what the page fetched.

## 5. login > signs in with valid credentials

Stable across all runs. No action.

## Suite-level actions

- Keep retries at 0 for now. Retries would have turned 8 red runs into mostly green ones while leaving every one of these defects in place. Once the three flaky tests are fixed, set retries to 1 with the flaky-test report enabled so new flakiness is tracked instead of hidden.
- Make the shared-seed rule explicit in the test guidelines. Specs create the data they mutate; seed data is read only.
- Add received values to assertion messages where they are missing, as in the cart test. Two of the four failures here could not be fully diagnosed from CI output alone.
- Re-run the suite 10 times on the same commit after the fixes. The goal is 10 of 10 green with retries at 0.
