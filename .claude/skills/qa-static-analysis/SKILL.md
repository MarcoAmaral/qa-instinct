---
name: qa-static-analysis
description: "Triages what a static analysis tool reports (SARIF, ESLint, Semgrep, CodeQL, tsc, npm audit or pasted output): reads the code behind each finding, folds duplicates, gives each a verdict (true positive, false positive, not reachable, needs a person), a severity by product risk and an action (fix, suppress with a reason, baseline, change the rule), and sets a CI gate on new findings only. Use when asked to triage, review or prioritise linter, scanner or static analysis findings, or to add such a tool to CI."
metadata:
  id: qa-static-analysis
  author: Marco Amaral
---
# Skill: Static Analysis Triage (verdict, severity, action, gate)

> **Senior QA Engineer** | ISTQB CTFL v4.0 (§3.1, §2.1.5, §5.2.1, §5.5, §6.1, §6.2) | A report is a list of suspects, not a list of defects

**If a rule is not loaded.** When a rule this file names is not in your context, load the `qa-rules` skill and read that rule in the skill's own `references` folder. If no `qa-rules` skill is installed either, go on without the rule and say at the end of your reply which rule you could not apply.

Static analysis is static testing done by a tool: it examines code without executing it (CTFL v4.0 §3.1) and finds some defect types more cheaply than dynamic testing, such as security vulnerabilities, unreachable code and deviations from coding standards (§3.1.3). Running it in CI is shift left (§2.1.5). What it returns is anomalies: each may turn out to be a real defect or something else, such as a false positive (§5.5).

The failure this skill prevents is **the ignored report**: a first run returns hundreds of findings, the team gates CI on all of them, the build stays red, and the tool is switched off, taking its real findings with it.

Files named "the `qa-reference` skill's `references/<file>.md`" are in the `qa-reference` skill's folder, not this skill's: load the `qa-reference` skill and read them there. `references/tool-formats.md` (no skill named) is in this skill's folder.

## Rules and references this skill reuses

- The `linting-standards` rule: the project's lint and scanner configuration is the team's; propose a change, never make it unasked.
- The `security-qa` rule for what counts as a vulnerability on the client side; the `qa-reference` skill's `references/security-checks.md` for the checks behind it.
- The `qa-reference` skill's `references/test-tools.md` for **choosing** a tool; this skill starts once a report exists.
- `/qa-defect` for a true positive that can fail in use.
- This skill's `references/tool-formats.md`: where each format keeps the rule, location, level and baseline state, and each tool's suppression and baseline syntax.

**Not ISTQB content:** SARIF, baselines, suppression comments and new-findings gates are not in the syllabus; do not cite it for them. It supports the frame: static analysis is static testing (§3.1), its tools are a category of test tool (§6.1), anomalies need classifying (§5.5), severity follows risk likelihood and impact (§5.2.1), and over-reliance on a tool is a listed risk (§6.2).

## Step 1: Read the report, then the code

1. Identify the tool, its version and the format (`references/tool-formats.md`). Record the finding count per rule and per level.
2. **Fold duplicates**: one location reported by two rules, or by two tools, is one finding. Triage it once and name every rule.
3. **Read the code at each location** before judging it, and the code that feeds it: where the value comes from, what checks it on the way. A verdict from the rule's message alone is a guess; when the code is not available, say so and mark the verdict an assumption.
4. Note the context of each file: test code, generated code (a "generated, do not edit" header), vendored code, dead code, production path.

## Step 2: Verdict

One verdict per finding, with the reason read from the code:

| Verdict | Means | Typical evidence |
| --- | --- | --- |
| **True positive** | The code has the defect the rule describes | Untrusted input reaches the sink unchecked |
| **False positive** | The rule fires, but the defect is not there | The value is validated, typed or constant before it is used |
| **Not reachable** | Real in principle, but cannot affect the product | Test-only helper, unused function, dev-only dependency |
| **Needs a person** | The code available cannot decide it | The input's origin is outside the repository; say what would decide it |

Never call a finding a false positive because fixing it is inconvenient. A "Not reachable" finding gets a low priority and is fixed in the normal cycle; it moves up only when the code can reach something shared, such as a test that runs against a shared environment.

## Step 3: Severity by product risk

Rate each true positive by likelihood and impact in this product (§5.2.1), not by the tool's level: a tool's `error` on an internal script can be low, a `warning` on the payment path high. When your severity differs from the tool's, show both and why. False positives and baseline findings get no severity.

## Step 4: Action

| Action | When | How |
| --- | --- | --- |
| **Fix** | True positive | The fix the rule's defect needs (a parameterized query, not escaping); a `/qa-defect` report when it can fail in use |
| **Suppress** | False positive on one line | Inline, in the tool's syntax, naming the rule and the reason (`references/tool-formats.md`); never a blanket file or rule disable |
| **Baseline** | A true positive the team accepts as known debt for now | Recorded in the baseline with an owner; it leaves the gate, not the backlog |
| **Change the rule** | The rule is wrong for a whole area, such as generated or vendored code | Exclude the path or tune the rule in the configuration; propose it, the team decides (the `linting-standards` rule) |

Generated code is never edited by hand: the next generation overwrites the edit. Exclude the folder, or fix the generator's template.

## Step 5: The CI gate

- **Fail on new findings only.** The first run becomes the baseline; CI compares each run with it and fails when a finding is added. The baseline shrinks as debt is paid; it never grows silently.
- How each tool does this is in `references/tool-formats.md` ("Baseline and gate").
- A suppression or a baseline entry without a reason fails review, like code without a test.
- A green gate means no **new** finding of the rules configured. It is not evidence of security or quality (§1.3, principle 1; the `test-tools` rule).

## Step 6: Report

1. The triage table: rule(s), location, verdict, severity (yours and the tool's), action, reason. Duplicates as one row.
2. The counts: findings reported, after folding, per verdict.
3. The gate to configure, and the baseline it starts from.
4. Defects to report through `/qa-defect`.
5. **Patterns go to the process**, not only to the fix (§1.2.2): the same rule firing across many files means a missing helper, review checklist item or training, not a backlog of single fixes.

## Output discipline

- Say what was read (the report, the code at each location) and what was not. A verdict on code not read is an assumption and says so.
- Count from the report; never estimate how many findings there are.
- Never present the tool's level as a severity without saying it is the tool's.
- Never run, install or configure a tool for the user; give the command that produces the report, if asked.
