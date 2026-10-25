# Plan 065: Rename to QA Instinct, publish it, and remove the old npm package

> **Executor instructions**: Branch `feat/qa-instinct-rename` from `main`, one pull request into
> `main`. One commit for this plan and the decision, then one commit per area of the rename. The
> GitHub rename (step 2) is approved for this task and comes before the code, so the new package's
> URLs are right from its first version. `npm publish` is **Marco's** (he logs in to npm, 2FA may
> ask for a code); prepare it and hand it over. Release as a normal Release Please 4.2.0.

## Status

- **Priority**: P1. The name is the first thing a reader sees, and the package has no users yet.
- **Effort**: M
- **Depends on**: plan 020 (the last rename, whose keep-list this follows); `decisions/name.md`
- **Planned at**: commit `a7ab7ab` (`main`), 2026-10-25
- **Outcome**: done; `qa-instinct` 4.2.0 published on 2026-10-25 (PRs #8, #11, #10, and this
  one for the demo); see "Outcome"

## Why this matters

Marco decided on 2026-10-25 (`decisions/name.md`, "Decision (2026-10-25)"): "Bem-te-vi" says
nothing about QA to anyone who does not know the bird. **QA Instinct** says what the package does:
a senior QA's instincts loaded into an AI assistant, which is what the README's "a QA engineer's
brain already loaded" promises. Nobody depends on the old name yet, so this is the cheapest moment
there will be.

## Evidence (re-checked 2026-10-25, before acting)

| Check | Result |
| --- | --- |
| `npm view qa-instinct` | 404, the name is free |
| GitHub `MarcoAmaral/qa-instinct` | does not exist |
| `@marcoamaral/bem-te-vi` on npm | already 404 on 2026-10-25 01:08 UTC (Marco: already unpublished) |
| GitHub `MarcoAmaral/bem-te-vi` | public, 0 stars, 0 forks |
| Release tags | `v4.1.0`, `v4.1.1`; `include-component-in-tag` is false, so the package name is not in any tag |
| Old-name occurrences | 1,001 in tracked files; 80 files outside the historical record |

The prompt's evidence (2026-10-25, other session) also found 147 downloads of the old package,
all on its publish day, and no web or GitHub presence for "QA Instinct" beyond a Ministry of
Testing talk titled "Testing With Instinct".

## Identifiers

| What | From | To |
| --- | --- | --- |
| Display name | Bem-te-vi | QA Instinct |
| npm package | `@marcoamaral/bem-te-vi` | `qa-instinct` (unscoped, `npx qa-instinct init`) |
| CLI command (`bin`) and its file | `bem-te-vi`, `cli/bem-te-vi.js` | `qa-instinct`, `cli/qa-instinct.js` |
| GitHub repository | `MarcoAmaral/bem-te-vi` | `MarcoAmaral/qa-instinct` (GitHub redirects the old URL) |
| Claude Code plugin and marketplace | `bem-te-vi` (`/bem-te-vi:qa-cases`) | `qa-instinct` (`/qa-instinct:qa-cases`) |
| Generated rule files (non-Claude editors) | `bem-te-vi.<ext>`, `bem-te-vi-<rule>.<ext>` | `qa-instinct.<ext>`, `qa-instinct-<rule>.<ext>` |
| Rule section markers in merged adapters | `<!-- bem-te-vi-<rule> -->` | `<!-- qa-instinct-<rule> -->` |

The generated rule files change name safely: for every editor but Claude, `update` prunes each
recorded path the package no longer ships (plan 047), so an update from 4.1.x removes the
unchanged `bem-te-vi-*` files and writes the `qa-instinct-*` ones; a changed one is kept and
reported, as always.

## Keep-list (not renamed, and why)

- **`.qa-skills-manifest`, `.qa-skills-known-hashes`, `.qa-skills-editor-map`, the backup suffix,
  `QA_SKILLS_DEBUG`, the `qa-skills` hook comments**: plan 020's keep-list, unchanged.
