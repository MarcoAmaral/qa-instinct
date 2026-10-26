#!/usr/bin/env bash
# Integration Test for QA Instinct Lifecycle Manager (Install, Update, Uninstall)
# Works in a completely sandboxed environment to prevent polluting user directories.

set -e

# Setup color codes
# Colour is on for a human at a terminal, off when piped or redirected.
# GITHUB_ACTIONS is checked because Actions is not a TTY but its log viewer
# does render ANSI — without it, CI logs would lose all colour.
use_colour() {
    [ -n "${NO_COLOR:-}" ] && return 1
    [ -n "${FORCE_COLOR:-}" ] && return 0
    [ -n "${GITHUB_ACTIONS:-}" ] && return 0
    [ -t 1 ]
}

if use_colour; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    NC='\033[0m'
else
    GREEN=''
    RED=''
    NC=''
fi

echo "=================================================="
echo "Starting QA Instinct Lifecycle Integration Tests (Unix)"
echo "=================================================="

# 1. Create a sandboxed workspace within the repo for compliance
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Files exactly as v2.2.0 shipped them, to simulate an install still holding an older release.
V220_DIR="$REPO_DIR/tests/fixtures/release-v2.2.0"
SANDBOX_DIR="$REPO_DIR/tests/sandbox"

echo "Initializing sandboxed workspace at: $SANDBOX_DIR"
rm -rf "$SANDBOX_DIR"
mkdir -p "$SANDBOX_DIR/project"
mkdir -p "$SANDBOX_DIR/mock-home"

# Set up environment variables to redirect Home and Git configs to the sandbox
export HOME="$SANDBOX_DIR/mock-home"
export GIT_CONFIG_GLOBAL="$SANDBOX_DIR/mock-home/.gitconfig"

# Initialize a mock git repository in project directory
cd "$SANDBOX_DIR/project"
git init -b main
git config user.name "QA Tester"
git config user.email "qa@tester.com"

printf '%b\n' "${GREEN}✔ Sandboxed environment configured successfully.${NC}"

# Return to repo root where the installer is located
cd "$REPO_DIR"

# 2. Run compile first to ensure adapters are generated
echo "Compiling rule adapters..."
# Explicit check: without it a compiler failure only surfaces later as confusing
# "Adapter not found" errors from the installer (test-lifecycle.ps1 checks the same way).
if ! ./generate-adapters.sh --clean; then
    printf '%b\n' "${RED}✘ generate-adapters.sh failed; cannot run the lifecycle tests.${NC}"
    exit 1
fi

# -----------------------------------------------------------------------------
# TEST 1: Fresh Installation (Project & Global - All Editors)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 1: Fresh Installation (both scopes, all editors)..."

# Run install.sh directing target to project and global using the mock paths
# Since --target both uses pwd and $HOME, and we set $HOME and are pwd-aligned:
cd "$SANDBOX_DIR/project"
"$REPO_DIR/install.sh" --target both --editor all --non-interactive

echo "Verifying project-level installation..."
[ -f ".claude/commands/qa.md" ] || { printf '%b\n' "${RED}✘ Missing qa.md in project commands${NC}"; exit 1; }
[ -f ".claude/rules/accessibility-qa.md" ] || { printf '%b\n' "${RED}✘ Missing accessibility-qa.md in project rules${NC}"; exit 1; }
[ -f ".claude/rules/security-qa.md" ] || { printf '%b\n' "${RED}✘ Missing security-qa.md in project rules${NC}"; exit 1; }
[ -f ".claude/hooks/validate-tc-format.sh" ] || { printf '%b\n' "${RED}✘ Missing validator hook in project${NC}"; exit 1; }
[ -f ".git/hooks/pre-commit" ] || { printf '%b\n' "${RED}✘ Missing git pre-commit hook in project${NC}"; exit 1; }
[ -f ".cursor/rules/qa-instinct.mdc" ] || { printf '%b\n' "${RED}✘ Missing cursor rule in project${NC}"; exit 1; }
[ -f ".cursor/skills/qa-cases/SKILL.md" ] || { printf '%b\n' "${RED}✘ Missing cursor skill in project${NC}"; exit 1; }
[ -f ".windsurf/rules/qa-instinct-security-qa.md" ] || { printf '%b\n' "${RED}✘ Missing windsurf rule in project${NC}"; exit 1; }
[ -f ".windsurf/skills/qa/SKILL.md" ] || { printf '%b\n' "${RED}✘ Missing windsurf skill in project${NC}"; exit 1; }
[ -f ".github/copilot-instructions.md" ] || { printf '%b\n' "${RED}✘ Missing copilot instructions in project${NC}"; exit 1; }
[ -f ".github/skills/qa-plan/SKILL.md" ] || { printf '%b\n' "${RED}✘ Missing copilot skill in project${NC}"; exit 1; }
[ -f ".cline/rules/qa-instinct.md" ] || { printf '%b\n' "${RED}✘ Missing cline rules in project${NC}"; exit 1; }
[ -f ".agents/rules/qa-instinct.md" ] || { printf '%b\n' "${RED}✘ Missing antigravity rule in project${NC}"; exit 1; }
[ -f ".agents/skills/qa/SKILL.md" ] || { printf '%b\n' "${RED}✘ Missing antigravity skill in project${NC}"; exit 1; }

echo "Verifying global-level installation..."
[ -f "$HOME/.claude/commands/qa.md" ] || { printf '%b\n' "${RED}✘ Missing global qa.md${NC}"; exit 1; }
[ -f "$HOME/.cursor/skills/qa/SKILL.md" ] || { printf '%b\n' "${RED}✘ Missing global cursor skill${NC}"; exit 1; }
[ -f "$HOME/.codeium/windsurf/skills/qa/SKILL.md" ] || { printf '%b\n' "${RED}✘ Missing global windsurf skill${NC}"; exit 1; }
[ -f "$HOME/.gemini/config/skills/qa/SKILL.md" ] || { printf '%b\n' "${RED}✘ Missing global antigravity skill${NC}"; exit 1; }
[ -f "$HOME/.git-templates/hooks/pre-commit" ] || { printf '%b\n' "${RED}✘ Missing global git templates pre-commit hook${NC}"; exit 1; }

printf '%b\n' "${GREEN}✔ Test 1 passed successfully! All files are in their correct spots.${NC}"

# -----------------------------------------------------------------------------
# TEST 2: Update Operations
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 2: Update (Verifying no overwrite prompts)..."

# Modify a file to simulate an old version
echo "Version: 1.0.0" > ".claude/commands/qa.md"

# Run update
"$REPO_DIR/install.sh" --target both --editor all --non-interactive --update

