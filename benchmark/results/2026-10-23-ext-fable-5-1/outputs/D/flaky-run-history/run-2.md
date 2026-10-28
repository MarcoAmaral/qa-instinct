**Flaky-test analysis, commit c0ffee1 on main, 10 CI runs, Playwright, 4 workers, retries 0**

**What was run and what was only read.** Nothing was run for this analysis. Every verdict below comes from the ten-run table, the failure messages, and the two repeat runs the team reported. The `testing-guidelines` rule and the `automation-ci` reference were read. The deadline, the threshold and the escalation target are the rule's. `retries: 0` is the right setting for this history: it exposes the true rate, and nothing below asks to raise it.

**Assumptions, stated so the team can correct them**

- The other 115 tests passed in all 10 runs.
- Sprint length is 2 weeks, so the rule's 2-sprint deadline is 4 weeks after quarantine.
- Quarantine date is 2026-10-26, the day the team adopts this.
- The suite size of 120 is the team's figure. `npx playwright test --list` was not run to confirm it.
- Each test signs in as its own user. This is confirmed for orders and not stated for cart or profile.
- A trace exists for at least one failed run of each test. If not, set `trace: 'retain-on-failure'` before the next run, because with retries at 0 the on-first-retry setting never captures anything.
- No seeded flake was introduced in this history.

## Verdicts

| Test | Failures / runs | Verdict | Cause class |
| --- | --- | --- | --- |
| cart > updates the total when the quantity changes | 3 / 10 | Flaky | Unknown: test timing, environment or product. The trace decides. |
| profile > saves a new avatar | 10 / 10 | Deterministic failure, not flaky | Defect, report now, not quarantine |
| search > filters results by tag | 4 / 10 in CI; 0 / 20 alone, 1 worker | Flaky | Order or shared state: cross-spec data collision |
| orders > shows the latest order first | 2 / 10 in CI; 3 / 50 alone | Flaky | Product intermittent defect: read-after-write lag |
| login > signs in with valid credentials | 0 / 10 | Not a suspect | 0 failures in 10 runs bounds the rate; it does not prove zero |

## What to do with each

**cart > updates the total when the quantity changes.** The assertion is already web-first: `toHaveText` retried for 5 seconds and the total never became €58.00. So the 300 ms sleep did not cause the failure on its own, and removing it will not by itself fix anything. What the message does say is that for 5.3 seconds after the click the DOM never showed the expected total. Three causes fit, and the evidence given cannot separate them:

1. The click lands before the handler is attached, so the quantity never changes. That is test timing if the control signals readiness and the test should wait for it, and a product defect if the button is clickable before it works.
2. The cart update request takes longer than 5 seconds under 4 workers. That is environment.
3. The total changed to a different value, such as a double increment. That is a product defect.

What decides it is the `Received` string, which the message as kept does not include, and the trace of one failed run: did the quantity field change, did a request go out, what did it return and when. Actions:

- Delete the sleep. It violates the no-sleep rule and hides nothing useful.
- Wait for the cart update response, then assert, following the `automation-ci` "Wait for Network State" pattern.
- Tag `@flaky`, open a defect report with "3 failures in 10 runs on c0ffee1", move to `@quarantine`.
- Reproduce with a trace and read it:

```bash
npx playwright test cart.spec.ts --repeat-each=50 --workers=4 --trace=on
npx playwright show-trace test-results/<failed-run>/trace.zip
```

- Exit: 0 failures in the 50-run repeat on the fix commit with the command and output recorded, and the test still fails when the total is wrong. Verify that by temporarily asserting the wrong amount or breaking the price calculation locally. If the trace shows the request returned the right total and the UI did not update, reclassify as a product defect and keep the test quarantined until the product fix.

**profile > saves a new avatar.** This is not flaky. It failed in every one of the 10 runs with the same message, so it is a deterministic failure on main. Do not quarantine it: quarantine is for tests whose verdict changes, and tagging this one would hide a red main. `Received: undefined` means the property the test asserts does not exist on whatever it read. Either the test reads the wrong field or selector, or the product does not return or persist the filename after save. The history cannot say which, and nobody should guess in the report. Actions:

- Debug first, per CTFL §1.1.2: open one failed trace, find the save request, and check whether the response carries the filename. That one fact decides test versus product.
- Report it now with `/qa-defect`, frequency "10 of 10 runs on c0ffee1", describing the failure and, only if the trace shows it, the defect location. If the cause turns out to be the test, close the report as not a defect, which §5.5 allows.
- If this test carries `@smoke`, the rule's stop line applies and the merge or deploy is blocked until it is resolved. The tag was not given; the team must check.
- The history cannot show when it started failing, because all 10 runs are the same commit. Look at the last green run of this test to find the introducing change.

**search > filters results by tag.** Flaky, cause known. It fails only in the suite, passes 20 of 20 alone with one worker, and the message explains why: it expects 3 results for the seeded tag "summer", and `tags.spec.ts` renames that tag during its own run. With 4 workers, whether the rename happens before the search decides the verdict. It is a test-isolation problem, not a product one. Actions:

