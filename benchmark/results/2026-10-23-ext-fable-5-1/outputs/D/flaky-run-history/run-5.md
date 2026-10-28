# Flaky-test analysis: e2e suite, commit c0ffee1, main

**Evidence base.** Read only: ten CI runs on the same commit (Playwright, 4 workers, retries 0, 120 tests) and the repeat-run outputs quoted in the request. Nothing was run in this session. Rates below are observed on 10 CI runs; they bound the flake rate, they do not fix it.

## 1. Detection

| Test | Runs | Failures | Verdict |
| --- | --- | --- | --- |
| cart > updates the total when the quantity changes | 10 | 3 | Flaky (both outcomes on unchanged code) |
| search > filters results by tag | 10 | 4 | Flaky |
| orders > shows the latest order first | 10 | 2 | Flaky |
| profile > saves a new avatar | 10 | 10 | **Not flaky: deterministic failure** (listed apart, section 4) |
| login > signs in with valid credentials | 10 | 0 | 0 failures in 10 runs (not proof of zero) |

## 2. Classification and action per flaky test

### cart > updates the total when the quantity changes — class: test timing

- **Evidence.** Hard sleep (`page.waitForTimeout(300)`) between the click and the read; the failure is always the same `toHaveText` timeout. Under 4 workers the re-render takes longer than 300 ms some of the time, and the 5 s assertion window then expires while the test is still looking at the pre-click state or a stale render.
- **Action.** Fix the test, not the product. Remove the sleep; wait for the response that updates the cart (`page.waitForResponse` on the cart/quantity call, or `expect(locator).toHaveText('€58.00')` with no sleep in front of it) so the web-first assertion retries until the total changes. If the 5 s window is still hit after that, the product is slow, not the test, and it becomes a performance finding.
- **Assumption.** The "+" click triggers a network request. If it is purely client-side, the fix is the same minus the response wait.
- **Exit proof.** `npx playwright test cart.spec.ts --workers=4 --repeat-each=50` green, plus red-green: break the total computation (or stub the response with the old total) and confirm the test fails.

### search > filters results by tag — class: order or shared state

- **Evidence.** Passes 20/20 alone with `--workers=1`; fails 4/10 in the suite with the same message (5 results instead of 3). `tags.spec.ts` renames the seeded tag "summer" during its own run; when the two specs overlap across workers, the search runs against a renamed tag and the filter no longer matches the seeded set.
- **Action.** Fix isolation, in both specs. `search.spec.ts` should create its own tag and its own tagged items (unique name per run) in a `beforeEach` and assert against them; `tags.spec.ts` should rename a tag it created, not the shared seed. Do not "fix" this with serial mode or a fixed worker order; that hides the coupling and slows the suite.
- **Exit proof.** Full suite at `--workers=4` repeated (e.g. 10 CI runs or `--repeat-each=10` on both specs together), then red-green: break the tag filter and confirm `search.spec.ts` fails.

### orders > shows the latest order first — class: product intermittent defect

- **Evidence.** The test already uses web-first assertions and a new user per run, so test timing and shared data are excluded. Still fails 3/50 alone and 2/10 in CI, and in the failing runs `GET /orders` returns a list without the just-created order for up to 2 s after creation. That is eventual consistency (read replica lag or a cache) in the product, not in the test.
- **Action.** Report via `/qa-defect` as a **product** defect with the observed frequency (3 of 50 alone, 2 of 10 in CI, up to 2 s stale reads). Quarantine while it is open, but quarantine alone would hide it: the defect report is the deliverable. Do not add a retry or a sleep to the test; that would turn a real read-after-write bug into a pass.
- **For the product team.** Decide whether read-after-write consistency on `GET /orders` is required (then fix it) or whether the UI must handle it (then the spec changes and the test with it).
- **Exit proof.** Only after the product fix: `--repeat-each=50` green on the fix commit, and red-green by reintroducing the lag (e.g. route-stub a stale response) to confirm the test still fails.

## 3. Quarantine proposal and ledger

The team decides; nothing is tagged or excluded by this analysis.

| Test ID | Cause class | Defect report | Owner | Quarantined on | Deadline | Status |
| --- | --- | --- | --- | --- | --- | --- |
| cart > updates the total when the quantity changes | Test timing | none (test fix) | QA automation owner (to assign) | 2026-10-26 | 2026-11-09 | proposed |
| search > filters results by tag | Order or shared state | none (test fix) | QA automation owner (to assign) | 2026-10-26 | 2026-11-09 | proposed |
| orders > shows the latest order first | Product intermittent defect | DR to be opened via `/qa-defect` | Orders service owner (to assign) | 2026-10-26 | 2026-11-09 | proposed |

- **Share.** 3 quarantined of 120 listed tests = 2.5%. Assumption: 120 is the `npx playwright test --list` count. I cannot compare this against the rule's threshold (see note at the end); the team should check it.
- **Deadline.** Assumption: one two-week sprint from the quarantine date. Replace with the rule's period if it differs.
- **Exclusion.** Add `--grep-invert @quarantine` to the `@smoke` and `@regression` jobs, and keep a separate non-blocking job that runs `--grep @quarantine` so a fix becomes visible without un-quarantining first.
- **Sequence per the protocol.** Tag `@flaky` now, open the defect report (orders only), then move to `@quarantine`. A row with no owner is not a quarantine; owners must be filled in before the tags land.
- **Not a fix.** Raising `retries` would turn the orders defect and the search coupling into green runs. Leave `retries: 0` until the three fixes above are proven.

## 4. Deterministic failure (not flaky)

**profile > saves a new avatar** fails 10/10 with `Expected: "avatar.png", Received: undefined`. Same commit, same message every time: this is a real, reproducible failure, and it is either a product regression (the saved profile no longer carries the avatar filename) or a test reading a field that no longer exists. The history cannot tell which.

- **What decides it.** Run the spec once with the trace viewer and inspect the profile response after upload. Field present under a different name: fix the test. Field absent: product defect, file via `/qa-defect` as Always (10/10 observed).
- **Do not quarantine it.** Quarantining a 100% failure is how a graveyard starts. Fix it or report it in this sprint; if the team chooses to skip it meanwhile, record the reason in the ledger.

## 5. What this history cannot show

- Only ten runs were kept; flake rates of 20–40% are coarse estimates and the login test's 0/10 says nothing below a ~10% rate.
- No runs before c0ffee1, so whether any of these started on this commit or earlier is unknown.
- The orders lag is observed from the client; its cause (replica, cache, queue) is outside the repository and needs the service owner.
- Whether other specs besides `tags.spec.ts` mutate seeded data is not visible here; a sweep of the specs for writes to seed fixtures would tell.

**Rule not applied.** The `testing-guidelines` rule (quarantine period and the escalation threshold and escalation target) was not loaded in this session and no `qa-rules` skill is installed, so the deadline and share comparison above are stated as assumptions rather than the rule's figures.
