# Plan 070: Audit the former name, Bem-te-vi, and keep it out of everything but the record

> **Executor instructions**: Branch `chore/name-audit` from `main`, one pull request into `main`,
> one concern per commit. Write the check first and quote its failure before fixing what it finds.
> Never rewrite a dated record: a plan, decision, changelog entry or recorded output keeps the name
> it was written under (CONTRIBUTING.md section 5).

## Status

- **Priority**: P3. One user-visible message and one broken link; no wrong behaviour.
- **Effort**: S.
- **Risk**: LOW. The installers change one message each; markers and folder names stay.
- **Depends on**: plan 065 (the rename and its keep-list), 066 (internal names)
- **Planned at**: commit `2888edc` (`main`), 2026-10-29

## Why this matters

On 2026-10-29 Marco read plan 048 on GitHub, found "Bem-te-vi" in it, and asked why the rename had
not replaced it, then whether the whole repository could be audited or should start over in a new
one. Starting over was rejected (below). Plan 065 checked the name once, by hand, with a `git grep`
in its Verification; nothing kept it from coming back.

## Audit (2026-10-29, `main` at `2888edc`)

`git grep -iE 'bem[-_ ]?te[-_ ]?vi'` found 462 lines. Each falls in one of three classes:

| Class | Where | Lines | Action |
| --- | --- | --- | --- |
| Record: what was true when written | `plans/` (31 files), `decisions/`, `CHANGELOG.md`, `examples/`, `evals/results/`, `benchmark/results/`, `tests/fixtures/` | 413 | Keep; a dated note where the document is still in use |
| History inside a document still in use | `benchmark/METHODOLOGY.md` (pilot disclosure), `benchmark/DEVIATIONS.md` (the rename's entry), `demo/README.md` (an earlier recording) | 9 | Keep, allowlisted |
| Functional: the code must recognise it | global hook fence lines, the retired `.bem-te-vi/` folder, the 4.0.1 CLI path in the conformance runners, test stand-ins for 4.0.1 files | 38 | Keep, allowlisted |
| Describes the product now | `install.sh` and `install.ps1`: "could not find the bem-te-vi block to remove" | 2 | Rename |

Also found:

- **A broken link**: `examples/demo-script.md` pointed at `demo/bem-te-vi.tape`, renamed
  `demo/qa-instinct.tape` by plan 065. No other relative link in the current documents is broken.
- **Clean**: `package.json`, the plugin manifests, `llms.txt`, `.github/`, the repository's
  description and topics, every file name outside `plans/`, and the local directory-submission
  drafts (`docs/launch/submissions.md`, untracked). The old npm packages return 404, and
  `github.com/MarcoAmaral/bem-te-vi` redirects to this repository.

## Steps

1. **Check**: `tests/test-old-name.sh` fails on any tracked line naming the former package outside
   the record's paths unless `tests/old-name-allowlist.txt` lists that exact line, on any file name
   carrying it outside the record, and on an allowlist entry that matches no line. Wired into CI,
   CONTRIBUTING.md section 4 and `npm test`.
2. **Rename** the installers' message to "could not find the block QA Instinct added".
3. **Fix** the demo tape link.
4. **Notes**: plan 048, the one plan still in progress that names the former package and the one
   `benchmark/METHODOLOGY.md` links to, gets a dated note at its top; `plans/README.md` states the
   rule.

## Decision for Marco: the hook fence lines

Every global pre-commit hook QA Instinct writes today, including on a fresh install, is fenced by
`# >>> bem-te-vi global pre-commit >>>` and `# <<< bem-te-vi global pre-commit <<<`. A user who
opens their hook sees the former name. Plans 064 and 065 kept the lines because uninstall finds the
block by them.

- **A (kept here)**: leave them. No risk; the name stays visible in new hooks.
- **B**: write `qa-instinct` fences from now on and recognise both on uninstall and reinstall, as
  plan 066 did for the manifest. Touches both shell installers, the hook-parity check, its fixtures
  and the conformance cases; its own plan, effort M.

## Rejected approaches

- **A new repository without the name.** It loses or copies the record: 111 commits on `main`,
  plans 001-069, the decisions, releases 4.1.0-4.5.0 and both benchmark arms, which are this
  project's audit trail and the monograph's evidence. The former name stays public anyway in npm's
  history, GitHub's redirect and every hook installed so far.
- **Rename the record.** A plan that says the pilot ran under `/bem-te-vi:qa-defect` would then
  state something false (CONTRIBUTING.md section 5).
- **Exempt whole files instead of lines.** `install.sh` would then hide a new user-facing
  occurrence like the one this audit found.

## Outcome

- **Red**: with the 47 kept lines allowlisted, `tests/test-old-name.sh` failed on exactly the two
  installer messages ("former name outside the record: install.ps1: … could not find the bem-te-vi
  block to remove"; the same for `install.sh`), exit 1. An allowlist entry matching no line failed
  it too ("allowlist entry matches no line any more").
- **Green**: after the rename, "The former name appears only in the record and on 47 allowlisted
  lines", exit 0.
