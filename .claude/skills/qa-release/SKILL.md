---
name: qa-release
description: "Evaluates a release candidate against the release gate and exit criteria already defined in the test plan (or the team's own Definition of Done), collects evidence per criterion with the build it came from, and writes a go/no-go record with exceptions, residual risks and defects not fixed, for the stakeholders who decide. Defines no criteria of its own. Use when asked whether a release is ready, for a go/no-go, release sign-off or readiness review; to define the criteria, use the planning skill."
metadata:
  id: qa-release
  author: Marco Amaral
---
# Skill: Release Readiness (Go/No-Go Record)

> **Senior QA Engineer** | ISTQB CTFL v4.0 (§1.1.1, §1.2.1, §5.1.3, §5.3.2, §1.4.4, §5.4) | Evaluates a gate, never defines one

**If a rule is not loaded.** When a rule this file names is not in your context, load the `qa-rules` skill and read that rule in the skill's own `references` folder. If no `qa-rules` skill is installed either, go on without the rule and say at the end of your reply which rule you could not apply.

This skill is activated when the question is "are we ready to ship?". It leaves one file, `release/go-no-go-<version>.md`, that a reader can audit: which criterion, what evidence, from which build, what is still open, who accepted which risk.

**This skill owns no criterion.** The gate and the exit criteria are in the planning skill (`qa-plan`), section Quality Gates; if the team has its own Definition of Done or exit criteria, those are the gate (the `context-discovery` rule: derive, do not override). Never retype a threshold here with a value of your own. If the gate seems to lack a criterion the release needs, say so and propose the change to the gate in `qa-plan`; do not add it to the record.

Testing informs the release decision; it does not take it (CTFL v4.0 §1.2.1, §1.1.1). QA recommends, and the stakeholders named in the plan decide. Ending testing early is acceptable only when they have reviewed and accepted the risk (§5.1.3).

Files named "the `qa-reference` skill's `references/<file>.md`" are in the `qa-reference` skill's folder, not this skill's: load the `qa-reference` skill and read them there.

## Steps

1. **Identify the candidate**: version, build and environment, taken from the deployment record (the `context-discovery` rule), not from a branch name. With no identified build, the answer is NO-GO, "cannot evaluate".
2. **Load the gate**: the team's own criteria if the repo has them, otherwise `qa-plan` Quality Gates (the release gate and the standard exit criteria), by section name.
3. **Collect evidence per criterion**: run results with the build they ran on, open defects by **severity** (defect priority schedules a fix and never gates; see `/qa-defect`), recorded exceptions (who, when, which risk was accepted), residual risks from the risk register, and the gate cases (`@gate` in `/qa-cases`). A criterion with no evidence is "not met: no evidence", never assumed met. A result that names no build is not evidence (§5.4).
4. **Write the record** (below), then state the recommendation and its reason.

## The record: `release/go-no-go-<version>.md`

Every field stays; empty ones read `N/A — <why>` (the `qa-reference` skill's `references/written-records.md`).

| Part | Content |
| --- | --- |
| Candidate | Version, build, environment, date, who decides |
| Criteria | One row per criterion of the loaded gate: criterion, evidence link, build, status (met, not met, exception) |
| Gate cases | One table: ID, what it proves, result. If none are marked, say so |
| Exceptions | Criterion, who accepted it, date, the risk accepted |
| Residual risks | From the register, each traced to the cases that cover it (§1.4.4) |
| Defects not fixed | ID, severity, whether the change caused it |
| Not caused by the change | Listed, never gating (`qa-plan`, release gate) |
| Not run | One row per case not run, blocked or dropped, with the resume point |
| Recommendation | GO, NO-GO, or GO with recorded exceptions, with the reason in one paragraph |

A recommendation of GO needs every criterion met or carrying a recorded exception. A criterion that is not met and has no exception makes it NO-GO. QA does not grant exceptions: it records who did.

Corrections follow the dated-note format in the `qa-reference` skill's `references/written-records.md`; nothing found wrong in a shared record is deleted.

## Not ISTQB content

A rollback plan, staged rollout and feature-flag release are release engineering, not syllabus content. Ask the team whether a rollback plan exists and record the answer in Residual risks; do not design one here (`/qa-refinement` covers rollback planning).
