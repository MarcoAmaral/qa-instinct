# Plan 069: `update` finishes a pre-manifest install in one run, and its closing note names the right command

> **Executor instructions**: Branch `fix/update-pre-manifest-install` from `main`, one pull request
> into `main`, two commits (item 1, item 2). Write each conformance case first and quote its
> failure against `main` before the installers change. All three installers change together in
> item 1's commit; never leave one behind in a commit that CI runs. `fix:` commits, so Release
> Please proposes 4.5.1. `npm publish` is **Marco's**.

## Status

- **Priority**: P2. A core command reports success on a half-updated install; running it again is
  a workaround, but nothing tells the user to.
- **Effort**: M. Item 1 touches the update path of all three installers; item 2 is one message.
- **Risk**: MEDIUM. The adopt path is what plans 011, 013 and 033 guard: update must still never
  install an editor that was not installed, and never overwrite a file the package cannot prove
  is its own.
- **Depends on**: plans 009-013 (manifest, known hashes, CLI parity, update), 016 (conformance
  suite), 033 item 3 (adopt only what a release shipped), 066 (manifest name)
- **Planned at**: commit `64e077c` (`main`), 2026-10-29

## Why this matters

On 2026-10-29 Marco brought two installs up to 4.5.0. Both exposed a defect.

- **MarcoWork's global install** dated from before manifests (2.3.3): 6 rules, 9 commands, 2
  skills, 4 agents and a hook, 22 files, every one a released file. `npx qa-instinct@latest update
  --global` adopted and refreshed the 22, printed "Update complete", and added nothing. The
  install was left with 22 of 54 files, and the refreshed rules point at the `qa-reference` skill,
  which was not there. A second run added the 32 missing files; a third reported "Everything is up
  to date".
- **SWARE's project install** (`~/swareco`) had a manifest, so one run did everything. Its closing
  note then told Marco to run `npm update -g qa-instinct`, although he had run
  `npx qa-instinct@latest` and has no global npm install.

Whoever updates an install made before 2.3.3 meets item 1; everyone who updates with `npx` reads
item 2.

## Reproduction (2026-10-29, commit `64e077c`)

- **CLI**: a scratch `HOME` holding the 16 `qa*` files from MarcoWork's backup.
  `HOME=<scratch> npx qa-instinct@4.5.0 update --global`: 0 files added, a 16-line manifest. The
  same with `node cli/qa-instinct.js`: the next run added 38.
- **`install.sh`**: a scratch project holding only conformance case 003's fixture
  (`.claude/commands/qa.md` as 2.3.0 shipped it). `install.sh --update --target project --editor
  claude --non-interactive`, three times: run 1 adopted the one file, "Update complete", 1 file,
  1-line manifest; run 2 added the rest, 54 files, 54-line manifest; run 3 "Everything is up to
  date".
- **`install.ps1`**: not run (no `pwsh` on this machine). Its update has the same two branches;
  the executor confirms the failure on Windows CI with the red case.

## Cause

Each installer decides once, at the start of an update, whether the target had a manifest:

- `cli/qa-instinct.js` `cmdUpdate`: with a manifest, `updateManifestEditor` per recorded editor
  (refresh, **add new files**, prune). Without one, `detectAndAdoptEditor` only (adopt).
- `install.sh` `update_to_editor`: `UPDATE_NO_MANIFEST_BASES` records the base as manifest-less for
  the whole run, so every editor goes to `adopt_known` and never to `install_to_editor`.
- `install.ps1`: the same split (`Adopted` handling around lines 885-1067 and 1478).

Adopting writes the manifest, so the **next** run takes the manifest branch and adds the missing
files. Plan 013 item 3 wrote the rule as "update must never create a file that isn't already
there". Its purpose was per editor (never silently install an editor that was not installed),
but it was implemented per file, and the second run already overrides it. The rule only delays
the add by one run and hides that delay behind "Update complete".

## Item 1: add the new files in the same run

