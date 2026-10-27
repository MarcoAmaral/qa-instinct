<p align="center">
  <img src="https://img.shields.io/badge/QA_Instinct-blue?style=for-the-badge&logo=checkmarx&logoColor=white" alt="QA Instinct" height="60">
</p>

<h1 align="center">QA Instinct</h1>

<p align="center">
  Built by Marco Amaral — Senior QA Engineer skills for any AI coding assistant
</p>

<p align="center">
  <a href="https://www.npmjs.com/package/qa-instinct"><img src="https://img.shields.io/npm/v/qa-instinct?style=flat-square&color=blue" alt="npm version"></a>
  <a href="https://www.npmjs.com/package/qa-instinct"><img src="https://img.shields.io/npm/dm/qa-instinct?style=flat-square" alt="npm downloads"></a>
  <a href="https://github.com/MarcoAmaral/qa-instinct/blob/main/LICENSE"><img src="https://img.shields.io/npm/l/qa-instinct?style=flat-square" alt="license"></a>
  <a href="https://github.com/MarcoAmaral/qa-instinct"><img src="https://img.shields.io/github/stars/MarcoAmaral/qa-instinct?style=flat-square" alt="GitHub stars"></a>
</p>

---

## What is QA Instinct?

*QA Instinct is a senior QA engineer's instincts, loaded into your AI assistant before the first prompt.*

QA Instinct is a plug-and-play skill package that gives AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Gemini) the expertise of a **Senior QA Engineer**. It ships as a set of modular rules, slash commands, auto-loaded skills, and four subagents (a code reviewer and the three stages of a test-design pipeline) — all grounded in the **ISTQB CTFL v4.0** syllabus and modern test engineering practices. Instead of prompting your AI with long, custom instructions every time, you install this once and get structured test case generation, defect reports, BDD scenarios, Playwright/Vitest scaffolding, risk analysis, TDD workflows, and more — all following industry standards out of the box.

---

## See It in Action

