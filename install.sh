#!/bin/bash

# QA Instinct - Installation Script
# Version: 2.0.0

set -e  # Exit on error

# ─── CLI Flag Defaults ───────────────────────────────────────────────────────

TARGET_FLAG=""
EDITOR_FLAG=""
NON_INTERACTIVE=false
OPT_NO_COLOR=false
NO_HOOKS=false
UPDATE_FLAG=false
UNINSTALL_FLAG=false
SHOW_HELP=false

# Cumulative uninstall reporting: how many recorded/matched files were actually removed vs.
# kept (changed since install, or read-only). The final summary is derived from these instead
# of assuming success.
UNINSTALL_REMOVED_COUNT=0
UNINSTALL_KEPT_COUNT=0

# Update reporting, the same three outcomes the CLI reports: files changed (refreshed, added,
# restored, adopted or removed), files already up to date, and files kept as they were.
UPDATE_REPORT=false
UPDATE_CHANGED_COUNT=0
UPDATE_UPTODATE_COUNT=0
UPDATE_KEPT_COUNT=0

# How many files install_file has written in this run. An editor is reported installed only when
# this grew while its files were installed, as the CLI does (plan 053 I14).
FILES_WRITTEN_COUNT=0

# ─── Parse CLI Flags ─────────────────────────────────────────────────────────

while [ $# -gt 0 ]; do
    case "$1" in
        --target)
            shift
            if [ -z "$1" ] || [[ "$1" == --* ]]; then
                echo "Error: --target requires a value (project|global|both)"
                exit 1
            fi
            TARGET_FLAG="$1"
            ;;
        --editor)
            shift
            if [ -z "$1" ] || [[ "$1" == --* ]]; then
                echo "Error: --editor requires a value (claude|cursor|windsurf|copilot|cline|antigravity|all)"
                exit 1
            fi
            EDITOR_FLAG="$1"
            ;;
        --non-interactive)
            NON_INTERACTIVE=true
            ;;
        --no-color)
            OPT_NO_COLOR=true
            ;;
        --no-hooks)
            NO_HOOKS=true
            ;;
        --update)
            UPDATE_FLAG=true
            ;;
        --uninstall|--remove)
            UNINSTALL_FLAG=true
            ;;
        --help)
            SHOW_HELP=true
            ;;
        *)
            echo "Unknown flag: $1"
            echo "Run with --help for usage information."
            exit 1
            ;;
    esac
    shift
done

# ─── Color codes ─────────────────────────────────────────────────────────────

# Colour is on for a human at a terminal, off when piped or redirected.
# GITHUB_ACTIONS is checked because Actions is not a TTY but its log viewer
# does render ANSI — without it, CI logs would lose all colour.
use_colour() {
    [ -n "${NO_COLOR:-}" ] && return 1
    [ -n "${FORCE_COLOR:-}" ] && return 0
    [ -n "${GITHUB_ACTIONS:-}" ] && return 0
    [ -t 1 ]
}

if [ "$OPT_NO_COLOR" = true ]; then
    GREEN=''
    YELLOW=''
    RED=''
    CYAN=''
    NC=''
elif use_colour; then
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    GREEN=''
    YELLOW=''
    RED=''
    CYAN=''
    NC=''
fi

# ─── Help ─────────────────────────────────────────────────────────────────────

if [ "$SHOW_HELP" = true ]; then
    cat << 'HELPTEXT'
QA Instinct - Installation Script v2.0.0

Usage: ./install.sh [OPTIONS]

Options:
  --target <project|global|both>
      Installation scope. Default: prompt interactively.

  --editor <claude|cursor|windsurf|copilot|cline|antigravity|all>
      Target editor. Default: claude (Claude Code).

  --non-interactive
      Skip all prompts, use defaults or specified flags.
      Defaults: --target project --editor claude

  --no-color
      Disable ANSI color codes in output.

  --no-hooks
      Skip registering the validate-tc-format.sh pre-commit validation hook.

  --update
      For each editor already installed, or only the one --editor names: refresh
      its files, install the files this release added, and remove the ones it no
      longer ships (kept if you changed them). Installs nothing for an editor that
      is not installed.

  --uninstall, --remove
      Completely uninstall all rules, commands, skills, and clean up Git hooks.

  --help
      Show this help message and exit.

Examples:
  ./install.sh
  ./install.sh --target project --editor claude
  ./install.sh --target both --editor all --non-interactive
  ./install.sh --non-interactive --no-color
HELPTEXT
    exit 0
fi

# ─── Pre-flight checks ──────────────────────────────────────────────────────

# 0. Check bash version >= 3.2
BASH_MAJOR="${BASH_VERSINFO[0]:-0}"
BASH_MINOR="${BASH_VERSINFO[1]:-0}"
if [ "$BASH_MAJOR" -lt 3 ] || { [ "$BASH_MAJOR" -eq 3 ] && [ "$BASH_MINOR" -lt 2 ]; }; then
    printf '%b\n' "${RED}Error: bash >= 3.2 required (found $BASH_VERSION).${NC}"
    exit 1
fi

# 0b. A SHA-256 tool that works. Every decision about an existing file rests on its hash; without
# one, a user's file could not be told from the package's own, so nothing is written (plan 045).
EMPTY_SHA256="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
SHA256_TOOL=""
sha256_stdin() {   # prints the SHA-256 of standard input; under pipefail, fails when the tool does
    if [ "$SHA256_TOOL" = sha256sum ]; then sha256sum; else shasum -a 256; fi | awk '{print $1}'
}
for CANDIDATE_TOOL in sha256sum shasum; do
    command -v "$CANDIDATE_TOOL" >/dev/null 2>&1 || continue
    SHA256_TOOL="$CANDIDATE_TOOL"
    [ "$(printf '' | sha256_stdin 2>/dev/null)" = "$EMPTY_SHA256" ] && break
    SHA256_TOOL=""
done
if [ -z "$SHA256_TOOL" ]; then
    printf '%b\n' "${RED}Error: no working SHA-256 tool found (sha256sum or shasum -a 256). Nothing was changed.${NC}"
    echo "The installer needs one to tell your own files from the package's; install one and run it again."
    exit 1
fi

echo "╔════════════════════════════════════════════════╗"
echo "║   QA Instinct - Installation Script               ║"
echo "║   QA skills for AI editors                      ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QA_COMMANDS_DIR="$SCRIPT_DIR/.claude/commands"
QA_SKILL_FILE="$QA_COMMANDS_DIR/qa.md"
ADAPTERS_DIR="$SCRIPT_DIR/adapters"
EDITOR_MAP_FILE="$SCRIPT_DIR/.qa-instinct-editor-map"

# 1. Check qa.md exists
if [ ! -f "$QA_SKILL_FILE" ]; then
    printf '%b\n' "${RED}Error: qa.md not found at $QA_SKILL_FILE${NC}"
    echo "Please ensure you're running this script from the QA package directory."
    exit 1
fi

# yes_no <prompt> <default>: asks until the answer is y or n, in either case, as install.ps1's
# Read-YesNo does, and leaves it, lower-cased, in YES_NO_ANSWER. An empty answer takes the default;
# so does the end of input, where install.ps1's Read-Host returns nothing (plan 045 item 6).
yes_no() {
    local PROMPT="$1" DEFAULT="$2" ANSWER
    while true; do
        ANSWER=""
        read -r -p "$PROMPT" ANSWER || true
        ANSWER="${ANSWER:-$DEFAULT}"
        case "$ANSWER" in
            y|Y) YES_NO_ANSWER=y; return 0 ;;
            n|N) YES_NO_ANSWER=n; return 0 ;;
        esac
        printf '%b\n' "${RED}Please enter 'y' or 'n'.${NC}"
    done
}

# 2. Check Claude Code is installed
if ! command -v claude &>/dev/null; then
    printf '%b\n' "${YELLOW}Warning: 'claude' command not found in PATH.${NC}"
    echo "The skill file will be installed, but Claude Code may not be set up yet."
    echo "Install Claude Code from: https://docs.anthropic.com/claude-code"
    echo ""
    if [ "$NON_INTERACTIVE" = true ]; then
        echo "Non-interactive mode: continuing without Claude Code."
    else
        yes_no "Continue anyway? (y/n): " n
        if [ "$YES_NO_ANSWER" != "y" ]; then
            echo "Installation cancelled."
            exit 0
        fi
    fi
fi

# ─── WSL Detection ──────────────────────────────────────────────────────────

IS_WSL=false
if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
fi
# Set when register_git_hook sets up the global hook; the Windows-side install reads it to say
# that the hook is not active for Windows-side git (plan 014 A3).
GLOBAL_HOOK_SET_UP=false

# 3. Check for version conflict (existing file that might be newer)
check_version_conflict() {
    local TARGET="$1"
    if [ -f "$TARGET" ]; then
        if [ "$OPERATION" = "update" ]; then
            return 0
        fi
        # -E, not -P: BSD grep (macOS) has no -P. The pipeline's status is head's, so an empty
        # result is the "unknown" case.
        local EXISTING_VER
        EXISTING_VER=$(grep -m1 'Version:' "$TARGET" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        EXISTING_VER="${EXISTING_VER:-unknown}"
        local NEW_VER
        NEW_VER=$(grep -m1 'Version:' "$QA_SKILL_FILE" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        NEW_VER="${NEW_VER:-unknown}"
        printf '%b\n' "${YELLOW}Existing file found at: $TARGET${NC}"
        echo "  Installed version : $EXISTING_VER"
        echo "  Package version   : $NEW_VER"
        if [ "$NON_INTERACTIVE" = true ]; then
            echo "Non-interactive mode: overwriting."
            return 0
        fi
        yes_no "Overwrite? (y/n): " n
        if [ "$YES_NO_ANSWER" != "y" ]; then
            printf '%b\n' "${CYAN}Skipping $TARGET — no changes made.${NC}"
            return 1
        fi
    fi
    return 0
}

# ─── Validate CLI flag values ────────────────────────────────────────────────

if [ -n "$TARGET_FLAG" ]; then
    case "$TARGET_FLAG" in
        project|global|both) ;;
        *)
            printf '%b\n' "${RED}Error: invalid --target value '$TARGET_FLAG'. Use: project, global, or both.${NC}"
            exit 1
            ;;
    esac
fi

if [ -n "$EDITOR_FLAG" ]; then
    case "$EDITOR_FLAG" in
        claude|cursor|windsurf|copilot|cline|antigravity|all) ;;
        *)
            printf '%b\n' "${RED}Error: invalid --editor value '$EDITOR_FLAG'. Use: claude, cursor, windsurf, copilot, cline, antigravity, or all.${NC}"
            exit 1
            ;;
    esac
fi

# ─── Helper: generate Cursor .mdc file with YAML frontmatter ────────────────

generate_cursor_mdc() {
    local SOURCE="$1"
    local TARGET="$2"
    mkdir -p "$(dirname "$TARGET")"
    cat > "$TARGET" << 'FRONTMATTER'
---
description: "Senior QA Engineer — aligned with ISTQB CTFL v4.0; Playwright, Vitest, BDD and CI/CD"
alwaysApply: false
---
FRONTMATTER
    cat "$SOURCE" >> "$TARGET"
}

# ─── Helper: check if adapter exists ──────────────────────────────────────────

check_adapter_exists() {
    local ADAPTER_PATH="$1"
    if [ ! -f "$ADAPTER_PATH" ]; then
        printf '%b\n' "${RED}Error: Adapter not found at $ADAPTER_PATH${NC}"
        echo "Run ./generate-adapters.sh first to generate the adapters."
        return 1
    fi
    return 0
}

# ─── Helper: register Git hooks ──────────────────────────────────────────────

# The marker line the project hook carries; uninstall and the "is this ours?" check match on it,
# and on the line every 4.x release wrote (plan 066).
PROJECT_HOOK_MARKER="Pre-commit hook to validate test cases in qa-instinct"
PROJECT_HOOK_OLD_MARKER="Pre-commit hook to validate test cases in qa-skills"

