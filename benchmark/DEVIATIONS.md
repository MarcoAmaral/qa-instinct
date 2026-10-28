# Deviations from the methodology

Every departure from `METHODOLOGY.md` after it is frozen is a dated entry here: what the
methodology says, what was done instead, and why. Entries are added, never edited away; a
correction to an entry is a new entry that names it. Newest first.

The pilot ran before the freeze, on the version it disclosed; what it changed is in
`METHODOLOGY.md`, "Pilot disclosure", not here.

## 2026-10-27: methodology 1.2, six content graders and one fixture changed before Arm 1

- **What the methodology says.** "A change before full collection is a new row under 'Version
  history' and an entry in DEVIATIONS.md." Arm 1 has not been collected.
- **What was done.** Marco decided on 2026-10-27 to fix, before Arm 1, the defects the Extension
  arm's read-through found (the entries below). Version 1.2:
  - Six content graders accept the wordings they wrongly failed, and only those; every earlier
    alternative is kept as written. `con-no-4-1-1` also allows a mention that calls 4.1.1 retired or
    deprecated, says it was removed, or applies it only under WCAG 2.0 or 2.1 ("removed" counts only
    next to 2.2 or as "was removed", because "Focus outline removed" in a nearby row passed a real
    failure). `con-limits-stated` adds statements that nothing was verified in a browser or with
    assistive technology, that no browser or screen reader was run, or that a result is estimated or
    needs confirmation. `con-severity-and-priority` adds the priority value "Blocker".
    `con-repro-rate` adds "3 in 10" and "30%". `con-undocumented-500` adds "only 201 and 400"
    before the 500. `con-404-missing-code` adds a 404 line with "only `message`" or "fails on
    `code`". `con-no-4-1-1`'s description says what is now allowed, in the grader and in the table.
  - `fixtures/flaky-run-history/run-history.md`: the cart test's failure is now "expect(received).toBe
    (expected). Expected: "€58.00". Received: "€29.00"", from a single `textContent()` read after
    `page.waitForTimeout(300)`. The old message, a 5-second web-first timeout, did not support the
    rubric's "fixed wait" cause. `jdg-cause-classes` is unchanged.
- **How the graders were checked.** Before any new run, each changed pattern was run with
  `build.js`'s own evaluator on every Extension-arm output of its task (240 outputs). Each one now
  gives exactly the verdicts the read-through set by hand, the 48 in `corrections.json` included,
  and changes no other verdict. The grader samples pass (131 of 131).
