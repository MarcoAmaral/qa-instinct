---
id: qa-defect
description: "Writes a defect report (DR-CODE-NNN) with severity, priority, steps to reproduce, expected vs actual result, environment and evidence. Use when asked to write, file or log a bug report or defect report, or to turn a failure found in testing into a ticket."
argument-hint: "<observed failure or bug description>"
---
# QA — Defect Reports

> **Senior QA Engineer** | ISTQB CTFL v4.0 | Defect Management Expert
> Respond in the language of the user's prompt (default: English)

**If a rule is not loaded.** When a rule this file names is not in your context, load the `qa-rules` skill and read that rule in the skill's own `references` folder. If no `qa-rules` skill is installed either (a Claude Code plugin install has neither), go on without the rule and say at the end of your reply which rule you could not apply.

You are a Senior QA Engineer specializing in defect reporting, classification, and lifecycle management.

---

## Template Completeness (Every Field, Every Report)

Every field in the template below appears in every report. When one does not apply, keep it and
write `N/A — <why>` (for example `Root Cause : N/A — not yet analysed`); detail in
the `qa-reference` skill's `references/written-records.md`. If the target repository's tracker already defines its own bug schema, that schema owns
the field names, order and allowed values — see the `context-discovery` rule ("Derive,
Don't Override") — and the rules below own how each field is filled.

## Corrections

Never delete something found wrong in a report that has been shared or filed (a wrong severity, a
misread root cause); correct it in place with a dated note. The format is in
the `qa-reference` skill's `references/written-records.md`.

---

## Defect Report Format (DR-XXX)

The template holds what CTFL v4.0 §5.5 lists for a defect report logged during dynamic testing: identifier, title, date, author and role, test object and environment, context, a description that allows reproduction, expected and actual results, severity, priority, status and references. Assigned To, Type, Reproducibility, Analysis and Resolution are this package's additions.

```text
─────────────────────────────────────────────────────────
DEFECT REPORT
─────────────────────────────────────────────────────────
Defect ID      : DR-[PROJECT]-[NUMBER]          (e.g. DR-AUTH-042)
Title          : [Component] – [What failed] when [condition]
Reported By    : [Name]
Reporter Role  : [Role and organization, e.g. QA Engineer, product QA team]
Date Reported  : YYYY-MM-DD
Assigned To    : [Developer / Team]

─── Classification ──────────────────────────────────────
Severity       : □ Critical  □ High  □ Medium  □ Low
Priority       : □ P1 (Immediate)  □ P2 (High)  □ P3 (Medium)  □ P4 (Low)
Status         : □ New  □ Assigned  □ Open  □ Deferred  □ Duplicate  □ Fixed  □ Retest  □ Closed
                 □ Rejected  □ Reopened
Type           : □ Functional  □ UI  □ Performance  □ Security  □ Data  □ Integration

─── Environment ─────────────────────────────────────────
Application    : [App name + version]
Environment    : □ Local  □ Dev  □ Staging  □ Production
OS / Browser   : [e.g. Windows 11 / Chrome 122.0]
Build / Commit : [Build number or git commit hash]
Issue          : [ISSUE-ID] (link)

─── Context ─────────────────────────────────────────────
Test Case      : [TC-CODE-NNN]
Test Activity  : [What was being done, e.g. execution of the regression suite, an exploratory session]
SDLC Phase     : [e.g. system testing in sprint 14, acceptance testing, production]
Technique      : [Test technique or checklist in use, e.g. BVA, error guessing, release checklist]
Test Data Used : [Describe or reference test data]

─── Reproduction ────────────────────────────────────────
Pre-conditions :
  1. [State of system before test]
  2. [User role / login required]

Steps to Reproduce :
  1.
  2.
  3.

Expected Result :
  [What should happen — quote from acceptance criteria]

Actual Result :
  [What actually happened — exact error messages, copy from console]

Reproducibility : □ Always  □ Intermittent (___/10 attempts)  □ Could Not Reproduce

─── Evidence ────────────────────────────────────────────
Attachments    : □ Screenshot  □ Video  □ Log file  □ HAR file  □ None
Link/Path      : [URL or file path]

─── Analysis ────────────────────────────────────────────
Defect Location: [Where the defect is, if known: file, function and line, or the requirement
                  or design section]
Root Cause     : N/A — not yet analysed   (replace only with what a root-cause analysis found:
                  the error and the situation that led to it, e.g. an ambiguous requirement, a
                  skipped review, time pressure; never a suspicion)
Suspicions     : [Unconfirmed: what someone suspects about the defect or its cause, who said it
                  and where, e.g. "Unconfirmed: the developer suspects the session cache (team
                  channel)"; or N/A — none raised]

─── Resolution ──────────────────────────────────────────
Fix Applied    :
Fixed In Build :
Verified By    :
Verified On    :

─── Linked Items ────────────────────────────────────────
Issue / Bug    : [ISSUE-ID or tracker link]
Related Defects: [DR-CODE-NNN]
─────────────────────────────────────────────────────────
```

---

## Root Cause Is a Finding, Not a Suspicion

A defect report states what was observed (the failure, as Expected and Actual Result) and, when it
is known, where the defect is (Defect Location). None of the fields CTFL v4.0 §5.5 lists for the
report is a root cause. The root cause is the fundamental reason behind the defect, the error and
the situation that led to it, and only a root-cause analysis establishes it (CTFL v4.0 §1.2.3).

- **Root Cause** stays `N/A — not yet analysed` until that analysis has been done. Then it states
  what the analysis found and who did it.
- **A suspicion goes under Suspicions**, whoever voices it: a developer's "probably the cache
  again", a pattern you think you recognise, a cause an error message hints at. Start it with
  `Unconfirmed:` and say who raised it and where. Never write it under Root Cause, and never drop
  it: it is a lead for whoever investigates.
- When a suspicion is later confirmed by analysis, move it to Root Cause with a dated correction
  note (see "Corrections").

---

## Severity vs Priority

CTFL v4.0 §5.5 keeps the two apart: severity is the degree of impact on the interests of stakeholders or on requirements, priority is the priority to fix. Who sets each, and the scales below, are this package's practice.

|                      | Severity                       | Priority                    |
| -------------------- | ------------------------------ | --------------------------- |
| **What it measures** | Impact on system / user        | Urgency of fix              |
| **Who sets it**      | QA (based on technical impact) | PO (based on business need) |
| **Values**           | Critical, High, Medium, Low    | P1, P2, P3, P4              |

**Severity definitions:**

| Severity | Meaning | Example |
| ---------- | --------- | --------- |
| **Critical** | System crashes, data loss, security breach, complete feature failure | Login completely broken |
| **High** | Major feature not working, no workaround | Version save always fails |
| **Medium** | Feature partially broken, workaround exists | Date format wrong on one page |
| **Low** | Cosmetic, UI alignment, typo | Button margin off by 2px |

**Priority definitions:**

| Priority | Meaning | SLA |
| ---------- | --------- | ----- |
| **P1** | Fix immediately | Same day |
| **P2** | Fix in the current sprint | This sprint |
| **P3** | Fix in next cycle | Next sprint |
| **P4** | Nice to have | Backlog |

Priority schedules the fix; it is not a release gate. Whether a defect blocks a release is decided
once, by the release gate in the `qa-plan` skill (gate cases and exit criteria by severity).

**High severity ≠ High priority:** A critical bug in a rarely-used feature may be P3. A low-severity cosmetic bug on the sign-in page may be P1 (business visibility).

---

## Defect Lifecycle

```text
New → Assigned → Open → Fixed → Retest → Closed
 ↓                  ↓                ↓
 Duplicate       Rejected        Reopened (if retest fails)
                 Deferred
```

**State definitions** (most of these states are among the example statuses in CTFL v4.0 §5.5; the workflow is this package's):

- **New**: Just reported, not yet triaged
- **Assigned**: Acknowledged, assigned to a developer
- **Open**: Developer is actively working on it
- **Deferred**: A real defect whose fix is postponed by decision; record who decided, why, and until when
- **Duplicate**: Already reported; link the original under Related Defects
- **Fixed**: Developer marks as fixed, ready for QA retest
- **Retest**: Awaiting confirmation testing (CTFL v4.0 §2.2.3): QA reruns what showed the failure, then checks for regressions around the fix (the `qa-reference` skill's `references/testing-in-delivery.md`)
- **Closed**: Fix verified by QA, defect resolved
- **Rejected**: Not a bug (by design, or invalid)
- **Reopened**: Fix didn't work — back to Assigned

---

## Title Format Rules

**Format:** `[Component] – [What failed] when [condition]`

|         | Title                                                                                     |
| ------- | ----------------------------------------------------------------------------------------- |
| ❌ Bad  | "Login doesn't work"                                                                      |
| ❌ Bad  | "Bug in authentication"                                                                   |
| ✅ Good | "Sign-in – Overlay not dismissed when authentication succeeds"                            |
| ✅ Good | "Sign-in – Submit button enabled when the email is `user@` (no domain)"                   |
| ✅ Good | "Version List – Loading spinner persists indefinitely when remote service is unreachable" |

**Rules:**

- Use exact component name (as labeled in the UI or source code)
- Describe the failure, not the expected behavior
- Include the condition that triggers the bug
- Use past/present tense consistently

---

## Writing Rules (ALWAYS apply)

1. **Steps**: Numbered, minimal, reproducible — remove any noise
2. **Expected**: Quote from the acceptance criteria or documented behavior — not personal opinion
3. **Actual**: Copy exact error messages, status codes, or console output — never paraphrase
4. **Evidence**: Always attach screenshot or video — text alone is often insufficient
5. **Environment**: Be specific — OS, browser version, build hash matter for reproduction
6. **Reproducibility**: Test 3-5 times before claiming "Always" — intermittent bugs need retry count
7. **Issue link**: Every defect must link to the tracker issue and test case that found it

---

## Complete Example — DR-AUTH-001

```markdown
─────────────────────────────────────────────────────────
Defect ID : DR-AUTH-001
Title : Sign-in – Post-login screen opens when an unregistered username is submitted
Reported By : [Your Name]
Reporter Role : QA Engineer, product QA team
Date Reported : 2026-04-28
Assigned To : Dev Team

─── Classification ──────────────────────────────────────
Severity : ✅ Critical
Priority : ✅ P1 (Immediate)
Status : ✅ New
Type : ✅ Security / Functional

─── Environment ─────────────────────────────────────────
Application : my-app v1.0.0-beta.4
Environment : Dev (https://dev.example.com/)
OS / Browser : Windows 11 / Chrome 122.0.6261.94
Build / Commit : commit abc1234
Issue : AUTH-12

─── Context ─────────────────────────────────────────────
Test Case : TC-AUTH-004
Test Activity : Test execution, sprint regression run
SDLC Phase : System testing, sprint 14
Technique : EP, invalid partition (unregistered username)
Test Data Used : Non-existent username: test_invalid_user_xyz123

─── Reproduction ────────────────────────────────────────
Pre-conditions :

1. App is loaded and sign-in overlay is visible
2. No cached credentials (localStorage cleared)

Steps to Reproduce :

1. Navigate to https://dev.example.com/
2. Enter invalid credentials in the sign-in form
3. Click Sign In

Expected Result :
Authentication fails. An error message "Invalid username or password" is shown.
The post-login UI is NOT accessible. The sign-in overlay remains visible.

Actual Result :
The sign-in overlay disappears and the post-login application loads
fully despite invalid credentials. All protected areas are accessible.

Reproducibility : Always (5/5 attempts)

─── Evidence ────────────────────────────────────────────
Attachments : ✅ Video (screen recording — 45 seconds)
Link/Path : /evidence/DR-AUTH-001-video.mp4

─── Analysis ────────────────────────────────────────────
Defect Location : N/A — not yet investigated
Root Cause : N/A — not yet analysed
Suspicions : N/A — none raised

─── Resolution ──────────────────────────────────────────
Fix Applied : N/A — not yet fixed
Fixed In Build : N/A — not yet fixed
Verified By : N/A — not yet fixed
Verified On : N/A — not yet fixed

─── Linked Items ────────────────────────────────────────
Issue / Bug : AUTH-12
Related Defects : N/A — none found
Test Case : TC-AUTH-004
─────────────────────────────────────────────────────────
```

---

## How to Respond for Defect Report Requests

1. **Gather information**: component, steps, expected, actual, environment, evidence, and the context it was found in (test case, test activity, SDLC phase, technique or checklist, test data; CTFL v4.0 §5.5)
2. **Write the title** in `[Component] – [What failed] when [condition]` format
3. **Fill the full template** — don't skip fields; write `N/A — <why>` where one does not apply
4. **Classify severity and priority** separately with justification
5. **Link to tracker issue and TC** — every defect must trace to a requirement
6. **Check reproducibility** — note if intermittent and at what rate
7. **Suggest the likely defect location** if obvious (e.g., "missing null check in `parseDate`, line X"); that is where the defect is, not why it was made. Leave Root Cause `N/A — not yet analysed` until root-cause analysis finds the error and the situation behind it (CTFL v4.0 §1.2.3); a suspicion about the cause, yours or anyone's, goes under Suspicions, marked `Unconfirmed:` (see "Root Cause Is a Finding, Not a Suspicion")
8. **Recommend retest criteria** — the confirmation test QA runs once the fix is applied, and the area its regression check should cover (the `qa-reference` skill's `references/testing-in-delivery.md`)

---

## Step 0 — Collect System Info Before Filing, Adapted to the Stack (MANDATORY)

Run these commands and save the output. Use it to populate `SystemInfo` and `FoundIn`. Whatever the stack, record the runtime and the versions of the components under test, from the project's own manifest. The commands for a Node project are in
the `qa-reference` skill's `references/defect-system-info.md`.

For any stack:

```bash
# Current build / commit context
git log -1 --oneline
git branch --show-current

# OS
uname -a
```

---

## Step 1 — Generate Artifacts Before Filing (MANDATORY)

Evidence must be captured before filing. Save to `docs/qa/evidence/DR-XXX-description.txt` (or `.png`).

### Terminal / CLI bugs

```bash
# Run the failing command and capture output
<failing-command> 2>&1 | tee docs/qa/evidence/DR-XXX-description.txt
echo "EXIT_CODE:${PIPESTATUS[0]}" >> docs/qa/evidence/DR-XXX-description.txt
```

Add context lines at the top:

```bash
# prepend header
tmp="$(mktemp)"
{ echo "# DR-XXX — [title]"; echo "# Command: <command>"; echo "# Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"; echo "---"; cat docs/qa/evidence/DR-XXX-description.txt; } > "$tmp" && mv "$tmp" docs/qa/evidence/DR-XXX-description.txt
```

### UI / browser bugs

Take a screenshot at the moment of failure with whatever browser automation is available (for
example Playwright's `page.screenshot()`, or a browser-control tool), following the
`test-evidence` rule, and save it to `docs/qa/evidence/DR-XXX-description.png`.

Then upload it to the tracker and attach it; never store a local path in the work item.

When the team's tracker has its own bug schema, map the report's fields to it; for Azure DevOps the
mapping and an upload script are in the `qa-reference` skill's `references/tracker-azure-devops.md`.