![A terminal: qa-instinct init installs the package, /qa-cases turns a three-criteria ServeRest cart story into nine test cases, and the package's format hook passes on them](demo/qa-instinct.gif)

*Real, unedited output of one live `/qa-cases` run in Claude Code's print mode on Claude Sonnet 5.5 (2026-10-20); only the model's wait is cut. How it was made and how to re-record it: [`demo/`](demo/README.md).*

---

## Why I Built This

As a QA professional, I found myself repeating the same detailed prompts every time I wanted AI help with testing tasks: "follow ISTQB standards", "use the AAA pattern", "apply Boundary Value Analysis", "use Page Object Model", "tag tests with @smoke @p0"... Every new conversation started from zero.

I wanted a solution where the AI **already knows** how a Senior QA Engineer works — the standards, the patterns, the templates, the techniques — so I could focus on the actual testing problem instead of re-teaching fundamentals every session.

QA Instinct solves this by encoding years of QA expertise into a portable, installable package. Install it once, and every AI conversation starts with a QA engineer's brain already loaded.

---

## See It Work

Real, unedited output on [ServeRest](https://serverest.dev), a public practice API, generated on
2026-10-08 by following the package's own command files. The full outputs, with the exact prompts
and an honest list of their limits, are in [`examples/`](examples/README.md).

<details>
<summary><code>/qa-static</code> reviewing ServeRest's cart API documentation: 14 findings</summary>

A technical review (CTFL v4.0 §3.2.4) of the `/carrinhos` section of ServeRest's OpenAPI document,
before writing a single test. Among the findings:

- **SR-001, Major, contradiction:** the schema declares `produtos` as an object, but its own example
  is an array, and the live API rejects the object form ("produtos deve ser um array").
- **SR-004, Major, undefined state:** a user may have only one cart, and no operation exists to
  change it, so "add one more product" has no defined path.
- **SR-005, Major, missing boundary:** `quantidade` has no minimum, and the string `"2"` is accepted
  as a quantity.

Verdict: 6 Major findings open, so the document is not yet a reliable test basis.
[Full review →](examples/serverest/qa-static/review.md)

</details>

<details>
<summary><code>/qa-automate</code> running the generated Playwright API tests live: 15 passed, 1 failed</summary>

Sixteen of the 33 cases the `/qa-agentic` pipeline wrote for "a customer can't add the same product
to the cart twice", automated as Playwright API tests (Page Object, fixtures) and run against the
live API. The one failure is a real ServeRest defect the review had already flagged (SR-005):

```text
  ✘  16 [api] › …cart-no-duplicate-product.api.spec.ts:319:7 › Cart: no duplicate product @cart ›
        quantidade as the string '2' is rejected @regression @api @p2 @cart (1.9s)

    Expected: 400
    Received: 201

  1 failed
  15 passed (33.4s)
```

[Tests, behaviour profile and full run output →](examples/serverest/qa-automate/)

</details>

---

## How It Differs

- **Grounded in the ISTQB CTFL v4.0 syllabus**: `/qa-static`, `/qa-trace`, the planning skill and the
  tools reference cite syllabus sections.
- **A traceable test-design pipeline** (`/qa-agentic`): groomer, designer and writer subagents, each
  reading only the previous stage's output, so every test case traces back to a requirement.
- **Six editors from one source**: Claude Code, Cursor, Windsurf, Copilot, Cline and Antigravity,
  each installed where the editor documents rules and Agent Skills today.
- **An installer that never destroys your files**: a manifest of what it installed, adoption of its
  own older files, a backup of anything else, and an uninstall that keeps whatever you edited.
- **Rules beyond test writing**: accessibility (WCAG 2.2 AA), security (OWASP), test evidence,
  context discovery, and respect for your repository's own lint and commit conventions.
- **Light on context in Claude Code**: about 21 KB of rules load into every conversation, roughly
  5,500 tokens (an estimate: bytes divided by 4; run `./tests/test-rules-size.sh` for the exact
  total); templates load only when needed. The other editors get the same rules, always on, as
  small rule files (about 23,000 characters in all), and every command, skill and agent as an Agent
  Skill that loads only when used. Sizes per editor are under "Editor Support".
- **Answers in the language of your prompt**, English by default.

---

## Quick Start

### Install with npm (the complete install)

Needs Node.js 24, the latest LTS, or later; Node.js 22 and older are no longer supported.

```bash
# Without installing anything globally
npx qa-instinct init

# Or install the command once
npm install -g qa-instinct
```

### Add to a project

```bash
# Option A: Copy files (independent, version-locked)
qa-instinct init

# Option B: Symlink (auto-updates when you update the npm package)
# On Windows without Developer Mode or an elevated shell it links with directory junctions instead
qa-instinct link

# Later: refresh what init copied to the installed package's version
qa-instinct update

# Remove files that `init` copied, keeping anything you changed
qa-instinct uninstall
```

### Other ways to install

**Claude Code plugin marketplace:**

```text
/plugin marketplace add MarcoAmaral/qa-instinct
/plugin install qa-instinct@qa-instinct
```

This installs the commands, skills and agents under the plugin's prefix (`/qa-instinct:qa-cases`,
`/qa-instinct:qa-bdd`, …). Claude Code plugins cannot ship rules, so the plugin carries them as the
`qa-rules` skill: a command, skill or agent that names a rule reads it from there when it runs.
**The rules are not always on**, as they are after `init`: a question asked without a command gets
none of them. If you use both the plugin and `init`, the commands appear twice.

**Skills only, for any agent:**

```bash
npx skills add MarcoAmaral/qa-instinct
```

This installs the nine skills (`qa-plan`, `qa-explore`, `qa-reference`, `qa-migrate`, `qa-api`, `qa-flaky`, `qa-static-analysis`, `qa-release`, `qa-a11y`) and nothing else: no
commands, agents or rules.

For everything, including the rules, and an update and uninstall that never touch your own files,
use `qa-instinct init`.

What each install gives you, and what the commands do where a part is missing:

| Install | Rules | References | Scripts |
| --- | --- | --- | --- |
| `qa-instinct init` (project) | Always loaded | Yes | Yes, `.claude/hooks/` |
| `qa-instinct init --global` | Always loaded, `~/.claude/rules/` | Yes | Yes, `~/.claude/hooks/` |
| Claude Code plugin | **No** ¹ | Yes | **No** ² |
| `npx skills add` | **No** ¹ | Yes | **No**, no commands |
| Other editors (project) ³ | Always loaded ⁴ | Yes | **No** ² |
| Other editors (global) ³ | `qa-rules` skill ⁵ | Yes | **No** ² |
| Cline (global) | Always loaded, `~/.cline/rules/` | Yes | **No** ² |
| `AGENTS.md`, `CLAUDE.md` ⁶ | Inline | With `adapters/skills/` ⁷ | **No** ² |

References are the `qa-reference` skill, in the editor's skills folder (the plugin's own skill
folder for the plugin). Scripts are `validate-tc-format.sh` and `check-test-evidence.sh`.

1. A command, skill or agent that names a rule goes on without it and says so in its reply.
2. The commands apply the checks by reading the files, and the reply says the script was not
   run. The plugin copies the scripts but does not wire them.