- **Frozen again.** `cases.sha256` was
  `354463545355b8aad70e03354a407fcd610ea6364a7e0f8675b703bae53cf6dd` and is now
  `7f873e1c3f2378840b6c55f4ed5f5f1ff8c137383ee3b9d39751b69a06523af7`. The placebo is 106.7% of the
  14,514-byte mean file D loads (106.5% of 14,550 before; D's files lost one parenthesis, plan 067).
- **Why it matters.** Arm 1 is collected on 1.2, so its content pass is not depressed for A, B and
  C by wording the old patterns missed, and its flaky judge verdict rests on evidence that decides
  the cause. The Extension arm stays as collected on 1.1; its corrected re-score applies the same
  verdicts by hand. Arm 1 and the Extension arm were never to be pooled.

## 2026-10-27: condition D now loads the package with the qa-rules and qa-static-analysis skills

- **What the methodology says.** Condition D loads "the repository root, the plugin as published"
  and records the files a run read beyond the expanded command.
- **What changed.** Since plan 067 (PR #20, released in 4.4.0) the plugin lists `./plugin/skills/`,
  which holds the `qa-rules` skill: every rule as a reference file. A D run that names a rule can now
  read it, where before it said which rule it could not apply. Since plan 068 (PR #22) the plugin
  also has the `qa-static-analysis` skill; no benchmark task concerns static analysis, but its name
  and description (about 530 characters) are among the skills a D run sees.
- **What was done.** Nothing else; Arm 1 runs D on the package as it is at collection, as the
  methodology says. The pilot and the Extension arm (from its pinned checkout) ran without either
  skill; two Extension-arm D runs (`flaky-run-history` runs 6 and 7) tried to read
  `.claude/skills/qa-rules/references/testing-guidelines.md`, a path that did not exist.
- **Why it matters.** D in Arm 1 can apply the rules a command names; D in the pilot and the
  Extension arm could not. A difference between them may come from this as well as from the model.

## 2026-10-27: the Extension arm's read-through missed four `con-limits-stated` verdicts

- **What happened.** Testing the 1.2 patterns on the Extension arm's outputs showed four answers the
  read-through had left failed that say what they could not check: B run 3 ("No browser, screen
  reader, or automated scanner was run"), B run 6 (the same), C run 7 ("Nothing was tested in a
  browser or with assistive technology") and C run 4 ("Target size is estimated", the same kind of
  statement as A run 8, which was corrected). The read-through's search printed only the first
  matching line of each answer, "source only", and they were left failed for it.
- **What was done.** The four are added to `corrections.json`, with that reason, making 48
  corrections (A 16, B 19, C 9, D 4), and both corrected analyses were generated again. Corrected:
  content pass A 41/90, B 45/90, C 44/90, D 90/90; D vs C +51.1 (+43.3 to +58.9), D vs B +50.0
  (+44.4 to +56.7), D vs A +54.4 (+45.6 to +62.2). Corrected without technique naming: A 68/90,
  B 74/90, C 74/90; D vs C +17.8 (+10.0 to +25.6), D vs B +17.8 (+12.2 to +24.4), D vs A +24.4
  (+17.8 to +31.1). These replace the figures in the two entries below, which are left as written.
- **Why it matters.** Every reading still supports the claim; the corrected differences are about
  two points smaller for B and C.

## 2026-10-27: technique naming decides the three test-case tasks in the Extension arm

- **What the methodology says.** Content pass requires every `con-` grader of the task. In the
  three test-case tasks one of them, `con-technique-named`, checks that the design technique is
  named (`Boundary[- ]Value|\bBVA\b`, `State[- ]Transition`).
- **What the read-through found.** In the Extension arm A, B and C apply the technique but rarely
  name it: they pass `con-bva-values`, `con-every-fee`, `con-subtotal-boundary` and
  `con-unlisted-invalid-transition` in 10 of 10 runs each, and write "boundary" 17 to 31 times per
  condition in `cases-quantity`, yet pass `con-technique-named` in 0 to 2 of 10. In those three
  tasks it is the only `con-` grader A, B and C fail, so it alone makes their content pass 0 to 2 of
  10 against D's 10.
- **What was done.** Nothing in the collected results changed; the grader does what its
  description says, so it is not a defect. As a sensitivity reading, not a correction,
  `rescore.js --set-aside con-technique-named` over the corrected verdicts (entry below) gives
  `analysis-corrected-without-naming.md`: content pass A 68/90, B 72/90, C 72/90, D 90/90; D vs C
  +20.0 (+12.2 to +27.8), D vs B +20.0 (+14.4 to +26.7), D vs A +24.4 (+17.8 to +31.1).
- **Why it matters.** About half of the headline difference is naming the technique, a habit the
  package teaches, rather than applying it. The claim still holds without it, at about a third of
  the size. Reports of this arm give both readings.

## 2026-10-27: the flaky-run-history fixture contradicts its judge rubric on the cart test

- **What the methodology says.** `jdg-cause-classes` passes when the reply classifies the cart test
  as "a test timing problem (a fixed wait instead of waiting for the result)".
- **What the read-through found.** The fixture's failure message is "Timeout 5000ms exceeded
  waiting for getByTestId('cart-total') to have text \"€58.00\"", a web-first assertion that already
  retries for five seconds, so the 300 ms fixed wait cannot by itself explain the failure; the
  evidence does not decide the cause. The judge failed D in 4 of 10 runs (2, 4, 8, 9), each of
  which classes the cart test as unknown and names the trace as what decides it, as the `qa-flaky`
  skill instructs, and B in 3 (7, 8, 9), which call the sleep "a smell but not the cause". A and C
  passed 10 of 10.
- **What was done.** The judge applied its rubric as written; nothing was re-judged or re-scored
  (`RUNBOOK.md` section 5). Judge pass in this arm: A 20/30, B 20/30, C 22/30, D 23/30.
- **Why it matters.** The rubric rewards the planted answer over the more careful one, which
  penalises D and B here. The fixture and rubric are frozen for Arm 1; changing them before Arm 1
  is collected is a new methodology version and its own entry, and is Marco's decision.

## 2026-10-27: six content graders gave 44 wrong verdicts in the Extension arm

- **What the methodology says.** `RUNBOOK.md` section 5: "A verdict that is wrong is a grader
  defect: record it in `DEVIATIONS.md` with the output that showed it." A defective grader is not
  fixed and re-scored silently; a corrected re-score is reported beside the analysis and labelled.
- **What the read-through found.** Each verdict below was checked by reading the output; every one
  is a failure that should have been a pass, and the reason for each is in
  `results/2026-10-23-ext-fable-5-1/corrections.json`.
  - `a11y-signup-form` `con-no-4-1-1` (A 4, B 9, C 1, D 4): the pattern allows a mention of 4.1.1
    only next to the word "obsolete", so "retired in WCAG 2.2", "deprecated since 4.1.1 Parsing was
    removed" and "4.1.1 Parsing under 2.0 and 2.1" fail. Answers that cite 4.1.1 as a current
    failure (A 1 and 6, B 9, C 1, 5 and 6) stay failed.
  - `a11y-signup-form` `con-limits-stated` (A 3, B 6, C 1): "nothing was verified in a browser or
    with assistive technology" and "No browser, screen reader, or automated scanner was run" are
    not covered. Answers that say only "source only" stay failed.
  - `defect-gift-card` `con-severity-and-priority` (A 1, C 2): "Blocker" is not in the priority
    values.
  - `defect-gift-card` `con-repro-rate` (A 3, C 1): "30%" and "3 in 10" are not covered.
  - `api-orders-contract` `con-undocumented-500` (A 3, B 2): a table row with "Only 201 and 400"
    before the 500 is not covered.
  - `api-orders-contract` `con-404-missing-code` (A 2, C 2): "requires `code` and `message` | Only
    `message`" is not covered.

  Totals: A 16, B 17, C 7, D 4. The patterns match the package's own wording, so the defects fall
  mostly on A, B and C. `fmt-every-scenario-tagged`, also flagged for reading, is correct: the
  failing scenarios have no tag.
- **What was done.** `runs.jsonl` and `analysis.md` stay as collected. `analysis/rescore.js`
  applies `corrections.json` and checks that each collected verdict is the one it records;
  `analysis-corrected.md` is its output through `analyze.js` unchanged: content pass A 41/90,
  B 43/90, C 42/90, D 90/90; D vs C +53.3 (+45.6 to +61.1), D vs B +52.2 (+45.6 to +58.9), D vs A
  +54.4 (+45.6 to +62.2), against +55.6, +56.7 and +61.1 as collected. Every contrast still
  "supports the claim". The patterns were not changed.
- **Why it matters.** The conclusion does not depend on these defects. They are fixed in the
  graders only by a new methodology version before Arm 1, with its own entry, if Marco decides so.

## 2026-10-27: the Extension arm's after-run checks differ, from plugin auto-updates

- **What the methodology says.** `RUNBOOK.md` section 4 compares `claude plugin list`,
  `claude plugin marketplace list` and the checksums in `sha-before.txt` with their state before the
  first run, to show the collection left the user's Claude Code setup as it found it.
- **What happened.** On the Extension arm, run from the SWARE distribution, the marketplace list
  is the same; `settings.json` matches its checksum; `installed_plugins.json` and
  `known_marketplaces.json` do not, and the plugin list differs only in `context7`, `github` and
  `playwright@claude-plugins-official`, version `465f09344424` before. `installed_plugins.json`
  dates the change: the official marketplace auto-updated those three plugins on 2026-10-26 at
  01:08 UTC, during the collection, and again on 2026-10-27 at 20:24 UTC, after it (now
  `f8c5e7a1dcb7`); `known_marketplaces.json` changed with each refresh. `github` is installed at
  project scope, so its enabled or disabled status depends on the folder the check runs from.
- **What was done.** Nothing to undo. Every run used a temporary home with no user plugins, and
  `claude plugin eval .` loads the package from the checkout, so neither the updates nor these
  plugins reach a generation. No plugin or marketplace the benchmark touches is in the lists.
- **Why it matters.** The check is evidence of isolation; here its differences come from Claude
  Code's own update schedule, not from the collection. A later arm should save the before state
  just before its first task and compare right after its last, as close together as it can.

## 2026-10-27: the Extension arm's outputs hold model-invented `example.com` addresses

- **What the methodology says.** `RUNBOOK.md` section 3: any address the redaction `grep` prints
  "must be one of the fixtures' reserved `.example` addresses or not be there".
- **What happened.** The `grep` printed 17 addresses at `example.com`, all in condition C:
  `name@example.com` in `a11y-signup-form` runs 2, 6 and 7, and `member@`, `nonmember@` and
  `expired@example.com` in `cases-shipping-fee` run 7, where the model named its test accounts.
  The model wrote them; no fixture or prompt holds them. `example.com` is reserved for examples by
  RFC 2606, so no person or mailbox stands behind them.
- **What was done.** Marco decided on 2026-10-27 to keep them as written. The outputs are
  published as the model produced them; no output was edited and nothing was re-scored.
- **Why it matters.** The rule exists to keep real personal data and local paths out of the
  results; these addresses are neither. The `grep` now reads, for this arm, as "any address it
  prints is one of the fixtures' `.example` addresses or at `example.com`".

## 2026-10-27: the Extension arm's cap is raised to US$260

- **What was recorded.** The entry of 2026-10-25 raised the Extension arm's cap on
  `claude-fable-5-1` to US$230, and the collection starts no task when what is left would not
  cover the largest task so far.
- **What happened.** Eight tasks cost US$207.19. After them US$22.81 was left, less than the
  largest task, US$43.12, so the collection did not start the ninth, `bdd-loyalty-points`.
- **What was done.** Marco raised the cap to US$260 on 2026-10-27 so that check lets
  `bdd-loyalty-points` run. The run is still on the subscription only, with extra usage off, and
  the benchmark files are otherwise unchanged; the eight collected tasks are unchanged.
- **Why it matters.** The cap bounds usage, not results, and the last task is still collected
  whole. As in the entries of 2026-10-23 and 2026-10-25, the figures are list prices as the tool
  reports them; the run counts against a subscription's usage limits.

## 2026-10-25: the Extension arm's cap is raised to US$230

- **What was recorded.** The entry of 2026-10-23 capped the Extension arm on `claude-fable-5-1`
  at US$161, 1.25 times an estimate of US$128.8 drawn from the pilot's token mix, and the
  collection starts no task when what is left would not cover the largest task so far.
- **What happened.** Five tasks cost US$122.07: US$20.36, US$18.92, US$21.58, US$18.11 and
  US$43.12. `plan-split-payment` cost about twice the others because its replies are full test
  plans. After it, US$38.93 was left, less than US$43.12, so the collection stopped before
  `api-orders-contract`, as designed.
- **What was done.** Marco raised the cap to US$230 on 2026-10-25, enough for the four remaining
  tasks at about US$20 each with the largest-task margin still in force for the last one. No
  task was cut; the five collected tasks are unchanged.
- **Why it matters.** The cap bounds usage, not results, and every task is still collected whole.
  As in the entry of 2026-10-23, the figures are list prices as the tool reports them; the run
  counts against a subscription's usage limits, with extra usage off.

## 2026-10-25: the package is renamed QA Instinct, so condition D's command prefix changes

- **What the methodology says.** Condition D invokes `/bem-te-vi:<command or skill>` and loads
  "the repository root, the plugin as published" ("Conditions"); `PROMPTS.md` holds the prompt and
  `cases.sha256` the frozen digest of the built cases. A change before full collection is a new
  version and an entry here.
- **What was done.** Marco renamed the package Bem-te-vi to QA Instinct on 2026-10-25
  (`plans/065-qa-instinct-rename.md`), and the Claude Code plugin from `bem-te-vi` to
  `qa-instinct`. `PROMPTS.md` now invokes `/qa-instinct:{{command}}`, `build.js` names its
  temporary folder after the new name, and `METHODOLOGY.md` is version 1.1. The digest is frozen
  again: `d6a8856973913d63de3ba6039802606028be17feb51704b91b9a457650116e1c` before,
  `354463545355b8aad70e03354a407fcd610ea6364a7e0f8675b703bae53cf6dd` now.
- **What did not change.** The fixtures, the graders, the placebo and the analysis; every grader
  sample still checks as expected (131 of 131). The files D loads are the same size: their mean is
  still 14,550 bytes and the placebo's 15,493 bytes are still 106.5% of it.
- **The Extension arm.** The arm on `claude-fable-5-1` (entry of 2026-10-23, on its branch), four
  of nine tasks collected under `/bem-te-vi:`, finishes from its pinned checkout of `9381269` under
  the old prefix, so all its generations saw one command name.
- **Why it matters.** Arm 1 is collected after this change and sees `/qa-instinct:`. The model sees
  the command's name, so a run could differ by the name alone; the pilot and the Extension arm saw
  `/bem-te-vi:`.

## 2026-10-23: an Extension arm on `claude-fable-5-1`, collected before Arm 1

- **What the methodology says.** "Arms": the Extension arm is "the same protocol with another
  model (a Sonnet-class model first)", reported on its own and never pooled with Arm 1, and
  conditional on budget. Arm 1 uses `claude-haiku-4-5-20251001` for the agent and the judge, and
  `RUNBOOK.md` section 2 names that model in both flags. "Cost" estimates Arm 1 at about US$13 with
  a US$16 cap.
- **What was done.** Marco decided on 2026-10-23 to collect an Extension arm on
  `claude-fable-5-1` for the agent and the judge, before Arm 1 and with no Sonnet-class arm first.
  It is Arm 1's design unchanged: 9 tasks x 4 conditions x 10 runs = 360 generations, 120 of them
  judged, collected with the `RUNBOOK.md` commands from a clean checkout of `a7ab7ab`, with only
  `--model` and `--judge-model` changed. Results go to
  `benchmark/results/2026-10-23-ext-fable-5-1/`. Claude Code 2.1.291 ran in another WSL
  distribution from the one that holds the checkout, signed in with a claude.ai Team subscription,
  not the pilot's account, with extra usage off; the run is bounded by that plan's usage limits.
- **Cost.** At list prices `claude-fable-5-1` costs US$10 / US$50 per million input / output
  tokens, against US$1 / US$5 for `claude-haiku-4-5-20251001`, ten times as much. On the pilot's
  token mix the arm is estimated at US$128.8 (generations US$118.4, judge US$10.3) and capped at
  US$161, Arm 1's margin of 1.25. The model always thinks, so the estimate is a lower bound; the
  cap cuts whole tasks, as in Arm 1.
- **Usage guard.** Before each task the collection reads the plan's usage meter and starts no task
  once the five-hour or weekly figure reaches 95%; a task in flight is stopped at 98%. A task
  stopped part-way is discarded and collected again whole in a new invocation, and that is a new
  entry here. Collection does not resume on its own after a limit resets.
- **What did not change.** `PROMPTS.md`, the fixtures, the graders, the placebo and the analysis.
  `node benchmark/build.js --check` passes with the frozen digest,
  `d6a8856973913d63de3ba6039802606028be17feb51704b91b9a457650116e1c`.
- **Why it matters.** This arm answers none of Arm 1's confirmatory questions, and Arm 1 is still
  to be collected as frozen. Its judge is `claude-fable-5-1`, so its judge verdicts do not compare
  with Arm 1's. It replicates on a larger model, which "Known limitations" names as the remedy for
  "One model in the primary arm, and a small one".

## 2026-10-20: condition D's files name their author and say which rule they could not apply

- **What the methodology says.** As in the entries below: condition D loads "the repository root,
  the plugin as published", not a pinned version, and `CONTROL.md` asks for any change to the mean
  file D loads to be recorded here, with the placebo kept within 75% to 125% of it.
- **What was done.** Plan 060 changed all seven files D loads. Every `SKILL.md` gained the line
  `author: Marco Amaral` under `metadata:` (`qa-plan`, `qa-api`, `qa-a11y`, `qa-flaky`: 23 bytes
  each). The six that name a rule (`qa-cases`, `qa-defect`, `qa-bdd`, `qa-api`, `qa-a11y`,
  `qa-flaky`) gained one paragraph after the banner, the same in each: when a rule the file names
  is not in context, read it from the `qa-rules` skill; if that skill is not installed either (a
  Claude Code plugin install has neither), go on without the rule and say at the end of the reply
  which rule could not be applied (342 bytes). Sizes, `github/next` at `8761bf4` to now:
  `qa-cases` 17,671 to 18,013; `qa-defect` 18,290 to 18,632; `qa-bdd` 12,777 to 13,119; `qa-plan`
  18,043 to 18,066; `qa-api` 10,703 to 11,068; `qa-a11y` 9,082 to 9,447; `qa-flaky` 6,216 to 6,581.
- **What did not change.** `PROMPTS.md`, the fixtures, the graders and the placebo. `node
  benchmark/build.js --check` passes with the same digest,
  `d6a8856973913d63de3ba6039802606028be17feb51704b91b9a457650116e1c`.
- **Placebo size parity.** The mean file D loads over the nine tasks went from 14,236 bytes
  (placebo 108.8%, measured on `8761bf4` with `build.js --check`) to 14,550 bytes; the placebo's
  15,493 bytes are now 106.5% of it, inside the 75% to 125% band, so `CONTROL.md` calls for no
  rebuild.
- **Why it matters.** Arm 1 has no rules and no `qa-rules` skill (the plugin ships neither), so a
  D run is now told to name, at the end of its reply, each rule it could not apply. The note is
  asked for at the end, not the start, because `fmt-frontmatter` checks how the reply starts; a
  model that puts it first, or that writes it although the prompt asks for the deliverable only,
  can fail a format grader it passed before. The full collection's outputs will show whether it
  happens; a difference from the pilot on the six tasks may come from this change as well as from
  the entries below.

## 2026-10-19: condition D's content changed again, two files now point to references

- **What the methodology says.** As in the entry below: condition D loads "the repository root,
  the plugin as published", not a pinned version. `CONTROL.md` asks for the placebo's size to stay
  within 75% to 125% of the mean file D loads, and for any change to that mean to be recorded here.
- **What was done.** Plan 056 brought two files D loads under the Agent Skills recommendation of a
  body under 5,000 tokens. `.claude/commands/qa-cases.md` (tasks 1 to 3) went from 22,168 to 17,573
  bytes: its tracker table, the worked example of each design technique, the runbook format and the
  results-reporting format moved to `qa-reference/references/test-case-writing.md` and
  `test-reporting.md`. `.claude/skills/qa-plan/SKILL.md` (task 5) went from 25,916 to 17,699 bytes:
  the testing quadrants table, the estimation techniques with their worked example, the test
  execution orderings, the suite-level artifacts, the detail of roles and independence, the
  configuration management checklist, and monitoring, control, reporting, completion and
  retrospectives moved to `test-planning.md` and `test-reporting.md`. Each body keeps a pointer at
  the place the detail was. Nothing else D loads changed.
- **What did not change.** `PROMPTS.md`, the fixtures, the graders and the placebo; `node
  benchmark/build.js --check` passes with the same digest,
  `d6a8856973913d63de3ba6039802606028be17feb51704b91b9a457650116e1c`. Everything a grader of tasks
  1 to 3 and 5 checks is still in the body D expands: the frontmatter keys, the eleven case rows,
  the Source values, the technique names with two-value boundary analysis, the nine plan fields,
  the register columns, the release gate and the entry and exit criteria.
- **Placebo size parity.** The mean file D loads is now 14,067 bytes (16,512 after the entry
  below); the placebo's 15,493 bytes are 110.1% of it (93.8% before), inside the 75% to 125% band,
  so `CONTROL.md` calls for no rebuild. Per task the placebo is now 88% of `qa-cases` (70% before)
  and 88% of `qa-plan` (60% before).
- **Why it matters.** The pilot's D runs read no reference file ("Pilot disclosure"): D got only the
  expanded command. The moved detail now reaches a D run only if the model reads the reference the
  body names, and `runs.jsonl` records every file a run read, so the full collection shows whether
  it did. A difference between the pilot and the full collection on these four tasks may come from
  this change as well as from the entry below.

## 2026-10-19: condition D's content changed after the pilot

- **What the methodology says.** Condition D loads "the repository root, the plugin as published"
  ("Conditions"), and `RUNBOOK.md` collects from a clean checkout of the commit that carries the
  frozen methodology. Neither pins D to a package version or commit. "Pilot disclosure" lists three
  findings about the package as "recorded for its maintainers and not used to change anything
  here".
- **What was done.** Marco decided on 2026-10-19 to fix those three findings before the 4.1.0
  export. The branch `fix/pilot-content-defects` changed two files condition D loads:
  `.claude/commands/qa-defect.md` (Root Cause starts as `N/A — not yet analysed`, a new Suspicions
  field holds unconfirmed leads, and three good example titles gain the `when` clause the title
  rule asks for) and `.claude/commands/qa-cases.md` (which Source values the TC hook accepts, and
  that a requirement stated outside the numbered ACs is `Added by QA (<reason>)`). The pilot's D
  outputs came from the earlier text, which is the same at `06240b4` (the commit that added the
  pilot results) and at `436faa9`; the full collection will load the new text.
- **What did not change.** `PROMPTS.md`, the fixtures, the graders and the placebo. `node
  benchmark/build.js --check` passes with the same digest,
  `d6a8856973913d63de3ba6039802606028be17feb51704b91b9a457650116e1c`. `fmt-title-form` still does
  not require the `when` clause. The reason its text gives ("two of the command's own good titles
  omit it") no longer holds, but the grader stays as frozen: it is now more lenient than the
  command's rule, equally in every condition. `fmt-root-cause-na`, `jdg-guess-not-cause` and
  `cases-shipping-fee/fmt-every-case-complete` already graded what the changed text asks.
- **Placebo size parity.** The mean file D loads is now 16,512 bytes (16,104 at planning); the
  placebo's 15,493 bytes are 93.8% of it (96.2% before), inside the 75% to 125% band, so CONTROL.md
  calls for no rebuild. Per task the placebo is now 85% of `qa-defect` (18,206 bytes; 93% before)
  and 70% of `qa-cases` (22,168 bytes; 72% before). CONTROL.md's figures describe the planning-time
  sizes and stand as written.
- **Why it matters.** A reader comparing the pilot with the full collection should know D's text
  differs between them. The pilot is not a result, and the pilot outputs were not re-graded, since
  neither they nor the graders changed; whether the fixes change how often these faults occur is
  unmeasured until the full collection.
