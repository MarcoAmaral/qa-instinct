# Plan 064: Keep the two installers' git hook texts identical, and pin every hook a release wrote

> **Executor instructions**: Branch `refactor/hook-template` from `main`, one pull request into
> `main`. Commits in the order of "Commit sequence" below: the characterisation tests first (green
> on `main`), then the parity tests (red on `main` for one byte), then the one-line fix. **Neither
> hook's text changes**: do not reword, reformat or "fix" a line of either hook, and do not change
> any marker constant. The only change to an installer is item 3's final newline. Read `CLAUDE.md`
> section 5 and `plans/026` (the hook's own file-safety rules) before touching `install.ps1`.
> `install.sh` must still run on bash 3.2 and `install.ps1` on Windows PowerShell 5.1. Run
> `bash ~/qa-ci-all.sh <worktree>` on all three platforms before reporting.

## Status

- **Priority**: P3 (no user-visible defect today; it removes a way for one to appear)
- **Effort**: M (item 1's fixtures are most of it)
- **Risk**: LOW (tests, plus one byte in the project hook `install.ps1` writes, proven safe by
  item 1 before it lands)
- **Depends on**: plan 016 (what stays in the lifecycle suites), plan 026 (the hook's file-safety
  rules)
- **Category**: installers, parity, tests
- **Planned at**: commit `b03e9ed` (`main`), 2026-10-23
- **Decided**: Marco, 2026-10-23: a parity test, not a shared template (see "Rejected approaches")
- **Outcome**: done, branch `refactor/hook-template` (PR to be opened); see "Outcome"

## Why this matters

`ROADMAP.md:77-78` lists it under "Planned Next": `install.sh` and `install.ps1` each carry their
own copy of the pre-commit hook they register.

**The texts are the same today.** The body of the project hook (`install.sh:450-473`, heredoc
`PRECOMMIT`; `install.ps1:428-451`, `$hookContent`) and of the global block (`install.sh:365-387`,
`global_hook_block`; `install.ps1:323-343`, `$Script:GlobalHookBlock`) are line-for-line identical
on `main` (checked by extracting all four and running `diff`). Both are ASCII.

**They have drifted before, for five releases.** In the old repository
(`/home/marco/Projetos/qa-skills`, read-only), commit `db19377` ("replace echo -e with printf
'%b\n' for sh compatibility", released in v2.7.0) changed the hooks in `install.sh` only.
`install.ps1` kept writing the `echo -e` hooks through v2.7.0, v2.7.1, v2.7.2, v2.8.0, v2.9.0,
v3.0.0 and v4.0.0, until v4.0.1 rewrote both. The fresh global hook drifted too: v4.0.0
`install.sh` wrote the header line, `# Added by qa-skills global installer` and
`# GLOBAL_PRECOMMIT_APPEND`; v4.0.0 `install.ps1` wrote only the header. Both removal functions still
carry special cases for that difference (`install.sh:389-412`, `install.ps1:345-380`). No test
compares the two installers' hooks, so nothing would catch the next drift.

**One byte differs today.** A PowerShell here-string does not include the line break before its
closing `'@`, so `install.ps1` writes the project hook without a final newline
(`install.ps1:451-453`), and `install.sh` (a heredoc) with one. Checked with Windows PowerShell 5.1
on a two-line here-string written with `WriteAllText`: the file ends in `f i`, no `\n`. The global
block has no such difference: `install.ps1:343` appends `` "`n" ``.

**What is not affected.** `cli/bem-te-vi.js` registers no git hook (its only "hooks" code is
`chmodHooks`, `cli/bem-te-vi.js:81`, which sets the mode of `.claude/hooks/*.sh`). The conformance
runners always pass `--no-hooks` / `-NoHooks` (`tests/conformance/run.sh:189`,
`tests/conformance/run.ps1:173`), and plan 016 item 6 keeps "git integration and hook
registration" in the lifecycle suites (`plans/016-installer-conformance-suite.md:127-131`).

## How an existing hook is recognised

Every hook a release ever wrote is recognised by **constants**, never by comparing it with the
current text:

| Constant | `install.sh` | `install.ps1` | Used for |
| --- | --- | --- | --- |
| `Pre-commit hook to validate test cases in qa-skills` (substring) | `PROJECT_HOOK_MARKER`, :337; read at :441 and :1308 | `$Script:ProjectHookMarker`, :257; read at :415 and :533 | "this project hook is ours": overwrite on install, delete on uninstall |
| `validate-tc-format.sh` (substring) | :497, :1327 | :483, :556 | "this global hook already has our block" / "may have our block" |
| `# >>> bem-te-vi global pre-commit >>>`, `# <<< bem-te-vi global pre-commit <<<` | `GLOBAL_HOOK_BEGIN/END`, :356-357 | `$Script:GlobalHookBegin/End`, :314-315 | fence of the current block (v4.0.1 on) |
| `# Added by qa-skills global installer` | `GLOBAL_HOOK_OLD_MARKER`, :358 | `$Script:GlobalHookOldMarker`, :316 | start of a block from v2.0.0-v4.0.0; the block then ends at the first line that is exactly `fi` |
| `# GLOBAL_PRECOMMIT_APPEND` | `GLOBAL_HOOK_OLD_END`, :359 | `$Script:GlobalHookOldEnd`, :317 | old end line, kept inside the current block so an older uninstaller still finds it |
| `# Global pre-commit hook to validate test cases in qa-skills` | `GLOBAL_HOOK_FRESH_HEADER`, :360; also written at :508 | `$Script:GlobalHookFreshHeader`, :318; also written at :500 | start of a fresh hook an older `install.ps1` wrote with no "Added by" line; and "nothing but our header is left, delete the file" (:1337, :564-568) |

The project hook is recognised by a substring anywhere in the file, so its final newline plays no
part in recognising it. Item 1 proves this, and everything else in the table, against the real
bytes of every release instead of leaving it to this reading.

## Items

1. **Pin the hook every release wrote, and how each is treated** (characterisation, green on
   `main`).
   - `tests/fixtures/git-hooks/` holds one file per distinct hook a release wrote, with the bytes
     the writer produced. The distinct texts, found by hashing the heredoc and here-string bodies
     at every tag of the old repository and at `v4.1.0` here:

     | Kind | Text | Written by |
     | --- | --- | --- |
     | project | `echo -e` | `install.sh` v2.0.0-v2.6.1; `install.ps1` v2.1.0-v4.0.0 |
     | project | `printf '%b\n'`, whitespace-split loop | `install.sh` v2.7.0-v4.0.0 |
     | project | current | both, v4.0.1-v4.1.0 |
     | global, fresh | header only, no "Added by" | `install.sh` v2.0.0; `install.ps1` v2.1.0-v4.0.0 |
     | global, fresh | header, "Added by", `echo -e`, `# GLOBAL_PRECOMMIT_APPEND` | `install.sh` v2.1.0-v2.6.1 |
     | global, fresh | header, "Added by", `printf`, `# GLOBAL_PRECOMMIT_APPEND` | `install.sh` v2.7.0-v4.0.0 |
     | global, fresh | header and the fenced block | both, v4.0.1-v4.1.0 |
     | global, appended | `echo -e` block, ends at `fi` | `install.sh` v2.0.0-v2.6.1; `install.ps1` v2.1.0-v4.0.0 (`Add-Content`) |
     | global, appended | the v2.0.0 `install.ps1` block (an expandable `@"..."@` string) | `install.ps1` v2.0.0 |
     | global, appended | `printf` block, ends at `fi` | `install.sh` v2.7.0-v4.0.0 |
     | global, appended | fenced block | both, v4.0.1-v4.1.0 |

     A file written by `install.ps1` gets the PowerShell semantics: a here-string written with
     `WriteAllText` has no final newline; `Add-Content` ends every line with CRLF. Before
     `.gitattributes` forced LF (first in v2.7.2, old-repo commit `9dcab8f`), a Windows clone had
     CRLF in `install.ps1` itself, so every `install.ps1` text up to v2.7.1 also gets a CRLF
     variant. **Every project text gets both a with- and a without-final-newline file**, whichever
     installer wrote it, because item 3 depends on both being handled.

     The v2.0.0 `install.ps1` block is a double-quoted here-string (`$appendContent = @"`, old
     repository `v2.0.0:install.ps1:273`), so what it wrote depended on the user's variables.
     Produce that fixture by evaluating the here-string in Windows PowerShell 5.1 with
     `$HOME = 'C:\Users\user'`, not by copying the source text.
   - `tests/fixtures/git-hooks/extract.sh <old-repo> <this-repo>` writes the files from
     `git show <tag>:install.sh` / `install.ps1` (read only: no checkout, no write in either
     repository) and prints each file's SHA-256. It is committed for the audit trail and not run
     by CI (CI has no old repository). Each appended fixture is stored as a whole hook,
     `#!/bin/sh`, `echo before`, the block as that release appended it, `echo after`, with a
     `.expected` file beside it holding what uninstall must leave: `#!/bin/sh`, `echo before`,
     `echo after`, in the fixture's own line endings.
   - `.gitattributes` gains `tests/fixtures/git-hooks/** -text`, as for the other release fixtures.
   - Bash Test 72 and PowerShell Test 56 (the next free numbers; plan 063 adds bash Test 71) run
     every fixture against their own installer, in a fresh repository and a throwaway `HOME` /
     `USERPROFILE`, as Tests 40-41 (bash) and 39-40 (PowerShell) do:
     - **project**: seeded as `.git/hooks/pre-commit`, `install --target project --editor claude`
       replaces it with the current hook (it is recognised as ours); seeded again, `uninstall`
       removes it.
     - **global, fresh**: seeded as `~/.git-templates/hooks/pre-commit`, `uninstall --target
       global` removes the file; seeded again, `install --target global` leaves it byte for byte
       (today's behaviour, see "Findings outside scope").
     - **global, appended**: `uninstall --target global` leaves exactly the `.expected` bytes.

   **Done when** both tests pass on `main` unchanged, on Linux, under bash 3.2 and in PowerShell
   5.1, and the pull request lists each fixture with its SHA-256 and the tags that wrote it.

2. **Parity tests** (red on `main`, for the final newline only).
   - **a, static: `tests/test-hook-parity.sh [repo-dir]`** (default: this repository), bash, no
     dependency beyond `awk`, `cmp` and `grep`. It extracts four bodies by their anchors and
     compares them in pairs, byte for byte, as text lines:
     - `install.sh`, the lines after `cat > "$HOOK_FILE" << 'PRECOMMIT'` up to the line
       `PRECOMMIT`, against `install.ps1`, the lines after `$hookContent = @'` up to the line `'@`;
     - `install.sh`, the lines after `cat << 'GLOBAL_PRECOMMIT_BLOCK'` up to the line
       `GLOBAL_PRECOMMIT_BLOCK`, against `install.ps1`, the lines after
       `$Script:GlobalHookBlock = ((@'` up to the line starting `'@)`.

     It also compares the six constants of the table above, each read from its assignment line in
     both files (`PROJECT_HOOK_MARKER=` / `$Script:ProjectHookMarker =`, and so on), and checks
     that the project body's second line is `# Pre-commit hook to validate test cases in qa-skills`
     and the global body's first two and last two lines are the fence and old-marker lines in the
     table's order, with those strings written literally in the test. **Any extraction that comes
     back empty fails the test**, so a moved anchor cannot make it pass vacuously. Green on
     `main`; prove it can fail by running it on a copy of the repository with one hook line
     changed in `install.ps1` only, and quote that failure in the pull request.
   - **b, bytes written** (bash Test 73, PowerShell Test 57). The text lines are not the whole hook:
     the final newline is a property of how each installer writes, which only a run shows. Item 1's
     `tests/fixtures/git-hooks/` gains `current/` with the three hooks `install.sh` on `main`
     writes: a project install into a fresh repository, a global install with no hook, and a global
     install onto `#!/bin/sh\necho before\n`. Each lifecycle suite runs its own installer the same
     three ways and compares the result with those files byte for byte (`cmp` / SHA-256). Bash
     Test 73 is green on `main`; PowerShell Test 57 is red on `main` for the project hook's
     missing final newline, and for nothing else. Quote that failure in the pull request.

   **Done when** `tests/test-hook-parity.sh` passes and its forced failure is quoted, bash Test 73
   passes, and PowerShell Test 57 fails on `main` only on the project hook's final byte.

3. **`install.ps1` ends the project hook with a newline.** Precondition: item 1 is green, which
   shows that both installers recognise, replace and remove every project hook with and without a
   final newline (item 1's "both variants" rule). If it is not green for both variants, do not do
   this item: the STOP below applies. The change is at `install.ps1:428-451`: the here-string
   becomes `$hookContent = (@'` ... ``'@) + "`n"``, as `$Script:GlobalHookBlock` already does at
   :323 and :343. Nothing else changes: not the text, not the encoding (`UTF8Encoding($false)`,
   :452-453), not the recognition. Line endings are left alone (`.gitattributes` checks
   `install.ps1` out with LF).

   **Done when** PowerShell Test 57 passes, and every existing PowerShell lifecycle test (39, 40,
   46, 54), item 1's Test 56 and `tests/conformance/run.ps1` pass in Windows PowerShell 5.1.
   PSScriptAnalyzer stays clean (`.github/workflows/ci.yml:324`).

4. **CI and records.**
   - `.github/workflows/ci.yml`: a step "Hook Text Parity" in the Linux job running
     `./tests/test-hook-parity.sh`, and the script added to the step "Lint Bash Scripts
     (ShellCheck)" (:106-110). Add it to `package.json`'s `test` script, after
     `tests/test-validate-tc-format.sh`.
   - `CONTRIBUTING.md` section 4: a row `| Hook Text Parity | ./tests/test-hook-parity.sh |` in
     the table, and the `npm test` sentence names it. Marco's local `~/qa-ci-local.sh` (outside
     the repository) repeats the ShellCheck list and the steps: tell him in the pull request.
   - `ROADMAP.md:77-78`: remove the item.
   - `plans/README.md`: this plan's row.

   **Done when** `bash ~/qa-ci-all.sh <worktree>` passes on Linux, macOS (bash 3.2) and Windows,
   and the row says DONE with the pull request number.

## Commit sequence

1. `test: pin the git hooks every release wrote` (item 1: fixtures, `extract.sh`,
   `.gitattributes`, bash Test 72, PowerShell Test 56; green)
2. `test: check that both installers embed the same git hook text` (item 2a; green, forced failure
   quoted in the pull request)
3. `test: require both installers to write the same git hook bytes` (item 2b: `current/` fixtures,
   bash Test 73, PowerShell Test 57; red in PowerShell)
4. `fix: end the project hook install.ps1 writes with a newline` (item 3)
5. `ci: run the hook text parity check` (item 4: `ci.yml`, `package.json`, `CONTRIBUTING.md`)
6. `docs: drop the git hook item from the roadmap` (item 4, `ROADMAP.md`)
7. `docs(plans): record plan 064's outcome`

The pull request title: `test: keep the installers' git hook texts identical`.

## STOP conditions

- **A characterisation test fails on `main`** (item 1). An installer mis-handles a hook a release
  wrote: that is a defect, not part of this plan. Stop, report the fixture and the output, and
  plan the fix separately.
- **Item 1 shows a project hook handled differently with and without its final newline.** Then the
  newline is not provably safe: skip item 3, and make Test 57 compare the project hook after
  removing exactly one trailing LF from both sides (and say why in the test and the pull request).
  No other normalisation.
- **PowerShell Test 57 fails on `main` on anything but the project hook's final byte.** That is a
  second, unknown drift: stop and report it.
- **A recognition constant or a hook line would have to change.** Out of scope; stop.
- **A distinct hook text is found that the table in item 1 does not list** (for example in an
  `archive/*` tag, or a release this plan did not hash). Add it as a fixture; if any current
  installer mis-handles it, the first STOP applies.

## Rejected approaches

- **A shared template** (`git-hooks/project-pre-commit.sh` and `git-hooks/global-pre-commit-block.sh`
  at the root, read at run time by both installers, as `.qa-skills-editor-map` is). Decided by
  Marco, 2026-10-23: a parity test stops the drift with no change to how either installer writes a
  hook and no new failure mode (a missing template file).
- **A conformance case.** The runners always pass `--no-hooks` (`run.sh:189`, `run.ps1:173`), the
  CLI registers no hook, and plan 016 item 6 keeps hook registration in the lifecycle suites. A case
  would need new directives in both runners and in `test-runner.sh`/`.ps1`, and `skip: cli` on every
  hook case, for a guarantee two installers share. The lifecycle tests read one fixture folder
  instead, so both installers meet the same bytes.
- **Only the static check.** It compares source text and cannot see the final newline, which is a
  property of how each installer writes; item 2b exists for that.
- **Only the lifecycle byte check.** Drift would show only in the Windows job, after a full run; the
  static check fails in seconds on Linux and in `npm test`.
- **Normalising every line ending in the comparison.** It would hide exactly the kind of byte
  difference this plan exists to find; only the one-byte fallback in the STOP conditions is allowed.
- **Changing the hook text in the same pull request** (for example to refresh old global hooks).
  Out of scope; see below.

## Findings outside scope

- **A global hook is never refreshed.** `install.sh:497` and `install.ps1:483` do nothing when the
  global hook already names `validate-tc-format.sh`, so a user who installed globally with v2.x
  still runs the `echo -e`, whitespace-split block today, which mis-handles file names with spaces
  (the defect plan 026 item 4 fixed in the current block). The project hook is replaced on every
  install. Refreshing the global block in place is a separate change for a later plan; item 1's
  fixtures are the tests it would need.
- **Old `install.ps1` uninstallers cut too much.** v4.0.0's `Purge-GitHook` removed everything after
  `# Added by qa-skills global installer` to the end of the file, the user's lines after the block
  included. Already fixed (v4.0.1); recorded because item 1's fixtures show it.

## Outcome

- **Item 1** (`392c74f` fixtures and `extract.sh`, `e1bbba6` bash Test 72 and PowerShell Test 56):
  every hook a release wrote is a fixture in `tests/fixtures/git-hooks/`, and both installers
  recognise, replace and remove each one. Green on `main`. Deviations: the v2.0.0 `install.ps1`
  does not parse in Windows PowerShell 5.1 (`|| true` inside `$(...)`), so no 5.1 install ever
  wrote its three double-quoted texts; all three were added anyway as `ps1-v2.0.0-expanded.*`,
  produced by `extract.sh` after dropping the `|| true`. `Add-Content` appends one CRLF after the
  value rather than ending every line with CRLF, as the plan said. Test 56 accepts the current hook
  with or without the final newline.
- **Item 2** (`e95ced6` static check `tests/test-hook-parity.sh`, `af96de0` bash Test 73 and
  PowerShell Test 57): the plan's "six constants" are the six with assignment lines;
  `validate-tc-format.sh` has none and is not compared. Red proof: PowerShell Test 57 failed with
  "the project hook differs from current\project (972 bytes, expected 973)", the missing byte being
  the final LF.
- **Item 3** (`1186445`): `install.ps1` ends the project hook with a newline. It uses
  `WriteAllText($hookFile, $hookContent + "`n", $utf8NoBom)` instead of the plan's
  `(@'...'@) + "`n"` form, because `test-hook-parity.sh` anchors on `$hookContent = @'` and a bare
  `'@`; the bytes are the same. Verified: PowerShell lifecycle suite all passed in 5.1, PowerShell
  conformance 102/102 (26 symlink cases not run locally, no Developer Mode), bash lifecycle suite
  under bash 3.2.57 all passed.
- **Item 4** (`4bd9631` CI step "Hook Text Parity", ShellCheck list, `package.json` `test`,
  `CONTRIBUTING.md` section 4; `d4bbb17` `ROADMAP.md`): Linux job only. Marco's
  `~/qa-ci-local.sh` repeats the ShellCheck list and steps and needs the same addition.
- **Still open, outside scope**: an existing global hook is never refreshed (see "Findings outside
  scope").
