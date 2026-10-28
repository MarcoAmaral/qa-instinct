# Flakiness analysis: e2e suite, commit c0ffee1, 10 runs

## Summary

| Test | Failures | Verdict | Root cause class | Action |
| --- | --- | --- | --- | --- |
| cart > updates the total when the quantity changes | 3/10 | Flaky | Timing in the test (fixed sleep, click race) | Fix the test now |
| profile > saves a new avatar | 10/10 | Not flaky, broken | Deterministic bug (test or product) | Fix or quarantine with ticket, blocks merge |
| search > filters results by tag | 4/10 | Flaky | Test isolation (shared seed data mutated by another spec) | Fix data ownership in both specs |
| orders > shows the latest order first | 2/10 | Flaky, but the test is right | Read-after-write lag in the product | File a product bug, make the test tolerate the agreed SLA |
| login > signs in with valid credentials | 0/10 | Stable | None | No action |

Assumptions used throughout: the other 115 tests passed in all 10 runs; the CI machine runs 4 workers on shared CPU; the suite seeds one shared database per run; the failure messages are complete as quoted. "Flaky" here means the same code produces different results on repeated runs with no change in inputs.

## Per-test findings

### 1. cart > updates the total when the quantity changes

**Observed.** Failed R2, R5, R9. The assertion is a web-first `toHaveText` that gave up after its 5 s default. The test sleeps 300 ms with `waitForTimeout` between clicking "+" and asserting.

**Why it is flaky.** The 5 s auto-retrying assertion means the total never reached "€58.00" within roughly 5.3 s, so a slow render alone does not explain it. Two mechanisms fit the evidence, and both are made worse by 4 workers competing for CPU:

- **Lost click.** The page is visible before its handlers are attached. Under load, hydration takes longer, the click lands on a button with no handler, nothing happens, and the total correctly stays at the old value. The test then waits 5 s for a change that was never triggered.
- **Slow recalculation.** If the total comes from a server round trip after the click, that call can exceed 5 s on a loaded runner.

The fixed 300 ms sleep is a symptom, not the cause. It neither prevents the lost click nor helps the slow path, and it adds 300 ms to every run.

**What to do.**

1. Pull the Playwright trace for a failing run and check whether the quantity field changed. If quantity did not change, it is the lost click. If quantity changed but the total did not, it is the slow recalculation.
2. Remove the `waitForTimeout(300)`.
3. Before clicking, wait for a real readiness signal: the "+" button enabled, or a hydration marker, or `await expect(quantity).toHaveValue('1')`.
4. After clicking, assert the quantity first, then the total. This separates the two failure modes in future reports.
5. Only if the trace shows a genuinely slow server call, raise the timeout on that one assertion and open a performance ticket. Do not raise the global expect timeout.

Owner: cart team. Priority: this week. It is the most frequent flake and cheap to fix.

### 2. profile > saves a new avatar

**Observed.** Failed 10 of 10 with `Expected "avatar.png", Received undefined`.

**Why it is not flaky.** A test that fails every time on the same commit is deterministic. Calling it flaky would hide a real regression. `undefined` points to a property that no longer exists where the test reads it: a renamed field in the API response, a changed data-testid, or an upload that silently fails.

Assumption: this test passed on the parent of c0ffee1. If it never passed, the test was merged broken and the same actions apply.

**What to do.**

1. Bisect against the previous green commit to decide whether the product or the test changed.
2. If the product changed intentionally, update the test. If not, this is a user-facing avatar bug and should block the release.
3. If it cannot be fixed within a day, quarantine it with `test.fixme` and a ticket link so the suite goes green for the right reasons. Do not leave it red, because a permanently red suite trains people to ignore CI.

Owner: profile team. Priority: today.

### 3. search > filters results by tag

**Observed.** Failed R2, R4, R7, R10 with 5 results instead of 3. Passes 20 of 20 alone with one worker.

**Why it is flaky.** Classic test pollution. Both specs use the seeded tag "summer". `tags.spec.ts` renames it, and whether `search.spec.ts` sees 3 results or 5 depends on which worker gets there first. With 4 workers the order changes every run, so the outcome does. The 20/20 pass in isolation confirms the test logic is correct and the data is shared. Note the cart and search failures do not coincide across runs beyond R2, so they are independent problems.

**What to do.**

1. Give each spec its own data. `search.spec.ts` should create a uniquely named tag in `beforeEach` (for example `summer-<testInfo.testId>`) and tag its own fixtures with it.
2. `tags.spec.ts` should also create the tag it renames instead of mutating the shared seed.
3. Treat the seed as read-only across the suite and add a lint or review rule to that effect.
4. Do not fix this by setting workers to 1 or by serialising the two specs. That hides the coupling and slows the suite roughly fourfold.

Owner: search team, with a small change in tags.spec.ts. Priority: this week.

### 4. orders > shows the latest order first

**Observed.** Failed R3, R8 in CI. Alone, with web-first assertions and a fresh user per run, it still failed 3 of 50. In those runs `GET /orders` omitted the new order for up to 2 s after creation.

**Why it is flaky.** The test is already written correctly and isolated. The variability comes from the system under test: an order is created, and a subsequent read does not include it. That is read-after-write inconsistency, typically a read replica, a cache, or an asynchronous write path. The test is detecting a real behaviour, and a user who refreshes right after checkout can see the same thing.

**What to do.**

1. File a product bug with the 2 s window and the 6 % reproduction rate. The owning backend team decides whether this is acceptable eventual consistency or a defect. My recommendation is defect, because the screen's purpose is to show the newest order first.
2. Until that is resolved, make the test tolerate the agreed window with `expect.poll` or `toPass` on the orders list, bounded to the documented SLA plus margin, with a comment linking the ticket. The default 5 s assertion timeout should already cover 2 s, so check whether the "latest first" assertion is on a list item that renders before the refetch completes.
3. When the product bug is fixed, remove the tolerance so the test guards the fix.

Owner: orders backend for the bug, e2e owners for the interim tolerance. Priority: file the bug today, test change this week.

### 5. login > signs in with valid credentials

**Observed.** 10 of 10 passes.

**Assessment.** No evidence of flakiness. Ten runs cannot prove stability. A test with a 10 % failure rate still passes ten in a row about a third of the time, so keep collecting history rather than marking anything "known stable".

## Suite-level recommendations

- **Keep retries at 0 on main for now.** It made these four signals visible. Once the fixes land, retries of 1 with flaky reporting enabled is reasonable, provided flaky results are tracked and not silently green.
- **Adopt a quarantine policy.** A test that fails deterministically or flakes above an agreed threshold gets a ticket and `test.fixme` within one working day, with an owner and a due date. Quarantined tests are reviewed weekly.
- **Ban `waitForTimeout` in e2e code** via an ESLint rule. Every instance is either unnecessary or hiding a missing readiness signal.
- **Make seed data read-only across specs.** Tests that mutate data create it themselves. This removes the whole class of failure seen in search.
- **Track flake rate per test over a rolling 30 runs**, not 10, so decisions rest on more than this sample.
