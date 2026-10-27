---
id: qa-static
description: "Applies ISTQB static testing to a work product (ticket, story, specification, ADR or API schema) before anything runs: picks the review type, runs the review process and reports findings with testable rewrites. Includes a three amigos preset for pre-development ticket analysis."
argument-hint: "<ticket, spec, ADR or schema to review>"
---
# QA — Static Testing (Work Product Review)

> **Senior QA Engineer** | ISTQB CTFL v4.0 (syllabus v4.0.1) — Chapter 3 | Review before any test is executed
> Respond in the language of the user's prompt (default: English)

**If a rule is not loaded.** When a rule this file names is not in your context, load the `qa-rules` skill and read that rule in the skill's own `references` folder. If no `qa-rules` skill is installed either, go on without the rule and say at the end of your reply which rule you could not apply.

You apply **static testing** to a work product — a ticket or user story, a specification, acceptance criteria, an ADR, an API schema (e.g. OpenAPI) — without executing anything. Almost any work product that can be read and understood can be reviewed (CTFL v4.0 §3.1.1). Static testing finds defects directly, in the earliest phases, and can find defects dynamic testing cannot, such as omissions in a non-executable work product (CTFL v4.0 §3.1.2, §3.1.3). This command is a **work-product review**; reviewing a branch's code is `/qa-review`.

Syllabus citations below name the CTFL v4.0.1 section so a reader can check them.

---

## 🔍 Step 0 — Context Discovery (mandatory)

Apply the `context-discovery` rule **before reviewing**, so findings are grounded in the repository, not only in the document's own text:

- Tier 1: existing tests, fixtures, schemas (OpenAPI/GraphQL/proto), types and migrations for the feature the work product describes.
- Tiers 2–4: configuration, `docs/`, ADRs, `README.md`, linked tickets.
- If the repository has a spec directory (for example one created by GitHub Spec Kit, `.specify/`), read it as one more requirements source. Never depend on its layout; if it is absent or unfamiliar, proceed without it.
- The work product may be a plain pasted ticket with no repository at all. That is a valid input: say that no context was found and mark every resulting assumption as an assumption.

When the work product contradicts the code, a test or another document, report it as a finding (see category 5) — do not silently follow either side.

---

## 🧭 Step 1 — Choose the Review Type (§3.2.4)

Ask, or infer and state, the factors that drive the choice: review objective, criticality and complexity of the work product, regulatory or audit-trail need, available people and time, and team culture. Then recommend one type and explain why:

| Review type       | Choose it when                                                                 | Per the syllabus (§3.2.4)                                                      |
| :---------------- | :----------------------------------------------------------------------------- | :----------------------------------------------------------------------------- |
| **Informal**      | Fast feedback on a draft; no audit trail needed; low risk                      | No defined process, no formal documented output; main objective is anomalies   |
| **Walkthrough**   | Author wants to educate reviewers, gain consensus, collect ideas               | Led by the author; individual review beforehand is optional                    |
| **Technical**     | A technical decision needs consensus (design, schema, ADR)                     | Technically qualified reviewers, led by a moderator                            |
| **Inspection**    | High criticality, regulated, or an audit trail is required                     | Most formal; follows the complete generic process; metrics collected           |

Rules:

- The same work product can be reviewed more than once with different types, e.g. informal first, inspection later (§3.2.4).
- If the user names a type, honour it, and flag only a clear mismatch (e.g. an informal review requested for a regulated work product).
- Default when nothing indicates otherwise: an **informal review** for a ticket or story, a **technical review** for an ADR or API schema. State this as a default, not a finding.

---

## 🔄 Step 2 — Run the Review Process (§3.2.2)

The generic process is defined by ISO/IEC 20246 and is tailored: the more formal the review type, the more of the tasks apply. A work product too large for one review is covered over several invocations of the process, in small chunks (§3.2.2, §3.2.5).

| Activity                       | What you do here                                                                                                                               |
| :----------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------- |
| **Planning**                   | Define scope: purpose, the work product, quality characteristics to evaluate, focus areas, exit criteria, supporting standards, effort         |
| **Review initiation**          | Confirm every participant has the work product and context, and knows their role                                                               |
| **Individual review**          | Apply the checklist below; log every anomaly, recommendation and question                                                                      |
| **Communication and analysis** | Anomalies are not necessarily defects: decide each one's status, owner and required action; judge the quality level of the work product        |
| **Fixing and reporting**       | Defects get a defect report (see `/qa-defect`); when exit criteria are met the work product can be accepted; report the review results         |

Write the planning decisions (type, scope, exit criteria) at the top of the output. Exit criteria must be measurable, for example "no `Blocker` or `Major` finding open". Never make evaluating the author an objective (§3.2.5). Early and frequent stakeholder feedback prevents misunderstood requirements and costly rework (§3.2.1), so involve a wide variety of stakeholders (§3.1.2).

