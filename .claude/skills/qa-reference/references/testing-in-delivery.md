---
id: ref-testing-in-delivery
---
# Testing in Delivery Reference

> **Read on demand** | Testing across the delivery lifecycle | Part of the `qa-reference` skill

Read this when deciding what testing a change needs after a fix or an enhancement, when a system already in operation is changed, migrated or retired, or when planning the testing that belongs in a DevOps pipeline. It holds testing across the delivery lifecycle: how testing changes under DevOps and shift-left, what confirmation and regression testing each prove, how to scope maintenance testing, what CI has to be before its results mean anything, what to do when the main build breaks, where the release gate sits under continuous delivery and continuous deployment, how to test code behind feature flags, and when a canary release or an A/B experiment can be trusted.

---

## DevOps, Shift-Left and Testing (CTFL v4.0 §2.1.4, §2.1.5)

DevOps brings development, testing included, and operations together around shared goals. It relies on team autonomy, fast feedback, integrated toolchains and practices such as continuous integration (CI) and continuous delivery (CD), so that code is built, tested and released through a delivery pipeline. It takes a cultural shift that treats development and operations as equally valuable.

What DevOps gives testing:

- Fast feedback on the quality of each change, and on whether it breaks existing code.
- Pressure to shift left: CI encourages developers to submit code together with its component tests and with static analysis already run.
- Stable test environments, which automated CI/CD processes make easier to establish.
- More visibility of non-functional characteristics, such as performance efficiency and reliability.
- Less repetitive manual testing, since the pipeline runs the automated checks.
- Lower regression risk, from the scale and range of the automated regression tests.

What it costs:

- The delivery pipeline has to be defined and set up.
- CI/CD tools have to be introduced and maintained.
- Test automation needs extra resources, and can be hard to establish and to keep working.

A pipeline full of automated tests does not remove manual testing: testing from the user's perspective is still needed (the `qa-explore` skill). And a pipeline's results are only as good as the practice behind it: see "CI: Preconditions" and "When the Main Build Breaks" below.

**Shift-left** is the early-testing principle (principle 3 in the `testing-guidelines` rule) applied to the lifecycle: test earlier, without dropping the testing that comes later. The practices the syllabus names, and where this package supports each:

| Practice | In this package |
| :------- | :-------------- |
| Review the specification as a tester, to catch ambiguity, gaps and contradictions before code exists | `/qa-static` |
| Write test cases before the code, and run the code in a test harness while it is written | `/qa-tdd`, `/qa-bdd` |
| Use CI, better still CD, with automated component tests submitted alongside the code | What CI requires: "CI: Preconditions" below; the pipeline: the `qa-reference` skill's `references/automation-ci.md` |
| Run static analysis on the source before dynamic testing, or as part of the automated process | Static analysis tools in the `qa-reference` skill's `references/test-tools.md`; triage of what they report: the `qa-static-analysis` skill |
| Start non-functional testing at the component level where possible, instead of waiting for a complete system | Not covered yet as guidance; the test types table in the `qa-reference` skill's `references/testing-design.md` shows which characteristics the package covers |

Shift-left costs training, effort or money early, in exchange for saving more later, and it needs the stakeholders to be convinced and committed to it.

---

## Confirmation and Regression Testing (CTFL v4.0 §2.2.3)

A change, whether it adds a feature or removes a defect, calls for two kinds of testing.

**Confirmation testing** shows that the original defect is fixed. Depending on the risk, choose one of these, from most to least thorough:

- run every test that failed because of the defect, and add tests for any code the fix had to change;
- run every test that failed because of the defect;
- when time or money is short, repeat the steps that reproduced the failure and check that it no longer occurs.

The person who ran the original test is the best one to confirm the fix (CTFL v4.0 §1.1.2).

**Regression testing** shows that the change, a confirmed fix included, caused no harm elsewhere: in the same component, in other components of the system, in connected systems, or in the environment.

- **Scope it with an impact analysis first**: it shows which parts of the software the change could affect, and so how far the regression testing has to reach.
- **Expect the suite to grow.** A regression suite runs many times and gains cases with every iteration or release, which makes it a strong candidate for automation, started early in the project. Where CI exists, the pipeline runs it.
- **Test at every level that changed.** Confirmation and regression testing are needed at each test level where a defect was fixed or a change was made.