- **The global pre-commit hook markers** `# >>> bem-te-vi global pre-commit >>>` and
  `# <<< bem-te-vi global pre-commit <<<` (`install.sh`, `install.ps1`): uninstall finds the block
  it wrote by these exact lines, so renaming them would strand every hook installed so far, the
  same reason plan 020 kept the `qa-skills` hook comments.
- **Historical record**: `CHANGELOG.md` past entries, `plans/`, `decisions/` (earlier sections),
  `history/`, `prompt-history/`, `known-hashes-before-public.txt` (sealed at export).
- **Recorded output**, committed as produced: `examples/`, `evals/results/`,
  `benchmark/results/`. Each names the package and version it ran on.
- **`tests/fixtures/release-v4.0.1/`**: a copy of an old release, there to prove updates from it.
- **Comments that describe an old install's paths**, for example `.bem-te-vi/` in
  `prune_unshipped`: they name what older versions wrote.
- **The demo recording** (`demo/bem-te-vi.gif`, `.mp4`): it runs the published package, so it is
  re-recorded after `qa-instinct` is on npm, in a follow-up pull request (Marco, 2026-10-25). The
  tape and scripts are renamed now.

## The benchmark

Condition D invokes `/bem-te-vi:<command>` (`benchmark/PROMPTS.md`), so the rename changes a
frozen prompt. Marco decided on 2026-10-25:

- The Extension arm on `claude-fable-5-1` (`DEVIATIONS.md`, 2026-10-23), four of nine tasks
  collected, finishes from its pinned checkout of `9381269` under the old name, so it stays one
  arm.
- On `main`, `PROMPTS.md` and `build.js` move to `/qa-instinct:`, the case digest is frozen again
  in `cases.sha256`, `METHODOLOGY.md` gains a version row, and `DEVIATIONS.md` an entry, all
  before Arm 1 is collected. The pilot's disclosure keeps the commands it ran.

## Steps

1. **Re-check** that `qa-instinct` is free on npm and `MarcoAmaral/qa-instinct` does not exist.
2. **Rename the GitHub repository**: `gh repo rename qa-instinct -R MarcoAmaral/bem-te-vi`, then
   `git remote set-url origin git@github.com:MarcoAmaral/qa-instinct.git` and `git fetch`.
3. **Rename in the code**, one commit per area: package and CLI (`package.json` `name`, `bin`,
   URLs, `npm install` for the lock file; `git mv cli/bem-te-vi.js cli/qa-instinct.js`);
   installers and generators; the plugin manifests and the commands' and skills' product name;
   tests and conformance cases that name the old command or rule files; README, CONTRIBUTING,
   SECURITY, ROADMAP, CLAUDE.md, `llms.txt`, issue templates, CI; demo scripts; the benchmark.
   The CHANGELOG gets the rename from Release Please's entry for 4.2.0; past entries stay.
4. **Verify**: the grep below prints only keep-list hits; adapters regenerate; the lifecycle and
   conformance suites, `tests/verify-adapters.sh`, `./generate-known-hashes.sh --check`,
   `node benchmark/build.js --check`, lint and markdownlint pass locally; CI is green on Linux,
   Windows and macOS.
5. **Release and publish (Marco)**: merge the PR, then the Release Please PR (4.2.0); then
   `npm login` and `npm publish` from a clean checkout of the tag. In a scratch folder,
   `npx qa-instinct@latest init --editor claude` installs.
6. **The old package**: Marco unpublished `@marcoamaral/bem-te-vi` before this plan ran; confirm
   `npm view @marcoamaral/bem-te-vi` still returns 404.
7. **Report** `https://www.npmjs.com/package/qa-instinct`, `https://github.com/MarcoAmaral/qa-instinct`
   and the published version, for the portfolio site.

