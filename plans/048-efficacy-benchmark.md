# Plan 048: A pre-registered efficacy benchmark (does Bem-te-vi make the output better?)

> **Executor instructions**: Two pull requests into `next`. The first holds only this plan and its
> `plans/README.md` row. The second, on a branch stacked on the first, builds `benchmark/`, validates
> its graders offline, runs the pilot within the budget below, and adds the README section. One
> concern per commit. Run every verification command and read its output. If anything in "STOP
> conditions" occurs, stop and report. When a step lands, update this plan's row in
> `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat 8487bd6..HEAD -- evals .claude/commands/qa-cases.md .claude/commands/qa-defect.md .claude/commands/qa-bdd.md .claude/skills/qa-plan .claude/skills/qa-api .claude/skills/qa-a11y .claude/skills/qa-flaky .claude-plugin package.json`
> A change to a command or skill under test since planning changes what condition D loads: re-read
> it, and re-check the placebo's size parity (CONTROL.md) before the pilot.
>
> **Note, 2026-10-29.** Written when the package was named Bem-te-vi. Plan 065 renamed it QA
> Instinct on 2026-10-25, and condition D now runs `/qa-instinct:<command or skill>` (methodology
> 1.1, `benchmark/METHODOLOGY.md`). The text below is kept as written; `benchmark/` is the current
> account of the method.

## Status

- **Priority**: P2
- **Effort**: L
- **Risk**: LOW for the harness (nothing shipped changes); MEDIUM for collection (paid model runs)
- **Depends on**: plan 037 step 5 (the `claude plugin eval` harness and its isolation checks),
  plans 039-042 (the skills under test), plan 020 part B (the public timestamp, see "Registration")
- **Category**: test, docs
- **Planned at**: commit `8487bd6` (`github/next`), 2026-10-18
- **Outcome**: plan PR #186; harness and pilot done 2026-10-18 on `test/efficacy-benchmark` (see
  "Outcome"); full collection waits for Marco's cap
- **Decided by Marco, 2026-10-18**: pilot runs may spend at most US$2.00 in total, out of the US$2.25
  left of his earlier US$5 cap for this account. Full collection waits for a cap he sets.
- **Decisions for Marco** (each has a default; see "Decisions"): the full-collection cap; whether
  to register on OSF as well; who the second human judge is; which extension arms to fund.
