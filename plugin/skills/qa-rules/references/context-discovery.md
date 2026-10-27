# Dynamic Context Discovery Rules & Guidelines

> **Ground Truth Before Test Design** | Codebase Search | Contradiction Disclosure

This ruleset governs what the AI must do, in a target/consuming repository, before designing
test cases, BDD scenarios, automation, or TDD tests. A test that is ISTQB-correct but ungrounded
in how the system under test actually behaves is a well-formed false positive: it will pass
review and catch nothing. Apply this rule before applying the test design techniques in
the `testing-guidelines` rule or the code patterns in the `code-style-qa` rule —
those assume the *what* is already known; this rule is how the AI finds it.

---

## 🔍 Search Order (Highest Confidence First)

Search top-down and stop once the behavior in question is confirmed by a source at or above
**Tier 2** — do not exhaustively read every file in a large repo; that is the documentation
equivalent of exhaustive testing, which this package already rejects (CTFL §1.3,
principle 2; the `testing-guidelines` rule).

1. **Executable truth**: existing test files, fixtures/mocks, and snapshots for the feature;
   OpenAPI/GraphQL/proto schemas; type definitions and DB migrations. These are enforced by a
   compiler or test runner, so they cannot silently go stale.
2. **Configuration & contracts**: feature flags, environment config, CI pipeline definitions.
   These show what is actually enabled and deployed, not just planned.
3. **Declared intent**: `plan.md`, `architecture.md`, `docs/`, ADRs, `README.md`,
   `CONTRIBUTING.md`, a spec directory such as `.specify/`, feature-area knowledge files. Useful for *why*, but unenforced — nothing stops these from drifting out
   of date.
4. **Historical record**: linked tickets, PR descriptions, `CHANGELOG.md`. Explains past
   decisions; treat as background, not current state. What was *tested*: the tracker beats docs.

If everything relevant fits in context, read all four tiers. The priority order exists for
triage in large repos, not as permission to skip lower tiers when time allows. How to read each
source: the `qa-reference` skill's `references/context-sources.md`.

**Deployed state is its own source.** When a test depends on *which version an environment runs*,
read that environment's **deployment record** (the deploy log, release tag, build metadata or
version endpoint) — not the branch name. A branch called `staging` may track the release line
rather than what the staging environment actually runs. Treat the deployment record as a Tier 1/2
source for the question "what is under test", and say which build you confirmed.

---

## ⚠️ When Context Is Missing or Contradicts the Ticket

Never silently guess, and never silently pick a side.

- **Code and docs disagree**: Tier 1 wins for what the system *currently* does. State the
  conflict in the output instead of quietly following the code and dropping the doc's claim —
  treat it as a documentation-drift finding, not a reason to distrust the code.
- **No context found at all**: Say so, and mark every resulting assumption as an assumption —
  in a test case's `Note` field, a BDD scenario comment, or a short preamble. An unmarked
  assumption inside a `Precondition` or `Expected` field is a fabrication, not a shortcut.
- **Never stall on a missing knowledge base**: a target repo may have no `docs/` at all. Do not
  ask the user to create one first — proceed from what can be verified and disclose the gap.
- **Before asking anyone**: follow "Before You Ask" in the `qa-reference` skill's `references/context-sources.md`.

---

## 🧩 Derive, Don't Override

When the target repository already has a **schema** for an artifact — a tool's field contract, a
template the team uses for test cases, defects or plans — then:

- **The schema owns** field names, field order and allowed values.
- **This package's rules own** how the content of each field is produced: grounded in the code,
  traced to a requirement, free of unmarked assumptions.
- **Neither rewrites the other.** Do not rename a team's fields to match this package, and do not
  drop a rule because the schema has no slot for it.
- **On a genuine conflict**, say so and ask. A conflict is a field the schema forbids or cannot
  hold that a rule here requires (or the reverse) — not a difference in wording.

The `linting-standards` rule applies the same idiom to lint configuration.

**A target platform's publishing constraints are a field contract too.** Limits on table width,
image size or accepted characters belong to the platform, not to this package. Write them down
**once, in the template** the team generates from, so every document inherits them instead of
rediscovering them one failed upload at a time. Publish: lint, review, build, verify
(the `qa-reference` skill's `references/context-sources.md`). The one constraint worth stating for every
platform: **evidence and attachment file names are ASCII-only** — see the
`test-evidence` rule.

---

## 🎯 Scope of This Rule

This governs every entry point that produces tests: the single-agent commands (`/qa-cases`,
`/qa-bdd`, `/qa-automate`, `/qa-tdd`, `/qa-static`, `/qa-trace`) and Stage 1 (`qa-groomer`) of the `/qa-agentic` pipeline.
Stages 2 and 3 (`qa-designer`, `qa-writer`) intentionally do not repeat this search — the
pipeline's traceability rule restricts them to reading only the previous stage's output file, so
context discovery happens once, at the point the ticket first becomes requirements.
