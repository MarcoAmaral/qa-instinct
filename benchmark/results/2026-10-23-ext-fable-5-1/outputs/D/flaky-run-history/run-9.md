# Flaky-test analysis: e2e suite, commit c0ffee1, main

**Evidence basis.** Everything here was read from the ten CI runs and the four repeat-run notes supplied. Nothing was run in this session. Runs: 10, all on c0ffee1, Playwright, 4 workers, retries 0, so there is no runner `flaky` outcome to lean on; a test either flipped across runs or it did not.

**Assumptions** (information missing from the input):

- The other 115 tests passed in all 10 runs. Only the five listed are assessed.
- The team runs two-week sprints, and the quarantine period is one sprint, so a quarantine opened today (2026-10-26) expires 2026-11-09.
- The escalation threshold and the escalation target come from the `testing-guidelines` rule, which is not loaded here (see the last section). I report the share and leave the comparison to the rule.
- The cart failure message did not include the received text of `cart-total`. If it did, it decides the cart case (see below).
- Defect IDs below are proposals; the team's tracker assigns the real ones.

## 1. Verdicts

| Test | Runs | Failures | Verdict |
| --- | --- | --- | --- |
| cart > updates the total when the quantity changes | 10 | 3 | Flaky |
| profile > saves a new avatar | 10 | 10 | **Deterministic failure, not flaky** |
| search > filters results by tag | 10 | 4 | Flaky |
| orders > shows the latest order first | 10 | 2 | Flaky |
| login > signs in with valid credentials | 10 | 0 | Not a suspect: 0 failures in 10 runs (a bound, not a proof) |

## 2. Deterministic failure (report separately, do not quarantine)

### profile > saves a new avatar

- **Evidence:** 10 of 10 failed with the same assertion: expected `"avatar.png"`, received `undefined`. The verdict never changed on unchanged code, so it is not flaky and quarantine would only hide it.
- **What it means:** the field the test reads is absent after the save. Either the product stopped returning or rendering the avatar filename, or the response shape changed and the test reads a property that no longer exists. The history cannot tell which: no earlier commit is in the data.
- **Action:** debug now, not later. Open the trace of any failed run and check the save response body. If the filename is missing from the response, file a product defect, frequency "Always (10/10 on c0ffee1)", via `/qa-defect`, and find the commit that introduced it. If the response carries the filename under another key, the test is wrong; fix the test and prove red-green. Either way this test is red on main today with retries 0, so it blocks the build until someone owns it. Proposed report: DR-PROF-001.

## 3. Flaky tests, classified

### cart > updates the total when the quantity changes

- **Observed:** 3 of 10 CI runs. Message: 5000 ms timeout waiting for `cart-total` to have text `"€58.00"`. The test clicks "+", sleeps 300 ms with `page.waitForTimeout`, then asserts.
- **Class: unknown. Leading hypothesis test timing, not confirmed.** The hard sleep is a timing smell and breaks the no-sleeps rule, but it is not the whole story: `toHaveText` already retries for 5 s, so the total never reached €58.00 for over 5 s after the click. That is consistent with three different causes:
  1. The click landed before the "+" handler was attached (hydration or re-render race), so no update was ever requested. Class: test timing.
  2. Another worker changed the same cart (shared user or shared cart fixture), so the total settled on a different value. Class: test data collision.
  3. The update request was sent and the product computed or rendered the wrong total. Class: product intermittent defect.
- **What decides it:** the trace of one failed run (`trace: 'on-first-retry'` does nothing with retries 0, so set `trace: 'retain-on-failure'` on this project). Check the network panel after the click: no cart request means cause 1; a request and a response with a total other than €58.00 means cause 2 or 3, distinguished by whether the cart fixture is private to the test; a correct response and a stale DOM means cause 3. The received text in the error message, if the team has it, narrows this immediately.
- **Fix to apply regardless:** remove `waitForTimeout(300)`; after the click wait for the cart update response (`page.waitForResponse` on the cart endpoint) or assert an intermediate state, then assert the total with a web-first assertion. If this alone makes `--repeat-each=50 --workers=4` pass, cause 1 was it. Red-green proof: break the quantity-to-total computation and confirm the test fails.
- **Proposed handling:** tag `@flaky` now; quarantine only if the trace triage does not produce a fix within the week, because a test of cart arithmetic is one the team wants running.

### search > filters results by tag