3. Cursor, Windsurf, Copilot, Antigravity; Cline too for a project install.
4. One rule file per rule, named `qa-instinct-<rule>`. Copilot: sections of
   `.github/copilot-instructions.md`.
5. No rule files: none of these editors documents a global rules folder every surface reads that
   the package may write, so the `qa-rules` skill holds every rule.
6. Copied by hand. Each rule sits under a `<!-- qa-instinct-<rule> -->` line.
7. Only if you also copy the package's `adapters/skills/` folders, as the file's header says.

Commands name a rule by its name (the `test-evidence` rule), a reference by the skill that holds
it (the `qa-reference` skill's `references/evidence-capture.md`, opened by loading that skill and
reading the file in its folder) and a script by its file name, so each pointer can be followed in
every install above.

### Use with any AI editor

Open your AI assistant and type:

```text
/qa explain the 7 ISTQB testing principles
/qa-cases write test cases for the login feature
/qa-automate scaffold Playwright E2E for checkout flow
/qa-defect report a bug: login button unresponsive on Chrome
```

---

## Commands & Modules

QA Instinct is modular — only the relevant module loads per task, saving tokens and context window.

| Command | What it does | Size |
| --- | --- | --- |
| `/qa` | Smart router — infers intent and dispatches to the right module | ~15KB |
| `/qa-cases` | Generate structured test cases (`TC-CODE-NNN` format with ISTQB techniques) | ~18KB |
| `/qa-automate` | Scaffold Playwright E2E, Vitest unit tests, POM, CI/CD pipelines | ~7KB |
| `/qa-bdd` | Generate BDD/Gherkin scenarios (Given/When/Then) with step definitions | ~13KB |
| `/qa-defect` | Write standardized defect reports (`DR-CODE-NNN`) | ~18KB |
| `/qa-tdd` | Strict TDD workflow (Red → Green → Refactor) + Chaos testing | ~5KB |
| `/qa-refinement` | Agile refinement advisory — Socratic gate, scope negotiation, rollback planning | ~8KB |
| `/qa-static` | ISTQB static testing of a work product — review type, review process, roles, checklist, cited to CTFL v4.0 | ~18KB |
| `/qa-trace` | Requirement → test case → result traceability report, every link marked traced or inferred, with coverage gaps; read-only by default | ~8KB |
| `/qa-agentic` | Multi-agent pipeline — groomer → designer → writer subagents turn a ticket into final test cases | ~5KB |
| `/qa-review` | Branch code review — deep first pass on the most capable model, then incremental re-reviews against a findings log | ~3KB |

### Auto-Loaded Modules

These activate automatically based on context — no slash command needed:

| Module | Activates when... |
| --- | --- |
| **Test Planning Skill** | You discuss test strategies, risk registers, quality gates |
| **Exploratory Testing Skill** | You mention charters, SBTM, exploratory sessions |
| **Test Suite Migration Skill** | You ask to migrate or port Cypress or Selenium tests to Playwright |
| **API Testing Skill** | You ask to test a REST or GraphQL API, an endpoint or a contract |
| **Flaky Test Skill** | Tests pass and fail on the same code, or you ask about flaky, intermittent or quarantined tests |
| **Release Readiness Skill** | You ask whether a release is ready, or for a go/no-go or sign-off record |
| **Accessibility Audit Skill** | You ask for an accessibility or WCAG audit of a page or flow |
| **QA Engineer Agent** | You request code reviews or testability assessments |
| **Testing Rules** | Always loaded — ISTQB principles, testing vs QA, the tagging taxonomy |
| **Context Discovery Rules** | Always loaded: read the code and the project's own sources before designing tests, and say where they contradict each other |
| **Repository Convention Rules** | Always loaded: follow your repository's own commit convention and lint configuration |
| **Code Style Rules** | Always loaded — AAA pattern, POM standards, locator hierarchy |
| **Accessibility Rules** | WCAG 2.2 AA checks, axe-core integration, a11y checklists (to run a full audit, the Accessibility Audit Skill) |
| **Security Rules** | OWASP Top 10, XSS payload testing, token storage audits |
| **Test Evidence Rules** | Screenshots, recordings and evidence files — viewport capture, ASCII-only names, reviewed recordings |
| **Test Tools Rules** | Choosing or justifying a test tool — tool categories, benefits and risks of automation |
| **QA Reference Skill** | Writing or reviewing test automation, an accessibility or security test, test evidence or a tag filter — the long templates and examples the rules point to, loaded only then |

---