- **Model**: the method is borrowed from the A11Y.md efficacy benchmark by Felipe A. Carriço
  (<https://github.com/fecarrico/A11Y.md/tree/main/benchmark>, study page
  <https://fecarrico.github.io/a11ymd/en/estudo/>): active controls including a size-matched
  placebo, frozen prompts, a pre-specified analysis, blind scoring, a deviations log, and a primary
  arm separate from an ecological one. Only the method is borrowed. No text from that repository is
  copied into this one; everything here is written for this package.

## Why this matters

The README tells a tester that Bem-te-vi makes an AI assistant produce better test work. The only
evidence today is plan 037 step 5: one case (`evals/qa-cases-format`), three runs per arm, plugin
against no plugin, graded on the package's own format. That shows the plugin changes the format,
which nobody doubted. It cannot show the things a testing engineer would ask before trusting the
claim:

- **Is it the content or just having a long document in context?** A no-plugin baseline cannot
  separate the two. A placebo of the same size and shape, about something else, can.
- **Is it better than one free sentence?** If "work as a thorough QA engineer" gets the same result,
  the package has no reason to exist for that task.
- **Does it hold beyond test cases?** Plan 037 dropped its `/qa-defect` case because the bare model
  already passed it. The package has seven main commands and skills; one was measured.
- **Were the rules fixed before the data?** A benchmark whose graders, prompts and analysis are
  chosen after seeing the outputs measures the author's choices.

## Current state

1. `evals/qa-cases-format/` and `evals/qa-cases-plain-request/`: regex graders restating
   `.claude/hooks/validate-tc-format.sh`, results under `evals/results/` (plan 037 step 5). Two arms
   only (plugin, no plugin). `--model sonnet`, three runs per arm.
2. `claude plugin eval` (Claude Code 2.1.291 in SWARE) can run each case against a plugin named in
   the case itself: `plugins:` in `prompt.md` frontmatter is a list of plugin directories relative to
   the case. Checked for this plan on 2026-10-18 with three throwaway cases in a scratch copy of the
   repository (`--ablation none --runs 1 --model haiku`, US$0.07 in total):
   - a case pointing at a plugin with only a `plugin.json` loaded no commands and no skills beyond
     Claude Code's built-in ones;
   - a case pointing at a second plugin with one skill expanded `/<plugin>:<skill>` from the prompt
     (the run's reply carried the marker the skill asked for);
   - a case pointing at the repository root loaded `bem-te-vi` 4.0.1 with all its commands and
     skills, and `/bem-te-vi:qa-flaky` expanded;
   - every run's trace records the model, here `claude-haiku-4-5-20251001`, and its cost. A run that
     only says "ok" cost US$0.016 to US$0.029: about 14,500 tokens of Claude Code's own system prompt
     and tools are written to the cache before any task text.
3. The eval directory can be moved with `--eval-dir <relative path>`, so the benchmark can live in
   `benchmark/` beside `evals/` without changing what `claude plugin eval .` runs today.
4. `package.json` `files` is an allowlist (`.claude/*`, `bin/`, `adapters/`, `README.md`,
   `CHANGELOG.md`, the two hash and map files), so a new top-level `benchmark/` is not published to
   npm. `npm pack --dry-run` confirms it in step 2.
5. Sizes of what condition D loads per task (bytes, at `8487bd6`): `qa-cases.md` 21,467,
   `qa-defect.md` 16,642, `qa-bdd.md` 12,674, `qa-plan/SKILL.md` 25,916, `qa-api/SKILL.md` 10,429,
   `qa-a11y/SKILL.md` 8,878, `qa-flaky/SKILL.md` 5,998. Mean over the nine tasks below: 16,104.

## The design (fixed here, before any data)

`benchmark/METHODOLOGY.md` restates this section in full and is the document collection follows.
Where the two differ, METHODOLOGY.md wins and the difference is a defect in this plan, corrected here
with a dated note.

### Claims under test

1. **Content.** With Bem-te-vi, the output for a QA task contains what a competent tester would put
   in it (every acceptance criterion covered, the right boundary values, the seeded defects found,
   the deterministic failure kept apart from the flaky ones, and so on) **more often** than without
   it, than with one generic sentence, and than with a placebo document of the same size and shape.
2. **Contract.** With Bem-te-vi, the output passes the package's own format contract (the
   `TC-CODE-NNN` cases `validate-tc-format.sh` accepts, the `DR-` report fields, the ledger columns)
   more often than without it. This is expected by construction and is reported as a check that
   condition D worked, never as evidence of quality on its own.
3. **Not just form.** The difference in claim 1 holds against the placebo (D vs C), which separates
   the package's content from the effect of any long, well-organised document loaded the same way.
4. **Not just a phrase.** The difference in claim 1 holds against one generic sentence (D vs B).

The benchmark makes no claim about tasks outside the nine below, models other than the one each arm
names, or whether the tests written would find real defects in a real product.

### Conditions

The task prompt is identical in every condition. Only what is put before it differs, and which
plugin the run loads. `benchmark/PROMPTS.md` holds every preamble and task prompt verbatim.

| | Condition | Preamble (verbatim) | Plugin loaded |
| --- | --- | --- | --- |
| A | bare | none | `benchmark/bare-plugin/` (a `plugin.json` and nothing else) |
| B | generic | `Work as a thorough, professional QA engineer.` | `benchmark/bare-plugin/` |
| C | placebo | `/writing-guide:help-articles` | `benchmark/control-standard/` (the placebo, one command) |
| D | Bem-te-vi | `/bem-te-vi:<command or skill>` for the task (table below) | the repository root, as a path target |

- **D's preamble** is what the README tells a user to type for that job: the namespaced command or
  skill, followed by the request. Whether the package loads without being named is a different
  question, measured by `evals/qa-cases-plain-request` (plan 037); it is not repeated here.
- **C** is the placebo: a guide to writing end-user help-center articles, written for this benchmark,
  about the size of the mean file D loads (16 KB), shaped like a Bem-te-vi command (frontmatter, a
  completeness rule, a file format, a template table, writing rules, a worked example, "how to
  respond"), loaded the same way (a namespaced slash command in a plugin). It is sound, real guidance
  on its own subject and says nothing about testing. Its construction rules, the word sweep that
  proves it silent on testing, and the asymmetries it cannot remove are in `benchmark/CONTROL.md`.
  Its plugin and command names were chosen so the model is not told it is a control.
- **A and B** load a plugin with no components, so every condition runs through the same
  `claude plugin eval` path with `--ablation none`, and none gets the tool's own no-plugin arm.
- Pre-registered contrasts: **D vs C** (content vs form), **D vs B** (the package vs one free
  sentence), **D vs A** (the headline effect).

### Tasks (9)

Each task has a fixture under `benchmark/fixtures/<task>/` and graders under
`benchmark/graders/<task>/`. Every prompt ends with the same two sentences: state assumptions instead
of asking questions, and reply with the deliverable only.

| # | Task | D invokes | Fixture | What the package says the output must contain |
| --- | --- | --- | --- | --- |
| 1 | `cases-quantity` | `/bem-te-vi:qa-cases` | story, 3 ACs, a 1-20 quantity limit | TC format; each AC covered; BVA values 0, 1, 20, 21; techniques named |
| 2 | `cases-order-status` | `/bem-te-vi:qa-cases` | story, 5 ACs, an order lifecycle | TC format; each AC covered; an invalid transition; State Transition named |
| 3 | `cases-shipping-fee` | `/bem-te-vi:qa-cases` | story, 3 ACs, fee rules on three conditions | TC format; each AC covered; every fee outcome; the 50.00 boundary; Decision Table named |
| 4 | `defect-gift-card` | `/bem-te-vi:qa-defect` | a CI failure log and a developer's guess | `DR-` id; title "Component – what failed when condition"; exact error copied; 3 of 10 reproducibility; severity and priority apart; build and commit; root cause left N/A |
| 5 | `plan-split-payment` | `/bem-te-vi:qa-plan` | a feature brief with a gateway, rounding and a deadline | the nine plan fields; a risk register with likelihood, impact and score; product and project risks; entry and exit criteria; a release gate |
| 6 | `api-orders-contract` | `/bem-te-vi:qa-api` | an OpenAPI snippet and three recorded responses | the `total` type mismatch; the 404 body missing `code`; the undocumented 500; the undeclared length limit; each mismatch classed as documentation drift or software defect |
| 7 | `a11y-signup-form` | `/bem-te-vi:qa-a11y` | a 40-line HTML page with seven seeded barriers | six WCAG 2.2 criteria found (1.1.1, 3.1.1, a label criterion, 2.1.1, 2.4.3, 2.4.7); WCAG 2.2 named; 4.1.1 not reported; `A11Y-` finding ids; what was not checked stated |
| 8 | `flaky-run-history` | `/bem-te-vi:qa-flaky` | ten CI runs of one commit, five tests | the always-failing test kept apart as deterministic; each flaky test's cause class (timing, order, product); a ledger with owner and deadline; `@quarantine` |
| 9 | `bdd-loyalty-points` | `/bem-te-vi:qa-bdd` | story, 4 ACs, tiers, one vague AC | Feature header with As a / I want / So that; a Scenario Outline with Examples; the AC message quoted; tier boundaries 499/500 and 1999/2000; every scenario tagged; the vague AC flagged |

The tasks were chosen to cover the package's main commands and skills (`/qa-cases` three times,
since it is the command the README leads with) and to give each one a fixture with a known right
answer, so most of the grading can be deterministic.

### Measurement

- **Deterministic graders first.** `claude plugin eval` has no custom-code graders, so every check
  is a `regex` grader over the final reply. Each grader's name starts with its family:
  - `con-`: content a competent tester would produce whatever the format (an AC covered by its id
    or its observable, a boundary value present, a seeded defect found, an exact error copied).
  - `fmt-`: the package's own contract or vocabulary (the `validate-tc-format.sh` checks restated
    as regexes, as plan 037 did; the `DR-` fields; `A11Y-` ids; the ledger columns).
