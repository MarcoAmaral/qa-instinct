# The placebo (condition C): how it was built

Condition C exists to answer one objection: "any long, well-organised document loaded the same way
would have done as much". It can answer it only if it matches what condition D loads in everything
except its subject. This file records how the matching was done, so anyone can audit the placebo
or rebuild it. It sits outside `control-standard/` on purpose: the placebo plugin is what the model
loads, and these notes must never be part of it.

The approach is borrowed from the A11Y.md efficacy benchmark (`METHODOLOGY.md`, "Credit"); the
placebo and these notes were written for this package.

## What it is

`control-standard/` is a Claude Code plugin named `writing-guide` with one command,
`commands/help-articles.md`: a guide to writing end-user help-center articles (how-to, concept,
troubleshooting and reference pages). Condition C's preamble invokes it as
`/writing-guide:help-articles`, exactly as condition D invokes `/qa-instinct:<command>`.

## Construction rules

1. **Same delivery.** The placebo is a plugin command, expanded by Claude Code from a namespaced
   slash command at the start of the message, which is how D's content arrives. A document pasted
   into the prompt would arrive as user text and the comparison would partly measure delivery.
2. **Same shape.** The file mirrors a QA Instinct command section for section: frontmatter with `id`,
   `description` (with a "Use when asked ..." clause) and `argument-hint`; a role banner; a "fill
   every field" rule; a corrections rule; a file format with YAML frontmatter; a type table; an
   individual-item template; title rules with weak and strong examples; numbered writing rules; a
   readability table; two complete worked examples; and a numbered "how to respond" list.
3. **Same size.** Parity is measured against the mean size of the file D loads over the nine tasks
   (16,104 bytes at planning time; `build.js --check` recomputes it on every run and fails outside
   75% to 125%). The placebo is 15,493 bytes, 96.2% of that mean. See "Known asymmetries" for the
   per-task spread.
4. **Silent on testing.** The placebo contains none of the words in `build.js`'s `BANNED` list
   (whole word, any case): the vocabulary of testing and of each task (test, quality, acceptance,
   criteria, defect, bug, failure, severity, priority, risk, boundary, partition, transition,
   scenario, coverage, flaky, quarantine, accessibility, WCAG, contract, schema, expected, verify,
   validation, checklist, review, error, regression, gate, story, requirement, audit and more), and
   no `AC-`, `TC-`, `DR-` or `§`. `build.js --check` runs this sweep every time and fails on any hit.
   Being silent matters more than being opposed: a placebo that discouraged testing practice would
   teach something too.
5. **Real content.** The guidance is sound practice for its own subject. A placebo of plausible
   nonsense could be recognised as such and would measure "good guide against bad guide".
6. **A neutral name.** The plugin and command names describe the subject (`writing-guide`,
   `help-articles`). The model is never told the document is a control; a name such as "placebo"
   would tell it.

## Known asymmetries (declared, not removed)

- **One placebo for nine tasks.** D loads a different file per task (5,998 to 25,916 bytes); C loads
  the same 15,493 bytes every time. Per task, the placebo is 60% of `qa-plan` (task 5), 72% of
  `qa-cases` (tasks 1 to 3), 93% of `qa-defect` (task 4), 122% of `qa-bdd` (task 9), 149% of
  `qa-api` (task 6), 175% of `qa-a11y` (task 7) and 258% of `qa-flaky` (task 8). Matching each task
  would need seven placebos; the mean is matched instead, and the per-task size is recorded so a
  reader can look for a size effect across tasks.
- **No on-demand files.** Some QA Instinct commands and skills point the model at reference files in
  `qa-reference/references/`, which it may read with the Read tool. The placebo has nothing to load
  on demand. `runs.jsonl` records every file a run read, so the extra loading in D is visible.
- **Shared generic words.** A how-to article has numbered steps and a "before you start" list, which
  resemble a test case's Steps and Precondition. This can only help condition C on format, which
  makes the D vs C contrast harder for D, not easier.
- **Training data.** QA Instinct's public repository may be in a model's training data; the placebo was
  written for this benchmark and cannot be. If this matters, it favours D, and it is listed in
  METHODOLOGY.md's limitations.
- **The task does not fit the guide.** The placebo is about another kind of writing, so the model may
  set it aside. That is the point of a placebo, and the reason C is compared with D rather than
  with A: if loading any guide of this size changed the output, C would differ from A as well.

## Maintenance

The placebo is frozen with the protocol. If a command or skill under test changes size enough to
move the mean outside the 75% to 125% band, `build.js --check` fails; the placebo is then rebuilt
with more real content on its subject (never padding) **before** the next collection, and the change
is a dated entry in DEVIATIONS.md. It is never changed during a collection.