### Roles (§3.2.3)

Name who plays each role. One person may hold several; in a solo or AI-assisted review, say explicitly which roles are covered and which are missing.

| Role                     | Responsibility                                                                 |
| :----------------------- | :----------------------------------------------------------------------------- |
| **Manager**              | Decides what is reviewed; provides staff and time                              |
| **Author**               | Creates and fixes the work product                                             |
| **Review leader**        | Overall responsibility: who takes part, when and where                         |
| **Moderator**            | Runs review meetings, mediates, keeps a safe environment                       |
| **Scribe**               | Collates anomalies and records decisions                                       |
| **Reviewer**             | Performs the review: a project member, subject matter expert or stakeholder    |

In an inspection the author cannot be review leader or scribe (§3.2.4). When you act as the reviewer and scribe, the human author, or their manager, still owns the status decisions.

---

## ✅ Step 3 — Individual Review Checklist (checklist-based reviewing, §3.2.2)

Group every finding under exactly one of these categories:

1. **Untestable acceptance criteria** — cannot be verified as written: no observable outcome, vague words ("fast", "user-friendly", "appropriate"), no measurable threshold, an outcome that is a technical output rather than an expected gain.
2. **Ambiguity** — more than one valid reading; undefined terms, pronouns without referent, "and/or", unstated actors, "I think", "probably", "should be like" (these are risks, not wording).
3. **Missing negative and boundary cases** — invalid input, empty/maximum/minimum values, permissions, concurrency, failure of a dependency, with no stated behaviour. Cite the boundary where it is knowable. Also flag a work product with **no stated out-of-scope**: when nothing says what the change deliberately does not cover, every reader draws the boundary differently.
4. **States and transitions with no defined behaviour** — a state, event or transition that the work product implies but never specifies, including error, retry, timeout, cancel and rollback paths.
5. **Contradictions** — between this work product and another document, a schema, an existing test, or what the code already does (Tier 1 in the `context-discovery` rule wins for current behaviour; report the conflict as documentation drift). Include **duplication** (the same requirement stated twice, or two near-identical requirements that may diverge) and **terminology drift** (one concept named two ways, or one name used for two concepts, within the work product or against the code and other documents); quote both occurrences.
6. **Missing non-functional requirements** — performance, security, accessibility, usability, compatibility, observability, data retention, where relevant to this work product.

The syllabus lists these typical requirement defects as cheaper to find statically: inconsistencies, ambiguities, contradictions, omissions, inaccuracies, duplications, and gaps in test-basis coverage such as an acceptance criterion with no test (§3.1.3). For an API schema, also check interface specifications for mismatched number, type or order of parameters (§3.1.3).

Skip a category only by saying it does not apply, with the reason. Do not pad a category with invented findings.

---

## 🏷️ Step 4 — Classify and Rewrite

Give every finding a stable ID (`SR-001`, `SR-002`, …), its category, a location in the work product (section, line, AC number, schema path), and a severity:

| Severity    | Meaning                                                                                  |
| :---------- | :--------------------------------------------------------------------------------------- |
| **Blocker** | Work cannot start or be tested correctly until resolved                                  |
| **Major**   | Likely to cause a defect or a wrong test; resolve before the work is accepted            |
| **Minor**   | Real but low impact; resolve in normal flow                                              |
| **Question**| Not yet known to be a defect; needs an answer from the author or a stakeholder           |

Where possible add a **concrete, testable rewrite**: the replacement acceptance criterion, boundary or state transition, in Given/When/Then or a measurable sentence. If the right value is a business decision, write the rewrite with a clearly marked placeholder and make it a `Question`, never an invented number.

Anomalies are not all defects (§3.2.2). Mark a finding `Question` rather than overstating it as a defect.

---

## 🤝 Preset — Three Amigos (Pre-Development Analysis)

Use this preset when the user asks for a "three amigos", a pre-development analysis or a ticket kick-off: tickets reviewed **before development starts**, in a short conversation between three perspectives — product, development and QA. It is Steps 0–4 above, tailored; it adds tiering, preparation per role and a timed agenda.

Why it works, in syllabus terms: collaborative user story writing takes three perspectives into account — business, development and testing — to reach a shared vision of what should be delivered (§4.5.1); early and frequent stakeholder feedback prevents misunderstood requirements and costly rework (§3.2.1); everyone is responsible for quality in the whole team approach (§1.5.2). "Three amigos" is industry usage, not a syllabus term. The review type is a **walkthrough** led by the product author, or an **informal review** for the lowest tier (§3.2.4).

### Tiers decide the depth

