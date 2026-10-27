---
name: qa-migrate
description: "Migrates an existing Cypress or Selenium WebDriver test suite to Playwright incrementally, with both suites running until a parity table shows the new one covers the old. Assesses the suite, maps commands, waits, intercepts, fixtures and page objects to Playwright idioms, and handles flaky tests. Use when asked to migrate, port or switch end-to-end tests to Playwright."
metadata:
  id: qa-migrate
  author: Marco Amaral
---
# Skill: Test Suite Migration (Cypress / Selenium to Playwright)

> **Senior QA Engineer** | ISTQB CTFL v4.0 (§2.2.3, §2.3, §1.4.3, §1.4.4, §6.2) | Incremental migration with a parity gate

**If a rule is not loaded.** When a rule this file names is not in your context, load the `qa-rules` skill and read that rule in the skill's own `references` folder. If no `qa-rules` skill is installed either, go on without the rule and say at the end of your reply which rule you could not apply.

This skill is activated when a request is to move, port or switch an existing end-to-end suite to Playwright. It is a multi-session workflow: each phase leaves a file under `migration/`, so work resumes from disk, not from memory.

The failure it prevents is **silent coverage loss**: twenty old tests become fifteen new ones, a flaky test is copied faithfully as a flaky test, and the old suite is deleted before the new one has proven anything.

Sources: Cypress and Selenium (any language binding). Target: Playwright Test. There is no official Playwright guide for either source (`playwright.dev/docs/cypress` and `/docs/selenium` do not exist, checked 2026-10-08); the tables below rest on Playwright's reference pages for locators, assertions, network, mocking, authentication and fixtures. The Cypress path is exercised end to end in `examples/todomvc-cypress-to-playwright/`; the Selenium rows were exercised on a purpose-written suite whose old tests could not be run, so they are less proven.

Files named "the `qa-reference` skill's `references/<file>.md`" are in the `qa-reference` skill's folder, not this skill's: load the `qa-reference` skill and read them there.

## Rules this skill reuses (read them; do not restate them here)

- The `code-style-qa` rule: locator order, AAA, Page Object Model with no assertions, web-first assertions, no hard sleeps, test isolation. Detail in the `qa-reference` skill's `references/automation-code.md`.
- The `context-discovery` rule: phase 1 finds the old suite's real behaviour and the app's real selectors. No selector is invented.
- The `testing-guidelines` rule: tags (`@smoke`, `@p0` ...) carry over to the new specs; its quarantine protocol is the route for flaky tests.
- The `test-evidence` rule: any side-by-side screenshots or recordings of old and new runs follow it; run the package's `check-test-evidence.sh <spec-dir>` on the migrated specs (a Claude Code install puts it in `.claude/hooks/`; when it is not installed, apply its checks by reading the specs and say that the checker was not run).

## Principles

1. **Incremental, never big-bang.** The old suite keeps running until the parity gate passes. This is the logic of regression testing: a regression suite is kept and trusted until something proven replaces it (CTFL v4.0 §2.2.3), and a change is checked for both the change and regressions in what did not change (§2.3).
2. **Re-derive, do not line-translate.** Ask what each test is meant to verify and write that in Playwright idiom. A literal translation carries over bad waits, fragile selectors and flakiness.
3. **The suite is testware** (CTFL v4.0 §1.4.3). The old tests, fixtures and page objects are being replaced, and the **parity table is traceability** from old test to new test (§1.4.4). A dropped test needs a recorded reason.
4. **Migrating the tool is itself a tool decision**, with the risks CTFL v4.0 §6.2 lists for test automation: unrealistic expectations, inaccurate effort estimates, over-reliance on a tool, open-source dependency. Put them in the assessment's risk list.
5. **Not ISTQB content:** flakiness handling, framework-to-framework migration and the mutation check are good practice from the sources in this skill. The syllabus does not cover them; do not cite it for them.

## The six phases

