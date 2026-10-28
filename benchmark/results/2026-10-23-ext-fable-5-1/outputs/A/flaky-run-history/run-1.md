## Flaky-test triage for c0ffee1 (10 runs, retries 0)

| Test | Fails | Verdict | Owner action |
| --- | --- | --- | --- |
| cart > updates the total when the quantity changes | 3/10 | Flaky, test-side race (app cause possible) | Fix the test now, keep it running |
| profile > saves a new avatar | 10/10 | Not flaky, deterministic failure | Treat as a regression, fix today |
| search > filters results by tag | 4/10 | Flaky, cross-test data pollution | Fix the fixture in both specs, keep it running |
| orders > shows the latest order first | 2/10 | Flaky, real app bug (read-after-write lag) | File a bug, quarantine the test with a ticket |
| login > signs in with valid credentials | 0/10 | Stable | None, use as the control |

Only three of the five are flaky. One is a plain failure that has been mislabelled, and one is the test correctly catching a product bug.

### cart > updates the total when the quantity changes

**What is happening.** The assertion already waits five seconds for the total to read €58.00, so the 300 ms sleep is not what fails. The total never reached the expected value in those five seconds. That leaves two candidate causes. Either the click on "+" is dropped because it lands before the page's handlers are attached, so nothing updates. Or the update is a server round-trip that sometimes exceeds five seconds under four parallel workers. Assumption: the "+" button triggers a request to recalculate the total, and no trace was retained from the failing runs.

**What to do.**
- Delete the `page.waitForTimeout(300)`. It adds nothing and hides intent.
- Before clicking, assert a precondition that proves the page is interactive, such as the quantity reading "1" and the button being enabled.
- After clicking, assert the quantity reads "2" before asserting the total. This splits the two causes: if the quantity never changes, the click was dropped and it is a test bug. If the quantity changes but the total does not, it is an app or performance bug.
- Turn on trace retention for failures in the Playwright config so the next failure shows the request timing.
- Keep the test in the suite. The fix is small and the failure rate is high enough that it will reappear quickly if the diagnosis is wrong.

### profile > saves a new avatar

**What is happening.** It fails ten times out of ten with the same message. That is a deterministic failure, not flakiness. The received value is undefined, which means the field the test reads is missing from the object or response. The most likely causes are a renamed or removed field in the profile API or page model, or a save that silently does nothing. Assumption: this started with c0ffee1 or a recent commit on main, since it is green nowhere.

**What to do.**
- Stop treating this as flaky and remove it from any flaky list. Retries will never make it pass.
- Bisect it against recent main commits and assign it to the owner of the profile feature today. Main is red until it is fixed or the offending change is reverted.
- If the field was intentionally renamed, update the test in the same change that renamed it.

### search > filters results by tag

**What is happening.** Alone it passes 20 of 20. In the suite it fails four of ten, always with extra results. The tests share one seeded database, and tags.spec.ts renames the "summer" tag that search.spec.ts filters on. Whether search fails depends on which worker runs which spec first, which is why the failures look random. This is order-dependent data pollution, not a bug in search.

**What to do.**
- Make tags.spec.ts create its own tag to rename instead of mutating the shared seed. That is the root cause and the primary fix.
- Make search.spec.ts create a uniquely named tag per test, for example suffixed with the test ID, tag a known number of items, and filter on that. Then no other spec can disturb it.
- Do not fix this by running with one worker, by forcing spec order, or by enabling retries. Each of those hides the coupling and slows every run.
- Grep the suite for other tests that mutate seeded rows. The same pattern is likely elsewhere.

### orders > shows the latest order first

**What is happening.** The test is sound. It uses a fresh user per run and web-first assertions, and it still fails three of fifty in isolation. The failing runs show GET /orders omitting the just-created order for up to two seconds. That is a read-after-write consistency gap in the orders service, probably a read replica, a cache, or asynchronous indexing. A retrying assertion cannot help because the page fetches the list once and renders it. A real user who places an order and lands on the list page will sometimes not see it, which is a product bug.

**What to do.**
- File a bug against the orders service with the fifty-run evidence. The fix belongs there: read from the primary after a write, invalidate the cache on create, or return the created order so the UI can merge it.
- Quarantine the test with the ticket number and an expiry date so it stops blocking merges while the bug is open. Keep it running in a non-blocking job so you can see when the fix lands.
- Do not loosen the test by adding a reload loop or a longer timeout unless product explicitly decides that a two-second delay is acceptable behaviour. If they do, encode that decision as a poll that reloads with a documented bound, and say why in the test.

### Suite-wide

- Keep retries at zero. It is the reason these ten runs produced usable data. Turning retries on would have hidden cart, search, and orders and left profile as the only visible failure.
- Add trace retention on failure to the shared Playwright config. Three of the four diagnoses above would have been immediate with a trace.
- Define flaky as a test that both passes and fails on the same commit. Profile does not meet that bar, and orders meets it only because the app is flaky, not the test.
- Re-run the same ten-run check on the fix commit. The target is zero failures on cart and search, profile green, and orders still failing in the non-blocking job until the service fix ships.
