#!/usr/bin/env bash
# tests/test-docs-drift.sh — the command names and sizes the README and the /qa router give match
# the files that ship (plan 055, item I5).
#
# Plans 001, 003, 031 and 034 each found the same drift by hand: a /qa-* name that no longer
# resolved, a README command table that missed a command, and size columns that no longer matched
# the files. This check fails when:
#
#   - a /qa-<name> in shipped content (.claude/agents, commands, rules, skills, hooks) or README.md
#     is neither a command (.claude/commands/qa-<name>.md) nor a skill invoked by its name
#     (.claude/skills/qa-<name>/SKILL.md);
#   - README's command table (under "## Commands & Modules") does not list exactly the files in
#     .claude/commands, or the /qa router's command table does not list every command but itself;
#   - a "~NKB" size in either table is not the file's size: bytes / 1024, rounded to the nearest
#     whole number, as the columns have always been written;
#   - CONTRIBUTING.md's "Allowed Types" list or the pull request template's "Type of change" list
#     does not name exactly the commit types the checks accept: commitlint's resolved type-enum
#     (commitlint.config.js and what it extends) and verify-merge-commits.sh's pattern, which must
#     agree with each other (Marco, 2026-10-20). Needs the devDependencies from npm ci.
#   - a paragraph of README.md, ROADMAP.md or CONTRIBUTING.md that names the conformance suite
#     gives a number of cases ("58 cases", "60 conformance cases") other than the number of
#     cases in tests/conformance/cases (pre-launch review, 2026-10-20).
#
# Usage: tests/test-docs-drift.sh [repo-dir]    (default: this repository)

set -u

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
COMMANDS="$ROOT/.claude/commands"
ROUTER="$COMMANDS/qa.md"
README="$ROOT/README.md"
FAILED=0

fail() { echo "  ✘ $*"; FAILED=1; }

# 1. Every /qa-<name> resolves. A name inside a path or URL (".claude/qa-x", "github.com/a/qa-x",
# "~/qa-x") is not a slash command, so the character before the slash must not be part of a path.
# A name followed by ":" is the plugin's prefix (/qa-instinct:qa-cases), not a command.
refs="$(cd "$ROOT" && grep -rnoE '(^|[^A-Za-z0-9_./~-])/qa-[a-z0-9]+(-[a-z0-9]+)*:?' \
  .claude/agents .claude/commands .claude/rules .claude/skills .claude/hooks README.md 2>/dev/null |
  grep -v ':$' |
  sed -E 's#^([^:]+:[0-9]+:).*(/qa-[a-z0-9-]+)$#\1\2#')"
count=0
unresolved=0
while IFS= read -r ref; do
  [ -n "$ref" ] || continue
  count=$((count + 1))
  name="${ref##*/}"
  if [ ! -f "$COMMANDS/$name.md" ] && [ ! -f "$ROOT/.claude/skills/$name/SKILL.md" ]; then
    fail "${ref%:*}: /$name is neither a command in .claude/commands nor a skill in .claude/skills"
    unresolved=$((unresolved + 1))
  fi
done <<EOF
$refs
EOF
if [ "$count" -eq 0 ]; then
  fail "no /qa-* reference found in shipped content or README.md; the search is broken"
elif [ "$unresolved" -eq 0 ]; then
  echo "  ✔ all $count /qa-* references in shipped content and README.md resolve"
fi