- Fix the data setup so neither spec depends on the shared seed: search creates its own tag with a unique name in a fixture and filters by that, and tags renames a tag it created itself. Either fix alone closes this collision, both together prevent the next one.
- Tag `@flaky`, open a defect report on the test suite, quarantine, and fix inside the deadline. This one should be the first to retire.
- Exit: repeat in the suite with CI's worker count, not alone, because alone already passes:

```bash
npx playwright test --workers=4 --repeat-each=10 search.spec.ts tags.spec.ts
```

Record the output. Red-green: the test must still fail when the filter returns untagged items, for example by filtering with a tag that has 5 items and keeping the expectation at 3.

**orders > shows the latest order first.** Flaky, cause known, and it belongs to the product. The team already did the hunt properly: web-first assertions, a new user per run, 3 failures in 50 alone. In the failed runs `GET /orders` omitted the just-created order for up to 2 seconds. The web-first assertion did not save it because the page fetched the list once, rendered #1042 first, and never re-fetched, so retrying the assertion against a DOM that does not change cannot help. A user who places an order and opens the orders page sees it missing. That is read-after-write lag, most likely a replica or cache, and quarantining alone would hide it. Actions:

- Report with `/qa-defect` as a product defect, frequency "3 of 50 repeat runs and 2 of 10 CI runs on c0ffee1", with the request and response timings as evidence.
- Tag `@flaky`, quarantine, and leave the test unchanged. Do not add a reload loop or a longer wait: that turns a product defect into a green test.
- One decision belongs to the product owner: if the list is meant to be eventually consistent, the bound must be written down, the defect becomes a documented behaviour, and the test may then poll the API for the new order before navigating. Record that decision in the ledger. Until it is made, the defect stands.
- Exit on the product fix: 0 failures in 50 with the same isolation the team already uses, output recorded, and the test still fails when ordering is wrong. Verify by sorting ascending locally.

**login > signs in with valid credentials.** Not a suspect. 0 failures in 10 runs. That bounds its rate; it does not prove zero.

## Ledger, exclusion and share

Rows for `flaky/ledger.md`. The owner column is unfilled because the history names nobody, and by the rule a row without an owner and a deadline is not a quarantine. The team fills it at triage before tagging anything. Defect report IDs are to be assigned when `/qa-defect` runs.

| Test ID | Cause class | Defect report | Owner | Quarantined on | Deadline | Status |
| --- | --- | --- | --- | --- | --- | --- |
| cart > updates the total when the quantity changes | Unknown, trace decides | to file, test suite until the trace says otherwise | to assign | 2026-10-26 | 2026-11-23 | quarantined |
| search > filters results by tag | Order or shared state | to file, test suite | to assign | 2026-10-26 | 2026-11-23 | quarantined |
| orders > shows the latest order first | Product intermittent defect | to file, product | to assign | 2026-10-26 | 2026-11-23 | quarantined, blocked on product fix or PO decision |

The profile test has no row. It is a red test with a defect, not a quarantined one. If the team decides it must leave the gate while the defect is open, use `test.fixme` with the report ID in the annotation, not `@quarantine`, so it does not count as a flake.

Share:

| Quarantined | Suite | Share | Threshold | Escalation |
| --- | --- | --- | --- | --- |
| 3 | 120 | 2.5% | 5% | not triggered |

The share stays at 3.3% even if the team also excludes the profile test, still below the threshold. Should it ever cross 5%, the rule says escalate to the Development Lead. The suite size comes from the team, not from a `--list` run.

CI changes, proposed for the team to apply:

- Add `--grep-invert @quarantine` to the `@smoke` and `@regression` jobs.
- Add a separate, non-blocking job that runs only the quarantined tests with the same 4 workers and `retries: 0`, so a fix becomes visible:

```bash
npx playwright test --grep @quarantine --workers=4
```

- Keep `retries: 0`. Raising it is not a fix and would hide the orders defect.
- No script quarantines or deletes on its own. The team decides.

At the deadline, each row is either retired with the repeat-run output and the red-green proof recorded, deleted with the reason written in the ledger, or extended with a recorded decision and a new date.

**What this history cannot show**

- The `Received` string and traces for the cart failures. Without them its class stays unknown.
- Whether the profile failure is in the test or the product, and when it began, because all 10 runs share one commit.
- Whether any of the 10 runs had other failures among the 115 tests not listed.
- Which worker ran which spec in each run, so the search collision rate under a different sharding may differ.
- Whether the orders lag is a replica, a cache or something else. That is outside the repository and belongs to the product investigation.
- The tags on these five tests, which decide whether the stop line applies to the profile failure.

Rule note: the `testing-guidelines` rule was read and applied. The `code-style-qa` rule was not loaded; its no-sleep, web-first, isolation and red-green requirements were applied from this skill's summary of it.
