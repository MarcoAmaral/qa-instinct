#!/usr/bin/env bash
# tests/test-llms-txt.sh — llms.txt names only files that exist, and names every shipped one
# (plan 050 step 5).
#
# llms.txt is the index an AI agent reads to find what to load from this repository. Its links are
# GitHub URLs on main, so a renamed or deleted file turns into a 404 that nothing else would catch,
# and a skill or reference added without a line in it is invisible to an agent that trusts it.
# This check fails when:
#
#   - a link is not a URL of this repository on main (raw.githubusercontent.com, or github.com's
#     blob/ and tree/ pages);
#   - a link's path is not tracked by git (an ignored file such as docs/ exists locally but is
#     not on GitHub);
#   - a shipped Markdown file under .claude/agents, commands, rules or skills has no raw link.
#
# Usage: tests/test-llms-txt.sh [repo-dir]    (default: this repository)

set -u

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
INDEX="$ROOT/llms.txt"
RAW="https://raw.githubusercontent.com/MarcoAmaral/qa-instinct/main/"
WEB="https://github.com/MarcoAmaral/qa-instinct/"
FAILED=0

if [ ! -f "$INDEX" ]; then
  echo "  ✘ no llms.txt at $ROOT"
  exit 1
fi

if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  tracked() { git -C "$ROOT" ls-files -- "$1"; }
else
  # Outside a git checkout (an unpacked archive), fall back to the files on disk.
  tracked() {
    if [ -d "$ROOT/$1" ]; then (cd "$ROOT" && find "$1" -type f); elif [ -f "$ROOT/$1" ]; then echo "$1"; fi
  }
fi

links="$(grep -oE '\]\([^)]+\)' "$INDEX" | sed -e 's/^](//' -e 's/)$//')"
if [ -z "$links" ]; then
  echo "  ✘ llms.txt has no links"
  exit 1
fi

count=0
linked_files=""
while IFS= read -r url; do
  count=$((count + 1))
  case "$url" in
    "$RAW"*) kind="file"; path="${url#"$RAW"}" ;;
    "${WEB}blob/main/"*) kind="file"; path="${url#"${WEB}blob/main/"}" ;;
    "${WEB}tree/main/"*) kind="dir"; path="${url#"${WEB}tree/main/"}"; path="${path%/}" ;;
    *)
      echo "  ✘ not a link to this repository on main: $url"
      FAILED=1
      continue
      ;;
  esac
  found="$(tracked "$path")"
  if [ "$kind" = file ] && [ "$found" != "$path" ]; then
    echo "  ✘ no tracked file at $path ($url)"
    FAILED=1
  elif [ "$kind" = dir ] && [ -z "$found" ]; then
    echo "  ✘ no tracked files under $path/ ($url)"
    FAILED=1
  fi
  [ "$kind" = file ] && linked_files="$linked_files
$path"
done <<EOF
$links
EOF

shipped=0
for dir in agents commands rules skills; do
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    case "$file" in *.md) ;; *) continue ;; esac
    shipped=$((shipped + 1))
    if ! printf '%s\n' "$linked_files" | grep -qxF "$file"; then
      echo "  ✘ $file ships but llms.txt does not link it; add: - [name]($RAW$file): what it is for"
      FAILED=1
    fi
  done <<EOF
$(tracked ".claude/$dir")
EOF
done

if [ "$shipped" -eq 0 ]; then
  echo "  ✘ no shipped Markdown found under $ROOT/.claude"
  exit 1
fi
if [ "$FAILED" -ne 0 ]; then
  echo "llms.txt check failed."
  exit 1
fi
echo "✔ All $count llms.txt links name tracked files, and all $shipped shipped .md files are linked."
