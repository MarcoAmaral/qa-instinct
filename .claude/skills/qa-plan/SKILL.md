---
name: qa-plan
description: "Builds test strategies, test plans and risk registers (5x5 likelihood x impact) with estimation, entry and exit criteria, a release gate, and monitoring and reporting, per ISTQB CTFL v4.0 chapter 5. Use when asked for a test plan, test strategy or QA strategy, a risk assessment or risk register, a test estimate, entry or exit criteria, release criteria, or a test progress or completion report."
metadata:
  id: qa-plan
  author: Marco Amaral
---
# Skill: Test Strategy, Planning & Risk Assessment

> **Senior QA Engineer** | ISTQB CTFL v4.0 (Chapter 5) | Test Planning & Risk Register Workflow

This skill is automatically activated when tasks involve creating test plans, designing test strategies, performing risk assessments, or setting up quality gates.

---

Files named "the `qa-reference` skill's `references/<file>.md`" are in the `qa-reference` skill's folder, not this skill's: load the `qa-reference` skill and read them there.

## 🎯 Task Activation Patterns

This skill matches tasks containing:

- `test plan`, `test strategy`, `risk register`, `entry criteria`, `exit criteria`
- `test pyramid design`, `traceability matrix`, `quality gates`
- `risk-based testing`, `test estimation`, `test effort`
- `completion report`, `retrospective`, `lessons learned`

---

## 📖 Test Strategy & Planning Workflow

### Step 1: Establish Project Parameters

Obtain or define the baseline project metadata:

- Project Name, Version, Owner, board URL (GitHub/ADO/JIRA).
- Tech stack and hosting environments (Local, Dev, Staging, Production).

### Step 2: Scope Delineation

Clearly divide the application into:

- **In Scope**: Feature areas, user story IDs, test levels, and business priority.
- **Out of Scope**: Specifically state what is excluded (and why) to manage expectations and timeline limits.

### Step 3: Core Strategy (The Adaptive Test Pyramid)

Define the test distribution using the "One Diagnostic Question":

> **"Where does the business logic live?"**

The test pyramid is a CTFL v4.0 model (§5.1.6): the higher the layer, the fewer, slower and less isolated its tests. The presets below are this package's, not syllabus figures.

Select the matching architectural preset:

1. **Backend / API / Microservices**: 70% Unit · 20% Integration · 10% E2E
2. **Full-stack web app (React + API)**: 40% Unit · 40% Integration · 20% E2E
3. **UI-heavy / Canvas / GIS / Mapping**: 20% Unit · 30% Integration · 50% E2E. The E2E share is a cost
   accepted because the logic lives in the UI, not a goal: end-to-end tests are the slowest, costliest
   and most brittle layer. Before choosing this preset, move logic out of the UI into units, cover
   rendering with component and visual regression tests, and check the E2E suite still fits the suite
   duration targets (see the caveat in the `qa-reference` skill's `references/testing-design.md`).
4. **Data pipeline / ETL**: 60% Unit · 35% Integration · 5% E2E

#### Check the Plan Against the Testing Quadrants (CTFL v4.0 §5.1.7)

The pyramid sets proportions; the testing quadrants (Brian Marick's model) check that no kind of testing is missing. They cross **business facing** or **technology facing** with **supports the team** or **critiques the product**: Q1 technology facing, supports the team; Q2 business facing, supports the team; Q3 business facing, critiques the product; Q4 technology facing, critiques the product. Before writing the test approach, read what each quadrant typically holds and where it sits in this package in the `qa-reference` skill's `references/test-planning.md`, "Testing Quadrants". A plan with nothing in one quadrant says why, in its test approach (item 6 of the test plan below).

### Step 4: Estimate the Test Effort

An estimate is a prediction built on assumptions and is always subject to error (CTFL v4.0 §5.1.4). State the assumptions next to the number, say which technique produced it, and decompose large work into smaller tasks before estimating. Report the estimate as a range with its assumptions, not as a single figure.

Choose one of the four techniques of CTFL v4.0 §5.1.4. Before choosing, read when each fits, and the worked three-point example, in the `qa-reference` skill's `references/test-planning.md`, "Estimation Techniques":

- **Metrics-based**: estimation by ratios (from earlier projects) or extrapolation (from earlier iterations of this one).
- **Expert-based**: Wideband Delphi (Planning Poker is a variant) or three-point estimation, E = (a + 4m + b) / 6 and SD = (b − a) / 6.

When the plan carries a risk register, the risk level of each item also feeds the effort assigned to it (see Risk-Based Testing below).

---

## 📊 Risk-Based Testing: The Risk Register Blueprint (5×5 Matrix)

This register is the package's **risk-based testing** mechanism: the test approach in which test activities are selected, prioritized and managed on the basis of risk analysis and risk control (CTFL v4.0 §5.2). A risk is characterized by its likelihood and its impact, and the two together give the risk level (CTFL v4.0 §5.2.1). The higher the level, the more important its treatment.

The risk level drives the plan (CTFL v4.0 §5.2.3):

- **Depth and scope**: which items are tested and how deeply, and which test levels and types apply.
- **Technique and coverage**: stronger techniques and higher coverage for higher levels (e.g. decision tables and state transition for a CRITICAL rule; happy path plus exploratory for a LOW one).
- **Effort**: more effort goes to tasks with a higher risk level (estimate it in Step 4).
- **Order**: test the highest levels first, so critical defects surface as early as possible (other orderings and what overrides them: Test Execution Order below).
- **Non-test measures**: where testing alone does not reduce a risk, say what else would (a review, a feature flag, a rollback plan).

Distinguish the two kinds of risk (CTFL v4.0 §5.2.2). **Product risks** concern the quality of the product (wrong calculation, security hole, poor response time). **Project risks** concern managing the project (late delivery, missing skills, tool problems, inaccurate estimates). Mark each register row with its Category.

Classify risks based on **Likelihood (1–5)** and **Impact (1–5)**:

- **Score = Likelihood × Impact**: the quantitative approach of CTFL v4.0 §5.2.3; the 1–5 scales and the levels below are this package's.

| Score     | Severity Level | Action Required                                                  |
| :-------- | :------------- | :--------------------------------------------------------------- |
| **15–25** | 🔴 CRITICAL    | Test first, absolute automated coverage, regular reviews         |
| **8–14**  | 🟠 HIGH        | Prioritize in test cycles, automate in Regression, track metrics |
| **4–7**   | 🟡 MEDIUM      | Standard functional coverage, run on Sprint deployments          |
| **1–3**   | 🟢 LOW         | Basic happy-path coverage, exploratory checks only               |

### Risk Register Schema

```markdown
| #   | ID  | Risk Description                            | Category | L   | I   | Score | Level       | Mitigation Strategy                       | Owner  |
| --- | --- | ------------------------------------------- | -------- | --- | --- | ----- | ----------- | ----------------------------------------- | ------ |
| 1   | R01 | Authentication session drops during editing | Product  | 3   | 5   | 15    | 🔴 CRITICAL | LocalStorage state persistence + E2E test | Dev/QA |
```

Risk control follows the analysis (CTFL v4.0 §5.2.4): **mitigation** carries out the actions that reduce the level, and **monitoring** checks that those actions work, gathers information to improve the assessment, and spots emerging risks. Responses are not only more testing: a risk can also be accepted, transferred, or covered by a contingency plan. Review the register at every progress report (see Test Monitoring and Control below) and re-score a row when its facts change.

### Test Execution Order (CTFL v4.0 §5.1.5)

Once the cases are grouped into suites, say in the plan which ordering each suite uses: **risk-based** (the default for the release gate), **coverage-based** (with its additional coverage variant) or **requirements-based**. **Dependencies** and **resources** available only in a time window override the priority order. Write the resulting order as a numbered list under the release gate table, with the reason wherever a dependency or a resource window moved a case. What each ordering means and when it fits: the `qa-reference` skill's `references/test-planning.md`, "Test Execution Order".

---

## 🚪 Quality Gates (Entry & Exit Criteria)

Entry criteria are the preconditions for starting an activity; exit criteria define what must be achieved to declare it complete. Define both for each test level, as they differ with the test objectives (CTFL v4.0 §5.1.3). Running out of time or budget can also end testing, but only when stakeholders have reviewed and accepted the risk of going live without further testing (CTFL v4.0 §5.1.3).

### The Release Gate: Separate from the Analysis

Every change gets one **release gate**: the smallest set of cases that answers two questions, "do the fixes work?" and "did the change break anything that already worked?". It is usually 5 to 8 cases. The exit criteria below are measured against this set. In CTFL terms the two questions are confirmation testing and regression testing (§2.2.3); scope the second with an impact analysis (the `qa-reference` skill's `references/testing-in-delivery.md`).

- **Build it from risk**: take the cases that cover the changed behavior, plus the neighboring behavior with the highest risk level in the register. A case belongs in the gate only if its failure would stop the release.
- **Show it as one table**: gate cases listed together (ID, what it proves, result), so a reviewer sees in one place what has to pass. Keep it apart from the longer list of analysis cases.
- **The broader analysis is still written down**: exploratory findings, edge cases and extra scenarios are where defects are found, and they are recorded. They do not gate the change.
- **Findings the change did not cause never gate it.** Log each one as its own ticket (see `/qa-defect`) and link it from the plan. A defect that existed before the change stays out of the gate's pass/fail.
- **A failed gate case blocks; a failed analysis case informs.** If an analysis finding turns out to be caused by the change, move its case into the gate and say so in the plan, with the date.

### 1. Entry Criteria for System-Level Test Execution (When to START Testing)

Test analysis, reviews and test design start earlier, at refinement (`/qa-static`, `/qa-bdd`).

- [ ] Feature is fully implemented and state is "Ready for QA" (ADO/JIRA)
- [ ] Code is compiled, built, and merged with zero compilation/linting errors
- [ ] Environment is successfully deployed and accessible
- [ ] Required test data is seeded or generator scripts are ready
- [ ] Target elements have explicit `data-testid` properties per code style rules

### 2. Standard Exit Criteria (When to STOP Testing & Release)

- [ ] Every release gate case executed and passing
- [ ] 100% of P0 test cases executed and passing
- [ ] 100% of P1 test cases executed and passing, or each failure has a recorded Product Owner exception
- [ ] Zero open Critical-severity defects
- [ ] Zero open High-severity defects (or recorded Product Owner exceptions)
- [ ] Smoke regression suite passes on all supported target browsers
- [ ] Test summary signed off by QA Lead and Product Owner

---

## 📈 Test Monitoring, Control & Completion

Monitoring gathers information about testing to judge progress and whether the exit criteria, or the tasks tied to them, are met. Control uses that information to issue corrective directives. Completion collects the experience and testware when a test level, iteration, project or release ends (CTFL v4.0 §5.3).

- **Monitor**: name a few metrics in the plan that answer a decision (CTFL v4.0 §5.3.1): test progress, defect, coverage, risk, project and cost.
- **Control**: when monitoring shows a deviation, record the directive and its reason.
- **Report**: a progress report supports ongoing control; a completion report summarizes a finished level, cycle, iteration or project (CTFL v4.0 §5.3.2). **Report every case's outcome, one case per row**, ending with a "Not run — resume point" section.
- **Complete and look back**: consolidate what was learned at each milestone, and hold a whole-team retrospective (CTFL v4.0 §2.1.6).

Before choosing the metrics, recording a directive, writing a progress or completion report, closing a milestone or running a retrospective, read the `qa-reference` skill's `references/test-reporting.md`: the metrics in each category, the syllabus's example directives, what each report contains, the row format for every case, the completion activities and how to run a retrospective.

---

## 🧱 Suite-Level Artifacts

Beyond the documents of one ticket, a suite that lives longer than a release keeps a master test plan, a risk register, a tagging standard, a traceability matrix (CTFL v4.0 §1.4.4) and a status matrix: each one living document, filterable by suite, with the same fields in every row (`N/A — <why>` when empty). Before building one, read what each holds in the `qa-reference` skill's `references/test-planning.md`, "Suite-Level Artifacts". Build these from the tracker's current state, not from memory of what was tested.

---

## 🧪 Test Data as a Documented Fixture Set

Tests that share an environment depend on records that other people can change. Keep one **fixture set** document, so a test starts from known data and does not disturb shared state:

- **Which records exist**: an identifier and a one-line description for each (never credentials; point to where those are kept).
- **What state each is in**: the state the tests assume, and the state a test must leave it in.
- **What may be changed**: records a test may write to, records it must only read, and records that are off limits. A change to shared state is a write: log it and restore it.
- **How to rebuild**: how to recreate a record that was damaged, or a note that nobody can.

A case's **Precondition** names the fixture it needs. When a fixture is missing or in the wrong state, the case is blocked, not failed.

---

## 🤝 Handover-Ready State

Keep the work in a state someone else could pick up today: an index of what exists, the current status of each item, and a resume point for everything unfinished.

---

## 🗂️ Configuration Management for Testware

Configuration management (CM) identifies, controls and tracks work products such as test plans, test cases, scripts, results, logs and reports as configuration items (CTFL v4.0 §5.4). Item 9 of the plan states how this is done; before writing it, read the checklist in the `qa-reference` skill's `references/test-planning.md`, "Configuration Management for Testware" (identification and version control, references by identifier and version, baselined environments, restorable baselines, CM in a CI/CD pipeline).

Practical check: every result in the plan or report names the build and environment version it was obtained on. A result without that is not reproducible.

---

## 📝 Test Plan Output: Every Field Appears

A test plan describes the test objectives, resources and processes for a test project (CTFL v4.0 §5.1.1). Produce it with every field below, in this order, unless the target repository already has a plan template: in that case its template owns field names and order, and this list only checks that nothing is missing.

1. Context of testing: scope, objectives, test basis
2. Assumptions and constraints
3. Stakeholders: roles, responsibilities, relevance to testing
4. Communication: forms and frequency, document templates
5. Risk register: product and project risks
6. Test approach: levels, types, techniques (see the `qa-reference` skill's `references/testing-design.md`), deliverables, entry and exit criteria, release gate, independence of testing (see Roles and Independence below), metrics to collect, test data and environment requirements, deviations from the test policy and strategy
7. Estimate: technique used, figure with its range, assumptions
8. Budget and schedule
9. Configuration management of testware

(Items 1 to 6 and 8 are the typical content in CTFL v4.0 §5.1.1; items 7 and 9 come from §5.1.4 and §5.4.)

**A field with nothing to put in it stays in the plan** (and in every risk register row and release gate column), written `N/A — <why>`; see the `qa-reference` skill's `references/written-records.md`.

### Roles and Independence (CTFL v4.0 §1.4.5, §1.5.3)

The **test management role** owns the test process, mainly planning, monitoring and control, and completion; the **testing role** owns test analysis, design, implementation and execution. They are roles, not job titles, and one person can hold both. Independence is a matter of degree, set by who tests the work product:

| Degree | Who tests |
| :----- | :-------- |
| None | The author |
| Some | A peer from the author's team |
| High | Testers from outside the author's team, within the organization |
| Very high | Testers from outside the organization |

In item 6, state for each test level who tests, at which degree of independence, and why that degree fits the risk. Before choosing, read who can hold each role, what independence brings, what it can cost and what it does not replace in the `qa-reference` skill's `references/test-planning.md`, "Roles and Independence".

### Corrections

Nothing found wrong in a plan that has been shared is deleted: risk scores that are re-assessed, estimates that are revised, gate cases that move in or out, criteria that change. Correct it in place with a dated note; the format is in the `qa-reference` skill's `references/written-records.md`.
