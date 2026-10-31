# Plan 068: The `qa-static-analysis` skill: triage what a static analysis tool reports

> **Executor instructions**: Branch `feat/qa-static-analysis-skill` from `main`, one pull request
> into `main`. Write the evals (step 1) and record their failure against `main` before the skill
> exists. No installer changes. Release as a minor version (`feat`). `npm publish` is **Marco's**.

## Status

- **Priority**: P3. Closes the one CTFL v4.0.1 topic the README lists as not covered; no defect.
- **Effort**: S. One skill, one reference, two evals, wiring and counts.
- **Risk**: LOW. Shipped content only; the generators and installers take a new skill folder as
  they are.
- **Depends on**: plans 040 (`qa-flaky`, the pattern this follows), 037 step 5 (behavioural evals,
  local and manual only), 038 (citation checks), 047 (the Agent Skills tree)
- **Planned at**: commit `2833678` (`main`), 2026-10-27

## Why this matters

CTFL v4.0.1 §3.1 covers static testing in two halves: reviews and static analysis. `/qa-static`
(work products) and `/qa-review` (code) cover reviews. Static analysis appears only as a tool
category in the `qa-reference` skill's `references/test-tools.md` (§6.1) and as a step in
`testing-in-delivery.md` (§2.1.5). The README's coverage table lists "Tool-based static analysis"
as the gap under chapter 3, and on 2026-10-20 Marco declared it a gap with no work planned
(`ROADMAP.md`).

Marco reopened it on 2026-10-27 ("Go"). What was missing is not running a tool, which is one line
of CI; it is what QA does with the result. A first run on an existing repository reports hundreds
of findings. Without triage, the team either ignores the report or gates CI on all of it and
switches the tool off a week later.

**Demand evidence.** `ROADMAP.md` asks that a new skill have "evidence that people need it". There
is none yet: no issue, field report or request. This plan rests on the syllabus coverage alone, by
Marco's decision, and the PR says so.

## Scope (decided 2026-10-27: triage only)

**In.** The user gives a tool's report: SARIF 2.1.0 (CodeQL, Semgrep, ESLint's SARIF formatter
and most security scanners export it), ESLint JSON, Semgrep JSON, `npm audit --json`, `tsc` output,
or pasted text. The skill reads the cited code before judging each finding and produces:

1. **A triage table**, one row per finding (duplicates folded into one row with a count): rule,
   location, verdict, severity, action, reason. Verdicts:
   - **True positive**: the code has the defect the rule describes.
   - **False positive**: the rule fires, but the code does not have the defect, with the reason
     read from the code (for example input already sanitized two lines up).
   - **Not reachable**: real in principle, but not reachable in this product, such as a vulnerable
     dependency used only by tests or a function never called. Written as an assumption unless the
     code shows it.
   - **Needs a person**: the skill cannot decide from the code it can read; it says what would decide it.
2. **Severity by product risk** (§5.2.1, likelihood and impact), not by the tool's label; when they
   differ, show both.
3. **An action** per finding:
   - Fix (a true positive; worth a `/qa-defect` report when it can fail in use).
   - Suppress, inline and with the reason, in the tool's own syntax.
   - Accept into the **baseline** as known debt.
   - Change the rule configuration, when the rule is wrong for the whole project.
4. **The CI gate**: fail on new findings only, not on the baseline; how each common tool does this
   (SARIF baseline, `eslint --max-warnings` with a recorded baseline count, Semgrep `--baseline-commit`).
5. **What to report**: true positives that can fail in use go to `/qa-defect`; patterns across many
   findings go to the process (§1.2.2, QA versus testing), not only to the fix.

**Out.**

- Choosing, installing or configuring a tool. Choosing one is `references/test-tools.md`; this
  skill never edits the project's lint or scanner configuration (the `linting-standards` rule).
- Running the tool for the user. It may suggest the command that produces the report.
- Treating a clean report as proof of quality (§1.3 principle 1; the `test-tools` rule).

## Steps

