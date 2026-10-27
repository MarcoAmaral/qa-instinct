---
name: qa-a11y
description: "Runs an accessibility audit against WCAG 2.2 AA: scopes pages and states, runs axe-core with Playwright and triages every result group (violations, incomplete, passes, inapplicable), does the manual checks a scanner cannot decide, and reports findings by WCAG criterion with evidence and what the audit can and cannot claim. Use when asked for an accessibility or WCAG audit, an a11y review of a page or flow, or whether a UI is accessible."
metadata:
  id: qa-a11y
  author: Marco Amaral
---
# Skill: Accessibility Audit (WCAG 2.2 AA)

> **Senior QA Engineer** | ISTQB CTFL v4.0 (§2.2.1, §2.2.2, §4.4.3, §5.1.7, §6.2, §5.5) | One living file: `a11y/audit.md`

**If a rule is not loaded.** When a rule this file names is not in your context, load the `qa-rules` skill and read that rule in the skill's own `references` folder. If no `qa-rules` skill is installed either, go on without the rule and say at the end of your reply which rule you could not apply.

The criteria are the `accessibility-qa` rule and the `qa-reference` skill's `references/accessibility-checks.md`; this skill runs the audit and restates neither. It is a multi-session workflow: each step writes to `a11y/audit.md`, so work resumes from disk.

The failure it prevents is **"axe is green, so it is accessible"**. A scanner decides only part of the criteria, and it reports what it could not decide as `incomplete`, which a test that asserts `violations` alone never reads.

Files named "the `qa-reference` skill's `references/<file>.md`" are in the `qa-reference` skill's folder, not this skill's: load the `qa-reference` skill and read them there.

## What the syllabus does and does not support

Accessibility is audited here as part of the usability quality characteristic of non-functional testing (CTFL v4.0 §2.2.2), on the deployed system in a representative environment (§2.2.1). Splitting the work into scanner and manual checks follows §4.4.3 (a checklist holds only what cannot be checked automatically) and §5.1.7 (usability is often manual, other non-functional tests often automated). Over-trusting the scanner is a risk §6.2 lists. A finding is a defect report (§5.5). The syllabus does not mention WCAG, accessibility or axe-core: do not cite it for them. WCAG 2.2 (W3C Recommendation, `https://www.w3.org/TR/WCAG22/`) is the standard; name that version.

## Rules this skill reuses (read them; do not restate them here)

- The `accessibility-qa` rule and the `qa-reference` skill's `references/accessibility-checks.md`: the criteria, the axe-core template (it attaches `incomplete`), the manual checklist.
- The `test-evidence` rule: every screenshot kept is a 1440 x 900 viewport with pointer and case label, ASCII file name. Run `check-test-evidence.sh <spec-dir>` on the audit specs (a Claude Code install puts it in `.claude/hooks/`; when it is not installed, apply its checks by reading the specs and say the checker was not run). Open every recording before keeping it.
- The `code-style-qa` rule: role locators first, web-first assertions, no hard sleeps.
- `/qa-defect` for severity and the defect report format.
- The `context-discovery` rule: find the real pages, states and routes; invent none.

## The five steps

### 1. Scope

Record at the top of `a11y/audit.md`:

- **Target**: WCAG 2.2 AA unless the team states otherwise. A different level is a decision for the team, not for this skill.
- **Blocking threshold**: ask the team which impact levels block a release (for example critical and serious only) and record the answer. Do not pick one for them.
- **Pages x states**: each page in each state it can be in: default, empty, loading, validation error, success, modal open, and focus on each form control. One row per pair; a pair not audited is listed as not audited.
- **Viewports**: the evidence rule's fixed viewport, plus one narrow viewport, plus 200% zoom (1.4.4).
- **Versions**: the build or date seen, `@axe-core/playwright` and the axe-core it bundles, the browser.

### 2. Automated scan

Per page and state, run the audit template from `accessibility-checks.md` and **keep the raw results** (the JSON, one file per page and state). Triage **all four groups**:

| Group | Meaning | What the audit does with it |
| --- | --- | --- |
| `violations` | axe decided the rule failed | Every item becomes a finding (step 4) |
| `incomplete` | axe could not decide | A manual check to do. Never a pass, never ignored: each item gets a verdict or "not checked" |
| `passes` | axe decided the rule held | Recorded as "automated pass" for that rule on that element. Never written as "conformant" |
| `inapplicable` | The rule found nothing to test | Listed, so a reader sees what the page never exercised (no video means no caption rules ran) |

