---
name: qa-api
description: "Tests REST and GraphQL APIs against their contract: finds the OpenAPI or GraphQL schema, designs per-endpoint tests with equivalence partitions, boundaries and resource state transitions, checks real responses (bodies and errors, not only status codes) for schema conformance, and recommends schema checks or consumer-driven contract tests. Use when asked to test an API, an endpoint, a contract, an OpenAPI or GraphQL schema, or to write API tests."
metadata:
  id: qa-api
  author: Marco Amaral
---
# Skill: API Testing (REST and GraphQL, contract and conformance)

> **Senior QA Engineer** | ISTQB CTFL v4.0 (§2.2.1, §2.2.2, §4.2.1, §4.2.2, §4.2.4, §5.1.7, §1.4.3) | Contract first, then design, then evidence

**If a rule is not loaded.** When a rule this file names is not in your context, load the `qa-rules` skill and read that rule in the skill's own `references` folder. If no `qa-rules` skill is installed either, go on without the rule and say at the end of your reply which rule you could not apply.

This skill is activated when a request is to test an API, an endpoint or a GraphQL operation, to check a response against its contract, or to write API tests. Each step leaves a file under `api-tests/`, so work resumes from disk.

Reviewing a schema **without running anything** is `/qa-static`. This skill sends requests.

The failure it prevents is **a green API suite that asserts status codes only**: a renamed field, a wrong type or an error with the wrong shape passes every test.

Files named "the `qa-reference` skill's `references/<file>.md`" are in the `qa-reference` skill's folder, not this skill's: load the `qa-reference` skill and read them there.

## Rules this skill reuses (read them; do not restate them here)

- The `context-discovery` rule: the schema is Tier 1 ground truth for what the API is *declared* to do, the running service for what it *does*. Say which build you confirmed from its deployment record or version endpoint.
- The `testing-guidelines` rule: the `@api` level tag, suite, priority and automation tags. Techniques and level mapping: the `qa-reference` skill's `references/testing-design.md`.
- The `code-style-qa` rule: AAA, no sleeps, test isolation, no assertions in helpers. Detail: the `qa-reference` skill's `references/automation-code.md`.
- The `security-qa` rule: object-level authorization, role escalation and CSRF checks. Detail: the `qa-reference` skill's `references/security-checks.md`. Do not re-derive them here.
- The `test-tools` rule: choose the activity and tool category before any tool name (below, step 5).
- The `test-evidence` rule: run the package's `check-test-evidence.sh <spec-dir>` on the specs (installed in `.claude/hooks/`; if absent, say it was not run).

## Principles

