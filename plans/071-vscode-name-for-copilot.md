# Plan 071: Name VS Code in the installers, as another name for the Copilot install

> **Executor instructions**: Branch `feat/vscode-editor-alias` from `main`, one pull request into
> `main`. Write the conformance cases first and quote their failure against `main` before the
> installers change. All three installers change in one commit; never leave one behind in a commit
> that CI runs. `feat:` commit, so Release Please proposes a minor version. `npm publish` is
> **Marco's**.

## Status

- **Priority**: P3. Discoverability; nothing is broken.
- **Effort**: S. One accepted value and one label in three installers, plus documentation.
- **Risk**: LOW. The value becomes `copilot` as soon as it is read, so manifests, paths and every
  later step are unchanged.
- **Depends on**: plans 012 (CLI parity), 016 (conformance suite), 047 (the Copilot layout, and why
  it holds no prompt files or native agents)
- **Planned at**: commit `2888edc` (`main`), 2026-10-31

## Why this matters

On 2026-10-31 Marco asked whether Cursor and VS Code are supported on install, then whether VS Code
could be made its own target. VS Code has no assistant of its own: its built-in AI is GitHub
Copilot, and `--editor copilot` already writes what Copilot reads there (plan 047's table of
Copilot's documentation, checked 2026-10-17). A separate target would install the same files. The
gap is the name: someone using VS Code looks for "VS Code" and has no way to know that "GitHub
Copilot" is the one to pick. Marco chose this option on 2026-10-31.

## Current behaviour (2026-10-31, commit `2888edc`)

- `qa-instinct init --editor vscode` and `install.sh --target project --editor vscode
  --non-interactive` both exit 1 with "invalid --editor value 'vscode'". `install.ps1` declares a
  `ValidateSet` without it (read, not run: no `pwsh` on this machine).
- The labels disagree: the menus of `install.sh` and `install.ps1` say "GitHub Copilot (VS Code)";
  the CLI's says "GitHub Copilot". The README's editor table says "GitHub Copilot".

## Contract (all three installers, identical)

1. `vscode` is accepted wherever an editor name is, for `init`, `update` and `uninstall`, and
   behaves exactly as `copilot`.
2. It is turned into `copilot` where the value is read: `parseArgs` in `cli/qa-instinct.js`, before
   the `--editor` check in `install.sh`, after the parameter block in `install.ps1`. Nothing past
   that point sees it.
3. Manifests record `copilot`, never `vscode`. No file, path or report line differs from a
   `--editor copilot` run.
4. `vscode` means Copilot only. The Claude Code and Cline extensions in VS Code keep `init` and
   `--editor cline`; the README says so where it names the alias.
5. `all` is unchanged: `vscode` is not a seventh editor, so nothing is installed twice.

## Steps

1. **Red**, conformance cases at the next free numbers, each failing on `main`:
   - **Install through the VS Code name equals the Copilot install**: `run: install project
     vscode`; expect `.github/copilot-instructions.md` and `.github/skills` as the package ships
     them, `expect-manifest: project copilot .github/copilot-instructions.md`, and no manifest
     entry under `vscode`.
   - **Uninstall through the VS Code name removes a Copilot install**: seed by `run: install project
     copilot`, then `run: uninstall project vscode`; expect the files absent.
   - **Update through the VS Code name refreshes a Copilot install**: the same with `update`.

   The runners accept only the editors in `tests/conformance/README.md`'s table, so `run:` learns
   `vscode` in `run.sh`, `run.ps1` and the table; `test-runner.sh` and `test-runner.ps1` keep
   proving a case with an unknown editor is refused.
2. **Green**: `install.sh`, `install.ps1`, `cli/qa-instinct.js`, together, each with its `--help`
   text and its "invalid --editor value" list.
3. **Label**: the CLI's menu says "VS Code / GitHub Copilot", and so do the shell menus, replacing
   "GitHub Copilot (VS Code)". The value stays `copilot`.
4. **Documentation**: the README's editor table row, its command table and the install section;
   `CLAUDE.md` and `llms.txt` only if they list `--editor` values.
5. **Verify**: the commands below.

## Verification

- The new cases fail on `main` (quote the output) and pass after, on all three installers.
- `./tests/conformance/test-runner.sh`, `./tests/conformance/run.sh`, `./tests/test-lifecycle.sh`
  and `npm test` green locally; Linux, Windows and macOS CI green (the PowerShell suites run only
  there).
- A `--editor vscode` and a `--editor copilot` install in two scratch projects: `diff -r` shows no
  difference.

## Rejected approaches

- **A seventh editor with its own folders.** It would write the same files, and two editors sharing
  one path break the rule that uninstalling one never removes another's files.
- **Prompt files or native agents for VS Code.** Skills are already slash commands in chat, prompt
  files are "supported only in Local harness sessions" (plan 047), and Marco decided on 2026-10-20
  that the agents stay Agent Skills.
- **A VS Code Marketplace extension.** It would mostly wrap the installer, and it adds a publisher
  account and a second release to maintain. It is the only option that makes the package findable
  from inside VS Code, so it can be its own plan if people ask for it.
- **`vscode` installing every assistant found in VS Code.** The installers cannot tell which
  extensions someone uses, and guessing is what the file-safety contracts forbid.