# Prints the hooks directory of the git repository rooted at $1 and fails when $1 is not the
# root of one. Asking git (rather than assuming $1/.git/hooks) handles a .git that is a file,
# as in a worktree or submodule.
project_hooks_dir() {
    local BASE="$1" DIR
    [ -e "$BASE/.git" ] || return 1
    DIR="$(git -C "$BASE" rev-parse --git-path hooks 2>/dev/null)" || return 1
    case "$DIR" in
        /*|[A-Za-z]:*) ;;
        *) DIR="$BASE/$DIR" ;;
    esac
    printf '%s\n' "$DIR"
}

# The global hook block is fenced by two exact marker lines so install and uninstall only ever
# touch their own lines of a hook that may be the user's. The old "Added by" line stays inside
# the block, and so does the old end line, so an older uninstaller still recognises it.
GLOBAL_HOOK_BEGIN="# >>> bem-te-vi global pre-commit >>>"
GLOBAL_HOOK_END="# <<< bem-te-vi global pre-commit <<<"
GLOBAL_HOOK_OLD_MARKER="# Added by qa-skills global installer"
GLOBAL_HOOK_OLD_END="# GLOBAL_PRECOMMIT_APPEND"
GLOBAL_HOOK_FRESH_HEADER="# Global pre-commit hook to validate test cases in qa-instinct"
# The header a 4.x or older release wrote; a fresh hook from before the fences starts at it.
GLOBAL_HOOK_OLD_FRESH_HEADER="# Global pre-commit hook to validate test cases in qa-skills"

# Matches a first line that is a sh or bash shebang, the only hooks a bash block can be appended to.
SH_SHEBANG_RE='^#![[:space:]]*(/[^[:space:]]*/)?(env[[:space:]]+)?(ba)?sh([[:space:]]|$)'

global_hook_block() {
    cat << 'GLOBAL_PRECOMMIT_BLOCK'
# >>> bem-te-vi global pre-commit >>>
# Added by qa-skills global installer
GLOBAL_VALIDATOR="$HOME/.claude/hooks/validate-tc-format.sh"
if [ -f "$GLOBAL_VALIDATOR" ]; then
    # Validate every staged Markdown file, renamed ones included. The list is NUL-separated so
    # names with spaces, non-ASCII characters or glob characters arrive intact. bash does the
    # reading, so this block also works appended to a hook that runs under plain sh.
    git diff --cached --name-only -z --diff-filter=ACMR -- '*.md' | bash -c '
        while IFS= read -r -d "" FILE; do
            if grep -qE "^## TC-[A-Z0-9]+-[0-9]+:" "$FILE" 2>/dev/null; then
                if ! "$1" "$FILE"; then
                    printf "\033[0;31mError: Test case validation failed for %s. Commit aborted.\033[0m\n" "$FILE"
                    exit 1
                fi
            fi
        done' bash "$GLOBAL_VALIDATOR" || exit 1
fi
# GLOBAL_PRECOMMIT_APPEND
# <<< bem-te-vi global pre-commit <<<
GLOBAL_PRECOMMIT_BLOCK
}

# Prints $1 without the bem-te-vi block. The block is the lines between the two markers; for a hook
# written by an older release it runs from the old "Added by" line (or, for a fresh hook written by
# install.ps1, the header comment) to the first line that is exactly "fi", which is how the old
# block ends. One blank line right before the block, the separator the installer added, goes too.
# Exit status 3: no block found. Exit status 4: a block starts but its end cannot be found, so
# nothing is printed and the caller must leave the file alone.
strip_global_hook_block() {
    awk -v B="$GLOBAL_HOOK_BEGIN" -v E="$GLOBAL_HOOK_END" -v O="$GLOBAL_HOOK_OLD_MARKER" \
        -v A="$GLOBAL_HOOK_OLD_END" -v H="$GLOBAL_HOOK_OLD_FRESH_HEADER" '
        { line[NR] = $0; t = $0; sub(/\r$/, "", t); trim[NR] = t }
        END {
            s = 0; old = 0
            for (i = 1; i <= NR && !s; i++) if (trim[i] == B) s = i
            if (!s) { old = 1; for (i = 1; i <= NR && !s; i++) if (trim[i] == O) s = i }
            if (!s) { for (i = 1; i <= NR && !s; i++) if (trim[i] == H) s = i }
            if (!s) exit 3
            e = 0; want = old ? "fi" : E
            for (i = s + 1; i <= NR && !e; i++) if (trim[i] == want) e = i
            if (!e) exit 4
            if (old && trim[e + 1] == A) e++
            if (s > 1 && trim[s - 1] == "") s--
            for (i = 1; i <= NR; i++) if (i < s || i > e) print line[i]
        }' "$1"
}

register_git_hook() {
    local SCOPE="$1"        # project|global
    local BASE_DIR="$2"     # project path or $HOME

    if [ "$NO_HOOKS" = true ]; then
        printf '%b\n' "${YELLOW}  ⚠ Hooks disabled by --no-hooks flag — skipping hook registration.${NC}"
        return 0
    fi

    if [ "$SCOPE" = "project" ]; then
        local HOOK_DIR HOOKS_PATH_CFG
        if ! HOOK_DIR="$(project_hooks_dir "$BASE_DIR")"; then
            printf '%b\n' "${YELLOW}  ⚠ Not a git repository, skipping project-level git hook.${NC}"
            return 0
        fi

        # A hook manager (husky, lefthook, ...) that sets core.hooksPath makes git ignore
        # .git/hooks entirely, so writing there would only pretend to register something.
        HOOKS_PATH_CFG="$(git -C "$BASE_DIR" config core.hooksPath 2>/dev/null || true)"
        if [ -n "$HOOKS_PATH_CFG" ]; then
            printf '%b\n' "${YELLOW}  ⚠ core.hooksPath is set ($HOOKS_PATH_CFG); add the qa-instinct check to your hook manager yourself:${NC}"
            printf '%b\n' "${CYAN}      bash .claude/hooks/validate-tc-format.sh <file>${NC}"
            return 0
        fi

        local HOOK_FILE="$HOOK_DIR/pre-commit"
        # Never replace a hook we did not write: it is the user's (or their hook manager's).
        if [ -L "$HOOK_FILE" ] || { [ -e "$HOOK_FILE" ] && ! grep -qF -e "$PROJECT_HOOK_MARKER" -e "$PROJECT_HOOK_OLD_MARKER" "$HOOK_FILE"; }; then
            printf '%b\n' "${YELLOW}  ⚠ Kept your existing pre-commit hook: $HOOK_FILE${NC}"
            printf '%b\n' "${CYAN}      To validate test cases from it, run: bash .claude/hooks/validate-tc-format.sh <file>${NC}"
            return 0
        fi

        mkdir -p "$HOOK_DIR"
        
        # Create pre-commit script
        cat > "$HOOK_FILE" << 'PRECOMMIT'
#!/usr/bin/env bash
# Pre-commit hook to validate test cases in qa-instinct

SCRIPT_DIR="$(git rev-parse --show-toplevel)"
VALIDATOR="$SCRIPT_DIR/.claude/hooks/validate-tc-format.sh"

if [ -f "$VALIDATOR" ]; then
    # Validate every staged Markdown file, renamed ones included. The list is NUL-separated so
    # names with spaces, non-ASCII characters or glob characters arrive intact.
    git diff --cached --name-only -z --diff-filter=ACMR -- '*.md' |
    while IFS= read -r -d '' FILE; do
        # Only validate if the file contains test cases
        if grep -qE "^## TC-[A-Z0-9]+-[0-9]+:" "$SCRIPT_DIR/$FILE" 2>/dev/null; then
            if ! "$VALIDATOR" "$SCRIPT_DIR/$FILE"; then
                printf '\033[0;31mError: Test case validation failed for %s. Commit aborted.\033[0m\n' "$FILE"
                exit 1
            fi
        fi
    done
    # The loop ran in a subshell, so its failure only shows up here.
    [ "${PIPESTATUS[1]}" -eq 0 ] || exit 1
fi
PRECOMMIT
        chmod +x "$HOOK_FILE"
        printf '%b\n' "${GREEN}  ✓ Registered project-level git pre-commit hook: $HOOK_FILE${NC}"
    else
        # Global registration
        GLOBAL_HOOK_SET_UP=true
        local GLOBAL_HOOKS_DIR="$HOME/.git-templates/hooks"
        # Check if user has core.hooksPath set
        local EXISTING_HOOKS_PATH
        EXISTING_HOOKS_PATH=$(git config --global core.hooksPath || echo "")
        
        if [ -n "$EXISTING_HOOKS_PATH" ]; then
            # Expand tilde
            EXISTING_HOOKS_PATH="${EXISTING_HOOKS_PATH/#\~/$HOME}"
            GLOBAL_HOOKS_DIR="$EXISTING_HOOKS_PATH"
        fi
        
        local HOOK_FILE="$GLOBAL_HOOKS_DIR/pre-commit"
        mkdir -p "$GLOBAL_HOOKS_DIR"
        
        # Create global pre-commit or append to it
        if [ -L "$HOOK_FILE" ]; then
            printf '%b\n' "${YELLOW}  ⚠ Kept your existing global pre-commit hook (a symlink): $HOOK_FILE${NC}"
            printf '%b\n' "${CYAN}      To validate test cases from it, run: bash ~/.claude/hooks/validate-tc-format.sh <file>${NC}"
        elif [ -f "$HOOK_FILE" ] && ! grep -q "validate-tc-format.sh" "$HOOK_FILE"; then
            if head -n 1 "$HOOK_FILE" | grep -qE "$SH_SHEBANG_RE"; then
                # Finish an unterminated last line, then add a blank separator and our block.
                if [ -n "$(tail -c 1 "$HOOK_FILE")" ]; then printf '\n' >> "$HOOK_FILE"; fi
                { printf '\n'; global_hook_block; } >> "$HOOK_FILE"
                printf '%b\n' "${GREEN}  ✓ Appended global pre-commit hook: $HOOK_FILE${NC}"
            else
                printf '%b\n' "${YELLOW}  ⚠ Kept your existing global pre-commit hook (not a sh or bash script): $HOOK_FILE${NC}"
                printf '%b\n' "${CYAN}      To validate test cases from it, run: bash ~/.claude/hooks/validate-tc-format.sh <file>${NC}"
            fi
        elif [ ! -e "$HOOK_FILE" ]; then
            { printf '#!/usr/bin/env bash\n%s\n\n' "$GLOBAL_HOOK_FRESH_HEADER"; global_hook_block; } > "$HOOK_FILE"
            chmod +x "$HOOK_FILE"
            printf '%b\n' "${GREEN}  ✓ Created global git pre-commit hook: $HOOK_FILE${NC}"
        fi
        
        # Configure global git templates/hooks if core.hooksPath not set
        if [ -z "$EXISTING_HOOKS_PATH" ]; then
            local EXISTING_TEMPLATE_DIR
            EXISTING_TEMPLATE_DIR=$(git config --global init.templateDir || echo "")
            if [ -z "$EXISTING_TEMPLATE_DIR" ]; then
                git config --global init.templateDir "$HOME/.git-templates"
                printf '%b\n' "${CYAN}  i Configured git global init.templateDir to $HOME/.git-templates${NC}"
            else
                printf '%b\n' "${CYAN}  i Kept your existing git init.templateDir: $EXISTING_TEMPLATE_DIR${NC}"
            fi
        fi
    fi
}

# ─── Helper: install to a specific editor path ──────────────────────────────

# ─── Shared editor → install-folder mapping ──────────────────────────────────
# Single source of truth for every non-claude editor's install folders and display label, shared
# with install.ps1 and cli/qa-instinct.js. See .qa-instinct-editor-map. Format: tab-separated
# "<editor>\t<project rules>\t<global rules>\t<project skills>\t<global skills>\t<label>",
# "-" where the editor has none (plan 047). The generated rule files of adapters/<editor>/rules/
# go into the rules folder, and the one Agent Skills tree adapters/skills/ into the skills folder.
# A skills column may name several folders separated by "," (Antigravity's App and IDE share one
# global folder, its CLI reads another; plan 058); the tree goes into each, in that order.
# An editor installs for a target only when it has a skills folder there. `claude` is not listed
# here: it copies the raw .claude/ tree and is handled separately in install_to_editor.