## What You Can Do

Every command answers in the language of your prompt, English by default.

### Test Documentation

- Structured test cases with frontmatter, ISTQB techniques, and automation scoring, plus an optional
  runbook (the `runbook:` key) that lists them in execution order
- Professional defect reports following industry standards
- Traceability matrices and test completion reports

### Test Automation

- **Playwright**: E2E tests with Page Object Model, auth fixtures, multi-browser configs
- **Vitest**: Unit/integration tests with mocking, coverage thresholds, React Testing Library
- **CI/CD**: GitLab/GitHub Actions pipeline stages for smoke, regression, and nightly runs
- Automation candidate scoring with weighted decision matrix

### Test Design (ISTQB Techniques)

- Equivalence Partitioning, Boundary Value Analysis, Decision Tables
- State Transition Testing, Error Guessing
- Session-Based Exploratory Testing (SBTM)

### Risk & Strategy

- Risk registers with 5×5 Likelihood × Impact matrices
- Adaptive test pyramid (adjusts distribution by architecture type)
- Quality gates with entry/exit criteria

### Agile QA

- Refinement advisory with Socratic questioning
- Scope negotiation using MoSCoW/RICE frameworks
- BDD scenario generation with Gherkin syntax
- TDD workflow enforcement

---

## Editor Support

| AI Editor | How it works | Install |
| --- | --- | --- |
| **Claude Code** (CLI & VS Code) | Slash commands + rules + skills + agents | `qa-instinct init` |
| **Cursor** / **Trae** | Rules in `.cursor/rules/` (`alwaysApply: true`); skills in `.cursor/skills/`, or `~/.cursor/skills/` globally; `/qa-cases` | `qa-instinct init --editor cursor` |
| **Windsurf (Devin Desktop)** | Rules in `.windsurf/rules/` (`trigger: always_on`); skills in `.windsurf/skills/`, or `~/.codeium/windsurf/skills/` globally; `@qa-cases` | `qa-instinct init --editor windsurf` |
| **GitHub Copilot** | Rules in `.github/copilot-instructions.md`; skills in `.github/skills/`, or `~/.copilot/skills/` globally (no rules file globally); `/qa-cases` | `qa-instinct init --editor copilot` |
| **Cline** | Rules in `.cline/rules/` (always active), or `~/.cline/rules/` globally; skills in `.cline/skills/`, or `~/.cline/skills/` globally; `/qa-cases` | `qa-instinct init --editor cline` |
| **Gemini / Antigravity** | Rules in `.agents/rules/` (`trigger: always_on`); skills in `.agents/skills/`, or globally in `~/.gemini/config/skills/` (App and IDE) and `~/.gemini/antigravity-cli/skills/` (CLI); ask for a skill by name | `qa-instinct init --editor antigravity` |
| **ChatGPT / Claude Web** | Upload or paste the universal adapter | Manual copy from `adapters/universal/` (and `adapters/skills/`) |

Outside Claude Code, every command, skill and agent is an Agent Skill of the same name (`/qa-cases`
is the skill `qa-cases`; the agents of `/qa-agentic` are skills too, whose stages the assistant runs
itself), so only the skills' names and descriptions are in context until one is used. The rules
are always on, as in Claude Code. The always-on files, measured by `tests/verify-adapters.sh`
against 85 percent of what each editor documents (it fails when this table is not what it
measures):

| Editor | Always-on files | Largest | All | Documented limit |
| --- | --- | --- | --- | --- |
| Windsurf | 10 | 7,887 characters | 23,257 characters | 12,000 characters per rule file |
| Cursor | 10 | 126 lines | 415 lines | "under 500 lines" per rule |
| Copilot | 1 | 393 lines | 393 lines | "about 1,000 lines" per file |
| Antigravity | 10 | 7,906 bytes | 23,382 bytes (23,297 characters) | 24,000 bytes per rule file; 20,000 tokens for all always-on rules |
| Cline | 10 | 7,860 characters | 22,987 characters | none stated |
| `AGENTS.md` | 1 | 24,384 bytes | 24,384 bytes | Codex reads 32 KiB |

The 25 skills hold 53 files; their names and descriptions, all that is in context before one is
used, come to 8,344 characters (about 2,090 tokens at 4 characters a token).

**Three notes on the editor layout.** Cursor, Windsurf, Copilot and Cline also read other tools'
skill folders (`.agents/skills/`, `.claude/skills/`), so with two editors installed in one project
the same skill can be listed twice; each editor keeps its own folder so that uninstalling one never
removes another's files. And `.github/copilot-instructions.md` is the one file every Copilot
surface reads: if you have your own, the install backs it up and replaces it, as for any file of
yours at a path the package writes; merge the two by hand.