1. **Assert the body, not only the status.** Every test validates the response body against the contract's schema for that status, error bodies included. A 400 with the wrong error shape is a failure.
2. **A mismatch is a finding, not a test to adjust.** When the schema says X and the API does Y, record both, classify as **documentation drift** or **software defect** (the `context-discovery` rule: Tier 1 wins for what the system currently does, and the conflict is reported), and do not change the test until the owner decides.
3. **Test the positive half too** (the `qa-reference` skill's `references/testing-design.md`, Field Heuristics). A validation that rejects everything passes every negative test.
4. **Black-box, interface level.** The contract is the documentation functional black-box tests derive from (CTFL v4.0 §2.2.2). They run at system or system integration level (§2.2.1), so a shared instance is a constraint.
5. **Not ISTQB content:** contract testing, consumer-driven contracts, schema validation, GraphQL and idempotency are good practice, not syllabus text. Do not cite CTFL for them.

## The five steps

| Step | Output | Notes |
| --- | --- | --- |
| 1. Find the contract | `api-tests/contract.md` | Read-only |
| 2. Design | `api-tests/design.md` | Per endpoint or operation |
| 3. Check conformance | `api-tests/conformance.md` | Sends requests: see "Shared environments" |
| 4. Automate | Specs and helpers | Only what steps 2 and 3 justify |
| 5. Choose a contract strategy | One paragraph in `design.md` | Recommendation, with reasons |

### Step 1: Find the contract

Record in `api-tests/contract.md`: where the contract lives (OpenAPI document, GraphQL SDL or introspection, protobuf, or none); its URL or path, version and the date fetched; the **deployed version under test** and how it was confirmed; the auth model (none, API key, bearer token, session); the base URL and what environment it is. No contract exists: say so, derive one from observed behaviour and mark it as an assumption; conformance (step 3) then reports behaviour only, since a derived contract cannot reveal drift.

### Step 2: Design per endpoint or operation

In `api-tests/design.md`, for each endpoint (or GraphQL operation), using the techniques in the `qa-reference` skill's `references/testing-design.md`:

- **Partitions and boundaries per field** (CTFL v4.0 §4.2.1, §4.2.2): valid and invalid partitions of each parameter and body field, including wrong JSON type, missing, null, empty and over-long; the limits the schema declares, and the ones it fails to declare.
- **Resource state model** (§4.2.4): the lifecycle as states and events (create, read, update, delete, complete, cancel), including **invalid transitions** (delete twice, update after delete, complete an empty cart). Each transition names the status and body expected.
- **Auth matrix**: each endpoint against no token, an expired token, another user's resource and the wrong role.
- **Error contract**: which statuses the schema documents, the body shape of each, and which statuses it leaves out.
- **Idempotency and retries**: repeating `PUT` or `DELETE` leaves the same state; a `POST` retried by a client does not duplicate. If the API does not promise this, say that, and test what it does.
- **Tags** from the `testing-guidelines` rule: `@api` plus suite, priority and automation status.

Each case names the acceptance criterion it checks (API testing is a Q2 test, CTFL v4.0 §5.1.7).

### Step 3: Check conformance

For a sample of real responses (every endpoint and every documented status, not only the happy path), validate the **body** against the declared schema for that status and record each result in `api-tests/conformance.md`. A mismatch row has: the request, the declared schema location, the actual response, **classification** (documentation drift or software defect, per principle 2), and the proposed owner. Mismatches that are software defects go to `/qa-defect`; drift goes back to whoever owns the document.

Check also what the schema does **not** say: an undocumented status, an extra response field, a field returned as another type, an error body of another shape.

### Step 4: Automate

Write specs with the runner's HTTP client: the Playwright `request` fixture when the repository uses Playwright, the framework's own client otherwise. API-specific structure only; everything else follows the `code-style-qa` rule.

- A helper class holds **actions** (one method per endpoint) and no assertions. Assertions sit in the spec.
- Each spec asserts status **and** body against the contract. Load the schema once, and validate through it, so the contract and the tests cannot drift apart silently.
- Each test creates its data and deletes it, even on failure.
- A new assertion is proven sensitive before it counts: change the expected value or schema in a throwaway copy, watch the test fail for the expected reason, and keep that output (see "Red-Green Proof" in the `qa-reference` skill's `references/automation-code.md`).
- Run the evidence checker on the spec directory.

### Step 5: Choose a contract strategy

One paragraph in `design.md`: **schema conformance checks are enough**, or **consumer-driven contract tests are justified**, and why. Follow the `test-tools` rule's order: activity and category first, then the tool.

- Schema conformance (step 3, kept running in CI) is the cheaper first activity: it needs only the provider's schema and a place to send requests.
- Consumer-driven contracts (a contract written by each consumer, verified against the provider, shared through a broker or file) are justified when **several independently released consumers** depend on one provider, the provider team cannot see or test those consumers, and breaking changes have already reached them. They cost both teams a process, a provider-side verification step and a broker owner. If those conditions do not hold, say so and recommend schema checks.
- When a provider is simulated in tests, the simulator is test environment (stubs, drivers, simulators and service virtualization are testware, CTFL v4.0 §1.4.3). It proves the consumer, never the provider.

## REST specifics

- Error bodies often have more than one shape (business rule versus validation). Document each, and test each.
- A schema with no `minimum`, `maxLength` or `enum` declares no boundary: probe for the real one and record it as observed.

## GraphQL specifics

- Errors usually arrive with HTTP `200` and an `errors` array, so a status-only assertion is vacuous (a gateway may answer `400` to unparseable requests: record what the service does). Assert that `errors` is absent for success cases and has the expected `message` and `path` for failure cases.
- A response may hold partial `data` **and** `errors` together. Test which fields are null and why.
- Nullability comes from the SDL (`!`). A non-null field returned as `null` is a conformance mismatch.
- Validate each query against the SDL before sending it: a typo in a field name is the tester's error, not a finding. Introspection disabled in production is a hardening choice, not a defect.
- If the server declares a depth, complexity or rate limit, test one request just inside and one just outside it. When it declares none, say so; do not invent a limit.

## Shared environments

- Read-only requests, or data **you** created with a unique name and deleted afterwards. Never write to a record the team marks read-only (the fixture-set section of the `qa-plan` skill).
- Check afterwards, through the API, that nothing you created is left.
- Probe boundaries with bounded, non-destructive inputs. Load and fuzzing volume are other activities.
- A shared instance changes under you: date every claim about live behaviour.

## Output discipline

- Say what was **run** and what was only read. "Conforms" without this run's responses is a guess; see "Pre-Push Verification" in the `qa-reference` skill's `references/automation-code.md`.
- State what the suite cannot show: operations not exercised, statuses never triggered, GraphQL if only REST was run.
- Commits are atomic and conventional: contract and design, conformance and each group of specs are separate.