editor_map_field() {
    local ED="$1" COL="$2"
    awk -F'\t' -v ed="$ED" -v col="$COL" '
        $1 == ed {
            if (col == "project-rules") print $2
            else if (col == "global-rules") print $3
            else if (col == "project-skills") print $4
            else if (col == "global-skills") print $5
            else if (col == "label") print $6
        }
    ' "$EDITOR_MAP_FILE"
}

# Removes each now-empty ancestor directory between $1 (a just-uninstalled file's
# parent dir) and $2 (BASE_DIR, exclusive), stopping at the first non-empty one.
# Reproduces, generically, the fixed-depth rmdir chains each editor's uninstall
# used to hand-write against its own hardcoded path.
# Uninstall prunes only after an actual removal (plan 047): the files this run removed are listed
# in UNINSTALL_REMOVED_RELS, one path relative to the base per line.
UNINSTALL_REMOVED_RELS=""
remove_empty_ancestors() {
    local DIR="$1" STOP="$2"
    while [ "$DIR" != "$STOP" ] && [ -d "$DIR" ]; do
        rmdir "$DIR" 2>/dev/null || break
        DIR="$(dirname "$DIR")"
    done
}

# ─── Install manifest ─────────────────────────────────────────────────────────
# Every file the installer writes is recorded in <base>/.qa-instinct-manifest as
# "<sha256>  <editor>  <path relative to base>". Uninstall then removes only files whose
# content still matches what was installed, so a project's own files are never destroyed —
# including ones whose names collide with the package's, and files this package shipped
# under a different name in an older version.
#
# The manifest is a portable format shared with install.ps1: no BOM, LF line endings,
# forward-slash path separators. install.ps1 writes the same bytes. Reads here tolerate a
# stray leading UTF-8 BOM and trailing \r so a manifest written by an older release, or by
# PowerShell's platform-native encoding, still parses correctly.

manifest_file() { echo "$1/.qa-instinct-manifest"; }
# The name every 4.x release wrote the manifest under (plan 066).
legacy_manifest_file() { echo "$1/.qa-skills-manifest"; }

valid_sha256() {   # text -> success when it is 64 lowercase hex digits
    [ "${#1}" -eq 64 ] && [ -z "${1//[0-9a-f]/}" ]
}

# Prints the file's SHA-256, or nothing with a failure status when the file cannot be read (or is
# a directory): a hash that was not computed must never be compared or recorded (plan 045).
hash_file() {
    local HASH
    HASH="$(set -o pipefail; { sha256_stdin < "$1"; } 2>/dev/null)" || HASH=""
    valid_sha256 "$HASH" || return 1
    printf '%s\n' "$HASH"
}

# The package's own file with CRLF line endings (a Windows checkout with core.autocrlf, a
# Windows editor) is still the package's file. A file on disk therefore *matches* a hash if
# its bytes hash to it, or its bytes with every carriage return removed do — the same rule in
# install.ps1 and cli/qa-instinct.js (plans/017). Hashes are still recorded as the raw bytes.
hash_file_without_cr() {
    local HASH
    HASH="$(set -o pipefail; { tr -d '\r' < "$1" | sha256_stdin; } 2>/dev/null)" || HASH=""
    valid_sha256 "$HASH" || return 1
    printf '%s\n' "$HASH"
}

file_matches() {   # file hash -> success if the file matches the hash, by the rule above
    [ -n "$2" ] || return 1
    [ "$(hash_file "$1")" = "$2" ] && return 0
    [ "$(hash_file_without_cr "$1")" = "$2" ]
}

# Reads a manifest file line by line on stdout, stripping a leading UTF-8 BOM (if present on
# the first line), any trailing \r (Windows CRLF), and normalizing recorded backslash path
# separators to forward slashes, so manifests written by either platform's installer — or by
# an older release — parse identically.
manifest_lines() {
    local MF="$1"
    [ -f "$MF" ] || return 0
    # shellcheck disable=SC1003 # the single quotes below hold one literal backslash, not an escape
    sed $'1s/^\xEF\xBB\xBF//' "$MF" | tr -d '\r' | tr '\\' '/'
}

manifest_lookup() {   # base editor rel -> recorded hash, empty when not recorded
    local MF="$1" ED="$2" REL="$3" HASH ENTRY_ED ENTRY_REL
    MF="$(manifest_file "$1")"
    [ -f "$MF" ] || return 0
    while read -r HASH ENTRY_ED ENTRY_REL; do
        if [ "$ENTRY_ED" = "$ED" ] && [ "$ENTRY_REL" = "$REL" ]; then
            printf '%s\n' "$HASH"
            return 0
        fi
    done < <(manifest_lines "$MF")
}

# Every manifest write goes to a new, randomly named temp file beside the manifest, created by
# write_exclusive: a name that is already taken, by a link or anything else, is never opened. The
# whole body is written through that one descriptor, with the umask's mode as every release
# before used, and the file is never reopened by path; it is then renamed over the manifest,
# which replaces a symlinked manifest instead of writing through it (plan 033 item 2). An empty
# body removes the manifest.
manifest_write() {   # manifest body
    local MF="$1" BODY="$2" TMP STATUS N=0
    if [ -z "$BODY" ]; then
        rm -f "$MF"
        return 0
    fi
    while :; do
        TMP="$MF.tmp.$$.$RANDOM$RANDOM$RANDOM"
        STATUS=0
        write_exclusive "$TMP" printf '%s' "$BODY" || STATUS=$?
        [ "$STATUS" -eq 0 ] && break
        if [ "$STATUS" -eq 3 ]; then
            printf '%b\n' "${RED}Error: could not write $TMP${NC}" >&2
            return 1
        fi
        N=$((N + 1))
        # Not created: the name was taken (retry with another) or the folder is not writable.
        if [ "$N" -ge 20 ] || { [ ! -e "$TMP" ] && [ ! -L "$TMP" ]; }; then
            printf '%b\n' "${RED}Error: could not create a temporary file beside $MF${NC}" >&2
            return 1
        fi
    done
    mv -f "$TMP" "$MF"
}

manifest_record() {   # base editor rel hash
    local MF ED="$2" REL="$3" HASH="$4" BODY="" EHASH EED EREL
    MF="$(manifest_file "$1")"
    # An entry without a real hash could never be matched again, so uninstall would keep the file.
    if ! valid_sha256 "$HASH"; then
        printf '%b\n' "${RED}Error: refusing to record $REL without a SHA-256${NC}" >&2
        return 1
    fi
    if [ -f "$MF" ]; then
        while read -r EHASH EED EREL; do
            [ "$EED" = "$ED" ] && [ "$EREL" = "$REL" ] && continue
            BODY="$BODY$EHASH  $EED  $EREL"$'\n'
        done < <(manifest_lines "$MF")
    fi
    BODY="$BODY$HASH  $ED  $REL"$'\n'
    manifest_write "$MF" "$BODY"
}

# Moves a 4.x install's manifest to the current name, the same in all three installers (plan 066),
# once per base and before anything reads the manifest. Every entry of both files is kept; on the
# same editor and path the current manifest's entry wins. The new manifest is written the usual
# way, then the old name is removed: a symlink there is unlinked, never its target. A folder or an
# unreadable file at the old name is not a manifest this run can use, so it is left and reported.
MIGRATED_BASES=""
migrate_manifest() {   # base
    local BASE="$1" OLD NEW BODY="" KEYS=$'\n' HASH ED REL
    case "$MIGRATED_BASES" in *"|$BASE|"*) return 0 ;; esac
    MIGRATED_BASES="$MIGRATED_BASES|$BASE|"
    OLD="$(legacy_manifest_file "$BASE")"
    NEW="$(manifest_file "$BASE")"
    if [ -d "$OLD" ]; then
        printf '%b\n' "${YELLOW}  ! Kept ${OLD##*/} — it is a directory, not a manifest${NC}"
        return 0
    fi
    [ -f "$OLD" ] || return 0
    if [ ! -r "$OLD" ]; then
        printf '%b\n' "${YELLOW}  ! Kept ${OLD##*/} — it cannot be read${NC}"
        return 0
    fi
    while read -r HASH ED REL; do
        [ -n "$HASH" ] || continue
        KEYS="$KEYS$ED  $REL"$'\n'
        BODY="$BODY$HASH  $ED  $REL"$'\n'
    done < <(manifest_lines "$NEW")
    while read -r HASH ED REL; do
        [ -n "$HASH" ] || continue
        case "$KEYS" in *$'\n'"$ED  $REL"$'\n'*) continue ;; esac
        BODY="$BODY$HASH  $ED  $REL"$'\n'
    done < <(manifest_lines "$OLD")
    manifest_write "$NEW" "$BODY" || return 1
    rm -f "$OLD"
}

# Known-hash list: the SHA-256 of every file this package has ever shipped, across all tagged
# releases (see generate-known-hashes.sh and plans/011-release-hash-provenance.md). Lets the
# installer tell its own older file from the user's edit with certainty instead of guessing —
# loaded once per run, not once per file, since ~20 files get installed in a typical run.
KNOWN_HASHES=""
KNOWN_HASHES_LOADED=false

load_known_hashes() {
    [ "$KNOWN_HASHES_LOADED" = true ] && return 0
    KNOWN_HASHES_LOADED=true
    local LIST="$SCRIPT_DIR/.qa-instinct-known-hashes"
    # Missing list (old checkout, trimmed package) is not an error: known_hash simply never
    # matches, and every differing destination falls back to today's back-up-and-warn behavior.
    [ -f "$LIST" ] || return 0
    # Same portable-format tolerance as manifest_lines: strip a leading UTF-8 BOM and any \r.
    # shellcheck disable=SC1003 # the single quotes below hold one literal backslash, not an escape
    KNOWN_HASHES="$(sed $'1s/^\xEF\xBB\xBF//' "$LIST" | tr -d '\r')"
}

known_hash() {   # sha256 -> success if some previous release shipped a file with this hash
    load_known_hashes
    [ -n "$KNOWN_HASHES" ] || return 1
    printf '%s\n' "$KNOWN_HASHES" | grep -q "^$1  "
}

backup_dest() {   # base editor rel dest src -> if dest's content differs from src/manifest,
                  # prints one of:
                  #   (nothing)      dest already matches src or the manifest — no action needed
                  #   ADOPTED        dest's hash matches a previous release's file — safe to
                  #                  overwrite, no backup needed
                  #   BACKUP <path>  dest is the user's own content — backed up to <path>
                  # (following symlinks, so a linked file's own content is backed up, not the link)
    local BASE="$1" ED="$2" REL="$3" DEST="$4" SRC="$5"
    local DEST_HASH SRC_HASH RECORDED PASS
    SRC_HASH="$(hash_file "$SRC")" || SRC_HASH=""
    RECORDED="$(manifest_lookup "$BASE" "$ED" "$REL")"
    # Raw bytes first; the carriage-return-free hash only when they match nothing (see
    # file_matches). A hash that could not be computed proves nothing: the file is backed up.
    for PASS in raw without-cr; do
        if [ "$PASS" = raw ]; then
            DEST_HASH="$(hash_file "$DEST")" || DEST_HASH=""
        else
            DEST_HASH="$(hash_file_without_cr "$DEST")" || DEST_HASH=""
        fi
        [ -n "$DEST_HASH" ] || break
        [ "$DEST_HASH" = "$SRC_HASH" ] && return 0
        [ -n "$RECORDED" ] && [ "$DEST_HASH" = "$RECORDED" ] && return 0
        if known_hash "$DEST_HASH"; then
            echo "ADOPTED"
            return 0
        fi
    done
    local BACKUP SUFFIX N=0
    SUFFIX="$(date -u +%Y%m%dT%H%M%SZ)"
    BACKUP="$DEST.qa-instinct-backup-$SUFFIX"
    # Created exclusively, like the manifest's temp file: a name already taken, a link planted
    # there included, is never opened; the next number is tried instead.
    until write_exclusive "$BACKUP" cat "$DEST"; do
        N=$((N + 1))
        if [ "$N" -ge 100 ] || { [ ! -e "$BACKUP" ] && [ ! -L "$BACKUP" ]; }; then
            printf '%b\n' "${RED}Error: could not back up $DEST${NC}" >&2
            return 1
        fi
        BACKUP="$DEST.qa-instinct-backup-$SUFFIX-$N"
    done
    echo "BACKUP $BACKUP"
}

