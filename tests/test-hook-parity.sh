#!/usr/bin/env bash
# tests/test-hook-parity.sh — install.sh and install.ps1 embed the same git hook text (plan 064).
#
# Each installer carries its own copy of the pre-commit hook it registers. They drifted for five
# releases once, and nothing compared them. This check extracts the project hook and the global
# block from both files by their anchors, and the constants that recognise a hook a release
# wrote, and compares them byte for byte. It reads source text only; the bytes each installer
# writes, final newline included, are checked by lifecycle Tests 73 (bash) and 57 (PowerShell).
#
# An extraction that comes back empty fails, so a moved anchor cannot make the check pass.
#
# Usage: tests/test-hook-parity.sh [repo-dir]    (default: this repository)

# shellcheck disable=SC2016  # the patterns below are literal text containing "$"
set -u

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SH="$ROOT/install.sh"
PS="$ROOT/install.ps1"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

failed=0
fail() { echo "  ✘ $1"; failed=1; }

# body FILE START END OUT: the lines after the first line equal to START (leading blanks ignored)
# up to, not including, the next line that begins with END. Literal strings, not patterns.
body() {
  S="$2" E="$3" awk '
    BEGIN { s = ENVIRON["S"]; e = ENVIRON["E"] }
    inside && substr($0, 1, length(e)) == e { exit }
    inside { print }
    !inside && !done { line = $0; sub(/^[ \t]+/, "", line); if (line == s) { inside = 1; done = 1 } }
  ' "$1" > "$4"
}

# constant FILE ASSIGNMENT_REGEX: the text between the quotes of the first matching line.
constant() {
  grep -m1 -E "$2" "$1" | sed -E "s/^[^'\"]*['\"](.*)['\"][[:space:]]*\$/\\1/"
}

if [ ! -f "$SH" ] || [ ! -f "$PS" ]; then
  echo "  ✘ install.sh or install.ps1 not found under $ROOT"
  exit 1
fi

body "$SH" "cat > \"\$HOOK_FILE\" << 'PRECOMMIT'" 'PRECOMMIT' "$TMP/project.sh"
body "$PS" "\$hookContent = @'" "'@" "$TMP/project.ps"
body "$SH" "cat << 'GLOBAL_PRECOMMIT_BLOCK'" 'GLOBAL_PRECOMMIT_BLOCK' "$TMP/global.sh"
body "$PS" "\$Script:GlobalHookBlock = ((@'" "'@)" "$TMP/global.ps"

for f in project.sh project.ps global.sh global.ps; do
  [ -s "$TMP/$f" ] || fail "could not extract the hook body $f; an anchor moved"
done

if [ "$failed" -eq 0 ]; then
  cmp -s "$TMP/project.sh" "$TMP/project.ps" || { fail "the project hook differs between install.sh and install.ps1:"; diff "$TMP/project.sh" "$TMP/project.ps" | sed 's/^/      /'; }
  cmp -s "$TMP/global.sh" "$TMP/global.ps" || { fail "the global hook block differs between install.sh and install.ps1:"; diff "$TMP/global.sh" "$TMP/global.ps" | sed 's/^/      /'; }

  # The recognition strings are written literally here, so editing them in both installers at once
  # still fails this check.
  [ "$(sed -n 2p "$TMP/project.sh")" = "# Pre-commit hook to validate test cases in qa-instinct" ] || fail "the project hook's second line is not the marker line"
  [ "$(sed -n 1p "$TMP/global.sh")" = "# >>> bem-te-vi global pre-commit >>>" ] || fail "the global block's first line is not the opening fence"
  [ "$(sed -n 2p "$TMP/global.sh")" = "# Added by qa-skills global installer" ] || fail "the global block's second line is not the old marker"
  [ "$(tail -n 2 "$TMP/global.sh" | sed -n 1p)" = "# GLOBAL_PRECOMMIT_APPEND" ] || fail "the global block's next-to-last line is not the old end line"
  [ "$(tail -n 1 "$TMP/global.sh")" = "# <<< bem-te-vi global pre-commit <<<" ] || fail "the global block's last line is not the closing fence"
fi

check_constant() {   # label sh-assignment-regex ps-assignment-regex
  local a b
  a="$(constant "$SH" "$2")"
  b="$(constant "$PS" "$3")"
  if [ -z "$a" ] || [ -z "$b" ]; then
    fail "constant $1 not found in both installers"
  elif [ "$a" != "$b" ]; then
    fail "constant $1 differs: install.sh has '$a', install.ps1 has '$b'"
  fi
}
check_constant PROJECT_HOOK_MARKER '^PROJECT_HOOK_MARKER=' '^\$Script:ProjectHookMarker = '
check_constant GLOBAL_HOOK_BEGIN '^GLOBAL_HOOK_BEGIN=' '^\$Script:GlobalHookBegin = '
check_constant GLOBAL_HOOK_END '^GLOBAL_HOOK_END=' '^\$Script:GlobalHookEnd = '
check_constant GLOBAL_HOOK_OLD_MARKER '^GLOBAL_HOOK_OLD_MARKER=' '^\$Script:GlobalHookOldMarker = '
check_constant GLOBAL_HOOK_OLD_END '^GLOBAL_HOOK_OLD_END=' '^\$Script:GlobalHookOldEnd = '
check_constant PROJECT_HOOK_OLD_MARKER '^PROJECT_HOOK_OLD_MARKER=' '^\$Script:ProjectHookOldMarker = '
check_constant GLOBAL_HOOK_OLD_FRESH_HEADER '^GLOBAL_HOOK_OLD_FRESH_HEADER=' '^\$Script:GlobalHookOldFreshHeader = '
check_constant GLOBAL_HOOK_FRESH_HEADER '^GLOBAL_HOOK_FRESH_HEADER=' '^\$Script:GlobalHookFreshHeader = '

if [ "$failed" -ne 0 ]; then
  echo "  ✘ install.sh and install.ps1 do not embed the same git hook text."
  exit 1
fi
echo "  ✔ install.sh and install.ps1 embed the same git hooks and recognition constants."