- **An LLM judge only where nothing deterministic exists**, declared as such, with names starting
  `jdg-`: task 4 (the developer's guess kept apart from the observed failure), task 5 (every score
  equals likelihood times impact and the highest scores come first), task 8 (the cause class of each
  flaky test matches the evidence). The judge is pinned to the same model as Arm 1. Judge results
  are a secondary outcome only.
- **Validated before any paid run.** Each task has a hand-written correct answer under
  `benchmark/graders/<task>/samples/`; `node benchmark/build.js --check` runs every grader's regex
  on it (and on a generic wrong answer) with Node's own regex engine, the same JavaScript dialect
  the tool uses. A grader that the correct answer fails, or the wrong answer passes, stops the build.
- **Blind human review**, on a sample of the full collection: two outputs per task and condition
  (72), drawn with a fixed seed by `benchmark/analysis/blind.js`, each renamed to a code derived from
  a salted SHA-256 of its run id. The key stays outside the repository until every review is
  recorded, then is committed beside the reviews. The judge is Marco; a second judge is planned
  (decision below) and their agreement will be reported as weighted Cohen's kappa. Each output is
  rated 1 to 4 on three questions (would you use it as delivered; is everything in it correct for
  the fixture; does it cover what the fixture needs), and the judge records a guess of the
  condition. Blinding is imperfect and declared: D's outputs carry the package's format, so the
  guess accuracy is reported next to the ratings.

