#!/usr/bin/env bash
#
# tests/conformance/run.sh — run every conformance case against every installer
# available on this platform: install.sh and cli/qa-instinct.js. (install.ps1 is covered by
# run.ps1 on Windows.) Each guarantee the installers share is written once, as a
# case under cases/, and is required of all of them. See plans/016.
#
# Usage: tests/conformance/run.sh [case-name-substring]
#
# CONFORMANCE_PKG=<dir> runs the installers from another package tree — a checked-out
# older release, say — while the cases still come from this repository. That is how a
# case is proven to fail against a historical installer before it passes.
#
# CONFORMANCE_CASES=<dir> reads the cases from another folder; tests/conformance/test-runner.sh
# uses it to feed the runner malformed cases.
#
# Must run on bash 3.2 (macOS): no associative arrays.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
pkg="${CONFORMANCE_PKG:-$repo}"
# The CLI moved from bin/cli.js to cli/bem-te-vi.js after 4.0.1 (plan 051), and to
# cli/qa-instinct.js with the rename (plan 065); an older package tree still has it at an old path.
cli="$pkg/cli/qa-instinct.js"
[ -f "$cli" ] || cli="$pkg/cli/bem-te-vi.js"
[ -f "$cli" ] || cli="$pkg/bin/cli.js"
cases="${CONFORMANCE_CASES:-$here/cases}"
filter="${1:-}"

if command -v sha256sum > /dev/null 2>&1; then
  sha() { sha256sum "$1" | cut -d' ' -f1; }
else
  sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
fi

# The project folder's name holds a space and wildcard characters, so every case also proves that
# an installer treats the paths it computes literally (plan 033 item 5).
proj='project [1]'

trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; printf '%s' "${s%"${s##*[![:space:]]}"}"; }

# ─── Reading a case file ─────────────────────────────────────────────────────
# A case file is data the runner acts on, so it is checked in full before any line runs: a path
# that is absolute or climbs out of its scope's folder, a scope, editor or operation the runner
# does not know, and a line outside the grammar make the case malformed, and nothing of it runs.
# run.ps1 applies the same grammar, line for line (tests/conformance/test-runner.sh checks both).

EDITORS="claude cursor windsurf copilot cline antigravity"

# A relative path with forward slashes, no empty, '.' or '..' segment, no drive or backslash.
safe_rel() {
  case "$1" in ''|/*|*\\*|[A-Za-z]:*) return 1 ;; esac
  local rest="$1/" seg
  while [ -n "$rest" ]; do
    seg="${rest%%/*}"; rest="${rest#*/}"
    case "$seg" in ''|.|..) return 1 ;; esac
  done
}
path_spec() {   # project:<rel> or home:<rel>
  case "$1" in
    project:*) safe_rel "${1#project:}" ;;
    home:*)    safe_rel "${1#home:}" ;;
    *) return 1 ;;
  esac
}
# A manifest entry is text the installers read, and a case may record one that climbs out of its
# scope (case 005 does, to prove the installers refuse it). The runner itself still reads and
# deletes at that path, so it must end inside the sandbox's project or home folder.
sandbox_rel() {   # rel, relative to a scope folder
  case "$1" in ''|/*|*\\*|[A-Za-z]:*) return 1 ;; esac
  local rest="$1/" seg depth=1 top=""
  while [ -n "$rest" ]; do
    seg="${rest%%/*}"; rest="${rest#*/}"
    case "$seg" in
      ''|.) return 1 ;;
      ..) depth=$((depth - 1)); [ "$depth" -ge 0 ] || return 1 ;;
      *) [ "$depth" -eq 0 ] && top="$seg"; depth=$((depth + 1)) ;;
    esac
  done
  [ "$depth" -ge 2 ] && { [ -z "$top" ] || [ "$top" = "$proj" ] || [ "$top" = home ]; }
}
one_of() { local w; for w in $2; do [ "$1" = "$w" ] && return 0; done; return 1; }