# The command rows of a table: lines that start with "| `/qa", from the heading line that starts
# with $2 to the next heading. Prints "<command> <size cell or empty>".
command_rows() {
  awk -v want="$2" '
    index($0, want) == 1 { on = 1; next }
    on && /^#/ { on = 0 }
    on && /^\| *`\/qa[a-z0-9-]*`/ {
      n = split($0, cell, "|")
      name = cell[2]; gsub(/[ `]/, "", name)
      size = cell[n - 1]; gsub(/ /, "", size)
      if (size !~ /^~[0-9]+KB$/) size = ""
      print name, size
    }
  ' "$1"
}

shipped="$(for f in "$COMMANDS"/*.md; do b="${f##*/}"; echo "/${b%.md}"; done | sort)"

# 2. The tables list the commands that ship.
compare_list() {  # <label> <listed names> <expected names>
  local missing extra
  missing="$(comm -13 <(printf '%s\n' "$2") <(printf '%s\n' "$3") | paste -s -d ' ' -)"
  extra="$(comm -23 <(printf '%s\n' "$2") <(printf '%s\n' "$3") | paste -s -d ' ' -)"
  if [ -z "$missing" ] && [ -z "$extra" ]; then
    echo "  ✔ $1 lists exactly the shipped commands it should"
  else
    [ -z "$missing" ] || fail "$1 does not list: $missing"
    [ -z "$extra" ] || fail "$1 lists commands that do not ship: $extra"
  fi
}
readme_rows="$(command_rows "$README" "## Commands & Modules")"
router_rows="$(command_rows "$ROUTER" "## 🚀 Specialized Active Commands")"
[ -n "$readme_rows" ] || fail "README.md: no command table under \"## Commands & Modules\""
[ -n "$router_rows" ] || fail "qa.md: no command table under \"## 🚀 Specialized Active Commands\""
compare_list "README.md's command table" "$(printf '%s\n' "$readme_rows" | cut -d' ' -f1 | sort)" "$shipped"
compare_list "the /qa router's command table" "$(printf '%s\n' "$router_rows" | cut -d' ' -f1 | sort)" \
  "$(printf '%s\n' "$shipped" | grep -vx '/qa')"

# 3. Every size matches the file.
check_sizes() {  # <label> <rows>
  local name size file bytes want bad=0 sized=0
  while read -r name size; do
    [ -n "$name" ] || continue
    file="$COMMANDS/${name#/}.md"
    if [ -z "$size" ]; then
      fail "$1: $name has no ~NKB size"
      bad=1
      continue
    fi
    [ -f "$file" ] || continue
    sized=$((sized + 1))
    bytes=$(wc -c < "$file" | tr -d ' ')
    want=$(((bytes + 512) / 1024))
    if [ "$size" != "~${want}KB" ]; then
      fail "$1: $name says $size, but ${file#"$ROOT"/} is $bytes bytes (~${want}KB)"
      bad=1
    fi
  done <<EOF
$2
EOF
  [ "$bad" -ne 0 ] || echo "  ✔ $1: all $sized sizes match wc -c (bytes / 1024, rounded)"
}
check_sizes "README.md's command table" "$readme_rows"
check_sizes "the /qa router's command table" "$router_rows"

# 4. The contributor docs name exactly the commit types the checks accept.
one_line() { tr '|' ' ' | tr ' ' '\n' | sed '/^$/d' | sort | paste -s -d ' ' -; }
listed_types() {  # <file> <heading> <sed pattern capturing the type>
  awk -v want="$2" 'index($0, want) == 1 { on = 1; next } on && /^#/ { on = 0 } on' "$1" |
    sed -nE "$3" | one_line
}
lint_types="$(cd "$ROOT" && node --input-type=module -e "
const { default: load } = await import('@commitlint/load');
const config = await load({}, { cwd: process.cwd() });
console.log(config.rules['type-enum'][2].join(' '));" 2>/dev/null | one_line)"
merge_types="$(sed -nE "s/^conventional='\^\(([a-z|]+)\).*/\1/p" "$ROOT/verify-merge-commits.sh" | one_line)"
if [ -z "$lint_types" ]; then
  fail "could not resolve commitlint's type-enum from commitlint.config.js (run npm ci first)"
elif [ -z "$merge_types" ]; then
  fail "verify-merge-commits.sh: no conventional='^(type|...)' pattern found"
elif [ "$lint_types" != "$merge_types" ]; then
  fail "commitlint accepts \"$lint_types\" but verify-merge-commits.sh accepts \"$merge_types\""
else
  check_types() {  # <label> <listed types>
    if [ "$2" = "$lint_types" ]; then
      echo "  ✔ $1 names exactly the commit types the checks accept"
    else
      fail "$1 names \"$2\"; the checks accept \"$lint_types\""
    fi
  }
  check_types "CONTRIBUTING.md's Allowed Types list" \
    "$(listed_types "$ROOT/CONTRIBUTING.md" "### Allowed Types" 's/^- .([a-z]+):. .*/\1/p')"
  check_types "the pull request template's Type of change list" \
    "$(listed_types "$ROOT/.github/pull_request_template.md" "## Type of change" \
      's/^- \[ \] .([a-z]+). .*/\1/p')"
fi

# 5. Every count of conformance cases is the number of cases. A paragraph is the unit, so a claim
# wrapped over two lines is still read; only paragraphs that name the conformance suite count.
cases=$(find "$ROOT/tests/conformance/cases" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')
claims="$(for doc in README.md ROADMAP.md CONTRIBUTING.md; do
  [ -f "$ROOT/$doc" ] || continue
  awk -v doc="$doc" '
    function flush() {
      if (para ~ /[Cc]onformance/) {
        rest = para
        while (match(rest, /[0-9][0-9,]* (conformance )?cases/)) {
          claim = substr(rest, RSTART, RLENGTH)
          n = claim; sub(/ .*/, "", n); gsub(/,/, "", n)
          print doc ":" start " " n " " claim
          rest = substr(rest, RSTART + RLENGTH)
        }
      }
      para = ""
    }
    /^[ \t]*$/ { flush(); next }
    { if (para == "") start = NR; para = para " " $0 }
    END { flush() }
  ' "$ROOT/$doc"
done)"
claimed=0
wrong=0
while read -r where n claim; do
  [ -n "$where" ] || continue
  claimed=$((claimed + 1))
  if [ "$n" -ne "$cases" ]; then
    fail "$where (the paragraph starting there): says \"$claim\", but tests/conformance/cases holds $cases cases"
    wrong=1
  fi
done <<EOF
$claims
EOF
[ "$wrong" -ne 0 ] ||
  echo "  ✔ all $claimed conformance case counts in README.md, ROADMAP.md and CONTRIBUTING.md are $cases"

if [ "$FAILED" -ne 0 ]; then
  echo "Command names, sizes, commit types or case counts in the docs have drifted from the files"
  echo "and checks."
  exit 1
fi
echo "✔ The README and the /qa router name and size exactly the commands that ship, the contributor"
echo "  docs name exactly the commit types the checks accept, and every conformance case count is"
echo "  the number of cases."