1. **Evals first** (`evals/qa-static-analysis-triage/`, the `claude plugin eval` layout of plan 037
   step 5). A small fixture: three source files, plus a SARIF report of six findings planted as
   - one true positive (SQL built by concatenating a request parameter);
   - one false positive (the same rule on a value already parameterized);
   - one duplicate of the true positive, from a second rule;
   - one finding in a test file, Not reachable;
   - one in the baseline (`baselineState: "unchanged"`);
   - one a rule the project could disable (a style rule firing on generated code).

   Graders (regex, like `qa-cases-format`) check the verdict of each planted finding, that the
   duplicate is folded, that the baseline finding is not in the CI gate, and that the reply reads
   the code instead of trusting the report. Run locally only, within plan 037's cap; record the
   failing run against `main` (the plugin without the skill) and the passing run after. Results go
   to `evals/results/`.

   > **Correction, 2026-10-31.** The graders as written are `llm` judges, not regex, and the run
   > against the plugin without the skill did not fail. See "Note, 2026-10-31".

2. **The skill**: `.claude/skills/qa-static-analysis/SKILL.md`. It mirrors `qa-flaky`: banner with
   citations, the "If a rule is not loaded" paragraph, the rules and references it reuses, then
   steps (read the report, read the code, verdict, severity, action, gate, report). The body stays
   under the 5,000-token cap (`tests/test-skill-bodies.sh`). Cites §3.1, §3.1.2, §3.1.3, §2.1.5,
   §5.2.1, §5.5, §6.1, §6.2; says what is **not** syllabus content (baselines, SARIF, suppression
   syntax), as `qa-flaky` does.
3. **Its reference**: `.claude/skills/qa-static-analysis/references/tool-formats.md`. For each
   format: where the rule, location, severity and baseline state are in the report, and the inline
   suppression and baseline syntax of ESLint, Semgrep, CodeQL, `tsc` and `npm audit`. Tool details
   change, so each section names the tool version or documentation date it was checked against.
4. **Wiring**:
   - `/qa` routes "static analysis", "linter findings", "scanner report", "SARIF" to the skill,
     replacing today's route to `references/test-tools.md` for findings (choosing a tool stays there).
   - `references/test-tools.md` and `testing-in-delivery.md` point to the skill for triage.
   - README: coverage table chapter 3 drops the gap; skill lists and counts (8 to 9 skills, 24 to 25
     Agent Skills, the `npx skills add` list); the skill-description character count.
   - `ROADMAP.md`: the declared gap becomes this plan; `llms.txt` gets the new files.
5. **Checks**: `./generate-adapters.sh`, `npm test`, `npm run lint`, markdownlint,
   `tests/verify-adapters.sh`, `tests/plugin/verify-plugin.sh`, both installer suites (a new skill
   folder is installed and uninstalled like the others), the evals (step 1).

## Rejected approaches

- **Extending `/qa-static`.** It reviews work products, not tool output; its input, steps and
  output all differ, and it is already 18 KB against the body cap.
- **A reference page only** (a section in `qa-reference`): it would hold the knowledge but no
  workflow; `/qa` would route to a page, and the triage steps would be left to the model.
- **Triage plus tool setup** (the larger scope): recommending and configuring tools duplicates
  `references/test-tools.md` and goes stale with every tool release. Not chosen by Marco.
- **Running the tool inside the skill**: the package runs nothing for the user (`ROADMAP.md`,
  "Out of Scope").

## Benchmark

Plan 048's tasks do not include static analysis; no case, grader or digest changes. Condition D
loads the plugin, so the new skill is present in D's runs. It is listed among the skills the model
can see, which adds about 400 characters of skill description to D's context.

## Outcome (2026-10-27)

- **Done**: steps 2-5. The skill (7.4 KB) and its reference, the `/qa` routes, the pointers from
  `test-tools.md` and `testing-in-delivery.md`, README (coverage table, skill list, 25 Agent Skills,
  sizes), ROADMAP and `llms.txt`. `npm test`, lint, markdownlint and `tests/verify-adapters.sh`
  pass.