# <scope> <editor> <path>: the path is the rest of the line, so it may hold a space (plan 053 I11).
check_manifest_args() {
  local a1 a2 a3
  read -r a1 a2 a3 <<< "$1"
  one_of "$a1" "project home" && one_of "$a2" "$EDITORS" && sandbox_rel "$a3"
}
# The editor may be left out: the run then names none, and each installer picks its own default
# (plan 061 B1).
check_run_args() {
  local a1 a2 a3 extra
  read -r a1 a2 a3 extra <<< "$1"
  [ -z "$extra" ] && one_of "$a1" "install uninstall update" && one_of "$a2" "project global" &&
    { [ -z "$a3" ] || one_of "$a3" "$EDITORS all"; }
}
# <left> = <right>: the left part is the text before the first " = ", the right part after it.
has_pair() { case "$1" in *" = "*) return 0 ;; esac; return 1; }
left_of() { trim "${1%% = *}"; }
right_of() { printf '%s' "${1#* = }"; }

check_directive() {   # key value -> 0 when well-formed
  local key="$1" val="$2" a1 a2 extra
  case "$key" in
    name) return 0 ;;
    skip|expect-output|expect-no-output) [ -n "$val" ] ;;
    seed|expect-content|expect-backup-content)
      has_pair "$val" && path_spec "$(left_of "$val")" ;;
    seed-fixture|seed-package|expect-same-as-package|expect-tree-as-package)
      has_pair "$val" && path_spec "$(left_of "$val")" && safe_rel "$(trim "$(right_of "$val")")" ;;
    expect-backup-link-target)
      has_pair "$val" && path_spec "$(left_of "$val")" && path_spec "$(trim "$(right_of "$val")")" ;;
    seed-symlink)
      case "$val" in *" -> "*) ;; *) return 1 ;; esac
      path_spec "$(trim "${val%% -> *}")" && path_spec "$(trim "${val#* -> }")" ;;
    seed-manifest|drop-manifest|expect-manifest|expect-no-manifest) check_manifest_args "$val" ;;
    seed-dir|seed-readonly|seed-unreadable|seed-crlf|expect-file|expect-absent|expect-backup|expect-no-backup) path_spec "$val" ;;
    run|run-unknown-option) check_run_args "$val" ;;
    expect-exit) case "$val" in ''|*[!0-9]*) return 1 ;; esac ;;
    expect-exit-nonzero) [ -z "$val" ] ;;
    expect-output-lists-package)
      read -r a1 a2 extra <<< "$val"
      [ -z "$extra" ] && safe_rel "$a1" && [ -n "$a2" ] && case "${a2%/}" in */*|*..*|'') false ;; esac ;;
    *) return 1 ;;
  esac
}

# Fills CASE_STEPS with "key|value" per directive line, or sets CASE_ERROR and fails. A leading
# BOM and trailing whitespace, a CR included, are not part of a line.
load_case() {   # case.conf
  local line key val num=0
  CASE_STEPS=(); CASE_ERROR=""
  while IFS= read -r line || [ -n "$line" ]; do
    num=$((num + 1))
    [ "$num" -eq 1 ] && line="${line#$'\357\273\277'}"
    line="$(trim "$line")"
    case "$line" in ''|'#'*) continue ;; esac
    case "$line" in
      [a-z]*:*) ;;
      *) CASE_ERROR="malformed case: line $num is not '<directive>: <value>'"; return 1 ;;
    esac
    key="${line%%:*}"; val="$(trim "${line#*:}")"
    case "$key" in *[!a-z-]*) CASE_ERROR="malformed case: line $num is not '<directive>: <value>'"; return 1 ;; esac
    if ! check_directive "$key" "$val"; then
      CASE_ERROR="malformed case: line $num ($key) — unknown directive, or a scope, editor, operation or path the runner does not accept"
      return 1
    fi
    CASE_STEPS+=("$key|$val")
  done < "$1"
}

# A manifest line is "<64 hex>  <editor>  <path>". The editor and the path are compared as plain
# text, never as a pattern: a dot in a path must match a dot, not any character.
# shellcheck disable=SC2016 # an awk program: $0 is awk's, not the shell's
MANIFEST_MATCH='length($0) == 64 + length(W) && substr($0, 1, 64) ~ /^[0-9a-f]+$/ && (substr($0, 65) "") == W'
manifest_has() {   # manifest, editor, path
  tr -d '\r' < "$1" | QS_W="  $2  $3" awk "BEGIN { W = ENVIRON[\"QS_W\"] } $MANIFEST_MATCH { f = 1 } END { exit !f }"
}
manifest_without() {   # manifest, editor, path: the manifest minus that entry
  QS_W="  $2  $3" awk "BEGIN { W = ENVIRON[\"QS_W\"] } !($MANIFEST_MATCH)" "$1"
}

# <scope>:<path> -> absolute path inside the current sandbox
resolve() {
  path_spec "$1" || { echo "conformance: refusing path '$1'" >&2; return 1; }
  case "$1" in
    project:*) printf '%s/%s/%s' "$sb" "$proj" "${1#project:}" ;;
    home:*)    printf '%s/home/%s' "$sb" "${1#home:}" ;;
    *) echo "conformance: path '$1' needs a project: or home: prefix" >&2; return 1 ;;
  esac
}
scope_root() {
  case "$1" in
    project) echo "$sb/$proj" ;;
    home) echo "$sb/home" ;;
    *) echo "conformance: unknown scope '$1'" >&2; return 1 ;;
  esac
}

# run_action <installer> <install|uninstall|update> <project|global> <editor|""> [bogus]
# An empty editor passes no editor option at all. A fifth argument appends one option the
# installer does not know, in its own syntax.
run_action() {
  local inst="$1" op="$2" scope="$3" ed="$4" bogus="${5:-}"
  local -a args
  case "$inst" in
    install.sh)
      args=(--target "$scope" --non-interactive --no-hooks --no-color)
      [ -n "$ed" ] && args+=(--editor "$ed")
      [ "$op" = uninstall ] && args+=(--uninstall)
      [ "$op" = update ] && args+=(--update)
      [ -n "$bogus" ] && args+=(--bogus-option)
      (cd "$sb/$proj" && HOME="$sb/home" GIT_CONFIG_GLOBAL="$sb/home/.gitconfig" "$pkg/install.sh" "${args[@]}") >> "$log" 2>&1
      ;;
    cli)
      case "$op" in install) args=(init) ;; *) args=("$op") ;; esac
      [ "$scope" = global ] && args+=(--global)
      [ -n "$ed" ] && args+=(--editor "$ed")
      [ -n "$bogus" ] && args+=(--bogus-option)
      (cd "$sb/$proj" && HOME="$sb/home" GIT_CONFIG_GLOBAL="$sb/home/.gitconfig" node "$cli" "${args[@]}") >> "$log" 2>&1
      ;;
  esac
  last_exit=$?
}

fail() { echo "      ✘ $*"; case_failed=1; }

run_case() {  # <case dir> <installer>
  local dir="$1" inst="$2" step key val target text want got n f a1 a2 a3 root
  if ! load_case "$dir/case.conf"; then
    echo "      ✘ $CASE_ERROR"
    return 1
  fi
  sb="$(mktemp -d "${TMPDIR:-/tmp}/qa-conformance.XXXXXX")"
  mkdir -p "$sb/$proj" "$sb/home"
  log="$sb/output.log"; : > "$log"
  last_exit=0; case_failed=0
  local -a expects=()

  for step in "${CASE_STEPS[@]}"; do
    key="${step%%|*}"; val="${step#*|}"
    case "$key" in
      name|skip) ;;
      seed|seed-fixture|seed-package)
        target="$(resolve "$(left_of "$val")")" || { fail "refused $val"; continue; }
        text="$(right_of "$val")"
        mkdir -p "$(dirname "$target")"
        case "$key" in
          seed)         printf '%s\n' "$text" > "$target" ;;
          seed-fixture) cp "$dir/$(trim "$text")" "$target" ;;
          seed-package) cp "$pkg/$(trim "$text")" "$target" ;;
        esac ;;
      seed-manifest)
        read -r a1 a2 a3 <<< "$val"
        root="$(scope_root "$a1")" || { fail "refused $val"; continue; }
        f="$(cd "$root" && cd "$(dirname "$a3")" 2>/dev/null && pwd)/$(basename "$a3")"
        printf '%s  %s  %s\n' "$(sha "$f")" "$a2" "$a3" >> "$root/.qa-skills-manifest" ;;
      drop-manifest)
        # Removes an installed file and its manifest line, as if the install predated the file.
        read -r a1 a2 a3 <<< "$val"
        root="$(scope_root "$a1")" || { fail "refused $val"; continue; }
        rm -f "$root/$a3"
        f="$root/.qa-skills-manifest"
        manifest_without "$f" "$a2" "$a3" > "$sb/manifest.tmp"
        cat "$sb/manifest.tmp" > "$f" && rm -f "$sb/manifest.tmp" ;;
      seed-dir)
        target="$(resolve "$val")" || { fail "refused $val"; continue; }
        mkdir -p "$target" ;;
      seed-readonly)
        target="$(resolve "$val")" || { fail "refused $val"; continue; }
        chmod a-w "$target" ;;
      seed-unreadable)
        target="$(resolve "$val")" || { fail "refused $val"; continue; }
        chmod a-r "$target" ;;
      seed-crlf)
        # Every LF gets a CR before it, an existing CRLF stays as it is, and a last line with no
        # newline stays without one. Rewritten in place, so the file keeps its mode.
        target="$(resolve "$val")" || { fail "refused $val"; continue; }
        {
          while IFS= read -r text; do printf '%s\r\n' "${text%$'\r'}"; done
          [ -z "$text" ] || printf '%s' "$text"
        } < "$target" > "$sb/crlf.tmp" && cat "$sb/crlf.tmp" > "$target" && rm -f "$sb/crlf.tmp" ;;
      seed-symlink)
        target="$(resolve "$(trim "${val#* -> }")")" || { fail "refused $val"; continue; }
        f="$(resolve "$(trim "${val%% -> *}")")" || { fail "refused $val"; continue; }
        ln -s "$target" "$f" ;;
      run)
        read -r a1 a2 a3 <<< "$val"
        run_action "$inst" "$a1" "$a2" "$a3" ;;
      run-unknown-option)
        read -r a1 a2 a3 <<< "$val"
        run_action "$inst" "$a1" "$a2" "$a3" bogus ;;
      expect-*) expects+=("$key|$val") ;;
      *) fail "unknown directive '$key'" ;;
    esac
  done

  local e
  for e in ${expects[@]+"${expects[@]}"}; do
    key="${e%%|*}"; val="${e#*|}"
    case "$key" in
      expect-exit)
        [ "$last_exit" = "$val" ] || fail "exit $last_exit, expected $val" ;;
      expect-exit-nonzero)
        [ "$last_exit" != 0 ] || fail "exit 0, expected a failure" ;;
      expect-file)
        [ -e "$(resolve "$val")" ] || fail "missing $val" ;;
      expect-absent)
        [ ! -e "$(resolve "$val")" ] || fail "should not exist: $val" ;;
      expect-content)
        target="$(resolve "$(trim "${val%% = *}")")"; want="${val#* = }"
        got="$(cat "$target" 2>/dev/null)"
        [ "$got" = "$want" ] || fail "${val%% = *} holds '$got', expected '$want'" ;;
      expect-same-as-package)
        target="$(resolve "$(trim "${val%% = *}")")"; want="${val#* = }"
        cmp -s "$target" "$pkg/$want" || fail "${val%% = *} differs from the package's $want" ;;
      expect-tree-as-package)
        # Every file below that folder of the package is installed below the path, byte for byte.
        # A package folder with no file in it proves nothing, so it fails too.
        target="$(resolve "$(trim "${val%% = *}")")"; want="${val#* = }"
        n=0
        while IFS= read -r f; do
          [ -n "$f" ] || continue
          n=$((n + 1))
          cmp -s "$target/$f" "$pkg/$want/$f" || fail "${val%% = *}/$f differs from the package's $want/$f"
        done <<< "$( [ -d "$pkg/$want" ] && cd "$pkg/$want" && find . -type f | sed 's#^\./##' | LC_ALL=C sort)"
        [ "$n" -gt 0 ] || fail "the package has no file under $want" ;;
      expect-backup|expect-no-backup|expect-backup-content|expect-backup-link-target)
        # A symlinked destination's backup has a <backup>.link-target file beside it, recording
        # where the link pointed; it matches the same glob but is not a backup itself.
        target="$(resolve "$(trim "${val%% = *}")")"
        n=0; got=""; text=""
        for f in "$target".qa-skills-backup-*; do
          [ -e "$f" ] || continue
          case "$f" in *.link-target) continue ;; esac
          n=$((n + 1)); got="$(cat "$f")"; text="$(tr -d '\r' < "$f.link-target" 2>/dev/null)"
        done
        case "$key" in
          expect-backup)    [ "$n" -ge 1 ] || fail "no backup of $val" ;;
          expect-no-backup) [ "$n" -eq 0 ] || fail "unexpected backup of $val" ;;
          expect-backup-content)
            want="${val#* = }"
            [ "$got" = "$want" ] || fail "backup of ${val%% = *} holds '$got', expected '$want'" ;;
          expect-backup-link-target)
            want="$(resolve "$(trim "${val#* = }")")"
            [ "$text" = "$want" ] || fail "backup of ${val%% = *} records link target '$text', expected '$want'" ;;
        esac ;;
      expect-manifest|expect-no-manifest)
        read -r a1 a2 a3 <<< "$val"
        f="$(scope_root "$a1")/.qa-skills-manifest"
        if [ -f "$f" ] && manifest_has "$f" "$a2" "$a3"; then n=1; else n=0; fi
        if [ "$key" = expect-manifest ]; then
          [ "$n" = 1 ] || fail "manifest lacks: $val"
        else
          [ "$n" = 0 ] || fail "manifest should not record: $val"
        fi ;;
      expect-output)
        grep -qF -- "$val" "$log" || fail "output lacks '$val'" ;;
      expect-output-lists-package)
        # Every match of the pattern in that folder of the package under test is named in the
        # output: without .md, and with a leading / for a command.
        read -r a1 a2 <<< "$val"
        for f in "$pkg/$a1"/$a2; do
          [ -e "$f" ] || continue
          text="$(basename "$f")"; text="${text%.md}"
          [ "$(basename "$a1")" = commands ] && text="/$text"
          grep -qF -- "$text" "$log" || fail "output does not list $text"
        done ;;
      expect-no-output)
        ! grep -qF -- "$val" "$log" || fail "output contains '$val'" ;;
      *) fail "unknown expectation '$key'" ;;
    esac
  done

  if [ "$case_failed" -ne 0 ]; then
    echo "      output (last 6 lines):"; tail -6 "$log" | sed 's/^/        /'
  fi
  chmod -R u+rw "$sb" 2>/dev/null
  rm -rf "$sb"
  return "$case_failed"
}

installers="install.sh cli"
total=0; failed=0; skipped=0
echo "Conformance: installers from $pkg"
for dir in "$cases"/*/; do
  dir="${dir%/}"; name="$(basename "$dir")"
  [ -n "$filter" ] && case "$name" in *"$filter"*) ;; *) continue ;; esac
  # The same reading as load_case: no BOM, no CR.
  conf="$(sed -e $'1s/^\xEF\xBB\xBF//' -e 's/\r$//' "$dir/case.conf")"
  echo "  $name — $(printf '%s\n' "$conf" | sed -n 's/^name:[[:space:]]*//p')"
  for inst in $installers; do
    reason="$(printf '%s\n' "$conf" | sed -n "s/^skip:[[:space:]]*${inst}[[:space:]]*—[[:space:]]*//p")"
    if [ -n "$reason" ]; then
      printf '    %-11s SKIP  %s\n' "$inst" "$reason"; skipped=$((skipped + 1)); continue
    fi
    total=$((total + 1))
    if out="$(run_case "$dir" "$inst")"; then
      printf '    %-11s pass\n' "$inst"
    else
      printf '    %-11s FAIL\n' "$inst"; printf '%s\n' "$out"; failed=$((failed + 1))
    fi
  done
done
echo "Conformance: $((total - failed))/$total passed, $failed failed, $skipped skipped"
[ "$failed" -eq 0 ]
