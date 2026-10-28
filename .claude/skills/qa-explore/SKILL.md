---
name: qa-explore
description: "Plans and runs session-based exploratory testing (SBTM): test charters, heuristics, time-boxed sessions and runbooks. Use when asked for exploratory testing or an exploratory session, to explore a feature by hand, organise a bug bash, write test charters, or test something without scripted cases."
metadata:
  id: qa-explore
  author: Marco Amaral
---
# Skill: Session-Based Exploratory Testing & SBTM

> **Senior QA Engineer** | ISTQB CTFL v4.0 | Exploratory Testing & SBTM Workflow

This skill is automatically activated when tasks involve exploratory testing, setting up bug bashes, executing session-based test management (SBTM), or defining test heuristic strategies.

---

Files named "the `qa-reference` skill's `references/<file>.md`" are in the `qa-reference` skill's folder, not this skill's: load the `qa-reference` skill and read them there.

## 🎯 Task Activation Patterns

This skill matches tasks containing:

- `exploratory testing`, `exploratory charter`, `ET charter`, `SBTM`, `session notes`
- `bug bash`, `heuristics`, `SFDPOT`, `FEW HICCUPS`, `FEW HICCUPPS`

---

## 🧭 Exploratory Testing Charter Blueprint (ET-XXX)

```markdown
---
charter_id: ET-[NNN]
feature: [Feature or area under test]
risk_level: HIGH|MEDIUM|LOW
session_duration: 60|90|120 min
tester: [Name]
date: YYYY-MM-DD
---

# ET-[NNN]: [Mission title]

| Field           | Value                                                     |
| --------------- | --------------------------------------------------------- |
| **Charter ID**  | ET-[NNN]                                                  |
| **Mission**     | Explore [target] to discover [what kind of issues]        |
| **Target Area** | [Module, feature, or user flow]                           |
| **Time-Box**    | [60/90/120] minutes                                       |
| **Heuristics**  | SFDPOT + [specific focus]                                 |
| **Test Data**   | [Specific accounts, data sets, or configurations]         |
| **Environment** | [Browser, device, URL, configuration]                     |
| **Risk**        | [Which risk(s) from RISK-REGISTER this charter addresses] |

## Focus Areas

1. [Specific target 1]
2. [Specific target 2]
3. [Specific target 3]

## Out of Scope

- [What this charter does NOT cover to prevent scope creep]

## Session Sheet and Debrief

Exploratory testing is session-based: time-boxed, guided by a charter, with notes and a debrief (CTFL v4.0 §4.4.2). Fill this in during and after the session.

| Field                 | Value                                               |
| --------------------- | --------------------------------------------------- |
| **Start / End**       | [HH:MM] / [HH:MM]                                   |
| **On charter**        | [%] on charter vs. [%] on opportunity (off-charter) |
| **Coverage achieved** | [Areas, data and heuristics actually covered]       |

**Notes:** [What was tried, in order, and what was observed]

**Bugs:** [DR-XXX ids, or "none"]

**Issues and questions:** [Blockers, unclear requirements, things to ask the product owner]

**Debrief:**

- What was learned about the product and the risks?
- What should be explored next (new charters)?
```

---

## 🧠 Core Testing Heuristics

### 1. SFDPOT (James Bach's Heuristic Test Strategy Model)

- **S**tructure: UI layout, DOM, element ordering, keyboard navigation tab order.
- **F**unction: CRUD operations, business rules, calculations, and data processing.
- **D**ata: Input validation, boundaries (empty, special characters, XSS payloads).
- **P**latform: Cross-browser compatibility (Chrome/Firefox/WebKit), viewport scaling.
- **O**perations: Installation, environment variables, local storage caching.
- **T**ime: Timeouts, session expiration, race conditions, date boundaries.

### 2. FEW HICCUPPS (consistency oracles)

Michael Bolton's list, from James Bach's work. Each item is an oracle: a way to recognise a problem by an inconsistency. Behavior that conflicts with one of these is worth investigating.

- **F**amiliar problems: the product is inconsistent with a failure pattern you have seen before.
- **E**xplainability: the product behaves in a way you cannot explain, or that you could not defend to a stakeholder.
- **W**orld: the product is inconsistent with how the real world works (dates, units, geography, physics).
- **H**istory: the product is inconsistent with its own earlier behavior, or with the previous version.
- **I**mage: the product is inconsistent with the image the organization wants to project (brand, tone, quality).
- **C**omparable products: the product is inconsistent with similar products that users also know.
- **C**laims: the product is inconsistent with what the specification, help text, marketing or a ticket says.
- **U**ser expectations: the product is inconsistent with what a reasonable user would expect.
- **P**roduct: the product is inconsistent with itself (the same action behaves differently in two places).
- **P**urpose: the product is inconsistent with the purpose it exists for, even if every claim is met.
- **S**tatutes and standards: the product is inconsistent with applicable law, regulation or standards (accessibility, privacy).

### 3. Risk-area prompts (package checklist)

Not part of FEW HICCUPPS. Use these to pick what to explore:

- **Common paths**: the most used paths and happy paths.
- **Error handling**: network drops, 401/403 responses, server down simulations.
- **Workflow**: end-to-end user journeys and interrupted workflows.
- **Hardware**: multi-device testing, touch viewports vs. pointer inputs.
- **Interruption**: mid-flow refreshes, back buttons, backgrounding tabs.
- **Control**: user roles, permissions, administrative settings.
- **Configuration**: stored preferences, internationalization/locale switching.
- **User scenarios**: power users vs. novice users vs. accessibility users.
- **Performance**: large data loads, network throttling, memory leaks.
- **Security**: input sanitization, authentication bypasses, session hijacking.

To run these as a test checklist, or to keep the list useful as defects are found, follow checklist-based testing in the `qa-reference` skill's `references/testing-design.md`.

---

## 🏆 Tour-Based Exploratory Testing

- **Money Tour**: Verify the core features that directly drive business value.
- **Landmark Tour**: Navigate systematically to every single page and check basic access.
- **Bad Neighborhood Tour**: Target areas with a high density of historically logged bugs: defects cluster (CTFL v4.0 §1.3, principle 4).
- **Saboteur Tour**: Actively try to break inputs, session states, and security layers.
- **Guidebook Tour**: Follow user guides and documentation to ensure app behavior matches.

---

## 📋 Runbook Heuristics

When an exploratory session or a checklist run will be executed by someone else, or at speed:

- **For a checklist run, write the runbook as a linear, numbered script.** The executor should never have to jump between sections; repeat a value inline rather than cross-reference it.
- **For an exploratory session handed to someone else, hand over the charter and the debrief questions, not steps.** A numbered script turns the session into scripted testing and removes the learning it exists for.
- **Mark clearly where to stop** when later stages are blocked (an unavailable dependency, a missing account), so nobody starts a pass they cannot finish.
- **Capture irreversible states first.** Put the steps whose evidence window closes permanently at the top of the runbook.
- **Treat a change to shared state as a write.** Note the original state and time in the runbook, and add a restore step.
- Recording pace is covered in the `qa-reference` skill's `references/evidence-capture.md`.
