# QA Instinct — Project Development Guide

Welcome to the **QA Instinct** package repository. This file serves as the primary entry point for AI agents and developers working on this project. It outlines the technology stack, project structure, build/compilation workflows, and development guidelines.

---

## 🎯 Project Overview & Stack

- **Purpose**: A universal, model-agnostic package providing high-fidelity QA Analyst + QA Engineer capabilities based on **ISTQB CTFL v4.0** and modern software engineering practices.
- **Target Editors**: Claude Code, Cursor, Windsurf, GitHub Copilot, Cline and Antigravity, plus a universal `AGENTS.md` / `CLAUDE.md` for any agent that reads Markdown.
- **Source Language**: Standard English Markdown (`.md`).
- **Build Scripts**: Bash and PowerShell compilers and installers, and a Node CLI (`cli/qa-instinct.js`).

---

## 📂 Repository Structure

The source files are structured in the modern, modular Claude Code layout under `.claude/`. The compiler compiles these source files into editor-specific targets under `adapters/`: each editor's always-on rule files, one Agent Skill per command, skill and agent in `adapters/skills/`, and the universal `AGENTS.md` / `CLAUDE.md`.

```text
qa-instinct/
├── CLAUDE.md                   # You are here (project entry point)
├── README.md                   # Public distribution guide
├── CHANGELOG.md                # Release history (Release Please writes it)
├── CONTRIBUTING.md             # Contributor guide, including every check CI runs (section 4)
├── ROADMAP.md, SECURITY.md, CODE_OF_CONDUCT.md
├── llms.txt                    # Index of the files an AI agent should read
├── generate-adapters.sh        # Linux/macOS compiler script
├── generate-adapters.ps1       # Windows PowerShell compiler script
├── generate-known-hashes.sh    # Records the SHA-256 each release shipped (see below)
├── generate-corpus.js          # Indexes the tree as citable chunks (CONTRIBUTING.md section 6)
├── .qa-skills-known-hashes     # Generated: lets installers identify their own older files
├── .qa-skills-editor-map       # Each editor's install paths, read by all three installers
├── known-hashes-before-public.txt # Hashes of the releases before the public repository; sealed at export
├── install.sh                  # Linux/macOS interactive installer
├── install.ps1                 # Windows PowerShell installer
├── cli/qa-instinct.js            # npm CLI — qa-instinct init / update / uninstall / link / unlink
├── .claude-plugin/             # Claude Code plugin and marketplace manifests
├── history/                    # Retired v1.x guides (usage examples, skill self-tests); not maintained
├── prompt-history/             # Session logs from `/qa` (local memory store; not published)
├── plans/                      # Numbered work plans + their status table (plans/README.md)
├── decisions/                  # Decision records (the name)
├── tests/                      # Lifecycle and conformance suites (bash + PowerShell), content checks
├── evals/                      # Behavioural evals for `claude plugin eval`
├── benchmark/                  # Pre-registered efficacy benchmark and its results
├── examples/                   # Real output on public software, committed unedited
├── demo/                       # The README demo and the script that records it
├── .claude/                    # Development Source Folder
│   ├── rules/                  # Declarative rules & taxonomies (see "Shipped rules" below)
│   ├── commands/               # Interactive slash commands
│   ├── skills/                 # Multi-step task-matching workflows
│   ├── agents/                 # Focused subagent personas
│   └── hooks/                  # Validation scripts (test case format, test evidence), run on demand
└── adapters/                   # Compiled outputs (generated, not committed)
```

---

## 🛠️ CLI Development Commands

### 1. Compile Adapters

Always run this script after modifying any rule, command, or skill under `.claude/` to update all compiled output adapters under `adapters/`:

```bash
# Linux/macOS
./generate-adapters.sh

# Run with clean generation (removes output directory first)
./generate-adapters.sh --clean

# Windows PowerShell
.\generate-adapters.ps1
```

### 2. Verify and Test Installs

Run the installer locally or globally to test changes:

```bash
# Local project-level install
./install.sh --target project --editor claude --non-interactive

# Global local install with hooks
./install.sh --target global --editor all
```

### 3. Run Automated Integration Tests

Before submitting any changes, execute the automated integration test suite in an isolated, sandboxed environment to ensure cross-platform correctness:

```bash
# Linux/macOS
./tests/test-lifecycle.sh

# Windows PowerShell
.\tests\test-lifecycle.ps1
```

A guarantee the three installers share belongs in the **conformance suite**, not in a lifecycle
suite: it is written once as a case under `tests/conformance/cases/` and run against every
installer. See `tests/conformance/README.md`.

```bash
# Linux/macOS: install.sh and cli/qa-instinct.js
./tests/conformance/run.sh

# Windows PowerShell: install.ps1 and cli/qa-instinct.js
.\tests\conformance\run.ps1
```