### Outcomes and analysis (pre-specified)

- **Primary outcome: content pass.** A generation passes when every `con-` grader of its task
  passes.
- **Secondary**: contract pass (every `fmt-` grader), content score (the share of `con-` graders
  passed), each grader's pass rate, judge pass rate, cost and tokens per generation (from each run's
  trace), the files D read beyond the expanded command (from the trace), human ratings.
- **Per condition**: pass rate with an exact (Clopper-Pearson) 95% interval.
- **Contrasts** (D vs C, D vs B, D vs A): the difference in content pass rate, averaged over tasks
  with equal weight, with a stratified bootstrap interval (runs resampled within each task and
  condition, 10,000 replicates, fixed seed) at 98.33% (Bonferroni over the three contrasts).
- **Decision rule**: a contrast supports the claim only when the interval's lower bound is above 0
  **and** every task and condition cell in it holds at least 8 generations. Below that, the contrast
  is printed as "underpowered, no conclusion", whatever its point estimate. The pilot (one run per
  cell) is underpowered by design and is never reported as a result.
- **Script**: `benchmark/analysis/analyze.js`, Node standard library only, deterministic, printing
  one Markdown table; `--self-test` checks it on synthetic results with known answers (reference
  Clopper-Pearson bounds, a seeded bootstrap that must repeat exactly, the underpowered rule).

### Arms

