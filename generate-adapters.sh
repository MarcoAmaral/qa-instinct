#!/usr/bin/env bash
# generate-adapters.sh — Generate every non-Claude editor's files from the modular .claude/ sources
# (plan 047): each editor's always-on rule files, one Agent Skills tree all of them share, and the
# universal AGENTS.md and CLAUDE.md. generate-adapters.ps1 writes the same bytes.

set -euo pipefail

# Byte order for every glob and sort, so the output comes out identical whatever the locale
# (en_US collation ignores hyphens) and identical to generate-adapters.ps1's ordinal sort.
export LC_COLLATE=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$SCRIPT_DIR/.claude"
OUT_DIR="$SCRIPT_DIR/adapters"

# --- Flags -------------------------------------------------------------------
CLEAN=false
OPT_NO_COLOR=false
for arg in "$@"; do
  case "$arg" in
    --clean)    CLEAN=true ;;
    --no-color) OPT_NO_COLOR=true ;;
    -h|--help)
      echo "Usage: $(basename "$0") [--clean] [--no-color]"
      echo "  --clean     Remove adapters/ directory before generating"
      echo "  --no-color  Disable colored output"
      exit 0 ;;
    *) echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

# --- Colors -------------------------------------------------------------------
# Colour is on for a human at a terminal, off when piped or redirected.
# GITHUB_ACTIONS is checked because Actions is not a TTY but its log viewer
# does render ANSI — without it, CI logs would lose all colour.
use_colour() {
    [ -n "${NO_COLOR:-}" ] && return 1
    [ -n "${FORCE_COLOR:-}" ] && return 0
    [ -n "${GITHUB_ACTIONS:-}" ] && return 0
    [ -t 1 ]
}

if [[ "$OPT_NO_COLOR" == true ]]; then
  GREEN="" YELLOW="" RED="" RESET=""
elif use_colour; then
  GREEN="\033[0;32m" YELLOW="\033[0;33m" RED="\033[0;31m" RESET="\033[0m"
else
  GREEN="" YELLOW="" RED="" RESET=""
fi

info()    { printf "${YELLOW}[INFO]${RESET}  %s\n" "$1"; }
success() { printf "${GREEN}[OK]${RESET}    %s\n" "$1"; }
error()   { printf "${RED}[ERR]${RESET}   %s\n" "$1" >&2; }

# --- Validate source ----------------------------------------------------------
if [[ ! -f "$CLAUDE_DIR/commands/qa.md" ]]; then
  error "Source file not found: $CLAUDE_DIR/commands/qa.md"
  exit 1
fi

# --- Helpers ------------------------------------------------------------------

# Print a source file without its leading YAML frontmatter. An unclosed frontmatter block is
# printed unchanged. awk ends every line with a newline, so the output always ends with one.
strip_frontmatter() {
    awk 'NR == 1 && $0 == "---" { infm = 1; next }
         infm { buf = buf $0 ORS; if ($0 == "---") { infm = 0; buf = "" }; next }
         { print }
         END { if (infm) printf "---%s%s", ORS, buf }' "$1"
}

# One top-level line of a file's frontmatter, as written, for the key given.
frontmatter_line() {   # file key
    awk -v key="$2" 'NR == 1 && $0 == "---" { infm = 1; next }
         infm && $0 == "---" { exit }
         infm && index($0, key ": ") == 1 { print; exit }' "$1"
}

# --- Validate the skill names -------------------------------------------------
# Every command and agent becomes the skill its id names, every skill folder keeps its own name,
# and qa-rules is generated. A command or an agent with no id would become adapters/skills//SKILL.md,
# and two sources with one name would write the same folder, the later silently replacing the
# earlier. Both are refused before anything is written or removed, in a fixed order and with the
# same words as generate-adapters.ps1 (tests/fixtures/generator-errors.txt).
TAB="$(printf '\t')"
SKILL_OWNERS=""   # one "<name><TAB><source>" line per skill name claimed so far
PROBLEMS=0

claim_skill_name() {   # name source
    local LINE
    while IFS= read -r LINE; do
        [ -n "$LINE" ] || continue
        if [ "${LINE%%"$TAB"*}" = "$1" ]; then
            error "Skill name '$1' is used by both ${LINE#*"$TAB"} and $2; one would overwrite the other in adapters/skills/$1"
            PROBLEMS=$((PROBLEMS + 1))
            return 0
        fi
    done <<OWNERS
$SKILL_OWNERS
OWNERS
    SKILL_OWNERS="$SKILL_OWNERS$1$TAB$2
"
}

