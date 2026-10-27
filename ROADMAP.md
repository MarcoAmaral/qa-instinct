# QA Instinct Roadmap

One page for newcomers: what the package ships, what comes next, what it will not do, and how to
suggest something. It is written by hand from [`plans/README.md`](plans/README.md), last on
2026-10-26. The detailed record lives in [`plans/`](plans/): every numbered plan, why it was
needed, the pull requests that carried it, and the approaches that were rejected and why. Where
this page and `plans/README.md` disagree, the plans index is right.

## What 4.3.0 Ships

4.1.0 was the first public release. Versions up to 4.0.1 were developed in a private repository;
[`CHANGELOG.md`](CHANGELOG.md) keeps their history. Since 4.1.0:

- **The name QA Instinct** (4.2.0, plan 065): npm package and command `qa-instinct`, repository
  `MarcoAmaral/qa-instinct`.
- **One Senior QA Engineer persona** (4.3.0): commands and skills speak as a Senior QA Engineer;
  `/qa` keeps the analysis and engineering split as two kinds of work.
- **`qa-instinct` names for the installers' own files** (4.3.0, plan 066): `.qa-instinct-manifest`
  and `.qa-instinct-backup-*`. The next run of any installer moves a 4.x `.qa-skills-manifest`
  to the new name, keeping every entry.

And from 4.1.0:

- **The `/qa` router and ten commands** for test cases, defect reports, BDD, automation, TDD,
  refinement, code review, static review of requirements, traceability and the multi-agent
  test-design pipeline (`/qa-agentic`, with its groomer, designer and writer agents).
- **Eight skills**: test planning, exploratory testing, migration from Cypress or Selenium to
  Playwright, and the reference library, plus four new in 4.1.0: API and contract testing
  (`qa-api`), flaky tests (`qa-flaky`), go/no-go records against your own release gate
  (`qa-release`) and accessibility audits against WCAG 2.2 AA (`qa-a11y`).
- **ISTQB CTFL v4.0.1 grounding**: test levels and types, coverage items for every black-box
  technique, statement and branch coverage, checklist-based testing, confirmation, regression and
  maintenance testing, prioritisation, roles and independence. Every syllabus claim cites its
  section, and CI keeps it that way.
- **Engineering practice** from *Engenharia de Software Moderna*: the FIRST properties, test
  smells, test doubles and what mocking costs, characterization tests, CI preconditions, delivery
  versus deployment, feature flags, canary and A/B validity.
- **Three installers that agree and never destroy your files**: the npm CLI, `install.sh` and
  `install.ps1`, held to one conformance suite of 70 cases on Linux, macOS (bash 3.2) and Windows
  (PowerShell 5.1), with the fixes from the pre-launch code audit (plans 044, 045 and 046).
- **Six editors from one source**: Claude Code, Cursor, Windsurf, GitHub Copilot, Cline and
  Antigravity. Outside Claude Code the rules are small always-on rule files and every command,
  skill and agent is an Agent Skill, installed where each editor documents them (plan 047). An
  update moves an install made by an earlier version to these locations. A global install reaches
  Copilot (`~/.copilot/skills/`), Cline (`~/.cline/rules/`, `~/.cline/skills/`) and the Antigravity
  CLI (`~/.gemini/antigravity-cli/skills/`) too (plan 058). Every Agent Skill body is
  under the format's recommended 5,000 tokens; the longer detail is read on demand (plan 056).
- **Installers that report what happened**: a run that skipped every destination says nothing was
  installed, a file that cannot be read is skipped and reported instead of stopping the run, and a
  WSL install reports a Windows home it cannot resolve (plans 053 and 057). An install from WSL
  into the Windows user profile says that its pre-commit hook is not active for Windows-side git
  and that `install.ps1` sets it up there (plan 014, A3).
