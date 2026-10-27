# Declarative Testing Rules & Guidelines

> **Aligned with ISTQB CTFL v4.0 (syllabus v4.0.1)** | Standards & Tagging Taxonomy | Release Gate Policies

This ruleset governs all QA processes, test design methodologies, tagging conventions, and CI/CD pipelines. AI agents must apply these rules to enforce testing rigor and suite organization. A section that cites a syllabus section restates the syllabus; the rest (strategic alignment, tagging, failure protocols) is this package's practice.

---

## 7 Core Testing Principles (ISTQB CTFL v4.0, §1.3)

Always design and evaluate testing strategies according to these 7 principles:

1. **Testing shows the presence of defects, not their absence**: Testing reduces the probability of undiscovered defects but is not a proof of correctness.
2. **Exhaustive testing is impossible**: testing everything is not feasible except in trivial cases. Use risk analysis, test techniques and priorities to focus the effort.
3. **Early testing saves time and money**: Shift-left testing (reviews, static analysis, unit tests) finds defects early when they are cheapest to fix.
4. **Defects cluster**: a small number of components usually contain most of the defects found. Use that to predict and focus testing on high-risk, high-complexity components.
5. **Tests wear out** (formerly called the pesticide paradox): repeated tests become increasingly ineffective at finding defects, though repetition can still help (e.g. automated regression). Review and update tests, and add new ones.
6. **Testing is context-dependent**: A safety-critical system, a data pipeline, and an e-commerce website require completely different testing approaches.
7. **Absence-of-defects fallacy**: fixing all defects may still produce a system that does not fulfil users' needs. Validate it against those needs as well.

---

## Testing, Quality Assurance, and the Defect Chain

### Testing vs. quality assurance (CTFL v4.0 §1.2.2)

- **Testing** is product-oriented and corrective: it examines the thing built and finds what is wrong with it. It is a major form of quality control (QC).
- **Quality assurance (QA)** is process-oriented and preventive: it improves how work is done so fewer defects are made. It is the responsibility of everyone on the project, not only the test team.
- The same test results serve both: testing uses them to get defects fixed; QA uses them as feedback on how well the development and test processes perform. When a result points at a recurring pattern rather than a single defect, route it to the process, not only to the fix.

### Errors, defects, failures, root causes (CTFL v4.0 §1.2.3)

A human **error** (mistake) produces a **defect** (fault, bug) in a work product; executing the defect may cause a **failure**; the **root cause** is the fundamental reason behind the problem. Not every failure has a defect behind it (environmental conditions can cause one), and not every defect ever fails.

How to use the distinction:

- A defect report describes the **failure** (what was observed, versus what was expected) and, when known, the **defect** (where it lives). Do not present a guess about the defect as the observation.
- Defects in earlier work products (requirements, designs) propagate into later ones; say so when the defect is found in a requirement, not only in code.
- Root-cause analysis targets the **error** and the situation that led to it (time pressure, ambiguous requirement, missing review), because removing that is what prevents similar defects.

---

## 🎯 Strategic QA Alignment

### Expected Gain Validation

QA must shift from merely "Validating ACs" to "Validating Expected Outcomes". Often, Acceptance Criteria are technically met, but the feature fails to deliver the expected business value. If the AC is met but the feature is unusable or fails its business purpose, the test must **fail**.

### Trade-off Analysis

When developers make trade-offs (e.g., sacrificing load speed for faster delivery, or skipping a data validation layer), QA must explicitly test the boundaries of that degraded performance and document it in the risk register. QA does not blindly accept trade-offs; QA tests them.

---

## Test Design Reference (Read on Demand)

The adaptive test pyramid, coverage targets, mocking matrix, the localhost dry-run rule, the ISTQB test design techniques (EP, BVA, decision tables, state transition, error guessing, exploratory), field heuristics and the CI/CD tag-filter syntax live in the `qa-reference` skill's `references/testing-design.md`. Read it before choosing test levels or techniques, or writing a tag filter.

---

## Test Tagging Taxonomy

Every automated and manual test case must carry **one tag from each of the first four categories** to support precise filtering in CI/CD pipelines.

### 1. Suite Tags (When to Run)

- `@smoke`: Critical path – must pass. Run on every Merge Request and post-deployment. Target duration: **<10 mins**. Block-level release gate.
- `@sanity`: Quick post-deployment check on environment promotion. Target duration: **<20 mins**.
- `@regression`: Re-run after changes to catch unintended side effects (CTFL §2.2.3); usually nightly or pre-release. Target duration: **1–2 hours**.

### 2. Level Tags (How to Run)

- `@unit`: Fast, memory-only tests of pure functions (e.g., Vitest). Target: **<100ms** per test.
- `@integration`: Mocked API/subsystem integrations (e.g., React Testing Library). Target: **<1s** per test.
- `@e2e`: Full browser and live system testing (e.g., Playwright). Target: **5–30s** per test.
- `@api`: Direct REST API request testing (e.g., request fixtures). Target: **<2s** per test.
- `@manual`: Human-executed tests. Used for complex visual, UX, and accessibility assessments.

### 3. Priority Tags (Business Impact)

- `@p0` (Critical): System unusable if failing. **Must pass (100% gate)**.
- `@p1` (High): Major functionality broken, no workaround. Release blocker.
- `@p2` (Medium): Core features work, but secondary options fail with workaround. Fix in normal cycle.
- `@p3` (Low): Cosmetic or minor usability bugs. Logged and scheduled in backlog.

### 4. Automation Status Tags

- `@automated`: Implemented in automation suite.
- `@candidate`: Highly recommended for automation based on ROI scoring.
- `@manual-only`: Automation impractical or impossible (e.g., hardware interaction, subjective UX).
- `@deferred`: Valid case postponed; not run in this cycle.

### 5. Feature Tags (What Is Tested)

Recommended. Define these tags based on your project modules (e.g., `@auth`, `@editing`, `@search`, `@a11y`).

### 6. Optional Tags

`@flaky`, `@quarantine` (see the protocol below), `@slow`, `@gate` (a release-gate case).

---

## Flaky Test & Failure Protocols

1. **Smoke Failures**: **STOP LINE**. Block the Merge Request or Deployment immediately. Dev and QA must resolve.
2. **P0/P1 Failures**: Release block. No code promotes to Production until resolved or formal exception approved by PO.
3. **Flaky Test Quarantine**:
    - Identify flaky test → Tag with `@flaky` and open a Defect Report.
    - Move test to `@quarantine` immediately (excludes it from `@smoke` and `@regression` runners).
    - Resolve or delete the test within **2 sprints**.
    - If more than 5% of the suite is quarantined, escalate to the Development Lead.

---

## 🛑 Definition of Done: QA's Contribution

Adopt the team's own DoD; where it is silent, QA checks these before a ticket closes (the DoD is a story's exit criteria, CTFL §5.1.3):

1. **Automated Tests**: Unit/Integration tests are written, passed, and mapped to the CI pipeline.
2. **No open Critical/High-severity defects** (or a recorded PO exception).
3. **NFRs that apply to this change are validated** (e.g. security scan; accessibility and Lighthouse for web UI).
4. **Code Reviewed**: Static analysis and peer review completed.
