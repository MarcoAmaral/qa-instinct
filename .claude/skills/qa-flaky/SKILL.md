---
name: qa-flaky
description: "Finds flaky tests from run history and repeat runs, classifies each by cause (test timing, order or shared data, environment, or a real intermittent product defect), quarantines it under the package's flaky-test protocol with an owner and deadline in a ledger, and retires it only with a repeat-run and red-green proof. Use when tests pass and fail on the same code, when asked about flaky, intermittent or quarantined tests, or about retries in CI."
metadata:
  id: qa-flaky
  author: Marco Amaral
---
# Skill: Flaky Tests (detect, classify, quarantine, retire)

> **Senior QA Engineer** | ISTQB CTFL v4.0 (§1.1.2, §1.2.3, §5.5, §6.2) | A quarantine with a ledger, not a graveyard

**If a rule is not loaded.** When a rule this file names is not in your context, load the `qa-rules` skill and read that rule in the skill's own `references` folder. If no `qa-rules` skill is installed either, go on without the rule and say at the end of your reply which rule you could not apply.

The protocol is the `testing-guidelines` rule, section "Flaky Test & Failure Protocols"; this skill applies it and adds nothing that contradicts it. Every number below (the deadline, the share that triggers escalation) is the rule's: read it there, do not restate it from here.

The failure it prevents is **quarantine as a graveyard**: tests tagged `@quarantine`, excluded from every run, never fixed, and the real defect some of them were catching never reported.

A flaky test is one whose verdict changes on unchanged code. The living file is `flaky/ledger.md`; work resumes from it, not from memory.

Files named "the `qa-reference` skill's `references/<file>.md`" are in the `qa-reference` skill's folder, not this skill's: load the `qa-reference` skill and read them there.

## Rules and references this skill reuses

- The `testing-guidelines` rule: the protocol, the optional tags `@flaky` and `@quarantine`, the tag filter syntax (the `qa-reference` skill's `references/testing-design.md`).
- The `qa-reference` skill's `references/automation-ci.md`, "Flakiness Hunting": trace viewer, no sleeps, wait for the response, `--repeat-each` on one spec. Use it for the hunt; this skill does not copy it.
- The `code-style-qa` rule: no hard sleeps, web-first assertions, test isolation, and the red-green proof (the `qa-reference` skill's `references/automation-code.md`, "Pre-Push Verification").
- `/qa-defect` for the report, with the observed frequency ("test 3-5 times before claiming Always").

**Not ISTQB content:** flaky tests, quarantine, retries and flake rate are not in the syllabus (checked 2026-10-14); do not cite it for them. It supports the frame: a failure's cause may be a defect or the environment (§1.2.3), finding it is debugging, then confirmation testing (§1.1.2), a report may turn out not to be a defect (§5.5), and relying on a tool, such as auto-retry, without critical thinking is a listed risk (§6.2).

## Step 1: Detect, from evidence

Never from memory ("that one is always flaky"). Use what the repository exposes, and record **runs, failures and commit** for each suspect:

1. CI history: JUnit XML or the runner's JSON from several runs of the **same commit**. A test with both outcomes is a suspect.
2. The runner's own `flaky` outcome (Playwright: failed, then passed on retry; it shows in the report even when the run is green).
3. A repeat run of the suspect: `npx playwright test <spec> --repeat-each=N`, with `--workers` as in CI.

A test that fails **every** time is not flaky; it is a deterministic failure, list it apart and report it as a defect. Zero failures in N runs bounds the failure rate, it does not prove zero: write "0 failures in N runs".

## Step 2: Classify the cause

One class per test, with the evidence for it:

| Class | Signal | Goes to |
| --- | --- | --- |
| Test timing | Sleep, missing web-first wait, race with the UI | Fix the test |
| Order or shared state | Passes alone, fails in the suite (or the reverse with `--workers=1`) | Fix the test's isolation |
| Test data collision | Fails on a shared environment, passes on a private one | Fix the data setup |
| Environment | Rate limit, slow dependency, resource contention | Environment owner, with the evidence |
| **Product intermittent defect** | Fails with correct waits and isolated data: a race, eventual consistency, caching | `/qa-defect` as a **product** defect with the observed frequency; quarantine alone hides it |

If the class is unknown, say "unknown" and what would decide it. Do not guess.

## Step 3: Quarantine per the rule, and keep the ledger

Follow the rule: tag `@flaky`, open the defect report, move to `@quarantine`. Add one row per test to `flaky/ledger.md`:

| Test ID | Cause class | Defect report | Owner | Quarantined on | Deadline | Status |
| --- | --- | --- | --- | --- | --- | --- |

- **Deadline** is the quarantine date plus the rule's period, in the team's sprint length. A row with no owner or no deadline is not a quarantine.
- **Share**: compute the quarantined count over the runner's test count (`npx playwright test --list`), never estimate it. When it is above the rule's threshold, say so and name who the rule says to escalate to.
- **Exclusion**: `--grep-invert @quarantine` on the `@smoke` and `@regression` jobs. Keep a separate, non-blocking job running the quarantined tests so a fix is visible.
- The skill proposes; the team decides. No script quarantines or deletes on its own.

## Step 4: Exit

A fix counts when both hold, on the fix commit:

1. The spec passes a repeat run of the agreed size (record the command and the output).
2. The spec still **fails when the behaviour it checks is broken** (red-green). A flake "fixed" by a test that can no longer fail is not fixed.

Then remove the tags and mark the row `retired (fixed)`. At the deadline without a fix: delete the test with the reason in the ledger, or extend with a recorded decision and a new deadline. Never close by raising `retries`; retries are for CI noise after the fact, not a fix. Never use self-healing selectors: a test that repairs its own locator can turn a real UI regression into a pass.

## Output discipline

- Say what was run and what was only read. "Not flaky" or "fixed" without this run's output is a guess.
- List deterministic failures separately from flakes.
- Never present a seeded flake (one introduced on purpose to show the steps) as a found one.
- State what the history cannot show: runs nobody kept, and causes outside the repository.
