#!/usr/bin/env bash
# verify-adapters.sh — Assert that generate-adapters.sh actually produced usable adapters.
#
# CI used to "verify" this with `git status --porcelain adapters/`, but adapters/ is gitignored,
# so that check could never fail and reported success even when nothing was generated at all.
# That is exactly how a bash 3.2 incompatibility shipped: the compiler aborted on macOS, wrote
# no adapters, and CI still said "compilation is clean and up to date".
#
# Since plan 047 the adapters are each editor's always-on rule files plus one Agent Skills tree.
# Every always-on file must stay within 85 percent of its editor's documented limit; the measured
# sizes are printed so the README can quote them. tests/verify-adapters.ps1 makes the same checks.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$REPO_DIR/adapters"
CLAUDE_DIR="$REPO_DIR/.claude"

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
FAILED=0

fail() { echo -e "${RED}✘ $1${NC}" >&2; FAILED=1; }

# Characters of a UTF-8 file: its bytes less the continuation bytes (10xxxxxx), the same count on
# every platform and in tests/verify-adapters.ps1.
chars() { LC_ALL=C tr -d '\200-\277' < "$1" | wc -c | tr -d ' '; }
bytes() { wc -c < "$1" | tr -d ' '; }
lines() { wc -l < "$1" | tr -d ' '; }

# Print a source file without its leading YAML frontmatter, as the generator does.
strip_frontmatter() {
    awk 'NR == 1 && $0 == "---" { infm = 1; next }
         infm { buf = buf $0 ORS; if ($0 == "---") { infm = 0; buf = "" }; next }
         { print }
         END { if (infm) printf "---%s%s", ORS, buf }' "$1"
}

RULES=()
for RULE_FILE in "$CLAUDE_DIR"/rules/*.md; do
    RULE_NAME="${RULE_FILE##*/}"
    RULES+=("${RULE_NAME%.md}")
done

# Every file the installers install, by editor. Keep in step with .qa-skills-editor-map.
EXPECTED="copilot/rules/copilot-instructions.md
universal/AGENTS.md
universal/CLAUDE.md"
for KEY in cursor windsurf cline antigravity; do
    case "$KEY" in cursor) EXT=mdc ;; *) EXT=md ;; esac
    EXPECTED="$EXPECTED
$KEY/rules/qa-instinct.$EXT"
    for RULE in "${RULES[@]}"; do
        EXPECTED="$EXPECTED
$KEY/rules/qa-instinct-$RULE.$EXT"
    done
done

# Skills: one per command, agent and skill, and qa-rules.
SKILLS=""
for SRC in "$CLAUDE_DIR"/commands/*.md "$CLAUDE_DIR"/agents/*.md; do
    SKILLS="$SKILLS ${SRC##*/}"
done
SKILLS="${SKILLS//.md/}"
for SRC in "$CLAUDE_DIR"/skills/*/SKILL.md; do
    SRC="${SRC%/SKILL.md}"
    SKILLS="$SKILLS ${SRC##*/}"
done
SKILLS="$SKILLS qa-rules"

echo "Verifying generated adapters in $OUT_DIR"

# Encoding: the sources are UTF-8 without a BOM, and so must every generated file be (the
# PowerShell generator once wrote mojibake and a BOM). Probe with the dispatcher's first non-ASCII
# line, which its skill must carry intact.
PROBE="$(LC_ALL=C grep -m1 -E '[^ -~	]' "$CLAUDE_DIR/commands/qa.md" | tr -d '\r')"
while IFS= read -r F; do
    REL="${F#"$OUT_DIR"/}"
    [ "$(head -c 3 "$F" | od -An -tx1 | tr -d ' ')" = "efbbbf" ] && fail "$REL starts with a UTF-8 BOM"
    # The merged file of plan 043 and before is gone; no section of it may come back.
    grep -q '^<!-- source: ' "$F" && fail "$REL carries a merged-file section marker (<!-- source: ...)"
done < <(find "$OUT_DIR" -type f | LC_ALL=C sort)
if [ -n "$PROBE" ] && ! grep -qF -- "$PROBE" "$OUT_DIR/skills/qa/SKILL.md" 2>/dev/null; then
    fail "skills/qa/SKILL.md does not contain the dispatcher's non-ASCII text intact (encoding garbled)"
fi

# --- The rule files -----------------------------------------------------------
while IFS= read -r REL; do
    [ -f "$OUT_DIR/$REL" ] || fail "missing: $REL"
