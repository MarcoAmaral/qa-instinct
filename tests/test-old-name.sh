#!/usr/bin/env bash
# tests/test-old-name.sh — the package's former name appears only where it was kept on purpose
# (plan 070).
#
# Plan 065 renamed Bem-te-vi to QA Instinct and checked the result once, by hand. This check keeps
# it that way. A tracked file may name the former package only when:
#
#   - it is part of the historical record or recorded output, kept as written (plan 065's
#     keep-list): plans/, decisions/, CHANGELOG.md, history/, prompt-history/, examples/,
#     evals/results/, benchmark/results/, tests/fixtures/, known-hashes-before-public.txt; or
#   - the exact line is listed in tests/old-name-allowlist.txt, which says why each one stays.
#
# It fails on any other line, on a tracked file name outside the record, and on an allowlist entry
# that no longer matches a line (so the list cannot rot).
#
# Usage: tests/test-old-name.sh [repo-dir]    (default: this repository)

set -u

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ALLOW="$ROOT/tests/old-name-allowlist.txt"
PATTERN='bem[-_ ]?te[-_ ]?vi'
FAILED=0

RECORD=(':!plans/' ':!decisions/' ':!CHANGELOG.md' ':!history/' ':!prompt-history/' ':!examples/'
  ':!evals/results/' ':!benchmark/results/' ':!tests/fixtures/' ':!known-hashes-before-public.txt'
  ':!tests/test-old-name.sh' ':!tests/old-name-allowlist.txt')

if [ ! -f "$ALLOW" ]; then
  echo "  ✘ no allowlist at tests/old-name-allowlist.txt"
  exit 1
fi

allowed="$(grep -v -e '^#' -e '^$' "$ALLOW")"
found="$(git -C "$ROOT" grep -I -i -E "$PATTERN" -- . "${RECORD[@]}")"

while IFS= read -r line; do
  [ -n "$line" ] || continue
  if ! printf '%s\n' "$allowed" | grep -qxF -- "$line"; then
    echo "  ✘ former name outside the record: $line"
    FAILED=1
  fi
done <<<"$found"

while IFS= read -r entry; do
  [ -n "$entry" ] || continue
  if ! printf '%s\n' "$found" | grep -qxF -- "$entry"; then
    echo "  ✘ allowlist entry matches no line any more: $entry"
    FAILED=1
  fi
done <<<"$allowed"

names="$(git -C "$ROOT" ls-files -- . "${RECORD[@]}" | grep -i -E "$PATTERN")"
if [ -n "$names" ]; then
  while IFS= read -r name; do
    echo "  ✘ file name carries the former name: $name"
  done <<<"$names"
  FAILED=1
fi

if [ "$FAILED" -ne 0 ]; then
  echo "Rename the line, or list it in tests/old-name-allowlist.txt with the reason it stays."
  exit 1
fi
echo "✔ The former name appears only in the record and on $(printf '%s\n' "$allowed" | grep -c .) allowlisted lines."
