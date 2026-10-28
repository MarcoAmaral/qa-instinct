# QA Instinct efficacy benchmark: methodology

> **Status:** version 1.0, frozen from the commit that merges it into the repository. Results are
> reported against this protocol as written; every later departure is a dated entry in
> [`DEVIATIONS.md`](DEVIATIONS.md), never a silent edit. A change before full collection is a new
> row under "Version history" and an entry in DEVIATIONS.md.
>
> **Planned in:** [`plans/048-efficacy-benchmark.md`](../plans/048-efficacy-benchmark.md).
> **Prepared by:** Marco Amaral.

## Version history

| Version | Date | What changed and why |
| --- | --- | --- |
| 1.0 | 2026-10-18 | First version, written before any benchmark data. The pilot ran on it (see "Pilot disclosure"). |
| 1.1 | 2026-10-25 | The package was renamed QA Instinct (plan 065): condition D invokes `/qa-instinct:<command or skill>`, and the case digest is frozen again. Nothing else changed; the pilot's disclosure keeps the commands it ran. See DEVIATIONS.md, 2026-10-25. |
| 1.2 | 2026-10-27 | Before Arm 1, from the Extension arm's read-through: six content graders accept the wordings they wrongly failed (`con-no-4-1-1`, `con-limits-stated`, `con-severity-and-priority`, `con-repro-rate`, `con-undocumented-500`, `con-404-missing-code`), and the flaky-run-history fixture's cart failure is a single non-retrying read after a fixed wait, so its evidence supports the judge rubric. Condition D also loads the package as it now is, with the `qa-rules` skill (plan 067) and the `qa-static-analysis` skill (plan 068). The case digest is frozen again. See DEVIATIONS.md, 2026-10-27. |

## Credit

The method is borrowed from the A11Y.md efficacy benchmark by Felipe A. Carriço
(<https://github.com/fecarrico/A11Y.md/tree/main/benchmark>; the study's account:
<https://fecarrico.github.io/a11ymd/en/estudo/>): a one-sentence control and a size-matched
placebo beside the bare model, prompts frozen before collection, an analysis fixed in advance,
blind human scoring, a deviations log, and a primary arm kept apart from an ecological one. Only the
method is borrowed; every file in this folder was written for QA Instinct.

## The question

QA Instinct says it makes an AI assistant do better QA work. A tester deciding whether to trust that
would ask four things, and each is a claim this benchmark tests:

1. **Content.** With QA Instinct, does the output for a QA task contain what a competent tester would
   put in it (every acceptance criterion covered, the right boundary values, the seeded defects
   found, the always-failing test kept apart from the flaky ones) more often than without it?
2. **Contract.** Does the output follow the package's own formats (the `TC-CODE-NNN` cases its hook
   accepts, the `DR-` report, the ledger) more often than without it? This one is expected by
   construction. It is reported as a check that condition D did what it should, never as evidence
   of quality on its own.
3. **Not just form.** Does the difference in claim 1 hold against a placebo: a document of the same
   size and shape, about something else, loaded the same way (D vs C)?
4. **Not just a phrase.** Does it hold against one generic sentence asking for professional work
   (D vs B)?

No claim is made about tasks outside the nine below, about models other than the one each arm names,
or about whether the tests written would find real defects in a real product.

## Conditions

The task prompt is identical in every condition. What differs is the preamble before it and the
plugin the run loads. [`PROMPTS.md`](PROMPTS.md) holds every preamble and prompt verbatim, and
[`build.js`](build.js) builds the cases from it and nothing else.

| | Condition | Preamble (verbatim) | Plugin the run loads |
| --- | --- | --- | --- |
| A | bare | none | [`bare-plugin/`](bare-plugin/): a manifest and nothing else |
| B | generic | `Work as a thorough, professional QA engineer.` | [`bare-plugin/`](bare-plugin/) |
| C | placebo | `/writing-guide:help-articles` | [`control-standard/`](control-standard/): one command, a help-article writing guide |
| D | QA Instinct | `/qa-instinct:<command or skill>` (per task, below) | the repository root, the plugin as published |

- **D** types what the README tells a user to type for the job: the namespaced command or skill,
  then the request. Whether QA Instinct loads when it is not named is a separate question, measured by
  `evals/qa-cases-plain-request` (plan 037), and not repeated here.