done <<EOF
$EXPECTED
EOF

for KEY in cursor windsurf cline antigravity; do
    for F in "$OUT_DIR/$KEY"/rules/*; do
        [ -f "$F" ] || continue
        case "$KEY" in
            cursor)
                head -1 "$F" | grep -q '^---$' || fail "${F#"$OUT_DIR"/} is missing its MDC frontmatter"
                grep -qx 'alwaysApply: true' "$F" || fail "${F#"$OUT_DIR"/} is not alwaysApply: true"
                grep -q '^description: ' "$F" || fail "${F#"$OUT_DIR"/} has no description" ;;
            windsurf|antigravity)
                [ "$(sed -n 2p "$F")" = "trigger: always_on" ] || fail "${F#"$OUT_DIR"/} is not trigger: always_on" ;;
            cline)
                head -1 "$F" | grep -q '^---$' && fail "${F#"$OUT_DIR"/} must have no frontmatter (always active)" ;;
        esac
    done
    grep -q 'ISTQB' "$OUT_DIR/$KEY/rules/qa-instinct-testing-guidelines".* || fail "$KEY rules lack the testing guidelines"
done
for F in "$OUT_DIR/copilot/rules/copilot-instructions.md" "$OUT_DIR/universal/AGENTS.md" "$OUT_DIR/universal/CLAUDE.md"; do
    [ -f "$F" ] || continue
    for RULE in "${RULES[@]}"; do
        grep -qx -- "<!-- qa-instinct-$RULE -->" "$F" || fail "${F#"$OUT_DIR"/} has no section for the $RULE rule"
    done
    head -1 "$F" | grep -q '^---$' && fail "${F#"$OUT_DIR"/} must not carry IDE frontmatter"
done
for U in AGENTS CLAUDE; do
    head -1 "$OUT_DIR/universal/$U.md" | grep -q '^<!-- QA Instinct' || fail "universal/$U.md is missing its header comment"
done

# --- The skills tree ------------------------------------------------------------
SKILL_COUNT=0
NAME_DESC_CHARS=0
for NAME in $SKILLS; do
    SKILL_COUNT=$((SKILL_COUNT + 1))
    F="$OUT_DIR/skills/$NAME/SKILL.md"
    if [ ! -f "$F" ]; then
        fail "missing skill: skills/$NAME/SKILL.md"
        continue
    fi
    # The Agent Skills format: name equal to the folder, lowercase words joined by hyphens, at
    # most 64 characters; a description of 1 to 1,024 characters; at most 500 lines.
    GOT_NAME="$(sed -n 's/^name: //p' "$F" | head -1)"
    [ "$GOT_NAME" = "$NAME" ] || fail "skills/$NAME/SKILL.md names itself '$GOT_NAME'"
    printf '%s\n' "$NAME" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$' || fail "skill name '$NAME' is not lowercase words joined by hyphens"
    [ "${#NAME}" -le 64 ] || fail "skill name '$NAME' is longer than 64 characters"
    DESC="$(sed -n 's/^description: //p' "$F" | head -1)"
    DESC="${DESC#\"}"; DESC="${DESC%\"}"
    DESC_CHARS="$(printf '%s' "$DESC" | LC_ALL=C tr -d '\200-\277' | wc -c | tr -d ' ')"
    { [ "$DESC_CHARS" -ge 1 ] && [ "$DESC_CHARS" -le 1024 ]; } || fail "skills/$NAME has a description of $DESC_CHARS characters (1 to 1,024)"
    NAME_DESC_CHARS=$((NAME_DESC_CHARS + ${#NAME} + DESC_CHARS))
    [ "$(lines "$F")" -le 500 ] || fail "skills/$NAME/SKILL.md has $(lines "$F") lines (at most 500)"
    # Every skill names its author under metadata, whatever it was generated from (plan 060).
    grep -qx '  author: Marco Amaral' <<< "$(awk 'NR == 1 { next } $0 == "---" { exit } { print }' "$F")" \
        || fail "skills/$NAME/SKILL.md has no 'author: Marco Amaral' under metadata"
done
ACTUAL_SKILLS="$(find "$OUT_DIR/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
[ "$ACTUAL_SKILLS" -eq "$SKILL_COUNT" ] || fail "expected $SKILL_COUNT skill folders, found $ACTUAL_SKILLS"

# README.md states how many files the skills hold and how many characters of names and
# descriptions are in context before any skill is used; both are what this run generated
# (pre-launch review, 2026-10-20). The README wraps the sentence, so it is read as one line.
SKILL_FILES="$(find "$OUT_DIR/skills" -type f | wc -l | tr -d ' ')"
NAME_DESC_FMT="$(printf '%s' "$NAME_DESC_CHARS" | awk '{ n = $0; s = ""; while (length(n) > 3) { s = "," substr(n, length(n) - 2) s; n = substr(n, 1, length(n) - 3) } print n s }')"
README_TEXT="$(tr '\n' ' ' < "$REPO_DIR/README.md" | tr -s ' ')"
case "$README_TEXT" in
    *"The $SKILL_COUNT skills hold $SKILL_FILES files"*) ;;
    *) fail "README.md must say \"The $SKILL_COUNT skills hold $SKILL_FILES files\" (what this run generated)" ;;
esac
case "$README_TEXT" in
    *"come to $NAME_DESC_FMT characters"*) ;;
    *) fail "README.md must say the skills' names and descriptions \"come to $NAME_DESC_FMT characters\" (what this run measured)" ;;
esac

# qa-reference keeps its references as they are; qa-rules holds each rule without frontmatter.
REF_COUNT=0
for SRC in "$CLAUDE_DIR"/skills/qa-reference/references/*.md; do
    REF_COUNT=$((REF_COUNT + 1))
    cmp -s "$SRC" "$OUT_DIR/skills/qa-reference/references/${SRC##*/}" || fail "skills/qa-reference/references/${SRC##*/} differs from its source"
done
[ "$(find "$OUT_DIR/skills/qa-reference/references" -type f | wc -l | tr -d ' ')" -eq "$REF_COUNT" ] \
    || fail "skills/qa-reference/references does not hold exactly the $REF_COUNT references"
for RULE in "${RULES[@]}"; do
    strip_frontmatter "$CLAUDE_DIR/rules/$RULE.md" | cmp -s - "$OUT_DIR/skills/qa-rules/references/$RULE.md" \
        || fail "skills/qa-rules/references/$RULE.md is not the $RULE rule without its frontmatter"
done
[ "$(find "$OUT_DIR/skills/qa-rules/references" -type f | wc -l | tr -d ' ')" -eq "${#RULES[@]}" ] \
    || fail "skills/qa-rules/references does not hold exactly the ${#RULES[@]} rules"

# Nothing unexpected, so a new file cannot be added without being covered here.
EXPECTED_COUNT=$(( $(printf '%s\n' "$EXPECTED" | wc -l) + $(find "$OUT_DIR/skills" -type f | wc -l) ))
ACTUAL_COUNT=$(find "$OUT_DIR" -type f | wc -l | tr -d ' ')
if [ "$ACTUAL_COUNT" -ne "$EXPECTED_COUNT" ]; then
    fail "expected $EXPECTED_COUNT adapter files, found $ACTUAL_COUNT"
fi

# --- Always-on size budgets: 85 percent of each editor's documented limit (plan 047) ----------
# Windsurf: 12,000 characters per rule file. Cursor: "under 500 lines" per rule. Copilot: "about
# 1,000 lines" per file. Antigravity: 24,000 bytes per rule file, and a 20,000-token budget for
# every always-on rule (68,000 characters at the 4 characters a token the plan assumes, 85 percent
# of 80,000). Universal AGENTS.md: Codex reads 32 KiB of AGENTS.md. Cline states no limit; its
# rules are capped at the source by tests/test-rules-size.sh.
echo "Always-on size per editor (largest file / all files; budget):"
budget() {   # key measure per-file-limit total-limit label
    local KEY="$1" MEASURE="$2" PER="$3" TOTAL="$4" LABEL="$5" F N MAX=0 MAXF="" SUM=0 COUNT=0
    for F in "$OUT_DIR/$KEY"/rules/*; do
        [ -f "$F" ] || continue
        N="$("$MEASURE" "$F")"
        SUM=$((SUM + N)); COUNT=$((COUNT + 1))
        if [ "$N" -gt "$MAX" ]; then MAX="$N"; MAXF="${F##*/}"; fi
        if [ "$PER" -gt 0 ] && [ "$N" -gt "$PER" ]; then fail "$KEY/rules/${F##*/} is $N $MEASURE, over the budget of $PER"; fi
    done
    if [ "$TOTAL" -gt 0 ] && [ "$SUM" -gt "$TOTAL" ]; then fail "$KEY rules total $SUM $MEASURE, over the budget of $TOTAL"; fi
    printf '  %-12s %2s files, largest %s %s (%s), all %s %s; %s\n' "$KEY" "$COUNT" "$MAX" "$MEASURE" "$MAXF" "$SUM" "$MEASURE" "$LABEL"
    B_COUNT="$COUNT"; B_MAX="$MAX"; B_SUM="$SUM"
}
# README.md's always-on table quotes these sizes: each budget call adds the row it must read.
commas() { local N="$1" OUT=""; while [ "${#N}" -gt 3 ]; do OUT=",${N: -3}$OUT"; N="${N%???}"; done; printf '%s%s' "$N" "$OUT"; }
README_ROWS=""
readme_row() { README_ROWS="$README_ROWS| $1 | $2 | $3 | $4 |
"; }
budget windsurf    chars 10200 0     "budget 10,200 chars per file"
readme_row Windsurf "$B_COUNT" "$(commas "$B_MAX") characters" "$(commas "$B_SUM") characters"
budget cursor      lines 425   0     "budget 425 lines per file"
readme_row Cursor "$B_COUNT" "$B_MAX lines" "$B_SUM lines"
budget copilot     lines 850   0     "budget 850 lines"
readme_row Copilot "$B_COUNT" "$B_MAX lines" "$B_SUM lines"
budget antigravity bytes 20400 0     "budget 20,400 bytes per file"
AG_COUNT="$B_COUNT"; AG_MAX="$B_MAX"; AG_SUM="$B_SUM"
budget antigravity chars 0     68000 "budget 68,000 chars in all"
readme_row Antigravity "$AG_COUNT" "$(commas "$AG_MAX") bytes" "$(commas "$AG_SUM") bytes ($(commas "$B_SUM") characters)"
budget cline       chars 0     0     "no limit stated"
readme_row Cline "$B_COUNT" "$(commas "$B_MAX") characters" "$(commas "$B_SUM") characters"
N="$(bytes "$OUT_DIR/universal/AGENTS.md")"
[ "$N" -le 27852 ] || fail "universal/AGENTS.md is $N bytes, over the budget of 27,852"
printf '  %-12s %2s files, %s bytes, %s lines; budget 27,852 bytes\n' "universal" 1 "$N" "$(lines "$OUT_DIR/universal/AGENTS.md")"
readme_row "\`AGENTS.md\`" 1 "$(commas "$N") bytes" "$(commas "$N") bytes"

# --- README.md's always-on table is what was just measured (pre-launch review, 2026-10-20) ----
# The table had drifted by up to 212 bytes. A change to .claude/rules or to the generator moves
# these sizes, so it updates the table in the same pull request. tests/verify-adapters.ps1 does
# not repeat this: it checks the README, not the adapters, and Linux and macOS run it here.
while IFS= read -r ROW; do
    [ -n "$ROW" ] || continue
    awk -v row="$ROW" 'index($0, row) == 1 { found = 1 } END { exit !found }' "$REPO_DIR/README.md" && continue
    EDITOR="${ROW#| }"; EDITOR="${EDITOR%% |*}"
    HAVE="$(awk -v ed="| $EDITOR |" 'index($0, ed) == 1 { print; exit }' "$REPO_DIR/README.md")"
    fail "README.md's always-on table has \"${HAVE:-no $EDITOR row}\"; this run measured \"$ROW\". Update the row to the measured sizes (a change to .claude/rules or the generator moves them)."
done <<EOF
$README_ROWS
EOF

# --- The generator refuses a broken source tree (plan 054) ----------------------
# A command or an agent with no id, and a skill name two sources share, on planted trees.
echo "Generator refusals (tests/fixtures/generator-errors.txt):"
bash "$REPO_DIR/tests/test-generator-errors.sh" \
    || fail "generate-adapters.sh does not refuse a broken source tree as tests/fixtures/generator-errors.txt says"

if [ "$FAILED" -ne 0 ]; then
    echo -e "${RED}Adapter verification failed.${NC}" >&2
    exit 1
fi

echo -e "${GREEN}✔ All $ACTUAL_COUNT adapter files generated correctly ($SKILL_COUNT skills, every editor within budget).${NC}"