And with Antigravity on WSL, open the project in a **WSL window**: its title reads
`[WSL: <distro>]`. There the agent runs inside the distro and reads the project's `.agents/` and
the distro's `~/.gemini/`, so install from inside the distro, project or `--global`. Typed in a
plain WSL terminal, `antigravity-ide .` currently opens the folder as a Windows window on
`\\wsl.localhost\...` instead (its launcher looks for VS Code's WSL extension, not Antigravity's);
that window's agent runs on Windows and is refused every read of the project, yours included.
Open it with `antigravity-ide --remote wsl+<distro> <folder>`, with `antigravity-ide <folder>`
from the terminal of a window already in WSL, or with "Connect to WSL"; under WSL, the
installers print that command after an Antigravity install. Checked on Antigravity IDE 2.5.5 on
2026-10-21: in a WSL window and from a Windows folder, the agent loaded the rules and the
`qa-cases` skill on its own, and its test cases passed the package's format check.

> **Note:** `qa-instinct init` (this npm package's CLI) supports every editor above via `--editor
> <name>` or `--editor all`, with an interactive menu when run on a TTY with no flag. The shell
> installer (`install.sh` / `install.ps1`) in the [GitHub repository](https://github.com/MarcoAmaral/qa-instinct)
> supports the same editors for users without Node/npm.
>
> A global install (`--global`, `--target global`) puts each editor's skills in its own global
> skills folder, and Cline's rules in `~/.cline/rules/`, as listed above. Running `install.sh` from
> WSL can also install into your
> Windows user profile; that copies the files but does not register the test-case pre-commit
> hook with Windows-side git, and `install.sh` says so when it happens. Run `install.ps1` from
> Windows PowerShell if you want the hook there.
>
> Run with no flags, `install.sh` asks for the operation, the scope and the editor. An empty
> answer takes the default shown in brackets, and so does input that has ended (piped answers
> that run out, or `< /dev/null`): with no flags and no input, `install.sh` installs Claude Code
> into the current project, as `install.ps1` does. A menu asks again on an answer it does not
> list, and a yes/no question on anything but `y` or `n`; a yes/no question with an empty answer
> or no input takes no. That includes "Continue anyway?", asked first when no `claude` command is
> on your PATH, so there the run stops without installing. `install.sh` also needs `sha256sum`
> or `shasum`; without either it stops before writing anything.

### Your own files are never destroyed

All three installers — `install.sh`, `install.ps1` and the npm CLI (`qa-instinct`) — record every
file they write in `.qa-instinct-manifest`, at the root of the project (or of your home directory
for a global install).

- **Installing** over a file that already exists and differs from what the installer is about to
  write first checks its content hash against `.qa-instinct-known-hashes` — every SHA-256 the
  package has ever shipped, across all its tagged releases. A match means the file is the
  package's own older content (however it got there, and whatever it's currently named), so it is
  overwritten and recorded in the manifest, with no backup. No match means it's treated as yours:
  it is copied to `<file>.qa-instinct-backup-<UTC timestamp>` first, and reported. This covers a file
  of your own whose name matches one of the package's (for example your own
  `.claude/rules/security-qa.md` or `.github/copilot-instructions.md`), including one you happen to have edited to the
  exact bytes of an older release.
- **Uninstalling** removes only files that are still exactly as installed. Anything you added or
  changed is kept, and reported. Backups are never removed.
- Keep `.qa-instinct-manifest` for as long as the package is installed; deleting it makes uninstall
  fall back to removing only files whose content still matches the package's current copy.
- **An install made before 4.3** recorded itself in `.qa-skills-manifest`. The next `init`, `update`
  or `uninstall` moves it to `.qa-instinct-manifest`, keeping every entry, and removes the old file;
  commit both changes. Backups named `.qa-skills-backup-*` are kept like any other backup.
- **A read-only file is left alone**, on install and on uninstall alike. Marking a file read-only
  is taken as a deliberate signal, and the rest of the tree still installs.
- **A symlinked destination is never written through.** The file it points at, outside the
  install tree, is left untouched; its content is backed up, `<backup>.link-target` records where
  the link pointed, and the link itself is replaced by the package's file.
- **A symlinked folder inside the editor's folder is never written or deleted through.** Files
  under a linked `.claude/rules` (say) are skipped on install and kept on uninstall, with a
  message; the rest installs. After `qa-instinct link`, run `qa-instinct unlink` before switching to
  a copy. The editor's own folder (`.claude` itself) may be a link, as in a dotfiles setup. A
  Windows directory junction counts as a link.
- This guarantee covers all three installers, and they interoperate: you can install with one and
  uninstall with another. All write and read the manifest in the same portable, on-disk format —
  no BOM, LF line endings, forward-slash path separators, tolerant of a stray leading BOM or
  trailing `\r` from an older release — and all three agree on SHA-256, whether it comes from
  `sha256sum` (Linux), `shasum -a 256` (macOS), `Get-FileHash` (Windows) or Node's `crypto`.
  They read the same known-hash list the same tolerant way.
- Set `QA_INSTINCT_DEBUG=1` (`install.sh` or `install.ps1`) to print a trace line for every manifest entry
  recorded during install.

---

## What It Installs and What Runs

**Nothing runs in the background, no API key is needed, and nothing is sent anywhere.** The package
is text your AI assistant reads, plus an installer.

- **What `qa-instinct init` writes.** For Claude Code: `.claude/commands/`, `.claude/rules/`,
  `.claude/skills/`, `.claude/agents/` and `.claude/hooks/` in your project (or in `~/.claude/`
  with `--global`). For the other editors: the rule files and the skills folder at the paths in
  [Editor Support](#editor-support).
  It also writes `.qa-instinct-manifest`, the record of what it installed, and backs up any file of
  yours that was in the way (see [Your own files are never destroyed](#your-own-files-are-never-destroyed)).
- **No network, no telemetry.** The `qa-instinct` command makes no network requests and starts no
  other programs: it copies files and records their hashes. (Getting the package from npm is, of
  course, a download.)
- **The two scripts in `.claude/hooks/` do not run on their own.** `init` copies them and marks them
  executable; it registers nothing with your editor or with git. Run them when you want them:

  ```bash
  .claude/hooks/validate-tc-format.sh path/to/TC-AUTH.md   # check a test case file's format
  .claude/hooks/check-test-evidence.sh playwright/tests     # flag full-page or element-only screenshots
  ```

- **The shell installers do register a git hook.** `install.sh` and `install.ps1` (the installers
  for people without Node) add `validate-tc-format.sh` as a git **pre-commit** hook, in the
  project's `.git/hooks/`, or, with `--target global`, in a global git hook directory. A global
  install also runs `git config --global init.templateDir ~/.git-templates` when you have no
  `core.hooksPath`. Pass `--no-hooks` (`-NoHooks` on Windows) to skip all of this. Uninstalling
  removes the hook it added but leaves `init.templateDir` set; remove it with
  `git config --global --unset init.templateDir` if you do not use git templates otherwise.

---

## CLI Reference

```text
qa-instinct init      [--global] [--editor <name>]
qa-instinct uninstall [--global] [--editor <name>]
qa-instinct update    [--global] [--editor <name>]
qa-instinct link      [--global]
qa-instinct unlink    [--global]
qa-instinct --version
```

`link` and `unlink` work on Claude Code's `.claude/` folder only and do not take `--editor`.

| Command | Description |
| --- | --- |
| `init` | Copy QA skills into `.claude/` (current project); shows an interactive editor menu on a TTY, or installs Claude Code only otherwise |
| `init --editor <name>` | Copy QA skills for one editor (`claude`, `cursor`, `windsurf`, `copilot`, `cline`, `antigravity`) |
| `init --editor all` | Copy QA skills for every supported editor |
| `init --global` | Copy QA skills into `~/.claude/` (all projects); with `--editor`, into that editor's global folders (see [Editor Support](#editor-support)) |
| `uninstall` | Remove Claude Code files copied by `init`/`update`, keeping anything you changed |
| `uninstall --editor <name>` / `--editor all` | Remove one editor's files, or every installed editor's files |
| `link` | Symlink into `.claude/` — auto-updates with `npm update -g` |
| `link --global` | Symlink into `~/.claude/` globally |
| `unlink` | Remove qa-instinct symlinks |
| `update` | Refresh installed files to this package's current version, install the files it added since your install, and remove unmodified ones it no longer ships. Files you changed are backed up, never overwritten. Never installs an editor that was not already installed; with nothing installed, does nothing. `install.sh --update` and `install.ps1 -Update` do the same |
| `update --editor <name>` | Refresh one editor's files. With no `--editor`, refreshes every editor the manifest records |
| `update --global` | Refresh the global install recorded in `~/.qa-instinct-manifest` |
| `--version` / `-v` | Print the installed version (`qa-instinct <version>`) |
| `help` / `--help` / `-h` | Print the commands and flags |

### Symlink vs Copy

| | `init` (copy) | `link` (symlink) |
| --- | --- | --- |
| **Speed** | Instant | Instant |
| **Updates** | Run `qa-instinct update` after upgrading the package | Automatic — symlink points to package |
| **Offline** | Works independently | Requires package to stay installed |
| **Git** | Can be committed to repo | Add `.claude/` to `.gitignore` |
| **Best for** | Teams, CI/CD | Personal use, multi-project |

`update` refreshes from the version of the package that is running it — it cannot fetch a newer
release of itself. Upgrade the package first, then run `qa-instinct update`.

### Rolling back to an older version

Uninstall with the version you have, then install the older one:

```bash
qa-instinct uninstall --editor all                 # with the version you are on now
npm install -g qa-instinct@<version>  # the version to go back to
qa-instinct init --editor <the editors you use>
```

With the shell installers it is the same two steps: run `install.sh --uninstall` (or
`install.ps1 -Uninstall`) from your current checkout, then check out the older tag and install.

This leaves the tree **byte-identical** to a fresh install of the older version — verified by
rolling a project back from 2.6.0 to 2.5.0. Installing the older version straight over the newer
one is *not* equivalent: files the newer version added and the older one does not know about are
left behind, and since rules load automatically, your assistant would then run a mix of both
versions. Uninstall still removes only files that are exactly as installed, so your own edits and
all backups survive the round trip.

### Output colour

| Tool | Colour is on when | Turn it off |
| --- | --- | --- |
| `install.sh`, `generate-adapters.sh` | Output is a terminal, `FORCE_COLOR` is set, or running in GitHub Actions | `NO_COLOR=1` (any value) or `--no-color` |
| `qa-instinct` CLI | Output is a terminal | `NO_COLOR=1` (any value) |
| `install.ps1` | Always — PowerShell's own console colours, not ANSI codes | Not configurable |

Piped or redirected output from the first two contains no escape codes unless `FORCE_COLOR` is set.

---

## Does it work?

A claim that a QA package makes an AI assistant better needs a measurement a tester would accept,
so QA Instinct has a benchmark whose method was written down before any data
([`benchmark/METHODOLOGY.md`](benchmark/METHODOLOGY.md)). It gives the same nine QA tasks (test
cases, a defect report, a risk-based plan, an API contract check, an accessibility audit, a flaky-test
analysis, BDD scenarios) to the same model under four conditions:

- **A**, nothing added;
- **B**, one sentence: "Work as a thorough, professional QA engineer.";
- **C**, a placebo: a guide of the same size and shape about writing help-center articles, loaded the
  same way as QA Instinct ([`benchmark/CONTROL.md`](benchmark/CONTROL.md));
- **D**, QA Instinct's command or skill for the task.

The primary outcome is **content pass**: every content check of the task passes (each acceptance
criterion covered, the right boundary values, the seeded defects found, and so on), checked by
regular expressions that were tested on correct and wrong sample answers before any paid run.
Following the package's own format is reported separately, because D wins it by construction.

**Pilot, not results.** One generation per task and condition (36 in all), run on 2026-10-18 with
`claude-haiku-4-5-20251001` to prove the harness works. One run per cell supports no conclusion,
and the analysis prints "underpowered" for every comparison.

| Condition | Content pass (pilot) | Package format (pilot) | Cost per generation (API prices) |
| --- | --- | --- | --- |
| A, nothing added | 3 of 9 | 0 of 9 | US$0.025 |
| B, one sentence | 4 of 9 | 0 of 9 | US$0.027 |
| C, placebo | 2 of 9 | 0 of 9 | US$0.034 |
| D, QA Instinct | 8 of 9 | 7 of 9 | US$0.046 |

The full collection (ten runs per cell, 360 generations, about US$13 at API prices) runs after the
method is frozen and published. The costs are what Claude Code reports at API list prices; run
on a Claude subscription, the same runs count against the plan's usage limits instead. Every pilot output, its grader verdicts and the analysis are in
[`benchmark/results/2026-10-18-pilot/`](benchmark/results/2026-10-18-pilot/). The method follows
the [A11Y.md efficacy benchmark](https://github.com/fecarrico/A11Y.md/tree/main/benchmark).

---

## Knowledge Base

### ISTQB CTFL v4.0 — Coverage

| Chapter | Covered | Not yet covered |
| --- | --- | --- |
| 1. Fundamentals | The 7 testing principles; testing vs QA; errors, defects, failures and root causes; roles and independence of testing | — |
| 2. SDLC | TDD/ATDD/BDD; test levels and test types; confirmation, regression and maintenance testing; DevOps and shift-left practices; retrospectives and process improvement | — |
| 3. Static Testing | Code review by an AI agent, testability and ambiguity checks on requirements; the review process, review types, roles and success factors (`/qa-static`); triage of what static analysis tools report (`qa-static-analysis`) | — |
| 4. Test Design | EP, BVA, decision tables, state transition, with their coverage items; white-box testing and statement/branch coverage; checklist-based testing; the 3 Cs and acceptance-criteria formats | — |
| 5. Managing | Planning, risk-based testing (5×5 likelihood × impact), estimation techniques, entry and exit criteria, monitoring, control and completion, configuration management, defect management; test case prioritisation strategies; the testing quadrants | — |
| 6. Tools | Tool categories, benefits and risks of test automation | — |

Package additions beyond the syllabus: automation ROI scoring and flaky-test handling.

The gaps are tracked in `plans/README.md` §"Backlog — audit after 4.0.0". Tool-based static
analysis, a declared gap from 2026-10-20, is covered by the `qa-static-analysis` skill since plan
068: it triages what a tool reports; choosing a tool stays in the tools reference.

### Supported Frameworks & Tools

| Category | Tools |
| --- | --- |
| **E2E** | Playwright |
| **Unit/Integration** | Vitest |
| **Component** | React Testing Library |
| **BDD** | Cucumber/Gherkin step definitions |
| **Accessibility** | `@axe-core/playwright` |
| **Migration sources** | Cypress, Selenium (to Playwright, via the migration skill) |

Other frameworks work through the assistant's general knowledge; QA Instinct has no dedicated guidance for them yet.

---

## Project Structure

```text
qa-instinct/
├── .claude/
│   ├── commands/          # 11 slash commands (/qa, /qa-cases, /qa-automate, ...)
│   ├── rules/             # 9 always-loaded rules (testing, context discovery, code style, a11y, security, ...)
│   ├── skills/            # 8 context-activated skills (planning, exploratory, migration, API testing, flaky tests, release readiness, accessibility audit, QA reference)
│   ├── agents/            # 4 subagents: the QA Engineer reviewer and the groomer, designer and writer pipeline
│   └── hooks/             # Validation scripts (test case format and test evidence checkers)
├── .claude-plugin/        # Claude Code plugin and marketplace manifests
├── adapters/              # Compiled outputs for other editors (generated, not committed)
├── cli/qa-instinct.js       # npm CLI (init, update, uninstall, link, unlink)
├── install.sh             # Multi-editor installer (Linux/macOS/WSL)
├── install.ps1            # Multi-editor installer (Windows)
├── generate-adapters.sh   # Compiler: .claude/ → adapters/ (generate-adapters.ps1 on Windows)
├── .qa-instinct-editor-map  # Each editor's install paths, read by all three installers
├── tests/                 # Conformance and lifecycle suites, content checks
├── examples/              # Real output on public software
├── benchmark/             # The efficacy benchmark and its pilot results
├── demo/                  # The demo above and how to re-record it
├── plans/                 # Numbered work plans and their status
└── package.json
```

---

## Contributing and Roadmap

- [CONTRIBUTING.md](CONTRIBUTING.md): the contributions that help most, the evidence a change
  needs, what will not be merged, and the checks to run before a pull request.
- [ROADMAP.md](ROADMAP.md): what 4.1.0 ships, what is planned next and what is out of scope;
  [`plans/`](plans/README.md) holds the detailed record.
- [Issue forms](https://github.com/MarcoAmaral/qa-instinct/issues/new/choose): installer bugs, wrong or
  missing CTFL claims, field reports from real QA work, proposals for a new skill or command.
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md): the Contributor Covenant 2.1.
- [llms.txt](llms.txt): the files an AI agent should read to use or change the package.

---

## Credits & References

Built on knowledge from:

- **ISTQB CTFL v4.0 Syllabus** — International Software Testing Qualifications Board
- **Engenharia de Software Moderna** — Marco Tulio Valente (DCC/UFMG)
- **Playwright**, **Vitest**, **Cypress** — official documentation

ISTQB® is a registered trademark of the International Software Testing Qualifications Board; syllabus content is used with acknowledgement of the ISTQB as source and copyright owner.

---

## Author

**Marco Amaral** — Senior QA Engineer

- GitHub: [github.com/MarcoAmaral](https://github.com/MarcoAmaral)
- npm: [@marcoamaral](https://www.npmjs.com/~marcoamaral)

---

## License

[MIT](LICENSE) — use it, fork it, improve it.
