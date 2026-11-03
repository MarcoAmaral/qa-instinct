# Plan 072: Three practices from Marco's own QA toolbox: a real pointer path, the data behind a result, and results written back once

> **Executor instructions**: Branch `feat/qa-tools-practices` from `main`, one pull request into
> `main`, one commit per item. Carry the practice, never the instance (plan 015): nothing here may
> name a client, product, internal system, host, ticket or account seen in the toolbox, and no
> file from it is copied. Content only: no installer change. `feat:` commits, so Release Please
> proposes a minor version. `npm publish` is **Marco's**.

## Status

- **Priority**: P3. Practice the package lacks; nothing is broken.
- **Effort**: M. Three additions to `qa-reference` references and the commands that point at them.
- **Risk**: LOW. Shipped text; the generators take changed references as they are.
- **Depends on**: plans 015 (practice from daily work), 038 (citation checks), 047 (Agent Skills
  tree)
- **Planned at**: commit `2888edc` (`main`), 2026-11-03

## Why this matters

On 2026-11-03 Marco asked whether QA Instinct has what his `qa-tools` folder in the SWARE
distribution has: a toolbox he wrote and uses to run tests and collect evidence. It was read that
day, except `sessions/` (saved logins, left unopened) and the bundled Playwright library. It holds:

| Part | What it does | In QA Instinct |
| --- | --- | --- |
| A shared Playwright install | One install outside every repository; a ticket folder holds only its config and specs | Partly: `/qa-automate`'s "One Shared Helper Library, Scaffolded Runners" |
| Saved sessions | One login per environment and account | As practice: the same section, and `storageState` in `references/playwright-patterns.md` |
| A pointer recorder | A local page records how a person moves and clicks; a local server saves the trace for the runner | **No** |
| A data query helper | Runs a read-only SQL query through a BI tool's API to check the data behind a result | **No** |
| A results recorder | Writes each case's status, outcome and evidence into the test plan's outcome table and the test-case file from one results file | **No**; `references/test-reporting.md` says what to report, not how the copies stay equal |
| A page verifier | Reads a published page back and compares it with the draft | As practice: "Verify" in `references/context-sources.md` |

Marco chose all three gaps on 2026-11-03. The package runs nothing for the user (`ROADMAP.md`, "Out
of Scope"), so each becomes guidance and code patterns, not a shipped tool.

## Item 1: replay a person's pointer path in evidence

**Where**: `references/evidence-capture.md`, "Make Actions Visible", and the click helper in
`/qa-automate`'s "One Shared Helper Library".

A click helper that jumps straight to the target makes a recording that shows no path, which the
reference already rejects. Moving in a straight line at constant speed is readable but looks
machine-made. The toolbox's answer: record a person once, then reuse the movement's shape.

- **Record once, locally.** A local page records pointer events (`{t, x, y, type}`), and the trace
  stays on the machine. It holds no page content, but it is still someone's behaviour: keep it out
  of the repository unless that person agrees.
- **Replay the shape, not the coordinates.** Take a recorded segment from rest to a click, scale and
  translate it from the pointer's position to the target's centre, and play it with
  `page.mouse.move` in steps at the recorded timing, then click through the helper.
- **Evidence runs only.** The path changes what the recording shows, never what the test does or
  asserts. A run without evidence skips it and stays fast.
- **Fail visibly.** A missing or unreadable trace falls back to a straight path and says so in the
  run log. It never fails the test.

The executor writes the pattern as a TypeScript sample (type-checked by `tests/test-ts-samples.sh`),
not as the toolbox's code.

## Item 2: check the data behind a result

**Where**: a section in `references/test-case-writing.md` (expected results), referenced from
`/qa-cases` and `/qa-automate` where an expected result names stored data.

A screen can say "saved" while the row is wrong. When the expected result is about stored data, the
case says how it is checked: a read-only query whose text, run time and result go in the evidence.

- **Read-only, always.** A reporting or replica connection, or a read-only account. A test that
  writes to check a write checks nothing.
- **Credentials stay outside the repository and the evidence.** Read from a file or variable the
  repository ignores; never printed in a log, a screenshot or a results page (the `security-qa`
  rule's sensitive data).
- **The query is evidence.** Record its text and its result next to the screenshot, so a reviewer
  can rerun it. Mask personal data in what is recorded.
- **Parameterised, and narrow.** Select the one record the case created, by its id, not "the latest
  row", which a parallel run can change.
- **Say when it cannot be checked.** No access is a reason to mark the case blocked on it, not a
  reason to pass on the screen alone.

Cite CTFL only where the syllabus says it (a test oracle, the expected result as part of a test
case), checked against the syllabus text as `tests/test-ctfl-citations.sh` requires.

## Item 3: record a result once, and let every copy follow

**Where**: `references/test-reporting.md`, after "Reporting Every Case", and the "Publishing to a
Shared Platform" gates in `references/context-sources.md`.

A run's results usually live in three places: the test-case file (each case's status and evidence),
the test plan's outcome table, and the published page. Updated by hand, they disagree within a day.

- **One results file is the source.** Each run writes one record per case: id, status, outcome,
  where and when it was checked, evidence, and for a pending or blocked case what it waits for.
- **Every copy is updated from it, never by hand.** A small script, or the assistant following the
  same steps, writes the status and evidence into each copy and fails loudly when it cannot find a
  case exactly once (a renamed case, a duplicate row).
- **Then publish through the four gates.** The published page is built from the updated draft and
  read back ("Verify"), so the record, the draft and the page agree.

## Steps

1. Items 1-3 as above, one commit each, with the commands' pointers and the `qa-reference` skill's
   table row updated for each changed reference.
2. `./generate-adapters.sh`; `npm test`, `npm run lint`, markdownlint, `tests/verify-adapters.sh`,
   `tests/test-reference-links.sh`, `tests/test-skill-bodies.sh`, `tests/test-ts-samples.sh`.
3. Optional: a behavioural eval for item 2 (a case whose screen says saved and whose row is wrong),
   in the `claude plugin eval` layout of plan 037, run by Marco on SWARE with exact model strings and
   `--keep-temp` (plan 068's note on what that run lacked).

## Rejected approaches

- **Ship the toolbox's scripts.** They name one client's systems, read saved logins and write to
  one ticket's paths, and the package runs nothing for the user.
- **A shared Playwright install as a fourth item.** `/qa-automate` already covers the library and
  scaffolded runners; one install across repositories is a machine set-up choice, not a practice
  the package should impose.
- **A new reference file per item.** Each extends a reference that already holds its neighbours;
  three new files would split guidance a reader needs together.

## Findings outside scope

- **The query helper writes its request to a session scratch folder under `/tmp`.** That folder is
  gone after a restart, as the MarcoWork backup was on 2026-10-31, so the helper fails until the
  folder exists again. A `mktemp` file avoids it. Marco's toolbox, not this repository: reported to
  him, not changed.
