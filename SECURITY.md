# Security Policy

`qa-instinct` installs files into other people's repositories. Its installers create,
overwrite and delete files on a user's machine, and they make those decisions partly from
`.qa-skills-manifest` — a file that lives inside the consuming repo and is therefore outside the
package's control. That is where this package's real risk sits, and it is what this policy is
mostly about.

This is a solo-maintained project. The response targets below are what one maintainer can honestly
commit to, not an enterprise SLA.

---

## Reporting a vulnerability

**Report privately through GitHub — do not open a public issue.**

Go to the repository's **Security** tab → **Report a vulnerability**, or:

<https://github.com/MarcoAmaral/qa-instinct/security/advisories/new>

This opens a private advisory visible only to you and the maintainer. It lets us fix the defect
and publish a GitHub Security Advisory (GHSA) at the same time, so users find out from their
tooling rather than from an attacker.

Please include:

- the version you tested (`qa-instinct --help` prints it, or check `package.json`);
- your OS, shell and Node version — the three installers (`install.sh`, `install.ps1`,
  `cli/qa-instinct.js`) are separate implementations and a defect often exists in only one of
  them;
- a reproduction: the smallest manifest, file layout or command that triggers it;
- what an attacker gains — a file read, written, deleted, or code executed.

A working proof of concept is welcome but not required. A clear description of the mechanism is
enough.

### What to expect

| Stage | Target |
| --- | --- |
| Acknowledgement that the report was received | 3 business days |
| Initial assessment: in scope, and rough severity | 7 business days |
| Fix released for a confirmed high-severity issue | 30 days |

If a report goes unanswered past those windows, escalate by opening a **public** issue that says
only that you sent a private report and received no reply — no details of the vulnerability.

---

## Supported versions

Only the latest released minor line receives security fixes. This package is small and updating
takes two commands (`npm update -g qa-instinct`, then `qa-instinct update`), so backports
to older lines are not offered.

4.1.0 is the first public release, and the first version published to npm. Versions up to 4.0.1
were releases of a private repository and were never published.

| Version | Supported |
| --- | --- |
| Latest minor release (4.1.x at launch) | Yes |
| Older minor releases | No: upgrade |
| Before 4.1.0 (private repository, never on npm) | No |

---

## Scope

### In scope

The installers act on a user's filesystem, so defects that let them act on the *wrong* files are
the primary concern:

- **Path traversal (CWE-22)** — a manifest, editor map or known-hash entry whose path escapes the
  install tree, causing a file outside it to be written or deleted.
- **Link following (CWE-59)** — writing through a symlink so the write lands somewhere the user did
  not choose.
- **Unintended file destruction** — overwriting or deleting a user's own file without the backup
  the package promises, or deleting a backup.
- **Arbitrary code execution** — anything that causes attacker-controlled code to run during
  install, update, uninstall or hook execution.
- **Privilege or scope escape** — a project-scoped install reaching outside the project, or a
  global install reaching outside the user's home directory.
- **Vulnerabilities in the package's runtime dependency**, `@inquirer/prompts`, where this package's
  use of it is what makes them exploitable.

Reports are welcome for any of the three installers. They are independent implementations of the
same contract, and a defect is often in only one of them, though not always (see the history
below).

### Out of scope

- **The quality or correctness of the QA guidance this package ships.** The rules under `.claude/`
  are prose for an AI assistant to read. Disagreeing with the testing advice is a normal issue or
  pull request, not a vulnerability.
- **AI model behaviour.** What Claude, Copilot, Gemini or any other assistant does after reading
  these rules is outside this package's control.
- **`npm audit` findings in `devDependencies`.** They do not ship — `package.json`'s `files` list
  limits the published tarball to the rule content, `cli/`, `adapters/` and metadata. CI gates
  production dependencies at `--audit-level=high` and treats dev findings as warnings.
- **Anything requiring an attacker who can already write to the user's repository as a
  precondition and gains nothing new by it.** Note the important exception: `.qa-skills-manifest`
  *is* attacker-controllable by design, because it is committed and travels with the repo. A
  crafted manifest that makes an installer act outside the install tree is firmly in scope — see
  the history below.

---

## Security-relevant design

Three invariants the installers are required to hold. A bug that breaks one of them is a
vulnerability, not a defect:

1. **Manifest paths are validated before use.** Every path read from `.qa-skills-manifest` is
   checked to be relative, free of `..` segments, and to resolve inside the install tree. An entry
   that fails is refused and reported, never acted on.
2. **A file that is not ours is never destroyed.** A colliding file is backed up to
   `<file>.qa-skills-backup-<UTC timestamp>` unless its hash appears in `.qa-skills-known-hashes`,
   which identifies it as the package's own older file. Uninstall removes only files still exactly
   as installed, keeps and reports the rest, and never deletes a backup.
3. **Links and read-only files are never forced.** A symlinked destination file is never written
   through: what it points at is backed up, the target is recorded in `<backup>.link-target`, and
   the link is replaced. A symlinked folder below the editor's folder, a read-only file and a
   destination that is a directory are skipped. The installer reports each and continues with the
   rest.

These are exercised by the conformance suite and the integration suites in `tests/`, which CI runs
on Linux, Windows and macOS for every pull request into `main` that changes more than
documentation.

---

## Disclosure history

| Fixed in | Class | Summary |
| --- | --- | --- |
| 2.6.1 | CWE-22 | All three uninstallers joined `.qa-skills-manifest` paths onto the install base without validation. A crafted entry deleted a file anywhere the user could write, and the command exited 0 as though it had succeeded. Affected 2.3.3 through 2.6.0, releases of the private repository that were never published to npm. Found by internal review, no known exploitation. |

A defect of the same class was found in the `update` command's removal path while that command was
still unreleased, and was fixed before it ever shipped. It is recorded in the plan and pull request
rather than here, since no released version contained it.

---

## Related

The OWASP Top 10 checks in `.claude/rules/security-qa.md` are QA guidance this package *ships to
its users* for testing their own applications. They are product content, not this policy. Security
of the package itself is governed by this document.