for SRC in "$CLAUDE_DIR"/commands/*.md "$CLAUDE_DIR"/agents/*.md; do
    [ -f "$SRC" ] || continue
    REL=".claude/${SRC#"$CLAUDE_DIR"/}"
    ID="$(frontmatter_line "$SRC" id)"
    ID="${ID#id: }"
    if [ -z "$ID" ]; then
        error "$REL has no id in its frontmatter; a command or an agent needs one to name its skill"
        PROBLEMS=$((PROBLEMS + 1))
        continue
    fi
    claim_skill_name "$ID" "$REL"
done
for SKILL_DIR in "$CLAUDE_DIR"/skills/*/; do
    [ -f "${SKILL_DIR}SKILL.md" ] || continue
    SKILL_NAME="$(basename "$SKILL_DIR")"
    claim_skill_name "$SKILL_NAME" ".claude/skills/$SKILL_NAME/"
done
claim_skill_name qa-rules "the generated qa-rules skill"
if [ "$PROBLEMS" -gt 0 ]; then
    error "Nothing was written to adapters/."
    exit 1
fi

# --- Clean --------------------------------------------------------------------
if [[ "$CLEAN" == true ]]; then
  info "Removing $OUT_DIR"
  rm -rf "$OUT_DIR"
fi

info "Source: .claude/{commands,agents,skills,rules}"
info "Output: $OUT_DIR"

# The rule names, in byte order: every .claude/rules/<rule>.md.
RULES=()
for RULE_FILE in "$CLAUDE_DIR"/rules/*.md; do
    [ -f "$RULE_FILE" ] || continue
    RULE_NAME="${RULE_FILE##*/}"
    RULES+=("${RULE_NAME%.md}")
done

# --- The Agent Skills tree ----------------------------------------------------
# One folder per command, agent and skill, named by its id, the same for every editor (plan 047).
# A command or an agent becomes a skill: its name, its description line as written, its id and
# the package's author under metadata (as every skill source carries them), then its text
# without the frontmatter (an agent's model and tools are Claude Code fields and are dropped). The skills are copied as they are, references included. qa-rules
# holds every rule as a reference, so an install with no rule files still reaches them.
SKILLS_OUT="$OUT_DIR/skills"
mkdir -p "$SKILLS_OUT"

skill_from_source() {   # source file
    local SRC="$1" ID
    ID="$(frontmatter_line "$SRC" id)"
    ID="${ID#id: }"
    mkdir -p "$SKILLS_OUT/$ID"
    {
        echo "---"
        echo "name: $ID"
        frontmatter_line "$SRC" description
        echo "metadata:"
        echo "  id: $ID"
        echo "  author: Marco Amaral"
        echo "---"
        strip_frontmatter "$SRC"
    } > "$SKILLS_OUT/$ID/SKILL.md"
}

for SRC in "$CLAUDE_DIR"/commands/*.md "$CLAUDE_DIR"/agents/*.md; do
    [ -f "$SRC" ] && skill_from_source "$SRC"
done

for SKILL_DIR in "$CLAUDE_DIR"/skills/*/; do
    [ -f "${SKILL_DIR}SKILL.md" ] || continue
    SKILL_NAME="$(basename "$SKILL_DIR")"
    (cd "$SKILL_DIR" && find . -type f) | LC_ALL=C sort | while IFS= read -r REL; do
        REL="${REL#./}"
        mkdir -p "$(dirname "$SKILLS_OUT/$SKILL_NAME/$REL")"
        cp "$SKILL_DIR$REL" "$SKILLS_OUT/$SKILL_NAME/$REL"
    done
done

mkdir -p "$SKILLS_OUT/qa-rules/references"
{
    echo "---"
    echo "name: qa-rules"
    echo "description: \"QA Instinct's QA rules, one file each: testing guidelines, code style, security, accessibility, evidence, tools, context discovery, commits and linting. Read the rule a pointer names (the <rule> rule) when this editor has not loaded the rule files, as in a global install.\""
    echo "metadata:"
    echo "  id: qa-rules"
    echo "  author: Marco Amaral"
    echo "---"
    echo "# QA Instinct rules"
    echo ""
    echo "Each rule of the package is a file in this skill's \`references\` folder. A project install"
    echo "also puts every rule in the editor's own rules folder, always on, as \`qa-instinct-<rule>\`; a"
    echo "global install has no rules folder, so read the rule a pointer names from here."
    echo ""
    echo "| Rule | File |"
    echo "| --- | --- |"
    for RULE in "${RULES[@]}"; do
        echo "| \`$RULE\` | \`references/$RULE.md\` |"
    done
} > "$SKILLS_OUT/qa-rules/SKILL.md"
for RULE in "${RULES[@]}"; do
    strip_frontmatter "$CLAUDE_DIR/rules/$RULE.md" > "$SKILLS_OUT/qa-rules/references/$RULE.md"