State the tag list used. A scan with the wrong tags silently drops the 2.1 and 2.2 rules.

### 3. Manual checks

Do by hand only what the scanner cannot decide. The mapping below says which criteria need a person. It names criteria by number and name only; the wording is in `accessibility-checks.md`. "Partly" means a rule exists but covers a slice; take its `incomplete` items into the manual column. Rule coverage depends on the axe-core version, so confirm in the raw results which rule IDs ran before relying on a row.

| Criterion | Means | The question for a person |
| --- | --- | --- |
| 1.1.1 Non-text Content | Partly | Does each `alt` say what the image is for, or is it a file name? |
| 1.4.3 Contrast (Minimum) | Partly | For each `incomplete` contrast item (background image, gradient, overlap), what are the measured colours? |
| 1.4.4 Resize Text | Partly | At 200% zoom is any text or control clipped, overlapped or lost? |
| 1.4.11 Non-text Contrast | Manual | Do borders, focus rings and state indicators reach 3:1 against what is next to them? |
| 2.1.1 Keyboard | Manual | Can the whole task be finished with the keyboard alone, without a pointer? |
| 2.1.2 No Keyboard Trap | Manual | Can focus always leave every widget and modal? Does `Escape` close a modal? |
| 2.4.3 Focus Order | Partly | Does focus move in a reading order that matches the meaning? (axe flags `tabindex` above 0 only) |
| 2.4.7 Focus Visible | Manual | Is the focused element visible at every step, in both themes? |
| 2.4.11 Focus Not Obscured (Minimum) | Manual | Is a focused element ever fully hidden by a sticky header, banner or widget? |
| 2.5.7 Dragging Movements | Manual | Is there a single-pointer way to do everything that needs dragging? |
| 2.5.8 Target Size (Minimum) | Partly | Is every pointer target 24 x 24 CSS px or spaced out? Check the rule's `incomplete` items |
| 3.1.1 Language of Page | Automated | None, unless the page mixes languages |
| 3.2.1 On Focus, 3.2.2 On Input | Manual | Does focusing or changing a control ever change context unannounced? |
| 3.2.6 Consistent Help | Manual | Is help in the same place on every page that offers it? |
| 3.3.1 Error Identification, 3.3.3 Error Suggestion | Partly | Is each error in text, tied to its field, and announced? What does it suggest? |
| 3.3.7 Redundant Entry | Manual | Is anything the user already entered asked for again in the same process? |
| 3.3.8 Accessible Authentication (Minimum) | Manual | Can the user sign in without recalling or transcribing, and may they paste and use a password manager? |
| 4.1.2 Name, Role, Value | Partly | Do custom controls expose a name, role and updated state when they change? |

Add the four checks of the manual checklist in `accessibility-checks.md` (tab test, modal trap, colour-blindness simulation, screen reader). A screen reader pass is a person with a screen reader; screen-reader automation is out of scope. If none was run, say "not checked".

Each manual check gets a verdict (pass, fail, not checked), the page and state, and evidence. 4.1.1 Parsing is obsolete in WCAG 2.2: do not report or test it.

### 4. Findings

One row per finding, in `a11y/audit.md`:

| Field | Holds |
| --- | --- |
| ID | `A11Y-<PAGE>-NNN` |
| Criterion | WCAG number and name |
| Page and state | From the scope table |
| Element | A locator a developer can find, not a screenshot coordinate |
| Observed / expected | Both, in one line each |
| User impact | Who is blocked and how, in plain words |
| Source | axe rule ID, or "manual" with the check |
| Evidence | File name (viewport screenshot, ASCII) |
| Suggested fix | One line |
| Severity | Per `/qa-defect`; say whether it meets the team's blocking threshold |

### 5. Report the claim honestly

End `a11y/audit.md` with a conclusion that keeps these statements apart:

- **"No violations found by the automated scan"** is a statement about the pages, states and rules that ran.
- **"Conformant"** is a statement about every criterion. An audit of this kind does not make it unless every criterion in the mapping was checked by the means it names.

List which criteria were checked by scanner, by hand, and **not checked at all**, and which pages and states were not audited. Never give a conformance score or a percentage: it hides which criterion failed. Do not quote how much of WCAG automation covers without a primary source and its date.

## Out of scope

Screen-reader automation, legal advice or a per-jurisdiction compliance mapping (it ages and is not QA's to give), native mobile apps, and changing the conformance level.