| Arm | Engine | Role | n |
| --- | --- | --- | --- |
| 1, primary | `claude plugin eval` in SWARE, path target, `--ablation none`, `--model claude-haiku-4-5-20251001` (the exact string read from each run's trace is recorded per generation) | All confirmatory analysis | 9 tasks x 4 conditions x 10 runs = 360 |
| 2, ecological | Claude Code CLI, `claude -p`, in a real project folder, with the user's own configuration; D loads the plugin with `--plugin-dir` (never installed) | Does the direction hold in a real agent session? Descriptive, no test | conditions A and D, tasks 1, 4 and 7, 3 runs each = 18 |
| Extension | the same protocol with another model (a Sonnet-class model first) or another agent (Codex CLI or Gemini CLI with the package's adapter) | Replication only; each reported on its own, never pooled | conditional on budget |

Arm 2's project folder, invocation and capture rules are fixed in a dated amendment to
`benchmark/METHODOLOGY.md` before its first run, as the A11Y.md study did for its ecological arm.

### Determinism

No seed exists for the model. The benchmark promises a reproducible process, not reproducible
outputs: frozen prompts and graders, the case tree's SHA-256 recorded with each collection
(`benchmark/cases.sha256`), the model string per generation, raw outputs committed, and an analysis
anyone can re-run on them.

### Results and publication

- Raw results under `benchmark/results/<date>[-pilot]/`: the tool's aggregate JSON, one Markdown file
  per generation (the final reply), `runs.jsonl` (one line per generation: condition, task, run,
  model, cost, tokens, grader verdicts), and the analysis table. Redacted as plan 037 requires: no
  account e-mail, no local paths (`<repository>`, `<temp>`), checked by a grep before committing.
- `benchmark/RUNBOOK.md`: how to collect, so a collection session needs no decisions.
- `benchmark/DEVIATIONS.md`: every departure from METHODOLOGY.md after it is frozen, dated, newest
  first, never edited away.
- README: a "Does it work?" section with the table and a link to the method. The pilot table is
  labelled "pilot, not results" until the full collection replaces it.

### Registration

- `benchmark/METHODOLOGY.md` is version 1.0 when the pull request that adds it merges, and frozen
  from then: a later change is a new version row in it and an entry in DEVIATIONS.md.
- The pilot runs on version 1.0 and is disclosed in it; its numbers prove the harness only.
- The public repository's first commit (plan 020 part B) carries the frozen methodology. That commit
  is its public timestamp, and **full collection happens after it**, never before.
- An OSF registration as well is optional and open (decision below).

### Budget

- Pilot: one run per task and condition (36 generations), with the judge, capped at US$2.00 for every
  run in this plan together, the mechanics check above included (US$0.07). `--max-cost-usd` is set to
  what remains; if the measured cost per generation says 36 will not fit, the pilot drops whole
  tasks (never conditions), and the plan records which.
- Estimate before the pilot, from the mechanics check and plan 037's sonnet runs scaled to Haiku
  list prices: US$0.03 to US$0.06 per generation plus about US$0.01 per judged run, so US$12 to
  US$24 for the full Arm 1 collection. The pilot replaces this with a measured cost per condition
  (`benchmark/RUNBOOK.md` and the README carry the measured figure).
- Full collection waits for the cap Marco sets.

## Decisions

- **Full-collection cap**: no default; collection does not start without it.
- **OSF registration**: default, none; the public repository's first commit is the timestamp.
- **Second judge**: default, recorded as planned with no name; the kappa is reported once there is one.
- **Extension arms**: default, none funded; declared so that adding one changes no protocol.

## Commands you will need

| Purpose | Command | Expected |
| --- | --- | --- |
| Build and check the cases | `node benchmark/build.js --check` | prints the case-tree SHA-256, equal to `benchmark/cases.sha256`; every sample verdict as expected |
| Analysis self-test | `node benchmark/analysis/analyze.js --self-test` | `self-test: N checks passed` |
| Pilot (SWARE) | see `benchmark/RUNBOOK.md` | an aggregate JSON under the scratch folder |
| Isolation | `claude plugin list`, `claude plugin marketplace list`, SHA-256 of `~/.claude/settings.json` and `~/.claude/plugins/installed_plugins.json`, before and after | identical |
| Not published | `npm pack --dry-run 2>&1 \| grep -c benchmark/` | `0` |
| Local CI | `bash ~/qa-ci-all.sh <worktree> linux` | `ALL LOCAL CI` line passes |

## Scope

**In scope**: this plan; `benchmark/` (new); a `benchmark/cases/` line in `.gitignore` (the built
case tree); one step in `.github/workflows/ci.yml`'s Linux job; one README section; this plan's row.

**Out of scope**: any shipped file (`.claude/`, `bin/`, installers, adapters); `evals/` (plan 037's
suite stays as it is); the full collection, Arm 2, the human review and extension arms, which run
later under this protocol; installing anything into any Claude Code.

## Git workflow

- PR 1, branch `docs/plan-048-efficacy-benchmark`: this plan and its README row (`docs(plans):`).
- PR 2, branch `test/efficacy-benchmark`, stacked on PR 1: `test:` for the harness, fixtures,
  graders, scripts and results; `docs:` for METHODOLOGY, CONTROL, PROMPTS, RUNBOOK, DEVIATIONS and
  the README section; `ci:` for the workflow step. Nothing here reaches a user, so no `feat:` or
  `fix:`.
- No AI attribution lines. Merge commit, never squash, never an empty body.

## Steps

### Step 1: this plan

Write the plan and its `plans/README.md` row. Pull request 1.

### Step 2: the benchmark folder

1. `benchmark/METHODOLOGY.md`, `CONTROL.md`, `PROMPTS.md`, `RUNBOOK.md`, `DEVIATIONS.md`.
2. `benchmark/fixtures/<task>/` and `benchmark/graders/<task>/` for the nine tasks, each grader a
   `claude plugin eval` grader file; a correct sample answer per task, and one generic wrong answer.
3. `benchmark/control-standard/` (the placebo plugin) and `benchmark/bare-plugin/`. Size parity and
   the word sweep recorded in CONTROL.md.
4. `benchmark/build.js`: builds `benchmark/cases/<condition>/<task>/` from PROMPTS.md, the fixtures
   and the graders; `--check` also runs the graders on the samples, runs the placebo's word sweep, and
   compares the tree's SHA-256 with `benchmark/cases.sha256`.
5. `benchmark/analysis/analyze.js` (with `--self-test`), `extract.js` (aggregate JSON and kept traces
   to `runs.jsonl` and one Markdown file per generation, redacting as it goes), `blind.js`.
6. The CI step: `node benchmark/build.js --check && node benchmark/analysis/analyze.js --self-test` in
   the Linux job.
7. `npm pack --dry-run` lists nothing under `benchmark/`.

### Step 3: the pilot

1. Record `claude plugin list`, `claude plugin marketplace list` and the SHA-256 of the settings and
   plugin registry files.
2. Build the cases; run `claude plugin eval .` from the worktree with `--eval-dir benchmark/cases
   --ablation none --runs 1 --model claude-haiku-4-5-20251001 --judge-model
   claude-haiku-4-5-20251001 --trust-plugin --no-publish --keep-temp --max-cost-usd <remaining>
   --output-dir <scratch>`.
3. Extract, redact, analyse; commit under `benchmark/results/<date>-pilot/`; delete the kept temp
   directories.
4. Repeat the isolation record; the two must match.
5. Read every pilot output against its graders: a grader that judged an output wrongly is a grader
   defect, fixed before freezing and recorded in METHODOLOGY.md's pilot disclosure, never after full
   collection starts.

### Step 4: the README section

"Does it work?": what is measured and why there are four conditions, the pilot table labelled "pilot,
not results", the measured cost, and links to METHODOLOGY.md and the pilot results. One block under
its own heading; nothing else in the README changes.

## Done criteria

- [ ] PR 1 open with this plan and its row.
- [ ] `benchmark/` exists with every file named in step 2; `build.js --check` and `analyze.js
      --self-test` pass locally and in the CI step.
- [ ] The pilot ran within the budget, its results are committed and redacted, and the isolation
      records match.
- [ ] The README section exists, labelled as a pilot.
- [ ] `npm pack --dry-run` lists nothing under `benchmark/`.
- [ ] This plan's "Outcome" records the pilot's cost per condition and the full-collection estimate.

## STOP conditions

- The pilot's spend would pass US$2.00 for all runs together: `--max-cost-usd` stops it; do not raise
  it. Record what ran.
- A case meant for A or B loads any command or skill of a plugin, or C loads anything but the
  placebo: the conditions are not what this plan says; stop.
- `claude plugin list`, `claude plugin marketplace list` or the recorded hashes differ after a run:
  something was installed; stop, report, do not try to undo it by hand.
- A correct sample fails a grader that cannot be fixed without weakening what it checks: report the
  grader and the claim it was meant to support.
- The placebo cannot be made silent on testing at a size within 25% of 16 KB: report rather than pad.

## Rejected approaches

- **The tool's own no-plugin arm for condition A.** It gives A only for D's prompt (with an unexpanded
  slash command in it), and B and C still need their own runs. One code path for all four, through
  `plugins:` and `--ablation none`, keeps the conditions alike.
- **The placebo pasted into the prompt.** D's content arrives by command expansion; a pasted document
  arrives as user text. The comparison would partly measure delivery. The placebo is a plugin
  command, loaded the same way.
- **A placebo `SKILL.md`.** `npx skills add` discovers `SKILL.md` folders in a repository (plan 022)
  and could offer the placebo to a user. A command file is not discovered.
- **Committing the built case tree.** It would hold four copies of every grader. The sources are
  committed, the build is deterministic, and its SHA-256 is.
- **An LLM judge as the primary outcome.** It votes differently between runs and reads long outputs
  partially; the primary outcome is deterministic.
- **A free model API as in the A11Y.md study.** The thing under test is a Claude Code plugin, and
  `claude plugin eval` is the harness that loads it as a user would; a raw API call would have to
  re-implement command expansion.
- **Sonnet for Arm 1.** About three times Haiku's list price; within the cap it would allow a third of
  the runs. It is the first extension arm instead.

## Maintenance notes

- Scores drift with the model: never compare a run against another made with a different model
  string, and re-run every condition together.
- A change to a command or skill under test changes condition D. Before a new collection, re-check
  the placebo's parity in CONTROL.md and log the package version in the results.
- The graders encode the fixtures' right answers. A fixture change needs its samples and graders
  changed in the same commit, and `build.js --check` green, before any run.

## Outcome (2026-10-18)

Steps 2 to 4 done by plan-048 on branch `test/efficacy-benchmark`, stacked on this plan's branch.
Default used (Marco asked for all remaining work on 2026-10-18): none of the four decisions above
needed one for this work; the full-collection cap, OSF, the second judge and the extension arms stay
open.

- **Built**: `benchmark/` with METHODOLOGY (version 1.0), CONTROL, PROMPTS, RUNBOOK, DEVIATIONS,
  nine fixtures, 66 graders (`con-`, `fmt-`, `jdg-`) with a correct sample per task and wrong
  samples, the placebo plugin (`writing-guide`, 15,493 bytes, 96.2% of the 16,104-byte mean, no
  banned word), the bare plugin, `build.js` (case tree SHA-256 in `benchmark/cases.sha256`),
  `analysis/analyze.js` (`--self-test`, 24 checks), `analysis/extract.js` (redaction, `--regrade`),
  `analysis/blind.js`; the CI step "Efficacy Benchmark Integrity" in the Linux job.
- **Pilot**: 36 generations, one per task and condition, `claude-haiku-4-5-20251001`, every run one
  turn, no Read or Skill call in any condition. Content pass A 3/9, B 4/9, C 2/9, D 8/9; package
  format A, B, C 0/9, D 7/9. Every contrast prints "underpowered, no conclusion", as designed.
  Results: `benchmark/results/2026-10-18-pilot/`.
- **Cost**: US$1.354 of the US$2.00 allowed (mechanics check US$0.065, pilot US$1.288 of which the
  judge US$0.104). Mean cost per generation without the judge: A US$0.0246, B US$0.0268, C US$0.0341,
  D US$0.0461.
- **Full-collection estimate**: 360 generations at those means, US$11.84, plus about US$1.04 for the
  judge on 120 runs: **about US$13**; a cap of US$16 leaves room for variance. Waits for Marco's cap.

> **Note, 2026-10-19, coordinator.** Every US$ figure in this plan, in `benchmark/METHODOLOGY.md`
> and in the README is the cost Claude Code reports at API list prices (`total_cost_usd`, `costUsd`).
> The pilot ran in a Claude Code signed in with a claude.ai subscription, not an API key, so it was
> not billed per token: it counted against the plan's usage limits. `--max-cost-usd` still bounds a
> run by that reported figure. The full collection's "cap" is therefore a usage bound, and which
> account runs it is Marco's choice.

- **Isolation**: `claude plugin list`, `claude plugin marketplace list` and the SHA-256 of
  `~/.claude/settings.json`, `installed_plugins.json` and `known_marketplaces.json` unchanged before
  and after every run; kept temporary folders deleted. Nothing installed.
- **Not published to npm**: `package.json` `files` is an allowlist without `benchmark/`;
  `npm pack --dry-run` lists no `benchmark/` path.

> **Correction, 2026-10-18.** Task 7's row in "Tasks" says the six barriers are "found" by their
> WCAG criterion numbers. The pilot showed two conditions finding every barrier in words without the
> numbers, so each `con-find-*` grader now accepts the number or the barrier named, and citing all
> six numbers is the contract grader `fmt-criteria-cited`. Twelve other grader corrections were made
> before the freeze for the same kind of reason; METHODOLOGY.md's "Pilot disclosure" lists all of
> them with the output that showed each.

### Findings about the package (recorded, not acted on here)

- Under `/bem-te-vi:qa-defect` the model filled Root Cause with the developer's unconfirmed guess,
  where the command says to leave it `N/A — not yet analysed`.
- Under `/bem-te-vi:qa-cases` (task 2) one case's Source was "Story requirement (initial state)",
  which `validate-tc-format.sh` rejects, and no invalid transition beyond the one AC-5 gives was
  written.
- `/qa-defect`'s title rule asks for `[Component] – [What failed] when [condition]`, but two of its
  three good example titles have no `when` clause.
- One run per cell says nothing about how often these happen; the full collection will.

> **Note, 2026-10-19.** Marco decided to fix the three findings above before the 4.1.0 export;
> fixed in `fix/pilot-content-defects`, one commit each. Root Cause: the template's placeholder
> asked to be filled and the template had no place for a suspicion; Root Cause now starts as
> `N/A — not yet analysed` and a new Suspicions field takes unconfirmed leads. Source: the hook was
> right and is unchanged (the qa-groomer agent already says a requirement outside the numbered ACs
> is `Added by QA (<why>)`); `/qa-cases` now says so and lists the accepted and rejected values.
> Titles: the two table titles and also the complete example's title (DR-AUTH-001, which had no
> `when` clause either) now have one. `tests/test-tc-contracts.sh` checks all three. The second
> finding's other half, no invalid transition beyond AC-5, is not addressed there. Condition D's
> content therefore changed after the pilot: `benchmark/DEVIATIONS.md`, entry of 2026-10-19.