# Runs a command with its output going to a file that must not exist yet. Any existing name, a
# link included whatever it points at, counts as taken and is never opened. bash's noclobber
# alone is not enough: it adds O_EXCL only when the name does not exist, and opens an existing
# name that is not a regular file, so a link to a FIFO or a device would be opened through (plan
# 045 item 5). noclobber still covers a name created between the check and the open, unless that
# new name is a link to something other than a regular file; plain bash cannot close that window.
# Fails when the name is taken (nothing is written) or the command fails (the file is removed,
# status 3).
write_exclusive() {   # file command...
    local FILE="$1" STATUS=0
    shift
    if [ -e "$FILE" ] || [ -L "$FILE" ]; then return 1; fi
    ( set -C; { "$@" >&3 || exit 3; } 3> "$FILE" ) 2>/dev/null || STATUS=$?
    [ "$STATUS" -eq 3 ] && rm -f "$FILE"
    return "$STATUS"
}

# A symlinked folder below the editor's top-level folder (.claude/rules, .agents/skills, ...) is
# never written or deleted through: after `qa-instinct link` those folders are the npm package's own
# files, and any other link leads outside the install tree. The top-level folder itself (.claude
# as a link into a dotfiles repository) is followed, as the editor follows it (plan 033 item 1).
linked_ancestor() {   # base rel -> prints the first symlinked folder (relative to base), if any
    local BASE="$1" REL="$2" PREFIX REST
    PREFIX="${REL%%/*}"
    [ "$PREFIX" != "$REL" ] || return 0
    REST="${REL#*/}"
    while [ "${REST#*/}" != "$REST" ]; do
        PREFIX="$PREFIX/${REST%%/*}"
        REST="${REST#*/}"
        if [ -L "$BASE/$PREFIX" ]; then
            printf '%s\n' "$PREFIX"
            return 0
        fi
    done
    return 0
}

REPORTED_LINKS=""
report_linked_dir() {   # base dir action verb — once per link and run
    local BASE="$1" DIR="$2" ACTION="$3" VERB="$4" HINT=""
    case "$REPORTED_LINKS" in *"|$DIR|"*) return 0 ;; esac
    REPORTED_LINKS="$REPORTED_LINKS|$DIR|"
    # A link `qa-instinct link` made points at some package's .claude/<same name>.
    case "/$(readlink "$BASE/$DIR")" in
        */.claude/"${DIR##*/}") HINT="; run 'qa-instinct unlink' first" ;;
    esac
    printf '%b\n' "${YELLOW}  ! $ACTION $DIR/ — it is a symbolic link; nothing was $VERB through it$HINT${NC}"
}

install_file() {      # base editor src dest
    # Prime the known-hash cache here, in the parent shell. backup_dest below runs inside a
    # command substitution, i.e. a subshell, so anything it loads is discarded when it returns;
    # loading here means the subshell inherits a populated cache and the list is read once per
    # run rather than once per file.
    load_known_hashes
    local BASE="$1" ED="$2" SRC="$3" DEST="$4"
    local REL="${DEST#"$BASE"/}"
    # REL is what gets recorded in the manifest and is later resolved as "$BASE/$REL" on
    # uninstall. If DEST doesn't actually live under BASE, the "${DEST#"$BASE"/}" strip is a
    # no-op (or leaves a path that climbs back out via "../"), producing an absolute or
    # out-of-tree entry that can never resolve against its own base — uninstall would then
    # skip it silently and drop the entry, orphaning the file forever. Refuse loudly instead:
    # this is a bug in the installer's own call site, not user data, so aborting the install
    # is preferable to continuing with a manifest entry we already know is unusable.
    case "$REL" in
        "$DEST"|/*|../*|..)
            printf '%b\n' "${RED}Error: refusing to install $DEST — it is not inside base $BASE, so it can never be recorded in the manifest.${NC}" >&2
            return 1
            ;;
    esac
    # What update reports for this file: the hash recorded before, and the content before.
    local RECORDED_BEFORE="" BEFORE_HASH=""
    if [ "$UPDATE_REPORT" = true ]; then
        RECORDED_BEFORE="$(manifest_lookup "$BASE" "$ED" "$REL")"
        if [ -f "$DEST" ] && [ ! -L "$DEST" ]; then BEFORE_HASH="$(hash_file "$DEST")" || BEFORE_HASH=""; fi
    fi
    local LINKED
    LINKED="$(linked_ancestor "$BASE" "$REL")"
    if [ -n "$LINKED" ]; then
        report_linked_dir "$BASE" "$LINKED" Skipped written
        if [ "$UPDATE_REPORT" = true ] && [ -n "$RECORDED_BEFORE" ]; then UPDATE_KEPT_COUNT=$((UPDATE_KEPT_COUNT + 1)); fi
        return 0
    fi
    if [ -d "$DEST" ]; then
        # A folder where the package installs a file (Cline also reads a .clinerules/ folder of
        # rule files) is the user's: nothing is written into it, backed up or recorded (plan 045).
        printf '%b\n' "${YELLOW}  ! Skipped $REL — it is a directory, not a file (nothing was written into it)${NC}"
        if [ "$UPDATE_REPORT" = true ] && [ -n "$RECORDED_BEFORE" ]; then UPDATE_KEPT_COUNT=$((UPDATE_KEPT_COUNT + 1)); fi
        return 0
    fi
    if [ -e "$DEST" ] && [ ! -r "$DEST" ]; then
        # A file that cannot be read can be neither hashed nor backed up, so nothing proves it is
        # the package's own: it is left as it is, like a read-only one (plan 045).
        printf '%b\n' "${YELLOW}  ! Skipped $REL — destination cannot be read (existing file left untouched)${NC}"
        if [ "$UPDATE_REPORT" = true ] && [ -n "$RECORDED_BEFORE" ]; then UPDATE_KEPT_COUNT=$((UPDATE_KEPT_COUNT + 1)); fi
        return 0
    fi
    if [ -L "$DEST" ]; then
        # DEST is a symlink: never write through it (that would silently modify whatever
        # file it points at, outside the install tree). Back up the link target's content,
        # then replace the link itself with the package's file.
        local LINK_TARGET RESULT BACKUP
        LINK_TARGET="$(readlink "$DEST")"
        if [ -e "$DEST" ]; then
            RESULT="$(backup_dest "$BASE" "$ED" "$REL" "$DEST" "$SRC")" || return 1
            case "$RESULT" in
                ADOPTED)
                    printf '%b\n' "  i $REL is a symlink to $LINK_TARGET whose content matches an earlier release — updating (link target left untouched)"
                    ;;
                "BACKUP "*)
                    BACKUP="${RESULT#BACKUP }"
                    write_exclusive "$BACKUP.link-target" printf '%s\n' "$LINK_TARGET" \
                        || printf '%b\n' "${YELLOW}  ! Could not record the link target: $(basename "$BACKUP").link-target already exists${NC}"
                    printf '%b\n' "${YELLOW}  ! $REL is a symlink to $LINK_TARGET — its content was backed up to $(basename "$BACKUP") (link target left untouched)${NC}"
                    ;;
            esac
        else
            printf '%b\n' "${YELLOW}  ! $REL is a broken symlink to $LINK_TARGET — replacing with the package file${NC}"
        fi
        rm -f "$DEST"
    elif [ -f "$DEST" ]; then
        if [ ! -w "$DEST" ]; then
            # A read-only destination is a deliberate signal not to overwrite it: skip this
            # file and keep installing the rest of the tree instead of aborting under set -e
            # on a raw `cp: Permission denied`.
            printf '%b\n' "${YELLOW}  ! Skipped $REL — destination is read-only (existing file left untouched)${NC}"
            if [ "$UPDATE_REPORT" = true ]; then UPDATE_UPTODATE_COUNT=$((UPDATE_UPTODATE_COUNT + 1)); fi
            return 0
        fi
        local RESULT BACKUP
        RESULT="$(backup_dest "$BASE" "$ED" "$REL" "$DEST" "$SRC")" || return 1
        case "$RESULT" in
            ADOPTED)
                printf '%b\n' "  i $REL already existed and matches an earlier release — updating to the current version"
                ;;
            "BACKUP "*)
                BACKUP="${RESULT#BACKUP }"
                printf '%b\n' "${YELLOW}  ! $REL already existed and differs — backed up to $(basename "$BACKUP")${NC}"
                ;;
        esac
    fi
    mkdir -p "$(dirname "$DEST")"
    cp "$SRC" "$DEST"
    FILES_WRITTEN_COUNT=$((FILES_WRITTEN_COUNT + 1))
    local AFTER_HASH
    if ! AFTER_HASH="$(hash_file "$DEST")"; then
        printf '%b\n' "${YELLOW}  ! Installed $REL but could not read it back, so it is not recorded; uninstall will keep it${NC}"
        return 0
    fi
    manifest_record "$BASE" "$ED" "$REL" "$AFTER_HASH"
    if [ "$UPDATE_REPORT" = true ]; then
        if [ -n "$RECORDED_BEFORE" ] && [ -n "$BEFORE_HASH" ] && [ "$BEFORE_HASH" = "$AFTER_HASH" ]; then
            UPDATE_UPTODATE_COUNT=$((UPDATE_UPTODATE_COUNT + 1))
        else
            if [ -z "$RECORDED_BEFORE" ]; then
                printf '%b\n' "${GREEN}  ✓ Added $REL${NC}"
            elif [ -z "$BEFORE_HASH" ]; then
                printf '%b\n' "${GREEN}  ✓ Restored $REL (was missing)${NC}"
            else
                printf '%b\n' "${GREEN}  ✓ Refreshed $REL${NC}"
            fi
            UPDATE_CHANGED_COUNT=$((UPDATE_CHANGED_COUNT + 1))
        fi
    fi
    if [ -n "${QA_INSTINCT_DEBUG:-}" ]; then
        echo "  (debug) recorded $REL in $(manifest_file "$BASE")"
    fi
}

# A manifest path must stay inside the base it was recorded under. The manifest sits at the
# project root and is committed into consuming repositories, so its contents are
# attacker-controllable: an entry such as "../../../.ssh/config" would otherwise make uninstall
# delete a file outside the install tree. install_file refuses to *record* such a path; this
# refuses to act on one.
safe_manifest_rel() {   # rel -> 0 when the path stays inside its base
    case "$1" in
        ""|/*|../*|*/../*|*/..|..) return 1 ;;
        [A-Za-z]:*) return 1 ;;
    esac
    return 0
}