# Verify it was updated back to new version (which contains version 2.1.0 or similar)
UPDATED_VER=$(grep -m1 'Version:' ".claude/commands/qa.md" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
if [ "$UPDATED_VER" = "1.0.0" ]; then
    printf '%b\n' "${RED}✘ Update failed: old version was not overwritten.${NC}"
    exit 1
fi

# The edit above stands in for a user-modified file: update must preserve it in a backup
# rather than discarding it.
EDIT_BACKUP=$(find .claude/commands -name 'qa.md.qa-instinct-backup-*' | head -1)
[ -n "$EDIT_BACKUP" ] || { printf '%b\n' "${RED}✘ Update overwrote a modified file without a backup${NC}"; exit 1; }
grep -q "Version: 1.0.0" "$EDIT_BACKUP" || { printf '%b\n' "${RED}✘ Backup does not contain the modified content${NC}"; exit 1; }
# This backup is left in place deliberately: it is the user's data, uninstall must never
# delete it, and Test 3 below asserts exactly that (a real backup surviving a real uninstall)
# instead of erasing the evidence to assert an empty tree.

printf '%b\n' "${GREEN}✔ Test 2 passed successfully! Update overwrote older files without asking and kept a backup.${NC}"

# -----------------------------------------------------------------------------
# TEST 3: Uninstallation / Purging
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 3: Uninstallation (both scopes, all editors)..."

"$REPO_DIR/install.sh" --target both --editor all --non-interactive --uninstall

echo "Verifying project-level removal (except the user backup Test 2 created, which must survive)..."
[ ! -f ".claude/commands/qa.md" ] || { printf '%b\n' "${RED}✘ Package qa.md still exists in project commands${NC}"; exit 1; }
[ ! -f ".claude/rules/security-qa.md" ] || { printf '%b\n' "${RED}✘ Package security-qa.md still exists in project rules${NC}"; exit 1; }
[ ! -d ".claude/rules" ] || { printf '%b\n' "${RED}✘ Now-empty project rules folder was not cleaned up${NC}"; exit 1; }
[ ! -d ".claude/hooks" ] || { printf '%b\n' "${RED}✘ Now-empty project hooks folder was not cleaned up${NC}"; exit 1; }
[ ! -d ".claude/skills" ] || { printf '%b\n' "${RED}✘ Now-empty project skills folder was not cleaned up${NC}"; exit 1; }
[ ! -d ".claude/agents" ] || { printf '%b\n' "${RED}✘ Now-empty project agents folder was not cleaned up${NC}"; exit 1; }
[ -f "$EDIT_BACKUP" ] || { printf '%b\n' "${RED}✘ Uninstall deleted the user's backup from Test 2${NC}"; exit 1; }
grep -q "Version: 1.0.0" "$EDIT_BACKUP" || { printf '%b\n' "${RED}✘ The surviving backup's content changed${NC}"; exit 1; }
# The backup must be the ONLY thing left. Naming individual files would let anything not
# named here survive unnoticed, which is what asserting an empty tree used to rule out.
REMAINING_FILES=$(find .claude -type f | sort)
[ "$REMAINING_FILES" = "$EDIT_BACKUP" ] || {
    printf '%b\n' "${RED}✘ Uninstall left files behind besides the user's backup${NC}"
    while IFS= read -r LEFTOVER; do echo "  $LEFTOVER"; done <<< "$REMAINING_FILES"
    exit 1
}
[ ! -f ".git/hooks/pre-commit" ] || { printf '%b\n' "${RED}✘ Git pre-commit hook still exists in project${NC}"; exit 1; }
[ ! -d ".cursor" ] || { printf '%b\n' "${RED}✘ .cursor folder still exists in project${NC}"; exit 1; }
[ ! -d ".windsurf" ] || { printf '%b\n' "${RED}✘ .windsurf folder still exists in project${NC}"; exit 1; }
[ ! -d ".github" ] || { printf '%b\n' "${RED}✘ .github folder still exists in project${NC}"; exit 1; }
[ ! -d ".cline" ] || { printf '%b\n' "${RED}✘ .cline folder still exists in project${NC}"; exit 1; }
[ ! -d ".agents" ] || { printf '%b\n' "${RED}✘ .agents folder still exists in project${NC}"; exit 1; }

echo "Verifying global-level removal..."
[ ! -d "$HOME/.claude" ] || { printf '%b\n' "${RED}✘ Global .claude folder still exists${NC}"; exit 1; }
[ ! -d "$HOME/.cursor" ] || { printf '%b\n' "${RED}✘ Global .cursor folder still exists${NC}"; exit 1; }
[ ! -d "$HOME/.codeium" ] || { printf '%b\n' "${RED}✘ Global .codeium folder still exists${NC}"; exit 1; }
[ ! -d "$HOME/.gemini" ] || { printf '%b\n' "${RED}✘ Global .gemini folder still exists${NC}"; exit 1; }
# Since the global pre-commit only had our appended block, the installer should have cleanly purged the file
[ ! -f "$HOME/.git-templates/hooks/pre-commit" ] || { printf '%b\n' "${RED}✘ Global git templates pre-commit hook still exists${NC}"; exit 1; }

printf '%b\n' "${GREEN}✔ Test 3 passed successfully! Uninstallation purged package files while leaving the user's backup untouched.${NC}"

# -----------------------------------------------------------------------------
# TEST 4: Project-owned files survive install and uninstall
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 4: Project-owned .claude/ files are preserved (install + uninstall)..."

mkdir -p "$SANDBOX_DIR/owned-project"
cd "$SANDBOX_DIR/owned-project"
git init -q -b main

# Files a project may already have that are NOT part of the qa-instinct package
OWNED_FILES=(
  ".claude/commands/team-deploy.md"
  ".claude/rules/team-conventions.md"
  ".claude/agents/team-reviewer.md"
  ".claude/skills/team-skill/SKILL.md"
  ".claude/hooks/team-hook.sh"
)
for f in "${OWNED_FILES[@]}"; do
  mkdir -p "$(dirname "$f")"
  echo "project-owned: $f" > "$f"
done

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks

echo "Verifying project-owned files survived install..."
for f in "${OWNED_FILES[@]}"; do
  [ "$(cat "$f" 2>/dev/null)" = "project-owned: $f" ] || { printf '%b\n' "${RED}✘ Install deleted or changed project-owned file: $f${NC}"; exit 1; }
done
[ -f ".claude/commands/qa.md" ] || { printf '%b\n' "${RED}✘ Package qa.md was not installed alongside project files${NC}"; exit 1; }

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --uninstall

echo "Verifying project-owned files survived uninstall..."
for f in "${OWNED_FILES[@]}"; do
  [ "$(cat "$f" 2>/dev/null)" = "project-owned: $f" ] || { printf '%b\n' "${RED}✘ Uninstall deleted or changed project-owned file: $f${NC}"; exit 1; }
done

echo "Verifying every package file was removed..."
while IFS= read -r pkg; do
  rel="${pkg#"$REPO_DIR"/}"
  [ ! -e "$rel" ] || { printf '%b\n' "${RED}✘ Uninstall left package file: $rel${NC}"; exit 1; }
done < <(find "$REPO_DIR/.claude/commands" "$REPO_DIR/.claude/rules" "$REPO_DIR/.claude/skills" "$REPO_DIR/.claude/agents" "$REPO_DIR/.claude/hooks" -type f)

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 4 passed successfully! Project-owned files were preserved and package files removed.${NC}"

# Test 5 moved to conformance case 002 (plan 016 item 6).

# -----------------------------------------------------------------------------
# TEST 6: Uninstall touches only what it installed
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 6: Uninstall leaves untracked and modified files alone..."

mkdir -p "$SANDBOX_DIR/untracked-project"
cd "$SANDBOX_DIR/untracked-project"
git init -q -b main

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks

# (a) A file that appeared after install: a project's own file, or a leftover from an
#     older package version that the current source no longer ships.
echo "added after install" > ".claude/rules/legacy-or-own.md"
# (b) A package file the user edited after install.
echo "user edited this" > ".claude/rules/testing-guidelines.md"

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --uninstall

[ "$(cat ".claude/rules/legacy-or-own.md" 2>/dev/null)" = "added after install" ] || { printf '%b\n' "${RED}✘ Uninstall deleted a file it never installed${NC}"; exit 1; }
[ "$(cat ".claude/rules/testing-guidelines.md" 2>/dev/null)" = "user edited this" ] || { printf '%b\n' "${RED}✘ Uninstall deleted a package file the user had modified${NC}"; exit 1; }
[ ! -f ".claude/rules/security-qa.md" ] || { printf '%b\n' "${RED}✘ Uninstall left an unmodified package rule behind${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 6 passed successfully! Only unmodified installed files were removed.${NC}"

# -----------------------------------------------------------------------------
# TEST 7: Same protection at global scope
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 7: Colliding file in the home directory is backed up, not destroyed..."

mkdir -p "$HOME/.claude/rules"
HOME_CONTENT="MY OWN GLOBAL TESTING GUIDELINES"
echo "$HOME_CONTENT" > "$HOME/.claude/rules/testing-guidelines.md"

mkdir -p "$SANDBOX_DIR/global-caller"
cd "$SANDBOX_DIR/global-caller"
"$REPO_DIR/install.sh" --target global --editor claude --non-interactive --no-hooks

HOME_BACKUP=$(find "$HOME/.claude/rules" -name 'testing-guidelines.md.qa-instinct-backup-*' | head -1)
[ -n "$HOME_BACKUP" ] || { printf '%b\n' "${RED}✘ Global install overwrote a colliding file without a backup${NC}"; exit 1; }
[ "$(cat "$HOME_BACKUP")" = "$HOME_CONTENT" ] || { printf '%b\n' "${RED}✘ Global backup does not contain the original content${NC}"; exit 1; }

"$REPO_DIR/install.sh" --target global --editor claude --non-interactive --uninstall
[ "$(cat "$HOME_BACKUP")" = "$HOME_CONTENT" ] || { printf '%b\n' "${RED}✘ Global uninstall destroyed the backup${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 7 passed successfully! Global-scope collisions are preserved too.${NC}"

# Test 8 moved to conformance cases 008 and 011 (plan 016 item 6).

# -----------------------------------------------------------------------------
# TEST 9: Manifest round-trips across platforms
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 9: A manifest rewritten into the other platform's on-disk form still uninstalls cleanly..."

mkdir -p "$SANDBOX_DIR/roundtrip-project"
cd "$SANDBOX_DIR/roundtrip-project"
git init -q -b main

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks

[ -f ".qa-instinct-manifest" ] || { printf '%b\n' "${RED}✘ Install did not write .qa-instinct-manifest${NC}"; exit 1; }
INSTALLED_COUNT=$(find .claude -type f | wc -l | tr -d ' ')

# Rewrite the manifest into install.ps1's exact on-disk form: UTF-8 BOM, CRLF line endings,
# and backslash path separators.
MF=".qa-instinct-manifest"
MF_TMP="$(mktemp)"
printf '\xEF\xBB\xBF' > "$MF_TMP"
while IFS= read -r line || [ -n "$line" ]; do
    printf '%s\r\n' "${line//\//\\}"
done < "$MF" >> "$MF_TMP"
mv "$MF_TMP" "$MF"

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --uninstall

echo "Verifying every installed file was actually removed..."
[ ! -d ".claude" ] || { printf '%b\n' "${RED}✘ .claude folder still exists — files installed under a foreign-platform manifest were orphaned${NC}"; find .claude -mindepth 1 | sed 's/^/  /'; exit 1; }
[ ! -f ".qa-instinct-manifest" ] || { printf '%b\n' "${RED}✘ Manifest still exists after uninstall${NC}"; exit 1; }
[ "$INSTALLED_COUNT" -gt 0 ] || { printf '%b\n' "${RED}✘ Test setup error: nothing was installed${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 9 passed successfully! A foreign-platform manifest (BOM + CRLF + backslashes) still uninstalls cleanly.${NC}"

# -----------------------------------------------------------------------------
# TEST 10: A project path containing a space installs and uninstalls without duplicating
# manifest entries
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 10: A project path with a space in it installs and uninstalls cleanly..."

mkdir -p "$SANDBOX_DIR/space project"
cd "$SANDBOX_DIR/space project"
git init -q -b main

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks
FIRST_INSTALL_LINES=$(wc -l < ".qa-instinct-manifest")

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks
SECOND_INSTALL_LINES=$(wc -l < ".qa-instinct-manifest")

[ "$FIRST_INSTALL_LINES" -eq "$SECOND_INSTALL_LINES" ] || { printf '%b\n' "${RED}✘ Re-installing into a path with a space duplicated manifest entries ($FIRST_INSTALL_LINES -> $SECOND_INSTALL_LINES lines)${NC}"; exit 1; }

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --uninstall

[ ! -d ".claude" ] || { printf '%b\n' "${RED}✘ .claude folder still exists in a path with a space${NC}"; exit 1; }
[ ! -f ".qa-instinct-manifest" ] || { printf '%b\n' "${RED}✘ Manifest still exists after uninstall in a path with a space${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 10 passed successfully! A project path with a space installs and uninstalls cleanly with no duplicate manifest entries.${NC}"

# Test 11 moved to conformance case 009 (plan 016 item 6).

# -----------------------------------------------------------------------------
# TEST 12: Uninstall reports what actually happened, not a blanket success
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 12: Uninstall reporting matches what was actually removed..."

# --- 12a: a file kept because it changed since install must not be reported as a
#     complete removal ---
mkdir -p "$SANDBOX_DIR/report-kept-project"
cd "$SANDBOX_DIR/report-kept-project"
git init -q -b main

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks
echo "user edited this" > ".claude/rules/testing-guidelines.md"

KEPT_LOG="$SANDBOX_DIR/test12-kept.log"
"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --uninstall > "$KEPT_LOG" 2>&1

echo "Verifying the summary does not claim complete removal when a file was kept..."
if grep -qi "completely removed" "$KEPT_LOG"; then
    printf '%b\n' "${RED}✘ Uninstall claimed the package was completely removed while a modified file was kept${NC}"
    cat "$KEPT_LOG"
    exit 1
fi
grep -qi "kept" "$KEPT_LOG" || { printf '%b\n' "${RED}✘ Uninstall summary did not mention that a file was kept${NC}"; cat "$KEPT_LOG"; exit 1; }

cd "$REPO_DIR"

# --- 12b: uninstalling when nothing was ever installed must say so, not claim success ---
mkdir -p "$SANDBOX_DIR/report-empty-project"
cd "$SANDBOX_DIR/report-empty-project"
git init -q -b main

EMPTY_LOG="$SANDBOX_DIR/test12-empty.log"
"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --uninstall > "$EMPTY_LOG" 2>&1

echo "Verifying the summary does not claim complete removal when nothing was installed..."
if grep -qi "completely removed" "$EMPTY_LOG"; then
    printf '%b\n' "${RED}✘ Uninstall claimed the package was completely removed when nothing was installed${NC}"
    cat "$EMPTY_LOG"
    exit 1
fi

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 12 passed successfully! Uninstall reports what was actually removed and what was kept.${NC}"

# -----------------------------------------------------------------------------
# TEST 13: install_file refuses to record a destination outside its base
# -----------------------------------------------------------------------------
# Regression for the WSL "install to Windows profile" bug: the antigravity global-install
# branch hardcoded its destination under $HOME while BASE_DIR was $WIN_HOME, so the recorded
# manifest path could never resolve against its own base. Rather than emulate WSL (which this
# sandbox is not), this test drives install_file directly with a BASE/DEST pair that
# reproduces the same shape of bug — a destination that does not live under its base — and
# asserts the defensive guard refuses it loudly instead of silently writing an unusable
# manifest entry.
echo ""
echo "Running Test 13: install_file refuses a destination outside its base..."

mkdir -p "$SANDBOX_DIR/wsl-guard"
FAKE_BASE="$SANDBOX_DIR/wsl-guard/fake-base"
mkdir -p "$FAKE_BASE"
OUTSIDE_DEST="$SANDBOX_DIR/wsl-guard/outside-base/.gemini/config/skills/qa/SKILL.md"
SRC_FILE="$SANDBOX_DIR/wsl-guard/source.md"
echo "SKILL CONTENT" > "$SRC_FILE"

# Isolate install_file (and the manifest/hash helpers it depends on) by sourcing just that
# function block out of install.sh, rather than sourcing (and thereby running) the whole
# script, which parses CLI flags and drives the full interactive installer.
FUNCS_FILE="$SANDBOX_DIR/wsl-guard/install-funcs.sh"
# awk, not sed: the range-with-negation form this needs is a GNU sed extension, and BSD sed
# (macOS) rejects it with "extra characters at the end of p command".
awk '/^manifest_file\(\) /{on=1}
     on{print}
     on && /^install_file\(\) \{/{inside=1}
     inside && /^\}$/{exit}' "$REPO_DIR/install.sh" > "$FUNCS_FILE"
# shellcheck source=/dev/null
source "$FUNCS_FILE"

set +e
INSTALL_FILE_OUTPUT=$(install_file "$FAKE_BASE" antigravity "$SRC_FILE" "$OUTSIDE_DEST" 2>&1)
INSTALL_FILE_STATUS=$?
set -e

if [ "$INSTALL_FILE_STATUS" -eq 0 ]; then
    printf '%b\n' "${RED}✘ install_file accepted a destination outside its base instead of refusing it${NC}"
    echo "$INSTALL_FILE_OUTPUT"
    exit 1
fi

echo "Verifying the out-of-base destination was never written..."
[ ! -f "$OUTSIDE_DEST" ] || { printf '%b\n' "${RED}✘ install_file wrote to a destination outside its base${NC}"; exit 1; }

echo "Verifying no unusable manifest entry was recorded..."
FAKE_MANIFEST="$FAKE_BASE/.qa-instinct-manifest"
if [ -f "$FAKE_MANIFEST" ] && grep -q "antigravity" "$FAKE_MANIFEST"; then
    printf '%b\n' "${RED}✘ install_file recorded a manifest entry despite refusing the out-of-base destination${NC}"
    cat "$FAKE_MANIFEST"
    exit 1
fi

echo "Verifying the refusal explains itself..."
echo "$INSTALL_FILE_OUTPUT" | grep -qi "base" || { printf '%b\n' "${RED}✘ install_file's refusal did not explain the reason${NC}"; echo "$INSTALL_FILE_OUTPUT"; exit 1; }

printf '%b\n' "${GREEN}✔ Test 13 passed successfully! install_file refused to record a destination outside its base.${NC}"

# -----------------------------------------------------------------------------
# TEST 14: The manifest is staged along with the rest of the installed files
# when the user accepts the installer's "add to git" offer, so consuming repos
# are not left with a stray untracked .qa-instinct-manifest.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 14: The manifest is included in the installer's git add..."

mkdir -p "$SANDBOX_DIR/gitadd-project/adapters"
cd "$SANDBOX_DIR/gitadd-project"
git init -q -b main
git config user.name "QA Tester"
git config user.email "qa@tester.com"
# git_commit_and_push's `git add` also names CLAUDE.md, .gitignore, generate-adapters.sh,
# install.sh and adapters/ — the rest of a vendored install of this package. Stub them so a
# missing pathspec among those doesn't abort the whole `git add` before it reaches the manifest.
touch CLAUDE.md .gitignore generate-adapters.sh install.sh
touch adapters/.keep

GITADD_LOG="$SANDBOX_DIR/test12-install.log"
# This test drives the interactive flow, so the prompt sequence has to be the same everywhere.
# When 'claude' is absent from PATH the installer asks an extra "Continue anyway?" question
# first, which would swallow the answer meant for the menu — so the run gets a stub 'claude'
# on PATH and the prompt never appears, on a developer machine and in CI alike.
FAKE_BIN="$SANDBOX_DIR/gitadd-fakebin"
mkdir -p "$FAKE_BIN"
printf '#!/bin/sh\nexit 0\n' > "$FAKE_BIN/claude"
chmod +x "$FAKE_BIN/claude"
# Answers: (1) Install, (2) yes to "Add to git and commit?", (3) no to "Push to remote?",
# (4) no to the WSL "Also install to Windows-side user profile?" prompt (absent off WSL, where
# the unread answer is simply ignored).
printf '1\ny\nn\nn\n' | PATH="$FAKE_BIN:$PATH" "$REPO_DIR/install.sh" --target project --editor claude --no-hooks > "$GITADD_LOG" 2>&1

git log -1 --name-only --pretty=format: | grep -qx ".qa-instinct-manifest" || {
    printf '%b\n' "${RED}✘ .qa-instinct-manifest was not staged/committed with the rest of the installed files${NC}"
    cat "$GITADD_LOG"
    exit 1
}

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 14 passed successfully! The manifest is staged consistently with the other installed files.${NC}"

# -----------------------------------------------------------------------------
# TEST 15: A project path containing non-ASCII characters installs and uninstalls
# without duplicating manifest entries
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 15: A project path with non-ASCII characters installs and uninstalls cleanly..."

mkdir -p "$SANDBOX_DIR/café-projëct-日本語"
cd "$SANDBOX_DIR/café-projëct-日本語"
git init -q -b main

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks
[ -f ".claude/commands/qa.md" ] || { printf '%b\n' "${RED}✘ Missing qa.md in non-ASCII project path${NC}"; exit 1; }
FIRST_INSTALL_LINES=$(wc -l < ".qa-instinct-manifest")

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks
SECOND_INSTALL_LINES=$(wc -l < ".qa-instinct-manifest")

[ "$FIRST_INSTALL_LINES" -eq "$SECOND_INSTALL_LINES" ] || { printf '%b\n' "${RED}✘ Re-installing into a non-ASCII path duplicated manifest entries ($FIRST_INSTALL_LINES -> $SECOND_INSTALL_LINES lines)${NC}"; exit 1; }

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --uninstall

[ ! -d ".claude" ] || { printf '%b\n' "${RED}✘ .claude folder still exists in a non-ASCII path${NC}"; exit 1; }
[ ! -f ".qa-instinct-manifest" ] || { printf '%b\n' "${RED}✘ Manifest still exists after uninstall in a non-ASCII path${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 15 passed successfully! A project path with non-ASCII characters installs and uninstalls cleanly with no duplicate manifest entries.${NC}"

# -----------------------------------------------------------------------------
# TEST 16: The no-manifest fallback removes unmodified package files and keeps
# user-modified ones, for an install made before manifests existed
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 16: Uninstall without a manifest falls back to content-matching removal..."

mkdir -p "$SANDBOX_DIR/no-manifest-project"
cd "$SANDBOX_DIR/no-manifest-project"
git init -q -b main

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks
[ -f ".qa-instinct-manifest" ] || { printf '%b\n' "${RED}✘ Test setup error: install did not write .qa-instinct-manifest${NC}"; exit 1; }

# Simulate a pre-v2.3.3 install: a file the user modified after installing, and no manifest.
echo "user edited this" > ".claude/rules/testing-guidelines.md"
rm -f ".qa-instinct-manifest"

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --uninstall

echo "Verifying the fallback removed an unmodified package file..."
[ ! -f ".claude/rules/security-qa.md" ] || { printf '%b\n' "${RED}✘ No-manifest fallback left an unmodified package file behind${NC}"; exit 1; }
[ ! -f ".claude/commands/qa.md" ] || { printf '%b\n' "${RED}✘ No-manifest fallback left an unmodified package file behind${NC}"; exit 1; }

echo "Verifying the fallback kept the user's modified file..."
[ "$(cat ".claude/rules/testing-guidelines.md" 2>/dev/null)" = "user edited this" ] || { printf '%b\n' "${RED}✘ No-manifest fallback deleted or changed the user's modified file${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 16 passed successfully! The no-manifest fallback removed unmodified package files and kept the user's edit.${NC}"

# Test 17 moved to conformance case 010 (plan 016 item 6).

# Test 18 moved to conformance case 003 (plan 016 item 6).

# -----------------------------------------------------------------------------
# TEST 19: A destination the user actually edited is still backed up and
# reported - the known-hash lookup must not misfire on real edits
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 19: A genuinely user-edited file is still backed up and reported..."

mkdir -p "$SANDBOX_DIR/user-edit-project"
cd "$SANDBOX_DIR/user-edit-project"
git init -q -b main

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks

# Content that was never shipped by any release, standing in for a real user edit made to a
# pre-manifest install.
USER_CONTENT="MY OWN SECURITY POLICY - DO NOT TOUCH"
echo "$USER_CONTENT" > ".claude/rules/security-qa.md"
USER_HASH=$(sha256sum ".claude/rules/security-qa.md" | awk '{print $1}')
grep -q "^$USER_HASH  " "$REPO_DIR/.qa-instinct-known-hashes" && { printf '%b\n' "${RED}✘ Test setup error: the user-edit content collides with a known release hash${NC}"; exit 1; }
rm -f ".qa-instinct-manifest"

# A reinstall, not --update: with no manifest, update adopts only files a release shipped and
# leaves this one alone (plan 033 item 3), so only install reaches the backup path.
"$REPO_DIR/install.sh" --target project --editor claude --non-interactive

echo "Verifying the user's edit was backed up, not silently discarded..."
BACKUP=$(find .claude/rules -name 'security-qa.md.qa-instinct-backup-*' | head -1)
[ -n "$BACKUP" ] || { printf '%b\n' "${RED}✘ A genuinely user-edited file was adopted instead of backed up${NC}"; exit 1; }
[ "$(cat "$BACKUP")" = "$USER_CONTENT" ] || { printf '%b\n' "${RED}✘ Backup does not contain the user's edit${NC}"; exit 1; }
grep -q "OWASP" ".claude/rules/security-qa.md" || { printf '%b\n' "${RED}✘ The current release's content was not installed${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 19 passed successfully! A genuinely user-edited file was backed up and reported.${NC}"

# -----------------------------------------------------------------------------
# TEST 20: The full no-manifest upgrade path leaves no spurious backups and
# then uninstalls to a clean tree
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 20: A full no-manifest upgrade leaves no spurious backups and uninstalls cleanly..."

mkdir -p "$SANDBOX_DIR/full-upgrade-project"
cd "$SANDBOX_DIR/full-upgrade-project"
git init -q -b main

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks

# Simulate a real pre-v2.3.3 install: several managed files still hold an older release's
# content, and there is no manifest at all.
for f in .claude/rules/security-qa.md .claude/rules/accessibility-qa.md .claude/commands/qa.md; do
    cp "$V220_DIR/$(basename "$f")" "$f"
done
rm -f ".qa-instinct-manifest"

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --update

echo "Verifying the upgrade left no spurious backups..."
SPURIOUS=$(find .claude -name '*.qa-instinct-backup-*')
[ -z "$SPURIOUS" ] || { printf '%b\n' "${RED}✘ The no-manifest upgrade created spurious backups:${NC}"; while IFS= read -r F; do echo "  $F"; done <<< "$SPURIOUS"; exit 1; }
grep -q "OWASP" ".claude/rules/security-qa.md" || { printf '%b\n' "${RED}✘ security-qa.md was not updated to the current release${NC}"; exit 1; }

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --uninstall

echo "Verifying uninstall left a clean tree..."
[ ! -d ".claude" ] || { printf '%b\n' "${RED}✘ .claude survived uninstall after a no-manifest upgrade${NC}"; exit 1; }
[ ! -f ".qa-instinct-manifest" ] || { printf '%b\n' "${RED}✘ Manifest survived uninstall${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 20 passed successfully! The no-manifest upgrade path left no spurious backups and uninstalled to a clean tree.${NC}"

# Test 21 moved to conformance case 002 (plan 016 item 6).

# Test 22 moved to conformance case 008 (plan 016 item 6).

# -----------------------------------------------------------------------------
# TEST 23: `qa-instinct uninstall` removes only unmodified installed files,
# keeps untracked and user-modified files, and cleans up the manifest
# (plan 012, item 3)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 23: qa-instinct uninstall removes only unmodified installed files..."

mkdir -p "$SANDBOX_DIR/cli-uninstall-project"
cd "$SANDBOX_DIR/cli-uninstall-project"

node "$REPO_DIR/cli/qa-instinct.js" init
[ -f ".claude/commands/qa.md" ] || { printf '%b\n' "${RED}✘ Test setup error: cli/qa-instinct.js init did not complete${NC}"; exit 1; }

echo "user edit" >> ".claude/rules/security-qa.md"
echo "untracked" > ".claude/rules/my-own-notes.md"

node "$REPO_DIR/cli/qa-instinct.js" uninstall

echo "Verifying unmodified installed files were removed..."
[ ! -f ".claude/commands/qa.md" ] || { printf '%b\n' "${RED}✘ uninstall left an unmodified installed file behind${NC}"; exit 1; }
[ ! -f ".claude/rules/testing-guidelines.md" ] || { printf '%b\n' "${RED}✘ uninstall left an unmodified installed file behind${NC}"; exit 1; }

echo "Verifying the user-modified file was kept..."
grep -q "user edit" ".claude/rules/security-qa.md" || { printf '%b\n' "${RED}✘ uninstall discarded the user's edit${NC}"; exit 1; }

echo "Verifying the untracked file was kept..."
[ "$(cat ".claude/rules/my-own-notes.md")" = "untracked" ] || { printf '%b\n' "${RED}✘ uninstall touched an untracked file${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 23 passed successfully! qa-instinct uninstall removed only unmodified installed files.${NC}"

# Test 24 moved to conformance case 003 (plan 016 item 6).

# -----------------------------------------------------------------------------
# TEST 25: The manifest cli/qa-instinct.js writes is interchangeable with install.sh's
# — install with one implementation, uninstall with the other, both directions
# (plan 012, item 5 — cross-implementation round trip)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 25: A cross-implementation install/uninstall round trip works both ways..."

# --- 25a: install with cli/qa-instinct.js, uninstall with install.sh ---
mkdir -p "$SANDBOX_DIR/cli-then-sh-project"
cd "$SANDBOX_DIR/cli-then-sh-project"
git init -q -b main

node "$REPO_DIR/cli/qa-instinct.js" init
[ -f ".claude/commands/qa.md" ] || { printf '%b\n' "${RED}✘ Test setup error: cli/qa-instinct.js init did not complete${NC}"; exit 1; }

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --uninstall

echo "Verifying install.sh fully uninstalled a cli/qa-instinct.js install..."
[ ! -d ".claude" ] || { printf '%b\n' "${RED}✘ install.sh left .claude behind after uninstalling a cli/qa-instinct.js install${NC}"; find .claude -mindepth 1 | sed 's/^/  /'; exit 1; }
[ ! -f ".qa-instinct-manifest" ] || { printf '%b\n' "${RED}✘ Manifest survived install.sh's uninstall${NC}"; exit 1; }

cd "$REPO_DIR"

# --- 25b: install with install.sh, uninstall with cli/qa-instinct.js ---
mkdir -p "$SANDBOX_DIR/sh-then-cli-project"
cd "$SANDBOX_DIR/sh-then-cli-project"
git init -q -b main

"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks
[ -f ".claude/commands/qa.md" ] || { printf '%b\n' "${RED}✘ Test setup error: install.sh did not complete${NC}"; exit 1; }

node "$REPO_DIR/cli/qa-instinct.js" uninstall

echo "Verifying cli/qa-instinct.js fully uninstalled an install.sh install..."
[ ! -d ".claude" ] || { printf '%b\n' "${RED}✘ cli/qa-instinct.js left .claude behind after uninstalling an install.sh install${NC}"; find .claude -mindepth 1 | sed 's/^/  /'; exit 1; }
[ ! -f ".qa-instinct-manifest" ] || { printf '%b\n' "${RED}✘ Manifest survived cli/qa-instinct.js's uninstall${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 25 passed successfully! The manifest format round-trips between cli/qa-instinct.js and install.sh in both directions.${NC}"

# -----------------------------------------------------------------------------
# TEST 26: cli/qa-instinct.js skips a read-only destination instead of crashing part-way
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 26: cli/qa-instinct.js init skips a read-only file and still completes..."

if [ "$(id -u)" = "0" ]; then
    echo "Skipping Test 26: running as root, where mode 444 does not prevent writes."
else
    mkdir -p "$SANDBOX_DIR/cli-readonly/.claude/rules"
    cd "$SANDBOX_DIR/cli-readonly"
    git init -q -b main
    CLI_RO_CONTENT="PROTECTED BY READ-ONLY"
    echo "$CLI_RO_CONTENT" > ".claude/rules/code-style-qa.md"
    chmod 444 ".claude/rules/code-style-qa.md"

    CLI_RO_LOG="$SANDBOX_DIR/test26-cli.log"
    if ! node "$REPO_DIR/cli/qa-instinct.js" init > "$CLI_RO_LOG" 2>&1; then
        printf '%b\n' "${RED}✘ cli/qa-instinct.js init aborted instead of skipping the read-only destination${NC}"
        cat "$CLI_RO_LOG"
        exit 1
    fi

    echo "Verifying the read-only file was left untouched and not backed up..."
    grep -qx "$CLI_RO_CONTENT" ".claude/rules/code-style-qa.md" || { printf '%b\n' "${RED}✘ cli/qa-instinct.js overwrote the read-only destination${NC}"; exit 1; }
    [ -z "$(find .claude/rules -name 'code-style-qa.md.qa-instinct-backup-*')" ] || { printf '%b\n' "${RED}✘ A skipped read-only file should leave no backup${NC}"; exit 1; }

    echo "Verifying the rest of the tree still installed completely..."
    for SUB in commands rules skills agents hooks; do
        [ -d ".claude/$SUB" ] || { printf '%b\n' "${RED}✘ .claude/$SUB is missing — the install stopped part-way${NC}"; exit 1; }
    done
    grep -q "code-style-qa.md" ".qa-instinct-manifest" && { printf '%b\n' "${RED}✘ A skipped file must not be recorded in the manifest${NC}"; exit 1; }

    cd "$REPO_DIR"
    printf '%b\n' "${GREEN}✔ Test 26 passed successfully! cli/qa-instinct.js skipped the read-only file and completed the install.${NC}"
fi

# -----------------------------------------------------------------------------
# TEST 27: cli/qa-instinct.js `init --editor <name>` installs a non-claude editor's
# compiled adapter at install.sh's own target path, byte-for-byte, recorded
# under that editor's own name in the manifest (plan 008)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 27: cli/qa-instinct.js init --editor cursor installs the right file at the right path..."

mkdir -p "$SANDBOX_DIR/cli-editor-cursor"
cd "$SANDBOX_DIR/cli-editor-cursor"

node "$REPO_DIR/cli/qa-instinct.js" init --editor cursor

echo "Verifying the rules and skills were installed byte-for-byte at install.sh's own target paths..."
diff "$REPO_DIR/adapters/cursor/rules/qa-instinct.mdc" ".cursor/rules/qa-instinct.mdc" || { printf '%b\n' "${RED}✘ .cursor/rules/qa-instinct.mdc does not match adapters/cursor/rules/qa-instinct.mdc byte-for-byte${NC}"; exit 1; }
diff -r "$REPO_DIR/adapters/skills" ".cursor/skills" || { printf '%b\n' "${RED}✘ .cursor/skills does not match adapters/skills byte-for-byte${NC}"; exit 1; }

echo "Verifying the manifest records them under 'cursor', not 'claude'..."
grep -q "  cursor  .cursor/rules/qa-instinct.mdc$" ".qa-instinct-manifest" || { printf '%b\n' "${RED}✘ Manifest did not record the cursor install under the 'cursor' editor${NC}"; exit 1; }
grep -q "  cursor  .cursor/skills/qa/SKILL.md$" ".qa-instinct-manifest" || { printf '%b\n' "${RED}✘ Manifest did not record the cursor skills under the 'cursor' editor${NC}"; exit 1; }

echo "Verifying no claude tree was installed alongside it..."
[ ! -d ".claude" ] || { printf '%b\n' "${RED}✘ --editor cursor unexpectedly installed the claude tree too${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 27 passed successfully! cli/qa-instinct.js init --editor cursor installed the right file at the right path.${NC}"

# -----------------------------------------------------------------------------
# TEST 28: A file colliding with a non-claude editor's target path is backed
# up, not destroyed, exactly like a claude-tree collision (plan 008)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 28: cli/qa-instinct.js init --editor copilot backs up a colliding file, not destroy it..."

mkdir -p "$SANDBOX_DIR/cli-editor-collision/.github"
cd "$SANDBOX_DIR/cli-editor-collision"
CLI_EDITOR_USER_CONTENT="MY OWN COPILOT INSTRUCTIONS - IRREPLACEABLE"
echo "$CLI_EDITOR_USER_CONTENT" > ".github/copilot-instructions.md"

node "$REPO_DIR/cli/qa-instinct.js" init --editor copilot

echo "Verifying the package's file was installed..."
diff "$REPO_DIR/adapters/copilot/rules/copilot-instructions.md" ".github/copilot-instructions.md" || { printf '%b\n' "${RED}✘ The package's copilot-instructions.md was not installed${NC}"; exit 1; }

echo "Verifying the user's original content is recoverable from a backup..."
CLI_EDITOR_BACKUP=$(find ".github" -name 'copilot-instructions.md.qa-instinct-backup-*')
[ -n "$CLI_EDITOR_BACKUP" ] || { printf '%b\n' "${RED}✘ cli/qa-instinct.js init --editor copilot did not back up the colliding file${NC}"; exit 1; }
[ "$(cat "$CLI_EDITOR_BACKUP")" = "$CLI_EDITOR_USER_CONTENT" ] || { printf '%b\n' "${RED}✘ Backup does not contain the user's original content${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 28 passed successfully! cli/qa-instinct.js backed up the colliding non-claude file instead of destroying it.${NC}"

# Test 29 moved to conformance case 010 (plan 016 item 6).

# -----------------------------------------------------------------------------
# TEST 30: `qa-instinct init` with no --editor and no TTY (CI, piped) behaves
# exactly like `--editor claude` -- no prompt, no hang, no other editor
# installed (plan 008 backward-compatibility requirement)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 30: Non-TTY default behaves exactly like --editor claude..."

mkdir -p "$SANDBOX_DIR/cli-nontty-default" "$SANDBOX_DIR/cli-explicit-claude"

cd "$SANDBOX_DIR/cli-nontty-default"
node "$REPO_DIR/cli/qa-instinct.js" init | cat
[ -d ".claude/commands" ] || { printf '%b\n' "${RED}✘ Non-TTY default did not install the claude tree${NC}"; exit 1; }
for NON_CLAUDE_DEST in ".cursor" ".windsurfrules" ".windsurf" ".github" ".clinerules" ".cline" ".agents"; do
    [ ! -e "$NON_CLAUDE_DEST" ] || { printf '%b\n' "${RED}✘ Non-TTY default with no --editor unexpectedly installed $NON_CLAUDE_DEST${NC}"; exit 1; }
done

cd "$SANDBOX_DIR/cli-explicit-claude"
node "$REPO_DIR/cli/qa-instinct.js" init --editor claude | cat
[ -d ".claude/commands" ] || { printf '%b\n' "${RED}✘ Test setup error: --editor claude did not install${NC}"; exit 1; }

echo "Verifying both produced the same manifest content (modulo the recorded path prefix)..."
diff <(sed 's/^[0-9a-f]*//' "$SANDBOX_DIR/cli-nontty-default/.qa-instinct-manifest" | sort) \
     <(sed 's/^[0-9a-f]*//' "$SANDBOX_DIR/cli-explicit-claude/.qa-instinct-manifest" | sort) \
     || { printf '%b\n' "${RED}✘ Non-TTY default manifest differs from an explicit --editor claude install${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 30 passed successfully! The non-TTY default behaves exactly like --editor claude.${NC}"

# -----------------------------------------------------------------------------
# TEST 31: A tampered manifest cannot delete files outside the install tree
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 31: Uninstall refuses an absolute manifest path outside the base..."

mkdir -p "$SANDBOX_DIR/traversal-project" "$SANDBOX_DIR/traversal-outside"
VICTIM="$SANDBOX_DIR/traversal-outside/victim.txt"
VICTIM_CONTENT="A FILE OUTSIDE THE INSTALL TREE"
echo "$VICTIM_CONTENT" > "$VICTIM"
# The real hash, so the refusal is proven even when an attacker knows the target's content
# and the entry would otherwise have matched and been removed.
if command -v sha256sum > /dev/null 2>&1; then
    VICTIM_HASH=$(sha256sum "$VICTIM" | awk '{print $1}')
else
    VICTIM_HASH=$(shasum -a 256 "$VICTIM" | awk '{print $1}')
fi

cd "$SANDBOX_DIR/traversal-project"
git init -q -b main
"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks > /dev/null

# The manifest lives at the project root and is committed into consuming repositories, so its
# contents cannot be trusted. The relative escape is conformance case 005; the absolute path
# cannot be written as a case (the sandbox path is not known in advance), so it stays here.
printf '%s  claude  %s\n' "$VICTIM_HASH" "$VICTIM" > ".qa-instinct-manifest"
"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --uninstall > "$SANDBOX_DIR/test31.log" 2>&1 || true

[ -f "$VICTIM" ] || { printf '%b\n' "${RED}✘ Uninstall deleted a file outside the install tree via '$VICTIM'${NC}"; exit 1; }
grep -qx "$VICTIM_CONTENT" "$VICTIM" || { printf '%b\n' "${RED}✘ The outside file's content changed via '$VICTIM'${NC}"; exit 1; }
grep -q "Refusing" "$SANDBOX_DIR/test31.log" || { printf '%b\n' "${RED}✘ Uninstall did not report refusing '$VICTIM'${NC}"; cat "$SANDBOX_DIR/test31.log"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 31 passed successfully! A tampered manifest cannot reach outside the install tree.${NC}"

# -----------------------------------------------------------------------------
# TEST 32: `qa-instinct update` refreshes an unmodified installed file to the
# current release (plan 013, item 1)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 32: An unmodified installed file is refreshed to the current version..."

mkdir -p "$SANDBOX_DIR/update-refresh-project/.claude/rules"
cd "$SANDBOX_DIR/update-refresh-project"

# Simulate a file installed back when the package still shipped an older release's content:
# the file itself, and the manifest hash recorded for it, both match that older release — i.e.
# unmodified since install, but stale relative to the current package.
cp "$V220_DIR/security-qa.md" ".claude/rules/security-qa.md"
OLD_HASH=$(sha256sum ".claude/rules/security-qa.md" | awk '{print $1}')
printf '%s  claude  %s\n' "$OLD_HASH" ".claude/rules/security-qa.md" > ".qa-instinct-manifest"
# The exact current-release hash, so refresh is proven precisely rather than by a substring
# that might already appear in the older release's content too.
CURRENT_HASH_32=$(sha256sum "$REPO_DIR/.claude/rules/security-qa.md" | awk '{print $1}')

node "$REPO_DIR/cli/qa-instinct.js" update > "$SANDBOX_DIR/test32.log" 2>&1

echo "Verifying the stale-but-unmodified file was refreshed to the current release..."
NEW_HASH=$(sha256sum ".claude/rules/security-qa.md" | awk '{print $1}')
[ "$NEW_HASH" = "$CURRENT_HASH_32" ] || { printf '%b\n' "${RED}✘ update did not refresh a stale, unmodified file to the current release${NC}"; exit 1; }
REFRESH_BACKUPS=$(find .claude/rules -name 'security-qa.md.qa-instinct-backup-*')
[ -z "$REFRESH_BACKUPS" ] || { printf '%b\n' "${RED}✘ An unmodified file was backed up instead of refreshed in place${NC}"; exit 1; }
grep -q "^$NEW_HASH  claude  .claude/rules/security-qa.md$" ".qa-instinct-manifest" || { printf '%b\n' "${RED}✘ The manifest was not updated to the refreshed file's new hash${NC}"; exit 1; }
grep -q "Refreshed .claude/rules/security-qa.md" "$SANDBOX_DIR/test32.log" || { printf '%b\n' "${RED}✘ update did not report the file as refreshed${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 32 passed successfully! An unmodified installed file was refreshed to the current version.${NC}"

# -----------------------------------------------------------------------------
# TEST 33: `qa-instinct update` backs up a user-modified file instead of
# silently overwriting it (plan 013, item 1)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 33: A user-modified file is backed up, not silently overwritten..."

mkdir -p "$SANDBOX_DIR/update-backup-project/.claude/rules"
cd "$SANDBOX_DIR/update-backup-project"

USER_CONTENT_33="MY OWN SECURITY POLICY - DO NOT TOUCH"
echo "$USER_CONTENT_33" > ".claude/rules/security-qa.md"
USER_HASH_33=$(sha256sum ".claude/rules/security-qa.md" | awk '{print $1}')
grep -q "^$USER_HASH_33  " "$REPO_DIR/.qa-instinct-known-hashes" && { printf '%b\n' "${RED}✘ Test setup error: the user-edit content collides with a known release hash${NC}"; exit 1; }
# The manifest records the hash of whatever was installed originally (an older release), not
# the user's later edit, so update sees a genuine change rather than "still unmodified".
INSTALL_HASH_33=$(sha256sum < "$V220_DIR/security-qa.md" | awk '{print $1}')
printf '%s  claude  %s\n' "$INSTALL_HASH_33" ".claude/rules/security-qa.md" > ".qa-instinct-manifest"

node "$REPO_DIR/cli/qa-instinct.js" update > "$SANDBOX_DIR/test33.log" 2>&1

echo "Verifying the user's edit was backed up, not silently discarded..."
BACKUP_33=$(find .claude/rules -name 'security-qa.md.qa-instinct-backup-*' | head -1)
[ -n "$BACKUP_33" ] || { printf '%b\n' "${RED}✘ update did not back up a user-modified file${NC}"; exit 1; }
[ "$(cat "$BACKUP_33")" = "$USER_CONTENT_33" ] || { printf '%b\n' "${RED}✘ Backup does not contain the user's edit${NC}"; exit 1; }
CURRENT_HASH_33=$(sha256sum "$REPO_DIR/.claude/rules/security-qa.md" | awk '{print $1}')
[ "$(sha256sum ".claude/rules/security-qa.md" | awk '{print $1}')" = "$CURRENT_HASH_33" ] || { printf '%b\n' "${RED}✘ The current release's content was not installed over the user's edit${NC}"; exit 1; }
grep -q "backed up" "$SANDBOX_DIR/test33.log" || { printf '%b\n' "${RED}✘ update did not report backing up the modified file${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 33 passed successfully! A user-modified file was backed up, not silently overwritten.${NC}"

# -----------------------------------------------------------------------------
# TEST 34: `qa-instinct update` removes a no-longer-shipped file when
# unmodified, and keeps it when the user changed it (plan 013, item 2)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 34: A file the package no longer ships is removed when unmodified, kept when modified..."

mkdir -p "$SANDBOX_DIR/update-remove-project/.claude/rules"
cd "$SANDBOX_DIR/update-remove-project"

# Case A: still exactly as installed - update must remove it.
echo "an old rule this package no longer ships" > ".claude/rules/deprecated-rule.md"
DEP_HASH_34=$(sha256sum ".claude/rules/deprecated-rule.md" | awk '{print $1}')

# Case B: changed since install - update must leave it alone.
echo "an old rule, later edited by the user" > ".claude/rules/deprecated-rule-2.md"
DEP2_INSTALL_HASH_34=$(sha256sum ".claude/rules/deprecated-rule-2.md" | awk '{print $1}')
echo "the user's own addition" >> ".claude/rules/deprecated-rule-2.md"

{
    printf '%s  claude  %s\n' "$DEP_HASH_34" ".claude/rules/deprecated-rule.md"
    printf '%s  claude  %s\n' "$DEP2_INSTALL_HASH_34" ".claude/rules/deprecated-rule-2.md"
} > ".qa-instinct-manifest"

node "$REPO_DIR/cli/qa-instinct.js" update > "$SANDBOX_DIR/test34.log" 2>&1

echo "Verifying the unmodified no-longer-shipped file was removed..."
[ ! -f ".claude/rules/deprecated-rule.md" ] || { printf '%b\n' "${RED}✘ update left an unmodified, no-longer-shipped file in place${NC}"; exit 1; }
[ -f ".qa-instinct-manifest" ] && grep -q "deprecated-rule.md" ".qa-instinct-manifest" && { printf '%b\n' "${RED}✘ The removed file's stale manifest entry survived${NC}"; exit 1; }
grep -q "Removed .claude/rules/deprecated-rule.md" "$SANDBOX_DIR/test34.log" || { printf '%b\n' "${RED}✘ update did not report removing the dropped file${NC}"; exit 1; }

echo "Verifying the modified no-longer-shipped file was kept..."
[ -f ".claude/rules/deprecated-rule-2.md" ] || { printf '%b\n' "${RED}✘ update deleted a no-longer-shipped file the user had changed${NC}"; exit 1; }
grep -q "the user's own addition" ".claude/rules/deprecated-rule-2.md" || { printf '%b\n' "${RED}✘ The user's edit to a dropped file was lost${NC}"; exit 1; }
grep -q "Kept .claude/rules/deprecated-rule-2.md" "$SANDBOX_DIR/test34.log" || { printf '%b\n' "${RED}✘ update did not report keeping the modified dropped file${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 34 passed successfully! A dropped file was removed when unmodified and kept when modified.${NC}"

# -----------------------------------------------------------------------------
# TEST 35: `qa-instinct update` adopts a pre-manifest install, and never
# touches the user's own files at another shipped path (plan 013, item 3)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 35: A pre-manifest install is picked up and adopted, and the user's own files survive it..."

mkdir -p "$SANDBOX_DIR/update-adopt-project"
cd "$SANDBOX_DIR/update-adopt-project"

# Simulate the state every pre-v2.3.3 install is in: a managed file still holding an older
# release's content, and no manifest recording it (manifests didn't exist yet).
mkdir -p ".claude/rules"
cp "$V220_DIR/security-qa.md" ".claude/rules/security-qa.md"
ADOPT_HASH_35=$(sha256sum ".claude/rules/security-qa.md" | awk '{print $1}')
grep -q "^$ADOPT_HASH_35  " "$REPO_DIR/.qa-instinct-known-hashes" || { printf '%b\n' "${RED}✘ Test setup error: v2.2.0's security-qa.md hash is not in the known-hash list${NC}"; exit 1; }

# The user's own file, sitting at another path this package also ships - update must leave it
# alone; its hash proves nothing, so it is never adopted on the strength of its path alone.
USER_CONTENT_35="MY OWN NOTES - NOT PACKAGE CONTENT"
echo "$USER_CONTENT_35" > ".claude/rules/accessibility-qa.md"

CURRENT_HASH_35=$(sha256sum "$REPO_DIR/.claude/rules/security-qa.md" | awk '{print $1}')

node "$REPO_DIR/cli/qa-instinct.js" update > "$SANDBOX_DIR/test35.log" 2>&1

echo "Verifying the pre-manifest install was detected and adopted..."
[ "$(sha256sum ".claude/rules/security-qa.md" | awk '{print $1}')" = "$CURRENT_HASH_35" ] || { printf '%b\n' "${RED}✘ update did not adopt a pre-manifest install matching a known release${NC}"; exit 1; }
ADOPT_BACKUPS_35=$(find .claude/rules -name 'security-qa.md.qa-instinct-backup-*')
[ -z "$ADOPT_BACKUPS_35" ] || { printf '%b\n' "${RED}✘ A file matching a previous release was backed up instead of adopted${NC}"; exit 1; }
grep -q "Adopted .claude/rules/security-qa.md" "$SANDBOX_DIR/test35.log" || { printf '%b\n' "${RED}✘ update did not report adopting the pre-manifest file${NC}"; exit 1; }

echo "Verifying the user's own file at another shipped path survived untouched..."
[ "$(cat ".claude/rules/accessibility-qa.md")" = "$USER_CONTENT_35" ] || { printf '%b\n' "${RED}✘ update touched the user's own file at a shipped path${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 35 passed successfully! A pre-manifest install was adopted and the user's own files survived.${NC}"

# -----------------------------------------------------------------------------
# TEST 36: `qa-instinct update` installs nothing when nothing is installed
# (plan 013, item 4/5)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 36: Update with nothing installed does not install anything..."

mkdir -p "$SANDBOX_DIR/update-empty-project"
cd "$SANDBOX_DIR/update-empty-project"

node "$REPO_DIR/cli/qa-instinct.js" update > "$SANDBOX_DIR/test36.log" 2>&1

echo "Verifying update did not install anything when nothing was there..."
[ ! -d ".claude" ] || { printf '%b\n' "${RED}✘ update created .claude/ out of nothing${NC}"; exit 1; }
[ ! -f ".qa-instinct-manifest" ] || { printf '%b\n' "${RED}✘ update created a manifest out of nothing${NC}"; exit 1; }
grep -q "Nothing installed" "$SANDBOX_DIR/test36.log" || { printf '%b\n' "${RED}✘ update did not honestly report that nothing is installed${NC}"; cat "$SANDBOX_DIR/test36.log"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 36 passed successfully! Update with nothing installed did not install anything.${NC}"

# -----------------------------------------------------------------------------
# TEST 37: A tampered manifest cannot make `qa-instinct update` delete files
# outside the install tree (regression for the fix alongside plan 013 item 2)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 37: Update refuses manifest paths that escape the base..."

mkdir -p "$SANDBOX_DIR/update-traversal-project" "$SANDBOX_DIR/update-traversal-outside"
VICTIM_37="$SANDBOX_DIR/update-traversal-outside/victim.txt"
VICTIM_37_CONTENT="A FILE OUTSIDE THE INSTALL TREE"
echo "$VICTIM_37_CONTENT" > "$VICTIM_37"
if command -v sha256sum > /dev/null 2>&1; then
    VICTIM_37_HASH=$(sha256sum "$VICTIM_37" | awk '{print $1}')
else
    VICTIM_37_HASH=$(shasum -a 256 "$VICTIM_37" | awk '{print $1}')
fi

cd "$SANDBOX_DIR/update-traversal-project"
node "$REPO_DIR/cli/qa-instinct.js" init > /dev/null

# A manifest entry naming a file this package no longer ships, at a path that escapes the
# project tree, must never reach update's removal branch (fs.rmSync) without a refusal.
for EVIL_REL in "../update-traversal-outside/victim.txt" "$VICTIM_37"; do
    printf '%s  claude  %s\n' "$VICTIM_37_HASH" "$EVIL_REL" > ".qa-instinct-manifest"
    node "$REPO_DIR/cli/qa-instinct.js" update > "$SANDBOX_DIR/test37.log" 2>&1 || true

    [ -f "$VICTIM_37" ] || { printf '%b\n' "${RED}✘ update deleted a file outside the install tree via '$EVIL_REL'${NC}"; exit 1; }
    grep -qx "$VICTIM_37_CONTENT" "$VICTIM_37" || { printf '%b\n' "${RED}✘ The outside file's content changed via '$EVIL_REL'${NC}"; exit 1; }
    grep -q "Refusing" "$SANDBOX_DIR/test37.log" || { printf '%b\n' "${RED}✘ update did not report refusing '$EVIL_REL'${NC}"; cat "$SANDBOX_DIR/test37.log"; exit 1; }
done

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 37 passed successfully! A tampered manifest cannot make update reach outside the install tree.${NC}"

# -----------------------------------------------------------------------------
# TEST 38: A global uninstall of an editor with nothing installed says so. Until plan 058 cline
# had no global target and this stayed quiet (conformance case 001, retired by plan 058); cline
# now installs globally, so it reports "nothing to remove" like every editor that does.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 38: Global uninstall of cline with nothing installed says there is nothing to remove..."

CALLER_38="$SANDBOX_DIR/global-caller-38"
mkdir -p "$CALLER_38"
cd "$CALLER_38"

UNINSTALL_OUT_38=$("$REPO_DIR/install.sh" --target global --editor cline --non-interactive --uninstall --no-color 2>&1)
if ! printf '%s\n' "$UNINSTALL_OUT_38" | grep -qF "Cline (global): nothing to remove (not installed)."; then
    printf '%b\n' "${RED}✘ A clean global uninstall of cline did not say there was nothing to remove${NC}"; printf '%s\n' "$UNINSTALL_OUT_38"; exit 1
fi

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 38 passed successfully! A clean global uninstall of cline says there is nothing to remove.${NC}"

# -----------------------------------------------------------------------------
# TEST 39: `qa-instinct link` then `uninstall` must not delete the package's own files, and
# `unlink` must keep a link that does not point to this package (plan 026 item 1)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 39: link then uninstall leaves the package intact; unlink keeps a foreign link..."

PKG_39="$SANDBOX_DIR/link-pkg"
PROJ_39="$SANDBOX_DIR/link-project"
mkdir -p "$PKG_39/.claude" "$PROJ_39"
cp -R "$REPO_DIR/cli" "$REPO_DIR/package.json" "$REPO_DIR/.qa-instinct-known-hashes" "$REPO_DIR/.qa-instinct-editor-map" "$PKG_39/"
ln -s "$REPO_DIR/node_modules" "$PKG_39/node_modules"
for SUB in agents commands rules skills hooks; do
    cp -R "$REPO_DIR/.claude/$SUB" "$PKG_39/.claude/"
done
SNAPSHOT_39="$SANDBOX_DIR/link-pkg-before"
cp -R "$PKG_39/.claude" "$SNAPSHOT_39"
BEFORE_39=$(find "$PKG_39/.claude" -type f | wc -l)

cd "$PROJ_39"
git init -q -b main
node "$PKG_39/cli/qa-instinct.js" link > /dev/null
UNINSTALL_OUT_39=$(node "$PKG_39/cli/qa-instinct.js" uninstall 2>&1)
AFTER_39=$(find "$PKG_39/.claude" -type f | wc -l)
# Every byte, not only the number of files: a file edited in place is a changed package too.
if [ "$BEFORE_39" != "$AFTER_39" ] || [ "$BEFORE_39" -eq 0 ] || ! diff -r "$SNAPSHOT_39" "$PKG_39/.claude" > /dev/null; then
    printf '%b\n' "${RED}✘ link then uninstall changed the package: $BEFORE_39 files before, $AFTER_39 after${NC}"
    printf '%s\n' "$UNINSTALL_OUT_39"
    exit 1
fi
printf '%s\n' "$UNINSTALL_OUT_39" | grep -q "link to the package" || { printf '%b\n' "${RED}✘ uninstall did not say it skipped a linked folder${NC}"; printf '%s\n' "$UNINSTALL_OUT_39"; exit 1; }

node "$PKG_39/cli/qa-instinct.js" unlink > /dev/null
for SUB in agents commands rules skills hooks; do
    [ ! -e ".claude/$SUB" ] || { printf '%b\n' "${RED}✘ unlink left .claude/$SUB behind${NC}"; exit 1; }
done

# A link that points somewhere else is not ours to remove.
mkdir -p "$SANDBOX_DIR/link-foreign"
ln -s "$SANDBOX_DIR/link-foreign" ".claude/rules"
UNLINK_OUT_39=$(node "$PKG_39/cli/qa-instinct.js" unlink 2>&1)
[ -L ".claude/rules" ] || { printf '%b\n' "${RED}✘ unlink removed a link that does not point to the package${NC}"; printf '%s\n' "$UNLINK_OUT_39"; exit 1; }
printf '%s\n' "$UNLINK_OUT_39" | grep -q "Kept rules/" || { printf '%b\n' "${RED}✘ unlink did not report the link it kept${NC}"; printf '%s\n' "$UNLINK_OUT_39"; exit 1; }
node "$PKG_39/cli/qa-instinct.js" link > /dev/null
[ "$(readlink .claude/rules)" = "$SANDBOX_DIR/link-foreign" ] || { printf '%b\n' "${RED}✘ link replaced a link that does not point to a qa-instinct package${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 39 passed successfully! link then uninstall left the package intact and a foreign link survived unlink and link.${NC}"

# -----------------------------------------------------------------------------
# TEST 39b: `link` and `unlink` at global scope, over a stale link, and over a real directory
# (plan 037 step 2; Test 39 covers the project-scope round trip)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 39b: link --global, a stale link, and a real directory in the way..."

make_package_39b() {   # destination folder: a package copy that cli/qa-instinct.js treats as its own
    mkdir -p "$1/.claude"
    cp -R "$REPO_DIR/cli" "$REPO_DIR/package.json" "$REPO_DIR/.qa-instinct-known-hashes" "$REPO_DIR/.qa-instinct-editor-map" "$1/"
    ln -s "$REPO_DIR/node_modules" "$1/node_modules"
    for SUB in agents commands rules skills hooks; do
        cp -R "$REPO_DIR/.claude/$SUB" "$1/.claude/"
    done
}

# 39b-1: link --global puts the links under $HOME/.claude, unlink --global takes them away.
PKG_39B="$SANDBOX_DIR/link-pkg-39b"
HOME_39B="$SANDBOX_DIR/link-home-39b"
make_package_39b "$PKG_39B"
mkdir -p "$HOME_39B"
BEFORE_39B=$(find "$PKG_39B/.claude" -type f | wc -l)
(cd "$SANDBOX_DIR" && HOME="$HOME_39B" node "$PKG_39B/cli/qa-instinct.js" link --global > /dev/null)
for SUB in agents commands rules skills hooks; do
    [ "$(readlink "$HOME_39B/.claude/$SUB")" = "$PKG_39B/.claude/$SUB" ] || { printf '%b\n' "${RED}✘ link --global did not link $SUB into the home directory${NC}"; exit 1; }
done
(cd "$SANDBOX_DIR" && HOME="$HOME_39B" node "$PKG_39B/cli/qa-instinct.js" unlink --global > /dev/null)
for SUB in agents commands rules skills hooks; do
    if [ -e "$HOME_39B/.claude/$SUB" ] || [ -L "$HOME_39B/.claude/$SUB" ]; then
        printf '%b\n' "${RED}✘ unlink --global left $SUB behind in the home directory${NC}"; exit 1
    fi
done
[ "$(find "$PKG_39B/.claude" -type f | wc -l)" = "$BEFORE_39B" ] || { printf '%b\n' "${RED}✘ link --global then unlink --global changed the package${NC}"; exit 1; }

# 39b-2: a link left by a package that has since been removed is refreshed to the new package.
PKG_A_39B="$SANDBOX_DIR/link-pkg-39b-a"
PKG_B_39B="$SANDBOX_DIR/link-pkg-39b-b"
PROJ_39B="$SANDBOX_DIR/link-project-39b"
make_package_39b "$PKG_A_39B"
make_package_39b "$PKG_B_39B"
mkdir -p "$PROJ_39B"
cd "$PROJ_39B"
node "$PKG_A_39B/cli/qa-instinct.js" link > /dev/null
rm -rf "$PKG_A_39B"
node "$PKG_B_39B/cli/qa-instinct.js" link > /dev/null
for SUB in agents commands rules skills hooks; do
    [ "$(readlink ".claude/$SUB")" = "$PKG_B_39B/.claude/$SUB" ] || { printf '%b\n' "${RED}✘ .claude/$SUB still points at the removed package after link from another copy${NC}"; readlink ".claude/$SUB"; exit 1; }
done
cd "$REPO_DIR"

# 39b-3: a real directory is never replaced, and the message names a command that can resolve it.
PROJ_REAL_39B="$SANDBOX_DIR/link-project-39b-real"
mkdir -p "$PROJ_REAL_39B/.claude/rules"
printf 'MY OWN RULE 39B\n' > "$PROJ_REAL_39B/.claude/rules/mine.md"
cd "$PROJ_REAL_39B"
LINK_OUT_39B=$(node "$PKG_B_39B/cli/qa-instinct.js" link 2>&1)
{ [ -d .claude/rules ] && [ ! -L .claude/rules ] && [ "$(cat .claude/rules/mine.md)" = "MY OWN RULE 39B" ]; } || { printf '%b\n' "${RED}✘ link replaced or changed a real directory${NC}"; exit 1; }
if printf '%s\n' "$LINK_OUT_39B" | grep -q "run 'unlink' first"; then
    printf '%b\n' "${RED}✘ link told the user to run 'unlink', which does not remove a real directory${NC}"
    printf '%s\n' "$LINK_OUT_39B"
    exit 1
fi
printf '%s\n' "$LINK_OUT_39B" | grep -q "remove or rename it first" || { printf '%b\n' "${RED}✘ link did not say how to resolve a real directory${NC}"; printf '%s\n' "$LINK_OUT_39B"; exit 1; }
cd "$REPO_DIR"

# 39b-4: a system that refuses to create symlinks. Windows without Developer Mode or an elevated
# shell answers EPERM; Linux never does on its own file systems, so a preload makes
# fs.symlinkSync throw the error Windows throws, and cli/qa-instinct.js runs unchanged. link must stop
# with one clear line, exit non-zero and leave the tree as it was: no new .claude folder, and a
# stale link it would have refreshed still in place (plan 037, decided 2026-10-18). Test 42b runs
# the same check for real on a Windows machine without that right.
EPERM_39B="$SANDBOX_DIR/eperm-symlink-39b.js"
cat > "$EPERM_39B" <<'JS'
const fs = require("fs");
fs.symlinkSync = (target, dest) => {
  const err = new Error(`EPERM: operation not permitted, symlink '${target}' -> '${dest}'`);
  err.code = "EPERM";
  err.syscall = "symlink";
  throw err;
};
JS
eperm_link_39b() {   # project folder: runs link there with symlinks refused
    EPERM_STATUS_39B=0
    EPERM_OUT_39B=$(cd "$1" && node --require "$EPERM_39B" "$PKG_B_39B/cli/qa-instinct.js" link 2>&1) || EPERM_STATUS_39B=$?
    if [ "$EPERM_STATUS_39B" -eq 0 ]; then
        printf '%b\n' "${RED}✘ link exited 0 although no symlink could be created${NC}"; printf '%s\n' "$EPERM_OUT_39B"; exit 1
    fi
    if printf '%s\n' "$EPERM_OUT_39B" | grep -q "symlinkSync\|node:internal"; then
        printf '%b\n' "${RED}✘ link printed a stack trace instead of a message${NC}"; printf '%s\n' "$EPERM_OUT_39B"; exit 1
    fi
    printf '%s\n' "$EPERM_OUT_39B" | grep -q "cannot create symbolic links" || { printf '%b\n' "${RED}✘ link did not say why it stopped${NC}"; printf '%s\n' "$EPERM_OUT_39B"; exit 1; }
    printf '%s\n' "$EPERM_OUT_39B" | grep -q "qa-instinct init" || { printf '%b\n' "${RED}✘ link did not name what to do instead${NC}"; printf '%s\n' "$EPERM_OUT_39B"; exit 1; }
}
PROJ_EPERM_39B="$SANDBOX_DIR/link-project-39b-eperm"
mkdir -p "$PROJ_EPERM_39B"
eperm_link_39b "$PROJ_EPERM_39B"
[ -z "$(ls -A "$PROJ_EPERM_39B")" ] || { printf '%b\n' "${RED}✘ link left something in the project after it could not link${NC}"; ls -A "$PROJ_EPERM_39B"; exit 1; }
PROJ_EPERM_STALE_39B="$SANDBOX_DIR/link-project-39b-eperm-stale"
mkdir -p "$PROJ_EPERM_STALE_39B/.claude"
printf '{}\n' > "$PROJ_EPERM_STALE_39B/.claude/settings.json"
ln -s "$SANDBOX_DIR/removed-pkg-39b/.claude/rules" "$PROJ_EPERM_STALE_39B/.claude/rules"
eperm_link_39b "$PROJ_EPERM_STALE_39B"
[ "$(readlink "$PROJ_EPERM_STALE_39B/.claude/rules")" = "$SANDBOX_DIR/removed-pkg-39b/.claude/rules" ] || { printf '%b\n' "${RED}✘ link removed a stale link it could not replace${NC}"; exit 1; }
[ "$(find "$PROJ_EPERM_STALE_39B/.claude" -mindepth 1 -maxdepth 1 -exec basename {} \; | LC_ALL=C sort | tr '\n' ' ')" = "rules settings.json " ] || { printf '%b\n' "${RED}✘ link changed .claude after it could not link${NC}"; ls -A "$PROJ_EPERM_STALE_39B/.claude"; exit 1; }
printf '%b\n' "${GREEN}✔ Test 39b passed successfully! link --global, a stale link, a real directory and refused symlinks all behave.${NC}"

# -----------------------------------------------------------------------------
# TEST 40: The project pre-commit hook never replaces a hook it did not write, never
# registers where git will not look, and is removed on uninstall only when it is ours
# (plan 026 item 2)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 40: Project pre-commit hook is never overwritten and respects core.hooksPath..."

# A repository without the global template hook an earlier test may have configured, so the
# only pre-commit hook present is the one this test seeds.
new_hook_repo_40() {
    rm -rf "$1"
    mkdir -p "$1"
    git -C "$1" -c init.templateDir= init -q -b main
    mkdir -p "$1/.git/hooks"
}

# 40a: the user's own hook survives install and uninstall byte for byte.
REPO_40A="$SANDBOX_DIR/hook-own"
new_hook_repo_40 "$REPO_40A"
printf '#!/bin/sh\necho mine\n' > "$REPO_40A/.git/hooks/pre-commit"
chmod +x "$REPO_40A/.git/hooks/pre-commit"
cp "$REPO_40A/.git/hooks/pre-commit" "$SANDBOX_DIR/hook-own.expected"
cd "$REPO_40A"
OUT_40A=$("$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-color 2>&1)
printf '%s\n' "$OUT_40A" | grep -q "Kept your existing pre-commit hook" || { printf '%b\n' "${RED}✘ install did not say it kept the user's pre-commit hook${NC}"; printf '%s\n' "$OUT_40A"; exit 1; }
cmp -s ".git/hooks/pre-commit" "$SANDBOX_DIR/hook-own.expected" || { printf '%b\n' "${RED}✘ install changed the user's pre-commit hook${NC}"; exit 1; }
"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-color --uninstall > /dev/null 2>&1
cmp -s ".git/hooks/pre-commit" "$SANDBOX_DIR/hook-own.expected" || { printf '%b\n' "${RED}✘ uninstall changed or removed the user's pre-commit hook${NC}"; exit 1; }

# 40b: with core.hooksPath set git never runs .git/hooks, so nothing is written there.
REPO_40B="$SANDBOX_DIR/hook-hookspath"
new_hook_repo_40 "$REPO_40B"
git -C "$REPO_40B" config core.hooksPath .husky/_
cd "$REPO_40B"
OUT_40B=$("$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-color 2>&1)
printf '%s\n' "$OUT_40B" | grep -q "core.hooksPath is set" || { printf '%b\n' "${RED}✘ install did not report core.hooksPath${NC}"; printf '%s\n' "$OUT_40B"; exit 1; }
[ ! -e ".git/hooks/pre-commit" ] || { printf '%b\n' "${RED}✘ install wrote .git/hooks/pre-commit although core.hooksPath is set${NC}"; exit 1; }

# 40c: with no hook present, install creates ours and uninstall removes it.
REPO_40C="$SANDBOX_DIR/hook-none"
new_hook_repo_40 "$REPO_40C"
cd "$REPO_40C"
"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-color > /dev/null 2>&1
grep -q "Pre-commit hook to validate test cases in qa-instinct" ".git/hooks/pre-commit" || { printf '%b\n' "${RED}✘ install did not create the pre-commit hook in a repository without one${NC}"; exit 1; }
"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-color --uninstall > /dev/null 2>&1
[ ! -e ".git/hooks/pre-commit" ] || { printf '%b\n' "${RED}✘ uninstall left our pre-commit hook behind${NC}"; exit 1; }

# 40d: a linked worktree has a .git file, not a directory; the hook goes where git looks.
WT_40="$SANDBOX_DIR/hook-worktree"
rm -rf "$WT_40"
git -C "$REPO_40C" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
git -C "$REPO_40C" worktree add -q -b wt-40 "$WT_40"
cd "$WT_40"
"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-color > /dev/null 2>&1
grep -q "Pre-commit hook to validate test cases in qa-instinct" "$REPO_40C/.git/hooks/pre-commit" || { printf '%b\n' "${RED}✘ install did not register the hook for a worktree checkout${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 40 passed successfully! The user's own hook and core.hooksPath were respected, and our hook was created and removed.${NC}"

# -----------------------------------------------------------------------------
# TEST 39c: install.sh's three menus, driven with piped answers and no flags for the menu under
# test (plan 037 step 4). Per menu: every valid choice, empty input (the default), and one
# invalid value followed by a valid one that is not the default: every menu re-asks, as
# install.ps1 does (Test 42c). At the end of input a menu or a y/n question takes its default, as
# install.ps1's Read-Host does, and never ends the run (plan 037, decided 2026-10-18).
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 39c: install.sh menus map every answer to the right operation, scope and editor..."

MENU_39C="$SANDBOX_DIR/menus-39c"
MENU_N_39C=0
# install.sh asks "Continue anyway?" first when no `claude` command is in PATH, which would take
# the first menu answer on a machine without Claude Code (CI). A stub keeps every machine alike.
MENU_BIN_39C="$MENU_39C/bin"
mkdir -p "$MENU_BIN_39C"
printf '#!/bin/sh\nexit 0\n' > "$MENU_BIN_39C/claude"
chmod +x "$MENU_BIN_39C/claude"
# Rows: editor, a file the install writes, in the order of the editor menu (2-6 after Claude Code).
EDITOR_FILES_39C=(
    "claude:.claude/commands/qa.md"
    "cursor:.cursor/rules/qa-instinct.mdc"
    "windsurf:.windsurf/rules/qa-instinct.md"
    "copilot:.github/copilot-instructions.md"
    "cline:.cline/rules/qa-instinct.md"
    "antigravity:.agents/rules/qa-instinct.md"
)

menu_fail_39c() {   # message
    printf '%b\n' "${RED}✘ Test 39c: $1${NC}"
    printf '%s\n' "--- output of the install.sh run (case $MENU_N_39C) ---"
    tail -15 "$MENU_LOG_39C"
    exit 1
}

# menu_run_39c <answers> <preinstalled: yes|no|git> <install.sh flags...>
# Leaves MENU_PROJ_39C, MENU_HOME_39C, MENU_LOG_39C and MENU_STATUS_39C set. The trailing answers
# cover the commit and Windows-side offers that some environments add; unread ones are harmless.
# Answers ending in EOF get no trailing answers: input ends right there. "git" gives the project
# a .git folder, so install.sh asks "Add to git and commit?".
menu_run_39c() {
    local ANSWERS="$1" PRE="$2" TAIL='n\nn\nn\n'
    shift 2
    case "$ANSWERS" in *EOF) ANSWERS="${ANSWERS%EOF}"; TAIL="" ;; esac
    MENU_N_39C=$((MENU_N_39C + 1))
    MENU_PROJ_39C="$MENU_39C/$MENU_N_39C/project"
    MENU_HOME_39C="$MENU_39C/$MENU_N_39C/home"
    MENU_LOG_39C="$MENU_39C/$MENU_N_39C/install.log"
    mkdir -p "$MENU_PROJ_39C" "$MENU_HOME_39C"
    if [ "$PRE" = yes ]; then
        (cd "$MENU_PROJ_39C" && HOME="$MENU_HOME_39C" "$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks --no-color > /dev/null 2>&1)
    fi
    [ "$PRE" = git ] && mkdir -p "$MENU_PROJ_39C/.git"
    MENU_STATUS_39C=0
    (cd "$MENU_PROJ_39C" && printf '%b' "${ANSWERS}${TAIL}" | PATH="$MENU_BIN_39C:$PATH" HOME="$MENU_HOME_39C" "$REPO_DIR/install.sh" --no-hooks --no-color "$@" > "$MENU_LOG_39C" 2>&1) || MENU_STATUS_39C=$?
}

# menu_expect_39c <project|home> <present|absent> <relative path>
menu_expect_39c() {
    local BASE="$MENU_PROJ_39C"
    [ "$1" = home ] && BASE="$MENU_HOME_39C"
    if [ "$2" = present ] && [ ! -e "$BASE/$3" ]; then menu_fail_39c "$3 is missing under the $1 directory"; fi
    if [ "$2" = absent ] && [ -e "$BASE/$3" ]; then menu_fail_39c "$3 should not exist under the $1 directory"; fi
}

menu_editors_39c() {   # manifest of the project: the editors it records, sorted, space separated
    sed -n 's/^[0-9a-f]\{64\}  \([^ ]*\)  .*/\1/p' "$MENU_PROJ_39C/.qa-instinct-manifest" 2>/dev/null | LC_ALL=C sort -u | tr '\n' ' '
}

# Operation menu (flags give the scope and editor): 1 install, empty = install, 2 update,
# 3 uninstall, 9 then 2 = asked again, then update; no input at all = install.
menu_run_39c '1\n' no --target project --editor claude
[ "$MENU_STATUS_39C" -eq 0 ] || menu_fail_39c "operation 1 failed ($MENU_STATUS_39C)"
menu_expect_39c project present .claude/commands/qa.md
menu_run_39c '\n' no --target project --editor claude
[ "$MENU_STATUS_39C" -eq 0 ] || menu_fail_39c "empty operation failed ($MENU_STATUS_39C)"
menu_expect_39c project present .claude/commands/qa.md
menu_run_39c '2\n' yes --target project --editor claude
[ "$MENU_STATUS_39C" -eq 0 ] || menu_fail_39c "operation 2 failed ($MENU_STATUS_39C)"
grep -q "mode: update" "$MENU_LOG_39C" || menu_fail_39c "operation 2 did not run an update"
menu_expect_39c project present .claude/commands/qa.md
menu_run_39c '3\n' yes --target project --editor claude
[ "$MENU_STATUS_39C" -eq 0 ] || menu_fail_39c "operation 3 failed ($MENU_STATUS_39C)"
menu_expect_39c project absent .claude/commands/qa.md
menu_run_39c '9\n2\n' yes --target project --editor claude
[ "$MENU_STATUS_39C" -eq 0 ] || menu_fail_39c "an invalid operation failed ($MENU_STATUS_39C)"
grep -q "Invalid choice '9'" "$MENU_LOG_39C" || menu_fail_39c "an invalid operation was not reported"
grep -q "mode: update" "$MENU_LOG_39C" || menu_fail_39c "an invalid operation was not asked again (2, update, did not run)"
menu_run_39c 'EOF' no --target project --editor claude
[ "$MENU_STATUS_39C" -eq 0 ] || menu_fail_39c "no input at all failed ($MENU_STATUS_39C)"
menu_expect_39c project present .claude/commands/qa.md

# Target menu (flag gives the editor; the first answer is the operation): 1 project, 2 global,
# 3 both, empty = project, 7 then 2 = asked again, then global; 7 then the end of input = project.
for ROW_39C in "1 present absent" "2 absent present" "3 present present" "- present absent"; do
    read -r ANS_39C IN_PROJECT_39C IN_HOME_39C <<< "$ROW_39C"
    [ "$ANS_39C" = "-" ] && ANS_39C=""
    menu_run_39c "1\n${ANS_39C}\n" no --editor claude
    [ "$MENU_STATUS_39C" -eq 0 ] || menu_fail_39c "target answer '${ANS_39C}' failed ($MENU_STATUS_39C)"
    menu_expect_39c project "$IN_PROJECT_39C" .claude/commands/qa.md
    menu_expect_39c home "$IN_HOME_39C" .claude/commands/qa.md
done
menu_run_39c '1\n7\n2\n' no --editor claude
[ "$MENU_STATUS_39C" -eq 0 ] || menu_fail_39c "an invalid target failed ($MENU_STATUS_39C)"
grep -q "Invalid choice '7'" "$MENU_LOG_39C" || menu_fail_39c "an invalid target was not reported"
menu_expect_39c project absent .claude/commands/qa.md
menu_expect_39c home present .claude/commands/qa.md
menu_run_39c '1\n7\nEOF' no --editor claude
[ "$MENU_STATUS_39C" -eq 0 ] || menu_fail_39c "an invalid target at the end of input failed ($MENU_STATUS_39C)"
grep -q "Invalid choice '7'" "$MENU_LOG_39C" || menu_fail_39c "an invalid target at the end of input was not reported"
menu_expect_39c project present .claude/commands/qa.md
menu_expect_39c home absent .claude/commands/qa.md

# Editor menu (flag gives the scope; the first answer is the operation): 1-6 one editor each,
# 7 all, empty = Claude Code, 9 then 2 = asked again, then Cursor / Trae ("9\n2" below).
for CHOICE_39C in 1 2 3 4 5 6 7 "" '9\n2'; do
    menu_run_39c "1\n${CHOICE_39C}\n" no --target project
    [ "$MENU_STATUS_39C" -eq 0 ] || menu_fail_39c "editor answer '$CHOICE_39C' failed ($MENU_STATUS_39C)"
    case "$CHOICE_39C" in
        "")   WANT_39C="claude" ;;
        '9\n2') WANT_39C="cursor" ;;
        7)    WANT_39C="claude cursor windsurf copilot cline antigravity" ;;
        *)    WANT_39C="${EDITOR_FILES_39C[$((CHOICE_39C - 1))]%%:*}" ;;
    esac
    for ROW_39C in "${EDITOR_FILES_39C[@]}"; do
        ED_39C="${ROW_39C%%:*}"
        case " $WANT_39C " in
            *" $ED_39C "*) menu_expect_39c project present "${ROW_39C#*:}" ;;
            *)             menu_expect_39c project absent "${ROW_39C#*:}" ;;
        esac
    done
    EXPECT_MANIFEST_39C="$(printf '%s\n' "$WANT_39C" | tr ' ' '\n' | LC_ALL=C sort | tr '\n' ' ')"
    [ "$(menu_editors_39c)" = "$EXPECT_MANIFEST_39C" ] || menu_fail_39c "editor answer '$CHOICE_39C': manifest records '$(menu_editors_39c)', expected '$EXPECT_MANIFEST_39C'"
done
[ "$EXPECT_MANIFEST_39C" = "cursor " ] || menu_fail_39c "the last editor case should have installed Cursor / Trae only"
grep -q "Invalid choice '9'" "$MENU_LOG_39C" || menu_fail_39c "an invalid editor was not reported"

# A y/n question at the end of input takes its default ("Add to git and commit?": no).
menu_run_39c '1\nEOF' git --target project --editor claude
[ "$MENU_STATUS_39C" -eq 0 ] || menu_fail_39c "the commit offer at the end of input failed ($MENU_STATUS_39C)"
menu_expect_39c project present .claude/commands/qa.md

# A y/n question asks again on anything but y or n, in either case, as install.ps1's Read-YesNo
# does (plan 045 item 6); "Overwrite?" is asked when the project already has commands/qa.md.
# On WSL a stray "y" would reach "Also install to Windows-side user profile?", so the Windows
# side is stubbed to fail there: nothing can be written outside the sandbox.
for STUB_39C in cmd.exe wslpath; do
    printf '#!/bin/sh\nexit 1\n' > "$MENU_BIN_39C/$STUB_39C"
    chmod +x "$MENU_BIN_39C/$STUB_39C"
done
menu_run_39c '1\nmaybe\ny\n' yes --target project --editor claude
[ "$MENU_STATUS_39C" -eq 0 ] || menu_fail_39c "an invalid y/n answer failed ($MENU_STATUS_39C)"
grep -q "Please enter 'y' or 'n'." "$MENU_LOG_39C" || menu_fail_39c "an invalid y/n answer was not reported"
if grep -q "Skipping" "$MENU_LOG_39C"; then menu_fail_39c "an invalid y/n answer was read as no instead of asking again"; fi
menu_run_39c '1\nY\n' yes --target project --editor claude
[ "$MENU_STATUS_39C" -eq 0 ] || menu_fail_39c "a capital Y failed ($MENU_STATUS_39C)"
if grep -q "Skipping" "$MENU_LOG_39C"; then menu_fail_39c "a capital Y was read as no"; fi
menu_run_39c '1\nmaybe\nEOF' yes --target project --editor claude
[ "$MENU_STATUS_39C" -eq 0 ] || menu_fail_39c "an invalid y/n answer at the end of input failed ($MENU_STATUS_39C)"
grep -q "Please enter 'y' or 'n'." "$MENU_LOG_39C" || menu_fail_39c "an invalid y/n answer at the end of input was not reported"
grep -q "Skipping" "$MENU_LOG_39C" || menu_fail_39c "a y/n question at the end of input did not take its default (no)"
printf '%b\n' "${GREEN}✔ Test 39c passed successfully! $MENU_N_39C menu runs matched their operation, scope and editor.${NC}"

# -----------------------------------------------------------------------------
# TEST 39d: the CLI's editor checkbox, driven through a pseudo-terminal (plan 037 step 4). The
# prompt only appears on a TTY, so it needs util-linux `script`; other systems skip it. Keys go in
# once the prompt is on screen, never on a fixed delay.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 39d: the CLI editor checkbox installs what the keys selected..."

if ! command -v script > /dev/null 2>&1 || ! script --version 2>&1 | grep -q util-linux; then
    printf '%b\n' "${GREEN}- Test 39d skipped: it needs util-linux script (Linux only).${NC}"
else
    # cli_checkbox_39d <case name> <key>...: runs `init` on a pseudo-terminal in a fresh project.
    cli_checkbox_39d() {
        local NAME="$1" KEY
        shift
        CLI_PROJ_39D="$SANDBOX_DIR/checkbox-39d/$NAME/project"
        CLI_HOME_39D="$SANDBOX_DIR/checkbox-39d/$NAME/home"
        CLI_LOG_39D="$SANDBOX_DIR/checkbox-39d/$NAME/out.log"
        mkdir -p "$CLI_PROJ_39D" "$CLI_HOME_39D"
        : > "$CLI_LOG_39D"
        local STATUS=0
        (
            for _ in $(seq 1 100); do
                grep -q "Which editors" "$CLI_LOG_39D" 2> /dev/null && break
                sleep 0.3
            done
            sleep 0.3
            for KEY in "$@"; do
                printf '%b' "$KEY"
                sleep 0.3
            done
        ) | (cd "$CLI_PROJ_39D" && HOME="$CLI_HOME_39D" timeout 60 script -qec "node '$REPO_DIR/cli/qa-instinct.js' init" /dev/null > "$CLI_LOG_39D" 2>&1) || STATUS=$?
        if [ "$STATUS" -ne 0 ]; then
            printf '%b\n' "${RED}✘ init on a pseudo-terminal exited $STATUS (case $NAME)${NC}"; tail -15 "$CLI_LOG_39D"; exit 1
        fi
    }

    # Enter alone accepts the default: Claude Code only.
    cli_checkbox_39d default '\r'
    [ -f "$CLI_PROJ_39D/.claude/commands/qa.md" ] || { printf '%b\n' "${RED}✘ the default checkbox answer did not install Claude Code${NC}"; tail -15 "$CLI_LOG_39D"; exit 1; }
    [ ! -e "$CLI_PROJ_39D/.cursor" ] || { printf '%b\n' "${RED}✘ the default checkbox answer also installed Cursor${NC}"; exit 1; }

    # Down, space, enter adds Cursor / Trae to Claude Code.
    cli_checkbox_39d cursor '\033[B' ' ' '\r'
    [ -f "$CLI_PROJ_39D/.claude/commands/qa.md" ] || { printf '%b\n' "${RED}✘ the checkbox dropped Claude Code when Cursor was added${NC}"; tail -15 "$CLI_LOG_39D"; exit 1; }
    [ -f "$CLI_PROJ_39D/.cursor/rules/qa-instinct.mdc" ] || { printf '%b\n' "${RED}✘ the checkbox did not install Cursor / Trae${NC}"; tail -15 "$CLI_LOG_39D"; exit 1; }

    # Nothing selected is the checkbox's only invalid answer: it asks again, as both shell
    # installers' menus do (plan 037, decided 2026-10-18). Space clears Claude Code, enter is
    # refused, space selects it again, enter installs it.
    cli_checkbox_39d none-then-claude ' ' '\r' ' ' '\r'
    grep -q "At least one" "$CLI_LOG_39D" || { printf '%b\n' "${RED}✘ the checkbox accepted an empty selection without asking again${NC}"; tail -15 "$CLI_LOG_39D"; exit 1; }
    [ -f "$CLI_PROJ_39D/.claude/commands/qa.md" ] || { printf '%b\n' "${RED}✘ the checkbox did not install Claude Code once it was selected again${NC}"; tail -15 "$CLI_LOG_39D"; exit 1; }
    printf '%b\n' "${GREEN}✔ Test 39d passed successfully! The checkbox default, an added editor and an empty selection behaved.${NC}"
fi

# -----------------------------------------------------------------------------
# TEST 41: The global pre-commit hook adds and removes only its own block, never rewrites a hook
# it cannot append to, and never replaces a git init.templateDir the user already has
# (plan 026 item 3)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 41: Global hook append and removal touch only our own block..."

# Runs the installer against its own throwaway HOME so no earlier test's global state leaks in.
global_install_41() {  # <home> <install|uninstall>
    local ARGS=(--target global --editor claude --non-interactive --no-color)
    [ "$2" = uninstall ] && ARGS+=(--uninstall)
    HOME="$1" GIT_CONFIG_GLOBAL="$1/.gitconfig" "$REPO_DIR/install.sh" "${ARGS[@]}" 2>&1
}

CALLER_41="$SANDBOX_DIR/global-caller-41"
mkdir -p "$CALLER_41"
cd "$CALLER_41"

# 41a: appended to the user's bash hook, and removed again leaving exactly the user's lines.
HOME_41A="$SANDBOX_DIR/home-41a"
mkdir -p "$HOME_41A/.git-templates/hooks"
HOOK_41A="$HOME_41A/.git-templates/hooks/pre-commit"
printf '#!/usr/bin/env bash\necho before\n' > "$HOOK_41A"
chmod +x "$HOOK_41A"
GIT_CONFIG_GLOBAL="$HOME_41A/.gitconfig" git config --global init.templateDir "$HOME_41A/their-templates"
global_install_41 "$HOME_41A" install > /dev/null
grep -qF "# >>> bem-te-vi global pre-commit >>>" "$HOOK_41A" || { printf '%b\n' "${RED}✘ global install did not append its block to the user's hook${NC}"; exit 1; }
bash -n "$HOOK_41A" || { printf '%b\n' "${RED}✘ the appended global hook is not valid bash${NC}"; exit 1; }
[ "$(GIT_CONFIG_GLOBAL="$HOME_41A/.gitconfig" git config --global init.templateDir)" = "$HOME_41A/their-templates" ] || { printf '%b\n' "${RED}✘ global install replaced the user's init.templateDir${NC}"; exit 1; }
printf 'echo after\n' >> "$HOOK_41A"
global_install_41 "$HOME_41A" uninstall > /dev/null
printf '#!/usr/bin/env bash\necho before\necho after\n' > "$SANDBOX_DIR/hook-41a.expected"
cmp -s "$HOOK_41A" "$SANDBOX_DIR/hook-41a.expected" || { printf '%b\n' "${RED}✘ global uninstall did not leave exactly the user's lines:${NC}"; cat "$HOOK_41A"; exit 1; }
bash -n "$HOOK_41A" || { printf '%b\n' "${RED}✘ the hook left after global uninstall is not valid bash${NC}"; exit 1; }

# 41b: a hook an older release appended to has no end marker; only its block may go.
HOME_41B="$SANDBOX_DIR/home-41b"
mkdir -p "$HOME_41B/.git-templates/hooks"
HOOK_41B="$HOME_41B/.git-templates/hooks/pre-commit"
{
    printf '#!/bin/sh\necho before\n'
    cat << 'OLD_BLOCK'

# Added by qa-skills global installer
GLOBAL_VALIDATOR="$HOME/.claude/hooks/validate-tc-format.sh"
if [ -f "$GLOBAL_VALIDATOR" ]; then
    STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.md$' || true)
    if [ -n "$STAGED_FILES" ]; then
        for FILE in $STAGED_FILES; do
            if grep -qE "^## TC-[A-Z0-9]+-[0-9]+:" "$FILE" 2>/dev/null; then
                if ! "$GLOBAL_VALIDATOR" "$FILE"; then
                    exit 1
                fi
            fi
        done
    fi
fi
OLD_BLOCK
    printf 'echo after\n'
} > "$HOOK_41B"
global_install_41 "$HOME_41B" uninstall > /dev/null
printf '#!/bin/sh\necho before\necho after\n' > "$SANDBOX_DIR/hook-41b.expected"
cmp -s "$HOOK_41B" "$SANDBOX_DIR/hook-41b.expected" || { printf '%b\n' "${RED}✘ uninstalling an older appended block did not leave exactly the user's lines:${NC}"; cat "$HOOK_41B"; exit 1; }

# 41c: a hook that is not a sh or bash script is left alone.
HOME_41C="$SANDBOX_DIR/home-41c"
mkdir -p "$HOME_41C/.git-templates/hooks"
HOOK_41C="$HOME_41C/.git-templates/hooks/pre-commit"
printf '#!/usr/bin/env python3\nprint("mine")\n' > "$HOOK_41C"
cp "$HOOK_41C" "$SANDBOX_DIR/hook-41c.expected"
OUT_41C=$(global_install_41 "$HOME_41C" install)
cmp -s "$HOOK_41C" "$SANDBOX_DIR/hook-41c.expected" || { printf '%b\n' "${RED}✘ global install modified a hook that is not a sh or bash script${NC}"; exit 1; }
printf '%s\n' "$OUT_41C" | grep -q "Kept your existing global pre-commit hook" || { printf '%b\n' "${RED}✘ global install did not say it kept the user's hook${NC}"; printf '%s\n' "$OUT_41C"; exit 1; }

# 41d: with no hook present, install creates ours and uninstall removes the file.
HOME_41D="$SANDBOX_DIR/home-41d"
mkdir -p "$HOME_41D"
global_install_41 "$HOME_41D" install > /dev/null
[ -f "$HOME_41D/.git-templates/hooks/pre-commit" ] || { printf '%b\n' "${RED}✘ global install did not create the hook${NC}"; exit 1; }
bash -n "$HOME_41D/.git-templates/hooks/pre-commit" || { printf '%b\n' "${RED}✘ the created global hook is not valid bash${NC}"; exit 1; }
global_install_41 "$HOME_41D" uninstall > /dev/null
[ ! -e "$HOME_41D/.git-templates/hooks/pre-commit" ] || { printf '%b\n' "${RED}✘ global uninstall left our hook behind${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 41 passed successfully! The global hook block was appended and removed without touching the user's lines or init.templateDir.${NC}"

# -----------------------------------------------------------------------------
# TEST 42: The installed hooks validate every staged test-case file, whatever its name, and
# a failed validation still aborts the commit (plan 026 item 4)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 42: Hooks validate staged files with spaces, non-ASCII names and renames..."

FIX_42="$REPO_DIR/tests/fixtures/tc-format"

# <repo> [<home>] -- a commit made with the home's global git config when one is given
commit_42() {
    local REPO="$1" HOME_DIR="${2:-$HOME}" MSG="$3"
    HOME="$HOME_DIR" GIT_CONFIG_GLOBAL="$HOME_DIR/.gitconfig" git -C "$REPO" -c user.name=t -c user.email=t@t commit -q -m "$MSG" > "$SANDBOX_DIR/commit-42.log" 2>&1
}

# 42a/42b: the project hook, on a name with spaces, a name with non-ASCII characters and a rename.
REPO_42="$SANDBOX_DIR/hook-names"
rm -rf "$REPO_42"
mkdir -p "$REPO_42"
git -C "$REPO_42" -c init.templateDir= init -q -b main
cd "$REPO_42"
"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-color > /dev/null 2>&1
[ -x ".git/hooks/pre-commit" ] || { printf '%b\n' "${RED}✘ the project hook was not installed${NC}"; exit 1; }

for NAME in "docs/My Tests/TC-AUTH.md" "docs/casos/TC-AÇÃO.md"; do
    mkdir -p "$(dirname "$NAME")"
    cp "$FIX_42/missing-field.md" "$NAME"
    git add -- "$NAME"
    if commit_42 "$REPO_42" "$HOME" "invalid"; then
        printf '%b\n' "${RED}✘ an invalid staged test-case file was committed: $NAME${NC}"
        exit 1
    fi
    git reset -q
    cp "$FIX_42/complete.md" "$NAME"
    git add -- "$NAME"
    commit_42 "$REPO_42" "$HOME" "valid" || { printf '%b\n' "${RED}✘ a valid test-case file was refused: $NAME${NC}"; cat "$SANDBOX_DIR/commit-42.log"; exit 1; }
done

cp "$FIX_42/complete.md" "docs/old name.md"
git add -- "docs/old name.md"
commit_42 "$REPO_42" "$HOME" "add old" || { printf '%b\n' "${RED}✘ a valid test-case file was refused${NC}"; exit 1; }
git mv "docs/old name.md" "docs/new name.md"
cp "$FIX_42/missing-field.md" "docs/new name.md"
git add -- "docs/new name.md"
git diff --cached --name-status | grep -q '^R' || { printf '%b\n' "${RED}✘ test setup: git did not report a rename${NC}"; exit 1; }
if commit_42 "$REPO_42" "$HOME" "renamed"; then
    printf '%b\n' "${RED}✘ an invalid renamed test-case file was committed${NC}"
    exit 1
fi

# 42c: the global block, appended to a hook that runs under plain sh.
HOME_42="$SANDBOX_DIR/home-42"
mkdir -p "$HOME_42/.git-templates/hooks"
printf '#!/bin/sh\necho before\n' > "$HOME_42/.git-templates/hooks/pre-commit"
chmod +x "$HOME_42/.git-templates/hooks/pre-commit"
global_install_41 "$HOME_42" install > /dev/null
GREPO_42="$SANDBOX_DIR/hook-global-names"
rm -rf "$GREPO_42"
HOME="$HOME_42" GIT_CONFIG_GLOBAL="$HOME_42/.gitconfig" git init -q -b main "$GREPO_42"
[ -x "$GREPO_42/.git/hooks/pre-commit" ] || { printf '%b\n' "${RED}✘ the global hook was not copied into a new repository${NC}"; exit 1; }
cd "$GREPO_42"
mkdir -p "docs/My Tests"
cp "$FIX_42/missing-field.md" "docs/My Tests/TC-AUTH.md"
git add -- "docs/My Tests/TC-AUTH.md"
if commit_42 "$GREPO_42" "$HOME_42" "invalid"; then
    printf '%b\n' "${RED}✘ the global hook let an invalid test-case file through${NC}"
    exit 1
fi
cp "$FIX_42/complete.md" "docs/My Tests/TC-AUTH.md"
git add -- "docs/My Tests/TC-AUTH.md"
commit_42 "$GREPO_42" "$HOME_42" "valid" || { printf '%b\n' "${RED}✘ the global hook refused a valid test-case file${NC}"; cat "$SANDBOX_DIR/commit-42.log"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 42 passed successfully! Names with spaces, non-ASCII characters and renames are validated, and a failure still aborts the commit.${NC}"

# -----------------------------------------------------------------------------
# TEST 43: "Add to git and commit?" commits only the files the installer wrote (plan 026 item 6)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 43: The commit offer leaves the user's staged and edited files out..."

REPO_43="$SANDBOX_DIR/commit-offer"
rm -rf "$REPO_43"
mkdir -p "$REPO_43"
cd "$REPO_43"
git init -q -b main
git config user.name "QA Tester"
git config user.email "qa@tester.com"
echo "my notes v1" > CLAUDE.md
git add CLAUDE.md
git commit -q -m "initial"
echo "my notes v2, not meant for this commit" > CLAUDE.md
echo "unrelated" > unrelated.txt
git add unrelated.txt
# Files a vendored copy of this package has, so an over-broad `git add` would pick them up too.
mkdir -p adapters
touch adapters/.keep .gitignore generate-adapters.sh install.sh

FAKE_BIN_43="$SANDBOX_DIR/commit-offer-fakebin"
mkdir -p "$FAKE_BIN_43"
printf '#!/bin/sh\nexit 0\n' > "$FAKE_BIN_43/claude"
chmod +x "$FAKE_BIN_43/claude"
# Answers: (1) Install, (2) yes to "Add to git and commit?", (3) no to "Push to remote?",
# (4) no to the WSL prompt (ignored off WSL).
printf '1\ny\nn\nn\n' | PATH="$FAKE_BIN_43:$PATH" "$REPO_DIR/install.sh" --target project --editor claude --no-hooks > "$SANDBOX_DIR/commit-offer.log" 2>&1

COMMITTED_43="$(git show --name-only --pretty=format: HEAD)"
printf '%s\n' "$COMMITTED_43" | grep -qx ".qa-instinct-manifest" || { printf '%b\n' "${RED}✘ the manifest was not committed${NC}"; cat "$SANDBOX_DIR/commit-offer.log"; exit 1; }
for LEAK in CLAUDE.md unrelated.txt; do
    if printf '%s\n' "$COMMITTED_43" | grep -qx "$LEAK"; then
        printf '%b\n' "${RED}✘ the installer committed $LEAK, which it did not write${NC}"
        exit 1
    fi
done
git diff --cached --name-only | grep -qx "unrelated.txt" || { printf '%b\n' "${RED}✘ the user's staged file is no longer staged${NC}"; exit 1; }
git diff --name-only | grep -qx "CLAUDE.md" || { printf '%b\n' "${RED}✘ the user's edit to CLAUDE.md was committed or lost${NC}"; exit 1; }

# 43b: a 4.x install committed its manifest as .qa-skills-manifest. The next run moves it to the
# current name (plan 066), and the commit it offers carries the old name's removal with it, so the
# repository is not left with a deleted file outside the commit.
git checkout -q -- CLAUDE.md
git reset -q
git mv .qa-instinct-manifest .qa-skills-manifest
git commit -q -m "a 4.x install" -- .qa-instinct-manifest .qa-skills-manifest
# Answers: Install, yes to "Overwrite?" (an install is there), yes to the commit, no, no.
printf '1\ny\ny\nn\nn\n' | PATH="$FAKE_BIN_43:$PATH" "$REPO_DIR/install.sh" --target project --editor claude --no-hooks > "$SANDBOX_DIR/commit-offer-43b.log" 2>&1
COMMITTED_43="$(git show --name-status --no-renames --pretty=format: HEAD)"
printf '%s\n' "$COMMITTED_43" | grep -qx "A	.qa-instinct-manifest" || { printf '%b\n' "${RED}✘ 43b: the new manifest was not committed${NC}"; printf '%s\n' "$COMMITTED_43"; cat "$SANDBOX_DIR/commit-offer-43b.log"; exit 1; }
printf '%s\n' "$COMMITTED_43" | grep -qx "D	.qa-skills-manifest" || { printf '%b\n' "${RED}✘ 43b: the old manifest's removal was not committed${NC}"; printf '%s\n' "$COMMITTED_43"; exit 1; }
[ -z "$(git status --porcelain -- .qa-skills-manifest)" ] || { printf '%b\n' "${RED}✘ 43b: the old manifest's removal was left out of the commit${NC}"; exit 1; }

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 43 passed successfully! The commit offer committed only installer-written files, left the user's work alone, and carried a 4.x manifest's move.${NC}"

# -----------------------------------------------------------------------------
# TEST 44: After `qa-instinct link`, install.sh install and uninstall must not write or delete
# through the linked folders: they are the npm package's own files (plan 033 item 1)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 44: install.sh never writes or deletes through folders qa-instinct link created..."

PKG_44="$SANDBOX_DIR/linked-pkg-44"
PROJ_44="$SANDBOX_DIR/linked-project-44"
mkdir -p "$PKG_44/.claude" "$PROJ_44"
cp -R "$REPO_DIR/cli" "$REPO_DIR/package.json" "$REPO_DIR/.qa-instinct-known-hashes" "$REPO_DIR/.qa-instinct-editor-map" "$PKG_44/"
for SUB in agents commands rules skills hooks; do
    cp -R "$REPO_DIR/.claude/$SUB" "$PKG_44/.claude/"
done
SNAPSHOT_44="$SANDBOX_DIR/linked-pkg-44-before"
cp -R "$PKG_44/.claude" "$SNAPSHOT_44"
BEFORE_44=$(find "$PKG_44/.claude" -type f | wc -l)

cd "$PROJ_44"
git init -q -b main
node "$PKG_44/cli/qa-instinct.js" link > /dev/null
"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks --no-color > "$SANDBOX_DIR/linked-44.log" 2>&1
"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks --no-color --uninstall >> "$SANDBOX_DIR/linked-44.log" 2>&1
AFTER_44=$(find "$PKG_44/.claude" -type f | wc -l)
if [ "$BEFORE_44" != "$AFTER_44" ] || [ "$BEFORE_44" -eq 0 ] || ! diff -r "$SNAPSHOT_44" "$PKG_44/.claude" > /dev/null; then
    printf '%b\n' "${RED}✘ install.sh changed the linked package: $BEFORE_44 files before, $AFTER_44 after${NC}"
    tail -20 "$SANDBOX_DIR/linked-44.log"
    exit 1
fi
grep -q "symbolic link" "$SANDBOX_DIR/linked-44.log" || { printf '%b\n' "${RED}✘ install.sh did not say it skipped a linked folder${NC}"; tail -20 "$SANDBOX_DIR/linked-44.log"; exit 1; }
grep -q "qa-instinct unlink" "$SANDBOX_DIR/linked-44.log" || { printf '%b\n' "${RED}✘ install.sh did not suggest 'qa-instinct unlink' for a qa-instinct link${NC}"; tail -20 "$SANDBOX_DIR/linked-44.log"; exit 1; }
for SUB in agents commands rules skills hooks; do
    [ -L ".claude/$SUB" ] || { printf '%b\n' "${RED}✘ .claude/$SUB is no longer the link qa-instinct link created${NC}"; exit 1; }
done

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 44 passed successfully! install.sh left the linked package's $BEFORE_44 files untouched.${NC}"

# -----------------------------------------------------------------------------
# TEST 45: Making the hooks executable never changes the mode of a file outside the install
# tree, through a linked hook file or a linked hooks folder (plan 033 item 1). install.ps1 sets
# no modes, so this is not a conformance case.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 45: Making hooks executable never chmods through a link..."

OUT_45="$SANDBOX_DIR/hook-mode-outside"
mkdir -p "$OUT_45/hooks-folder"
printf 'echo mine\n' > "$OUT_45/my-tool.sh"
printf 'echo mine\n' > "$OUT_45/hooks-folder/their-tool.sh"
chmod 644 "$OUT_45/my-tool.sh" "$OUT_45/hooks-folder/their-tool.sh"

for INSTALLER_45 in install.sh cli; do
    for LAYOUT_45 in file folder; do
        PROJ_45="$SANDBOX_DIR/hook-mode-$INSTALLER_45-$LAYOUT_45"
        mkdir -p "$PROJ_45/.claude/hooks"
        if [ "$LAYOUT_45" = file ]; then
            ln -s "$OUT_45/my-tool.sh" "$PROJ_45/.claude/hooks/my-tool.sh"
            TARGET_45="$OUT_45/my-tool.sh"
        else
            rmdir "$PROJ_45/.claude/hooks"
            ln -s "$OUT_45/hooks-folder" "$PROJ_45/.claude/hooks"
            TARGET_45="$OUT_45/hooks-folder/their-tool.sh"
        fi
        cd "$PROJ_45"
        if [ "$INSTALLER_45" = install.sh ]; then
            "$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks --no-color > "$SANDBOX_DIR/hook-mode.log" 2>&1
        else
            node "$REPO_DIR/cli/qa-instinct.js" init --editor claude > "$SANDBOX_DIR/hook-mode.log" 2>&1
        fi
        if [ -x "$TARGET_45" ]; then
            printf '%b\n' "${RED}✘ $INSTALLER_45 made a file outside the install tree executable through a linked hook $LAYOUT_45${NC}"
            tail -5 "$SANDBOX_DIR/hook-mode.log"
            exit 1
        fi
        grep -q "symbolic link" "$SANDBOX_DIR/hook-mode.log" || { printf '%b\n' "${RED}✘ $INSTALLER_45 did not report the linked hook $LAYOUT_45${NC}"; tail -5 "$SANDBOX_DIR/hook-mode.log"; exit 1; }
        if [ "$LAYOUT_45" = file ] && [ ! -x .claude/hooks/validate-tc-format.sh ]; then
            printf '%b\n' "${RED}✘ $INSTALLER_45 did not make its own hook executable${NC}"
            exit 1
        fi
        cd "$REPO_DIR"
    done
done

printf '%b\n' "${GREEN}✔ Test 45 passed successfully! No hook link was followed when setting modes, and the package's own hook is executable.${NC}"

# -----------------------------------------------------------------------------
# TEST 46: The manifest gets the umask's mode, as the CLI's does (plan 033 item 2), and a link
# planted at the name of its temp file is never written through (plan 053 I9)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 46: Manifest writes use the umask's mode and never open a link planted at their temp name..."

# 46a: with umask 002 both installers leave a group-writable manifest, as every release did.
for INSTALLER_46 in install.sh cli; do
    PROJ_46="$SANDBOX_DIR/manifest-mode-$INSTALLER_46"
    mkdir -p "$PROJ_46"
    cd "$PROJ_46"
    if [ "$INSTALLER_46" = install.sh ]; then
        (umask 002 && "$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks --no-color > /dev/null 2>&1)
    else
        (umask 002 && node "$REPO_DIR/cli/qa-instinct.js" init --editor claude > /dev/null 2>&1)
    fi
    [ -n "$(find .qa-instinct-manifest -perm 664)" ] || { printf '%b\n' "${RED}✘ $INSTALLER_46 did not give the manifest the umask's mode (664)${NC}"; exit 1; }
    cd "$REPO_DIR"
done

# 46b: a link planted at the exact name of the manifest's temp file is never written or chmodded
# through (plan 053 I9). install.sh names that file <manifest>.tmp.<pid>.<three $RANDOM draws>, so
# the link is planted from BASH_ENV, which runs in the installer's own shell before the script: it
# seeds $RANDOM, plants a link to the victim at the first name manifest_write will draw, and seeds
# $RANDOM again, so the script draws the same numbers. It then unsets BASH_ENV, so no shell the
# installer starts plants anything. The control is a copy of install.sh whose write_exclusive is
# replaced by one that opens any name: it must write through the link. If it does not, the plant
# missed the name install.sh uses and the test fails, rather than pass without testing anything
# (an earlier version intercepted mktemp, which install.sh had stopped calling for this file).
ENV_46="$SANDBOX_DIR/manifest-plant-env.sh"
VICTIM_46="$SANDBOX_DIR/manifest-plant-victim.txt"
PLANTED_46="$SANDBOX_DIR/manifest-plant-name.txt"
cat > "$ENV_46" <<'PLANT_46'
RANDOM=4646
QA_PLANT_AT="$PWD/.qa-instinct-manifest.tmp.$$.$RANDOM$RANDOM$RANDOM"
ln -s "$QA_PLANT_VICTIM" "$QA_PLANT_AT" && printf '%s\n' "$QA_PLANT_AT" > "$QA_PLANT_RECORD"
unset BASH_ENV QA_PLANT_AT QA_PLANT_VICTIM QA_PLANT_RECORD
RANDOM=4646
PLANT_46
MUTANT_46="$SANDBOX_DIR/manifest-plant-mutant"
mkdir -p "$MUTANT_46"
for PKG_46 in .claude adapters .qa-instinct-editor-map .qa-instinct-known-hashes; do ln -s "$REPO_DIR/$PKG_46" "$MUTANT_46/$PKG_46"; done
grep -q '^write_exclusive() {' "$REPO_DIR/install.sh" || { printf '%b\n' "${RED}✘ install.sh has no write_exclusive any more; update Test 46b's control${NC}"; exit 1; }
# shellcheck disable=SC2016 # the replacement is shell code for the copy, not for this script
sed -e '/^write_exclusive() {/,/^}/c\
write_exclusive() { local FILE="$1"; shift; "$@" > "$FILE"; }
' "$REPO_DIR/install.sh" > "$MUTANT_46/install.sh"
chmod +x "$MUTANT_46/install.sh"
plant_46() {   # installer project -> victim content after an install with the link planted
    printf 'VICTIM CONTENT\n' > "$VICTIM_46"
    chmod 600 "$VICTIM_46"
    rm -f "$PLANTED_46"
    mkdir -p "$2"
    (cd "$2" && BASH_ENV="$ENV_46" QA_PLANT_VICTIM="$VICTIM_46" QA_PLANT_RECORD="$PLANTED_46" "$1" --target project --editor claude --non-interactive --no-hooks --no-color > "$2.log" 2>&1) || true
    [ -s "$PLANTED_46" ] || { printf '%b\n' "${RED}✘ Test 46b planted no link${NC}"; tail -3 "$2.log"; exit 1; }
}
plant_46 "$MUTANT_46/install.sh" "$SANDBOX_DIR/manifest-plant-control"
if [ "$(cat "$VICTIM_46")" = "VICTIM CONTENT" ]; then
    printf '%b\n' "${RED}✘ Test 46b's control did not write through the planted link: it is not at the name install.sh uses${NC}"; exit 1
fi
plant_46 "$REPO_DIR/install.sh" "$SANDBOX_DIR/manifest-plant"
[ "$(cat "$VICTIM_46")" = "VICTIM CONTENT" ] || { printf '%b\n' "${RED}✘ install.sh wrote the manifest through a link planted at its temp file's name${NC}"; head -3 "$VICTIM_46"; exit 1; }
[ -n "$(find "$VICTIM_46" -perm 600)" ] || { printf '%b\n' "${RED}✘ install.sh changed the mode of a file through a link planted at its temp file's name${NC}"; exit 1; }
[ "$(readlink "$(cat "$PLANTED_46")")" = "$VICTIM_46" ] || { printf '%b\n' "${RED}✘ install.sh removed or replaced the link planted at its temp file's name${NC}"; exit 1; }
MF_46="$SANDBOX_DIR/manifest-plant/.qa-instinct-manifest"
{ [ -f "$MF_46" ] && [ ! -L "$MF_46" ] && grep -q '  claude  .claude/commands/qa.md$' "$MF_46"; } || { printf '%b\n' "${RED}✘ install.sh did not write its manifest beside the planted link${NC}"; tail -5 "$SANDBOX_DIR/manifest-plant.log"; exit 1; }
cd "$REPO_DIR"

printf '%b\n' "${GREEN}✔ Test 46 passed successfully! The manifest has the umask's mode, and a link planted at its temp file's name was never written through.${NC}"

# -----------------------------------------------------------------------------
# TEST 47: The CLI refuses a command or an option it does not know, and writes nothing
# (plan 033 item 4). The unknown option is conformance case 020; the unknown command and the
# --globl typo, which would otherwise install into the project, are the CLI's own.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 47: The CLI refuses an unknown command or option and writes nothing..."

PROJ_47="$SANDBOX_DIR/cli-unknown-input"
mkdir -p "$PROJ_47"
cd "$PROJ_47"
for ARGS_47 in "instal" "init --globl --editor claude" "uninstall --editr claude" "link --editor claude"; do
    STATUS_47=0
    # shellcheck disable=SC2086 # the words are meant to split into separate arguments
    node "$REPO_DIR/cli/qa-instinct.js" $ARGS_47 > "$SANDBOX_DIR/cli-unknown-input.log" 2>&1 || STATUS_47=$?
    [ "$STATUS_47" -eq 1 ] || { printf '%b\n' "${RED}✘ 'qa-instinct $ARGS_47' exited $STATUS_47, expected 1${NC}"; tail -5 "$SANDBOX_DIR/cli-unknown-input.log"; exit 1; }
    grep -q "Error: unknown" "$SANDBOX_DIR/cli-unknown-input.log" || { printf '%b\n' "${RED}✘ 'qa-instinct $ARGS_47' did not name what it refused${NC}"; tail -5 "$SANDBOX_DIR/cli-unknown-input.log"; exit 1; }
    [ -z "$(ls -A)" ] || { printf '%b\n' "${RED}✘ 'qa-instinct $ARGS_47' wrote into the project:${NC}"; ls -A; exit 1; }
done
for ARGS_47 in "help" "--help" "-h" ""; do
    # shellcheck disable=SC2086 # the words are meant to split into separate arguments
    node "$REPO_DIR/cli/qa-instinct.js" $ARGS_47 > /dev/null 2>&1 || { printf '%b\n' "${RED}✘ 'qa-instinct $ARGS_47' did not print help with exit 0${NC}"; exit 1; }
done

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 47 passed successfully! Unknown commands and options were refused before anything was written.${NC}"

# -----------------------------------------------------------------------------
# TEST 48: GLOBAL=true ./generate-adapters.sh never overwrites a user's own global CLAUDE.md or
# AGENTS.md (plan 033 item 7). Bash only: generate-adapters.ps1 has no GLOBAL mode.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 48: The generator's global mode keeps a user's own global files..."

HOME_48="$SANDBOX_DIR/generator-home-48"
mkdir -p "$HOME_48/.claude"
printf 'MY OWN GLOBAL CLAUDE NOTES\n' > "$HOME_48/.claude/CLAUDE.md"
printf 'MY OWN AGENTS FILE\n' > "$HOME_48/AGENTS.md"
HOME="$HOME_48" GLOBAL=true ./generate-adapters.sh > "$SANDBOX_DIR/generator-48.log" 2>&1 || { printf '%b\n' "${RED}✘ GLOBAL=true ./generate-adapters.sh failed${NC}"; tail -5 "$SANDBOX_DIR/generator-48.log"; exit 1; }
[ "$(cat "$HOME_48/.claude/CLAUDE.md")" = "MY OWN GLOBAL CLAUDE NOTES" ] || { printf '%b\n' "${RED}✘ The generator overwrote the user's ~/.claude/CLAUDE.md${NC}"; exit 1; }
[ "$(cat "$HOME_48/AGENTS.md")" = "MY OWN AGENTS FILE" ] || { printf '%b\n' "${RED}✘ The generator overwrote the user's ~/AGENTS.md${NC}"; exit 1; }
grep -q "merge adapters/universal/CLAUDE.md into it by hand" "$SANDBOX_DIR/generator-48.log" || { printf '%b\n' "${RED}✘ The generator did not say how to merge the kept file${NC}"; tail -5 "$SANDBOX_DIR/generator-48.log"; exit 1; }

# With nothing there, global mode still installs both files.
HOME_48B="$SANDBOX_DIR/generator-home-48b"
mkdir -p "$HOME_48B"
HOME="$HOME_48B" GLOBAL=true ./generate-adapters.sh > /dev/null 2>&1
cmp -s "$HOME_48B/.claude/CLAUDE.md" adapters/universal/CLAUDE.md || { printf '%b\n' "${RED}✘ The generator did not install ~/.claude/CLAUDE.md into an empty home${NC}"; exit 1; }
cmp -s "$HOME_48B/AGENTS.md" adapters/universal/AGENTS.md || { printf '%b\n' "${RED}✘ The generator did not install ~/AGENTS.md into an empty home${NC}"; exit 1; }

printf '%b\n' "${GREEN}✔ Test 48 passed successfully! The generator kept the user's global files and installed into an empty home.${NC}"

# -----------------------------------------------------------------------------
# TEST 49: A link planted at the exact name of a backup, or of a backup's .link-target file, is
# never written through (plan 033, found while implementing items 1-2). The names carry a UTC
# timestamp, so the clock is pinned: a date stand-in for install.sh, a Date preload for the CLI.
# install.ps1 cannot have its clock pinned from here; the Windows job runs the rest of its suite.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 49: Backups and link-target files are never written through a planted link..."

PIN_49="$SANDBOX_DIR/pinned-clock-49"
mkdir -p "$PIN_49/bin"
REAL_DATE_49="$(command -v date)"
cat > "$PIN_49/bin/date" <<EOF
#!/bin/sh
case "\$*" in
    *%Y%m%dT%H%M%SZ*) echo 20300101T000000Z ;;
    *) exec "$REAL_DATE_49" "\$@" ;;
esac
EOF
chmod +x "$PIN_49/bin/date"
cat > "$PIN_49/date.js" <<'EOF'
const RealDate = Date;
const PINNED = RealDate.UTC(2030, 0, 1);
global.Date = class extends RealDate {
  constructor(...args) {
    if (args.length === 0) super(PINNED);
    else super(...args);
  }
  static now() {
    return PINNED;
  }
};
EOF
STAMP_49="qa-instinct-backup-20300101T000000Z"

for INSTALLER_49 in install.sh cli; do
    for LAYOUT_49 in backup link-target; do
        PROJ_49="$SANDBOX_DIR/planted-$INSTALLER_49-$LAYOUT_49"
        VICTIM_49="$SANDBOX_DIR/planted-victim-$INSTALLER_49-$LAYOUT_49.txt"
        mkdir -p "$PROJ_49/.claude/rules"
        if [ "$LAYOUT_49" = backup ]; then
            # The user's own file collides with a package file, so it is backed up.
            printf 'MY OWN RULE 49\n' > "$PROJ_49/.claude/rules/security-qa.md"
            ln -s "$VICTIM_49" "$PROJ_49/.claude/rules/security-qa.md.$STAMP_49"
        else
            # The colliding file is a link to the user's file, so its target is recorded too.
            printf 'MY OWN RULE 49\n' > "$SANDBOX_DIR/planted-outside-$INSTALLER_49.md"
            ln -s "$SANDBOX_DIR/planted-outside-$INSTALLER_49.md" "$PROJ_49/.claude/rules/security-qa.md"
            ln -s "$VICTIM_49" "$PROJ_49/.claude/rules/security-qa.md.$STAMP_49.link-target"
        fi
        cd "$PROJ_49"
        STATUS_49=0
        if [ "$INSTALLER_49" = install.sh ]; then
            PATH="$PIN_49/bin:$PATH" "$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks --no-color > "$SANDBOX_DIR/planted-49.log" 2>&1 || STATUS_49=$?
        else
            NODE_OPTIONS="--require $PIN_49/date.js" node "$REPO_DIR/cli/qa-instinct.js" init --editor claude > "$SANDBOX_DIR/planted-49.log" 2>&1 || STATUS_49=$?
        fi
        if [ -e "$VICTIM_49" ]; then
            printf '%b\n' "${RED}✘ $INSTALLER_49 wrote through a link planted at the $LAYOUT_49 name${NC}"; head -3 "$VICTIM_49"; exit 1
        fi
        [ "$STATUS_49" -eq 0 ] || { printf '%b\n' "${RED}✘ $INSTALLER_49 failed ($STATUS_49) on a link planted at the $LAYOUT_49 name${NC}"; tail -5 "$SANDBOX_DIR/planted-49.log"; exit 1; }
        if [ "$LAYOUT_49" = backup ]; then
            BACKUP_49="$(grep -lx 'MY OWN RULE 49' .claude/rules/security-qa.md.qa-instinct-backup-* 2>/dev/null | head -1)"
            [ -n "$BACKUP_49" ] || { printf '%b\n' "${RED}✘ $INSTALLER_49 did not back up the user's file under another name${NC}"; ls .claude/rules; exit 1; }
        fi
        cd "$REPO_DIR"
    done
done

printf '%b\n' "${GREEN}✔ Test 49 passed successfully! No backup or link-target write followed a planted link.${NC}"

# -----------------------------------------------------------------------------
# TEST 50: install.sh never takes a file it could not hash for one that matches (plan 045 item 1).
# A failed hash used to print nothing, and nothing equals an empty recorded hash, so the user's
# file was overwritten with no backup and recorded with an empty hash.
# 50a: with neither sha256sum nor shasum on PATH, install.sh stops before writing anything.
# 50b: a destination it cannot read is skipped and reported, never overwritten unproven.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 50: install.sh never treats a file it could not hash as matching..."

NOHASH_50="$SANDBOX_DIR/no-hash-50"
mkdir -p "$NOHASH_50/bin" "$NOHASH_50/project/.claude/rules" "$NOHASH_50/home"
# Every tool install.sh calls, except the two SHA-256 tools.
for TOOL_50 in awk basename cat chmod cmp cp cut date dirname find git grep head ls mkdir mktemp mv perl readlink rm rmdir sed sort tail touch tr uname wc; do
    TOOL_PATH_50="$(command -v "$TOOL_50" 2>/dev/null)" || continue
    ln -s "$TOOL_PATH_50" "$NOHASH_50/bin/$TOOL_50"
done
printf 'MY OWN RULES 50\n' > "$NOHASH_50/project/.claude/rules/security-qa.md"
STATUS_50=0
(cd "$NOHASH_50/project" && env -i HOME="$NOHASH_50/home" PATH="$NOHASH_50/bin" "$BASH" "$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks --no-color > "$NOHASH_50/install.log" 2>&1) || STATUS_50=$?
[ "$STATUS_50" -ne 0 ] || { printf '%b\n' "${RED}✘ install.sh ran with no SHA-256 tool (exit 0)${NC}"; tail -5 "$NOHASH_50/install.log"; exit 1; }
grep -q "SHA-256" "$NOHASH_50/install.log" || { printf '%b\n' "${RED}✘ install.sh did not say it needs a SHA-256 tool${NC}"; tail -5 "$NOHASH_50/install.log"; exit 1; }
[ "$(cat "$NOHASH_50/project/.claude/rules/security-qa.md")" = "MY OWN RULES 50" ] || { printf '%b\n' "${RED}✘ install.sh overwrote the user's file with no SHA-256 tool${NC}"; exit 1; }
WRITTEN_50="$(cd "$NOHASH_50/project" && find . -mindepth 1 | LC_ALL=C sort | tr '\n' ' ')"
[ "$WRITTEN_50" = "./.claude ./.claude/rules ./.claude/rules/security-qa.md " ] || { printf '%b\n' "${RED}✘ install.sh wrote into the project with no SHA-256 tool: $WRITTEN_50${NC}"; exit 1; }
[ -z "$(ls -A "$NOHASH_50/home")" ] || { printf '%b\n' "${RED}✘ install.sh wrote into the home folder with no SHA-256 tool${NC}"; exit 1; }

if [ "$(id -u)" = "0" ]; then
    echo "Skipping Test 50b: running as root, who can read a mode 0200 file."
else
    PROJ_50="$SANDBOX_DIR/unreadable-50"
    mkdir -p "$PROJ_50/.claude/rules"
    printf 'MY SECRET RULES 50\n' > "$PROJ_50/.claude/rules/security-qa.md"
    chmod 0200 "$PROJ_50/.claude/rules/security-qa.md"
    STATUS_50=0
    (cd "$PROJ_50" && "$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks --no-color > "$SANDBOX_DIR/unreadable-50.log" 2>&1) || STATUS_50=$?
    chmod 0600 "$PROJ_50/.claude/rules/security-qa.md"
    [ "$STATUS_50" -eq 0 ] || { printf '%b\n' "${RED}✘ install.sh failed ($STATUS_50) on a destination it cannot read${NC}"; tail -5 "$SANDBOX_DIR/unreadable-50.log"; exit 1; }
    [ "$(cat "$PROJ_50/.claude/rules/security-qa.md")" = "MY SECRET RULES 50" ] || { printf '%b\n' "${RED}✘ install.sh overwrote a file it could not read${NC}"; exit 1; }
    grep -q "Skipped .claude/rules/security-qa.md" "$SANDBOX_DIR/unreadable-50.log" || { printf '%b\n' "${RED}✘ install.sh did not report the file it skipped${NC}"; tail -5 "$SANDBOX_DIR/unreadable-50.log"; exit 1; }
    if grep -q "security-qa.md" "$PROJ_50/.qa-instinct-manifest"; then printf '%b\n' "${RED}✘ a skipped file was recorded in the manifest${NC}"; exit 1; fi
    [ -f "$PROJ_50/.claude/commands/qa.md" ] || { printf '%b\n' "${RED}✘ the rest of the tree did not install${NC}"; exit 1; }
    if grep -vE '^[0-9a-f]{64}  [a-z]+  [^ ]' "$PROJ_50/.qa-instinct-manifest"; then printf '%b\n' "${RED}✘ the manifest has a line without a hash (above)${NC}"; exit 1; fi
fi

printf '%b\n' "${GREEN}✔ Test 50 passed successfully! No hash, no decision: nothing was overwritten unproven.${NC}"

# -----------------------------------------------------------------------------
# TEST 51: install.sh uses no GNU-only grep option (plan 045 item 4). BSD grep, the one macOS
# ships, has no -P; a grep stand-in that refuses it, as BSD grep does, runs the reinstall path
# that reads the installed version.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 51: install.sh runs with a grep that has no -P, as on macOS..."

BSD_GREP_51="$SANDBOX_DIR/bsd-grep-51"
mkdir -p "$BSD_GREP_51/bin" "$BSD_GREP_51/project"
REAL_GREP_51="$(command -v grep)"
cat > "$BSD_GREP_51/bin/grep" <<EOF
#!/bin/sh
for A in "\$@"; do
    case "\$A" in
        --) break ;;
        --perl-regexp*) echo "grep: unrecognized option '\$A'" >&2; exit 2 ;;
        --*) ;;
        -*P*) echo "grep: invalid option -- P" >&2; exit 2 ;;
    esac
done
exec "$REAL_GREP_51" "\$@"
EOF
chmod +x "$BSD_GREP_51/bin/grep"
cd "$BSD_GREP_51/project"
"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks --no-color > /dev/null 2>&1
PATH="$BSD_GREP_51/bin:$PATH" "$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks --no-color > "$BSD_GREP_51/install.log" 2>&1 || { printf '%b\n' "${RED}✘ install.sh failed with a grep that has no -P${NC}"; tail -5 "$BSD_GREP_51/install.log"; exit 1; }
if grep -q "invalid option\|unrecognized option" "$BSD_GREP_51/install.log"; then printf '%b\n' "${RED}✘ install.sh called grep with an option BSD grep does not have:${NC}"; grep "option" "$BSD_GREP_51/install.log"; exit 1; fi
grep -qE "Installed version : [^ ]" "$BSD_GREP_51/install.log" || { printf '%b\n' "${RED}✘ install.sh printed no installed version${NC}"; grep "version" "$BSD_GREP_51/install.log"; exit 1; }
cd "$REPO_DIR"

printf '%b\n' "${GREEN}✔ Test 51 passed successfully! install.sh ran its reinstall path with a grep that has no -P.${NC}"

# -----------------------------------------------------------------------------
# TEST 52: A link to a FIFO planted at the exact backup name is never opened (plan 045 item 5).
# bash's noclobber only adds O_EXCL when the name does not exist; a link to an existing FIFO or
# device is opened through, and opening a FIFO for writing waits for a reader for ever. The clock
# is pinned as in Test 49, and the run is killed if it hangs.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 52: A link to a FIFO at the backup name is skipped, never opened..."

FIFO_52="$SANDBOX_DIR/fifo-52"
mkdir -p "$FIFO_52/project/.claude/rules"
mkfifo "$FIFO_52/fifo"
printf 'MY OWN RULE 52\n' > "$FIFO_52/project/.claude/rules/security-qa.md"
ln -s "$FIFO_52/fifo" "$FIFO_52/project/.claude/rules/security-qa.md.$STAMP_49"
if command -v timeout > /dev/null 2>&1; then
    LIMIT_52=(timeout 60)
else
    LIMIT_52=(perl -e 'alarm shift; exec @ARGV' 60)
fi
cd "$FIFO_52/project"
STATUS_52=0
PATH="$PIN_49/bin:$PATH" "${LIMIT_52[@]}" "$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-hooks --no-color > "$FIFO_52/install.log" 2>&1 < /dev/null || STATUS_52=$?
[ "$STATUS_52" -eq 0 ] || { printf '%b\n' "${RED}✘ install.sh hung or failed ($STATUS_52) on a link to a FIFO at the backup name${NC}"; tail -5 "$FIFO_52/install.log"; exit 1; }
[ -p "$FIFO_52/fifo" ] || { printf '%b\n' "${RED}✘ the FIFO behind the planted link was replaced${NC}"; exit 1; }
[ -L ".claude/rules/security-qa.md.$STAMP_49" ] || { printf '%b\n' "${RED}✘ the planted link was replaced${NC}"; exit 1; }
BACKUP_52="$(grep -lx 'MY OWN RULE 52' .claude/rules/security-qa.md.qa-instinct-backup-*-* 2>/dev/null | head -1)"
[ -n "$BACKUP_52" ] || { printf '%b\n' "${RED}✘ install.sh did not back up the user's file under the next name${NC}"; ls .claude/rules; exit 1; }
cmp -s .claude/rules/security-qa.md "$REPO_DIR/.claude/rules/security-qa.md" || { printf '%b\n' "${RED}✘ the package's file was not installed${NC}"; exit 1; }
cd "$REPO_DIR"

printf '%b\n' "${GREEN}✔ Test 52 passed successfully! The link to a FIFO was left alone and the backup took the next name.${NC}"

# -----------------------------------------------------------------------------
# TEST 53: The commit offer works in a git worktree, whose .git is a file, and never passes git a
# manifest path that leaves the project (plan 045 item 7).
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 53: The commit offer works in a worktree and skips a manifest path outside it..."

MAIN_53="$SANDBOX_DIR/commit-worktree-main"
WT_53="$SANDBOX_DIR/commit-worktree"
FAKE_BIN_53="$SANDBOX_DIR/commit-worktree-fakebin"
mkdir -p "$MAIN_53" "$FAKE_BIN_53"
# Claude Code present; on WSL the Windows side fails, so a stray "y" writes nothing outside.
printf '#!/bin/sh\nexit 0\n' > "$FAKE_BIN_53/claude"
printf '#!/bin/sh\nexit 1\n' > "$FAKE_BIN_53/cmd.exe"
printf '#!/bin/sh\nexit 1\n' > "$FAKE_BIN_53/wslpath"
chmod +x "$FAKE_BIN_53/claude" "$FAKE_BIN_53/cmd.exe" "$FAKE_BIN_53/wslpath"
cd "$MAIN_53"
git init -q -b main
git config user.name "QA Tester"
git config user.email "qa@tester.com"
echo "base" > README.md
git add README.md
git commit -q -m "initial"
git worktree add -q -b qa-53 "$WT_53"
cd "$WT_53"
[ -f .git ] || { printf '%b\n' "${RED}✘ the worktree's .git should be a file${NC}"; exit 1; }
# A committed manifest is attacker-controllable: an entry climbing out of the project must never
# reach git add, where it would make the whole commit fail (or add a file outside).
printf 'outside the project\n' > "$SANDBOX_DIR/commit-worktree-outside.txt"
printf '%064d  cursor  ../commit-worktree-outside.txt\n' 0 > .qa-instinct-manifest
# Answers: (1) Install, (2) yes to "Add to git and commit?", (3) no to "Push to remote?",
# (4) no to the WSL prompt (ignored off WSL).
printf '1\ny\nn\nn\n' | PATH="$FAKE_BIN_53:$PATH" "$REPO_DIR/install.sh" --target project --editor claude --no-hooks --no-color > "$SANDBOX_DIR/commit-worktree.log" 2>&1 || { printf '%b\n' "${RED}✘ install.sh failed in a worktree${NC}"; tail -5 "$SANDBOX_DIR/commit-worktree.log"; exit 1; }
[ "$(git log -1 --format=%s)" = "Add/update QA skill for AI-assisted editors (ISTQB CTFL v4.0)" ] || { printf '%b\n' "${RED}✘ install.sh did not commit in a worktree${NC}"; tail -8 "$SANDBOX_DIR/commit-worktree.log"; exit 1; }
COMMITTED_53="$(git show --name-only --pretty=format: HEAD)"
for WANT_53 in .qa-instinct-manifest .claude/commands/qa.md; do
    printf '%s\n' "$COMMITTED_53" | grep -qx "$WANT_53" || { printf '%b\n' "${RED}✘ $WANT_53 was not committed${NC}"; exit 1; }
done
if printf '%s\n' "$COMMITTED_53" | grep -q "outside"; then printf '%b\n' "${RED}✘ a manifest path outside the project was committed${NC}"; exit 1; fi
cd "$REPO_DIR"

printf '%b\n' "${GREEN}✔ Test 53 passed successfully! The worktree got its commit, and the path outside it was left out.${NC}"

# -----------------------------------------------------------------------------
# TEST 54: Updating from a real earlier release (plan 014 A4, plan 045 item 9). Release 4.0.1,
# as tests/fixtures/release-v4.0.1 holds it, installs every editor with its own installer; the
# current install.sh then runs --update. The result must equal a fresh install of the current
# tree, file for file and manifest line for manifest line, with no backup; uninstall must then
# leave nothing behind. 4.0.1 had no global install of Copilot or Cline, and update never adds an
# editor, so the fresh home install is of the editors 4.0.1 installed there (plan 058).
# 4.0.1 recorded its install in .qa-skills-manifest, so the update also moves the manifest to its
# current name (plan 066); the tree comparison fails on an old manifest left behind.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 54: An install of release 4.0.1 updates to the current tree and uninstalls cleanly..."

V401_54="$SANDBOX_DIR/release-v4.0.1"
UP_54="$SANDBOX_DIR/upgrade-54"
FRESH_54="$SANDBOX_DIR/fresh-54"
cp -R "$REPO_DIR/tests/fixtures/release-v4.0.1" "$V401_54"
mkdir -p "$UP_54/project" "$UP_54/home" "$FRESH_54/project" "$FRESH_54/home"
(cd "$V401_54" && "$BASH" ./generate-adapters.sh > "$SANDBOX_DIR/v401-generate.log" 2>&1) || { printf '%b\n' "${RED}✘ release 4.0.1's generator failed${NC}"; tail -5 "$SANDBOX_DIR/v401-generate.log"; exit 1; }
(cd "$UP_54/project" && HOME="$UP_54/home" "$BASH" "$V401_54/install.sh" --target both --editor all --non-interactive --no-hooks --no-color > "$SANDBOX_DIR/v401-install.log" 2>&1) || { printf '%b\n' "${RED}✘ release 4.0.1's installer failed${NC}"; tail -5 "$SANDBOX_DIR/v401-install.log"; exit 1; }
for SCOPE_54 in project home; do
    [ -f "$UP_54/$SCOPE_54/.qa-skills-manifest" ] || { printf '%b\n' "${RED}✘ release 4.0.1 wrote no $SCOPE_54 manifest${NC}"; exit 1; }
done
(cd "$UP_54/project" && HOME="$UP_54/home" "$REPO_DIR/install.sh" --target both --editor all --non-interactive --no-hooks --no-color --update > "$SANDBOX_DIR/v401-update.log" 2>&1) || { printf '%b\n' "${RED}✘ --update over release 4.0.1 failed${NC}"; tail -5 "$SANDBOX_DIR/v401-update.log"; exit 1; }
(cd "$FRESH_54/project" && HOME="$FRESH_54/home" "$REPO_DIR/install.sh" --target project --editor all --non-interactive --no-hooks --no-color > /dev/null 2>&1)
for ED_54 in claude cursor windsurf antigravity; do
    (cd "$FRESH_54/project" && HOME="$FRESH_54/home" "$REPO_DIR/install.sh" --target global --editor "$ED_54" --non-interactive --no-hooks --no-color > /dev/null 2>&1)
done

BACKUPS_54="$(find "$UP_54" -name '*.qa-instinct-backup-*')"
[ -z "$BACKUPS_54" ] || { printf '%b\n' "${RED}✘ --update over release 4.0.1 made backups:${NC}"; printf '%s\n' "$BACKUPS_54"; exit 1; }
if grep -q "Kept" "$SANDBOX_DIR/v401-update.log"; then printf '%b\n' "${RED}✘ --update over release 4.0.1 kept files it should have replaced:${NC}"; grep "Kept" "$SANDBOX_DIR/v401-update.log"; exit 1; fi
for SCOPE_54 in project home; do
    if ! diff <(LC_ALL=C sort "$UP_54/$SCOPE_54/.qa-instinct-manifest") <(LC_ALL=C sort "$FRESH_54/$SCOPE_54/.qa-instinct-manifest") > "$SANDBOX_DIR/v401-manifest.diff"; then
        printf '%b\n' "${RED}✘ the $SCOPE_54 manifest after --update differs from a fresh install's (< updated, > fresh):${NC}"; head -20 "$SANDBOX_DIR/v401-manifest.diff"; exit 1
    fi
    if ! diff -r "$UP_54/$SCOPE_54" "$FRESH_54/$SCOPE_54" > "$SANDBOX_DIR/v401-tree.diff" 2>&1; then
        printf '%b\n' "${RED}✘ the $SCOPE_54 tree after --update differs from a fresh install's:${NC}"; head -20 "$SANDBOX_DIR/v401-tree.diff"; exit 1
    fi
done

(cd "$UP_54/project" && HOME="$UP_54/home" "$REPO_DIR/install.sh" --target both --editor all --non-interactive --no-hooks --no-color --uninstall > "$SANDBOX_DIR/v401-uninstall.log" 2>&1) || { printf '%b\n' "${RED}✘ uninstall after the update failed${NC}"; tail -5 "$SANDBOX_DIR/v401-uninstall.log"; exit 1; }
LEFT_54="$(find "$UP_54/project" "$UP_54/home" -mindepth 1)"
[ -z "$LEFT_54" ] || { printf '%b\n' "${RED}✘ uninstall after the update left:${NC}"; printf '%s\n' "$LEFT_54" | head -20; exit 1; }

printf '%b\n' "${GREEN}✔ Test 54 passed successfully! Release 4.0.1 updated to a fresh install's exact tree with no backup, and uninstalled to nothing.${NC}"

# -----------------------------------------------------------------------------
# TEST 60: The CLI skips a destination that is a folder and carries on (plan 046 item 1). Cline
# also reads a .clinerules folder, so a project may already have one where the CLI installs the
# .clinerules file: copyFileSync threw EISDIR, the CLI exited 1 with a stack trace, and with
# --editor all the editors after Cline were never installed. Conformance cases 044-045 hold the
# shared behaviour; this checks the CLI's crash, --editor all, and update over such a folder.
# Since plan 047 Cline installs into .cline/, so the folder stands at Copilot's
# .github/copilot-instructions.md, a path the package still writes.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 60: The CLI skips a destination that is a folder and installs the rest..."

PROJ_60="$SANDBOX_DIR/cli-folder-destination"
DIR_60=".github/copilot-instructions.md"
mkdir -p "$PROJ_60/$DIR_60"
printf 'MY COPILOT NOTES 60\n' > "$PROJ_60/$DIR_60/01-mine.md"
cd "$PROJ_60"
for OP_60 in "init --editor all" "update --editor all" "uninstall --editor all"; do
    STATUS_60=0
    # shellcheck disable=SC2086 # the words are meant to split into separate arguments
    node "$REPO_DIR/cli/qa-instinct.js" $OP_60 > "$SANDBOX_DIR/cli-folder-destination.log" 2>&1 || STATUS_60=$?
    [ "$STATUS_60" -eq 0 ] || { printf '%b\n' "${RED}✘ 'qa-instinct $OP_60' exited $STATUS_60 over a folder at $DIR_60${NC}"; tail -8 "$SANDBOX_DIR/cli-folder-destination.log"; exit 1; }
    if grep -q "EISDIR\|node:internal\|    at " "$SANDBOX_DIR/cli-folder-destination.log"; then
        printf '%b\n' "${RED}✘ 'qa-instinct $OP_60' printed a stack trace over a folder at $DIR_60${NC}"; tail -8 "$SANDBOX_DIR/cli-folder-destination.log"; exit 1
    fi
    if [ "$(find "$DIR_60" -mindepth 1 | tr '\n' ' ')" != "$DIR_60/01-mine.md " ] || [ "$(cat "$DIR_60/01-mine.md")" != "MY COPILOT NOTES 60" ]; then
        printf '%b\n' "${RED}✘ 'qa-instinct $OP_60' changed the folder at $DIR_60:${NC}"; find "$DIR_60"; exit 1
    fi
    if grep -q "  copilot  $DIR_60$" .qa-instinct-manifest 2>/dev/null; then
        printf '%b\n' "${RED}✘ 'qa-instinct $OP_60' recorded the folder at $DIR_60 in the manifest${NC}"; exit 1
    fi
    case "$OP_60" in
        init*)
            grep -q "Skipped $DIR_60" "$SANDBOX_DIR/cli-folder-destination.log" || { printf '%b\n' "${RED}✘ init did not say it skipped the folder at $DIR_60${NC}"; cat "$SANDBOX_DIR/cli-folder-destination.log"; exit 1; }
            # Copilot's other files (its skills) are written, so its line is printed now; the one
            # it skipped is reported above (plan 047).
            for F_60 in .claude/commands/qa.md .cursor/rules/qa-instinct.mdc .github/skills/qa/SKILL.md .cline/rules/qa-instinct.md .agents/skills/qa/SKILL.md; do
                [ -f "$F_60" ] || { printf '%b\n' "${RED}✘ init --editor all stopped before installing $F_60${NC}"; tail -8 "$SANDBOX_DIR/cli-folder-destination.log"; exit 1; }
            done ;;
        uninstall*)
            [ ! -e .agents/skills/qa/SKILL.md ] || { printf '%b\n' "${RED}✘ uninstall --editor all left Antigravity's file${NC}"; exit 1; } ;;
    esac
done

# A recorded file that has since become a folder: update writes nothing into it and keeps it,
# and uninstall keeps it.
PROJ_60B="$SANDBOX_DIR/cli-folder-destination-recorded"
mkdir -p "$PROJ_60B"
cd "$PROJ_60B"
node "$REPO_DIR/cli/qa-instinct.js" init --editor cursor > /dev/null
rm .cursor/rules/qa-instinct.mdc
mkdir .cursor/rules/qa-instinct.mdc
for OP_60 in update uninstall; do
    STATUS_60=0
    node "$REPO_DIR/cli/qa-instinct.js" "$OP_60" --editor cursor > "$SANDBOX_DIR/cli-folder-destination.log" 2>&1 || STATUS_60=$?
    [ "$STATUS_60" -eq 0 ] || { printf '%b\n' "${RED}✘ 'qa-instinct $OP_60' exited $STATUS_60 over a recorded file that is now a folder${NC}"; tail -8 "$SANDBOX_DIR/cli-folder-destination.log"; exit 1; }
    { [ -d .cursor/rules/qa-instinct.mdc ] && [ -z "$(ls -A .cursor/rules/qa-instinct.mdc)" ]; } || { printf '%b\n' "${RED}✘ 'qa-instinct $OP_60' changed a recorded file that is now a folder${NC}"; ls -la .cursor/rules; exit 1; }
done
# An install from before manifests existed, with a folder where a package file goes: uninstall
# keeps the folder, says so, and does not stop on it.
PROJ_60C="$SANDBOX_DIR/cli-folder-destination-premanifest"
mkdir -p "$PROJ_60C/.claude/rules/security-qa.md"
printf 'MY NOTES 60\n' > "$PROJ_60C/.claude/rules/security-qa.md/notes.md"
cp "$REPO_DIR/.claude/rules/test-tools.md" "$PROJ_60C/.claude/rules/test-tools.md"
cd "$PROJ_60C"
STATUS_60=0
node "$REPO_DIR/cli/qa-instinct.js" uninstall > "$SANDBOX_DIR/cli-folder-destination.log" 2>&1 || STATUS_60=$?
[ "$STATUS_60" -eq 0 ] || { printf '%b\n' "${RED}✘ uninstall exited $STATUS_60 over a folder at a package path, with no manifest${NC}"; tail -8 "$SANDBOX_DIR/cli-folder-destination.log"; exit 1; }
[ "$(cat .claude/rules/security-qa.md/notes.md)" = "MY NOTES 60" ] || { printf '%b\n' "${RED}✘ uninstall changed a folder at a package path${NC}"; exit 1; }
[ ! -e .claude/rules/test-tools.md ] || { printf '%b\n' "${RED}✘ uninstall stopped before removing the package's own file${NC}"; exit 1; }
grep -q "is a directory" "$SANDBOX_DIR/cli-folder-destination.log" || { printf '%b\n' "${RED}✘ uninstall did not say it kept a folder${NC}"; cat "$SANDBOX_DIR/cli-folder-destination.log"; exit 1; }
cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 60 passed successfully! A destination that is a folder was skipped and every other editor installed.${NC}"

# -----------------------------------------------------------------------------
# TEST 61: qa-instinct --version and -v print the version and exit 0; anything else that is not a
# command is still refused (plan 046 item 3; plan 033 item 4).
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 61: The CLI prints its version..."

VERSION_61="$(node -p "require('$REPO_DIR/package.json').version")"
PROJ_61="$SANDBOX_DIR/cli-version"
mkdir -p "$PROJ_61"
cd "$PROJ_61"
for ARG_61 in --version -v; do
    STATUS_61=0
    OUT_61="$(node "$REPO_DIR/cli/qa-instinct.js" "$ARG_61" 2>&1)" || STATUS_61=$?
    [ "$STATUS_61" -eq 0 ] || { printf '%b\n' "${RED}✘ 'qa-instinct $ARG_61' exited $STATUS_61${NC}"; printf '%s\n' "$OUT_61"; exit 1; }
    [ "$OUT_61" = "qa-instinct $VERSION_61" ] || { printf '%b\n' "${RED}✘ 'qa-instinct $ARG_61' printed '$OUT_61', expected 'qa-instinct $VERSION_61'${NC}"; exit 1; }
done
node "$REPO_DIR/cli/qa-instinct.js" --help | grep -q -- "--version" || { printf '%b\n' "${RED}✘ help does not list --version${NC}"; exit 1; }
for ARGS_61 in "--versio" "-V" "init --version"; do
    STATUS_61=0
    # shellcheck disable=SC2086 # the words are meant to split into separate arguments
    node "$REPO_DIR/cli/qa-instinct.js" $ARGS_61 > /dev/null 2>&1 || STATUS_61=$?
    [ "$STATUS_61" -eq 1 ] || { printf '%b\n' "${RED}✘ 'qa-instinct $ARGS_61' exited $STATUS_61, expected 1${NC}"; exit 1; }
done
[ -z "$(ls -A)" ] || { printf '%b\n' "${RED}✘ the version checks wrote into the project:${NC}"; ls -A; exit 1; }
cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 61 passed successfully! --version and -v print the version; a near miss is refused.${NC}"

# -----------------------------------------------------------------------------
# TEST 62: Where Windows refuses a symlink (no Developer Mode, not elevated), link falls back to a
# directory junction, and stops with one clear line only when a junction cannot be made either
# (plan 046 item 4). Linux has neither the refusal nor junctions, so a preload reports the platform
# as win32, makes fs.symlinkSync throw EPERM for a "dir" link, and for a "junction" either creates
# the link (Linux ignores the type) or throws the error a drive that is not NTFS gives. Test 42b
# runs link with real junctions on a Windows machine without the right to create a symlink.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 62: link falls back to a directory junction where symlinks are refused..."

PKG_62="$SANDBOX_DIR/link-pkg-62"
make_package_39b "$PKG_62"
WIN_62="$SANDBOX_DIR/win32-no-symlink-62.js"
cat > "$WIN_62" <<'JS'
const fs = require("fs");
const realSymlink = fs.symlinkSync;
Object.defineProperty(process, "platform", { value: "win32" });
fs.symlinkSync = (target, dest, type) => {
  if (type === "junction" && process.env.JUNCTION_62 === "ok") return realSymlink(target, dest);
  const code = type === "junction" ? "EISDIR" : "EPERM";
  const err = new Error(`${code}: operation not permitted, symlink '${target}' -> '${dest}'`);
  err.code = code;
  err.syscall = "symlink";
  throw err;
};
JS
BEFORE_62=$(find "$PKG_62/.claude" -type f | wc -l)

# A junction can be made: link succeeds and says so, unlink removes every link.
PROJ_62="$SANDBOX_DIR/link-project-62"
mkdir -p "$PROJ_62"
cd "$PROJ_62"
STATUS_62=0
OUT_62=$(JUNCTION_62=ok node --require "$WIN_62" "$PKG_62/cli/qa-instinct.js" link 2>&1) || STATUS_62=$?
[ "$STATUS_62" -eq 0 ] || { printf '%b\n' "${RED}✘ link exited $STATUS_62 where a junction could be made${NC}"; printf '%s\n' "$OUT_62"; exit 1; }
printf '%s\n' "$OUT_62" | grep -q "directory junctions" || { printf '%b\n' "${RED}✘ link did not say it used directory junctions${NC}"; printf '%s\n' "$OUT_62"; exit 1; }
for SUB in agents commands rules skills hooks; do
    [ "$(readlink ".claude/$SUB")" = "$PKG_62/.claude/$SUB" ] || { printf '%b\n' "${RED}✘ link did not link $SUB with the fallback${NC}"; printf '%s\n' "$OUT_62"; exit 1; }
done
JUNCTION_62=ok node --require "$WIN_62" "$PKG_62/cli/qa-instinct.js" unlink > /dev/null
[ -z "$(ls -A .claude)" ] || { printf '%b\n' "${RED}✘ unlink left links made by the fallback${NC}"; ls -A .claude; exit 1; }
[ "$(find "$PKG_62/.claude" -type f | wc -l)" = "$BEFORE_62" ] || { printf '%b\n' "${RED}✘ link then unlink changed the package${NC}"; exit 1; }

# Neither can be made: one clear line, a non-zero exit, and nothing changed.
PROJ_62B="$SANDBOX_DIR/link-project-62-refused"
mkdir -p "$PROJ_62B"
cd "$PROJ_62B"
STATUS_62=0
OUT_62=$(node --require "$WIN_62" "$PKG_62/cli/qa-instinct.js" link 2>&1) || STATUS_62=$?
[ "$STATUS_62" -ne 0 ] || { printf '%b\n' "${RED}✘ link exited 0 although neither a symlink nor a junction could be made${NC}"; printf '%s\n' "$OUT_62"; exit 1; }
if printf '%s\n' "$OUT_62" | grep -q "symlinkSync\|node:internal"; then
    printf '%b\n' "${RED}✘ link printed a stack trace instead of a message${NC}"; printf '%s\n' "$OUT_62"; exit 1
fi
for WANT_62 in "cannot create symbolic links" "Developer Mode" "junction could not be made" "EISDIR" "qa-instinct init"; do
    printf '%s\n' "$OUT_62" | grep -q "$WANT_62" || { printf '%b\n' "${RED}✘ the refusal does not say '$WANT_62'${NC}"; printf '%s\n' "$OUT_62"; exit 1; }
done
[ -z "$(ls -A)" ] || { printf '%b\n' "${RED}✘ link left something in the project after it could not link${NC}"; ls -A; exit 1; }
cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 62 passed successfully! link fell back to a junction, and refused clearly when neither could be made.${NC}"

# -----------------------------------------------------------------------------
# TEST 63: An install of release 4.0.1 moves to the native layout, one editor at a time, through
# install.sh and the CLI (plan 047 step 6). 4.0.1 wrote one merged adapter per editor at the old
# paths (.cursor/rules/qa.mdc, .windsurfrules, .clinerules, ~/.windsurf/rules/qa.md,
# ~/.gemini/antigravity/skills/qa/SKILL.md, ...). Update must remove each old file it no longer
# ships, saying so, add the editor's rules and skills, and leave nothing behind on uninstall;
# uninstall straight from 4.0.1, with no update, must leave nothing either. Plan 043's
# .bem-te-vi/ never shipped in a release; conformance cases 052 and 056 cover it.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 63: A 4.0.1 install of each editor updates to the native layout and uninstalls to nothing..."

V401_63="$SANDBOX_DIR/release-v4.0.1-63"
cp -R "$REPO_DIR/tests/fixtures/release-v4.0.1" "$V401_63"
(cd "$V401_63" && "$BASH" ./generate-adapters.sh > "$SANDBOX_DIR/v401-generate-63.log" 2>&1) || { printf '%b\n' "${RED}✘ release 4.0.1's generator failed${NC}"; tail -5 "$SANDBOX_DIR/v401-generate-63.log"; exit 1; }

# The 4.0.1 install of one editor, in both scopes where it has them, into a fresh project and home.
install_401_63() {   # editor root
    mkdir -p "$2/project" "$2/home"
    (cd "$2/project" && HOME="$2/home" "$BASH" "$V401_63/install.sh" --target both --editor "$1" --non-interactive --no-hooks --no-color > "$2/install-401.log" 2>&1) \
        || { printf '%b\n' "${RED}✘ release 4.0.1's installer failed for $1${NC}"; tail -5 "$2/install-401.log"; exit 1; }
}
# Runs the current installer: install.sh, or the CLI once per scope.
run_current_63() {   # installer update|uninstall editor root
    local INST="$1" OP="$2" ED="$3" ROOT="$4" STATUS=0
    if [ "$INST" = install.sh ]; then
        (cd "$ROOT/project" && HOME="$ROOT/home" "$REPO_DIR/install.sh" --target both --editor "$ED" --non-interactive --no-hooks --no-color "--$OP" > "$ROOT/$OP.log" 2>&1) || STATUS=$?
    else
        { (cd "$ROOT/project" && HOME="$ROOT/home" node "$REPO_DIR/cli/qa-instinct.js" "$OP" --editor "$ED") \
            && (cd "$ROOT/project" && HOME="$ROOT/home" node "$REPO_DIR/cli/qa-instinct.js" "$OP" --global --editor "$ED"); } > "$ROOT/$OP.log" 2>&1 || STATUS=$?
    fi
    [ "$STATUS" -eq 0 ] || { printf '%b\n' "${RED}✘ $INST $OP over 4.0.1's $ED install exited $STATUS${NC}"; tail -8 "$ROOT/$OP.log"; exit 1; }
}
left_63() {   # root: what is left in the project and the home, or nothing
    find "$1/project" "$1/home" -mindepth 1 | sed "s#^$1/##"
}

for INST_63 in install.sh cli; do
    for ED_63 in cursor windsurf copilot cline antigravity; do
        ROOT_63="$SANDBOX_DIR/migrate-63/$INST_63-$ED_63"
        install_401_63 "$ED_63" "$ROOT_63"
        OLD_63="$(awk '{ print "project/" $3 }' "$ROOT_63/project/.qa-skills-manifest" 2>/dev/null || true; awk '{ print "home/" $3 }' "$ROOT_63/home/.qa-skills-manifest" 2>/dev/null || true)"
        [ -n "$OLD_63" ] || { printf '%b\n' "${RED}✘ release 4.0.1 recorded nothing for $ED_63${NC}"; exit 1; }

        run_current_63 "$INST_63" update "$ED_63" "$ROOT_63"
        grep -q "Added" "$ROOT_63/update.log" || { printf '%b\n' "${RED}✘ $INST_63 update of 4.0.1's $ED_63 install added nothing${NC}"; tail -8 "$ROOT_63/update.log"; exit 1; }
        # Copilot is the one editor whose 4.0.1 file is still shipped where it was.
        if [ "$ED_63" != copilot ]; then
            grep -q "no longer shipped" "$ROOT_63/update.log" || { printf '%b\n' "${RED}✘ $INST_63 update of 4.0.1's $ED_63 install removed no old file${NC}"; tail -8 "$ROOT_63/update.log"; exit 1; }
        fi
        if grep -q "Kept\|backed up" "$ROOT_63/update.log"; then printf '%b\n' "${RED}✘ $INST_63 update of 4.0.1's $ED_63 install kept or backed up a file:${NC}"; grep "Kept\|backed up" "$ROOT_63/update.log"; exit 1; fi
        while IFS= read -r OLD_FILE_63; do
            case "$OLD_FILE_63" in project/.github/copilot-instructions.md|project/.agents/skills/qa/SKILL.md) continue ;; esac
            [ ! -e "$ROOT_63/$OLD_FILE_63" ] || { printf '%b\n' "${RED}✘ $INST_63 update left 4.0.1's $OLD_FILE_63${NC}"; exit 1; }
            if grep -q "  ${OLD_FILE_63#*/}$" "$ROOT_63/${OLD_FILE_63%%/*}/.qa-instinct-manifest" 2>/dev/null; then
                printf '%b\n' "${RED}✘ $INST_63 update still records 4.0.1's $OLD_FILE_63${NC}"; exit 1
            fi
        done <<< "$OLD_63"
        for SCOPE_63 in project home; do
            [ ! -e "$ROOT_63/$SCOPE_63/.qa-skills-manifest" ] || { printf '%b\n' "${RED}✘ $INST_63 update left 4.0.1's $SCOPE_63 manifest under its old name${NC}"; exit 1; }
        done
        SKILLS_63="$(awk -F'\t' -v ed="$ED_63" '$1 == ed { print $4 }' "$REPO_DIR/.qa-instinct-editor-map")"
        diff -r "$REPO_DIR/adapters/skills" "$ROOT_63/project/$SKILLS_63" > /dev/null || { printf '%b\n' "${RED}✘ $INST_63 update did not install $ED_63's skills in $SKILLS_63${NC}"; exit 1; }
        [ -z "$(find "$ROOT_63" -name '*.qa-instinct-backup-*')" ] || { printf '%b\n' "${RED}✘ $INST_63 update made a backup${NC}"; find "$ROOT_63" -name '*.qa-instinct-backup-*'; exit 1; }

        run_current_63 "$INST_63" uninstall "$ED_63" "$ROOT_63"
        [ -z "$(left_63 "$ROOT_63")" ] || { printf '%b\n' "${RED}✘ $INST_63 uninstall after the update of $ED_63 left:${NC}"; left_63 "$ROOT_63" | head -10; exit 1; }

        # Uninstall straight from 4.0.1: the manifest leads to the old paths.
        rm -rf "$ROOT_63"
        install_401_63 "$ED_63" "$ROOT_63"
        run_current_63 "$INST_63" uninstall "$ED_63" "$ROOT_63"
        [ -z "$(left_63 "$ROOT_63")" ] || { printf '%b\n' "${RED}✘ $INST_63 uninstall of 4.0.1's $ED_63 install left:${NC}"; left_63 "$ROOT_63" | head -10; exit 1; }
    done
done

printf '%b\n' "${GREEN}✔ Test 63 passed successfully! Each editor's 4.0.1 install moved to the native layout and uninstalled to nothing, through install.sh and the CLI.${NC}"

# -----------------------------------------------------------------------------
# TEST 64: The CLI help names, for each command, exactly the options that command accepts. The
# help once said --editor defaults to claude "for init/uninstall/link/unlink" while link and unlink
# refuse --editor. Everything is read from the help text and checked by running the command, so the
# help and the CLI's option table cannot drift apart again.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 64: The CLI help lists, for each command, only the options it accepts..."

ROOT_64="$SANDBOX_DIR/cli-help-64"
HELP_64="$(NO_COLOR=1 node "$REPO_DIR/cli/qa-instinct.js" help)"

# Succeeds unless the command refuses the option as unknown. Each run gets its own project and
# home, so an accepted option that installs or links something touches nothing else.
accepts_64() {
    local dir="$ROOT_64/$1$2" out
    rm -rf "$dir"
    mkdir -p "$dir/project" "$dir/home"
    if [ "$2" = "--editor" ]; then
        out="$(cd "$dir/project" && HOME="$dir/home" node "$REPO_DIR/cli/qa-instinct.js" "$1" "$2" claude 2>&1 < /dev/null)" || true
    else
        out="$(cd "$dir/project" && HOME="$dir/home" node "$REPO_DIR/cli/qa-instinct.js" "$1" "$2" 2>&1 < /dev/null)" || true
    fi
    case "$out" in *"unknown option '$2'"*) return 1 ;; esac
    return 0
}

COMMANDS_64="$(printf '%s\n' "$HELP_64" | awk '/^Commands:/ { on = 1; next } /^Flags:/ { on = 0 } on && /^  [a-z]/ { print $1 }')"
[ -n "$COMMANDS_64" ] || { printf '%b\n' "${RED}✘ the help lists no commands${NC}"; exit 1; }
# The --editor entry under Flags: its first line and the deeper-indented lines that continue it.
EDITOR_HELP_64="$(printf '%s\n' "$HELP_64" | awk '/^  --editor / { on = 1; print; next } on && !/^    / { on = 0 } on { print }')"
[ -n "$EDITOR_HELP_64" ] || { printf '%b\n' "${RED}✘ the help has no --editor entry${NC}"; exit 1; }

for CMD_64 in $COMMANDS_64; do
    if ! accepts_64 "$CMD_64" --editor && printf '%s\n' "$EDITOR_HELP_64" | grep -qw -- "$CMD_64"; then
        printf '%b\n' "${RED}✘ the help for --editor names '$CMD_64', which refuses --editor:${NC}"
        printf '%s\n' "$EDITOR_HELP_64"
        exit 1
    fi
done

# Each command's usage line, and every option any usage line names.
USAGE_64="$(printf '%s\n' "$HELP_64" | awk '/^Usage:/ { on = 1; next } /^Commands:/ { on = 0 } on')"
ALL_OPTS_64="$(printf '%s\n' "$USAGE_64" | grep -o -- '\[--[a-z][a-z-]*' | tr -d '[' | sort -u)"
for CMD_64 in $COMMANDS_64; do
    LINE_64="$(printf '%s\n' "$USAGE_64" | grep -E "^  qa-instinct $CMD_64( |$)" || true)"
    [ -n "$LINE_64" ] || { printf '%b\n' "${RED}✘ the help has no usage line for '$CMD_64':${NC}"; printf '%s\n' "$USAGE_64"; exit 1; }
    for OPT_64 in $ALL_OPTS_64; do
        if printf '%s\n' "$LINE_64" | grep -q -- "\[${OPT_64}[] ]"; then
            accepts_64 "$CMD_64" "$OPT_64" || { printf '%b\n' "${RED}✘ the help lists $OPT_64 for '$CMD_64', which refuses it${NC}"; exit 1; }
        else
            ! accepts_64 "$CMD_64" "$OPT_64" || { printf '%b\n' "${RED}✘ '$CMD_64' accepts $OPT_64, which its usage line does not list${NC}"; exit 1; }
        fi
    done
    # Every example of the command uses only options its usage line lists.
    for OPT_64 in $(printf '%s\n' "$HELP_64" | awk '/^Examples:/ { on = 1; next } on' | grep -E "^  qa-instinct $CMD_64( |$)" | sed 's/#.*//' | grep -o -- '--[a-z][a-z-]*' | sort -u); do
        printf '%s\n' "$LINE_64" | grep -q -- "\[${OPT_64}[] ]" || { printf '%b\n' "${RED}✘ an example uses '$CMD_64 $OPT_64', which its usage line does not list${NC}"; exit 1; }
    done
done
rm -rf "$ROOT_64"

printf '%b\n' "${GREEN}✔ Test 64 passed successfully! The help lists, for each command, exactly the options it accepts.${NC}"

# -----------------------------------------------------------------------------
# TEST 65: On WSL, a Windows home that cannot be resolved is reported, and the run finishes (plan
# 053 I13). The Windows-side step is offered only on WSL. cmd.exe and wslpath are stand-ins, so
# nothing outside the sandbox is reached: an install where cmd.exe fails, and an uninstall where
# cmd.exe answers and wslpath fails.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 65: On WSL, a Windows home that cannot be resolved is reported..."

if ! grep -qi microsoft /proc/version 2>/dev/null; then
    printf '%b\n' "${GREEN}- Test 65 skipped: install.sh offers the Windows side only on WSL.${NC}"
else
    for CASE_65 in install:cmd.exe uninstall:wslpath; do
        OP_65="${CASE_65%%:*}"
        BIN_65="$SANDBOX_DIR/wsl-home-65-$OP_65-bin"
        PROJ_65="$SANDBOX_DIR/wsl-home-65-$OP_65"
        LOG_65="$SANDBOX_DIR/wsl-home-65-$OP_65.log"
        mkdir -p "$BIN_65" "$PROJ_65"
        if [ "${CASE_65#*:}" = cmd.exe ]; then
            printf '#!/bin/sh\nexit 1\n' > "$BIN_65/cmd.exe"
        else
            cat > "$BIN_65/cmd.exe" <<'STUB_65'
#!/bin/sh
printf 'C:\\Users\\qa\r\n'
STUB_65
        fi
        printf '#!/bin/sh\nexit 1\n' > "$BIN_65/wslpath"
        chmod +x "$BIN_65/cmd.exe" "$BIN_65/wslpath"
        cd "$PROJ_65"
        STATUS_65=0
        if [ "$OP_65" = install ]; then
            # (1) Install, then "y" to "Also install to Windows-side user profile?".
            printf '1\ny\n' | PATH="$BIN_65:$PATH" "$REPO_DIR/install.sh" --target project --editor cursor --no-hooks --no-color > "$LOG_65" 2>&1 || STATUS_65=$?
        else
            "$REPO_DIR/install.sh" --target project --editor cursor --non-interactive --no-hooks --no-color > /dev/null 2>&1
            printf 'y\n' | PATH="$BIN_65:$PATH" "$REPO_DIR/install.sh" --target project --editor cursor --uninstall --no-hooks --no-color > "$LOG_65" 2>&1 || STATUS_65=$?
        fi
        cd "$REPO_DIR"
        grep -q "could not resolve Windows home directory" "$LOG_65" || { printf '%b\n' "${RED}✘ $OP_65 with a failing ${CASE_65#*:} did not report the Windows home it could not resolve (exit $STATUS_65)${NC}"; tail -4 "$LOG_65"; exit 1; }
        [ "$STATUS_65" -eq 0 ] || { printf '%b\n' "${RED}✘ $OP_65 with a failing ${CASE_65#*:} exited $STATUS_65${NC}"; tail -4 "$LOG_65"; exit 1; }
        if [ "$OP_65" = install ]; then
            [ -f "$PROJ_65/.cursor/skills/qa/SKILL.md" ] || { printf '%b\n' "${RED}✘ the project install did not finish${NC}"; exit 1; }
        else
            [ ! -e "$PROJ_65/.cursor/skills/qa/SKILL.md" ] || { printf '%b\n' "${RED}✘ the project uninstall did not finish${NC}"; exit 1; }
        fi
    done
    printf '%b\n' "${GREEN}✔ Test 65 passed successfully! A Windows home that could not be resolved was reported, and both runs finished.${NC}"
fi

# -----------------------------------------------------------------------------
# TEST 66: A link planted at the exact name of the CLI's manifest temp file is never written
# through, and the install still finishes and records what it wrote (plan 053 I10). The CLI names
# that file <manifest>.tmp-<pid>-<12 hex digits from crypto.randomBytes(6)>. A preload makes the
# first such call return known bytes, plants a link to the victim at the resulting name, and
# records whether the CLI opened that name; if it never did, the plant missed and the test fails.
# Test 46b does the same for install.sh; tests/test-lifecycle.ps1 Test 52 for install.ps1.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 66: The CLI never writes its manifest through a link planted at its temp name..."

PRELOAD_66="$SANDBOX_DIR/manifest-plant-66.js"
VICTIM_66="$SANDBOX_DIR/manifest-plant-66-victim.txt"
TRIED_66="$SANDBOX_DIR/manifest-plant-66-tried.txt"
PROJ_66="$SANDBOX_DIR/manifest-plant-66"
cat > "$PRELOAD_66" <<'JS'
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const realRandomBytes = crypto.randomBytes;
let pinned = false;
crypto.randomBytes = function (size, callback) {
  if (!pinned && size === 6 && typeof callback !== "function") {
    pinned = true;
    return Buffer.alloc(6, 0x66);
  }
  return realRandomBytes.apply(this, arguments);
};
const planted = path.join(process.cwd(), `.qa-instinct-manifest.tmp-${process.pid}-${"66".repeat(6)}`);
fs.symlinkSync(process.env.VICTIM_66, planted);
const realOpenSync = fs.openSync;
fs.openSync = function (file, ...rest) {
  if (path.resolve(String(file)) === planted) fs.appendFileSync(process.env.TRIED_66, `${planted}\n`);
  return realOpenSync.call(this, file, ...rest);
};
JS
printf 'VICTIM CONTENT\n' > "$VICTIM_66"
chmod 600 "$VICTIM_66"
mkdir -p "$PROJ_66"
cd "$PROJ_66"
STATUS_66=0
VICTIM_66="$VICTIM_66" TRIED_66="$TRIED_66" node --require "$PRELOAD_66" "$REPO_DIR/cli/qa-instinct.js" init --editor cursor > "$PROJ_66.log" 2>&1 || STATUS_66=$?
cd "$REPO_DIR"
[ -s "$TRIED_66" ] || { printf '%b\n' "${RED}✘ the CLI never opened the name Test 66 planted its link at; the plant missed${NC}"; tail -5 "$PROJ_66.log"; exit 1; }
[ "$(cat "$VICTIM_66")" = "VICTIM CONTENT" ] || { printf '%b\n' "${RED}✘ the CLI wrote its manifest through a link planted at its temp file's name${NC}"; head -3 "$VICTIM_66"; exit 1; }
[ -n "$(find "$VICTIM_66" -perm 600)" ] || { printf '%b\n' "${RED}✘ the CLI changed the mode of a file through a link planted at its temp file's name${NC}"; exit 1; }
[ "$(readlink "$(head -1 "$TRIED_66")")" = "$VICTIM_66" ] || { printf '%b\n' "${RED}✘ the CLI removed or replaced the link planted at its temp file's name${NC}"; exit 1; }
[ "$STATUS_66" -eq 0 ] || { printf '%b\n' "${RED}✘ the CLI exited $STATUS_66 over a link at its manifest temp name, where install.sh picks another name${NC}"; grep -m3 "Error\|EEXIST" "$PROJ_66.log"; exit 1; }
grep -q '  cursor  .cursor/skills/qa/SKILL.md$' "$PROJ_66/.qa-instinct-manifest" 2>/dev/null || { printf '%b\n' "${RED}✘ the CLI did not record what it installed${NC}"; exit 1; }
printf '%b\n' "${GREEN}✔ Test 66 passed successfully! The CLI passed over the link planted at its manifest temp name and finished the install.${NC}"

# -----------------------------------------------------------------------------
# TEST 67: The npm CLI's update over a real earlier release's Claude Code install (plan 014 A4).
# Release 4.0.1, as tests/fixtures/release-v4.0.1 holds it, installs Claude Code in both scopes
# with its own install.sh; the current CLI then runs update in each scope. The result must equal a
# fresh install by the current CLI, file for file and manifest line for manifest line, with no
# backup and nothing kept; the CLI's uninstall must then leave nothing. The manifests are compared
# sorted: update appends the files it adds after the ones it refreshed, init writes them in order.
# Test 54 runs this path with install.sh for every editor and Test 63 with the CLI for the five
# other editors; Test 33 covers the CLI backing up a user's edit to an older release's file.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 67: A 4.0.1 install of Claude Code updates through the CLI to a fresh CLI install and uninstalls to nothing..."

V401_67="$SANDBOX_DIR/release-v4.0.1-67"
UP_67="$SANDBOX_DIR/upgrade-67"
FRESH_67="$SANDBOX_DIR/fresh-67"
cp -R "$REPO_DIR/tests/fixtures/release-v4.0.1" "$V401_67"
mkdir -p "$UP_67/project" "$UP_67/home" "$FRESH_67/project" "$FRESH_67/home"
(cd "$V401_67" && "$BASH" ./generate-adapters.sh > "$SANDBOX_DIR/v401-generate-67.log" 2>&1) || { printf '%b\n' "${RED}✘ release 4.0.1's generator failed${NC}"; tail -5 "$SANDBOX_DIR/v401-generate-67.log"; exit 1; }
(cd "$UP_67/project" && HOME="$UP_67/home" "$BASH" "$V401_67/install.sh" --target both --editor claude --non-interactive --no-hooks --no-color > "$SANDBOX_DIR/v401-install-67.log" 2>&1) || { printf '%b\n' "${RED}✘ release 4.0.1's installer failed${NC}"; tail -5 "$SANDBOX_DIR/v401-install-67.log"; exit 1; }

# Runs the current CLI for Claude Code in one scope: the project, or the home with --global.
cli_67() {   # command root project|home
    if [ "$3" = home ]; then
        (cd "$2/project" && HOME="$2/home" node "$REPO_DIR/cli/qa-instinct.js" "$1" --global --editor claude)
    else
        (cd "$2/project" && HOME="$2/home" node "$REPO_DIR/cli/qa-instinct.js" "$1" --editor claude)
    fi
}

for SCOPE_67 in project home; do
    [ -f "$UP_67/$SCOPE_67/.qa-skills-manifest" ] || { printf '%b\n' "${RED}✘ release 4.0.1 wrote no $SCOPE_67 manifest${NC}"; exit 1; }
    cli_67 init "$FRESH_67" "$SCOPE_67" > "$SANDBOX_DIR/fresh-67-$SCOPE_67.log" 2>&1 || { printf '%b\n' "${RED}✘ the CLI's fresh $SCOPE_67 install failed${NC}"; tail -5 "$SANDBOX_DIR/fresh-67-$SCOPE_67.log"; exit 1; }
    # A 4.0.1 install that already equals a fresh one would make the comparison below prove nothing.
    if diff <(LC_ALL=C sort "$UP_67/$SCOPE_67/.qa-skills-manifest") <(LC_ALL=C sort "$FRESH_67/$SCOPE_67/.qa-instinct-manifest") > /dev/null; then
        printf '%b\n' "${RED}✘ release 4.0.1's $SCOPE_67 install already equals a fresh CLI install; Test 67 would prove nothing${NC}"; exit 1
    fi
    cli_67 update "$UP_67" "$SCOPE_67" > "$SANDBOX_DIR/v401-update-67-$SCOPE_67.log" 2>&1 || { printf '%b\n' "${RED}✘ the CLI's $SCOPE_67 update over release 4.0.1 failed${NC}"; tail -5 "$SANDBOX_DIR/v401-update-67-$SCOPE_67.log"; exit 1; }
    if grep -q "Kept\|backed up" "$SANDBOX_DIR/v401-update-67-$SCOPE_67.log"; then
        printf '%b\n' "${RED}✘ the CLI's $SCOPE_67 update over release 4.0.1 kept or backed up files it should have replaced:${NC}"; grep "Kept\|backed up" "$SANDBOX_DIR/v401-update-67-$SCOPE_67.log" | head -10; exit 1
    fi
done

BACKUPS_67="$(find "$UP_67" -name '*.qa-instinct-backup-*')"
[ -z "$BACKUPS_67" ] || { printf '%b\n' "${RED}✘ the CLI's update over release 4.0.1 made backups:${NC}"; printf '%s\n' "$BACKUPS_67" | head -10; exit 1; }
for SCOPE_67 in project home; do
    if ! diff <(LC_ALL=C sort "$UP_67/$SCOPE_67/.qa-instinct-manifest") <(LC_ALL=C sort "$FRESH_67/$SCOPE_67/.qa-instinct-manifest") > "$SANDBOX_DIR/v401-manifest-67.diff"; then
        printf '%b\n' "${RED}✘ the $SCOPE_67 manifest after the CLI's update differs from a fresh CLI install's (< updated, > fresh):${NC}"; head -20 "$SANDBOX_DIR/v401-manifest-67.diff"; exit 1
    fi
    if ! diff -r -x .qa-instinct-manifest "$UP_67/$SCOPE_67" "$FRESH_67/$SCOPE_67" > "$SANDBOX_DIR/v401-tree-67.diff" 2>&1; then
        printf '%b\n' "${RED}✘ the $SCOPE_67 tree after the CLI's update differs from a fresh CLI install's:${NC}"; head -20 "$SANDBOX_DIR/v401-tree-67.diff"; exit 1
    fi
done

for SCOPE_67 in project home; do
    cli_67 uninstall "$UP_67" "$SCOPE_67" > "$SANDBOX_DIR/v401-uninstall-67-$SCOPE_67.log" 2>&1 || { printf '%b\n' "${RED}✘ the CLI's $SCOPE_67 uninstall after the update failed${NC}"; tail -5 "$SANDBOX_DIR/v401-uninstall-67-$SCOPE_67.log"; exit 1; }
done
LEFT_67="$(find "$UP_67/project" "$UP_67/home" -mindepth 1)"
[ -z "$LEFT_67" ] || { printf '%b\n' "${RED}✘ the CLI's uninstall after the update left:${NC}"; printf '%s\n' "$LEFT_67" | head -20; exit 1; }

printf '%b\n' "${GREEN}✔ Test 67 passed successfully! The CLI updated release 4.0.1's Claude Code install to a fresh CLI install's exact tree with no backup, and uninstalled it to nothing.${NC}"

# -----------------------------------------------------------------------------
# TEST 68: On WSL, an install into the Windows user profile that sets up the pre-commit hook says,
# once, that the hook is not active for Windows-side git and that install.ps1 sets it up there
# (plan 014 A3, decided by Marco on 2026-10-20). No note when that install sets up no hook
# (--no-hooks) or when there is no Windows-side install. cmd.exe and wslpath are stand-ins, as in
# Test 65, and the Windows profile is a sandbox folder; the Windows-side step is offered only on WSL.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 68: On WSL, a Windows-side install with the hook says the hook is not active there..."

if ! grep -qi microsoft /proc/version 2>/dev/null; then
    printf '%b\n' "${GREEN}- Test 68 skipped: install.sh offers the Windows side only on WSL.${NC}"
else
    BIN_68="$SANDBOX_DIR/wsl-hook-68-bin"
    WIN_68="$SANDBOX_DIR/wsl-hook-68-win"
    mkdir -p "$BIN_68"
    cat > "$BIN_68/cmd.exe" <<'STUB_68'
#!/bin/sh
printf 'C:\\Users\\qa\r\n'
STUB_68
    printf '#!/bin/sh\nprintf "%%s\\n" "%s"\n' "$WIN_68" > "$BIN_68/wslpath"
    chmod +x "$BIN_68/cmd.exe" "$BIN_68/wslpath"
    NOTE_68="The pre-commit hook is not active for Windows-side git"
    # Each case: the answer to the Windows-side question, an extra flag, how often the note shows.
    for CASE_68 in "y::1" "y:--no-hooks:0" "n::0"; do
        ANSWER_68="${CASE_68%%:*}"; REST_68="${CASE_68#*:}"; FLAG_68="${REST_68%%:*}"; WANT_68="${REST_68#*:}"
        PROJ_68="$SANDBOX_DIR/wsl-hook-68-proj-$ANSWER_68$FLAG_68"
        HOME_68="$SANDBOX_DIR/wsl-hook-68-home-$ANSWER_68$FLAG_68"
        LOG_68="$PROJ_68.log"
        rm -rf "$WIN_68" && mkdir -p "$WIN_68" "$PROJ_68" "$HOME_68"
        # (1) Install, then the answer to "Also install to Windows-side user profile?".
        (cd "$PROJ_68" && printf '1\n%s\n' "$ANSWER_68" | HOME="$HOME_68" GIT_CONFIG_GLOBAL="$HOME_68/.gitconfig" PATH="$BIN_68:$PATH" "$REPO_DIR/install.sh" --target project --editor claude ${FLAG_68:+"$FLAG_68"} --no-color > "$LOG_68" 2>&1) || { printf '%b\n' "${RED}✘ the install answering '$ANSWER_68' $FLAG_68 failed${NC}"; tail -5 "$LOG_68"; exit 1; }
        if [ "$ANSWER_68" = y ]; then
            [ -f "$WIN_68/.claude/hooks/validate-tc-format.sh" ] || { printf '%b\n' "${RED}✘ the Windows-side install did not reach the stand-in profile${NC}"; tail -5 "$LOG_68"; exit 1; }
        fi
        GOT_68="$(grep -c "$NOTE_68" "$LOG_68" || true)"
        [ "$GOT_68" = "$WANT_68" ] || { printf '%b\n' "${RED}✘ answering '$ANSWER_68' $FLAG_68 printed the Windows-side hook note $GOT_68 time(s), expected $WANT_68${NC}"; tail -8 "$LOG_68"; exit 1; }
        if [ "$WANT_68" = 1 ]; then
            grep -q "run install.ps1 from Windows PowerShell" "$LOG_68" || { printf '%b\n' "${RED}✘ the Windows-side hook note does not point at install.ps1${NC}"; tail -8 "$LOG_68"; exit 1; }
        fi
    done
    printf '%b\n' "${GREEN}✔ Test 68 passed successfully! A Windows-side install with the hook said once that install.ps1 sets it up there; no note without the hook or the Windows side.${NC}"
fi

# -----------------------------------------------------------------------------
# TEST 69: The CLI's header and "Done!" line name no Claude Code folder or command for another
# editor, and stay as they were for Claude Code alone (plan 062)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 69: cli/qa-instinct.js init prints each editor's own wording..."

mkdir -p "$SANDBOX_DIR/cli-wording/project" "$SANDBOX_DIR/cli-wording/home" "$SANDBOX_DIR/cli-wording/claude"
LOG_69="$SANDBOX_DIR/cli-wording/out.log"
cd "$SANDBOX_DIR/cli-wording/project"
for FLAG_69 in "" "--global"; do
    # Outside WSL: under WSL the extra line names this folder, whose path may hold ".claude/"
    # (a worktree), and Test 70 covers that line.
    # shellcheck disable=SC2086  # FLAG_69 is empty or one word
    env -u WSL_DISTRO_NAME HOME="$SANDBOX_DIR/cli-wording/home" node "$REPO_DIR/cli/qa-instinct.js" init --editor antigravity $FLAG_69 > "$LOG_69" 2>&1
    if grep -q '\.claude/' "$LOG_69"; then
        printf '%b\n' "${RED}✘ init --editor antigravity $FLAG_69 names a .claude/ folder it did not write${NC}"; cat "$LOG_69"; exit 1
    fi
    if grep -q 'type /qa' "$LOG_69"; then
        printf '%b\n' "${RED}✘ init --editor antigravity $FLAG_69 tells the user to type /qa${NC}"; cat "$LOG_69"; exit 1
    fi
    grep -q 'Next steps:' "$LOG_69" || { printf '%b\n' "${RED}✘ init --editor antigravity $FLAG_69 printed no \"Next steps:\" line${NC}"; cat "$LOG_69"; exit 1; }
    grep -q 'ask for qa-cases' "$LOG_69" || { printf '%b\n' "${RED}✘ init --editor antigravity $FLAG_69 lost its Antigravity line${NC}"; cat "$LOG_69"; exit 1; }
done
cd "$SANDBOX_DIR/cli-wording/claude"
node "$REPO_DIR/cli/qa-instinct.js" init > "$LOG_69" 2>&1
grep -q 'installing to project (\./\.claude/)' "$LOG_69" || { printf '%b\n' "${RED}✘ init with no editor no longer names ./.claude/${NC}"; cat "$LOG_69"; exit 1; }
grep -q 'Claude Code : type /qa to start' "$LOG_69" || { printf '%b\n' "${RED}✘ init with no editor no longer says to type /qa${NC}"; cat "$LOG_69"; exit 1; }
cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 69 passed successfully! An Antigravity install names no Claude Code folder or command; Claude Code's wording is unchanged.${NC}"

# -----------------------------------------------------------------------------
# TEST 70: Under WSL, an Antigravity install says how to open the folder in a WSL window, in the
# same words from install.sh and the CLI; outside WSL it says nothing (plan 062)
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 70: an Antigravity install under WSL names the command that opens a WSL window..."

LOG_70="$SANDBOX_DIR/wsl-tip.log"
HOME_70="$SANDBOX_DIR/wsl-tip-home"
TIP_70="in WSL, open the folder in a WSL window: antigravity-ide --remote wsl+TestDistro"
for INSTALLER_70 in install.sh cli; do
    for SCOPE_70 in project global; do
        DIR_70="$SANDBOX_DIR/wsl-tip-$INSTALLER_70-$SCOPE_70"
        mkdir -p "$DIR_70" "$HOME_70"
        cd "$DIR_70"
        if [ "$INSTALLER_70" = cli ]; then
            if [ "$SCOPE_70" = global ]; then FLAGS_70="--global"; else FLAGS_70=""; fi
            # shellcheck disable=SC2086  # FLAGS_70 is empty or one word
            HOME="$HOME_70" WSL_DISTRO_NAME=TestDistro node "$REPO_DIR/cli/qa-instinct.js" init --editor antigravity $FLAGS_70 > "$LOG_70" 2>&1
        else
            HOME="$HOME_70" WSL_DISTRO_NAME=TestDistro "$REPO_DIR/install.sh" --target "$SCOPE_70" --editor antigravity --non-interactive --no-hooks > "$LOG_70" 2>&1
        fi
        if [ "$SCOPE_70" = project ]; then WANT_70="$TIP_70 $(pwd -P)"; else WANT_70="$TIP_70 <folder>"; fi
        grep -qF "$WANT_70" "$LOG_70" || { printf '%b\n' "${RED}✘ $INSTALLER_70 $SCOPE_70 under WSL did not print: $WANT_70${NC}"; cat "$LOG_70"; exit 1; }
    done
done
cd "$SANDBOX_DIR/wsl-tip-cli-project"
env -u WSL_DISTRO_NAME HOME="$HOME_70" node "$REPO_DIR/cli/qa-instinct.js" init --editor antigravity > "$LOG_70" 2>&1
if grep -q 'in WSL, open the folder' "$LOG_70"; then
    printf '%b\n' "${RED}✘ the CLI printed the WSL tip outside WSL${NC}"; cat "$LOG_70"; exit 1
fi
cd "$SANDBOX_DIR/wsl-tip-install.sh-project"
env -u WSL_DISTRO_NAME HOME="$HOME_70" "$REPO_DIR/install.sh" --target project --editor antigravity --non-interactive --no-hooks > "$LOG_70" 2>&1
if grep -q 'in WSL, open the folder' "$LOG_70"; then
    printf '%b\n' "${RED}✘ install.sh printed the WSL tip outside WSL${NC}"; cat "$LOG_70"; exit 1
fi
cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 70 passed successfully! Under WSL, install.sh and the CLI name the command that opens a WSL window; outside WSL they do not.${NC}"

# -----------------------------------------------------------------------------
# TEST 71: An update that reads only the start of an editor's file list removes nothing and fails
# (plan 063, issue #3). On macOS, bash 3.2 once handed the update 13 of Windsurf's 61 lines and it
# removed the other 48 skill files as no longer shipped. That cut cannot be caused on demand, so
# QA_INSTINCT_TEST_CUT_LIST makes install.sh read only that many lines of the list.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 71: an update given a cut file list removes nothing..."

DIR_71="$SANDBOX_DIR/cut-list"
LOG_71="$SANDBOX_DIR/cut-list.log"
mkdir -p "$DIR_71"
cd "$DIR_71"
"$REPO_DIR/install.sh" --target project --editor windsurf --non-interactive --no-hooks > "$LOG_71" 2>&1
RECORDED_71="$(grep -c '  windsurf  ' .qa-instinct-manifest)"
EXIT_71=0
QA_INSTINCT_TEST_CUT_LIST=13 "$REPO_DIR/install.sh" --target project --editor windsurf --update --non-interactive --no-hooks > "$LOG_71" 2>&1 || EXIT_71=$?
while IFS= read -r FILE_71; do
    REL_71="${FILE_71#"$REPO_DIR/adapters/skills/"}"
    cmp -s "$FILE_71" ".windsurf/skills/$REL_71" || { printf '%b\n' "${RED}✘ .windsurf/skills/$REL_71 is missing or changed after an update given a cut list${NC}"; cat "$LOG_71"; exit 1; }
done < <(find "$REPO_DIR/adapters/skills" -type f)
if grep -q 'no longer shipped' "$LOG_71"; then
    printf '%b\n' "${RED}✘ the update removed files as no longer shipped from a cut list${NC}"; cat "$LOG_71"; exit 1
fi
[ "$(grep -c '  windsurf  ' .qa-instinct-manifest)" = "$RECORDED_71" ] || { printf '%b\n' "${RED}✘ the update dropped manifest entries after a cut list${NC}"; cat "$LOG_71"; exit 1; }
[ "$EXIT_71" -ne 0 ] || { printf '%b\n' "${RED}✘ the update exited 0 after a cut list${NC}"; cat "$LOG_71"; exit 1; }
grep -q 'Could not read the whole list' "$LOG_71" || { printf '%b\n' "${RED}✘ the update did not say it could not read the whole list${NC}"; cat "$LOG_71"; exit 1; }
cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 71 passed successfully! An update that reads only part of an editor's file list removes nothing, keeps the manifest and fails.${NC}"

# -----------------------------------------------------------------------------
# TEST 72: install.sh recognises, replaces and removes every git hook any release wrote
# (plan 064 item 1). tests/fixtures/git-hooks/ holds the bytes each release's installers wrote
# (extract.sh there lists the tags). A project hook is ours by the marker alone, so install
# replaces it and uninstall removes it, with or without a final line break; a global hook that
# already names validate-tc-format.sh is left byte for byte by install, a fresh one is removed by
# uninstall, and an appended block is cut out leaving exactly the user's lines.
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 72: install.sh handles every git hook a release wrote..."

HOOKS_72="$REPO_DIR/tests/fixtures/git-hooks"
WORK_72="$SANDBOX_DIR/hook-fixtures"
rm -rf "$WORK_72"
mkdir -p "$WORK_72"

fail_72() {   # message
    printf '%b\n' "${RED}✘ Test 72: $1${NC}"
    exit 1
}

# 72a: project hooks. A fresh repository without the global template hook an earlier test may have
# configured, so the only pre-commit hook present is the one seeded.
for FIXTURE_72 in "$HOOKS_72"/project/*; do
    NAME_72="project/$(basename "$FIXTURE_72")"
    REPO_72="$WORK_72/repo"
    rm -rf "$REPO_72"
    mkdir -p "$REPO_72"
    git -C "$REPO_72" -c init.templateDir= init -q -b main
    mkdir -p "$REPO_72/.git/hooks"
    cp "$FIXTURE_72" "$REPO_72/.git/hooks/pre-commit"
    chmod +x "$REPO_72/.git/hooks/pre-commit"
    cd "$REPO_72"
    "$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-color > "$WORK_72/install.log" 2>&1 || { cat "$WORK_72/install.log"; fail_72 "install over $NAME_72 failed"; }
    cmp -s ".git/hooks/pre-commit" "$HOOKS_72/project/current.lf.nl" || { cat "$WORK_72/install.log"; fail_72 "install did not replace $NAME_72 with the current hook"; }
    cp "$FIXTURE_72" ".git/hooks/pre-commit"
    "$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-color --uninstall > "$WORK_72/uninstall.log" 2>&1 || { cat "$WORK_72/uninstall.log"; fail_72 "uninstall over $NAME_72 failed"; }
    [ ! -e ".git/hooks/pre-commit" ] || fail_72 "uninstall left $NAME_72 behind"
done

# 72b: global hooks written fresh by a release: install leaves them byte for byte, uninstall
# removes the file. Each in its own throwaway HOME.
for FIXTURE_72 in "$HOOKS_72"/global-fresh/*; do
    NAME_72="global-fresh/$(basename "$FIXTURE_72")"
    HOME_72="$WORK_72/home"
    rm -rf "$HOME_72"
    mkdir -p "$HOME_72/.git-templates/hooks"
    cp "$FIXTURE_72" "$HOME_72/.git-templates/hooks/pre-commit"
    cd "$WORK_72"
    HOME="$HOME_72" GIT_CONFIG_GLOBAL="$HOME_72/.gitconfig" "$REPO_DIR/install.sh" --target global --editor claude --non-interactive --no-color > "$WORK_72/install.log" 2>&1 || { cat "$WORK_72/install.log"; fail_72 "global install over $NAME_72 failed"; }
    cmp -s "$FIXTURE_72" "$HOME_72/.git-templates/hooks/pre-commit" || fail_72 "global install changed $NAME_72"
    HOME="$HOME_72" GIT_CONFIG_GLOBAL="$HOME_72/.gitconfig" "$REPO_DIR/install.sh" --target global --editor claude --non-interactive --no-color --uninstall > "$WORK_72/uninstall.log" 2>&1 || { cat "$WORK_72/uninstall.log"; fail_72 "global uninstall over $NAME_72 failed"; }
    [ ! -e "$HOME_72/.git-templates/hooks/pre-commit" ] || fail_72 "global uninstall left $NAME_72 behind"
done

# 72c: global blocks appended to a user's hook: uninstall leaves exactly the .expected bytes.
for FIXTURE_72 in "$HOOKS_72"/global-appended/*; do
    case "$FIXTURE_72" in *.expected) continue ;; esac
    NAME_72="global-appended/$(basename "$FIXTURE_72")"
    HOME_72="$WORK_72/home"
    rm -rf "$HOME_72"
    mkdir -p "$HOME_72/.git-templates/hooks"
    cp "$FIXTURE_72" "$HOME_72/.git-templates/hooks/pre-commit"
    cd "$WORK_72"
    HOME="$HOME_72" GIT_CONFIG_GLOBAL="$HOME_72/.gitconfig" "$REPO_DIR/install.sh" --target global --editor claude --non-interactive --no-color --uninstall > "$WORK_72/uninstall.log" 2>&1 || { cat "$WORK_72/uninstall.log"; fail_72 "global uninstall over $NAME_72 failed"; }
    cmp -s "$FIXTURE_72.expected" "$HOME_72/.git-templates/hooks/pre-commit" || fail_72 "global uninstall of $NAME_72 did not leave exactly the user's lines"
done

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 72 passed successfully! install.sh replaces, removes and cleans every git hook text a release wrote, with and without a final line break.${NC}"

# -----------------------------------------------------------------------------
# TEST 73: install.sh writes exactly the hook bytes in tests/fixtures/git-hooks/current/
# (plan 064 item 2b; lifecycle Test 57 in PowerShell). tests/test-hook-parity.sh compares the hook
# text in the two installers' sources; the final newline is a property of how each installer
# writes, which only a run shows. The fixtures are what install.sh writes on main: a project
# install into a fresh repository, a global install with no hook, and a global install onto
# "#!/bin/sh", "echo before".
# -----------------------------------------------------------------------------
echo ""
echo "Running Test 73: install.sh writes the same git hook bytes as the fixtures..."

CURRENT_73="$REPO_DIR/tests/fixtures/git-hooks/current"
WORK_73="$SANDBOX_DIR/hook-bytes"
rm -rf "$WORK_73"
mkdir -p "$WORK_73/repo" "$WORK_73/home-fresh/.git-templates/hooks" "$WORK_73/home-appended/.git-templates/hooks"

fail_73() {   # message
    printf '%b\n' "${RED}✘ Test 73: $1${NC}"
    exit 1
}

git -C "$WORK_73/repo" -c init.templateDir= init -q -b main
cd "$WORK_73/repo"
"$REPO_DIR/install.sh" --target project --editor claude --non-interactive --no-color > "$WORK_73/project.log" 2>&1 || { cat "$WORK_73/project.log"; fail_73 "project install failed"; }
cmp -s ".git/hooks/pre-commit" "$CURRENT_73/project" || fail_73 "the project hook differs from current/project"

cd "$WORK_73"
HOME="$WORK_73/home-fresh" GIT_CONFIG_GLOBAL="$WORK_73/home-fresh/.gitconfig" "$REPO_DIR/install.sh" --target global --editor claude --non-interactive --no-color > "$WORK_73/fresh.log" 2>&1 || { cat "$WORK_73/fresh.log"; fail_73 "global install with no hook failed"; }
cmp -s "$WORK_73/home-fresh/.git-templates/hooks/pre-commit" "$CURRENT_73/global-fresh" || fail_73 "the fresh global hook differs from current/global-fresh"

printf '#!/bin/sh\necho before\n' > "$WORK_73/home-appended/.git-templates/hooks/pre-commit"
HOME="$WORK_73/home-appended" GIT_CONFIG_GLOBAL="$WORK_73/home-appended/.gitconfig" "$REPO_DIR/install.sh" --target global --editor claude --non-interactive --no-color > "$WORK_73/appended.log" 2>&1 || { cat "$WORK_73/appended.log"; fail_73 "global install onto an existing hook failed"; }
cmp -s "$WORK_73/home-appended/.git-templates/hooks/pre-commit" "$CURRENT_73/global-appended" || fail_73 "the appended global hook differs from current/global-appended"

cd "$REPO_DIR"
printf '%b\n' "${GREEN}✔ Test 73 passed successfully! install.sh writes the project hook, a fresh global hook and an appended global block byte for byte as the fixtures.${NC}"

# Clean up sandbox
rm -rf "$SANDBOX_DIR"

echo ""
echo "=================================================="
printf '%b\n' "${GREEN}ALL INTEGRATION TESTS PASSED SUCCESSFULLY! 100% GREEN${NC}"
echo "=================================================="