```bash
git grep -nIiE 'bem-te-vi|bemtevi' -- . ':!CHANGELOG.md' ':!plans/' ':!decisions/' ':!history/' \
  ':!prompt-history/' ':!examples/' ':!evals/results/' ':!benchmark/results/' \
  ':!known-hashes-before-public.txt' ':!tests/fixtures/release-v4.0.1/'
```

## Version

Renaming the command is breaking for anyone who scripted `bem-te-vi`, and plan 020 made its rename
a major for that reason. This one is a minor, 4.2.0, by Marco's decision: the package is published
under a new name, so nobody's `npm update` moves them across, the old package has no users, and a
continuous series keeps the release history readable.

## Downstream (Marco, not from this repository)

Projects that installed with the old CLI (the portfolio, MoutsTI, the SWARECO workspace) update
with `npx qa-instinct update`. The manifest names files, not the package, so the new CLI finds the
install; for non-Claude editors it swaps the `bem-te-vi-*` rule files for `qa-instinct-*`. A
global hook installed earlier keeps working and is still removed by uninstall (keep-list).

## Rejected approaches

- **Rename the hook markers too**: strands every installed hook unless all three installers learn
  both marker pairs, for no user-visible gain.
- **Edit recorded output so the grep is empty**: breaks the "committed as produced" promise of
  `examples/` and the benchmark's raw outputs.
- **Re-record the demo in this PR**: the recording runs the published package, which does not
  exist under the new name until step 5.
- **Rename the Fable arm's remaining tasks**: mixing two command prefixes in one arm.

## Verification

- `git grep` (above) prints only the hook markers and comments on the keep-list.
- `node cli/qa-instinct.js --help` prints `qa-instinct`; `npm pack --dry-run` shows `qa-instinct`.
- The full CI check list is green on Linux, Windows and macOS.
- After step 5: `npm view qa-instinct version` prints 4.2.0, and `npx qa-instinct@latest init`
  works in a clean folder; `npm view @marcoamaral/bem-te-vi` returns 404.

## Outcome

- **Steps 1-2**: `qa-instinct` was free on npm and GitHub; the repository was renamed to
  `MarcoAmaral/qa-instinct` and the old URL answers 301.
- **Steps 3-4**: PR #8, rebased onto PR #7 (one conflict, both rows of `plans/README.md` kept), the
  full local CI list and CI on Linux, Windows and macOS green. Two checks failed on the first local
  run and were fixed in the rename commit: the README's measured always-on sizes (the new name is
  two characters longer) and the docs drift check, which read the plugin prefix `/qa-instinct:`
  as an unknown command and now skips a name followed by `:`. An update from an install made at
  `9381269`, run by hand, removed the 39 unchanged `bem-te-vi-*` rule files, wrote 40
  `qa-instinct-*` ones and kept the one edited by hand.
- **The changelog header** still named Bem-te-vi, because the rename left `CHANGELOG.md` alone;
  PR #11 renamed the header before the release. Past entries are unchanged.
- **Step 5**: Release Please opened the 4.2.0 release as PR #10 on a new branch, since its branch
  name follows the package name; the 4.1.2 release PR it had opened for PR #7 (#9) was closed as
  superseded. `v4.2.0` is tagged at `0cb704d`. Marco published from the tag on 2026-10-25 at
  20:20 UTC, not from `main`, whose next commit only adds 4.2.0's hashes to
  `.qa-skills-known-hashes` for the next release. `npm publish` asked for a second browser
  approval after `npm login`. npm also lists `0.0.0-stage`, the placeholder its staged publishing
  creates; `latest` is 4.2.0. `npx qa-instinct@latest init --editor claude` installed in a clean
  folder and `uninstall` removed its 52 files.
- **Step 6**: `npm view @marcoamaral/bem-te-vi` returns 404.
- **The demo**, re-recorded with `demo/record.sh` from the 4.2.0 tree: nine test cases, the hook
  passed, US$0.31 on Claude Sonnet 5.5 (`demo/README.md`, "The last recording").
- **Local**: the working folder is `~/Projetos/qa-instinct`, its linked worktrees repaired.