How this maps to the package:

- The release gate in the `qa-plan` skill asks both questions. "Do the fixes work?" is confirmation testing; "did the change break anything that already worked?" is regression testing.
- `@regression` and `@smoke` are suite tags in the `testing-guidelines` rule: they say when a case runs. They are not test types. A case is a regression test because it re-checks existing behavior after a change.
- In a defect report (`/qa-defect`), the `Retest` status means awaiting confirmation testing, and the retest criteria the report recommends are that confirmation test.

---

## Maintenance Testing (CTFL v4.0 §2.3)

Maintenance changes a system already in operation. The change can be corrective, adaptive to a changed environment, or made to improve performance or maintainability, and it can arrive in a planned release or as an unplanned hot fix. An impact analysis can come before the change, to decide whether to make it at all given its consequences elsewhere in the system.

Testing such a change checks two things: that the change was implemented successfully, and that the parts left unchanged, usually most of the system, still work (regression testing, above).

Size the testing by three factors:

- the risk of the change;
- the size of the existing system;
- the size of the change.

What triggers maintenance testing:

- **Modification**: planned enhancements shipped in a release, corrective changes, hot fixes.
- **Upgrade or migration of the operational environment**, such as a move from one platform to another: test the new environment as well as the changed software, and test data conversion when data from another application is migrated into the system.
- **Retirement** at the end of the system's life: test data archiving when data must be kept for a long time, and the restore and retrieval procedures in case archived data is needed during that period.

The `qa-migrate` skill applies the same logic to a test suite moving to Playwright: the old suite keeps running as the regression suite until the new one proves it covers the same ground. That is a change to the testware, not to the operational environment, so it follows the principle without being one of the triggers above.

---

## CI: Preconditions (Valente, section 10.3)

A CI result means something only when the practice behind it is in place (Valente, *Engenharia de Software Moderna*, section 10.3). Check these before trusting a pipeline's green, or before planning testing around one:

- **The build is automated end to end**: from a clean checkout to a tested artefact with no manual step. A step someone does by hand is a step that can differ between runs.
- **The build is fast enough to run on every integration.** When it takes longer than people will wait, they stop waiting for it. Keep the stage that runs on every push within the `@smoke` target in the `testing-guidelines` rule (under 10 minutes), and move slower suites to a scheduled run.
- **Automated tests run in it**, at the levels that give quick feedback: unit and component integration tests on every push, slower levels on a schedule, selected by tag (the `qa-reference` skill's `references/testing-design.md`, "CI/CD Pipeline & Filtering Reference").
- **Everyone integrates into the main line at least daily.** That is what makes integration continuous. A long-lived feature branch that a server builds on every push is continuous building, not continuous integration: its integration problems are only postponed to the merge. Branches that live less than a day are compatible with CI, and trunk-based development, where work goes straight to the main line with unfinished parts behind a feature flag, is its usual companion. The daily bar is the practice's own; the book treats it as a guideline a team may adapt to its context, not a law.

What this means for testing:

- **The CI run is the result.** A pass on a developer's or tester's machine is a feasibility check ("Localhost Is a Dry Run, Never a Result" in the `qa-reference` skill's `references/testing-design.md`); the run recorded against the commit is what counts.
- **Green locally and red in CI usually means CI built something else**: a file that was never committed, or a dependency that resolved to a different version. Commit the lockfile and install with `npm ci` (or the stack's equivalent) in the pipeline, so CI builds exactly the versions that were tested.
- **The pipeline itself** is in the `qa-reference` skill's `references/automation-ci.md`, with a nightly regression job; this section adds no YAML.

---

## When the Main Build Breaks (Valente, section 10.3)

A broken main build stops everyone who integrates after it. The STOP LINE in the `testing-guidelines` rule (a failing smoke suite blocks the merge or the deployment) covers the gate; the same priority applies to the main line itself:

- **Fixing it comes first**, before any new work, for whoever broke it. Reverting the commit that broke it is a legitimate fix and often the fastest; the change comes back once it passes.
- **Whoever pushes waits for the CI result** before moving on to the next task, so the person with the context is the one who fixes a break.
- **QA does not start a test session on a build that has not passed CI.** Results from a build that failed its own checks can be neither compared nor reproduced. Record which build was tested (commit and pipeline run), and confirm what the environment runs from its deployment record ("Field Heuristics" in the `qa-reference` skill's `references/testing-design.md`).

---

## Delivery or Deployment: Where the Release Gate Sits (Valente, section 10.4)

The two practices share the initials CD and differ in one decision (Valente, *Engenharia de Software Moderna*, section 10.4):

- **Continuous delivery** keeps every change that passes the pipeline releasable, and leaves the release itself to a decision: a person, or a business reason, chooses when it goes out.
- **Continuous deployment** releases every change that passes the pipeline, with no one deciding. It suits software the team updates for its users, such as a web application; software users install themselves (desktop, mobile, embedded) usually stays with delivery.

The consequence for the release gate in the `qa-plan` skill ("The Release Gate: Separate from the Analysis"):

- **Under continuous deployment, the pipeline is the release gate.** Every gate case must be automated, tagged `@gate`, and run in a pipeline stage before the release step. A gate case only a person can run cannot gate: automate it, or hold that change for a manual decision, which makes it continuous delivery for that change.
- **Under continuous delivery, the gate's evidence goes to the person who decides**: what passed, what failed, what was not run, and the risks still open, so the release decision is made on the record rather than on a green badge.
- **Either way, run the `@sanity` suite after the release**, against the environment it reached.

---

## Feature Flags (Valente, section 10.4)

A feature flag lets code reach the main line, and production, switched off until it is ready, so integration stays continuous while the feature is unfinished (Valente, *Engenharia de Software Moderna*, section 10.4). For testing, every flag doubles the paths through the code it guards:

- **Test both states, and treat off as the state production runs today.** With the flag off, the system must behave exactly as before the change; that is where a flagged change most often breaks something already working. With the flag on, test the new behaviour as any other change.
- **Several flags that interact form a decision table**, one condition per flag (Decision Table Testing in the `qa-reference` skill's `references/testing-design.md`). Test the combinations that can occur together in an environment, chosen by risk, rather than every combination.
- **Record the flag states** in each test case's preconditions and in the defect report's environment (`/qa-defect`). A result without its flag states cannot be reproduced.
- **Read each environment's flag values from that environment**: its flag service, configuration or admin screen. The default in the code only says what happens when nothing is set.
- **Removing a flag is a change, and gets regression testing** like any other ("Confirmation and Regression Testing" above): the off path and the flag check are deleted, and the code that remains must still do what the on state did.
- **Report stale flags as debt.** A release flag that has been on everywhere for a long time keeps an untested off path alive. Flags meant to stay, such as one that enables a feature only in the regions where it is allowed, are product configuration: test each value as a variant, and they are not stale.

---

## Canary Releases and A/B Experiments (Valente, sections 10.4 and 3.6)

Both expose a change to real users on purpose, and both are only as trustworthy as the conditions they run under.

**A canary release** gives the change to a small share of users first, then widens it step by step (Valente, *Engenharia de Software Moderna*, section 10.4). It limits the damage of a defect that testing missed; it replaces none of the testing. Before it starts, write down:

- the health signals watched, such as the error rate, the response time and the business event the feature exists for;
- the threshold on those signals that halts the rollout;
- the rollback, and who triggers it.

**An A/B experiment** gives different variants to separate groups of users to learn which one better reaches a goal (Valente, section 3.6). Its result means something only when:

- **users are assigned at random**, and each user stays in the same variant on every visit;
- **one success metric is chosen before it starts**, together with the rule that will decide the winner;
- **the sample size is computed before it starts**, from the current rate of the metric, the smallest improvement worth detecting and the confidence wanted, and the experiment runs until it reaches that size. Stopping as soon as one variant looks ahead is a classic error: early differences are often noise;
- **an A/A run comes first**, with the same variant in both groups. If it declares a winner, assignment or measurement is broken; fix that before any A/B run.

More than two variants can be compared at once, at the cost of a larger sample. A product with few users may never reach the sample an experiment needs: say so, and do not report the difference it shows as a result.

**What QA tests is the experiment itself**, before it starts:

- assignment is random, follows the planned proportions, and does not change for a user between sessions;
- every variant works end to end, since each one is a release candidate;
- the events behind the metric fire once per action, in every variant, labelled with the variant;
- the flag or router sends each user to the variant recorded for that user (see "Feature Flags" above).