- **Step 1, evals: written, not run.** Two cases, `qa-static-analysis-triage` (the skill named) and
  `qa-static-analysis-plain-request` (plain words), committed before the skill (`e86d191`) so the
  "before" round can run at that commit. On this machine Claude Code is 2.1.224, where
  `claude plugin eval` prints "currently in early access" and runs nothing (no cost). Both rounds
  are left to Marco, on a Claude Code where the command works (plan 037 ran it on 2.1.291):

  ```bash
  git switch --detach e86d191
  claude plugin eval . --case 'qa-static-analysis*' --max-cost-usd 2.4 --no-publish \
    --json evals/results/2026-10-27-static-analysis-before.json
  git switch feat/qa-static-analysis-skill
  claude plugin eval . --case 'qa-static-analysis*' --max-cost-usd 2.4 --no-publish \
    --json evals/results/2026-10-27-static-analysis-after.json
  ```

- **Stand-in check, not an eval**: one `claude -p --model sonnet --plugin-dir <checkout>` run of
  the plain-request prompt (US$0.59; Marco's own configuration loaded too, so not isolated). The
  reply used the skill and got five of the six planted findings as the graders expect. It ranked
  the test-only finding "fix now", following the skill's sentence that test-only code "still
  deserves a fix"; that sentence now gives it a low priority unless the code reaches something
  shared. Not re-run after the change.
- **Tool details checked on 2026-10-27**: ESLint inline descriptions and bulk suppressions,
  `nosemgrep` and `.semgrepignore`, Semgrep `--baseline-commit`, `npm audit` flags. CodeQL's
  inline suppression is from its 2.12.0 changelog and secondary sources, and the reference says to
  check it before relying on it.

## Note, 2026-10-31: the evals ran, and they cannot show a gain

Both rounds ran on SWARE (Claude Code 2.1.291, `--runs 3 --model sonnet --trust-plugin -j 3`, a
fresh clone) on 2026-10-31, under plan 037's cap: "before" at `e86d191`, "after" at `2888edc`, the
current `main`, not the feature branch the Outcome names, which is merged. Files:
`evals/results/2026-10-31-static-analysis-before.json` and `-after.json`, with paths replaced by
`<repository>` and `<temp>`; scores and costs are unchanged. A first attempt on 2026-10-30 ended in
`auth_failed` at no cost; the cause was not established, and the rerun authenticated.

| Round | Case | Plugin arm | Baseline arm | Skill call | Cost (US$) |
| --- | --- | --- | --- | --- | --- |
| Before | plain request | 1.00 | 1.00 | 0 of 3 | 1.51, both cases |
| Before | skill named | 1.00 | 0.89 | 0 of 3 | |
| After | plain request | 1.00 | 0.94 | 3 of 3 | 1.87, both cases |
| After | skill named | 0.94 | 1.00 | 0 of 3 | |

- **The red step did not happen.** The plugin without the skill scored 1.00 on both cases, so
  these evals do not show that the skill improves the answer. Sonnet already gets the six planted
  findings without it. Every difference above is one or two graders in one run. Showing a gain
  would need a harder fixture or a smaller model.
- **What they do show: the skill is found.** Asked in plain words, the model called it in 3 of 3
  runs on `main`, and in 0 of 3 before it existed.
- **"Skill call 0 of 3" on the named case is the indicator's limit, not a miss.** `skill-fired`
  counts `Skill` tool calls, and a slash command expands without one. The replies show the skill
  loaded: on `e86d191` all three open by saying the command "isn't installed"; on `main` none does,
  they take 2 to 6 turns instead of 1, and each states what was read and what was not, as the
  skill's report step asks. The indicator could be dropped from that case.
- **The one lost point looks like a split judge, not a wrong reply.** In the named case, run 2,
  `baseline-out-of-gate` failed on votes FAIL FAIL PASS. That reply notes the finding is marked
  `unchanged`, says "Fail on new findings only", and baselines it with an owner, which is what the
  rubric asks. The fixture may be the cause: the prompt calls this the first run, a finding marked
  `unchanged` does not fit one, and all three replies in that case say so and query it instead of
  taking it as settled. The score is kept as collected.
- **The test-only sentence, "Not re-run after the change" above**: `test-only-not-reachable` passed
  in all six plugin-arm runs on `main`.
