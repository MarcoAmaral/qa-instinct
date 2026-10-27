---
name: qa-rules
description: "QA Instinct's QA rules, one file each: testing guidelines, code style, security, accessibility, evidence, tools, context discovery, commits and linting. Read the rule a pointer names (the <rule> rule) when this editor has not loaded the rule files, as in a global install or the Claude Code plugin."
metadata:
  id: qa-rules
  author: Marco Amaral
---
# QA Instinct rules

Each rule of the package is a file in this skill's `references` folder. A project install
also puts every rule in the editor's own rules folder, always on, as `qa-instinct-<rule>`; a
global install and the Claude Code plugin have none, so read the rule a pointer names from here.

| Rule | File |
| --- | --- |
| `accessibility-qa` | `references/accessibility-qa.md` |
| `code-style-qa` | `references/code-style-qa.md` |
| `context-discovery` | `references/context-discovery.md` |
| `conventional-commits` | `references/conventional-commits.md` |
| `linting-standards` | `references/linting-standards.md` |
| `security-qa` | `references/security-qa.md` |
| `test-evidence` | `references/test-evidence.md` |
| `test-tools` | `references/test-tools.md` |
| `testing-guidelines` | `references/testing-guidelines.md` |