uninstall_recorded() {   # base editor — removes only recorded files that are unchanged
    local BASE="$1" ED="$2" MF HASH ENTRY_ED REL FILE BODY="" LINKED
    MF="$(manifest_file "$BASE")"
    [ -f "$MF" ] || return 0
    while read -r HASH ENTRY_ED REL; do
        if [ "$ENTRY_ED" != "$ED" ]; then
            BODY="$BODY$HASH  $ENTRY_ED  $REL"$'\n'
            continue
        fi
        if ! safe_manifest_rel "$REL"; then
            printf '%b\n' "${RED}  ✘ Refusing $REL — it points outside $BASE. The manifest may have been tampered with.${NC}" >&2
            BODY="$BODY$HASH  $ENTRY_ED  $REL"$'\n'
            continue
        fi
        LINKED="$(linked_ancestor "$BASE" "$REL")"
        if [ -n "$LINKED" ]; then
            # Kept, and still recorded: the file is not ours to delete through a link.
            report_linked_dir "$BASE" "$LINKED" Kept deleted
            BODY="$BODY$HASH  $ENTRY_ED  $REL"$'\n'
            UNINSTALL_KEPT_COUNT=$((UNINSTALL_KEPT_COUNT + 1))
            continue
        fi
        FILE="$BASE/$REL"
        if [ -d "$FILE" ]; then
            # Never hashed or deleted: a folder now stands where the file was installed.
            printf '%b\n' "${YELLOW}  ! Kept $REL — it is a directory now, not the file that was installed${NC}"
            old_location_note "$BASE" "$ED" "$REL"
            UNINSTALL_KEPT_COUNT=$((UNINSTALL_KEPT_COUNT + 1))
            continue
        fi
        [ -f "$FILE" ] || continue
        if [ ! -w "$FILE" ]; then
            # A writable parent directory would let `rm -f` delete a read-only file anyway;
            # treat read-only the same deliberate way on removal as on install and keep it.
            printf '%b\n' "${YELLOW}  ! Kept $REL — destination is read-only${NC}"
            UNINSTALL_KEPT_COUNT=$((UNINSTALL_KEPT_COUNT + 1))
        elif [ ! -r "$FILE" ]; then
            # Cannot be hashed, so nothing proves it is the package's: kept, for that reason and
            # not as "changed" (plan 053 I15).
            printf '%b\n' "${YELLOW}  ! Kept $REL — destination cannot be read${NC}"
            UNINSTALL_KEPT_COUNT=$((UNINSTALL_KEPT_COUNT + 1))
        elif file_matches "$FILE" "$HASH"; then
            rm -f "$FILE"
            UNINSTALL_REMOVED_COUNT=$((UNINSTALL_REMOVED_COUNT + 1))
            UNINSTALL_REMOVED_RELS="$UNINSTALL_REMOVED_RELS$REL"$'\n'
        else
            printf '%b\n' "${YELLOW}  ! Kept $REL — changed since it was installed${NC}"
            old_location_note "$BASE" "$ED" "$REL"
            UNINSTALL_KEPT_COUNT=$((UNINSTALL_KEPT_COUNT + 1))
        fi
    done < <(manifest_lines "$MF")
    manifest_write "$MF" "$BODY"
}

remove_if_matches() {    # base src dest — fallback for installs made before manifests existed
    local BASE="$1" SRC="$2" DEST="$3" LINKED
    LINKED="$(linked_ancestor "$BASE" "${DEST#"$BASE"/}")"
    if [ -n "$LINKED" ]; then
        report_linked_dir "$BASE" "$LINKED" Kept deleted
        if [ -e "$DEST" ]; then UNINSTALL_KEPT_COUNT=$((UNINSTALL_KEPT_COUNT + 1)); fi
        return 0
    fi
    [ -f "$DEST" ] || return 0
    if [ ! -r "$DEST" ]; then
        printf '%b\n' "${YELLOW}  ! Kept $DEST — destination cannot be read${NC}"
        UNINSTALL_KEPT_COUNT=$((UNINSTALL_KEPT_COUNT + 1))
        return 0
    fi
    if [ -f "$SRC" ] && file_matches "$DEST" "$(hash_file "$SRC")"; then
        rm -f "$DEST"
        UNINSTALL_REMOVED_COUNT=$((UNINSTALL_REMOVED_COUNT + 1))
        UNINSTALL_REMOVED_RELS="$UNINSTALL_REMOVED_RELS${DEST#"$BASE"/}"$'\n'
    else
        printf '%b\n' "${YELLOW}  ! Kept $DEST — not installed by this package, or changed since install${NC}"
        UNINSTALL_KEPT_COUNT=$((UNINSTALL_KEPT_COUNT + 1))
    fi
}

had_manifest() { [ -f "$(manifest_file "$1")" ]; }

# What a kept file at one of the locations plan 047 moved away from means for the editor. The
# package never deletes it for the user: .clinerules/default-rules.md is not a path it recorded.
old_location_note() {   # base editor rel
    case "$2:$3" in
        cline:.clinerules)
            [ -d "$1/.clinerules" ] && echo "    Cline moved the old rules to .clinerules/default-rules.md; delete that file if you no longer want them." ;;
        windsurf:.windsurfrules)
            echo "    Windsurf still loads .windsurfrules in every conversation; delete it if you no longer want it." ;;
        antigravity:.gemini/antigravity/skills/qa/SKILL.md)
            echo "    The Antigravity IDE lists two qa skills while it stays; delete it if you no longer want it." ;;
    esac
    return 0
}

report_uninstall_result() {   # label scope removed kept — prints what actually happened
    local LABEL="$1" SCOPE="$2" REMOVED="$3" KEPT="$4"
    if [ "$KEPT" -gt 0 ]; then
        printf '%b\n' "${YELLOW}  ! $LABEL ($SCOPE): partially uninstalled — removed $REMOVED file(s), kept $KEPT.${NC}"
    elif [ "$REMOVED" -eq 0 ]; then
        printf '%b\n' "${CYAN}  i $LABEL ($SCOPE): nothing to remove (not installed).${NC}"
    else
        printf '%b\n' "${GREEN}  ✓ $LABEL ($SCOPE): uninstalled.${NC}"
    fi
}

# Never through a link: a linked hooks folder was skipped by install_file, and a linked hook file
# is left as it is (plan 033 item 1).
make_hooks_executable() {   # base
    local BASE_DIR="$1" HOOK_FILE
    local TARGET_DIR="$BASE_DIR/.claude"
    if [ -d "$TARGET_DIR/hooks" ] && [ ! -L "$TARGET_DIR/hooks" ]; then
        for HOOK_FILE in "$TARGET_DIR/hooks"/*.sh; do
            if [ -L "$HOOK_FILE" ]; then
                printf '%b\n' "${YELLOW}  ! Skipped ${HOOK_FILE#"$BASE_DIR"/} — it is a symbolic link; its mode was not changed${NC}"
            elif [ -f "$HOOK_FILE" ]; then
                chmod +x "$HOOK_FILE" 2>/dev/null || true
            fi
        done
    fi
}

# A non-claude editor's install folder for a scope: its rules or its skills folder, "-" for none.
editor_folder() {   # editor scope rules|skills
    editor_map_field "$1" "$([ "$2" = global ] && echo global || echo project)-$3"
}

# Every "<package file><TAB><destination>" a non-claude editor's install writes (plan 047): each
# generated rule file of adapters/<editor>/rules/ into the rules folder, when the scope has one,
# and every file of adapters/skills/ below the skills folder. Nothing when the scope has no skills
# folder. Each editor has its own folders, so uninstalling one never removes another's files.
editor_files() {   # editor scope base
    local ED="$1" SCOPE="$2" BASE="$3" RULES SKILLS SRC_FILE
    RULES="$(editor_folder "$ED" "$SCOPE" rules)"
    SKILLS="$(editor_folder "$ED" "$SCOPE" skills)"
    [ -n "$SKILLS" ] && [ "$SKILLS" != "-" ] || return 0
    if [ -n "$RULES" ] && [ "$RULES" != "-" ]; then
        for SRC_FILE in "$ADAPTERS_DIR/$ED/rules"/*; do
            [ -f "$SRC_FILE" ] || continue
            printf '%s\t%s\n' "$SRC_FILE" "$BASE/$RULES/${SRC_FILE##*/}"
        done
    fi
    [ -d "$ADAPTERS_DIR/skills" ] || return 0
    local SKILLS_ONE SKILL_FILES
    SKILL_FILES="$(find "$ADAPTERS_DIR/skills" -type f | LC_ALL=C sort)"
    for SKILLS_ONE in ${SKILLS//,/ }; do
        while IFS= read -r SRC_FILE; do
            [ -n "$SRC_FILE" ] || continue
            printf '%s\t%s\n' "$SRC_FILE" "$BASE/$SKILLS_ONE/${SRC_FILE#"$ADAPTERS_DIR"/skills/}"
        done <<< "$SKILL_FILES"
    done
}

# editor_files read to its end, or not at all (plan 063). On macOS, bash 3.2 once handed a loop
# fed by `< <(editor_files ...)` only the start of the list, and the update removed the rest as
# no longer shipped. A command substitution reads all of the output, and its last line proves the
# list was not cut: a list without it is never acted on.
EDITOR_FILES_END="-- end of the file list --"
EDITOR_FILES_LIST=""
LIST_CUT=false
read_editor_files() {   # editor scope base — sets EDITOR_FILES_LIST; fails when the list is cut
    local LIST
    LIST="$(editor_files "$1" "$2" "$3"; printf '%s\n' "$EDITOR_FILES_END")"
    # Test seam: keep only this many lines, as the cut on macOS did (lifecycle Test 71).
    if [ -n "${QA_INSTINCT_TEST_CUT_LIST:-}" ]; then
        LIST="$(printf '%s\n' "$LIST" | head -n "$QA_INSTINCT_TEST_CUT_LIST")"
    fi
    case "$LIST" in
        "$EDITOR_FILES_END"|*$'\n'"$EDITOR_FILES_END") ;;
        *)
            printf '%b\n' "${RED}  ✘ Could not read the whole list of files this release ships for $(editor_map_field "$1" label); none of them was installed or removed. Run the installer again.${NC}" >&2
            LIST_CUT=true
            return 1 ;;
    esac
    EDITOR_FILES_LIST="${LIST%"$EDITOR_FILES_END"}"
}

# Prints "<package file><TAB><destination>" for every file an install of one editor writes.
package_files() {   # editor scope base
    local ED="$1" SCOPE="$2" BASE="$3" SUB SRC_FILE
    if [ "$ED" = claude ]; then
        for SUB in commands rules skills agents hooks; do
            [ -d "$SCRIPT_DIR/.claude/$SUB" ] || continue
            while IFS= read -r SRC_FILE; do
                printf '%s\t%s\n' "$SRC_FILE" "$BASE/.claude/${SRC_FILE#"$SCRIPT_DIR"/.claude/}"
            done < <(find "$SCRIPT_DIR/.claude/$SUB" -type f)
        done
        return 0
    fi
    editor_files "$ED" "$SCOPE" "$BASE"
}

# Update, the same in all three installers (plan 033 item 3). For an editor the manifest records:
# refresh its files and install the ones this release added (the install path), then remove each
# recorded file the package no longer ships if it is unchanged, keep and report it otherwise, and
# drop its entry either way. With no manifest at all, adopt only files whose hash a release
# shipped. An editor the manifest does not record is never installed.
UPDATE_NO_MANIFEST_BASES=""
update_to_editor() {   # editor scope base
    local ED="$1" SCOPE="$2" BASE="$3" MF
    MF="$(manifest_file "$BASE")"
    # Whether the base had a manifest is decided once per run: adopting one editor's files writes
    # a manifest, and the next editor must still be adopted, not skipped as "not recorded".
    if [ ! -f "$MF" ]; then UPDATE_NO_MANIFEST_BASES="$UPDATE_NO_MANIFEST_BASES|$BASE|"; fi
    if case "$UPDATE_NO_MANIFEST_BASES" in *"|$BASE|"*) false ;; *) true ;; esac; then
        manifest_lines "$MF" | awk -v ed="$ED" '$2 == ed { found = 1 } END { exit !found }' || return 0
        UPDATE_REPORT=true
        install_to_editor "$ED" "$SCOPE" "$BASE"
        UPDATE_REPORT=false
        prune_unshipped "$BASE" "$ED" "$SCOPE"
    else
        adopt_known "$ED" "$SCOPE" "$BASE"
    fi
}

