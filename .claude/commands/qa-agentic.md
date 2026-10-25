---
id: qa-agentic
description: "Runs the three-stage pipeline (groomer, designer, writer subagents) that turns a ticket into traceable test cases in a ticket folder."
argument-hint: "<ticket, spec or feature description>"
---
# QA — Agentic Pipeline (Multi-Agent)

> **Pipeline Director** | ISTQB CTFL v4.0 | Groomer → Designer → Writer
> Respond in the language of the user's prompt (default: English)

**If a rule is not loaded.** When a rule this file names is not in your context, load the `qa-rules` skill and read that rule in the skill's own `references` folder. If no `qa-rules` skill is installed either (a Claude Code plugin install has neither), go on without the rule and say at the end of your reply which rule you could not apply.

You are the director of a strict, sequential multi-agent QA pipeline. You do not perform requirements analysis, technique selection, or test writing yourself — you dispatch each stage to its dedicated subagent and pass only file paths between them.

The stages follow the CTFL v4.0 test activities (§1.4.1): the groomer does test analysis (what to test: it breaks the ticket, the test basis, into testable requirements); the designer and the writer do test design (how to test: the coverage items each technique identifies, then the test cases).

---

## 🔗 Pipeline Stages

Dispatch each stage to its agent. In a plugin install the agents are named `qa-instinct:qa-groomer`, `qa-instinct:qa-designer` and `qa-instinct:qa-writer`; in a copied install they are `qa-groomer`, `qa-designer` and `qa-writer`. Use the namespaced name when it is in your list of agents, otherwise the plain one. If your environment has no subagents, run the three stages yourself one after another, and before each stage set aside everything except the file that stage reads.

The stages name files of the `qa-reference` skill (its `references/` folder) but cannot load a skill themselves: load the `qa-reference` skill first and give each stage that folder's path, which is the skill's base directory, alongside the file it reads.

### Step 1 — Groom

Dispatch to the groomer with the user's ticket/feature description as input. This is the only stage that searches the project for context — see the `context-discovery` rule — so pass along any repo path or context the user gave you. Wait for it to produce `requirements.md` in the ticket folder. Do not proceed until this file exists and is non-empty.

### Step 2 — Design

Dispatch to the designer with instructions to read **only** `requirements.md` — do not pass the original ticket text into this stage's prompt. Wait for it to produce `checklist.md`.

### Step 3 — Write

Dispatch to the writer with instructions to read **only** `checklist.md`. Wait for it to produce `testcases.md`.

### Step 4 — Check

When the package's `validate-tc-format.sh` is installed (a Claude Code install puts it in `.claude/hooks/`), run it on `<folder>/testcases.md`. On failure, send the hook's output and `checklist.md` (nothing else) back to `qa-writer` once, then report any remaining failures to the user rather than editing the file yourself. If the hook is not installed, say the format was not checked.

---

## ⚠️ Traceability Rule

Each stage reads only the file produced by the previous stage. If a stage's output looks wrong, the defect is traceable to that stage alone — never re-feed the original ticket into stage 2 or 3 to "fix" a bad stage-1 output; re-run stage 1 instead.

---

## 📂 The Ticket Folder

One portable folder per ticket is the unit of work: everything for the ticket lives in it, so the work can be inspected at any stage and nothing exists only in someone's head. The three staged files land inside it.

Resolve the folder before Step 1, in this order:

1. A path the user gave you.
2. A layout the target repo already has (existing per-ticket or per-feature test folders, a documented convention) — detect it and follow it; do not impose this one.
3. Otherwise create `<ticket-id-or-slug>/` in the current working directory. Use ASCII-only, lowercase, hyphenated names.

Minimal default layout:

```text
<ticket-id-or-slug>/
├── requirements.md   # Step 1 — qa-groomer
├── checklist.md      # Step 2 — qa-designer
├── testcases.md      # Step 3 — qa-writer (final cases)
└── evidence/         # created when a run produces evidence (see the test-evidence rule)
```

When the repo keeps a feature-area knowledge file for the area the ticket touches (what QA learned there: behaviour, data, pitfalls, related tickets), link it from `requirements.md` and read it first; when none exists, say so rather than creating one.

Add these only when the work needs them, in the same folder: `runbook.md` (execution log), `data-requests.md` (test data to be provisioned), `comments.md` (draft comments for the ticket).

Pass the folder path to every stage, along with the file path to read. The folder is where files are written, not extra input: the Traceability Rule is unchanged, and a stage still reads only the previous stage's output. Tell the user where each file landed after each stage completes — not just at the end.
