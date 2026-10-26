# Contributing to QA Instinct

First off, thank you for considering contributing to QA Instinct! We welcome contributions from everyone and value your feedback.

**Start here.** To report a problem or send a change, read sections 7 to 10 first: the
contributions that help most, the evidence a change needs, what will not be merged, and the steps
from fork to pull request. Section 4 lists every check CI runs and how to run it on your machine.
[ROADMAP.md](ROADMAP.md) says what is planned and what is out of scope. Sections 2 to 6 govern
commits, merges, the release and the written records: read section 2 before your first commit and
section 6 before you change anything under `.claude/`.

## 1. Code of Conduct

By participating in this project, you are expected to uphold our [Code of Conduct](CODE_OF_CONDUCT.md)
(the Contributor Covenant 2.1). Please be respectful and considerate of others. To report a breach,
e-mail the maintainer at <contato@marcoamaral.com>.

## 2. Conventional Commits

We use **Release Please** to automate our versioning and changelog generation. This means **all commits must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.**

### Format

`<type>[optional scope]: <description>`

### Allowed Types

- `feat:` A new feature (Correlates with MINOR in Semantic Versioning).
- `fix:` A bug fix (Correlates with PATCH in Semantic Versioning).

> **The type you choose sets the released version and what users are told they are getting.**
> `feat:` and `fix:` appear in the changelog and bump the version; every other type does
> neither. Reserve them for changes that reach someone who installs this package — anything
> under `.claude/`, `cli/`, `adapters/`, or the installers.
>
> Work on CI, tests, tooling or the build is `ci:`, `test:`, `chore:` or `build:`, however
> substantial it is. A `feat:` on a CI script produced release 2.6.0, a minor bump whose notes
> advertised "add dedupe-changelog.sh" — a script no user will ever have, in a version where
> the only published file that changed was `CHANGELOG.md` itself. That release was closed
> unreleased rather than ship notes describing nothing observable.

- `docs:` Documentation only changes.
- `style:` Changes that do not affect the meaning of the code (white-space, formatting, etc).
- `refactor:` A code change that neither fixes a bug nor adds a feature.
- `perf:` A code change that improves performance.
- `test:` Adding missing tests or correcting existing tests.
- `chore:` Changes to auxiliary tools and libraries, and other maintenance no other type covers.
- `ci:` Changes to the CI configuration files and scripts.
- `build:` Changes that affect the build system or external dependencies.
- `revert:` Reverts a previous commit; the subject repeats the reverted commit's header.

### Breaking Changes

To indicate a breaking change (MAJOR version bump), append a `!` after the type/scope:
`feat!: change core adapter generation mechanism`
Or add a `BREAKING CHANGE:` footer in the commit body.

### Atomic Commits (No "Loads of Diffs")

We strictly follow the **Atomic Commit** philosophy. An atomic commit is a commit that does **exactly one thing** (a single logical change).

- **Do not mix concerns:** Never mix a new feature with an unrelated bug fix, or a refactor with a whitespace cleanup in the same commit.
- **Why?** It prevents massive, unreadable PRs ("loads of diffs"), makes code review exponentially faster, and allows us to easily `git revert` or `git cherry-pick` a specific change without breaking the system.
- **Rule of Thumb:** If you have to use the word "and" in your commit message (e.g., `feat: added login AND fixed button alignment`), your commit is not atomic and should be split.

## 3. Pull Request Process

