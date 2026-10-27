# Plan 067: Ship the `qa-rules` skill in the Claude Code plugin

> **Executor instructions**: Branch `feat/plugin-ships-qa-rules` from `main`, one pull request into
> `main`. Both generators change together and must keep writing the same bytes. Release as a minor
> version (`feat`). `npm publish` is **Marco's**.

## Status

- **Priority**: P2. A plugin install runs every command without the rules it names.
- **Effort**: S. Two generators, the plugin manifest, its check, wording.
- **Risk**: LOW. No installer changes; the npm package is unchanged except for wording.
- **Depends on**: plans 022 (plugin manifests and their check), 047 (the Agent Skills tree and
  `qa-rules`), 060 (the "If a rule is not loaded" fallback)
- **Planned at**: commit `b2d5783` (`main`), 2026-10-26

## Why this matters

Claude Code plugins carry commands, skills, agents and hooks, not rules. `.claude-plugin/plugin.json`
lists `./.claude/skills/`, which has no `qa-rules` skill: that skill is generated into
`adapters/skills/qa-rules/` for the other editors and `adapters/` is not committed. So in a plugin
install every command that names a rule reaches its fallback ("load the `qa-rules` skill"), finds no
such skill, and says which rule it could not apply (`ROADMAP.md`, "Plugin installs without rules").

Reproduced at `b2d5783`: `ls .claude/skills` lists `qa-a11y qa-api qa-explore qa-flaky qa-migrate
qa-plan qa-reference qa-release`; no `qa-rules`.

Marco chose option A on 2026-10-26: ship the generated `qa-rules` skill in the plugin, so the
fallback every command already carries finds it.

## Steps

1. **A committed copy for the plugin.** Both generators also write the `qa-rules` skill to
   `plugin/skills/qa-rules/`, replacing the folder each run so a removed rule leaves no reference
   behind. It is generated, but committed, because the plugin installs from the repository and
   `adapters/` is not tracked. It cannot live in `.claude/skills/`: every installer copies that
   folder, so a normal install would get the rules twice.
2. **The manifest.** `plugin.json` lists `./plugin/skills/` beside `./.claude/skills/`, and its
   description no longer says the plugin has no rules.
3. **The check.** `tests/plugin/verify-plugin.sh` fails when `plugin/skills/qa-rules/` differs from
   `adapters/skills/qa-rules/` (or skips, saying so, when the adapters were not generated; CI
   always generates them first), and when its references are not exactly `.claude/rules/*.md`.
   The Windows job's bash/PowerShell comparison also compares the plugin copy.
4. **Wording.** The `qa-rules` skill names the plugin among the installs that read the rules from
   it. The fallback paragraph drops "(a Claude Code plugin install has neither)", which is no longer
   true. README, ROADMAP and CONTRIBUTING say what the plugin now does.

## What the plugin still does not do

The rules are read when a command or skill reaches for them, not loaded into every session: a
free-form question with no command gets no rule. `npx qa-instinct init` remains the complete install.

## Rejected approaches

- **A SessionStart hook that prints the rules** (option B): always on, like a real install, but about
  6,000 tokens in every session of every project with the plugin enabled, QA work or not.
- **A setup command pointing at `npx qa-instinct init`** (option C): what the plugin description
  already says; it closes nothing.
- **Putting `qa-rules` in `.claude/skills/`**: every installer copies that folder, so project and
  global installs would carry each rule twice, once always on and once as a skill.

## Benchmark

Plan 048's condition D loads "the plugin as published" and records the files a run read beyond the
expanded command. After this plan a D run can load `qa-rules`. The case digest does not change (it
covers prompts and graders), but what D can read does; whether collection runs before or after this
merges, or after it with a `benchmark/DEVIATIONS.md` entry, is Marco's call.