- **C** is the placebo. How it was built, why it is silent on testing, and what it cannot match are
  in [`CONTROL.md`](CONTROL.md).
- **A and B** load a plugin with no commands, skills or agents. Every condition therefore runs
  through the same `claude plugin eval` path with `--ablation none`; none of them uses the tool's
  own no-plugin arm.
- In every condition Claude Code's built-in skills and plugins are present, as for any user.

**Pre-registered contrasts:** D vs C (the package's content against form and size), D vs B (against
one free sentence), D vs A (the headline effect).

## Tasks

Nine tasks cover the package's main commands and skills. Each has a fixture with a known right
answer under [`fixtures/`](fixtures/) and graders under [`graders/`](graders/). Every prompt ends
with the same closing: state assumptions instead of asking, and reply with the deliverable only.

| # | Task | D invokes | Fixture |
| --- | --- | --- | --- |
| 1 | `cases-quantity` | `qa-cases` | A story with three ACs: a 1 to 20 quantity limit, a confirmation at 0, a message above 20 |
| 2 | `cases-order-status` | `qa-cases` | A story with five ACs describing an order's status lifecycle |
| 3 | `cases-shipping-fee` | `qa-cases` | A story with three ACs: shipping fees on membership, subtotal and speed |
| 4 | `defect-gift-card` | `qa-defect` | A CI log: a 500 on 3 of 10 attempts, the exact error, the build, and a developer's guess |
| 5 | `plan-split-payment` | `qa-plan` | A feature brief: two-card payment, a gateway, a rounding rule, a deadline, one half-time tester |
| 6 | `api-orders-contract` | `qa-api` | An OpenAPI 3.0 snippet and three recorded responses that break it in three ways |
| 7 | `a11y-signup-form` | `qa-a11y` | A sign-up page's source with six real barriers and one obsolete-criterion bait |
| 8 | `flaky-run-history` | `qa-flaky` | Ten CI runs of one commit: a timing flake, a shared-data flake, a product race, a test that always fails, a stable test |
| 9 | `bdd-loyalty-points` | `qa-bdd` | A story with four ACs: earning, tiers, a refusal message, and one vague AC |

`/qa-cases` has three tasks because it is the command the README leads with, and because its three
fixtures each call for a different technique (boundary values, state transitions, a decision
table).

## Measurement

### Graders

`claude plugin eval` has no custom-code graders, so every deterministic check is a `regex` grader
on the final reply. A grader's name says its family:

- **`con-`, content**: what a competent tester would produce whatever the format. An acceptance
  criterion counts as covered when it is named by its id or by the observable it specifies (its
  exact message, its state change, its fee); a boundary counts when its values appear; a seeded
  defect counts when its criterion is named.
- **`fmt-`, contract**: the package's own formats and vocabulary, restated from its commands and
  skills (the `validate-tc-format.sh` checks as plan 037 restated them, the `DR-` fields, `A11Y-`
  ids, the ledger columns, the release gate).
