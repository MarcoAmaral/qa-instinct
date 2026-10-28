## Verdict per test (commit c0ffee1, 10 CI runs, 4 workers, retries 0)

Everything below was read from the history and the repeat runs the team reported. I ran nothing in this session. With `retries: 0` Playwright never records its own `flaky` outcome, so detection rests on comparing runs of the same commit.

| Test | Failures in CI | Verdict | Cause class |
| --- | --- | --- | --- |
| cart > updates the total when the quantity changes | 3 of 10 | Flaky | Test timing (provisional, see below) |
| profile > saves a new avatar | 10 of 10 | Not flaky: deterministic failure | Defect, product or test, undecided |
| search > filters results by tag | 4 of 10 | Flaky | Order or shared state |
| orders > shows the latest order first | 2 of 10 in CI, 3 of 50 alone | Flaky | Product intermittent defect |
| login > signs in with valid credentials | 0 of 10 | Not a suspect | None |

**login.** 0 failures in 10 runs. That bounds the failure rate, it does not prove zero. No action.

**profile > saves a new avatar: deterministic, not a flake.** It fails every run with the same message, expected `"avatar.png"`, received `undefined`. A test that always fails on unchanged code is a defect to report, not a quarantine candidate. The message alone does not say whether the product stopped returning the file name or the test reads a field that was renamed. Decide it by inspecting the upload response in the trace viewer. If the field is present under another name the test is wrong. If it is absent the product is wrong. File it through `/qa-defect` today as Always, 10 of 10, and keep it in the blocking run so it stays red until fixed.

**cart: flaky, test timing as the provisional class.** The test has a hard sleep of 300 ms, which the code-style rule forbids and which must go regardless. But the sleep is not what fails. The failing step is a web-first `toHaveText` that waited the full 5 s and never saw €58.00. So the total did not update within 5 s, and the likely reason is that the click on "+" was lost, fired before the cart was hydrated or the handler attached. The second candidate is a cart shared across the 4 workers, which would make it a data collision. The trace decides it. If the received text is the old total, the click was lost and the fix is to wait for the button to be enabled and for the quantity response before asserting. If the received text is a different total, the cart is shared and the fix is one cart per test. Assumption until the trace is read: lost click, test timing. Rerun `cart.spec.ts` with `--repeat-each=30` at `--workers=4` and again at `--workers=1`. If it only fails at 4 workers, the class moves to data collision.

**search: flaky, order or shared state. Not a product defect.** It passed 20 of 20 alone with one worker and fails 4 of 10 in the suite. The cause is named in the evidence. It asserts on the seeded tag "summer", and tags.spec.ts renames that same tag during its own run. With 4 workers the two specs overlap, and the result depends on which one gets there first. The fix is isolation, and it belongs mostly in the polluter. tags.spec.ts must create its own tag and rename that, never a seeded one. search.spec.ts should also stop depending on the seed and create a unique tag per test, for example `summer-<testInfo.workerIndex>-<timestamp>`, so no later spec can collide with it. Quarantining search alone leaves tags.spec.ts free to break any other test that reads "summer". Check for those with a grep on the seed name.

**orders: flaky, product intermittent defect. Quarantine alone would hide it.** The team already did the hunt correctly: a fresh user per run, web-first assertions, 50 repeats alone, and it still failed 3 of 50. In those runs `GET /orders` returned a list without the new order for up to 2 s after creation. That is read-after-write inconsistency in the product, a read replica or cache lagging the write. Report it through `/qa-defect` as a product defect with the observed frequency, 3 of 50 alone and 2 of 10 in CI, and attach the trace showing the stale response. Do not fix the test by polling for 2 s or by raising the assertion timeout. That would make the test pass while the user still sees a missing order. If the product owner declares eventual consistency acceptable, the defect becomes a UI requirement to show the new order from the write response, and the test changes only after that decision is recorded.

## Quarantine proposal and ledger

The team decides and applies the tags, nothing here does it. Per the protocol: tag `@flaky`, open the defect report, then move to `@quarantine`. Rows without an owner or deadline are not a quarantine, so the two placeholder columns must be filled before the tag lands.

Assumptions, because the `testing-guidelines` rule is not loaded in this session: quarantine date 2026-10-26, a two-week sprint, deadline one sprint out, 2026-11-09. Replace both with the rule's period once it is available. Owners are the area owners for each spec as a placeholder.

| Test ID | Cause class | Defect report | Owner | Quarantined on | Deadline | Status |
| --- | --- | --- | --- | --- | --- | --- |
| cart > updates the total when the quantity changes | Test timing (provisional) | DR-CART-001, to open, test defect | Cart area owner (TBD) | 2026-10-26 | 2026-11-09 | quarantined |
| search > filters results by tag | Order or shared state | DR-SEARCH-001, to open, test defect, fix in tags.spec.ts | Search area owner (TBD) | 2026-10-26 | 2026-11-09 | quarantined |
| orders > shows the latest order first | Product intermittent defect | DR-ORDERS-001, to open, product defect, 3 of 50 and 2 of 10 | Orders backend owner (TBD) | 2026-10-26 | 2026-11-09 | quarantined |

Not in the ledger: profile > saves a new avatar. It is deterministic and stays blocking, reported as DR-PROFILE-001.

Share quarantined: 3 of 120, 2.5 %. The 120 is the figure the team gave, not the output of `npx playwright test --list`, so confirm it against the runner before recording it. The rule's escalation threshold is not loaded, so I cannot say whether 2.5 % crosses it. If the rule puts it below the line, no escalation.

CI wiring:

```
# blocking jobs
npx playwright test --grep @smoke --grep-invert @quarantine
npx playwright test --grep @regression --grep-invert @quarantine

# separate, non-blocking job so a fix becomes visible
npx playwright test --grep @quarantine
```

Keep `retries: 0`. Raising retries would turn the orders defect into a green run and remove the only signal the team has.

## Exit criteria and what the history cannot show

A row closes as `retired (fixed)` only when both hold on the fix commit, with the command and output pasted into the ledger:

- **cart.** Sleep removed, click waits for the enabled button and the quantity response. `npx playwright test cart.spec.ts --repeat-each=30 --workers=4` passes 30 of 30. Red-green: stub the quantity response to return the old total and confirm the test fails.
- **search.** tags.spec.ts and search.spec.ts each own their tag. Full suite at 4 workers passes `--repeat-each=10` with both specs in the same run. Red-green: return 5 results for the tag and confirm the test fails.
- **orders.** Closes only after the product fix. `--repeat-each=50` alone passes 50 of 50. Red-green: return the stale list from `GET /orders` and confirm the test fails. A test that passes against the stale list is not a fix.

At the deadline without a fix: delete the test with the reason in the ledger, or extend with a recorded decision and a new deadline.

What this history cannot show: any run before these 10, which worker and which spec order each failure had, the traces for the cart failures, and the orders backend configuration that causes the 2 s lag. The first three are in CI artifacts if they were kept. The last is outside the repository and belongs to the backend owner.

Rule not applied: the `testing-guidelines` rule is not in context and the `qa-rules` skill is not installed here. The quarantine period, the escalation threshold and the escalation contact above are stated assumptions, not the rule's values.
