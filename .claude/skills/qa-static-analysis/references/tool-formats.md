---
id: ref-static-analysis-tool-formats
---
# Tool Formats, Suppression and Baselines

> **Read on demand** | Part of the `qa-static-analysis` skill | Not syllabus content

Tool details change with every release. Each section says what it was checked against; when the
version in use differs, read the tool's own documentation and say which you followed. Never
invent a flag or a comment syntax: when unsure, say so and give the documentation link instead.

---

## SARIF 2.1.0 (CodeQL, Semgrep, ESLint's SARIF formatter, most scanners)

Checked against the OASIS SARIF 2.1.0 standard, 2026-10-27.

| What | Where in the file |
| --- | --- |
| Tool and version | `runs[].tool.driver.name`, `.version` (one run per tool) |
| Rule | `runs[].results[].ruleId`; the rule's text in `runs[].tool.driver.rules[]` |
| Level | `results[].level`: `error`, `warning`, `note` or `none`. The tool's label, not a severity |
| Location | `results[].locations[].physicalLocation.artifactLocation.uri` and `.region.startLine` |
| Code | `region.snippet.text`, when the tool includes it; otherwise read the file |
| Baseline state | `results[].baselineState`: `new`, `unchanged`, `updated` or `absent`, present only when the run was compared with a baseline |
| Already suppressed | `results[].suppressions[]`, with `kind` and `justification` |
| Identity across runs | `results[].partialFingerprints`, used to match a finding when lines move |

A result with a `suppressions` entry is not a new finding; report it apart, with its justification.

## ESLint

Checked against eslint.org ("Configure Rules", "Bulk Suppressions"), 2026-10-27.

- **Report**: `npx eslint . -f json` gives one entry per file with `messages[]` (`ruleId`,
  `severity` 1 = warning, 2 = error, `line`, `message`). SARIF needs a formatter package.
- **Suppress one line, with the reason**:
  `// eslint-disable-next-line no-console -- why this is safe here`. The reason goes after two or
  more `-`. Keep `linterOptions.reportUnusedDisableDirectives` on so stale suppressions surface.
- **Generated or vendored code**: an `ignores` entry in `eslint.config.js`, for example
  `{ ignores: ["src/generated/**"] }`, rather than comments in each generated file.
- **Baseline and gate**: `npx eslint . --suppress-all` (or `--suppress-rule <name>`) writes
  `eslint-suppressions.json`; commit it. Later runs fail only on violations not in it, and fail on
  suppressions no longer needed until `--prune-suppressions` removes them. Bulk suppressions apply
  to rules set to `error`.

## Semgrep

Checked against docs.semgrep.dev ("Ignore files, folders and code") and Semgrep's CI
documentation, 2026-10-27.

- **Report**: `semgrep scan --json` (`results[]` with `check_id`, `path`, `start.line`,
  `extra.severity`, `extra.message`) or `--sarif`.
- **Suppress one match**: `// nosemgrep: <rule-id>` on the first line of the match or the line
  before it, with the rule ID's full namespace. The documentation does not say whether a reason may
  follow the ID; put the reason in a comment on the line above.
- **Paths**: `.semgrepignore` at the repository root, `.gitignore` syntax.
- **Baseline and gate**: `semgrep scan --error --baseline-commit <sha>` reports and fails only on
  findings absent from that commit; in CI use the merge base with the target branch, with full git
  history checked out. `semgrep ci` does the same diff-aware scan on pull requests.

## CodeQL (GitHub code scanning)

Checked against the CodeQL CLI 2.12.0 changelog and GitHub's code scanning documentation,
2026-10-27. Support differs by language and query version.

- **Report**: SARIF, uploaded to code scanning.
- **Suppress**: dismiss the alert in code scanning with its reason (false positive, used in
  tests, won't fix). Inline `// codeql[<query-id>]` comments on the line before the alert work only
  where the alert-suppression query runs for that language; check before relying on them.
- **Baseline and gate**: code scanning's pull request check reports alerts the pull request
  introduces; existing alerts stay in the repository's alert list.

## TypeScript (`tsc`)

- **Report**: `file(line,col): error TS<code>: message`, one per line.
- **Suppress**: `// @ts-expect-error <reason>` on the line before, not `// @ts-ignore`:
  `@ts-expect-error` itself fails once the error is gone, so the suppression cannot go stale.
- **Baseline and gate**: no built-in baseline. Fix before gating, or gate on a recorded error
  count that may only go down.

## `npm audit`

Checked against docs.npmjs.com (npm 11, `npm audit`), 2026-10-27.

- **Report**: `npm audit --json`. Its structure is not documented; read the file given rather than
  assume fields.
- **Not reachable**: a vulnerability only in development dependencies does not ship. Audit what
  ships with `npm audit --omit=dev`.
- **Gate**: `npm audit --omit=dev --audit-level=high` exits non-zero at `high` or above.
- **Suppress**: `npm audit` has no option to ignore one advisory. Upgrade, override the
  transitive version (`overrides` in `package.json`), or use an allowlist tool the team already
  has, and record the reason.