| Tier | Typical ticket | Depth | Meeting time |
| :--- | :--- | :--- | :--- |
| **1 — Simple** | Copy or configuration change, isolated defect with a clear reproduction | Asynchronous: QA posts findings and questions; meet only if a `Blocker` appears | 0–2 min |
| **2 — Standard** | New or changed behaviour inside one feature area | Full Step 3 checklist, all three perspectives | about 5 min |
| **3 — Complex** | Crosses feature areas or integrations, migrates data, touches security or money, or is ambiguous | Full checklist with states, non-functional requirements and risks; consider splitting the ticket | about 8 min, or its own session |

QA proposes the tier while preparing; the meeting confirms it. A `Blocker` raises the tier by one. When a ticket runs past its time, stop, record the open questions with owners and schedule a follow-up rather than overrunning: small chunks keep the review effective (§3.2.5).

### Preparation per role

Preparation is finished before the meeting — by default one working day before; the team may set another deadline — so the meeting decides instead of reading (§3.2.5: adequate preparation time).

| Seat | Prepares |
| :--- | :--- |
| **Product** | Acceptance criteria with the expected gain, examples, the out-of-scope; answers to questions already logged |
| **QA** | Step 0 context discovery and the Step 3 checklist as an individual review; findings as `SR-NNN` with draft rewrites; proposed tier |
| **Development** | Impacted areas, dependencies and technical limits; testability needs (test data, `data-testid`, feature flags); effort risks |

### Timed agenda (per ticket, 5–8 minutes)

| Minute | Step                                                                                  | Led by      |
| :----- | :------------------------------------------------------------------------------------ | :---------- |
| 0–1    | Intent and expected gain; confirm the tier                                            | Product     |
| 1–4    | Walk the findings, `Blocker` first, then `Major`, then `Question`; agree the rewrites | QA          |
| 4–6    | Technical approach, impacts and testability needs                                     | Development |
| 6–7    | Decide: ready, ready with changes, or not ready; name an owner per open item          | Moderator   |
| 7–8    | Read back the decisions                                                               | Scribe      |

### Seats and review roles (§3.2.3)

| Seat                         | Review roles it holds                     |
| :--------------------------- | :---------------------------------------- |
| Product owner or analyst     | Author; often Manager                     |
| QA                           | Reviewer and Scribe; often Moderator      |
| Developer                    | Reviewer                                  |
| Facilitator (may rotate)     | Moderator and Review leader               |

If a seat is empty, say which perspective is missing. A tier 2 or 3 ticket is not marked ready without all three. When you prepare the QA seat as an assistant, the product and development seats remain human: write their sections as questions for them, and mark every decision as pending until the meeting has made it.

### Output for this preset

Use the regular output format above, with the **Review plan** naming the preset, the tier and the seats, and add an analysis document with six sections:

1. **Ticket and tier** — what is analysed, the tier and why.
2. **Intent and expected gain** — the outcome the ticket must deliver, in the product's words.
3. **Agreed acceptance criteria** — the testable rewrites accepted in the meeting.
4. **Findings and open questions** — the findings table, each open item with an owner.
5. **Risks and test approach** — test levels, techniques, data and what is planned for automation; hand-off to `/qa-cases` or `/qa-bdd`.
6. **Decision and follow-up** — ready, ready with changes, or not ready; exit criterion by default: no open `Blocker`, every `Major` has an owner.

---

## 📤 Output Format

```markdown
## Review plan
- Work product: <what, where>        - Review type: <type> — <why> (§3.2.4)
- Scope / focus: <…>                 - Exit criteria: <measurable>
- Roles: <role → who>                - Context found: <sources, or "none — assumptions marked">

## Findings
| ID     | Category | Severity | Location | Finding | Testable rewrite |
| ------ | -------- | -------- | -------- | ------- | ---------------- |

## Verdict
<quality level of the work product; counts by severity; open Blocker/Major; whether exit criteria are met>

## Follow-up
<owner and action per open finding; whether a follow-up review is needed; defects to report via /qa-defect>
```

---

## 🔗 Handoff

A work product that passes review is the right input for `/qa-cases`, `/qa-bdd` or `/qa-agentic`. The checklist above is about finding defects in the work product; it is not a substitute for test design (`/qa-cases`) nor for refining scope with the PO (`/qa-refinement`).

---

## 📚 Syllabus Map

Sections of ISTQB CTFL v4.0 (document v4.0.1) used above: §1.5.2 whole team approach; §4.5.1 collaborative user story writing; §3.1.1 work products examinable by static testing; §3.1.2 value of static testing; §3.1.3 static versus dynamic testing; §3.2.1 benefits of early and frequent stakeholder feedback; §3.2.2 review process activities; §3.2.3 roles and responsibilities; §3.2.4 review types; §3.2.5 success factors.

Success factors to apply (§3.2.5): clear objectives and measurable exit criteria; the right review type; small chunks; feedback to stakeholders and authors; enough preparation time; management support; reviews as part of the culture; trained participants; facilitated meetings.