| Phase | Output | Notes |
| --- | --- | --- |
| 1. Assess | `migration/assessment.md` | Read-only |
| 2. Prioritise | `migration/backlog.md` | Dropping a test is a documented decision |
| 3. Set up | `playwright.config.ts`, separate test directory, non-blocking CI job, one smoke spec | The old suite is untouched |
| 4. Migrate infrastructure | Auth, fixtures, page objects, data helpers, one **golden reference** spec | Before the specs that use them |
| 5. Migrate specs | Specs plus `migration/parity.md` rows | One spec at a time |
| 6. Decommission | Go/no-go checklist, then removal | Deletion is its own commit |

### Phase 1: Assess

Apply the `context-discovery` rule to the old suite and the app. Record in `migration/assessment.md`:

- **Inventory** by spec or class: test count (count `it(` / `@Test` blocks by running the old runner's list or dry-run mode, not by eye; a runner with neither, such as Cypress, is counted from one full run's result table. Say whether the baseline counts methods or executions: a parameterised test is one method and one execution per data row), size, runtime, skipped or `.only` tests, known-flaky tests (CI history if exposed).
- **Shared infrastructure**: custom commands, page objects, fixtures, plugins, helpers, data setup, environment variables.
- **CI stages** that run the suite, and what reports or parallelism they use.
- **Behaviour the old tests do not check** that the migration must not claim to cover (state it; do not fix it silently).
- **Risk list** per principle 4, and the **count baseline**: `old tests = N`. Every later count reconciles to this number.

### Phase 2: Prioritise

Order the backlog: critical journeys first (priority tags `@p0`/`@p1`), then high-failure tests, then the rest. Keep a **do not migrate** list with a reason for each (duplicate, obsolete, disabled, covered at a lower level). Flaky tests go last (see "Flaky tests").

### Phase 3: Set up

Create `playwright.config.ts` with one fixed viewport, `fullyParallel`, `trace: "on-first-retry"`, `retries: 0` locally and `1` in CI (retries are for CI noise after the fact, not a fix; with none, `on-first-retry` never records a trace). Put new specs in their own directory. Add a CI job beside the old one, non-blocking, in every CI system that runs the old suite. Non-blocking is per platform: `continue-on-error` on GitHub Actions; where a job cannot be allowed to fail (CircleCI), a separate workflow kept out of the required checks. Write one smoke spec that proves the environment and `baseURL` work.

### Phase 4: Migrate infrastructure

In this order: authentication (`storageState` from a setup project), fixtures, page objects, data helpers. Then hand-migrate **one golden reference spec** (a representative, stable test), commit it, and check every later spec against it for style and structure. Page objects expose actions and locators, never assertions (the `code-style-qa` rule).

### Phase 5: Migrate specs

One spec at a time, re-derived, never line-translated. For each old test add a row to `migration/parity.md` (below) in the same commit as the new test. Carry tags over; where the old tests have none, assign them and mark them in `backlog.md` as the migrator's assumption. When nothing but structure identifies an element and the product cannot change now, use the least fragile locator, flag it in the parity row, and propose the `data-testid` as a product change. Run the new test with `--repeat-each` (see "Flaky tests") before its row says `migrated`.

### Phase 6: Decommission

Go only if all of these hold, and record the answers in `migration/decommission.md`:

- [ ] Parity table complete; counts reconcile (below).
- [ ] Mutation check done for every Critical and High test.
- [ ] New suite passed in CI for the agreed period (default: **two release cycles**; the team's call).
- [ ] No test is left in `@quarantine` without an owner and a deadline.
- [ ] Reports, CI parallelism and any recording or dashboard the old suite provided have a replacement, or the loss is accepted in writing.

Removal of the old framework is a separate commit, never mixed with a migration commit. A migrated test is marked in the old suite ("migrated to `<new path>`") before it is ever deleted.

## Concept mapping

Each row maps to the Playwright idiom, not to a literal translation. Locator choices follow the `code-style-qa` rule's order; sleeps and conditional assertions are not carried over.

### Cypress

| From | To | Pitfall |
| --- | --- | --- |
| `cy.get(css)`, `cy.contains` | `getByRole`, `getByLabel`, `getByTestId`, `getByText` | A CSS selector copied across stays fragile and breaks the locator rule. If the app has no role, label or test id to use, say so and add a `data-testid` in the product, rather than keep the class |
| Command queue and implicit retry | `await` on every action; web-first `expect(locator)` | Cypress commands are not promises. A missing `await` in Playwright races or fails silently |
| `.should('have.text', t)` | `toHaveText(t)`, or `toHaveText(/^t$/)` when whitespace matters | A string argument normalises whitespace, so a trim test needs the regex. `have.text` on an `<input>` is always empty: assert `toHaveValue` instead |
| `.should('have.length', n)`, `.should('contain', t)`, `.should('have.class', c)`, `.should('not.exist')` | `toHaveCount(n)`, `toContainText(t)`, `toHaveClass(/c/)`, `toHaveCount(0)` or `toBeHidden()` | `toHaveClass` with a string is an exact match; use a regex for one class among many. `toBeHidden` also passes for a missing element |
| `.eq(i)`, `.first()`, `.find()` | `.nth(i)`, `.first()`, a chained locator | Index locators are positional: assert the ordering the test is about, and prefer filtering by text |
| `.type(t)` + `{enter}` / `{esc}` | `fill(t)` then `press("Enter")` / `press("Escape")` | `fill` replaces the value, `.type` appends; `pressSequentially` is the append form |
| `.check()`, `.uncheck()` | `check()`, `uncheck()` | Both assert the end state in Playwright; a click does not |
| `cy.wait(ms)`, `Thread.sleep`, `implicitlyWait`, `WebDriverWait`, `FluentWait` | Delete. Rely on auto-wait or a web-first assertion | Forbidden by the `code-style-qa` rule. If the test needs a condition, assert it |
| `cy.intercept` (stub) | `page.route(url, handler)` | Register before the navigation that triggers the call |
| `cy.intercept` + `cy.wait('@alias')` (spy) | `page.waitForResponse(predicate)` | Start the wait **before** the action that triggers the request, then `await` both |
| `cy.fixture` | JSON imported in the spec, or a Playwright fixture | The two tools use "fixture" for different things |
| `Cypress.Commands.add` | Playwright test fixtures or page-object methods | A command that hides an assertion must be split: the assertion moves into the test |
| `cy.session`, login in `beforeEach` | `storageState` produced once in a setup project | The most common silent-breakage point: a test passing as the wrong user |
| `cy.origin`, multi-origin workarounds | Delete the workaround; Playwright handles several origins | |
| `cy.clearLocalStorage` and automatic state reset | Each Playwright test gets a fresh browser context | Do not port manual clean-up code |
| `cy.go('back')`, `cy.reload()` | `page.goBack()`, `page.reload()` | |
| `cypress-axe` `checkA11y` | `@axe-core/playwright` `AxeBuilder` | Rule scoping differs: map `runOnly` to `.withTags([...])` and verify the same rules run |
| `cypress run --record`, Dashboard parallelism | `fullyParallel`, `--shard`, HTML report, trace viewer | |

### Selenium

| From | To | Pitfall |
| --- | --- | --- |
| `By.id/name/className/cssSelector/xpath`, `findElement` | Locator hierarchy above | Never port `By.xpath` or index-based locators |
| `WebDriverWait` + `ExpectedConditions` | Web-first `expect` | Do not wrap `expect` in a manual retry loop |
| `implicitlyWait`, `Thread.sleep` | Delete, as in the Cypress sleep row | |
| `Select`, `Actions` (`moveToElement`, `dragAndDrop`, `doubleClick`), `sendKeys` | `selectOption`, `hover` / `dragTo` / `dblclick`, `fill` / `press` | `sendKeys(Keys.chord(CONTROL, "a"), t)` is a replace: use `fill(t)` |
| `getText()`, `getAttribute("class").contains(c)`, `findElements(...).size()` | `toHaveText`, `toHaveClass(/c/)`, `toHaveCount(n)` | `getText()` is whitespace-normalised like `toHaveText`, so neither sees a missing trim |
| Page objects | Playwright page objects without assertions | Selenium page objects often assert; move the assertion into the test |
| `driver.switchTo()` window / frame / alert | `context.waitForEvent("page")`, `frameLocator`, `page.on("dialog")` | Register the dialog handler before the action |
| TestNG / JUnit / NUnit / pytest hooks and data providers | `test.beforeEach`, fixtures, parameterised tests from a data array | Shared mutable state in static fields must become per-test fixtures |
| Grid, `RemoteWebDriver` | `projects`, `--shard`, a CI matrix | |

Converter tools (for example the `cy2pw` web converter) exist. Their behaviour and provenance were not verified here; treat any converter output as a first draft to be re-derived and checked against the parity table, never as a result.

## Parity

A migration is not done when the new tests are green; it is done when they are shown to cover the old ones. `migration/parity.md` holds one row per old test:

| Old test | New test | Same assertions? | Mutation check | Repeat run | Status |
| --- | --- | --- | --- | --- | --- |

- **Same assertions?** Compare what each test verifies, not how it is written. Four assertions reduced to two is a regression of the suite; write the difference in the cell.
- **Mutation check**: for each Critical and High test, break the behaviour it covers in a throwaway branch (comment out the validation, change the expected value) and confirm the new test fails, for the expected reason. A migrated test that cannot fail is not a test. This is the red-green idea of the `code-style-qa` rule, applied to migration. Record what was mutated.
- **Run the same mutation against the old suite.** An old test that still passes was vacuous: comparing assertions as written would copy it faithfully. Mark it weak in the assessment; the new test must be stronger, and the "Same assertions?" cell says so. A new suite stricter than the old one means "all green" in each is no longer the same statement; say which tests changed.
- **A data row that cannot fail** (one row of a parameterised test survives its mutation) is recorded against that row, not the whole test, and goes to the test's owner to redesign or drop.
- **Repeat run**: `npx playwright test <spec> --repeat-each=5` (or the team's number), result in the cell.
- **Status** is one of `migrated`, `dropped (reason)`, `remaining`, `flaky-quarantined`.
- **Counts reconcile**: `old = migrated + dropped + remaining + quarantined`, equal to the phase 1 baseline. Refuse to declare completion if the totals do not add up, and say which side is short.
- Optional: compare line or route coverage before and after when the project already measures it. Coverage is a guide, not a goal (the `qa-reference` skill's `references/testing-design.md`).

## Flaky tests during migration

Migrating a flaky test reproduces the flakiness.

1. Mark in the assessment the tests that are flaky, with their failure history if CI exposes it.
2. Migrate them last, re-derived from what they are meant to verify, never copied.
3. Run each migrated test repeatedly (`--repeat-each`) before it counts as migrated, and record the result.
4. If it still flakes, apply the quarantine protocol in the `testing-guidelines` rule (tag `@flaky`, open a defect report, move to `@quarantine`, deadline), not more retries.

The `qa-flaky` skill covers detecting, classifying and retiring flaky tests in general; this section covers the migration-time case only.

## Output discipline

- Say what was run and what was only read. "Migrated" without this run's output (`--repeat-each` result, mutation result) is a guess; see "Pre-Push Verification" in the `qa-reference` skill's `references/automation-code.md`.
- State what the parity table cannot show: behaviour neither suite checks, and the Selenium path if no Selenium suite was run.
- Commits are atomic and conventional: infrastructure, each spec or small group of specs, and the removal are separate commits.
