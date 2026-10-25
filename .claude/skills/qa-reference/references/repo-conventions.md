---
id: ref-repo-conventions
---
# Repository Conventions Reference

> **Read on demand** | Detail behind the `conventional-commits` and `linting-standards` rules | Part of the `qa-reference` skill

Read this when committing on behalf of the user or writing and editing code in the target repository. The always-on must-lists stay in the two rules.

---

## Conventional Commits

> **Conventional Commits v1.0.0** | Commit Hygiene | AI-Authored Commits | Target Repo Scope

This ruleset governs the format and atomicity of commits the AI makes **in the target/consuming
repository** — the project that installed this `qa-instinct` package, not this package's own repo
(which governs its own contribution process via its `CONTRIBUTING.md`). AI agents must apply
these rules whenever they commit code on behalf of a user in a target repo.

---

### 📦 Commit Type Taxonomy

Every commit message must start with one of these types, following the
[Conventional Commits](https://www.conventionalcommits.org/) specification:

- **`feat`**: A new feature or capability added for the user.
- **`fix`**: A bug fix.
- **`docs`**: Documentation-only changes.
- **`style`**: Changes that do not affect code meaning (whitespace, formatting, missing
  semicolons).
- **`refactor`**: A code change that neither fixes a bug nor adds a feature.
- **`perf`**: A code change that improves performance.
- **`test`**: Adding or correcting tests.
- **`chore`**: Maintenance tasks (tooling, dependencies, build config) that don't modify
  source or test files.

---

### ⚛️ Atomic Commits

Commits must follow the atomic-commit philosophy: one concept per commit, and if the message
needs the word "and" to describe it, split it into multiple commits. This is the same standard
already codified for test automation code in
the `qa-reference` skill's `references/automation-code.md` §"Git & Version Control Standards" → "Atomic Commits" — treat
that section as the canonical wording and do not restate or diverge from it here. This rule
simply extends that same discipline to **all** commits the AI authors in a target repo, not
just test automation changes.

---

### 💥 Breaking Change Notation

When a commit introduces a breaking change, signal it using one of the two standard notations:

- **`!` suffix** after the type/scope: `feat(api)!: remove deprecated /v1 endpoint`
- **`BREAKING CHANGE:` footer**: a trailing paragraph in the commit body starting with
  `BREAKING CHANGE:` describing the impact and migration path.

---

### 🎯 Scope of This Rule

This rule applies to commits the AI makes **inside the target/consuming repository** — the
project where this package has been installed. It does not govern commits made to the
`qa-instinct` package's own repository; that repo has its own commit conventions defined in its
root `CONTRIBUTING.md`.

---

## Linting Standards

> **Respect Existing Config** | No Imposed Style | Target Repo Scope

This ruleset governs how the AI handles linting and code formatting when writing or editing
code **in a target/consuming repository** — the project that installed this `qa-instinct`
package. AI agents must apply these rules before writing or editing any code in that repo.

---

### 🔍 Detect and Respect Existing Configuration

Before writing or editing any code in a target repo, the AI must detect the repo's **existing**
lint and format configuration and conform to it, rather than imposing this package's own
opinions or a different style. Look for configuration such as:

- ESLint: `.eslintrc*`, `eslint.config.*`
- Prettier: `.prettierrc*`, `prettier.config.*`
- Stylelint: `.stylelintrc*`
- Rubocop: `.rubocop.yml`
- golangci-lint: `.golangci.yml`
- Python: `pyproject.toml` `[tool.ruff]` or `[tool.black]`, `setup.cfg`, `.flake8`

Whatever tooling and rules are already configured take precedence over any style preference
the AI might otherwise default to.

---

### 🚫 No Config Found: Follow Observed Style, Don't Invent One

If no lint or format configuration exists in the target repo, the AI must **not** silently
invent one. Instead, it should follow the target repo's *observed* code style — the
conventions already visible in existing files (indentation, quote style, naming, import
ordering, etc.) — and only propose adding new linting/formatting tooling if the user
explicitly asks for it.

---

### 🎯 Scope of This Rule

This rule is about respecting **the target repo's own code** style and tooling. It is not
about linting or formatting this `qa-instinct` package's own source files — that is a separate
concern scoped to this repo's own development tooling, not something this rule governs.