- **`jdg-`, judge**: an LLM judge, used only where no regex can decide (task 4: the developer's guess
  kept apart from the observed failure; task 5: every risk score equals likelihood times impact and
  the highest come first; task 8: each flaky test's cause class matches the evidence). The judge is
  the same model as Arm 1 and votes three times; it is a secondary outcome only.

The graders, per task (each file under [`graders/`](graders/) holds the pattern and this text):

| Task | Grader | What it checks |
| --- | --- | --- |
| cases-quantity | `con-bva-values` | Two-value boundary value analysis of the 1 to 20 range: the values 0, 1, 20 and 21 all appear (CTFL v4.0.1 section 4.2.2). |
| cases-quantity | `con-every-ac` | Every acceptance criterion is covered: named by its id, or by what it specifies (AC-1: 1 or 20 accepted; AC-2 and AC-3: their exact messages). |
| cases-quantity | `con-technique-named` | The test design technique that fits the story best is named: boundary value analysis. |
| cases-quantity | `fmt-every-case-complete` | No `## TC-CODE-NNN:` case lacks any of the eleven field rows the hook requires, each with a value, and a Source naming an acceptance criterion or `Added by QA (reason)`. A row counts only inside its own case, up to the next heading, as in the hook. |
| cases-quantity | `fmt-frontmatter` | The reply starts with the frontmatter block `validate-tc-format.sh` requires: `---` on the first line, the nine keys it checks (`runbook` or its old name `cdt`), and a closing `---`. Restated from `evals/qa-cases-format` (plan 037). |
| cases-quantity | `fmt-has-cases` | At least one case heading in the package's `## TC-CODE-NNN:` form. |
| cases-order-status | `con-every-ac` | Every acceptance criterion is covered: named by its id, or by what it specifies (the state change on one line, or AC-5's exact message). |
| cases-order-status | `con-technique-named` | The test design technique that fits the story is named: state transition testing. |
| cases-order-status | `con-unlisted-invalid-transition` | A case for an invalid transition the ACs do not list (AC-5 lists only cancelling a Shipped order): shipping an unpaid order, delivering one that was not shipped, paying or cancelling a Delivered or Cancelled order. The line must say the action is attempted or refused. State transition testing covers invalid transitions, not only the valid ones (CTFL v4.0.1 section 4.2.4). |
| cases-order-status | `fmt-every-case-complete` | No `## TC-CODE-NNN:` case lacks any of the eleven field rows the hook requires, each with a value, and a Source naming an acceptance criterion or `Added by QA (reason)`. A row counts only inside its own case, up to the next heading, as in the hook. |
| cases-order-status | `fmt-frontmatter` | The reply starts with the frontmatter block `validate-tc-format.sh` requires: `---` on the first line, the nine keys it checks (`runbook` or its old name `cdt`), and a closing `---`. Restated from `evals/qa-cases-format` (plan 037). |
| cases-order-status | `fmt-has-cases` | At least one case heading in the package's `## TC-CODE-NNN:` form. |
| cases-shipping-fee | `con-every-ac` | Every acceptance criterion is covered: named by its id, or by what it specifies (AC-1: the $5.99 fee; AC-2: free standard shipping for members; AC-3: the member's $7.99 express fee). |
| cases-shipping-fee | `con-every-fee` | Every fee outcome of the rules appears: free, $5.99, $12.99 and $7.99. |
| cases-shipping-fee | `con-subtotal-boundary` | The $50.00 subtotal boundary is tested on both sides: $49.99 and $50.00. |
| cases-shipping-fee | `con-technique-named` | The test design technique that fits the rules is named: decision table testing. |
| cases-shipping-fee | `fmt-every-case-complete` | No `## TC-CODE-NNN:` case lacks any of the eleven field rows the hook requires, each with a value, and a Source naming an acceptance criterion or `Added by QA (reason)`. A row counts only inside its own case, up to the next heading, as in the hook. |
| cases-shipping-fee | `fmt-frontmatter` | The reply starts with the frontmatter block `validate-tc-format.sh` requires: `---` on the first line, the nine keys it checks (`runbook` or its old name `cdt`), and a closing `---`. Restated from `evals/qa-cases-format` (plan 037). |
| cases-shipping-fee | `fmt-has-cases` | At least one case heading in the package's `## TC-CODE-NNN:` form. |
| defect-gift-card | `con-build-and-commit` | The environment names the build and the commit from the log. |
| defect-gift-card | `con-exact-error` | The actual result copies the exact error from the response body. |
| defect-gift-card | `con-expected-actual` | Both the expected outcome (the summary line) and the actual one (the toast text) are quoted exactly; a typographic minus or dash in place of the hyphen is accepted. |
| defect-gift-card | `con-repro-rate` | Reproducibility states the observed rate: 3 failures in 10 attempts. |
| defect-gift-card | `con-severity-and-priority` | Severity and priority are both given, each with a value (on the same line or the line after its label). |
| defect-gift-card | `fmt-dr-id` | The report has an identifier in the package's `DR-CODE-NNN` form. |
| defect-gift-card | `fmt-root-cause-na` | Root Cause is left `N/A` until analysis finds it, as the package requires, instead of adopting the developer's guess. |
| defect-gift-card | `fmt-title-form` | The title starts with the component, then a dash, then what failed, as the package's title rule asks (`[Component] – [What failed] when [condition]`). The `when` clause is not required, because two of the command's own good titles omit it. |
| defect-gift-card | `jdg-guess-not-cause` | PASS if the report treats the developer's remark about the currency service cache as an unconfirmed suspicion (for example a hypothesis, a lead, a suspected cause, or something to investigate) and does not state it as the established cause of the failure. FAIL if the report states, without qualification, that the currency service cache is the cause, or presents the developer's guess as an observed fact. |
| plan-split-payment | `con-entry-exit` | Entry and exit criteria are both defined. |
| plan-split-payment | `con-existing-checkout` | The existing single-card checkout is protected (regression). |
| plan-split-payment | `con-project-risk` | The brief's constraints (the sandbox's two days, the half-time tester, the deadline) are treated as project risks: named in a table row, as a risk register has them, or on a line that calls them a risk. The word "project" is not required. |
| plan-split-payment | `con-refund-risk` | The automatic refund after a declined second charge is identified as a risk to test. |
| plan-split-payment | `con-rounding-risk` | The remainder-cent rule is identified as a risk to test. |
| plan-split-payment | `fmt-plan-fields` | The nine fields of the package's test plan output appear: context, assumptions, stakeholders, communication, risk register, test approach, estimate, budget, configuration management. |
| plan-split-payment | `fmt-register-columns` | The risk register is a table with likelihood, impact and score columns. |
| plan-split-payment | `fmt-release-gate` | The plan names its release gate, the package's term for the cases that decide go or no-go. |
| plan-split-payment | `jdg-score-consistent` | PASS if the plan has a risk register in which every risk has a likelihood and an impact, every score equals likelihood multiplied by impact, and the risks with the highest scores are tested or listed first. FAIL if there is no risk register, if any score is not the product of its likelihood and impact, or if the order of testing ignores the scores. |
| api-orders-contract | `con-404-missing-code` | The 404 body lacks `code`, which the Error schema requires. |
| api-orders-contract | `con-total-type` | The 200 response's `total` is a string where the schema declares a number. |
| api-orders-contract | `con-undeclared-length` | The schema declares no maximum length for `note`, while the server enforces one. |
| api-orders-contract | `con-undocumented-500` | The 500 response is not documented in the contract (said in those words, or by setting it against the only statuses documented, 201 and 400). |
| api-orders-contract | `fmt-contract-strategy` | A contract strategy is recommended: schema conformance checks, or consumer-driven contract tests. |
| api-orders-contract | `fmt-drift-or-defect` | Each mismatch is classified in the package's two classes: documentation drift or software defect. |
| a11y-signup-form | `con-find-focus-visible` | `outline: none` on focus with no replacement is found (2.4.7, or by naming it). |
| a11y-signup-form | `con-find-img-alt` | The logo image without a text alternative is found (by its criterion, 1.1.1, or by naming the missing `alt`). |
| a11y-signup-form | `con-find-keyboard` | The `div` with an `onclick`, which a keyboard cannot reach or use, is found (2.1.1, or in words). |
| a11y-signup-form | `con-find-label` | The inputs with only a placeholder and no label are found (1.3.1, 3.3.2 or 4.1.2, or in words). |
| a11y-signup-form | `con-find-lang` | The missing page language is found (3.1.1, or the missing `lang`). |
| a11y-signup-form | `con-find-tabindex` | The positive `tabindex` is found (2.4.3, or by naming it). |
| a11y-signup-form | `con-limits-stated` | The audit says what it could not check from the source alone. |
| a11y-signup-form | `con-no-4-1-1` | The duplicate id is not reported under 4.1.1 Parsing, which WCAG 2.2 made obsolete; a mention that says it is obsolete, retired or deprecated, or that applies it only under WCAG 2.0 or 2.1, is allowed. |
| a11y-signup-form | `con-wcag-2-2` | The audit names WCAG 2.2 as the standard. |
| a11y-signup-form | `fmt-criteria-cited` | Every seeded barrier is reported under its WCAG criterion number (1.1.1, 3.1.1, 1.3.1 or 3.3.2 or 4.1.2, 2.1.1, 2.4.3, 2.4.7), as the package's findings format requires. |
| a11y-signup-form | `fmt-finding-id` | Findings carry the package's `A11Y-<PAGE>-NNN` identifiers. |
| flaky-run-history | `con-deterministic-apart` | The avatar test, which fails in every run, is kept apart as a deterministic failure, not called flaky. |
| flaky-run-history | `con-product-intermittent` | The latest-order test is traced to the product, not the test: the API or backend returns the list without the new order for a time (stale data, a race, replication or caching). |
| flaky-run-history | `con-search-isolation` | The search test is traced to data shared with another spec (isolation, order or parallel runs). |
| flaky-run-history | `fmt-ledger-columns` | The quarantine is a ledger table with an owner and a deadline per test. |
| flaky-run-history | `fmt-quarantine-tag` | The package's `@quarantine` tag is used. |
| flaky-run-history | `jdg-cause-classes` | PASS if the reply classifies the four tests that failed as follows, in any wording: the cart total test as a test timing problem (a fixed wait instead of waiting for the result); the search test as shared data or order dependence between specs; the latest-order test as a real intermittent defect in the product (the API returns the list without the new order for a time); and the avatar test as a consistent failure that is not flaky. The login test must not be called flaky. FAIL if any of the four is given a different cause, if the avatar test is called flaky, or if the login test is called flaky. |
| bdd-loyalty-points | `con-message-quoted` | A Then step quotes the exact message AC-3 specifies. |
| bdd-loyalty-points | `con-outline-examples` | The data-driven tier rule is written as a Scenario Outline with Examples. |
| bdd-loyalty-points | `con-tier-boundaries` | Both tier boundaries are tested on both sides: 499 and 500, 1,999 and 2,000. |
| bdd-loyalty-points | `con-vague-ac-flagged` | AC-4 ("should load fast") is flagged as not measurable as written, or the threshold used is stated as an assumption. |
| bdd-loyalty-points | `fmt-every-scenario-tagged` | Every scenario has a tag line directly above it, as the package's writing rules require. |
| bdd-loyalty-points | `fmt-feature-header` | The feature starts with the package's header: `Feature:`, then As a / I want / So that. |

### Graders are checked before any paid run

Each task has a hand-written correct answer, `graders/<task>/samples/correct.txt`, and tasks with a
"must not contain" grader also have a wrong answer, `samples/wrong.txt`. `node benchmark/build.js
--check` runs every regex grader on them with Node's regex engine (the same JavaScript dialect the
tool uses): every grader must pass on the correct answer, every "contains" grader must fail on a
generic wrong answer (`graders/generic-wrong.txt`), and each wrong sample must fail at least one
grader. CI runs this check on every change.

### Blind human review

After full collection, a sample of two outputs per task and condition (72) is drawn with a fixed
seed by [`analysis/blind.js`](analysis/blind.js). Each output is renamed to a code from a salted
SHA-256; the key and salt stay outside the repository until every review is recorded, and are then
committed beside the reviews. The judge is Marco Amaral. A second judge is planned (not yet named);
when there is one, their agreement is reported as weighted Cohen's kappa. For each output the judge
rates, from 1 to 4: would I use it as delivered; is everything in it correct for the fixture; does it
cover what the fixture needs. The judge also guesses the condition. Blinding is imperfect and this is
declared: D's outputs carry the package's format, so the guess accuracy is reported next to the
ratings.

## Outcomes and analysis (fixed in advance)

- **Primary outcome: content pass.** A generation passes when every `con-` grader of its task passes.
- **Secondary outcomes**: contract pass (every `fmt-` grader passes); content score (the share of
  `con-` graders passed); each grader's pass rate; judge pass; cost and tokens per generation; the
  files condition D read beyond the expanded command; the human ratings.
- **Per condition**: the pass rate with an exact (Clopper-Pearson) 95% interval.
- **Contrasts**: D vs C, D vs B and D vs A on content pass, as the mean over tasks (equal weight) of
  the difference in pass rate, with a bootstrap interval: runs resampled within each task and
  condition, 10,000 replicates, seed 20261018, at 98.33% (Bonferroni over the three contrasts).
- **Decision rule**: a contrast supports its claim only when the interval's lower bound is above 0
  **and** every task and condition cell in it holds at least 8 generations. Otherwise it is printed
  as "underpowered, no conclusion", whatever its point estimate, or "does not support the claim"
  when it is powered and the interval reaches 0.
- **Script**: [`analysis/analyze.js`](analysis/analyze.js) (Node standard library, deterministic,
  one Markdown table). `--self-test` checks it on synthetic results: exact intervals against
  reference values, the same report from the same input twice, and the decision rule on a large
  difference, no difference, a pilot and one thin cell.
- **Exploratory, labelled as such**: anything else, including differences between tasks, between
  commands and skills, and cost per point of content pass gained.

## Arms

| Arm | Engine | Role | Size |
| --- | --- | --- | --- |
| 1, primary | `claude plugin eval` (Claude Code 2.1.291 or later) in a clean environment per run, path target, `--ablation none`, model `claude-haiku-4-5-20251001` for the agent and the judge; the model string each run reports is recorded per generation | All confirmatory analysis | 9 tasks x 4 conditions x 10 runs = 360 generations |
| 2, ecological | Claude Code CLI (`claude -p`) in a real project folder with the user's own configuration; D loads the plugin with `--plugin-dir`, never by installing it | Does the direction of Arm 1 hold in a real session? Descriptive only, no test | Conditions A and D, tasks 1, 4 and 7, 3 runs each = 18 |
| Extension | The same protocol with another model (a Sonnet-class model first) or another agent (Codex CLI or Gemini CLI with the package's adapter) | Replication; each reported on its own, never pooled with Arm 1 | Conditional on budget |

Arm 1 isolates each run: a temporary home, working directory and configuration, no user settings,
no memory, no other plugins. That is its strength and its limit, and the reason Arm 2 exists. Arm 2's
project folder, invocation and capture are fixed in a dated amendment to this file before its first
run.

## Determinism

There is no seed for the model. The benchmark promises a reproducible process, not reproducible
outputs: frozen prompts and graders; the SHA-256 of the built case tree, recorded in
[`cases.sha256`](cases.sha256) and checked before every collection; the model string per
generation; every raw output committed; and an analysis anyone can re-run on them without calling a
model.

## Known limitations (stated before collection)

- **Regex graders read words, not understanding.** A grader can pass an output that names the right
  thing for the wrong reason, or fail one that says it in other words. The correct samples, the
  pilot's reading of every output, and the human review are the checks on this, not a cure.
- **One model in the primary arm**, and a small one. Named in every report; extension arms are the
  remedy.
- **Arm 1 is not a user's session.** It has no project, no history and no rules files (the plugin
  ships no rules). Arm 2 exists for this.
- **The package's format is visible.** Graders and the human judge can recognise D. The contract
  outcome is labelled as a check, and the judge's condition guesses are reported.
- **Training data.** The package is public and may be in a model's training data; the fixtures and
  the placebo were written for this benchmark.
- **Model drift under a stable name.** Results hold for the model strings recorded, on the dates
  recorded.
- **The benchmark's author is the package's author.** Mitigated by fixing everything here before
  collection, a placebo and a one-sentence control, deterministic graders checked on samples,
  blinding, publishing every output, and the deviations log; not by good faith.

## Cost

Measured in the pilot (one generation per task and condition, `claude-haiku-4-5-20251001`, list
prices as the tool reports them), the mean cost of one generation without the judge was US$0.0246
(A), US$0.0268 (B), US$0.0341 (C) and US$0.0461 (D); the judge added US$0.0086 per judged
generation. D costs more because the expanded command is in its context and its replies are about
twice as long (4,034 output tokens on average, against 1,841 to 2,276).

The full Arm 1 collection (360 generations, 120 of them judged) is therefore estimated at
US$11.84 for the generations plus about US$1.04 for the judge, **about US$13**. A cap of US$16 leaves
room for longer runs. Collection waits for the cap Marco sets; the runbook lowers `--max-cost-usd`
task by task, so a cap that runs out cuts whole tasks, never conditions.

## Pilot disclosure

The pilot proves the harness works end to end. It is not a result, and its numbers answer none of
the claims: one generation per cell is underpowered by design, and the analysis says so.

- **When and how.** 2026-10-18, Claude Code 2.1.291 in a second WSL distribution, `claude plugin
  eval` on the repository as a path target, `--ablation none --runs 1 --model
  claude-haiku-4-5-20251001 --judge-model claude-haiku-4-5-20251001 -j 2`, one invocation per task,
  9 tasks x 4 conditions = 36 generations. Every run reported the model `claude-haiku-4-5-20251001`
  and finished in one turn. No run called Read or Skill: condition D got its command by expansion
  only and read no reference file.
- **Cost.** US$1.288 (generations US$1.184, judge US$0.104), plus US$0.065 for a mechanics check
  before it (three throwaway cases that showed `plugins:` loads the bare, placebo and Bem-te-vi
  plugins as intended), US$1.354 in all, within the US$2.00 allowed.
- **Isolation.** `claude plugin list`, `claude plugin marketplace list` and the SHA-256 of
  `~/.claude/settings.json`, `installed_plugins.json` and `known_marketplaces.json` were the same
  before and after; the kept temporary folders were deleted.
- **Graders corrected after reading every output, before the freeze.** Each correction made a grader
  judge what its text says, not something narrower or wider. They were applied to the pilot's
  outputs with `analysis/extract.js --regrade`, which first reproduced the tool's verdict on every
  unchanged grader; `runs.jsonl` keeps both verdicts (`toolGraders` is the tool's).
  1. `cases-quantity/con-every-ac`: AC-1 also counts when 1 or 20 is accepted (B covered it without
     naming it). `con-technique-named`: boundary value analysis alone (equivalence partitioning is
     no longer required beside it).
  2. `cases-order-status/con-unlisted-invalid-transition`: rewritten. The first version passed D on
     a step list of the valid path (a false pass) and failed A's "Attempt shipping on non-paid order"
     (a false fail). `con-every-ac`: the state change on one line also counts (no verdict changed).
  3. `cases-shipping-fee/con-every-ac`: each AC also counts by what it specifies (A, B and C covered
     all three without naming them).
  4. `defect-gift-card/con-expected-actual`: a typographic minus in "-€20.00" is accepted (C).
     `con-severity-and-priority`: the value may sit on the line after its label (no verdict changed).
  5. `plan-split-payment/con-project-risk`: the word "project" is no longer required (A and C put
     the brief's constraints in their risk tables).
  6. `api-orders-contract/con-undocumented-500`: setting the 500 against the documented 201 and 400
     also counts (A).
  7. `a11y-signup-form`: each `con-find-*` grader accepts the criterion number or the barrier named
     in words (B and C found barriers without citing numbers); citing all six numbers became the new
     contract grader `fmt-criteria-cited`.
  8. `flaky-run-history/con-product-intermittent`: tracing the race to the backend, replication or
     consistency also counts (A and C).
  9. `bdd-loyalty-points/fmt-feature-header`: a Markdown heading marker before `Feature:` is
     accepted (D). `con-vague-ac-flagged`: stating the threshold as an explicit assumption counts
     (B and D).
- **What the pilot showed about the package**, recorded for its maintainers and not used to change
  anything here: under `/bem-te-vi:qa-defect` the model filled Root Cause with the developer's guess
  instead of leaving it `N/A` as the command asks; under `/bem-te-vi:qa-cases` one case's Source read
  "Story requirement (initial state)", which the package's own hook rejects, and no invalid transition
  beyond AC-5 was written; two of the good titles in `/qa-defect`'s title table omit the `when`
  clause its rule asks for, so `fmt-title-form` does not require it. Under the placebo, the
  accessibility audit came back as a help-center article with the placebo's frontmatter: the
  placebo does reach the output, which is what makes it a fair control.
- **Results**: [`results/2026-10-18-pilot/`](results/2026-10-18-pilot/) (`analysis.md`,
  `runs.jsonl`, every output, the tool's redacted JSON).

## Registration

This file is frozen when the pull request that adds it is merged. The public repository's first
commit (plan 020 part B) carries it, and that commit is its public timestamp. **Full collection
happens after that commit, never before.** A registration on OSF as well is optional and an open
decision for Marco. From the freeze on, every departure is an entry in [`DEVIATIONS.md`](DEVIATIONS.md).

## Publication

Each collection's results go to `benchmark/results/<date>/` (pilots: `<date>-pilot/`): the tool's
aggregate JSON per invocation, one Markdown file per generation, `runs.jsonl`, and `analysis.md`,
redacted as plan 037 requires (no account e-mail, no local paths). The README's "Does it work?"
section carries the latest table, its date, model and size, and links here.