prune_unshipped() {   # base editor scope
    local BASE="$1" ED="$2" SCOPE="$3" MF HASH ENTRY_ED REL SRC FILE LINKED BODY="" SHIPPED="" SHIPPED_REL
    MF="$(manifest_file "$BASE")"
    [ -f "$MF" ] || return 0
    # For a non-claude editor, "still shipped" is "a destination this install writes" (plan 047):
    # every other recorded path, the old merged adapters and .bem-te-vi/ included, is not.
    if [ "$ED" != claude ]; then
        # The manifest stays as it is, so the next update prunes from the whole list.
        read_editor_files "$ED" "$SCOPE" "$BASE" || return 0
        while IFS=$'\t' read -r _ SHIPPED_REL; do
            [ -n "$SHIPPED_REL" ] || continue
            SHIPPED="$SHIPPED${SHIPPED_REL#"$BASE"/}"$'\n'
        done <<< "$EDITOR_FILES_LIST"
        SHIPPED=$'\n'"$SHIPPED"
    fi
    while read -r HASH ENTRY_ED REL; do
        if [ "$ENTRY_ED" != "$ED" ]; then
            BODY="$BODY$HASH  $ENTRY_ED  $REL"$'\n'
            continue
        fi
        if ! safe_manifest_rel "$REL"; then
            printf '%b\n' "${RED}  ✘ Refusing $REL — it points outside $BASE. The manifest may have been tampered with.${NC}" >&2
            BODY="$BODY$HASH  $ENTRY_ED  $REL"$'\n'
            continue
        fi
        if [ "$ED" = claude ]; then
            SRC="$SCRIPT_DIR/.claude/${REL#.claude/}"
            if [ -f "$SRC" ]; then
                BODY="$BODY$HASH  $ENTRY_ED  $REL"$'\n'
                continue
            fi
        else
            case "$SHIPPED" in
                *$'\n'"$REL"$'\n'*)
                    BODY="$BODY$HASH  $ENTRY_ED  $REL"$'\n'
                    continue ;;
            esac
        fi
        LINKED="$(linked_ancestor "$BASE" "$REL")"
        if [ -n "$LINKED" ]; then
            # Kept, and still recorded: the file is not ours to delete through a link.
            report_linked_dir "$BASE" "$LINKED" Kept deleted
            BODY="$BODY$HASH  $ENTRY_ED  $REL"$'\n'
            UPDATE_KEPT_COUNT=$((UPDATE_KEPT_COUNT + 1))
            continue
        fi
        FILE="$BASE/$REL"
        if [ -d "$FILE" ]; then
            # Never hashed, entered or deleted (plan 047): Cline turns its .clinerules file into a
            # folder. Kept and forgotten, like any changed file the package stopped shipping.
            printf '%b\n' "${YELLOW}  ! Kept $REL — it is a directory now, not the file that was installed${NC}"
            old_location_note "$BASE" "$ED" "$REL"
            UPDATE_KEPT_COUNT=$((UPDATE_KEPT_COUNT + 1))
            continue
        fi
        [ -f "$FILE" ] || continue
        if [ ! -w "$FILE" ]; then
            printf '%b\n' "${YELLOW}  ! Kept $REL — destination is read-only${NC}"
            UPDATE_KEPT_COUNT=$((UPDATE_KEPT_COUNT + 1))
        elif [ ! -r "$FILE" ]; then
            printf '%b\n' "${YELLOW}  ! Kept $REL — destination cannot be read${NC}"
            UPDATE_KEPT_COUNT=$((UPDATE_KEPT_COUNT + 1))
        elif file_matches "$FILE" "$HASH"; then
            rm -f "$FILE"
            printf '%b\n' "${YELLOW}  - Removed $REL (no longer shipped)${NC}"
            UPDATE_CHANGED_COUNT=$((UPDATE_CHANGED_COUNT + 1))
            # Its folders go while they are empty, up to the base (plan 047); none is a link, as
            # linked_ancestor found none above.
            [ "$ED" = claude ] || remove_empty_ancestors "$(dirname "$FILE")" "$BASE"
        else
            printf '%b\n' "${YELLOW}  ! Kept $REL — changed since it was installed${NC}"
            old_location_note "$BASE" "$ED" "$REL"
            UPDATE_KEPT_COUNT=$((UPDATE_KEPT_COUNT + 1))
        fi
    done < <(manifest_lines "$MF")
    manifest_write "$MF" "$BODY"
}

# An install made before manifests existed: only a file identical to the package's current one,
# or whose hash a release shipped, is the package's, so only such a file is refreshed. Nothing
# is created.
adopt_known() {   # editor scope base
    local ED="$1" SCOPE="$2" BASE="$3" SRC_FILE DEST LINKED ADOPTED=false SRC_HASH DEST_HASH DEST_HASH_NOCR
    load_known_hashes
    while IFS=$'\t' read -r SRC_FILE DEST; do
        LINKED="$(linked_ancestor "$BASE" "${DEST#"$BASE"/}")"
        if [ -n "$LINKED" ]; then
            if [ -e "$DEST" ]; then
                report_linked_dir "$BASE" "$LINKED" Skipped written
                UPDATE_KEPT_COUNT=$((UPDATE_KEPT_COUNT + 1))
            fi
            continue
        fi
        [ -f "$DEST" ] || continue
        # A file that cannot be hashed is not proven to be the package's, so it is not adopted.
        SRC_HASH="$(hash_file "$SRC_FILE")" || continue
        DEST_HASH="$(hash_file "$DEST")" || continue
        DEST_HASH_NOCR="$(hash_file_without_cr "$DEST")" || continue
        [ "$DEST_HASH" = "$SRC_HASH" ] || [ "$DEST_HASH_NOCR" = "$SRC_HASH" ] \
            || known_hash "$DEST_HASH" || known_hash "$DEST_HASH_NOCR" || continue
        install_file "$BASE" "$ED" "$SRC_FILE" "$DEST"
        printf '%b\n' "${GREEN}  ✓ Adopted ${DEST#"$BASE"/}${NC}"
        UPDATE_CHANGED_COUNT=$((UPDATE_CHANGED_COUNT + 1))
        ADOPTED=true
    done < <(package_files "$ED" "$SCOPE" "$BASE")
    if [ "$ADOPTED" = true ] && [ "$ED" = claude ]; then make_hooks_executable "$BASE"; fi
}

# Install, or update when --update was given.
deploy_to_editor() {   # editor scope base
    migrate_manifest "$3"
    if [ "$OPERATION" = update ]; then update_to_editor "$@"; else install_to_editor "$@"; fi
}

install_to_editor() {
    local EDITOR_NAME="$1"    # claude|cursor|windsurf|copilot|cline
    local SCOPE="$2"          # project|global
    local BASE_DIR="$3"       # base directory (project dir or $HOME)
    local WRITTEN_BEFORE="$FILES_WRITTEN_COUNT"

    case "$EDITOR_NAME" in
        claude)
            local TARGET_DIR="$BASE_DIR/.claude"
            local TARGET_PATH="$TARGET_DIR/commands/qa.md"
            if check_version_conflict "$TARGET_PATH"; then
                # A linked folder, even one whose target is missing, is never created through: it
                # is skipped file by file below, and reported there (plan 033 item 1).
                for SUB in rules commands skills agents hooks; do
                    [ -L "$TARGET_DIR/$SUB" ] || mkdir -p "$TARGET_DIR/$SUB"
                done
                
                # Copy all files
                for SUB in commands rules skills agents hooks; do
                    [ -d "$SCRIPT_DIR/.claude/$SUB" ] || continue
                    while IFS= read -r SRC_FILE; do
                        install_file "$BASE_DIR" claude "$SRC_FILE" "$TARGET_DIR/${SRC_FILE#"$SCRIPT_DIR"/.claude/}"
                    done < <(find "$SCRIPT_DIR/.claude/$SUB" -type f)
                done
                make_hooks_executable "$BASE_DIR"

                # Every file skipped (linked folders, read-only files): nothing to report installed.
                if [ "$FILES_WRITTEN_COUNT" -gt "$WRITTEN_BEFORE" ]; then
                    printf '%b\n' "${GREEN}  ✓ Claude Code ($SCOPE): $TARGET_DIR/ (scaffolded rules, commands, skills, agents, and hooks)${NC}"
                fi
                
                # Register Git Hook
                register_git_hook "$SCOPE" "$BASE_DIR"
            fi
            ;;
        *)
            # Every other editor: its generated rule files and the Agent Skills tree, installed in
            # the folders the shared mapping in $EDITOR_MAP_FILE names (plan 047).
            local RULES_REL SKILLS_REL LABEL WHERE SEP PKG_SRC PKG_DEST
            RULES_REL="$(editor_folder "$EDITOR_NAME" "$SCOPE" rules)"
            SKILLS_REL="$(editor_folder "$EDITOR_NAME" "$SCOPE" skills)"
            LABEL="$(editor_map_field "$EDITOR_NAME" label)"
            if [ "$SKILLS_REL" = "-" ]; then
                printf '%b\n' "${YELLOW}  ⚠ $LABEL only supports project-level install — skipping global.${NC}"
                return 0
            fi
            if ! check_adapter_exists "$ADAPTERS_DIR/skills/qa/SKILL.md"; then return 0; fi
            # The first skills folder stands for the install when asking about an existing one.
            if check_version_conflict "$BASE_DIR/${SKILLS_REL%%,*}/qa/SKILL.md"; then
                read_editor_files "$EDITOR_NAME" "$SCOPE" "$BASE_DIR" || return 0
                while IFS=$'\t' read -r PKG_SRC PKG_DEST; do
                    [ -n "$PKG_SRC" ] || continue
                    install_file "$BASE_DIR" "$EDITOR_NAME" "$PKG_SRC" "$PKG_DEST"
                done <<< "$EDITOR_FILES_LIST"
                SEP='/ and '
                WHERE="${SKILLS_REL//,/$SEP}/"
                [ "$RULES_REL" = "-" ] || WHERE="$RULES_REL/ and $WHERE"
                if [ "$FILES_WRITTEN_COUNT" -gt "$WRITTEN_BEFORE" ]; then
                    printf '%b\n' "${GREEN}  ✓ $LABEL ($SCOPE): $WHERE${NC}"
                fi
            fi
            ;;
    esac
}

# ─── Helper: purge Git hooks ─────────────────────────────────────────────────

purge_git_hook() {
    local SCOPE="$1"        # project|global
    local BASE_DIR="$2"     # project path or $HOME

    if [ "$SCOPE" = "project" ]; then
        # The hooks directory git reports, and the plain .git/hooks an earlier release wrote to.
        local HOOK_FILE HOOK_DIR
        for HOOK_DIR in "$(project_hooks_dir "$BASE_DIR" || true)" "$BASE_DIR/.git/hooks"; do
            [ -n "$HOOK_DIR" ] || continue
            HOOK_FILE="$HOOK_DIR/pre-commit"
            if [ -f "$HOOK_FILE" ] && [ ! -L "$HOOK_FILE" ]; then
                if grep -qF -e "$PROJECT_HOOK_MARKER" -e "$PROJECT_HOOK_OLD_MARKER" "$HOOK_FILE"; then
                    rm -f "$HOOK_FILE"
                    printf '%b\n' "${GREEN}  ✓ Purged project-level git pre-commit hook: $HOOK_FILE${NC}"
                fi
            fi
        done
    else
        # Global registration
        local GLOBAL_HOOKS_DIR="$HOME/.git-templates/hooks"
        local EXISTING_HOOKS_PATH
        EXISTING_HOOKS_PATH=$(git config --global core.hooksPath || echo "")
        
        if [ -n "$EXISTING_HOOKS_PATH" ]; then
            EXISTING_HOOKS_PATH="${EXISTING_HOOKS_PATH/#\~/$HOME}"
            GLOBAL_HOOKS_DIR="$EXISTING_HOOKS_PATH"
        fi
        
        local HOOK_FILE="$GLOBAL_HOOKS_DIR/pre-commit"
        if [ -f "$HOOK_FILE" ] && [ ! -L "$HOOK_FILE" ]; then
            if grep -q "validate-tc-format.sh" "$HOOK_FILE"; then
                # Strip only our own block, leaving every other line of the hook as it was.
                local STRIPPED STRIP_STATUS=0
                STRIPPED="$(mktemp "${TMPDIR:-/tmp}/qa-hook.XXXXXX")"
                strip_global_hook_block "$HOOK_FILE" > "$STRIPPED" || STRIP_STATUS=$?
                if [ "$STRIP_STATUS" -eq 0 ]; then
                    cat "$STRIPPED" > "$HOOK_FILE"
                    printf '%b\n' "${GREEN}  ✓ Cleaned global git pre-commit hook: $HOOK_FILE${NC}"

                    # Remove if nothing is left but the shebang and our own header comments
                    if ! grep -qvE "^(#!.*|$GLOBAL_HOOK_FRESH_HEADER|$GLOBAL_HOOK_OLD_FRESH_HEADER|$GLOBAL_HOOK_OLD_END|[[:space:]]*)\$" "$HOOK_FILE"; then
                        rm -f "$HOOK_FILE"
                        printf '%b\n' "${CYAN}  i Removed empty global hook file.${NC}"
                    fi
                else
                    printf '%b\n' "${YELLOW}  ! Kept global pre-commit hook — could not find the block QA Instinct added: $HOOK_FILE${NC}"
                fi
                rm -f "$STRIPPED"
            fi
        fi
    fi
}