- **A CLI help that is true**: `qa-instinct --help` lists each command with only the options it
  accepts, and the package requires Node 24, the latest LTS (#197).
- **Corrected `/qa-defect` and `/qa-cases`**: Root Cause stays "not yet analysed" until analysis
  finds it, with a separate field for suspicions; every good title states its condition; and
  `/qa-cases` says how to cite a requirement stated outside the numbered acceptance criteria (#198).
- **References that open in every install**: text names a reference as "the `qa-reference`
  skill's `references/<file>.md`", checked in a Claude Code project install and through the plugin
  (plan 057).
- **Two claims checked at the source**: Copilot reads the whole instructions file (GitHub removed
  its 4,000-character limit for code review on 2026-06-12), and `npx skills add` finds exactly the
  eight skills (plan 054).
- **TypeScript samples that compile**: CI type-checks every sample; the ten partial ones are marked
  with the reason (plan 055).

In the repository but not in the npm package: a re-recordable demo near the top of the README
(plan 049), the contributor guide, issue forms and `llms.txt` (plan 050), and the efficacy
benchmark with its pilot (plan 048). For contributors, the generators now refuse a source tree
with a missing or shared skill name (plan 054), and CI checks the command tables against the files,
the `/qa-agentic` agents' contract, and lint and formatting (plan 055).

The [README](README.md) explains each part, and `CHANGELOG.md` lists every change.

## Planned Next

- **Plan 048, benchmark collection.** The harness and a pilot of one run per task and condition are
  in `benchmark/` (#186, #191). Next is the full collection, ten runs per cell, so that what the
  package claims to improve rests on measurements rather than on a pilot that supports no
  conclusion.
- **Each editor checked by hand.** The non-Claude layouts follow each editor's own documentation;
  none has yet been observed in the editor itself (plan 047, "Findings outside scope").
- **Plugin installs without rules.** Claude Code plugins cannot ship rules, so a plugin install has
  the commands and skills but not the rules they assume. Since plan 060 each command, skill and
  agent that names a rule says in its reply which rule it could not apply; closing the gap itself
  is still open.

The plugin without rules waits on a decision by the maintainer before any work starts.

Deferred until someone needs them (decided by Marco, 2026-10-20):

- A project QA-principles file the commands check their output against (plan 024, C4b).
- A checklist form of `/qa-static`'s findings (plan 024, N2).

A declared gap, with no work planned (decided by Marco, 2026-10-20): **tool-based static
analysis**, the one CTFL v4.0.1 topic the README lists as not yet covered (§3.1, §6.1). The package
names static analysis tools but does not teach running one or triaging its findings.

## Out of Scope

- **Each editor's native subagents.** The four agents ship as Agent Skills in every editor, not as
  Claude Code subagents copied into each editor's own format (decided by Marco, 2026-10-20; plan
  003, maintenance notes; plan 047, D6).
- **Running anything for you.** The package is text your assistant reads, plus an installer. No
  service, no telemetry, no API key, and the CLI makes no network requests.
- **Instructions for one model or vendor.** Shipped content must work in every supported editor;
  editor-specific detail lives in the installers and the generator.
- **A copy or summary of the syllabus, or exam preparation.** The package cites CTFL sections and
  teaches the practice in its own words.
- **Skills added for the count.** A new skill needs a QA task the existing ones miss and evidence
  that people need it.

## How to Propose Something

- **A new skill or command**: open a [proposal](https://github.com/MarcoAmaral/qa-instinct/issues/new?template=proposal.yml)
  before writing it.
- **Something wrong in what the package teaches**: the [CTFL claim](https://github.com/MarcoAmaral/qa-instinct/issues/new?template=ctfl-claim.yml)
  form.
- **What happened when you used it**: a [field report](https://github.com/MarcoAmaral/qa-instinct/issues/new?template=field-report.yml).
- **A question or an early idea**: [Discussions](https://github.com/MarcoAmaral/qa-instinct/discussions).

Larger work becomes a numbered plan in `plans/` before any code. [`CONTRIBUTING.md`](CONTRIBUTING.md)
has the evidence a change needs and the steps from fork to pull request.
