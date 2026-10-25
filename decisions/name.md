# Decision: keep the name "qa-skills" or rename before launch

> **Status: decided, 2026-10-08: rename to "Bem-te-vi" (option B).** See "Decision" at the end.
> Written 2026-10-08 for plan 019 phase 5, which suggested
> `docs/decisions/`; `docs/` is gitignored local scratch here, so decisions live in `decisions/`. Nothing has been
> renamed yet; the rename is planned in `plans/020-bem-te-vi-rename-and-public-cutover.md`.

## The clash

Checked on 2026-10-08 against the npm registry and the GitHub API:

| Where | Who | Facts |
| --- | --- | --- |
| npm, unscoped `qa-skills` | AZANIR | v3.2.3, GPL-3.0-only, created 2026-03-08, a QA skills CLI for many editors |
| GitHub `petrkindlmann/qa-skills` | Petr Kindlmann | 166 stars, MIT, created 2026-03-23, 50 QA skills for coding agents |
| GitHub `neonwatty/qa-skills` | neonwatty | 33 stars, MIT, created 2026-01-07, Playwright E2E pipeline |
| GitHub `AZANIR/qa-skills` | AZANIR | 2 stars, GPL-3.0, created 2026-03-07, source of the npm package above |

This package is `@marcoamaral/qa-skills`. The scope rules out a technical clash on npm, but search
results, word of mouth, directory listings and a bare `npx qa-skills` all point at the others first.
`npx qa-skills` would install AZANIR's GPL package, not this one.

## Where the name lives

432 occurrences in tracked files. Most are prose and can be changed freely. What users depend on:

| Contract | Where | Breaking to change? |
| --- | --- | --- |
| npm package `@marcoamaral/qa-skills` | `package.json` | **No, today.** It is not published yet (`npm view` returns 404) |
| CLI command `qa-skills` | `package.json` `bin`, 10 files mention `qa-skills init` | No, today; yes once published |
| GitHub repo `MarcoAmaral/qa-skills` | badges, links (5 files) | No. GitHub redirects a renamed repo |
| `.qa-skills-manifest` | the three installers, tests, docs (16 files) | **Yes.** Existing installs find their files through it |
| `.qa-skills-known-hashes` | installers, generator, tests (18 files) | **Yes**, for adopting older files |
| `.qa-skills-editor-map` | installers (5 files) | Yes, inside the package only |
| `<file>.qa-skills-backup-<UTC>` | installers, tests (14 files) | Only cosmetically; old backups keep their names |
| `QA_SKILLS_DEBUG` environment variable | installers (debug output only) | Hardly; a debug switch |

Existing installs today are the maintainer's own. The repository is private and the package unpublished, so no outside user depends on any of this yet.

## Options

### A. Keep "qa-skills"

- **Cost:** none now. Every later step (badges, directories, the launch post) uses the name as is.
- **Risk:** permanently sharing a name with three other projects, one with 166 stars and one owning
  the unscoped npm name. Users who search, or type `npx qa-skills`, land elsewhere. Renaming after
  launch loses stars' context, links, directory listings and installs.

### B. Rename the package, command and repo; keep the internal file names

- **Change:** the npm name (for example `@marcoamaral/<new>`), the `bin` command, the GitHub repo
  (GitHub redirects the old URL), the README, docs and badges, and the product name in the
  commands' text.
- **Keep:** `.qa-skills-manifest`, `.qa-skills-known-hashes`, `.qa-skills-editor-map`, the backup
  suffix and `QA_SKILLS_DEBUG`. They are implementation details users rarely see, and keeping them
  means every existing install keeps working with no migration.
- **Cost:** about a day, mostly text, done before anything is published. The internal names stay
  slightly inconsistent with the brand.

### C. Full rename, including the internal file names

- **Change:** everything in B, plus the manifest, known-hash list, editor map, backup suffix and
  the debug variable.
- **Needs:** a migration in all three installers (read the old manifest name if the new one is
  absent, write the new one, never lose an entry), conformance cases proving it on every
  platform, and a major version (a `feat!:` / `BREAKING CHANGE`), because an old CLI cannot see a
  new install.