done

# The skill names, in byte order, for the index.
SKILL_NAMES=()
for SKILL_DIR in "$SKILLS_OUT"/*; do
    [ -d "$SKILL_DIR" ] && SKILL_NAMES+=("${SKILL_DIR##*/}")
done

# --- The index and the rule files --------------------------------------------
# The index (qa-instinct) is the one rule the package adds: it says the package is installed, how
# this editor invokes a skill, and how a pointer in the package's text resolves. $1 is the editor
# key; copilot and universal hold the rules in the same file, under a marker line each.
index_body() {   # key
    local INVOKE RULES_ARE RULE_POINTER NAME LIST=""
    case "$1" in
        cursor)      INVOKE="type \`/qa-cases\` in Agent chat" ;;
        windsurf)    INVOKE="type \`@qa-cases\`" ;;
        copilot)     INVOKE="type \`/qa-cases\` in chat" ;;
        cline)       INVOKE="type \`/qa-cases\`" ;;
        antigravity) INVOKE="ask for it by name, for example \"use the qa-cases skill\"" ;;
        *)           INVOKE="ask for it by name; an editor that lists skills as slash commands also takes \`/qa-cases\`" ;;
    esac
    case "$1" in
        copilot|universal)
            RULES_ARE="Its rules follow in this file, each under a \`<!-- qa-instinct-<rule> -->\` line, and are always on."
            RULE_POINTER="the section under \`<!-- qa-instinct-<rule> -->\` in this file" ;;
        *)
            RULES_ARE="Its rules are the rule files named \`qa-instinct-<rule>\`, always on."
            RULE_POINTER="the rule file \`qa-instinct-<rule>\`" ;;
    esac
    for NAME in "${SKILL_NAMES[@]}"; do
        LIST="$LIST${LIST:+, }\`$NAME\`"
    done
    echo "# QA Instinct"
    echo ""
    echo "QA Instinct, QA Analyst and QA Engineer guidance based on ISTQB CTFL v4.0, is installed here."
    echo "$RULES_ARE"
    echo "Everything else is an Agent Skill of the same name, loaded when its description matches the"
    echo "task, or when you $INVOKE."
    echo ""
    echo "Skills: $LIST."
    echo ""
    echo "How a pointer in the package's text resolves:"
    echo ""
    echo "- a command such as \`/qa-cases\` is the skill \`qa-cases\`;"
    echo "- an agent such as \`qa-groomer\` is the skill \`qa-groomer\`: where the text dispatches it, read"
    echo "  that skill and do its stage yourself;"
    echo "- \"the \`qa-reference\` skill's \`references/<file>.md\`\" is that file in the \`references\`"
    echo "  folder of the \`qa-reference\` skill, never a path under the project root;"
    echo "- \"the \`<rule>\` rule\" is $RULE_POINTER, and the same text is"
    echo "  \`references/<rule>.md\` in the \`qa-rules\` skill;"
    echo "- a script such as \`check-test-evidence.sh\` is not installed for this editor: apply its checks"
    echo "  by reading the files, and say that it was not run."
}

rule_front() {   # key name: the editor's frontmatter for one rule file
    case "$1" in
        cursor)
            echo "---"
            if [ "$2" = qa-instinct ]; then
                echo "description: \"QA Instinct: how its rules and skills are installed in this editor\""
            else
                echo "description: \"QA Instinct rule: ${2#qa-instinct-}\""
            fi
            echo "alwaysApply: true"
            echo "---" ;;
        windsurf|antigravity)
            echo "---"
            echo "trigger: always_on"
            echo "---" ;;
    esac
}

rules_in_one_file() {   # key: the index, then every rule under its marker line
    local RULE
    index_body "$1"
    for RULE in "${RULES[@]}"; do
        echo ""
        echo "<!-- qa-instinct-$RULE -->"
        strip_frontmatter "$CLAUDE_DIR/rules/$RULE.md"
    done
}

