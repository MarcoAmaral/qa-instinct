# Deviations from the methodology

Every departure from `METHODOLOGY.md` after it is frozen is a dated entry here: what the
methodology says, what was done instead, and why. Entries are added, never edited away; a
correction to an entry is a new entry that names it. Newest first.

The pilot ran before the freeze, on the version it disclosed; what it changed is in
`METHODOLOGY.md`, "Pilot disclosure", not here.

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
