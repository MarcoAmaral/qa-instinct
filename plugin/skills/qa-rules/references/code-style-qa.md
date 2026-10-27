# Test Automation Code Style Rules

> **QA Code Standards** | Locators, Assertion Patterns & Best Practices

This ruleset governs the style, architecture, and coding conventions for all test automation code (E2E Playwright/Cypress, Integration Testing Library, Unit Vitest/Jest).

---

## 🏗️ Core Patterns

- **Arrange-Act-Assert**: every test has three clear sections: set up, perform the one action under test, assert the outcome.
- **Page Object Model** for `@e2e`: selectors and page actions live in page objects; navigating methods return the next page object; page objects never assert.

---

## 🎯 Locator Strategy (Order of Precedence)

To prevent fragile tests that break when classes or layout structures change, selectors must adhere to this strict hierarchy:

1. **User-Facing Roles (First Choice)**:
    `page.getByRole('button', { name: 'Submit' })`
2. **Explicit Test IDs (Best for Dynamic/Internal Elements)**:
    `page.getByTestId('submit-btn')`
3. **User-Facing Text / Labels**:
    `page.getByLabel('Username')` or `page.getByPlaceholder('Enter password...')`
4. **❌ NEVER USE FRACTIONAL OR STRUCTURAL CSS/XPATH SELECTORS**:
    - _Bad_: `page.locator('div > ul > li:nth-child(3) > button')`
    - _Bad_: `page.locator('.btn-primary.submit-class-active')`

---

## 🚫 Anti-Patterns & Enforcement Rules

- **No Hardcoded Sleeps (Strictly Enforced)**:
  - _Bad_: `await page.waitForTimeout(5000);`
  - _Good_: `await page.waitForResponse(response => response.url().includes('/api/v1/save') && response.status() === 200);`
  - _Good_: `await expect(page.getByTestId('loading-spinner')).toBeHidden();`
- **No Conditional Assertions**:
  Tests must run deterministically. Avoid `if` conditions around your assertions.
- **Independent Test Isolation**:
  Tests must run in complete isolation. Never write tests that depend on the state or execution order of a previous test. Use `beforeEach` hooks or mock fixtures to seed required states.

---

## 🌿 Commits and Claims

- One concept per commit, in Conventional Commits format; a message that needs "and" is two commits.
- Every commit leaves the tests passing.
- Never say a spec passes or a bug is fixed without this run's output; a regression spec must fail without the fix.

Full patterns, assertion examples and the version control standards: the `qa-reference` skill's `references/automation-code.md`.