# ─── Helper: uninstall from a specific editor path ──────────────────────────

# Whether a base had a manifest is decided once per run, before any editor is uninstalled from it,
# as update and the CLI decide it: an earlier editor's uninstall can empty and delete the manifest,
# and the next editor must not then take the base for an install made before manifests existed.
UNINSTALL_SEEN_BASES=""
UNINSTALL_NO_MANIFEST_BASES=""
note_uninstall_base() {   # base
    case "$UNINSTALL_SEEN_BASES" in *"|$1|"*) return 0 ;; esac
    UNINSTALL_SEEN_BASES="$UNINSTALL_SEEN_BASES|$1|"
    had_manifest "$1" || UNINSTALL_NO_MANIFEST_BASES="$UNINSTALL_NO_MANIFEST_BASES|$1|"
}
base_had_manifest() {   # base -> success when it had a manifest when this run first reached it
    case "$UNINSTALL_NO_MANIFEST_BASES" in *"|$1|"*) return 1 ;; esac
    return 0
}

uninstall_from_editor() {
    local EDITOR_NAME="$1"    # claude|cursor|windsurf|copilot|cline|antigravity
    local SCOPE="$2"          # project|global
    local BASE_DIR="$3"       # base directory (project dir or $HOME)
    local ED_REMOVED_START=$UNINSTALL_REMOVED_COUNT
    local ED_KEPT_START=$UNINSTALL_KEPT_COUNT
    migrate_manifest "$BASE_DIR"
    note_uninstall_base "$BASE_DIR"

    case "$EDITOR_NAME" in
        claude)
            local TARGET_DIR="$BASE_DIR/.claude"
            printf '%b\n' "${CYAN}  Removing Claude Code files...${NC}"
            
            # Remove only what was installed and is still unchanged (see the manifest helpers).
            # Files the project added or edited are kept, and reported.
            UNINSTALL_REMOVED_RELS=""
            if base_had_manifest "$BASE_DIR"; then
                uninstall_recorded "$BASE_DIR" claude
            else
                # Installed before manifests existed: fall back to removing files whose content
                # still matches the package's current copy.
                uninstall_recorded "$BASE_DIR" claude
                for SUB in commands rules skills agents hooks; do
                    [ -d "$SCRIPT_DIR/.claude/$SUB" ] || continue
                    while IFS= read -r SRC_FILE; do
                        remove_if_matches "$BASE_DIR" "$SRC_FILE" "$TARGET_DIR/${SRC_FILE#"$SCRIPT_DIR"/.claude/}"
                    done < <(find "$SCRIPT_DIR/.claude/$SUB" -type f)
                done
            fi
            
            # The folders this run emptied, up to the base and never inside a linked one: those of
            # each file it removed and, when it removed any, the package's five folders and
            # .claude. A folder it did not empty stays, even an empty one under .claude/skills/
            # (plan 061 L1, plan 047's rule for the other editors).
            if [ -n "$UNINSTALL_REMOVED_RELS" ]; then
                local REL SUB
                while IFS= read -r REL; do
                    if [ -z "$REL" ] || ! safe_manifest_rel "$REL"; then continue; fi
                    [ -z "$(linked_ancestor "$BASE_DIR" "$REL")" ] || continue
                    remove_empty_ancestors "$(dirname "$BASE_DIR/$REL")" "$BASE_DIR"
                done < <(printf '%s' "$UNINSTALL_REMOVED_RELS"; for SUB in commands rules skills agents hooks; do printf '.claude/%s/-\n' "$SUB"; done)
            fi
            
            report_uninstall_result "Claude Code" "$SCOPE" "$((UNINSTALL_REMOVED_COUNT - ED_REMOVED_START))" "$((UNINSTALL_KEPT_COUNT - ED_KEPT_START))"

            # Purge Git Hook
            purge_git_hook "$SCOPE" "$BASE_DIR"
            ;;
        *)
            # Every other editor: every file the manifest records for it, wherever it is (the
            # folders of plan 047 and the paths of earlier releases alike), then the folders those
            # removals left empty. Editors with no global skills folder are never installed there.
            # With no manifest there is nothing to remove: unlike Claude Code's, these
            # destinations were never written without one, and the package's older files here
            # are not in .qa-instinct-known-hashes, so a match could only be a copy the user made
            # (plan 047, review of #193).
            local LABEL REL PKG_DEST
            LABEL="$(editor_map_field "$EDITOR_NAME" label)"
            [ "$(editor_folder "$EDITOR_NAME" "$SCOPE" skills)" = "-" ] && return 0
            UNINSTALL_REMOVED_RELS=""
            uninstall_recorded "$BASE_DIR" "$EDITOR_NAME"
            # The folders this run emptied, up to the base and never inside a linked one: those of
            # each file it removed and, when it removed any, the package's own folders of this
            # editor. A folder of an editor with nothing removed is never touched (plan 047).
            if [ -n "$UNINSTALL_REMOVED_RELS" ]; then
                while IFS= read -r REL; do
                    if [ -z "$REL" ] || ! safe_manifest_rel "$REL"; then continue; fi
                    [ -z "$(linked_ancestor "$BASE_DIR" "$REL")" ] || continue
                    remove_empty_ancestors "$(dirname "$BASE_DIR/$REL")" "$BASE_DIR"
                done < <(printf '%s' "$UNINSTALL_REMOVED_RELS"; editor_files "$EDITOR_NAME" "$SCOPE" "$BASE_DIR" | while IFS=$'\t' read -r _ PKG_DEST; do printf '%s\n' "${PKG_DEST#"$BASE_DIR"/}"; done)
            fi
            report_uninstall_result "$LABEL" "$SCOPE" "$((UNINSTALL_REMOVED_COUNT - ED_REMOVED_START))" "$((UNINSTALL_KEPT_COUNT - ED_KEPT_START))"
            ;;
    esac
}

# ─── Helper: git commit + optional push (Claude Code project files) ─────────

git_commit_and_push() {
    # .git is a folder in a plain clone and a file in a worktree or submodule.
    if [ -d .git ] || [ -f .git ]; then
        echo ""
        if [ "$NON_INTERACTIVE" = true ]; then
            echo "Non-interactive mode: skipping git commit."
            return 0
        fi
        yes_no "Add to git and commit? (y/n): " n
        if [ "$YES_NO_ANSWER" = "y" ]; then
            # Commit only what the installer wrote: the paths in the project manifest, plus the
            # manifest itself. Whatever else the user has staged or edited stays out of the commit.
            # A manifest path that leaves the project (the manifest is committed, so it can be
            # tampered with) never reaches git add.
            local MANIFEST PATHS=() HASH ENTRY_ED REL
            MANIFEST="$(manifest_file "$(pwd)")"
            while read -r HASH ENTRY_ED REL; do
                safe_manifest_rel "$REL" && [ -e "$REL" ] && PATHS+=("$REL")
            done < <(manifest_lines "$MANIFEST")
            [ -e "$MANIFEST" ] && PATHS+=("$(basename "$MANIFEST")")
            # A manifest moved from its 4.x name: commit the old name's removal with it (plan 066).
            if [ ! -e "$(legacy_manifest_file "$(pwd)")" ] \
                && git ls-files --error-unmatch -- "$(basename "$(legacy_manifest_file "$(pwd)")")" >/dev/null 2>&1; then
                PATHS+=("$(basename "$(legacy_manifest_file "$(pwd)")")")
            fi

            if [ "${#PATHS[@]}" -gt 0 ] \
                && git add -- "${PATHS[@]}" \
                && git commit -m "Add/update QA skill for AI-assisted editors (ISTQB CTFL v4.0)" -- "${PATHS[@]}"; then
                printf '%b\n' "${GREEN}✓ Committed to git${NC}"

                yes_no "Push to remote? (y/n): " n
                if [ "$YES_NO_ANSWER" = "y" ]; then
                    # Only the current branch's upstream, never every remote.
                    if git push; then
                        printf '%b\n' "${GREEN}✓ Pushed${NC}"
                    else
                        printf '%b\n' "${RED}✘ Push failed (does this branch have an upstream?)${NC}"
                    fi
                fi
            else
                printf '%b\n' "${RED}✘ Nothing was committed (see the git output above)${NC}"
            fi
        fi
    fi
}

# ─── Post-install hint ───────────────────────────────────────────────────────

# Lists what the package ships, read from its own .claude/ at run time, so a new command, skill
# or agent shows up here with no edit. The same block in install.ps1 and cli/qa-instinct.js (plan 033
# item 8). Rules are counted, not named.
print_claude_hint() {
    local CLAUDE_SRC="$SCRIPT_DIR/.claude" COMMANDS SKILLS AGENTS RULES
    COMMANDS="$(find "$CLAUDE_SRC/commands" -mindepth 1 -maxdepth 1 -type f -name 'qa-*.md' | sed -e 's|.*/||' -e 's/\.md$//' -e 's|^|/|' | LC_ALL=C sort | tr '\n' ' ')"
    SKILLS="$(find "$CLAUDE_SRC/skills" -mindepth 1 -maxdepth 1 -type d | sed 's|.*/||' | LC_ALL=C sort | tr '\n' ' ')"
    AGENTS="$(find "$CLAUDE_SRC/agents" -mindepth 1 -maxdepth 1 -type f -name '*.md' | sed -e 's|.*/||' -e 's/\.md$//' | LC_ALL=C sort | tr '\n' ' ')"
    RULES="$(find "$CLAUDE_SRC/rules" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
    echo "  Claude Code : type /qa to start"
    echo "              : commands : ${COMMANDS% }"
    echo "              : skills   : ${SKILLS% }"
    echo "              : agents   : ${AGENTS% }"
    echo "              : rules    : $RULES files in .claude/rules/ (always loaded)"
}

# ─── Menus ───────────────────────────────────────────────────────────────────

# menu_choice <prompt> <default> <valid choice>...: asks until the answer is one of the valid
# choices, as install.ps1's Read-UserChoice does, and leaves it in MENU_ANSWER. An empty answer
# takes the default; so does the end of input, where install.ps1's Read-Host returns nothing, so
# piped answers that run out never end the run (plan 037, decided 2026-10-18).
menu_choice() {
    local PROMPT="$1" DEFAULT="$2" ANSWER CHOICE VALID
    shift 2
    VALID="$*"
    while true; do
        ANSWER=""
        read -r -p "$PROMPT" ANSWER || true
        ANSWER="${ANSWER:-$DEFAULT}"
        for CHOICE in "$@"; do
            if [ "$ANSWER" = "$CHOICE" ]; then
                MENU_ANSWER="$ANSWER"
                return 0
            fi
        done
        printf '%b\n' "${RED}Invalid choice '$ANSWER'. Valid options: ${VALID// /, }${NC}"
    done
}

# ─── Operation mode selection ────────────────────────────────────────────────

OPERATION="install" # default
if [ "$UPDATE_FLAG" = true ]; then
    OPERATION="update"
elif [ "$UNINSTALL_FLAG" = true ]; then
    OPERATION="uninstall"
elif [ "$NON_INTERACTIVE" = true ]; then
    OPERATION="install"
else
    echo "QA Instinct - Lifecycle Manager"
    echo "1. Install (Fresh deployment of QA Instinct)"
    echo "2. Update (Pull latest versions of all rules and commands)"
    echo "3. Uninstall / Remove (Purge all copied files & clean up git hooks)"
    echo ""
    menu_choice "Choose action (1/2/3) [1]: " 1 1 2 3
    case "$MENU_ANSWER" in
        1) OPERATION="install" ;;
        2) OPERATION="update" ;;
        3) OPERATION="uninstall" ;;
    esac
    echo ""