- **Observed:** 4 of 10 CI runs; expected 3 results, received 5. Alone (`search.spec.ts --workers=1 --repeat-each=20`) it passed 20 of 20.
- **Class: order or shared state (cross-spec data).** Passes alone, fails in the suite, and the mechanism is named: `tags.spec.ts` renames the seeded tag "summer" during its own run. With 4 workers the two specs run on different workers, and which one touches "summer" first depends on scheduling, which fits a 40 percent rate. The 20-of-20 run bounds the standalone failure rate below about 5 percent; it does not prove zero.
- **Fix the isolation, not the symptom:** both specs must stop sharing a seeded row. Preferred: each test creates its own tag with a unique name (for example suffixed with `testInfo.workerIndex` and a timestamp) and deletes it afterwards. Minimum: `tags.spec.ts` renames a tag it created itself, never a seeded one. Do not serialise the two specs or pin the order; that hides the coupling and will reappear with the next spec that touches tags. Proof: `--repeat-each=20 --workers=4` on the full suite with no failures, then break the tag filter and confirm the test fails.
- **Proposed handling:** tag `@flaky`, fix this sprint. No quarantine needed if the fix lands within the week; otherwise move to `@quarantine` so a known data race stops reddening main. No defect report: the product behaves correctly.

### orders > shows the latest order first

- **Observed:** 2 of 10 CI runs; expected `Order #1043`, received `Order #1042`. Repeat run alone, 50 iterations, web-first assertions, a new user per run: 3 of 50 failed, and in those runs `GET /orders` returned the list without the new order for up to 2 s after creation.
- **Class: product intermittent defect.** The test has correct waits and private data and still fails; the server itself serves a stale list. That is a read-after-write gap in the product (eventual consistency, a read replica, or a cache), not test noise. Quarantine alone would hide it.
- **Action:** file a product defect now via `/qa-defect`, frequency "Intermittent: 2/10 in CI, 3/50 in isolation", with one failing trace and the stale `GET /orders` response as evidence. Proposed report: DR-ORD-001. The product owner must say whether a user who just placed an order is guaranteed to see it (then the lag is a defect to fix) or whether a bounded lag is acceptable (then the lag becomes a documented product behaviour and the test waits for it explicitly, with the stated bound as the timeout). Do not quietly extend the expect timeout before that decision is recorded; that converts a product finding into test configuration.
- **Proposed handling:** tag `@flaky`, open DR-ORD-001, move to `@quarantine` with the ledger row below. Exit when the fix commit passes `--repeat-each=50` and the test still fails when the sort order is broken.

## 4. Quarantine ledger (proposed rows for `flaky/ledger.md`)

| Test ID | Cause class | Defect report | Owner | Quarantined on | Deadline | Status |
| --- | --- | --- | --- | --- | --- | --- |
| orders > shows the latest order first | Product intermittent defect | DR-ORD-001 (to file) | to assign | 2026-10-26 | 2026-11-09 | quarantined |
| search > filters results by tag | Order or shared state | none (test fix) | to assign | not yet | 2026-11-09 if quarantined | @flaky, fix in progress |
| cart > updates the total when the quantity changes | unknown (timing suspected) | pending trace triage | to assign | not yet | 2026-11-09 if quarantined | @flaky, triage |

A row with no owner is not a quarantine. Each row needs a named person before the tag is applied.

**Share of the suite:** 1 of 120 quarantined today (0.8 percent); 3 of 120 (2.5 percent) if cart and search also go in. Confirm 120 against `npx playwright test --list` before recording the share. Whether this crosses the escalation threshold is decided by the `testing-guidelines` rule, which was not available here.

**Exclusion:** add `--grep-invert @quarantine` to the `@smoke` and `@regression` jobs, and run a separate non-blocking job with `--grep @quarantine` so the fix for orders becomes visible the day it lands.

**Do not:** raise `retries` to make these green. With retries at 1 the search and cart failures would mostly vanish from the pass/fail column and the orders defect would never have been seen. Keep retries 0 until these four are closed, then decide on retries for CI noise only.

## 5. Red-green proof required for every exit

Before removing a tag, record on the fix commit:

1. The repeat-run command and its output (suggested sizes: cart and search `--repeat-each=20 --workers=4`; orders `--repeat-each=50`).
2. A deliberate break of the behaviour under test (wrong total, broken tag filter, wrong order sort) with the test failing. A test that can no longer fail is not fixed.

## 6. What this history cannot show

- Runs before these ten, so no baseline rate and no commit where profile or orders started failing.
- Whether the other 115 tests ever flipped; assumed all green.
- The received text of `cart-total` at timeout, and the trace network timeline for any failed run.
- Environment facts outside the repository: whether CI runners were under load during R2, R5 and R9, and what sits behind `GET /orders` (replica, cache, queue).

**Rule not applied:** the `testing-guidelines` rule (the flaky-test protocol with the quarantine period and escalation threshold) is not loaded, and no `qa-rules` skill is installed to read it from. Deadline and threshold above are stated assumptions; replace them with the rule's values before recording the ledger.
