# Plan 066: Rename the installers' internal `qa-skills` names, migrating every existing install

> **Executor instructions**: Branch `feat/qa-instinct-internal-names` from `main`, one pull request
> into `main`. Write each conformance case first and quote its failure against `main` before the
> installers change. All three installers change together; never leave one behind in a commit
> that CI runs. Release as 5.0.0 (`feat!` with a `BREAKING CHANGE` footer). `npm publish` is
> **Marco's**.

## Status

- **Priority**: P2. Naming consistency; no defect.
- **Effort**: L. It touches the file-safety contracts plans 009-012 and 016 protect.
- **Risk**: HIGH. A mistake strands an install: `update` and `uninstall` stop finding its files.
- **Depends on**: plans 009-012 (manifest, portable format, known hashes, CLI parity), 016
  (conformance suite), 064 (hook parity), 065 (the keep-list this plan ends); `decisions/name.md`
- **Planned at**: commit `c397034` (`main`), 2026-10-25

## Why this matters

Marco installed QA Instinct in his portfolio repository and found `.qa-skills-manifest` at its
root: a file named after the package's first name, two renames ago. Marco decided on 2026-10-25
(`decisions/name.md`, "Decision (2026-10-25, internal names)") to take option C, which the first
rename decision priced and deferred: rename the internal names too, with a migration.

## Names

| What | Seen by | From | To |
| --- | --- | --- | --- |
| Install manifest | the user, at the project or home root | `.qa-skills-manifest` | `.qa-instinct-manifest` |
| Backup suffix | the user, after a collision | `<file>.qa-skills-backup-<UTC>` | `<file>.qa-instinct-backup-<UTC>` |
| Project hook marker | `.git/hooks/pre-commit` | `Pre-commit hook to validate test cases in qa-skills` | `... in qa-instinct` |
| Fresh global hook header | the global hooks folder (`~/.git-templates/hooks/pre-commit` or `core.hooksPath`) | `# Global pre-commit hook to validate test cases in qa-skills` | `... in qa-instinct` |
| Debug switch | README, issue template | `QA_SKILLS_DEBUG` | `QA_INSTINCT_DEBUG` |
| Known-hash list | inside the package only | `.qa-skills-known-hashes` | `.qa-instinct-known-hashes` |
| Editor map | inside the package only | `.qa-skills-editor-map` | `.qa-instinct-editor-map` |

## Migration contract (all three installers, identical)

1. **Only the old manifest exists** (any 4.x install): read it as the manifest. The first manifest
   write goes to `.qa-instinct-manifest` by the existing exclusive-temp-and-rename path; after
   that rename succeeds, the old manifest is removed. A run that writes nothing (an uninstall that
   keeps every file) still migrates, so the old name never outlives a run.
2. **Both exist** (a 4.x installer ran after a 5.x one, or a run stopped between the rename and the
   removal): read both, the new one's entry winning on the same editor and path, write the union to
   the new name, remove the old. A stale hash can only make a file look changed, which keeps or
   backs it up: the safe direction.
3. **The old manifest is a symlink**: read it as the manifest is read today, then remove the link
   itself, never its target (plan 033 item 2's rule for the manifest).
4. **The old manifest is a directory or unreadable**: leave it, say so, and go on with the new
   manifest alone, as the installers already do for a destination they cannot read (conformance
   cases 044, 045, 064).
5. **Backups keep their names.** Uninstall never deletes a backup, old or new suffix.
6. **Hooks**: a hook carrying the old project marker or the old fresh header is recognised as ours
   (install's "is this ours?" check and uninstall). New hooks carry the new text. The global block's
   `# Added by qa-skills global installer` line **stays**, word for word: uninstallers older than
   the `bem-te-vi` begin/end markers find the block by it (plan 064).
7. **`QA_SKILLS_DEBUG`** is not read any more; it is a debug switch, named in the changelog.

## Steps

1. **Decision**: `decisions/name.md` gains "Decision (2026-10-25, internal names)".
2. **Red**: conformance cases, each failing on `main`, for contract items 1-4 and 6 (old project
   hook marker recognised by uninstall). A runner directive `legacy-manifest: <scope>` renames the
   scope's manifest to the old name, standing in for a 4.x install. Runners, `test-runner.*` and
   the README's directive table learn the new names.
3. **Green**: `install.sh`, `install.ps1`, `cli/qa-instinct.js`, together.
4. **The rest**: `generate-known-hashes.sh`, `package.json` `files`, the lifecycle suites, hook
   parity (a new pinned hook text), README, CONTRIBUTING, CLAUDE.md, the issue template, `llms.txt`.
5. **Verify**: the grep below prints only the keep-list; the full CI list green locally and on
   Linux, Windows and macOS. The lifecycle tests that install with `tests/fixtures/release-v4.0.1`
   and update with the current tree now exercise the migration end to end.
6. **Release and publish (Marco)**: merge, merge the 5.0.0 release PR, `npm publish` from the tag.
7. **Downstream (Marco)**: `npx qa-instinct@latest update` in the portfolio and the other installs;
   `.qa-skills-manifest` becomes `.qa-instinct-manifest`.

```bash
git grep -nIiE 'qa-skills|qa_skills' -- . ':!CHANGELOG.md' ':!plans/' ':!decisions/' ':!history/' \
  ':!prompt-history/' ':!examples/' ':!evals/results/' ':!benchmark/results/' \
  ':!known-hashes-before-public.txt' ':!tests/fixtures/release-v4.0.1/' ':!tests/fixtures/release-v2.2.0/' \
  ':!tests/fixtures/dedupe-changelog/'
```

## Keep-list

- The global block's `# Added by qa-skills global installer` line (contract item 6), and the
  installers' recognition of the old names (they exist to find 4.x installs).
- The `bem-te-vi` global hook begin/end markers: plan 065's keep-list, not this plan's request.
- The historical record and recorded output, as in plan 065.

## Version

5.0.0. An install made by 5.x has no `.qa-skills-manifest`, so a 4.x CLI reports "Nothing
installed" against it: that is breaking, and `decisions/name.md` option C priced it as a major.

## Rejected approaches

- **Rename only the manifest**: leaves the other names, and the request was all of them.
- **Keep reading the old name forever without migrating**: two manifests could diverge.
- **Accept `QA_SKILLS_DEBUG` as an alias**: code kept for a debug switch nobody scripts.

## Outcome

- **Red**: the six cases 081-086, run with the new runner against the installers on `main`,
  failed 14 of 16 runs: every installer still wrote `.qa-skills-manifest`, so "missing
  project:.qa-instinct-manifest" and "no manifest to rename" (case 008 failed too, on the backup
  suffix). After the change, the full suite passed 140 of 140 locally (`install.sh`, CLI).
- **The 4.0.1 fixture** now exercises the migration end to end: lifecycle Tests 54, 63 and 67 run
  the real 4.0.1 installer, then update with the current tree, and require the old manifest gone.
  PowerShell Test 50 builds the same install by hand.
- **Found while testing**: the interactive commit offer committed the new manifest but left the
  tracked old one deleted outside the commit. Both installers now add the old name's removal when
  git tracks it. Lifecycle Test 43b proved it red against a copy of the tree without that fix
  ("the old manifest's removal was not committed"), then green; PowerShell Test 49b mirrors it.
- **Hook fixtures**: the 4.x project hook moved to `project/qa-skills-marker.*`; `project/current.*`,
  `current/` and `global-fresh/fenced-qa-instinct.lf.nl` hold the new text. Lifecycle Tests 72 and
  73 pass on it.
- **Not run locally**: the PowerShell suites (no `pwsh` on this machine); CI runs them on Windows.