**Contract (all three installers, identical).** In an update with no manifest:

1. Adopt every editor exactly as today (by hash only, never on the strength of a path).
2. An editor that adopted **at least one** file is installed. In the same run, take it through the
   path the manifest branch takes (refresh, add what this release ships, prune what it recorded),
   as if the run had started with the manifest the adopt step just wrote.
3. An editor that adopted nothing is not installed, and nothing is written for it: conformance
   case 019 ("update with nothing installed writes nothing") still holds, now per editor.

**The consequence to accept.** In step 2, a file at a package path that adoption left alone (the
user's own content) meets the install path's collision handling: it is backed up to
`<file>.qa-instinct-backup-<UTC>`, then replaced. That is what the second run does today and what
`init` does. Option B below avoids it; this plan recommends A.

**Red cases** (next free numbers, 087-089), each failing against `main`:

- **087, update of a pre-manifest install adds what the release ships in one run**: seed case 003's
  `qa-v2.3.0.md` at `project:.claude/commands/qa.md`; `run: update project claude`; expect
  `Adopted`, `expect-same-as-package` and `expect-manifest` for `.claude/skills/qa-reference/SKILL.md`
  and `.claude/rules/test-tools.md`, and `expect-tree-as-package` for `.claude/rules`.
- **088, a user's file at a package path is backed up, not lost**: as 087, plus
  `project:.claude/rules/security-qa.md = MY OWN POLICY`; expect a backup with that content and
  the package's file in place.
- **089, an editor with nothing adopted is still not installed**: as 087 with `run: update project
  all`; expect `project:.cursor`, `.windsurf`, `.github/skills`, `.cline` and `.agents` absent.

**Other tests**: lifecycle Test 35 (bash) and its PowerShell twin assert the adopt half; extend
each to require the added files. Lifecycle tests that rely on update adding nothing to a
pre-manifest install must change with the contract; the executor lists any found.

## Item 2: a closing note that is true however the CLI was run

`printUpdateReport` (CLI only; `install.sh` and `install.ps1` print no such note) ends every run
that wrote a file with "To pick up a newer release, run 'npm update -g qa-instinct' first". That is
right only for a global npm install. Through `npx` it names a command that does nothing useful.

**Change**: name the version that ran and both ways to get a newer one, without detecting how the
CLI was started (detection through npm's environment variables is fragile and adds nothing):

> Note: these are qa-instinct 4.5.1's files. For a newer release, run 'npx qa-instinct@latest
> update', or 'npm update -g qa-instinct' first if you installed it with npm -g.

The `--help` text for `update` ("Refreshing does not check npm…") changes to match. No test greps
the old wording. The note is the CLI's alone, so the test is a CLI lifecycle assertion, not a
conformance case: after an update that writes a file, the output names the running version and
both commands.

## Verification

- Cases 087-089 fail on `main` (quote the output) and pass after, on all three installers.
- `./tests/conformance/run.sh` and `./tests/test-lifecycle.sh` green locally; Linux, Windows and
  macOS CI green (the PowerShell suites run only there).
- By hand: MarcoWork's backup (16 or 22 files) in a scratch `HOME`, one `update --global`, then 54
  files, and a second run reports "Everything is up to date".
- Release 4.5.1; Marco publishes it; checked against the registry the same way.

## Rejected approaches

- **B: add only files whose destination does not exist.** Leaves a user's file at a package path
  alone in this run, but the next update (manifest now present) backs it up anyway, so it only
  moves the backup to a later run and keeps the two-run behaviour for that file. Kept here in case
  Marco prefers it.
- **Tell the user to run update again.** Documents the defect instead of fixing it.
- **Make update always behave like `init`.** Breaks plan 013's rule that update never installs an
  editor that was not installed (case 019).
- **Detect `npx` for item 2** (`npm_command=exec`, `npm_config_user_agent`): fragile across npm
  versions and package runners (`pnpm dlx`, `bunx`), and one message covering both routes is true
  for all of them.
