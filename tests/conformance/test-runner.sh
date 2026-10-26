#!/usr/bin/env bash
#
# tests/conformance/test-runner.sh — tests the conformance runner itself. A case file is data the
# runner acts on: a malformed one (a path that climbs out of the sandbox or is absolute, a scope or
# editor the runner does not know, a line it cannot parse) must fail the case before anything is
# written, read or deleted, and a well-formed one must parse the same way in run.sh and run.ps1
# (tests/conformance/test-runner.ps1 holds the same checks). The cases here are written at run time,
# outside cases/, so the real suite never runs them.
#
# Must run on bash 3.2 (macOS).
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/qa-runner-selftest.XXXXXX")"
failures=0
n=0

# Runs one case through run.sh with the sandbox under $t, so a path that climbs two folders out of
# the project lands in $t, beside the canary.
run_one() {   # name, case.conf body (printf format)
  n=$((n + 1))
  t="$work/t$n"; mkdir -p "$t/tmp" "$t/cases/001-$1"
  printf 'CANARY\n' > "$t/tmp/canary"
  # shellcheck disable=SC2059 # the body is a printf format on purpose, for \r and the BOM
  printf "$2" > "$t/cases/001-$1/case.conf"
  printf 'FIXTURE TEXT\n' > "$t/cases/001-$1/fixture.txt"
  out="$(TMPDIR="$t/tmp" CONFORMANCE_CASES="$t/cases" "$here/run.sh" 2>&1)"; status=$?
}
bad() { echo "  ✘ $*"; failures=$((failures + 1)); }

rejected() {   # name, body, [file under $t/tmp that must not exist]
  run_one "$1" "$2"
  [ "$status" -ne 0 ] || bad "$1: the runner accepted a malformed case"
  # A here-string, not printf piped into grep -q: grep exits at the first match, a printf still
  # writing gets SIGPIPE, and pipefail turns its 141 into a false failure (plan 033, 2026-10-20).
  grep -q 'malformed case' <<< "$out" || bad "$1: the runner did not report a malformed case"
  [ "$(cat "$t/tmp/canary" 2>/dev/null)" = CANARY ] || bad "$1: the runner changed or deleted a file outside its sandbox"
  # A chmod leaves the content alone, so the mode is part of "unchanged" too.
  [ -n "$(find "$t/tmp/canary" -perm -u+rw 2>/dev/null)" ] || bad "$1: the runner changed the mode of a file outside its sandbox"
  [ -z "${3:-}" ] || [ ! -e "$t/tmp/$3" ] || bad "$1: the runner wrote $3 outside its sandbox"
}
accepted() {   # name, body
  run_one "$1" "$2"
  [ "$status" -eq 0 ] || { bad "$1: the runner rejected a well-formed case"; printf '%s\n' "$out" | tail -8 | sed 's/^/      /'; }
}

echo "Conformance runner self-test"

# Paths: every path stays inside its scope's folder.
rejected seed-climbs-out 'name: x\nseed: project:../../escaped.txt = X\n' escaped.txt
rejected drop-climbs-out 'name: x\ndrop-manifest: project claude ../../canary\n'
rejected absolute-path 'name: x\nseed: home:/abs.txt = X\n'
rejected drive-path 'name: x\nseed: home:C:/abs.txt = X\n'
rejected backslash-path 'name: x\nseed: home:..\\..\\escaped.txt = X\n' escaped.txt
rejected symlink-target-climbs-out 'name: x\nseed-symlink: project:link -> home:../../canary\n'
rejected package-path-climbs-out 'name: x\nseed-package: home:copy.txt = ../outside.txt\n'
rejected fixture-path-climbs-out 'name: x\nseed-fixture: home:copy.txt = ../../canary\n'
rejected manifest-path-absolute 'name: x\nseed-manifest: project claude /etc/hostname\n'
rejected manifest-entry-at-sandbox-root 'name: x\nseed-manifest: project claude ../output.log\n'
rejected legacy-manifest-bad-scope 'name: x\nlegacy-manifest: global\n'
rejected legacy-manifest-link-climbs-out 'name: x\nlegacy-manifest: project -> home:../../canary\n'
rejected expect-path-climbs-out 'name: x\nexpect-absent: home:../../canary\n'
rejected readonly-climbs-out 'name: x\nseed-readonly: home:../../canary\n'
rejected unreadable-climbs-out 'name: x\nseed-unreadable: home:../../canary\n'
rejected crlf-climbs-out 'name: x\nseed-crlf: home:../../canary\n'
rejected dir-climbs-out 'name: x\nseed-dir: home:../../canary\n'
rejected expect-content-climbs-out 'name: x\nexpect-content: home:../../canary = CANARY\n'
rejected backup-link-target-climbs-out 'name: x\nexpect-backup-link-target: project:a.md = home:../../canary\n'
rejected package-listing-climbs-out 'name: x\nexpect-output-lists-package: ../.. *\n'
rejected package-tree-climbs-out 'name: x\nexpect-tree-as-package: project:t = ../..\n'

