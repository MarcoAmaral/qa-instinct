---
id: qa-trace
description: "Builds a requirement to test case to result traceability report. Reads a /qa-agentic ticket folder, a spec directory or a pasted ticket, links each requirement to its test cases (marking every link traced or inferred) and their last results, and lists the gaps with a coverage figure. Read-only by default."
argument-hint: "<ticket folder, spec directory or pasted ticket> [results file] [--write]"
---
# QA — Traceability (Requirement → Test Case → Result)

> **Senior QA Engineer** | ISTQB CTFL v4.0 (syllabus v4.0.1) — §1.4.4 | Read-only by default
> Respond in the language of the user's prompt (default: English)

**If a rule is not loaded.** When a rule this file names is not in your context, load the `qa-rules` skill and read that rule in the skill's own `references` folder. If no `qa-rules` skill is installed either, go on without the rule and say at the end of your reply which rule you could not apply.

You build a **traceability report**: for every requirement, which test cases cover it, how each link is known, and what the last result was. Traceability between the test basis, test cases, test results and defects supports coverage evaluation, shows the impact of a change, facilitates audits and makes progress and completion reports understandable (CTFL v4.0 §1.4.4). A requirement with no test is a gap in test-basis coverage, one of the defects static testing finds cheaply (§3.1.3).

This command **reports**. It does not design tests (`/qa-cases`, `/qa-bdd`), review the requirements themselves (`/qa-static`) or fix links.

---

## 🔍 Step 0 — Context Discovery (mandatory)

Apply the `context-discovery` rule before reading anything else. Two of its sources matter most here, both described in the `qa-reference` skill's `references/context-sources.md`: a spec directory, and the tracker as the record of what was tested.

---

## 📋 Step 1 — Requirements

Read the **first** of these that exists. Degrade; never require one.

1. **The `/qa-agentic` ticket folder's `requirements.md`** — the path the user gave, or the folder found as "The Ticket Folder" in `/qa-agentic` describes. Item *n* of its numbered list is `REQ-n`: the ID `qa-writer` carries into each test case's **Note**.
2. **A spec directory such as `.specify/`** — the specification's identified requirements and acceptance scenarios. Keep the identifiers it uses (`FR-001`, `SC-002`).
3. **A pasted ticket** — use any stable identifier it carries (`AC-2`). If it has none, assign `R-001`, `R-002`, … in order of appearance and **say the IDs were invented** by this run.

Name the source in the report. If two sources exist and disagree (for example the spec and `requirements.md`), report the disagreement; do not pick one silently.

---

## 🔗 Step 2 — Test Cases and Links

Read the test cases in the ticket folder (`testcases.md`) and any `TC-*.md` files the user names, using the test case layout from `/qa-cases`: one `## TC-CODE-NNN:` section per case and one table row per field. Read automated specs only when the user points at them or a test case file names one in its `spec:` frontmatter.

Every link has exactly one **link basis**:

| Link basis | When |
| :--- | :--- |
| **traced** | An explicit record links them: the **Note** row says `Traces to REQ-n` (or the requirement's own ID); the **Source** row names an acceptance criterion (`AC-n`) that the requirement source labels the same way, or the requirement's own ID; the **Issue** row names the requirement's own tracker item; or the requirement ID appears in an automated test's title or tag |
| **inferred** | Anything else — for example the case and the requirement describe the same behaviour in similar words. Name the words that matched |

- An **Issue** row naming only the ticket proves that the case belongs to the ticket, not which requirement it covers. It is not a trace.
- `Added by QA (…)` in the **Source** row is not a link to a requirement: such a case counts as a case with no requirement unless its Note traces it.
- **Never report an inferred link as traced.** Do not invent a link to close a gap: when a match is weak, leave the requirement uncovered and mention the candidate case in the gap's detail.
- Take **Technique** from the case's **ISTQB Technique** row and **Automation** from its tag: `@automated`, `@candidate` or `@manual-only`.

---

## ▶️ Step 3 — Results

Use only a results source the user points at or the ticket folder holds: a runner report, `runbook.md` (`run-sheet.md` in older folders), pasted runner output, or test-run records in the tracker. Match a result to a case by the case ID in the test's title.

Write the result as `pass`, `fail`, `blocked`, `not run`, `verified by a developer` or `dropped` (the outcomes `/qa-cases` and `qa-plan` use). A case with no result is **`not run`**, never `pass`. When the source is older than the test case or you cannot tell, say so under the report's sources.

---

## 📤 Step 4 — The Report

Same inputs must give the same report, so the ordering is fixed:

- **Coverage**: one row per requirement and test case pair, requirements in source order, then case IDs ascending. A requirement with no test gets one row of dashes.
- **Gaps**: kinds in this order — `No test`, `Inferred only`, `No passing test` (each per requirement, in requirement order), then `No requirement` (per test case, in case ID order). IDs run `TR-001`, `TR-002`, … in table order, so a re-run on unchanged inputs produces the same IDs.
- **Metrics**: the lines below, computed from the Coverage table.

```markdown
# Traceability: <feature or ticket title>

- Requirements: <source>, <first ID> to <last ID> (<numbered by the pipeline | from the spec | invented by this run>)
- Test cases: <source>, <N> cases
- Results: <source, or "none — every case is not run">
- Written: <nothing (read-only run) | path of traceability.md>

## Coverage

| Requirement | Test case | Technique | Automation | Link basis | Last result |
| --- | --- | --- | --- | --- | --- |

## Gaps

| ID | Kind | Item | Detail |
| --- | --- | --- | --- |

## Metrics

- Requirements: <N>
- With at least one test (traced or inferred): <n> of <N> (<p>%)
- With at least one traced test: <n> of <N> (<p>%)
- With at least one passing test: <n> of <N> (<p>%)
- Test cases: <N>; with no requirement: <n>

Coverage counts requirements that have a test. It is not evidence that the tests are adequate:
testing shows the presence of defects, not their absence.
```

Percentages are rounded down to whole numbers. The coverage figure is never a verdict on quality (§1.3, principle 1). A requirement whose test passes but does not deliver the expected outcome is still a finding; when you notice one, say so in the gap detail or under the report.

`tests/fixtures/qa-trace/password-reset/` in this package's repository holds a worked example: a ticket folder and the report this command must produce from it.

---

## 💾 Writing

- **Default: write nothing.** The report goes in the reply.
- **With `--write`**, or when the user explicitly asks, write it as `traceability.md` in the ticket folder. If that file exists, show what would change and ask before replacing it.
- Never modify requirements, test cases or results. A gap is closed by the people who own those files.

## 👤 Who Decides

The report proposes; people decide. Do not mark a gap resolved or an inferred link confirmed yourself: the test case's author confirms a link by adding `Traces to REQ-n` to its **Note** (`/qa-cases` can do it on request), and the requirement's owner decides whether a `No requirement` case reveals a missing requirement or an unneeded test.

---

## 📚 Syllabus Map

Sections of ISTQB CTFL v4.0 (document v4.0.1) used above: §1.3 testing principles (principle 1); §1.4.4 traceability between the test basis and testware; §3.1.3 gaps in test-basis coverage as a defect type.