for KEY in cursor windsurf cline antigravity; do
    case "$KEY" in cursor) EXT=mdc ;; *) EXT=md ;; esac
    mkdir -p "$OUT_DIR/$KEY/rules"
    { rule_front "$KEY" qa-instinct; index_body "$KEY"; } > "$OUT_DIR/$KEY/rules/qa-instinct.$EXT"
    for RULE in "${RULES[@]}"; do
        { rule_front "$KEY" "qa-instinct-$RULE"; strip_frontmatter "$CLAUDE_DIR/rules/$RULE.md"; } \
            > "$OUT_DIR/$KEY/rules/qa-instinct-$RULE.$EXT"
    done
done

mkdir -p "$OUT_DIR/copilot/rules"
rules_in_one_file copilot > "$OUT_DIR/copilot/rules/copilot-instructions.md"

# --- Universal ----------------------------------------------------------------
# AGENTS.md and CLAUDE.md, copied by hand: the header, the index and the rules, no IDE
# frontmatter. The skills are adapters/skills/, copied by hand beside them.
mkdir -p "$OUT_DIR/universal"
for U in AGENTS CLAUDE; do
    {
        cat << 'UNIVERSAL_HEADER'
<!-- QA Instinct — Senior QA Analyst + QA Engineer (ISTQB CTFL v4.0)
     Universal adapter: no IDE-specific frontmatter. The rules are below; every command, skill
     and agent is an Agent Skill in the package's adapters/skills/ folder.
     Compatible with: Claude Code (CLAUDE.md / --agents-file), Codex, Devin,
     GitHub Copilot (paste into instructions), and any agent that reads markdown.
     Install globally (copy only if you have no such file; otherwise merge it by hand):
       cp adapters/universal/CLAUDE.md ~/.claude/CLAUDE.md        # Claude Code global
       cp adapters/universal/AGENTS.md ~/AGENTS.md                # Codex / Devin / others
       cp adapters/universal/AGENTS.md <project-root>/AGENTS.md   # Project-level universal
     Then copy the folders in adapters/skills/ to the folder your agent reads skills from.
-->

UNIVERSAL_HEADER
        rules_in_one_file universal
    } > "$OUT_DIR/universal/$U.md"
done

# --- Optional: install universals globally -----------------------------------
echo ""
if [[ "${GLOBAL:-false}" == "true" ]]; then
  info "Installing global adapters..."

  # A file already at either path is the user's own: it is kept, never overwritten (plan 033
  # item 7). Only an empty path is written, and a link there counts as a file.
  install_global() {   # adapter file, destination
    if [ -e "$2" ] || [ -L "$2" ]; then
      printf "%b!%b Kept %s — it already exists; merge adapters/universal/%s into it by hand\n" "${YELLOW}" "${RESET}" "$2" "$1"
      return 0
    fi
    mkdir -p "$(dirname "$2")"
    cp "$OUT_DIR/universal/$1" "$2"
    success "Installed global: $2"
  }
  install_global CLAUDE.md "$HOME/.claude/CLAUDE.md"   # Claude Code global skill
  install_global AGENTS.md "$HOME/AGENTS.md"           # Universal AGENTS.md
else
  printf "%b[TIP]%b   To install globally, run: GLOBAL=true ./generate-adapters.sh\n" "${YELLOW}" "${RESET}"
  printf "        Copy only if you have no such file; otherwise merge it by hand.\n"
  printf "        Claude Code global  → cp adapters/universal/CLAUDE.md ~/.claude/CLAUDE.md\n"
  printf "        Universal (Codex…)  → cp adapters/universal/AGENTS.md ~/AGENTS.md\n"
  printf "        Project-level       → cp adapters/universal/AGENTS.md <project>/AGENTS.md\n"
fi

# --- Summary ------------------------------------------------------------------
echo ""
printf "%b%-50s %8s%b\n" "${YELLOW}" "FILE" "SIZE" "${RESET}"
printf '%.0s-' {1..60}; echo ""
while IFS= read -r f; do
  rel="${f#"$OUT_DIR/"}"
  case "$rel" in skills/*) continue ;; esac
  printf "%-50s %6s B\n" "$rel" "$(wc -c < "$f" | tr -d ' ')"
done < <(find "$OUT_DIR" -type f | LC_ALL=C sort)
printf "%-50s %6s files\n" "skills/ (${#SKILL_NAMES[@]} skills)" "$(find "$SKILLS_OUT" -type f | wc -l | tr -d ' ')"

echo ""
success "All adapters generated ($(find "$OUT_DIR" -type f | wc -l | tr -d ' ') files)"