fi

# ─── Installation scope selection ────────────────────────────────────────────

if [ -n "$TARGET_FLAG" ]; then
    case "$TARGET_FLAG" in
        project) OPTION="1" ;;
        global)  OPTION="2" ;;
        both)    OPTION="3" ;;
    esac
elif [ "$NON_INTERACTIVE" = true ]; then
    OPTION="1"   # default: project
else
    echo "Installation Options:"
    echo "1. Project-level (current project only)"
    echo "2. Global (all projects)"
    echo "3. Both"
    echo ""
    menu_choice "Choose option (1/2/3) [1]: " 1 1 2 3
    OPTION="$MENU_ANSWER"
fi

# Validate input
if [[ ! "$OPTION" =~ ^[123]$ ]]; then
    printf '%b\n' "${RED}Invalid option '$OPTION'. Please enter 1, 2, or 3. Exiting.${NC}"
    exit 1
fi

# ─── Editor selection ────────────────────────────────────────────────────────

EDITORS=()

if [ -n "$EDITOR_FLAG" ]; then
    if [ "$EDITOR_FLAG" = "all" ]; then
        EDITORS=(claude cursor windsurf copilot cline antigravity)
    else
        EDITORS=("$EDITOR_FLAG")
    fi
elif [ "$OPERATION" = update ]; then
    # No editor named: every editor, with no menu, as the CLI's update; update_to_editor skips an
    # editor the manifest does not record, so only what is installed is refreshed (plan 061 B1).
    EDITORS=(claude cursor windsurf copilot cline antigravity)
elif [ "$NON_INTERACTIVE" = true ]; then
    EDITORS=(claude)   # default: Claude Code
else
    echo ""
    echo "Editor to install for:"
    echo "1. Claude Code — CLI & VS Code extension (default)"
    echo "2. Cursor / Trae"
    echo "3. Windsurf"
    echo "4. GitHub Copilot (VS Code)"
    echo "5. Cline (VS Code)"
    echo "6. Antigravity (Google)"
    echo "7. All editors"
    echo ""
    menu_choice "Choose editor (1-7) [1]: " 1 1 2 3 4 5 6 7

    case "$MENU_ANSWER" in
        1) EDITORS=(claude)   ;;
        2) EDITORS=(cursor)   ;;
        3) EDITORS=(windsurf)  ;;
        4) EDITORS=(copilot)   ;;
        5) EDITORS=(cline)     ;;
        6) EDITORS=(antigravity) ;;
        7) EDITORS=(claude cursor windsurf copilot cline antigravity) ;;
    esac
fi

# ─── Perform action ──────────────────────────────────────────────────────────

echo ""

run_lifecycle_action() {
    local ACTION="$1"
    local SCOPE_OPT="$2"
    
    case $SCOPE_OPT in
        1)
            if [ "$ACTION" = "uninstall" ]; then
                printf '%b\n' "${YELLOW}Uninstalling from current project...${NC}"
                for EDITOR in "${EDITORS[@]}"; do
                    uninstall_from_editor "$EDITOR" "project" "$(pwd)"
                done
            else
                printf '%b\n' "${YELLOW}Deploying to current project (mode: $ACTION)...${NC}"
                for EDITOR in "${EDITORS[@]}"; do
                    deploy_to_editor "$EDITOR" "project" "$(pwd)"
                done
                git_commit_and_push
            fi
            ;;
        2)
            if [ "$ACTION" = "uninstall" ]; then
                printf '%b\n' "${YELLOW}Uninstalling globally...${NC}"
                for EDITOR in "${EDITORS[@]}"; do
                    uninstall_from_editor "$EDITOR" "global" "$HOME"
                done
            else
                printf '%b\n' "${YELLOW}Deploying globally (mode: $ACTION)...${NC}"
                for EDITOR in "${EDITORS[@]}"; do
                    deploy_to_editor "$EDITOR" "global" "$HOME"
                done
            fi
            ;;
        3)
            if [ "$ACTION" = "uninstall" ]; then
                printf '%b\n' "${YELLOW}Uninstalling from both locations...${NC}"
                echo ""
                printf '%b\n' "${CYAN}── Project-level ──${NC}"
                for EDITOR in "${EDITORS[@]}"; do
                    uninstall_from_editor "$EDITOR" "project" "$(pwd)"
                done
                echo ""
                printf '%b\n' "${CYAN}── Global ──${NC}"
                for EDITOR in "${EDITORS[@]}"; do
                    uninstall_from_editor "$EDITOR" "global" "$HOME"
                done
            else
                printf '%b\n' "${YELLOW}Deploying to both locations (mode: $ACTION)...${NC}"
                echo ""
                printf '%b\n' "${CYAN}── Project-level ──${NC}"
                for EDITOR in "${EDITORS[@]}"; do
                    deploy_to_editor "$EDITOR" "project" "$(pwd)"
                done
                echo ""
                printf '%b\n' "${CYAN}── Global ──${NC}"
                for EDITOR in "${EDITORS[@]}"; do
                    deploy_to_editor "$EDITOR" "global" "$HOME"
                done
                git_commit_and_push
            fi
            ;;
    esac
}

run_lifecycle_action "$OPERATION" "$OPTION"

# ─── WSL: offer Windows-side installation / uninstallation ─────────────────

if [ "$IS_WSL" = true ]; then
    echo ""
    INSTALL_WIN=false
    if [ "$NON_INTERACTIVE" = true ]; then
        echo "WSL detected. Non-interactive mode: skipping Windows-side operations."
    else
        printf '%b\n' "${CYAN}WSL detected.${NC}"
        if [ "$OPERATION" = "uninstall" ]; then
            yes_no "Also uninstall from Windows-side user profile? (y/n) [n]: " n
        else
            yes_no "Also install to Windows-side user profile? (y/n) [n]: " n
        fi
        if [ "$YES_NO_ANSWER" = "y" ]; then
            INSTALL_WIN=true
        fi
    fi

    if [ "$INSTALL_WIN" = true ]; then
        # A failing cmd.exe or wslpath must reach the message below, not end the run under set -e.
        WIN_HOME=$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')" 2>/dev/null) || WIN_HOME=""
        if [ -z "$WIN_HOME" ] || [ ! -d "$WIN_HOME" ]; then
            printf '%b\n' "${RED}Error: could not resolve Windows home directory.${NC}"
            echo "Tried: wslpath of %USERPROFILE%"
        else
            if [ "$OPERATION" = "uninstall" ]; then
                printf '%b\n' "${YELLOW}Uninstalling from Windows profile: $WIN_HOME${NC}"
                for EDITOR in "${EDITORS[@]}"; do
                    uninstall_from_editor "$EDITOR" "global" "$WIN_HOME"
                done
                printf '%b\n' "${GREEN}✓ Windows-side uninstallation complete.${NC}"
            else
                printf '%b\n' "${YELLOW}Installing to Windows profile: $WIN_HOME${NC}"
                GLOBAL_HOOK_SET_UP=false
                for EDITOR in "${EDITORS[@]}"; do
                    deploy_to_editor "$EDITOR" "global" "$WIN_HOME"
                done
                printf '%b\n' "${GREEN}✓ Windows-side installation complete.${NC}"
                # The global hook is registered with this side's git (its $HOME), never with
                # Windows-side git; install.ps1 registers it there (plan 014 A3, Marco 2026-10-20).
                if [ "$GLOBAL_HOOK_SET_UP" = true ]; then
                    printf '%b\n' "${YELLOW}  ⚠ The pre-commit hook is not active for Windows-side git.${NC}"
                    printf '%b\n' "${CYAN}      To set it up there, run install.ps1 from Windows PowerShell.${NC}"
                fi
            fi
        fi
    fi
fi

# ─── Done ────────────────────────────────────────────────────────────────────

echo ""
echo "════════════════════════════════════════════════"
echo ""

if [ "$OPERATION" = "uninstall" ]; then
    if [ "$UNINSTALL_KEPT_COUNT" -gt 0 ]; then
        printf '%b\n' "${YELLOW}Uninstallation finished with some files kept.${NC}"
        echo "Removed $UNINSTALL_REMOVED_COUNT file(s); kept $UNINSTALL_KEPT_COUNT (see warnings above)."
    elif [ "$UNINSTALL_REMOVED_COUNT" -eq 0 ]; then
        printf '%b\n' "${CYAN}Nothing to uninstall.${NC}"
        echo "No QA Instinct files were found installed."
    else
        printf '%b\n' "${GREEN}Uninstallation successful!${NC}"
        echo "QA Instinct has been completely removed. Removed $UNINSTALL_REMOVED_COUNT file(s)."
    fi
elif [ "$OPERATION" = "update" ]; then
    UPDATE_TOTAL=$((UPDATE_CHANGED_COUNT + UPDATE_UPTODATE_COUNT + UPDATE_KEPT_COUNT))
    if [ "$LIST_CUT" = true ]; then
        printf '%b\n' "${RED}Update incomplete — see above, and run the update again.${NC}"
    elif [ "$UPDATE_TOTAL" -eq 0 ]; then
        printf '%b\n' "${CYAN}Nothing installed — run the installer without --update first.${NC}"
    elif [ "$UPDATE_KEPT_COUNT" -gt 0 ]; then
        printf '%b\n' "${YELLOW}Update complete — $UPDATE_KEPT_COUNT file(s) kept as-is (see above).${NC}"
    elif [ "$UPDATE_CHANGED_COUNT" -eq 0 ]; then
        printf '%b\n' "${GREEN}Everything is up to date.${NC}"
    else
        printf '%b\n' "${GREEN}Update complete.${NC}"
    fi
elif [ "$FILES_WRITTEN_COUNT" -eq 0 ]; then
    # Every destination was skipped (linked, a folder, unreadable or read-only): nothing to use.
    printf '%b\n' "${YELLOW}Nothing was installed: every destination was skipped (see above).${NC}"
else
    printf '%b\n' "${GREEN}Installation successful!${NC}"
    echo ""
    echo "Next steps:"
    # A global install writes rules for Claude Code and Cline only; the other editors get skills.
    if [ "$OPTION" = "2" ]; then
        RULES_HINT="skills only (a global install writes no rules)"
        COPILOT_RULES_HINT="$RULES_HINT"
    else
        RULES_HINT="qa-instinct rules always on"
        COPILOT_RULES_HINT="rules in .github/copilot-instructions.md"
    fi
    for EDITOR in "${EDITORS[@]}"; do
        case "$EDITOR" in
            claude)
                print_claude_hint
                ;;
            cursor)
                echo "  Cursor/Trae : $RULES_HINT; every command, skill and agent is a skill (/qa-cases)"
                ;;
            windsurf)
                echo "  Windsurf    : $RULES_HINT; every command, skill and agent is a skill (@qa-cases)"
                ;;
            copilot)
                echo "  Copilot     : $COPILOT_RULES_HINT; every command, skill and agent is a skill (/qa-cases)"
                ;;
            cline)
                echo "  Cline       : qa-instinct rules always on; every command, skill and agent is a skill (/qa-cases)"
                ;;
            antigravity)
                echo "  Antigravity : $RULES_HINT; every command, skill and agent is a skill (ask for qa-cases)"
                # Antigravity's launcher in a plain WSL terminal opens a Windows window whose agent
                # cannot read the folder; a WSL window works (plan 062).
                if [ -n "${WSL_DISTRO_NAME:-}" ]; then
                    if [ "$OPTION" = "2" ]; then WSL_FOLDER="<folder>"; else WSL_FOLDER="$(pwd -P)"; fi
                    echo "              : in WSL, open the folder in a WSL window: antigravity-ide --remote wsl+$WSL_DISTRO_NAME $WSL_FOLDER"
                fi
                ;;
        esac
    done
    echo ""
    echo "Documentation:"
    echo "- Full guide: cat $SCRIPT_DIR/README.md"
    echo "- Examples: cat $SCRIPT_DIR/examples/README.md"
fi
echo ""
echo "════════════════════════════════════════════════"

# A file list read only in part (plan 063): what it covers was left as it was, and the run failed.
[ "$LIST_CUT" = false ] || exit 1