1. **Fork the repository** and create your branch from `main`.
2. **Use a descriptive branch name**: e.g., `feat/add-vitest-skills` or `fix/playwright-scaffolding`.
3. **Commit your changes** following the Conventional Commits specification.
4. **Do NOT update the `CHANGELOG.md` or `package.json` version.** Release Please will do this automatically when your PR is merged.
5. **Run tests/linters** locally if applicable.
6. **Merging**: use GitHub's default **"Create a merge commit"** — the button, or plain
   `gh pr merge <N> --merge`. This repository's setting writes the PR title into the merge
   commit's body, and that body is **the one changelog record Release Please is guaranteed to
   see.** Never merge with an empty body (`--body ""`), and never squash.

   **Why the merge commit is the record.** Release Please walks history newest-first and stops
   at the previous release commit. A PR whose commits were written before that release was
   merged sits behind it in the walk, so those commits are never visited — even though they are
   new to this release. Only the PR's merge commit, dated at merge time, is. That is why 2.7.0
   and 2.7.1 listed only merge commits. Merged with empty bodies, those PRs would have produced
   no entry at all, and no release would ever have been proposed for the work they carried —
   reproduced by simulating the walk over this repository's history.

   **Why the changelog is not duplicated.** When a PR's own commits *are* recent enough to be
   visited, the PR appears twice: once per commit, once for the merge. `dedupe-changelog.sh`
   runs in the release workflow and removes a merge-commit entry only when at least one of that
   PR's own commits is listed beside it in the same section. Otherwise the merge entry is the
   PR's only record and is kept. As a last line of defence it refuses to empty a section, and
   fails the workflow instead.

   **The net.** On every push to `main`, `verify-merge-commits.sh` fails the build if a PR merge
   commit carries no conventional-commit text, because that PR may now be missing from the next
   release. The merge cannot be undone without rewriting `main`; the fix is to check the release
   PR's changelog and write the PR's entry by hand.

   **Before merging a release PR**, read its CHANGELOG section: every PR merged since the last
   release must appear once, linked either to its merge commit or to its own commits.

   *History of this rule, kept for the record:* the duplication was first fixed by hand (#53),
   then by stripping every merge-commit entry (#55). That emptied 2.7.0's changelog, because its
   only entries were merge commits; #74 made the script refuse rather than empty a section, and
   2.7.0 and 2.7.1 were written by hand. #75 then proposed merging with empty bodies — which,
   once the walk was understood, would have hidden those releases entirely. It was closed
   unmerged, and the rule above replaced it.

## 4. Development & Testing

If you are modifying the shell scripts or adapter generation logic:

1. Run `shellcheck` on `.sh` files before submitting. CI fails on **every** finding, including
   style-level ones.
2. Run `markdownlint` to ensure markdown syntax is clean.
3. Test the installation locally via `tests/test-lifecycle.sh`, and
   `tests/test-lifecycle.ps1` if you touched `install.ps1`.

If you are modifying an installer (`install.sh`, `install.ps1` or `cli/qa-instinct.js`), also:

1. Read the file-safety contracts in `CLAUDE.md` first. All three installers share the
   `.qa-instinct-manifest` and `.qa-instinct-known-hashes` formats, and the suites round-trip a
   file written by one and read by another — changing one in isolation will break the others.
2. Keep `install.sh` compatible with **bash 3.2**, which is what macOS ships. `declare -A` and
   other bash 4 features will pass locally on Linux and fail on the macOS CI job.
3. Write the failing test first and quote its failure in the pull request. Every installer fix
   in `plans/009`-`plans/012` was proven this way, because several of these defects reached a
   published release by looking correct in review.

If you add, rename or remove an agent under `.claude/agents/`, list it in
`.claude-plugin/plugin.json` too: the Claude Code plugin names each agent file individually.
`tests/plugin/verify-plugin.sh` fails CI when the two drift apart. Commands and skills need no
change, because the plugin points at their folders.

CI runs the suites on Linux, Windows and macOS. A change that passes locally is not done until
all three are green.

### Running the Checks Locally

Run `npm ci` once; it also installs the commit hook, which checks every commit message against
section 2. `shellcheck` is a system package (`apt install shellcheck`, `brew install shellcheck`).
These are the steps of the CI job "Lint & Test (Linux)", by the name `ci.yml` gives them, from the
repository root:

| CI step | Command |
| --- | --- |
| Lint Bash Scripts (ShellCheck) | `shellcheck` on the scripts listed in that step of `ci.yml` |
| Lint JavaScript and Formatting (ESLint, Prettier) | `npm run lint` |
| Audit Shipped Dependencies (blocking) | `npm audit --omit=dev --audit-level=high` |
| Audit Dev Dependencies (report only) | `npm audit --audit-level=high` |
| Verify Known-Hash List Is Current | `./generate-known-hashes.sh --check` |
| Lint Markdown Files (MarkdownLint) | `npx markdownlint --dot "**/*.md" --ignore node_modules --ignore .git --ignore adapters` |
| Verify Generated Adapters | `./generate-adapters.sh --clean && ./tests/verify-adapters.sh` (it also runs `tests/test-generator-errors.sh`) |
| Run Conformance Suite | `./tests/conformance/test-runner.sh && ./tests/conformance/run.sh` |
| Test Evidence Checker | `./tests/test-check-test-evidence.sh` |
| Test Case Format Hook | `./tests/test-validate-tc-format.sh` |
| Hook Text Parity | `./tests/test-hook-parity.sh` |
| Skill and Command Frontmatter | `./tests/test-frontmatter.sh` |
| CTFL Section Citations | `./tests/test-ctfl-citations.sh` |
| Plan Format (Plans 038 On) | `./tests/test-plan-format.sh` |
| Efficacy Benchmark Integrity | `node benchmark/build.js --check && node benchmark/analysis/analyze.js --self-test` |
| llms.txt Links Resolve | `./tests/test-llms-txt.sh` |
| Corpus Index | `node generate-corpus.js --ref HEAD --out corpus/index.jsonl` (CI then validates the file) |
| Test Case Format Contracts | `./tests/test-tc-contracts.sh` |
| Claude Code Plugin Manifests | `./tests/plugin/verify-plugin.sh` |
| Always-Loaded Rules Size Cap | `./tests/test-rules-size.sh` |
| Agent Skill Body Size and Moved Detail | `./tests/test-skill-bodies.sh` |
| Skill Reference Pointers Resolve | `./tests/test-reference-links.sh` |
| Traceability Fixture (/qa-trace) | `./tests/test-qa-trace.sh` |
| Changelog Merge-Entry Dedupe | `./tests/test-dedupe-changelog.sh` |
| Node Engines Within Runtime Dependencies | `./tests/test-node-engines.sh` |
| Command Names and Sizes Match the Files | `./tests/test-docs-drift.sh` |
| TypeScript Samples Type-Check | `./tests/test-ts-samples.sh` |
| Run Integration Tests | `./tests/test-lifecycle.sh` |

For a quick pass before you push, `npm run lint` runs ESLint and Prettier, and `npm test` runs the
checks in the table that take a few seconds and need only Node and bash: frontmatter, citations,
plan format, `llms.txt`, test case contracts, both hook tests, the hook text parity check, the plugin
manifests, rules size, reference pointers, `/qa-trace`, the changelog dedupe, Node engines, command names and sizes,
TypeScript samples and the benchmark integrity check. It stops at the first failure. It does not run
ShellCheck, markdownlint, the known-hash check, the adapter generator, the corpus index, the
conformance suite or the integration tests: run those from the table when you touch what they cover.

The job "Test (macOS)" runs the adapters, conformance, both hook tests and the integration tests
again under bash 3.2. The job "Test (Windows)" runs PSScriptAnalyzer,
`.\generate-adapters.ps1 -Clean` with `.\tests\verify-adapters.ps1` (and through it
`tests\test-generator-errors.ps1`), a byte comparison of the bash
and PowerShell adapters, `.\tests\conformance\test-runner.ps1` with `.\tests\conformance\run.ps1`,
both hook tests under Git Bash, and `.\tests\test-lifecycle.ps1`. A pull request that touches only `plans/`, `docs/` or
Markdown at the repository root runs the Linux job alone.

## 5. Correcting Plans and Other Records

Nothing found wrong in a plan, a changelog note or any other working document is deleted. Correct
it in place with a dated note, or strike the text through with a note saying why. What was
believed, and when it changed, is part of this repository's audit trail.

`plans/014` is the example to copy: its measurements were later found to be phrase-grep
artifacts, and instead of rewriting them it carries blockquotes such as
`> **Correction, 2026-10-01.** ...` directly under the claims they correct. Rejected approaches
are kept the same way, with the reason they were rejected. The same convention is shipped to
users in the documentation-producing commands (`/qa-cases`, `/qa-defect`); its one canonical
wording is `.claude/skills/qa-reference/references/written-records.md`.

## 6. Citations and Ids in Shipped Content

Everything under `.claude/` is cited as evidence of what the package teaches, so each claim must be
checkable and each file must keep one name (plan 038).

**Citations.**

- In shipped content, `§` followed by a number means a section of the CTFL v4.0.1 syllabus and
  nothing else. Name any other document's sections in words: "(Valente, *Engenharia de Software
  Moderna*, section 8.3)".
- A sentence that states what the syllabus says cites the section beside it: `(CTFL v4.0
  §4.2.2)`, or `§4.2.2` alone inside a paragraph or banner that already names CTFL. Cite a chapter
  (`CTFL v4.0 Chapter 6`) only when the whole chapter is meant.
- Package practice that is not syllabus content says so ("Not ISTQB content: ...", or "the presets
  below are this package's") instead of borrowing a citation.
- Take section numbers only from `tests/fixtures/ctfl-v4.0.1-sections.txt`, which was read from the
  official PDF. A claim whose section is not in that list may not be from the syllabus: leave it
  uncited and say so in the pull request. A new syllabus version gets a new list and a deliberate
  migration of the citations; the v4.0.1 list is never edited.
- `tests/test-ctfl-citations.sh` fails on a `§` that is not in the list, and on a line that names
  CTFL without a `§` or a chapter. A line that legitimately names CTFL without citing (a role
  banner, a template placeholder) goes into `tests/fixtures/ctfl-uncited-allow.txt` with its reason;
  that list should only shrink.

**Ids.**

- Every shipped `.md` file opens with frontmatter holding an `id`: the basename for rules,
  commands and agents, the folder name for skills (under `metadata:` in a `SKILL.md`, because the
  Agent Skills specification allows no other top-level key), `ref-<basename>` for skill references.
  `tests/test-frontmatter.sh` enforces it.
- **An id is permanent.** Renaming or moving a file keeps its id. A deleted file's id is never
  reused. When two files merge, the one that remains keeps its id, and the pull request records the
  other.
- Do not add `version`, `title` or `istqb` to frontmatter: `generate-corpus.js` derives them (the
  version from the ref it indexes, the title from the first heading, the sections from the
  citations in each chunk), so a copy would drift. Never give a rule `paths:`, which would make it
  load only for matching files.

`node generate-corpus.js --ref <tag>` rebuilds the index of any version from git alone; the index is
not committed. A chunk's anchor (`<id>#<heading-slug>`) is valid for the version recorded beside
it, so cite the version or commit with the anchor.

## 7. The Contributions That Help Most

1. **A wrong or missing CTFL claim.** The package cites the CTFL v4.0.1 syllabus by section so that
   each claim can be checked against it. A claim the cited section does not support, a wrong section
   number, or a topic taught without its section is the most serious content defect it can have.
   Open a [wrong or missing CTFL claim](https://github.com/MarcoAmaral/qa-instinct/issues/new?template=ctfl-claim.yml)
   issue with the file, the claim quoted and the section.
2. **A field report.** You used a command or skill on real QA work and something happened: it
   caught a defect, missed one, produced a document your team could not use, or your assistant did
   something with an instruction that surprised you. A failure, written down with the output, is
   worth more than praise. Open a [field report](https://github.com/MarcoAmaral/qa-instinct/issues/new?template=field-report.yml).
3. **A worked example.** Real output on someone else's public software, committed unedited, with a
   `README.md` giving the prompt, the date, the package version, the editor and model, and honest
   limits. [`examples/README.md`](examples/README.md) shows the shape and which commands have one.
4. **An editor's install path.** An editor the package does not support yet, or a path an editor has
   moved. Bring the link to the editor's own documentation. Paths live in `.qa-instinct-editor-map`,
   which all three installers read; a new editor also needs its adapter in both generators, and
   either change starts with a failing conformance case (section 8).

Installer defects are welcome too: the [installer bug](https://github.com/MarcoAmaral/qa-instinct/issues/new?template=installer-bug.yml)
form asks for what decides whether a report reproduces. For a new skill or command, open a
[proposal](https://github.com/MarcoAmaral/qa-instinct/issues/new?template=proposal.yml) before
writing it. Security problems go to [SECURITY.md](SECURITY.md), never to a public issue.

## 8. The Evidence Bar

Everything under `.claude/` is read by an assistant as instructions and by people as evidence of
what the package teaches. A change is judged by whether it is true and checkable, not by whether it
reads well.

- **Syllabus claims cite a section.** Every sentence that says what the CTFL syllabus says cites a
  CTFL v4.0.1 section with `§`, taken from `tests/fixtures/ctfl-v4.0.1-sections.txt`. Section 6 has
  the full rule; `tests/test-ctfl-citations.sh` enforces it.
- **Other sources are named in words.** A book is cited by author, title and "section N.N"; a tool
  claim links the tool's own documentation. Primary sources only: a summary of a source is not the
  source.
- **Package practice says so.** Advice that is not syllabus content is labelled ("Not ISTQB
  content: ...", "the presets below are this package's") instead of borrowing a citation.
- **Write it in your own words.** Paraphrase and cite; do not copy text from the syllabus, a book or
  another project.
- **Installer changes start with a failing test.** A behaviour the three installers share is a
  case under `tests/conformance/cases/`, run against every installer. Write the case first, show it
  failing, and quote the failure in the pull request. Then change `install.sh`, `install.ps1` and
  `cli/qa-instinct.js` together, so they still behave identically, keeping the file-safety contracts
  in `CLAUDE.md` and bash 3.2 for `install.sh` (section 4).
- **The always-loaded rules stay small.** `.claude/rules/` loads into every conversation in an
  installed Claude Code project. `tests/test-rules-size.sh` caps the rules at 25,000 bytes and
  prints the approximate token cost; templates, examples and long procedures go into a reference
  under `.claude/skills/qa-reference/references/`. Shipped text names it "the `qa-reference`
  skill's `references/<file>.md`", the one form `tests/test-reference-links.sh` accepts: a path
  such as `qa-reference/references/<file>.md` is read from the project root and found in no
  install (plan 057).
- **Every skill body stays under 5,000 tokens.** Each command, agent and skill becomes an Agent
  Skill whose whole body loads when it is used; `tests/test-skill-bodies.sh` caps each source at
  20,000 bytes (about 5,000 tokens, the Agent Skills recommendation) and checks that the detail
  moved out of `qa-plan` and `/qa-cases` is in the reference section each body points to.
- **Every shipped file keeps its id.** A new file under `.claude/` opens with its `id` frontmatter
  (section 6) and a line in `llms.txt`; a new agent is also listed in `.claude-plugin/plugin.json`.
- **A report carries its context.** Package version, editor, install method, OS and shell, the
  exact command or prompt, and the output.

## 9. What Will Not Be Merged

- Installer behaviour with no test that failed first, or a change to one installer that the other
  two do not match.
- A syllabus claim with no section, with a section that is not in the v4.0.1 list, or package
  practice presented as syllabus content.
- Instructions written for one model, vendor or editor in shipped content. Everything under
  `.claude/` must work in every supported editor (`CLAUDE.md`, development convention 1); the
  editor-specific parts belong in the installers and the generator.
- Hand edits to `adapters/` (generated), and changes to `CHANGELOG.md` or the version (Release
  Please writes them).
- Growth of the always-loaded rules past the cap, or a long template moved into a rule.
- A change that lets an installer remove or overwrite a user's file without the backup the package
  promises.
- Text copied from the syllabus, a book or another project.
- Output from an AI assistant that you have not checked yourself. Drafting with an assistant is
  fine; this package exists for that. Signing off unchecked output is the failure it exists to
  prevent.

## 10. From Fork to Pull Request

1. Fork the repository on GitHub and clone your fork.
2. Run `npm ci` with Node 24, the latest LTS (24.15.0 or later: `ini` 7, under markdownlint-cli,
   declares `^24.15.0`). It installs the development tools and the commit hook.
3. Create a branch from `main` named for the change: `fix/...`, `feat/...`, `docs/...`, `test/...`.
4. Make the change. For an installer, write the failing conformance case first (section 8). After
   any change under `.claude/`, run `./generate-adapters.sh --clean`; the output is not committed.
5. Run the checks in section 4 that cover what you touched: markdownlint always; the conformance
   and integration suites for an installer; frontmatter, citations, references and rules size for
   content.
6. Commit as section 2 says: Conventional Commits, one concern per commit.
7. Push the branch to your fork and open a pull request against `main`. Fill in the template,
   including the failing output for an installer fix.
8. CI runs on the pull request; a maintainer may have to approve the first run from a new
   contributor. Fix anything red with new commits rather than a force push, so the review history
   stays readable.
9. The maintainer reviews and merges as section 3 describes. You do not need to edit the changelog
   or the version.

Thank you for helping us maintain a high-quality QA standard!