# Scopes and editors: only the runner's own; a typo never falls back to some other folder.
# An unknown scope used to resolve to no folder at all, so this path was taken from the root.
rejected drop-unknown-scope "name: x\ndrop-manifest: projct claude ${work#/}/t$((n + 1))/tmp/canary\n"
rejected run-unknown-scope 'name: x\nrun: install projct claude\n'
rejected run-unknown-operation 'name: x\nrun: instal project claude\n'
rejected run-extra-word 'name: x\nrun: install project claude now\n'
rejected run-without-scope 'name: x\nrun: update\n'
rejected manifest-unknown-editor 'name: x\nexpect-manifest: project claud .claude/x.md\n'
rejected path-unknown-scope 'name: x\nexpect-file: projct:.claude\n'

# Lines: one grammar, and anything outside it is an error.
rejected no-colon 'name: x\nthis line has no colon\n'
rejected unknown-directive 'name: x\nseed-everything: project:x.txt = y\n'
rejected unspaced-equals 'name: x\nseed: project:a.txt=X\n'
rejected unspaced-arrow 'name: x\nseed-symlink: project:a->home:b\n'
rejected exit-not-a-number 'name: x\nexpect-exit: zero\n'
rejected exit-nonzero-takes-no-value 'name: x\nexpect-exit-nonzero: 1\n'
rejected skip-without-reason 'name: x\nskip:\n'
# A lone CR does not end a line in either runner, so this is one line with an unknown directive.
rejected lone-cr 'expect-everything: x\rname: y\n'

# Well-formed cases, every setup directive and every expectation that needs no installer run.
accepted bom '\357\273\277name: a case file saved with a BOM\nexpect-absent: project:nothing-here\n'
accepted crlf 'name: a case file saved with CRLF\r\n# a comment\r\n\r\nexpect-absent: project:nothing-here\r\n'
accepted manifest-entry-in-the-other-scope 'name: an entry may climb into the home folder, as case 005 records\nseed: home:v.txt = V\nseed-manifest: project claude ../home/v.txt\nexpect-manifest: project claude ../home/v.txt\n'
# A path in a manifest line is plain text: a dot matches a dot, not any character.
accepted manifest-lookup-is-literal 'name: expect-manifest and drop-manifest compare a path as text\nseed: project:a.md = A\nseed: project:aXmd = B\nseed-manifest: project claude aXmd\nexpect-no-manifest: project claude a.md\nseed-manifest: project claude a.md\ndrop-manifest: project claude a.md\nexpect-manifest: project claude aXmd\nexpect-no-manifest: project claude a.md\n'
# A manifest path is the rest of the line, so it may hold a space (plan 053 I11).
accepted manifest-path-with-a-space 'name: a manifest path may hold a space\nseed: project:my notes/a  b.md = A\nseed: project:my notes/c d.md = C\nseed-manifest: project cursor my notes/a  b.md\nseed-manifest: project cursor my notes/c d.md\ndrop-manifest: project cursor my notes/c d.md\nexpect-manifest: project cursor my notes/a  b.md\nexpect-no-manifest: project cursor my notes/a b.md\nexpect-no-manifest: project cursor my notes/c d.md\nexpect-file: project:my notes/a  b.md\nexpect-absent: project:my notes/c d.md\n'
rejected manifest-path-with-a-space-climbs-out 'name: x\ndrop-manifest: project claude ../../canary x\n'
accepted package-tree 'name: a copy of a package folder matches it file for file\nseed-package: home:t/check-test-evidence.sh = .claude/hooks/check-test-evidence.sh\nseed-package: home:t/validate-tc-format.sh = .claude/hooks/validate-tc-format.sh\nexpect-tree-as-package: home:t = .claude/hooks\n'
# The editor of a run line may be left out: the installer then gets no editor option (plan 061 B1).
accepted legacy-manifest 'name: legacy-manifest renames the manifest to its 4.x name\nseed: project:a.md = A\nseed-manifest: project claude a.md\nlegacy-manifest: project\nexpect-file: project:.qa-skills-manifest\nexpect-absent: project:.qa-instinct-manifest\n'
accepted run-without-editor 'name: a run line may name no editor\nrun: uninstall project\nexpect-exit: 0\n'
accepted every-directive 'name: every directive\nseed: project:a/b.txt = HELLO\nseed-fixture: project:fx.txt = fixture.txt\nexpect-content: project:fx.txt = FIXTURE TEXT\nseed: project:crlf.txt = LINE\nseed-crlf: project:crlf.txt\nseed-readonly: project:a/b.txt\nseed: project:locked.txt = LOCKED\nseed-unreadable: project:locked.txt\nseed-package: home:pkg.md = .claude/rules/security-qa.md\nseed-manifest: home claude pkg.md\nseed: project:gone.txt = BYE\nseed-manifest: project claude gone.txt\ndrop-manifest: project claude gone.txt\nseed-symlink: project:link.md -> home:pkg.md\nseed-dir: project:empty/folder\nexpect-file: project:empty/folder\nexpect-exit: 0\nexpect-file: project:link.md\nexpect-absent: project:gone.txt\nexpect-content: project:a/b.txt = HELLO\nexpect-same-as-package: home:pkg.md = .claude/rules/security-qa.md\nexpect-manifest: home claude pkg.md\nexpect-no-manifest: project claude gone.txt\nexpect-no-backup: project:a/b.txt\nexpect-no-output: anything at all\n'

chmod -R u+rw "$work" 2>/dev/null
rm -rf "$work"
if [ "$failures" -eq 0 ]; then
  echo "Conformance runner self-test: $n checks passed"
else
  echo "Conformance runner self-test: $failures problem(s)"
  exit 1
fi