CI runs more checks than these (frontmatter, CTFL citations, llms.txt links, rules size, the
benchmark's integrity and others); `CONTRIBUTING.md` section 4 lists every one with its command.

---

## 🎨 Development Conventions & Rules

1. **Strict Agent-Agnosticism**: All rule and command contents must remain 100% agent and model-agnostic. Never hardcode references to a specific model unless illustrating a specific tool config.
2. **No Direct Edits to `adapters/`**: Never edit files in the `adapters/` directory directly. They are compiled outputs and will be overwritten by `./generate-adapters.sh`. Always edit the source files under `.claude/`.
3. **Atomic Commits**: Keep commits small and focused:
   - `feat`: Add new testing skill modules
   - `fix`: Correct a lint issue or installation bug
   - `refactor`: Improve rule syntax or restructure directories
   - `docs`: Update readme, changelog, or distribution files
   - Every type the checks accept, with its meaning, is in `CONTRIBUTING.md` section 2.
4. **Test Case Formatting Hook**: Newly created test cases matching `TC-*.md` must pass the validation hook in `.claude/hooks/validate-tc-format.sh`.
5. **Installer File-Safety Contracts**: `install.sh`, `install.ps1` and `cli/qa-instinct.js` must behave identically, and a user's own file must never be destroyed. Before changing any of them, read `plans/009`-`plans/012`, and keep these invariants:
   - `.qa-skills-manifest` and `.qa-skills-known-hashes` are shared, portable formats: no BOM, LF endings, forward-slash paths. The manifest is `<sha256>  <editor>  <path>`; the known-hash list is `<sha256>  <path>`. Reads tolerate a leading BOM and trailing `\r`. A file written by one installer must be readable by the other two — the suites round-trip this.
   - A colliding file is backed up to `<file>.qa-skills-backup-<UTC timestamp>` unless it is identical to the package's current file or its hash appears in `.qa-skills-known-hashes`, in which case it is the package's own and is adopted silently. Never guess by any other means.
   - Never write through a symlinked destination: back up the content it points at, record the target in `<backup>.link-target`, and replace the link. Never write or delete through a symlinked directory below the editor's top-level folder (plan 033 item 1). Never overwrite a read-only file; skip it and carry on installing the rest. Skip a destination that is a directory the same way, and keep a recorded path that is now a directory on uninstall (conformance cases 044-045).
   - Every manifest write goes to an exclusively created temporary file renamed into place.
   - Uninstall removes only files still exactly as installed, keeps and reports the rest, and never deletes backups.
   - `install.sh` must run on **bash 3.2** (macOS ships it): no `declare -A`, no associative arrays.
6. **Shipped Rules Govern the Target Repo, Not This One**: everything under `.claude/` is content this package installs into someone else's project. Two rules in particular are written in the imperative and are easy to misread as instructions for this repository:
   - `.claude/rules/conventional-commits.md` — how the AI should write commits **in a repo that installed this package**. This repository's own commit conventions live in `CONTRIBUTING.md`.
   - `.claude/rules/linting-standards.md` — tells the AI to detect and respect **the target repo's** existing lint configuration rather than impose one. It says nothing about how this package's own sources are linted; that is `eslint`, `prettier` and `markdownlint` as configured here.

   The remaining rules (`testing-guidelines.md`, `context-discovery.md`, `code-style-qa.md`, `security-qa.md`, `accessibility-qa.md`, `test-evidence.md`, `test-tools.md`) are QA guidance shipped to users, not process rules for this repository either. Edit them as product content, and remember the compiled adapters must be regenerated afterwards.
7. **Work Plans**: Non-trivial work gets a numbered plan in `plans/`, and `plans/README.md` tracks its status. Reproduce a defect before writing it down, and record rejected approaches with the reason rather than deleting them.
8. **Git & PR Workflow**:
   - **Branches**: Always work in dedicated branches (e.g., `feat/...`, `fix/...`, `chore/...`). Never commit directly to `main` or main development branches.
   - **Commits**: Make atomic, clean commits with conventional commit messages.
   - **Pull Requests**: Always open pull requests to merge work, pre-filling both the **Title** (prefixed with conventional commits like `feat(v2.0): ...`) and a detailed **Description**.
   - **Approval**: Present the pre-filled GitHub PR URL to the user for explicit approval before merging.
   - **Merging**: GitHub's default merge commit — the button or plain `gh pr merge <N> --merge`.
     **Never merge with an empty body (`--body ""`) and never squash.** The PR title in the merge
     commit body is the only changelog record Release Please is guaranteed to see: it walks history
     newest-first and stops at the previous release, so a PR whose commits predate that release is
     visible only through its merge commit. With an empty body such a PR gets no entry and no
     version bump — 2.7.0 and 2.7.1 would never have been proposed. `dedupe-changelog.sh` removes the
     resulting duplicate only when the PR's own commits are listed too.
   - **Before merging a release PR**: read its `CHANGELOG.md` section. Every PR merged since the last
     release must appear exactly once. A missing or duplicated entry is a defect — this repository is
     monograph evidence and the changelog is part of its audit trail. CONTRIBUTING.md §3 item 6 has
     the full explanation.
