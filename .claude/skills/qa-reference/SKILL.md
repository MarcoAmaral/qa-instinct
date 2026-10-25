---
name: qa-reference
description: "QA Instinct's on-demand QA reference. Text that names the `qa-reference` skill's `references/<file>.md` means a file in this skill's folder: load this skill, then read it there. Holds the test pyramid, CTFL test levels and types, ISTQB design techniques, coverage items and measures, CI/CD tag filters, Playwright/Vitest assertion examples, the axe-core template, the XSS payload spec and security checklists, evidence capture, Vitest and Playwright project patterns, automation in CI, defect report system info and Azure DevOps filing, test case examples, planning and reporting detail, test tool selection, shift-left, confirmation, regression and maintenance testing, CI preconditions and the broken build, delivery versus deployment, feature flags, canary and A/B validity, commit and lint conventions, and how to record an empty field and a correction. Use when writing or reviewing test automation, an accessibility or security test, test evidence, a tag filter, or when recommending a test tool."
metadata:
  id: qa-reference
  author: Marco Amaral
---
# Skill: QA Reference (Read on Demand)

> **QA Instinct** | Templates, examples and procedures behind the always-on rules

**If a rule is not loaded.** When a rule this file names is not in your context, load the `qa-rules` skill and read that rule in the skill's own `references` folder. If no `qa-rules` skill is installed either (a Claude Code plugin install has neither), go on without the rule and say at the end of your reply which rule you could not apply.

The rules (`testing-guidelines`, `code-style-qa`, `test-evidence` and the others) hold the short must-lists that apply to every conversation. The
detail behind them lives here and costs nothing until it is needed: read the one file the task
calls for, not all of them.

## Contents

| File | Holds | Read it when |
| --- | --- | --- |
| `references/testing-design.md` | Adaptive test pyramid, coverage targets and the measure behind each, mocking matrix, the kinds of test double and what mocking costs, localhost dry runs, the three technique families, ISTQB test design techniques and their coverage items, checklist-based testing, statement and branch coverage, CTFL test levels and test types (§2.2), field heuristics, CI/CD tag-filter syntax | Choosing test levels, test types or techniques, setting or reading a coverage figure, testing on a shared environment, writing a `--grep` or `testNamePattern` filter |
| `references/automation-code.md` | Arrange-Act-Assert and Page Object Model detail, the FIRST properties with a check for each, test smells and assertions per test, Playwright and Vitest assertion examples, atomic commits, pre-push verification, red-green proof, parallel ticket work | Writing or reviewing automation code, committing, or claiming a spec passes or a bug is fixed |
| `references/accessibility-checks.md` | Full WCAG 2.2 AA criteria, the `@axe-core/playwright` audit template, the manual a11y checklist | Writing an accessibility audit or a manual a11y test plan |
| `references/security-checks.md` | Full OWASP client-side verification, the `npm audit` gate, the Playwright XSS payload spec, the manual security checklist | Writing a security test, a payload spec or a security test plan |
| `references/evidence-capture.md` | Viewport screenshots with code, visible pointer and case label, opening recordings, the skipped-test recording trap, pacing, ASCII names, the evidence checker | Writing automation that captures screenshots or video, or handing evidence to a reviewer |
| `references/context-sources.md` | How to read the sources context discovery names: a spec directory, the tracker as the record of what was tested, feature-area knowledge files; the before-you-ask steps; the lint, review, build, verify publishing pipeline | Grounding tests or a review in a spec directory or feature-area notes; deciding what was already tested; before asking anyone a question; publishing a document to a shared platform |
| `references/test-tools.md` | CTFL v4.0 tool categories (§6.1), benefits and risks of test automation (§6.2), how to recommend a tool | Recommending, justifying or introducing a test tool, or proposing to automate manual tests |
| `references/repo-conventions.md` | Full Conventional Commits rules (types, atomic commits, breaking-change notation) and the linting rules (detect and respect the repository's config, no invented style) | Committing on behalf of the user, or writing or editing code in the target repository |
| `references/written-records.md` | The `N/A — <why>` spelling for a field with nothing to put in it, and the one correction format (dated note or strike-through with a reason) | Filling a template field that does not apply, or correcting something in a test case, defect report or plan that has been shared |
| `references/test-case-writing.md` | Each tracker's identifier format and URL pattern, a worked example of each ISTQB technique in test case format (EP, BVA, decision table, state transition, error guessing), the runbook format | Linking a tracker issue in a test case, writing a case's ISTQB Technique row, writing the runbook a test case file points to |
| `references/test-planning.md` | The testing quadrants table (§5.1.7), the four estimation techniques with a worked three-point example (§5.1.4), the three test execution orderings and what overrides them (§5.1.5), the suite-level artifacts, roles and independence of testing (§1.4.5, §1.5.3), the configuration management checklist (§5.4) | Writing a test plan's test approach, estimate, execution order or configuration management, or building a suite-level document |
| `references/test-reporting.md` | Monitoring metrics, control directives, progress and completion reports (§5.3), the row format for reporting every case with its resume point, completion activities, retrospectives (§2.1.6) | Choosing a plan's metrics, recording a control directive, writing a progress, completion or results report, closing a milestone, running a retrospective |
| `references/vitest-patterns.md` | Vitest project tree, `vitest.config.ts`, setup file, unit test pattern, mocking an external SDK, `localStorage` testing, running Vitest | Scaffolding Vitest unit or integration tests |
| `references/playwright-patterns.md` | Playwright project tree, `playwright.config.ts`, auth fixture, Page Objects, E2E spec, running Playwright, `data-testid` naming guide | Scaffolding Playwright end-to-end tests or choosing `data-testid` names |
| `references/automation-ci.md` | Flakiness hunting, the GitLab CI/CD pipeline with a nightly regression job, terminal logging and custom reporters | Debugging a flaky test, wiring tests into a pipeline, or writing console output and reporters |
| `references/defect-system-info.md` | Per-stack commands that collect runtime and dependency versions for a defect report (Node) | Filling a defect report's `SystemInfo` and `FoundIn` for a Node project |
| `references/testing-in-delivery.md` | DevOps and shift-left from the tester's side, confirmation and regression testing, impact analysis, maintenance testing and its triggers, what CI requires before its results count, what to do when the main build breaks, continuous delivery versus continuous deployment, testing behind feature flags, the conditions for canary releases and A/B experiments | Testing a fix or a change, scoping a regression run, testing a system that is changed, migrated or retired, planning the testing in a DevOps pipeline, deciding whether a CI result can be trusted, deciding who or what opens the release gate, testing a change behind a feature flag, or planning a canary release or an A/B experiment |
| `references/tracker-azure-devops.md` | The ADO `SystemInfo` HTML block, the attachment upload script, the bug field mapping and the filing template (Python) | Filing a defect report in Azure DevOps |

## How to use

1. Apply the matching rule first; it says what must hold.
2. Open the reference above for the template, example or procedure, and follow it.
3. When a reference and a rule seem to disagree, the rule wins; report the conflict.

Elsewhere in the package a file here is named "the `qa-reference` skill's `references/<file>.md`":
the `references/` folder beside this `SKILL.md`, wherever the skill is installed, never a path under
the project root. Claude Code gives that folder as this skill's base directory when it loads; every
other editor the package supports installs this skill as a folder in its skills folder, with
`references/` beside `SKILL.md`, so the name is the same in all.