- **Cost:** several days, and it touches the file-safety contracts plans 009-012 and 016 exist to
  protect.

## What a rename would need either way

- Choose a name that is free on npm (scoped and unscoped), as a GitHub repo and as a domain or
  handle you would want, and that does not clash in the QA tooling space. Check before deciding.
- Rename the GitHub repo in Settings. GitHub redirects the old URL for clones and links.
- Publish under the new name. There is nothing to `npm deprecate`, because the old name was never
  published.
- Update `plans/019` phases 7, 8 and 12, which quote the name in the README, checklist and
  directory submissions.

## Recommendation (Marco decides)

If renaming at all, do it **now**, before phase 8 makes the repo public and publishes to npm,
because after that every option gets more expensive. Option B gets the distinct public name for
the least risk; option C's only gain is internal consistency.

## Decision (2026-10-08)

**Rename to Bem-te-vi, option B**: package, command, repository and product name change; the
internal file names (`.qa-skills-manifest`, `.qa-skills-known-hashes`, `.qa-skills-editor-map`,
the backup suffix, `QA_SKILLS_DEBUG`) stay, so existing installs keep working with no migration.

Why this name: the bem-te-vi is a Brazilian bird whose name means "I saw you!", which is what a
tester says to a defect. It is the maintainer's own roots, and it describes the work accurately:
testing finds defects (CTFL v4.0 principle 1); it does not fix them.

| Identifier | Value | Checked 2026-10-08 |
| --- | --- | --- |
| Display name | Bem-te-vi | — |
| npm package | `@marcoamaral/bem-te-vi` | scope is the maintainer's |
| CLI command (`bin`) | `bem-te-vi` | not `bemtevi`: the unscoped npm `bemtevi` (2021, unmaintained, `oliveira88/bemtevi`) installs a `bemtevi` command |
| GitHub repository | `MarcoAmaral/bem-te-vi` | free |
| Unscoped npm `bem-te-vi` | free | optional: reserving it at launch makes `npx bem-te-vi` reach this package; publishing is the maintainer's step |

Other names considered and checked the same day, so the choice is on record: qa-agent (taken on
npm, ~4,600 GitHub repos), QA Superpowers (borrows the brand of obra/superpowers, ~297k stars),
Bugkiller (`bug-killer` taken on npm, 29 exact repos), BugHammer and Testwarden (free, but frame
or brand the work less accurately), verity-qa, qa-rigor, perito-qa, tamandua-qa (free).

## Decision (2026-10-25): rename to QA Instinct

> **Status: decided, 2026-10-25, by Marco.** Supersedes the 2026-10-08 choice of name; option B's
> keep-list stands. Executed in `plans/065-qa-instinct-rename.md`.

**Rename Bem-te-vi to QA Instinct.** "Bem-te-vi" says nothing about QA to anyone who does not know
the bird. "QA Instinct" says what the package does: a senior QA's instincts loaded into an AI
assistant, as the README's "a QA engineer's brain already loaded" puts it.

| Identifier | Value | Checked 2026-10-25 |
| --- | --- | --- |
| Display name | QA Instinct | no product or company of that name; only a Ministry of Testing talk titled "Testing With Instinct" |
| npm package | `qa-instinct`, unscoped (`npx qa-instinct init`), not `@marcoamaral/qa-instinct` | `npm view qa-instinct` 404 |
| CLI command (`bin`) | `qa-instinct` | — |
| GitHub repository | `MarcoAmaral/qa-instinct`, renamed from `MarcoAmaral/bem-te-vi` (GitHub redirects the old URL) | 0 repositories named like it |
| Old npm package | `@marcoamaral/bem-te-vi` unpublished, not deprecated | 147 downloads, all on its publish day (2026-10-22): mirrors and scanners, not users; 0 stars, forks or watchers |

The version continues the series (4.2.0, the next minor after 4.1.1), so the release history
stays readable. Publishing `qa-instinct` and removing the old package are approved for this
rename; any other outward-facing step still needs Marco's go-ahead.
