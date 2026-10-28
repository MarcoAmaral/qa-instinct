# Installer conformance suite

`install.sh`, `install.ps1` and `cli/qa-instinct.js` must behave identically. Each guarantee they
share is written **once** here, as a case, and every installer is run against every case:

```bash
tests/conformance/run.sh            # install.sh and cli/qa-instinct.js (Linux, macOS)
```

```powershell
tests\conformance\run.ps1           # install.ps1 and cli/qa-instinct.js (Windows)
```

Both accept a case-name filter. Both can run the installers from another package tree, so a new
case can be shown to fail against a historical release before it passes against the current one:

```bash
CONFORMANCE_PKG=/path/to/old-release tests/conformance/run.sh
```

```powershell
tests\conformance\run.ps1 -Package C:\path\to\old-release
```

The package tree needs its adapters generated first (`generate-adapters.sh` or
`generate-adapters.ps1`). Why this suite exists, and what stays in the lifecycle suites, is in
[plan 016](../../plans/016-installer-conformance-suite.md).

## Writing a case

A case is a directory under `cases/` named `NNN-what-it-guarantees`, holding a `case.conf` and any
fixture files it copies in. `case.conf` is line-based: `key: value`, `#` comments, repeatable keys.
Paths carry a scope prefix — `project:` or `home:` — and use forward slashes.

Setup directives and `run:` lines execute in file order, so a case can install, then edit a file,
then uninstall. Expectations are checked after the last line.

| Directive | Meaning |
| --- | --- |
| `name:` | One line describing the guarantee |
| `skip: <installer> — <reason>` | Exempt one installer. A skip is a recorded divergence; both runners print every skip |
| `seed: <path> = <text>` | Write a file containing the text and a newline |
| `seed-fixture: <path> = <file>` | Copy a file from the case directory |
| `seed-package: <path> = <package path>` | Copy a file from the package under test |
| `seed-manifest: <scope> <editor> <path>` | Append a manifest entry carrying that file's real hash |
| `drop-manifest: <scope> <editor> <path>` | Remove an installed file and its manifest entry, as if the install predated it |
| `legacy-manifest: <scope> [-> <path>]` | Rename the scope's manifest to `.qa-skills-manifest`, the name a 4.x install wrote (plan 066). With `-> <path>`, move the manifest there and make the old name a symlink to it |
| `seed-dir: <path>` | Create an empty folder, and any folder above it |
| `seed-readonly: <path>` | Make a seeded file read-only |
| `seed-unreadable: <path>` | Make a seeded file unreadable: `chmod a-r`, or on Windows a rule denying the current user the right to read its data |
| `seed-crlf: <path>` | Rewrite an existing file with CRLF line endings: a CR before every LF, never doubling an existing CRLF |
| `seed-symlink: <path> -> <path>` | Create a symlink. A missing target gives a dangling link (on Windows, a folder link). On Windows without Developer Mode the case is reported **not run**; any other failure to create it stops the run |
| `run: <install\|uninstall\|update> <project\|global> [<editor>]` | Run the installer under test; `update` is `--update`, `-Update` or the CLI's `update`. With no editor, no editor option is passed |
| `run-unknown-option: <install\|uninstall\|update> <project\|global> <editor>` | As `run:`, plus one option the installer does not know (`--bogus-option`, or `-BogusOption` for `install.ps1`) |
| `expect-exit: <n>` | Exit status of the last `run:` |
| `expect-exit-nonzero:` | The last `run:` failed, whatever its status (`powershell.exe -File` reports a binding error its own way) |
| `expect-file:` / `expect-absent: <path>` | Exists / does not exist |
| `expect-content: <path> = <text>` | Exact content, ignoring a trailing newline |
| `expect-same-as-package: <path> = <package path>` | Byte-identical to the package's copy |
| `expect-tree-as-package: <path> = <package folder>` | Every file below that folder of the package is below the path, byte-identical; a package folder with no file fails |
| `expect-backup:` / `expect-no-backup: <path>` | A `<path>.qa-instinct-backup-*` does / does not exist (the `.link-target` file beside a symlink's backup is not counted) |
| `expect-backup-content: <path> = <text>` | The backup holds this text |
| `expect-backup-link-target: <path> = <path>` | The backup of a replaced symlink records that target in `<backup>.link-target` |
| `expect-manifest:` / `expect-no-manifest: <scope> <editor> <path>` | Manifest entry present / absent |
| `expect-output-lists-package: <package dir> <pattern>` | Every match of the pattern in that folder of the package (`*/` for folders) is named in the output, without `.md`, with a leading `/` in `.claude/commands` |
| `expect-output:` / `expect-no-output: <phrase>` | Substring of the combined output of every `run:` |

In the four manifest directives that take an editor, the path is the rest of the line after the scope and the editor,
so it may hold a space.

**A case file is checked before it runs.** Every path stays inside its scope's folder: relative,
forward slashes, no `.` or `..` segment (a manifest entry may climb into the other scope, as case
005 records, but never out of the sandbox). Scopes, editors and operations are the ones in the
table. A line is `<directive>: <value>`, split on LF, trimmed, with no BOM; `=` and `->` need a
space on each side. Anything else makes the case **malformed**: it fails, and none of its lines
run. `tests/conformance/test-runner.sh` and `test-runner.ps1` prove both runners refuse the same
malformed cases and accept the same well-formed ones.

**Output is a contract.** The installers word most messages differently, so `expect-output` may
only use a phrase all three already share, such as `only supports project-level install`,
`Refusing` or `no longer shipped`.
If a case needs a phrase they do not share, align the installers' wording first.

**Prove every case can fail.** Before a case is added, run it against a release that lacked the
guarantee and quote that failure in the pull request. A case that passes against every installer
ever shipped tests nothing.

**Historical fixtures stay byte-exact.** `cases/003-*/qa-v2.3.0.md` and `cases/006-*/qa-v2.3.0-crlf.md`
are copies of `qa.md` as release 2.3.0 shipped it, Portuguese text included. Their hashes are what
the "older release adopted" cases test, so they are not translated.
