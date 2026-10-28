# Flaky test analysis: e2e suite, commit c0ffee1, 10 CI runs

**Evidence used.** Only read, nothing run by me: the 10-run CI table (Playwright, 4 workers, retries 0, 120 tests) and the two repeat runs the team already did (search alone, orders alone). Rates from 10 runs are coarse; they rank the suspects, they do not measure them.

**Headline.** One deterministic failure, three flakes, one clean test. Every run was red because of the deterministic failure. With it excluded, 8 of 10 runs would still have been red from the three flakes on unchanged code.

## Verdict per test

| Test | Failures | Class | Verdict |
| --- | --- | --- | --- |
| profile > saves a new avatar | 10 of 10 | Deterministic failure | Not flaky. Defect, not quarantine |
| search > filters results by tag | 4 of 10 in suite, 0 of 20 alone | Order or shared state | Flaky. Fix isolation now |
| orders > shows the latest order first | 2 of 10 in suite, 3 of 50 alone | Product intermittent defect | Flaky. Product defect report, quarantine while open |
| cart > updates the total when the quantity changes | 3 of 10 | Unknown (see below) | Flaky. Diagnose with the trace, quarantine meanwhile |
| login > signs in with valid credentials | 0 of 10 | Not a suspect | 0 failures in 10 runs. Bounds the rate, does not prove zero |

### profile > saves a new avatar (deterministic, listed apart)

Same assertion failure in all 10 runs: expected "avatar.png", received undefined. This is a broken build on main, not a flake. The history cannot say whether the product stopped returning the avatar field or the test reads a property that no longer exists. Either way it needs one owner today: file it with `/qa-defect` at frequency "Always (10 of 10)", and fix or revert on main. Do not put it in the ledger and do not tag it `@quarantine`, because that would hide a failure that reproduces every time.

### search > filters results by tag (order or shared state)

Passes 20 of 20 alone with one worker, fails 4 of 10 in the suite. The cause is named in the evidence: tags.spec.ts renames the seeded tag "summer" that search.spec.ts filters on, so whenever a worker runs the rename before the search, two extra untagged items leak in (5 instead of 3). The isolation violation is in tags.spec.ts, which mutates shared seed data. Fix both sides:

- tags.spec.ts creates its own tag in `beforeEach` and renames that, so no shared seed is ever mutated.
- search.spec.ts creates its own tagged items with a unique tag per run, so it no longer depends on any seed another spec could touch.

Exit proof: `npx playwright test search.spec.ts tags.spec.ts --workers=4 --repeat-each=20` with 0 failures, then three green full-suite runs. Red-green: break the filter so it returns all items; the test must fail. Tag `@flaky` now. Quarantine only if the fix is not merged by the deadline below.

### orders > shows the latest order first (product intermittent defect)

The team's own hunt already ruled out the test: web-first assertions, a new user per run, run alone, and it still failed 3 of 50. In those runs GET /orders returned a list without the new order for up to 2 seconds after creation. The page fetches once and renders, so the retrying assertion waits on a DOM that will never change. A user who places an order and opens the orders page within 2 seconds sees the same thing. This is read-after-write inconsistency in the orders API (assumption: replica lag or a cache), not a test problem.

- File with `/qa-defect` as a product defect, frequency "Intermittent: 3 of 50 isolated, 2 of 10 in CI", with the request timestamps from the 3 failed runs.
- Do not fix the test by reloading until the order appears. That would make the test pass while hiding the defect users hit.
- Quarantine while the defect is open. Exit when the fix commit passes `npx playwright test orders.spec.ts --workers=4 --repeat-each=50` with 0 failures, and the red-green check (sort ascending, test fails) still holds.

### cart > updates the total when the quantity changes (unknown)

The 300 ms sleep violates the no-sleeps rule and must go, but it does not explain the failure. The message is from a retrying `toHaveText`, so the total did not reach €58.00 for a further 5 seconds. Three causes fit and the evidence does not pick one:

- The click was lost (fired before the handler was attached), so the total never changed. Test timing, or a product hydration race.
- Another worker's test shares the same cart or user, so the total went to a different value. Shared state.
- Cart recalculation takes over 5 seconds under 4-worker load. Environment.

What decides it: the "Received string" from the failed reports (unchanged total, a foreign total, or €58.00 arriving late) plus the trace of one failed run showing whether the cart update request fired and what it returned. Also `npx playwright test cart.spec.ts --repeat-each=30` at `--workers=4` and again at `--workers=1`. Quarantine with the diagnosis as the first task. Removing the sleep alone, without this evidence, is not a fix and must not retire the row.

## Quarantine ledger (proposed, the team decides)

Assumptions: the rule's quarantine period is one two-week sprint, so deadline is 2026-11-09. Owners are the squads owning each feature; a named person must replace the squad before a row counts as a quarantine.

| Test ID | Cause class | Defect report | Owner | Quarantined on | Deadline | Status |
| --- | --- | --- | --- | --- | --- | --- |
| search > filters results by tag | Order or shared state | Test fix, no product defect | Search squad | 2026-10-26 (`@flaky` only) | 2026-11-09 | fix in progress, quarantine if not merged by deadline |
| orders > shows the latest order first | Product intermittent defect | DR to file (orders API read-after-write) | Orders squad | 2026-10-26 | 2026-11-09 | quarantined, awaiting product fix |
| cart > updates the total when the quantity changes | Unknown | None until diagnosed | Checkout squad | 2026-10-26 | 2026-11-09 | quarantined, diagnosis first |

**Share.** 3 quarantined of 120 listed tests is 2.5% (confirm the count with `npx playwright test --list`). I could not read the rule's escalation threshold; at 2.5% I assume it is below, but check it against the rule and escalate to whoever the rule names if not.

**CI changes.** Add `--grep-invert @quarantine` to the `@smoke` and `@regression` jobs. Add one non-blocking job that runs `--grep @quarantine` on every push so a fix becomes visible. Keep retries at 0. Raising retries would turn the orders defect into a green run and that is the one outcome to avoid.

**At the deadline.** Each row is either retired with the repeat-run output and red-green proof recorded, extended with a recorded decision and new date, or deleted with the reason in the ledger. Nothing stays quarantined without a date.

**What the history cannot show.** Runs before these 10, whether any of these tests also failed on other commits, the received values and traces of the failed runs (not in the summary I was given), whether the cart test shares a user with other specs, and whether the orders inconsistency reproduces in production.

**Rule not applied.** The `testing-guidelines` rule was not in context, no `qa-rules` skill is installed, and the file search for it was denied, so the quarantine period and escalation threshold above are stated assumptions rather than the rule's values. The `qa-reference` files `automation-ci.md` and `testing-design.md` were not read either; the hunt commands above are from the skill text and Playwright defaults.
